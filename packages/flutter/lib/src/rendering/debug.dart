// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';

/// Causes each RenderBox to paint a box around its bounds, and some extra
/// boxes, such as RenderPadding, to draw construction lines.
bool debugPaintSizeEnabled = false;

/// The color to use when painting RenderObject bounds.
Color debugPaintSizeColor = const Color(0xFF00FFFF);

/// The color to use when painting some boxes that just add space (e.g. an empty
/// RenderConstrainedBox or RenderPadding).
Color debugPaintSpacingColor = const Color(0x90909090);

/// The color to use when painting RenderPadding edges.
Color debugPaintPaddingColor = const Color(0x900090FF);

/// The color to use when painting RenderPadding edges.
Color debugPaintPaddingInnerEdgeColor = const Color(0xFF0090FF);

/// The color to use when painting the arrows used to show RenderPositionedBox alignment.
Color debugPaintArrowColor = const Color(0xFFFFFF00);

/// Causes each RenderBox to paint a line at each of its baselines.
bool debugPaintBaselinesEnabled = false;

/// The color to use when painting alphabetic baselines.
Color debugPaintAlphabeticBaselineColor = const Color(0xFF00FF00);

/// The color ot use when painting ideographic baselines.
Color debugPaintIdeographicBaselineColor = const Color(0xFFFFD000);

/// Causes each Layer to paint a box around its bounds.
bool debugPaintLayerBordersEnabled = false;

/// The color to use when painting Layer borders.
Color debugPaintLayerBordersColor = const Color(0xFFFF9800);

/// Causes RenderBox objects to flash while they are being tapped.
bool debugPaintPointersEnabled = false;

/// The color to use when reporting pointers.
int debugPaintPointersColorValue = 0x00BBBB;

/// Overlay a rotating set of colors when repainting layers in checked mode.
bool debugRepaintRainbowEnabled = false;

/// The current color to overlay when repainting a layer.
HSVColor debugCurrentRepaintColor = const HSVColor.fromAHSV(0.4, 60.0, 1.0, 1.0);

/// The amount to increment the hue of the current repaint color.
double debugRepaintRainbowHueIncrement = 2.0;

/// Log the call stacks that mark render objects as needing paint.
bool debugPrintMarkNeedsPaintStacks = false;

/// Log the call stacks that mark render objects as needing layout.
bool debugPrintMarkNeedsLayoutStacks = false;

/// Check the intrinsic sizes of each [RenderBox] during layout.
bool debugCheckIntrinsicSizes = false;

List<String> debugDescribeTransform(Matrix4 transform) {
  List<String> matrix = transform.toString().split('\n').map((String s) => '  $s').toList();
  matrix.removeLast();
  return matrix;
}
