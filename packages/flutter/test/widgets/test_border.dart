import 'package:flutter/material.dart';

typedef Logger = void Function(String caller);

class TestBorder extends ShapeBorder {
  const TestBorder(this.onLog) : assert(onLog != null);

  final Logger onLog;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsetsDirectional.only(start: 1.0);

  @override
  ShapeBorder scale(double t) => TestBorder(onLog);

  @override
  Path getInnerPath(Rect rect, { TextDirection textDirection }) {
    onLog('getInnerPath $rect $textDirection');
    return Path();
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection textDirection }) {
    onLog('getOuterPath $rect $textDirection');
    return Path();
  }

  @override
  void paint(Canvas canvas, Rect rect, { TextDirection textDirection }) {
    onLog('paint $rect $textDirection');
  }
}

