// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/heroes/hero.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Hero flight animation with default rect tween', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.HeroApp(),
    );

    expect(find.text('Hero Sample'), findsOneWidget);
    await tester.tap(find.byType(Container).first);
    await tester.pump();

    Size heroSize = tester.getSize(find.byType(Container).first);
    expect(heroSize, const Size(50.0, 50.0));

    // Jump 25% into the transition (total length = 300ms)
    await tester.pump(const Duration(milliseconds: 75)); // 25% of 300ms
    heroSize = tester.getSize(find.byType(Container).first);
    expect(heroSize.width.roundToDouble(), 88.0);
    expect(heroSize.height.roundToDouble(), 59.0);

    // Jump to 50% into the transition.
    await tester.pump(const Duration(milliseconds: 75)); // 25% of 300ms
    heroSize = tester.getSize(find.byType(Container).first);
    expect(heroSize.width.roundToDouble(), 170.0);
    expect(heroSize.height.roundToDouble(), 141.0);

    // Jump to 75% into the transition.
    await tester.pump(const Duration(milliseconds: 75)); // 25% of 300ms
    heroSize = tester.getSize(find.byType(Container).first);
    expect(heroSize.width.roundToDouble(), 195.0);
    expect(heroSize.height.roundToDouble(), 188.0);

    // Jump to 100% into the transition.
    await tester.pump(const Duration(milliseconds: 75)); // 25% of 300ms
    heroSize = tester.getSize(find.byType(Container).first);
    expect(heroSize, const Size(200.0, 200.0));

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();

    // Jump 25% into the transition (total length = 300ms)
    await tester.pump(const Duration(milliseconds: 75)); // 25% of 300ms
    heroSize = tester.getSize(find.byType(Container).first);
    expect(heroSize.width.roundToDouble(), 195.0);
    expect(heroSize.height.roundToDouble(), 188.0);

    // Jump to 50% into the transition.
    await tester.pump(const Duration(milliseconds: 75)); // 25% of 300ms
    heroSize = tester.getSize(find.byType(Container).first);
    expect(heroSize.width.roundToDouble(), 170.0);
    expect(heroSize.height.roundToDouble(), 141.0);

    // Jump to 75% into the transition.
    await tester.pump(const Duration(milliseconds: 75)); // 25% of 300ms
    heroSize = tester.getSize(find.byType(Container).first);
    expect(heroSize.width.roundToDouble(), 88.0);
    expect(heroSize.height.roundToDouble(), 59.0);

    // Jump to 100% into the transition.
    await tester.pump(const Duration(milliseconds: 75)); // 25% of 300ms
    heroSize = tester.getSize(find.byType(Container).first);
    expect(heroSize, const Size(50.0, 50.0));
  });

  testWidgets('Hero flight animation with custom rect tween', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.HeroApp(),
    );

    expect(find.text('Hero Sample'), findsOneWidget);
    await tester.tap(find.byType(Container).last);
    await tester.pump();

    Size heroSize = tester.getSize(find.byType(Container).last);
    expect(heroSize, const Size(50.0, 50.0));

    // Jump 25% into the transition (total length = 300ms)
    await tester.pump(const Duration(milliseconds: 75)); // 25% of 300ms
    heroSize = tester.getSize(find.byType(Container).last);
    expect(heroSize.width.roundToDouble(), 86.0);
    expect(heroSize.height.roundToDouble(), 86.0);

    // Jump to 50% into the transition.
    await tester.pump(const Duration(milliseconds: 75)); // 25% of 300ms
    heroSize = tester.getSize(find.byType(Container).last);
    expect(heroSize.width.roundToDouble(), 166.0);
    expect(heroSize.height.roundToDouble(), 166.0);

    // Jump to 75% into the transition.
    await tester.pump(const Duration(milliseconds: 75)); // 25% of 300ms
    heroSize = tester.getSize(find.byType(Container).first);
    expect(heroSize.width.roundToDouble(), 195.0);
    expect(heroSize.height.roundToDouble(), 188.0);

    // Jump to 100% into the transition.
    await tester.pump(const Duration(milliseconds: 75)); // 25% of 300ms
    heroSize = tester.getSize(find.byType(Container).last);
    expect(heroSize, const Size(200.0, 200.0));

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();

    // Jump 25% into the transition (total length = 300ms)
    await tester.pump(const Duration(milliseconds: 75)); // 25% of 300ms
    heroSize = tester.getSize(find.byType(Container).last);
    expect(heroSize.width.roundToDouble(), 194.0);
    expect(heroSize.height.roundToDouble(), 194.0);

    // Jump to 50% into the transition.
    await tester.pump(const Duration(milliseconds: 75)); // 25% of 300ms
    heroSize = tester.getSize(find.byType(Container).last);
    expect(heroSize.width.roundToDouble(), 166.0);
    expect(heroSize.height.roundToDouble(), 166.0);

    // Jump to 75% into the transition.
    await tester.pump(const Duration(milliseconds: 75)); // 25% of 300ms
    heroSize = tester.getSize(find.byType(Container).last);
    expect(heroSize.width.roundToDouble(), 86.0);
    expect(heroSize.height.roundToDouble(), 86.0);

    // Jump to 100% into the transition.
    await tester.pump(const Duration(milliseconds: 75)); // 25% of 300ms
    heroSize = tester.getSize(find.byType(Container).last);
    expect(heroSize, const Size(50.0, 50.0));
  });
}
