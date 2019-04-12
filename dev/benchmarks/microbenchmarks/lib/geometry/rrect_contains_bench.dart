// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:ui';

import '../common.dart';

const int _kNumIters = 10000;

void main() {
  final Stopwatch watch = Stopwatch();
  print('RRect contains benchmark...');
  watch.start();
  for (int i = 0; i < _kNumIters; i += 1) {
    RRect outter = RRect.fromLTRBR(10, 10, 20, 20, const Radius.circular(2.0));
    outter.contains(const Offset(15, 15));
  }
  watch.stop();

  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();
  printer.addResult(
    description: 'RRect contains',
    value: watch.elapsedMicroseconds / _kNumIters,
    unit: 'µs per iteration',
    name: 'rrect_contains_iteration',
  );
  printer.printToStdout();
}
