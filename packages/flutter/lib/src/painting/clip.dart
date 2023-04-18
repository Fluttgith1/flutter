// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Canvas, Clip, Paint, Path, RRect, Rect, VoidCallback;

/// Clip utilities used by [PaintingContext].
abstract class ClipContext {
  /// The canvas on which to paint.
  Canvas get canvas;

  void _clipAndPaint(final void Function(bool doAntiAlias) canvasClipCall, final Clip clipBehavior, final Rect bounds, final VoidCallback painter) {
    canvas.save();
    switch (clipBehavior) {
      case Clip.none:
        break;
      case Clip.hardEdge:
        canvasClipCall(false);
      case Clip.antiAlias:
        canvasClipCall(true);
      case Clip.antiAliasWithSaveLayer:
        canvasClipCall(true);
        canvas.saveLayer(bounds, Paint());
    }
    painter();
    if (clipBehavior == Clip.antiAliasWithSaveLayer) {
      canvas.restore();
    }
    canvas.restore();
  }

  /// Clip [canvas] with [Path] according to [Clip] and then paint. [canvas] is
  /// restored to the pre-clip status afterwards.
  ///
  /// `bounds` is the saveLayer bounds used for [Clip.antiAliasWithSaveLayer].
  void clipPathAndPaint(final Path path, final Clip clipBehavior, final Rect bounds, final VoidCallback painter) {
    _clipAndPaint((final bool doAntiAlias) => canvas.clipPath(path, doAntiAlias: doAntiAlias), clipBehavior, bounds, painter);
  }

  /// Clip [canvas] with [Path] according to `rrect` and then paint. [canvas] is
  /// restored to the pre-clip status afterwards.
  ///
  /// `bounds` is the saveLayer bounds used for [Clip.antiAliasWithSaveLayer].
  void clipRRectAndPaint(final RRect rrect, final Clip clipBehavior, final Rect bounds, final VoidCallback painter) {
    _clipAndPaint((final bool doAntiAlias) => canvas.clipRRect(rrect, doAntiAlias: doAntiAlias), clipBehavior, bounds, painter);
  }

  /// Clip [canvas] with [Path] according to `rect` and then paint. [canvas] is
  /// restored to the pre-clip status afterwards.
  ///
  /// `bounds` is the saveLayer bounds used for [Clip.antiAliasWithSaveLayer].
  void clipRectAndPaint(final Rect rect, final Clip clipBehavior, final Rect bounds, final VoidCallback painter) {
    _clipAndPaint((final bool doAntiAlias) => canvas.clipRect(rect, doAntiAlias: doAntiAlias), clipBehavior, bounds, painter);
  }
}
