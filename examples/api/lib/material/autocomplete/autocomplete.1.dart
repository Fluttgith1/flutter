// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [Autocomplete].

void main() => runApp(const AutocompleteExampleApp());

class AutocompleteExampleApp extends StatelessWidget {
  const AutocompleteExampleApp({super.key});

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Autocomplete Basic User'),
        ),
        body: const Center(
          child: AutocompleteBasicUserExample(),
        ),
      ),
    );
  }
}

@immutable
class User {
  const User({
    required this.email,
    required this.name,
  });

  final String email;
  final String name;

  @override
  String toString() {
    return '$name, $email';
  }

  @override
  bool operator ==(final Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is User && other.name == name && other.email == email;
  }

  @override
  int get hashCode => Object.hash(email, name);
}

class AutocompleteBasicUserExample extends StatelessWidget {
  const AutocompleteBasicUserExample({super.key});

  static const List<User> _userOptions = <User>[
    User(name: 'Alice', email: 'alice@example.com'),
    User(name: 'Bob', email: 'bob@example.com'),
    User(name: 'Charlie', email: 'charlie123@gmail.com'),
  ];

  static String _displayStringForOption(final User option) => option.name;

  @override
  Widget build(final BuildContext context) {
    return Autocomplete<User>(
      displayStringForOption: _displayStringForOption,
      optionsBuilder: (final TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<User>.empty();
        }
        return _userOptions.where((final User option) {
          return option.toString().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (final User selection) {
        debugPrint('You just selected ${_displayStringForOption(selection)}');
      },
    );
  }
}
