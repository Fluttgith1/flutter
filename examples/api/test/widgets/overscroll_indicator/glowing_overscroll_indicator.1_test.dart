// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_api_samples/widgets/overscroll_indicator/glowing_overscroll_indicator.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test visibility', (WidgetTester tester) async {
    await tester.pumpWidget(const example.GlowingOverscrollIndicatorExampleApp());

    expect(find.descendant(
      of: find.byType(Scaffold),
      matching: find.widgetWithText(AppBar, 'GlowingOverscrollIndicator Sample'),
    ), findsOne);

    expect(find.descendant(
      of: find.byType(NestedScrollView),
      matching: find.widgetWithText(SliverAppBar, 'Custom NestedScrollViews'),
    ), findsOne);

    expect(find.descendant(
      of: find.byType(NestedScrollView),
      matching: find.widgetWithText(Center, 'Glow all day!'),
    ), findsOne);

    expect(find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(SliverToBoxAdapter),
    ), findsOne);

    expect(find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.widgetWithIcon(SliverFillRemaining, Icons.sunny),
    ), findsOne);

    expect(find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(GlowingOverscrollIndicator),
    ), findsOne);
  });

  testWidgets('Test behavior', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.GlowingOverscrollIndicatorExampleApp(),
    );

    final Finder customScrollViewFinder = find.byType(CustomScrollView);
    await tester.drag(customScrollViewFinder, const Offset(0, 500));
    await tester.pump();

    final RenderBox overscrollIndicator = tester.renderObject<RenderBox>(
      find.descendant(
        of: customScrollViewFinder,
        matching: find.byType(GlowingOverscrollIndicator),
      ),
    );
    final RenderSliver sliverAppBar = tester.renderObject<RenderSliver>(
      find.widgetWithText(SliverAppBar, 'Custom NestedScrollViews'),
    );
    final Matrix4 transform = overscrollIndicator.getTransformTo(sliverAppBar);
    final Offset? offset = MatrixUtils.getAsTranslation(transform);

    final BuildContext context = tester.element(customScrollViewFinder);
    final double headerHeight = MediaQuery.paddingOf(context).top + kToolbarHeight;
    expect(offset?.dy, headerHeight);
  });
}
