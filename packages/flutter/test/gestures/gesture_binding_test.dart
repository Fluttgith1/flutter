// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import '../flutter_test_alternative.dart';

typedef HandleEventCallback = void Function(PointerEvent event);

class TestGestureFlutterBinding extends BindingBase with GestureBinding {
  HandleEventCallback callback;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    super.handleEvent(event, entry);
    if (callback != null)
      callback(event);
  }
}

TestGestureFlutterBinding _binding = TestGestureFlutterBinding();

void ensureTestGestureBinding() {
  _binding ??= TestGestureFlutterBinding();
  assert(GestureBinding.instance != null);
}

void main() {
  setUp(ensureTestGestureBinding);

  test('Pointer tap events', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(change: ui.PointerChange.down, buttons: 1),
        ui.PointerData(change: ui.PointerChange.up),
      ],
    );

    final List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = events.add;

    ui.window.onPointerDataPacket(packet);
    expect(events.length, 2);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerUpEvent));
  });

  test('Pointer move events', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(change: ui.PointerChange.down, buttons: 1),
        ui.PointerData(change: ui.PointerChange.move, buttons: 1),
        ui.PointerData(change: ui.PointerChange.up),
      ],
    );

    final List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = events.add;

    ui.window.onPointerDataPacket(packet);
    expect(events.length, 3);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerMoveEvent));
    expect(events[2].runtimeType, equals(PointerUpEvent));
  });

  test('Pointer hover events', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
        data: <ui.PointerData>[
          ui.PointerData(change: ui.PointerChange.add),
          ui.PointerData(change: ui.PointerChange.hover),
          ui.PointerData(change: ui.PointerChange.hover),
          ui.PointerData(change: ui.PointerChange.remove),
          ui.PointerData(change: ui.PointerChange.add),
          ui.PointerData(change: ui.PointerChange.hover),
        ],
    );

    final List<PointerEvent> pointerRouterEvents = <PointerEvent>[];
    GestureBinding.instance.pointerRouter.addGlobalRoute(pointerRouterEvents.add);

    final List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = events.add;

    ui.window.onPointerDataPacket(packet);
    expect(events.length, 0);
    expect(pointerRouterEvents.length, 6,
        reason: 'pointerRouterEvents contains: $pointerRouterEvents');
    expect(pointerRouterEvents[0].runtimeType, equals(PointerAddedEvent));
    expect(pointerRouterEvents[1].runtimeType, equals(PointerHoverEvent));
    expect(pointerRouterEvents[2].runtimeType, equals(PointerHoverEvent));
    expect(pointerRouterEvents[3].runtimeType, equals(PointerRemovedEvent));
    expect(pointerRouterEvents[4].runtimeType, equals(PointerAddedEvent));
    expect(pointerRouterEvents[5].runtimeType, equals(PointerHoverEvent));
  });

  test('Pointer cancel events', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(change: ui.PointerChange.down, buttons: 1),
        ui.PointerData(change: ui.PointerChange.cancel),
      ],
    );

    final List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = events.add;

    ui.window.onPointerDataPacket(packet);
    expect(events.length, 2);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerCancelEvent));
  });

  test('Can cancel pointers', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(change: ui.PointerChange.down, buttons: 1),
        ui.PointerData(change: ui.PointerChange.up),
      ],
    );

    final List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = (PointerEvent event) {
      events.add(event);
      if (event is PointerDownEvent)
        _binding.cancelPointer(event.pointer);
    };

    ui.window.onPointerDataPacket(packet);
    expect(events.length, 2);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerCancelEvent));
  });

  test('Can expand add and hover pointers', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(change: ui.PointerChange.add, device: 24),
        ui.PointerData(change: ui.PointerChange.hover, device: 24),
        ui.PointerData(change: ui.PointerChange.remove, device: 24),
        ui.PointerData(change: ui.PointerChange.add, device: 24),
        ui.PointerData(change: ui.PointerChange.hover, device: 24),
      ],
    );

    final List<PointerEvent> events = PointerEventConverter.expand(
      packet.data, ui.window.devicePixelRatio).toList();

    expect(events.length, 5);
    expect(events[0].runtimeType, equals(PointerAddedEvent));
    expect(events[1].runtimeType, equals(PointerHoverEvent));
    expect(events[2].runtimeType, equals(PointerRemovedEvent));
    expect(events[3].runtimeType, equals(PointerAddedEvent));
    expect(events[4].runtimeType, equals(PointerHoverEvent));
  });

  test('Can expand pointer scroll events', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
        data: <ui.PointerData>[
          ui.PointerData(change: ui.PointerChange.add),
          ui.PointerData(change: ui.PointerChange.hover, signalKind: ui.PointerSignalKind.scroll),
        ],
    );

    final List<PointerEvent> events = PointerEventConverter.expand(
      packet.data, ui.window.devicePixelRatio).toList();

    expect(events.length, 2);
    expect(events[0].runtimeType, equals(PointerAddedEvent));
    expect(events[1].runtimeType, equals(PointerScrollEvent));
  });
}
