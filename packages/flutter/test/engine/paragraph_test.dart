// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:test/test.dart';

void main() {
  // Ahem font uses a constant ideographic/alphabetic baseline ratio.
  const double kAhemBaselineRatio = 1.1662499904632568;

  test('predictably lays out a single-line paragraph', () {
    for (double fontSize in <double>[10.0, 20.0, 30.0, 40.0]) {
      final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
        fontFamily: 'Ahem',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.normal,
        fontSize: fontSize,
      ));
      builder.addText('Test');
      final Paragraph paragraph = builder.build();
      paragraph.layout(ParagraphConstraints(width: 400.0));

      expect(paragraph.height, fontSize);
      expect(paragraph.width, 400.0);
      expect(paragraph.minIntrinsicWidth, fontSize * 4.0);
      expect(paragraph.maxIntrinsicWidth, fontSize * 4.0);
      expect(paragraph.alphabeticBaseline, fontSize * .8);
      expect(
        paragraph.ideographicBaseline,
        closeTo(paragraph.alphabeticBaseline * kAhemBaselineRatio, 0.001),
      );
    }
  });

  test('predictably lays out a multi-line paragraph', () {
    for (double fontSize in <double>[10.0, 20.0, 30.0, 40.0]) {
      final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
        fontFamily: 'Ahem',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.normal,
        fontSize: fontSize,
      ));
      builder.addText('Test Ahem');
      final Paragraph paragraph = builder.build();
      paragraph.layout(ParagraphConstraints(width: fontSize * 5.0));

      expect(paragraph.height, fontSize * 2.0); // because it wraps
      expect(paragraph.width, fontSize * 5.0);
      expect(paragraph.minIntrinsicWidth, fontSize * 4.0);

      // TODO(yjbanov): see https://github.com/flutter/flutter/issues/21965
      expect(paragraph.maxIntrinsicWidth, fontSize * 8.0);
      expect(paragraph.alphabeticBaseline, fontSize * .8);
      expect(
        paragraph.ideographicBaseline,
        closeTo(paragraph.alphabeticBaseline * kAhemBaselineRatio, 0.001),
      );
    }
  });
}
