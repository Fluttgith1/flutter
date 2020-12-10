// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'base_code_gen.dart';
import 'logical_key_data.dart';
import 'physical_key_data.dart';
import 'utils.dart';


/// Generates the key mapping of Android, based on the information in the key
/// data structure given to it.
class AndroidCodeGenerator extends PlatformCodeGenerator {
  AndroidCodeGenerator(PhysicalKeyData physicalData, this.logicalData) : super(physicalData);

  final LogicalKeyData logicalData;

  /// This generates the map of Android key codes to logical keys.
  String get _androidKeyCodeMap {
    final StringBuffer androidKeyCodeMap = StringBuffer();
    for (final LogicalKeyEntry entry in logicalData.data.values) {
      for (final int code in entry.androidValues) {
        androidKeyCodeMap.writeln('      put(${toHex(code, digits: 10)}L, ${toHex(entry.value, digits: 10)}L);    // ${entry.constantName}');
      }
    }
    return androidKeyCodeMap.toString().trimRight();
  }

  /// This generates the map of Android number pad key codes to logical keys.
  String get _androidNumpadMap {
    final StringBuffer androidKeyCodeMap = StringBuffer();
    // for (final PhysicalKeyEntry entry in numpadKeyData) {
    //   if (entry.androidKeyCodes != null) {
    //     for (final int code in entry.androidKeyCodes.cast<int>()) {
    //       androidKeyCodeMap.writeln('  { $code, ${toHex(entry.flutterId, digits: 10)} },    // ${entry.constantName}');
    //     }
    //   }
    // }
    return androidKeyCodeMap.toString().trimRight();
  }

  /// This generates the map of Android scan codes to physical keys.
  String get _androidScanCodeMap {
    final StringBuffer androidScanCodeMap = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.data) {
      if (entry.androidScanCodes != null) {
        for (final int code in entry.androidScanCodes.cast<int>()) {
          androidScanCodeMap.writeln('      put(${toHex(code, digits: 10)}L, ${toHex(entry.usbHidCode, digits: 10)}L);    // ${entry.constantName}');
        }
      }
    }
    return androidScanCodeMap.toString().trimRight();
  }

  @override
  String get templatePath => path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'android_keyboard_map_java.tmpl');

  @override
  String outputPath(String platform) => path.join(flutterRoot.path, '..', 'engine', 'src', 'flutter', 'shell', 'platform',
      path.join('android', 'io', 'flutter', 'embedding', 'android', 'KeyboardMap.java'));

  @override
  Map<String, String> mappings() {
    return <String, String>{
      'ANDROID_SCAN_CODE_MAP': _androidScanCodeMap,
      'ANDROID_KEY_CODE_MAP': _androidKeyCodeMap,
      // 'ANDROID_NUMPAD_MAP': _androidNumpadMap,
    };
  }
}
