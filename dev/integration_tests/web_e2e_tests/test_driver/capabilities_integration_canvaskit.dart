// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_e2e_tests/capabilities_main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // When the app is run using 'web-renderer=auto' and the targetPlatform isDesktop,
  // the app should be using canvasKit.
  final bool isDesktop = _isDesktop(defaultTargetPlatform);

  testWidgets('Capabilities integration test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    final Finder textFinder = find.byKey(const Key('isCanvaskit bool is true'));
    expect(textFinder, findsOneWidget);
    final Text text = tester.widget(textFinder);
    expect(text.data, 'The app is canvasKit');
  }, skip: !isDesktop); // [intended] text.data should verify isCanvasKit is true
  // when the targetPlatform isDesktop.
}

bool _isDesktop(TargetPlatform targetPlatform) {
  final bool isDesktop;
    switch (targetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        isDesktop = false;
        break;
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        isDesktop = true;
        break;
    }
    return isDesktop;
}
