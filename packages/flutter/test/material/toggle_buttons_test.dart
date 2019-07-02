// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

Widget boilerplate({Widget child}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  );
}

void main() {
  testWidgets('Initial toggle state is reflected', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            onPressed: (int index) {},
            isSelected: const <bool>[false, true],
            children: const <Widget>[
              Text('First child'),
              Text('Second child'),
            ],
          ),
        ),
      ),
    );

    final DefaultTextStyle textStyleOne = tester.firstWidget(
      find.widgetWithText(DefaultTextStyle, 'First child'),
    );
    expect(textStyleOne.style.color, theme.colorScheme.onSurface);
    final DefaultTextStyle textStyleTwo = tester.firstWidget(
      find.widgetWithText(DefaultTextStyle, 'Second child'),
    );
    expect(textStyleTwo.style.color, theme.colorScheme.primary);
  });

  testWidgets(
    'onPressed is triggered on button tap',
    (WidgetTester tester) async {
      final List<bool> _isSelected = <bool>[false, true];
      final ThemeData theme = ThemeData();
      await tester.pumpWidget(
        Material(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return boilerplate(
                child: ToggleButtons(
                  onPressed: (int index) {
                    setState(() {
                      _isSelected[index] = !_isSelected[index];
                    });
                  },
                  isSelected: _isSelected,
                  children: const <Widget>[
                    Text('First child'),
                    Text('Second child'),
                  ],
                ),
              );
            },
          ),
        ),
      );

      DefaultTextStyle textStyleOne;
      DefaultTextStyle textStyleTwo;

      expect(_isSelected[0], isFalse);
      expect(_isSelected[1], isTrue);
      textStyleOne = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyleOne.style.color, theme.colorScheme.onSurface);
      textStyleTwo = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'Second child'),
      );
      expect(textStyleTwo.style.color, theme.colorScheme.primary);

      await tester.tap(find.text('Second child'));
      await tester.pumpAndSettle();

      expect(_isSelected[0], isFalse);
      expect(_isSelected[1], isFalse);
      textStyleOne = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyleOne.style.color, theme.colorScheme.onSurface);
      textStyleTwo = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'Second child'),
      );
      expect(textStyleTwo.style.color, theme.colorScheme.onSurface);
    },
  );

  testWidgets(
    'onPressed that is null disables buttons',
    (WidgetTester tester) async {
      final List<bool> _isSelected = <bool>[false, true];
      final ThemeData theme = ThemeData();

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: _isSelected,
              children: const <Widget>[
                Text('First child'),
                Text('Second child'),
              ],
            ),
          ),
        ),
      );

      DefaultTextStyle textStyleOne;
      DefaultTextStyle textStyleTwo;

      expect(_isSelected[0], isFalse);
      expect(_isSelected[1], isTrue);
      textStyleOne = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyleOne.style.color, theme.disabledColor);
      textStyleTwo = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'Second child'),
      );
      expect(textStyleTwo.style.color, theme.disabledColor);

      await tester.tap(find.text('Second child'));
      await tester.pumpAndSettle();

      // nothing should change
      expect(_isSelected[0], isFalse);
      expect(_isSelected[1], isTrue);
      textStyleOne = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyleOne.style.color, theme.disabledColor);
      textStyleTwo = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'Second child'),
      );
      expect(textStyleTwo.style.color, theme.disabledColor);
    },
  );

  testWidgets('children property cannot be null', (WidgetTester tester) async {
    try {
      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: const <bool>[false, true],
              onPressed: (int index) {},
              children: null,
            ),
          ),
        ),
      );
      fail(
          'Should not be possible to create a toggle button with no children.');
    } on AssertionError catch (e) {
      expect(e.toString(), contains('children != null'));
    }
  });

  testWidgets(
    'isSelected property cannot be null',
    (WidgetTester tester) async {
      try {
        await tester.pumpWidget(
          Material(
            child: boilerplate(
              child: ToggleButtons(
                isSelected: null,
                onPressed: (int index) {},
                children: const <Widget>[
                  Text('First child'),
                  Text('Second child'),
                ],
              ),
            ),
          ),
        );
        fail(
            'Should not be possible to create a toggle button with no isSelected.');
      } on AssertionError catch (e) {
        expect(e.toString(), contains('isSelected != null'));
      }
    },
  );

  testWidgets(
    'children and isSelected properties have to be the same length',
    (WidgetTester tester) async {
      try {
        await tester.pumpWidget(
          Material(
            child: boilerplate(
              child: ToggleButtons(
                isSelected: const <bool>[false],
                children: const <Widget>[
                  Text('First child'),
                  Text('Second child'),
                ],
              ),
            ),
          ),
        );
        fail('Should not be possible to create a toggle button with mismatching'
            'children.length and isSelected.length.');
      } on AssertionError catch (e) {
        expect(e.toString(), contains('children.length'));
        expect(e.toString(), contains('isSelected.length'));
      }
    },
  );

  testWidgets(
    'Default text/icon colors for enabled, selected and disabled states',
    (WidgetTester tester) async {
      final ThemeData theme = ThemeData();
      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: const <bool>[false],
              onPressed: (int index) {},
              children: <Widget>[
                Row(children: const <Widget>[
                  Text('First child'),
                  Icon(Icons.check),
                ]),
              ],
            ),
          ),
        ),
      );

      DefaultTextStyle textStyle;
      IconTheme iconTheme;

      // default enabled color
      textStyle = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyle.style.color, theme.colorScheme.onSurface);
      iconTheme = tester.firstWidget(
        find.widgetWithIcon(IconTheme, Icons.check),
      );
      expect(iconTheme.data.color, theme.colorScheme.onSurface);

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: const <bool>[true],
              onPressed: (int index) {},
              children: <Widget>[
                Row(children: const <Widget>[
                  Text('First child'),
                  Icon(Icons.check),
                ]),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // default selected color
      textStyle = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyle.style.color, theme.colorScheme.primary);
      iconTheme = tester.firstWidget(
        find.widgetWithIcon(IconTheme, Icons.check),
      );
      expect(iconTheme.data.color, theme.colorScheme.primary);

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: const <bool>[true],
              children: <Widget>[
                Row(children: const <Widget>[
                  Text('First child'),
                  Icon(Icons.check),
                ]),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // default disabled color
      textStyle = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyle.style.color, theme.disabledColor);
      iconTheme = tester.firstWidget(
        find.widgetWithIcon(IconTheme, Icons.check),
      );
      expect(iconTheme.data.color, theme.disabledColor);
    },
  );

  testWidgets(
    'Custom text/icon colors for enabled, selected and disabled states',
    (WidgetTester tester) async {
      final ThemeData theme = ThemeData();
      const Color enabledColor = Colors.lime;
      const Color selectedColor = Colors.green;
      const Color disabledColor = Colors.yellow;

      // tests are ineffective if the custom colors are the same as the theme's
      expect(theme.colorScheme.onSurface, isNot(enabledColor));
      expect(theme.colorScheme.primary, isNot(selectedColor));
      expect(theme.disabledColor, isNot(disabledColor));

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              color: enabledColor,
              isSelected: const <bool>[false],
              onPressed: (int index) {},
              children: <Widget>[
                Row(children: const <Widget>[
                  Text('First child'),
                  Icon(Icons.check),
                ]),
              ],
            ),
          ),
        ),
      );

      DefaultTextStyle textStyle;
      IconTheme iconTheme;

      // custom enabled color
      textStyle = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyle.style.color, enabledColor);
      iconTheme = tester.firstWidget(
        find.widgetWithIcon(IconTheme, Icons.check),
      );
      expect(iconTheme.data.color, enabledColor);

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              selectedColor: selectedColor,
              isSelected: const <bool>[true],
              onPressed: (int index) {},
              children: <Widget>[
                Row(children: const <Widget>[
                  Text('First child'),
                  Icon(Icons.check),
                ]),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // custom selected color
      textStyle = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyle.style.color, selectedColor);
      iconTheme = tester.firstWidget(
        find.widgetWithIcon(IconTheme, Icons.check),
      );
      expect(iconTheme.data.color, selectedColor);

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              disabledColor: disabledColor,
              isSelected: const <bool>[true],
              children: <Widget>[
                Row(children: const <Widget>[
                  Text('First child'),
                  Icon(Icons.check),
                ]),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // custom disabled color
      textStyle = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyle.style.color, disabledColor);
      iconTheme = tester.firstWidget(
        find.widgetWithIcon(IconTheme, Icons.check),
      );
      expect(iconTheme.data.color, disabledColor);
    },
  );

  testWidgets(
    'Theme text/icon colors for enabled, selected and disabled states',
    (WidgetTester tester) async {
      final ThemeData theme = ThemeData();
      const Color enabledColor = Colors.lime;
      const Color selectedColor = Colors.green;
      const Color disabledColor = Colors.yellow;

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtonsTheme(
              child: ToggleButtons(
                color: enabledColor,
                isSelected: const <bool>[false],
                onPressed: (int index) {},
                children: <Widget>[
                  Row(children: const <Widget>[
                    Text('First child'),
                    Icon(Icons.check),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );

      DefaultTextStyle textStyle;
      IconTheme iconTheme;

      // custom theme enabled color
      expect(theme.colorScheme.onSurface, isNot(enabledColor));
      textStyle = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyle.style.color, enabledColor);
      iconTheme = tester.firstWidget(
        find.widgetWithIcon(IconTheme, Icons.check),
      );
      expect(iconTheme.data.color, enabledColor);

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtonsTheme(
              selectedColor: selectedColor,
              child: ToggleButtons(
                color: enabledColor,
                isSelected: const <bool>[true],
                onPressed: (int index) {},
                children: <Widget>[
                  Row(children: const <Widget>[
                    Text('First child'),
                    Icon(Icons.check),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // custom theme selected color
      expect(theme.colorScheme.primary, isNot(selectedColor));
      textStyle = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyle.style.color, selectedColor);
      iconTheme = tester.firstWidget(
        find.widgetWithIcon(IconTheme, Icons.check),
      );
      expect(iconTheme.data.color, selectedColor);

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtonsTheme(
              disabledColor: disabledColor,
              child: ToggleButtons(
                color: enabledColor,
                isSelected: const <bool>[false],
                children: <Widget>[
                  Row(children: const <Widget>[
                    Text('First child'),
                    Icon(Icons.check),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // custom theme disabled color
      expect(theme.disabledColor, isNot(disabledColor));
      textStyle = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyle.style.color, disabledColor);
      iconTheme = tester.firstWidget(
        find.widgetWithIcon(IconTheme, Icons.check),
      );
      expect(iconTheme.data.color, disabledColor);
    },
  );

  testWidgets('Default button fillColor', (WidgetTester tester) async {
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            isSelected: const <bool>[true],
            onPressed: (int index) {},
            children: <Widget>[
              Row(children: const <Widget>[
                Text('First child'),
              ]),
            ],
          ),
        ),
      ),
    );

    final Material material = tester.firstWidget<Material>(
      find.descendant(
        of: find.byType(RawMaterialButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, isNull);
    expect(material.type, MaterialType.transparency);
  });

  testWidgets('Custom button fillColor', (WidgetTester tester) async {
    const Color customFillColor = Colors.green;
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            fillColor: customFillColor,
            isSelected: const <bool>[true],
            onPressed: (int index) {},
            children: <Widget>[
              Row(children: const <Widget>[
                Text('First child'),
              ]),
            ],
          ),
        ),
      ),
    );

    final Material material = tester.firstWidget<Material>(
      find.descendant(
        of: find.byType(RawMaterialButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, customFillColor);
    expect(material.type, MaterialType.button);
  });

  testWidgets('Theme button fillColor', (WidgetTester tester) async {
    const Color customFillColor = Colors.green;
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtonsTheme(
            fillColor: customFillColor,
            child: ToggleButtons(
              isSelected: const <bool>[true],
              onPressed: (int index) {},
              children: <Widget>[
                Row(children: const <Widget>[
                  Text('First child'),
                ]),
              ],
            ),
          ),
        ),
      ),
    );

    final Material material = tester.firstWidget<Material>(
      find.descendant(
        of: find.byType(RawMaterialButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, customFillColor);
    expect(material.type, MaterialType.button);
  });

  testWidgets('Default InkWell colors', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    final FocusNode focusNode = FocusNode();
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            isSelected: const <bool>[true],
            onPressed: (int index) {},
            focusNodes: <FocusNode>[focusNode],
            children: const <Widget>[
              Text('First child'),
            ],
          ),
        ),
      ),
    );

    final Offset center = tester.getCenter(find.text('First child'));

    // splashColor
    // highlightColor
    final TestGesture touchGesture = await tester.createGesture();
    await touchGesture.down(center);
    await tester.pumpAndSettle();

    RenderObject inkFeatures;
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(
      inkFeatures,
      paints
        ..circle(color: theme.splashColor)
        ..rect(color: theme.highlightColor),
    );

    await touchGesture.up();
    await tester.pumpAndSettle();

    // hoverColor
    final TestGesture hoverGesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await hoverGesture.addPointer();
    await hoverGesture.moveTo(center);
    await tester.pumpAndSettle();

    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(inkFeatures, paints..rect(color: theme.hoverColor));
    await hoverGesture.removePointer();

    // focusColor
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(inkFeatures, paints..rect(color: theme.focusColor));
  });

  testWidgets('Custom InkWell colors', (WidgetTester tester) async {
    const Color splashColor = Color(0xff4caf50);
    const Color highlightColor = Color(0xffcddc39);
    const Color hoverColor = Color(0xffffeb3b);
    const Color focusColor = Color(0xffffff00);
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            splashColor: splashColor,
            highlightColor: highlightColor,
            hoverColor: hoverColor,
            focusColor: focusColor,
            isSelected: const <bool>[true],
            onPressed: (int index) {},
            focusNodes: <FocusNode>[focusNode],
            children: const <Widget>[
              Text('First child'),
            ],
          ),
        ),
      ),
    );

    final Offset center = tester.getCenter(find.text('First child'));

    // splashColor
    // highlightColor
    final TestGesture touchGesture = await tester.createGesture();
    await touchGesture.down(center);
    await tester.pumpAndSettle();

    RenderObject inkFeatures;
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(
      inkFeatures,
      paints
        ..circle(color: splashColor)
        ..rect(color: highlightColor),
    );

    await touchGesture.up();
    await tester.pumpAndSettle();

    // hoverColor
    final TestGesture hoverGesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await hoverGesture.addPointer();
    await hoverGesture.moveTo(center);
    await tester.pumpAndSettle();

    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(inkFeatures, paints..rect(color: hoverColor));
    await hoverGesture.removePointer();

    // focusColor
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(inkFeatures, paints..rect(color: focusColor));
  });

  testWidgets('Theme InkWell colors', (WidgetTester tester) async {
    const Color splashColor = Color(0xff4caf50);
    const Color highlightColor = Color(0xffcddc39);
    const Color hoverColor = Color(0xffffeb3b);
    const Color focusColor = Color(0xffffff00);
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtonsTheme(
            splashColor: splashColor,
            highlightColor: highlightColor,
            hoverColor: hoverColor,
            focusColor: focusColor,
            child: ToggleButtons(
              isSelected: const <bool>[true],
              onPressed: (int index) {},
              focusNodes: <FocusNode>[focusNode],
              children: const <Widget>[
                Text('First child'),
              ],
            ),
          ),
        ),
      ),
    );

    final Offset center = tester.getCenter(find.text('First child'));

    // splashColor
    // highlightColor
    final TestGesture touchGesture = await tester.createGesture();
    await touchGesture.down(center);
    await tester.pumpAndSettle();

    RenderObject inkFeatures;
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(
      inkFeatures,
      paints
        ..circle(color: splashColor)
        ..rect(color: highlightColor),
    );

    await touchGesture.up();
    await tester.pumpAndSettle();

    // hoverColor
    final TestGesture hoverGesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await hoverGesture.addPointer();
    await hoverGesture.moveTo(center);
    await tester.pumpAndSettle();

    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(inkFeatures, paints..rect(color: hoverColor));
    await hoverGesture.removePointer();

    // focusColor
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(inkFeatures, paints..rect(color: focusColor));
  });

  testWidgets(
    'Default border width and border colors for enabled, selected and disabled states',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: const <bool>[false],
              onPressed: (int index) {},
              children: const <Widget>[
                Text('First child'),
              ],
            ),
          ),
        ),
      );

      RenderObject toggleButtonRenderObject;
      toggleButtonRenderObject = tester.allRenderObjects.firstWhere((RenderObject object) {
        return object.runtimeType.toString() == '_SelectToggleButtonRenderObject';
      });
      expect(
        toggleButtonRenderObject,
        paints
          // trailing side
          ..path(
            style: PaintingStyle.stroke,
            color: const Color(0xff000000), // enabled borderColor
            strokeWidth: 1.0, // default borderWidth
          )
          // leading side, top and bottom
          ..path(
            style: PaintingStyle.stroke,
            color: const Color(0xff000000), // enabled borderColor
            strokeWidth: 1.0, // default borderWidth
          ),
      );

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: const <bool>[true],
              onPressed: (int index) {},
              children: const <Widget>[
                Text('First child'),
              ],
            ),
          ),
        ),
      );

      toggleButtonRenderObject = tester.allRenderObjects.firstWhere((RenderObject object) {
        return object.runtimeType.toString() == '_SelectToggleButtonRenderObject';
      });
      expect(
        toggleButtonRenderObject,
        paints
          // trailing side
          ..path(
            style: PaintingStyle.stroke,
            color: const Color(0xff2196f3), // selected borderColor
            strokeWidth: 1.0, // default borderWidth
          )
          // leading side, top and bottom
          ..path(
            style: PaintingStyle.stroke,
            color: const Color(0xff2196f3), // selected borderColor
            strokeWidth: 1.0, // default borderWidth
          ),
      );

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: const <bool>[false],
              children: const <Widget>[
                Text('First child'),
              ],
            ),
          ),
        ),
      );

      toggleButtonRenderObject = tester.allRenderObjects.firstWhere((RenderObject object) {
        return object.runtimeType.toString() == '_SelectToggleButtonRenderObject';
      });
      expect(
        toggleButtonRenderObject,
        paints
          // trailing side
          ..path(
            style: PaintingStyle.stroke,
            color: const Color(0x61000000), // disabled borderColor
            strokeWidth: 1.0, // default borderWidth
          )
          // leading side, top and bottom
          ..path(
            style: PaintingStyle.stroke,
            color: const Color(0x61000000), // disabled borderColor
            strokeWidth: 1.0, // default borderWidth
          ),
      );
    },
  );

  testWidgets(
    'Custom border width and border colors for enabled, selected and disabled states',
    (WidgetTester tester) async {
      const Color borderColor = Color(0xff4caf50);
      const Color selectedBorderColor = Color(0xffcddc39);
      const Color disabledBorderColor = Color(0xffffeb3b);
      const double customWidth = 2.0;

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              borderColor: borderColor,
              borderWidth: customWidth,
              isSelected: const <bool>[false],
              onPressed: (int index) {},
              children: const <Widget>[
                Text('First child'),
              ],
            ),
          ),
        ),
      );

      RenderObject toggleButtonRenderObject;
      toggleButtonRenderObject = tester.allRenderObjects.firstWhere((RenderObject object) {
        return object.runtimeType.toString() == '_SelectToggleButtonRenderObject';
      });
      expect(
        toggleButtonRenderObject,
        paints
          // trailing side
          ..path(
            style: PaintingStyle.stroke,
            color: borderColor, // enabled borderColor
            strokeWidth: customWidth, // default borderWidth
          )
          // leading side, top and bottom
          ..path(
            style: PaintingStyle.stroke,
            color: borderColor, // enabled borderColor
            strokeWidth: customWidth, // default borderWidth
          ),
      );

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              selectedBorderColor: selectedBorderColor,
              borderWidth: customWidth,
              isSelected: const <bool>[true],
              onPressed: (int index) {},
              children: const <Widget>[
                Text('First child'),
              ],
            ),
          ),
        ),
      );

      toggleButtonRenderObject = tester.allRenderObjects.firstWhere((RenderObject object) {
        return object.runtimeType.toString() == '_SelectToggleButtonRenderObject';
      });
      expect(
        toggleButtonRenderObject,
        paints
          // trailing side
          ..path(
            style: PaintingStyle.stroke,
            color: selectedBorderColor, // selected borderColor
            strokeWidth: customWidth, // default borderWidth
          )
          // leading side, top and bottom
          ..path(
            style: PaintingStyle.stroke,
            color: selectedBorderColor, // selected borderColor
            strokeWidth: customWidth, // default borderWidth
          ),
      );

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              disabledBorderColor: disabledBorderColor,
              borderWidth: customWidth,
              isSelected: const <bool>[false],
              children: const <Widget>[
                Text('First child'),
              ],
            ),
          ),
        ),
      );

      toggleButtonRenderObject = tester.allRenderObjects.firstWhere((RenderObject object) {
        return object.runtimeType.toString() == '_SelectToggleButtonRenderObject';
      });
      expect(
        toggleButtonRenderObject,
        paints
          // trailing side
          ..path(
            style: PaintingStyle.stroke,
            color: disabledBorderColor, // disabled borderColor
            strokeWidth: customWidth, // default borderWidth
          )
          // leading side, top and bottom
          ..path(
            style: PaintingStyle.stroke,
            color: disabledBorderColor, // disabled borderColor
            strokeWidth: customWidth, // default borderWidth
          ),
      );
    },
  );

  testWidgets(
    'Theme border width and border colors for enabled, selected and disabled states',
    (WidgetTester tester) async {
      const Color borderColor = Color(0xff4caf50);
      const Color selectedBorderColor = Color(0xffcddc39);
      const Color disabledBorderColor = Color(0xffffeb3b);
      const double customWidth = 2.0;

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtonsTheme(
              borderColor: borderColor,
              borderWidth: customWidth,
              child: ToggleButtons(
                isSelected: const <bool>[false],
                onPressed: (int index) {},
                children: const <Widget>[
                  Text('First child'),
                ],
              ),
            ),
          ),
        ),
      );

      RenderObject toggleButtonRenderObject;
      toggleButtonRenderObject = tester.allRenderObjects.firstWhere((RenderObject object) {
        return object.runtimeType.toString() == '_SelectToggleButtonRenderObject';
      });
      expect(
        toggleButtonRenderObject,
        paints
          // trailing side
          ..path(
            style: PaintingStyle.stroke,
            color: borderColor, // enabled borderColor
            strokeWidth: customWidth, // default borderWidth
          )
          // leading side, top and bottom
          ..path(
            style: PaintingStyle.stroke,
            color: borderColor, // enabled borderColor
            strokeWidth: customWidth, // default borderWidth
          ),
      );

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtonsTheme(
              selectedBorderColor: selectedBorderColor,
              borderWidth: customWidth,
              child: ToggleButtons(
                isSelected: const <bool>[true],
                onPressed: (int index) {},
                children: const <Widget>[
                  Text('First child'),
                ],
              ),
            ),
          ),
        ),
      );

      toggleButtonRenderObject = tester.allRenderObjects.firstWhere((RenderObject object) {
        return object.runtimeType.toString() == '_SelectToggleButtonRenderObject';
      });
      expect(
        toggleButtonRenderObject,
        paints
          // trailing side
          ..path(
            style: PaintingStyle.stroke,
            color: selectedBorderColor, // selected borderColor
            strokeWidth: customWidth, // default borderWidth
          )
          // leading side, top and bottom
          ..path(
            style: PaintingStyle.stroke,
            color: selectedBorderColor, // selected borderColor
            strokeWidth: customWidth, // default borderWidth
          ),
      );

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtonsTheme(
              disabledBorderColor: disabledBorderColor,
              borderWidth: customWidth,
              child: ToggleButtons(
                isSelected: const <bool>[false],
                children: const <Widget>[
                  Text('First child'),
                ],
              ),
            ),
          ),
        ),
      );

      toggleButtonRenderObject = tester.allRenderObjects.firstWhere((RenderObject object) {
        return object.runtimeType.toString() == '_SelectToggleButtonRenderObject';
      });
      expect(
        toggleButtonRenderObject,
        paints
          // trailing side
          ..path(
            style: PaintingStyle.stroke,
            color: disabledBorderColor, // disabled borderColor
            strokeWidth: customWidth, // default borderWidth
          )
          // leading side, top and bottom
          ..path(
            style: PaintingStyle.stroke,
            color: disabledBorderColor, // disabled borderColor
            strokeWidth: customWidth, // default borderWidth
          ),
      );
    },
  );

  // height of all buttons must match the tallest button
  testWidgets('Height of segmented control is determined by tallest widget', (WidgetTester tester) async {
    final List<Widget> children = <Widget>[
      Container(
        constraints: const BoxConstraints.tightFor(height: 100.0),
      ),
      Container(
        constraints: const BoxConstraints.tightFor(height: 400.0), // tallest widget
      ),
      Container(
        constraints: const BoxConstraints.tightFor(height: 200.0),
      ),
    ];

    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            isSelected: const <bool>[false, true, false],
            children: children,
          ),
        ),
      ),
    );

    final List<Widget> toggleButtons = tester.allWidgets.where((Widget widget) {
      return widget.runtimeType.toString() == '_SelectToggleButton';
    }).toList();

    for (int i = 0; i < toggleButtons.length; i++) {
      final Rect rect = tester.getRect(find.byWidget(toggleButtons[i]));
      expect(rect.height, 400.0);
    }
  });

  testWidgets('Directionality test', (WidgetTester tester) async {
    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: ToggleButtons(
              onPressed: (int index) {},
              isSelected: const <bool>[false, true],
              children: const <Widget>[
                Text('First child'),
                Text('Second child'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getTopRight(find.text('First child')).dx < tester.getTopRight(find.text('Second child')).dx,
      isTrue,
    );

    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: ToggleButtons(
              onPressed: (int index) {},
              isSelected: const <bool>[false, true],
              children: const <Widget>[
                Text('First child'),
                Text('Second child'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getTopRight(find.text('First child')).dx > tester.getTopRight(find.text('Second child')).dx,
      isTrue,
    );
  });

  // proper paints based on state
  // default border radius
  // custom border radius
  // theme border radius
}
