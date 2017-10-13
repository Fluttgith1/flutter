// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';

void main() {
  testWidgets('onTap detection with canceled pointer and a drag listener', (WidgetTester tester) async {
    int detector1TapCount = 0;
    int detector2TapCount = 0;

    final Widget widget = new GestureDetector(
        child: new Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              new GestureDetector(
                  onTap: () => detector1TapCount++,
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(width: 200.0, height: 200.0),
              ),
              new GestureDetector(
                onTap: () => detector2TapCount++,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(width: 200.0, height: 200.0)
              )
            ],
          ));

    await tester.pumpWidget(widget);

    // The following pointer event sequence was causing the issue described
    // in issue #12470 by triggering 2 tap events on the second detector.
    final TestGesture gesture1 = await tester.startGesture(const Offset(400.0, 10.0), pointer: 1);
    final TestGesture gesture2 = await tester.startGesture(const Offset(400.0, 210.0), pointer: 2);
    await gesture1.up();
    await gesture2.cancel();
    final TestGesture gesture3 = await tester.startGesture(const Offset(400.0, 250.0), pointer: 3);
    await gesture3.up();

    expect(detector1TapCount, 1);
    expect(detector2TapCount, 1);
  });
}
