// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [AspectRatio].

void main() => runApp(const AspectRatioApp());

class AspectRatioApp extends StatelessWidget {
  const AspectRatioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('AspectRatio Sample')),
        body: AspectRatioExample(),
      ),
    );
  }
}

class AspectRatioExample extends StatelessWidget {
  const AspectRatioExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      alignment: Alignment.center,
      width: 100.0,
      height: 100.0,
      child: AspectRatio(
        aspectRatio: 2.0,
        child: Container(
          width: 100.0,
          height: 50.0,
          color: Colors.green,
        ),
      ),
    );
  }
}
