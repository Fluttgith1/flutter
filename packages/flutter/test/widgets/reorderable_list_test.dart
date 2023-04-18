// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('SliverReorderableList works well when having gestureSettings', (final WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/103404
    const int itemCount = 5;
    int onReorderCallCount = 0;
    final List<int> items = List<int>.generate(itemCount, (final int index) => index);

    void handleReorder(final int fromIndex, int toIndex) {
      onReorderCallCount += 1;
      if (toIndex > fromIndex) {
        toIndex -= 1;
      }
      items.insert(toIndex, items.removeAt(fromIndex));
    }
    // The list has five elements of height 100
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(gestureSettings: DeviceGestureSettings(touchSlop: 8.0)),
          child: CustomScrollView(
            slivers: <Widget>[
              SliverReorderableList(
                itemCount: itemCount,
                itemBuilder: (final BuildContext context, final int index) {
                  return SizedBox(
                    key: ValueKey<int>(items[index]),
                    height: 100,
                    child: ReorderableDragStartListener(
                      index: index,
                      child: Text('item ${items[index]}'),
                    ),
                  );
                },
                onReorder: handleReorder,
              )
            ],
          ),
        ),
      ),
    );

    // Start gesture on first item
    final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 0')));
    await tester.pump(kPressTimeout);

    // Drag a little bit to make `ImmediateMultiDragGestureRecognizer` compete with `VerticalDragGestureRecognizer`
    await drag.moveBy(const Offset(0, 10));
    await tester.pump();
    // Drag enough to move down the first item
    await drag.moveBy(const Offset(0, 40));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();

    expect(onReorderCallCount, 1);
    expect(items, orderedEquals(<int>[1, 0, 2, 3, 4]));
  });

  testWidgets('SliverReorderableList item has correct semantics', (final WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const int itemCount = 5;
    int onReorderCallCount = 0;
    final List<int> items = List<int>.generate(itemCount, (final int index) => index);

    void handleReorder(final int fromIndex, int toIndex) {
      onReorderCallCount += 1;
      if (toIndex > fromIndex) {
        toIndex -= 1;
      }
      items.insert(toIndex, items.removeAt(fromIndex));
    }
    // The list has five elements of height 100
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(gestureSettings: DeviceGestureSettings(touchSlop: 8.0)),
          child: CustomScrollView(
            slivers: <Widget>[
              SliverReorderableList(
                itemCount: itemCount,
                itemBuilder: (final BuildContext context, final int index) {
                  return SizedBox(
                    key: ValueKey<int>(items[index]),
                    height: 100,
                    child: ReorderableDragStartListener(
                      index: index,
                      child: Text('item ${items[index]}'),
                    ),
                  );
                },
                onReorder: handleReorder,
              )
            ],
          ),
        ),
      ),
    );

    expect(
      semantics,
      includesNodeWith(
        label: 'item 0',
        actions: <SemanticsAction>[SemanticsAction.customAction],
      ),
    );
    final SemanticsNode node = tester.getSemantics(find.text('item 0'));

    // perform custom action 'move down'.
    tester.binding.pipelineOwner.semanticsOwner!.performAction(node.id, SemanticsAction.customAction, 0);
    await tester.pumpAndSettle();

    expect(onReorderCallCount, 1);
    expect(items, orderedEquals(<int>[1, 0, 2, 3, 4]));

    semantics.dispose();
  });

  testWidgets('SliverReorderableList custom semantics action has correct label', (final WidgetTester tester) async {
    const int itemCount = 5;
    final List<int> items = List<int>.generate(itemCount, (final int index) => index);
    // The list has five elements of height 100
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(gestureSettings: DeviceGestureSettings(touchSlop: 8.0)),
          child: CustomScrollView(
            slivers: <Widget>[
              SliverReorderableList(
                itemCount: itemCount,
                itemBuilder: (final BuildContext context, final int index) {
                  return SizedBox(
                    key: ValueKey<int>(items[index]),
                    height: 100,
                    child: ReorderableDragStartListener(
                      index: index,
                      child: Text('item ${items[index]}'),
                    ),
                  );
                },
                onReorder: (final int _, final int __) { },
              )
            ],
          ),
        ),
      ),
    );
    final SemanticsNode node = tester.getSemantics(find.text('item 0'));
    final SemanticsData data = node.getSemanticsData();
    expect(data.customSemanticsActionIds!.length, 2);
    final CustomSemanticsAction action1 = CustomSemanticsAction.getAction(data.customSemanticsActionIds![0])!;
    expect(action1.label, 'Move down');
    final CustomSemanticsAction action2 = CustomSemanticsAction.getAction(data.customSemanticsActionIds![1])!;
    expect(action2.label, 'Move to the end');
  });

  // Regression test for https://github.com/flutter/flutter/issues/100451
  testWidgets('SliverReorderableList.builder respects findChildIndexCallback', (final WidgetTester tester) async {
    bool finderCalled = false;
    int itemCount = 7;
    late StateSetter stateSetter;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (final BuildContext context, final StateSetter setState) {
            stateSetter = setState;
            return CustomScrollView(
              slivers: <Widget>[
                SliverReorderableList(
                  itemCount: itemCount,
                  itemBuilder: (final BuildContext _, final int index) => Container(
                    key: Key('$index'),
                    height: 2000.0,
                  ),
                  findChildIndexCallback: (final Key key) {
                    finderCalled = true;
                    return null;
                  },
                  onReorder: (final int oldIndex, final int newIndex) { },
                ),
              ],
            );
          },
        ),
      )
    );
    expect(finderCalled, false);

    // Trigger update.
    stateSetter(() => itemCount = 77);
    await tester.pump();

    expect(finderCalled, true);
  });

  // Regression test for https://github.com/flutter/flutter/issues/88191
  testWidgets('Do not crash when dragging with two fingers simultaneously', (final WidgetTester tester) async {
    final List<int> items = List<int>.generate(3, (final int index) => index);
    void handleReorder(final int fromIndex, int toIndex) {
      if (toIndex > fromIndex) {
        toIndex -= 1;
      }
      items.insert(toIndex, items.removeAt(fromIndex));
    }

    await tester.pumpWidget(MaterialApp(
      home: ReorderableList(
        itemBuilder: (final BuildContext context, final int index) {
          return ReorderableDragStartListener(
            index: index,
            key: ValueKey<int>(items[index]),
            child: SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('item ${items[index]}'),
                ],
              ),
            ),
          );
        },
        itemCount: items.length,
        onReorder: handleReorder,
      ),
    ));

    final TestGesture drag1 = await tester.startGesture(tester.getCenter(find.text('item 0')));
    final TestGesture drag2 = await tester.startGesture(tester.getCenter(find.text('item 0')));
    await tester.pump(kLongPressTimeout);

    await drag1.moveBy(const Offset(0, 100));
    await drag2.moveBy(const Offset(0, 100));
    await tester.pumpAndSettle();

    await drag1.up();
    await drag2.up();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('negative itemCount should assert', (final WidgetTester tester) async {
    final List<int> items = <int>[1, 2, 3];
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (final BuildContext outerContext, final StateSetter setState) {
          return CustomScrollView(
            slivers: <Widget>[
              SliverReorderableList(
                itemCount: -1,
                onReorder: (final int fromIndex, int toIndex) {
                  setState(() {
                    if (toIndex > fromIndex) {
                      toIndex -= 1;
                    }
                    items.insert(toIndex, items.removeAt(fromIndex));
                  });
                },
                itemBuilder: (final BuildContext context, final int index) {
                  return SizedBox(
                    height: 100,
                    child: Text('item ${items[index]}'),
                  );
                },
              ),
            ],
          );
        },
      ),
    ));
    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('zero itemCount should not build widget', (final WidgetTester tester) async {
    final List<int> items = <int>[1, 2, 3];
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (final BuildContext outerContext, final StateSetter setState) {
          return CustomScrollView(
            slivers: <Widget>[
              SliverFixedExtentList(
                itemExtent: 50.0,
                delegate: SliverChildListDelegate(<Widget>[
                  const Text('before'),
                ]),
              ),
              SliverReorderableList(
                itemCount: 0,
                onReorder: (final int fromIndex, int toIndex) {
                  setState(() {
                    if (toIndex > fromIndex) {
                      toIndex -= 1;
                    }
                    items.insert(toIndex, items.removeAt(fromIndex));
                  });
                },
                itemBuilder: (final BuildContext context, final int index) {
                  return SizedBox(
                    height: 100,
                    child: Text('item ${items[index]}'),
                  );
                },
              ),
              SliverFixedExtentList(
                itemExtent: 50.0,
                delegate: SliverChildListDelegate(<Widget>[
                  const Text('after'),
                ]),
              ),
            ],
          );
        },
      ),
    ));

    expect(find.text('before'), findsOneWidget);
    expect(find.byType(SliverReorderableList), findsNothing);
    expect(find.text('after'), findsOneWidget);
  });

  testWidgets('SliverReorderableList, drag and drop, fixed height items', (final WidgetTester tester) async {
    final List<int> items = List<int>.generate(8, (final int index) => index);

    Future<void> pressDragRelease(final Offset start, final Offset delta) async {
      final TestGesture drag = await tester.startGesture(start);
      await tester.pump(kPressTimeout);
      await drag.moveBy(delta);
      await tester.pump(kPressTimeout);
      await drag.up();
      await tester.pumpAndSettle();
    }

    void check({ final List<int> visible = const <int>[], final List<int> hidden = const <int>[] }) {
      for (final int i in visible) {
        expect(find.text('item $i'), findsOneWidget);
      }
      for (final int i in hidden) {
        expect(find.text('item $i'), findsNothing);
      }
    }

    // The SliverReorderableList is 800x600, 8 items, each item is 800x100 with
    // an "item $index" text widget at the item's origin.  Drags are initiated by
    // a simple press on the text widget.
    await tester.pumpWidget(TestList(items: items));
    check(visible: <int>[0, 1, 2, 3, 4, 5], hidden: <int>[6, 7]);

    // Drag item 0 downwards less than halfway and let it snap back. List
    // should remain as it is.
    await pressDragRelease(const Offset(12, 50), const Offset(12, 60));
    check(visible: <int>[0, 1, 2, 3, 4, 5], hidden: <int>[6, 7]);
    expect(tester.getTopLeft(find.text('item 0')), Offset.zero);
    expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 100));
    expect(items, orderedEquals(<int>[0, 1, 2, 3, 4, 5, 6, 7]));

    // Drag item 0 downwards more than halfway to displace item 1.
    await pressDragRelease(tester.getCenter(find.text('item 0')), const Offset(0, 51));
    check(visible: <int>[0, 1, 2, 3, 4, 5], hidden: <int>[6, 7]);
    expect(tester.getTopLeft(find.text('item 1')), Offset.zero);
    expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 100));
    expect(items, orderedEquals(<int>[1, 0, 2, 3, 4, 5, 6, 7]));

    // Drag item 0 back to where it was.
    await pressDragRelease(tester.getCenter(find.text('item 0')), const Offset(0, -51));
    check(visible: <int>[0, 1, 2, 3, 4, 5], hidden: <int>[6, 7]);
    expect(tester.getTopLeft(find.text('item 0')), Offset.zero);
    expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 100));
    expect(items, orderedEquals(<int>[0, 1, 2, 3, 4, 5, 6, 7]));

    // Drag item 1 to item 3
    await pressDragRelease(tester.getCenter(find.text('item 1')), const Offset(0, 151));
    check(visible: <int>[0, 1, 2, 3, 4, 5], hidden: <int>[6, 7]);
    expect(tester.getTopLeft(find.text('item 0')), Offset.zero);
    expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 300));
    expect(tester.getTopLeft(find.text('item 3')), const Offset(0, 200));
    expect(items, orderedEquals(<int>[0, 2, 3, 1, 4, 5, 6, 7]));

    // Drag item 1 back to where it was
    await pressDragRelease(tester.getCenter(find.text('item 1')), const Offset(0, -200));
    check(visible: <int>[0, 1, 2, 3, 4, 5], hidden: <int>[6, 7]);
    expect(tester.getTopLeft(find.text('item 0')), Offset.zero);
    expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 100));
    expect(tester.getTopLeft(find.text('item 3')), const Offset(0, 300));
    expect(items, orderedEquals(<int>[0, 1, 2, 3, 4, 5, 6, 7]));
  });

  testWidgets('SliverReorderableList, items inherit DefaultTextStyle, IconTheme', (final WidgetTester tester) async {
    const Color textColor = Color(0xffffffff);
    const Color iconColor = Color(0xff0000ff);

    TextStyle getIconStyle() {
      return tester.widget<RichText>(
        find.descendant(
          of: find.byType(Icon),
          matching: find.byType(RichText),
        ),
      ).text.style!;
    }

    TextStyle getTextStyle() {
      return tester.widget<RichText>(
        find.descendant(
          of: find.text('item 0'),
          matching: find.byType(RichText),
        ),
      ).text.style!;
    }

    // This SliverReorderableList has just one item: "item 0".
    await tester.pumpWidget(
      TestList(
        items: List<int>.from(<int>[0]),
        textColor: textColor,
        iconColor: iconColor,
      ),
    );
    expect(tester.getTopLeft(find.text('item 0')), Offset.zero);
    expect(getIconStyle().color, iconColor);
    expect(getTextStyle().color, textColor);

    // Dragging item 0 causes it to be reparented in the overlay. The item
    // should still inherit the IconTheme and DefaultTextStyle because they are
    // InheritedThemes.
    final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 0')));
    await tester.pump(kPressTimeout);
    await drag.moveBy(const Offset(0, 50));
    await tester.pump(kPressTimeout);
    expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 50));
    expect(getIconStyle().color, iconColor);
    expect(getTextStyle().color, textColor);

    // Drag is complete, item 0 returns to where it was.
    await drag.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('item 0')), Offset.zero);
    expect(getIconStyle().color, iconColor);
    expect(getTextStyle().color, textColor);
  });

  testWidgets('SliverReorderableList - custom proxyDecorator', (final WidgetTester tester) async {
    const ValueKey<String> fadeTransitionKey = ValueKey<String>('reordered-fade');

    await tester.pumpWidget(
      TestList(
        items: List<int>.from(<int>[0, 1, 2, 3]),
        proxyDecorator: (
            final Widget child,
            final int index,
            final Animation<double> animation,
            ) {
          return AnimatedBuilder(
            animation: animation,
            builder: (final BuildContext context, final Widget? child) {
              final Tween<double> fadeValues = Tween<double>(begin: 1.0, end: 0.5);
              final Animation<double> fadeAnimation = animation.drive(fadeValues);
              return FadeTransition(
                key: fadeTransitionKey,
                opacity: fadeAnimation,
                child: child,
              );
            },
            child: child,
          );
        },
      ),
    );

    Finder getItemFadeTransition() => find.byKey(fadeTransitionKey);

    expect(getItemFadeTransition(), findsNothing);

    // Start gesture on first item
    final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 0')));
    await tester.pump(kPressTimeout);

    // Drag enough for transition animation defined in proxyDecorator to start.
    await drag.moveBy(const Offset(0, 50));
    await tester.pump();

    // At the start, opacity should be at 1.0.
    expect(getItemFadeTransition(), findsOneWidget);
    FadeTransition fadeTransition = tester.widget(getItemFadeTransition());
    expect(fadeTransition.opacity.value, 1.0);

    // Let animation run halfway.
    await tester.pump(const Duration(milliseconds: 125));
    fadeTransition = tester.widget(getItemFadeTransition());
    expect(fadeTransition.opacity.value, greaterThan(0.5));
    expect(fadeTransition.opacity.value, lessThan(1.0));

    // Allow animation to run to the end.
    await tester.pumpAndSettle();
    expect(find.byKey(fadeTransitionKey), findsOneWidget);
    fadeTransition = tester.widget(getItemFadeTransition());
    expect(fadeTransition.opacity.value, 0.5);

    // Finish reordering.
    await drag.up();
    await tester.pumpAndSettle();
    expect(getItemFadeTransition(), findsNothing);
  });

  testWidgets('ReorderableList supports items with nested list views without throwing layout exception.', (final WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) {
          return MediaQuery(
            // Ensure there is always a top padding to simulate a phone with
            // safe area at the top. If the nested list doesn't have the
            // padding removed before it is put into the overlay it will
            // overflow the layout by the top padding.
            data: MediaQuery.of(context).copyWith(padding: const EdgeInsets.only(top: 50)),
            child: child!,
          );
        },
        home: Scaffold(
          appBar: AppBar(title: const Text('Nested Lists')),
          body: ReorderableList(
            itemCount: 10,
            itemBuilder: (final BuildContext context, final int index) {
              return ReorderableDragStartListener(
                index: index,
                key: ValueKey<int>(index),
                child: Column(
                  children: <Widget>[
                    ListView(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      children: const <Widget>[
                        Text('Other data'),
                        Text('Other data'),
                        Text('Other data'),
                      ],
                    ),
                  ],
                ),
              );
            },
            onReorder: (final int oldIndex, final int newIndex) {},
          ),
        ),
      ),
    );

    // Start gesture on first item
    final TestGesture drag = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey<int>(0))));
    await tester.pump(kPressTimeout);

    // Drag enough for move to start
    await drag.moveBy(const Offset(0, 50));
    await tester.pumpAndSettle();

    // There shouldn't be a layout overflow exception.
    expect(tester.takeException(), isNull);
  });

  testWidgets('ReorderableList supports items with nested list views without throwing layout exception.', (final WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/83224.
    await tester.pumpWidget(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) {
          return MediaQuery(
            // Ensure there is always a top padding to simulate a phone with
            // safe area at the top. If the nested list doesn't have the
            // padding removed before it is put into the overlay it will
            // overflow the layout by the top padding.
            data: MediaQuery.of(context).copyWith(padding: const EdgeInsets.only(top: 50)),
            child: child!,
          );
        },
        home: Scaffold(
          appBar: AppBar(title: const Text('Nested Lists')),
          body: ReorderableList(
            itemCount: 10,
            itemBuilder: (final BuildContext context, final int index) {
              return ReorderableDragStartListener(
                index: index,
                key: ValueKey<int>(index),
                child: Column(
                  children: <Widget>[
                    ListView(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      children: const <Widget>[
                        Text('Other data'),
                        Text('Other data'),
                        Text('Other data'),
                      ],
                    ),
                  ],
                ),
              );
            },
            onReorder: (final int oldIndex, final int newIndex) {},
          ),
        ),
      ),
    );

    // Start gesture on first item.
    final TestGesture drag = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey<int>(0))));
    await tester.pump(kPressTimeout);

    // Drag enough for move to start.
    await drag.moveBy(const Offset(0, 50));
    await tester.pumpAndSettle();

    // There shouldn't be a layout overflow exception.
    expect(tester.takeException(), isNull);
  });

  testWidgets('SliverReorderableList - properly animates the drop in a reversed list', (final WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/110949
    final List<int> items = List<int>.generate(8, (final int index) => index);

    Future<void> pressDragRelease(final Offset start, final Offset delta) async {
      final TestGesture drag = await tester.startGesture(start);
      await tester.pump(kPressTimeout);
      await drag.moveBy(delta);
      await tester.pumpAndSettle();
      await drag.up();
      await tester.pump();
    }

    // The TestList is 800x600 SliverReorderableList with 8 items 800x100 each.
    // Each item has a text widget with 'item $index' that can be moved by a
    // press and drag gesture. For this test we are reversing the order so
    // the first item is at the bottom.
    await tester.pumpWidget(TestList(items: items, reverse: true));

    expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 500));
    expect(tester.getTopLeft(find.text('item 2')), const Offset(0, 300));

    // Drag item 0 up and insert it between item 1 and item 2. It should
    // smoothly animate.
    await pressDragRelease(tester.getCenter(find.text('item 0')), const Offset(0, -50));
    expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 450));
    expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 500));
    expect(tester.getTopLeft(find.text('item 2')), const Offset(0, 300));

    // After the first several frames we should be moving closer to the final position,
    // not further away as was the case with the original bug.
    await tester.pump(const Duration(milliseconds: 10));
    expect(tester.getTopLeft(find.text('item 0')).dy, lessThan(450));
    expect(tester.getTopLeft(find.text('item 0')).dy, greaterThan(400));

    // Sample the middle (don't use exact values as it depends on the internal
    // curve being used).
    await tester.pump(const Duration(milliseconds: 125));
    expect(tester.getTopLeft(find.text('item 0')).dy, lessThan(450));
    expect(tester.getTopLeft(find.text('item 0')).dy, greaterThan(400));

    // Sample the end of the animation.
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(find.text('item 0')).dy, lessThan(450));
    expect(tester.getTopLeft(find.text('item 0')).dy, greaterThan(400));

    // Wait for it to finish, it should be back to the original position
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 400));
  });

  testWidgets('SliverReorderableList - properly animates the drop at starting position in a reversed list', (final WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/84625
    final List<int> items = List<int>.generate(8, (final int index) => index);

    Future<void> pressDragRelease(final Offset start, final Offset delta) async {
      final TestGesture drag = await tester.startGesture(start);
      await tester.pump(kPressTimeout);
      await drag.moveBy(delta);
      await tester.pumpAndSettle();
      await drag.up();
      await tester.pump();
    }

    // The TestList is 800x600 SliverReorderableList with 8 items 800x100 each.
    // Each item has a text widget with 'item $index' that can be moved by a
    // press and drag gesture. For this test we are reversing the order so
    // the first item is at the bottom.
    await tester.pumpWidget(TestList(items: items, reverse: true));

    expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 500));
    expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 400));

    // Drag item 0 downwards off the edge and let it snap back. It should
    // smoothly animate back up.
    await pressDragRelease(tester.getCenter(find.text('item 0')), const Offset(0, 50));
    expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 550));
    expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 400));

    // After the first several frames we should be moving closer to the final position,
    // not further away as was the case with the original bug.
    await tester.pump(const Duration(milliseconds: 10));
    expect(tester.getTopLeft(find.text('item 0')).dy, lessThan(550));

    // Sample the middle (don't use exact values as it depends on the internal
    // curve being used).
    await tester.pump(const Duration(milliseconds: 125));
    expect(tester.getTopLeft(find.text('item 0')).dy, lessThan(550));

    // Wait for it to finish, it should be back to the original position
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 500));
  });

  testWidgets('SliverReorderableList calls onReorderStart and onReorderEnd correctly', (final WidgetTester tester) async {
    final List<int> items = List<int>.generate(8, (final int index) => index);
    int? startIndex, endIndex;
    final Finder item0 = find.textContaining('item 0');

    await tester.pumpWidget(TestList(
      items: items,
      onReorderStart: (final int index) {
        startIndex = index;
      },
      onReorderEnd: (final int index) {
        endIndex = index;
      },
    ));

    TestGesture drag = await tester.startGesture(tester.getCenter(item0));
    await tester.pump(kPressTimeout);
    // Drag enough for move to start.
    await drag.moveBy(const Offset(0, 20));

    expect(startIndex, equals(0));
    expect(endIndex, isNull);

    // Move item0 from index 0 to index 3
    await drag.moveBy(const Offset(0, 300));
    await tester.pumpAndSettle();
    await drag.up();
    await tester.pumpAndSettle();

    expect(endIndex, equals(3));

    startIndex = null;
    endIndex = null;

    drag = await tester.startGesture(tester.getCenter(item0));
    await tester.pump(kPressTimeout);
    // Drag enough for move to start.
    await drag.moveBy(const Offset(0, 20));

    expect(startIndex, equals(2));
    expect(endIndex, isNull);

    // Move item0 from index 2 to index 0
    await drag.moveBy(const Offset(0, -200));
    await tester.pumpAndSettle();
    await drag.up();
    await tester.pumpAndSettle();

    expect(endIndex, equals(0));
  });

  testWidgets('ReorderableList calls onReorderStart and onReorderEnd correctly', (final WidgetTester tester) async {
    final List<int> items = List<int>.generate(8, (final int index) => index);
    int? startIndex, endIndex;
    final Finder item0 = find.textContaining('item 0');

    void handleReorder(final int fromIndex, int toIndex) {
      if (toIndex > fromIndex) {
        toIndex -= 1;
      }
      items.insert(toIndex, items.removeAt(fromIndex));
    }

    await tester.pumpWidget(MaterialApp(
      home: ReorderableList(
        itemCount: items.length,
        itemBuilder: (final BuildContext context, final int index) {
          return SizedBox(
            key: ValueKey<int>(items[index]),
            height: 100,
            child: ReorderableDelayedDragStartListener(
              index: index,
              child: Text('item ${items[index]}'),
            ),
          );
        },
        onReorder: handleReorder,
        onReorderStart: (final int index) {
          startIndex = index;
        },
        onReorderEnd: (final int index) {
          endIndex = index;
        },
      ),
    ));

    TestGesture drag = await tester.startGesture(tester.getCenter(item0));
    await tester.pump(kLongPressTimeout);
    // Drag enough for move to start.
    await drag.moveBy(const Offset(0, 20));

    expect(startIndex, equals(0));
    expect(endIndex, isNull);

    // Move item0 from index 0 to index 3
    await drag.moveBy(const Offset(0, 300));
    await tester.pumpAndSettle();
    await drag.up();
    await tester.pumpAndSettle();

    expect(endIndex, equals(3));

    startIndex = null;
    endIndex = null;

    drag = await tester.startGesture(tester.getCenter(item0));
    await tester.pump(kLongPressTimeout);
    // Drag enough for move to start.
    await drag.moveBy(const Offset(0, 20));

    expect(startIndex, equals(2));
    expect(endIndex, isNull);

    // Move item0 from index 2 to index 0
    await drag.moveBy(const Offset(0, -200));
    await tester.pumpAndSettle();
    await drag.up();
    await tester.pumpAndSettle();

    expect(endIndex, equals(0));
  });



  testWidgets('ReorderableList asserts on both non-null itemExtent and prototypeItem', (final WidgetTester tester) async {
    final List<int> numbers = <int>[0,1,2];
    expect(() => ReorderableList(
      itemBuilder: (final BuildContext context, final int index) {
        return SizedBox(
            key: ValueKey<int>(numbers[index]),
            height: 20 + numbers[index] * 10,
            child: ReorderableDragStartListener(
              index: index,
              child: Text(numbers[index].toString()),
            )
        );
      },
      itemCount: numbers.length,
      itemExtent: 30,
      prototypeItem: const SizedBox(),
      onReorder: (final int fromIndex, final int toIndex) { },
    ), throwsAssertionError);
  });

  testWidgets('SliverReorderableList asserts on both non-null itemExtent and prototypeItem', (final WidgetTester tester) async {
    final List<int> numbers = <int>[0,1,2];
    expect(() => SliverReorderableList(
      itemBuilder: (final BuildContext context, final int index) {
        return SizedBox(
            key: ValueKey<int>(numbers[index]),
            height: 20 + numbers[index] * 10,
            child: ReorderableDragStartListener(
              index: index,
              child: Text(numbers[index].toString()),
            )
        );
      },
      itemCount: numbers.length,
      itemExtent: 30,
      prototypeItem: const SizedBox(),
      onReorder: (final int fromIndex, final int toIndex) { },
    ), throwsAssertionError);
  });

  testWidgets('if itemExtent is non-null, children have same extent in the scroll direction', (final WidgetTester tester) async {
    final List<int> numbers = <int>[0,1,2];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (final BuildContext context, final StateSetter setState) {
              return ReorderableList(
                itemBuilder: (final BuildContext context, final int index) {
                  return SizedBox(
                    key: ValueKey<int>(numbers[index]),
                    // children with different heights
                    height: 20 + numbers[index] * 10,
                    child: ReorderableDragStartListener(
                      index: index,
                      child: Text(numbers[index].toString()),
                    )
                  );
                },
                itemCount: numbers.length,
                itemExtent: 30,
                onReorder: (final int fromIndex, int toIndex) {
                  if (fromIndex < toIndex) {
                    toIndex--;
                  }
                  final int value = numbers.removeAt(fromIndex);
                  numbers.insert(toIndex, value);
                },
              );
            },
          ),
        ),
      )
    );

    final double item0Height = tester.getSize(find.text('0').hitTestable()).height;
    final double item1Height = tester.getSize(find.text('1').hitTestable()).height;
    final double item2Height = tester.getSize(find.text('2').hitTestable()).height;

    expect(item0Height, 30.0);
    expect(item1Height, 30.0);
    expect(item2Height, 30.0);
  });

  testWidgets('if prototypeItem is non-null, children have same extent in the scroll direction', (final WidgetTester tester) async {
    final List<int> numbers = <int>[0,1,2];

    await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (final BuildContext context, final StateSetter setState) {
                return ReorderableList(
                  itemBuilder: (final BuildContext context, final int index) {
                    return SizedBox(
                        key: ValueKey<int>(numbers[index]),
                        // children with different heights
                        height: 20 + numbers[index] * 10,
                        child: ReorderableDragStartListener(
                          index: index,
                          child: Text(numbers[index].toString()),
                        )
                    );
                  },
                  itemCount: numbers.length,
                  prototypeItem: const SizedBox(
                    height: 30,
                    child: Text('3'),
                  ),
                  onReorder: (final int oldIndex, final int newIndex) {  },
                );
              },
            ),
          ),
        )
    );

    final double item0Height = tester.getSize(find.text('0').hitTestable()).height;
    final double item1Height = tester.getSize(find.text('1').hitTestable()).height;
    final double item2Height = tester.getSize(find.text('2').hitTestable()).height;

    expect(item0Height, 30.0);
    expect(item1Height, 30.0);
    expect(item2Height, 30.0);
  });

  group('ReorderableDragStartListener', () {
    testWidgets('It should allow the item to be dragged when enabled is true', (final WidgetTester tester) async {
      const int itemCount = 5;
      int onReorderCallCount = 0;
      final List<int> items = List<int>.generate(itemCount, (final int index) => index);

      void handleReorder(final int fromIndex, int toIndex) {
        onReorderCallCount += 1;
        if (toIndex > fromIndex) {
          toIndex -= 1;
        }
        items.insert(toIndex, items.removeAt(fromIndex));
      }
      // The list has five elements of height 100
      await tester.pumpWidget(
        MaterialApp(
          home: ReorderableList(
            itemCount: itemCount,
            itemBuilder: (final BuildContext context, final int index) {
              return SizedBox(
                key: ValueKey<int>(items[index]),
                height: 100,
                child: ReorderableDragStartListener(
                  index: index,
                  child: Text('item ${items[index]}'),
                ),
              );
            },
            onReorder: handleReorder,
          ),
        ),
      );

      // Start gesture on first item
      final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 0')));
      await tester.pump(kPressTimeout);

      // Drag enough to move down the first item
      await drag.moveBy(const Offset(0, 50));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      expect(onReorderCallCount, 1);
      expect(items, orderedEquals(<int>[1, 0, 2, 3, 4]));
    });

    testWidgets('It should not allow the item to be dragged when enabled is false', (final WidgetTester tester) async {
      const int itemCount = 5;
      int onReorderCallCount = 0;
      final List<int> items = List<int>.generate(itemCount, (final int index) => index);

      void handleReorder(final int fromIndex, int toIndex) {
        onReorderCallCount += 1;
        if (toIndex > fromIndex) {
          toIndex -= 1;
        }
        items.insert(toIndex, items.removeAt(fromIndex));
      }
      // The list has five elements of height 100
      await tester.pumpWidget(
        MaterialApp(
          home: ReorderableList(
            itemCount: itemCount,
            itemBuilder: (final BuildContext context, final int index) {
              return SizedBox(
                key: ValueKey<int>(items[index]),
                height: 100,
                child: ReorderableDragStartListener(
                  index: index,
                  enabled: false,
                  child: Text('item ${items[index]}'),
                ),
              );
            },
            onReorder: handleReorder,
          ),
        ),
      );

      // Start gesture on first item
      final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 0')));
      await tester.pump(kLongPressTimeout);

      // Drag enough to move down the first item
      await drag.moveBy(const Offset(0, 50));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      expect(onReorderCallCount, 0);
      expect(items, orderedEquals(<int>[0, 1, 2, 3, 4]));
    });
  });

  group('ReorderableDelayedDragStartListener', () {
    testWidgets('It should allow the item to be dragged when enabled is true', (final WidgetTester tester) async {
      const int itemCount = 5;
      int onReorderCallCount = 0;
      final List<int> items = List<int>.generate(itemCount, (final int index) => index);

      void handleReorder(final int fromIndex, int toIndex) {
        onReorderCallCount += 1;
        if (toIndex > fromIndex) {
          toIndex -= 1;
        }
        items.insert(toIndex, items.removeAt(fromIndex));
      }
      // The list has five elements of height 100
      await tester.pumpWidget(
        MaterialApp(
          home: ReorderableList(
            itemCount: itemCount,
            itemBuilder: (final BuildContext context, final int index) {
              return SizedBox(
                key: ValueKey<int>(items[index]),
                height: 100,
                child: ReorderableDelayedDragStartListener(
                  index: index,
                  child: Text('item ${items[index]}'),
                ),
              );
            },
            onReorder: handleReorder,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start gesture on first item
      final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 0')));
      await tester.pump(kLongPressTimeout);

      // Drag enough to move down the first item
      await drag.moveBy(const Offset(0, 50));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      expect(onReorderCallCount, 1);
      expect(items, orderedEquals(<int>[1, 0, 2, 3, 4]));
    });

    testWidgets('It should not allow the item to be dragged when enabled is false', (final WidgetTester tester) async {
      const int itemCount = 5;
      int onReorderCallCount = 0;
      final List<int> items = List<int>.generate(itemCount, (final int index) => index);

      void handleReorder(final int fromIndex, int toIndex) {
        onReorderCallCount += 1;
        if (toIndex > fromIndex) {
          toIndex -= 1;
        }
        items.insert(toIndex, items.removeAt(fromIndex));
      }
      // The list has five elements of height 100
      await tester.pumpWidget(
        MaterialApp(
          home: ReorderableList(
            itemCount: itemCount,
            itemBuilder: (final BuildContext context, final int index) {
              return SizedBox(
                key: ValueKey<int>(items[index]),
                height: 100,
                child: ReorderableDelayedDragStartListener(
                  index: index,
                  enabled: false,
                  child: Text('item ${items[index]}'),
                ),
              );
            },
            onReorder: handleReorder,
          ),
        ),
      );

      // Start gesture on first item
      final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 0')));
      await tester.pump(kLongPressTimeout);

      // Drag enough to move down the first item
      await drag.moveBy(const Offset(0, 50));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      expect(onReorderCallCount, 0);
      expect(items, orderedEquals(<int>[0, 1, 2, 3, 4]));
    });
  });

  testWidgets('SliverReorderableList properly disposes items', (final WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/105010
    const int itemCount = 5;
    final List<int> items = List<int>.generate(itemCount, (final int index) => index);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(),
          drawer: Drawer(
            child: Builder(
              builder: (final BuildContext context) {
                return Column(
                  children: <Widget>[
                    Expanded(
                      child: CustomScrollView(
                        slivers: <Widget>[
                          SliverReorderableList(
                            itemCount: itemCount,
                            itemBuilder: (final BuildContext context, final int index) {
                              return Material(
                                key: ValueKey<String>('item-$index'),
                                child: ReorderableDragStartListener(
                                  index: index,
                                  child: ListTile(
                                    title: Text('item ${items[index]}'),
                                  ),
                                ),
                              );
                            },
                            onReorder: (final int oldIndex, final int newIndex) {},
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Scaffold.of(context).closeDrawer();
                      },
                      child: const Text('Close drawer'),
                    ),
                  ],
                );
              }
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    final Finder item0 = find.text('item 0');
    expect(item0, findsOneWidget);

    // Start gesture on first item without drag up event.
    final TestGesture drag = await tester.startGesture(tester.getCenter(item0));
    await drag.moveBy(const Offset(0, 200));
    await tester.pump();

    await tester.tap(find.text('Close drawer'));
    await tester.pumpAndSettle();

    expect(item0, findsNothing);
  });

  testWidgets('SliverReorderableList auto scrolls speed is configurable', (final WidgetTester tester) async {
    Future<void> pumpFor({
      required final Duration duration,
      final Duration interval = const Duration(milliseconds: 50),
    }) async {
      await tester.pump();

      int times = (duration.inMilliseconds / interval.inMilliseconds).ceil();
      while (times > 0) {
        await tester.pump(interval + const Duration(milliseconds: 1));
        await tester.idle();
        times--;
      }
    }

    Future<double> pumpListAndDrag({required final double autoScrollerVelocityScalar}) async {
      final List<int> items = List<int>.generate(10, (final int index) => index);
      final ScrollController scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              SliverReorderableList(
                itemBuilder: (final BuildContext context, final int index) {
                  return Container(
                    key: ValueKey<int>(items[index]),
                    height: 100,
                    color: items[index].isOdd ? Colors.red : Colors.green,
                    child: ReorderableDragStartListener(
                      index: index,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('item ${items[index]}'),
                          const Icon(Icons.drag_handle),
                        ],
                      ),
                    ),
                  );
                },
                itemCount: items.length,
                onReorder: (final int fromIndex, final int toIndex) {},
                autoScrollerVelocityScalar: autoScrollerVelocityScalar,
              ),
            ],
          ),
        ),
      );

      expect(scrollController.offset, 0);

      final Finder item = find.text('item 0');
      final TestGesture drag = await tester.startGesture(tester.getCenter(item));

      // Drag just enough to touch the edge but not surpass it, so the
      // auto scroller is not yet triggered
      await drag.moveBy(const Offset(0, 500));
      await pumpFor(duration: const Duration(milliseconds: 200));

      expect(scrollController.offset, 0);

      // Now drag a little bit more so the auto scroller triggers
      await drag.moveBy(const Offset(0, 50));
      await pumpFor(
        duration: const Duration(milliseconds: 600),
        interval: Duration(milliseconds: (1000 / autoScrollerVelocityScalar).round()),
      );

      return scrollController.offset;
    }

    const double fastVelocityScalar = 20;
    final double offsetForFastScroller = await pumpListAndDrag(autoScrollerVelocityScalar: fastVelocityScalar);

    // Reset widget tree
    await tester.pumpWidget(const SizedBox());

    const double slowVelocityScalar = 5;
    final double offsetForSlowScroller = await pumpListAndDrag(autoScrollerVelocityScalar: slowVelocityScalar);

    expect(offsetForFastScroller / offsetForSlowScroller, fastVelocityScalar / slowVelocityScalar);
  });
}

class TestList extends StatelessWidget {
  const TestList({
    super.key,
    this.textColor,
    this.iconColor,
    this.proxyDecorator,
    required this.items,
    this.reverse = false,
    this.onReorderStart,
    this.onReorderEnd,
    this.autoScrollerVelocityScalar,
  });

  final List<int> items;
  final Color? textColor;
  final Color? iconColor;
  final ReorderItemProxyDecorator? proxyDecorator;
  final bool reverse;
  final void Function(int)? onReorderStart, onReorderEnd;
  final double? autoScrollerVelocityScalar;

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: DefaultTextStyle(
          style: TextStyle(color: textColor),
          child: IconTheme(
            data: IconThemeData(color: iconColor),
            child: StatefulBuilder(
              builder: (final BuildContext outerContext, final StateSetter setState) {
                final List<int> items = this.items;
                return CustomScrollView(
                  reverse: reverse,
                  slivers: <Widget>[
                    SliverReorderableList(
                      itemBuilder: (final BuildContext context, final int index) {
                        return Container(
                          key: ValueKey<int>(items[index]),
                          height: 100,
                          color: items[index].isOdd ? Colors.red : Colors.green,
                          child: ReorderableDragStartListener(
                            index: index,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('item ${items[index]}'),
                                const Icon(Icons.drag_handle),
                              ],
                            ),
                          ),
                        );
                      },
                      itemCount: items.length,
                      onReorder: (final int fromIndex, int toIndex) {
                        setState(() {
                          if (toIndex > fromIndex) {
                            toIndex -= 1;
                          }
                          items.insert(toIndex, items.removeAt(fromIndex));
                        });
                      },
                      proxyDecorator: proxyDecorator,
                      onReorderStart: onReorderStart,
                      onReorderEnd: onReorderEnd,
                      autoScrollerVelocityScalar: autoScrollerVelocityScalar,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
