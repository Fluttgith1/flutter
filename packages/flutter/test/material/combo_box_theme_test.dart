// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ComboBoxThemeData copyWith, ==, hashCode basics', () {
    expect(const ComboBoxThemeData(), const ComboBoxThemeData().copyWith());
    expect(const ComboBoxThemeData().hashCode, const ComboBoxThemeData().copyWith().hashCode);

    const ComboBoxThemeData custom = ComboBoxThemeData(
      menuStyle: MenuStyle(backgroundColor: MaterialStatePropertyAll<Color>(Colors.green)),
      inputDecorationTheme: InputDecorationTheme(filled: true),
      textStyle: TextStyle(fontSize: 25.0),
    );
    final ComboBoxThemeData copy = const ComboBoxThemeData().copyWith(
      menuStyle: custom.menuStyle,
      inputDecorationTheme: custom.inputDecorationTheme,
      textStyle: custom.textStyle,
    );
    expect(copy, custom);
  });

  testWidgets('Default ComboBoxThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const ComboBoxThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });

  testWidgets('With no other configuration, defaults are used', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    await tester.pumpWidget(
      MaterialApp(
        theme: themeData,
        home: const Scaffold(
          body: Center(
            child: ComboBox(
              comboBoxEntries: <ComboBoxEntry>[
                ComboBoxEntry(label: 'Item 0'),
                ComboBoxEntry(label: 'Item 1'),
                ComboBoxEntry(label: 'Item 2'),
              ],
            ),
          ),
        ),
      )
    );

    final EditableText editableText = tester.widget(find.byType(EditableText));
    expect(editableText.style.color, themeData.textTheme.labelLarge!.color);
    expect(editableText.style.background, themeData.textTheme.labelLarge!.background);
    expect(editableText.style.shadows, themeData.textTheme.labelLarge!.shadows);
    expect(editableText.style.decoration, themeData.textTheme.labelLarge!.decoration);
    expect(editableText.style.locale, themeData.textTheme.labelLarge!.locale);
    expect(editableText.style.wordSpacing, themeData.textTheme.labelLarge!.wordSpacing);

    final TextField textField = tester.widget(find.byType(TextField));
    expect(textField.decoration?.border, const OutlineInputBorder());

    await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_drop_down).first);
    await tester.pump();
    expect(find.byType(MenuAnchor), findsOneWidget);

    final Finder menuMaterial = find.ancestor(
      of: find.widgetWithText(TextButton, 'Item 0'),
      matching: find.byType(Material),
    ).last;
    Material material = tester.widget<Material>(menuMaterial);
    expect(material.color, themeData.colorScheme.surface);
    expect(material.shadowColor, themeData.colorScheme.shadow);
    expect(material.surfaceTintColor, themeData.colorScheme.surfaceTint);
    expect(material.elevation, 3.0);
    expect(material.shape, const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))));

    final Finder buttonMaterial = find.descendant(
      of: find.widgetWithText(TextButton, 'Item 0'),
      matching: find.byType(Material),
    ).last;

    material = tester.widget<Material>(buttonMaterial);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shape, const RoundedRectangleBorder());
    expect(material.textStyle?.color, themeData.colorScheme.onSurface);
  });

  testWidgets('ThemeData.comboBoxTheme overrides defaults', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(
      comboBoxTheme: ComboBoxThemeData(
        textStyle: TextStyle(
          color: Colors.orange,
          backgroundColor: Colors.indigo,
          fontSize: 30.0,
          shadows: kElevationToShadow[1],
          decoration: TextDecoration.underline,
          wordSpacing: 2.0,
        ),
        menuStyle: const MenuStyle(
          backgroundColor: MaterialStatePropertyAll<Color>(Colors.grey),
          shadowColor: MaterialStatePropertyAll<Color>(Colors.brown),
          surfaceTintColor: MaterialStatePropertyAll<Color>(Colors.amberAccent),
          elevation: MaterialStatePropertyAll<double>(10.0),
          shape: MaterialStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: Colors.lightGreen),
      )
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: Center(
            child: ComboBox(
              comboBoxEntries: <ComboBoxEntry>[
                ComboBoxEntry(label: 'Item 0'),
                ComboBoxEntry(label: 'Item 1'),
                ComboBoxEntry(label: 'Item 2'),
              ],
            ),
          ),
        )
      )
    );

    final EditableText editableText = tester.widget(find.byType(EditableText));
    expect(editableText.style.color, Colors.orange);
    expect(editableText.style.backgroundColor, Colors.indigo);
    expect(editableText.style.shadows, kElevationToShadow[1]);
    expect(editableText.style.decoration, TextDecoration.underline);
    expect(editableText.style.wordSpacing, 2.0);

    final TextField textField = tester.widget(find.byType(TextField));
    expect(textField.decoration?.filled, isTrue);
    expect(textField.decoration?.fillColor, Colors.lightGreen);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_drop_down).first);
    await tester.pump();
    expect(find.byType(MenuAnchor), findsOneWidget);

    final Finder menuMaterial = find.ancestor(
      of: find.widgetWithText(TextButton, 'Item 0'),
      matching: find.byType(Material),
    ).last;
    Material material = tester.widget<Material>(menuMaterial);
    expect(material.color, Colors.grey);
    expect(material.shadowColor, Colors.brown);
    expect(material.surfaceTintColor, Colors.amberAccent);
    expect(material.elevation, 10.0);
    expect(material.shape, const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))));

    final Finder buttonMaterial = find.descendant(
      of: find.widgetWithText(TextButton, 'Item 0'),
      matching: find.byType(Material),
    ).last;

    material = tester.widget<Material>(buttonMaterial);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shape, const RoundedRectangleBorder());
    expect(material.textStyle?.color, theme.colorScheme.onSurface);
  });

  testWidgets('ComboBoxTheme overrides ThemeData and defaults', (WidgetTester tester) async {
    final ComboBoxThemeData global = ComboBoxThemeData(
      textStyle: TextStyle(
        color: Colors.orange,
        backgroundColor: Colors.indigo,
        fontSize: 30.0,
        shadows: kElevationToShadow[1],
        decoration: TextDecoration.underline,
        wordSpacing: 2.0,
      ),
      menuStyle: const MenuStyle(
        backgroundColor: MaterialStatePropertyAll<Color>(Colors.grey),
        shadowColor: MaterialStatePropertyAll<Color>(Colors.brown),
        surfaceTintColor: MaterialStatePropertyAll<Color>(Colors.amberAccent),
        elevation: MaterialStatePropertyAll<double>(10.0),
        shape: MaterialStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: Colors.lightGreen),
    );

    final ComboBoxThemeData comboBoxTheme = ComboBoxThemeData(
      textStyle: TextStyle(
        color: Colors.red,
        backgroundColor: Colors.orange,
        fontSize: 27.0,
        shadows: kElevationToShadow[2],
        decoration: TextDecoration.lineThrough,
        wordSpacing: 5.0,
      ),
      menuStyle: const MenuStyle(
        backgroundColor: MaterialStatePropertyAll<Color>(Colors.yellow),
        shadowColor: MaterialStatePropertyAll<Color>(Colors.green),
        surfaceTintColor: MaterialStatePropertyAll<Color>(Colors.teal),
        elevation: MaterialStatePropertyAll<double>(15.0),
        shape: MaterialStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: Colors.blue),
    );

    final ThemeData theme = ThemeData(comboBoxTheme: global);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: ComboBoxTheme(
          data: comboBoxTheme,
          child: const Scaffold(
            body: Center(
              child: ComboBox(
                comboBoxEntries: <ComboBoxEntry>[
                  ComboBoxEntry(label: 'Item 0'),
                  ComboBoxEntry(label: 'Item 1'),
                  ComboBoxEntry(label: 'Item 2'),
                ],
              ),
            ),
          ),
        )
      )
    );

    final EditableText editableText = tester.widget(find.byType(EditableText));
    expect(editableText.style.color, Colors.red);
    expect(editableText.style.backgroundColor, Colors.orange);
    expect(editableText.style.fontSize, 27.0);
    expect(editableText.style.shadows, kElevationToShadow[2]);
    expect(editableText.style.decoration, TextDecoration.lineThrough);
    expect(editableText.style.wordSpacing, 5.0);

    final TextField textField = tester.widget(find.byType(TextField));
    expect(textField.decoration?.filled, isTrue);
    expect(textField.decoration?.fillColor, Colors.blue);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_drop_down).first);
    await tester.pump();
    expect(find.byType(MenuAnchor), findsOneWidget);

    final Finder menuMaterial = find.ancestor(
      of: find.widgetWithText(TextButton, 'Item 0'),
      matching: find.byType(Material),
    ).last;
    Material material = tester.widget<Material>(menuMaterial);
    expect(material.color, Colors.yellow);
    expect(material.shadowColor, Colors.green);
    expect(material.surfaceTintColor, Colors.teal);
    expect(material.elevation, 15.0);
    expect(material.shape, const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))));

    final Finder buttonMaterial = find.descendant(
      of: find.widgetWithText(TextButton, 'Item 0'),
      matching: find.byType(Material),
    ).last;

    material = tester.widget<Material>(buttonMaterial);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shape, const RoundedRectangleBorder());
    expect(material.textStyle?.color, theme.colorScheme.onSurface);
  });

  testWidgets('Widget parameters overrides ComboBoxTheme, ThemeData and defaults', (WidgetTester tester) async {
    final ComboBoxThemeData global = ComboBoxThemeData(
      textStyle: TextStyle(
        color: Colors.orange,
        backgroundColor: Colors.indigo,
        fontSize: 30.0,
        shadows: kElevationToShadow[1],
        decoration: TextDecoration.underline,
        wordSpacing: 2.0,
      ),
      menuStyle: const MenuStyle(
        backgroundColor: MaterialStatePropertyAll<Color>(Colors.grey),
        shadowColor: MaterialStatePropertyAll<Color>(Colors.brown),
        surfaceTintColor: MaterialStatePropertyAll<Color>(Colors.amberAccent),
        elevation: MaterialStatePropertyAll<double>(10.0),
        shape: MaterialStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: Colors.lightGreen),
    );

    final ComboBoxThemeData comboBoxTheme = ComboBoxThemeData(
      textStyle: TextStyle(
        color: Colors.red,
        backgroundColor: Colors.orange,
        fontSize: 27.0,
        shadows: kElevationToShadow[2],
        decoration: TextDecoration.lineThrough,
        wordSpacing: 5.0,
      ),
      menuStyle: const MenuStyle(
        backgroundColor: MaterialStatePropertyAll<Color>(Colors.yellow),
        shadowColor: MaterialStatePropertyAll<Color>(Colors.green),
        surfaceTintColor: MaterialStatePropertyAll<Color>(Colors.teal),
        elevation: MaterialStatePropertyAll<double>(15.0),
        shape: MaterialStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: Colors.blue),
    );

    final ThemeData theme = ThemeData(comboBoxTheme: global);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: ComboBoxTheme(
          data: comboBoxTheme,
          child: Scaffold(
            body: Center(
              child: ComboBox(
                textStyle: TextStyle(
                  color: Colors.pink,
                  backgroundColor: Colors.cyan,
                  fontSize: 32.0,
                  shadows: kElevationToShadow[3],
                  decoration: TextDecoration.overline,
                  wordSpacing: 3.0,
                ),
                menuStyle: const MenuStyle(
                  backgroundColor: MaterialStatePropertyAll<Color>(Colors.limeAccent),
                  shadowColor: MaterialStatePropertyAll<Color>(Colors.deepOrangeAccent),
                  surfaceTintColor: MaterialStatePropertyAll<Color>(Colors.lightBlue),
                  elevation: MaterialStatePropertyAll<double>(21.0),
                  shape: MaterialStatePropertyAll<OutlinedBorder>(
                    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15.0))),
                  ),
                ),
                inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: Colors.deepPurple),
                comboBoxEntries: const <ComboBoxEntry>[
                  ComboBoxEntry(label: 'Item 0'),
                  ComboBoxEntry(label: 'Item 1'),
                  ComboBoxEntry(label: 'Item 2'),
                ],
              ),
            ),
          ),
        )
      )
    );

    final EditableText editableText = tester.widget(find.byType(EditableText));
    expect(editableText.style.color, Colors.pink);
    expect(editableText.style.backgroundColor, Colors.cyan);
    expect(editableText.style.fontSize, 32.0);
    expect(editableText.style.shadows, kElevationToShadow[3]);
    expect(editableText.style.decoration, TextDecoration.overline);
    expect(editableText.style.wordSpacing, 3.0);

    final TextField textField = tester.widget(find.byType(TextField));
    expect(textField.decoration?.filled, isTrue);
    expect(textField.decoration?.fillColor, Colors.deepPurple);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_drop_down).first);
    await tester.pump();
    expect(find.byType(MenuAnchor), findsOneWidget);

    final Finder menuMaterial = find.ancestor(
      of: find.widgetWithText(TextButton, 'Item 0'),
      matching: find.byType(Material),
    ).last;
    Material material = tester.widget<Material>(menuMaterial);
    expect(material.color, Colors.limeAccent);
    expect(material.shadowColor, Colors.deepOrangeAccent);
    expect(material.surfaceTintColor, Colors.lightBlue);
    expect(material.elevation, 21.0);
    expect(material.shape, const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15.0))));

    final Finder buttonMaterial = find.descendant(
      of: find.widgetWithText(TextButton, 'Item 0'),
      matching: find.byType(Material),
    ).last;

    material = tester.widget<Material>(buttonMaterial);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shape, const RoundedRectangleBorder());
    expect(material.textStyle?.color, theme.colorScheme.onSurface);
  });
}
