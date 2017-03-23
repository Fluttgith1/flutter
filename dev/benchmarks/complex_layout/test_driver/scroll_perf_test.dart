// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('scrolling performance test', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null)
        driver.close();
    });

    test('measure', () async {
      final Timeline timeline = await driver.traceAction(() async {
        // Find the scrollable stock list
        final SerializableFinder stockList = find.byValueKey('main-scroll');
        expect(stockList, isNotNull);

        // Scroll down
        for (int i = 0; i < 5; i++) {
          await driver.scroll(stockList, 0.0, -300.0, const Duration(milliseconds: 300));
          await new Future<Null>.delayed(const Duration(milliseconds: 500));
        }

        // Scroll up
        for (int i = 0; i < 5; i++) {
          await driver.scroll(stockList, 0.0, 300.0, const Duration(milliseconds: 300));
          await new Future<Null>.delayed(const Duration(milliseconds: 500));
        }
      });

      final TimelineSummary summary = new TimelineSummary.summarize(timeline);
      summary.writeSummaryToFile('complex_layout_scroll_perf', pretty: true);
      summary.writeTimelineToFile('complex_layout_scroll_perf', pretty: true);
    });
  });
}
