// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'basic.dart';
import 'framework.dart';
import 'text.dart';

/// Signature for a callback that passes a [String] representing a link that has
/// been tapped.
typedef LinkTapCallback = void Function(String linkString);

/// Singature for a function that builds the [Widget] output by [LinkedText].
///
/// Typically a [Text.rich] containing a [TextSpan] whose children are the
/// [linkedSpans].
typedef LinkedTextWidgetBuilder = Widget Function (
  BuildContext context,
  Iterable<InlineSpan> linkedSpans,
);

/// A widget that displays text with parts of it made interactive.
///
/// By default, any URLs in the text are made interactive, and clicking one
/// calls the provided callback.
///
/// Works with either a flat [String] (`text`) or a list of [InlineSpan]s
/// (`spans`). When using `spans`, only [TextSpan]s will be converted to links.
///
/// {@tool dartpad}
/// This example shows how to create a [LinkedText] that turns URLs into
/// working links.
///
/// ** See code in examples/api/lib/widgets/linked_text/linked_text.0.dart **
/// {@end-tool}
class LinkedText extends StatefulWidget {
  // TODO(justinmc): Update docs.
  /// Creates an instance of [LinkedText] from the given [text] or [spans],
  /// highlighting any URLs by default.
  ///
  /// {@template flutter.widgets.LinkedText.new}
  /// By default, highlights URLs in the [text] or [spans] and makes them
  /// tappable with [onTap].
  /// {@endtemplate}
  ///
  /// {@tool dartpad}
  /// This example shows how to create a [LinkedText] that turns URLs into
  /// working links.
  ///
  /// ** See code in examples/api/lib/widgets/linked_text/linked_text.0.dart **
  /// {@end-tool}
  ///
  /// {@tool dartpad}
  /// This example shows how to use [LinkedText] to link Twitter handles by
  /// passing in a custom [RegExp].
  ///
  /// ** See code in examples/api/lib/widgets/linked_text/linked_text.1.dart **
  /// {@end-tool}
  ///
  /// {@tool dartpad}
  /// This example shows how to use [LinkedText] to link URLs in a TextSpan tree
  /// instead of in a flat string.
  ///
  /// ** See code in examples/api/lib/widgets/linked_text/linked_text.2.dart **
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [LinkedText.textLinkers], which uses [TextLinker]s to allow full
  ///    control over matching and building different types of links.
  LinkedText({
    super.key,
    required this.onTap,
    this.builder = _defaultBuilder,
    // TODO(justinmc): Should it be possible to pass a TextRangesFinder?
    this.regExp,
    List<InlineSpan>? spans,
    String? text,
  }) : assert((text == null) != (spans == null), 'Must specify exactly one to link: either text or spans.'),
       spans = spans ?? <InlineSpan>[
         TextSpan(
           text: text,
         ),
       ],
       textLinkers = null;

  /// Creates an instance of [LinkedText] where the given [textLinkers] are
  /// applied.
  ///
  /// {@template flutter.widgets.LinkedText.textLinkers}
  /// Useful for independently matching different types of strings with
  /// different behaviors. For example, highlighting both URLs and Twitter
  /// handles with different style and/or behavior.
  /// {@endtemplate}
  ///
  /// The [TextLinker.textRangesFinder] must not produce overlapping
  /// [TextRange]s.
  ///
  /// See also:
  ///
  ///  * [TextLinker.regExp], which can be used to easily create a [TextLinker]
  ///    from a given [RegExp].
  ///  * [LinkedText.new], which can be passed [TextRange]s directly or
  ///    otherwise matches URLs by default.
  LinkedText.textLinkers({
    super.key,
    this.builder = _defaultBuilder,
    String? text,
    List<InlineSpan>? spans,
    required List<TextLinker> textLinkers,
  }) : assert((text == null) != (spans == null), 'Must specify exactly one to link: either text or spans.'),
       assert(textLinkers.isNotEmpty),
       textLinkers = textLinkers, // ignore: prefer_initializing_formals
       spans = spans ?? <InlineSpan>[
         TextSpan(
           text: text,
         ),
       ],
       onTap = null,
       regExp = null;

  /// The spans on which to create links.
  ///
  /// It's also possible to specify a plain string by using the `text`
  /// parameter instead.
  final List<InlineSpan> spans;

  /// Builds the [Widget] that is output by [LinkedText].
  ///
  /// By default, builds a [Text.rich] with a single [TextSpan] whose children
  /// are the linked [TextSpan]s, and whose style is [DefaultTextStyle].
  final LinkedTextWidgetBuilder builder;

  /// Handles tapping on a link.
  ///
  /// This is irrelevant when using [LinkedText.textLinkers], where this is
  /// controlled with an [InlineLinkBuilder] instead.
  final LinkTapCallback? onTap;

  /// Matches the text that should be turned into a link.
  ///
  /// This is irrelevant when using [LinkedText.textLinkers], where this is
  /// controlled with an [TextRangesFinder] instead.
  ///
  /// {@tool dartpad}
  /// This example shows how to use [LinkedText] to link Twitter handles by
  /// passing in a custom [RegExp].
  ///
  /// ** See code in examples/api/lib/widgets/linked_text/linked_text.1.dart **
  /// {@end-tool}
  final RegExp? regExp;

  /// Defines what parts of the text to match and how to link them.
  ///
  /// [TextLinker]s are applied in the order given. Overlapping matches are not
  /// supported and will produce an error.
  final List<TextLinker>? textLinkers;

  static final RegExp _urlRegExp = RegExp(r'(?<!@[a-zA-Z0-9-]*)(?<![\/\.a-zA-Z0-9-])((https?:\/\/)?(([a-zA-Z0-9-]*\.)*[a-zA-Z0-9-]+(\.[a-zA-Z]+)+))(?::\d{1,5})?(?:\/[^\s]*)?(?:\?[^\s#]*)?(?:#[^\s]*)?(?![a-zA-Z0-9-]*@)');

  /// The default value of [builder].
  ///
  /// Builds a [Text.rich] with a single [TextSpan] whose children are the
  /// linked [TextSpan]s, and whose style is [DefaultTextStyle]. If there are no
  /// linked [TextSpan]s to display, builds a [SizedBox.shrink].
  static Widget _defaultBuilder(BuildContext context, Iterable<InlineSpan> linkedSpans) {
    if (linkedSpans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text.rich(
      TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: linkedSpans.toList(),
      ),
    );
  }

  static Color get _linkColor {
    return switch (defaultTargetPlatform) {
      // This value was taken from Safari on an iPhone 14 Pro iOS 16.4
      // simulator.
      TargetPlatform.iOS => const Color(0xff1717f0),
      // This value was taken from Chrome on macOS 13.4.1.
      TargetPlatform.macOS => const Color(0xff0000ee),
      // This value was taken from Chrome on Android 14.
      TargetPlatform.android || TargetPlatform.fuchsia => const Color(0xff0e0eef),
      // This value was taken from the Chrome browser running on GNOME 43.3 on
      // Debian.
      TargetPlatform.linux => const Color(0xff0026e8),
      // This value was taken from the Edge browser running on Windows 10.
      TargetPlatform.windows => const Color(0xff1e2b8b),
    };
  }

  /// The style used for the link by default if none is given.
  @visibleForTesting
  static TextStyle defaultLinkStyle = TextStyle(
    color: _linkColor,
    decorationColor: _linkColor,
    decoration: TextDecoration.underline,
  );

  /// A [TextRangesFinder] that returns [TextRange]s for URLs.
  ///
  /// Matches full (https://www.example.com/?q=1) and shortened (example.com)
  /// URLs.
  ///
  /// Excludes:
  ///
  ///   * URLs with any protocol other than http or https.
  ///   * Email addresses.
  static final TextRangesFinder defaultTextRangesFinder = TextLinker.textRangesFinderFromRegExp(_urlRegExp);

  @override
  State<LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<LinkedText> {
  final List<GestureRecognizer> _recognizers = <GestureRecognizer>[];
  late Iterable<InlineSpan> _linkedSpans;
  late final List<TextLinker> _textLinkers;

  void _disposeRecognizers() {
    for (final GestureRecognizer recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  void _linkSpans() {
    _disposeRecognizers();
    final Iterable<InlineSpan> linkedSpans = TextLinker.linkSpans(
      widget.spans,
      _textLinkers,
    );
    _linkedSpans = linkedSpans;
  }

  @override
  void initState() {
    super.initState();
    _textLinkers = widget.textLinkers ?? <TextLinker>[
       TextLinker(
         textRangesFinder: widget.regExp == null
             ? LinkedText.defaultTextRangesFinder
             : TextLinker.textRangesFinderFromRegExp(widget.regExp!),
         linkBuilder: (String displayString, String linkString) {
           final TapGestureRecognizer recognizer = TapGestureRecognizer()
               ..onTap = () => widget.onTap!(linkString);
           // Keep track of created recognizers so that they can be disposed.
           _recognizers.add(recognizer);
           return _InlineLinkSpan(
             recognizer: recognizer,
             style: LinkedText.defaultLinkStyle,
             text: displayString,
           );
         },
       ),
     ];
    _linkSpans();
  }

  @override
  void didUpdateWidget(LinkedText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.spans != oldWidget.spans || widget.textLinkers != oldWidget.textLinkers) {
      _linkSpans();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _linkedSpans);
  }
}

/// An inline, interactive text link.
///
/// See also:
///
///  * [LinkedText], which creates links with this class by default.
class _InlineLinkSpan extends TextSpan {
  /// Create an instance of [_InlineLinkSpan].
  _InlineLinkSpan({
    required String text,
    TextStyle? style,
    super.recognizer,
  }) : super(
    style: style ?? defaultLinkStyle,
    mouseCursor: SystemMouseCursors.click,
    text: text,
  );

  static Color get _linkColor {
    return switch (defaultTargetPlatform) {
      // This value was taken from Safari on an iPhone 14 Pro iOS 16.4
      // simulator.
      TargetPlatform.iOS => const Color(0xff1717f0),
      // This value was taken from Chrome on macOS 13.4.1.
      TargetPlatform.macOS => const Color(0xff0000ee),
      // This value was taken from Chrome on Android 14.
      TargetPlatform.android || TargetPlatform.fuchsia => const Color(0xff0e0eef),
      // This value was taken from the Chrome browser running on GNOME 43.3 on
      // Debian.
      TargetPlatform.linux => const Color(0xff0026e8),
      // This value was taken from the Edge browser running on Windows 10.
      TargetPlatform.windows => const Color(0xff1e2b8b),
    };
  }

  /// The style used for the link by default if none is given.
  @visibleForTesting
  static TextStyle defaultLinkStyle = TextStyle(
    color: _linkColor,
    decorationColor: _linkColor,
    decoration: TextDecoration.underline,
  );
}
