// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';

void main() {
  // Constants taken from _ContextMenuSheetActionState.
  const Color _kBackgroundColor = Color(0xFFEEEEEE);
  const Color _kBackgroundColorPressed = Color(0xFFDDDDDD);

  Widget _getApp([VoidCallback onPressed]) {
    final UniqueKey actionKey = UniqueKey();
    final ContextMenuSheetAction action = ContextMenuSheetAction(
      key: actionKey,
      child: Text('I am a ContextMenuSheetAction'),
      onPressed: onPressed,
    );

    return CupertinoApp(
      home: CupertinoPageScaffold(
        child: Center(
          child: action,
        ),
      ),
    );
  }

  BoxDecoration _getDecoration(WidgetTester tester) {
    Finder finder = find.descendant(
      of: find.byType(ContextMenuSheetAction),
      matching: find.byType(Container),
    );
    expect(finder, findsOneWidget);
    final Container container = tester.widget(finder);
    return container.decoration;
  }

  testWidgets('responds to taps', (WidgetTester tester) async {
    bool wasPressed = false;
    await tester.pumpWidget(_getApp(() {
      wasPressed = true;
    }));

    expect(wasPressed, false);
    await tester.tap(find.byType(ContextMenuSheetAction));
    expect(wasPressed, true);
  });

  testWidgets('turns grey when pressed and held', (WidgetTester tester) async {
    await tester.pumpWidget(_getApp());
    expect(_getDecoration(tester).color, _kBackgroundColor);

    final Offset actionCenter = tester.getCenter(find.byType(ContextMenuSheetAction));
    final TestGesture gesture = await tester.startGesture(actionCenter);
    await tester.pump();
    expect(_getDecoration(tester).color, _kBackgroundColorPressed);

    await gesture.up();
    await tester.pump();
    expect(_getDecoration(tester).color, _kBackgroundColor);
  });
}
