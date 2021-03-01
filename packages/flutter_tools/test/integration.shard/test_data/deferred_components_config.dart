// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';

import '../test_utils.dart';

abstract class DeferredComponentsConfig {
  String get deferredLibrary;
  String get deferredComponentsGolden;
  String get androidSettings;
  String get androidBuild;
  String get androidLocalProperties;
  String get androidGradleProperties;
  String get androidKeyProperties;
  List<int> get androidKey;
  String get appBuild;
  String get appManifest;
  String get appStrings;
  String get appStyles;
  String get appLaunchBackground;
  List<DeferredComponentModule> get deferredComponents;

  void setUpIn(Directory dir) {
    if (deferredLibrary != null) {
      writeFile(fileSystem.path.join(dir.path, 'lib', 'deferred_library.dart'), deferredLibrary);
    }
    if (deferredComponentsGolden != null) {
      writeFile(fileSystem.path.join(dir.path, 'deferred_components_loading_units.yaml'), deferredComponentsGolden);
    }
    if (androidSettings != null) {
      writeFile(fileSystem.path.join(dir.path, 'android', 'settings.gradle'), androidSettings);
    }
    if (androidBuild != null) {
      writeFile(fileSystem.path.join(dir.path, 'android', 'build.gradle'), androidBuild);
    }
    if (androidLocalProperties != null) {
      writeFile(fileSystem.path.join(dir.path, 'android', 'local.properties'), androidLocalProperties);
    }
    if (androidGradleProperties != null) {
      writeFile(fileSystem.path.join(dir.path, 'android', 'gradle.properties'), androidGradleProperties);
    }
    if (androidKeyProperties != null) {
      writeFile(fileSystem.path.join(dir.path, 'android', 'key.properties'), androidKeyProperties);
    }
    if (androidKey != null) {
      writeBytesFile(fileSystem.path.join(dir.path, 'android', 'app', 'key.jks'), androidKey);
    }
    if (appBuild != null) {
      writeFile(fileSystem.path.join(dir.path, 'android', 'app', 'build.gradle'), appBuild);
    }
    if (appManifest != null) {
      writeFile(fileSystem.path.join(dir.path, 'android', 'app', 'src', 'main', 'AndroidManifest.xml'), appManifest);
    }
    if (appStrings != null) {
      writeFile(fileSystem.path.join(dir.path, 'android', 'app', 'src', 'main', 'res', 'values', 'strings.xml'), appStrings);
    }
    if (appStyles != null) {
      writeFile(fileSystem.path.join(dir.path, 'android', 'app', 'src', 'main', 'res', 'values', 'styles.xml'), appStyles);
    }
    if (appLaunchBackground != null) {
      writeFile(fileSystem.path.join(dir.path, 'android', 'app', 'src', 'main', 'res', 'drawable', 'launch_background.xml'), appLaunchBackground);
    }
    if (deferredComponents != null) {
      for (final DeferredComponentModule component in deferredComponents) {
        component.setUpIn(dir);
      }
    }
  }
}

class DeferredComponentModule {
  DeferredComponentModule(this.name);

  String name;

  void setUpIn(Directory dir) {
    if (name != null) {
      writeFile(fileSystem.path.join(dir.path, 'android', name, 'build.gradle'), r'''
      def localProperties = new Properties()
      def localPropertiesFile = rootProject.file('local.properties')
      if (localPropertiesFile.exists()) {
          localPropertiesFile.withReader('UTF-8') { reader ->
              localProperties.load(reader)
          }
      }

      def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
      if (flutterVersionCode == null) {
          flutterVersionCode = '1'
      }

      def flutterVersionName = localProperties.getProperty('flutter.versionName')
      if (flutterVersionName == null) {
          flutterVersionName = '1.0'
      }

      apply plugin: "com.android.dynamic-feature"

      android {
          compileSdkVersion 30

          sourceSets {
              applicationVariants.all { variant ->
                  main.assets.srcDirs += "${project.buildDir}/intermediates/flutter/${variant.name}/deferred_assets"
                  main.jniLibs.srcDirs += "${project.buildDir}/intermediates/flutter/${variant.name}/deferred_libs"
              }
          }

          defaultConfig {
              minSdkVersion 16
              targetSdkVersion 30
              versionCode flutterVersionCode.toInteger()
              versionName flutterVersionName
          }
          compileOptions {
              sourceCompatibility 1.8
              targetCompatibility 1.8
          }
      }

      dependencies {
          implementation project(":app")
      }
      ''');

      writeFile(fileSystem.path.join(dir.path, 'android', name, 'src', 'main', 'AndroidManifest.xml'), '''
      <manifest xmlns:android="http://schemas.android.com/apk/res/android"
          xmlns:dist="http://schemas.android.com/apk/distribution"
          package="com.example.$name">

          <dist:module
              dist:instant="false"
              dist:title="@string/component1Name">
              <dist:delivery>
                  <dist:on-demand />
              </dist:delivery>
              <dist:fusing dist:include="true" />
          </dist:module>
      </manifest>
      ''');
    }
  }
}