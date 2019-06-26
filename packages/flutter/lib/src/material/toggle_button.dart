// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/src/material/debug.dart';
import 'package:flutter/src/material/theme_data.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'theme.dart';

/// An inherited widget that defines color and border parameters for
/// [ToggleButtons] in this widget's subtree.
///
/// Values specified here are used for [ToggleButtons] properties that are not
/// given an explicit non-null value.
class ToggleButtonsTheme extends InheritedWidget {
  /// Creates a toggle buttons theme that controls the color and border
  /// parameters for [ToggleButtons].
  const ToggleButtonsTheme({
    Key key,
    this.color,
    this.activeColor,
    this.disabledColor,
    this.fillColor,
    this.focusColor,
    this.highlightColor,
    this.hoverColor,
    this.splashColor,
    this.borderColor,
    this.activeBorderColor,
    this.disabledBorderColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(0.0)),
    this.borderWidth = 1.0,
    Widget child,
  }) : super(key: key, child: child);

  /// Creates a toggle buttons theme that controls the color and style
  /// parameters for [ToggleButtons], and merges in the current toggle buttons
  /// theme, if any.
  ///
  /// The [child] argument must not be null.
  static Widget merge({
    Key key,
    Color color,
    Color activeColor,
    Color disabledColor,
    Color fillColor,
    Color focusColor,
    Color highlightColor,
    Color hoverColor,
    Color splashColor,
    Color borderColor,
    Color activeBorderColor,
    Color disabledBorderColor,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(0.0)),
    double borderWidth = 1.0,
    @required Widget child,
  }) {
    assert(child != null);
    return Builder(
      builder: (BuildContext context) {
        final ToggleButtonsTheme parent = ToggleButtonsTheme.of(context);
        return ToggleButtonsTheme(
          key: key,
          color: color ?? parent.color,
          activeColor: activeColor ?? parent.activeColor,
          disabledColor: disabledColor ?? parent.disabledColor,
          fillColor: fillColor ?? parent.fillColor,
          focusColor: focusColor ?? parent.focusColor,
          highlightColor: highlightColor ?? parent.highlightColor,
          hoverColor: hoverColor ?? parent.hoverColor,
          splashColor: splashColor ?? parent.splashColor,
          borderColor: borderColor ?? parent.borderColor,
          activeBorderColor: activeBorderColor ?? parent.activeBorderColor,
          disabledBorderColor: disabledBorderColor ?? parent.disabledBorderColor,
          borderRadius: borderRadius ?? parent.borderRadius,
          borderWidth: borderWidth ?? parent.borderWidth,
          child: child,
        );
      },
    );
  }

  /// The color for [Text] and [Icon] widgets.
  ///
  /// If [selected] is set to false and [onPressed] is not null, this color will be used.
  final Color color;

  /// The color for [Text] and [Icon] widgets.
  ///
  /// If [selected] is set to true and [onPressed] is not null, this color will be used.
  final Color activeColor;

  /// The color for [Text] and [Icon] widgets if the button is disabled.
  ///
  /// If [onPressed] is null, this color will be used.
  final Color disabledColor;

  /// The fill color for selected toggle buttons.
  final Color fillColor;

  /// The color to use for filling the button when the button has input focus.
  final Color focusColor;

  /// The highlight color for the button's [InkWell].
  final Color highlightColor;

  /// The splash color for the button's [InkWell].
  final Color splashColor;

  /// The color to use for filling the button when the button has a pointer hovering over it.
  final Color hoverColor;

  /// The border color to display when the toggle button is selected.
  final Color borderColor;

  /// The border color to display when the toggle button is active/selectable.
  final Color activeBorderColor;

  /// The border color to display when the toggle button is disabled.
  final Color disabledBorderColor;

  /// The width of the border surrounding each toggle button.
  ///
  /// This applies to both the greater surrounding border, as well as the
  /// borders dividing each toggle button.
  ///
  /// To omit the border entirely, set [renderBorder] to false.
  ///
  /// To render a hairline border (one physical pixel), set borderWidth to 0.0.
  /// See [BorderSide.width] for more details on hairline borders.
  final double borderWidth;

  /// The radii of the border's corners.
  ///
  /// By default, the border's corners are not rounded.
  final BorderRadius borderRadius;

  /// The closest instance of this class that encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ToggleButtonsTheme theme = ToggleButtonsTheme.of(context);
  /// ```
  static ToggleButtonsTheme of(BuildContext context) {
    final ToggleButtonsTheme result = context.inheritFromWidgetOfExactType(ToggleButtonsTheme);
    return result ?? const ToggleButtonsTheme();
  }

  @override
  bool updateShouldNotify(ToggleButtonsTheme oldWidget) {
    return color != oldWidget.color
        || activeColor != oldWidget.activeColor
        || disabledColor != oldWidget.disabledColor
        || fillColor != oldWidget.fillColor
        || focusColor != oldWidget.focusColor
        || highlightColor != oldWidget.highlightColor
        || hoverColor != oldWidget.hoverColor
        || splashColor != oldWidget.splashColor
        || borderColor != oldWidget.borderColor
        || activeBorderColor != oldWidget.activeBorderColor
        || disabledBorderColor != oldWidget.disabledBorderColor
        || borderRadius != oldWidget.borderRadius
        || borderWidth != oldWidget.borderWidth;
  }
}

/// A horizontal set of toggle buttons.
///
/// It displays its widgets provided in a [List] of [children] horizontally.
/// The state of each button is controlled by [isSelected], which is a list of
/// bools that determine if a button is in an active, disabled, or selected
/// state. They are both correlated by their index in the list.
///
/// ## Customizing toggle buttons
/// The toggle buttons are designed to be configurable, meaning the actions
/// performed by tapping a toggle button and the desired interface can be
/// designed. This can be configured using the [onPressed] callback, which
/// is triggered when a button is pressed.
///
/// Here is an implementation that allows for multiple buttons to be
/// simultaneously selected, while requiring none of the buttons to be
/// selected.
/// ```dart
/// ToggleButtons(
///   children: <Widget>[
///     Icon(Icons.ac_unit),
///     Icon(Icons.call),
///     Icon(Icons.cake),
///   ],
///   onPressed: (int index) {
///     setState(() {
///       isSelected[index] = !isSelected[index];
///     });
///   },
///   isSelected: isSelected,
/// ),
/// ```
///
/// Here is an implementation that requires mutually exclusive selection
/// while requiring at least one selection. Note that this assumes that
/// [isSelected] was properly initialized with one selection.
/// ```dart
/// ToggleButtons(
///   children: <Widget>[
///     Icon(Icons.ac_unit),
///     Icon(Icons.call),
///     Icon(Icons.cake),
///   ],
///   onPressed: (int index) {
///     setState(() {
///       for (int currentIndex = 0; currentIndex < isSelected.length; currentIndex++) {
///         if (currentIndex == index) {
///           isSelected[currentIndex] = true;
///         } else {
///           isSelected[currentIndex] = false;
///         }
///       }
///     });
///   },
///   isSelected: isSelected,
/// ),
/// ```
///
/// Here is an implementation that requires mutually exclusive selection,
/// but allows for none of the buttons to be selected.
/// ```dart
/// ToggleButtons(
///   children: <Widget>[
///     Icon(Icons.ac_unit),
///     Icon(Icons.call),
///     Icon(Icons.cake),
///   ],
///   onPressed: (int index) {
///     setState(() {
///       for (int currentIndex = 0; currentIndex < isSelected.length; currentIndex++) {
///         if (currentIndex == index) {
///           isSelected[currentIndex] = !isSelected[currentIndex];
///         } else {
///           isSelected[currentIndex] = false;
///         }
///       }
///     });
///   },
///   isSelected: isSelected,
/// ),
/// ```
///
/// Here is an implementation that allows for multiple buttons to be
/// simultaneously selected, while requiring at least one selection. Note
/// that this assumes that [isSelected] was properly initialized with one
/// selection.
/// ```dart
/// ToggleButtons(
///   children: <Widget>[
///     Icon(Icons.ac_unit),
///     Icon(Icons.call),
///     Icon(Icons.cake),
///   ],
///   onPressed: (int index) {
///     int count = 0;
///     isSelected.forEach((bool val) {
///       if (val) count++;
///     });
///
///     if (isSelected[index] && count < 2)
///       return;
///
///     setState(() {
///       isSelected[index] = !isSelected[index];
///     });
///   },
///   isSelected: isSelected,
/// ),
/// ```
///
/// ## ToggleButton Borders
/// The toggle buttons, by default, have a solid, 1 dp pixel surrounding itself
/// and separating each button. The toggle button borders' color, width, and
/// corner radii are configurable.
///
/// The [activeBorderColor] determines the border's color when the button is
/// enabled, while [disabledBorderColor] determines the border's color when
/// the button is disabled. [borderColor] is used when the button is selected
/// and enabled.
///
/// To remove the border, set [borderWidth] to null. Setting [borderWidth] to
/// 0.0 results in a hairline border. For more information on hairline borders,
/// see [BorderSide.width].
///
/// See also:
///
///  * <https://material.io/design/components/buttons.html#toggle-button>
class ToggleButtons extends StatelessWidget {
  /// Creates a horizontal set of toggle buttons.
  ///
  /// It displays its widgets provided in a [List] of [children] horizontally.
  /// The state of each button is controlled by [isSelected], which is a list of
  /// bools that determine if a button is in an active, disabled, or selected
  /// state. They are both correlated by their index in the list.
  ///
  /// Both [children] and [isSelected] properties arguments are required.
  const ToggleButtons({
    Key key,
    @required this.children,
    @required this.isSelected,
    this.onPressed,
    this.color,
    this.activeColor,
    this.disabledColor,
    this.fillColor,
    this.focusColor,
    this.highlightColor,
    this.hoverColor,
    this.splashColor,
    this.renderBorder = true,
    this.borderColor,
    this.activeBorderColor,
    this.disabledBorderColor,
    this.borderRadius,
    this.borderWidth,
  }) :
    assert(children != null),
    assert(isSelected != null),
    super(key: key);

  /// The corresponding widget values in the toggle buttons.
  ///
  /// The selection state corresponds to its state in the [isSelected] list.
  final List<Widget> children;

  /// The corresponding selection state of each toggle button.
  ///
  /// The boolean values in the list map directly to [children] by its index.
  /// The values in the list cannot be null.
  final List<bool> isSelected;

  /// The callback that is called when a button is tapped.
  ///
  /// When set to null, all toggle buttons will be disabled.
  final Function onPressed;

  /// The color for [Text] and [Icon] widgets.
  ///
  /// If [selected] is set to false and [onPressed] is not null, this color will be used.
  final Color color;

  /// The color for [Text] and [Icon] widgets.
  ///
  /// If [selected] is set to true and [onPressed] is not null, this color will be used.
  final Color activeColor;

  /// The color for [Text] and [Icon] widgets if the button is disabled.
  ///
  /// If [onPressed] is null, this color will be used.
  final Color disabledColor;

  /// The fill color for selected toggle buttons.
  final Color fillColor;

  /// The color to use for filling the button when the button has input focus.
  ///
  /// Defaults to [ThemeData.focusColor] for the current theme.
  final Color focusColor;

  /// The highlight color for the button's [InkWell].
  final Color highlightColor;

  /// The splash color for the button's [InkWell].
  final Color splashColor;

  /// The color to use for filling the button when the button has a pointer hovering over it.
  ///
  /// Defaults to [ThemeData.hoverColor] for the current theme.
  final Color hoverColor;

  /// Whether or not to render a border around each toggle button.
  ///
  /// When set to true, a border with [borderWidth], [borderRadius] and the
  /// corresponsing border colors will render. Otherwise, no border will be
  /// rendered.
  final bool renderBorder;

  /// The border color to display when the toggle button is selected.
  final Color borderColor;

  /// The border color to display when the toggle button is active/selectable.
  final Color activeBorderColor;

  /// The border color to display when the toggle button is disabled.
  final Color disabledBorderColor;

  /// The width of the border surrounding each toggle button.
  ///
  /// This applies to both the greater surrounding border, as well as the
  /// borders dividing each toggle button.
  ///
  /// To omit the border entirely, set this value to null.
  ///
  /// To render a hairline border (one physical pixel), set borderWidth to 0.0.
  /// See [BorderSide.width] for more details on hairline borders.
  final double borderWidth;

  /// The radii of the border's corners.
  ///
  /// By default, the border's corners are not rounded.
  final BorderRadius borderRadius;

  BorderRadius _getEdgeBorderRadius(int index, int length, TextDirection textDirection, ToggleButtonsTheme toggleButtonsTheme) {
    final BorderRadius resultingBorderRadius = borderRadius ?? toggleButtonsTheme.borderRadius;

    if (
      index == 0 && textDirection == TextDirection.ltr ||
      index == children.length - 1 && textDirection == TextDirection.rtl
    ) {
      return BorderRadius.only(
        topLeft: resultingBorderRadius.topLeft,
        bottomLeft: resultingBorderRadius.bottomLeft,
      );
    } else if (
      index == children.length - 1 && textDirection == TextDirection.ltr ||
      index == 0 && textDirection == TextDirection.rtl
    ) {
      return BorderRadius.only(
        topRight: resultingBorderRadius.topRight,
        bottomRight: resultingBorderRadius.bottomRight,
      );
    }
    return BorderRadius.zero;
  }

  BorderRadius _getClipBorderRadius(int index, int length, TextDirection textDirection, ToggleButtonsTheme toggleButtonsTheme) {
    final BorderRadius resultingBorderRadius = borderRadius ?? toggleButtonsTheme.borderRadius;

    if (
      index == 0 && textDirection == TextDirection.ltr ||
      index == children.length - 1 && textDirection == TextDirection.rtl
    ) {
      return BorderRadius.only(
        topLeft: resultingBorderRadius.topLeft - Radius.circular(borderWidth ?? toggleButtonsTheme.borderWidth / 2.0),
        bottomLeft: resultingBorderRadius.bottomLeft - Radius.circular(borderWidth ?? toggleButtonsTheme.borderWidth / 2.0),
      );
    } else if (
      index == children.length - 1 && textDirection == TextDirection.ltr ||
      index == 0 && textDirection == TextDirection.rtl
    ) {
      return BorderRadius.only(
        topRight: resultingBorderRadius.topRight - Radius.circular(borderWidth ?? toggleButtonsTheme.borderWidth / 2.0),
        bottomRight: resultingBorderRadius.bottomRight - Radius.circular(borderWidth ?? toggleButtonsTheme.borderWidth / 2.0),
      );
    }
    return BorderRadius.zero;
  }

  BorderSide _getLeadingBorderSide(
    int index,
    ThemeData theme,
    ToggleButtonsTheme toggleButtonsTheme,
  ) {
    if (!renderBorder)
      return BorderSide.none;

    if (onPressed != null && (isSelected[index] || (index != 0 && isSelected[index - 1]))) {
      return BorderSide(
        color: borderColor ?? toggleButtonsTheme.borderColor ?? theme.colorScheme.primary,
        width: borderWidth ?? toggleButtonsTheme.borderWidth,
      );
    } else if (onPressed != null && !isSelected[index]) {
      return BorderSide(
        color: activeBorderColor ?? toggleButtonsTheme.activeBorderColor ?? theme.colorScheme.onSurface,
        width: borderWidth ?? toggleButtonsTheme.borderWidth,
      );
    } else {
      return BorderSide(
        color: disabledBorderColor ?? toggleButtonsTheme.disabledBorderColor ?? theme.disabledColor,
        width: borderWidth ?? toggleButtonsTheme.borderWidth,
      );
    }
  }

  BorderSide _getHorizontalBorderSide(
    int index,
    ThemeData theme,
    ToggleButtonsTheme toggleButtonsTheme,
  ) {
    if (!renderBorder)
      return BorderSide.none;

    if (onPressed != null && isSelected[index]) {
      return BorderSide(
        color: borderColor ?? toggleButtonsTheme.borderColor ?? theme.colorScheme.primary,
        width: borderWidth ?? toggleButtonsTheme.borderWidth,
      );
    } else if (onPressed != null && !isSelected[index]) {
      return BorderSide(
        color: activeBorderColor ?? toggleButtonsTheme.activeBorderColor ?? theme.colorScheme.onSurface,
        width: borderWidth ?? toggleButtonsTheme.borderWidth,
      );
    } else {
      return BorderSide(
        color: disabledBorderColor ?? toggleButtonsTheme.disabledBorderColor ?? theme.disabledColor,
        width: borderWidth ?? toggleButtonsTheme.borderWidth,
      );
    }
  }

  BorderSide _getTrailingBorderSide(
    int index,
    ThemeData theme,
    ToggleButtonsTheme toggleButtonsTheme,
  ) {
    if (!renderBorder)
      return BorderSide.none;

    if (index != children.length - 1)
      return null;

    if (onPressed != null && (isSelected[index])) {
      return BorderSide(
        color: borderColor ?? toggleButtonsTheme.borderColor ?? theme.colorScheme.primary,
        width: borderWidth ?? toggleButtonsTheme.borderWidth,
      );
    } else if (onPressed != null && !isSelected[index]) {
      return BorderSide(
        color: activeBorderColor ?? toggleButtonsTheme.activeBorderColor ?? theme.colorScheme.onSurface,
        width: borderWidth ?? toggleButtonsTheme.borderWidth,
      );
    } else {
      return BorderSide(
        color: disabledBorderColor ?? toggleButtonsTheme.disabledBorderColor ?? theme.disabledColor,
        width: borderWidth ?? toggleButtonsTheme.borderWidth,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(
      !isSelected.any((bool val) => val == null),
      'There is a null value in isSelected: $isSelected'
    );
    final ThemeData theme = Theme.of(context);
    final ToggleButtonsTheme toggleButtonsTheme = ToggleButtonsTheme.of(context);
    final TextDirection textDirection = Directionality.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(children.length, (int index) {
          final BorderRadius edgeBorderRadius = _getEdgeBorderRadius(index, children.length, textDirection, toggleButtonsTheme);
          final BorderRadius clipBorderRadius = _getClipBorderRadius(index, children.length, textDirection, toggleButtonsTheme);

          final BorderSide leadingBorderSide = _getLeadingBorderSide(index, theme, toggleButtonsTheme);
          final BorderSide horizontalBorderSide = _getHorizontalBorderSide(index, theme, toggleButtonsTheme);
          final BorderSide trailingBorderSide = _getTrailingBorderSide(index, theme, toggleButtonsTheme);

          return _ToggleButton(
            selected: isSelected[index],
            color: color,
            activeColor: activeColor,
            disabledColor: disabledColor,
            fillColor: fillColor,
            focusColor: focusColor,
            highlightColor: highlightColor,
            hoverColor: hoverColor,
            splashColor: splashColor,
            onPressed: onPressed != null
              ? () { onPressed(index); }
              : null,
            leadingBorderSide: leadingBorderSide,
            horizontalBorderSide: horizontalBorderSide,
            trailingBorderSide: trailingBorderSide,
            borderRadius: edgeBorderRadius,
            clipRadius: clipBorderRadius,
            isFirstButton: index == 0,
            isLastButton: index == children.length - 1,
            child: children[index],
          );
        }),
      ),
    );
  }

  // TODO(WIP): include debugFillProperties method
}

/// An individual toggle button, otherwise known as a segmented button.
///
/// This button is used by [ToggleButtons] to implement a set of segmented controls.
class _ToggleButton extends StatelessWidget {
  /// Creates a toggle button based on [RawMaterialButton].
  ///
  /// This class adds some logic to determine between enabled, active, and
  /// disabled states to determine the appropriate colors to use.
  ///
  /// It takes in a [shape] property to modify the borders of the button,
  /// which is used by [ToggleButtons] to customize borders based on the
  /// order in which this button appears in the list.
  const _ToggleButton({
    Key key,
    this.selected = false,
    this.color,
    this.activeColor,
    this.disabledColor,
    this.fillColor,
    this.focusColor,
    this.highlightColor,
    this.hoverColor,
    this.splashColor,
    this.onPressed,
    this.leadingBorderSide,
    this.horizontalBorderSide,
    this.trailingBorderSide,
    this.borderRadius,
    this.clipRadius,
    this.isFirstButton,
    this.isLastButton,
    this.child,
  }) : super(key: key);

  /// Determines if the button is displayed as active/selected or enabled.
  final bool selected;

  /// The color for [Text] and [Icon] widgets.
  ///
  /// If [selected] is set to false and [onPressed] is not null, this color will be used.
  final Color color;

  /// The color for [Text] and [Icon] widgets.
  ///
  /// If [selected] is set to true and [onPressed] is not null, this color will be used.
  final Color activeColor;

  /// The color for [Text] and [Icon] widgets if the button is disabled.
  ///
  /// If [onPressed] is null, this color will be used.
  final Color disabledColor;

  /// The color of the button's [Material].
  final Color fillColor;

  /// The color for the button's [Material] when it has the input focus.
  final Color focusColor;

  /// The color for the button's [Material] when a pointer is hovering over it.
  final Color hoverColor;

  /// The highlight color for the button's [InkWell].
  final Color highlightColor;

  /// The splash color for the button's [InkWell].
  final Color splashColor;

  /// Called when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled, see [enabled].
  final VoidCallback onPressed;

  /// The width and color of the button's leading side border.
  final BorderSide leadingBorderSide;

  /// The width and color of the button's top and bottom side borders.
  final BorderSide horizontalBorderSide;

  /// The width and color of the button's trailing side border.
  final BorderSide trailingBorderSide;

  /// The border radii of each corner of the button.
  final BorderRadius borderRadius;

  /// The corner radii used to clip the button's contents.
  ///
  /// This is used to have the button's contents be properly clipped taking
  /// the [borderRadius] and the border's width into account.
  final BorderRadius clipRadius;

  /// Whether or not this toggle button is the first button in the list.
  final bool isFirstButton;

  /// Whether or not this toggle button is the last button in the list.
  final bool isLastButton;

  /// The button's label, which is usually an [Icon] or a [Text] widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    Color currentColor;
    final ThemeData theme = Theme.of(context);
    final ToggleButtonsTheme toggleButtonsTheme = ToggleButtonsTheme.of(context);

    if (onPressed != null && selected) {
      currentColor = activeColor
        ?? toggleButtonsTheme.color
        ?? theme.colorScheme.primary;
    } else if (onPressed != null && !selected) {
      currentColor = color
        ?? toggleButtonsTheme.activeColor
        ?? theme.colorScheme.onSurface;
    } else {
      currentColor =
      disabledColor
        ?? toggleButtonsTheme.disabledColor
        ?? theme.disabledColor;
    }

    final Widget result = IconTheme.merge(
      data: IconThemeData(
        color: currentColor,
      ),
      child: ClipRRect(
        borderRadius: clipRadius,
        child: RawMaterialButton(
          textStyle: TextStyle(
            color: currentColor,
          ),
          elevation: 0.0,
          highlightElevation: 0.0,
          fillColor: selected ? fillColor : null,
          focusColor: selected ? focusColor : null,
          highlightColor: highlightColor,
          hoverColor: hoverColor,
          splashColor: splashColor,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onPressed: onPressed,
          child: child,
        ),
      ),
    );

    return _SelectToggleButton(
      key: key,
      leadingBorderSide: leadingBorderSide,
      horizontalBorderSide: horizontalBorderSide,
      trailingBorderSide: trailingBorderSide,
      borderRadius: borderRadius,
      isFirstButton: isFirstButton,
      isLastButton: isLastButton,
      child: result,
    );
  }

  // TODO(WIP): include debugFillProperties method
}

class _SelectToggleButton extends SingleChildRenderObjectWidget {
  const _SelectToggleButton({
    Key key,
    Widget child,
    this.leadingBorderSide,
    this.horizontalBorderSide,
    this.trailingBorderSide,
    this.borderRadius,
    this.isFirstButton,
    this.isLastButton,
  }) : super(
    key: key,
    child: child,
  );

  // The width and color of the button's leading side border.
  final BorderSide leadingBorderSide;

  // The width and color of the button's top and bottom side borders.
  final BorderSide horizontalBorderSide;

  // The width and color of the button's trailing side border.
  final BorderSide trailingBorderSide;

  // The border radii of each corner of the button.
  final BorderRadius borderRadius;

  // Whether or not this toggle button is the first button in the list.
  final bool isFirstButton;

  // Whether or not this toggle button is the last button in the list.
  final bool isLastButton;

  @override
  _SelectToggleButtonRenderObject createRenderObject(BuildContext context) => _SelectToggleButtonRenderObject(
    leadingBorderSide: leadingBorderSide,
    horizontalBorderSide: horizontalBorderSide,
    trailingBorderSide: trailingBorderSide,
    borderRadius: borderRadius,
    isFirstButton: isFirstButton,
    isLastButton: isLastButton,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, _SelectToggleButtonRenderObject renderObject) {
    renderObject
      ..leadingBorderSide = leadingBorderSide
      ..horizontalBorderSide = horizontalBorderSide
      ..trailingBorderSide = trailingBorderSide
      ..borderRadius = borderRadius
      ..isFirstButton = isFirstButton
      ..isLastButton = isLastButton
      ..textDirection = Directionality.of(context);
  }
}

class _SelectToggleButtonRenderObject extends RenderShiftedBox {
  _SelectToggleButtonRenderObject({
    this.leadingBorderSide,
    this.horizontalBorderSide,
    this.trailingBorderSide,
    this.borderRadius,
    this.isFirstButton,
    this.isLastButton,
    this.textDirection,
    RenderBox child,
  }) : super(child);

  // The width and color of the button's leading side border.
  BorderSide leadingBorderSide;

  // The width and color of the button's top and bottom side borders.
  BorderSide horizontalBorderSide;

  // The width and color of the button's trailing side border.
  BorderSide trailingBorderSide;

  // The border radii of each corner of the button.
  BorderRadius borderRadius;

  // Whether or not this toggle button is the first button in the list.
  bool isFirstButton;

  // Whether or not this toggle button is the last button in the list.
  bool isLastButton;

  // The direction in which text flows for this application.
  TextDirection textDirection;

  @override
  void performLayout() {
    if (child == null) {
      size = constraints.constrain(Size(
        leadingBorderSide.width + trailingBorderSide.width,
        horizontalBorderSide.width * 2.0,
      ));
      return;
    }

    final double trailingBorderOffset = isLastButton ? trailingBorderSide.width : 0.0;
    double leftConstraint;
    double rightConstraint;

    switch (textDirection) {
      case TextDirection.ltr:
        rightConstraint = trailingBorderOffset;
        leftConstraint = leadingBorderSide.width;

        final BoxConstraints innerConstraints = constraints.deflate(
          EdgeInsets.only(
            left: leftConstraint,
            top: horizontalBorderSide.width,
            right: rightConstraint,
            bottom: horizontalBorderSide.width,
          ),
        );

        child.layout(innerConstraints, parentUsesSize: true);
        final BoxParentData childParentData = child.parentData;
        childParentData.offset = Offset(leadingBorderSide.width, leadingBorderSide.width);

        size = constraints.constrain(Size(
          leftConstraint + child.size.width + rightConstraint,
          horizontalBorderSide.width * 2.0 + child.size.height,
        ));
        break;
      case TextDirection.rtl:
        rightConstraint = leadingBorderSide.width;
        leftConstraint = trailingBorderOffset;

        final BoxConstraints innerConstraints = constraints.deflate(
          EdgeInsets.only(
            left: leftConstraint,
            top: horizontalBorderSide.width,
            right: rightConstraint,
            bottom: horizontalBorderSide.width,
          ),
        );

        child.layout(innerConstraints, parentUsesSize: true);
        final BoxParentData childParentData = child.parentData;

        if (isLastButton) {
          childParentData.offset = Offset(trailingBorderOffset, trailingBorderOffset);
        } else {
          childParentData.offset = Offset(0, horizontalBorderSide.width);
        }

        size = constraints.constrain(Size(
          leftConstraint + child.size.width + rightConstraint,
          horizontalBorderSide.width * 2.0 + child.size.height,
        ));
        break;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    final Offset bottomRight = size.bottomRight(offset);
    final Rect outer = Rect.fromLTRB(offset.dx, offset.dy, bottomRight.dx, bottomRight.dy);
    final Rect center = outer.deflate(horizontalBorderSide.width / 2.0);
    const double sweepAngle = math.pi / 2.0;

    final RRect rrect = RRect.fromRectAndCorners(
      center,
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    ).scaleRadii();

    final Rect tlCorner = Rect.fromLTWH(
      rrect.left,
      rrect.top,
      rrect.tlRadiusX * 2.0,
      rrect.tlRadiusY * 2.0,
    );
    final Rect blCorner = Rect.fromLTWH(
      rrect.left,
      rrect.bottom - (rrect.blRadiusY * 2.0),
      rrect.blRadiusX * 2.0,
      rrect.blRadiusY * 2.0,
    );
    final Rect trCorner = Rect.fromLTWH(
      rrect.right - (rrect.trRadiusX * 2),
      rrect.top,
      rrect.trRadiusX * 2,
      rrect.trRadiusY * 2,
    );
    final Rect brCorner = Rect.fromLTWH(
      rrect.right - (rrect.brRadiusX * 2),
      rrect.bottom - (rrect.brRadiusY * 2),
      rrect.brRadiusX * 2,
      rrect.brRadiusY * 2,
    );

    final Paint leadingPaint = leadingBorderSide.toPaint();
    switch (textDirection) {
      case TextDirection.ltr:
        if (isFirstButton) {
          final Path leadingPath = Path()
            ..moveTo(outer.right, rrect.bottom)
            ..lineTo(rrect.left + rrect.blRadiusX, rrect.bottom)
            ..addArc(blCorner, math.pi / 2.0, sweepAngle)
            ..lineTo(rrect.left, rrect.top + rrect.tlRadiusY)
            ..addArc(tlCorner, math.pi, sweepAngle)
            ..lineTo(outer.right, rrect.top);
          context.canvas.drawPath(leadingPath, leadingPaint);
        } else if (isLastButton) {
          final Path leftPath = Path()
            ..moveTo(rrect.left, rrect.bottom + leadingBorderSide.width / 2)
            ..lineTo(rrect.left, rrect.top - leadingBorderSide.width / 2);
          context.canvas.drawPath(leftPath, leadingPaint);

          final Paint endingPaint = trailingBorderSide.toPaint();
          final Path endingPath = Path()
            ..moveTo(rrect.left + horizontalBorderSide.width / 2.0, rrect.top)
            ..lineTo(rrect.right - rrect.trRadiusX, rrect.top)
            ..addArc(trCorner, math.pi * 3.0 / 2.0, sweepAngle)
            ..lineTo(rrect.right, rrect.bottom - rrect.brRadiusY)
            ..addArc(brCorner, 0, sweepAngle)
            ..lineTo(rrect.left + horizontalBorderSide.width / 2.0, rrect.bottom);
          context.canvas.drawPath(endingPath, endingPaint);
        } else {
          final Path leadingPath = Path()
            ..moveTo(rrect.left, rrect.bottom + leadingBorderSide.width / 2)
            ..lineTo(rrect.left, rrect.top - leadingBorderSide.width / 2);
          context.canvas.drawPath(leadingPath, leadingPaint);

          final Paint horizontalPaint = horizontalBorderSide.toPaint();
          final Path horizontalPaths = Path()
            ..moveTo(rrect.left + horizontalBorderSide.width / 2.0, rrect.top)
            ..lineTo(outer.right - rrect.trRadiusX, rrect.top)
            ..moveTo(rrect.left + horizontalBorderSide.width / 2.0 + rrect.tlRadiusX, rrect.bottom)
            ..lineTo(outer.right - rrect.trRadiusX, rrect.bottom);
          context.canvas.drawPath(horizontalPaths, horizontalPaint);
        }
        break;
      case TextDirection.rtl:
        if (isFirstButton) {
          final Path leadingPath = Path()
            ..moveTo(outer.left, rrect.bottom)
            ..lineTo(rrect.right - rrect.brRadiusX, rrect.bottom)
            ..addArc(brCorner, math.pi / 2.0, -sweepAngle)
            ..lineTo(rrect.right, rrect.top + rrect.trRadiusY)
            ..addArc(trCorner, 0, -sweepAngle)
            ..lineTo(outer.left, rrect.top);
          context.canvas.drawPath(leadingPath, leadingPaint);
        } else if (isLastButton) {
          final Path leadingPath = Path()
            ..moveTo(rrect.right, rrect.bottom + leadingBorderSide.width / 2)
            ..lineTo(rrect.right, rrect.top - leadingBorderSide.width / 2);
          context.canvas.drawPath(leadingPath, leadingPaint);

          final Paint endingPaint = trailingBorderSide.toPaint();
          final Path endingPath = Path()
            ..moveTo(rrect.right - horizontalBorderSide.width / 2.0, rrect.top)
            ..lineTo(rrect.left + rrect.tlRadiusX, rrect.top)
            ..addArc(tlCorner, math.pi * 3.0 / 2.0, -sweepAngle)
            ..lineTo(rrect.left, rrect.bottom - rrect.blRadiusY)
            ..addArc(blCorner, math.pi, -sweepAngle)
            ..lineTo(rrect.right - horizontalBorderSide.width / 2.0, rrect.bottom);
          context.canvas.drawPath(endingPath, endingPaint);
        } else {
          final Path leadingPath = Path()
            ..moveTo(rrect.right, rrect.bottom + leadingBorderSide.width / 2)
            ..lineTo(rrect.right, rrect.top - leadingBorderSide.width / 2);
          context.canvas.drawPath(leadingPath, leadingPaint);

          final Paint horizontalPaint = horizontalBorderSide.toPaint();
          final Path horizontalPaths = Path()
            ..moveTo(rrect.right - horizontalBorderSide.width / 2.0, rrect.top)
            ..lineTo(outer.left - rrect.tlRadiusX, rrect.top)
            ..moveTo(rrect.right - horizontalBorderSide.width / 2.0 + rrect.trRadiusX, rrect.bottom)
            ..lineTo(outer.left - rrect.tlRadiusX, rrect.bottom);
          context.canvas.drawPath(horizontalPaths, horizontalPaint);
        }
        break;
    }
  }
}
