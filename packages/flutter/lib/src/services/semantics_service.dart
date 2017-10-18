// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'system_channels.dart';

/// Allows access to the platform's accessibility services.
///
/// Events sent by this service are handled by the platform-specific
/// accessibility bridge in Flutter's engine.
class SemanticsService {
  SemanticsService._();

  /// Sends a semantic announcement.
  ///
  /// This should be used for announcement that are not seamlessly announced by
  /// the system as a result of a UI state change.
  ///
  /// For example a camera application can use this method to make accessibility
  /// announcements regarding objects in the viewfinder.
  static Future<Null> announce(String message) async {
    final Map<String, dynamic> event = <String, dynamic>{
      'type': 'announce',
      'data': <String, String> {'message': message},
    };
    await SystemChannels.accessibility.send(event);
  }
}
