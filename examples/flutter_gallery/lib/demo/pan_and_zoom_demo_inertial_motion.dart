import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' show Vector2;

// Provides calculations for an object moving with inertia and friction.
class InertialMotion {
  InertialMotion(this._initialVelocity, this._initialPosition);

  static const double FRICTIONAL_ACCELERATION = 0.01; // How quickly to stop
  Velocity _initialVelocity;
  Point<double> _initialPosition;

  // The position when the motion stops.
  Point<double> get finalPosition {
    return _getPositionAt(Duration(milliseconds: duration.toInt()));
  }

  // Get the total time that the animation takes to stop
  double get duration {
    return (_initialVelocity.pixelsPerSecond.dx / 1000 / _acceleration.x).abs();
  }

  // The acceleration opposing the initial velocity.
  Vector2 get _acceleration {
    final double velocityTotal = _initialVelocity.pixelsPerSecond.dx.abs() + _initialVelocity.pixelsPerSecond.dy.abs();
    final double vRatioX = _initialVelocity.pixelsPerSecond.dx.abs() / velocityTotal;
    final double vRatioY = _initialVelocity.pixelsPerSecond.dy.abs() / velocityTotal;
    final double vSignX = _initialVelocity.pixelsPerSecond.dx.isNegative ? 1 : -1;
    final double vSignY = _initialVelocity.pixelsPerSecond.dy.isNegative ? 1 : -1;
    return Vector2(
      vSignX * FRICTIONAL_ACCELERATION * vRatioX,
      vSignY * FRICTIONAL_ACCELERATION * vRatioY,
    );
  }

  // The position at a given time
  Point<double> _getPositionAt(Duration time) {
    final double xf = _getPosition(
      r0: _initialPosition.x,
      v0: _initialVelocity.pixelsPerSecond.dx / 1000,
      t: time.inMilliseconds,
      a: _acceleration.x,
    );
    final double yf = _getPosition(
      r0: _initialPosition.y,
      v0: _initialVelocity.pixelsPerSecond.dy / 1000,
      t: time.inMilliseconds,
      a: _acceleration.y,
    );
    return Point<double>(xf, yf);
  }

  // Physics equation of motion.
  double _getPosition({double r0, double v0, int t, double a}) {
    // Stop movement when it would otherwise reverse direction.
    final double stopTime = (v0 / a).abs();
    if (t > stopTime) {
      t = stopTime.toInt();
    }

    final double answer = r0 + v0 * t + 0.5 * a * pow(t, 2);
    return answer;
  }
}
