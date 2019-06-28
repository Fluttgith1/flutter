// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import '../common.dart';
import './button_matrix_app.dart' as button_matrix;

const int _kNumWarmUpIters = 20;
const int _kNumIters = 300;

Future<void> main() async {
  assert(false, "Don't run benchmarks in checked mode! Use 'flutter run --release'.");
  final Stopwatch watch = Stopwatch();
  print('GestureDetector semantics benchmark...');

  await benchmarkWidgets((WidgetTester tester) async {
    button_matrix.main();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    Future<void> iter() async {
      await tester.tapAt(const Offset(760.0, 30.0)); // Close drawer
      await tester.pump();
    }

    for (int i = 0; i < _kNumWarmUpIters; i += 1) {
      await iter();
    }

    watch.start();
    for (int i = 0; i < _kNumIters; i += 1) {
      await iter();
    }
    watch.stop();
  }, semanticsEnabled: true);

  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();
  printer.addResult(
    description: 'GestureDetector semantics',
    value: watch.elapsedMicroseconds / _kNumIters,
    unit: 'µs per iteration',
    name: 'gesture_detector_semantics_bench',
  );
  printer.printToStdout();
}
