// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Can hit test flex children of stacks', (WidgetTester tester) async {
    bool didReceiveTap = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: const Color(0xFF00FF00),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: 10.0,
                left: 10.0,
                child: Column(
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        didReceiveTap = true;
                      },
                      child: Container(
                        color: const Color(0xFF0000FF),
                        width: 100.0,
                        height: 100.0,
                        child: const Center(
                          child: Text('X', textDirection: TextDirection.ltr),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('X'));
    expect(didReceiveTap, isTrue);
  });

  testWidgets('Flexible defaults to loose', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Row(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          Flexible(child: SizedBox(width: 100.0, height: 200.0)),
        ],
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(SizedBox));
    expect(box.size.width, 100.0);
  });

  testWidgets("Doesn't overflow because of floating point accumulated error", (WidgetTester tester) async {
    // both of these cases have failed in the past due to floating point issues
    await tester.pumpWidget(
      const Center(
        child: SizedBox(
          height: 400.0,
          child: Column(
            children: <Widget>[
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      const Center(
        child: SizedBox(
          height: 199.0,
          child: Column(
            children: <Widget>[
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  });

  testWidgets('Error information is printed correctly', (WidgetTester tester) async {
    // We run this twice, the first time without an error, so that the second time
    // we only get a single exception. Otherwise we'd get two, the one we want and
    // an extra one when we discover we never computed a size.
    await tester.pumpWidget(
      const Column(
        children: <Widget>[
          Column(),
        ],
      ),
      duration: Duration.zero,
      phase: EnginePhase.layout,
    );

    // Turn off intrinsics checking, which also fails with the same exception.
    debugCheckIntrinsicSizes = false;
    await tester.pumpWidget(
      Column(
        children: <Widget>[
          Column(
            children: <Widget>[
              Expanded(child: Container()),
            ],
          ),
        ],
      ),
      duration: Duration.zero,
      phase: EnginePhase.layout,
    );
    debugCheckIntrinsicSizes = true;
    final String message = tester.takeException().toString();
    expect(message, contains('\nSee also:'));
  });

  testWidgets('Can set and update clipBehavior', (WidgetTester tester) async {
    await tester.pumpWidget(const Flex(direction: Axis.vertical));
    final RenderFlex renderObject = tester.allRenderObjects.whereType<RenderFlex>().first;
    expect(renderObject.clipBehavior, equals(Clip.none));

    await tester.pumpWidget(const Flex(direction: Axis.vertical, clipBehavior: Clip.antiAlias));
    expect(renderObject.clipBehavior, equals(Clip.antiAlias));
  });

  test('Flex/Column/Row can be const-constructed', () {
    const Flex(direction: Axis.vertical);
    const Column();
    const Row();
  });

  testWidgets('Default Flex.spacing value', (WidgetTester tester) async {
    await tester.pumpWidget(const Flex(direction: Axis.vertical));

    final Flex flex = tester.widget(find.byType(Flex));
    expect(flex.spacing, 0.0);
  });

  testWidgets('Can update Flex.spacing value', (WidgetTester tester) async {
    Widget buildFlex({ required double spacing }) {
      return Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Flex(
            spacing: spacing,
            direction: Axis.vertical,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                height: 100.0,
                width: 100.0,
                color: const Color(0xFFFF0000),
              ),
              Container(
                height: 100.0,
                width: 100.0,
                color: const Color(0xFF0000FF),
              ),
              Container(
                height: 100.0,
                width: 100.0,
                color: const Color(0xff00FF00),
              ),
            ],
          ),
        ),
      );
    }
    await tester.pumpWidget(buildFlex(spacing: 8.0));

    RenderFlex renderObject = tester.allRenderObjects.whereType<RenderFlex>().first;
    expect(renderObject.spacing, equals(8.0));
    expect(tester.getSize(find.byType(Flex)).width, equals(100.0));
    expect(tester.getSize(find.byType(Flex)).height, equals(316.0));

    await tester.pumpWidget(buildFlex(spacing: 18.0));

    renderObject = tester.allRenderObjects.whereType<RenderFlex>().first;
    expect(renderObject.spacing, equals(18.0));
    expect(tester.getSize(find.byType(Flex)).width, equals(100.0));
    expect(tester.getSize(find.byType(Flex)).height, equals(336.0));
  });
}
