// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [InputDecoration].

void main() => runApp(const MaterialStateExampleApp());

class MaterialStateExampleApp extends StatelessWidget {
  const MaterialStateExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const Scaffold(
        appBar: AppBar(title: Text('InputDecoration Sample')),
        body: MaterialStateExample(),
      ),
    );
  }
}

class MaterialStateExample extends StatelessWidget {
  const MaterialStateExample({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return Theme(
      data: themeData.copyWith(
        inputDecorationTheme: themeData.inputDecorationTheme.copyWith(
          prefixIconColor: WidgetStateColor.resolveWith(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.error)) {
                return Colors.red;
              }
              if (states.contains(WidgetState.focused)) {
                return Colors.blue;
              }
              return Colors.grey;
            },
          ),
        ),
      ),
      child: TextFormField(
        initialValue: 'example.com',
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.web),
        ),
          autovalidateMode: AutovalidateMode.always,
          validator: (String? text) {
            if (text?.endsWith('.com') ?? false) {
              return null;
            }
            return 'No .com tld';
          }
      ),
    );
  }
}
