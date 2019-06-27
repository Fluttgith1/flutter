// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('MatrixUtils.getAsTranslation()', () {
    Matrix4 test;
    test = Matrix4.identity();
    expect(MatrixUtils.getAsTranslation(test), equals(Offset.zero));
    test = Matrix4.zero();
    expect(MatrixUtils.getAsTranslation(test), isNull);
    test = Matrix4.rotationX(1.0);
    expect(MatrixUtils.getAsTranslation(test), isNull);
    test = Matrix4.rotationZ(1.0);
    expect(MatrixUtils.getAsTranslation(test), isNull);
    test = Matrix4.translationValues(1.0, 2.0, 0.0);
    expect(MatrixUtils.getAsTranslation(test), equals(const Offset(1.0, 2.0)));
    test = Matrix4.translationValues(1.0, 2.0, 3.0);
    expect(MatrixUtils.getAsTranslation(test), isNull);

    test = Matrix4.identity();
    expect(MatrixUtils.getAsTranslation(test), equals(Offset.zero));
    test.rotateX(2.0);
    expect(MatrixUtils.getAsTranslation(test), isNull);

    test = Matrix4.identity();
    expect(MatrixUtils.getAsTranslation(test), equals(Offset.zero));
    test.scale(2.0);
    expect(MatrixUtils.getAsTranslation(test), isNull);

    test = Matrix4.identity();
    expect(MatrixUtils.getAsTranslation(test), equals(Offset.zero));
    test.translate(2.0, -2.0);
    expect(MatrixUtils.getAsTranslation(test), equals(const Offset(2.0, -2.0)));
    test.translate(4.0, 8.0);
    expect(MatrixUtils.getAsTranslation(test), equals(const Offset(6.0, 6.0)));
  });

  test('cylindricalProjectionTransform identity', () {
    final Matrix4 initialState = MatrixUtils.createCylindricalProjectionTransform(
      radius: 0.0,
      angle: 0.0,
      perspective: 0.0,
    );

    expect(initialState, Matrix4.identity());
  });

  test('cylindricalProjectionTransform rotate with no radius', () {
    final Matrix4 simpleRotate = MatrixUtils.createCylindricalProjectionTransform(
      radius: 0.0,
      angle: pi / 2.0,
      perspective: 0.0,
    );

    expect(simpleRotate, Matrix4.rotationX(pi / 2.0));
  });

  test('cylindricalProjectionTransform radius does not change scale', () {
    final Matrix4 noRotation = MatrixUtils.createCylindricalProjectionTransform(
      radius: 1000000.0,
      angle: 0.0,
      perspective: 0.0,
    );

    expect(noRotation, Matrix4.identity());
  });

  test('cylindricalProjectionTransform calculation spot check', () {
    final Matrix4 actual = MatrixUtils.createCylindricalProjectionTransform(
      radius: 100.0,
      angle: pi / 3.0,
      perspective: 0.001,
    );

    expect(actual.storage, <dynamic>[
      1.0, 0.0, 0.0, 0.0,
      0.0, moreOrLessEquals(0.5), moreOrLessEquals(0.8660254037844386), moreOrLessEquals(-0.0008660254037844386),
      0.0, moreOrLessEquals(-0.8660254037844386), moreOrLessEquals(0.5), moreOrLessEquals(-0.0005),
      0.0, moreOrLessEquals(-86.60254037844386), moreOrLessEquals(-50.0), 1.05,
    ]);
  });

  test('forceToPoint', () {
    const Offset forcedOffset = Offset(20, -30);
    final Matrix4 forcedTransform = MatrixUtils.forceToPoint(forcedOffset);

    expect(
      MatrixUtils.transformPoint(forcedTransform, forcedOffset),
      forcedOffset,
    );

    expect(
      MatrixUtils.transformPoint(forcedTransform, Offset.zero),
      forcedOffset,
    );

    expect(
      MatrixUtils.transformPoint(forcedTransform, const Offset(1, 1)),
      forcedOffset,
    );

    expect(
      MatrixUtils.transformPoint(forcedTransform, const Offset(-1, -1)),
      forcedOffset,
    );

    expect(
      MatrixUtils.transformPoint(forcedTransform, const Offset(-20, 30)),
      forcedOffset,
    );

    expect(
      MatrixUtils.transformPoint(forcedTransform, const Offset(-1.2344, 1422434.23)),
      forcedOffset,
    );
  });

  test('transformRect with no perspective (w = 1)', () {
    const Rect l10t20r30b40 = Rect.fromLTRB(10, 20, 30, 40);
    const Rect l20t40r60b80 = Rect.fromLTRB(20, 40, 60, 80);

    // Identity
    expect(
      MatrixUtils.transformRect(Matrix4.identity(), l10t20r30b40),
      l10t20r30b40,
    );

    // 2D Scaling
    expect(
      MatrixUtils.transformRect(Matrix4.diagonal3Values(2, 2, 2), l10t20r30b40),
      l20t40r60b80,
    );

    // Rotation
    expect(
      MatrixUtils.transformRect(Matrix4.rotationZ(pi / 2.0), l10t20r30b40),
      within<Rect>(distance: 0.00001, from: const Rect.fromLTRB(-40.0, 10.0, -20.0, 30.0)),
    );
  });

  test('transformRect with perspective (w != 1)', () {
    final Matrix4 transform = MatrixUtils.createCylindricalProjectionTransform(
      radius: 10.0,
      angle: pi / 8.0,
      perspective: 0.3,
    );

    for (int i = 1; i < 10000; i++) {
      final Rect rect = Rect.fromLTRB(11.0 * i, 12.0 * i, 15.0 * i, 18.0 * i);
      final Rect golden = _vectorWiseTransformRect(transform, rect);
      expect(MatrixUtils.transformRect(transform, rect), golden);
    }
  });
}

// Produces the same computation as `MatrixUtils.transformRect` but it does this
// one point at a time. This function is used as the golden implementation of the
// optimized `MatrixUtils.transformRect` to make sure optimizations do not contain
// bugs.
Rect _vectorWiseTransformRect(Matrix4 transform, Rect rect) {
  final Offset point1 = MatrixUtils.transformPoint(transform, rect.topLeft);
  final Offset point2 = MatrixUtils.transformPoint(transform, rect.topRight);
  final Offset point3 = MatrixUtils.transformPoint(transform, rect.bottomLeft);
  final Offset point4 = MatrixUtils.transformPoint(transform, rect.bottomRight);
  return Rect.fromLTRB(
      _min4(point1.dx, point2.dx, point3.dx, point4.dx),
      _min4(point1.dy, point2.dy, point3.dy, point4.dy),
      _max4(point1.dx, point2.dx, point3.dx, point4.dx),
      _max4(point1.dy, point2.dy, point3.dy, point4.dy),
  );
}

double _min4(double a, double b, double c, double d) {
  return min(a, min(b, min(c, d)));
}

double _max4(double a, double b, double c, double d) {
  return max(a, max(b, max(c, d)));
}
