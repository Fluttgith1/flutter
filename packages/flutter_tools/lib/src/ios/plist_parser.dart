// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';
import 'package:xml/xml.dart';

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../convert.dart';

class PlistParser {
  PlistParser({
    required final FileSystem fileSystem,
    required final Logger logger,
    required final ProcessManager processManager,
  }) : _fileSystem = fileSystem,
       _logger = logger,
       _processUtils = ProcessUtils(logger: logger, processManager: processManager);

  final FileSystem _fileSystem;
  final Logger _logger;
  final ProcessUtils _processUtils;

  static const String kCFBundleIdentifierKey = 'CFBundleIdentifier';
  static const String kCFBundleShortVersionStringKey = 'CFBundleShortVersionString';
  static const String kCFBundleExecutableKey = 'CFBundleExecutable';
  static const String kCFBundleVersionKey = 'CFBundleVersion';
  static const String kCFBundleDisplayNameKey = 'CFBundleDisplayName';
  static const String kMinimumOSVersionKey = 'MinimumOSVersion';
  static const String kNSPrincipalClassKey = 'NSPrincipalClass';

  static const String _plutilExecutable = '/usr/bin/plutil';

  /// Returns the content, converted to XML, of the plist file located at
  /// [plistFilePath].
  ///
  /// If [plistFilePath] points to a non-existent file or a file that's not a
  /// valid property list file, this will return null.
  ///
  /// The [plistFilePath] argument must not be null.
  String? plistXmlContent(final String plistFilePath) {
    if (!_fileSystem.isFileSync(_plutilExecutable)) {
      throw const FileNotFoundException(_plutilExecutable);
    }
    final List<String> args = <String>[
      _plutilExecutable, '-convert', 'xml1', '-o', '-', plistFilePath,
    ];
    try {
      final String xmlContent = _processUtils.runSync(
        args,
        throwOnError: true,
      ).stdout.trim();
      return xmlContent;
    } on ProcessException catch (error) {
      _logger.printError('$error');
      return null;
    }
  }

  /// Replaces the string key in the given plist file with the given value.
  ///
  /// If the value is null, then the key will be removed.
  ///
  /// Returns true if successful.
  bool replaceKey(final String plistFilePath, {required final String key, final String? value }) {
    if (!_fileSystem.isFileSync(_plutilExecutable)) {
      throw const FileNotFoundException(_plutilExecutable);
    }
    final List<String> args;
    if (value == null) {
      args = <String>[
        _plutilExecutable, '-remove', key, plistFilePath,
      ];
    } else {
      args = <String>[
        _plutilExecutable, '-replace', key, '-string', value, plistFilePath,
      ];
    }
    try {
      _processUtils.runSync(
        args,
        throwOnError: true,
      );
    } on ProcessException catch (error) {
      _logger.printError('$error');
      return false;
    }
    return true;
  }

  /// Parses the plist file located at [plistFilePath] and returns the
  /// associated map of key/value property list pairs.
  ///
  /// If [plistFilePath] points to a non-existent file or a file that's not a
  /// valid property list file, this will return an empty map.
  ///
  /// The [plistFilePath] argument must not be null.
  Map<String, Object> parseFile(final String plistFilePath) {
    if (!_fileSystem.isFileSync(plistFilePath)) {
      return const <String, Object>{};
    }

    final String normalizedPlistPath = _fileSystem.path.absolute(plistFilePath);

    final String? xmlContent = plistXmlContent(normalizedPlistPath);
    if (xmlContent == null) {
      return const <String, Object>{};
    }

    return _parseXml(xmlContent);
  }

  Map<String, Object> _parseXml(final String xmlContent) {
    final XmlDocument document = XmlDocument.parse(xmlContent);
    // First element child is <plist>. The first element child of plist is <dict>.
    final XmlElement dictObject = document.firstElementChild!.firstElementChild!;
    return _parseXmlDict(dictObject);
  }

  Map<String, Object> _parseXmlDict(final XmlElement node) {
    String? lastKey;
    final Map<String, Object> result = <String, Object>{};
    for (final XmlNode child in node.children) {
      if (child is XmlElement) {
        if (child.name.local == 'key') {
          lastKey = child.text;
        } else {
          assert(lastKey != null);
          result[lastKey!] = _parseXmlNode(child)!;
          lastKey = null;
        }
      }
    }

    return result;
  }

  static final RegExp _nonBase64Pattern = RegExp('[^a-zA-Z0-9+/=]+');

  Object? _parseXmlNode(final XmlElement node) {
    switch (node.name.local){
      case 'string':
        return node.text;
      case 'real':
        return double.parse(node.text);
      case 'integer':
        return int.parse(node.text);
      case 'true':
        return true;
      case 'false':
        return false;
      case 'date':
        return DateTime.parse(node.text);
      case 'data':
        return base64.decode(node.text.replaceAll(_nonBase64Pattern, ''));
      case 'array':
        return node.children.whereType<XmlElement>().map<Object?>(_parseXmlNode).whereType<Object>().toList();
      case 'dict':
        return _parseXmlDict(node);
    }
    return null;
  }

  /// Parses the Plist file located at [plistFilePath] and returns the string
  /// value that's associated with the specified [key] within the property list.
  ///
  /// If [plistFilePath] points to a non-existent file or a file that's not a
  /// valid property list file, this will return null.
  ///
  /// If [key] is not found in the property list, this will return null.
  ///
  /// The [plistFilePath] and [key] arguments must not be null.
  String? getStringValueFromFile(final String plistFilePath, final String key) {
    final Map<String, dynamic> parsed = parseFile(plistFilePath);
    return parsed[key] as String?;
  }
}
