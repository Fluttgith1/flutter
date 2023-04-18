// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/reorderable_list/reorderable_list_view.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> longPressDrag(final WidgetTester tester, final Offset start, final Offset end) async {
    final TestGesture drag = await tester.startGesture(start);
    await tester.pump(kLongPressTimeout + kPressTimeout);
    await drag.moveTo(end);
    await tester.pump(kPressTimeout);
    await drag.up();
  }

  testWidgets('Reorder list item', (final WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: example.ReorderableApp(),
      ),
    );

    expect(tester.getCenter(find.text('Item 3')).dy, 252.0);
    await longPressDrag(
      tester,
      tester.getCenter(find.text('Item 3')),
      tester.getCenter(find.text('Item 2')),
    );
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.text('Item 3')).dy, 196.0);
  });
}
