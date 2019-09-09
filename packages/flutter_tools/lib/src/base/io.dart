// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This file serves as the single point of entry into the `dart:io` APIs
/// within Flutter tools.
///
/// In order to make Flutter tools more testable, we use the `FileSystem` APIs
/// in `package:file` rather than using the `dart:io` file APIs directly (see
/// `file_system.dart`). Doing so allows us to swap out local file system
/// access with mockable (or in-memory) file systems, making our tests hermetic
/// vis-a-vis file system access.
///
/// We also use `package:platform` to provide an abstraction away from the
/// static methods in the `dart:io` `Platform` class (see `platform.dart`). As
/// such, do not export Platform from this file!
///
/// To ensure that all file system and platform API access within Flutter tools
/// goes through the proper APIs, we forbid direct imports of `dart:io` (via a
/// test), forcing all callers to instead import this file, which exports the
/// blessed subset of `dart:io` that is legal to use in Flutter tools.
///
/// Because of the nature of this file, it is important that **platform and file
/// APIs not be exported from `dart:io` in this file**! Moreover, be careful
/// about any additional exports that you add to this file, as doing so will
/// increase the API surface that we have to test in Flutter tools, and the APIs
/// in `dart:io` can sometimes be hard to use in tests.
import 'dart:async';
import 'dart:io' as io show exit, IOSink, Process, ProcessSignal, stderr, stdin, Stdout, stdout;
import 'dart:io';

import 'package:file/file.dart' hide File, Directory, Link, FileSystemEntity;
import 'package:file/memory.dart';
import 'package:meta/meta.dart';

import 'context.dart';
import 'platform.dart';
import 'process.dart';

export 'dart:io'
    show
        BytesBuilder,
        CompressionOptions,
        // Directory,         NO! Use `file_system.dart`
        exitCode,
        // File,              NO! Use `file_system.dart`
        // FileSystemEntity,  NO! Use `file_system.dart`
        gzip,
        HandshakeException,
        HttpClient,
        HttpClientRequest,
        HttpClientResponse,
        HttpClientResponseCompressionState,
        HttpException,
        HttpHeaders,
        HttpRequest,
        HttpServer,
        HttpStatus,
        InternetAddress,
        InternetAddressType,
        IOException,
        IOSink,
        // Link              NO! Use `file_system.dart`
        pid,
        // Platform          NO! use `platform.dart`
        Process,
        ProcessException,
        ProcessResult,
        // ProcessSignal     NO! Use [ProcessSignal] below.
        ProcessStartMode,
        // RandomAccessFile  NO! Use `file_system.dart`
        ServerSocket,
        // stderr,           NO! Use `io.dart`
        // stdin,            NO! Use `io.dart`
        Stdin,
        StdinException,
        // stdout,           NO! Use `io.dart`
        Stdout,
        Socket,
        SocketException,
        systemEncoding,
        WebSocket,
        WebSocketException,
        WebSocketTransformer;

/// An [IOOverrides] that can delegate to [FileSystem] implementation if provided.
///
/// Does not override any of the socket facilities.
///
/// Do not provide a [LocalFileSystem] as a delegate. Since internally this calls
/// out to `dart:io` classes, it will result in a stack overflow error as the
/// IOOverrides and LocalFileSystem call eachother endlessly.
///
/// The only safe delegate types are those that do not call out to `dart:io`,
/// like the [MemoryFileSystem].
class FlutterIOOverrides extends IOOverrides {
  FlutterIOOverrides({ FileSystem fileSystem })
    : _fileSystemDelegate = fileSystem;

  final FileSystem _fileSystemDelegate;

  @override
  Directory createDirectory(String path) {
    if (_fileSystemDelegate == null) {
      return super.createDirectory(path);
    }
    return _fileSystemDelegate.directory(path);
  }

  @override
  File createFile(String path) {
    if (_fileSystemDelegate == null) {
      return super.createFile(path);
    }
    return _fileSystemDelegate.file(path);
  }

  @override
  Link createLink(String path) {
    if (_fileSystemDelegate == null) {
      return super.createLink(path);
    }
    return _fileSystemDelegate.link(path);
  }

  @override
  Stream<FileSystemEvent> fsWatch(String path, int events, bool recursive) {
    if (_fileSystemDelegate == null) {
      return super.fsWatch(path, events, recursive);
    }
    return _fileSystemDelegate.file(path).watch(events: events, recursive: recursive);
  }

  @override
  bool fsWatchIsSupported() {
    if (_fileSystemDelegate == null) {
      return super.fsWatchIsSupported();
    }
    return _fileSystemDelegate.isWatchSupported;
  }

  @override
  Future<FileSystemEntityType> fseGetType(String path, bool followLinks) {
    if (_fileSystemDelegate == null) {
      return super.fseGetType(path, followLinks);
    }
    return _fileSystemDelegate.type(path, followLinks: followLinks ?? true);
  }

  @override
  FileSystemEntityType fseGetTypeSync(String path, bool followLinks) {
    if (_fileSystemDelegate == null) {
      return super.fseGetTypeSync(path, followLinks);
    }
    return _fileSystemDelegate.typeSync(path, followLinks: followLinks ?? true);
  }

  @override
  Future<bool> fseIdentical(String path1, String path2) {
    if (_fileSystemDelegate == null) {
      return super.fseIdentical(path1, path2);
    }
    return _fileSystemDelegate.identical(path1, path2);
  }

  @override
  bool fseIdenticalSync(String path1, String path2) {
    if (_fileSystemDelegate == null) {
      return super.fseIdenticalSync(path1, path2);
    }
    return _fileSystemDelegate.identicalSync(path1, path2);
  }

  @override
  Directory getCurrentDirectory() {
    if (_fileSystemDelegate == null) {
      return super.getCurrentDirectory();
    }
    return _fileSystemDelegate.currentDirectory;
  }

  @override
  Directory getSystemTempDirectory() {
    if (_fileSystemDelegate == null) {
      return super.getSystemTempDirectory();
    }
    return _fileSystemDelegate.systemTempDirectory;
  }

  @override
  void setCurrentDirectory(String path) {
    if (_fileSystemDelegate == null) {
      return super.setCurrentDirectory(path);
    }
    _fileSystemDelegate.currentDirectory = path;
  }

  @override
  Future<FileStat> stat(String path) {
    if (_fileSystemDelegate == null) {
      return super.stat(path);
    }
    return _fileSystemDelegate.stat(path);
  }

  @override
  FileStat statSync(String path) {
    if (_fileSystemDelegate == null) {
      return super.statSync(path);
    }
    return _fileSystemDelegate.statSync(path);
  }
}

/// Exits the process with the given [exitCode].
typedef ExitFunction = void Function(int exitCode);

const ExitFunction _defaultExitFunction = io.exit;

ExitFunction _exitFunction = _defaultExitFunction;

/// Exits the process.
///
/// This is analogous to the `exit` function in `dart:io`, except that this
/// function may be set to a testing-friendly value by calling
/// [setExitFunctionForTests] (and then restored to its default implementation
/// with [restoreExitFunction]). The default implementation delegates to
/// `dart:io`.
ExitFunction get exit => _exitFunction;

/// Sets the [exit] function to a function that throws an exception rather
/// than exiting the process; this is intended for testing purposes.
@visibleForTesting
void setExitFunctionForTests([ ExitFunction exitFunction ]) {
  _exitFunction = exitFunction ?? (int exitCode) {
    throw ProcessExit(exitCode, immediate: true);
  };
}

/// Restores the [exit] function to the `dart:io` implementation.
@visibleForTesting
void restoreExitFunction() {
  _exitFunction = _defaultExitFunction;
}

/// A portable version of [io.ProcessSignal].
///
/// Listening on signals that don't exist on the current platform is just a
/// no-op. This is in contrast to [io.ProcessSignal], where listening to
/// non-existent signals throws an exception.
///
/// This class does NOT implement io.ProcessSignal, because that class uses
/// private fields. This means it cannot be used with, e.g., [Process.killPid].
/// Alternative implementations of the relevant methods that take
/// [ProcessSignal] instances are available on this class (e.g. "send").
class ProcessSignal {
  @visibleForTesting
  const ProcessSignal(this._delegate);

  static const ProcessSignal SIGWINCH = _PosixProcessSignal._(io.ProcessSignal.sigwinch);
  static const ProcessSignal SIGTERM = _PosixProcessSignal._(io.ProcessSignal.sigterm);
  static const ProcessSignal SIGUSR1 = _PosixProcessSignal._(io.ProcessSignal.sigusr1);
  static const ProcessSignal SIGUSR2 = _PosixProcessSignal._(io.ProcessSignal.sigusr2);
  static const ProcessSignal SIGINT =  ProcessSignal(io.ProcessSignal.sigint);
  static const ProcessSignal SIGKILL =  ProcessSignal(io.ProcessSignal.sigkill);

  final io.ProcessSignal _delegate;

  Stream<ProcessSignal> watch() {
    return _delegate.watch().map<ProcessSignal>((io.ProcessSignal signal) => this);
  }

  /// Sends the signal to the given process (identified by pid).
  ///
  /// Returns true if the signal was delivered, false otherwise.
  ///
  /// On Windows, this can only be used with [ProcessSignal.SIGTERM], which
  /// terminates the process.
  ///
  /// This is implemented by sending the signal using [Process.killPid].
  bool send(int pid) {
    assert(!platform.isWindows || this == ProcessSignal.SIGTERM);
    return io.Process.killPid(pid, _delegate);
  }

  @override
  String toString() => _delegate.toString();
}

/// A [ProcessSignal] that is only available on Posix platforms.
///
/// Listening to a [_PosixProcessSignal] is a no-op on Windows.
class _PosixProcessSignal extends ProcessSignal {

  const _PosixProcessSignal._(io.ProcessSignal wrappedSignal) : super(wrappedSignal);

  @override
  Stream<ProcessSignal> watch() {
    if (platform.isWindows)
      return const Stream<ProcessSignal>.empty();
    return super.watch();
  }
}

class Stdio {
  const Stdio();

  Stream<List<int>> get stdin => io.stdin;
  io.Stdout get stdout => io.stdout;
  io.IOSink get stderr => io.stderr;

  bool get hasTerminal => io.stdout.hasTerminal;
  int get terminalColumns => hasTerminal ? io.stdout.terminalColumns : null;
  int get terminalLines => hasTerminal ? io.stdout.terminalLines : null;
  bool get supportsAnsiEscapes => hasTerminal && io.stdout.supportsAnsiEscapes;
}

Stdio get stdio => context.get<Stdio>() ?? const Stdio();
io.Stdout get stdout => stdio.stdout;
Stream<List<int>> get stdin => stdio.stdin;
io.IOSink get stderr => stdio.stderr;
