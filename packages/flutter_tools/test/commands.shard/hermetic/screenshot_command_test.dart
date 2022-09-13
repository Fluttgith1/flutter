// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/screenshot.dart';
import 'package:flutter_tools/src/vmservice.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  group('Validate screenshot options', () {
    testUsingContext('rasterizer and skia screenshots do not require a device', () async {
      // Throw a specific exception when attempting to make a VM Service connection to
      // verify that we've made it past the initial validation.
      openChannelForTesting = (String url, {CompressionOptions? compression, Logger? logger}) async {
        expect(url, 'ws://localhost:8181/ws');
        throw Exception('dummy');
      };

      await expectLater(() => createTestCommandRunner(ScreenshotCommand(fs: MemoryFileSystem.test()))
        .run(<String>['screenshot', '--type=skia', '--observatory-url=http://localhost:8181']),
        throwsA(isException.having((Exception exception) => exception.toString(), 'message', contains('dummy'))),
      );

      await expectLater(() => createTestCommandRunner(ScreenshotCommand(fs: MemoryFileSystem.test()))
        .run(<String>['screenshot', '--type=rasterizer', '--observatory-url=http://localhost:8181']),
        throwsA(isException.having((Exception exception) => exception.toString(), 'message', contains('dummy'))),
      );
    });


    testUsingContext('rasterizer and skia screenshots require observatory uri', () async {
      await expectLater(() => createTestCommandRunner(ScreenshotCommand(fs: MemoryFileSystem.test()))
        .run(<String>['screenshot', '--type=skia']),
        throwsToolExit(message: 'Observatory URI must be specified for screenshot type skia')
      );

      await expectLater(() => createTestCommandRunner(ScreenshotCommand(fs: MemoryFileSystem.test()))
        .run(<String>['screenshot', '--type=rasterizer',]),
        throwsToolExit(message: 'Observatory URI must be specified for screenshot type rasterizer'),
      );
    });

    testUsingContext('device screenshots require device', () async {
      await expectLater(() => createTestCommandRunner(ScreenshotCommand(fs: MemoryFileSystem.test()))
        .run(<String>['screenshot']),
        throwsToolExit(message: 'Must have a connected device for screenshot type device'),
      );
    });

    testUsingContext('device screenshots cannot provided Observatory', () async {
      await expectLater(() => createTestCommandRunner(ScreenshotCommand(fs: MemoryFileSystem.test()))
        .run(<String>['screenshot',  '--observatory-url=http://localhost:8181']),
        throwsToolExit(message: 'Observatory URI cannot be provided for screenshot type device'),
      );
    });
  });

  group('Screenshot file validation', () {
    testWithoutContext('successful', () async {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      expect(
          () => ScreenshotCommand.validateOutputFile(fs.file('test.png'), fs),
          returnsNormally);
    });

    testWithoutContext('failed due to incorrect filename', () async {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      expect(() => ScreenshotCommand.validateOutputFile(fs.file('.'), fs),
          throwsToolExit(message: 'The provided filename is invalid'));
    });

    testWithoutContext('failed due to incorrect file type', () async {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      expect(
          () => ScreenshotCommand.validateOutputFile(fs.file('test.pngg'), fs),
          throwsToolExit(message: 'The provided filename is invalid'));
    });

    testWithoutContext('failed due to invalid directory', () async {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      expect(
          () => ScreenshotCommand.validateOutputFile(
              fs.file('test/test.png'), fs),
          throwsToolExit(
              message:
                  'The provided path to file needs to have a directory that exists'));
    });
  });
}
