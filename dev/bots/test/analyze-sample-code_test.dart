// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'common.dart';

void main() {
  test('analyze-sample-code', () {
    final ProcessResult process = Process.runSync(
      '../../bin/cache/dart-sdk/bin/dart',
      <String>['analyze-sample-code.dart', 'test/analyze-sample-code-test-input'],
    );
    final List<String> stdoutLines = process.stdout.toString().split('\n');
    final List<String> stderrLines = process.stderr.toString().split('\n')
      ..removeWhere((String line) => line.startsWith('Analyzer output:'));
    final Match line = RegExp(
      r'Kept temporary directory (.+) because there were errors\.',
      multiLine: true,
    ).firstMatch(process.stderr);
    expect(line, isNotNull);
    final String directory = line[1];
    Directory(directory).deleteSync(recursive: true); // Clean up the messy temp dir.
    expect(process.exitCode, isNot(equals(0)));
    expect(stderrLines, <String>[
      'Kept temporary directory $directory because there were errors.',
      '',
      'known_broken_documentation.dart:27:9: new Opacity(',
      '>>> Unnecessary new keyword (unnecessary_new)',
      'known_broken_documentation.dart:39:9: new Opacity(',
      '>>> Unnecessary new keyword (unnecessary_new)',
      '',
      'Found 1 sample code errors.',
      '',
    ]);
    expect(stdoutLines, <String>['Found 2 sample code sections.', 'Starting analysis of samples.', '']);
  }, skip: Platform.isWindows);
}
