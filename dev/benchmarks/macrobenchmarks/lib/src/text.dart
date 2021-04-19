// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class TextPage extends StatelessWidget {
  const TextPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: const <Widget>[
          SizedBox(
            width: 200,
            height: 100,
            child: TextField(
              key: Key('basic-textfield'),
            ),
          ),
        ],
      ),
    );
  }
}
