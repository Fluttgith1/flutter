import 'package:flutter/src/painting/text_span.dart';
import 'package:flutter/src/painting/text_style.dart';
import 'package:flutter/src/widgets/spell_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'text_selection_toolbar.dart';
import 'text_selection_toolbar_text_button.dart';

/// Provides logic for displaying spell check suggestions for Android.
class MaterialSpellCheckerControls extends SpellCheckerControls{
    /// Responsible for causing the SpellCheckerSuggestionsToolbar to appear.
    /// This toolbar will allow for tap and replace of suggestions for misspelled 
    /// words.
    /// See calls in
    /// (1) _TextFieldSelectionGestureDetectorBuilder [material/text_field.dart]
    /// (2) EditableTextState [editable_text.dart]
    /// (3) MaterialTextSelectionControls [material/text_selection.dart]
    Widget buildSpellCheckerSuggestionsToolbar(
        TextSelectionDelegate delegate, List<TextSelectionPoint> endpoints, 
        Rect globalEditableRegion, Offset selectionMidpoint, double textLineHeight, 
        List<SpellCheckerSuggestionSpan>? spellCheckerSuggestionSpans) {
            return _SpellCheckerSuggestionsToolbar(
            delegate: delegate,
            endpoints: endpoints,
            globalEditableRegion: globalEditableRegion,
            selectionMidpoint: selectionMidpoint,
            textLineHeight: textLineHeight,
            spellCheckerSuggestionSpans: spellCheckerSuggestionSpans,
          );
    }
}

// start of pasting
class _SpellCheckerSuggestionsToolbarItemData {
  const _SpellCheckerSuggestionsToolbarItemData({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;
}

const double _kHandleSize = 22.0;

// Padding between the toolbar and the anchor.
const double _kToolbarContentDistanceBelow = _kHandleSize - 2.0;
const double _kToolbarContentDistance = 8.0;

// The highest level toolbar widget, built directly by buildToolbar.
class _SpellCheckerSuggestionsToolbar extends StatefulWidget {
  const _SpellCheckerSuggestionsToolbar({
    Key? key,
    required this.delegate,
    required this.endpoints,
    required this.globalEditableRegion,
    required this.selectionMidpoint,
    required this.textLineHeight,
    required this.spellCheckerSuggestionSpans,
  }) : super(key: key);

  final TextSelectionDelegate delegate;
  final List<TextSelectionPoint> endpoints;
  final Rect globalEditableRegion;
  final Offset selectionMidpoint;
  final double textLineHeight;
  final List<SpellCheckerSuggestionSpan>? spellCheckerSuggestionSpans;

  @override
  _SpellCheckerSuggestionsToolbarState createState() => _SpellCheckerSuggestionsToolbarState();
}

class _SpellCheckerSuggestionsToolbarState extends State<_SpellCheckerSuggestionsToolbar> with TickerProviderStateMixin {

  SpellCheckerSuggestionSpan? findSuggestions(int curr_index, List<SpellCheckerSuggestionSpan> spellCheckerSuggestionSpans) {
    int left_index = 0;
    int right_index = spellCheckerSuggestionSpans.length - 1;
    int mid_index = 0;

    while (left_index <= right_index) {
        mid_index = (left_index + (right_index - left_index) / 2).floor();

        // Check if x is present at mid
        if (spellCheckerSuggestionSpans[mid_index].start <= curr_index && spellCheckerSuggestionSpans[mid_index].end + 1 >= curr_index) { 
            return spellCheckerSuggestionSpans[mid_index];
        }

        if (spellCheckerSuggestionSpans[mid_index].start <= curr_index) {
            left_index = left_index + 1;
        }
        else {
            right_index = right_index - 1;
        }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {

    if (widget.spellCheckerSuggestionSpans == null || widget.spellCheckerSuggestionSpans!.length == 0) {
        return const SizedBox.shrink();
    }

    // Calculate the positioning of the menu. It is placed above the selection
    // if there is enough room, or otherwise below.
    final TextSelectionPoint startTextSelectionPoint = widget.endpoints[0];
    final TextSelectionPoint endTextSelectionPoint = widget.endpoints.length > 1
      ? widget.endpoints[1]
      : widget.endpoints[0];
    final Offset anchorAbove = Offset(
      widget.globalEditableRegion.left + widget.selectionMidpoint.dx,
      widget.globalEditableRegion.top + startTextSelectionPoint.point.dy - widget.textLineHeight - _kToolbarContentDistance,
    );
    final Offset anchorBelow = Offset(
      widget.globalEditableRegion.left + widget.selectionMidpoint.dx,
      widget.globalEditableRegion.top + endTextSelectionPoint.point.dy + _kToolbarContentDistanceBelow,
    );

    // Determine which buttons will appear so that the order and total number is
    // known. A button's position in the menu can slightly affect its
    // appearance.
    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);

    // Determine which suggestions to show
    TextEditingValue value = widget.delegate.textEditingValue;
    int cursorIndex = value.selection.baseOffset;

    SpellCheckerSuggestionSpan? relevantSpan = findSuggestions(cursorIndex, widget.spellCheckerSuggestionSpans!);

    if (relevantSpan == null) {
        return const SizedBox.shrink();
    }
    final List<_SpellCheckerSuggestionsToolbarItemData> itemDatas = <_SpellCheckerSuggestionsToolbarItemData>[];

    relevantSpan.replacementSuggestions.forEach((String suggestion) {
        itemDatas.add(        
            _SpellCheckerSuggestionsToolbarItemData(
                label: suggestion,
                onPressed: () 
                {
                    widget.delegate.replaceSelection(SelectionChangedCause.toolbar, suggestion, relevantSpan.start, relevantSpan.end + 1);
                },
        ));
    });

    return TextSelectionToolbar(
      anchorAbove: anchorAbove,
      anchorBelow: anchorBelow,
      children: itemDatas.asMap().entries.map((MapEntry<int, _SpellCheckerSuggestionsToolbarItemData> entry) {
        return TextSelectionToolbarTextButton(
          padding: TextSelectionToolbarTextButton.getPadding(entry.key, itemDatas.length),
          onPressed: entry.value.onPressed,
          child: Text(entry.value.label),
        );
      }).toList(),
    );
  }
}

/// Provides logic for indicating misspelled words for Android.
class MaterialMisspelledWordsHandler extends MisspelledWordsHandler {
    //TODO(camillesimon): add comments, clean up code
    int scssSpans_consumed_index = 0;
    int text_consumed_index = 0;

    /// Responsible for rebuilding the TextSpan with the TextStyle changed for all 
    /// of the misspelled words.
    /// See call in EditableTextState [editable_text.dart]
    TextSpan buildWithMisspelledWordsIndicated(List<SpellCheckerSuggestionSpan> spellCheckerSuggestionSpans, 
        TextEditingValue value, TextStyle? style, bool ignoreComposing) {
        scssSpans_consumed_index = 0;
        text_consumed_index = 0;
        if (ignoreComposing) {
            return TextSpan(
                style: style,
                children: buildSubtreesWithMisspelledWordsIndicated(spellCheckerSuggestionSpans, value.text, style)
            );
        } else {
            return TextSpan(
                style: style,
                children: <TextSpan>[
                    TextSpan(children: buildSubtreesWithMisspelledWordsIndicated(spellCheckerSuggestionSpans, value.composing.textBefore(value.text), style)),
                    TextSpan(children: buildSubtreesWithMisspelledWordsIndicated(spellCheckerSuggestionSpans, value.composing.textInside(value.text), style?.merge(const TextStyle(decoration: TextDecoration.underline)
                        ?? const TextStyle(decoration: TextDecoration.underline)))),
                    TextSpan(children: buildSubtreesWithMisspelledWordsIndicated(spellCheckerSuggestionSpans, value.composing.textAfter(value.text), style)),
                ],
            );
        }
    }

    List<TextSpan> buildSubtreesWithMisspelledWordsIndicated(List<SpellCheckerSuggestionSpan> spellCheckerSuggestionSpans, String text, TextStyle? style) {
        List<TextSpan> tsTreeChildren = <TextSpan>[];
        int text_pointer = 0;

        if (scssSpans_consumed_index < spellCheckerSuggestionSpans.length) {
            int scss_pointer = scssSpans_consumed_index;
            SpellCheckerSuggestionSpan currScssSpan = spellCheckerSuggestionSpans[scss_pointer];
            int span_pointer = currScssSpan.start;

            while (text_pointer < text.length && scss_pointer < spellCheckerSuggestionSpans.length && (currScssSpan.start-text_consumed_index) < text.length) {
                int end_index;
                currScssSpan = spellCheckerSuggestionSpans[scss_pointer];

                if ((currScssSpan.start-text_consumed_index) > text_pointer) {
                    end_index = (currScssSpan.start-text_consumed_index) < text.length ? (currScssSpan.start-text_consumed_index) : text.length;
                    tsTreeChildren.add(TextSpan(style: style,
                                                text: text.substring(text_pointer, end_index)));
                    text_pointer = end_index;
                }
                else {
                    end_index = (currScssSpan.end - text_consumed_index + 1) < text.length ? (currScssSpan.end - text_consumed_index + 1) : text.length;
                    tsTreeChildren.add(TextSpan(style: overrideTextSpanStyle(style),
                                                text: text.substring((currScssSpan.start-text_consumed_index), end_index)));

                    text_pointer = end_index;
                    scss_pointer += 1;
                }
            }

            text_consumed_index = text_pointer + text_consumed_index;

            // Add remaining text if there is any
            if (text_pointer < text.length) {
                tsTreeChildren.add(TextSpan(style: style, text: text.substring(text_pointer, text.length)));
                text_consumed_index = text.length + text_consumed_index;
            }
            scssSpans_consumed_index = scss_pointer;
            return tsTreeChildren;
        } else {
            text_consumed_index = text.length;
            return <TextSpan>[TextSpan(text: text, style: style)];
        }
    }

    /// Responsible for defining the behavior of overriding/merging
    /// the TestStyle specified for a particular TextSpan with the style used to
    /// indicate misspelled words (straight red underline for Android).
    /// Will be used in buildWithMisspelledWordsIndicated(...) method above.
    TextStyle overrideTextSpanStyle(TextStyle? currentTextStyle) {
        TextStyle misspelledStyle = TextStyle(decoration: TextDecoration.underline,
                                decorationColor: Colors.red,
                                decorationStyle: TextDecorationStyle.wavy);
        return currentTextStyle?.merge(misspelledStyle)
            ?? misspelledStyle;
    }
}
