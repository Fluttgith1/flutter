// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../artifacts.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import 'build_system.dart';
import 'exceptions.dart';

/// A set of source files.
abstract class ResolvedFiles {
  /// Whether any of the sources we evaluated contained a missing depfile.
  ///
  /// If so, the build system needs to rerun the visitor after executing the
  /// build to ensure all hashes are up to date.
  bool get containsNewDepfile;

  /// The resolved source files.
  List<File> get sources;
}

/// Collects sources for a [Target] into a single list of [FileSystemEntities].
class SourceVisitor implements ResolvedFiles {
  /// Create a new [SourceVisitor] from an [Environment].
  SourceVisitor(this.environment, [ this.inputs = true ]);

  /// The current environment.
  final Environment environment;

  /// Whether we are visiting inputs or outputs.
  ///
  /// Defaults to `true`.
  final bool inputs;

  @override
  final List<File> sources = <File>[];

  @override
  bool get containsNewDepfile => _containsNewDepfile;
  bool _containsNewDepfile = false;

  /// Visit a depfile which contains both input and output files.
  ///
  /// If the file is missing, this visitor is marked as [containsNewDepfile].
  /// This is used by the [Node] class to tell the [BuildSystem] to
  /// defer hash computation until after executing the target.
  // depfile logic adopted from https://github.com/flutter/flutter/blob/7065e4330624a5a216c8ffbace0a462617dc1bf5/dev/devicelab/lib/framework/apk_utils.dart#L390
  void visitDepfile(final String name) {
    final File depfile = environment.buildDir.childFile(name);
    if (!depfile.existsSync()) {
      _containsNewDepfile = true;
      return;
    }
    final String contents = depfile.readAsStringSync();
    final List<String> colonSeparated = contents.split(': ');
    if (colonSeparated.length != 2) {
      environment.logger.printError('Invalid depfile: ${depfile.path}');
      return;
    }
    if (inputs) {
      sources.addAll(_processList(colonSeparated[1].trim()));
    } else {
      sources.addAll(_processList(colonSeparated[0].trim()));
    }
  }

  final RegExp _separatorExpr = RegExp(r'([^\\]) ');
  final RegExp _escapeExpr = RegExp(r'\\(.)');

  Iterable<File> _processList(final String rawText) {
    return rawText
    // Put every file on right-hand side on the separate line
        .replaceAllMapped(_separatorExpr, (final Match match) => '${match.group(1)}\n')
        .split('\n')
    // Expand escape sequences, so that '\ ', for example,ß becomes ' '
        .map<String>((final String path) => path.replaceAllMapped(_escapeExpr, (final Match match) => match.group(1)!).trim())
        .where((final String path) => path.isNotEmpty)
        .toSet()
        .map(environment.fileSystem.file);
  }

  /// Visit a [Source] which contains a file URL.
  ///
  /// The URL may include constants defined in an [Environment]. If
  /// [optional] is true, the file is not required to exist. In this case, it
  /// is never resolved as an input.
  void visitPattern(final String pattern, final bool optional) {
    // perform substitution of the environmental values and then
    // of the local values.
    final List<String> segments = <String>[];
    final List<String> rawParts = pattern.split('/');
    final bool hasWildcard = rawParts.last.contains('*');
    String? wildcardFile;
    if (hasWildcard) {
      wildcardFile = rawParts.removeLast();
    }
    // If the pattern does not start with an env variable, then we have nothing
    // to resolve it to, error out.
    switch (rawParts.first) {
      case Environment.kProjectDirectory:
        segments.addAll(
          environment.fileSystem.path.split(environment.projectDir.resolveSymbolicLinksSync()));
      case Environment.kBuildDirectory:
        segments.addAll(environment.fileSystem.path.split(
          environment.buildDir.resolveSymbolicLinksSync()));
      case Environment.kCacheDirectory:
        segments.addAll(
          environment.fileSystem.path.split(environment.cacheDir.resolveSymbolicLinksSync()));
      case Environment.kFlutterRootDirectory:
        // flutter root will not contain a symbolic link.
        segments.addAll(
          environment.fileSystem.path.split(environment.flutterRootDir.absolute.path));
      case Environment.kOutputDirectory:
        segments.addAll(
          environment.fileSystem.path.split(environment.outputDir.resolveSymbolicLinksSync()));
      default:
        throw InvalidPatternException(pattern);
    }
    rawParts.skip(1).forEach(segments.add);
    final String filePath = environment.fileSystem.path.joinAll(segments);
    if (!hasWildcard) {
      if (optional && !environment.fileSystem.isFileSync(filePath)) {
        return;
      }
      sources.add(environment.fileSystem.file(
        environment.fileSystem.path.normalize(filePath)));
      return;
    }
    // Perform a simple match by splitting the wildcard containing file one
    // the `*`. For example, for `/*.dart`, we get [.dart]. We then check
    // that part of the file matches. If there are values before and after
    // the `*` we need to check that both match without overlapping. For
    // example, `foo_*_.dart`. We want to match `foo_b_.dart` but not
    // `foo_.dart`. To do so, we first subtract the first section from the
    // string if the first segment matches.
    final List<String> wildcardSegments = wildcardFile?.split('*') ?? <String>[];
    if (wildcardSegments.length > 2) {
      throw InvalidPatternException(pattern);
    }
    if (!environment.fileSystem.directory(filePath).existsSync()) {
      environment.fileSystem.directory(filePath).createSync(recursive: true);
    }
    for (final FileSystemEntity entity in environment.fileSystem.directory(filePath).listSync()) {
      final String filename = environment.fileSystem.path.basename(entity.path);
      if (wildcardSegments.isEmpty) {
        sources.add(environment.fileSystem.file(entity.absolute));
      } else if (wildcardSegments.length == 1) {
        if (filename.startsWith(wildcardSegments[0]) ||
            filename.endsWith(wildcardSegments[0])) {
          sources.add(environment.fileSystem.file(entity.absolute));
        }
      } else if (filename.startsWith(wildcardSegments[0])) {
        if (filename.substring(wildcardSegments[0].length).endsWith(wildcardSegments[1])) {
          sources.add(environment.fileSystem.file(entity.absolute));
        }
      }
    }
  }

  /// Visit a [Source] which is defined by an [Artifact] from the flutter cache.
  ///
  /// If the [Artifact] points to a directory then all child files are included.
  /// To increase the performance of builds that use a known revision of Flutter,
  /// these are updated to point towards the engine.version file instead of
  /// the artifact itself.
  void visitArtifact(final Artifact artifact, final TargetPlatform? platform, final BuildMode? mode) {
    // This is not a local engine.
    if (environment.engineVersion != null) {
      sources.add(environment.flutterRootDir
        .childDirectory('bin')
        .childDirectory('internal')
        .childFile('engine.version'),
      );
      return;
    }
    final String path = environment.artifacts
      .getArtifactPath(artifact, platform: platform, mode: mode);
    if (environment.fileSystem.isDirectorySync(path)) {
      sources.addAll(<File>[
        for (FileSystemEntity entity in environment.fileSystem.directory(path).listSync(recursive: true))
          if (entity is File)
            entity,
      ]);
      return;
    }
    sources.add(environment.fileSystem.file(path));
  }

  /// Visit a [Source] which is defined by an [HostArtifact] from the flutter cache.
  ///
  /// If the [Artifact] points to a directory then all child files are included.
  /// To increase the performance of builds that use a known revision of Flutter,
  /// these are updated to point towards the engine.version file instead of
  /// the artifact itself.
  void visitHostArtifact(final HostArtifact artifact) {
    // This is not a local engine.
    if (environment.engineVersion != null) {
      sources.add(environment.flutterRootDir
        .childDirectory('bin')
        .childDirectory('internal')
        .childFile('engine.version'),
      );
      return;
    }
    final FileSystemEntity entity = environment.artifacts.getHostArtifact(artifact);
    if (entity is Directory) {
      sources.addAll(<File>[
        for (FileSystemEntity entity in entity.listSync(recursive: true))
          if (entity is File)
            entity,
      ]);
      return;
    }
    sources.add(entity as File);
  }
}

/// A description of an input or output of a [Target].
abstract class Source {
  /// This source is a file URL which contains some references to magic
  /// environment variables.
  const factory Source.pattern(final String pattern, { final bool optional }) = _PatternSource;

  /// The source is provided by an [Artifact].
  ///
  /// If [artifact] points to a directory then all child files are included.
  const factory Source.artifact(final Artifact artifact, {final TargetPlatform? platform, final BuildMode? mode}) = _ArtifactSource;

  /// The source is provided by an [HostArtifact].
  ///
  /// If [artifact] points to a directory then all child files are included.
  const factory Source.hostArtifact(final HostArtifact artifact) = _HostArtifactSource;

  /// Visit the particular source type.
  void accept(final SourceVisitor visitor);

  /// Whether the output source provided can be known before executing the rule.
  ///
  /// This does not apply to inputs, which are always explicit and must be
  /// evaluated before the build.
  ///
  /// For example, [Source.pattern] and [Source.version] are not implicit
  /// provided they do not use any wildcards.
  bool get implicit;
}

class _PatternSource implements Source {
  const _PatternSource(this.value, { this.optional = false });

  final String value;
  final bool optional;

  @override
  void accept(final SourceVisitor visitor) => visitor.visitPattern(value, optional);

  @override
  bool get implicit => value.contains('*');
}

class _ArtifactSource implements Source {
  const _ArtifactSource(this.artifact, { this.platform, this.mode });

  final Artifact artifact;
  final TargetPlatform? platform;
  final BuildMode? mode;

  @override
  void accept(final SourceVisitor visitor) => visitor.visitArtifact(artifact, platform, mode);

  @override
  bool get implicit => false;
}

class _HostArtifactSource implements Source {
  const _HostArtifactSource(this.artifact);

  final HostArtifact artifact;

  @override
  void accept(final SourceVisitor visitor) => visitor.visitHostArtifact(artifact);

  @override
  bool get implicit => false;
}
