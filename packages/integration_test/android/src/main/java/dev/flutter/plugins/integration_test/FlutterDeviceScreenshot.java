// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.plugins.integration_test;

import android.app.Instrumentation;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.graphics.Bitmap.CompressFormat;
import androidx.test.platform.app.InstrumentationRegistry;
import androidx.test.runner.AndroidJUnitRunner;
import java.io.ByteArrayOutputStream;

/** FlutterDeviceScreenshot */
class FlutterDeviceScreenshot {

  /**
   * Captures a screenshot of the device, then it crops the image by the given components.
   *
   * @return byte array containing the cropped image in PNG format.
   */
  static byte[] capture() {
    final AndroidJUnitRunner instrumentation = new AndroidJUnitRunner();
    // instrumentation.setArguments(new Bundle());
    final Bitmap originalBitmap = instrumentation.getUiAutomation().takeScreenshot();
    final int width = originalBitmap.getWidth();
    final int height = originalBitmap.getHeight();
    final Bitmap croppedBitmap = Bitmap.createBitmap(originalBitmap, 0, 0, width, height);

    final ByteArrayOutputStream output = new ByteArrayOutputStream();
    croppedBitmap.compress(Bitmap.CompressFormat.PNG, /* irrelevant for PNG */ 100, output);

    return output.toByteArray();
  }
}
