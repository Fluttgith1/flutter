import 'dart:ui' as ui show window;
import 'dart:ui' show Size, Locale;

import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

void main() {
  testWidgets('TestWindow can fake device pixel ratio', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<double>(
      tester: tester,
      realValue: ui.window.devicePixelRatio,
      fakeValue: 2.5,
      propertyRetriever: () {
        return WidgetsBinding.instance.window.devicePixelRatio;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, double fakeValue) {
        binding.window.devicePixelRatioTestValue = fakeValue;
      }
    );
  });

  testWidgets('TestWindow can fake physical size', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<Size>(
      tester: tester,
      realValue: ui.window.physicalSize,
      fakeValue: const Size(50, 50),
      propertyRetriever: () {
        return WidgetsBinding.instance.window.physicalSize;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, Size fakeValue) {
        binding.window.physicalSizeTestValue = fakeValue;
      }
    );
  });

  // testWidgets('TestWindow can fake view insets', (WidgetTester tester) async {
  //   await verifyThatTestWindowCanFakeProperty<WindowPadding>(
  //     tester: tester,
  //     realPropertyValue: ui.window.viewInsets,
  //     fakePropertyValue: const WindowPadding(),
  //     propertyRetriever: (BuildContext context) {
  //       EdgeInsets.fromWindowPadding(window.viewInsets, window.devicePixelRatio)
  //       return MediaQuery.of(context).viewInsets;
  //     },
  //     propertyFaker: (TestWidgetsFlutterBinding binding, WindowPadding fakeValue) {
  //       binding.window.viewInsetsTestValue = fakeValue;
  //     }
  //   );
  // });

  // testWidgets('TestWindow can fake padding', (WidgetTester tester) async {
  //   await verifyThatTestWindowCanFakeProperty<WindowPadding>(
  //     tester: tester,
  //     realPropertyValue: ui.window.padding,
  //     fakePropertyValue: const WindowPadding(50, 50),
  //     propertyRetriever: (BuildContext context) {
  //       final Size physicalSize = MediaQuery.of(context).size * MediaQuery.of(context).devicePixelRatio;
  //       return physicalSize;
  //     },
  //     propertyFaker: (TestWidgetsFlutterBinding binding, Size fakeValue) {
  //       binding.window.physicalSizeTestValue = fakeValue;
  //     }
  //   );
  // });

  testWidgets('TestWindow can fake locale', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<Locale>(
      tester: tester,
      realValue: ui.window.locale,
      fakeValue: const Locale('fake_language_code'),
      propertyRetriever: () {
        return WidgetsBinding.instance.window.locale;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, Locale fakeValue) {
        binding.window.localeTestValue = fakeValue;
      }
    );
  });

  testWidgets('TestWindow can fake locales', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<List<Locale>>(
      tester: tester,
      realValue: ui.window.locales,
      fakeValue: <Locale>[const Locale('fake_language_code')],
      propertyRetriever: () {
        return WidgetsBinding.instance.window.locales;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, List<Locale> fakeValue) {
        binding.window.localesTestValue = fakeValue;
      }
    );
  });

  testWidgets('TestWindow can fake text scale factor', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<double>(
      tester: tester,
      realValue: ui.window.textScaleFactor,
      fakeValue: 2.5,
      propertyRetriever: () {
        return WidgetsBinding.instance.window.textScaleFactor;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, double fakeValue) {
        binding.window.textScaleFactorTestValue = fakeValue;
      }
    );
  });

  testWidgets('TestWindow can fake clock format', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<bool>(
      tester: tester,
      realValue: ui.window.alwaysUse24HourFormat,
      fakeValue: !ui.window.alwaysUse24HourFormat,
      propertyRetriever: () {
        return WidgetsBinding.instance.window.alwaysUse24HourFormat;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, bool fakeValue) {
        binding.window.alwaysUse24HourFormatTestValue = fakeValue;
      }
    );
  });

  testWidgets('TestWindow can fake default route name', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<String>(
      tester: tester,
      realValue: ui.window.defaultRouteName,
      fakeValue: 'fake_route',
      propertyRetriever: () {
        return WidgetsBinding.instance.window.defaultRouteName;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, String fakeValue) {
        binding.window.defaultRouteNameTestValue = fakeValue;
      }
    );
  });

  testWidgets('TestWindow can fake semantics enabled', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<bool>(
      tester: tester,
      realValue: ui.window.semanticsEnabled,
      fakeValue: !ui.window.semanticsEnabled,
      propertyRetriever: () {
        return WidgetsBinding.instance.window.semanticsEnabled;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, bool fakeValue) {
        binding.window.semanticsEnabledTestValue = fakeValue;
      }
    );
  });

  // testWidgets('TestWindow can fake accessibility features', (WidgetTester tester) async {
  //   verifyThatTestWindowCanFakeProperty<AccessibilityFeatures>(
  //     tester: tester,
  //     realValue: ui.window.accessibilityFeatures,
  //     fakeValue: AccessibilityFeatures(),
  //     propertyRetriever: () {
  //       return WidgetsBinding.instance.window.semanticsEnabled;
  //     },
  //     propertyFaker: (TestWidgetsFlutterBinding binding, bool fakeValue) {
  //       binding.window.semanticsEnabledTestValue = fakeValue;
  //     }
  //   );
  // });

  testWidgets('TestWindow can clear out fake properties all at once', (WidgetTester tester) {
    final double originalDevicePixelRatio = ui.window.devicePixelRatio;
    final double originalTextScaleFactor = ui.window.textScaleFactor;
    final TestWindow testWindow = retrieveTestBinding(tester).window;

    // Set fake values for window properties.
    testWindow.devicePixelRatioTestValue = 2.5;
    testWindow.textScaleFactorTestValue = 3.0;

    // Erase fake window property values.
    testWindow.clearAllTestValues();

    // Verify that the window once again reports real property values.
    expect(WidgetsBinding.instance.window.devicePixelRatio, originalDevicePixelRatio);
    expect(WidgetsBinding.instance.window.textScaleFactor, originalTextScaleFactor);
  });
}

void verifyThatTestWindowCanFakeProperty<WindowPropertyType>({
  @required WidgetTester tester,
  @required WindowPropertyType realValue,
  @required WindowPropertyType fakeValue,
  @required WindowPropertyType Function() propertyRetriever,
  @required Function(TestWidgetsFlutterBinding, WindowPropertyType fakeValue) propertyFaker,
}) {
  WindowPropertyType propertyBeforeFaking;
  WindowPropertyType propertyAfterFaking;

  propertyBeforeFaking = propertyRetriever();

  propertyFaker(retrieveTestBinding(tester), fakeValue);

  propertyAfterFaking = propertyRetriever();

  expect(propertyBeforeFaking, realValue);
  expect(propertyAfterFaking, fakeValue);
}

TestWidgetsFlutterBinding retrieveTestBinding(WidgetTester tester) {
  final WidgetsBinding binding = tester.binding;
  assert(binding is TestWidgetsFlutterBinding);
  final TestWidgetsFlutterBinding testBinding = binding;
  return testBinding;
}