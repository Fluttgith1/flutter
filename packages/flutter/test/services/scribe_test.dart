// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Scribe.registerScribeClient', () {
    // TODO
  });
}

// TODO(justinmc): Trim this down to a mock ScribeClient.
class _ScribeState extends State<_Scribe> implements ScribeClient {
  // The handwriting bounds padding of EditText in Android API 34.
  static const EdgeInsets _handwritingPadding = EdgeInsets.symmetric(
    horizontal: 10.0,
    vertical: 40.0,
  );

  /// Returns a new Rect whose size has changed by the given padding while
  /// remaining centered.
  static Rect _pad(Rect rect, EdgeInsets padding) {
    return Rect.fromLTRB(
      rect.left - padding.horizontal,
      rect.top - padding.vertical,
      rect.right + padding.horizontal,
      rect.bottom + padding.vertical,
    );
  }

  /// Given a [Rect] in a [RenderBox]'s local coordinate space, returns that
  /// [Rect] in global coordinates.
  static Rect _localToGlobalRect(Rect rect, RenderBox renderBox) {
    return Rect.fromPoints(
      renderBox.localToGlobal(rect.topLeft),
      renderBox.localToGlobal(rect.bottomRight),
    );
  }

  Rect? _getHandleRect(TextSelectionHandleType type) {
    if (widget.selectionControls == null) {
      return null;
    }
    // Do not expand the Rect to kMinInteractiveDimension because it will
    // targeted by a precise pointing device.
    return widget.selectionControls!.getHandleRect(type, _renderEditable.preferredLineHeight);
  }

  RenderEditable get _renderEditable => widget.editableKey.currentContext!.findRenderObject()! as RenderEditable;

  Future<void> _handlePointerEvent(PointerEvent event) async {
    if (event is! PointerDownEvent
      || event.kind != ui.PointerDeviceKind.stylus
      || !(await Scribe.isStylusHandwritingAvailable() ?? false)) {
      return;
    }

    final RenderBox renderBox = widget.editableKey.currentContext!.findRenderObject()! as RenderBox;

    // A stylus event that starts on a selection handle does not start
    // handwriting, it moves the handle.
    final Offset? startHandleOffset = _renderEditable.startHandleLayerLink.leader?.offset;
    if (startHandleOffset != null) {
      final Rect? leftHandleRectLocal = _getHandleRect(TextSelectionHandleType.left);
      if (leftHandleRectLocal != null && !leftHandleRectLocal.isEmpty) {
        final Rect leftHandleRectGlobal = _localToGlobalRect(leftHandleRectLocal, renderBox);
        final Rect leftHandleRect = leftHandleRectGlobal.shift(startHandleOffset);
        if (leftHandleRect.contains(event.position)) {
          return;
        }
      }
    }
    final Offset? endHandleOffset = _renderEditable.endHandleLayerLink.leader?.offset;
    if (endHandleOffset != null) {
      final Rect? rightHandleRectLocal = _getHandleRect(TextSelectionHandleType.right);
      if (rightHandleRectLocal != null && !rightHandleRectLocal.isEmpty) {
        final Rect rightHandleRectGlobal = _localToGlobalRect(rightHandleRectLocal, renderBox);
        final Rect rightHandleRect = rightHandleRectGlobal.shift(endHandleOffset);
        if (rightHandleRect.contains(event.position)) {
          return;
        }
      }
    }

    final Rect renderBoxRect = _localToGlobalRect(renderBox.paintBounds, renderBox);
    final Rect hitRect = _pad(renderBoxRect, _handwritingPadding);
    if (!hitRect.contains(event.position)) {
      return;
    }

    if (!widget.focusNode.hasFocus) {
      widget.focusNode.requestFocus();
    }

    return Scribe.startStylusHandwriting();
  }

  @override
  void initState() {
    super.initState();
    Scribe.registerScribeClient(this);
    // TODO(justinmc): Make sure you don't add this if stylus handwriting is not
    // possible (read only, disabled, anything else?).
    if (widget.enabled) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
    }
  }

  @override
  void didUpdateWidget(_Scribe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.enabled && widget.enabled) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
    }
    if (oldWidget.enabled && !widget.enabled) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointerEvent);
    }
  }

  @override
  void dispose() {
    Scribe.unregisterScribeClient(this);
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointerEvent);
    super.dispose();
  }

  // Begin ScribeClient.

  @override
  double get devicePixelRatio => MediaQuery.devicePixelRatioOf(context);

  // TODO(justinmc): ScribbleClient does this in EditableText, setting the
  // active client on Scribble. Maybe that's better? Reconcile?
  @override
  bool get isActive => widget.focusNode.hasFocus;

  // TODO(justinmc): Scribe stylus gestures should be supported here.
  // https://github.com/flutter/flutter/issues/156018

  // End ScribeClient.

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
