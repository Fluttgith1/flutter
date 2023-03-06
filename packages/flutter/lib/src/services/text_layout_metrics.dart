// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show TextRange;

import 'text_editing.dart';

export 'dart:ui' show TextPosition, TextRange;

export 'text_editing.dart' show TextSelection;

/// A read-only interface for accessing visual information about the
/// implementing text.
abstract class TextLayoutMetrics {
  /// {@template flutter.services.TextLayoutMetrics.getLineAtOffset}
  /// Return a [TextSelection] containing the line of the given [TextPosition].
  /// {@endtemplate}
  TextSelection getLineAtOffset(TextPosition position);

  /// {@macro flutter.painting.TextPainter.getWordBoundary}
  TextRange getWordBoundary(TextPosition position);

  /// {@template flutter.services.TextLayoutMetrics.getTextPositionAbove}
  /// Returns the TextPosition above the given offset into the text.
  ///
  /// If the offset is already on the first line, the given offset will be
  /// returned.
  /// {@endtemplate}
  TextPosition getTextPositionAbove(TextPosition position);

  /// {@template flutter.services.TextLayoutMetrics.getTextPositionBelow}
  /// Returns the TextPosition below the given offset into the text.
  ///
  /// If the offset is already on the last line, the given offset will be
  /// returned.
  /// {@endtemplate}
  TextPosition getTextPositionBelow(TextPosition position);
}
