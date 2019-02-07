import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

const String kCullOpacityRouteName = '/cull_opacity';
const String kCubicBezierRouteName = '/cubic_bezier';

void macroPerfTest(
    String testName,
    String routeName,
    {Duration pageDelay, Duration duration = const Duration(seconds: 3)}) {
  test(testName, () async {
    final FlutterDriver driver = await FlutterDriver.connect();

    // The slight initial delay avoids starting the timing during a
    // period of increased load on the device. Without this delay, the
    // benchmark has greater noise.
    // See: https://github.com/flutter/flutter/issues/19434
    await Future<void>.delayed(const Duration(milliseconds: 250));

    await driver.forceGC();

    final SerializableFinder button = find.byValueKey(routeName);
    expect(button, isNotNull);
    await driver.tap(button);

    if (pageDelay != null) {
      // Wait for the page to load
      await Future<void>.delayed(pageDelay);
    }

    final Timeline timeline = await driver.traceAction(() async {
      await Future<void>.delayed(duration);
    });

    final TimelineSummary summary = TimelineSummary.summarize(timeline);
    summary.writeSummaryToFile(testName, pretty: true);
    summary.writeTimelineToFile(testName, pretty: true);

    driver.close();
  });
}
