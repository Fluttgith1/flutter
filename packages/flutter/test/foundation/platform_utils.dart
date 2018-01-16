// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

/// Replaces Windows-style path separators with Unix-style separators.
String sanitizePaths(String path) {
  if (Platform.isWindows) {
    path = path.replaceAll(new RegExp('\\\\'), '/');
  }
  return path;
}