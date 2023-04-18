// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Default PageTransitionsTheme platform', (final WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('home')));
    final PageTransitionsTheme theme = Theme.of(tester.element(find.text('home'))).pageTransitionsTheme;
    expect(theme.builders, isNotNull);
    for (final TargetPlatform platform in TargetPlatform.values) {
      switch (platform) {
        case TargetPlatform.android:
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          expect(
            theme.builders[platform],
            isNotNull,
            reason: 'theme builder for $platform is null',
          );
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          expect(
            theme.builders[platform],
            isNull,
            reason: 'theme builder for $platform is not null',
          );
      }
    }
  });

  testWidgets('Default PageTransitionsTheme builds a CupertinoPageTransition', (final WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (final BuildContext context) => Material(
        child: TextButton(
          child: const Text('push'),
          onPressed: () { Navigator.of(context).pushNamed('/b'); },
        ),
      ),
      '/b': (final BuildContext context) => const Text('page b'),
    };

    await tester.pumpWidget(
      MaterialApp(
        routes: routes,
      ),
    );

    expect(Theme.of(tester.element(find.text('push'))).platform, debugDefaultTargetPlatformOverride);
    expect(find.byType(CupertinoPageTransition), findsOneWidget);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
    expect(find.byType(CupertinoPageTransition), findsOneWidget);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('Default PageTransitionsTheme builds a _ZoomPageTransition for android', (final WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (final BuildContext context) => Material(
        child: TextButton(
          child: const Text('push'),
          onPressed: () { Navigator.of(context).pushNamed('/b'); },
        ),
      ),
      '/b': (final BuildContext context) => const Text('page b'),
    };

    await tester.pumpWidget(
      MaterialApp(
        routes: routes,
      ),
    );

    Finder findZoomPageTransition() {
      return find.descendant(
        of: find.byType(MaterialApp),
        matching: find.byWidgetPredicate((final Widget w) => '${w.runtimeType}' == '_ZoomPageTransition'),
      );
    }

    expect(Theme.of(tester.element(find.text('push'))).platform, debugDefaultTargetPlatformOverride);
    expect(findZoomPageTransition(), findsOneWidget);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
    expect(findZoomPageTransition(), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('PageTransitionsTheme override builds a _OpenUpwardsPageTransition', (final WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (final BuildContext context) => Material(
        child: TextButton(
          child: const Text('push'),
          onPressed: () { Navigator.of(context).pushNamed('/b'); },
        ),
      ),
      '/b': (final BuildContext context) => const Text('page b'),
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(), // creates a _OpenUpwardsPageTransition
            },
          ),
        ),
        routes: routes,
      ),
    );

    Finder findOpenUpwardsPageTransition() {
      return find.descendant(
        of: find.byType(MaterialApp),
        matching: find.byWidgetPredicate((final Widget w) => '${w.runtimeType}' == '_OpenUpwardsPageTransition'),
      );
    }

    expect(Theme.of(tester.element(find.text('push'))).platform, debugDefaultTargetPlatformOverride);
    expect(findOpenUpwardsPageTransition(), findsOneWidget);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
    expect(findOpenUpwardsPageTransition(), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('PageTransitionsTheme override builds a _FadeUpwardsTransition', (final WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (final BuildContext context) => Material(
        child: TextButton(
          child: const Text('push'),
          onPressed: () { Navigator.of(context).pushNamed('/b'); },
        ),
      ),
      '/b': (final BuildContext context) => const Text('page b'),
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(), // creates a _FadeUpwardsTransition
            },
          ),
        ),
        routes: routes,
      ),
    );

    Finder findFadeUpwardsPageTransition() {
      return find.descendant(
        of: find.byType(MaterialApp),
        matching: find.byWidgetPredicate((final Widget w) => '${w.runtimeType}' == '_FadeUpwardsPageTransition'),
      );
    }

    expect(Theme.of(tester.element(find.text('push'))).platform, debugDefaultTargetPlatformOverride);
    expect(findFadeUpwardsPageTransition(), findsOneWidget);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
    expect(findFadeUpwardsPageTransition(), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  Widget boilerplate({
    required final bool themeAllowSnapshotting,
    final bool secondRouteAllowSnapshotting = true,
  }) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        pageTransitionsTheme: PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: ZoomPageTransitionsBuilder(
              allowSnapshotting: themeAllowSnapshotting,
            ),
          },
        ),
      ),
      onGenerateRoute: (final RouteSettings settings) {
        if (settings.name == '/') {
          return MaterialPageRoute<Widget>(
            builder: (final _) => const Material(child: Text('Page 1')),
          );
        }
        return MaterialPageRoute<Widget>(
          builder: (final _) => const Material(child: Text('Page 2')),
          allowSnapshotting: secondRouteAllowSnapshotting,
        );
      },
    );
  }

  bool isTransitioningWithSnapshotting(final WidgetTester tester, final Finder of) {
    final Iterable<Layer> layers = tester.layerListOf(
      find.ancestor(of: of, matching: find.byType(SnapshotWidget)).first,
    );
    final bool hasOneOpacityLayer = layers.whereType<OpacityLayer>().length == 1;
    final bool hasOneTransformLayer = layers.whereType<TransformLayer>().length == 1;
    // When snapshotting is on, the OpacityLayer and TransformLayer will not be
    // applied directly.
    return !(hasOneOpacityLayer && hasOneTransformLayer);
  }

  testWidgets('ZoomPageTransitionsBuilder default route snapshotting behavior', (final WidgetTester tester) async {
    await tester.pumpWidget(
      boilerplate(themeAllowSnapshotting: true),
    );

    final Finder page1 = find.text('Page 1');
    final Finder page2 = find.text('Page 2');

    // Transitioning from page 1 to page 2.
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/2');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Exiting route should be snapshotted.
    expect(isTransitioningWithSnapshotting(tester, page1), isTrue);

    // Entering route should be snapshotted.
    expect(isTransitioningWithSnapshotting(tester, page2), isTrue);

    await tester.pumpAndSettle();

    // Transitioning back from page 2 to page 1.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Exiting route should be snapshotted.
    expect(isTransitioningWithSnapshotting(tester, page2), isTrue);

    // Entering route should be snapshotted.
    expect(isTransitioningWithSnapshotting(tester, page1), isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android), skip: kIsWeb); // [intended] rasterization is not used on the web.

  testWidgets('ZoomPageTransitionsBuilder.allowSnapshotting can disable route snapshotting', (final WidgetTester tester) async {
    await tester.pumpWidget(
      boilerplate(themeAllowSnapshotting: false),
    );

    final Finder page1 = find.text('Page 1');
    final Finder page2 = find.text('Page 2');

    // Transitioning from page 1 to page 2.
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/2');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Exiting route should not be snapshotted.
    expect(isTransitioningWithSnapshotting(tester, page1), isFalse);

    // Entering route should not be snapshotted.
    expect(isTransitioningWithSnapshotting(tester, page2), isFalse);

    await tester.pumpAndSettle();

    // Transitioning back from page 2 to page 1.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Exiting route should not be snapshotted.
    expect(isTransitioningWithSnapshotting(tester, page2), isFalse);

    // Entering route should not be snapshotted.
    expect(isTransitioningWithSnapshotting(tester, page1), isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android), skip: kIsWeb); // [intended] rasterization is not used on the web.

  testWidgets('Setting PageRoute.allowSnapshotting to false overrides ZoomPageTransitionsBuilder.allowSnapshotting = true', (final WidgetTester tester) async {
    await tester.pumpWidget(
      boilerplate(
        themeAllowSnapshotting: true,
        secondRouteAllowSnapshotting: false,
      ),
    );

    final Finder page1 = find.text('Page 1');
    final Finder page2 = find.text('Page 2');

    // Transitioning from page 1 to page 2.
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/2');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // First route should be snapshotted.
    expect(isTransitioningWithSnapshotting(tester, page1), isTrue);

    // Second route should not be snapshotted.
    expect(isTransitioningWithSnapshotting(tester, page2), isFalse);

    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.android), skip: kIsWeb); // [intended] rasterization is not used on the web.

  testWidgets('_ZoomPageTransition only causes child widget built once', (final WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/58345

    int builtCount = 0;

    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (final BuildContext context) => Material(
        child: TextButton(
          child: const Text('push'),
          onPressed: () { Navigator.of(context).pushNamed('/b'); },
        ),
      ),
      '/b': (final BuildContext context) => StatefulBuilder(
        builder: (final BuildContext context, final StateSetter setState) {
          builtCount++; // Increase [builtCount] each time the widget build
          return TextButton(
            child: const Text('pop'),
            onPressed: () { Navigator.pop(context); },
          );
        },
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: ZoomPageTransitionsBuilder(), // creates a _ZoomPageTransition
            },
          ),
        ),
        routes: routes,
      ),
    );

    // No matter push or pop was called, the child widget should built only once.
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(builtCount, 1);

    await tester.tap(find.text('pop'));
    await tester.pumpAndSettle();
    expect(builtCount, 1);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
