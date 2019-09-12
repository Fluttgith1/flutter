// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('!chrome') // web has different stack traces

import 'package:flutter/foundation.dart';
import '../flutter_test_alternative.dart';

void main() {
  // TODO(ianh): These tests and the filtering mechanism should be revisited to
  // account for causal async stack traces. https://github.com/flutter/flutter/issues/8128
  test('FlutterError.defaultStackFilter', () {
    final List<String> filtered = FlutterError.defaultStackFilter(StackTrace.current.toString().trimRight().split('\n')).toList();
    expect(filtered.length, greaterThanOrEqualTo(4));
    expect(filtered[0], matches(r'^#0 +main\.<anonymous closure> \(.*stack_trace_test\.dart:[0-9]+:[0-9]+\)$'));
    expect(filtered[1], matches(r'^#1 +Declarer\.test\.<anonymous closure>.<anonymous closure>.<anonymous closure> \(package:test_api/.+:[0-9]+:[0-9]+\)$'));
    expect(filtered[2], equals('<asynchronous suspension>'));
    expect(filtered.last, matches(r'^\(elided [1-9][0-9]+ frames from package dart:async(, package dart:async-patch,)? and package stack_trace\)$'));
  });

  test('FlutterError.defaultStackFilter (async test body)', () async {
    final List<String> filtered = FlutterError.defaultStackFilter(StackTrace.current.toString().trimRight().split('\n')).toList();
    expect(filtered.length, greaterThanOrEqualTo(3));
    expect(filtered[0], matches(r'^#0 +main\.<anonymous closure> \(.*stack_trace_test\.dart:[0-9]+:[0-9]+\)$'));
    expect(filtered[1], equals('<asynchronous suspension>'));
    expect(filtered.last, matches(r'^\(elided [1-9][0-9]+ frames from package dart:async(, package dart:async-patch,)? and package stack_trace\)$'));
  });
}
