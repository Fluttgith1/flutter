// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart';

import 'text_editing_action.dart';

// TODO(justinmc): Maybe move these to a text_editing_intents.dart?
// TODO(justinmc): Do I want the const constructors? I think so so that the
// instantiation can be const.
class AltArrowLeftTextIntent extends Intent {
  const AltArrowLeftTextIntent();
}
class AltArrowRightTextIntent extends Intent {
  const AltArrowRightTextIntent();
}
class AltShiftArrowLeftTextIntent extends Intent {
  const AltShiftArrowLeftTextIntent();
}
class AltShiftArrowRightTextIntent extends Intent {
  const AltShiftArrowRightTextIntent();
}
class ArrowDownTextIntent extends Intent {
  const ArrowDownTextIntent();
}
class ArrowUpTextIntent extends Intent {
  const ArrowUpTextIntent();
}
class DoubleTapDownTextIntent extends Intent {
  const DoubleTapDownTextIntent();
}
class DragSelectionEndTextIntent extends Intent {
  const DragSelectionEndTextIntent();
}
class DragSelectionStartTextIntent extends Intent {
  const DragSelectionStartTextIntent();
}
class DragSelectionUpdateTextIntent extends Intent {
  const DragSelectionUpdateTextIntent();
}
class ForcePressEndTextIntent extends Intent {
  const ForcePressEndTextIntent();
}
class ForcePressStartTextIntent extends Intent {
  const ForcePressStartTextIntent();
}
class EndTextIntent extends Intent {
  const EndTextIntent();
}
class HomeTextIntent extends Intent {
  const HomeTextIntent();
}
class MetaArrowDownTextIntent extends Intent {
  const MetaArrowDownTextIntent();
}
class MetaArrowLeftTextIntent extends Intent {
  const MetaArrowLeftTextIntent();
}
class MetaArrowRightTextIntent extends Intent {
  const MetaArrowRightTextIntent();
}
class MetaArrowUpTextIntent extends Intent {
  const MetaArrowUpTextIntent();
}
class MetaShiftArrowDownTextIntent extends Intent {
  const MetaShiftArrowDownTextIntent();
}
class MetaShiftArrowLeftTextIntent extends Intent {
  const MetaShiftArrowLeftTextIntent();
}
class MetaShiftArrowRightTextIntent extends Intent {
  const MetaShiftArrowRightTextIntent();
}
class MetaShiftArrowUpTextIntent extends Intent {
  const MetaShiftArrowUpTextIntent();
}
class MetaCTextIntent extends Intent {
  const MetaCTextIntent();
}
class SingleLongTapEndTextIntent extends Intent {
  const SingleLongTapEndTextIntent();
}
class SingleLongTapMoveUpdateTextIntent extends Intent {
  const SingleLongTapMoveUpdateTextIntent();
}
class SingleLongTapStartTextIntent extends Intent {
  const SingleLongTapStartTextIntent();
}
class SingleTapCancelTextIntent extends Intent {
  const SingleTapCancelTextIntent();
}
class ShiftArrowDownTextIntent extends Intent {
  const ShiftArrowDownTextIntent();
}
class ShiftArrowLeftTextIntent extends Intent {
  const ShiftArrowLeftTextIntent();
}
class ShiftArrowRightTextIntent extends Intent {
  const ShiftArrowRightTextIntent();
}
class ShiftArrowUpTextIntent extends Intent {
  const ShiftArrowUpTextIntent();
}
class ShiftEndTextIntent extends Intent {
  const ShiftEndTextIntent();
}
class ShiftHomeTextIntent extends Intent {
  const ShiftHomeTextIntent();
}
class ArrowLeftTextIntent extends Intent {}
class ArrowRightTextIntent extends Intent {}
class ControlATextIntent extends Intent {}
class ControlArrowLeftTextIntent extends Intent {}
class ControlArrowRightTextIntent extends Intent {}
class ControlCTextIntent extends Intent {}
class SingleTapUpTextIntent extends Intent {
  const SingleTapUpTextIntent({
    required this.details,
  });

  final TapUpDetails details;
}
class TapDownTextIntent extends Intent {
  const TapDownTextIntent({
    required this.details,
  });

  final TapDownDetails details;
}

// TODO(justinmc): Document.
/// The map of [Action]s that correspond to the default behavior for Flutter on
/// the current platform.
///
/// See also:
///
/// * [Actions], the widget that accepts a map like this.
class TextEditingActions extends StatelessWidget {
  /// Creates an instance of TextEditingActions.
  TextEditingActions({
    Key? key,
    // TODO(justinmc): Is additionalActions a good way to do this?
    Map<Type, Action<Intent>>? additionalActions,
    required this.child,
  }) : additionalActions = additionalActions ?? <Type, Action<Intent>>{},
       super(key: key);

  /// The child [Widget] of TextEditingActions.
  final Widget child;

  /// The actions to be merged with the default text editing actions.
  ///
  /// The default text editing actions will override any conflicting keys in
  /// additionalActions. To override the default text editing actions, use an
  /// [Actions] Widget in the tree below this Widget.
  final Map<Type, Action<Intent>> additionalActions;

  // TODO(justinmc): All of these can be static. Should be public for users to
  // be able to use/remap them.
  static final TextEditingAction<SingleTapUpTextIntent> _singleTapUpTextAction = TextEditingAction<SingleTapUpTextIntent>(
    onInvoke: (SingleTapUpTextIntent intent, EditableTextState editableTextState) {
      print('justin TEB singleTapUp action invoked');
      editableTextState.hideToolbar();
      if (editableTextState.widget.selectionEnabled) {
        switch (defaultTargetPlatform) {
          case TargetPlatform.iOS:
          case TargetPlatform.macOS:
            switch (intent.details.kind) {
              case PointerDeviceKind.mouse:
              case PointerDeviceKind.stylus:
              case PointerDeviceKind.invertedStylus:
                // Precise devices should place the cursor at a precise position.
                editableTextState.renderEditable.selectPosition(cause: SelectionChangedCause.tap);
                break;
              case PointerDeviceKind.touch:
              case PointerDeviceKind.unknown:
                // On macOS/iOS/iPadOS a touch tap places the cursor at the edge
                // of the word.
                editableTextState.renderEditable.selectWordEdge(cause: SelectionChangedCause.tap);
                break;
            }
            break;
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
          case TargetPlatform.linux:
          case TargetPlatform.windows:
            editableTextState.renderEditable.selectPosition(cause: SelectionChangedCause.tap);
            break;
        }
      }
      // TODO(justinmc): State of keyboard visibility should be controllable here
      // too.
      //_state._requestKeyboard();

      // TODO(justinmc): Still need to handle calling of onTap.
      //if (_state.widget.onTap != null)
      //  _state.widget.onTap!();
    },
  );

  /// Handler for [TextSelectionGestureDetector.onTapDown].
  ///
  /// By default, it forwards the tap to [RenderEditable.handleTapDown] and sets
  /// [shouldShowSelectionToolbar] to true if the tap was initiated by a finger or stylus.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onTapDown], which triggers this callback.
  final TextEditingAction<TapDownTextIntent> _tapDownTextAction = TextEditingAction<TapDownTextIntent>(
    onInvoke: (TapDownTextIntent intent, EditableTextState editableTextState) {
      // TODO(justinmc): Should be no handling anything in renderEditable, it
      // should just receive commands to do specific things.
      editableTextState.renderEditable.handleTapDown(intent.details);
      // The selection overlay should only be shown when the user is interacting
      // through a touch screen (via either a finger or a stylus). A mouse shouldn't
      // trigger the selection overlay.
      // For backwards-compatibility, we treat a null kind the same as touch.
      //final PointerDeviceKind? kind = intent.details.kind;
      // TODO(justinmc): What about _shouldShowSelectionToolbar?
      /*
      _shouldShowSelectionToolbar = kind == null
        || kind == PointerDeviceKind.touch
        || kind == PointerDeviceKind.stylus;
        */
    },
  );

  final TextEditingAction<AltArrowLeftTextIntent> _altArrowLeftTextAction = TextEditingAction<AltArrowLeftTextIntent>(
    onInvoke: (AltArrowLeftTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.moveSelectionLeftByWord(SelectionChangedCause.keyboard, false);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  final TextEditingAction<AltArrowRightTextIntent> _altArrowRightTextAction = TextEditingAction<AltArrowRightTextIntent>(
    onInvoke: (AltArrowRightTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.moveSelectionRightByWord(SelectionChangedCause.keyboard, false);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  final TextEditingAction<AltShiftArrowLeftTextIntent> _altShiftArrowLeftTextAction = TextEditingAction<AltShiftArrowLeftTextIntent>(
    onInvoke: (AltShiftArrowLeftTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.extendSelectionLeftByWord(SelectionChangedCause.keyboard, false);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  final TextEditingAction<AltShiftArrowRightTextIntent> _altShiftArrowRightTextAction = TextEditingAction<AltShiftArrowRightTextIntent>(
    onInvoke: (AltShiftArrowRightTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.extendSelectionRightByWord(SelectionChangedCause.keyboard, false);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  final TextEditingAction<MetaArrowDownTextIntent> _metaArrowDownTextAction = TextEditingAction<MetaArrowDownTextIntent>(
    onInvoke: (MetaArrowDownTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.moveSelectionToEnd(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  final TextEditingAction<MetaArrowLeftTextIntent> _metaArrowLeftTextAction = TextEditingAction<MetaArrowLeftTextIntent>(
    onInvoke: (MetaArrowLeftTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  final TextEditingAction<MetaArrowRightTextIntent> _metaArrowRightTextAction = TextEditingAction<MetaArrowRightTextIntent>(
    onInvoke: (MetaArrowRightTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.moveSelectionRightByLine(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  final TextEditingAction<MetaArrowUpTextIntent> _metaArrowUpTextAction = TextEditingAction<MetaArrowUpTextIntent>(
    onInvoke: (MetaArrowUpTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.moveSelectionToStart(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  final TextEditingAction<MetaShiftArrowDownTextIntent> _metaShiftArrowDownTextAction = TextEditingAction<MetaShiftArrowDownTextIntent>(
    onInvoke: (MetaShiftArrowDownTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.extendSelectionToEnd(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  final TextEditingAction<MetaShiftArrowLeftTextIntent> _metaShiftArrowLeftTextAction = TextEditingAction<MetaShiftArrowLeftTextIntent>(
    onInvoke: (MetaShiftArrowLeftTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.extendSelectionLeftByLine(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  final TextEditingAction<MetaShiftArrowRightTextIntent> _metaShiftArrowRightTextAction = TextEditingAction<MetaShiftArrowRightTextIntent>(
    onInvoke: (MetaShiftArrowRightTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.extendSelectionRightByLine(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  final TextEditingAction<MetaShiftArrowUpTextIntent> _metaShiftArrowUpTextAction = TextEditingAction<MetaShiftArrowUpTextIntent>(
    onInvoke: (MetaShiftArrowUpTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.extendSelectionToStart(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  final TextEditingAction<MetaCTextIntent> _metaCTextAction = TextEditingAction<MetaCTextIntent>(
    onInvoke: (MetaCTextIntent intent, EditableTextState editableTextState) {
      // TODO(justinmc): This needs to be deduplicated with text_selection.dart.
      final TextSelectionDelegate delegate = editableTextState.renderEditable.textSelectionDelegate;
      final TextEditingValue value = delegate.textEditingValue;
      Clipboard.setData(ClipboardData(
        text: value.selection.textInside(value.text),
      ));
      //clipboardStatus?.update();
      delegate.textEditingValue = TextEditingValue(
        text: value.text,
        selection: TextSelection.collapsed(offset: value.selection.end),
      );
      delegate.bringIntoView(delegate.textEditingValue.selection.extent);
      //delegate.hideToolbar();
    },
  );

  // TODO(justinmc): Notice that this does nearly the same thing as
  // MetaArrowLeftTextIntent, but for different platforms.
  final TextEditingAction<HomeTextIntent> _homeTextAction = TextEditingAction<HomeTextIntent>(
    onInvoke: (HomeTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.windows:
          editableTextState.renderEditable.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          break;
      }
    },
  );

  final TextEditingAction<EndTextIntent> _endTextAction = TextEditingAction<EndTextIntent>(
    onInvoke: (EndTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.windows:
          editableTextState.renderEditable.moveSelectionRightByLine(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          break;
      }
    },
  );

  final TextEditingAction<ArrowDownTextIntent> _arrowDownTextAction = TextEditingAction<ArrowDownTextIntent>(
    onInvoke: (ArrowDownTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionDown(SelectionChangedCause.keyboard);
    },
  );

  final TextEditingAction<ArrowLeftTextIntent> _arrowLeftTextAction = TextEditingAction<ArrowLeftTextIntent>(
    onInvoke: (ArrowLeftTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionLeft(SelectionChangedCause.keyboard);
    },
  );

  final TextEditingAction<ArrowRightTextIntent> _arrowRightTextAction = TextEditingAction<ArrowRightTextIntent>(
    onInvoke: (ArrowRightTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionRight(SelectionChangedCause.keyboard);
    },
  );

  final TextEditingAction<ArrowUpTextIntent> _arrowUpTextAction = TextEditingAction<ArrowUpTextIntent>(
    onInvoke: (ArrowUpTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionUp(SelectionChangedCause.keyboard);
    },
  );

  final TextEditingAction<ControlCTextIntent> _controlCTextAction = TextEditingAction<ControlCTextIntent>(
    onInvoke: (ControlCTextIntent intent, EditableTextState editableTextState) {
      print('justin copy (with control, not command)');
    },
  );

  final TextEditingAction<ControlATextIntent> _controlATextAction = TextEditingAction<ControlATextIntent>(
    onInvoke: (ControlATextIntent intent, EditableTextState editableTextState) {
      // TODO(justinmc): Select all.
    },
  );

  final TextEditingAction<ControlArrowLeftTextIntent> _controlArrowLeftTextAction = TextEditingAction<ControlArrowLeftTextIntent>(
    onInvoke: (ControlArrowLeftTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          editableTextState.renderEditable.moveSelectionLeftByWord(SelectionChangedCause.keyboard);
          break;
      }
    },
  );

  final TextEditingAction<ControlArrowRightTextIntent> _controlArrowRightTextAction = TextEditingAction<ControlArrowRightTextIntent>(
    onInvoke: (ControlArrowRightTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          editableTextState.renderEditable.moveSelectionRightByWord(SelectionChangedCause.keyboard);
          break;
      }
    },
  );

  final TextEditingAction<ShiftArrowDownTextIntent> _shiftArrowDownTextAction = TextEditingAction<ShiftArrowDownTextIntent>(
    onInvoke: (ShiftArrowDownTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionDown(SelectionChangedCause.keyboard);
    },
  );

  final TextEditingAction<ShiftArrowLeftTextIntent> _shiftArrowLeftTextAction = TextEditingAction<ShiftArrowLeftTextIntent>(
    onInvoke: (ShiftArrowLeftTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionLeft(SelectionChangedCause.keyboard);
    },
  );

  final TextEditingAction<ShiftArrowRightTextIntent> _shiftArrowRightTextAction = TextEditingAction<ShiftArrowRightTextIntent>(
    onInvoke: (ShiftArrowRightTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionRight(SelectionChangedCause.keyboard);
    },
  );

  final TextEditingAction<ShiftArrowUpTextIntent> _shiftArrowUpTextAction = TextEditingAction<ShiftArrowUpTextIntent>(
    onInvoke: (ShiftArrowUpTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionUp(SelectionChangedCause.keyboard);
    },
  );

  final TextEditingAction<ShiftHomeTextIntent> _shiftHomeTextAction = TextEditingAction<ShiftHomeTextIntent>(
    onInvoke: (ShiftHomeTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.windows:
          editableTextState.renderEditable.extendSelectionLeftByLine(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          break;
      }
    },
  );

  final TextEditingAction<ShiftEndTextIntent> _shiftEndTextAction = TextEditingAction<ShiftEndTextIntent>(
    onInvoke: (ShiftEndTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.windows:
          editableTextState.renderEditable.extendSelectionRightByLine(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          break;
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    return Actions(
      // TODO(justinmc): Should handle all actions from
      // TextSelectionGestureDetectorBuilder and from
      // _TextFieldSelectionGestureDetectorBuilder.
      // TODO(justinmc): Alternative idea: These intents should map to actions
      // that are named for what they do. The mapping is different depending on
      // the platform. I guess I'd have a bunch of properties above like
      // _androidTextEditingActionMap etc. But then, would each action just be
      // a single call to a RenderEditable method?
      actions: <Type, Action<Intent>>{
        ...additionalActions,
        AltArrowLeftTextIntent: _altArrowLeftTextAction,
        AltArrowRightTextIntent: _altArrowRightTextAction,
        AltShiftArrowLeftTextIntent: _altShiftArrowLeftTextAction,
        AltShiftArrowRightTextIntent: _altShiftArrowRightTextAction,
        ArrowDownTextIntent: _arrowDownTextAction,
        ArrowLeftTextIntent: _arrowLeftTextAction,
        ArrowRightTextIntent: _arrowRightTextAction,
        ArrowUpTextIntent: _arrowUpTextAction,
        ControlATextIntent: _controlATextAction,
        ControlArrowLeftTextIntent: _controlArrowLeftTextAction,
        ControlArrowRightTextIntent: _controlArrowRightTextAction,
        ControlCTextIntent: _controlCTextAction,
        EndTextIntent: _endTextAction,
        HomeTextIntent: _homeTextAction,
        MetaCTextIntent: _metaCTextAction,
        MetaArrowDownTextIntent: _metaArrowDownTextAction,
        MetaArrowRightTextIntent: _metaArrowRightTextAction,
        MetaArrowLeftTextIntent: _metaArrowLeftTextAction,
        MetaArrowUpTextIntent: _metaArrowUpTextAction,
        MetaShiftArrowDownTextIntent: _metaShiftArrowDownTextAction,
        MetaShiftArrowLeftTextIntent: _metaShiftArrowLeftTextAction,
        MetaShiftArrowRightTextIntent: _metaShiftArrowRightTextAction,
        MetaShiftArrowUpTextIntent: _metaShiftArrowUpTextAction,
        ShiftArrowDownTextIntent: _shiftArrowDownTextAction,
        ShiftArrowLeftTextIntent: _shiftArrowLeftTextAction,
        ShiftArrowRightTextIntent: _shiftArrowRightTextAction,
        ShiftArrowUpTextIntent: _shiftArrowUpTextAction,
        SingleTapUpTextIntent: _singleTapUpTextAction,
        ShiftHomeTextIntent: _shiftHomeTextAction,
        ShiftEndTextIntent: _shiftEndTextAction,
        TapDownTextIntent: _tapDownTextAction,
      },
      child: child,
    );
  }
}
