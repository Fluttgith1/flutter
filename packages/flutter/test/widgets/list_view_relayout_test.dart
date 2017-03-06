// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  testWidgets('Nested ListView with shrinkWrap', (WidgetTester tester) async {
    await tester.pumpWidget(new ListView(
      shrinkWrap: true,
      children: <Widget>[
        new ListView(
          shrinkWrap: true,
          children: <Widget>[
            new Text('1'),
            new Text('2'),
            new Text('3'),
          ],
        ),
        new ListView(
          shrinkWrap: true,
          children: <Widget>[
            new Text('4'),
            new Text('5'),
            new Text('6'),
          ],
        ),
      ],
    ));
  });

  testWidgets('Underflowing ListView should relayout for additional children', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/5950

    await tester.pumpWidget(new ListView(
      children: <Widget>[
        new SizedBox(height: 100.0, child: new Text('100')),
      ],
    ));

    await tester.pumpWidget(new ListView(
      children: <Widget>[
        new SizedBox(height: 100.0, child: new Text('100')),
        new SizedBox(height: 200.0, child: new Text('200')),
      ],
    ));

    expect(find.text('200'), findsOneWidget);
  });

  testWidgets('Underflowing ListView contentExtent should track additional children', (WidgetTester tester) async {
    await tester.pumpWidget(new ListView(
      children: <Widget>[
        new SizedBox(height: 100.0, child: new Text('100')),
      ],
    ));

    final RenderSliverList list = tester.renderObject(find.byType(SliverList));
    expect(list.geometry.scrollExtent, equals(100.0));

    await tester.pumpWidget(new ListView(
      children: <Widget>[
        new SizedBox(height: 100.0, child: new Text('100')),
        new SizedBox(height: 200.0, child: new Text('200')),
      ],
    ));
    expect(list.geometry.scrollExtent, equals(300.0));

    await tester.pumpWidget(new ListView(
      children: <Widget>[]
    ));
    expect(list.geometry.scrollExtent, equals(0.0));
  });

  testWidgets('Overflowing ListView should relayout for missing children', (WidgetTester tester) async {
    await tester.pumpWidget(new ListView(
      children: <Widget>[
        new SizedBox(height: 300.0, child: new Text('300')),
        new SizedBox(height: 400.0, child: new Text('400')),
      ],
    ));

    expect(find.text('300'), findsOneWidget);
    expect(find.text('400'), findsOneWidget);

    await tester.pumpWidget(new ListView(
      children: <Widget>[
        new SizedBox(height: 300.0, child: new Text('300')),
      ],
    ));

    expect(find.text('300'), findsOneWidget);
    expect(find.text('400'), findsNothing);

    await tester.pumpWidget(new ListView(
      children: <Widget>[]
    ));

    expect(find.text('300'), findsNothing);
    expect(find.text('400'), findsNothing);
  });

  testWidgets('Overflowing ListView should not relayout for additional children', (WidgetTester tester) async {
    await tester.pumpWidget(new ListView(
      children: <Widget>[
        new SizedBox(height: 300.0, child: new Text('300')),
        new SizedBox(height: 400.0, child: new Text('400')),
      ],
    ));

    expect(find.text('300'), findsOneWidget);
    expect(find.text('400'), findsOneWidget);

    await tester.pumpWidget(new ListView(
      children: <Widget>[
        new SizedBox(height: 300.0, child: new Text('300')),
        new SizedBox(height: 400.0, child: new Text('400')),
        new SizedBox(height: 100.0, child: new Text('100')),
      ],
    ));

    expect(find.text('300'), findsOneWidget);
    expect(find.text('400'), findsOneWidget);
    expect(find.text('100'), findsNothing);

    final RenderSliverList list = tester.renderObject(find.byType(SliverList));
    expect(list.geometry.scrollExtent, equals(700.0));
  });

  testWidgets('Overflowing ListView should become scrollable', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/5920
    // When a ListView's viewport hasn't overflowed, scrolling is disabled.
    // When children are added that cause it to overflow, scrolling should
    // be enabled.

    await tester.pumpWidget(new ListView(
      children: <Widget>[
        new SizedBox(height: 100.0, child: new Text('100')),
      ],
    ));

    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, 0.0);

    await tester.pumpWidget(new ListView(
      children: <Widget>[
        new SizedBox(height: 100.0, child: new Text('100')),
        new SizedBox(height: 200.0, child: new Text('200')),
        new SizedBox(height: 400.0, child: new Text('400')),
      ],
    ));

    expect(scrollable.position.maxScrollExtent, 100.0);
  });

}
