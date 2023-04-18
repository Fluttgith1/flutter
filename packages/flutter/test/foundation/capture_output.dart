// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/foundation.dart';

List<String> captureOutput(final VoidCallback fn) {
  final List<String> log = <String>[];

  runZoned<void>(fn, zoneSpecification: ZoneSpecification(
    print: (
      final Zone self,
      final ZoneDelegate parent,
      final Zone zone,
      final String line,
    ) {
      log.add(line);
    },
  ));

  return log;
}
