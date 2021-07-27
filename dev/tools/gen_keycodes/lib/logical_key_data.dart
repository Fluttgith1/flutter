// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:gen_keycodes/utils.dart';
import 'package:path/path.dart' as path;

import 'constants.dart';
import 'physical_key_data.dart';

bool _isControlCharacter(int codeUnit) {
  return (codeUnit <= 0x1f && codeUnit >= 0x00) || (codeUnit >= 0x7f && codeUnit <= 0x9f);
}

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
    String macosLogicalToPhysical,
    String iosLogicalToPhysical,
    String glfwHeaderFile,
    String glfwNameMap,
    PhysicalKeyData physicalKeyData,
  ) {
    final Map<String, LogicalKeyEntry> data = <String, LogicalKeyEntry>{};
    _readKeyEntries(data, chromiumKeys);
    _readWindowsKeyCodes(data, windowsKeyCodeHeader, parseMapOfListOfString(windowsNameMap));
    _readGtkKeyCodes(data, gtkKeyCodeHeader, parseMapOfListOfString(gtkNameMap));
    _readAndroidKeyCodes(data, androidKeyCodeHeader, parseMapOfListOfString(androidNameMap));
    _readMacOsKeyCodes(data, physicalKeyData, parseMapOfListOfString(macosLogicalToPhysical));
    _readIosKeyCodes(data, physicalKeyData, parseMapOfListOfString(iosLogicalToPhysical));
    _readFuchsiaKeyCodes(data, physicalKeyData);
    _readGlfwKeyCodes(data, glfwHeaderFile, parseMapOfListOfString(glfwNameMap));
    // Sort entries by value
    final List<MapEntry<String, LogicalKeyEntry>> sortedEntries = data.entries.toList()..sort(
      (MapEntry<String, LogicalKeyEntry> a, MapEntry<String, LogicalKeyEntry> b) =>
        LogicalKeyEntry.compareByValue(a.value, b.value),
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
      return MapEntry<String, LogicalKeyEntry>(entry.name, entry);
    }));
    return LogicalKeyData._(data);
  }

  /// Parses the input data given in from the various data source files,
  /// populating the data structure.
  ///
  /// None of the parameters may be null.
  LogicalKeyData._(this._data);
    // : _dataById = Map<int, LogicalKeyEntry>.fromIterable(_data.values, key: (dynamic entry) => (entry as LogicalKeyEntry).value);

  /// Converts the data structure into a JSON structure that can be parsed by
  /// [LogicalKeyData.fromJson].
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> outputMap = <String, dynamic>{};
    for (final LogicalKeyEntry entry in _data.values) {
      outputMap[entry.name] = entry.toJson();
    }
    return outputMap;
  }

  /// Find an entry from name.
  ///
  /// Asserts if the name is not found.
  LogicalKeyEntry entryByName(String name) {
    assert(_data.containsKey(name),
        'Unable to find logical entry by name $name.');
    return _data[name]!;
  }

  /// Find an entry from ID.
  ///
  /// Asserts if the ID is not found.
  // LogicalKeyEntry entryById(int id) {
  //   assert(_dataById.containsKey(id),
  //       'Unable to find logical entry by ID $id.');
  //   return _dataById[id]!;
  // }

  /// All entries.
  Iterable<LogicalKeyEntry> get entries => _data.values;

  // Keys mapped from their names.
  final Map<String, LogicalKeyEntry> _data;
  // final Map<int, LogicalKeyEntry> _dataById;

  /// Parses entries from Chromium's key mapping header file.
  ///
  /// Lines in this file look like either of these (without the ///):
  ///                Key        Enum      Unicode code point
  /// DOM_KEY_UNI("Backspace", BACKSPACE, 0x0008),
  ///                Key        Enum       Value
  /// DOM_KEY_MAP("Accel",      ACCEL,    0x0101),
  ///
  /// Flutter's supplemental_key_data.inc also has some new formats.
  /// The following format uses a character as the 3rd argument.
  ///                Key        Enum       Character
  /// DOM_KEY_UNI("KeyB",      KEY_B,      'b'),
  ///
  /// The following format should be mapped to the Flutter plane.
  ///                 Key       Enum       Character
  /// FLUTTER_KEY_MAP("Lang4",  LANG4,     0x00013),
  static void _readKeyEntries(Map<String, LogicalKeyEntry> data, String input) {
    final RegExp domKeyRegExp = RegExp(
      r'(?<source>DOM|FLUTTER)_KEY_(?<kind>UNI|MAP)\s*\(\s*'
      r'"(?<name>[^\s]+?)",\s*'
      r'(?<enum>[^\s]+?),\s*'
      r"(?:0[xX](?<unicode>[a-fA-F0-9]+)|'(?<char>.)')\s*"
      r'\)',
      // Multiline is necessary because some definitions spread across
      // multiple lines.
      multiLine: true,
    );
    final RegExp commentRegExp = RegExp(r'//.*$', multiLine: true);
    input = input.replaceAll(commentRegExp, '');
    for (final RegExpMatch match in domKeyRegExp.allMatches(input)) {
      final String source = match.namedGroup('source')!;
      final String webName = match.namedGroup('name')!;
      // ".AltGraphLatch"  is consumed internally and not expressed to the Web.
      if (webName.startsWith('.')) {
        continue;
      }
      final String name = LogicalKeyEntry.computeName(webName.replaceAll(RegExp('[^A-Za-z0-9]'), ''));
      final int value = match.namedGroup('unicode') != null ?
        getHex(match.namedGroup('unicode')!) :
        match.namedGroup('char')!.codeUnitAt(0);
      final String? keyLabel = (match.namedGroup('kind')! == 'UNI' && !_isControlCharacter(value)) ?
        String.fromCharCode(value) : null;
      // Skip modifier keys from DOM. They will be added with supplemental data.
      if (_chromeModifiers.containsKey(name) && source == 'DOM') {
        continue;
      }

      final bool isPrintable = keyLabel != null;
      data.putIfAbsent(name, () {
        final LogicalKeyEntry entry = LogicalKeyEntry.fromName(
          value: toPlane(value, _sourceToPlane(source, isPrintable)),
          name: name,
          keyLabel: keyLabel,
        );
        if (source == 'DOM')
          entry.webNames.add(webName);
        return entry;
      });
    }
  }

  static void _readMacOsKeyCodes(
    Map<String, LogicalKeyEntry> data,
    PhysicalKeyData physicalKeyData,
    Map<String, List<String>> logicalToPhysical,
  ) {
    final Map<String, String> physicalToLogical = reverseMapOfListOfString(logicalToPhysical,
        (String logicalKeyName, String physicalKeyName) { print('Duplicate logical key name $logicalKeyName for macOS'); });

    physicalToLogical.forEach((String physicalKeyName, String logicalKeyName) {
      final PhysicalKeyEntry physicalEntry = physicalKeyData.entryByName(physicalKeyName);
      assert(physicalEntry.macOSScanCode != null,
        'Physical entry $physicalKeyName does not have a macOSScanCode.');
      final LogicalKeyEntry? logicalEntry = data[logicalKeyName];
      assert(logicalEntry != null,
        'Unable to find logical entry by name $logicalKeyName.');
      logicalEntry!.macOSKeyCodeNames.add(physicalEntry.name);
      logicalEntry.macOSKeyCodeValues.add(physicalEntry.macOSScanCode!);
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
      final PhysicalKeyEntry physicalEntry = physicalKeyData.entryByName(physicalKeyName);
      assert(physicalEntry.iOSScanCode != null,
        'Physical entry $physicalKeyName does not have an iosScanCode.');
      final LogicalKeyEntry? logicalEntry = data[logicalKeyName];
      assert(logicalEntry != null,
        'Unable to find logical entry by name $logicalKeyName.');
      logicalEntry!.iOSKeyCodeNames.add(physicalEntry.name);
      logicalEntry.iOSKeyCodeValues.add(physicalEntry.iOSScanCode!);
    });
  }

  /// Parses entries from GTK's gdkkeysyms.h key code data file.
  ///
  /// Lines in this file look like this (without the ///):
  ///  /** Space key. */
  ///  #define GDK_KEY_space 0x020
  static void _readGtkKeyCodes(Map<String, LogicalKeyEntry> data, String headerFile, Map<String, List<String>> nameToGtkName) {
    final RegExp definedCodes = RegExp(
      r'#define '
      r'GDK_KEY_(?<name>[a-zA-Z0-9_]+)\s*'
      r'0x(?<value>[0-9a-f]+),?',
    );
    final Map<String, String> gtkNameToFlutterName = reverseMapOfListOfString(nameToGtkName,
        (String flutterName, String gtkName) { print('Duplicate GTK logical name $gtkName'); });

    for (final RegExpMatch match in definedCodes.allMatches(headerFile)) {
      final String gtkName = match.namedGroup('name')!;
      final String? name = gtkNameToFlutterName[gtkName];
      final int value = int.parse(match.namedGroup('value')!, radix: 16);
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

    final RegExp definedCodes = RegExp(
      r'define '
      r'VK_(?<name>[A-Z0-9_]+)\s*'
      r'(?<value>[A-Z0-9_x]+),?',
    );
    for (final RegExpMatch match in definedCodes.allMatches(headerFile)) {
      final String windowsName = match.namedGroup('name')!;
      final String? name = nameToFlutterName[windowsName];
      final int value = int.tryParse(match.namedGroup('value')!)!;
      if (name == null) {
        print('Unmapped Windows logical entry $windowsName');
        continue;
      }
      final LogicalKeyEntry? entry = data[name];
      if (entry == null) {
        print('Invalid logical entry by name $name (from Windows $windowsName)');
        continue;
      }
      addNameValue(
        entry.windowsNames,
        entry.windowsValues,
        windowsName,
        value,
      );
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
    final RegExp enumEntry = RegExp(
      r'AKEYCODE_(?<name>[A-Z0-9_]+)\s*'
      r'=\s*'
      r'(?<value>[0-9]+),?',
    );
    for (final RegExpMatch match in enumEntry.allMatches(headerFile)) {
      final String androidName = match.namedGroup('name')!;
      final String? name = nameToFlutterName[androidName];
      final int value = int.tryParse(match.namedGroup('value')!)!;
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

  static void _readFuchsiaKeyCodes(Map<String, LogicalKeyEntry> data, PhysicalKeyData physicalData) {
    for (final LogicalKeyEntry entry in data.values) {
      final int? value = (() {
        if (entry.value == 0) // "None" key
          return 0;
        final String? keyLabel = printable[entry.constantName];
        if (keyLabel != null && !entry.constantName.startsWith('numpad')) {
          return toPlane(keyLabel.codeUnitAt(0), kUnicodePlane.value);
        } else {
          final PhysicalKeyEntry? physicalEntry = physicalData.tryEntryByName(entry.name);
          if (physicalEntry != null) {
            return toPlane(physicalEntry.usbHidCode, kFuchsiaPlane.value);
          }
        }
      })();
      if (value != null)
        entry.fuchsiaValues.add(value);
    }
  }

  /// Parses entries from GLFW's keycodes.h key code data file.
  ///
  /// Lines in this file look like this (without the ///):
  ///  /** Space key. */
  ///  #define GLFW_KEY_SPACE              32,
  ///  #define GLFW_KEY_LAST               GLFW_KEY_MENU
  static void _readGlfwKeyCodes(Map<String, LogicalKeyEntry> data, String headerFile, Map<String, List<String>> nameMap) {
    final Map<String, String> nameToFlutterName  = reverseMapOfListOfString(nameMap,
        (String flutterName, String glfwName) { print('Duplicate GLFW logical name $glfwName'); });

    // Only get the KEY definitions, ignore the rest (mouse, joystick, etc).
    final RegExp definedCodes = RegExp(
      r'define\s+'
      r'GLFW_KEY_(?<name>[A-Z0-9_]+)\s+'
      r'(?<value>[A-Z0-9_]+),?',
    );
    final Map<String, dynamic> replaced = <String, dynamic>{};
    for (final RegExpMatch match in definedCodes.allMatches(headerFile)) {
      final String name = match.namedGroup('name')!;
      final String value = match.namedGroup('value')!;
      replaced[name] = int.tryParse(value) ?? value.replaceAll('GLFW_KEY_', '');
    }
    final Map<String, int> glfwNameToKeyCode = <String, int>{};
    replaced.forEach((String key, dynamic value) {
      // Some definition values point to other definitions (e.g #define GLFW_KEY_LAST GLFW_KEY_MENU).
      if (value is String) {
        glfwNameToKeyCode[key] = replaced[value] as int;
      } else {
        glfwNameToKeyCode[key] = value as int;
      }
    });

    glfwNameToKeyCode.forEach((String glfwName, int value) {
      final String? name = nameToFlutterName[glfwName];
      final LogicalKeyEntry? entry = data[nameToFlutterName[glfwName]];
      if (entry == null) {
        print('Invalid logical entry by name $name (from GLFW $glfwName)');
        return;
      }
      addNameValue(
        entry.glfwNames,
        entry.glfwValues,
        glfwName,
        value,
      );
    });
  }

  // Map Web key to the pair of key names
  static late final Map<String, _ModifierPair> _chromeModifiers = () {
    final String rawJson = File(path.join(dataRoot, 'chromium_modifiers.json',)).readAsStringSync();
    return (json.decode(rawJson) as Map<String, dynamic>).map((String key, dynamic value) {
      final List<dynamic> pair = value as List<dynamic>;
      return MapEntry<String, _ModifierPair>(key, _ModifierPair(pair[0] as String, pair[1] as String));
    });
  }();

  /// Returns the static map of printable representations.
  static late final Map<String, String> printable = (() {
    final String printableKeys = File(path.join(dataRoot, 'printable.json',)).readAsStringSync();
    return (json.decode(printableKeys) as Map<String, dynamic>)
      .cast<String, String>();
  })();

  /// Returns the static map of synonym representations.
  ///
  /// These include synonyms for keys which don't have printable
  /// representations, and appear in more than one place on the keyboard (e.g.
  /// SHIFT, ALT, etc.).
  static late final Map<String, List<String>> synonyms = (() {
    final String synonymKeys = File(path.join(dataRoot, 'synonyms.json',)).readAsStringSync();
    final Map<String, dynamic> dynamicSynonym = json.decode(synonymKeys) as Map<String, dynamic>;
    return dynamicSynonym.map((String name, dynamic values) {
      // The keygen and algorithm of macOS relies on synonyms being pairs.
      // See siblingKeyMap in macos_code_gen.dart.
      final List<String> names = (values as List<dynamic>).whereType<String>().toList();
      assert(names.length == 2);
      return MapEntry<String, List<String>>(name, names);
    });
  })();

  static int _sourceToPlane(String source, bool isPrintable) {
    if (isPrintable)
      return kUnicodePlane.value;
    switch (source) {
      case 'DOM':
        return kUnprintablePlane.value;
      case 'FLUTTER':
        return kFlutterPlane.value;
      default:
        assert(false, 'Unrecognized logical key source $source');
        return kFlutterPlane.value;
    }
  }
}


/// A single entry in the key data structure.
///
/// Can be read from JSON with the [LogicalKeyEntry.fromJsonMapEntry] constructor, or
/// written with the [toJson] method.
class LogicalKeyEntry {
  /// Creates a single key entry from available data.
  LogicalKeyEntry({
    required this.value,
    required this.name,
    this.keyLabel,
  })  : webNames = <String>[],
        macOSKeyCodeNames = <String>[],
        macOSKeyCodeValues = <int>[],
        iOSKeyCodeNames = <String>[],
        iOSKeyCodeValues = <int>[],
        gtkNames = <String>[],
        gtkValues = <int>[],
        windowsNames = <String>[],
        windowsValues = <int>[],
        androidNames = <String>[],
        androidValues = <int>[],
        fuchsiaValues = <int>[],
        glfwNames = <String>[],
        glfwValues = <int>[];

  LogicalKeyEntry.fromName({
    required int value,
    required String name,
    String? keyLabel,
  })  : this(
          value: value,
          name: name,
          keyLabel: keyLabel,
        );

  /// Populates the key from a JSON map.
  LogicalKeyEntry.fromJsonMapEntry(Map<String, dynamic> map)
    : value = map['value'] as int,
      name = map['name'] as String,
      webNames = _toNonEmptyArray<String>((map['names'] as Map<String, dynamic>)['web']),
      macOSKeyCodeNames = _toNonEmptyArray<String>((map['names'] as Map<String, dynamic>)['macos']),
      macOSKeyCodeValues = _toNonEmptyArray<int>((map['values'] as Map<String, dynamic>?)?['macos']),
      iOSKeyCodeNames = _toNonEmptyArray<String>((map['names'] as Map<String, dynamic>)['ios']),
      iOSKeyCodeValues = _toNonEmptyArray<int>((map['values'] as Map<String, dynamic>?)?['ios']),
      gtkNames = _toNonEmptyArray<String>((map['names'] as Map<String, dynamic>)['gtk']),
      gtkValues = _toNonEmptyArray<int>((map['values'] as Map<String, dynamic>?)?['gtk']),
      windowsNames = _toNonEmptyArray<String>((map['names'] as Map<String, dynamic>)['windows']),
      windowsValues = _toNonEmptyArray<int>((map['values'] as Map<String, dynamic>?)?['windows']),
      androidNames = _toNonEmptyArray<String>((map['names'] as Map<String, dynamic>)['android']),
      androidValues = _toNonEmptyArray<int>((map['values'] as Map<String, dynamic>?)?['android']),
      fuchsiaValues = _toNonEmptyArray<int>((map['values'] as Map<String, dynamic>?)?['fuchsia']),
      glfwNames = _toNonEmptyArray<String>((map['names'] as Map<String, dynamic>)['glfw']),
      glfwValues = _toNonEmptyArray<int>((map['values'] as Map<String, dynamic>?)?['glfw']),
      keyLabel = map['keyLabel'] as String?;

  final int value;

  final String name;

  /// The name of the key suitable for placing in comments.
  String get commentName => computeCommentName(name);

  String get constantName => computeConstantName(commentName);

  /// The name of the key, mostly derived from the DomKey name in Chromium,
  /// but where there was no DomKey representation, derived from the Chromium
  /// symbol name.
  final List<String> webNames;

  /// The names of the key codes that corresponds to this logical key on macOS,
  /// created from the corresponding physical keys.
  final List<String> macOSKeyCodeNames;

  /// The key codes that corresponds to this logical key on macOS, created from
  /// the physical key list substituted with the key mapping.
  final List<int> macOSKeyCodeValues;

  /// The names of the key codes that corresponds to this logical key on iOS,
  /// created from the corresponding physical keys.
  final List<String> iOSKeyCodeNames;

  /// The key codes that corresponds to this logical key on iOS, created from the
  /// physical key list substituted with the key mapping.
  final List<int> iOSKeyCodeValues;

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

  final List<int> fuchsiaValues;

  /// The list of names that GLFW gives to this key (symbol names minus the
  /// prefix).
  final List<String> glfwNames;

  /// The list of GLFW key codes matching this key, created by looking up the
  /// GLFW name in the Chromium data, and substituting the GLFW key code
  /// value.
  final List<int> glfwValues;

  /// A string indicating the letter on the keycap of a letter key.
  ///
  /// This is only used to generate the key label mapping in keyboard_map.dart.
  /// [LogicalKeyboardKey.keyLabel] uses a different definition and is generated
  /// differently.
  final String? keyLabel;

  /// Creates a JSON map from the key data.
  Map<String, dynamic> toJson() {
    return removeEmptyValues(<String, dynamic>{
      'name': name,
      'value': value,
      'keyLabel': keyLabel,
      'names': <String, dynamic>{
        'web': webNames,
        'macos': macOSKeyCodeNames,
        'ios': iOSKeyCodeNames,
        'gtk': gtkNames,
        'windows': windowsNames,
        'android': androidNames,
        'glfw': glfwNames,
      },
      'values': <String, List<int>>{
        'macos': macOSKeyCodeValues,
        'ios': iOSKeyCodeValues,
        'gtk': gtkValues,
        'windows': windowsValues,
        'android': androidValues,
        'fuchsia': fuchsiaValues,
        'glfw': glfwValues,
      },
    });
  }

  @override
  String toString() {
    return "'$name': (value: ${toHex(value)}) ";
  }

  /// Gets the named used for the key constant in the definitions in
  /// keyboard_key.dart.
  ///
  /// If set by the constructor, returns the name set, but otherwise constructs
  /// the name from the various different names available, making sure that the
  /// name isn't a Dart reserved word (if it is, then it adds the word "Key" to
  /// the end of the name).
  static String computeName(String rawName) {
    final String result = rawName.replaceAll('PinP', 'PInP');
    if (kDartReservedWords.contains(result)) {
      return '${result}Key';
    }
    return result;
  }

  /// Takes the [name] and converts it from lower camel case to capitalized
  /// separate words (e.g. "wakeUp" converts to "Wake Up").
  static String computeCommentName(String name) {
    final String replaced = name.replaceAllMapped(
      RegExp(r'(Digit|Numpad|Lang|Button|Left|Right)([0-9]+)'), (Match match) => '${match.group(1)} ${match.group(2)}',
    );
    return replaced
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

  static String computeConstantName(String commentName) {
    // Convert the first word in the comment name.
    final String lowerCamelSpace = commentName.replaceFirstMapped(RegExp(r'^[^ ]+'),
      (Match match) => match[0]!.toLowerCase(),
    );
    final String result = lowerCamelSpace.replaceAll(' ', '');
    if (kDartReservedWords.contains(result)) {
      return '${result}Key';
    }
    return result;
  }

  static int compareByValue(LogicalKeyEntry a, LogicalKeyEntry b) =>
      a.value.compareTo(b.value);
}
