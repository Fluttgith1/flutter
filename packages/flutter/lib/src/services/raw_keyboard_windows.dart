// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'keyboard_maps.g.dart';
import 'raw_keyboard.dart';

export 'package:flutter/foundation.dart' show DiagnosticPropertiesBuilder;

export 'keyboard_key.g.dart' show LogicalKeyboardKey, PhysicalKeyboardKey;
export 'raw_keyboard.dart' show KeyboardSide, ModifierKey;

// Virtual key VK_PROCESSKEY in Win32 API.
//
// Key down events related to IME operations use this as keyCode.
const int _vkProcessKey = 0xe5;

/// Platform-specific key event data for Windows.
///
/// This object contains information about key events obtained from Windows's
/// win32 API.
///
/// See also:
///
///  * [RawKeyboard], which uses this interface to expose key data.
class RawKeyEventDataWindows extends RawKeyEventData {
  /// Creates a key event data structure specific for Windows.
  ///
  /// The [keyCode], [scanCode], [characterCodePoint], and [modifiers], arguments
  /// must not be null.
  const RawKeyEventDataWindows({
    this.keyCode = 0,
    this.scanCode = 0,
    this.characterCodePoint = 0,
    this.modifiers = 0,
  })  : assert(keyCode != null),
        assert(scanCode != null),
        assert(characterCodePoint != null),
        assert(modifiers != null);

  /// The hardware key code corresponding to this key event.
  ///
  /// This is the physical key that was pressed, not the Unicode character.
  /// See [characterCodePoint] for the Unicode character.
  final int keyCode;

  /// The hardware scan code id corresponding to this key event.
  ///
  /// These values are not reliable and vary from device to device, so this
  /// information is mainly useful for debugging.
  final int scanCode;

  /// The Unicode code point represented by the key event, if any.
  ///
  /// If there is no Unicode code point, this value is zero.
  final int characterCodePoint;

  /// A mask of the current modifiers. The modifier values must be in sync with
  /// the ones defined in https://github.com/flutter/engine/blob/master/shell/platform/windows/key_event_handler.cc
  final int modifiers;

  @override
  String get keyLabel => characterCodePoint == 0 ? '' : String.fromCharCode(characterCodePoint);

  @override
  PhysicalKeyboardKey get physicalKey =>
      kWindowsToPhysicalKey[scanCode] ?? PhysicalKeyboardKey(LogicalKeyboardKey.windowsPlane + scanCode);

  @override
  LogicalKeyboardKey get logicalKey {
    // Look to see if the keyCode is a printable number pad key, so that a
    // difference between regular keys (e.g. "=") and the number pad version
    // (e.g. the "=" on the number pad) can be determined.
    final LogicalKeyboardKey? numPadKey = kWindowsNumPadMap[keyCode];
    if (numPadKey != null) {
      return numPadKey;
    }

    // If it has a non-control-character label, then either return the existing
    // constant, or construct a new Unicode-based key from it. Don't mark it as
    // autogenerated, since the label uniquely identifies an ID from the Unicode
    // plane.
    if (keyLabel.isNotEmpty && !LogicalKeyboardKey.isControlCharacter(keyLabel)) {
      final int keyId = LogicalKeyboardKey.unicodePlane | (characterCodePoint & LogicalKeyboardKey.valueMask);
      return LogicalKeyboardKey.findKeyByKeyId(keyId) ?? LogicalKeyboardKey(keyId);
    }
    // Look to see if the keyCode is one we know about and have a mapping for.
    final LogicalKeyboardKey? newKey = kWindowsToLogicalKey[keyCode];
    if (newKey != null) {
      return newKey;
    }

    // This is a non-printable key that we don't know about, so we mint a new
    // code.
    return LogicalKeyboardKey(keyCode | LogicalKeyboardKey.windowsPlane);
  }

  bool _isLeftRightModifierPressed(KeyboardSide side, int anyMask, int leftMask, int rightMask) {
    if (modifiers & anyMask == 0 && modifiers & leftMask == 0 && modifiers & rightMask == 0) {
      return false;
    }
    // If only the "anyMask" bit is set, then we respond true for requests of
    // whether either left or right is pressed. Handles the case where Windows
    // supplies just the "either" modifier flag, but not the left/right flag.
    // (e.g. modifierShift but not modifierLeftShift).
    final bool anyOnly = modifiers & (leftMask | rightMask | anyMask) == anyMask;
    switch (side) {
      case KeyboardSide.any:
        return true;
      case KeyboardSide.all:
        return modifiers & leftMask != 0 && modifiers & rightMask != 0 || anyOnly;
      case KeyboardSide.left:
        return modifiers & leftMask != 0 || anyOnly;
      case KeyboardSide.right:
        return modifiers & rightMask != 0 || anyOnly;
    }
  }

  @override
  bool isModifierPressed(ModifierKey key, {KeyboardSide side = KeyboardSide.any}) {
    final bool result;
    switch (key) {
      case ModifierKey.controlModifier:
        result = _isLeftRightModifierPressed(side, modifierControl, modifierLeftControl, modifierRightControl);
        break;
      case ModifierKey.shiftModifier:
        result = _isLeftRightModifierPressed(side, modifierShift, modifierLeftShift, modifierRightShift);
        break;
      case ModifierKey.altModifier:
        result = _isLeftRightModifierPressed(side, modifierAlt, modifierLeftAlt, modifierRightAlt);
        break;
      case ModifierKey.metaModifier:
        // Windows does not provide an "any" key for win key press.
        result = _isLeftRightModifierPressed(
            side, modifierLeftMeta | modifierRightMeta, modifierLeftMeta, modifierRightMeta);
        break;
      case ModifierKey.capsLockModifier:
        result = modifiers & modifierCaps != 0;
        break;
      case ModifierKey.scrollLockModifier:
        result = modifiers & modifierScrollLock != 0;
        break;
      case ModifierKey.numLockModifier:
        result = modifiers & modifierNumLock != 0;
        break;
      // The OS does not expose the Fn key to the drivers, it doesn't generate a key message.
      case ModifierKey.functionModifier:
      case ModifierKey.symbolModifier:
        // These modifier masks are not used in Windows keyboards.
        result = false;
        break;
    }
    assert(!result || getModifierSide(key) != null,
        "$runtimeType thinks that a modifier is pressed, but can't figure out what side it's on.");
    return result;
  }

  @override
  KeyboardSide? getModifierSide(ModifierKey key) {
    KeyboardSide? findSide(int leftMask, int rightMask, int anyMask) {
      final int combinedMask = leftMask | rightMask;
      final int combined = modifiers & combinedMask;
      if (combined == leftMask) {
        return KeyboardSide.left;
      } else if (combined == rightMask) {
        return KeyboardSide.right;
      } else if (combined == combinedMask || modifiers & (combinedMask | anyMask) == anyMask) {
        // Handles the case where Windows supplies just the "either" modifier
        // flag, but not the left/right flag. (e.g. modifierShift but not
        // modifierLeftShift).
        return KeyboardSide.all;
      }
      return null;
    }

    switch (key) {
      case ModifierKey.controlModifier:
        return findSide(modifierLeftControl, modifierRightControl, modifierControl);
      case ModifierKey.shiftModifier:
        return findSide(modifierLeftShift, modifierRightShift, modifierShift);
      case ModifierKey.altModifier:
        return findSide(modifierLeftAlt, modifierRightAlt, modifierAlt);
      case ModifierKey.metaModifier:
        return findSide(modifierLeftMeta, modifierRightMeta, 0);
      case ModifierKey.capsLockModifier:
      case ModifierKey.numLockModifier:
      case ModifierKey.scrollLockModifier:
      case ModifierKey.functionModifier:
      case ModifierKey.symbolModifier:
        return KeyboardSide.all;
    }
  }

  @override
  bool shouldDispatchEvent() {
    // In Win32 API, down events related to IME operations use VK_PROCESSKEY as
    // keyCode. This event, as well as the following key up event (which uses a
    // normal keyCode), should be skipped, because the effect of IME operations
    // will be handled by the text input API.
    return keyCode != _vkProcessKey;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<int>('keyCode', keyCode));
    properties.add(DiagnosticsProperty<int>('scanCode', scanCode));
    properties.add(DiagnosticsProperty<int>('characterCodePoint', characterCodePoint));
    properties.add(DiagnosticsProperty<int>('modifiers', modifiers));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is RawKeyEventDataWindows &&
        other.keyCode == keyCode &&
        other.scanCode == scanCode &&
        other.characterCodePoint == characterCodePoint &&
        other.modifiers == modifiers;
  }

  @override
  int get hashCode => Object.hash(
        keyCode,
        scanCode,
        characterCodePoint,
        modifiers,
      );

  // These are not the values defined by the Windows header for each modifier. Since they
  // can't be packaged into a single int, we are re-defining them here to reduce the size
  // of the message from the embedder. Embedders should map these values to the native key codes.
  // Keep this in sync with https://github.com/flutter/engine/blob/master/shell/platform/windows/key_event_handler.cc

  /// This mask is used to check the [modifiers] field to test whether one of the
  /// SHIFT modifier keys is pressed.
  ///
  /// {@template flutter.services.RawKeyEventDataWindows.modifierShift}
  /// Use this value if you need to decode the [modifiers] field yourself, but
  /// it's much easier to use [isModifierPressed] if you just want to know if
  /// a modifier is pressed.
  /// {@endtemplate}
  static const int modifierShift = 1 << 0;

  /// This mask is used to check the [modifiers] field to test whether the left
  /// SHIFT modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataWindows.modifierShift}
  static const int modifierLeftShift = 1 << 1;

  /// This mask is used to check the [modifiers] field to test whether the right
  /// SHIFT modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataWindows.modifierShift}
  static const int modifierRightShift = 1 << 2;

  /// This mask is used to check the [modifiers] field to test whether one of the
  /// CTRL modifier keys is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataWindows.modifierShift}
  static const int modifierControl = 1 << 3;

  /// This mask is used to check the [modifiers] field to test whether the left
  /// CTRL modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataWindows.modifierShift}
  static const int modifierLeftControl = 1 << 4;

  /// This mask is used to check the [modifiers] field to test whether the right
  /// CTRL modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataWindows.modifierShift}
  static const int modifierRightControl = 1 << 5;

  /// This mask is used to check the [modifiers] field to test whether one of the
  /// ALT modifier keys is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataWindows.modifierShift}
  static const int modifierAlt = 1 << 6;

  /// This mask is used to check the [modifiers] field to test whether the left
  /// ALT modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataWindows.modifierShift}
  static const int modifierLeftAlt = 1 << 7;

  /// This mask is used to check the [modifiers] field to test whether the right
  /// ALT modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataWindows.modifierShift}
  static const int modifierRightAlt = 1 << 8;

  /// This mask is used to check the [modifiers] field to test whether the left
  /// WIN modifier keys is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataWindows.modifierShift}
  static const int modifierLeftMeta = 1 << 9;

  /// This mask is used to check the [modifiers] field to test whether the right
  /// WIN modifier keys is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataWindows.modifierShift}
  static const int modifierRightMeta = 1 << 10;

  /// This mask is used to check the [modifiers] field to test whether the CAPS LOCK key
  /// is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataWindows.modifierShift}
  static const int modifierCaps = 1 << 11;

  /// This mask is used to check the [modifiers] field to test whether the NUM LOCK key
  /// is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataWindows.modifierShift}
  static const int modifierNumLock = 1 << 12;

  /// This mask is used to check the [modifiers] field to test whether the SCROLL LOCK key
  /// is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataWindows.modifierShift}
  static const int modifierScrollLock = 1 << 13;
}
