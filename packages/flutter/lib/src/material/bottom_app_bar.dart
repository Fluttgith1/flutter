// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'bottom_app_bar_theme.dart';
import 'color_scheme.dart';
import 'colors.dart';
import 'elevation_overlay.dart';
import 'material.dart';
import 'scaffold.dart';
import 'theme.dart';

// Examples can assume:
// late Widget bottomAppBarContents;

/// A container that is typically used with [Scaffold.bottomNavigationBar].
///
/// Typically used with a [Scaffold] and a [FloatingActionButton].
///
/// {@tool snippet}
/// ```dart
/// Scaffold(
///   bottomNavigationBar: BottomAppBar(
///     color: Colors.white,
///     child: bottomAppBarContents,
///   ),
///   floatingActionButton: const FloatingActionButton(onPressed: null),
/// )
/// ```
/// {@end-tool}
///
/// {@tool dartpad}
/// This example shows the [BottomAppBar], which (in Material 2)
/// can be configured to have a notch using the
/// [BottomAppBar.shape] property. This also includes an optional [FloatingActionButton], which illustrates
/// the [FloatingActionButtonLocation]s in relation to the [BottomAppBar].
///
/// ** See code in examples/api/lib/material/bottom_app_bar/bottom_app_bar.1.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example shows Material 3 [BottomAppBar] with its expected look and behaviors.
///
/// This also includes an optional [FloatingActionButton], which illustrates
/// the [FloatingActionButtonLocation.endContained].
///
/// ** See code in examples/api/lib/material/bottom_app_bar/bottom_app_bar.2.dart **
/// {@end-tool}
///
/// See also:
///
///  * [NotchedShape] which calculates the notch for a notched [BottomAppBar]
///    in Material 2.
///  * [FloatingActionButton] which the [BottomAppBar] makes a notch for in
///    Material 2.
///  * [AppBar] for a toolbar that is shown at the top of the screen.
class BottomAppBar extends StatefulWidget {
  /// Creates a bottom application bar.
  ///
  /// The [clipBehavior] argument defaults to [Clip.none].
  /// Additionally, [elevation] must be non-negative.
  ///
  /// If [color], [elevation], or [shape] are null, their [BottomAppBarTheme] values will be used.
  /// If the corresponding [BottomAppBarTheme] property is null, then the default
  /// specified in the property's documentation will be used.
  const BottomAppBar({
    super.key,
    this.color,
    this.elevation,
    this.shape,
    this.clipBehavior = Clip.none,
    this.notchMargin = 4.0,
    this.child,
    this.padding,
    this.surfaceTintColor,
    this.shadowColor,
    this.height,
  }) : assert(elevation == null || elevation >= 0.0);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  ///
  /// Typically the child will be a [Row] whose first child
  /// is an [IconButton] with the [Icons.menu] icon.
  final Widget? child;

  /// The amount of space to surround the child inside the bounds of the [BottomAppBar].
  ///
  /// In Material 3 the padding will default to `EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)`
  /// Otherwise the value will default to EdgeInsets.zero.
  final EdgeInsetsGeometry? padding;

  /// The bottom app bar's background color.
  ///
  /// If this property is null then [BottomAppBarTheme.color] of
  /// [ThemeData.bottomAppBarTheme] is used. If that's null then
  /// [ThemeData.bottomAppBarColor] is used.
  final Color? color;

  /// The z-coordinate at which to place this bottom app bar relative to its
  /// parent.
  ///
  /// This controls the size of the shadow below the bottom app bar. The
  /// value is non-negative.
  ///
  /// If this property is null then [BottomAppBarTheme.elevation] of
  /// [ThemeData.bottomAppBarTheme] is used. If that's null and
  /// [ThemeData.useMaterial3] is true, than the default value is 3 else is 8.
  final double? elevation;

  /// The notch that is made for the floating action button.
  ///
  /// If this property is null then [BottomAppBarTheme.shape] of
  /// [ThemeData.bottomAppBarTheme] is used. If that's null then the shape will
  /// be rectangular with no notch.
  ///
  /// If the ambient [ThemeData.useMaterial3] is true,
  /// then there is never a notch, and this property must be null.
  /// (The Material 3 spec does not provide for a notch:
  /// <https://m3.material.io/components/bottom-app-bar/specs#9d91e4a4-a6d9-4ad5-afad-430267ebb4e9>.)
  final NotchedShape? shape;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  ///
  /// Has no effect if there is no notch; see [shape].
  final Clip clipBehavior;

  /// The margin between the [FloatingActionButton] and the [BottomAppBar]'s
  /// notch.
  ///
  /// Has no effect if there is no notch; see [shape].
  final double notchMargin;

  /// The color used as an overlay on [color] to indicate elevation.
  ///
  /// If this is null, no overlay will be applied. Otherwise the
  /// color will be composited on top of [color] with an opacity related
  /// to [elevation] and used to paint the background of the [BottomAppBar].
  ///
  /// The default is null.
  ///
  /// See [Material.surfaceTintColor] for more details on how this overlay is applied.
  final Color? surfaceTintColor;

  /// The color of the shadow below the app bar.
  ///
  /// If this property is null, then [BottomAppBarTheme.shadowColor] of
  /// [ThemeData.bottomAppBarTheme] is used. If that is also null, the default value
  /// is fully opaque black for Material 2, and transparent for Material 3.
  ///
  /// See also:
  ///
  ///  * [elevation], which defines the size of the shadow below the app bar.
  ///  * [shape], which defines the shape of the app bar and its shadow.
  final Color? shadowColor;

  /// The double value used to indicate the height of the [BottomAppBar].
  ///
  /// If this is null, the default value is the minimum in relation to the content,
  /// unless [ThemeData.useMaterial3] is true, in which case it defaults to 80.0.
  final double? height;

  @override
  State createState() => _BottomAppBarState();
}

class _BottomAppBarState extends State<BottomAppBar> {
  late ValueListenable<ScaffoldGeometry> geometryListenable;
  final GlobalKey materialKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    geometryListenable = Scaffold.geometryOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isMaterial3 = theme.useMaterial3;
    assert(!isMaterial3 || widget.shape == null,
      'The [BottomAppBar.shape] field is not permitted in Material 3.');

    final BottomAppBarTheme babTheme = BottomAppBarTheme.of(context);
    final BottomAppBarTheme defaults = isMaterial3 ? _BottomAppBarDefaultsM3(context) : _BottomAppBarDefaultsM2(context);

    final bool hasFab = Scaffold.of(context).hasFloatingActionButton;
    final NotchedShape? notchedShape = widget.shape ?? babTheme.shape ?? defaults.shape;
    final CustomClipper<Path> clipper = notchedShape != null && hasFab
      ? _BottomAppBarClipper(
          geometry: geometryListenable,
          shape: notchedShape,
          materialKey: materialKey,
          notchMargin: widget.notchMargin,
        )
      : const ShapeBorderClipper(shape: RoundedRectangleBorder());
    final double elevation = widget.elevation ?? babTheme.elevation ?? defaults.elevation!;
    final double? height = widget.height ?? babTheme.height ?? defaults.height;
    final Color color = widget.color ?? babTheme.color ?? defaults.color!;
    final Color surfaceTintColor = widget.surfaceTintColor ?? babTheme.surfaceTintColor ?? defaults.surfaceTintColor!;
    final Color shadowColor = widget.shadowColor ?? babTheme.shadowColor ?? defaults.shadowColor!;

    Widget child = Padding(
      padding: widget.padding ?? babTheme.padding ?? (isMaterial3 ? const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0) : EdgeInsets.zero),
      child: widget.child,
    );

    if (isMaterial3) {
      child = Material(
        key: materialKey,
        elevation: elevation,
        color: color,
        surfaceTintColor: surfaceTintColor,
        shadowColor: shadowColor,
        child: SafeArea(child: child),
      );
    } else {
      child = PhysicalShape(
        clipper: clipper,
        elevation: elevation,
        shadowColor: shadowColor,
        color: ElevationOverlay.applyOverlay(context, color, elevation),
        clipBehavior: widget.clipBehavior,
        child: Material(
          key: materialKey,
          type: MaterialType.transparency,
          child: SafeArea(child: child),
        ),
      );
    }

    return SizedBox(height: height, child: child);
  }
}

class _BottomAppBarClipper extends CustomClipper<Path> {
  const _BottomAppBarClipper({
    required this.geometry,
    required this.shape,
    required this.materialKey,
    required this.notchMargin,
  }) : super(reclip: geometry);

  final ValueListenable<ScaffoldGeometry> geometry;
  final NotchedShape shape;
  final GlobalKey materialKey;
  final double notchMargin;

  // Returns the top of the BottomAppBar in global coordinates.
  //
  // If the Scaffold's bottomNavigationBar was specified, then we can use its
  // geometry value, otherwise we compute the location based on the AppBar's
  // Material widget.
  double get bottomNavigationBarTop {
    final double? bottomNavigationBarTop = geometry.value.bottomNavigationBarTop;
    if (bottomNavigationBarTop != null) {
      return bottomNavigationBarTop;
    }
    final RenderBox? box = materialKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.localToGlobal(Offset.zero).dy ?? 0;
  }

  @override
  Path getClip(Size size) {
    // button is the floating action button's bounding rectangle in the
    // coordinate system whose origin is at the appBar's top left corner,
    // or null if there is no floating action button.
    final Rect? button = geometry.value.floatingActionButtonArea?.translate(0.0, bottomNavigationBarTop * -1.0);
    return shape.getOuterPath(Offset.zero & size, button?.inflate(notchMargin));
  }

  @override
  bool shouldReclip(_BottomAppBarClipper oldClipper) {
    return oldClipper.geometry != geometry
        || oldClipper.shape != shape
        || oldClipper.notchMargin != notchMargin;
  }
}

class _BottomAppBarDefaultsM2 extends BottomAppBarTheme {
  const _BottomAppBarDefaultsM2(this.context)
    : super(
      elevation: 8.0,
    );

  final BuildContext context;

  @override
  Color? get color => Theme.of(context).bottomAppBarColor;

  @override
  Color? get surfaceTintColor => Theme.of(context).colorScheme.surfaceTint;

  @override
  Color get shadowColor => const Color(0xFF000000);
}

// BEGIN GENERATED TOKEN PROPERTIES - BottomAppBar

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

// Token database version: v0_162

class _BottomAppBarDefaultsM3 extends BottomAppBarTheme {
  _BottomAppBarDefaultsM3(this.context)
    : super(
      elevation: 3.0,
      height: 80.0,
    );

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  Color? get color => _colors.surface;

  @override
  Color? get surfaceTintColor => _colors.surfaceTint;

  @override
  Color? get shadowColor => Colors.transparent;
}

// END GENERATED TOKEN PROPERTIES - BottomAppBar
