// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'message_codec.dart';
import 'system_channels.dart';

/// An interface into Android's stylus handwriting text input.
///
/// This is typically used by implemeting the methods in [ScribeClient] in a
/// class, usually a [State], and setting an instance of it to [client]. The
/// relevant methods on [ScribeClient] will be called in response to method
/// channel calls on [SystemChannels.scribe].
///
/// See also:
///
///  * [EditableText.stylusHandwritingEnabled], which controls whether Flutter's
///    built-in text fields support handwriting input. On Android it uses this
///    class via [ScribeClient].
///  * [SystemChannels.scribe], which is the [MethodChannel] used by this
///    class, and which has a list of the methods that this class handles.
class Scribe {
  Scribe._() {
    _channel.setMethodCallHandler(_loudlyHandleScribeInputInvocation);
  }

  static final Scribe _instance = Scribe._();

  /// Set the given [ScribeClient] as the single active client.
  ///
  /// This is usually based on the [ScribeClient] receiving focus.
  static set client(ScribeClient? client) {
    _instance._client = client;
  }

  /// Return the current active [ScribeClient], or null if none.
  static ScribeClient? get client => _instance._client;

  ScribeClient? _client;

  static const MethodChannel _channel = SystemChannels.scribe;

  /// Returns true if the InputMethodManager supports Scribe stylus handwriting
  /// input.
  ///
  /// Call this before calling [startStylusHandwriting] to make sure it's
  /// available.
  ///
  /// Supported on Android API 34 and above.
  ///
  /// See also:
  ///
  /// * [https://developer.android.com/reference/android/view/inputmethod/InputMethodManager#isStylusHandwritingAvailable()],
  ///   which is the corresponding API on Android.
  static Future<bool?> isStylusHandwritingAvailable() {
    return _channel.invokeMethod<bool?>(
      'Scribe.isStylusHandwritingAvailable',
    );
  }

  /// Tell Android to begin receiving stylus handwriting input.
  ///
  /// This is typically called after detecting the start of stylus input.
  ///
  /// Supported on Android API 33 and above.
  ///
  /// See also:
  ///
  /// * [https://developer.android.com/reference/android/view/inputmethod/InputMethodManager#startStylusHandwriting(android.view.View)],
  ///   which is the corresponding API on Android.
  static Future<void> startStylusHandwriting() {
    return _channel.invokeMethod<void>(
      'Scribe.startStylusHandwriting',
    );
  }

  Future<dynamic> _loudlyHandleScribeInputInvocation(MethodCall call) async {
    try {
      return await _handleScribeInputInvocation(call);
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'services library',
        context: ErrorDescription('during method call ${call.method}'),
        informationCollector: () => <DiagnosticsNode>[
          DiagnosticsProperty<MethodCall>('call', call, style: DiagnosticsTreeStyle.errorProperty),
        ],
      ));
      rethrow;
    }
  }

  Future<dynamic> _handleScribeInputInvocation(MethodCall methodCall) async {
    // TODO(justinmc): Scribe stylus gestures should be supported here.
    // https://github.com/flutter/flutter/issues/156018
    throw MissingPluginException();
  }
}

/// An interface into Android's stylus handwriting text input.
///
/// This is typically mixed into a [State].
///
/// See also:
///
///  * [ScribbleClient], which implements the iOS version of this feature,
///  [Scribble](https://support.apple.com/guide/ipad/enter-text-with-scribble-ipad355ab2a7/ipados).
mixin ScribeClient {
  bool get isActive;

  // TODO(justinmc): Is there a cleaner way to adjust for the device pixel ratio?
  double get devicePixelRatio;

  // TODO(justinmc): Scribe stylus gestures should be supported here.
  // https://github.com/flutter/flutter/issues/156018
}
