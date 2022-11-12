// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'scroll_activity.dart';
import 'scroll_context.dart';
import 'scroll_notification.dart';
import 'scroll_physics.dart';
import 'scroll_position.dart';

/// A scroll position that manages scroll activities for a single
/// [ScrollContext].
///
/// This class is a concrete subclass of [ScrollPosition] logic that handles a
/// single [ScrollContext], such as a [Scrollable]. An instance of this class
/// manages [ScrollActivity] instances, which change what content is visible in
/// the [Scrollable]'s [Viewport].
///
/// See also:
///
///  * [ScrollPosition], which defines the underlying model for a position
///    within a [Scrollable] but is agnostic as to how that position is
///    changed.
///  * [ScrollView] and its subclasses such as [ListView], which use
///    [ScrollPositionWithSingleContext] to manage their scroll position.
///  * [ScrollController], which can manipulate one or more [ScrollPosition]s,
///    and which uses [ScrollPositionWithSingleContext] as its default class for
///    scroll positions.
class ScrollPositionWithSingleContext extends ScrollPosition implements ScrollActivityDelegate {
  /// Create a [ScrollPosition] object that manages its behavior using
  /// [ScrollActivity] objects.
  ///
  /// The `initialPixels` argument can be null, but in that case it is
  /// imperative that the value be set, using [correctPixels], as soon as
  /// [applyNewDimensions] is invoked, before calling the inherited
  /// implementation of that method.
  ///
  /// If [keepScrollOffset] is true (the default), the current scroll offset is
  /// saved with [PageStorage] and restored it if this scroll position's scrollable
  /// is recreated.
  ScrollPositionWithSingleContext({
    required super.physics,
    required super.context,
    double? initialPixels = 0.0,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  }) {
    // If oldPosition is not null, the superclass will first call absorb(),
    // which may set _pixels and _activity.
    if (!hasPixels && initialPixels != null) {
      correctPixels(initialPixels);
    }
    if (activity == null) {
      goIdle();
    }
    assert(activity != null);
  }

  /// Velocity from a previous activity temporarily held by [hold] to potentially
  /// transfer to a next activity.
  double _heldPreviousVelocity = 0.0;

  @override
  AxisDirection get axisDirection => context.axisDirection;

  @override
  double setPixels(double newPixels) {
    assert(activity!.isScrolling);
    return super.setPixels(newPixels);
  }

  @override
  void absorb(ScrollPosition other) {
    super.absorb(other);
    if (other is! ScrollPositionWithSingleContext) {
      goIdle();
      return;
    }
    activity!.updateDelegate(this);
    _userScrollDirection = other._userScrollDirection;
    assert(_currentDrag == null);
    if (other._currentDrag != null) {
      _currentDrag = other._currentDrag;
      _currentDrag!.updateDelegate(this);
      other._currentDrag = null;
    }
  }

  @override
  void applyNewDimensions() {
    super.applyNewDimensions();
    context.setCanDrag(physics.shouldAcceptUserOffset(this));
  }

  @override
  void beginActivity(ScrollActivity? newActivity) {
    _heldPreviousVelocity = 0.0;
    if (newActivity == null) {
      return;
    }
    assert(newActivity.delegate == this);
    super.beginActivity(newActivity);
    _currentDrag?.dispose();
    _currentDrag = null;
    if (!activity!.isScrolling) {
      updateUserScrollDirection(ScrollDirection.idle);
    }
  }

  @override
  void applyUserOffset(double delta) {
    updateUserScrollDirection(delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    setPixels(pixels - physics.applyPhysicsToUserOffset(this, delta));
  }

  @override
  void goIdle() {
    beginActivity(IdleScrollActivity(this));
  }

  /// Start a physics-driven simulation that settles the [pixels] position,
  /// starting at a particular velocity.
  ///
  /// This method defers to [ScrollPhysics.createBallisticSimulation], which
  /// typically provides a bounce simulation when the current position is out of
  /// bounds and a friction simulation when the position is in bounds but has a
  /// non-zero velocity.
  ///
  /// The velocity should be in logical pixels per second.
  @override
  void goBallistic(double velocity) {
    assert(hasPixels);
    final Simulation? simulation = physics.createBallisticSimulation(this, velocity);
    if (simulation != null) {
      beginActivity(BallisticScrollActivity(
        this,
        simulation,
        context.vsync,
        activity?.shouldIgnorePointer ?? true,
      ));
    } else {
      goIdle();
    }
  }

  @override
  ScrollDirection get userScrollDirection => _userScrollDirection;
  ScrollDirection _userScrollDirection = ScrollDirection.idle;

  /// Set [userScrollDirection] to the given value.
  ///
  /// If this changes the value, then a [UserScrollNotification] is dispatched.
  @protected
  @visibleForTesting
  void updateUserScrollDirection(ScrollDirection value) {
    assert(value != null);
    if (userScrollDirection == value) {
      return;
    }
    _userScrollDirection = value;
    didUpdateScrollDirection(value);
  }

  @override
  Future<void> animateTo(
    double to, {
    required Duration duration,
    required Curve curve,
  }) {
    if (nearEqual(to, pixels, physics.tolerance.distance)) {
      // Skip the animation, go straight to the position as we are already close.
      jumpTo(to);
      return Future<void>.value();
    }

    final DrivenScrollActivity activity = DrivenScrollActivity(
      this,
      from: pixels,
      to: to,
      duration: duration,
      curve: curve,
      vsync: context.vsync,
    );
    beginActivity(activity);
    return activity.done;
  }

  @override
  void jumpTo(double value) {
    goIdle();
    if (pixels != value) {
      final double oldPixels = pixels;
      forcePixels(value);
      didStartScroll();
      didUpdateScrollPositionBy(pixels - oldPixels);
      didEndScroll();
    }
    goBallistic(0.0);
  }

  double accumulatedDelta = 0;

  @override
  void pointerScroll(double delta) {
    // If an update is made to pointer scrolling here, consider if the same
    // (or similar) change should be made in
    // _NestedScrollCoordinator.pointerScroll.
    assert(delta != 0.0);

    final double targetPixels = math.min(
      math.max(pixels + delta, minScrollExtent),
      maxScrollExtent,
    );
    accumulatedDelta += delta;
    if (targetPixels != pixels && physics.shouldAcceptPointerOffset(this, accumulatedDelta)) {
      // Reset the accumulator if the delta has been accepted.
      accumulatedDelta = 0.0;
      // The position should change.

      // Call on the ScrollConfiguration to see if we should use the smoothing opt-in
      // if (ScrollConfiguration.of(context).animatePointerScroll) {
      //
      // } else {
      //
      // }


      // OG
      // goIdle();
      // updateUserScrollDirection(
      //     -delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse,
      // );
      // final double oldPixels = pixels;
      // Set the notifier before calling force pixels.
      // This is set to false again after going ballistic below.
      // isScrollingNotifier.value = true;
      // forcePixels(targetPixels);
      // didStartScroll();
      // didUpdateScrollPositionBy(pixels - oldPixels);
      // didEndScroll();
      // goBallistic(0.0);

      // Smooth Algorithm
      _goSmoothly(delta, targetPixels);
    }
  }

  // Durations are in milliseconds
  static const double _pointerAnimationMinDuration = 100.0;
  static const double _pointerAnimationMaxDuration = 200;
  static const double _pointerAnimationSlope = -6.0 / 360.0;
  static const double _pointerAnimationOffset = _pointerAnimationMaxDuration - 120.0 * _pointerAnimationSlope;
  bool _animating = false;
  double _lastVelocity = 0.0;

  double _durationForDelta(double delta) {
    final double computedDuration = _pointerAnimationOffset + delta.abs() * _pointerAnimationSlope;
    final double clampedDuration = clampDouble(
      computedDuration / 60 * 1000,
      _pointerAnimationMinDuration,
      _pointerAnimationMaxDuration,
    );
    return clampedDuration;
  }

  void _goSmoothly(double delta, double newTargetPixels) {
    if (!_animating) {
      // Initiate a new animation.
      final double duration = _durationForDelta(delta);
      _lastVelocity = delta / duration;
      _animating = true;
      moveTo(
        newTargetPixels,
        duration: Duration(milliseconds: duration.round()),
        curve: Curves.easeInOut,
      ).whenComplete(() => _animating = false );
    } else {
      // We are already animating.
      // Create a new animation to the new target, incorporating the one already
      // underway
      // moveTo already handles these conditions:
      // 1. If the target is the same, don't update
      // 2. If the current position is close to the new target, stop animating.

      // Compute the delta-based duration for the new input
      final double newDuration = _durationForDelta(delta);
      final double newVelocity = delta / newDuration;
      final double compositedVelocity = newVelocity + _lastVelocity;
      final double updatedDuration = clampDouble(
        delta / compositedVelocity,
        _pointerAnimationMinDuration,
        _pointerAnimationMaxDuration,
      );
      _lastVelocity = compositedVelocity;
      _animating = true;
      moveTo(
        newTargetPixels,
        duration: Duration(milliseconds: updatedDuration.round()),
        curve: Curves.easeInOut,
      ).whenComplete(() => _animating = false );
    }
  }


  @Deprecated('This will lead to bugs.') // flutter_ignore: deprecation_syntax, https://github.com/flutter/flutter/issues/44609
  @override
  void jumpToWithoutSettling(double value) {
    goIdle();
    if (pixels != value) {
      final double oldPixels = pixels;
      forcePixels(value);
      didStartScroll();
      didUpdateScrollPositionBy(pixels - oldPixels);
      didEndScroll();
    }
  }

  @override
  ScrollHoldController hold(VoidCallback holdCancelCallback) {
    final double previousVelocity = activity!.velocity;
    final HoldScrollActivity holdActivity = HoldScrollActivity(
      delegate: this,
      onHoldCanceled: holdCancelCallback,
    );
    beginActivity(holdActivity);
    _heldPreviousVelocity = previousVelocity;
    return holdActivity;
  }

  ScrollDragController? _currentDrag;

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    final ScrollDragController drag = ScrollDragController(
      delegate: this,
      details: details,
      onDragCanceled: dragCancelCallback,
      carriedVelocity: physics.carriedMomentum(_heldPreviousVelocity),
      motionStartDistanceThreshold: physics.dragStartDistanceMotionThreshold,
    );
    beginActivity(DragScrollActivity(this, drag));
    assert(_currentDrag == null);
    _currentDrag = drag;
    return drag;
  }

  @override
  void dispose() {
    _currentDrag?.dispose();
    _currentDrag = null;
    super.dispose();
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('${context.runtimeType}');
    description.add('$physics');
    description.add('$activity');
    description.add('$userScrollDirection');
  }
}
