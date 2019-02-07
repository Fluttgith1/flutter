// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf;

import '../../../raw/spinning_square.dart' as demo;

void main() {
  test('layers smoketest for raw/shader_warm_up.dart', () {
    demo.main();
  });
}
