// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// Positions the toolbar above [anchorAbove] if it fits, or otherwise below
/// [anchorBelow].
///
/// See also:
///
///   * [TextSelectionToolbar], which uses this to position itself.
///   * [CupertinoTextSelectionToolbar], which also uses this to position
///     itself.
class TextSelectionToolbarLayoutDelegate extends SingleChildLayoutDelegate {
  /// Creates an instance of TextSelectionToolbarLayoutDelegate.
  TextSelectionToolbarLayoutDelegate({
    required this.anchorAbove,
    required this.anchorBelow,
    this.fitsAbove,
  });

  /// {@macro flutter.material.TextSelectionToolbar.anchorAbove}
  ///
  /// Should be provided in local coordinates.
  final Offset anchorAbove;

  /// {@macro flutter.material.TextSelectionToolbar.anchorAbove}
  ///
  /// Should be provided in local coordinates.
  final Offset anchorBelow;

  /// Whether or not the child should be considered to fit above anchorAbove.
  ///
  /// Typically used to force the child to be drawn at anchorAbove even when it
  /// doesn't fit, such as when the Material [TextSelectionToolbar] draws an
  /// open overflow menu.
  ///
  /// If not provided, it will be calculated.
  final bool? fitsAbove;

  /// Return the value that centers width as closely as possible to position
  /// while fitting inside of min and max.
  static double centerOn(final double position, final double width, final double max) {
    // If it overflows on the left, put it as far left as possible.
    if (position - width / 2.0 < 0.0) {
      return 0.0;
    }

    // If it overflows on the right, put it as far right as possible.
    if (position + width / 2.0 > max) {
      return max - width;
    }

    // Otherwise it fits while perfectly centered.
    return position - width / 2.0;
  }

  @override
  BoxConstraints getConstraintsForChild(final BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(final Size size, final Size childSize) {
    final bool fitsAbove = this.fitsAbove ?? anchorAbove.dy >= childSize.height;
    final Offset anchor = fitsAbove ? anchorAbove : anchorBelow;

    return Offset(
      centerOn(
        anchor.dx,
        childSize.width,
        size.width,
      ),
      fitsAbove
        ? math.max(0.0, anchor.dy - childSize.height)
        : anchor.dy,
    );
  }

  @override
  bool shouldRelayout(final TextSelectionToolbarLayoutDelegate oldDelegate) {
    return anchorAbove != oldDelegate.anchorAbove
        || anchorBelow != oldDelegate.anchorBelow
        || fitsAbove != oldDelegate.fitsAbove;
  }
}
