// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PopupMenuThemeData copyWith, ==, hashCode basics', () {
    expect(const PopupMenuThemeData(),
        const PopupMenuThemeData().copyWith());
    expect(const PopupMenuThemeData().hashCode,
        const PopupMenuThemeData().copyWith().hashCode);
  });

  test('PopupMenuThemeData null fields by default', () {
    const PopupMenuThemeData popupMenuTheme =
        PopupMenuThemeData();
    expect(popupMenuTheme.color, null);
    expect(popupMenuTheme.shape, null);
    expect(popupMenuTheme.elevation, null);
    expect(popupMenuTheme.textStyle, null);
  });

  testWidgets('Default PopupMenuThemeData debugFillProperties',
      (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const PopupMenuThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });

  testWidgets('PopupMenuThemeData implements debugFillProperties',
      (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    PopupMenuThemeData(
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.0)),
      elevation: 2.0,
      textStyle: const TextStyle(color: Color(0xffffffff)),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'color: Color(0xffffffff)',
      'shape: RoundedRectangleBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none), BorderRadius.circular(2.0))',
      'elevation: 2.0',
      'text style: TextStyle(inherit: true, color: Color(0xffffffff))'
    ]);
  });

  testWidgets('Passing no PopupMenuThemeData returns defaults',
      (WidgetTester tester) async {
    final Key popupButtonKey = UniqueKey();
    final Key popupButtonApp = UniqueKey();
    final Key popupItemKey = UniqueKey();
    final ThemeData theme = ThemeData();

    await tester.pumpWidget(MaterialApp(
      theme: theme,
      key: popupButtonApp,
      home: Material(
        child: Column(
          children: <Widget>[
            PopupMenuButton<void>(
              key: popupButtonKey,
              itemBuilder: (BuildContext context) {
                final List<PopupMenuEntry<Object>> list = <PopupMenuEntry<Object>>[
                  PopupMenuItem<void>(
                    key: popupItemKey,
                    child: const Text(''),
                  ),
                ];
                return list;
              },
            ),
          ],
        ),
      ),
    ));

    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();

    final Material button = tester.widget<Material>(
      find.descendant(
            of: find.byKey(popupButtonApp),
            matching: find.byType(Material),
          )
          .last,
    );
    expect(button.color, null);
    expect(button.shape, null);
    expect(button.elevation, 8.0);

    final AnimatedDefaultTextStyle text =
        tester.widget<AnimatedDefaultTextStyle>(
      find.descendant(
            of: find.byKey(popupItemKey),
            matching: find.byType(AnimatedDefaultTextStyle),
          )
          .last,
    );
    expect(text.style.fontFamily, 'Roboto');
    expect(text.style.color, const Color(0xdd000000));
  });

  testWidgets('PopupMenuEntry uses values from PopupMenuThemeData',
      (WidgetTester tester) async {
    final PopupMenuThemeData popupMenuTheme = _popupMenuTheme();
    final Key popupButtonKey = UniqueKey();
    final Key popupButtonApp = UniqueKey();
    final Key popupItemKey = UniqueKey();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(popupMenuTheme: popupMenuTheme),
      key: popupButtonApp,
      home: Material(
        child: Column(
          children: <Widget>[
            PopupMenuButton<void>(
              key: popupButtonKey,
              itemBuilder: (BuildContext context) {
                final List<PopupMenuEntry<Object>> list = <PopupMenuEntry<Object>>[
                  PopupMenuItem<void>(
                    key: popupItemKey,
                    child: const Text(''),
                  ),
                ];
                return list;
              },
            ),
          ],
        ),
      ),
    ));

    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();

    final Material button = tester.widget<Material>(
      find.descendant(
            of: find.byKey(popupButtonApp),
            matching: find.byType(Material),
          )
          .last,
    );
    expect(button.color, popupMenuTheme.color);
    expect(button.shape, popupMenuTheme.shape);
    expect(button.elevation, popupMenuTheme.elevation);

    final AnimatedDefaultTextStyle text =
        tester.widget<AnimatedDefaultTextStyle>(
      find.descendant(
            of: find.byKey(popupItemKey),
            matching: find.byType(AnimatedDefaultTextStyle),
          )
          .last,
    );
    expect(text.style, popupMenuTheme.textStyle);
  });

  testWidgets('PopupMenuEntry widget properties take priority over theme',
      (WidgetTester tester) async {
    final PopupMenuThemeData popupMenuTheme = _popupMenuTheme();
    final Key popupButtonKey = UniqueKey();
    final Key popupButtonApp = UniqueKey();
    final Key popupItemKey = UniqueKey();

    const Color color = Colors.purple;
    const ShapeBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(9.0)),
    );
    const double elevation = 7.0;
    const TextStyle textStyle = TextStyle(color: Color(0x00000000), textBaseline: TextBaseline.alphabetic);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(popupMenuTheme: popupMenuTheme),
      key: popupButtonApp,
      home: Material(
        child: Column(
          children: <Widget>[
            PopupMenuButton<void>(
              key: popupButtonKey,
              elevation: elevation,
              color: color,
              shape: shape,
              itemBuilder: (BuildContext context) {
                final List<PopupMenuEntry<Object>> list = <PopupMenuEntry<Object>>[
                  PopupMenuItem<void>(
                    key: popupItemKey,
                    textStyle: textStyle,
                    child: const Text(''),
                  ),
                ];
                return list;
              },
            ),
          ],
        ),
      ),
    ));

    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();

    final Material button = tester.widget<Material>(
      find.descendant(
            of: find.byKey(popupButtonApp),
            matching: find.byType(Material),
          )
          .last,
    );
    expect(button.color, color);
    expect(button.shape, shape);
    expect(button.elevation, elevation);

    final AnimatedDefaultTextStyle text =
        tester.widget<AnimatedDefaultTextStyle>(
      find.descendant(
            of: find.byKey(popupItemKey),
            matching: find.byType(AnimatedDefaultTextStyle),
          )
          .last,
    );
    expect(text.style, textStyle);
  });
}

PopupMenuThemeData _popupMenuTheme() {
  return PopupMenuThemeData(
    color: Colors.orange,
    shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 12.0,
    textStyle: const TextStyle(color: Color(0xffffffff), textBaseline: TextBaseline.alphabetic),
  );
}
