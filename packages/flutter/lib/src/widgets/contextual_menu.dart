import 'dart:collection' show LinkedHashMap;
import 'dart:ui' show Offset;

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'inherited_theme.dart';
import 'navigator.dart';
import 'overlay.dart';
import 'text_selection.dart';
import 'ticker_provider.dart';

/// A function that builds a widget to use as a contextual menu.
typedef ContextualMenuBuilder = Widget Function(BuildContext, Offset, Offset?);

// TODO(justinmc): Figure out all the platforms and nested packages.
// Should a CupertinoTextField on Android show the iOS toolbar?? It seems to now
// before this PR.
/*
class ContextualMenuConfiguration extends InheritedWidget {
  const ContextualMenuConfiguration({
    Key? key,
    required this.buildMenu,
    required Widget child,
  }) : super(key: key, child: child);

  final ContextualMenuBuilder buildMenu;

  /// Get the [ContextualMenuConfiguration] that applies to the given
  /// [BuildContext].
  static ContextualMenuConfiguration of(BuildContext context) {
    final ContextualMenuConfiguration? result = context.dependOnInheritedWidgetOfExactType<ContextualMenuConfiguration>();
    assert(result != null, 'No ContextualMenuConfiguration found in context.');
    return result!;
  }

  @override
  bool updateShouldNotify(ContextualMenuConfiguration old) => buildMenu != old.buildMenu;
}
*/

/// Designates a part of the Widget tree to have the contextual menu given by
/// [buildMenu].
class ContextualMenuArea extends StatefulWidget {
  const ContextualMenuArea({
    Key? key,
    required this.buildMenu,
    required this.child,
  }) : super(key: key);

  final ContextualMenuBuilder buildMenu;
  final Widget child;

  // TODO(justinmc): Another option would be to return ContextualMenuController
  // but make it so that it exists even when the overlay isn't shown.
  /// Returns the nearest [ContextualMenuController] for the given
  /// [BuildContext], if any.
  static ContextualMenuAreaState? of(BuildContext context) {
    return context.findAncestorStateOfType<ContextualMenuAreaState>();
  }

  @override
  State<ContextualMenuArea> createState() => ContextualMenuAreaState();
}

class ContextualMenuAreaState extends State<ContextualMenuArea> {
  ContextualMenuController? _contextualMenuController;

  bool get contextualMenuIsVisible => _contextualMenuController != null;

  // TODO(justinmc): This kills any existing menu then creates a new one. Is
  // that ok? Do I ever need to move an existing menu?
  void showContextualMenu(Offset primaryAnchor, [Offset? secondaryAnchor]) {
    _contextualMenuController?.dispose();
    _contextualMenuController = ContextualMenuController(
      primaryAnchor: primaryAnchor,
      secondaryAnchor: secondaryAnchor,
      context: context,
      buildMenu: widget.buildMenu,
    );
  }

  void disposeContextualMenu() {
    _contextualMenuController?.dispose();
    _contextualMenuController = null;
  }

  @override
  void dispose() {
    disposeContextualMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// TODO(justinmc): Ok public? Put in own file?
class ContextualMenuController {
  // TODO(justinmc): Pass in the anchor, and pass it through to buildMenu.
  // What other fields would I need to pass in to buildMenu? There are a ton on
  // buildToolbar...
  // Also, create an update method.
  ContextualMenuController({
    // TODO(justinmc): Accept these or just BuildContext?
    required ContextualMenuBuilder buildMenu,
    required Offset primaryAnchor,
    required BuildContext context,
    Offset? secondaryAnchor,
    Widget? debugRequiredFor
  }) {
    _insert(
      context: context,
      buildMenu: buildMenu,
      primaryAnchor: primaryAnchor,
      secondaryAnchor: secondaryAnchor,
      debugRequiredFor: debugRequiredFor,
    );
  }

  OverlayEntry? _menuOverlayEntry;

  // Insert the ContextualMenu into the given OverlayState.
  void _insert({
    required ContextualMenuBuilder buildMenu,
    required BuildContext context,
    required Offset primaryAnchor,
    Offset? secondaryAnchor,
    Widget? debugRequiredFor,
  }) {
    final OverlayState? overlayState = Overlay.of(
      context,
      rootOverlay: true,
      debugRequiredFor: debugRequiredFor,
    );
    // TODO(justinmc): Should I create a default menu here if no ContextualMenuConfiguration?
    /*
    final ContextualMenuConfiguration contextualMenuConfiguration =
      ContextualMenuConfiguration.of(context);
      */
    final CapturedThemes capturedThemes = InheritedTheme.capture(
      from: context,
      to: Navigator.of(context).context,
    );

    _menuOverlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: dispose,
          onSecondaryTap: dispose,
          // TODO(justinmc): I'm using this to block taps on the menu from being
          // received by the above barrier. Is there a less weird way?
          child: GestureDetector(
            onTap: () {},
            onSecondaryTap: () {},
            child: capturedThemes.wrap(buildMenu(context, primaryAnchor, secondaryAnchor)),
          ),
        );
      },
    );
    overlayState!.insert(_menuOverlayEntry!);
  }

  /// True iff the menu is currently being displayed.
  bool get isVisible => _menuOverlayEntry != null;

  /// Remove the menu.
  void dispose() {
    _menuOverlayEntry?.remove();
    _menuOverlayEntry = null;
  }
}

// TODO(justinmc): Move to contextual_menu.dart?
/// The buttons that can appear in a contextual menu by default.
enum DefaultContextualMenuButtonType {
  /// A button that cuts the current text selection.
  cut,

  /// A button that copies the current text selection.
  copy,

  /// A button that pastes the clipboard contents into the focused text field.
  paste,

  /// A button that selects all the contents of the focused text field.
  selectAll,
}

/// The label and callback for the available default contextual menu buttons.
@immutable
class ContextualMenuButtonData {
  /// Creates an instance of [ContextualMenuButtonData].
  const ContextualMenuButtonData({
    required this.onPressed,
    required this.type,
  });

  /// The callback to be called when the button is pressed.
  final VoidCallback onPressed;

  /// The type of button this represents.
  final DefaultContextualMenuButtonType type;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ContextualMenuButtonData
        && other.onPressed == onPressed
        && other.type == type;
  }

  @override
  int get hashCode => Object.hash(onPressed, type);
}

/// A builder function that builds a toolbar given the default [buttonDatas].
///
/// See also:
///
///   * [TextSelectionToolbarButtons], which receives this as a parameter.
typedef ToolbarButtonWidgetBuilder = Widget Function(
  BuildContext context,
  LinkedHashMap<DefaultContextualMenuButtonType, ContextualMenuButtonData> buttonDatas,
);

// TODO(justinmc): Move this to its own file once the name is finalized.
// TODO(justinmc): What about the general contextualmenu case?
/// The default buttons for [TextSelectionToolbar].
class TextSelectionToolbarButtons extends StatefulWidget {
  /// Creates an instance of [TextSelectionToolbarButtons].
  const TextSelectionToolbarButtons({
    Key? key,
    required this.builder,
    required this.clipboardStatus,
    required this.handleCut,
    required this.handleCopy,
    required this.handlePaste,
    required this.handleSelectAll,
  }) : super(key: key);

  /// Called with a list of [ContextualMenuButtonData]s so the contextual menu
  /// can be built.
  final ToolbarButtonWidgetBuilder builder;
  final ClipboardStatusNotifier? clipboardStatus;
  final VoidCallback? handleCut;
  final VoidCallback? handleCopy;
  final VoidCallback? handlePaste;
  final VoidCallback? handleSelectAll;

  @override
  _TextSelectionToolbarButtonsState createState() => _TextSelectionToolbarButtonsState();
}

class _TextSelectionToolbarButtonsState extends State<TextSelectionToolbarButtons> with TickerProviderStateMixin {
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
  void didUpdateWidget(TextSelectionToolbarButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clipboardStatus != oldWidget.clipboardStatus) {
      widget.clipboardStatus?.addListener(_onChangedClipboardStatus);
      oldWidget.clipboardStatus?.removeListener(_onChangedClipboardStatus);
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.clipboardStatus?.removeListener(_onChangedClipboardStatus);
  }

  @override
  Widget build(BuildContext context) {
    // If there are no buttons to be shown, don't render anything.
    if (widget.handleCut == null && widget.handleCopy == null
        && widget.handlePaste == null && widget.handleSelectAll == null) {
      return const SizedBox.shrink();
    }
    // If the paste button is desired, don't render anything until the state of
    // the clipboard is known, since it's used to determine if paste is shown.
    if (widget.handlePaste != null
        && widget.clipboardStatus?.value == ClipboardStatus.unknown) {
      return const SizedBox.shrink();
    }

    // Determine which buttons will appear so that the order and total number is
    // known. A button's position in the menu can slightly affect its
    // appearance.
    final LinkedHashMap<DefaultContextualMenuButtonType, ContextualMenuButtonData> buttonDatas =
        LinkedHashMap<DefaultContextualMenuButtonType, ContextualMenuButtonData>.of(
            <DefaultContextualMenuButtonType, ContextualMenuButtonData>{
              if (widget.handleCut != null)
                DefaultContextualMenuButtonType.cut: ContextualMenuButtonData(
                  onPressed: widget.handleCut!,
                  type: DefaultContextualMenuButtonType.cut,
                ),
              if (widget.handleCopy != null)
                DefaultContextualMenuButtonType.copy: ContextualMenuButtonData(
                  onPressed: widget.handleCopy!,
                  type: DefaultContextualMenuButtonType.copy,
                ),
              if (widget.handlePaste != null
                  && widget.clipboardStatus?.value == ClipboardStatus.pasteable)
                DefaultContextualMenuButtonType.paste: ContextualMenuButtonData(
                  onPressed: widget.handlePaste!,
                  type: DefaultContextualMenuButtonType.paste,
                ),
              if (widget.handleSelectAll != null)
                DefaultContextualMenuButtonType.selectAll: ContextualMenuButtonData(
                  onPressed: widget.handleSelectAll!,
                  type: DefaultContextualMenuButtonType.selectAll,
                ),
            });

    // If there is no option available, build an empty widget.
    if (buttonDatas.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return widget.builder(context, buttonDatas);
  }
}
