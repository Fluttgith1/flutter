// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../localization/localizations_utils.dart';

import '../common.dart';

void main() {
  group('generateString', () {
    test('handles simple string', () {
      expect(generateString('abc'), "'abc'");
    });

    test('handles string with quote', () {
      expect(generateString("ab'c"), '''"ab'c"''');
    });

    test('handles string with double quote', () {
      expect(generateString('ab"c'), """'ab"c'""");
    });

    test('handles string with both single and double quote', () {
      expect(generateString('''a'b"c'''), """'''a'b"c'''""");
    });

    test('handles string with a triple single quote and a double quote', () {
      expect(generateString("""a"b'''c"""), '''"""a"b\'''c"""''');
    });

    test('handles string with a triple double quote and a single quote', () {
      expect(generateString('''a'b"""c'''), """'''a'b\"""c'''""");
    });

    test('handles string with both triple single and triple double quote', () {
      expect(generateString('''a\'''\'''\''b"""c'''), """'a' "'''"  "'''" '''''b\"""c'''""");
    });

    test('handles dollar', () {
      expect(generateString(r'ab$c'), r"r'ab$c'");
    });

    test('handles backslash', () {
      expect(generateString(r'ab\c'), r"r'ab\c'");
    });

    test("doesn't support multiline strings", () {
      expect(() => generateString('ab\nc'), throwsA(isA<AssertionError>()));
    });
  });
}