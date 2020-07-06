// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  test('Wrap test; toStringDeep', () {
    final RenderWrap renderWrap = RenderWrap();
    expect(renderWrap, hasAGoodToStringDeep);
    expect(
      renderWrap.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        'RenderWrap#00000 NEEDS-LAYOUT NEEDS-PAINT DETACHED\n'
        '   parentData: MISSING\n'
        '   constraints: MISSING\n'
        '   size: MISSING\n'
        '   direction: horizontal\n'
        '   alignment: start\n'
        '   spacing: 0.0\n'
        '   runAlignment: start\n'
        '   runSpacing: 0.0\n'
        '   crossAxisAlignment: 0.0\n'
      ),
    );
  });

  test('Compute intrinsic height test', () {
    final List<RenderBox> children = <RenderBox>[
      RenderConstrainedBox(
        additionalConstraints: const BoxConstraints(
          minWidth: 80,
          minHeight: 80,
        ),
      ),
      RenderConstrainedBox(
        additionalConstraints: const BoxConstraints(
          minWidth: 80,
          minHeight: 80,
        ),
      ),
      RenderConstrainedBox(
        additionalConstraints: const BoxConstraints(
          minWidth: 80,
          minHeight: 80,
        ),
      ),
    ];

    final RenderWrap renderWrap = RenderWrap();

    children.forEach(renderWrap.add);

    renderWrap.spacing = 5;
    renderWrap.runSpacing = 5;
    renderWrap.direction = Axis.horizontal;

    expect(renderWrap.computeMaxIntrinsicHeight(245), 165);
    expect(renderWrap.computeMaxIntrinsicHeight(250), 80);
    expect(renderWrap.computeMaxIntrinsicHeight(80), 250);
    expect(renderWrap.computeMaxIntrinsicHeight(79), 250);
    expect(renderWrap.computeMinIntrinsicHeight(245), 165);
    expect(renderWrap.computeMinIntrinsicHeight(250), 80);
    expect(renderWrap.computeMinIntrinsicHeight(80), 250);
    expect(renderWrap.computeMinIntrinsicHeight(79), 250);
  });

  test('Compute intrinsic width test', () {
    final List<RenderBox> children = <RenderBox>[
      RenderConstrainedBox(
        additionalConstraints: const BoxConstraints(
          minWidth: 80,
          minHeight: 80,
        ),
      ),
      RenderConstrainedBox(
        additionalConstraints: const BoxConstraints(
          minWidth: 80,
          minHeight: 80,
        ),
      ),
      RenderConstrainedBox(
        additionalConstraints: const BoxConstraints(
          minWidth: 80,
          minHeight: 80,
        ),
      ),
    ];

    final RenderWrap renderWrap = RenderWrap();

    children.forEach(renderWrap.add);

    renderWrap.spacing = 5;
    renderWrap.runSpacing = 5;
    renderWrap.direction = Axis.vertical;

    expect(renderWrap.computeMaxIntrinsicWidth(245), 165);
    expect(renderWrap.computeMaxIntrinsicWidth(250), 80);
    expect(renderWrap.computeMaxIntrinsicWidth(80), 250);
    expect(renderWrap.computeMaxIntrinsicWidth(79), 250);
    expect(renderWrap.computeMinIntrinsicWidth(245), 165);
    expect(renderWrap.computeMinIntrinsicWidth(250), 80);
    expect(renderWrap.computeMinIntrinsicWidth(80), 250);
    expect(renderWrap.computeMinIntrinsicWidth(79), 250);
  });

  test('Compute intrinsic height for only one run', () {
    final RenderBox child = RenderConstrainedBox(
      additionalConstraints: const BoxConstraints(
        minWidth: 80,
        minHeight: 80,
      ),
    );

    final RenderWrap renderWrap = RenderWrap();
    renderWrap.add(child);

    renderWrap.spacing = 5;
    renderWrap.runSpacing = 5;
    renderWrap.direction = Axis.horizontal;

    expect(renderWrap.computeMaxIntrinsicHeight(100), 80);
    expect(renderWrap.computeMaxIntrinsicHeight(79), 80);
    expect(renderWrap.computeMaxIntrinsicHeight(80), 80);
    expect(renderWrap.computeMinIntrinsicHeight(100), 80);
    expect(renderWrap.computeMinIntrinsicHeight(79), 80);
    expect(renderWrap.computeMinIntrinsicHeight(80), 80);
  });

  test('Compute intrinsic width for only one run', () {
    final RenderBox child = RenderConstrainedBox(
      additionalConstraints: const BoxConstraints(
        minWidth: 80,
        minHeight: 80,
      ),
    );

    final RenderWrap renderWrap = RenderWrap();
    renderWrap.add(child);

    renderWrap.spacing = 5;
    renderWrap.runSpacing = 5;
    renderWrap.direction = Axis.vertical;

    expect(renderWrap.computeMaxIntrinsicWidth(100), 80);
    expect(renderWrap.computeMaxIntrinsicWidth(79), 80);
    expect(renderWrap.computeMaxIntrinsicWidth(80), 80);
    expect(renderWrap.computeMinIntrinsicWidth(100), 80);
    expect(renderWrap.computeMinIntrinsicWidth(79), 80);
    expect(renderWrap.computeMinIntrinsicWidth(80), 80);
  });

  test('Wrap respects clipBehavior', () {
    const BoxConstraints viewport = BoxConstraints(maxHeight: 100.0, maxWidth: 100.0);
    final TestClipPaintingContext context = TestClipPaintingContext();

    // By default, clipBehavior should be Clip.none
    final RenderWrap defaultWrap = RenderWrap(textDirection: TextDirection.ltr, children: <RenderBox>[box200x200]);
    layout(defaultWrap, constraints: viewport, phase: EnginePhase.composite, onErrors: expectOverflowedErrors);
    defaultWrap.paint(context, Offset.zero);
    expect(context.clipBehavior, equals(Clip.none));

    for (final Clip clip in Clip.values) {
      final RenderWrap wrap = RenderWrap(textDirection: TextDirection.ltr, children: <RenderBox>[box200x200], clipBehavior: clip);
      layout(wrap, constraints: viewport, phase: EnginePhase.composite, onErrors: expectOverflowedErrors);
      wrap.paint(context, Offset.zero);
      expect(context.clipBehavior, equals(clip));
    }
  });
}
