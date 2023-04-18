// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/widgets.dart';

/// Flutter code sample for [FontFeature.FontFeature.denominator].

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(final BuildContext context) {
    return WidgetsApp(
      builder: (final BuildContext context, final Widget? navigator) => const ExampleWidget(),
      color: const Color(0xffffffff),
    );
  }
}

class ExampleWidget extends StatelessWidget {
  const ExampleWidget({super.key});

  @override
  Widget build(final BuildContext context) {
    // The Piazzolla font can be downloaded from Google Fonts
    // (https://www.google.com/fonts).
    return const Text(
      'Fractions: 1/2 2/3 3/4 4/5',
      style: TextStyle(
        fontFamily: 'Piazzolla',
        fontFeatures: <FontFeature>[
          FontFeature.denominator(),
        ],
      ),
    );
  }
}
