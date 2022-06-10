// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../image_data.dart';
import '../rendering/mock_canvas.dart';

void main() {
  test('SwitchThemeData copyWith, ==, hashCode basics', () {
    expect(const SwitchThemeData(), const SwitchThemeData().copyWith());
    expect(const SwitchThemeData().hashCode, const SwitchThemeData().copyWith().hashCode);
  });

  test('SwitchThemeData defaults', () {
    const SwitchThemeData themeData = SwitchThemeData();
    expect(themeData.thumbColor, null);
    expect(themeData.thumbImage, null);
    expect(themeData.trackColor, null);
    expect(themeData.mouseCursor, null);
    expect(themeData.materialTapTargetSize, null);
    expect(themeData.overlayColor, null);
    expect(themeData.splashRadius, null);

    const SwitchTheme theme = SwitchTheme(data: SwitchThemeData(), child: SizedBox());
    expect(theme.data.thumbColor, null);
    expect(themeData.thumbImage, null);
    expect(theme.data.trackColor, null);
    expect(theme.data.mouseCursor, null);
    expect(theme.data.materialTapTargetSize, null);
    expect(theme.data.overlayColor, null);
    expect(theme.data.splashRadius, null);
  });

  testWidgets('Default SwitchThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const SwitchThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[]);
  });

  testWidgets('SwitchThemeData implements debugFillProperties', (WidgetTester tester) async {
    final Uint8List thumbImageBytes = Uint8List.fromList(kBlueRectPng);
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    SwitchThemeData(
      thumbColor: const MaterialStatePropertyAll<Color>(Color(0xfffffff0)),
      thumbImage: MaterialStatePropertyAll<ImageProvider>(MemoryImage(thumbImageBytes)),
      trackColor: const MaterialStatePropertyAll<Color>(Color(0xfffffff1)),
      mouseCursor: const MaterialStatePropertyAll<MouseCursor>(SystemMouseCursors.click),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      overlayColor: const MaterialStatePropertyAll<Color>(Color(0xfffffff2)),
      splashRadius: 1.0,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description[0], 'thumbColor: MaterialStatePropertyAll(Color(0xfffffff0))');
    expect(description[1], 'thumbImage: MaterialStatePropertyAll(MemoryImage(Uint8List#${shortHash(thumbImageBytes)}, scale: 1.0))');
    expect(description[2], 'trackColor: MaterialStatePropertyAll(Color(0xfffffff1))');
    expect(description[3], 'materialTapTargetSize: MaterialTapTargetSize.shrinkWrap');
    expect(description[4], 'mouseCursor: MaterialStatePropertyAll(SystemMouseCursor(click))');
    expect(description[5], 'overlayColor: MaterialStatePropertyAll(Color(0xfffffff2))');
    expect(description[6], 'splashRadius: 1.0');
  });

  testWidgets('Switch is themeable', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    const Color defaultThumbColor = Color(0xfffffff0);
    const Color selectedThumbColor = Color(0xfffffff1);
    final ImageProvider defaultThumbImage = MemoryImage(Uint8List.fromList(kBlueRectPng));
    final ImageProvider selectedThumbImage = MemoryImage(Uint8List.fromList(kTransparentImage));
    const Color defaultTrackColor = Color(0xfffffff2);
    const Color selectedTrackColor = Color(0xfffffff3);
    const MouseCursor mouseCursor = SystemMouseCursors.text;
    const MaterialTapTargetSize materialTapTargetSize = MaterialTapTargetSize.shrinkWrap;
    const Color focusOverlayColor = Color(0xfffffff4);
    const Color hoverOverlayColor = Color(0xfffffff5);
    const double splashRadius = 1.0;

    Widget buildSwitch({bool selected = false, bool autofocus = false}) {
      return MaterialApp(
        theme: ThemeData(
          switchTheme: SwitchThemeData(
            thumbColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return selectedThumbColor;
              }
              return defaultThumbColor;
            }),
            thumbImage: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return selectedThumbImage;
              }
              return defaultThumbImage;
            }),
            trackColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return selectedTrackColor;
              }
              return defaultTrackColor;
            }),
            mouseCursor: const MaterialStatePropertyAll<MouseCursor>(mouseCursor),
            materialTapTargetSize: materialTapTargetSize,
            overlayColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.focused)) {
                return focusOverlayColor;
              }
              if (states.contains(MaterialState.hovered)) {
                return hoverOverlayColor;
              }
              return null;
            }),
            splashRadius: splashRadius,
          ),
        ),
        home: Scaffold(
          body: Switch(
            dragStartBehavior: DragStartBehavior.down,
            value: selected,
            onChanged: (bool value) {},
            autofocus: autofocus,
          ),
        ),
      );
    }

    // Switch.
    await tester.pumpWidget(buildSwitch());
    await tester.pumpAndSettle();
    expect(
      _getSwitchMaterial(tester),
      paints
        ..rrect(color: defaultTrackColor)
        ..circle()
        ..circle()
        ..circle()
        ..circle(color: defaultThumbColor),
    );
    // Size from MaterialTapTargetSize.shrinkWrap.
    expect(tester.getSize(find.byType(Switch)), const Size(59.0, 40.0));
    // TODO(kirolous-nashaat): verify that defaultThumbImage is used.

    // Selected switch.
    await tester.pumpWidget(buildSwitch(selected: true));
    await tester.pumpAndSettle();
    expect(
      _getSwitchMaterial(tester),
      paints
        ..rrect(color: selectedTrackColor)
        ..circle()
        ..circle()
        ..circle()
        ..circle(color: selectedThumbColor),
    );
    // TODO(kirolous-nashaat): verify that selectedThumbImage is used.

    // Switch with hover.
    await tester.pumpWidget(buildSwitch());
    await _pointGestureToSwitch(tester);
    await tester.pumpAndSettle();
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);
    expect(_getSwitchMaterial(tester), paints..circle(color: hoverOverlayColor));

    // Switch with focus.
    await tester.pumpWidget(buildSwitch(autofocus: true));
    await tester.pumpAndSettle();
    expect(_getSwitchMaterial(tester), paints..circle(color: focusOverlayColor, radius: splashRadius));
  });

  testWidgets('Switch properties are taken over the theme values', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    const Color themeDefaultThumbColor = Color(0xfffffff0);
    const Color themeSelectedThumbColor = Color(0xfffffff1);
    final ImageProvider themeDefaultThumbImage = MemoryImage(Uint8List.fromList(kBlueRectPng));
    final ImageProvider themeSelectedThumbImage = MemoryImage(Uint8List.fromList(kTransparentImage));
    const Color themeDefaultTrackColor = Color(0xfffffff2);
    const Color themeSelectedTrackColor = Color(0xfffffff3);
    const MouseCursor themeMouseCursor = SystemMouseCursors.click;
    const MaterialTapTargetSize themeMaterialTapTargetSize = MaterialTapTargetSize.padded;
    const Color themeFocusOverlayColor = Color(0xfffffff4);
    const Color themeHoverOverlayColor = Color(0xfffffff5);
    const double themeSplashRadius = 1.0;

    const Color defaultThumbColor = Color(0xffffff0f);
    const Color selectedThumbColor = Color(0xffffff1f);
    const Color defaultTrackColor = Color(0xffffff2f);
    const Color selectedTrackColor = Color(0xffffff3f);
    const MouseCursor mouseCursor = SystemMouseCursors.text;
    const MaterialTapTargetSize materialTapTargetSize = MaterialTapTargetSize.shrinkWrap;
    const Color focusColor = Color(0xffffff4f);
    const Color hoverColor = Color(0xffffff5f);
    const double splashRadius = 2.0;

    Widget buildSwitch({bool selected = false, bool autofocus = false}) {
      return MaterialApp(
        theme: ThemeData(
          switchTheme: SwitchThemeData(
            thumbColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return themeSelectedThumbColor;
              }
              return themeDefaultThumbColor;
            }),
            thumbImage: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return themeSelectedThumbImage;
              }
              return themeDefaultThumbImage;
            }),
            trackColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return themeSelectedTrackColor;
              }
              return themeDefaultTrackColor;
            }),
            mouseCursor: const MaterialStatePropertyAll<MouseCursor>(themeMouseCursor),
            materialTapTargetSize: themeMaterialTapTargetSize,
            overlayColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.focused)) {
                return themeFocusOverlayColor;
              }
              if (states.contains(MaterialState.hovered)) {
                return themeHoverOverlayColor;
              }
              return null;
            }),
            splashRadius: themeSplashRadius,
          ),
        ),
        home: Scaffold(
          body: Switch(
            value: selected,
            onChanged: (bool value) {},
            autofocus: autofocus,
            thumbColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return selectedThumbColor;
              }
              return defaultThumbColor;
            }),
            trackColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return selectedTrackColor;
              }
              return defaultTrackColor;
            }),
            mouseCursor: mouseCursor,
            materialTapTargetSize: materialTapTargetSize,
            focusColor: focusColor,
            hoverColor: hoverColor,
            splashRadius: splashRadius,
          ),
        ),
      );
    }

    // Switch.
    await tester.pumpWidget(buildSwitch());
    await tester.pumpAndSettle();
    expect(
      _getSwitchMaterial(tester),
      paints
        ..rrect(color: defaultTrackColor)
        ..circle()
        ..circle()
        ..circle()
        ..circle(color: defaultThumbColor),
    );
    // Size from MaterialTapTargetSize.shrinkWrap.
    expect(tester.getSize(find.byType(Switch)), const Size(59.0, 40.0));
    // TODO(kirolous-nashaat): verify that themeDefaultThumbImage is used.

    // Selected switch.
    await tester.pumpWidget(buildSwitch(selected: true));
    await tester.pumpAndSettle();
    expect(
      _getSwitchMaterial(tester),
      paints
        ..rrect(color: selectedTrackColor)
        ..circle()
        ..circle()
        ..circle()
        ..circle(color: selectedThumbColor),
    );
    // TODO(kirolous-nashaat): verify that themeSelectedThumbImage is used.

    // Switch with hover.
    await tester.pumpWidget(buildSwitch());
    await _pointGestureToSwitch(tester);
    await tester.pumpAndSettle();
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);
    expect(_getSwitchMaterial(tester), paints..circle(color: hoverColor));

    // Switch with focus.
    await tester.pumpWidget(buildSwitch(autofocus: true));
    await tester.pumpAndSettle();
    expect(_getSwitchMaterial(tester), paints..circle(color: focusColor, radius: splashRadius));
  });

  testWidgets('Switch active and inactive properties are taken over the theme values', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    const Color themeDefaultThumbColor = Color(0xfffffff0);
    const Color themeSelectedThumbColor = Color(0xfffffff1);
    final ImageProvider themeDefaultThumbImage = MemoryImage(Uint8List.fromList(kBlueRectPng));
    final ImageProvider themeSelectedThumbImage = MemoryImage(Uint8List.fromList(kTransparentImage));
    const Color themeDefaultTrackColor = Color(0xfffffff2);
    const Color themeSelectedTrackColor = Color(0xfffffff3);

    const Color defaultThumbColor = Color(0xffffff0f);
    const Color selectedThumbColor = Color(0xffffff1f);
    final ImageProvider defaultThumbImage = MemoryImage(Uint8List.fromList(kBlueSquarePng));
    final ImageProvider selectedThumbImage = MemoryImage(Uint8List.fromList(kBlueSquarePng));
    const Color defaultTrackColor = Color(0xffffff2f);
    const Color selectedTrackColor = Color(0xffffff3f);

    Widget buildSwitch({bool selected = false, bool autofocus = false}) {
      return MaterialApp(
        theme: ThemeData(
          switchTheme: SwitchThemeData(
            thumbColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return themeSelectedThumbColor;
              }
              return themeDefaultThumbColor;
            }),
            thumbImage: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return themeSelectedThumbImage;
              }
              return themeDefaultThumbImage;
            }),
            trackColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return themeSelectedTrackColor;
              }
              return themeDefaultTrackColor;
            }),
          ),
        ),
        home: Scaffold(
          body: Switch(
            value: selected,
            onChanged: (bool value) {},
            autofocus: autofocus,
            activeColor: selectedThumbColor,
            inactiveThumbColor: defaultThumbColor,
            activeThumbImage: selectedThumbImage,
            inactiveThumbImage: defaultThumbImage,
            activeTrackColor: selectedTrackColor,
            inactiveTrackColor: defaultTrackColor,
          ),
        ),
      );
    }

    // Unselected switch.
    await tester.pumpWidget(buildSwitch());
    await tester.pumpAndSettle();
    expect(
      _getSwitchMaterial(tester),
      paints
        ..rrect(color: defaultTrackColor)
        ..circle()
        ..circle()
        ..circle()
        ..circle(color: defaultThumbColor),
    );
    // TODO(kirolous-nashaat): verify that defaultThumbImage is used.

    // Selected switch.
    await tester.pumpWidget(buildSwitch(selected: true));
    await tester.pumpAndSettle();
    expect(
      _getSwitchMaterial(tester),
      paints
        ..rrect(color: selectedTrackColor)
        ..circle()
        ..circle()
        ..circle()
        ..circle(color: selectedThumbColor),
    );
    // TODO(kirolous-nashaat): verify that selectedThumbImage is used.
  });

  testWidgets('Switch theme overlay color resolves in active/pressed states', (WidgetTester tester) async {
    const Color activePressedOverlayColor = Color(0xFF000001);
    const Color inactivePressedOverlayColor = Color(0xFF000002);

    Color? getOverlayColor(Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        if (states.contains(MaterialState.selected)) {
          return activePressedOverlayColor;
        }
        return inactivePressedOverlayColor;
      }
      return null;
    }
    const double splashRadius = 24.0;

    Widget buildSwitch({required bool active}) {
      return MaterialApp(
        theme: ThemeData(
          switchTheme: SwitchThemeData(
            overlayColor: MaterialStateProperty.resolveWith(getOverlayColor),
            splashRadius: splashRadius,
          ),
        ),
        home: Scaffold(
          body: Switch(
            value: active,
            onChanged: (_) { },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildSwitch(active: false));
    await tester.press(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(
      _getSwitchMaterial(tester),
      paints
        ..rrect()
        ..circle(
          color: inactivePressedOverlayColor,
          radius: splashRadius,
        ),
      reason: 'Inactive pressed Switch should have overlay color: $inactivePressedOverlayColor',
    );

    await tester.pumpWidget(buildSwitch(active: true));
    await tester.press(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(
      _getSwitchMaterial(tester),
      paints
        ..rrect()
        ..circle(
          color: activePressedOverlayColor,
          radius: splashRadius,
        ),
      reason: 'Active pressed Switch should have overlay color: $activePressedOverlayColor',
    );
  });

  testWidgets('Local SwitchTheme can override global SwitchTheme', (WidgetTester tester) async {
    const Color globalThemeThumbColor = Color(0xfffffff1);
    final ImageProvider globalThemeThumbImage = MemoryImage(Uint8List.fromList(kBlueRectPng));
    const Color globalThemeTrackColor = Color(0xfffffff2);

    const Color localThemeThumbColor = Color(0xffff0000);
    final ImageProvider localThemeThumbImage = MemoryImage(Uint8List.fromList(kTransparentImage));
    const Color localThemeTrackColor = Color(0xffff0000);

    Widget buildSwitch({bool selected = false, bool autofocus = false}) {
      return MaterialApp(
        theme: ThemeData(
          switchTheme: SwitchThemeData(
            thumbColor: const MaterialStatePropertyAll<Color>(globalThemeThumbColor),
            thumbImage: MaterialStatePropertyAll<ImageProvider>(globalThemeThumbImage),
            trackColor: const MaterialStatePropertyAll<Color>(globalThemeTrackColor),
          ),
        ),
        home: Scaffold(
          body: SwitchTheme(
            data: SwitchThemeData(
              thumbColor: const MaterialStatePropertyAll<Color>(localThemeThumbColor),
              thumbImage: MaterialStatePropertyAll<ImageProvider>(localThemeThumbImage),
              trackColor: const MaterialStatePropertyAll<Color>(localThemeTrackColor),
            ),
            child: Switch(
              value: selected,
              onChanged: (bool value) {},
              autofocus: autofocus,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildSwitch(selected: true));
    await tester.pumpAndSettle();
    expect(
      _getSwitchMaterial(tester),
      paints
        ..rrect(color: localThemeTrackColor)
        ..circle()
        ..circle()
        ..circle()
        ..circle(color: localThemeThumbColor),
    );
    // TODO(kirolous-nashaat): verify that localThemeThumbImage is used.
  });
}

Future<void> _pointGestureToSwitch(WidgetTester tester) async {
  final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer();
  addTearDown(gesture.removePointer);
  await gesture.moveTo(tester.getCenter(find.byType(Switch)));
}

MaterialInkController? _getSwitchMaterial(WidgetTester tester) {
  return Material.of(tester.element(find.byType(Switch)));
}
