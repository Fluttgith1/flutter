// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

import 'desktop_text_selection.dart';
import 'text_selection_toolbar.dart';
import 'text_selection_toolbar_buttons.dart';
import 'theme.dart';

// TODO(justinmc): A user building a contextual menu not related to text
// selection might want something like this, too.
/// The default contextual menu for text selection for the current platform.
///
/// See also:
///
/// * [TextSelectionToolbarButtonDatasBuilder], which builds the
///   [ContextualMenuButtonData]s.
/// * [TextSelectionToolbarButtonsBuilder], which builds the button Widgets
///   given [ContextualMenuButtonData]s.
class DefaultTextSelectionToolbar extends StatelessWidget {
  /// Create an instance of [DefaultTextSelectionToolbar].
  const DefaultTextSelectionToolbar({
    super.key,
    required this.primaryAnchor,
    this.secondaryAnchor,
    this.buttonDatas,
    this.children,
    this.editableTextState,
  }) : assert(
         buttonDatas == null || children == null,
         'No need for both buttonDatas and children.',
       ),
       assert(
         !(buttonDatas == null && children == null && editableTextState == null),
         'If not providing buttonDatas or children, provide editableTextState to generate them.',
       );

  /// The main location on which to anchor the menu.
  ///
  /// Optionally, [secondaryAnchor] can be provided as an alternative anchor
  /// location if the menu doesn't fit here.
  final Offset primaryAnchor;

  /// The optional secondary location on which to anchor the menu, if it doesn't
  /// fit at [primaryAnchor].
  final Offset? secondaryAnchor;

  /// The information needed to create each child button of the menu.
  ///
  /// If provided, [children] cannot also be provided.
  final List<ContextualMenuButtonData>? buttonDatas;

  /// Used to generate the default buttons for the platform in the case that
  /// [children] and [buttonDatas] are not provided.
  final EditableTextState? editableTextState;

  // TODO(justinmc): Does it make sesne to have this parameter? Even though
  // there is a switch on the platform in here. Try out some examples.
  /// The children of the toolbar.
  ///
  /// If provided, buttonDatas cannot also be provided.
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if ((children?.isEmpty ?? false) || (buttonDatas?.isEmpty ?? false)) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    if (children?.isNotEmpty ?? false) {
      return _DefaultTextSelectionToolbarFromChildren(
        primaryAnchor: primaryAnchor,
        secondaryAnchor: secondaryAnchor,
        children: children!,
      );
    }

    if (buttonDatas?.isNotEmpty ?? false) {
      return _DefaultTextSelectionToolbarFromButtonDatas(
        primaryAnchor: primaryAnchor,
        secondaryAnchor: secondaryAnchor,
        buttonDatas: buttonDatas!,
      );
    }

    return TextSelectionToolbarButtonDatasBuilder(
      editableTextState: editableTextState!,
      builder: (BuildContext context, List<ContextualMenuButtonData> buttonDatas) {
        return _DefaultTextSelectionToolbarFromButtonDatas(
          primaryAnchor: primaryAnchor,
          secondaryAnchor: secondaryAnchor,
          buttonDatas: buttonDatas,
        );
      },
    );
  }
}

/// The default text selection toolbar by platform given the [children] for the
/// platform.
class _DefaultTextSelectionToolbarFromChildren extends StatelessWidget {
  const _DefaultTextSelectionToolbarFromChildren({
    required this.primaryAnchor,
    this.secondaryAnchor,
    required this.children,
  }) : assert(children != null);

  /// The main location on which to anchor the menu.
  ///
  /// Optionally, [secondaryAnchor] can be provided as an alternative anchor
  /// location if the menu doesn't fit here.
  final Offset primaryAnchor;

  /// The optional secondary location on which to anchor the menu, if it doesn't
  /// fit at [primaryAnchor].
  final Offset? secondaryAnchor;

  /// The children of the toolbar, typically buttons.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if (children.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
        return CupertinoTextSelectionToolbar(
          anchorAbove: primaryAnchor,
          anchorBelow: secondaryAnchor!,
          children: children,
        );
      case TargetPlatform.android:
        return TextSelectionToolbar(
          anchorAbove: primaryAnchor,
          anchorBelow: secondaryAnchor!,
          children: children,
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return DesktopTextSelectionToolbar(
          anchor: primaryAnchor,
          children: children,
        );
      case TargetPlatform.macOS:
        return CupertinoDesktopTextSelectionToolbar(
          anchor: primaryAnchor,
          children: children,
        );
    }
  }
}

/// The default text selection toolbar by platform given [buttonDatas]
/// representing the children for the platform.
class _DefaultTextSelectionToolbarFromButtonDatas extends StatelessWidget {
  const _DefaultTextSelectionToolbarFromButtonDatas({
    required this.primaryAnchor,
    this.secondaryAnchor,
    required this.buttonDatas,
  }) : assert(buttonDatas != null);

  /// The main location on which to anchor the menu.
  ///
  /// Optionally, [secondaryAnchor] can be provided as an alternative anchor
  /// location if the menu doesn't fit here.
  final Offset primaryAnchor;

  /// The optional secondary location on which to anchor the menu, if it doesn't
  /// fit at [primaryAnchor].
  final Offset? secondaryAnchor;

  /// The information needed to create each child button of the menu.
  final List<ContextualMenuButtonData> buttonDatas;

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if (buttonDatas.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return TextSelectionToolbarButtonsBuilder(
      buttonDatas: buttonDatas,
      builder: (BuildContext context, List<Widget> children) {
        return _DefaultTextSelectionToolbarFromChildren(
          primaryAnchor: primaryAnchor,
          secondaryAnchor: secondaryAnchor,
          children: children,
        );
      },
    );
  }
}
