// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';

import 'basic.dart';
import 'framework.dart';
import 'text.dart';

/// A widget that displays text with parts of it made interactive.
///
/// By default, any URLs in the text are made interactive, and clicking one
/// calls [onTap].
///
/// Works with either a flat [String] ([text]) or a list of [InlineSpans]
/// ([spans]).
///
/// {@tool dartpad}
/// This example shows how to create a [LinkedText] that turns URLs into
/// working links.
///
/// ** See code in examples/api/lib/painting/linked_text/linked_text.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [InlineLinkedText], which is like this but is an inline TextSpan instead
///    of a widget.
class LinkedText extends StatefulWidget {
  /// Creates an instance of [LinkedText] from the given [text] or [spans],
  /// highlighting any URLs by default.
  ///
  /// {@template flutter.widgets.LinkedText.new}
  /// By default, highlights URLs in the [text] or [spans] and makes them
  /// tappable with [onTap].
  ///
  /// If [ranges] is given, then makes those ranges in the text interactive
  /// instead of URLs.
  ///
  /// [linkBuilder] can be used to specify a custom [InlineSpan] for each
  /// [TextRange] in [ranges].
  /// {@endtemplate}
  ///
  /// {@tool dartpad}
  /// This example shows how to create a [LinkedText] that turns URLs into
  /// working links.
  ///
  /// ** See code in examples/api/lib/painting/linked_text/linked_text.0.dart **
  /// {@end-tool}
  ///
  /// {@tool dartpad}
  /// This example shows how to use [LinkedText] to link URLs in a TextSpan tree
  /// instead of in a flat string.
  ///
  /// ** See code in examples/api/lib/painting/linked_text/linked_text.3.dart **
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [LinkedText.regExp], which automatically finds ranges that match
  ///    the given [RegExp].
  ///  * [LinkedText.textLinkers], which uses [TextLinker]s to allow
  ///    specifying an arbitrary number of [ranges] and [linkBuilders].
  ///  * [InlineLinkedText.new], which is like this, but for inline text.
  LinkedText({
    super.key,
    required LinkTapCallback onTap,
    String? text,
    List<InlineSpan>? spans,
    this.style,
    Iterable<TextRange>? ranges,
    // TODO(justinmc): Maybe shouldn't take something that takes a recognizer here, should be callback?
    LinkBuilder? linkBuilder,
  }) : assert(text != null || spans != null, 'Must specify something to link: either text or spans.'),
       assert(text == null || spans == null, 'Pass one of spans or text, not both.'),
       textLinkers = <TextLinker>[
         TextLinker(
           rangesFinder: ranges == null
               ? InlineLinkedText.defaultRangesFinder
               : (String text) => ranges,
           linkBuilder: linkBuilder ?? InlineLinkedText.getDefaultLinkBuilder(onTap),
         ),
       ],
       spans = spans ?? <InlineSpan>[
         TextSpan(
           text: text,
         ),
       ];

  /// Create an instance of [LinkedText] where text matched by the given
  /// [RegExp] is made interactive.
  ///
  /// {@tool dartpad}
  /// This example shows how to use [LinkedText.regExp] to link Twitter handles.
  ///
  /// ** See code in examples/api/lib/painting/linked_text/linked_text.1.dart **
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [LinkedText.new], which can be passed [TextRange]s directly or
  ///    otherwise matches URLs by default.
  ///  * [LinkedText.textLinkers], which uses [TextLinker]s to allow
  ///    specifying an arbitrary number of [ranges] and [linkBuilders].
  ///  * [InlineLinkedText.regExp], which is like this, but for inline text.
  LinkedText.regExp({
    super.key,
    required LinkTapCallback onTap,
    String? text,
    List<InlineSpan>? spans,
    required RegExp regExp,
    this.style,
    LinkBuilder? linkBuilder,
  }) : assert(text != null || spans != null, 'Must specify something to link: either text or spans.'),
       assert(text == null || spans == null, 'Pass one of spans or text, not both.'),
       textLinkers = <TextLinker>[
         TextLinker(
           rangesFinder: TextLinker.rangesFinderFromRegExp(regExp),
           linkBuilder: linkBuilder ?? InlineLinkedText.getDefaultLinkBuilder(onTap),
         ),
       ],
       spans = spans ?? <InlineSpan>[
         TextSpan(
           text: text,
         ),
       ];

  /// Create an instance of [LinkedText] where text matched by the given
  /// [RegExp] is made interactive.
  ///
  /// {@template flutter.widgets.LinkedText.textLinkers}
  /// Useful for independently matching different types of strings with
  /// different behaviors. For example, highlighting both URLs and Twitter
  /// handles with different style and/or behavior.
  /// {@endtemplate}
  ///
  /// {@tool dartpad}
  /// This example shows how to use [LinkedText.textLinkers] to link both URLs
  /// and Twitter handles independently.
  ///
  /// ** See code in examples/api/lib/painting/linked_text/linked_text.2.dart **
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [LinkedText.new], which can be passed [TextRange]s directly or
  ///    otherwise matches URLs by default.
  ///  * [LinkedText.regExp], which automatically finds ranges that match
  ///    the given [RegExp].
  ///  * [InlineLinkedText.textLinkers], which is like this, but for inline
  ///    text.
  LinkedText.textLinkers({
    super.key,
    String? text,
    List<InlineSpan>? spans,
    required this.textLinkers,
    this.style,
  }) : assert(text != null || spans != null, 'Must specify something to link: either text or spans.'),
       assert(text == null || spans == null, 'Pass one of spans or text, not both.'),
       spans = spans ?? <InlineSpan>[
         TextSpan(
           text: text,
         ),
       ],
       assert(textLinkers.isNotEmpty);

  /// The spans on which to create links by applying [textLinkers].
  final List<InlineSpan> spans;

  /// Defines what parts of the text to match and how to link them.
  ///
  /// [TextLinker]s are applied in the order given. Overlapping matches are not
  /// supported.
  late final List<TextLinker> textLinkers;

  /// The [TextStyle] to apply to the output [InlineSpan].
  ///
  /// If not provided, the [DefaultTextStyle] at this point in the tree will be
  /// used.
  final TextStyle? style;

  @override
  State<LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<LinkedText> {
  final GlobalKey _textKey = GlobalKey();

  static void _disposeRecognizers(Text text) {
    final InlineLinkedText inlineLinkedText = text.textSpan! as InlineLinkedText;
    for (final GestureRecognizer recognizer in inlineLinkedText.recognizers) {
      recognizer.dispose();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers(_textKey.currentWidget! as Text);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Text? text = _textKey.currentWidget as Text?;
    if (text != null) {
      _disposeRecognizers(text);
    }

    if (widget.spans.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text.rich(
      key: _textKey,
      InlineLinkedText.textLinkers(
        style: widget.style ?? DefaultTextStyle.of(context).style,
        textLinkers: widget.textLinkers,
        spans: widget.spans,
      ),
    );
  }
}
