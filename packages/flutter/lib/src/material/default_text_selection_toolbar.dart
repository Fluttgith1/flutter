// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/rendering.dart';

import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'text_button.dart';
import 'text_selection_toolbar.dart';
import 'text_selection_toolbar_text_button.dart';
import 'theme.dart';

const double _kToolbarScreenPadding = 8.0;
const double _kToolbarWidth = 222.0;

/// The default context menu for text selection for the current platform.
///
/// The children can be customized using the [children] or [buttonDatas]
/// parameters. If neither is given, then the default buttons will be used.
///
/// See also:
///
/// * [TextSelectionToolbarButtonDatasBuilder], which builds the
///   [ContextMenuButtonData]s.
/// * [TextSelectionToolbarButtonsBuilder], which builds the button Widgets
///   given [ContextMenuButtonData]s.
/// * [DefaultCupertinoTextSelectionToolbar], which does the same thing as this
///   widget but only for Cupertino context menus.
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
         'No need for both buttonDatas and children, use one or the other, or neither.',
       ),
       assert(
         !(buttonDatas == null && children == null && editableTextState == null),
         'If not providing buttonDatas or children, provide editableTextState to generate them.',
       );

  /// If provided, used to generate the buttons.
  ///
  /// Otherwise, manually pass in [buttonDatas] or [children].
  final EditableTextState? editableTextState;

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
  final List<ContextMenuButtonData>? buttonDatas;

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
      builder: (BuildContext context, List<ContextMenuButtonData> buttonDatas) {
        return _DefaultTextSelectionToolbarFromButtonDatas(
          primaryAnchor: primaryAnchor,
          secondaryAnchor: secondaryAnchor,
          buttonDatas: buttonDatas,
        );
      },
    );
  }
}

/// Calls [builder] with a List of Widgets generated by turning [buttonDatas]
/// into the default buttons for the platform.
///
/// This is useful when building a text selection toolbar with the default
/// button appearance for the given platform, but where the toolbar and/or the
/// button actions and labels may be custom.
///
/// See also:
///
/// * [DefaultTextSelectionToolbar], which builds the toolbar itself. By
///   wrapping [TextSelectionToolbarButtonsBuilder] with
///   [DefaultTextSelectionToolbar] and passing the given children to
///   [DefaultTextSelectionToolbar.children], a default toolbar can be built
///   with custom button actions and labels.
/// * [TextSelectionToolbarButtonDatasBuilder], which is similar to this class,
///   but calls its builder with [ContextMenuButtonData]s instead of with fully
///   built children Widgets.
/// * [CupertinoTextSelectionToolbarButtonsBuilder], which is the Cupertino
///   equivalent of this class and builds only the Cupertino buttons.
class TextSelectionToolbarButtonsBuilder extends StatelessWidget {
  /// Creates an instance of [TextSelectionToolbarButtonsBuilder].
  const TextSelectionToolbarButtonsBuilder({
    super.key,
    required this.buttonDatas,
    required this.builder,
  });

  /// The information used to create each button Widget.
  final List<ContextMenuButtonData> buttonDatas;

  /// Called with a List of Widgets created from the given [buttonDatas].
  ///
  /// Typically builds a text selection toolbar with the given Widgets as
  /// children.
  final ContextMenuFromChildrenBuilder builder;

  static String _getButtonLabel(ContextMenuButtonData buttonData, MaterialLocalizations localizations) {
    if (buttonData.label != null) {
      return buttonData.label!;
    }
    switch (buttonData.type) {
      case ContextMenuButtonType.cut:
        return localizations.cutButtonLabel;
      case ContextMenuButtonType.copy:
        return localizations.copyButtonLabel;
      case ContextMenuButtonType.paste:
        return localizations.pasteButtonLabel;
      case ContextMenuButtonType.selectAll:
        return localizations.selectAllButtonLabel;
      case ContextMenuButtonType.custom:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    int buttonIndex = 0;
    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
        assert(debugCheckHasCupertinoLocalizations(context));
        final CupertinoLocalizations localizations = CupertinoLocalizations.of(context);
        return builder(
          context,
          buttonDatas.map((ContextMenuButtonData buttonData) {
            return CupertinoTextSelectionToolbarButton.text(
              onPressed: buttonData.onPressed,
              text: CupertinoTextSelectionToolbarButton.getButtonLabel(buttonData, localizations),
            );
          }).toList(),
        );
      case TargetPlatform.android:
        assert(debugCheckHasMaterialLocalizations(context));
        final MaterialLocalizations localizations = MaterialLocalizations.of(context);
        return builder(
          context,
          buttonDatas.map((ContextMenuButtonData buttonData) {
            return TextSelectionToolbarTextButton(
              padding: TextSelectionToolbarTextButton.getPadding(buttonIndex++, buttonDatas.length),
              onPressed: buttonData.onPressed,
              child: Text(_getButtonLabel(buttonData, localizations)),
            );
          }).toList(),
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        assert(debugCheckHasMaterialLocalizations(context));
        final MaterialLocalizations localizations = MaterialLocalizations.of(context);
        return builder(
          context,
          buttonDatas.map((ContextMenuButtonData buttonData) {
            return _DesktopTextSelectionToolbarButton.text(
              context: context,
              onPressed: buttonData.onPressed,
              text: _getButtonLabel(buttonData, localizations),
            );
          }).toList(),
        );
      case TargetPlatform.macOS:
        assert(debugCheckHasCupertinoLocalizations(context));
        final CupertinoLocalizations localizations = CupertinoLocalizations.of(context);
        return builder(
          context,
          buttonDatas.map((ContextMenuButtonData buttonData) {
            return CupertinoDesktopTextSelectionToolbarButton.text(
              context: context,
              onPressed: buttonData.onPressed,
              text: CupertinoTextSelectionToolbarButton.getButtonLabel(buttonData, localizations),
            );
          }).toList(),
        );
    }
  }
}

const TextStyle _kToolbarButtonFontStyle = TextStyle(
  inherit: false,
  fontSize: 14.0,
  letterSpacing: -0.15,
  fontWeight: FontWeight.w400,
);

const EdgeInsets _kToolbarButtonPadding = EdgeInsets.fromLTRB(
  20.0,
  0.0,
  20.0,
  3.0,
);

/// A [TextButton] for the Material desktop text selection toolbar.
class _DesktopTextSelectionToolbarButton extends StatelessWidget {
  /// Creates an instance of _DesktopTextSelectionToolbarButton.
  const _DesktopTextSelectionToolbarButton({
    required this.onPressed,
    required this.child,
  });

  /// Create an instance of [_DesktopTextSelectionToolbarButton] whose child is
  /// a [Text] widget in the style of the Material text selection toolbar.
  _DesktopTextSelectionToolbarButton.text({
    required BuildContext context,
    required this.onPressed,
    required String text,
  }) : child = Text(
         text,
         overflow: TextOverflow.ellipsis,
         style: _kToolbarButtonFontStyle.copyWith(
           color: Theme.of(context).colorScheme.brightness == Brightness.dark
               ? Colors.white
               : Colors.black87,
         ),
       );

  /// {@macro flutter.material.TextSelectionToolbarTextButton.onPressed}
  final VoidCallback onPressed;

  /// {@macro flutter.material.TextSelectionToolbarTextButton.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TODO(hansmuller): Should be colorScheme.onSurface
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.colorScheme.brightness == Brightness.dark;
    final Color primary = isDark ? Colors.white : Colors.black87;

    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          enabledMouseCursor: SystemMouseCursors.basic,
          disabledMouseCursor: SystemMouseCursors.basic,
          primary: primary,
          shape: const RoundedRectangleBorder(),
          minimumSize: const Size(kMinInteractiveDimension, 36.0),
          padding: _kToolbarButtonPadding,
        ),
        onPressed: onPressed,
        child: child,
      ),
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
          anchorBelow: secondaryAnchor == null ? primaryAnchor : secondaryAnchor!,
          children: children,
        );
      case TargetPlatform.android:
        return TextSelectionToolbar(
          anchorAbove: primaryAnchor,
          anchorBelow: secondaryAnchor == null ? primaryAnchor : secondaryAnchor!,
          children: children,
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return _DesktopTextSelectionToolbar(
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
  final List<ContextMenuButtonData> buttonDatas;

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

/// A Material-style desktop text selection toolbar.
///
/// Typically displays buttons for text manipulation, e.g. copying and pasting
/// text.
///
/// Tries to position itself as closely as possible to [anchor] while remaining
/// fully on-screen.
///
/// See also:
///
///  * [_DesktopTextSelectionControls.buildToolbar], where this is used by
///    default to build a Material-style desktop toolbar.
///  * [TextSelectionToolbar], which is similar, but builds an Android-style
///    toolbar.
class _DesktopTextSelectionToolbar extends StatelessWidget {
  /// Creates an instance of _DesktopTextSelectionToolbar.
  const _DesktopTextSelectionToolbar({
    required this.anchor,
    required this.children,
  }) : assert(children.length > 0);

  /// The point at which the toolbar will attempt to position itself as closely
  /// as possible.
  final Offset anchor;

  /// {@macro flutter.material.TextSelectionToolbar.children}
  ///
  /// See also:
  ///   * [_DesktopTextSelectionToolbarButton], which builds a default
  ///     Material-style desktop text selection toolbar text button.
  final List<Widget> children;

  // Builds a desktop toolbar in the Material style.
  static Widget _defaultToolbarBuilder(BuildContext context, Widget child) {
    return SizedBox(
      width: _kToolbarWidth,
      child: Material(
        borderRadius: const BorderRadius.all(Radius.circular(7.0)),
        clipBehavior: Clip.antiAlias,
        elevation: 1.0,
        type: MaterialType.card,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final double paddingAbove = mediaQuery.padding.top + _kToolbarScreenPadding;
    final Offset localAdjustment = Offset(_kToolbarScreenPadding, paddingAbove);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _kToolbarScreenPadding,
        paddingAbove,
        _kToolbarScreenPadding,
        _kToolbarScreenPadding,
      ),
      child: CustomSingleChildLayout(
        delegate: DesktopTextSelectionToolbarLayoutDelegate(
          anchor: anchor - localAdjustment,
        ),
        child: _defaultToolbarBuilder(context, Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        )),
      ),
    );
  }
}

/// Desktop Material styled text selection handle controls.
///
/// Specifically does not manage the toolbar, which is left to
/// [EditableText.buildContextMenu].
class _DesktopTextSelectionHandleControls extends _DesktopTextSelectionControls with TextSelectionHandleControls {
}

class _DesktopTextSelectionControls extends TextSelectionControls {
  /// Desktop has no text selection handles.
  @override
  Size getHandleSize(double textLineHeight) {
    return Size.zero;
  }

  /// Builder for the Material-style desktop copy/paste text selection toolbar.
  @Deprecated(
    'Use `buildContextMenu` instead. '
    'This feature was deprecated after v2.12.0-4.1.pre.',
  )
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ClipboardStatusNotifier? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    return _DesktopTextSelectionControlsToolbar(
      clipboardStatus: clipboardStatus,
      endpoints: endpoints,
      globalEditableRegion: globalEditableRegion,
      handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
      handleCopy: canCopy(delegate) ? () => handleCopy(delegate) : null,
      handlePaste: canPaste(delegate) ? () => handlePaste(delegate) : null,
      handleSelectAll: canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
      selectionMidpoint: selectionMidpoint,
      lastSecondaryTapDownPosition: lastSecondaryTapDownPosition,
      textLineHeight: textLineHeight,
    );
  }

  /// Builds the text selection handles, but desktop has none.
  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textLineHeight, [VoidCallback? onTap]) {
    return const SizedBox.shrink();
  }

  /// Gets the position for the text selection handles, but desktop has none.
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    return Offset.zero;
  }

  @override
  bool canSelectAll(TextSelectionDelegate delegate) {
    // Allow SelectAll when selection is not collapsed, unless everything has
    // already been selected. Same behavior as Android.
    final TextEditingValue value = delegate.textEditingValue;
    return delegate.selectAllEnabled &&
           value.text.isNotEmpty &&
           !(value.selection.start == 0 && value.selection.end == value.text.length);
  }

  @override
  void handleSelectAll(TextSelectionDelegate delegate) {
    super.handleSelectAll(delegate);
    delegate.hideToolbar();
  }
}

/// Desktop text selection handle controls that loosely follow Material design
/// conventions.
@Deprecated(
  'Use `desktopTextSelectionControls` instead. '
  'This feature was deprecated after v2.12.0-4.1.pre.',
)
final TextSelectionControls desktopTextSelectionHandleControls =
    _DesktopTextSelectionHandleControls();

// Generates the child that's passed into DesktopTextSelectionToolbar.
class _DesktopTextSelectionControlsToolbar extends StatefulWidget {
  const _DesktopTextSelectionControlsToolbar({
    required this.clipboardStatus,
    required this.endpoints,
    required this.globalEditableRegion,
    required this.handleCopy,
    required this.handleCut,
    required this.handlePaste,
    required this.handleSelectAll,
    required this.selectionMidpoint,
    required this.textLineHeight,
    required this.lastSecondaryTapDownPosition,
  });

  final ClipboardStatusNotifier? clipboardStatus;
  final List<TextSelectionPoint> endpoints;
  final Rect globalEditableRegion;
  final VoidCallback? handleCopy;
  final VoidCallback? handleCut;
  final VoidCallback? handlePaste;
  final VoidCallback? handleSelectAll;
  final Offset? lastSecondaryTapDownPosition;
  final Offset selectionMidpoint;
  final double textLineHeight;

  @override
  _DesktopTextSelectionControlsToolbarState createState() => _DesktopTextSelectionControlsToolbarState();
}

class _DesktopTextSelectionControlsToolbarState extends State<_DesktopTextSelectionControlsToolbar> {
  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  @override
  void initState() {
    super.initState();
    widget.clipboardStatus?.addListener(_onChangedClipboardStatus);
  }

  @override
  void didUpdateWidget(_DesktopTextSelectionControlsToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clipboardStatus != widget.clipboardStatus) {
      oldWidget.clipboardStatus?.removeListener(_onChangedClipboardStatus);
      widget.clipboardStatus?.addListener(_onChangedClipboardStatus);
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.clipboardStatus?.removeListener(_onChangedClipboardStatus);
  }

  @override
  Widget build(BuildContext context) {
    // Don't render the menu until the state of the clipboard is known.
    if (widget.handlePaste != null && widget.clipboardStatus?.value == ClipboardStatus.unknown) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final Offset midpointAnchor = Offset(
      clampDouble(widget.selectionMidpoint.dx - widget.globalEditableRegion.left,
        mediaQuery.padding.left,
        mediaQuery.size.width - mediaQuery.padding.right,
      ),
      widget.selectionMidpoint.dy - widget.globalEditableRegion.top,
    );

    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final List<Widget> items = <Widget>[];

    void addToolbarButton(
      String text,
      VoidCallback onPressed,
    ) {
      items.add(_DesktopTextSelectionToolbarButton.text(
        context: context,
        onPressed: onPressed,
        text: text,
      ));
    }

    if (widget.handleCut != null) {
      addToolbarButton(localizations.cutButtonLabel, widget.handleCut!);
    }
    if (widget.handleCopy != null) {
      addToolbarButton(localizations.copyButtonLabel, widget.handleCopy!);
    }
    if (widget.handlePaste != null
        && widget.clipboardStatus?.value == ClipboardStatus.pasteable) {
      addToolbarButton(localizations.pasteButtonLabel, widget.handlePaste!);
    }
    if (widget.handleSelectAll != null) {
      addToolbarButton(localizations.selectAllButtonLabel, widget.handleSelectAll!);
    }

    // If there is no option available, build an empty widget.
    if (items.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return _DesktopTextSelectionToolbar(
      anchor: widget.lastSecondaryTapDownPosition ?? midpointAnchor,
      children: items,
    );
  }
}

/// Desktop text selection controls that loosely follow Material design
/// conventions.
final TextSelectionControls desktopTextSelectionControls =
    _DesktopTextSelectionControls();
