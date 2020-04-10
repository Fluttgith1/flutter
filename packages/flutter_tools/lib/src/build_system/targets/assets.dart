// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/logger.dart';
import 'package:meta/meta.dart';
import 'package:pool/pool.dart';

import '../../asset.dart';
import '../../base/file_system.dart';
import '../../build_info.dart';
import '../../convert.dart';
import '../../devfs.dart';
import '../../globals.dart' as globals;
import '../build_system.dart';
import '../depfile.dart';
import 'dart.dart';
import 'icon_tree_shaker.dart';

/// The input key for an SkSL bundle path.
const String kBundleSkSLPath = 'BundleSkSLPath';

/// A helper function to copy an asset bundle into an [environment]'s output
/// directory.
///
/// Throws [Exception] if [AssetBundle.build] returns a non-zero exit code.
///
/// [skSLBundle] may optionally contain a validated SkSL shader bundle.
///
/// Returns a [Depfile] containing all assets used in the build.
Future<Depfile> copyAssets(Environment environment, Directory outputDirectory, {
  Map<String, String> skSLBundle,
}) async {
  final File pubspecFile =  environment.projectDir.childFile('pubspec.yaml');
  final ManifestAssetBundle assetBundle = AssetBundleFactory.instance.createBundle()
    as ManifestAssetBundle;
  if (skSLBundle != null) {
    assetBundle.skSLBundle = skSLBundle;
  }
  final int resultCode = await assetBundle.build(
    manifestPath: pubspecFile.path,
    packagesPath: environment.projectDir.childFile('.packages').path,
  );
  if (resultCode != 0) {
    throw Exception('Failed to bundle asset files.');
  }
  final Pool pool = Pool(kMaxOpenFiles);
  final List<File> inputs = <File>[
    // An asset manifest with no assets would have zero inputs if not
    // for this pubspec file.
    pubspecFile,
  ];
  final List<File> outputs = <File>[];

  final IconTreeShaker iconTreeShaker = IconTreeShaker(
    environment,
    assetBundle.entries[kFontManifestJson] as DevFSStringContent,
    processManager: globals.processManager,
    logger: globals.logger,
    fileSystem: globals.fs,
    artifacts: globals.artifacts,
  );

  await Future.wait<void>(
    assetBundle.entries.entries.map<Future<void>>((MapEntry<String, DevFSContent> entry) async {
      final PoolResource resource = await pool.request();
      try {
        // This will result in strange looking files, for example files with `/`
        // on Windows or files that end up getting URI encoded such as `#.ext`
        // to `%23.ext`. However, we have to keep it this way since the
        // platform channels in the framework will URI encode these values,
        // and the native APIs will look for files this way.
        final File file = globals.fs.file(globals.fs.path.join(outputDirectory.path, entry.key));
        outputs.add(file);
        file.parent.createSync(recursive: true);
        final DevFSContent content = entry.value;
        if (content is DevFSFileContent && content.file is File) {
          inputs.add(globals.fs.file(content.file.path));
          if (!await iconTreeShaker.subsetFont(
            inputPath: content.file.path,
            outputPath: file.path,
            relativePath: entry.key,
          )) {
            await (content.file as File).copy(file.path);
          }
        } else {
          await file.writeAsBytes(await entry.value.contentsAsBytes());
        }
      } finally {
        resource.release();
      }
  }));
  return Depfile(inputs + assetBundle.additionalDependencies, outputs);
}

/// Validate and process an SkSL asset bundle.
///
/// Returns `null` if the bundle was not provided, otherwise attempts to
/// validate the bundle.
///
/// Throws [Exception] if the bundle is invalid due to formatting issues.
///
/// If the current target platform is different than the platform constructed
/// for the bundle, a warning will be printed.
Map<String, String> processSkSLBundle(String bundlePath, {
  @required TargetPlatform targetPlatform,
  @required FileSystem fileSystem,
  @required Logger logger,
  @required String engineRevision,
}) {
  if (bundlePath == null) {
    return null;
  }
  // Step 1: check that file exists.
  final File skSLBundleFile = fileSystem.file(bundlePath);
  if (!skSLBundleFile.existsSync()) {
    logger.printError('$bundlePath does not exist.');
    throw Exception('SkSL bundle was invalid.');
  }

  // Step 2: validate top level bundle structure.
  Map<String, Object> bundle;
  try {
    bundle = json.decode(skSLBundleFile.readAsStringSync())
      as Map<String, Object>;
  } on FormatException {
    logger.printError('"$bundle" was not a JSON object.');
    throw Exception('SkSL bundle was invalid.');
  }

  // Step 3: Validate that:
  // * The engine revision the bundle was compiled with
  //   is the same as the current revision.
  // * The target platform is the same (this one is a warning only).
  final String bundleEngineRevision = bundle['engineRevision'] as String;
  if (bundleEngineRevision != engineRevision) {
    logger.printError(
      'The SkSL bundle was produced with a different engine revision. It must '
      'be recreated for the current Flutter version.'
    );
    throw Exception('SkSL bundle was invalid');
  }

  final TargetPlatform bundleTargetPlatform = getTargetPlatformForName(
    bundle['platform'] as String);
  if (bundleTargetPlatform != targetPlatform) {
    logger.printError(
      'The SkSL bundle was created for $bundleTargetPlatform, but the curent '
      'platform is $targetPlatform. This may lead to less efficient shader '
      'caching.'
    );
  }
  return (bundle['data'] as Map<String, Object>).cast<String, String>();
}

/// Copy the assets defined in the flutter manifest into a build directory.
class CopyAssets extends Target {
  const CopyAssets();

  @override
  String get name => 'copy_assets';

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
  ];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/assets.dart'),
    ...IconTreeShaker.inputs,
  ];

  @override
  List<Source> get outputs => const <Source>[];

  @override
  List<String> get depfiles => const <String>[
    'flutter_assets.d'
  ];

  @override
  Future<void> build(Environment environment) async {
    final Directory output = environment
      .buildDir
      .childDirectory('flutter_assets');
    output.createSync(recursive: true);
    final TargetPlatform targetPlatform = getTargetPlatformForName(
      environment.defines[kTargetPlatform]);
    final String skSLBundlePath = environment.inputs[kBundleSkSLPath];
    final Map<String, String> skSLBundle = processSkSLBundle(
      skSLBundlePath,
      engineRevision: globals.flutterVersion.engineRevision,
      fileSystem: environment.fileSystem,
      logger: environment.logger,
      targetPlatform: targetPlatform,
    );
    final Depfile depfile = await copyAssets(environment, output, skSLBundle: skSLBundle);
    if (skSLBundlePath != null) {
      final File skSLBundleFile = environment.fileSystem
        .file(skSLBundlePath).absolute;
      depfile.inputs.add(skSLBundleFile);
    }
    final DepfileService depfileService = DepfileService(
      fileSystem: globals.fs,
      logger: globals.logger,
      platform: globals.platform,
    );
    depfileService.writeToFile(
      depfile,
      environment.buildDir.childFile('flutter_assets.d'),
    );
  }
}
