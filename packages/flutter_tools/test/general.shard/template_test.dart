// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/template.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/template.dart';
import '../src/common.dart';
import '../src/context.dart';

void main() {
  testWithoutContext('Template constructor throws ToolExit when source directory is missing', () {
    final FileExceptionHandler handler = FileExceptionHandler();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test(opHandle: handler.opHandle);

    expect(() => Template(
      fileSystem.directory('doesNotExist'),
      fileSystem.currentDirectory,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      templateRenderer: FakeTemplateRenderer(),
    ), throwsToolExit());
  });

  testWithoutContext('Template.render throws ToolExit when FileSystem exception is raised', () {
    final FileExceptionHandler handler = FileExceptionHandler();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test(opHandle: handler.opHandle);
    final Template template = Template(
      fileSystem.directory('examples')..createSync(recursive: true),
      fileSystem.currentDirectory,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      templateRenderer: FakeTemplateRenderer(),
    );
    final Directory directory = fileSystem.directory('foo');
    handler.addError(directory, FileSystemOp.create, const FileSystemException());

    expect(() => template.render(directory, <String, Object>{}),
      throwsToolExit());
  });

  group('template image directory', () {
    late BufferLogger logger;
    late MemoryFileSystem fileSystem;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      logger = BufferLogger.test();
    });

    testUsingContext('templateImageDirectory returns parent template directory if passed null name', () async {
      final String packageConfigPath = fileSystem.path.join(
          Cache.flutterRoot!,
          'packages',
          'flutter_tools',
          '.dart_tool',
          'package_config.json',
      );

      fileSystem.file(packageConfigPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "flutter_template_images",
      "rootUri": "flutter_template_images",
      "packageUri": "lib/",
      "languageVersion": "2.12"
    }
  ]
}
''');
      expect(
          (await templateImageDirectory(null, fileSystem, logger)).path,
          fileSystem.path.join(
              Cache.flutterRoot!,
              'packages',
              'flutter_tools',
              '.dart_tool',
              'flutter_template_images',
              'templates',
          ),
      );
    });

    testUsingContext('templateImageDirectory returns the directory containing the `name` template directory', () async {
      final String packageConfigPath = fileSystem.path.join(
          Cache.flutterRoot!,
          'packages',
          'flutter_tools',
          '.dart_tool',
          'package_config.json',
      );
      fileSystem.file(packageConfigPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "flutter_template_images",
      "rootUri": "flutter_template_images",
      "packageUri": "lib/",
      "languageVersion": "2.12"
    }
  ]
}
''');
      expect(
        (await templateImageDirectory('app_shared', fileSystem, logger)).path,
        fileSystem.path.join(
            Cache.flutterRoot!,
            'packages',
            'flutter_tools',
            '.dart_tool',
            'flutter_template_images',
            'templates',
            'app_shared',
        ),
      );
    });
  });

  group('renders template', () {
    late Directory destination;
    const String imageName = 'some_image.png';
    late File sourceImage;
    late BufferLogger logger;
    late Template template;

    setUp(() {
      final MemoryFileSystem fileSystem = MemoryFileSystem.test();
      final Directory templateDir = fileSystem.directory('templates');
      final Directory imageSourceDir = fileSystem.directory('template_images');
      destination = fileSystem.directory('target');
      templateDir.childFile('$imageName.img.tmpl').createSync(recursive: true);
      sourceImage = imageSourceDir.childFile(imageName);
      sourceImage.createSync(recursive: true);
      sourceImage.writeAsStringSync("Ceci n'est pas une pipe");

      logger = BufferLogger.test();
      template = Template(
        templateDir,
        imageSourceDir,
        fileSystem: fileSystem,
        logger: logger,
        templateRenderer: FakeTemplateRenderer(),
      );
    });

    testWithoutContext('overwrites .img.tmpl files with files from the image source', () {
      expect(template.render(destination, <String, Object>{}), 1);

      final File destinationImage = destination.childFile(imageName);
      final Uint8List sourceImageBytes = sourceImage.readAsBytesSync();
      expect(destinationImage, exists);
      expect(destinationImage.readAsBytesSync(), equals(sourceImageBytes));

      expect(logger.errorText, isEmpty);
      expect(logger.statusText, contains('${destinationImage.path} (created)'));
      logger.clear();

      // Run it again to overwrite (returns 1 file updated).
      expect(template.render(destination, <String, Object>{}), 1);

      expect(destinationImage.readAsBytesSync(), equals(sourceImageBytes));
      expect(logger.errorText, isEmpty);
      expect(logger.statusText, contains('${destinationImage.path} (overwritten)'));
    });

    testWithoutContext('does not overwrite .img.tmpl files with files from the image source', () {
      expect(template.render(destination, <String, Object>{}), 1);

      final File destinationImage = destination.childFile(imageName);
      expect(destinationImage, exists);

      expect(logger.errorText, isEmpty);
      expect(logger.statusText, contains('${destinationImage.path} (created)'));
      logger.clear();

      // Run it again, do not overwrite (returns 0 files updated).
      expect(template.render(destination, <String, Object>{}, overwriteExisting: false), 0);

      expect(destinationImage, exists);
      expect(logger.errorText, isEmpty);
      expect(logger.statusText, isEmpty);
    });

    testWithoutContext('can suppress file printing', () {
      template.render(destination, <String, Object>{}, printStatusWhenWriting: false);

      final File destinationImage = destination.childFile(imageName);
      expect(destinationImage, exists);

      expect(logger.errorText, isEmpty);
      expect(logger.statusText, isEmpty);
    });
  });
}

class FakeTemplateRenderer extends TemplateRenderer {
  @override
  String renderString(String template, dynamic context, {bool htmlEscapeValues = false}) {
    return '';
  }
}
