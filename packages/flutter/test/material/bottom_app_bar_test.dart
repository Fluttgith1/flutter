// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('shadow effect is not doubled', (final WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/123064
    debugDisableShadows = false;

    const double elevation = 1;
    const Color shadowColor = Colors.black;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: const Scaffold(
          bottomNavigationBar: BottomAppBar(
            elevation: elevation,
            shadowColor: shadowColor,
          ),
        ),
      ),
    );

    final Finder finder = find.byType(BottomAppBar);
    expect(finder, paints..shadow(color: shadowColor, elevation: elevation));
    expect(finder, paintsExactlyCountTimes(#drawShadow, 1));

    debugDisableShadows = true;
  });

  testWidgets('only one layer with `color` is painted', (final WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/122667
    const Color bottomAppBarColor = Colors.black45;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: const Scaffold(
          bottomNavigationBar: BottomAppBar(
            color: bottomAppBarColor,

            // Avoid getting a surface tint color, to keep the color check below simple
            elevation: 0,
          ),
        ),
      ),
    );

    // There should be just one color layer, and with the specified color.
    final Finder finder = find.descendant(
      of: find.byType(BottomAppBar),
      matching: find.byWidgetPredicate((final Widget widget) {
        // A color layer is probably a [PhysicalShape] or [PhysicalModel],
        // either used directly or backing a [Material] (one without
        // [MaterialType.transparency]).
        return widget is PhysicalShape || widget is PhysicalModel;
      }),
    );
    final Widget widget = tester.widgetList(finder).single;
    if (widget is PhysicalShape) {
      expect(widget.color, bottomAppBarColor);
    } else if (widget is PhysicalModel) {
      expect(widget.color, bottomAppBarColor);
    } else {
      // Should be unreachable: compare with the finder.
      assert(false);
    }
  });

  testWidgets('no overlap with floating action button', (final WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: null,
          ),
          bottomNavigationBar: ShapeListener(
            BottomAppBar(
              child: SizedBox(height: 100.0),
            ),
          ),
        ),
      ),
    );

    final ShapeListenerState shapeListenerState = tester.state(find.byType(ShapeListener));
    final RenderBox renderBox = tester.renderObject(find.byType(BottomAppBar));
    final Path expectedPath = Path()
      ..addRect(Offset.zero & renderBox.size);

    final Path actualPath = shapeListenerState.cache.value;
    expect(
      actualPath,
      coversSameAreaAs(
        expectedPath,
        areaToCompare: (Offset.zero & renderBox.size).inflate(5.0),
      ),
    );
  });

  testWidgets('custom shape', (final WidgetTester tester) async {
    final Key key = UniqueKey();
    Future<void> pump(final FloatingActionButtonLocation location) async {
      await tester.pumpWidget(
        SizedBox(
          width: 200,
          height: 200,
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
              home: Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: () { },
                ),
                floatingActionButtonLocation: location,
                bottomNavigationBar: const BottomAppBar(
                  shape: AutomaticNotchedShape(
                    BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(50.0))),
                    ContinuousRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30.0))),
                  ),
                  notchMargin: 10.0,
                  color: Colors.green,
                  child: SizedBox(height: 100.0),
                ),
              ),
            ),
          ),
        ),
      );
    }
    await pump(FloatingActionButtonLocation.endDocked);
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('bottom_app_bar.custom_shape.1.png'),
    );
    await pump(FloatingActionButtonLocation.centerDocked);
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('bottom_app_bar.custom_shape.2.png'),
    );
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/44572

  testWidgets('Custom Padding', (final WidgetTester tester) async {
    const EdgeInsets customPadding = EdgeInsets.all(10);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.light()),
        home: Builder(
          builder: (final BuildContext context) {
            return const Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: BottomAppBar(
                  padding: customPadding,
                  child: ColoredBox(
                    color: Colors.green,
                    child: SizedBox(width: 300, height: 60),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    final BottomAppBar bottomAppBar = tester.widget(find.byType(BottomAppBar));
    expect(bottomAppBar.padding, customPadding);
    final Rect babRect = tester.getRect(find.byType(BottomAppBar));
    final Rect childRect = tester.getRect(find.byType(ColoredBox));
    expect(childRect, const Rect.fromLTRB(250, 530, 550, 590));
    expect(babRect, const Rect.fromLTRB(240, 520, 560, 600));
  });

  testWidgets('Custom Padding in Material 3', (final WidgetTester tester) async {
    const EdgeInsets customPadding = EdgeInsets.all(10);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.light(), useMaterial3: true),
        home: Builder(
          builder: (final BuildContext context) {
            return const Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: BottomAppBar(
                  padding: customPadding,
                  child: ColoredBox(
                    color: Colors.green,
                    child: SizedBox(width: 300, height: 60),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    final BottomAppBar bottomAppBar = tester.widget(find.byType(BottomAppBar));
    expect(bottomAppBar.padding, customPadding);
    final Rect babRect = tester.getRect(find.byType(BottomAppBar));
    final Rect childRect = tester.getRect(find.byType(ColoredBox));
    expect(childRect, const Rect.fromLTRB(250, 530, 550, 590));
    expect(babRect, const Rect.fromLTRB(240, 520, 560, 600));
  });

  testWidgets('color defaults to Theme.bottomAppBarColor', (final WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (final BuildContext context) {
            return Theme(
              data: Theme.of(context).copyWith(bottomAppBarColor: const Color(0xffffff00)),
              child: const Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: null,
                ),
                bottomNavigationBar: BottomAppBar(),
              ),
            );
          },
        ),
      ),
    );

    final PhysicalShape physicalShape =
      tester.widget(find.byType(PhysicalShape).at(0));

    expect(physicalShape.color, const Color(0xffffff00));
  });

  testWidgets('color overrides theme color', (final WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (final BuildContext context) {
            return Theme(
              data: Theme.of(context).copyWith(bottomAppBarColor: const Color(0xffffff00)),
              child: const Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: null,
                ),
                bottomNavigationBar: BottomAppBar(
                  color: Color(0xff0000ff),
                ),
              ),
            );
          },
        ),
      ),
    );

    final PhysicalShape physicalShape =
      tester.widget(find.byType(PhysicalShape).at(0));
    final Material material = tester.widget(find.byType(Material).at(1));

    expect(physicalShape.color, const Color(0xff0000ff));
    expect(material.color, null); /* no value in Material 2. */
  });


  testWidgets('color overrides theme color with Material 3', (final WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true).copyWith(
          bottomAppBarColor: const Color(0xffffff00)),
        home: Builder(
          builder: (final BuildContext context) {
            return const Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: null,
                ),
                bottomNavigationBar: BottomAppBar(
                  color: Color(0xff0000ff),
                  surfaceTintColor: Colors.transparent,
                ),
            );
          },
        ),
      ),
    );

    final PhysicalShape physicalShape = tester.widget(
        find.descendant(of: find.byType(BottomAppBar), matching: find.byType(PhysicalShape)));

    expect(physicalShape.color, const Color(0xff0000ff));
  });

  testWidgets('Shadow color is transparent in Material 3', (final WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true,
        ),
        home: const Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: null,
          ),
          bottomNavigationBar: BottomAppBar(
            color: Color(0xff0000ff),
          ),
        ),
      )
    );

    final PhysicalShape physicalShape = tester.widget(
        find.descendant(of: find.byType(BottomAppBar), matching: find.byType(PhysicalShape)));

    expect(physicalShape.shadowColor, Colors.transparent);
  });

  testWidgets('dark theme applies an elevation overlay color', (final WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.dark()),
        home: Scaffold(
          bottomNavigationBar: BottomAppBar(
            color: const ColorScheme.dark().surface,
          ),
        ),
      ),
    );

    final PhysicalShape physicalShape = tester.widget(find.byType(PhysicalShape).at(0));

    // For the default dark theme the overlay color for elevation 8 is 0xFF2D2D2D
    expect(physicalShape.color, const Color(0xFF2D2D2D));
  });

  // This is a regression test for a bug we had where toggling the notch on/off
  // would crash, as the shouldReclip method of ShapeBorderClipper or
  // _BottomAppBarClipper would try an illegal downcast.
  testWidgets('toggle shape to null', (final WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomAppBar(
            shape: RectangularNotch(),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomAppBar(),
        ),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomAppBar(
            shape: RectangularNotch(),
          ),
        ),
      ),
    );
  });

  testWidgets('no notch when notch param is null', (final WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ShapeListener(BottomAppBar()),
          floatingActionButton: FloatingActionButton(
            onPressed: null,
            child: Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        ),
      ),
    );

    final ShapeListenerState shapeListenerState = tester.state(find.byType(ShapeListener));
    final RenderBox renderBox = tester.renderObject(find.byType(BottomAppBar));
    final Path expectedPath = Path()
      ..addRect(Offset.zero & renderBox.size);

    final Path actualPath = shapeListenerState.cache.value;

    expect(
      actualPath,
      coversSameAreaAs(
        expectedPath,
        areaToCompare: (Offset.zero & renderBox.size).inflate(5.0),
      ),
    );
  });

  testWidgets('notch no margin', (final WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ShapeListener(
            BottomAppBar(
              shape: RectangularNotch(),
              notchMargin: 0.0,
              child: SizedBox(height: 100.0),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: null,
            child: Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        ),
      ),
    );

    final ShapeListenerState shapeListenerState = tester.state(find.byType(ShapeListener));
    final RenderBox babBox = tester.renderObject(find.byType(BottomAppBar));
    final Size babSize = babBox.size;
    final RenderBox fabBox = tester.renderObject(find.byType(FloatingActionButton));
    final Size fabSize = fabBox.size;

    final double fabLeft = (babSize.width / 2.0) - (fabSize.width / 2.0);
    final double fabRight = fabLeft + fabSize.width;
    final double fabBottom = fabSize.height / 2.0;

    final Path expectedPath = Path()
      ..moveTo(0.0, 0.0)
      ..lineTo(fabLeft, 0.0)
      ..lineTo(fabLeft, fabBottom)
      ..lineTo(fabRight, fabBottom)
      ..lineTo(fabRight, 0.0)
      ..lineTo(babSize.width, 0.0)
      ..lineTo(babSize.width, babSize.height)
      ..lineTo(0.0, babSize.height)
      ..close();

    final Path actualPath = shapeListenerState.cache.value;

    expect(
      actualPath,
      coversSameAreaAs(
        expectedPath,
        areaToCompare: (Offset.zero & babSize).inflate(5.0),
      ),
    );
  });

  testWidgets('notch with margin', (final WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ShapeListener(
            BottomAppBar(
              shape: RectangularNotch(),
              notchMargin: 6.0,
              child: SizedBox(height: 100.0),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: null,
            child: Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        ),
      ),
    );

    final ShapeListenerState shapeListenerState = tester.state(find.byType(ShapeListener));
    final RenderBox babBox = tester.renderObject(find.byType(BottomAppBar));
    final Size babSize = babBox.size;
    final RenderBox fabBox = tester.renderObject(find.byType(FloatingActionButton));
    final Size fabSize = fabBox.size;

    final double fabLeft = (babSize.width / 2.0) - (fabSize.width / 2.0) - 6.0;
    final double fabRight = fabLeft + fabSize.width + 6.0;
    final double fabBottom = 6.0 + fabSize.height / 2.0;

    final Path expectedPath = Path()
      ..moveTo(0.0, 0.0)
      ..lineTo(fabLeft, 0.0)
      ..lineTo(fabLeft, fabBottom)
      ..lineTo(fabRight, fabBottom)
      ..lineTo(fabRight, 0.0)
      ..lineTo(babSize.width, 0.0)
      ..lineTo(babSize.width, babSize.height)
      ..lineTo(0.0, babSize.height)
      ..close();

    final Path actualPath = shapeListenerState.cache.value;

    expect(
      actualPath,
      coversSameAreaAs(
        expectedPath,
        areaToCompare: (Offset.zero & babSize).inflate(5.0),
      ),
    );
  });

  testWidgets('observes safe area', (final WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            padding: EdgeInsets.all(50.0),
          ),
          child: Scaffold(
            bottomNavigationBar: BottomAppBar(
              child: Center(
                child: Text('safe'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getBottomLeft(find.widgetWithText(Center, 'safe')),
      const Offset(50.0, 550.0),
    );
  });

  testWidgets('clipBehavior is propagated', (final WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomAppBar(
            shape: RectangularNotch(),
            notchMargin: 0.0,
            child: SizedBox(height: 100.0),
          ),
        ),
      ),
    );

    PhysicalShape physicalShape = tester.widget(find.byType(PhysicalShape));
    expect(physicalShape.clipBehavior, Clip.none);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar:
          BottomAppBar(
            shape: RectangularNotch(),
            notchMargin: 0.0,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: SizedBox(height: 100.0),
          ),
        ),
      ),
    );

    physicalShape = tester.widget(find.byType(PhysicalShape));
    expect(physicalShape.clipBehavior, Clip.antiAliasWithSaveLayer);
  });

  testWidgets('BottomAppBar with shape when Scaffold.bottomNavigationBar == null', (final WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/80878
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.green,
            child: const Icon(Icons.home),
            onPressed: () {},
          ),
          body: Stack(
            children: <Widget>[
              Container(
                color: Colors.amber,
              ),
              Container(
                alignment: Alignment.bottomCenter,
                child: BottomAppBar(
                  color: Colors.green,
                  shape: const CircularNotchedRectangle(),
                  child: Container(height: 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(FloatingActionButton)), const Rect.fromLTRB(372, 528, 428, 584));
    expect(tester.getSize(find.byType(BottomAppBar)), const Size(800, 50));
  });

  testWidgets('notch with margin and top padding, home safe area', (final WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/90024
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          padding: EdgeInsets.only(top: 128),
        ),
        child: MaterialApp(
          useInheritedMediaQuery: true,
          home: SafeArea(
            child: Scaffold(
              bottomNavigationBar: ShapeListener(
                BottomAppBar(
                  shape: RectangularNotch(),
                  notchMargin: 6.0,
                  child: SizedBox(height: 100.0),
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: null,
                child: Icon(Icons.add),
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            ),
          ),
        ),
      ),
    );

    final ShapeListenerState shapeListenerState = tester.state(find.byType(ShapeListener));
    final RenderBox babBox = tester.renderObject(find.byType(BottomAppBar));
    final Size babSize = babBox.size;
    final RenderBox fabBox = tester.renderObject(find.byType(FloatingActionButton));
    final Size fabSize = fabBox.size;

    final double fabLeft = (babSize.width / 2.0) - (fabSize.width / 2.0) - 6.0;
    final double fabRight = fabLeft + fabSize.width + 6.0;
    final double fabBottom = 6.0 + fabSize.height / 2.0;

    final Path expectedPath = Path()
      ..moveTo(0.0, 0.0)
      ..lineTo(fabLeft, 0.0)
      ..lineTo(fabLeft, fabBottom)
      ..lineTo(fabRight, fabBottom)
      ..lineTo(fabRight, 0.0)
      ..lineTo(babSize.width, 0.0)
      ..lineTo(babSize.width, babSize.height)
      ..lineTo(0.0, babSize.height)
      ..close();

    final Path actualPath = shapeListenerState.cache.value;

    expect(
      actualPath,
      coversSameAreaAs(
        expectedPath,
        areaToCompare: (Offset.zero & babSize).inflate(5.0),
      ),
    );
  });

  testWidgets('BottomAppBar does not apply custom clipper without FAB', (final WidgetTester tester) async {
    Widget buildWidget({final Widget? fab}) {
      return MaterialApp(
        home: Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: fab,
          bottomNavigationBar: BottomAppBar(
            color: Colors.green,
            shape: const CircularNotchedRectangle(),
            child: Container(height: 50),
          ),
        ),
      );
    }
    await tester.pumpWidget(buildWidget(fab: FloatingActionButton(onPressed: () { })));

    PhysicalShape physicalShape = tester.widget(find.byType(PhysicalShape).at(0));
    expect(physicalShape.clipper.toString(), '_BottomAppBarClipper');

    await tester.pumpWidget(buildWidget());

    physicalShape = tester.widget(find.byType(PhysicalShape).at(0));
    expect(physicalShape.clipper.toString(), 'ShapeBorderClipper');
  });

  testWidgets('BottomAppBar adds bottom padding to height', (final WidgetTester tester) async {
    const double bottomPadding = 35.0;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(bottom: bottomPadding),
          viewPadding: EdgeInsets.only(bottom: bottomPadding),
        ),
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
            floatingActionButton: FloatingActionButton(onPressed: () { }),
            bottomNavigationBar: BottomAppBar(
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
            ),
          ),
        ),
      )
    );

    final Rect bottomAppBar = tester.getRect(find.byType(BottomAppBar));
    final Rect iconButton = tester.getRect(find.widgetWithIcon(IconButton, Icons.search));
    final Rect fab = tester.getRect(find.byType(FloatingActionButton));

    // The height of the bottom app bar should be its height(default is 80.0) + bottom safe area height.
    expect(bottomAppBar.height, 80.0 + bottomPadding);

    // The vertical position of the icon button and fab should be center of the area excluding the bottom padding.
    final double barCenter = bottomAppBar.topLeft.dy + (bottomAppBar.height - bottomPadding) / 2;
    expect(iconButton.center.dy, barCenter);
    expect(fab.center.dy, barCenter);
  });
}

// The bottom app bar clip path computation is only available at paint time.
// In order to examine the notch path we implement this caching painter which
// at paint time looks for a descendant PhysicalShape and caches the
// clip path it is using.
class ClipCachePainter extends CustomPainter {
  ClipCachePainter(this.context);

  late Path value;
  BuildContext context;

  @override
  void paint(final Canvas canvas, final Size size) {
    final RenderPhysicalShape physicalShape = findPhysicalShapeChild(context)!;
    value = physicalShape.clipper!.getClip(size);
  }

  RenderPhysicalShape? findPhysicalShapeChild(final BuildContext context) {
    RenderPhysicalShape? result;
    context.visitChildElements((final Element e) {
      final RenderObject renderObject = e.findRenderObject()!;
      if (renderObject.runtimeType == RenderPhysicalShape) {
        assert(result == null);
        result = renderObject as RenderPhysicalShape;
      } else {
        result = findPhysicalShapeChild(e);
      }
    });
    return result;
  }

  @override
  bool shouldRepaint(final ClipCachePainter oldDelegate) {
    return true;
  }
}

class ShapeListener extends StatefulWidget {
  const ShapeListener(this.child, { super.key });

  final Widget child;

  @override
  State createState() => ShapeListenerState();

}

class ShapeListenerState extends State<ShapeListener> {
  @override
  Widget build(final BuildContext context) {
    return CustomPaint(
      painter: cache,
      child: widget.child,
    );
  }

  late ClipCachePainter cache;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cache = ClipCachePainter(context);
  }

}

class RectangularNotch extends NotchedShape {
  const RectangularNotch();

  @override
  Path getOuterPath(final Rect host, final Rect? guest) {
    if (guest == null) {
      return Path()..addRect(host);
    }
    return Path()
      ..moveTo(host.left, host.top)
      ..lineTo(guest.left, host.top)
      ..lineTo(guest.left, guest.bottom)
      ..lineTo(guest.right, guest.bottom)
      ..lineTo(guest.right, host.top)
      ..lineTo(host.right, host.top)
      ..lineTo(host.right, host.bottom)
      ..lineTo(host.left, host.bottom)
      ..close();
  }
}
