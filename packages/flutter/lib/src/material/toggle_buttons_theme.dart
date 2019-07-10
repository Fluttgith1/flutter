// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Defines the color and border properties of [ToggleButtons] widgets.
///
/// Used by [ToggleButtonsTheme] to control the color and border properties
/// of toggle buttons in a widget subtree.
///
/// To obtain the current [ToggleButtonsTheme], use [ToggleButtonsTheme.of].
///
/// See also:
///
///  * [ToggleButtonsTheme], which describes the actual configuration of a
///    toggle buttons theme.
class ToggleButtonsThemeData extends Diagnosticable {
  /// Creates the set of color and border properties used to configure
  /// [ToggleButtons].
  const ToggleButtonsThemeData({
    this.color,
    this.selectedColor,
    this.disabledColor,
    this.fillColor,
    this.focusColor,
    this.highlightColor,
    this.hoverColor,
    this.splashColor,
    this.borderColor,
    this.selectedBorderColor,
    this.disabledBorderColor,
    this.borderRadius = BorderRadius.zero,
    this.borderWidth = 1.0,
  });

  /// The color for [Text] and [Icon] widgets if the button is enabled.
  ///
  /// If [selected] is set to false and [onPressed] is not null, this color will be used.
  final Color color;

  /// The color for [Text] and [Icon] widgets if the button is selected.
  ///
  /// If [selected] is set to true and [onPressed] is not null, this color will be used.
  final Color selectedColor;

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

  /// The border color to display when the toggle button is enabled.
  final Color borderColor;

  /// The border color to display when the toggle button is selected.
  final Color selectedBorderColor;

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

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  ToggleButtonsThemeData copyWith({
    Color color,
    Color selectedColor,
    Color disabledColor,
    Color fillColor,
    Color focusColor,
    Color highlightColor,
    Color hoverColor,
    Color splashColor,
    Color borderColor,
    Color selectedBorderColor,
    Color disabledBorderColor,
    BorderRadius borderRadius = BorderRadius.zero,
    double borderWidth = 1.0,
  }) {
    return ToggleButtonsThemeData(
      color: color ?? this.color,
      selectedColor: selectedColor ?? this.selectedColor,
      disabledColor: disabledColor ?? this.disabledColor,
      fillColor: fillColor ?? this.fillColor,
      focusColor: focusColor ?? this.focusColor,
      highlightColor: highlightColor ?? this.highlightColor,
      hoverColor: hoverColor ?? this.hoverColor,
      splashColor: splashColor ?? this.splashColor,
      borderColor: borderColor ?? this.borderColor,
      selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
      disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }

  /// Linearly interpolate between two toggle buttons themes.
  static ToggleButtonsThemeData lerp(ToggleButtonsThemeData a, ToggleButtonsThemeData b, double t) {
    assert (t != null);
    if (a == null && b == null)
      return null;
    return ToggleButtonsThemeData(
      color: Color.lerp(a?.color, b?.color, t),
      selectedColor: Color.lerp(a?.selectedColor, b?.selectedColor, t),
      disabledColor: Color.lerp(a?.disabledColor, b?.disabledColor, t),
      fillColor: Color.lerp(a?.fillColor, b?.fillColor, t),
      focusColor: Color.lerp(a?.focusColor, b?.focusColor, t),
      highlightColor: Color.lerp(a?.highlightColor, b?.highlightColor, t),
      hoverColor: Color.lerp(a?.hoverColor, b?.hoverColor, t),
      splashColor: Color.lerp(a?.splashColor, b?.splashColor, t),
      borderColor: Color.lerp(a?.borderColor, b?.borderColor, t),
      selectedBorderColor: Color.lerp(a?.selectedBorderColor, b?.selectedBorderColor, t),
      disabledBorderColor: Color.lerp(a?.disabledBorderColor, b?.disabledBorderColor, t),
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      borderWidth: lerpDouble(a?.borderWidth, b?.borderWidth, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      color,
      selectedColor,
      disabledColor,
      fillColor,
      focusColor,
      highlightColor,
      hoverColor,
      splashColor,
      borderColor,
      selectedBorderColor,
      disabledBorderColor,
      borderRadius,
      borderWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final ToggleButtonsThemeData typedOther = other;
    return typedOther.color == color
        && typedOther.selectedColor == selectedColor
        && typedOther.disabledColor == disabledColor
        && typedOther.fillColor == fillColor
        && typedOther.focusColor == focusColor
        && typedOther.highlightColor == highlightColor
        && typedOther.hoverColor == hoverColor
        && typedOther.splashColor == splashColor
        && typedOther.borderColor == borderColor
        && typedOther.selectedBorderColor == selectedBorderColor
        && typedOther.disabledBorderColor == disabledBorderColor
        && typedOther.borderRadius == borderRadius
        && typedOther.borderWidth == borderWidth;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(ColorProperty('selectedColor', selectedColor, defaultValue: null));
    properties.add(ColorProperty('disabledColor', disabledColor, defaultValue: null));
    properties.add(ColorProperty('fillColor', fillColor, defaultValue: null));
    properties.add(ColorProperty('focusColor', focusColor, defaultValue: null));
    properties.add(ColorProperty('highlightColor', highlightColor, defaultValue: null));
    properties.add(ColorProperty('hoverColor', hoverColor, defaultValue: null));
    properties.add(ColorProperty('splashColor', splashColor, defaultValue: null));
    properties.add(ColorProperty('borderColor', borderColor, defaultValue: null));
    properties.add(ColorProperty('selectedBorderColor', selectedBorderColor, defaultValue: null));
    properties.add(ColorProperty('disabledBorderColor', disabledBorderColor, defaultValue: null));
    properties.add(DiagnosticsProperty<BorderRadius>('borderRadius', borderRadius, defaultValue: null));
    properties.add(DoubleProperty('borderWidth', borderWidth, defaultValue: null));
  }
}

/// An inherited widget that defines color and border parameters for
/// [ToggleButtons] in this widget's subtree.
///
/// Values specified here are used for [ToggleButtons] properties that are not
/// given an explicit non-null value.
class ToggleButtonsTheme extends InheritedWidget {
  /// Creates a toggle buttons theme that controls the color and border
  /// parameters for [ToggleButtons].
  ToggleButtonsTheme({
    Key key,
    Color color,
    Color selectedColor,
    Color disabledColor,
    Color fillColor,
    Color focusColor,
    Color highlightColor,
    Color hoverColor,
    Color splashColor,
    Color borderColor,
    Color selectedBorderColor,
    Color disabledBorderColor,
    BorderRadius borderRadius = BorderRadius.zero,
    double borderWidth = 1.0,
    Widget child,
  }) :  data = ToggleButtonsThemeData(
          color: color,
          selectedColor: selectedColor,
          disabledColor: disabledColor,
          fillColor: fillColor,
          focusColor: focusColor,
          highlightColor: highlightColor,
          hoverColor: hoverColor,
          splashColor: splashColor,
          borderColor: borderColor,
          selectedBorderColor: selectedBorderColor,
          disabledBorderColor: disabledBorderColor,
          borderRadius: borderRadius,
          borderWidth: borderWidth,
        ),
        super(key: key, child: child);

  /// Specifies the color and border values for descendant [ToggleButtons] widgets.
  final ToggleButtonsThemeData data;

  /// The closest instance of this class that encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ToggleButtonsTheme theme = ToggleButtonsTheme.of(context);
  /// ```
  static ToggleButtonsThemeData of(BuildContext context) {
    final ToggleButtonsTheme toggleButtonsTheme = context.inheritFromWidgetOfExactType(ToggleButtonsTheme);
    return toggleButtonsTheme?.data ?? Theme.of(context).toggleButtonsTheme;
  }

  @override
  bool updateShouldNotify(ToggleButtonsTheme oldWidget) => data != oldWidget.data;
}