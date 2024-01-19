// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/src/interface/file_system_entity.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart'
    show getGradlewFileName;

import '../src/common.dart';
import '../src/context.dart';
import 'test_utils.dart';

const String gradleSettingsFileContent = r'''
pluginManagement {
    def flutterSdkPath = {
        def properties = new Properties()
        file("local.properties").withInputStream { properties.load(it) }
        def flutterSdkPath = properties.getProperty("flutter.sdk")
        assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
        return flutterSdkPath
    }()

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "AGPREPLACEME" apply false
    id "org.jetbrains.kotlin.android" version "KGPREPLACEME" apply false
}

include ":app"

''';

const String gradleWrapperPropertiesFileContent = r'''
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-REPLACEME-all.zip

''';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
  });

  tearDownAll(() async {
    tryToDelete(tempDir as FileSystemEntity);
  });

  testUsingContext(
      'AGP version out of support band prints warning but still builds', () async {
    // Create a new flutter project.
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'create',
      'dependency_checker_app',
      '--platforms=android',
    ], workingDirectory: tempDir.path);
    expect(result, const ProcessResultMatcher());
    const String gradleVersion = '7.5';
    const String agpVersion = '4.2.0';
    const String kgpVersion = '1.7.10';

    final Directory app = Directory(fileSystem.path.join(tempDir.path, 'dependency_checker_app'));

    // Modify gradle version to passed in version.
    final File gradleWrapperProperties = File(fileSystem.path.join(
        app.path, 'android', 'gradle', 'wrapper', 'gradle-wrapper.properties'));
    final String propertyContent = gradleWrapperPropertiesFileContent.replaceFirst(
      'REPLACEME',
      gradleVersion,
    );
    await gradleWrapperProperties.writeAsString(propertyContent, flush: true);

    final File gradleSettings = File(fileSystem.path.join(
        app.path, 'android', 'settings.gradle'));
    final String settingsContent = gradleSettingsFileContent
        .replaceFirst('AGPREPLACEME', agpVersion)
        .replaceFirst('KGPREPLACEME', kgpVersion);
    await gradleSettings.writeAsString(settingsContent, flush: true);


    // Ensure that gradle files exists from templates.
    result = await processManager.run(<String>[
      flutterBin,
      'build',
      'apk',
      '--debug',
    ], workingDirectory: app.path);
    expect(result, const ProcessResultMatcher());
    expect(result.stderr, contains('Please upgrade your AGP version soon.'));
    
    print(result.stderr.toString());
    print("hi gray");
    print(result.stdout.toString());
    //expect(stdout.toString().contains('Built build/app'), true);
  });

  testUsingContext(
      'Gradle version out of support band prints warning but still builds', () async {
    // Create a new flutter project.
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'create',
      'dependency_checker_app',
      '--platforms=android',
    ], workingDirectory: tempDir.path);
    expect(result, const ProcessResultMatcher());
    const String gradleVersion = '7.0';
    const String agpVersion = '4.2.0';
    const String kgpVersion = '1.7.10';

    final Directory app = Directory(fileSystem.path.join(tempDir.path, 'dependency_checker_app'));

    // Modify gradle version to passed in version.
    final File gradleWrapperProperties = File(fileSystem.path.join(
        app.path, 'android', 'gradle', 'wrapper', 'gradle-wrapper.properties'));
    final String propertyContent = gradleWrapperPropertiesFileContent.replaceFirst(
      'REPLACEME',
      gradleVersion,
    );
    await gradleWrapperProperties.writeAsString(propertyContent, flush: true);

    final File gradleSettings = File(fileSystem.path.join(
        app.path, 'android', 'settings.gradle'));
    final String settingsContent = gradleSettingsFileContent
        .replaceFirst('AGPREPLACEME', agpVersion)
        .replaceFirst('KGPREPLACEME', kgpVersion);
    await gradleSettings.writeAsString(settingsContent, flush: true);


    // Ensure that gradle files exists from templates.
    result = await processManager.run(<String>[
      flutterBin,
      'build',
      'apk',
      '--debug',
    ], workingDirectory: app.path);
    expect(result, const ProcessResultMatcher());
    expect(result.stderr, contains('Please upgrade your Gradle version soon.'));

    print(result.stderr.toString());
    print("hi gray");
    print(result.stdout.toString());
  });

  testUsingContext(
      'Kotlin version out of support band prints warning but still builds', () async {
    // Create a new flutter project.
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'create',
      'dependency_checker_app',
      '--platforms=android',
    ], workingDirectory: tempDir.path);
    expect(result, const ProcessResultMatcher());
    const String gradleVersion = '7.5';
    const String agpVersion = '7.4.0';
    const String kgpVersion = '1.3.10';

    final Directory app = Directory(fileSystem.path.join(tempDir.path, 'dependency_checker_app'));

    // Modify gradle version to passed in version.
    final File gradleWrapperProperties = File(fileSystem.path.join(
        app.path, 'android', 'gradle', 'wrapper', 'gradle-wrapper.properties'));
    final String propertyContent = gradleWrapperPropertiesFileContent.replaceFirst(
      'REPLACEME',
      gradleVersion,
    );
    await gradleWrapperProperties.writeAsString(propertyContent, flush: true);

    final File gradleSettings = File(fileSystem.path.join(
        app.path, 'android', 'settings.gradle'));
    final String settingsContent = gradleSettingsFileContent
        .replaceFirst('AGPREPLACEME', agpVersion)
        .replaceFirst('KGPREPLACEME', kgpVersion);
    await gradleSettings.writeAsString(settingsContent, flush: true);


    // Ensure that gradle files exists from templates.
    result = await processManager.run(<String>[
      flutterBin,
      'build',
      'apk',
      '--debug',
    ], workingDirectory: app.path);
    expect(result, const ProcessResultMatcher());
    expect(result.stderr, contains('Please upgrade your Kotlin version soon.'));

    print(result.stderr.toString());
    print("hi gray");
    print(result.stdout.toString());
  });

  // TODO(gmackall): Add tests for build blocking when we enable the
  // corresponding error versions.
}
