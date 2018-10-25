// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/src/material/dialog_theme.dart';
import 'package:flutter_test/flutter_test.dart';

MaterialApp _appWithAlertDialog(WidgetTester tester, AlertDialog dialog, {ThemeData theme}) {
  return MaterialApp(
    theme: theme,
    home: Material(
        child: Builder(
            builder: (BuildContext context) {
              return Center(
                  child: RaisedButton(
                      child: const Text('X'),
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (BuildContext context) {
                            return dialog;
                          },
                        );
                      }
                  )
              );
            }
        )
    ),
  );
}

void main() {
  testWidgets('Custom dialog shape', (WidgetTester tester) async {
    const RoundedRectangleBorder customBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0)));
    const AlertDialog dialog = AlertDialog(
      title: Text('Title'),
      actions: <Widget>[ ],
    );
    final ThemeData theme = ThemeData(dialogTheme: const DialogTheme(shape: customBorder));

    await tester.pumpWidget(
      _appWithAlertDialog(tester, dialog, theme: theme)
    );
    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1));

    final StatefulElement widget = tester.element(
        find.descendant(of: find.byType(AlertDialog), matching: find.byType(Material)));
    final Material materialWidget = widget.state.widget;
    expect(materialWidget.shape, customBorder);
  });
}