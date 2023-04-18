// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show AccessibilityFeatures, Brightness, Locale, PlatformDispatcher;

import 'package:flutter/widgets.dart' show WidgetsBinding, WidgetsBindingObserver;
import 'package:flutter_test/flutter_test.dart';

import 'utils/fake_and_mock_utils.dart';

void main() {
  test('TestPlatformDispatcher can handle new methods without breaking', () {
    final dynamic testPlatformDispatcher = TestPlatformDispatcher(platformDispatcher: PlatformDispatcher.instance);
    // ignore: avoid_dynamic_calls
    expect(testPlatformDispatcher.someNewProperty, null);
  });

  testWidgets('TestPlatformDispatcher can fake locale', (final WidgetTester tester) async {
    verifyPropertyFaked<Locale>(
      tester: tester,
      realValue: PlatformDispatcher.instance.locale,
      fakeValue: const Locale('fake_language_code'),
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.locale;
      },
      propertyFaker: (final TestWidgetsFlutterBinding binding, final Locale fakeValue) {
        binding.platformDispatcher.localeTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake locales', (final WidgetTester tester) async {
    verifyPropertyFaked<List<Locale>>(
      tester: tester,
      realValue: PlatformDispatcher.instance.locales,
      fakeValue: <Locale>[const Locale('fake_language_code')],
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.locales;
      },
      propertyFaker: (final TestWidgetsFlutterBinding binding, final List<Locale> fakeValue) {
        binding.platformDispatcher.localesTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake text scale factor', (final WidgetTester tester) async {
    verifyPropertyFaked<double>(
      tester: tester,
      realValue: PlatformDispatcher.instance.textScaleFactor,
      fakeValue: 2.5,
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.textScaleFactor;
      },
      propertyFaker: (final TestWidgetsFlutterBinding binding, final double fakeValue) {
        binding.platformDispatcher.textScaleFactorTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake clock format', (final WidgetTester tester) async {
    verifyPropertyFaked<bool>(
      tester: tester,
      realValue: PlatformDispatcher.instance.alwaysUse24HourFormat,
      fakeValue: !PlatformDispatcher.instance.alwaysUse24HourFormat,
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.alwaysUse24HourFormat;
      },
      propertyFaker: (final TestWidgetsFlutterBinding binding, final bool fakeValue) {
        binding.platformDispatcher.alwaysUse24HourFormatTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake brieflyShowPassword', (final WidgetTester tester) async {
    verifyPropertyFaked<bool>(
      tester: tester,
      realValue: PlatformDispatcher.instance.brieflyShowPassword,
      fakeValue: !PlatformDispatcher.instance.brieflyShowPassword,
      propertyRetriever: () => WidgetsBinding.instance.platformDispatcher.brieflyShowPassword,
      propertyFaker: (final TestWidgetsFlutterBinding binding, final bool fakeValue) {
        binding.platformDispatcher.brieflyShowPasswordTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake default route name', (final WidgetTester tester) async {
    verifyPropertyFaked<String>(
      tester: tester,
      realValue: PlatformDispatcher.instance.defaultRouteName,
      fakeValue: 'fake_route',
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.defaultRouteName;
      },
      propertyFaker: (final TestWidgetsFlutterBinding binding, final String fakeValue) {
        binding.platformDispatcher.defaultRouteNameTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake accessibility features', (final WidgetTester tester) async {
    verifyPropertyFaked<AccessibilityFeatures>(
      tester: tester,
      realValue: PlatformDispatcher.instance.accessibilityFeatures,
      fakeValue: const FakeAccessibilityFeatures(),
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
      },
      propertyFaker: (final TestWidgetsFlutterBinding binding, final AccessibilityFeatures fakeValue) {
        binding.platformDispatcher.accessibilityFeaturesTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake platform brightness', (final WidgetTester tester) async {
    verifyPropertyFaked<Brightness>(
      tester: tester,
      realValue: Brightness.light,
      fakeValue: Brightness.dark,
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.platformBrightness;
      },
      propertyFaker: (final TestWidgetsFlutterBinding binding, final Brightness fakeValue) {
        binding.platformDispatcher.platformBrightnessTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can clear out fake properties all at once', (final WidgetTester tester) async {
    final Locale originalLocale = PlatformDispatcher.instance.locale;
    final double originalTextScaleFactor = PlatformDispatcher.instance.textScaleFactor;
    final TestPlatformDispatcher testPlatformDispatcher = retrieveTestBinding(tester).platformDispatcher;

    // Set fake values for window properties.
    testPlatformDispatcher.localeTestValue = const Locale('foobar');
    testPlatformDispatcher.textScaleFactorTestValue = 3.0;

    // Erase fake window property values.
    testPlatformDispatcher.clearAllTestValues();

    // Verify that the window once again reports real property values.
    expect(WidgetsBinding.instance.platformDispatcher.locale, originalLocale);
    expect(WidgetsBinding.instance.platformDispatcher.textScaleFactor, originalTextScaleFactor);
  });

  testWidgets('TestPlatformDispatcher sends fake locales when WidgetsBindingObserver notifiers are called', (final WidgetTester tester) async {
    final List<Locale> defaultLocales = WidgetsBinding.instance.platformDispatcher.locales;
    final TestObserver observer = TestObserver();
    retrieveTestBinding(tester).addObserver(observer);
    final List<Locale> expectedValue = <Locale>[const Locale('fake_language_code')];
    retrieveTestBinding(tester).platformDispatcher.localesTestValue = expectedValue;
    expect(observer.locales, equals(expectedValue));
    retrieveTestBinding(tester).platformDispatcher.localesTestValue = defaultLocales;
  });
}

class TestObserver with WidgetsBindingObserver {
  List<Locale>? locales;

  @override
  void didChangeLocales(final List<Locale>? locales) {
    this.locales = locales;
  }
}
