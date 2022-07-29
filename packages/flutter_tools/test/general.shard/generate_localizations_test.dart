// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/localizations/gen_l10n.dart';
import 'package:flutter_tools/src/localizations/gen_l10n_types.dart';
import 'package:flutter_tools/src/localizations/localizations_utils.dart';
import 'package:yaml/yaml.dart';

import '../src/common.dart';
import '../src/context.dart';

const String defaultTemplateArbFileName = 'app_en.arb';
const String defaultOutputFileString = 'output-localization-file.dart';
const String defaultClassNameString = 'AppLocalizations';
const String singleMessageArbFileString = '''
{
  "title": "Title",
  "@title": {
    "description": "Title for the application."
  }
}''';
const String twoMessageArbFileString = '''
{
  "title": "Title",
  "@title": {
    "description": "Title for the application."
  },
  "subtitle": "Subtitle",
  "@subtitle": {
    "description": "Subtitle for the application."
  }
}''';
const String esArbFileName = 'app_es.arb';
const String singleEsMessageArbFileString = '''
{
  "title": "Título"
}''';
const String singleZhMessageArbFileString = '''
{
  "title": "标题"
}''';
const String intlImportDartCode = '''
import 'package:intl/intl.dart' as intl;
''';
const String foundationImportDartCode = '''
import 'package:flutter/foundation.dart';
''';

void _standardFlutterDirectoryL10nSetup(FileSystem fs) {
  final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
    ..createSync(recursive: true);
  l10nDirectory.childFile(defaultTemplateArbFileName)
    .writeAsStringSync(singleMessageArbFileString);
  l10nDirectory.childFile(esArbFileName)
    .writeAsStringSync(singleEsMessageArbFileString);
}

void main() {
  late MemoryFileSystem fs;
  late BufferLogger logger;
  late String defaultL10nPathString;
  late String syntheticPackagePath;
  late String syntheticL10nPackagePath;

  setUp(() {
    fs = MemoryFileSystem.test();
    logger = BufferLogger.test();

    defaultL10nPathString = fs.path.join('lib', 'l10n');
    syntheticPackagePath = fs.path.join('.dart_tool', 'flutter_gen');
    syntheticL10nPackagePath = fs.path.join(syntheticPackagePath, 'gen_l10n');
    precacheLanguageAndRegionTags();
  });

  group('Setters', () {
    testWithoutContext('setInputDirectory fails if the directory does not exist', () {
      expect(
        () => LocalizationsGenerator.inputDirectoryFromPath(fs, 'lib', fs.directory('bogus')),
        throwsA(isA<L10nException>().having(
          (L10nException e) => e.message,
          'message',
          contains('Make sure that the correct path was provided'),
        )),
      );
    });

    testWithoutContext('setting className fails if input string is empty', () {
      _standardFlutterDirectoryL10nSetup(fs);
      expect(
        () => LocalizationsGenerator.classNameFromString(''),
        throwsA(isA<L10nException>().having(
          (L10nException e) => e.message,
          'message',
          contains('cannot be empty'),
        )),
      );
    });

    testUsingContext('sets absolute path of the target Flutter project', () async {
      // Set up project directory.
      final Directory l10nDirectory = fs.currentDirectory
        .childDirectory('absolute')
        .childDirectory('path')
        .childDirectory('to')
        .childDirectory('flutter_project')
        .childDirectory('lib')
        .childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile(defaultTemplateArbFileName)
        .writeAsStringSync(singleMessageArbFileString);
      l10nDirectory.childFile(esArbFileName)
        .writeAsStringSync(singleEsMessageArbFileString);

      // Run localizations generator in specified absolute path.
      final String flutterProjectPath = fs.path.join('absolute', 'path', 'to', 'flutter_project');
      await LocalizationsGenerator(
        fileSystem: fs,
        projectPathString: flutterProjectPath,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        logger: logger,
      ).generate();

      // Output files should be generated in the provided absolute path.
      expect(
        fs.isFileSync(fs.path.join(
          flutterProjectPath,
          '.dart_tool',
          'flutter_gen',
          'gen_l10n',
          'output-localization-file_en.dart',
        )),
        true,
      );
      expect(
        fs.isFileSync(fs.path.join(
          flutterProjectPath,
          '.dart_tool',
          'flutter_gen',
          'gen_l10n',
          'output-localization-file_es.dart',
        )),
        true,
      );
    });

    testWithoutContext('throws error when directory at absolute path does not exist', () {
      // Set up project directory.
      final Directory l10nDirectory = fs.currentDirectory
        .childDirectory('lib')
        .childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile(defaultTemplateArbFileName)
        .writeAsStringSync(singleMessageArbFileString);
      l10nDirectory.childFile(esArbFileName)
        .writeAsStringSync(singleEsMessageArbFileString);

      // Project path should be intentionally a directory that does not exist.
      expect(
        () => LocalizationsGenerator(
          fileSystem: fs,
          projectPathString: 'absolute/path/to/flutter_project',
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
          logger: logger,
        ),
        throwsA(isA<L10nException>().having(
          (L10nException e) => e.message,
          'message',
          contains('Directory does not exist'),
        )),
      );
    });

    testWithoutContext('throws error when arb file does not exist', () {
      // Set up project directory.
      fs.currentDirectory
        .childDirectory('lib')
        .childDirectory('l10n')
        .createSync(recursive: true);

      // Arb file should be nonexistent in the l10n directory.
      expect(
        () => LocalizationsGenerator(
          fileSystem: fs,
          projectPathString: './',
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
          logger: logger,
        ),
        throwsA(isA<L10nException>().having(
          (L10nException e) => e.message,
          'message',
          contains(', does not exist.'),
        )),
      );
    });

    group('className should only take valid Dart class names', () {
      setUp(() {
        _standardFlutterDirectoryL10nSetup(fs);
      });

      testWithoutContext('fails on string with spaces', () {
        expect(
          () => LocalizationsGenerator.classNameFromString('String with spaces'),
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('is not a valid public Dart class name'),
          )),
        );
      });

      testWithoutContext('fails on non-alphanumeric symbols', () {
        expect(
          () => LocalizationsGenerator.classNameFromString('TestClass@123'),
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('is not a valid public Dart class name'),
          )),
        );
      });

      testWithoutContext('fails on camel-case', () {
        expect(
          () => LocalizationsGenerator.classNameFromString('camelCaseClassName'),
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('is not a valid public Dart class name'),
          )),
        );
      });

      testWithoutContext('fails when starting with a number', () {
        expect(
          () => LocalizationsGenerator.classNameFromString('123ClassName'),
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('is not a valid public Dart class name'),
          )),
        );
      });
    });
  });

  testWithoutContext('correctly adds a headerString when it is set', () {
    _standardFlutterDirectoryL10nSetup(fs);

    final LocalizationsGenerator generator = LocalizationsGenerator(
      fileSystem: fs,
      inputPathString: defaultL10nPathString,
      outputPathString: defaultL10nPathString,
      templateArbFileName: defaultTemplateArbFileName,
      outputFileString: defaultOutputFileString,
      classNameString: defaultClassNameString,
      headerString: '/// Sample header',
      logger: logger,
    );

    expect(generator.header, '/// Sample header');
  });

  testWithoutContext('correctly adds a headerFile when it is set', () {
    fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
      ..createSync(recursive: true)
      ..childFile(defaultTemplateArbFileName).writeAsStringSync(singleMessageArbFileString)
      ..childFile(esArbFileName).writeAsStringSync(singleEsMessageArbFileString)
      ..childFile('header.txt').writeAsStringSync('/// Sample header in a text file');

    final LocalizationsGenerator generator = LocalizationsGenerator(
      fileSystem: fs,
      inputPathString: defaultL10nPathString,
      outputPathString: defaultL10nPathString,
      templateArbFileName: defaultTemplateArbFileName,
      outputFileString: defaultOutputFileString,
      classNameString: defaultClassNameString,
      headerFile: 'header.txt',
      logger: logger,
    );

    expect(generator.header, '/// Sample header in a text file');
  });

  testUsingContext('sets templateArbFileName with more than one underscore correctly', () async {
    final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
      ..createSync(recursive: true);
    l10nDirectory.childFile('app_localizations_en.arb')
      .writeAsStringSync(singleMessageArbFileString);
    l10nDirectory.childFile('app_localizations_es.arb')
      .writeAsStringSync(singleEsMessageArbFileString);
    await LocalizationsGenerator(
      fileSystem: fs,
      inputPathString: defaultL10nPathString,
      templateArbFileName: 'app_localizations_en.arb',
      outputFileString: defaultOutputFileString,
      classNameString: defaultClassNameString,
      logger: logger,
    ).generate();

    final Directory outputDirectory = fs.directory(syntheticL10nPackagePath);
    expect(outputDirectory.childFile('output-localization-file.dart').existsSync(), isTrue);
    expect(outputDirectory.childFile('output-localization-file_en.dart').existsSync(), isTrue);
    expect(outputDirectory.childFile('output-localization-file_es.dart').existsSync(), isTrue);
  });

  testUsingContext('filenames with invalid locales should not be recognized', () {
    final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
      ..createSync(recursive: true);
    l10nDirectory.childFile('app_localizations_en.arb')
      .writeAsStringSync(singleMessageArbFileString);
    l10nDirectory.childFile('app_localizations_en_CA_foo.arb')
      .writeAsStringSync(singleMessageArbFileString);
    expect(
      () {
        LocalizationsGenerator(
          fileSystem: fs,
          inputPathString: defaultL10nPathString,
          templateArbFileName: 'app_localizations_en.arb',
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
          logger: logger,
        ).loadResources();
      },
      throwsA(isA<L10nException>().having(
        (L10nException e) => e.message,
        'message',
        contains("The following .arb file's locale could not be determined"),
      )),
    );
  });

  testUsingContext('correctly creates an untranslated messages file (useSyntheticPackage = true)', () async {
    fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
      ..createSync(recursive: true)
      ..childFile(defaultTemplateArbFileName).writeAsStringSync(twoMessageArbFileString)
      ..childFile(esArbFileName).writeAsStringSync(singleEsMessageArbFileString);

    await LocalizationsGenerator(
      fileSystem: fs,
      inputPathString: defaultL10nPathString,
      outputPathString: defaultL10nPathString,
      templateArbFileName: defaultTemplateArbFileName,
      outputFileString: defaultOutputFileString,
      classNameString: defaultClassNameString,
      untranslatedMessagesFile: fs.path.join('lib', 'l10n', 'unimplemented_message_translations.json'),
      logger: logger,
    ).generate();

    final File unimplementedOutputFile = fs.file(
      fs.path.join('lib', 'l10n', 'unimplemented_message_translations.json'),
    );
    final String unimplementedOutputString = unimplementedOutputFile.readAsStringSync();
    try {
      // Since ARB file is essentially JSON, decoding it should not fail.
      json.decode(unimplementedOutputString);
    } on Exception {
      fail('Parsing arb file should not fail');
    }
    expect(unimplementedOutputString, contains('es'));
    expect(unimplementedOutputString, contains('subtitle'));
  });

  testUsingContext('correctly creates an untranslated messages file (useSyntheticPackage = false)', () async {
    fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
      ..createSync(recursive: true)
      ..childFile(defaultTemplateArbFileName).writeAsStringSync(twoMessageArbFileString)
      ..childFile(esArbFileName).writeAsStringSync(singleEsMessageArbFileString);

    await LocalizationsGenerator(
      fileSystem: fs,
      inputPathString: defaultL10nPathString,
      outputPathString: defaultL10nPathString,
      templateArbFileName: defaultTemplateArbFileName,
      outputFileString: defaultOutputFileString,
      classNameString: defaultClassNameString,
      useSyntheticPackage: false,
      untranslatedMessagesFile: fs.path.join('lib', 'l10n', 'unimplemented_message_translations.json'),
      logger: logger,
    ).generate();

    final File unimplementedOutputFile = fs.file(
      fs.path.join('lib', 'l10n', 'unimplemented_message_translations.json'),
    );
    final String unimplementedOutputString = unimplementedOutputFile.readAsStringSync();
    try {
      // Since ARB file is essentially JSON, decoding it should not fail.
      json.decode(unimplementedOutputString);
    } on Exception {
      fail('Parsing arb file should not fail');
    }
    expect(unimplementedOutputString, contains('es'));
    expect(unimplementedOutputString, contains('subtitle'));
  });

  testUsingContext(
    'untranslated messages suggestion is printed when translation is missing: '
    'command line message',
    () async {
      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true)
        ..childFile(defaultTemplateArbFileName).writeAsStringSync(twoMessageArbFileString)
        ..childFile(esArbFileName).writeAsStringSync(singleEsMessageArbFileString);

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        useSyntheticPackage: false,
        logger: logger,
      ).generate();

      expect(
        logger.statusText,
        contains('To see a detailed report, use the --untranslated-messages-file'),
      );
      expect(
        logger.statusText,
        contains('flutter gen-l10n --untranslated-messages-file=desiredFileName.txt'),
      );
    },
  );

  testUsingContext(
    'untranslated messages suggestion is printed when translation is missing: '
    'l10n.yaml message',
    () async {
      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true)
        ..childFile(defaultTemplateArbFileName).writeAsStringSync(twoMessageArbFileString)
        ..childFile(esArbFileName).writeAsStringSync(singleEsMessageArbFileString);

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        logger: logger,
      ).generate(isFromYaml: true);

      expect(
        logger.statusText,
        contains('To see a detailed report, use the untranslated-messages-file'),
      );
      expect(
        logger.statusText,
        contains('untranslated-messages-file: desiredFileName.txt'),
      );
    },
  );

  testUsingContext(
    'unimplemented messages suggestion is not printed when all messages '
    'are fully translated',
    () async {
      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true)
        ..childFile(defaultTemplateArbFileName).writeAsStringSync(twoMessageArbFileString)
        ..childFile(esArbFileName).writeAsStringSync(twoMessageArbFileString);

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        logger: logger,
      ).generate();

      expect(logger.statusText, '');
    },
  );

  testUsingContext('untranslated messages file included in generated JSON list of outputs', () async {
    _standardFlutterDirectoryL10nSetup(fs);

    await LocalizationsGenerator(
      fileSystem: fs,
      inputPathString: defaultL10nPathString,
      templateArbFileName: defaultTemplateArbFileName,
      outputFileString: defaultOutputFileString,
      classNameString: defaultClassNameString,
      inputsAndOutputsListPath: syntheticL10nPackagePath,
      untranslatedMessagesFile: fs.path.join('lib', 'l10n', 'unimplemented_message_translations.json'),
      logger: logger,
    ).generate();

    final File inputsAndOutputsList = fs.file(
      fs.path.join(syntheticL10nPackagePath, 'gen_l10n_inputs_and_outputs.json'),
    );
    expect(inputsAndOutputsList.existsSync(), isTrue);
    final Map<String, dynamic> jsonResult = json.decode(
      inputsAndOutputsList.readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(jsonResult.containsKey('outputs'), isTrue);
    final List<dynamic> outputList = jsonResult['outputs'] as List<dynamic>;
    expect(outputList, contains(contains('unimplemented_message_translations.json')));
  });

  testUsingContext(
    'uses inputPathString as outputPathString when the outputPathString is '
    'null while not using the synthetic package option',
    () async {
      _standardFlutterDirectoryL10nSetup(fs);
      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        // outputPathString is intentionally not defined
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        useSyntheticPackage: false,
        logger: logger,
      ).generate();

      final Directory outputDirectory = fs.directory('lib').childDirectory('l10n');
      expect(outputDirectory.childFile('output-localization-file.dart').existsSync(), isTrue);
      expect(outputDirectory.childFile('output-localization-file_en.dart').existsSync(), isTrue);
      expect(outputDirectory.childFile('output-localization-file_es.dart').existsSync(), isTrue);
    },
  );

  testUsingContext(
    'correctly generates output files in non-default output directory if it '
    'already exists while not using the synthetic package option',
    () async {
      final Directory l10nDirectory = fs.currentDirectory
        .childDirectory('lib')
        .childDirectory('l10n')
        ..createSync(recursive: true);
      // Create the directory 'lib/l10n/output'.
      l10nDirectory.childDirectory('output');

      l10nDirectory
        .childFile(defaultTemplateArbFileName)
        .writeAsStringSync(singleMessageArbFileString);
      l10nDirectory
        .childFile(esArbFileName)
        .writeAsStringSync(singleEsMessageArbFileString);

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: fs.path.join('lib', 'l10n', 'output'),
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        useSyntheticPackage: false,
        logger: logger,
      ).generate();

      final Directory outputDirectory = fs.directory('lib').childDirectory('l10n').childDirectory('output');
      expect(outputDirectory.existsSync(), isTrue);
      expect(outputDirectory.childFile('output-localization-file.dart').existsSync(), isTrue);
      expect(outputDirectory.childFile('output-localization-file_en.dart').existsSync(), isTrue);
      expect(outputDirectory.childFile('output-localization-file_es.dart').existsSync(), isTrue);
    },
  );

  testUsingContext(
    'correctly creates output directory if it does not exist and writes files '
    'in it while not using the synthetic package option',
    () async {
      _standardFlutterDirectoryL10nSetup(fs);

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: fs.path.join('lib', 'l10n', 'output'),
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        useSyntheticPackage: false,
        logger: logger,
      ).generate();

      final Directory outputDirectory = fs.directory('lib').childDirectory('l10n').childDirectory('output');
      expect(outputDirectory.existsSync(), isTrue);
      expect(outputDirectory.childFile('output-localization-file.dart').existsSync(), isTrue);
      expect(outputDirectory.childFile('output-localization-file_en.dart').existsSync(), isTrue);
      expect(outputDirectory.childFile('output-localization-file_es.dart').existsSync(), isTrue);
    },
  );

  testUsingContext(
    'generates nullable localizations class getter via static `of` method '
    'by default',
    () async {
      _standardFlutterDirectoryL10nSetup(fs);

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: fs.path.join('lib', 'l10n', 'output'),
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        useSyntheticPackage: false,
        logger: logger,
      ).generate();

      final Directory outputDirectory = fs.directory('lib').childDirectory('l10n').childDirectory('output');
      expect(outputDirectory.existsSync(), isTrue);
      expect(outputDirectory.childFile('output-localization-file.dart').existsSync(), isTrue);
      expect(
        outputDirectory.childFile('output-localization-file.dart').readAsStringSync(),
        contains('static AppLocalizations? of(BuildContext context)'),
      );
      expect(
        outputDirectory.childFile('output-localization-file.dart').readAsStringSync(),
        contains('return Localizations.of<AppLocalizations>(context, AppLocalizations);'),
      );
    },
  );

  testUsingContext(
    'can generate non-nullable localizations class getter via static `of` method ',
    () async {
      _standardFlutterDirectoryL10nSetup(fs);

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: fs.path.join('lib', 'l10n', 'output'),
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        useSyntheticPackage: false,
        usesNullableGetter: false,
        logger: logger,
      ).generate();

      final Directory outputDirectory = fs.directory('lib').childDirectory('l10n').childDirectory('output');
      expect(outputDirectory.existsSync(), isTrue);
      expect(outputDirectory.childFile('output-localization-file.dart').existsSync(), isTrue);
      expect(
        outputDirectory.childFile('output-localization-file.dart').readAsStringSync(),
        contains('static AppLocalizations of(BuildContext context)'),
      );
      expect(
        outputDirectory.childFile('output-localization-file.dart').readAsStringSync(),
        contains('return Localizations.of<AppLocalizations>(context, AppLocalizations)!;'),
      );
    },
  );

  testUsingContext('creates list of inputs and outputs when file path is specified', () async {
    _standardFlutterDirectoryL10nSetup(fs);

    await LocalizationsGenerator(
      fileSystem: fs,
      inputPathString: defaultL10nPathString,
      templateArbFileName: defaultTemplateArbFileName,
      outputFileString: defaultOutputFileString,
      classNameString: defaultClassNameString,
      inputsAndOutputsListPath: syntheticL10nPackagePath,
      logger: logger,
    ).generate();

    final File inputsAndOutputsList = fs.file(
      fs.path.join(syntheticL10nPackagePath, 'gen_l10n_inputs_and_outputs.json'),
    );
    expect(inputsAndOutputsList.existsSync(), isTrue);

    final Map<String, dynamic> jsonResult = json.decode(inputsAndOutputsList.readAsStringSync()) as Map<String, dynamic>;
    expect(jsonResult.containsKey('inputs'), isTrue);
    final List<dynamic> inputList = jsonResult['inputs'] as List<dynamic>;
    expect(inputList, contains(fs.path.absolute('lib', 'l10n', 'app_en.arb')));
    expect(inputList, contains(fs.path.absolute('lib', 'l10n', 'app_es.arb')));

    expect(jsonResult.containsKey('outputs'), isTrue);
    final List<dynamic> outputList = jsonResult['outputs'] as List<dynamic>;
    expect(outputList, contains(fs.path.absolute(syntheticL10nPackagePath, 'output-localization-file.dart')));
    expect(outputList, contains(fs.path.absolute(syntheticL10nPackagePath, 'output-localization-file_en.dart')));
    expect(outputList, contains(fs.path.absolute(syntheticL10nPackagePath, 'output-localization-file_es.dart')));
  });

  testWithoutContext('setting both a headerString and a headerFile should fail', () {
    fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
      ..createSync(recursive: true)
      ..childFile(defaultTemplateArbFileName).writeAsStringSync(singleMessageArbFileString)
      ..childFile(esArbFileName).writeAsStringSync(singleEsMessageArbFileString)
      ..childFile('header.txt').writeAsStringSync('/// Sample header in a text file');

    expect(
      () {
        LocalizationsGenerator(
          fileSystem: fs,
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
          headerString: '/// Sample header for localizations file.',
          headerFile: 'header.txt',
          logger: logger,
        );
      },
      throwsA(isA<L10nException>().having(
        (L10nException e) => e.message,
        'message',
        contains('Cannot accept both header and header file arguments'),
      )),
    );
  });

  testWithoutContext('setting a headerFile that does not exist should fail', () {
    final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
      ..createSync(recursive: true);
    l10nDirectory.childFile(defaultTemplateArbFileName)
      .writeAsStringSync(singleMessageArbFileString);
    l10nDirectory.childFile(esArbFileName)
      .writeAsStringSync(singleEsMessageArbFileString);
    l10nDirectory.childFile('header.txt')
      .writeAsStringSync('/// Sample header in a text file');

    expect(
      () {
        LocalizationsGenerator(
          fileSystem: fs,
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
          headerFile: 'header.tx', // Intentionally spelled incorrectly
          logger: logger,
        );
      },
      throwsA(isA<L10nException>().having(
        (L10nException e) => e.message,
        'message',
        contains('Failed to read header file'),
      )),
    );
  });

  group('generateLocalizations', () {
    testUsingContext('forwards arguments correctly', () async {
      _standardFlutterDirectoryL10nSetup(fs);
      final LocalizationOptions options = LocalizationOptions(
        header: 'HEADER',
        arbDirectory: Uri.directory(defaultL10nPathString),
        deferredLoading: true,
        outputClass: 'Foo',
        outputLocalizationsFile: Uri.file('bar.dart', windows: false),
        outputDirectory: Uri.directory(defaultL10nPathString, windows: false),
        preferredSupportedLocales: <String>['es'],
        templateArbFile: Uri.file(defaultTemplateArbFileName, windows: false),
        untranslatedMessagesFile: Uri.file('untranslated', windows: false),
        useSyntheticPackage: false,
        areResourceAttributesRequired: true,
        usesNullableGetter: false,
      );

      // Verify that values are correctly passed through the localizations target.
      final LocalizationsGenerator generator = await generateLocalizations(
        fileSystem: fs,
        options: options,
        logger: logger,
        projectDir: fs.currentDirectory,
        dependenciesDir: fs.currentDirectory,
      );

      expect(generator.inputDirectory.path, '/lib/l10n/');
      expect(generator.outputDirectory.path, '/lib/l10n/');
      expect(generator.templateArbFile.path, '/lib/l10n/app_en.arb');
      expect(generator.baseOutputFile.path, '/lib/l10n/bar.dart');
      expect(generator.className, 'Foo');
      expect(generator.preferredSupportedLocales.single, LocaleInfo.fromString('es'));
      expect(generator.header, 'HEADER');
      expect(generator.useDeferredLoading, isTrue);
      expect(generator.inputsAndOutputsListFile?.path, '/gen_l10n_inputs_and_outputs.json');
      expect(generator.useSyntheticPackage, isFalse);
      expect(generator.projectDirectory?.path, '/');
      expect(generator.areResourceAttributesRequired, isTrue);
      expect(generator.untranslatedMessagesFile?.path, 'untranslated');
      expect(generator.usesNullableGetter, isFalse);

      // Just validate one file.
      expect(fs.file('/lib/l10n/bar_en.dart').readAsStringSync(), '''
HEADER

import 'bar.dart';

/// The translations for English (`en`).
class FooEn extends Foo {
  FooEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Title';
}
''');
    });

    testUsingContext('throws exception on missing flutter: generate: true flag', () async {
      _standardFlutterDirectoryL10nSetup(fs);

      // Missing flutter: generate: true should throw exception.
      fs.file(fs.path.join(syntheticPackagePath, 'pubspec.yaml'))
        ..createSync(recursive: true)
        ..writeAsStringSync('''
flutter:
  uses-material-design: true
''');

      final LocalizationOptions options = LocalizationOptions(
        header: 'HEADER',
        headerFile: Uri.file('header', windows: false),
        arbDirectory: Uri.file('arb', windows: false),
        deferredLoading: true,
        outputClass: 'Foo',
        outputLocalizationsFile: Uri.file('bar', windows: false),
        preferredSupportedLocales: <String>['en_US'],
        templateArbFile: Uri.file('example.arb', windows: false),
        untranslatedMessagesFile: Uri.file('untranslated', windows: false),
      );

      expect(
        () => generateLocalizations(
          fileSystem: fs,
          options: options,
          logger: BufferLogger.test(),
          projectDir: fs.currentDirectory,
          dependenciesDir: fs.currentDirectory,
        ),
        throwsToolExit(
          message: 'Attempted to generate localizations code without having the '
              'flutter: generate flag turned on.',
        ),
      );
    });

    testUsingContext('blank lines generated nicely', () async {
      _standardFlutterDirectoryL10nSetup(fs);

      // Test without headers.
      await generateLocalizations(
        fileSystem: fs,
        options: LocalizationOptions(
          arbDirectory: Uri.directory(defaultL10nPathString),
          outputDirectory: Uri.directory(defaultL10nPathString, windows: false),
          templateArbFile: Uri.file(defaultTemplateArbFileName, windows: false),
          useSyntheticPackage: false,
        ),
        logger: BufferLogger.test(),
        projectDir: fs.currentDirectory,
        dependenciesDir: fs.currentDirectory,
      );

      expect(fs.file('/lib/l10n/app_localizations_en.dart').readAsStringSync(), '''
import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Title';
}
''');

    // Test with headers.
    await generateLocalizations(
      fileSystem: fs,
      options: LocalizationOptions(
        header: 'HEADER',
        arbDirectory: Uri.directory(defaultL10nPathString),
        outputDirectory: Uri.directory(defaultL10nPathString, windows: false),
        templateArbFile: Uri.file(defaultTemplateArbFileName, windows: false),
        useSyntheticPackage: false,
      ),
      logger: logger,
      projectDir: fs.currentDirectory,
      dependenciesDir: fs.currentDirectory,
    );

    expect(fs.file('/lib/l10n/app_localizations_en.dart').readAsStringSync(), '''
HEADER

import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Title';
}
''');
    });

    testUsingContext('files well formatted', () async {
      // Use a physical file system to make generated files format-able.
      final FileSystem fs = globals.fs;
      final Directory projectDir = fs.systemTempDirectory.createTempSync(
        'flutter_tools_generate_localizations_test.',
      );
      final String l10nPathString = fs.path.join(projectDir.path, 'lib', 'l10n');
      final Directory l10nDirectory = fs.directory(l10nPathString);
      l10nDirectory
        ..createSync(recursive: true)
        ..childFile(defaultTemplateArbFileName).writeAsStringSync(singleMessageArbFileString)
        ..childFile(esArbFileName).writeAsStringSync(singleEsMessageArbFileString);

      // Test without headers.
      await generateLocalizations(
        fileSystem: fs,
        options: LocalizationOptions(
          arbDirectory: Uri.directory(l10nPathString),
          outputDirectory: Uri.directory(l10nPathString, windows: false),
          templateArbFile: Uri.file(defaultTemplateArbFileName, windows: false),
          useSyntheticPackage: false,
        ),
        logger: BufferLogger.test(),
        projectDir: projectDir,
        dependenciesDir: projectDir,
      );

      for (final FileSystemEntity file in l10nDirectory.listSync()) {
        if (file is File && file.basename.endsWith('.dart')) {
          final String original = file.readAsStringSync();
          final Process process = await Process.start(
            globals.artifacts!.getHostArtifact(HostArtifact.engineDartBinary).path,
            <String>['format', '--output=show', file.path],
            workingDirectory: l10nDirectory.path,
          );
          final String formatted = await process.stdout.transform(utf8.decoder).join();
          expect(formatted, contains(original), reason: file.path);
        }
      }
    });
  });

  group('loadResources', () {
    testUsingContext('correctly initializes supportedLocales and supportedLanguageCodes properties', () {
      _standardFlutterDirectoryL10nSetup(fs);

      final LocalizationsGenerator generator = LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        logger: logger,
      )..loadResources();

      expect(generator.supportedLocales.contains(LocaleInfo.fromString('en')), true);
      expect(generator.supportedLocales.contains(LocaleInfo.fromString('es')), true);
    });

    testWithoutContext('correctly sorts supportedLocales and supportedLanguageCodes alphabetically', () {
      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      // Write files in non-alphabetical order so that read performs in that order
      l10nDirectory.childFile('app_zh.arb')
        .writeAsStringSync(singleZhMessageArbFileString);
      l10nDirectory.childFile('app_es.arb')
        .writeAsStringSync(singleEsMessageArbFileString);
      l10nDirectory.childFile('app_en.arb')
        .writeAsStringSync(singleMessageArbFileString);

      final LocalizationsGenerator generator = LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        logger: logger,
      )
        ..loadResources();

      expect(generator.supportedLocales.first, LocaleInfo.fromString('en'));
      expect(generator.supportedLocales.elementAt(1), LocaleInfo.fromString('es'));
      expect(generator.supportedLocales.elementAt(2), LocaleInfo.fromString('zh'));
    });

    testWithoutContext('adds preferred locales to the top of supportedLocales and supportedLanguageCodes', () {
      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile('app_en.arb')
        .writeAsStringSync(singleMessageArbFileString);
      l10nDirectory.childFile('app_es.arb')
        .writeAsStringSync(singleEsMessageArbFileString);
      l10nDirectory.childFile('app_zh.arb')
        .writeAsStringSync(singleZhMessageArbFileString);

      const List<String> preferredSupportedLocale = <String>['zh', 'es'];
      final LocalizationsGenerator generator = LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        preferredSupportedLocales: preferredSupportedLocale,
        logger: logger,
      )
        ..loadResources();

      expect(generator.supportedLocales.first, LocaleInfo.fromString('zh'));
      expect(generator.supportedLocales.elementAt(1), LocaleInfo.fromString('es'));
      expect(generator.supportedLocales.elementAt(2), LocaleInfo.fromString('en'));
    });

    testWithoutContext(
      'throws an error attempting to add preferred locales when there is no corresponding arb file for that locale',
      () {
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile('app_en.arb')
          .writeAsStringSync(singleMessageArbFileString);
        l10nDirectory.childFile('app_es.arb')
          .writeAsStringSync(singleEsMessageArbFileString);
        l10nDirectory.childFile('app_zh.arb')
          .writeAsStringSync(singleZhMessageArbFileString);

        const List<String> preferredSupportedLocale = <String>['am', 'es'];
        expect(
          () {
            LocalizationsGenerator(
              fileSystem: fs,
              inputPathString: defaultL10nPathString,
              outputPathString: defaultL10nPathString,
              templateArbFileName: defaultTemplateArbFileName,
              outputFileString: defaultOutputFileString,
              classNameString: defaultClassNameString,
              preferredSupportedLocales: preferredSupportedLocale,
              logger: logger,
            ).loadResources();
          },
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains("The preferred supported locale, 'am', cannot be added."),
          )),
        );
      },
    );

    testWithoutContext('correctly sorts arbPathString alphabetically', () {
      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      // Write files in non-alphabetical order so that read performs in that order
      l10nDirectory.childFile('app_zh.arb')
        .writeAsStringSync(singleZhMessageArbFileString);
      l10nDirectory.childFile('app_es.arb')
        .writeAsStringSync(singleEsMessageArbFileString);
      l10nDirectory.childFile('app_en.arb')
        .writeAsStringSync(singleMessageArbFileString);

      final LocalizationsGenerator generator = LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        logger: logger,
      )
        ..loadResources();

      expect(generator.arbPathStrings.first, fs.path.join('lib', 'l10n', 'app_en.arb'));
      expect(generator.arbPathStrings.elementAt(1), fs.path.join('lib', 'l10n', 'app_es.arb'));
      expect(generator.arbPathStrings.elementAt(2), fs.path.join('lib', 'l10n', 'app_zh.arb'));
    });

    testWithoutContext('correctly parses @@locale property in arb file', () {
      const String arbFileWithEnLocale = '''
{
  "@@locale": "en",
  "title": "Title",
  "@title": {
    "description": "Title for the application"
  }
}''';

      const String arbFileWithZhLocale = '''
{
  "@@locale": "zh",
  "title": "标题",
  "@title": {
    "description": "Title for the application"
  }
}''';

      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile('first_file.arb')
        .writeAsStringSync(arbFileWithEnLocale);
      l10nDirectory.childFile('second_file.arb')
        .writeAsStringSync(arbFileWithZhLocale);

      final LocalizationsGenerator generator = LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: 'first_file.arb',
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        logger: logger,
      )
        ..loadResources();

      expect(generator.supportedLocales.contains(LocaleInfo.fromString('en')), true);
      expect(generator.supportedLocales.contains(LocaleInfo.fromString('zh')), true);
    });

    testWithoutContext('correctly requires @@locale property in arb file to match the filename locale suffix', () {
      const String arbFileWithEnLocale = '''
{
  "@@locale": "en",
  "title": "Stocks",
  "@title": {
    "description": "Title for the Stocks application"
  }
}''';

      const String arbFileWithZhLocale = '''
{
  "@@locale": "zh",
  "title": "标题",
  "@title": {
    "description": "Title for the Stocks application"
  }
}''';

      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile('app_es.arb')
        .writeAsStringSync(arbFileWithEnLocale);
      l10nDirectory.childFile('app_am.arb')
        .writeAsStringSync(arbFileWithZhLocale);

      expect(
        () {
          LocalizationsGenerator(
            fileSystem: fs,
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: 'app_es.arb',
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            logger: logger,
          ).loadResources();
        },
        throwsA(isA<L10nException>().having(
          (L10nException e) => e.message,
          'message',
          contains('The locale specified in @@locale and the arb filename do not match.'),
        )),
      );
    });

    testWithoutContext("throws when arb file's locale could not be determined", () {
      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true)
        ..childFile('app.arb')
        .writeAsStringSync(singleMessageArbFileString);
      expect(
        () {
          LocalizationsGenerator(
            fileSystem: fs,
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: 'app.arb',
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            logger: logger,
          ).loadResources();
        },
        throwsA(isA<L10nException>().having(
          (L10nException e) => e.message,
          'message',
          contains('locale could not be determined'),
        )),
      );
    });

    testWithoutContext('throws when an empty string is used as a key', () {
      const String arbFileStringWithEmptyResourceId = '''
{
  "market": "MARKET",
  "": {
    "description": "This key is invalid"
  }
}''';

      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile('app_en.arb')
        .writeAsStringSync(arbFileStringWithEmptyResourceId);

      expect(
        () => LocalizationsGenerator(
          fileSystem: fs,
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
          templateArbFileName: 'app_en.arb',
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
          logger: logger,
        ).loadResources(),
        throwsA(isA<L10nException>().having(
          (L10nException e) => e.message,
          'message',
          contains('Invalid ARB resource name ""'),
        )),
      );
    });

    testWithoutContext('throws when the same locale is detected more than once', () {
      const String secondMessageArbFileString = '''
{
  "market": "MARKET",
  "@market": {
    "description": "Label for the Market tab"
  }
}''';

      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile('app_en.arb')
        .writeAsStringSync(singleMessageArbFileString);
      l10nDirectory.childFile('app2_en.arb')
        .writeAsStringSync(secondMessageArbFileString);

      expect(
        () {
          LocalizationsGenerator(
            fileSystem: fs,
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: 'app_en.arb',
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            logger: logger,
          ).loadResources();
        },
        throwsA(isA<L10nException>().having(
          (L10nException e) => e.message,
          'message',
          contains("Multiple arb files with the same 'en' locale detected"),
        )),
      );
    });

    testWithoutContext('throws when the base locale does not exist', () {
      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile('app_en_US.arb')
        .writeAsStringSync(singleMessageArbFileString);

      expect(
        () {
          LocalizationsGenerator(
            fileSystem: fs,
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: 'app_en_US.arb',
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            logger: logger,
          ).loadResources();
        },
        throwsA(isA<L10nException>().having(
          (L10nException e) => e.message,
          'message',
          contains('Arb file for a fallback, en, does not exist'),
        )),
      );
    });
  });

  group('writeOutputFiles', () {
    testUsingContext('message without placeholders - should generate code comment with description and template message translation', () async {
      _standardFlutterDirectoryL10nSetup(fs);
      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        logger: logger,
      ).generate();

      final File baseLocalizationsFile = fs.file(
        fs.path.join(syntheticL10nPackagePath, 'output-localization-file.dart')
      );
      expect(baseLocalizationsFile.existsSync(), isTrue);

      final String baseLocalizationsFileContents = fs.file(
        fs.path.join(syntheticL10nPackagePath, 'output-localization-file.dart')
      ).readAsStringSync();
      expect(baseLocalizationsFileContents, contains('/// Title for the application.'));
      expect(baseLocalizationsFileContents, contains('''
  /// In en, this message translates to:
  /// **'Title'**'''));
    });

    testUsingContext('template message translation handles newline characters', () async {
      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile(defaultTemplateArbFileName)
        .writeAsStringSync(r'''
{
  "title": "Title \n of the application",
  "@title": {
    "description": "Title for the application."
  }
}''');
      l10nDirectory.childFile(esArbFileName)
        .writeAsStringSync(singleEsMessageArbFileString);

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        logger: logger,
      ).generate();

      final File baseLocalizationsFile = fs.file(
        fs.path.join(syntheticL10nPackagePath, 'output-localization-file.dart')
      );
      expect(baseLocalizationsFile.existsSync(), isTrue);

      final String baseLocalizationsFileContents = fs.file(
        fs.path.join(syntheticL10nPackagePath, 'output-localization-file.dart')
      ).readAsStringSync();
      expect(baseLocalizationsFileContents, contains('/// Title for the application.'));
      expect(baseLocalizationsFileContents, contains(r'''
  /// In en, this message translates to:
  /// **'Title \n of the application'**'''));
    });

    testUsingContext('message with placeholders - should generate code comment with description and template message translation', () async {
      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile(defaultTemplateArbFileName)
        .writeAsStringSync(r'''
{
  "price": "The price of this item is: ${price}",
  "@price": {
    "description": "The price of an online shopping cart item.",
    "placeholders": {
      "price": {
        "type": "double",
        "format": "decimalPattern"
      }
    }
  }
}''');
      l10nDirectory.childFile(esArbFileName)
        .writeAsStringSync(r'''
{
  "price": "el precio de este artículo es: ${price}"
}''');

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        logger: logger,
      ).generate();

      final File baseLocalizationsFile = fs.file(
        fs.path.join(syntheticL10nPackagePath, 'output-localization-file.dart')
      );
      expect(baseLocalizationsFile.existsSync(), isTrue);

      final String baseLocalizationsFileContents = fs.file(
        fs.path.join(syntheticL10nPackagePath, 'output-localization-file.dart')
      ).readAsStringSync();
      expect(baseLocalizationsFileContents, contains('/// The price of an online shopping cart item.'));
      expect(baseLocalizationsFileContents, contains(r'''
  /// In en, this message translates to:
  /// **'The price of this item is: \${price}'**'''));
    });

    testUsingContext('should generate a file per language', () async {
      const String singleEnCaMessageArbFileString = '''
{
  "title": "Canadian Title"
}''';
      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')..createSync(recursive: true)
        ..childFile(defaultTemplateArbFileName).writeAsStringSync(singleMessageArbFileString)
        ..childFile('app_en_CA.arb').writeAsStringSync(singleEnCaMessageArbFileString);

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        logger: logger,
      ).generate();

      expect(fs.isFileSync(fs.path.join(syntheticL10nPackagePath, 'output-localization-file_en.dart')), true);
      expect(fs.isFileSync(fs.path.join(syntheticL10nPackagePath, 'output-localization-file_en_US.dart')), false);

      final String englishLocalizationsFile = fs.file(
        fs.path.join(syntheticL10nPackagePath, 'output-localization-file_en.dart')
      ).readAsStringSync();
      expect(englishLocalizationsFile, contains('class AppLocalizationsEnCa extends AppLocalizationsEn'));
      expect(englishLocalizationsFile, contains('class AppLocalizationsEn extends AppLocalizations'));
    });

    testUsingContext('language imports are sorted when preferredSupportedLocaleString is given', () async {
      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')..createSync(recursive: true)
        ..childFile(defaultTemplateArbFileName).writeAsStringSync(singleMessageArbFileString)
        ..childFile('app_zh.arb').writeAsStringSync(singleZhMessageArbFileString)
        ..childFile('app_es.arb').writeAsStringSync(singleEsMessageArbFileString);

      const List<String> preferredSupportedLocale = <String>['zh'];
      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        preferredSupportedLocales: preferredSupportedLocale,
        logger: logger,
      ).generate();

      final String localizationsFile = fs.file(
        fs.path.join(syntheticL10nPackagePath, defaultOutputFileString),
      ).readAsStringSync();
      expect(localizationsFile, contains(
'''
import 'output-localization-file_en.dart';
import 'output-localization-file_es.dart';
import 'output-localization-file_zh.dart';
'''));
    });

    // Regression test for https://github.com/flutter/flutter/issues/88356
    testUsingContext('full output file suffix is retained', () async {
      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')..createSync(recursive: true)
        ..childFile(defaultTemplateArbFileName).writeAsStringSync(singleMessageArbFileString);

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: 'output-localization-file.g.dart',
        classNameString: defaultClassNameString,
        logger: logger,
      ).generate();

      final String baseLocalizationsFile = fs.file(
        fs.path.join(syntheticL10nPackagePath, 'output-localization-file.g.dart'),
      ).readAsStringSync();
      expect(baseLocalizationsFile, contains(
'''
import 'output-localization-file_en.g.dart';
'''));

      final String englishLocalizationsFile = fs.file(
        fs.path.join(syntheticL10nPackagePath, 'output-localization-file_en.g.dart'),
      ).readAsStringSync();
      expect(englishLocalizationsFile, contains(
'''
import 'output-localization-file.g.dart';
'''));
    });

    testUsingContext('throws an exception when invalid output file name is passed in', () {
      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')..createSync(recursive: true)
        ..childFile(defaultTemplateArbFileName).writeAsStringSync(singleMessageArbFileString);

        expect(
          () => LocalizationsGenerator(
            fileSystem: fs,
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: 'asdf',
            classNameString: defaultClassNameString,
            logger: logger,
          ).generate(),
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            allOf(
              contains('output-localization-file'),
              contains('asdf'),
              contains('is invalid'),
              contains('The file name must have a .dart extension.'),
            ),
          )),
        );

        expect(
          () => LocalizationsGenerator(
            fileSystem: fs,
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: '.g.dart',
            classNameString: defaultClassNameString,
            logger: logger,
          ).generate(),
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            allOf(
              contains('output-localization-file'),
              contains('.g.dart'),
              contains('is invalid'),
              contains('The base name cannot be empty.'),
            ),
          )),
        );
      });

    testUsingContext('imports are deferred and loaded when useDeferredImports are set', () async {
      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')..createSync(recursive: true)
        ..childFile(defaultTemplateArbFileName).writeAsStringSync(singleMessageArbFileString);

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        useDeferredLoading: true,
        logger: logger,
      ).generate();

      final String localizationsFile = fs.file(
        fs.path.join(syntheticL10nPackagePath, defaultOutputFileString),
      ).readAsStringSync();
      expect(localizationsFile, contains(
'''
import 'output-localization-file_en.dart' deferred as output-localization-file_en;
'''));
      expect(localizationsFile, contains('output-localization-file_en.loadLibrary()'));
    });

    group('DateTime tests', () {
      testUsingContext('imports package:intl', () async {
        const String singleDateMessageArbFileString = '''
{
  "@@locale": "en",
  "springBegins": "Spring begins on {springStartDate}",
  "@springBegins": {
    "description": "The first day of spring",
    "placeholders": {
      "springStartDate": {
        "type": "DateTime",
        "format": "yMd"
      }
    }
  }
}''';
        fs.currentDirectory.childDirectory('lib').childDirectory('l10n')..createSync(recursive: true)
          ..childFile(defaultTemplateArbFileName).writeAsStringSync(singleDateMessageArbFileString);

        await LocalizationsGenerator(
          fileSystem: fs,
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
          logger: logger,
        ).generate();

        final String localizationsFile = fs.file(
          fs.path.join(syntheticL10nPackagePath, 'output-localization-file_en.dart'),
        ).readAsStringSync();
        expect(localizationsFile, contains(intlImportDartCode));
      });

      testUsingContext('throws an exception when improperly formatted date is passed in', () {
        const String singleDateMessageArbFileString = '''
{
  "@@locale": "en",
  "springBegins": "Spring begins on {springStartDate}",
  "@springBegins": {
    "description": "The first day of spring",
    "placeholders": {
      "springStartDate": {
        "type": "DateTime",
        "format": "asdf"
      }
    }
  }
}''';
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(singleDateMessageArbFileString);

        expect(
          () => LocalizationsGenerator(
            fileSystem: fs,
            inputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            logger: logger,
          ).generate(),
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            allOf(
              contains('asdf'),
              contains('springStartDate'),
              contains('does not have a corresponding DateFormat'),
            ),
          )),
        );
      });

      testUsingContext('use standard date format whenever possible', () async {
        const String singleDateMessageArbFileString = '''
{
  "@@locale": "en",
  "springBegins": "Spring begins on {springStartDate}",
  "@springBegins": {
    "description": "The first day of spring",
    "placeholders": {
      "springStartDate": {
        "type": "DateTime",
        "format": "yMd",
        "isCustomDateFormat": "true"
      }
    }
  }
}''';
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
            .writeAsStringSync(singleDateMessageArbFileString);

        await LocalizationsGenerator(
          fileSystem: fs,
          inputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
          logger: logger,
        ).generate();

        final String localizationsFile = fs.file(
          fs.path.join(syntheticL10nPackagePath, 'output-localization-file_en.dart'),
        ).readAsStringSync();
        expect(localizationsFile, contains('DateFormat.yMd(localeName)'));
      });

      testUsingContext('handle arbitrary formatted date', () async {
        const String singleDateMessageArbFileString = '''
{
  "@@locale": "en",
  "springBegins": "Spring begins on {springStartDate}",
  "@springBegins": {
    "description": "The first day of spring",
    "placeholders": {
      "springStartDate": {
        "type": "DateTime",
        "format": "asdf o'clock",
        "isCustomDateFormat": "true"
      }
    }
  }
}''';
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
            .writeAsStringSync(singleDateMessageArbFileString);

        await LocalizationsGenerator(
          fileSystem: fs,
          inputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
          logger: logger,
        ).generate();

        final String localizationsFile = fs.file(
          fs.path.join(syntheticL10nPackagePath, 'output-localization-file_en.dart'),
        ).readAsStringSync();
        expect(localizationsFile, contains(r"DateFormat('asdf o\'clock', localeName)"));
      });

      testUsingContext('throws an exception when no format attribute is passed in', () async {
        const String singleDateMessageArbFileString = '''
{
  "springBegins": "Spring begins on {springStartDate}",
  "@springBegins": {
    "description": "The first day of spring",
    "placeholders": {
      "springStartDate": {
        "type": "DateTime"
      }
    }
  }
}''';
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(singleDateMessageArbFileString);

        expect(
          () => LocalizationsGenerator(
            fileSystem: fs,
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            logger: logger,
          ).generate(),
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('the "format" attribute needs to be set'),
          )),
        );
      });
    });

    group('NumberFormat tests', () {
      testUsingContext('imports package:intl', () async {
        const String singleDateMessageArbFileString = '''
{
  "courseCompletion": "You have completed {progress} of the course.",
  "@courseCompletion": {
    "description": "The amount of progress the student has made in their class.",
    "placeholders": {
      "progress": {
        "type": "double",
        "format": "percentPattern"
      }
    }
  }
}''';
        fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true)
          ..childFile(defaultTemplateArbFileName).writeAsStringSync(
              singleDateMessageArbFileString);

        await LocalizationsGenerator(
          fileSystem: fs,
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
          logger: logger,
        ).generate();

        final String localizationsFile = fs.file(
          fs.path.join(syntheticL10nPackagePath, 'output-localization-file_en.dart'),
        ).readAsStringSync();
        expect(localizationsFile, contains(intlImportDartCode));
      });

      testUsingContext('throws an exception when improperly formatted number is passed in', () {
        const String singleDateMessageArbFileString = '''
{
  "courseCompletion": "You have completed {progress} of the course.",
  "@courseCompletion": {
    "description": "The amount of progress the student has made in their class.",
    "placeholders": {
      "progress": {
        "type": "double",
        "format": "asdf"
      }
    }
  }
}''';
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(singleDateMessageArbFileString);

        expect(
          () => LocalizationsGenerator(
            fileSystem: fs,
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            logger: logger,
          ).generate(),
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            allOf(
              contains('asdf'),
              contains('progress'),
              contains('does not have a corresponding NumberFormat'),
            ),
          )),
        );
      });
    });

    group('plural messages', () {
      testUsingContext('should throw attempting to generate a plural message without placeholders', () {
        const String pluralMessageWithoutPlaceholdersAttribute = '''
{
  "helloWorlds": "{count,plural, =0{Hello}=1{Hello World}=2{Hello two worlds}few{Hello {count} worlds}many{Hello all {count} worlds}other{Hello other {count} worlds}}",
  "@helloWorlds": {
    "description": "Improperly formatted since it has no placeholder attribute."
  }
}''';

        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(pluralMessageWithoutPlaceholdersAttribute);

        expect(
          () => LocalizationsGenerator(
            fileSystem: fs,
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            logger: logger,
          ).generate(),
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('Check to see if the plural message is in the proper ICU syntax format'),
          )),
        );
      });

      testUsingContext('should throw attempting to generate a plural message with an empty placeholders map', () {
        const String pluralMessageWithEmptyPlaceholdersMap = '''
{
  "helloWorlds": "{count,plural, =0{Hello}=1{Hello World}=2{Hello two worlds}few{Hello {count} worlds}many{Hello all {count} worlds}other{Hello other {count} worlds}}",
  "@helloWorlds": {
    "description": "Improperly formatted since it has no placeholder attribute.",
    "placeholders": {}
  }
}''';

        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(pluralMessageWithEmptyPlaceholdersMap);

        expect(
          () => LocalizationsGenerator(
            fileSystem: fs,
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            logger: logger,
          ).generate(),
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('Check to see if the plural message is in the proper ICU syntax format'),
          )),
        );
      });

      testUsingContext('should throw attempting to generate a plural message with no resource attributes', () {
        const String pluralMessageWithoutResourceAttributes = '''
{
  "helloWorlds": "{count,plural, =0{Hello}=1{Hello World}=2{Hello two worlds}few{Hello {count} worlds}many{Hello all {count} worlds}other{Hello other {count} worlds}}"
}''';

        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(pluralMessageWithoutResourceAttributes);

        expect(
          () => LocalizationsGenerator(
              fileSystem: fs,
              inputPathString: defaultL10nPathString,
              outputPathString: defaultL10nPathString,
              templateArbFileName: defaultTemplateArbFileName,
              outputFileString: defaultOutputFileString,
              classNameString: defaultClassNameString,
              logger: logger,
          ).generate(),
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('Resource attribute "@helloWorlds" was not found'),
          )),
        );
      });

      testUsingContext('should throw attempting to generate a plural message with incorrect format for placeholders', () {
        const String pluralMessageWithIncorrectPlaceholderFormat = '''
{
  "helloWorlds": "{count,plural, =0{Hello}=1{Hello World}=2{Hello two worlds}few{Hello {count} worlds}many{Hello all {count} worlds}other{Hello other {count} worlds}}",
  "@helloWorlds": {
    "placeholders": "Incorrectly a string, should be a map."
  }
}''';

        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(pluralMessageWithIncorrectPlaceholderFormat);

        expect(
          () async {
            await LocalizationsGenerator(
              fileSystem: fs,
              inputPathString: defaultL10nPathString,
              outputPathString: defaultL10nPathString,
              templateArbFileName: defaultTemplateArbFileName,
              outputFileString: defaultOutputFileString,
              classNameString: defaultClassNameString,
              logger: logger,
            ).generate();
          },
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            allOf(
              contains('is not properly formatted'),
              contains('Ensure that it is a map with string valued keys'),
            ),
          )),
        );
      });

      testUsingContext('should warn attempting to generate a plural message whose placeholder is not num or null', () async {
        const String pluralMessageWithIncorrectPlaceholderType = '''
{
  "helloWorlds": "{count,plural, =0{Hello}=1{Hello World}=2{Hello two worlds}few{Hello {count} worlds}many{Hello all {count} worlds}other{Hello other {count} worlds}}",
  "@helloWorlds": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}''';
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(pluralMessageWithIncorrectPlaceholderType);
        await LocalizationsGenerator(
          fileSystem: fs,
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
          logger: logger,
        ).generate();
        expect(logger.warningText, contains("Placeholders for plurals are automatically converted to type 'num'"));
      });
    });

    group('select messages', () {
      testUsingContext('should throw attempting to generate a select message without placeholders', () {
        const String selectMessageWithoutPlaceholdersAttribute = '''
{
  "genderSelect": "{gender, select, female {She} male {He} other {they} }",
  "@genderSelect": {
    "description": "Improperly formatted since it has no placeholder attribute."
  }
}''';

        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(selectMessageWithoutPlaceholdersAttribute);

        expect(
          () async {
            await LocalizationsGenerator(
              fileSystem: fs,
              inputPathString: defaultL10nPathString,
              outputPathString: defaultL10nPathString,
              templateArbFileName: defaultTemplateArbFileName,
              outputFileString: defaultOutputFileString,
              classNameString: defaultClassNameString,
              logger: logger,
            ).generate();
          },
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('Check to see if the select message is in the proper ICU syntax format'),
          )),
        );
      });

      testUsingContext('should throw attempting to generate a select message with an empty placeholders map', () async {
        const String selectMessageWithEmptyPlaceholdersMap = '''
{
  "genderSelect": "{gender, select, female {She} male {He} other {they} }",
  "@genderSelect": {
    "description": "Improperly formatted since it has no placeholder attribute.",
    "placeholders": {}
  }
}''';

        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
            .writeAsStringSync(selectMessageWithEmptyPlaceholdersMap);

        expect(
          () => LocalizationsGenerator(
            fileSystem: fs,
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            logger: logger,
          ).generate(),
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('Check to see if the select message is in the proper ICU syntax format'),
          )),
        );
      });

      testUsingContext('should throw attempting to generate a select message with no resource attributes', () {
        const String selectMessageWithoutResourceAttributes = '''
{
  "genderSelect": "{gender, select, female {She} male {He} other {they} }"
}''';

        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
            .writeAsStringSync(selectMessageWithoutResourceAttributes);

        expect(
          () => LocalizationsGenerator(
            fileSystem: fs,
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            logger: logger,
          ).generate(),
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('Resource attribute "@genderSelect" was not found'),
          )),
        );
      });

      testUsingContext('should throw attempting to generate a select message with incorrect format for placeholders', () {
        const String selectMessageWithIncorrectPlaceholderFormat = '''
{
  "genderSelect": "{gender, select, female {She} male {He} other {they} }",
  "@genderSelect": {
    "placeholders": "Incorrectly a string, should be a map."
  }
}''';

        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
            .writeAsStringSync(selectMessageWithIncorrectPlaceholderFormat);

        expect(
          () async {
            await LocalizationsGenerator(
              fileSystem: fs,
              inputPathString: defaultL10nPathString,
              outputPathString: defaultL10nPathString,
              templateArbFileName: defaultTemplateArbFileName,
              outputFileString: defaultOutputFileString,
              classNameString: defaultClassNameString,
              logger: logger,
            ).generate();
          },
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            allOf(
              contains('is not properly formatted'),
              contains('Ensure that it is a map with string valued keys'),
            ),
          )),
        );
      });

      testUsingContext('should throw attempting to generate a select message with an incorrect message', () {
        const String selectMessageWithoutPlaceholdersAttribute = '''
{
  "genderSelect": "{gender, select,}",
  "@genderSelect": {
    "placeholders": {
      "gender": {}
    }
  }
}''';

        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(selectMessageWithoutPlaceholdersAttribute);

        expect(
          () => LocalizationsGenerator(
            fileSystem: fs,
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            logger: logger,
          ).generate(),
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            allOf(
              contains('Incorrect select message format for'),
              contains('Check to see if the select message is in the proper ICU syntax format.'),
            ),
          )),
        );
      });
    });

    testUsingContext('intl package import should be omitted in subclass files when no plurals are included', () async {
      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')..createSync(recursive: true)
        ..childFile(defaultTemplateArbFileName).writeAsStringSync(singleMessageArbFileString)
        ..childFile('app_es.arb').writeAsStringSync(singleEsMessageArbFileString);

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        logger: logger,
      ).generate();

      final String localizationsFile = fs.file(
        fs.path.join(syntheticL10nPackagePath, 'output-localization-file_es.dart'),
      ).readAsStringSync();
      expect(localizationsFile, isNot(contains(intlImportDartCode)));
    });

    testUsingContext('intl package import should be kept in subclass files when plurals are included', () async {
      const String pluralMessageArb = '''
{
  "helloWorlds": "{count,plural, =0{Hello} =1{Hello World} =2{Hello two worlds} few{Hello {count} worlds} many{Hello all {count} worlds} other{Hello other {count} worlds}}",
  "@helloWorlds": {
    "description": "A plural message",
    "placeholders": {
      "count": {}
    }
  }
}
''';

      const String pluralMessageEsArb = '''
{
  "helloWorlds": "{count,plural, =0{ES - Hello} =1{ES - Hello World} =2{ES - Hello two worlds} few{ES - Hello {count} worlds} many{ES - Hello all {count} worlds} other{ES - Hello other {count} worlds}}"
}
''';

      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')..createSync(recursive: true)
        ..childFile(defaultTemplateArbFileName).writeAsStringSync(pluralMessageArb)
        ..childFile('app_es.arb').writeAsStringSync(pluralMessageEsArb);

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        logger: logger,
      ).generate();

      final String localizationsFile = fs.file(
        fs.path.join(syntheticL10nPackagePath, 'output-localization-file_es.dart'),
      ).readAsStringSync();
      expect(localizationsFile, contains(intlImportDartCode));
    });

    testUsingContext('intl package import should be kept in subclass files when select is included', () async {
      const String selectMessageArb = '''
{
  "genderSelect": "{gender, select, female {She} male {He} other {they} }",
  "@genderSelect": {
    "description": "A select message",
    "placeholders": {
      "gender": {}
    }
  }
}
''';

      const String selectMessageEsArb = '''
{
  "genderSelect": "{gender, select, female {ES - She} male {ES - He} other {ES - they} }"
}
''';

      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')..createSync(recursive: true)
        ..childFile(defaultTemplateArbFileName).writeAsStringSync(selectMessageArb)
        ..childFile('app_es.arb').writeAsStringSync(selectMessageEsArb);

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        logger: logger,
      ).generate();

      final String localizationsFile = fs.file(
        fs.path.join(syntheticL10nPackagePath, 'output-localization-file_es.dart'),
      ).readAsStringSync();
      expect(localizationsFile, contains(intlImportDartCode));
    });

    testUsingContext('check indentation on generated files', () async {
      _standardFlutterDirectoryL10nSetup(fs);

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        logger: logger,
      ).generate();

      final String localizationsFile = fs.file(
        fs.path.join(syntheticL10nPackagePath, 'output-localization-file.dart'),
      ).readAsStringSync();
      // Tests a few of the lines in the generated code.
      // Localizations lookup code
      expect(localizationsFile.contains('  switch (locale.languageCode) {'), true);
      expect(localizationsFile.contains("    case 'en': return AppLocalizationsEn();"), true);
      expect(localizationsFile.contains("    case 'es': return AppLocalizationsEs();"), true);
      expect(localizationsFile.contains('  }'), true);

      // Supported locales list
      expect(localizationsFile.contains('  static const List<Locale> supportedLocales = <Locale>['), true);
      expect(localizationsFile.contains("    Locale('en'),"), true);
      expect(localizationsFile.contains("    Locale('es')"), true);
      expect(localizationsFile.contains('  ];'), true);
    });

    testUsingContext('foundation package import should be omitted from file template when deferred loading = true', () async {
      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')..createSync(recursive: true)
        ..childFile(defaultTemplateArbFileName).writeAsStringSync(singleMessageArbFileString)
        ..childFile('app_es.arb').writeAsStringSync(singleEsMessageArbFileString);

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        useDeferredLoading: true,
        logger: logger,
      ).generate();

      final String localizationsFile = fs.file(
        fs.path.join(syntheticL10nPackagePath, 'output-localization-file.dart'),
      ).readAsStringSync();
      expect(localizationsFile, isNot(contains(foundationImportDartCode)));
    });

    testUsingContext('foundation package import should be kept in file template when deferred loading = false', () async {
      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')..createSync(recursive: true)
        ..childFile(defaultTemplateArbFileName).writeAsStringSync(singleMessageArbFileString)
        ..childFile('app_es.arb').writeAsStringSync(singleEsMessageArbFileString);

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        logger: logger,
      ).generate();

      final String localizationsFile = fs.file(
        fs.path.join(syntheticL10nPackagePath, 'output-localization-file.dart'),
      ).readAsStringSync();
      expect(localizationsFile, contains(foundationImportDartCode));
    });

    testUsingContext('check for string interpolation rules', () async {
      const String enArbCheckList = '''
{
  "one": "The number of {one} elapsed is: 44",
  "@one": {
    "description": "test one",
    "placeholders": {
      "one": {
        "type": "String"
      }
    }
  },
  "two": "哈{two}哈",
  "@two": {
    "description": "test two",
    "placeholders": {
      "two": {
        "type": "String"
      }
    }
  },
  "three": "m{three}m",
  "@three": {
    "description": "test three",
    "placeholders": {
      "three": {
        "type": "String"
      }
    }
  },
  "four": "I have to work _{four}_ sometimes.",
  "@four": {
    "description": "test four",
    "placeholders": {
      "four": {
        "type": "String"
      }
    }
  },
  "five": "{five} elapsed.",
  "@five": {
    "description": "test five",
    "placeholders": {
      "five": {
        "type": "String"
      }
    }
  },
  "six": "{six}m",
  "@six": {
    "description": "test six",
    "placeholders": {
      "six": {
        "type": "String"
      }
    }
  },
  "seven": "hours elapsed: {seven}",
  "@seven": {
    "description": "test seven",
    "placeholders": {
      "seven": {
        "type": "String"
      }
    }
  },
  "eight": " {eight}",
  "@eight": {
    "description": "test eight",
    "placeholders": {
      "eight": {
        "type": "String"
      }
    }
  },
  "nine": "m{nine}",
  "@nine": {
    "description": "test nine",
    "placeholders": {
      "nine": {
        "type": "String"
      }
    }
  }
}
''';

      // It's fine that the arb is identical -- Just checking
      // generated code for use of '${variable}' vs '$variable'
      const String esArbCheckList = '''
{
  "one": "The number of {one} elapsed is: 44",
  "two": "哈{two}哈",
  "three": "m{three}m",
  "four": "I have to work _{four}_ sometimes.",
  "five": "{five} elapsed.",
  "six": "{six}m",
  "seven": "hours elapsed: {seven}",
  "eight": " {eight}",
  "nine": "m{nine}"
}
''';

      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')..createSync(recursive: true)
        ..childFile(defaultTemplateArbFileName).writeAsStringSync(enArbCheckList)
        ..childFile('app_es.arb').writeAsStringSync(esArbCheckList);

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        logger: logger,
      ).generate();

      final String localizationsFile = fs.file(
        fs.path.join(syntheticL10nPackagePath, 'output-localization-file_es.dart'),
      ).readAsStringSync();

      expect(localizationsFile, contains(r'$one'));
      expect(localizationsFile, contains(r'$two'));
      expect(localizationsFile, contains(r'${three}'));
      expect(localizationsFile, contains(r'${four}'));
      expect(localizationsFile, contains(r'$five'));
      expect(localizationsFile, contains(r'${six}m'));
      expect(localizationsFile, contains(r'$seven'));
      expect(localizationsFile, contains(r'$eight'));
      expect(localizationsFile, contains(r'${nine}'));
    });

    testUsingContext('check for string interpolation rules - plurals', () async {
      const String enArbCheckList = '''
{
  "first": "{count,plural, =0{test {count} test} =1{哈{count}哈} =2{m{count}m} few{_{count}_} many{{count} test} other{{count}m}",
  "@first": {
    "description": "First set of plural messages to test.",
    "placeholders": {
      "count": {}
    }
  },
  "second": "{count,plural, =0{test {count}} other{ {count}}",
  "@second": {
    "description": "Second set of plural messages to test.",
    "placeholders": {
      "count": {}
    }
  },
  "third": "{total,plural, =0{test {total}} other{ {total}}",
  "@third": {
    "description": "Third set of plural messages to test, for number.",
    "placeholders": {
      "total": {
        "type": "int",
        "format": "compactLong"
      }
    }
  }
}
''';

      // It's fine that the arb is identical -- Just checking
      // generated code for use of '${variable}' vs '$variable'
      const String esArbCheckList = '''
{
  "first": "{count,plural, =0{test {count} test} =1{哈{count}哈} =2{m{count}m} few{_{count}_} many{{count} test} other{{count}m}",
  "second": "{count,plural, =0{test {count}} other{ {count}}"
}
''';

      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')..createSync(recursive: true)
        ..childFile(defaultTemplateArbFileName).writeAsStringSync(enArbCheckList)
        ..childFile('app_es.arb').writeAsStringSync(esArbCheckList);

      await LocalizationsGenerator(
        fileSystem: fs,
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        logger: logger,
      ).generate();

      final String localizationsFile = fs.file(
        fs.path.join(syntheticL10nPackagePath, 'output-localization-file_es.dart'),
      ).readAsStringSync();

      expect(localizationsFile, contains(r'test $count test'));
      expect(localizationsFile, contains(r'哈$count哈'));
      expect(localizationsFile, contains(r'm${count}m'));
      expect(localizationsFile, contains(r'_${count}_'));
      expect(localizationsFile, contains(r'$count test'));
      expect(localizationsFile, contains(r'${count}m'));
      expect(localizationsFile, contains(r'test $count'));
      expect(localizationsFile, contains(r' $count'));
      expect(localizationsFile, contains(r'String totalString = totalNumberFormat'));
      expect(localizationsFile, contains(r'test $totalString'));
      expect(localizationsFile, contains(r' $totalString'));
    });

    testUsingContext(
      'should throw with descriptive error message when failing to parse the '
      'arb file',
      () {
        const String arbFileWithTrailingComma = '''
{
  "title": "Stocks",
  "@title": {
    "description": "Title for the Stocks application"
  },
}''';
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(arbFileWithTrailingComma);

        expect(
          () => LocalizationsGenerator(
            fileSystem: fs,
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            logger: logger,
          ).generate(),
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            allOf(
              contains('app_en.arb'),
              contains('FormatException'),
              contains('Unexpected character'),
            ),
          )),
        );
      },
    );

    testUsingContext('should throw when resource is missing resource attribute (isResourceAttributeRequired = true)', () {
      const String arbFileWithMissingResourceAttribute = '''
{
  "title": "Stocks"
}''';
      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile(defaultTemplateArbFileName)
        .writeAsStringSync(arbFileWithMissingResourceAttribute);

      expect(
        () => LocalizationsGenerator(
          fileSystem: fs,
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
          areResourceAttributesRequired: true,
          logger: logger,
        ).generate(),
        throwsA(isA<L10nException>().having(
          (L10nException e) => e.message,
          'message',
          contains('Resource attribute "@title" was not found'),
        )),
      );
    });

    group('checks for method/getter formatting', () {
      testUsingContext('cannot contain non-alphanumeric symbols', () {
        const String nonAlphaNumericArbFile = '''
{
  "title!!": "Stocks",
  "@title!!": {
    "description": "Title for the Stocks application"
  }
}''';
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(nonAlphaNumericArbFile);

        expect(
          () => LocalizationsGenerator(
            fileSystem: fs,
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            logger: logger,
          ).generate(),
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('Invalid ARB resource name'),
          )),
        );
      });

      testUsingContext('must start with lowercase character', () {
        const String nonAlphaNumericArbFile = '''
{
  "Title": "Stocks",
  "@Title": {
    "description": "Title for the Stocks application"
  }
}''';
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(nonAlphaNumericArbFile);

        expect(
          () => LocalizationsGenerator(
            fileSystem: fs,
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            logger: logger,
          ).generate(),
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('Invalid ARB resource name'),
          )),
        );
      });

      testUsingContext('cannot start with a number', () {
        const String nonAlphaNumericArbFile = '''
{
  "123title": "Stocks",
  "@123title": {
    "description": "Title for the Stocks application"
  }
}''';
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(nonAlphaNumericArbFile);

        expect(
          () => LocalizationsGenerator(
            fileSystem: fs,
            inputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            logger: logger,
          ).generate(),
          throwsA(isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('Invalid ARB resource name'),
          )),
        );
      });
    });

    testUsingContext('throws when the language code is not supported', () {
      const String arbFileWithInvalidCode = '''
{
  "@@locale": "invalid",
  "title": "invalid"
}''';

      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile('app_invalid.arb')
        .writeAsStringSync(arbFileWithInvalidCode);

      expect(
        () => LocalizationsGenerator(
          fileSystem: fs,
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
          templateArbFileName: 'app_invalid.arb',
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
          logger: logger,
        ).generate(),
        throwsA(isA<L10nException>().having(
          (L10nException e) => e.message,
          'message',
          contains('"invalid" is not a supported language code.'),
        )),
      );
    });
  });

  testUsingContext('should generate a valid pubspec.yaml file when using synthetic package if it does not already exist', () async {
    _standardFlutterDirectoryL10nSetup(fs);
    await LocalizationsGenerator(
      fileSystem: fs,
      inputPathString: defaultL10nPathString,
      templateArbFileName: defaultTemplateArbFileName,
      outputFileString: defaultOutputFileString,
      classNameString: defaultClassNameString,
      logger: logger,
    ).generate();

    final Directory outputDirectory = fs.directory(syntheticPackagePath);
    final File pubspecFile = outputDirectory.childFile('pubspec.yaml');
    expect(pubspecFile.existsSync(), isTrue);

    final YamlNode yamlNode = loadYamlNode(pubspecFile.readAsStringSync());
    expect(yamlNode, isA<YamlMap>());

    final YamlMap yamlMap = yamlNode as YamlMap;
    final String pubspecName = yamlMap['name'] as String;
    final String pubspecDescription = yamlMap['description'] as String;
    expect(pubspecName, 'synthetic_package');
    expect(pubspecDescription, "The Flutter application's synthetic package.");
  });

  testUsingContext('should not overwrite existing pubspec.yaml file when using synthetic package', () async {
    _standardFlutterDirectoryL10nSetup(fs);
    final File pubspecFile = fs.file(fs.path.join(syntheticPackagePath, 'pubspec.yaml'))
      ..createSync(recursive: true)
      ..writeAsStringSync('abcd');

    await LocalizationsGenerator(
      fileSystem: fs,
      inputPathString: defaultL10nPathString,
      templateArbFileName: defaultTemplateArbFileName,
      outputFileString: defaultOutputFileString,
      classNameString: defaultClassNameString,
      logger: logger,
    ).generate();

    // The original pubspec file should not be overwritten.
    expect(pubspecFile.readAsStringSync(), 'abcd');
  });

  testUsingContext('can use type: int without specifying a format', () async {
    const String arbFile = '''
{
  "orderNumber": "This is order #{number}.",
  "@orderNumber": {
    "description": "The title for an order with a given number.",
    "placeholders": {
      "number": {
        "type": "int"
      }
    }
  }
}''';

    final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
      ..createSync(recursive: true);
    l10nDirectory.childFile(defaultTemplateArbFileName)
        .writeAsStringSync(arbFile);

    await LocalizationsGenerator(
      fileSystem: fs,
      inputPathString: defaultL10nPathString,
      outputPathString: defaultL10nPathString,
      templateArbFileName: defaultTemplateArbFileName,
      outputFileString: defaultOutputFileString,
      classNameString: defaultClassNameString,
      logger: logger,
    ).generate();

    final String localizationsFile = fs.file(
      fs.path.join(syntheticL10nPackagePath, 'output-localization-file_en.dart'),
    ).readAsStringSync();
    expect(localizationsFile, containsIgnoringWhitespace(r'''
String orderNumber(int number) {
  return 'This is order #$number.';
}
'''));
    expect(localizationsFile, isNot(contains(intlImportDartCode)));
  });

  testUsingContext('app localizations lookup is a public method', () async {
    final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
      ..createSync(recursive: true);
    l10nDirectory.childFile(defaultTemplateArbFileName)
        .writeAsStringSync(singleMessageArbFileString);

    await LocalizationsGenerator(
      fileSystem: fs,
      inputPathString: defaultL10nPathString,
      outputPathString: defaultL10nPathString,
      templateArbFileName: defaultTemplateArbFileName,
      outputFileString: defaultOutputFileString,
      classNameString: defaultClassNameString,
      logger: logger,
    ).generate();

    final String localizationsFile = fs.file(
      fs.path.join(syntheticL10nPackagePath, 'output-localization-file.dart'),
    ).readAsStringSync();
    expect(localizationsFile, containsIgnoringWhitespace(r'''
AppLocalizations lookupAppLocalizations(Locale locale) {
'''));
  });

  // Regression test for https://github.com/flutter/flutter/pull/93228
  testUsingContext('should use num type for plural', () async {
    const String arbFile = '''
{
  "tryToPollute": "{count, plural, =0{零} =1{一} other{其他}}",
  "@tryToPollute": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },
  "withoutType": "{count, plural, =0{零} =1{一} other{其他}}",
  "@withoutType": {
    "placeholders": {
      "count": {}
    }
  }
}''';

    final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
      ..createSync(recursive: true);
    l10nDirectory.childFile(defaultTemplateArbFileName)
        .writeAsStringSync(arbFile);

    await LocalizationsGenerator(
      fileSystem: fs,
      inputPathString: defaultL10nPathString,
      outputPathString: defaultL10nPathString,
      templateArbFileName: defaultTemplateArbFileName,
      outputFileString: defaultOutputFileString,
      classNameString: defaultClassNameString,
      logger: logger,
    ).generate();

    final String localizationsFile = fs.file(
      fs.path.join(syntheticL10nPackagePath, 'output-localization-file_en.dart'),
    ).readAsStringSync();
    expect(localizationsFile, containsIgnoringWhitespace(r'String tryToPollute(num count) {'));
    expect(localizationsFile, containsIgnoringWhitespace(r'String withoutType(num count) {'));
  });
}
