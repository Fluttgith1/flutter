// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

import 'actions.dart';
import 'framework.dart';
import 'shortcuts.dart';
import 'text_editing_intents.dart';

/// A [Shortcuts] widget with the shortcuts used for the default text editing
/// behavior.
///
/// This default behavior can be overridden by placing a [Shortcuts] widget
/// lower in the widget tree than this. See [TextEditingActions] for an example
/// of remapping a text editing [Intent] to a custom [Action].
///
/// {@tool snippet}
///
/// This example shows how to use an additional [Shortcuts] widget to override
/// the left arrow key [Intent] and map it to the right arrow key instead.
///
/// If
///
/// ```dart
/// final TextEditingController controller = TextEditingController(
///   text: "Try using the keyboard's arrow keys and notice that left moves right.",
/// );
///
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: Center(
///       child: Shortcuts(
///         shortcuts: <LogicalKeySet, Intent>{
///           LogicalKeySet(LogicalKeyboardKey.arrowLeft): ArrowRightTextIntent(),
///         },
///         child: TextField(
///           controller: controller,
///         ),
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [TextEditingActions], which contains all of the [Action]s that respond
///    to the [Intent]s in these shortcuts with the default text editing
///    behavior.
class TextEditingShortcuts extends StatelessWidget {
  /// Creates an instance of TextEditingShortcuts.
  const TextEditingShortcuts({
    Key? key,
    required this.child,
  }) : super(key: key);

  /// The child [Widget].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      debugLabel: '<Default Text Editing Shortcuts>',
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowDown): ArrowDownTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): ArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): ArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): ArrowUpTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): AltArrowDownTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): AltArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): AltArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp): AltArrowUpTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): AltShiftArrowDownTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): AltShiftArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): AltShiftArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): AltShiftArrowUpTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft):  ControlArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight):  ControlArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft):  ControlShiftArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight):  ControlShiftArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.end):  EndTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.home):  HomeTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyC):  MetaCTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowDown):  MetaArrowDownTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowRight):  MetaArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowLeft):  MetaArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowUp):  MetaArrowUpTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown):  MetaShiftArrowDownTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight):  MetaShiftArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft):  MetaShiftArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp):  MetaShiftArrowUpTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): ShiftArrowDownTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): ShiftArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): ShiftArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.home):  ShiftHomeTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.end):  ShiftEndTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): ShiftArrowUpTextIntent(),
      },
      child: child,
    );
  }
}
