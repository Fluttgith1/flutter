// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'inline_link.dart';
import 'inline_span.dart';
import 'text_span.dart';
import 'text_style.dart';

// TODO(justinmc): On some platforms, may want to underline link?

/// A callback that passes a [String] representing a link that has been tapped.
typedef LinkTapCallback = void Function(String linkString);

/// Builds an [InlineSpan] for displaying a link on [displayString] linking to
/// [linkString].
///
/// Creates a [TapGestureRecognizer] and returns it so that its lifecycle can be
/// maintained by the caller.
///
/// {@template flutter.painting.LinkBuilder.recognizer}
/// It's necessary to call [TapGestureRecognizer.dispose] on the returned
/// recognizer when the owning widget is disposed. See [TextSpan.recognizer].
/// {@endtemplate}
typedef LinkBuilder = (InlineSpan, TapGestureRecognizer) Function(
  String displayString,
  String linkString,
);

/// Finds [TextRange]s in the given [String].
typedef RangesFinder = Iterable<TextRange> Function(String text);

/// A [TextSpan] that makes parts of the [text] interactive.
///
/// This class generates [TapGestureRecognizer]s to handle taps on any links,
/// and the owning widget is responsible for managing the lifecycle of these
/// recognizers. Access the recognizers at [InlineLinkedText.recognizers] and
/// call [TapGestureRecognizer.dispose] whenever the owning widget is rebuilt or
/// disposed.
///
/// {@tool dartpad}
/// This example shows how to create an [InlineLinkedText] and manage its
/// [InlineLinkedText.recognizers].
///
/// ** See code in examples/api/lib/painting/inline_linked_text/inline_linked_text.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [LinkedText], which is a widget that performs the same functionality.
class InlineLinkedText extends TextSpan {
  /// Create an instance of [InlineLinkedText].
  ///
  /// {@macro flutter.widgets.LinkedText.new}
  ///
  /// See also:
  ///
  ///  * [InlineLinkedText.regExp], which automatically finds ranges that match
  ///    the given [RegExp].
  ///  * [InlineLinkedText.textLinkers], which uses [TextLinker]s to allow
  ///    specifying an arbitrary number of [ranges] and [linkBuilders].
  factory InlineLinkedText({
    // TODO(justinmc): Why is style required?
    required TextStyle style,
    LinkBuilder? linkBuilder,
    LinkTapCallback? onTap,
    Iterable<TextRange>? ranges,
    List<InlineSpan>? spans,
    String? text,
  }) {
    assert(text != null || spans != null, 'Must specify something to link: either text or spans.');
    assert(text == null || spans == null, 'Pass one of spans or text, not both.');
    assert(linkBuilder != null || onTap != null);
    final RangesFinder rangesFinder = ranges != null
      ? (String text) => ranges
      : defaultRangesFinder;
    final TextLinker textLinker = TextLinker(
      rangesFinder: rangesFinder,
      linkBuilder: linkBuilder ?? getDefaultLinkBuilder(onTap!),
    );
    final (Iterable<InlineSpan> linkedSpans, Iterable<TapGestureRecognizer> recognizers) =
        text == null
            ? linkSpans(spans!, <TextLinker>[textLinker])
            : textLinker.getSpans(text);
    return InlineLinkedText._(
      recognizers: recognizers,
      style: style,
      children: linkedSpans.toList(),
    );
  }

  /// Create an instance of [InlineLinkedText] where the text matched by the
  /// given [regExp] is made interactive.
  ///
  /// See also:
  ///
  ///  * [InlineLinkedText.new], which can be passed [TextRange]s directly or
  ///    otherwise matches URLs by default.
  ///  * [InlineLinkedText.textLinkers], which uses [TextLinker]s to allow
  ///    specifying an arbitrary number of [ranges] and [linkBuilders].
  factory InlineLinkedText.regExp({
    required RegExp regExp,
    required TextStyle style,
    LinkTapCallback? onTap,
    LinkBuilder? linkBuilder,
    String? text,
    List<InlineSpan>? spans,
  }) {
    assert(text != null || spans != null, 'Must specify something to link: either text or spans.');
    assert(text == null || spans == null, 'Pass one of spans or text, not both.');
    assert(linkBuilder != null || onTap != null);

    final TextLinker textLinker = TextLinker(
      rangesFinder: TextLinker.rangesFinderFromRegExp(regExp),
      linkBuilder: linkBuilder ?? getDefaultLinkBuilder(onTap!),
    );
    final (Iterable<InlineSpan> linkedSpans, Iterable<TapGestureRecognizer> recognizers) =
        text == null
            ? linkSpans(spans!, <TextLinker>[textLinker])
            : textLinker.getSpans(text);

    return InlineLinkedText._(
      recognizers: recognizers,
      style: style,
      children: linkedSpans.toList(),
    );
  }

  /// Create an instance of [InlineLinkedText] with the given [textLinkers]
  /// applied.
  ///
  /// {@macro flutter.widgets.LinkedText.textLinkers}
  ///
  /// See also:
  ///
  ///  * [InlineLinkedText.new], which can be passed [TextRange]s directly or
  ///    otherwise matches URLs by default.
  ///  * [InlineLinkedText.regExp], which automatically finds ranges that match
  ///    the given [RegExp].
  factory InlineLinkedText.textLinkers({
    required TextStyle style,
    required Iterable<TextLinker> textLinkers,
    String? text,
    List<InlineSpan>? spans,
  }) {
    assert(text != null || spans != null, 'Must specify something to link: either text or spans.');
    assert(text == null || spans == null, 'Pass one of spans or text, not both.');
    final (Iterable<InlineSpan> linkedSpans, Iterable<TapGestureRecognizer> recognizers) =
        text == null
            ? linkSpans(spans!, textLinkers)
            : TextLinker.getSpansForMany(textLinkers, text);

    return InlineLinkedText._(
      recognizers: recognizers,
      style: style,
      children: linkedSpans.toList(),
    );
  }

  const InlineLinkedText._({
    super.style,
    super.children,
    required this.recognizers,
  });

  /// Any [TapGestureRecognizer]s that have been generated for handling taps on
  /// the links and whose lifecycle must be maintained by the
  /// [InlineLinkedText]'s owner.
  ///
  /// Call [dispose] on these recognizers before throwing away this
  /// [InlineLinkedText].
  ///
  /// See also:
  ///  * [TextSpan.recognizer], which explains the need to manage the lifecycle
  ///    of [GestureRecognizer]s created in [InlineSpan]s.
  ///  * [InlineLinkedText], which has a full example of managing these
  ///    recognizers.
  final Iterable<TapGestureRecognizer> recognizers;

  static final RegExp _urlRegExp = RegExp(r'(?<!@[a-zA-Z0-9-]*)(?<![\/\.a-zA-Z0-9-])((https?:\/\/)?(([a-zA-Z0-9-]*\.)*[a-zA-Z0-9-]+(\.[a-zA-Z]+)+))(?::\d{1,5})?(?:\/[^\s]*)?(?:\?[^\s#]*)?(?:#[^\s]*)?(?![a-zA-Z0-9-]*@)');

  /// A [RangesFinder] that returns [TextRange]s for URLs.
  ///
  /// Matches full (https://www.example.com/?q=1) and shortened (example.com)
  /// URLs.
  ///
  /// Excludes:
  ///
  ///   * URLs with any protocol other than http or https.
  ///   * Email addresses.
  static final RangesFinder defaultRangesFinder = TextLinker.rangesFinderFromRegExp(_urlRegExp);

  /// Finds urls in text and replaces them with a plain, platform-specific link.
  static Iterable<TextLinker> defaultTextLinkers(LinkTapCallback onTap) {
    return <TextLinker>[
      TextLinker(
        rangesFinder: defaultRangesFinder,
        linkBuilder: getDefaultLinkBuilder(onTap),
      ),
    ];
  }

  /// Returns a [LinkBuilder] that highlights the given text and sets the given
  /// [onTap] handler.
  static LinkBuilder getDefaultLinkBuilder(LinkTapCallback onTap) {
    return (String displayString, String linkString) {
      final TapGestureRecognizer recognizer = TapGestureRecognizer()
          ..onTap = () => onTap(linkString);
      return (
        InlineLink(
          recognizer: recognizer,
          text: displayString,
        ),
        recognizer,
      );
    };
  }

  static List<_TextLinkerMatch> _cleanTextLinkerMatches(Iterable<_TextLinkerMatch> textLinkerMatches) {
    final List<_TextLinkerMatch> nextTextLinkerMatches = textLinkerMatches.toList();

    // Sort by start.
    nextTextLinkerMatches.sort((_TextLinkerMatch a, _TextLinkerMatch b) {
      return a.textRange.start.compareTo(b.textRange.start);
    });

    int lastEnd = 0;
    nextTextLinkerMatches.removeWhere((_TextLinkerMatch textLinkerMatch) {
      // Return empty ranges.
      if (textLinkerMatch.textRange.start == textLinkerMatch.textRange.end) {
        return true;
      }

      // Remove overlapping ranges.
      final bool overlaps = textLinkerMatch.textRange.start < lastEnd;
      if (!overlaps) {
        lastEnd = textLinkerMatch.textRange.end;
      }
      return overlaps;
    });

    return nextTextLinkerMatches;
  }

  /// Apply the given [TextLinker]s to the given [InlineSpan]s and return the
  /// new resulting spans and any created [TapGestureRecognizer]s.
  ///
  /// {@macro flutter.painting.LinkBuilder.recognizer}
  static (Iterable<InlineSpan>, Iterable<TapGestureRecognizer>) linkSpans(Iterable<InlineSpan> spans, Iterable<TextLinker> textLinkers) {
    // Flatten the spans and find all ranges in the flat String. This must be done
    // cumulatively, and not during a traversal, because matches may occur across
    // span boundaries.
    final List<({InlineSpan span, int length})> spansWithLength =
        <({InlineSpan span, int length})>[];
    String spansText = '';
    for (final InlineSpan span in spans) {
      final String string = span.toPlainText();
      spansText += string;
      spansWithLength.add((
        span: span,
        length: string.length,
      ));
    }
    final Iterable<_TextLinkerMatch> textLinkerMatches =
        _cleanTextLinkerMatches(
          _TextLinkerMatch.fromTextLinkers(textLinkers, spansText),
        );

    final (Iterable<InlineSpan> output, Iterable<_TextLinkerMatch> _, Iterable<TapGestureRecognizer> recognizers) =
        _linkSpansRecursive(spansWithLength, textLinkerMatches, 0);
    return (output, recognizers);
  }

  static (Iterable<InlineSpan>, Iterable<_TextLinkerMatch>, Iterable<TapGestureRecognizer>) _linkSpansRecursive(Iterable<({InlineSpan span, int length})> spansWithLength, Iterable<_TextLinkerMatch> textLinkerMatches, int index) {
    final List<InlineSpan> output = <InlineSpan>[];
    Iterable<_TextLinkerMatch> nextTextLinkerMatches = textLinkerMatches;
    final List<TapGestureRecognizer> recognizers = <TapGestureRecognizer>[];
    int nextIndex = index;
    for (final (span: InlineSpan span, length: int length) in spansWithLength) {
      final (InlineSpan childSpan, Iterable<_TextLinkerMatch> childTextLinkerMatches, Iterable<TapGestureRecognizer> childRecognizers) = _linkSpanRecursive(
        span,
        nextTextLinkerMatches,
        nextIndex,
      );
      output.add(childSpan);
      nextTextLinkerMatches = childTextLinkerMatches;
      recognizers.addAll(childRecognizers);
      nextIndex += length;
    }

    return (output, nextTextLinkerMatches, recognizers);
  }

  // index is the index of the start of `span` in the overall flattened tree
  // string.
  //
  // The TapGestureRecognizers must be disposed by an owning widget.
  static (InlineSpan, Iterable<_TextLinkerMatch>, Iterable<TapGestureRecognizer>) _linkSpanRecursive(InlineSpan span, Iterable<_TextLinkerMatch> textLinkerMatches, int index) {
    if (span is! TextSpan) {
      return (span, textLinkerMatches, <TapGestureRecognizer>[]);
    }

    final List<InlineSpan> nextChildren = <InlineSpan>[];
    final List<TapGestureRecognizer> recognizers = <TapGestureRecognizer>[];
    List<_TextLinkerMatch> nextTextLinkerMatches = <_TextLinkerMatch>[...textLinkerMatches];
    int lastLinkEnd = index;
    if (span.text?.isNotEmpty ?? false) {
      final int textEnd = index + span.text!.length;
      for (final _TextLinkerMatch textLinkerMatch in textLinkerMatches) {
        if (textLinkerMatch.textRange.start >= textEnd) {
          // Because ranges is ordered, there are no more relevant ranges for this
          // text.
          break;
        }
        if (textLinkerMatch.textRange.end <= index) {
          // This range ends before this span and is therefore irrelevant to it.
          // It should have been removed from ranges.
          assert(false, 'Invalid ranges.');
          nextTextLinkerMatches.removeAt(0);
          continue;
        }
        if (textLinkerMatch.textRange.start > index) {
          // Add the unlinked text before the range.
          nextChildren.add(TextSpan(
            text: span.text!.substring(
              lastLinkEnd - index,
              textLinkerMatch.textRange.start - index,
            ),
          ));
        }
        // Add the link itself.
        final int linkStart = math.max(textLinkerMatch.textRange.start, index);
        lastLinkEnd = math.min(textLinkerMatch.textRange.end, textEnd);
        final (InlineSpan nextChild, TapGestureRecognizer recognizer) = textLinkerMatch.linkBuilder(
          span.text!.substring(linkStart - index, lastLinkEnd - index),
          textLinkerMatch.linkString,
        );
        nextChildren.add(nextChild);
        recognizers.add(recognizer);
        if (textLinkerMatch.textRange.end > textEnd) {
          // If we only partially used this range, keep it in nextRanges. Since
          // overlapping ranges have been removed, this must be the last relevant
          // range for this span.
          break;
        }
        nextTextLinkerMatches.removeAt(0);
      }

      // Add any extra text after any ranges.
      final String remainingText = span.text!.substring(lastLinkEnd - index);
      if (remainingText.isNotEmpty) {
        nextChildren.add(TextSpan(
          text: remainingText,
        ));
      }
    }

    // Recurse on the children.
    if (span.children?.isNotEmpty ?? false) {
      final (
        Iterable<InlineSpan> childrenSpans,
        Iterable<_TextLinkerMatch> childrenTextLinkerMatches,
        Iterable<TapGestureRecognizer> childrenRecognizers,
      ) = _linkSpansRecursive(
        span.children!.map((InlineSpan childSpan) => (
          span: childSpan,
          length: childSpan.toPlainText().length,
        )),
        nextTextLinkerMatches,
        index + (span.text?.length ?? 0),
      );
      nextTextLinkerMatches = childrenTextLinkerMatches.toList();
      nextChildren.addAll(childrenSpans);
      recognizers.addAll(childrenRecognizers);
    }

    return (
      TextSpan(
        style: span.style,
        children: nextChildren,
      ),
      nextTextLinkerMatches,
      recognizers,
    );
  }
}

/// A matched replacement on some String.
///
/// Produced by applying a [TextLinker]'s [RangesFinder] to a string.
class _TextLinkerMatch {
  _TextLinkerMatch({
    required this.textRange,
    required this.linkBuilder,
    required this.linkString,
  }) : assert(textRange.end - textRange.start == linkString.length);

  final LinkBuilder linkBuilder;
  final TextRange textRange;

  /// The [String] that [textRange] matches.
  final String linkString;

  /// Get all [_TextLinkerMatch]s obtained from applying the given
  // `textLinker`s with the given `text`.
  static List<_TextLinkerMatch> fromTextLinkers(Iterable<TextLinker> textLinkers, String text) {
    return textLinkers
        .fold<List<_TextLinkerMatch>>(
          <_TextLinkerMatch>[],
          (List<_TextLinkerMatch> previousValue, TextLinker value) {
            return previousValue..addAll(value._link(text));
        });
  }

  /// Returns a list of [InlineSpan]s representing all of the [text].
  ///
  /// Ranges matched by [textLinkerMatches] are built with their respective
  /// [LinkBuilder], and other text is represented with a simple [TextSpan].
  static (List<InlineSpan>, List<TapGestureRecognizer>) getSpansForMany(Iterable<_TextLinkerMatch> textLinkerMatches, String text) {
    // Sort so that overlapping ranges can be detected and ignored.
    final List<_TextLinkerMatch> textLinkerMatchesList = textLinkerMatches
        .toList()
        ..sort((_TextLinkerMatch a, _TextLinkerMatch b) {
          return a.textRange.start.compareTo(b.textRange.start);
        });

    final List<InlineSpan> spans = <InlineSpan>[];
    final List<TapGestureRecognizer> recognizers = <TapGestureRecognizer>[];
    int index = 0;
    for (final _TextLinkerMatch textLinkerMatch in textLinkerMatchesList) {
      // Ignore overlapping ranges.
      if (index > textLinkerMatch.textRange.start) {
        continue;
      }
      if (index < textLinkerMatch.textRange.start) {
        spans.add(TextSpan(
          text: text.substring(index, textLinkerMatch.textRange.start),
        ));
      }
      final (InlineSpan nextChild, TapGestureRecognizer recognizer) =
          textLinkerMatch.linkBuilder(
            text.substring(
              textLinkerMatch.textRange.start,
              textLinkerMatch.textRange.end,
            ),
            textLinkerMatch.linkString,
          );
      spans.add(nextChild);
      recognizers.add(recognizer);

      index = textLinkerMatch.textRange.end;
    }
    if (index < text.length) {
      spans.add(TextSpan(
        text: text.substring(index),
      ));
    }

    return (spans, recognizers);
  }

  @override
  String toString() {
    return '_TextLinkerMatch $textRange, $linkBuilder, $linkString';
  }
}

// TODO(justinmc): This shouldn't just be a record should it?
// TODO(justinmc): Would it simplify things if the public class TextLinker
// actually handled multiple rangesFinders and linkBuilders? Then there was a
// private single _TextLinker or something? Seems like it didn't work out when
// I tried this, actually.
// TODO(justinmc): Think about which links need to go here vs. on InlineTextLinker.
/// Specifies a way to find and style parts of a String.
class TextLinker {
  /// Creates an instance of [TextLinker].
  const TextLinker({
    // TODO(justinmc): Change "range" naming to always be "textRange"?
    required this.rangesFinder,
    required this.linkBuilder,
  });

  /// Builds an [InlineSpan] to display the text that it's passed.
  final LinkBuilder linkBuilder;

  // TODO(justinmc): Is it possible to enforce this order by TextRange.start, or should I just assume it's unordered?
  /// Returns [TextRange]s that should be built with [linkBuilder].
  final RangesFinder rangesFinder;

  // Turns all matches from the regExp into a list of TextRanges.
  static Iterable<TextRange> _rangesFromText({
    required String text,
    required RegExp regExp,
  }) {
    final Iterable<RegExpMatch> matches = regExp.allMatches(text);
    return matches.map((RegExpMatch match) {
      return TextRange(
        start: match.start,
        end: match.end,
      );
    });
  }

  /// Returns a flat list of [InlineSpan]s for multiple [TextLinker]s.
  ///
  /// Similar to [getSpans], but for multiple [TextLinker]s instead of just one.
  static (List<InlineSpan>, List<TapGestureRecognizer>) getSpansForMany(Iterable<TextLinker> textLinkers, String text) {
    final List<_TextLinkerMatch> combinedRanges = textLinkers
        .fold<List<_TextLinkerMatch>>(
          <_TextLinkerMatch>[],
          (List<_TextLinkerMatch> previousValue, TextLinker value) {
            final Iterable<TextRange> ranges = value.rangesFinder(text);
            for (final TextRange range in ranges) {
              previousValue.add(_TextLinkerMatch(
                textRange: range,
                linkBuilder: value.linkBuilder,
                linkString: text.substring(range.start, range.end),
              ));
            }
            return previousValue;
        });

    return _TextLinkerMatch.getSpansForMany(combinedRanges, text);
  }

  /// Creates a [RangesFinder] that finds all the matches of the given [RegExp].
  static RangesFinder rangesFinderFromRegExp(RegExp regExp) {
    return (String text) {
      return _rangesFromText(
        text: text,
        regExp: regExp,
      );
    };
  }

  /// Apply this [TextLinker] to a [String].
  Iterable<_TextLinkerMatch> _link(String text) {
    final Iterable<TextRange> textRanges = rangesFinder(text);
    return textRanges.map((TextRange textRange) {
      return _TextLinkerMatch(
        textRange: textRange,
        linkBuilder: linkBuilder,
        linkString: text.substring(textRange.start, textRange.end),
      );
    });
  }

  /// Builds the [InlineSpan]s for the given text.
  ///
  /// Builds [linkBuilder] for any ranges found by [rangesFinder]. All other
  /// text is presented in a plain [TextSpan].
  (List<InlineSpan>, List<TapGestureRecognizer>) getSpans(String text) {
    final Iterable<_TextLinkerMatch> textLinkerMatches = _link(text);
    return _TextLinkerMatch.getSpansForMany(textLinkerMatches, text);
  }

  @override
  String toString() {
    return 'TextLinker $rangesFinder, $linkBuilder';
  }
}
