// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:test_api/test_api.dart' hide test; // ignore: deprecated_member_use
import 'package:vm_service/vm_service.dart' as vm_service;

export 'package:test_api/test_api.dart' hide isInstanceOf, test; // ignore: deprecated_member_use

/// A fake implementation of a vm_service that mocks the JSON-RPC request
/// and response structure.
class FakeVmServiceHost {
  FakeVmServiceHost({
    required final List<VmServiceExpectation> requests,
    final Uri? httpAddress,
    final Uri? wsAddress,
  }) : _requests = requests {
    _vmService = FlutterVmService(vm_service.VmService(
      _input.stream,
      _output.add,
    ), httpAddress: httpAddress, wsAddress: wsAddress);
    _applyStreamListen();
    _output.stream.listen((final String data) {
      final Map<String, Object?> request = json.decode(data) as Map<String, Object?>;
      if (_requests.isEmpty) {
        throw Exception('Unexpected request: $request');
      }
      final FakeVmServiceRequest fakeRequest = _requests.removeAt(0) as FakeVmServiceRequest;
      expect(request, isA<Map<String, Object?>>()
        .having((final Map<String, Object?> request) => request['method'], 'method', fakeRequest.method)
        .having((final Map<String, Object?> request) => request['params'], 'args', fakeRequest.args)
      );
      if (fakeRequest.close) {
        unawaited(_vmService.dispose());
        expect(_requests, isEmpty);
        return;
      }
      if (fakeRequest.errorCode == null) {
        _input.add(json.encode(<String, Object?>{
          'jsonrpc': '2.0',
          'id': request['id'],
          'result': fakeRequest.jsonResponse ?? <String, Object>{'type': 'Success'},
        }));
      } else {
        _input.add(json.encode(<String, Object?>{
          'jsonrpc': '2.0',
          'id': request['id'],
          'error': <String, Object?>{
            'code': fakeRequest.errorCode,
            'message': 'error',
          },
        }));
      }
      _applyStreamListen();
    });
  }

  final List<VmServiceExpectation> _requests;
  final StreamController<String> _input = StreamController<String>();
  final StreamController<String> _output = StreamController<String>();

  FlutterVmService get vmService => _vmService;
  late final FlutterVmService _vmService;


  bool get hasRemainingExpectations => _requests.isNotEmpty;

  // remove FakeStreamResponse objects from _requests until it is empty
  // or until we hit a FakeRequest
  void _applyStreamListen() {
    while (_requests.isNotEmpty && !_requests.first.isRequest) {
      final FakeVmServiceStreamResponse response = _requests.removeAt(0) as FakeVmServiceStreamResponse;
      _input.add(json.encode(<String, Object>{
        'jsonrpc': '2.0',
        'method': 'streamNotify',
        'params': <String, Object>{
          'streamId': response.streamId,
          'event': response.event.toJson(),
        },
      }));
    }
  }
}

abstract class VmServiceExpectation {
  bool get isRequest;
}

class FakeVmServiceRequest implements VmServiceExpectation {
  const FakeVmServiceRequest({
    required this.method,
    this.args = const <String, Object?>{},
    this.jsonResponse,
    this.errorCode,
    this.close = false,
  });

  final String method;

  /// When true, the vm service is automatically closed.
  final bool close;

  /// If non-null, the error code for a [vm_service.RPCError] in place of a
  /// standard response.
  final int? errorCode;
  final Map<String, Object?>? args;
  final Map<String, Object?>? jsonResponse;

  @override
  bool get isRequest => true;
}

class FakeVmServiceStreamResponse implements VmServiceExpectation {
  const FakeVmServiceStreamResponse({
    required this.event,
    required this.streamId,
  });

  final vm_service.Event event;
  final String streamId;

  @override
  bool get isRequest => false;
}
