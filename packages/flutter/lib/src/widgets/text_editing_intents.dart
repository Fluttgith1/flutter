// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'actions.dart';

/// An [Intent] to send the event straight to the engine.
///
/// See also:
///
///   * [DefaultTextEditingShortcuts], which triggers this [Intent].
class DoNothingAndStopPropagationTextIntent extends Intent {
  /// Creates an instance of [DoNothingAndStopPropagationTextIntent].
  const DoNothingAndStopPropagationTextIntent();
}

/// A text editing related [Intent] that performs an operation towards a given
/// direction of the current caret location.
abstract class DirectionalTextEditingIntent extends Intent {
  /// Creates a [DirectionalTextEditingIntent].
  const DirectionalTextEditingIntent(
    this.forward,
  );

  /// Whether the input field, if applicable, should perform the text editing
  /// operation from the current caret location towards the end of the document.
  ///
  /// Unless otherwise specified by the recipient of this intent, this parameter
  /// uses the logical order of characters in the string to determind the
  /// direction, and is not affected by the writing direction of the text.
  final bool forward;
}

/// Deletes the character before or after the caret location, based on whether
/// `forward` is true.
///
/// {@template flutter.widgets.TextEditingIntents.logicalOrder}
/// {@endtemplate}
///
/// Typically a text field will not respond to this intent if it has no active
/// caret ([TextSelection.isValid] is false for the current selection).
class DeleteCharacterIntent extends DirectionalTextEditingIntent {
  /// Creates a [DeleteCharacterIntent].
  const DeleteCharacterIntent({ required bool forward }) : super(forward);
}

/// Deletes from the current caret location to the previous or next word
/// boundary, based on whether `forward` is true.
class DeleteToNextWordBoundaryIntent extends DirectionalTextEditingIntent {
  /// Creates a [DeleteToNextWordBoundaryIntent].
  const DeleteToNextWordBoundaryIntent({ required bool forward }) : super(forward);
}

/// Deletes from the current caret location to the previous or next soft or hard
/// line break, based on whether `forward` is true.
class DeleteToLineBreakIntent extends DirectionalTextEditingIntent {
  /// Creates a [DeleteToLineBreakIntent].
  const DeleteToLineBreakIntent({ required bool forward }) : super(forward);
}

/// A [DirectionalTextEditingIntent] that moves the caret or the selection to a
/// new location.
abstract class DirectionalCaretMovementIntent extends DirectionalTextEditingIntent {
  /// Creates a [DirectionalCaretMovementIntent].
  const DirectionalCaretMovementIntent(
    super.forward,
    this.collapseSelection,
    [
      this.collapseAtReversal = false,
      this.continuesAtWrap = false,
    ]
  ) : assert(!collapseSelection || !collapseAtReversal);

  /// Whether this [Intent] should make the selection collapsed (so it becomes a
  /// caret), after the movement.
  ///
  /// When [collapseSelection] is false, the input field typically only moves
  /// the current [TextSelection.extent] to the new location, while maintains
  /// the current [TextSelection.base] location.
  ///
  /// When [collapseSelection] is true, the input field typically should move
  /// both the [TextSelection.base] and the [TextSelection.extent] to the new
  /// location.
  final bool collapseSelection;

  /// Whether to collapse the selection when it would otherwise reverse order.
  ///
  /// For example, consider when forward is true and the extent is before the
  /// base. If collapseAtReversal is true, then this will cause the selection to
  /// collapse at the base. If it's false, then the extent will be placed at the
  /// linebreak, reversing the order of base and offset.
  ///
  /// Cannot be true when collapseSelection is true.
  final bool collapseAtReversal;

  /// Whether or not to continue to the next line at a wordwrap.
  ///
  /// If true, when an [Intent] to go to the beginning/end of a wordwrapped line
  /// is received and the selection is already at the beginning/end of the line,
  /// then the selection will be moved to the next/previous line.  If false, the
  /// selection will remain at the wordwrap.
  final bool continuesAtWrap;
}

/// Extends, or moves the current selection from the current
/// [TextSelection.extent] position to the previous or the next character
/// boundary.
class ExtendSelectionByCharacterIntent extends DirectionalCaretMovementIntent {
  /// Creates an [ExtendSelectionByCharacterIntent].
  const ExtendSelectionByCharacterIntent({
    required bool forward,
    required bool collapseSelection,
  }) : super(forward, collapseSelection);
}

/// Extends, or moves the current selection from the current
/// [TextSelection.extent] position to the previous or the next word
/// boundary.
class ExtendSelectionToNextWordBoundaryIntent extends DirectionalCaretMovementIntent {
  /// Creates an [ExtendSelectionToNextWordBoundaryIntent].
  const ExtendSelectionToNextWordBoundaryIntent({
    required bool forward,
    required bool collapseSelection,
  }) : super(forward, collapseSelection);
}

/// Extends, or moves the current selection from the current
/// [TextSelection.extent] position to the previous or the next word
/// boundary, or the [TextSelection.base] position if it's closer in the move
/// direction.
///
/// This [Intent] typically has the same effect as an
/// [ExtendSelectionToNextWordBoundaryIntent], except it collapses the selection
/// when the order of [TextSelection.base] and [TextSelection.extent] would
/// reverse.
///
/// This is typically only used on MacOS.
class ExtendSelectionToNextWordBoundaryOrCaretLocationIntent extends DirectionalTextEditingIntent {
  /// Creates an [ExtendSelectionToNextWordBoundaryOrCaretLocationIntent].
  const ExtendSelectionToNextWordBoundaryOrCaretLocationIntent({
    required bool forward,
  }) : super(forward);
}

/// Expands the current selection to the document boundary in the direction
/// given by [forward].
///
/// Unlike [ExpandSelectionToLineBreakIntent], the extent will be moved, which
/// matches the behavior on MacOS.
///
/// See also:
///
///   [ExtendSelectionToDocumentBoundaryIntent], which is similar but always
///   moves the extent.
class ExpandSelectionToDocumentBoundaryIntent extends DirectionalTextEditingIntent {
  /// Creates an [ExpandSelectionToDocumentBoundaryIntent].
  const ExpandSelectionToDocumentBoundaryIntent({
    required bool forward,
  }) : super(forward);
}

/// Expands the current selection to the closest line break in the direction
/// given by [forward].
///
/// Either the base or extent can move, whichever is closer to the line break.
/// The selection will never shrink.
///
/// This behavior is common on MacOS.
///
/// See also:
///
///   [ExtendSelectionToLineBreakIntent], which is similar but always moves the
///   extent.
class ExpandSelectionToLineBreakIntent extends DirectionalTextEditingIntent {
  /// Creates an [ExpandSelectionToLineBreakIntent].
  const ExpandSelectionToLineBreakIntent({
    required bool forward,
  }) : super(forward);
}

/// Extends, or moves the current selection from the current
/// [TextSelection.extent] position to the closest line break in the direction
/// given by [forward].
///
/// See also:
///
///   [ExpandSelectionToLineBreakIntent], which is similar but always increases
///   the size of the selection.
class ExtendSelectionToLineBreakIntent extends DirectionalCaretMovementIntent {
  /// Creates an [ExtendSelectionToLineBreakIntent].
  const ExtendSelectionToLineBreakIntent({
    required bool forward,
    required bool collapseSelection,
    bool collapseAtReversal = false,
    bool continuesAtWrap = false,
  }) : assert(!collapseSelection || !collapseAtReversal),
       super(forward, collapseSelection, collapseAtReversal, continuesAtWrap);
}

/// Extends, or moves the current selection from the current
/// [TextSelection.extent] position to the closest position on the adjacent
/// line.
class ExtendSelectionVerticallyToAdjacentLineIntent extends DirectionalCaretMovementIntent {
  /// Creates an [ExtendSelectionVerticallyToAdjacentLineIntent].
  const ExtendSelectionVerticallyToAdjacentLineIntent({
    required bool forward,
    required bool collapseSelection,
  }) : super(forward, collapseSelection);
}

/// Extends, or moves the current selection from the current
/// [TextSelection.extent] position to the start or the end of the document.
///
/// See also:
///
///   [ExtendSelectionToDocumentBoundaryIntent], which is similar but always
///   increases the size of the selection.
class ExtendSelectionToDocumentBoundaryIntent extends DirectionalCaretMovementIntent {
  /// Creates an [ExtendSelectionToDocumentBoundaryIntent].
  const ExtendSelectionToDocumentBoundaryIntent({
    required bool forward,
    required bool collapseSelection,
  }) : super(forward, collapseSelection);
}

/// Scrolls to the beginning or end of the document depending on the [forward]
/// parameter.
class ScrollToDocumentBoundaryIntent extends DirectionalTextEditingIntent {
  /// Creates a [ScrollToDocumentBoundaryIntent].
  const ScrollToDocumentBoundaryIntent({
    required bool forward,
  }) : super(forward);
}

/// An [Intent] to select everything in the field.
class SelectAllTextIntent extends Intent {
  /// Creates an instance of [SelectAllTextIntent].
  const SelectAllTextIntent(this.cause);

  /// {@template flutter.widgets.TextEditingIntents.cause}
  /// The [SelectionChangedCause] that triggered the intent.
  /// {@endtemplate}
  final SelectionChangedCause cause;
}

/// An [Intent] that represents a user interaction that attempts to copy or cut
/// the current selection in the field.
class CopySelectionTextIntent extends Intent {
  const CopySelectionTextIntent._(this.cause, this.collapseSelection);

  /// Creates an [Intent] that represents a user interaction that attempts to
  /// cut the current selection in the field.
  const CopySelectionTextIntent.cut(SelectionChangedCause cause) : this._(cause, true);

  /// An [Intent] that represents a user interaction that attempts to copy the
  /// current selection in the field.
  static const CopySelectionTextIntent copy = CopySelectionTextIntent._(SelectionChangedCause.keyboard, false);

  /// {@macro flutter.widgets.TextEditingIntents.cause}
  final SelectionChangedCause cause;

  /// Whether the original text needs to be removed from the input field if the
  /// copy action was successful.
  final bool collapseSelection;
}

/// An [Intent] to paste text from [Clipboard] to the field.
class PasteTextIntent extends Intent {
  /// Creates an instance of [PasteTextIntent].
  const PasteTextIntent(this.cause);

  /// {@macro flutter.widgets.TextEditingIntents.cause}
  final SelectionChangedCause cause;
}

/// An [Intent] that represents a user interaction that attempts to go back to
/// the previous editing state.
class RedoTextIntent extends Intent {
  /// Creates a [RedoTextIntent].
  const RedoTextIntent(this.cause);

  /// {@macro flutter.widgets.TextEditingIntents.cause}
  final SelectionChangedCause cause;
}

/// An [Intent] that represents a user interaction that attempts to modify the
/// current [TextEditingValue] in an input field.
class ReplaceTextIntent extends Intent {
  /// Creates a [ReplaceTextIntent].
  const ReplaceTextIntent(this.currentTextEditingValue, this.replacementText, this.replacementRange, this.cause);

  /// The [TextEditingValue] that this [Intent]'s action should perform on.
  final TextEditingValue currentTextEditingValue;

  /// The text to replace the original text within the [replacementRange] with.
  final String replacementText;

  /// The range of text in [currentTextEditingValue] that needs to be replaced.
  final TextRange replacementRange;

  /// {@macro flutter.widgets.TextEditingIntents.cause}
  final SelectionChangedCause cause;
}

/// An [Intent] that represents a user interaction that attempts to go back to
/// the previous editing state.
class UndoTextIntent extends Intent {
  /// Creates an [UndoTextIntent].
  const UndoTextIntent(this.cause);

  /// {@macro flutter.widgets.TextEditingIntents.cause}
  final SelectionChangedCause cause;
}

/// An [Intent] that represents a user interaction that attempts to change the
/// selection in an input field.
class UpdateSelectionIntent extends Intent {
  /// Creates an [UpdateSelectionIntent].
  const UpdateSelectionIntent(this.currentTextEditingValue, this.newSelection, this.cause);

  /// The [TextEditingValue] that this [Intent]'s action should perform on.
  final TextEditingValue currentTextEditingValue;

  /// The new [TextSelection] the input field should adopt.
  final TextSelection newSelection;

  /// {@macro flutter.widgets.TextEditingIntents.cause}
  final SelectionChangedCause cause;
}

/// An [Intent] that represents a user interaction that attempts to swap the
/// characters immediately around the cursor.
class TransposeCharactersIntent extends Intent {
  /// Creates a [TransposeCharactersIntent].
  const TransposeCharactersIntent();
}

// ---------- Selection Gesture Intents ----------

/// An [Intent] that represents a gesture interaction when the secondary button is released.
class SecondaryTapUpIntent extends ListedIntents {
  /// Creates a [SecondaryTapUpIntent].
  const SecondaryTapUpIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [TapUpDetails] corresponding to a [TapGestureRecognizer.onSecondaryTapUp] event.
  final TapUpDetails details;
}

/// An [Intent] that represents a gesture interaction that is triggered when the secondary button
/// is released similar to [SecondaryTapUpIntent].
class SecondaryTapIntent extends ListedIntents {
  /// Creates a [SecondaryTapIntent].
  const SecondaryTapIntent({required super.intents, required super.enabledContext});
}

/// An [Intent] that represents a gesture interaction when the secondary button is pressed down.
class SecondaryTapDownIntent extends ListedIntents {
  /// Creates a [SecondaryTapDownIntent].
  const SecondaryTapDownIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [TapDownDetails] corresponding to a [TapGestureRecognizer.onSecondaryTapDown] event.
  final TapDownDetails details;
}

/// An [Intent] that represents a gesture interaction when the primary button is pressed down
/// while the shift key is pressed down.
class ShiftTapDownIntent extends ListedIntents {
  /// Creates a [ShiftTapDownIntent].
  const ShiftTapDownIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [TapDownDetails] corresponding to a [TapGestureRecognizer.onTapDown] event.
  final TapDownDetails details;
}

/// An [Intent] that represents a gesture interaction when the primary button is pressed down.
class TapDownIntent extends ListedIntents {
  /// Creates a [TapDownIntent].
  const TapDownIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [TapDownDetails] corresponding to a [TapGestureRecognizer.onTapDown] event.
  final TapDownDetails details;
}

/// An [Intent] that represents a gesture interaction when the primary button is pressed down twice.
class DoubleTapDownIntent extends ListedIntents {
  /// Creates a [DoubleTapDownIntent].
  const DoubleTapDownIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [TapDownDetails] corresponding to a [TapGestureRecognizer.onTapDown] event.
  final TapDownDetails details;
}

/// An [Intent] that represents a gesture interaction when the primary button is pressed down three times.
class TripleTapDownIntent extends ListedIntents {
  /// Creates a [TripleTapDownIntent].
  const TripleTapDownIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [TapDownDetails] corresponding to a [TapGestureRecognizer.onTapDown] event.
  final TapDownDetails details;
}

/// An [Intent] that represents a gesture interaction when the primary button is released.
class TapUpIntent extends ListedIntents {
  /// Creates a [TapUpIntent].
  const TapUpIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [TapUpDetails] corresponding to a [TapGestureRecognizer.onTapUp] event.
  final TapUpDetails details;
}

/// An [Intent] that represents a gesture interaction when the primary button is released while
/// the shift key is pressed down.
class ShiftTapUpIntent extends ListedIntents {
  /// Creates a [ShiftTapUpIntent].
  const ShiftTapUpIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [TapUpDetails] corresponding to a [TapGestureRecognizer.onTapUp] event.
  final TapUpDetails details;
}

/// An [Intent] that represents a gesture interaction when the primary button press is interrupted.
class TapCancelIntent extends ListedIntents {
  /// Creates a [TapCancelIntent].
  const TapCancelIntent({required super.intents, required super.enabledContext});
}

/// An [Intent] that represents a gesture interaction when the primary button is pressed down
/// to potentially initiate a drag.
class DragTapDownIntent extends ListedIntents {
  /// Creates a [DragTapDownIntent].
  const DragTapDownIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [DragDownDetails] corresponding to a [DragGestureRecognizer.onDown] event.
  final DragDownDetails details;
}

/// An [Intent] that represents a gesture interaction when a drag is initiated.
class DragStartIntent extends ListedIntents {
  /// Creates a [DragStartIntent].
  const DragStartIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [DragStartDetails] corresponding to a [DragGestureRecognizer.onStart] event.
  final DragStartDetails details;
}

/// An [Intent] that represents a gesture interaction when a drag is initiated and the shift key
/// has been tapped at anytime during the drag.
class ShiftTappingOnDragStartIntent extends ListedIntents {
  /// Creates a [ShiftTappingOnDragStartIntent].
  const ShiftTappingOnDragStartIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [DragStartDetails] corresponding to a [DragGestureRecognizer.onStart] event.
  final DragStartDetails details;
}

/// An [Intent] that represents a gesture interaction when a drag is being updated.
class DragUpdateIntent extends ListedIntents {
  /// Creates a [DragUpdateIntent].
  const DragUpdateIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [DragUpdateDetails] corresponding to a [DragGestureRecognizer.onUpdate] event.
  final DragUpdateDetails details;
}

/// An [Intent] that represents a gesture interaction when a drag is being updated and the shift key
/// has been tapped at anytime during the drag.
class ShiftTappingOnDragUpdateIntent extends ListedIntents {
  /// Creates a [ShiftTappingOnDragUpdateIntent].
  const ShiftTappingOnDragUpdateIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [DragUpdateDetails] corresponding to a [DragGestureRecognizer.onUpdate] event.
  final DragUpdateDetails details;
}

/// An [Intent] that represents a gesture interaction when a drag has ended.
class DragEndIntent extends ListedIntents {
  /// Creates a [DragEndIntent].
  const DragEndIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [DragEndDetails] corresponding to a [DragGestureRecognizer.onEnd] event.
  final DragEndDetails details;
}

/// An [Intent] that represents a gesture interaction when a drag has ended and the shift key
/// has been tapped at anytime during the drag.
class ShiftTappingOnDragEndIntent extends ListedIntents {
  /// Creates a [ShiftTappingOnDragEndIntent].
  const ShiftTappingOnDragEndIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [DragEndDetails] corresponding to a [DragGest ureRecognizer.onEnd] event.
  final DragEndDetails details;
}

/// An [Intent] that represents a gesture interaction when a long press is initiated.
class LongPressStartIntent extends ListedIntents {
  /// Create a [LongPressStartIntent].
  const LongPressStartIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [LongPressStartDetails] corresponding to a [LongPressGestureRecognizer.onLongPressStart] event.
  final LongPressStartDetails details;
}

/// An [Intent] that represents a gesture interaction when a long press is being updated.
class LongPressMoveUpdateIntent extends ListedIntents {
  /// Creates a [LongPressMoveUpdateIntent].
  const LongPressMoveUpdateIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [LongPressMoveUpdateDetails] corresponding to a [LongPressGestureRecognizer.onLongPressMoveUpdate] event.
  final LongPressMoveUpdateDetails details;
}

/// An [Intent] that represents a gesture interaction when a long press has ended.
class LongPressEndIntent extends ListedIntents {
  /// Creates a [LongPressEndIntent].
  const LongPressEndIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [LongPressEndDetails] corresponding to a [LongPressGestureRecognizer.onLongPressEnd] event.
  final LongPressEndDetails details;
}

/// An [Intent] that represents a gesture interaction when a force press is initiated.
class ForcePressStartIntent extends ListedIntents {
  /// Creates a [ForcePressStartIntent].
  const ForcePressStartIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [ForcePressDetails] corresponding to a [ForcePressGestureRecognizer.onStart] event.
  final ForcePressDetails details;
}

/// An [Intent] that represents a gesture interaction when a force press has ended.
class ForcePressEndIntent extends ListedIntents {
  /// Creates a [ForcePressEndIntent].
  const ForcePressEndIntent({required super.intents, required super.enabledContext, required this.details});

  /// The [ForcePressDetails] corresponding to a [ForcePressGestureRecognizer.onEnd] event.
  final ForcePressDetails details;
}

/// An [Intent] that requests the selection in an input field be expanded from
/// either the [TextSelection.baseOffset] or [TextSelection.extentOffset] to the
/// given [position], whichever is closest.
class ExpandSelectionToPositionIntent extends Intent {
  /// Creates an [ExpandSelectionToPositionIntent].
  const ExpandSelectionToPositionIntent({required this.cause, this.fromSelection, required this.position});

  /// {@macro flutter.widgets.TextEditingIntents.cause}
  final SelectionChangedCause cause;

  /// An optional starting selection which should be expanded from.
  final TextSelection? fromSelection;

  /// The global position which to expand the selection to.
  final Offset position;
}

/// An [Intent] that requests the selection in an input field be extended from
/// the [TextSelection.baseOffset] to the given [position].
class ExtendSelectionToPositionIntent extends Intent {
  /// Creates an [ExtendSelectionToPositionIntent].
  const ExtendSelectionToPositionIntent({required this.cause, required this.position});

  /// {@macro flutter.widgets.TextEditingIntents.cause}
  final SelectionChangedCause cause;

  /// The global position which to extend the selection to.
  final Offset position;
}

/// An [Intent] that represents a user interaction that attempts to request
/// hardware generated feedback such as haptic feedback.
class FeedbackRequestIntent extends Intent {
  /// Creates an [FeedbackRequestIntent].
  const FeedbackRequestIntent();
}

/// An [Intent] that represents a user interaction that attempts to request the
/// virtual keyboard.
class KeyboardRequestIntent extends Intent {
  /// Creates an [KeyboardRequestIntent].
  const KeyboardRequestIntent();
}

/// An [Intent] that saves or clears the selection when a drag starts.
class SelectionOnDragStartControlIntent extends Intent {
  /// Creates an [SelectionOnDragStartControlIntent].
  const SelectionOnDragStartControlIntent._({required this.store});

  /// Creates an [SelectionOnDragStartControlIntent] that requests the selection
  /// be saved at the beginning of a drag gesture.
  static const SelectionOnDragStartControlIntent save = SelectionOnDragStartControlIntent._(store: true);

  /// Creates an [SelectionOnDragStartControlIntent] that requests the selection
  /// be cleared, usually at the end of a drag gesture.
  static const SelectionOnDragStartControlIntent clear = SelectionOnDragStartControlIntent._(store: false);

  /// Whether the selection should be saved or not.
  final bool store;
}

/// An [Intent] that represents a user interaction that attempts to select the
/// edge of the word closest to the [position] in an input field.
class SelectWordEdgeIntent extends Intent {
  /// Creates an [SelectWordEdgeIntent].
  const SelectWordEdgeIntent({required this.cause, required this.position});

  /// {@macro flutter.widgets.TextEditingIntents.cause}
  final SelectionChangedCause cause;

  /// The global position selected by the user.
  final Offset position;
}

/// An [Intent] that represents a user interaction that attempts to select the
/// range in an input field at [from] to [to].
class SelectWordsInRangeIntent extends Intent {
  /// Creates an [SelectWordsInRangeIntent].
  const SelectWordsInRangeIntent({required this.cause, required this.from, this.to});

  /// {@macro flutter.widgets.TextEditingIntents.cause}
  final SelectionChangedCause cause;

  /// {@macro flutter.widgets.TextEditingIntents.from}
  final Offset from;

  /// {@macro flutter.widgets.TextEditingIntents.to}
  final Offset? to;
}

/// An [Intent] that represents a user interaction that attempts to select the
/// the word in an input field at the location of the [globalPosition].
class SelectWordIntent extends Intent {
  /// Creates an [SelectWordIntent].
  const SelectWordIntent({required this.cause, required this.globalPosition});

  /// {@macro flutter.widgets.TextEditingIntents.cause}
  final SelectionChangedCause cause;

  /// {@macro flutter.widgets.TextEditingIntents.from}
  final Offset globalPosition;
}

/// An [Intent] that represents a user interaction that attempts to select the
/// the word in an input field at the location of the [globalPosition].
class SelectStartEdgeIntent extends Intent {
  /// Creates an [SelectStartEdgeIntent].
  const SelectStartEdgeIntent({required this.cause, required this.globalPosition});

  /// {@macro flutter.widgets.TextEditingIntents.cause}
  final SelectionChangedCause cause;

  /// {@macro flutter.widgets.TextEditingIntents.from}
  final Offset globalPosition;
}

/// An [Intent] that represents a user interaction that attempts to select the
/// the word in an input field at the location of the [globalPosition].
class SelectEndEdgeIntent extends Intent {
  /// Creates an [SelectEndEdgeIntent].
  const SelectEndEdgeIntent({required this.cause, required this.globalPosition});

  /// {@macro flutter.widgets.TextEditingIntents.cause}
  final SelectionChangedCause cause;

  /// {@macro flutter.widgets.TextEditingIntents.from}
  final Offset globalPosition;
}

/// An [Intent] that represents a user interaction that attempts to hide, show,
/// or toggle the selection toolbar overlay.
class SelectionToolbarControlIntent extends Intent {
  /// Creates an [SelectionToolbarControlIntent].
  const SelectionToolbarControlIntent._({this.positionToDisplay, this.showSelectionToolbar, this.toggleSelectionToolbar});

  /// Creates an [SelectionToolbarControlIntent] that requests the toolbar to be
  /// shown.
  const SelectionToolbarControlIntent.show({required Offset position}) : this._(positionToDisplay: position, showSelectionToolbar: true);

  /// Creates an [SelectionToolbarControlIntent] that requests the toolbar to be
  /// toggled.
  const SelectionToolbarControlIntent.toggle({required Offset position}) : this._(positionToDisplay: position, toggleSelectionToolbar: true);

  /// Creates an [SelectionToolbarControlIntent] that requests the toolbar to be
  /// hidden.
  static const SelectionToolbarControlIntent hide = SelectionToolbarControlIntent._(showSelectionToolbar: false);

  /// The global position where the toolbar should be displayed at.
  final Offset? positionToDisplay;

  /// Whether the selection toolbar should be shown.
  final bool? showSelectionToolbar;

  /// Whether the selection toolbar should be toggled.
  final bool? toggleSelectionToolbar;
}

/// An [Intent] that represents a user interaction that attempts to execute a given
/// callback provided by the user.
class UserOnTapCallbackIntent extends Intent {
  /// Creates an [UserOnTapCallbackIntent].
  const UserOnTapCallbackIntent();
}
