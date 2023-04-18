// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [TweenAnimationBuilder].

void main() => runApp(const TweenAnimationBuilderExampleApp());

class TweenAnimationBuilderExampleApp extends StatelessWidget {
  const TweenAnimationBuilderExampleApp({super.key});

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('TweenAnimationBuilder Sample')),
        body: const Center(
          child: TweenAnimationBuilderExample(),
        ),
      ),
    );
  }
}

class TweenAnimationBuilderExample extends StatefulWidget {
  const TweenAnimationBuilderExample({super.key});

  @override
  State<TweenAnimationBuilderExample> createState() => _TweenAnimationBuilderExampleState();
}

class _TweenAnimationBuilderExampleState extends State<TweenAnimationBuilderExample> {
  double targetValue = 24.0;

  @override
  Widget build(final BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: targetValue),
      duration: const Duration(seconds: 1),
      builder: (final BuildContext context, final double size, final Widget? child) {
        return IconButton(
          iconSize: size,
          color: Colors.blue,
          icon: child!,
          onPressed: () {
            setState(() {
              targetValue = targetValue == 24.0 ? 48.0 : 24.0;
            });
          },
        );
      },
      child: const Icon(Icons.aspect_ratio),
    );
  }
}
