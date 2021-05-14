// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'actions.dart';
import 'editable_text.dart';
import 'framework.dart';
import 'text_editing_action.dart';
import 'text_editing_intents.dart';

typedef _OnTextEditingIntentCallback<T extends TextEditingGestureIntent> = void Function(T intent, EditableTextState editableTextState);
typedef _Handler<T> = void Function(T);
typedef _IntentBuilder<T, IntentType extends Intent> = IntentType Function(T);

TextRange _clampTextRange(TextRange range, String text) {
  if (!range.isValid) {
    return range;
  }
  return TextRange(start: range.start.clamp(0, text.length), end: range.end.clamp(0, text.length));
}

TextSelection _clampTextSelection(TextPosition base, TextPosition extent, String text) {
  return TextSelection(
    baseOffset: base.offset.clamp(0, text.length),
    extentOffset: extent.offset.clamp(0, text.length),
    affinity: extent.affinity,
  );
}



/// An [Actions] widget that handles the default text editing behavior for
/// Flutter on the current platform.
///
/// This default behavior can be overridden by placing an [Actions] widget lower
/// in the widget tree than this. See [DefaultTextEditingShortcuts] for an example of
/// remapping keyboard keys to an existing text editing [Intent].
///
/// See also:
///
///   * [DefaultTextEditingShortcuts], which maps keyboard keys to many of the
///     [Intent]s that are handled here.
///   * [WidgetsApp], which creates a DefaultTextEditingShortcuts.
class DefaultTextEditingActions extends Actions {
  /// Creates an instance of DefaultTextEditingActions.
  DefaultTextEditingActions({
    Key? key,
    required Widget child,
  }) : super(
    key: key,
    actions: <Type, Action<Intent>>{
      ..._shortcutsActions,
      ..._PlatformGestureActions.platformGestureActions,
    },
    child: child,
  );

  // These Intents are triggered by DefaultTextEditingShortcuts. They are included
  // regardless of the platform; it's up to DefaultTextEditingShortcuts to decide which
  // are called on which platform.
  static final Map<Type, Action<Intent>> _shortcutsActions = <Type, Action<Intent>>{
    DoNothingAndStopPropagationTextIntent: _DoNothingAndStopPropagationTextAction(),
    DeleteTextIntent: _DeleteTextAction(),
    DeleteByWordTextIntent: _DeleteByWordTextAction(),
    DeleteByLineTextIntent: _DeleteByLineTextAction(),
    DeleteForwardTextIntent: _DeleteForwardTextAction(),
    DeleteForwardByWordTextIntent: _DeleteForwardByWordTextAction(),
    DeleteForwardByLineTextIntent: _DeleteForwardByLineTextAction(),
    ExtendSelectionDownTextIntent: _ExtendSelectionDownTextAction(),
    ExtendSelectionLeftByLineTextIntent: _ExtendSelectionLeftByLineTextAction(),
    ExtendSelectionLeftByWordTextIntent: _ExtendSelectionLeftByWordTextAction(),
    ExtendSelectionLeftByWordAndStopAtReversalTextIntent: _ExtendSelectionLeftByWordAndStopAtReversalTextAction(),
    ExtendSelectionLeftTextIntent: _ExtendSelectionLeftTextAction(),
    ExtendSelectionRightByWordAndStopAtReversalTextIntent: _ExtendSelectionRightByWordAndStopAtReversalTextAction(),
    ExtendSelectionRightByWordTextIntent: _ExtendSelectionRightByWordTextAction(),
    ExtendSelectionRightByLineTextIntent: _ExtendSelectionRightByLineTextAction(),
    ExtendSelectionRightTextIntent: _ExtendSelectionRightTextAction(),
    ExtendSelectionUpTextIntent: _ExtendSelectionUpTextAction(),
    ExpandSelectionLeftByLineTextIntent: _ExpandSelectionLeftByLineTextAction(),
    ExpandSelectionRightByLineTextIntent: _ExpandSelectionRightByLineTextAction(),
    ExpandSelectionToEndTextIntent: _ExpandSelectionToEndTextAction(),
    ExpandSelectionToStartTextIntent: _ExpandSelectionToStartTextAction(),
    MoveSelectionDownTextIntent: _MoveSelectionDownTextAction(),
    MoveSelectionLeftByLineTextIntent: _MoveSelectionLeftByLineTextAction(),
    MoveSelectionLeftByWordTextIntent: _MoveSelectionLeftByWordTextAction(),
    MoveSelectionLeftTextIntent: _MoveSelectionLeftTextAction(),
    MoveSelectionRightByLineTextIntent: _MoveSelectionRightByLineTextAction(),
    MoveSelectionRightByWordTextIntent: _MoveSelectionRightByWordTextAction(),
    MoveSelectionRightTextIntent: _MoveSelectionRightTextAction(),
    MoveSelectionToEndTextIntent: _MoveSelectionToEndTextAction(),
    MoveSelectionToStartTextIntent: _MoveSelectionToStartTextAction(),
    MoveSelectionUpTextIntent: _MoveSelectionUpTextAction(),
  };
}

class _TextEditingCallbackAction<T extends TextEditingGestureIntent> extends Action<T> {
  _TextEditingCallbackAction({
    required this.onInvoke,
    this.enabledPredicate,
  });

  final _OnTextEditingIntentCallback<T> onInvoke;
  final bool Function(T)? enabledPredicate;

  @override
  void invoke(T intent) {
    final EditableTextState? editableTextState = intent.gestureDelegate.editableTextKey.currentState;
    if (editableTextState == null) {
      return;
    }
    onInvoke(intent, editableTextState);
  }

  @override
  bool isEnabled(T intent) => enabledPredicate?.call(intent) ?? true;
}

class TextEditingGestureBuilder extends StatefulWidget {
  const TextEditingGestureBuilder({
    Key? key,
    required this.child,
    required this.delegate,
    this.behavior,
  }) : super(key: key);

  final Widget child;
  final TextSelectionGestureDetectorBuilderDelegate delegate;
  final HitTestBehavior? behavior;

  @override
  State<TextEditingGestureBuilder> createState() => _TextEditingGestureBuilderState();
}

class _TextEditingGestureBuilderState extends State<TextEditingGestureBuilder> {
  Intent _tapDownIntent(TapDownDetails details) => TapDownTextIntent(tapDownDetails: details, gestureDelegate: widget.delegate);
  Intent _forcePressStartIntent(ForcePressDetails details) => ForcePressStartTextIntent.ForcePressTextGestureIntent(forcePressDetails: details, gestureDelegate: widget.delegate);
  Intent _forcePressEndIntent(ForcePressDetails details) => ForcePressEndTextIntent(forcePressDetails: details, gestureDelegate: widget.delegate);

  Intent get _secondaryTapIntent => SecondaryTapTextIntent(gestureDelegate: widget.delegate);
  Intent _secondaryTapDown(TapDownDetails details) => SecondaryTapDownTextIntent(tapDownDetails: details, gestureDelegate: widget.delegate);

  Intent _singleTapUp(TapUpDetails details) => SingleTapUpTextIntent(tapUpDetails: details, gestureDelegate: widget.delegate);
  Intent get _singleTapCancel => SingleTapCancelTextIntent(gestureDelegate: widget.delegate);

  Intent _singleLongTapStart(LongPressStartDetails details) => SingleLongTapStartTextIntent(longPressStartDetails: details, gestureDelegate: widget.delegate);
  Intent _singleLongTapMoveUpdate(LongPressMoveUpdateDetails details) => SingleLongTapMoveTextIntent(longPressMoveDetails: details, gestureDelegate: widget.delegate);
  Intent _singleLongTapEnd(LongPressEndDetails details) => SingleLongTapEndTextIntent(longPressEndDetails: details, gestureDelegate: widget.delegate);

  Intent _doubleTapDown(TapDownDetails details) => DoubleTapDownTextIntent(tapDownDetails: details, gestureDelegate: widget.delegate);

  Intent _dragSelectionStart(DragStartDetails details) => DragSelectionStartTextIntent(dragStartDetails: details, gestureDelegate: widget.delegate);
  Intent _dragSelectionEnd(DragEndDetails details) => DragSelectionEndTextIntent(dragEndDetails: details, gestureDelegate: widget.delegate);

  VoidCallback? _fromNullaryIntent<IntentType extends Intent>(IntentType intent) {
    final Action<IntentType>? action = Actions.maybeFind<IntentType>(context);
    // Unfortunately we need to build
    if (action == null || action is DoNothingAction) {
      return null;
    }

    return () {
      if (action.isEnabled(intent)) {
        Actions.of(context).invokeAction(action, intent);
      }
    };
  }

  _Handler<T>? _fromIntent<T, IntentType extends Intent>(_IntentBuilder<T, IntentType> intentFromGesture) {
    final Action<IntentType>? action = Actions.maybeFind<IntentType>(context);
    if (action == null || action is DoNothingAction) {
      return null;
    }

    return (T eventDetails) {
      final IntentType intent = intentFromGesture(eventDetails);
      // Could be that the action was enabled when the closure was created,
      // but is now no longer enabled, so check again.
      if (action.isEnabled(intent)) {
        Actions.of(context).invokeAction(action, intent);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final Action<DragSelectionUpdateTextIntent>? action = Actions.maybeFind<DragSelectionUpdateTextIntent>(this.context);
    final DragSelectionUpdateCallback? dragSelectionUpdateCallback = action == null || action is DoNothingAction
      ? null
      : (DragStartDetails startDetails, DragUpdateDetails updateDetails) {
        final DragSelectionUpdateTextIntent intent = DragSelectionUpdateTextIntent(
          dragStartDetails: startDetails,
          dragUpdateDetails: updateDetails,
          gestureDelegate: widget.delegate,
        );
        if (action.isEnabled(intent)) {
          Actions.of(this.context).invokeAction(action, intent);
        }
      };

    return _GestureStateStorage(
      state: _TextEditingGesturesStorage(),
      child: TextSelectionGestureDetector(
        onTapDown: _fromIntent(_tapDownIntent),
        onForcePressStart: _fromIntent(_forcePressStartIntent),
        onForcePressEnd: _fromIntent(_forcePressEndIntent),
        onSecondaryTap: _fromNullaryIntent(_secondaryTapIntent),
        onSecondaryTapDown: _fromIntent(_secondaryTapDown),
        onSingleTapUp: _fromIntent(_singleTapUp),
        onSingleTapCancel: _fromNullaryIntent(_singleTapCancel),
        onSingleLongTapStart: _fromIntent(_singleLongTapStart),
        onSingleLongTapMoveUpdate: _fromIntent(_singleLongTapMoveUpdate),
        onSingleLongTapEnd: _fromIntent(_singleLongTapEnd),
        onDoubleTapDown: _fromIntent(_doubleTapDown),
        onDragSelectionStart: _fromIntent(_dragSelectionStart),
        onDragSelectionUpdate: dragSelectionUpdateCallback,
        onDragSelectionEnd: _fromIntent(_dragSelectionEnd),
        behavior: widget.behavior,
        child: widget.child,
      ),
    );
  }
}

// [Action]s that correspond to text input gestures, and their platform
// mappings.
class _PlatformGestureActions {
  _PlatformGestureActions._();

  // ---------- Gesture Actions ----------

  @protected
  static final Map<Type, Action<Intent>> _commonActions = <Type, Action<Intent>>{
    ForcePressTextGestureIntent: _TextEditingCallbackAction<ForcePressTextGestureIntent>(
      onInvoke: (ForcePressTextGestureIntent intent, EditableTextState editableTextState, [BuildContext? context]) {
        final ForcePressDetails forcePressDetails = intent.forcePressUpDetails ?? intent.forcePressDownDetails;
        editableTextState.renderEditable.selectWordsInRange(
          from: forcePressDetails.globalPosition,
          cause: SelectionChangedCause.forcePress,
        );
      },
      enabledPredicate: (ForcePressTextGestureIntent intent) => intent.gestureDelegate.forcePressEnabled && intent.gestureDelegate.selectionEnabled,
    ),

    TapTextGestureIntent: _TextEditingCallbackAction<TapTextGestureIntent>(
      onInvoke: (TapTextGestureIntent intent, EditableTextState editableTextState, [BuildContext? context]) {
        assert(!intent.isCancelled);
        assert(intent.recognizedTapCount <= intent.maxTapCount);
        assert(intent.recognizedTapCount >= 0);

        // onTapDown. This is called for every tap down.
        if (intent.tapUpDetails == null) {
          editableTextState.renderEditable.handleTapDown(intent.tapDownDetails);
        }

        if (intent.recognizedTapCount == 2 && intent.tapUpDetails == null) {
          editableTextState.renderEditable.selectWord(cause: SelectionChangedCause.doubleTap);
          if (intent.shouldShowSelectionBar) {
            editableTextState.showToolbar();
          }
          return;
        }

        // onSingleTapUp
        if (intent.recognizedTapCount == 1) {
          final TapUpDetails? tapUpDetails = intent.tapUpDetails;
          if (tapUpDetails != null) {
            editableTextState.hideToolbar();
            switch (tapUpDetails.kind) {
              case PointerDeviceKind.mouse:
              case PointerDeviceKind.stylus:
              case PointerDeviceKind.invertedStylus:
                editableTextState.renderEditable.selectPosition(cause: SelectionChangedCause.tap);
                break;
              case PointerDeviceKind.touch:
              case PointerDeviceKind.unknown:
                editableTextState.renderEditable.selectWordEdge(cause: SelectionChangedCause.tap);
                break;
            }
            editableTextState.requestKeyboard();
          }
        }
      },
      enabledPredicate: (TapTextGestureIntent intent) => intent.gestureDelegate.selectionEnabled && !intent.isCancelled,
    ),

    SecondaryTapTextGestureIntent: _TextEditingCallbackAction<SecondaryTapTextGestureIntent>(
      onInvoke: (SecondaryTapTextGestureIntent intent, EditableTextState editableTextState, [BuildContext? context]) {
        final RenderEditable renderEditable = editableTextState.renderEditable;

        // onSecondaryTap.
        if (intent.isRecognized) {
          final TextSelection? selection = renderEditable.selection;
          final Offset? lastSecondaryTapDownPosition = renderEditable.lastSecondaryTapDownPosition;

          if (selection != null && selection.isValid && lastSecondaryTapDownPosition != null) {
            final TextPosition textPosition = renderEditable.getPositionForPoint(lastSecondaryTapDownPosition);
            final bool lastTapOnSelection = selection.start <= textPosition.offset && selection.end >= textPosition.offset;
            if (!lastTapOnSelection) {
              renderEditable.selectWord(cause: SelectionChangedCause.tap);
            }
          }
          editableTextState.hideToolbar();
          editableTextState.showToolbar();
        } else {
          renderEditable.handleSecondaryTapDown(intent.tapDownDetails);
        }
      },
      //enabledPredicate: (SecondaryTapTextGestureIntent intent) => intent.gestureDelegate.selectionEnabled,
    ),
    LongTapTextGestureIntent: _TextEditingCallbackAction<LongTapTextGestureIntent>(
      onInvoke: (LongTapTextGestureIntent intent, EditableTextState editableTextState, [BuildContext? context]) {
        final RenderEditable renderEditable = editableTextState.renderEditable;
        final LongPressEndDetails? endDetails = intent.longPressEndDetails;
        final Offset globalDragLocation = intent.longPressMoveDetails?.globalPosition
                                       ?? intent.longPressStartDetails.globalPosition;

        if (endDetails != null) {
          // End event.
          assert(intent.longPressMoveDetails != null);
          editableTextState.showToolbar();
        } else {
          // Start & Update event.
          renderEditable.selectPositionAt(
            from: globalDragLocation,
            cause: SelectionChangedCause.longPress,
          );
        }
      },
      enabledPredicate: (LongTapTextGestureIntent intent) => intent.gestureDelegate.selectionEnabled,
    ),
    DragTextGestureIntent: _TextEditingCallbackAction<DragTextGestureIntent>(
      onInvoke: (DragTextGestureIntent intent, EditableTextState editableTextState, [BuildContext? context]) {
        if (intent.dragEndDetails != null) {
          assert(intent.dragUpdateDetails != null);
          return;
        }
        assert((intent.dragUpdateDetails == null) == (intent.selectionBase == null));
        final Offset dragLocation = intent.dragUpdateDetails?.globalPosition ?? intent.dragStartDetails.globalPosition;
        final TextPosition currentPosition = editableTextState.renderEditable.getPositionForPoint(dragLocation);
        final TextPosition fromPosition = intent.selectionBase ?? currentPosition;
        intent.selectionBase ??= currentPosition;

        final TextEditingValue currentTextEditingValue = editableTextState.currentTextEditingValue;
        editableTextState.userUpdateTextEditingValue(
          currentTextEditingValue.copyWith(
            selection: TextSelection(
              baseOffset: fromPosition.offset.clamp(0, currentTextEditingValue.text.length),
              extentOffset: currentPosition.offset.clamp(0, currentTextEditingValue.text.length),
              affinity: currentPosition.affinity,
            ),
          ),
          SelectionChangedCause.drag,
        );
      },
      enabledPredicate: (DragTextGestureIntent intent) => intent.gestureDelegate.selectionEnabled,
    ),
  };

  @protected
  static final Map<Type, Action<Intent>> _androidActions = <Type, Action<Intent>>{
  };

  @protected
  static final Map<Type, Action<Intent>> _fuchsiaActions = <Type, Action<Intent>>{
  };

  @protected
  static final Map<Type, Action<Intent>> _iOSActions = <Type, Action<Intent>>{
  };

  @protected
  static final Map<Type, Action<Intent>> _linuxActions = <Type, Action<Intent>>{
  };

  @protected
  static final Map<Type, Action<Intent>> _macActions = _iOSActions;

  @protected
  static final Map<Type, Action<Intent>> _windowsActions = <Type, Action<Intent>>{
  };

  static final Map<Type, Action<Intent>> platformGestureActions = (){
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidActions;
      case TargetPlatform.fuchsia:
        return _fuchsiaActions;
      case TargetPlatform.iOS:
        return _iOSActions;
      case TargetPlatform.linux:
        return _linuxActions;
      case TargetPlatform.macOS:
        return _macActions;
      case TargetPlatform.windows:
        return _windowsActions;
    }
  }();
}

// This allows the web engine to handle text editing events natively while using
// the same TextEditingAction logic to only handle events from a
// TextEditingTarget.
class _DoNothingAndStopPropagationTextAction extends TextEditingAction<DoNothingAndStopPropagationTextIntent> {
  _DoNothingAndStopPropagationTextAction();

  @override
  bool consumesKey(Intent intent) => false;

  @override
  void invoke(DoNothingAndStopPropagationTextIntent intent, [BuildContext? context]) {}
}

class _DeleteTextAction extends TextEditingAction<DeleteTextIntent> {
  @override
  Object? invoke(DeleteTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.delete(SelectionChangedCause.keyboard);
  }
}

class _DeleteByWordTextAction extends TextEditingAction<DeleteByWordTextIntent> {
  @override
  Object? invoke(DeleteByWordTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.deleteByWord(SelectionChangedCause.keyboard, false);
  }
}

class _DeleteByLineTextAction extends TextEditingAction<DeleteByLineTextIntent> {
  @override
  Object? invoke(DeleteByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.deleteByLine(SelectionChangedCause.keyboard);
  }
}

class _DeleteForwardTextAction extends TextEditingAction<DeleteForwardTextIntent> {
  @override
  Object? invoke(DeleteForwardTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.deleteForward(SelectionChangedCause.keyboard);
  }
}

class _DeleteForwardByWordTextAction extends TextEditingAction<DeleteForwardByWordTextIntent> {
  @override
  Object? invoke(DeleteForwardByWordTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.deleteForwardByWord(SelectionChangedCause.keyboard, false);
  }
}

class _DeleteForwardByLineTextAction extends TextEditingAction<DeleteForwardByLineTextIntent> {
  @override
  Object? invoke(DeleteForwardByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.deleteForwardByLine(SelectionChangedCause.keyboard);
  }
}

class _ExpandSelectionLeftByLineTextAction extends TextEditingAction<ExpandSelectionLeftByLineTextIntent> {
  @override
  Object? invoke(ExpandSelectionLeftByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.expandSelectionLeftByLine(SelectionChangedCause.keyboard);
  }
}

class _ExpandSelectionRightByLineTextAction extends TextEditingAction<ExpandSelectionRightByLineTextIntent> {
  @override
  Object? invoke(ExpandSelectionRightByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.expandSelectionRightByLine(SelectionChangedCause.keyboard);
  }
}

class _ExpandSelectionToEndTextAction extends TextEditingAction<ExpandSelectionToEndTextIntent> {
  @override
  Object? invoke(ExpandSelectionToEndTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.expandSelectionToEnd(SelectionChangedCause.keyboard);
  }
}

class _ExpandSelectionToStartTextAction extends TextEditingAction<ExpandSelectionToStartTextIntent> {
  @override
  Object? invoke(ExpandSelectionToStartTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.expandSelectionToStart(SelectionChangedCause.keyboard);
  }
}

class _ExtendSelectionDownTextAction extends TextEditingAction<ExtendSelectionDownTextIntent> {
  @override
  Object? invoke(ExtendSelectionDownTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionDown(SelectionChangedCause.keyboard);
  }
}

class _ExtendSelectionLeftByLineTextAction extends TextEditingAction<ExtendSelectionLeftByLineTextIntent> {
  @override
  Object? invoke(ExtendSelectionLeftByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionLeftByLine(SelectionChangedCause.keyboard);
  }
}

class _ExtendSelectionLeftByWordAndStopAtReversalTextAction extends TextEditingAction<ExtendSelectionLeftByWordAndStopAtReversalTextIntent> {
  @override
  Object? invoke(ExtendSelectionLeftByWordAndStopAtReversalTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionLeftByWord(SelectionChangedCause.keyboard, false, true);
  }
}

class _ExtendSelectionLeftByWordTextAction extends TextEditingAction<ExtendSelectionLeftByWordTextIntent> {
  @override
  Object? invoke(ExtendSelectionLeftByWordTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionLeftByWord(SelectionChangedCause.keyboard, false);
  }
}

class _ExtendSelectionLeftTextAction extends TextEditingAction<ExtendSelectionLeftTextIntent> {
  @override
  Object? invoke(ExtendSelectionLeftTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionLeft(SelectionChangedCause.keyboard);
  }
}

class _ExtendSelectionRightByLineTextAction extends TextEditingAction<ExtendSelectionRightByLineTextIntent> {
  @override
  Object? invoke(ExtendSelectionRightByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionRightByLine(SelectionChangedCause.keyboard);
  }
}

class _ExtendSelectionRightByWordAndStopAtReversalTextAction extends TextEditingAction<ExtendSelectionRightByWordAndStopAtReversalTextIntent> {
  @override
  Object? invoke(ExtendSelectionRightByWordAndStopAtReversalTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionRightByWord(SelectionChangedCause.keyboard, false, true);
  }
}

class _ExtendSelectionRightByWordTextAction extends TextEditingAction<ExtendSelectionRightByWordTextIntent> {
  @override
  Object? invoke(ExtendSelectionRightByWordTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionRightByWord(SelectionChangedCause.keyboard, false);
  }
}

class _ExtendSelectionRightTextAction extends TextEditingAction<ExtendSelectionRightTextIntent> {
  @override
  Object? invoke(ExtendSelectionRightTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionRight(SelectionChangedCause.keyboard);
  }
}

class _ExtendSelectionUpTextAction extends TextEditingAction<ExtendSelectionUpTextIntent> {
  @override
  Object? invoke(ExtendSelectionUpTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionUp(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionDownTextAction extends TextEditingAction<MoveSelectionDownTextIntent> {
  @override
  Object? invoke(MoveSelectionDownTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionDown(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionLeftTextAction extends TextEditingAction<MoveSelectionLeftTextIntent> {
  @override
  Object? invoke(MoveSelectionLeftTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionLeft(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionRightTextAction extends TextEditingAction<MoveSelectionRightTextIntent> {
  @override
  Object? invoke(MoveSelectionRightTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionRight(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionUpTextAction extends TextEditingAction<MoveSelectionUpTextIntent> {
  @override
  Object? invoke(MoveSelectionUpTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionUp(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionLeftByLineTextAction extends TextEditingAction<MoveSelectionLeftByLineTextIntent> {
  @override
  Object? invoke(MoveSelectionLeftByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionLeftByWordTextAction extends TextEditingAction<MoveSelectionLeftByWordTextIntent> {
  @override
  Object? invoke(MoveSelectionLeftByWordTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionLeftByWord(SelectionChangedCause.keyboard, false);
  }
}

class _MoveSelectionRightByLineTextAction extends TextEditingAction<MoveSelectionRightByLineTextIntent> {
  @override
  Object? invoke(MoveSelectionRightByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionRightByLine(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionRightByWordTextAction extends TextEditingAction<MoveSelectionRightByWordTextIntent> {
  @override
  Object? invoke(MoveSelectionRightByWordTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionRightByWord(SelectionChangedCause.keyboard, false);
  }
}

class _MoveSelectionToEndTextAction extends TextEditingAction<MoveSelectionToEndTextIntent> {
  @override
  Object? invoke(MoveSelectionToEndTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionToEnd(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionToStartTextAction extends TextEditingAction<MoveSelectionToStartTextIntent> {
  @override
  Object? invoke(MoveSelectionToStartTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionToStart(SelectionChangedCause.keyboard);
  }
}
