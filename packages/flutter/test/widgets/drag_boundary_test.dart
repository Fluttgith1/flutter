// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('test DragBoundary<Rect> with useGlobalPosition', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Container(
        margin: const EdgeInsets.only(top: 100, left: 100),
        alignment: Alignment.topLeft,
        child: DragBoundaryProvider(
          child: SizedBox(
            key: key,
            width: 100,
            height: 100,
          ),
        ),
      ),
    );
    final DragBoundary<Rect>? boundary = DragBoundaryProvider.forRectOf(key.currentContext!, useGlobalPosition: true);
    expect(boundary, isNotNull);
    expect(boundary!.isWithinBoundary(const Rect.fromLTWH(50, 50, 20, 20)), isFalse);
    expect(boundary.isWithinBoundary(const Rect.fromLTWH(100, 100, 20, 20)), isTrue);
    expect(boundary.nearestPositionWithinBoundary(const Rect.fromLTWH(50, 50, 20, 20)), const Rect.fromLTWH(100, 100, 20, 20));
    expect(boundary.nearestPositionWithinBoundary(const Rect.fromLTWH(150, 150, 20, 20)), const Rect.fromLTWH(150, 150, 20, 20));
  });

  testWidgets('test DragBoundary<Rect> without useGlobalPosition', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Container(
        margin: const EdgeInsets.only(top: 100, left: 100),
        alignment: Alignment.topLeft,
        child: DragBoundaryProvider(
          child: SizedBox(
            key: key,
            width: 100,
            height: 100,
          ),
        ),
      ),
    );
    final DragBoundary<Rect>? boundary = DragBoundaryProvider.forRectOf(key.currentContext!);
    expect(boundary, isNotNull);
    expect(boundary!.isWithinBoundary(const Rect.fromLTWH(50, 50, 20, 20)), isTrue);
    expect(boundary.isWithinBoundary(const Rect.fromLTWH(90, 90, 20, 20)), isFalse);
    expect(boundary.nearestPositionWithinBoundary(const Rect.fromLTWH(50, 50, 20, 20)), const Rect.fromLTWH(50, 50, 20, 20));
    expect(boundary.nearestPositionWithinBoundary(const Rect.fromLTWH(90, 90, 20, 20)), const Rect.fromLTWH(80, 80, 20, 20));
  });
}
