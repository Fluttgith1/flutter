import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';

import 'debug.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'theme.dart';

class _MaterialSheetBuilder extends StatelessWidget {
  const _MaterialSheetBuilder({
    Key? key,
    required this.child,
    this.backgroundColor,
    this.elevation,
    this.theme,
    this.clipBehavior,
    this.shape,
  }) : super(key: key);

  /// The child contained by the modal sheet
  final Widget child;

  final Color? backgroundColor;
  final double? elevation;
  final ThemeData? theme;
  final Clip? clipBehavior;
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    final BottomSheetThemeData? bottomSheetTheme =
        Theme.of(context)?.bottomSheetTheme;
    final Color? color = backgroundColor ??
        bottomSheetTheme?.modalBackgroundColor ??
        bottomSheetTheme?.backgroundColor;
    final double elevation =
        this.elevation ?? bottomSheetTheme?.elevation ?? 0.0;
    final ShapeBorder? shape = this.shape ?? bottomSheetTheme?.shape;
    final Clip clipBehavior =
        this.clipBehavior ?? bottomSheetTheme?.clipBehavior ?? Clip.none;

    final Widget sheet = Material(
        color: color,
        elevation: elevation,
        shape: shape,
        clipBehavior: clipBehavior,
        child: child);

    if (theme != null) {
      return Theme(data: theme!, child: sheet);
    } else {
      return sheet;
    }
  }
}

/// We are missing accesibility labels this way.
class MaterialSheetRoute<T> extends SheetRoute<T> {
  MaterialSheetRoute({
    double? closeProgressThreshold,
    required WidgetBuilder builder,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    Color? barrierColor,
    bool bounce = false,
    bool expand = false,
    AnimationController? secondAnimation,
    Curve? animationCurve,
    bool isDismissible = true,
    bool enableDrag = true,
    Duration? duration,
  }) : super(
          builder: (BuildContext context) {
            return _MaterialSheetBuilder(
              child: Builder(builder: builder),
              clipBehavior: clipBehavior,
              theme: Theme.of(context, shadowThemeOnly: true),
              elevation: elevation,
              shape: shape,
              backgroundColor: backgroundColor,
            );
          },
          closeProgressThreshold: closeProgressThreshold,
          secondAnimationController: secondAnimation,
          bounce: bounce,
          expanded: expand,
          //barrierLabel: MaterialLocalizations.of(context)!.modalBarrierDismissLabel,
          //modalLabel: _getRouteLabel(context),
          isDismissible: isDismissible,
          modalBarrierColor: barrierColor,
          enableDrag: enableDrag,
          animationCurve: animationCurve,
          duration: duration,
        );

  String _getRouteLabel(BuildContext context) {
    final TargetPlatform platform =
        Theme.of(context)?.platform ?? defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return '';
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        if (MaterialLocalizations.of(context) != null) {
          return MaterialLocalizations.of(context)!.dialogLabel;
        } else {
          return const DefaultMaterialLocalizations().dialogLabel;
        }
    }
  }
}
