// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';

// All values eyeballed.
const double _kScrollbarMinLength = 36.0;
const double _kScrollbarMinOverscrollLength = 8.0;
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 1200);
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 250);
const Duration _kScrollbarResizeDuration = Duration(milliseconds: 100);

// Extracted from iOS 13.1 beta using Debug View Hierarchy.
const Color _kScrollbarColor = CupertinoDynamicColor.withBrightness(
  color: Color(0x59000000),
  darkColor: Color(0x80FFFFFF),
);

// This is the amount of space from the top of a vertical scrollbar to the
// top edge of the scrollable, measured when the vertical scrollbar overscrolls
// to the top.
// TODO(LongCatIsLooong): fix https://github.com/flutter/flutter/issues/32175
const double _kScrollbarMainAxisMargin = 3.0;
const double _kScrollbarCrossAxisMargin = 3.0;

/// An iOS style scrollbar.
///
/// A scrollbar indicates which portion of a [Scrollable] widget is actually
/// visible.
///
/// To add a scrollbar to a [ScrollView], simply wrap the scroll view widget in
/// a [CupertinoScrollbar] widget.
///
/// By default, the CupertinoScrollbar will be draggable (a feature introduced
/// in iOS 13), it uses the PrimaryScrollController. For multiple scrollbars, or
/// other more complicated situations, see the [controller] parameter.
///
/// See also:
///
///  * [ListView], which display a linear, scrollable list of children.
///  * [GridView], which display a 2 dimensional, scrollable array of children.
///  * [Scrollbar], a Material Design scrollbar that dynamically adapts to the
///    platform showing either an Android style or iOS style scrollbar.
///  * [RawScrollbarThumb], the abstract base class this inherits from.
class CupertinoScrollbar extends RawScrollbarThumb {
  /// Creates an iOS style scrollbar that wraps the given [child].
  ///
  /// The [child] should be a source of [ScrollNotification] notifications,
  /// typically a [Scrollable] widget.
  const CupertinoScrollbar({
    Key? key,
    required Widget child,
    ScrollController? controller,
    bool isAlwaysShown = false,
    double thickness = defaultThickness,
    this.thicknessWhileDragging = defaultThicknessWhileDragging,
    Radius radius = defaultRadius,
    this.radiusWhileDragging = defaultRadiusWhileDragging,
  }) : assert(thickness != null),
       assert(thickness < double.infinity),
       assert(thicknessWhileDragging != null),
       assert(thicknessWhileDragging < double.infinity),
       assert(radius != null),
       assert(radiusWhileDragging != null),
       super(
      key: key,
      child: child,
      controller: controller,
      isAlwaysShown: isAlwaysShown,
      thickness: thickness,
      radius: radius,
      fadeDuration: _kScrollbarFadeDuration,
      timeToFade: _kScrollbarTimeToFade,
      pressDuration: const Duration(milliseconds: 100),
    );

  /// Default value for [thickness] if it's not specified in [CupertinoScrollbar].
  static const double defaultThickness = 3;

  /// Default value for [thicknessWhileDragging] if it's not specified in
  /// [CupertinoScrollbar].
  static const double defaultThicknessWhileDragging = 8.0;

  /// Default value for [radius] if it's not specified in [CupertinoScrollbar].
  static const Radius defaultRadius = Radius.circular(1.5);

  /// Default value for [radiusWhileDragging] if it's not specified in
  /// [CupertinoScrollbar].
  static const Radius defaultRadiusWhileDragging = Radius.circular(4.0);

  /// The thickness of the scrollbar when it's being dragged by the user.
  ///
  /// When the user starts dragging the scrollbar, the thickness will animate
  /// from [thickness] to this value, then animate back when the user stops
  /// dragging the scrollbar.
  final double thicknessWhileDragging;

  /// The radius of the scrollbar edges when the scrollbar is being dragged by
  /// the user.
  ///
  /// When the user starts dragging the scrollbar, the radius will animate
  /// from [radius] to this value, then animate back when the user stops
  /// dragging the scrollbar.
  final Radius radiusWhileDragging;


  @override
  _CupertinoScrollbarState createState() => _CupertinoScrollbarState();
}

class _CupertinoScrollbarState extends RawScrollbarThumbState<CupertinoScrollbar> {
  late AnimationController _thicknessAnimationController;

  @override
  ScrollbarPainter? painter;
  @override
  final GlobalKey customPaintKey = GlobalKey();

  double get _thickness {
    return widget.thickness! + _thicknessAnimationController.value * (widget.thicknessWhileDragging - widget.thickness!);
  }

  Radius get _radius {
    return Radius.lerp(widget.radius, widget.radiusWhileDragging, _thicknessAnimationController.value)!;
  }

  @override
  void initState() {
    super.initState();
    _thicknessAnimationController = AnimationController(
      vsync: this,
      duration: _kScrollbarResizeDuration,
    );
    _thicknessAnimationController.addListener(() {
      painter!.updateThickness(_thickness, _radius);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (painter == null) {
      painter = _buildCupertinoScrollbarPainter(context);
    } else {
      painter!
        ..textDirection = Directionality.of(context)
        ..color = CupertinoDynamicColor.resolve(_kScrollbarColor, context)
        ..padding = MediaQuery.of(context).padding;
    }
    triggerScrollbar();
  }

  @override
  void didUpdateWidget(CupertinoScrollbar oldWidget) {
    assert(painter != null);
    painter!.updateThickness(_thickness, _radius);
    super.didUpdateWidget(oldWidget);
  }

  /// Returns a [ScrollbarPainter] visually styled like the iOS scrollbar.
  ScrollbarPainter _buildCupertinoScrollbarPainter(BuildContext context) {
    return ScrollbarPainter(
      color: CupertinoDynamicColor.resolve(_kScrollbarColor, context),
      textDirection: Directionality.of(context),
      thickness: _thickness,
      fadeoutOpacityAnimation: fadeoutOpacityAnimation,
      mainAxisMargin: _kScrollbarMainAxisMargin,
      crossAxisMargin: _kScrollbarCrossAxisMargin,
      radius: _radius,
      padding: MediaQuery.of(context).padding,
      minLength: _kScrollbarMinLength,
      minOverscrollLength: _kScrollbarMinOverscrollLength,
    );
  }

  double _pressStartAxisPosition = 0.0;

  // Long press event callbacks handle the gesture where the user long presses
  // on the scrollbar thumb and then drags the scrollbar without releasing.

  @override
  void handleLongPressStart(LongPressStartDetails details) {
    super.handleLongPressStart(details);
    final Axis direction = getDirection()!;
    switch (direction) {
      case Axis.vertical:
        _pressStartAxisPosition = details.localPosition.dy;
        break;
      case Axis.horizontal:
        _pressStartAxisPosition = details.localPosition.dx;
        break;
    }
  }

  @override
  void handleLongPress() {
    if (getDirection() == null) {
      return;
    }
    super.handleLongPress();
    _thicknessAnimationController.forward().then<void>(
          (_) => HapticFeedback.mediumImpact(),
    );
  }

  @override
  void handleLongPressEnd(LongPressEndDetails details) {
    final Axis? direction = getDirection();
    if (direction == null) {
      return;
    }
    _thicknessAnimationController.reverse();
    super.handleLongPressEnd(details);
    switch(direction) {
      case Axis.vertical:
        if (details.velocity.pixelsPerSecond.dy.abs() < 10 &&
          (details.localPosition.dy - _pressStartAxisPosition).abs() > 0) {
          HapticFeedback.mediumImpact();
        }
        break;
      case Axis.horizontal:
        if (details.velocity.pixelsPerSecond.dx.abs() < 10 &&
          (details.localPosition.dx - _pressStartAxisPosition).abs() > 0) {
          HapticFeedback.mediumImpact();
        }
        break;
    }
  }

  @override
  void dispose() {
    _thicknessAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: handleScrollNotification,
      child: RepaintBoundary(
        child: RawGestureDetector(
          gestures: defaultGestures,
          child: CustomPaint(
            key: customPaintKey,
            foregroundPainter: painter,
            child: RepaintBoundary(child: widget.child),
          ),
        ),
      ),
    );
  }
}
