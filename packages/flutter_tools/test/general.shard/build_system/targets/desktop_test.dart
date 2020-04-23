// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_system/depfile.dart';
import 'package:flutter_tools/src/build_system/targets/desktop.dart';

import '../../../src/common.dart';

void main() {
  testWithoutContext('unpackDesktopArtifacts copies files/directories to target', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    fileSystem.directory('inputs/foo').createSync(recursive: true);
    // Should be copied.
    fileSystem.file('inputs/a.txt').createSync();
    fileSystem.file('inputs/b.txt').createSync();
    fileSystem.file('foo/c.txt').createSync(recursive: true);
    // Sould not be copied.
    fileSystem.file('inputs/d.txt').createSync();

    final Depfile depfile = unpackDesktopArtifacts(
      fileSystem: fileSystem,
      engineSourcePath: 'inputs',
      outputDirectory: fileSystem.directory('outputs'),
      artifacts: <String>[
        'a.txt',
        'b.txt',
      ],
      clientSourcePath: 'foo',
    );

    // Files are copied
    expect(fileSystem.file('outputs/a.txt'), exists);
    expect(fileSystem.file('outputs/b.txt'), exists);
    expect(fileSystem.file('outputs/foo/c.txt'), exists);
    expect(fileSystem.file('outputs/d.txt'), isNot(exists));

    // Depfile is correct.
    expect(depfile.inputs.map((File file) => file.path), unorderedEquals(<String>[
      'inputs/a.txt',
      'inputs/b.txt',
      'foo/c.txt',
    ]));
    expect(depfile.outputs.map((File file) => file.path), unorderedEquals(<String>[
      'outputs/a.txt',
      'outputs/b.txt',
      'outputs/foo/c.txt',
    ]));
  });

  testWithoutContext('unpackDesktopArtifacts throws when attempting to copy missing file', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();

    expect(() => unpackDesktopArtifacts(
      fileSystem: fileSystem,
      engineSourcePath: 'inputs',
      outputDirectory: fileSystem.directory('outputs'),
      artifacts: <String>[
        'a.txt',
      ],
      clientSourcePath: 'foo'
    ), throwsA(isA<Exception>()));
  });

  testWithoutContext('unpackDesktopArtifacts throws when attempting to copy missing directory', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    fileSystem.file('a.txt').createSync();

    expect(() => unpackDesktopArtifacts(
      fileSystem: fileSystem,
      engineSourcePath: 'inputs',
      outputDirectory: fileSystem.directory('outputs'),
      artifacts: <String>[
        'a.txt',
      ],
      clientSourcePath: 'foo'
    ), throwsA(isA<Exception>()));
  });
}
