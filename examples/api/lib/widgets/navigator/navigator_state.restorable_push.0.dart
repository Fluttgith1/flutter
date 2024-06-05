// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [NavigatorState.restorablePush].

void main() => runApp(const RestorablePushExampleApp());

class RestorablePushExampleApp extends StatelessWidget {
  const RestorablePushExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: RestorablePushExample(),
    );
  }
}

class RestorablePushExample extends StatefulWidget {
  const RestorablePushExample({super.key});

  @override
  State<RestorablePushExample> createState() => _RestorablePushExampleState();
}

class _RestorablePushExampleState extends State<RestorablePushExample> {
  @pragma('vm:entry-point')
  static Route<void> _myRouteBuilder(BuildContext context, Object? arguments) {
    return MaterialPageRoute<void>(
      builder: (BuildContext context) => const RestorablePushExample(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBar(
        title: Text('Sample Code'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).restorablePush(_myRouteBuilder),
        tooltip: 'Increment Counter',
        child: const Icon(Icons.add),
      ),
    );
  }
}
