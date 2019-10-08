// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';

// Extracted from https://developer.apple.com/design/resources/.

// Minimum padding from edges of the segmented control to edges of
// encompassing widget.
const EdgeInsetsGeometry _kHorizontalItemPadding = EdgeInsets.symmetric(vertical: 2, horizontal: 3);

// The corner radius of the thumb.
const double _kThumbCornerRadius = 6.93;
const EdgeInsets _kThumbInsets = EdgeInsets.symmetric(horizontal: 1);

// Minimum height of the segmented control.
const double _kMinSegmentedControlHeight = 28.0;

const Color _kSeparatorColor = Color(0x4D8E8E93);

const CupertinoDynamicColor _kThumbColor = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFFFFFFF),
  darkColor: Color(0xFF636366),
);

// The amount of space by which to inset each separator.
const EdgeInsets _kSeparatorInset = EdgeInsets.symmetric(vertical: 6);
const double _kSeparatorWidth = 1;
const Radius _kSeparatorRadius = Radius.circular(_kSeparatorWidth/2);
const double _kMinThumbScale = 0.95;

// The minimal horizontal distance between the edges of the separator and the closest child.
const double _kSegmentMinPadding = 9.25;

// The threshold value used in hasDraggedTooFar, for checking against the square
// L2 distance from the location of the current drag pointer, to the nearest
// vertice of the CupertinoSlidingSegmentedControl's Rect.
//
// Both the mechanism and the value are speculated.
const double _kTouchYDistanceThreshold = 50.0 * 50.0;

// The corner radius of the segmented control.
// Inspected from iOS 13.2 simulator.
const double _kCornerRadius = 8;

const SpringDescription _kSegmentedControlSpringDescription = SpringDescription(mass: 1, stiffness: 503.551, damping: 44.8799);
final SpringSimulation _kThumbSpringAnimationSimulation = SpringSimulation(
  _kSegmentedControlSpringDescription,
  0,
  1,
  0, // Everytime a new spring animation starts the previous animation stops.
);


const Duration _kSpringAnimationDuration = Duration(milliseconds: 412);

const Duration _kOpacityAnimationDuration = Duration(milliseconds: 470);

const Duration _kHighlightAnimationDuration = Duration(milliseconds: 200);

typedef _IntCallback = void Function(int);

class _FontWeightTween extends Tween<FontWeight> {
  _FontWeightTween({ FontWeight begin, FontWeight end}) : super(begin: begin, end: end);

  @override
  FontWeight lerp(double t) => FontWeight.lerp(begin, end, t);
}

/// An iOS 13 style segmented control.
///
/// Displays the widgets provided in the [Map] of [children] in a
/// horizontal list. Used to select between a number of mutually exclusive
/// options. When one option in the segmented control is selected, the other
/// options in the segmented control cease to be selected.
///
/// A segmented control can feature any [Widget] as one of the values in its
/// [Map] of [children]. The type T is the type of the keys used
/// to identify each widget and determine which widget is selected. As
/// required by the [Map] class, keys must be of consistent types
/// and must be comparable. The ordering of the keys will determine the order
/// of the widgets in the segmented control.
///
/// When the state of the segmented control changes, the widget calls the
/// [onValueChanged] callback. The map key associated with the newly selected
/// widget is returned in the [onValueChanged] callback. Typically, widgets
/// that use a segmented control will listen for the [onValueChanged] callback
/// and rebuild the segmented control with a new [groupValue] to update which
/// option is currently selected.
///
/// The [children] will be displayed in the order of the keys in the [Map].
/// The height of the segmented control is determined by the height of the
/// tallest widget provided as a value in the [Map] of [children].
/// The width of each child in the segmented control will be equal to the width
/// of widest child, unless the combined width of the children is wider than
/// the available horizontal space. In this case, the available horizontal space
/// is divided by the number of provided [children] to determine the width of
/// each widget. The selection area for each of the widgets in the [Map] of
/// [children] will then be expanded to fill the calculated space, so each
/// widget will appear to have the same dimensions.
///
/// A segmented control may optionally be created with custom colors. The
/// [thumbColor], [backgroundColor] arguments can be used to override the segmented
/// control's colors from its defaults.
///
/// See also:
///
///  * <https://developer.apple.com/design/human-interface-guidelines/ios/controls/segmented-controls/>
class CupertinoSlidingSegmentedControl<T> extends StatefulWidget {
  /// Creates an iOS-style segmented control bar.
  ///
  /// The [children] and [onValueChanged] arguments must not be null. The
  /// [children] argument must be an ordered [Map] such as a [LinkedHashMap].
  /// Further, the length of the [children] list must be greater than one.
  ///
  /// Each widget value in the map of [children] must have an associated key
  /// that uniquely identifies this widget. This key is what will be returned
  /// in the [onValueChanged] callback when a new value from the [children] map
  /// is selected.
  ///
  /// The [groupValue] is the currently selected value for the segmented control.
  /// If no [groupValue] is provided, or the [groupValue] is null, no widget will
  /// appear as selected. The [groupValue] must be either null or one of the keys
  /// in the [children] map.
  CupertinoSlidingSegmentedControl({
    Key key,
    @required this.children,
    @required this.onValueChanged,
    this.controller,
    this.thumbColor = _kThumbColor,
    this.padding,
    this.backgroundColor = CupertinoColors.tertiarySystemFill,
  }) : assert(children != null),
       assert(children.length >= 2),
       assert(onValueChanged != null),
       assert(
         controller.value == null || children.keys.any((T child) => child == controller.value),
         "The controller's value must be either null or one of the keys in the children map.",
       ),
       super(key: key);

  /// The identifying keys and corresponding widget values in the
  /// segmented control.
  ///
  /// The map must have more than one entry.
  /// This attribute must be an ordered [Map] such as a [LinkedHashMap].
  final Map<T, Widget> children;

  /// A [ValueNotifier]<[T]> that controls the currently selected child.
  ///
  /// Its value must be one of the keys in the [Map] of [children], or null, in
  /// which case no widget will be selected.
  ///
  /// Changing [container]'s value will
  final ValueNotifier<T> controller;

  /// The callback that is called when a new option is tapped.
  ///
  /// This attribute must not be null.
  ///
  /// The segmented control passes the newly selected widget's associated key
  /// to the callback but does not actually change state until the parent
  /// widget rebuilds the segmented control with the new [groupValue].
  ///
  /// The callback provided to [onValueChanged] should update the state of
  /// the parent [StatefulWidget] using the [State.setState] method, so that
  /// the parent gets rebuilt; for example:
  ///
  /// {@tool sample}
  ///
  /// ```dart
  /// class SegmentedControlExample extends StatefulWidget {
  ///   @override
  ///   State createState() => SegmentedControlExampleState();
  /// }
  ///
  /// class SegmentedControlExampleState extends State<SegmentedControlExample> {
  ///   final Map<int, Widget> children = const {
  ///     0: Text('Child 1'),
  ///     1: Text('Child 2'),
  ///   };
  ///
  ///   int currentValue;
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return Container(
  ///       child: CupertinoSegmentedControl<int>(
  ///         children: children,
  ///         onValueChanged: (int newValue) {
  ///           setState(() {
  ///             currentValue = newValue;
  ///           });
  ///         },
  ///         groupValue: currentValue,
  ///       ),
  ///     );
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  final ValueChanged<T> onValueChanged;

  /// The color used to paint the rounded rect behind the [children] and the separators.
  ///
  /// The default value is [CupertinoColors.tertiarySystemFill]. Skips painting
  /// entirely if null is specified.
  final Color backgroundColor;

  /// The color used to paint the interior of the thumb that appears behind the
  /// currently selected item.
  ///
  /// The default value is a [CupertinoDynamicColor] that appears white in light
  /// mode and becomes a gray color
  final Color thumbColor;

  /// The CupertinoSegmentedControl will be placed inside this padding
  ///
  /// Defaults to EdgeInsets.symmetric(horizontal: 16.0)
  final EdgeInsetsGeometry padding;

  @override
  _SegmentedControlState<T> createState() => _SegmentedControlState<T>();
}

class _SegmentedControlState<T> extends State<CupertinoSlidingSegmentedControl<T>>
    with TickerProviderStateMixin<CupertinoSlidingSegmentedControl<T>> {

  final Map<T, AnimationController> _highlightControllers = <T, AnimationController>{};
  final Tween<FontWeight> highlightTween = _FontWeightTween(begin: FontWeight.normal, end: FontWeight.w600);

  final Map<T, AnimationController> _pressControllers = <T, AnimationController>{};
  final Tween<double> pressTween = Tween<double>(begin: 1, end: 0.2);

  TextDirection textDirection;
  ValueNotifier<T> controller;

  AnimationController createHighlightAnimationController({ bool isCompleted = false }) {
    return AnimationController(
      duration: _kHighlightAnimationDuration,
      value: isCompleted ? 1 : 0,
      vsync: this,
    )..addListener(() {
      setState(() {
        // State of background/text colors has changed
      });
    });
  }

  AnimationController createFadeoutAnimationController() {
    return AnimationController(
      duration: _kOpacityAnimationDuration,
      vsync: this,
    )..addListener(() {
        setState(() {
            // State of background/text colors has changed
        });
    });
  }

  @override
  void initState() {
    super.initState();

    controller = widget.controller;
    _highlighted = controller.value;

    for (T currentKey in widget.children.keys) {
      _highlightControllers[currentKey] = createHighlightAnimationController(
        isCompleted: currentKey == controller.value,  // Highlight the current selection.
      );
      _pressControllers[currentKey] = createFadeoutAnimationController();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    textDirection = Directionality.of(context);
  }

  @override
  void didUpdateWidget(CupertinoSlidingSegmentedControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update animation controllers.
    for (T oldKey in oldWidget.children.keys) {
      if (!widget.children.containsKey(oldKey)) {
        _highlightControllers[oldKey]..dispose();
        _pressControllers[oldKey].dispose();

        _highlightControllers.remove(oldKey);
        _pressControllers.remove(oldKey);
      }
    }

    for (T newKey in widget.children.keys) {
      if (!_highlightControllers.keys.contains(newKey)) {
        _highlightControllers[newKey] = createHighlightAnimationController();
        _pressControllers[newKey] = createFadeoutAnimationController();
      }
    }

    if (controller.value != oldWidget.controller.value) {
      highlighted = widget.controller.value;
    }

    controller = widget.controller;
  }

  @override
  void dispose() {
    for (AnimationController animationController in _highlightControllers.values) {
      animationController.dispose();
    }

    for (AnimationController animationController in _pressControllers.values) {
      animationController.dispose();
    }
    super.dispose();
  }

  void animateHighlightController({ T at, bool forward }) {
    if (at == null)
      return;
    final AnimationController controller = _highlightControllers[at];
    assert(!forward || controller != null);
    controller?.animateTo(forward ? 1 : 0, duration: _kHighlightAnimationDuration, curve: Curves.ease);
  }

  T _highlighted;
  set highlighted(T newValue) {
    if (_highlighted == newValue)
      return;
    animateHighlightController(at: newValue, forward: true);
    animateHighlightController(at: _highlighted, forward: false);
    _highlighted = newValue;
  }

  T _pressed;
  set pressed(T newValue) {
    if (_pressed == newValue)
      return;

    if (_pressed != null) {
      _pressControllers[_pressed]?.animateTo(0, duration: _kOpacityAnimationDuration, curve: Curves.ease);
    }
    if (newValue != _highlighted && newValue != null) {
      _pressControllers[newValue].animateTo(1, duration: _kOpacityAnimationDuration, curve: Curves.ease);
    }
    _pressed = newValue;
  }

  void _didChangeSelectedByGesture() {
    controller.value = _highlighted;
  }

  @override
  Widget build(BuildContext context) {
    List<T> keys;

    switch (textDirection) {
      case TextDirection.ltr:
        keys = widget.children.keys.toList(growable: false);
        break;
      case TextDirection.rtl:
        keys = widget.children.keys.toList().reversed.toList(growable: false);
        break;
    }

    final List<Widget> children = <Widget>[];
    for (T currentKey in keys) {
      final TextStyle textStyle = DefaultTextStyle.of(context).style.copyWith(
        fontWeight: highlightTween.evaluate(_highlightControllers[currentKey]),
      );

      final Widget child = DefaultTextStyle(
        style: textStyle,
        child: Semantics(
          button: true,
          inMutuallyExclusiveGroup: true,
          selected: controller.value == currentKey,
          child: Opacity(
            alwaysIncludeSemantics: true,
            opacity: pressTween.evaluate(_pressControllers[currentKey]),
            // Expand the hitTest area to be as large as the Opacity widget.
            child: MetaData(
              behavior: HitTestBehavior.opaque,
              child: Center(child: widget.children[currentKey]),
            ),
          ),
        ),
      );

      children.add(child);
    }

    final int selectedIndex = controller.value == null ? null : keys.indexOf(controller.value);

    final Widget box = _SegmentedControlRenderWidget<T>(
      children: children,
      selectedIndex: selectedIndex,
      thumbColor: widget.thumbColor,
      onPressedIndexChange: (int index) { pressed = index == null ? null : keys[index]; },
      onSelectedIndexChange: (int index) { highlighted = index == null ? null : keys[index]; },
      didChangeSelectedByGesture: _didChangeSelectedByGesture,
      vsync: this,
    );

    return UnconstrainedBox(
      constrainedAxis: Axis.horizontal,
      child: Container(
        padding: widget.padding ?? _kHorizontalItemPadding,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(_kCornerRadius)),
          color: CupertinoDynamicColor.resolve(widget.backgroundColor, context),
        ),
        child: UnconstrainedBox(constrainedAxis: Axis.horizontal, child: box),
      ),
    );
  }
}

class _SegmentedControlRenderWidget<T> extends MultiChildRenderObjectWidget {
  _SegmentedControlRenderWidget({
    Key key,
    List<Widget> children = const <Widget>[],
    @required this.selectedIndex,
    @required this.thumbColor,
    @required this.onSelectedIndexChange,
    @required this.onPressedIndexChange,
    @required this.didChangeSelectedByGesture,
    @required this.vsync,
  }) : super(
          key: key,
          children: children,
        );

  final int selectedIndex;
  final Color thumbColor;
  final TickerProvider vsync;

  final _IntCallback onSelectedIndexChange;
  final _IntCallback onPressedIndexChange;
  final VoidCallback didChangeSelectedByGesture;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSegmentedControl<T>(
      selectedIndex: selectedIndex,
      thumbColor: CupertinoDynamicColor.resolve(thumbColor, context),
      onPressedIndexChange: onPressedIndexChange,
      onSelectedIndexChange: onSelectedIndexChange,
      vsync: vsync,
    )..didChangeSelectedByGesture = didChangeSelectedByGesture;
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSegmentedControl<T> renderObject) {
    renderObject
      ..didChangeSelectedByGesture = didChangeSelectedByGesture
      ..onPressedIndexChange = onPressedIndexChange
      ..onSelectedIndexChange = onSelectedIndexChange
      ..thumbColor = CupertinoDynamicColor.resolve(thumbColor, context)
      ..guardedSetHighlightedIndex(selectedIndex);
  }
}

class _ChildAnimationManifest {
  _ChildAnimationManifest({
    this.opacity = 1,
    @required this.separatorOpacity,
  }) : assert(separatorOpacity != null),
       assert(opacity != null),
       separatorTween = Tween<double>(begin: separatorOpacity, end: separatorOpacity),
       opacityTween = Tween<double>(begin: opacity, end: opacity);

  double opacity;
  Tween<double> opacityTween;
  double separatorOpacity;
  Tween<double> separatorTween;
}


class _SegmentedControlContainerBoxParentData extends ContainerBoxParentData<RenderBox> { }

// The behavior of a UISegmentedControl as observed on iOS 13.1:
//
// 1. Tap up events inside it will set the current selected index to the index of the
//    segment at the tap up location instantaneously (there might be animation but
//    the index change seems to happen before animation finishes), unless the tap down event from the same
//    touch event didn't happen within the segmented control, in which case the touch event will be ignored
//    entirely (will be referring to these touch events as invalid touch events below).
//
// 2. A valid tap up event will also trigger the sliding CASpringAnimation (even
//    when it lands on the current segment), starting from the current `frame`
//    of the thumb. The previous sliding animation, if still playing, will be
//    removed and its velocity reset to 0. The sliding animation has a fixed
//    duration, regardless of the distance or transform.
//
// 3. When the sliding animation plays two other animations take place. In one animation
//    the content of the current segment gradually becomes "highlighted", turning the
//    font weight to semibold (CABasicAnimation, timingFunction = default, duration = 0.2).
//    The other is the separator fadein/fadeout animation.
//
// 4. A tap down event on the segment pointed to by the current selected
//    index will trigger a CABasciaAnimation that shrinks the thumb to 95% of its
//    original size, even if the
//    sliding animation is still playing. The corresponding tap up event will revert
//    the process (eyeballed).
//
// 5. A tap down event on other segments will trigger a CABasciaAnimation
//    (timingFunction = default, duration = 0.47.) that fades out the content,
//    eventually reducing the alpha of that segment to 20% unless interrupted by
//    a tap up event or the pointer moves out of the region (either outside of the
//    segmented control's vicinity or to a different segment). The reverse animation
//    has the same duration and timing function.
class _RenderSegmentedControl<T> extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, ContainerBoxParentData<RenderBox>>,
        RenderBoxContainerDefaultsMixin<RenderBox, ContainerBoxParentData<RenderBox>> {
  _RenderSegmentedControl({
    @required int selectedIndex,
    @required int pressedIndex,
    @required Color thumbColor,
    @required this.onSelectedIndexChange,
    @required this.onPressedIndexChange,
    @required TickerProvider vsync,
  }) : _highlightedIndex = selectedIndex,
       _pressedIndex = pressedIndex,
       _thumbColor = thumbColor,
       _vsync = vsync,
       thumbController = AnimationController(
         duration: _kSpringAnimationDuration,
         value: 0,
         vsync: vsync,
       ),
       thumbScaleController = AnimationController(
         duration: _kSpringAnimationDuration,
         value: 1,
         vsync: vsync,
       ),
       separatorOpacityController = AnimationController(
         duration: _kSpringAnimationDuration,
         value: 0,
         vsync: vsync,
       ) {
         thumbController.addListener(markNeedsPaint);
         thumbScaleController.addListener(markNeedsPaint);
         separatorOpacityController.addListener(markNeedsPaint);

         _drag
          ..onDown = _onDown
          ..onUpdate = _onUpdate
          ..onEnd = _onEnd
          ..onCancel = _onCancel;
       }

  TickerProvider get vsync => _vsync;
  TickerProvider _vsync;
  set vsync(TickerProvider value) {
    assert(value != null);
    if (value == _vsync)
      return;
    _vsync = value;
    thumbController.resync(vsync);
    thumbScaleController.resync(vsync);
    separatorOpacityController.resync(vsync);
  }


  final HorizontalDragGestureRecognizer _drag = HorizontalDragGestureRecognizer();

  Map<RenderBox, _ChildAnimationManifest> childAnimations = <RenderBox, _ChildAnimationManifest>{};

  // The current **Unscaled** Thumb Rect.
  Rect currentThumbRect;

  Tween<Rect> currentThumbTween;
  final AnimationController thumbController;

  final AnimationController separatorOpacityController;

  Tween<double> thumbScaleTween = Tween<double>(begin: _kMinThumbScale, end: 1);
  final AnimationController thumbScaleController;
  double currentThumbScale = 1;

  Offset localDragOffset;
  bool startedOnSelectedSegment;

  _IntCallback onSelectedIndexChange;
  _IntCallback onPressedIndexChange;
  VoidCallback didChangeSelectedByGesture;

  @override
  void insert(RenderBox child, { RenderBox after }) {
    super.insert(child, after: after);
    if (childAnimations == null)
      return;

    assert(childAnimations[child] == null);
    childAnimations[child] = _ChildAnimationManifest(separatorOpacity: 1);
  }

  @override
  void remove(RenderBox child) {
    super.remove(child);
    childAnimations?.remove(child);
  }

  // selectedIndex has changed, animations need to be updated.
  bool _needsThumbAnimationUpdate = false;

  int get highlightedIndex => _highlightedIndex;
  int _highlightedIndex;
  set highlightedIndex(int value) {
    if (_highlightedIndex == value) {
      return;
    }

    _needsThumbAnimationUpdate = true;
    _highlightedIndex = value;

    thumbController.animateWith(_kThumbSpringAnimationSimulation);

    separatorOpacityController.reset();
    separatorOpacityController.animateTo(
      1,
      duration: _kSpringAnimationDuration,
      curve: Curves.ease,
    );

    onSelectedIndexChange(value);
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  void guardedSetHighlightedIndex(int value) {
    // Ignore set highlightedIndex when a valid user gesture is in progress.
    if (startedOnSelectedSegment == true)
      return;
    highlightedIndex = value;
  }

  int get pressedIndex => _pressedIndex;
  int _pressedIndex;
  set pressedIndex(int value) {
    if (_pressedIndex == value) {
      return;
    }

    assert(value == null || (value >= 0 && value < childCount));

    _pressedIndex = value;
    onPressedIndexChange(value);
  }

  Color get thumbColor => _thumbColor;
  Color _thumbColor;
  set thumbColor(Color value) {
    if (_thumbColor == value) {
      return;
    }
    _thumbColor = value;
    markNeedsPaint();
  }

  double get totalSeparatorWidth => (_kSeparatorInset.horizontal + _kSeparatorWidth) * (childCount - 1);

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      _drag.addPointer(event);
    }
  }

  int indexFromLocation(Offset location) {
    return childCount == 0
      ? 0
      // This assumes all children have the same width.
      : (localDragOffset.dx / (size.width / childCount))
        .floor()
        .clamp(0, childCount - 1);
  }

  void _onDown(DragDownDetails details) {
    assert(size.contains(details.localPosition));
    localDragOffset = details.localPosition;
    final int index = indexFromLocation(localDragOffset);
    startedOnSelectedSegment = index == highlightedIndex;
    pressedIndex = index;

    if (startedOnSelectedSegment) {
      playThumbScaleAnimation(isExpanding: false);
    }
  }

  void _onUpdate(DragUpdateDetails details) {
    localDragOffset = details.localPosition;
    final int newIndex = indexFromLocation(localDragOffset);

    if (startedOnSelectedSegment) {
      highlightedIndex = newIndex;
      pressedIndex = newIndex;
    } else {
      pressedIndex = hasDraggedTooFar(details) ? null : newIndex;
    }
  }

  void _onEnd(DragEndDetails details) {
    if (startedOnSelectedSegment) {
      playThumbScaleAnimation(isExpanding: true);
      didChangeSelectedByGesture();
    }

    if (pressedIndex != null) {
      highlightedIndex = pressedIndex;
      didChangeSelectedByGesture();
    }
    pressedIndex = null;
    localDragOffset = null;
    startedOnSelectedSegment = null;
  }

  void _onCancel() {
    if (startedOnSelectedSegment) {
      playThumbScaleAnimation(isExpanding: true);
    }

    pressedIndex = null;
    localDragOffset = null;
    startedOnSelectedSegment = null;
  }

  void playThumbScaleAnimation({ @required bool isExpanding }) {
    assert(isExpanding != null);

    thumbScaleTween = Tween<double>(begin: currentThumbScale, end: isExpanding ? 1 : _kMinThumbScale);
    thumbScaleController.animateWith(_kThumbSpringAnimationSimulation);
  }

  bool hasDraggedTooFar(DragUpdateDetails details) {
    final Offset offCenter = details.localPosition - Offset(size.width/2, size.height/2);
    return math.pow(math.max(0, offCenter.dx.abs() - size.width/2), 2) + math.pow(math.max(0, offCenter.dy.abs() - size.height/2), 2) > _kTouchYDistanceThreshold;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    RenderBox child = firstChild;
    double minWidth = 0.0;
    while (child != null) {
      final _SegmentedControlContainerBoxParentData childParentData = child.parentData;
      final double childWidth = child.getMinIntrinsicWidth(height) + 2 * _kSegmentMinPadding;
      minWidth = math.max(minWidth, childWidth);
      child = childParentData.nextSibling;
    }
    return minWidth * childCount + totalSeparatorWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    RenderBox child = firstChild;
    double maxWidth = 0.0;
    while (child != null) {
      final _SegmentedControlContainerBoxParentData childParentData = child.parentData;
      final double childWidth = child.getMaxIntrinsicWidth(height) + 2 * _kSegmentMinPadding;
      maxWidth = math.max(maxWidth, childWidth);
      child = childParentData.nextSibling;
    }
    return maxWidth * childCount + totalSeparatorWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    RenderBox child = firstChild;
    double minHeight = 0.0;
    while (child != null) {
      final _SegmentedControlContainerBoxParentData childParentData = child.parentData;
      final double childHeight = child.getMinIntrinsicHeight(width);
      minHeight = math.max(minHeight, childHeight);
      child = childParentData.nextSibling;
    }
    return minHeight;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    RenderBox child = firstChild;
    double maxHeight = 0.0;
    while (child != null) {
      final _SegmentedControlContainerBoxParentData childParentData = child.parentData;
      final double childHeight = child.getMaxIntrinsicHeight(width);
      maxHeight = math.max(maxHeight, childHeight);
      child = childParentData.nextSibling;
    }
    return maxHeight;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SegmentedControlContainerBoxParentData) {
      child.parentData = _SegmentedControlContainerBoxParentData();
    }
  }

  @override
  void performLayout() {
    double childWidth = (constraints.minWidth - totalSeparatorWidth) / childCount;
    double maxHeight = _kMinSegmentedControlHeight;

    for (RenderBox child in getChildrenAsList()) {
      childWidth = math.max(childWidth, child.getMaxIntrinsicWidth(double.infinity) + 2 * _kSegmentMinPadding);
    }

    childWidth = math.min(
      childWidth,
      (constraints.maxWidth - totalSeparatorWidth) / childCount,
    );

    RenderBox child = firstChild;
    while (child != null) {
      final double boxHeight = child.getMaxIntrinsicHeight(childWidth);
      maxHeight = math.max(maxHeight, boxHeight);
      child = childAfter(child);
    }

    constraints.constrainHeight(maxHeight);

    final BoxConstraints childConstraints = BoxConstraints.tightFor(
      width: childWidth,
      height: maxHeight,
    );

    // Layout children.
    child = firstChild;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      child = childAfter(child);
    }

    double start = 0.0;
    child = firstChild;

    while (child != null) {
      final _SegmentedControlContainerBoxParentData childParentData = child.parentData;
      final Offset childOffset = Offset(start, 0.0);
      childParentData.offset = childOffset;
      start += child.size.width + _kSeparatorWidth + _kSeparatorInset.horizontal;
      child = childAfter(child);
    }

    size = constraints.constrain(Size(childWidth * childCount + totalSeparatorWidth, maxHeight));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final List<RenderBox> children = getChildrenAsList();

    // Paint thumb if highlightedIndex is not null.
    if (highlightedIndex != null) {
      if (childAnimations == null) {
        childAnimations = <RenderBox, _ChildAnimationManifest> { };
        for (int i = 0; i < childCount - 1; i++) {
          // The separator associated with the last child will not be painted (unless
          // a new trailing segment is added), and its opacity will always be 1.
          final bool shouldFadeOut = i == highlightedIndex || i == highlightedIndex - 1;
          final RenderBox child = children[i];
          childAnimations[child] = _ChildAnimationManifest(separatorOpacity: shouldFadeOut ? 0 : 1);
        }
      }

      final RenderBox selectedChild = children[highlightedIndex];

      final _SegmentedControlContainerBoxParentData childParentData = selectedChild.parentData;
      final Rect unscaledThumbTargetRect = _kThumbInsets.inflateRect(childParentData.offset & selectedChild.size);

      // Update related Tweens before animation update phase.
      if (_needsThumbAnimationUpdate) {
        // Needs to ensure _currentThumbRect is valid.
        currentThumbTween = RectTween(begin: currentThumbRect ?? unscaledThumbTargetRect, end: unscaledThumbTargetRect);

        for (int i = 0; i < childCount - 1; i++) {
          // The separator associated with the last child will not be painted (unless
          // a new segment is appended to the child list), and its opacity will always be 1.
          final bool shouldFadeOut = i == highlightedIndex || i == highlightedIndex - 1;
          final RenderBox child = children[i];
          final _ChildAnimationManifest manifest = childAnimations[child];
          assert(manifest != null);
          manifest.separatorTween = Tween<double>(
            begin: manifest.separatorOpacity,
            end: shouldFadeOut ? 0 : 1,
          );
        }

        _needsThumbAnimationUpdate = false;
      }

      for (int index = 0; index < childCount - 1; index++) {
        _paintSeparator(context, offset, children[index]);
      }

      currentThumbRect = currentThumbTween?.evaluate(thumbController)
                        ?? unscaledThumbTargetRect;

      currentThumbScale = thumbScaleTween.evaluate(thumbScaleController);

      final Rect thumbRect = Rect.fromCenter(
        center: currentThumbRect.center,
        width: currentThumbRect.width * currentThumbScale,
        height: currentThumbRect.height * currentThumbScale,
      );

      _paintThumb(context, offset, thumbRect);
    } else {
      // Reset all animations when there's no thumb.
      currentThumbRect = null;
      childAnimations = null;

      // Paint separators.
      for (int index = 0; index < childCount - 1; index++) {
        _paintSeparator(context, offset, children[index]);
      }
    }


    for (int index = 0; index < children.length; index++) {
      _paintChild(context, offset, children[index], index);
    }
  }

  // Paint the separator to the right of the given child.
  void _paintSeparator(PaintingContext context, Offset offset, RenderBox child) {
    assert(child != null);
    final _SegmentedControlContainerBoxParentData childParentData = child.parentData;

    final Paint paint = Paint();

    final _ChildAnimationManifest manifest = childAnimations == null ? null : childAnimations[child];
    final double opacity = manifest?.separatorTween?.evaluate(separatorOpacityController) ?? 1;
    manifest?.separatorOpacity = opacity;
    paint.color = _kSeparatorColor.withOpacity(_kSeparatorColor.opacity * opacity);

    final Rect childRect = (childParentData.offset + offset) & child.size;
    final Rect separatorRect = _kSeparatorInset.deflateRect(
      childRect.topRight & Size(_kSeparatorInset.horizontal + _kSeparatorWidth, child.size.height),
    );

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(separatorRect, _kSeparatorRadius),
      paint,
    );
  }

  void _paintChild(PaintingContext context, Offset offset, RenderBox child, int childIndex) {
    assert(child != null);
    final _SegmentedControlContainerBoxParentData childParentData = child.parentData;
    context.paintChild(child, childParentData.offset + offset);
  }

  void _paintThumb(PaintingContext context, Offset offset, Rect thumbRect) {
    // Colors extracted from https://developer.apple.com/design/resources/.
    const List<BoxShadow> thumbShadow = <BoxShadow> [
      BoxShadow(
        color: Color(0x1F000000),
        offset: Offset(0, 3),
        blurRadius: 8,
      ),
      BoxShadow(
        color: Color(0x0A000000),
        offset: Offset(0, 3),
        blurRadius: 1,
      ),
    ];

    final RRect thumbRRect = RRect.fromRectAndRadius(
      thumbRect.shift(offset),
      const Radius.circular(_kThumbCornerRadius),
    );

    for (BoxShadow shadow in thumbShadow) {
      context.canvas.drawRRect(
        thumbRRect.shift(shadow.offset),
        shadow.toPaint(),
      );
    }

    context.canvas.drawRRect(
      thumbRRect.inflate(0.5),
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0x0A000000),
    );

    context.canvas.drawRRect(
      thumbRRect,
      Paint()
        ..style = PaintingStyle.fill
        ..color = thumbColor,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { @required Offset position }) {
    assert(position != null);
    RenderBox child = lastChild;
    while (child != null) {
      final _SegmentedControlContainerBoxParentData childParentData = child.parentData;
      if ((childParentData.offset & child.size).contains(position)) {
        final Offset center = (Offset.zero & child.size).center;
        return result.addWithRawTransform(
          transform: MatrixUtils.forceToPoint(center),
          position: center,
          hitTest: (BoxHitTestResult result, Offset position) {
            assert(position == center);
            return child.hitTest(result, position: center);
          },
        );
      }
      child = childParentData.previousSibling;
    }
    return false;
  }
}
