// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show utf8;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTextChannel implements MethodChannel {
  FakeTextChannel(this.outgoing);

  Future<dynamic> Function(MethodCall) outgoing;
  Future<void> Function(MethodCall)? incoming;

  List<MethodCall> outgoingCalls = <MethodCall>[];

  @override
  BinaryMessenger get binaryMessenger => throw UnimplementedError();

  @override
  MethodCodec get codec => const JSONMethodCodec();

  @override
  Future<List<T>> invokeListMethod<T>(final String method, [final dynamic arguments]) => throw UnimplementedError();

  @override
  Future<Map<K, V>> invokeMapMethod<K, V>(final String method, [final dynamic arguments]) => throw UnimplementedError();

  @override
  Future<T> invokeMethod<T>(final String method, [final dynamic arguments]) async {
    final MethodCall call = MethodCall(method, arguments);
    outgoingCalls.add(call);
    return await outgoing(call) as T;
  }

  @override
  String get name => 'flutter/textinput';

  @override
  void setMethodCallHandler(final Future<void> Function(MethodCall call)? handler) => incoming = handler;

  void validateOutgoingMethodCalls(final List<MethodCall> calls) {
    expect(outgoingCalls.length, calls.length);
    final StringBuffer output = StringBuffer();
    bool hasError = false;
    for (int i = 0; i < calls.length; i++) {
      final ByteData outgoingData = codec.encodeMethodCall(outgoingCalls[i]);
      final ByteData expectedData = codec.encodeMethodCall(calls[i]);
      final String outgoingString = utf8.decode(outgoingData.buffer.asUint8List());
      final String expectedString = utf8.decode(expectedData.buffer.asUint8List());

      if (outgoingString != expectedString) {
        output.writeln(
          'Index $i did not match:\n'
          '  actual:   $outgoingString\n'
          '  expected: $expectedString',
        );
        hasError = true;
      }
    }
    if (hasError) {
      fail('Calls did not match:\n$output');
    }
  }
}

class FakeScribbleElement implements ScribbleClient {
  FakeScribbleElement({required final String elementIdentifier, final Rect bounds = Rect.zero})
      : _elementIdentifier = elementIdentifier,
        _bounds = bounds;

  final String _elementIdentifier;
  final Rect _bounds;
  String latestMethodCall = '';

  @override
  Rect get bounds => _bounds;

  @override
  String get elementIdentifier => _elementIdentifier;

  @override
  bool isInScribbleRect(final Rect rect) {
    return _bounds.overlaps(rect);
  }

  @override
  void onScribbleFocus(final Offset offset) {
    latestMethodCall = 'onScribbleFocus';
  }
}
