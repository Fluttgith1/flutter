// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:gen_keycodes/utils.dart';

import 'physical_key_data.dart';

const int kNumpadPlane = 0x00200000000;
const int kLeftModifierPlane = 0x00300000000;
const int kRightModifierPlane = 0x00400000000;

/// A pair of strings that represents left and right modifiers.
class _ModifierPair {
  const _ModifierPair(this.left, this.right);

  final String left;
  final String right;
}

List<T> _toNonEmptyArray<T>(dynamic source) {
  final List<dynamic>? dynamicNullableList = source as List<dynamic>?;
  final List<dynamic> dynamicList = dynamicNullableList ?? <dynamic>[];
  return dynamicList.cast<T>();
}

/// The data structure used to manage keyboard key entries.
///
/// The main constructor parses the given input data into the data structure.
///
/// The data structure can be also loaded and saved to JSON, with the
/// [LogicalKeyData.fromJson] constructor and [toJson] method, respectively.
class LogicalKeyData {
  factory LogicalKeyData(
    String chromiumKeys,
    String gtkKeyCodeHeader,
    String gtkNameMap,
    String windowsKeyCodeHeader,
    String windowsNameMap,
    String androidKeyCodeHeader,
    String androidNameMap,
    PhysicalKeyData physicalKeyData,
  ) {
    final Map<String, LogicalKeyEntry> data = <String, LogicalKeyEntry>{};
    final String supplementalChromiumKeys = File(path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'supplemental_key_data.inc',)).readAsStringSync();
    _readKeyEntries(data, chromiumKeys + '\n' + supplementalChromiumKeys);
    _readWindowsKeyCodes(data, windowsKeyCodeHeader, parseMapOfListOfString(windowsNameMap));
    _readGtkKeyCodes(data, gtkKeyCodeHeader, parseMapOfListOfString(gtkNameMap));
    _readAndroidKeyCodes(data, androidKeyCodeHeader, parseMapOfListOfString(androidNameMap));
    _readMacOsKeyCodes(
      data,
      physicalKeyData,
      parseMapOfListOfString(File(
        path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'macos_logical_to_physical.json')
      ).readAsStringSync()),
    );
    _readIosKeyCodes(
      data,
      physicalKeyData,
      parseMapOfListOfString(File(
        path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'ios_logical_to_physical.json')
      ).readAsStringSync()),
    );
    // Sort entries by value
    final List<MapEntry<String, LogicalKeyEntry>> sortedEntries = data.entries.toList()..sort(
      (MapEntry<String, LogicalKeyEntry> a, MapEntry<String, LogicalKeyEntry> b) => a.value.value.compareTo(b.value.value)
    );
    data
      ..clear()
      ..addEntries(sortedEntries);
    return LogicalKeyData._(data);
  }

  /// Parses the given JSON data and populates the data structure from it.
  factory LogicalKeyData.fromJson(Map<String, dynamic> contentMap) {
    final Map<String, LogicalKeyEntry> data = <String, LogicalKeyEntry>{};
    data.addEntries(contentMap.values.map((dynamic value) {
      final LogicalKeyEntry entry = LogicalKeyEntry.fromJsonMapEntry(value as Map<String, dynamic>);
      return MapEntry<String, LogicalKeyEntry>(entry.constantName, entry);
    }));
    return LogicalKeyData._(data);
  }

  /// Parses the input data given in from the various data source files,
  /// populating the data structure.
  ///
  /// None of the parameters may be null.
  LogicalKeyData._(this.data);

  /// Converts the data structure into a JSON structure that can be parsed by
  /// [LogicalKeyData.fromJson].
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> outputMap = <String, dynamic>{};
    for (final LogicalKeyEntry entry in data.values) {
      outputMap[entry.constantName] = entry.toJson();
    }
    return outputMap;
  }

  /// Keys mapped from their constant names.
  final Map<String, LogicalKeyEntry> data;

  /// Parses entries from Chromium's key mapping header file.
  ///
  /// Lines in this file look like either of these (without the ///):
  ///                Key        Enum      Unicode code point
  /// DOM_KEY_UNI("Backspace", BACKSPACE, 0x0008),
  ///                Key        Enum       Value
  /// DOM_KEY_MAP("Accel",      ACCEL,    0x0101),
  ///
  /// The UNI lines are ignored. Their entries have been included in the
  /// printable file.
  static void _readKeyEntries(Map<String, LogicalKeyEntry> data, String input) {
    final Map<String, String> unusedNumpad = Map<String, String>.from(printableToNumpads);

    final RegExp domKeyRegExp = RegExp(
        r'DOM_KEY_(UNI|MAP)\s*\(\s*"([^\s]+?)",\s*'
        r"([^\s]+?),\s*(?:0x([a-fA-F0-9]+)|'(.)')\s*\)",
        multiLine: true);
    final RegExp commentRegExp = RegExp(r'//.*$', multiLine: true);
    input = input.replaceAll(commentRegExp, '');
    for (final Match match in domKeyRegExp.allMatches(input)) {
      if (match == null) {
        continue;
      }
      final String name = match.group(2)!.replaceAll(RegExp('[^A-Za-z0-9]'), '');
      final int value = match.group(4) != null ? getHex(match.group(4)!) : match.group(5)!.codeUnitAt(0);
      final String? keyLabel = match.group(1)! == 'UNI' ? String.fromCharCode(value) : null;
      // If it's a modifier key, add left and right keys instead.
      // Don't add web names and values; they're solved with locations.
      if (chromeModifiers.containsKey(name)) {
        final _ModifierPair pair = chromeModifiers[name]!;
        data[LogicalKeyEntry.computeConstantName(pair.left)] = LogicalKeyEntry.fromName(
          value: value + kLeftModifierPlane,
          name: pair.left,
          keyLabel: null, // Modifier keys don't have keyLabels
        );
        data[LogicalKeyEntry.computeConstantName(pair.right)] = LogicalKeyEntry.fromName(
          value: value + kRightModifierPlane,
          name: pair.right,
          keyLabel: null, // Modifier keys don't have keyLabels
        );
      }

      // If it has a numpad counterpart, also add the numpad key.
      final String? char = value < 256 ? String.fromCharCode(value) : null;
      if (char != null && printableToNumpads.containsKey(char)) {
        final String numpadName = printableToNumpads[char]!;
        data[LogicalKeyEntry.computeConstantName(numpadName)] = LogicalKeyEntry.fromName(
          value: char.codeUnitAt(0) + kNumpadPlane,
          name: numpadName,
          keyLabel: null, // Don't add keyLabel for numpad counterparts
        );
        unusedNumpad.remove(char);
      }

      final LogicalKeyEntry entry = data.putIfAbsent(LogicalKeyEntry.computeConstantName(name), () => LogicalKeyEntry.fromName(
        value: value,
        name: name,
        keyLabel: keyLabel,
      ));
      entry
        ..webNames.add(name)
        ..webValues.add(value);
    }

    // Make sure every Numpad keys that we care have been defined.
    unusedNumpad.forEach((String key, String value) {
      print('Unuadded numpad key $value');
    });
  }

  static void _readMacOsKeyCodes(
    Map<String, LogicalKeyEntry> data,
    PhysicalKeyData physicalKeyData,
    Map<String, List<String>> logicalToPhysical,
  ) {
    final Map<String, String> physicalToLogical = reverseMapOfListOfString(logicalToPhysical,
        (String logicalKeyName, String physicalKeyName) { print('Duplicate logical key name $logicalKeyName for macOS'); });

    physicalToLogical.forEach((String physicalKeyName, String logicalKeyName) {
      final PhysicalKeyEntry? physicalEntry = physicalKeyData.getEntryByName(physicalKeyName);
      final LogicalKeyEntry? logicalEntry = data[logicalKeyName];
      if (physicalEntry == null || physicalEntry.macOsScanCode == null) {
        print('Unexpected physical key $physicalKeyName specified for macOS keyCodeToLogicalMap.');
        return;
      }
      if (logicalEntry == null) {
        print('Unexpected logical key $logicalKeyName specified for macOS keyCodeToLogicalMap.');
        return;
      }
      logicalEntry.macOsKeyCodeNames.add(physicalEntry.name);
      if (physicalEntry.macOsScanCode != null)
        logicalEntry.macOsKeyCodeValues.add(physicalEntry.macOsScanCode!);
    });
  }

  static void _readIosKeyCodes(
    Map<String, LogicalKeyEntry> data,
    PhysicalKeyData physicalKeyData,
    Map<String, List<String>> logicalToPhysical,
  ) {
    final Map<String, String> physicalToLogical = reverseMapOfListOfString(logicalToPhysical,
        (String logicalKeyName, String physicalKeyName) { print('Duplicate logical key name $logicalKeyName for iOS'); });

    physicalToLogical.forEach((String physicalKeyName, String logicalKeyName) {
      final PhysicalKeyEntry? physicalEntry = physicalKeyData.getEntryByName(physicalKeyName);
      final LogicalKeyEntry? logicalEntry = data[logicalKeyName];
      if (physicalEntry == null || physicalEntry.iosScanCode == null) {
        print('Unexpected physical key $physicalKeyName specified for iOS keyCodeToLogicalMap.');
        return;
      }
      if (logicalEntry == null) {
        print('Unexpected logical key $logicalKeyName specified for iOS keyCodeToLogicalMap.');
        return;
      }
      logicalEntry.iosKeyCodeNames.add(physicalEntry.name);
      if (physicalEntry.iosScanCode != null)
        logicalEntry.iosKeyCodeValues.add(physicalEntry.iosScanCode!);
    });
  }

  /// Parses entries from GTK's gdkkeysyms.h key code data file.
  ///
  /// Lines in this file look like this (without the ///):
  ///  /** Space key. */
  ///  #define GDK_KEY_space 0x020
  static void _readGtkKeyCodes(Map<String, LogicalKeyEntry> data, String headerFile, Map<String, List<String>> nameToGtkName) {
    final RegExp definedCodes = RegExp(r'#define GDK_KEY_([a-zA-Z0-9_]+)\s*0x([0-9a-f]+),?');
    final Map<String, String> gtkNameToFlutterName = reverseMapOfListOfString(nameToGtkName,
        (String flutterName, String gtkName) { print('Duplicate GTK logical name $gtkName'); });

    for (final Match match in definedCodes.allMatches(headerFile)) {
      final String gtkName = match.group(1)!;
      final String? name = gtkNameToFlutterName[gtkName];
      final int value = int.parse(match.group(2)!, radix: 16);
      if (name == null) {
        // print('Unmapped GTK logical entry $gtkName');
        continue;
      }

      final LogicalKeyEntry? entry = data[name];
      if (entry == null) {
        print('Invalid logical entry by name $name (from GTK $gtkName)');
        continue;
      }
      entry
        ..gtkNames.add(gtkName)
        ..gtkValues.add(value);
    }
  }

  static void _readWindowsKeyCodes(Map<String, LogicalKeyEntry> data, String headerFile, Map<String, List<String>> nameMap) {
    // The mapping from the Flutter name (e.g. "enter") to the Windows name (e.g.
    // "RETURN").
    final Map<String, String> nameToFlutterName  = reverseMapOfListOfString(nameMap,
        (String flutterName, String windowsName) { print('Duplicate Windows logical name $windowsName'); });

    final RegExp definedCodes = RegExp(r'define VK_([A-Z0-9_]+)\s*([A-Z0-9_x]+),?');
    for (final Match match in definedCodes.allMatches(headerFile)) {
      final String windowsName = match.group(1)!;
      final String? name = nameToFlutterName[windowsName];
      final int value = int.tryParse(match.group(2)!)!;
      if (name == null) {
        print('Unmapped Windows logical entry $windowsName');
        continue;
      }
      final LogicalKeyEntry? entry = data[name];
      if (entry == null) {
        print('Invalid logical entry by name $name (from Windows $windowsName)');
        continue;
      }
      entry
        ..windowsNames.add(windowsName)
        ..windowsValues.add(value);
    }
  }

  /// Parses entries from Android's keycodes.h key code data file.
  ///
  /// Lines in this file look like this (without the ///):
  ///  /** Left Control modifier key. */
  ///  AKEYCODE_CTRL_LEFT       = 113,
  static void _readAndroidKeyCodes(Map<String, LogicalKeyEntry> data, String headerFile, Map<String, List<String>> nameMap) {
    final Map<String, String> nameToFlutterName  = reverseMapOfListOfString(nameMap,
        (String flutterName, String androidName) { print('Duplicate Android logical name $androidName'); });

    final RegExp enumBlock = RegExp(r'enum\s*\{(.*)\};', multiLine: true);
    // Eliminate everything outside of the enum block.
    headerFile = headerFile.replaceAllMapped(enumBlock, (Match match) => match.group(1)!);
    final RegExp enumEntry = RegExp(r'AKEYCODE_([A-Z0-9_]+)\s*=\s*([0-9]+),?');
    for (final Match match in enumEntry.allMatches(headerFile)) {
      final String androidName = match.group(1)!;
      final String? name = nameToFlutterName[androidName];
      final int value = int.tryParse(match.group(2)!)!;
      if (name == null) {
        print('Unmapped Android logical entry $androidName');
        continue;
      }
      final LogicalKeyEntry? entry = data[name];
      if (entry == null) {
        print('Invalid logical entry by name $name (from Android $androidName)');
        continue;
      }
      entry
        ..androidNames.add(androidName)
        ..androidValues.add(value);
    }
  }

  // Map Web key to the pair of key names
  static late final Map<String, _ModifierPair> chromeModifiers = () {
    final String rawJson = File(path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'chromium_modifiers.json',)).readAsStringSync();
    return (json.decode(rawJson) as Map<String, dynamic>).map((String key, dynamic value) {
      final List<dynamic> pair = value as List<dynamic>;
      return MapEntry<String, _ModifierPair>(key, _ModifierPair(pair[0] as String, pair[1] as String));
    });
  }();

  // Map printable to corresponding numpad key name
  static late final Map<String, String> printableToNumpads = () {
    final String rawJson = File(path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'printable_to_numpads.json',)).readAsStringSync();
    return (json.decode(rawJson) as Map<String, dynamic>).map((String key, dynamic value) {
      return MapEntry<String, String>(key, value as String);
    });
  }();
}

/// A single entry in the key data structure.
///
/// Can be read from JSON with the [LogicalKeyEntry.fromJsonMapEntry] constructor, or
/// written with the [toJson] method.
class LogicalKeyEntry {
  /// Creates a single key entry from available data.
  LogicalKeyEntry({
    required this.value,
    required this.constantName,
    required this.commentName,
    this.keyLabel,
  })  : assert(constantName != null),
        assert(commentName != null),
        assert(value != null),
        webNames = <String>[],
        webValues = <int>[],
        macOsKeyCodeNames = <String>[],
        macOsKeyCodeValues = <int>[],
        iosKeyCodeNames = <String>[],
        iosKeyCodeValues = <int>[],
        gtkNames = <String>[],
        gtkValues = <int>[],
        windowsNames = <String>[],
        windowsValues = <int>[],
        androidNames = <String>[],
        androidValues = <int>[];

  LogicalKeyEntry.fromName({
    required int value,
    required String name,
    String? keyLabel,
  })  : this(
          value: value,
          commentName: LogicalKeyEntry.computeCommentName(name),
          constantName: LogicalKeyEntry.computeConstantName(name),
          keyLabel: keyLabel,
        );

  /// Populates the key from a JSON map.
  LogicalKeyEntry.fromJsonMapEntry(Map<String, dynamic> map)
    : value = map['value'] as int,
      constantName = map['constant'] as String,
      commentName = map['english'] as String,
      webNames = _toNonEmptyArray<String>(map['names']['web']),
      webValues = _toNonEmptyArray<int>(map['values']['web']),
      macOsKeyCodeNames = _toNonEmptyArray<String>(map['names']['macOs']),
      macOsKeyCodeValues = _toNonEmptyArray<int>(map['values']['macOs']),
      iosKeyCodeNames = _toNonEmptyArray<String>(map['names']['ios']),
      iosKeyCodeValues = _toNonEmptyArray<int>(map['values']['ios']),
      gtkNames = _toNonEmptyArray<String>(map['names']['gtk']),
      gtkValues = _toNonEmptyArray<int>(map['values']['gtk']),
      windowsNames = _toNonEmptyArray<String>(map['names']['windows']),
      windowsValues = _toNonEmptyArray<int>(map['values']['windows']),
      androidNames = _toNonEmptyArray<String>(map['names']['android']),
      androidValues = _toNonEmptyArray<int>(map['values']['android']),
      keyLabel = map['keyLabel'] as String;

  final int value;

  final String constantName;

  /// The name of the key suitable for placing in comments.
  final String commentName;

  /// The name of the key, mostly derived from the DomKey name in Chromium,
  /// but where there was no DomKey representation, derived from the Chromium
  /// symbol name.
  final List<String> webNames;

  /// The value of the key.
  final List<int> webValues;

  /// The names of the key codes that corresponds to this logical key on macOS,
  /// created from the corresponding physical keys.
  final List<String> macOsKeyCodeNames;

  /// The key codes that corresponds to this logical key on macOS, created from
  /// the physical key list substituted with the key mapping.
  final List<int> macOsKeyCodeValues;

  /// The names of the key codes that corresponds to this logical key on iOS,
  /// created from the corresponding physical keys.
  final List<String> iosKeyCodeNames;

  /// The key codes that corresponds to this logical key on iOS, created from the
  /// physical key list substituted with the key mapping.
  final List<int> iosKeyCodeValues;

  /// The list of names that GTK gives to this key (symbol names minus the
  /// prefix).
  final List<String> gtkNames;

  /// The list of GTK key codes matching this key, created by looking up the
  /// Linux name in the GTK data, and substituting the GTK key code
  /// value.
  final List<int> gtkValues;

  /// The list of names that Windows gives to this key (symbol names minus the
  /// prefix).
  final List<String> windowsNames;

  /// The list of Windows key codes matching this key, created by looking up the
  /// Windows name in the Chromium data, and substituting the Windows key code
  /// value.
  final List<int> windowsValues;

  /// The list of names that Android gives to this key (symbol names minus the
  /// prefix).
  final List<String> androidNames;

  /// The list of Android key codes matching this key, created by looking up the
  /// Android name in the Chromium data, and substituting the Android key code
  /// value.
  final List<int> androidValues;

  final String? keyLabel;

  /// Creates a JSON map from the key data.
  Map<String, dynamic> toJson() {
    return removeEmptyValues(<String, dynamic>{
      'constant': constantName,
      'english': commentName,
      'value': value,
      'keyLabel': keyLabel,
      'names': removeEmptyValues(<String, dynamic>{
        'web': webNames,
        'macOs': macOsKeyCodeNames,
        'ios': iosKeyCodeNames,
        'gtk': gtkNames,
        'windows': windowsNames,
        'android': androidNames,
      }),
      'values': removeEmptyValues(<String, List<int>>{
        'web': webValues,
        'macOs': macOsKeyCodeValues,
        'ios': iosKeyCodeValues,
        'gtk': gtkValues,
        'windows': windowsValues,
        'android': androidValues,
      }),
    });
  }

  @override
  String toString() {
    return """'$constantName': (name: "$commentName", value: ${toHex(value)}) """;
  }

  static String _computeConstantNameBase(String name) {
    final String result = name
      .replaceAll('PinP', 'PInP');
      // .replaceAllMapped(RegExp('([A-Z])([A-Z]+)([A-Z0-9]|\$)'),
      //   (Match match) => '${match.group(1)}${match.group(2).toLowerCase()}${match.group(3)}');
    return result;
  }

  /// Gets the named used for the key constant in the definitions in
  /// keyboard_key.dart.
  ///
  /// If set by the constructor, returns the name set, but otherwise constructs
  /// the name from the various different names available, making sure that the
  /// name isn't a Dart reserved word (if it is, then it adds the word "Key" to
  /// the end of the name).
  static String computeConstantName(String name) {
    final String result = upperCamelToLowerCamel(_computeConstantNameBase(name));
    if (kDartReservedWords.contains(result)) {
      return '${result}Key';
    }
    return result;
  }

  /// Takes the [constantName] and converts it from lower camel case to capitalized
  /// separate words (e.g. "wakeUp" converts to "Wake Up").
  static String computeCommentName(String name) {
    String upperCamel = lowerCamelToUpperCamel(_computeConstantNameBase(name));
    upperCamel = upperCamel.replaceAllMapped(RegExp(r'(Digit|Numpad|Lang|Button|Left|Right)([0-9]+)'), (Match match) => '${match.group(1)} ${match.group(2)}');
    return upperCamel
      // 'fooBar' => 'foo Bar', 'fooBAR' => 'foo BAR'
      .replaceAllMapped(RegExp(r'([^A-Z])([A-Z])'), (Match match) => '${match.group(1)} ${match.group(2)}')
      // 'ABCDoo' => 'ABC Doo'
      .replaceAllMapped(RegExp(r'([A-Z])([A-Z])([a-z])'), (Match match) => '${match.group(1)} ${match.group(2)}${match.group(3)}')
      // 'AB1' => 'AB 1', 'F1' => 'F1'
      .replaceAllMapped(RegExp(r'([A-Z]{2,})([0-9])'), (Match match) => '${match.group(1)} ${match.group(2)}')
      // 'Foo1' => 'Foo 1'
      .replaceAllMapped(RegExp(r'([a-z])([0-9])'), (Match match) => '${match.group(1)} ${match.group(2)}')
      .trim();
  }
}
