// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:core' hide print;
import 'dart:io' as io;

import 'package:path/path.dart' as path;

import 'utils.dart';

/// Runs the `executable` and returns standard output as a stream of lines.
///
/// The returned stream reaches its end immediately after the command exits.
///
/// If `expectNonZeroExit` is false and the process exits with a non-zero exit
/// code fails the test immediately by exiting the test process with exit code
/// 1.
Stream<String> runAndGetStdout(final String executable, final List<String> arguments, {
  final String? workingDirectory,
  final Map<String, String>? environment,
  final bool expectNonZeroExit = false,
}) async* {
  final StreamController<String> output = StreamController<String>();
  final Future<CommandResult?> command = runCommand(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    expectNonZeroExit: expectNonZeroExit,
    // Capture the output so it's not printed to the console by default.
    outputMode: OutputMode.capture,
    outputListener: (final String line, final io.Process process) {
      output.add(line);
    },
  );

  // Close the stream controller after the command is complete. Otherwise,
  // the yield* will never finish.
  command.whenComplete(output.close);

  yield* output.stream;
}

/// Represents a running process launched using [startCommand].
class Command {
  Command._(this.process, this._time, this._savedStdout, this._savedStderr);

  /// The raw process that was launched for this command.
  final io.Process process;
  final Stopwatch _time;
  final Future<String> _savedStdout;
  final Future<String> _savedStderr;
}

/// The result of running a command using [startCommand] and [runCommand];
class CommandResult {
  CommandResult._(this.exitCode, this.elapsedTime, this.flattenedStdout, this.flattenedStderr);

  /// The exit code of the process.
  final int exitCode;

  /// The amount of time it took the process to complete.
  final Duration elapsedTime;

  /// Standard output decoded as a string using UTF8 decoder.
  final String? flattenedStdout;

  /// Standard error output decoded as a string using UTF8 decoder.
  final String? flattenedStderr;
}

/// Starts the `executable` and returns a command object representing the
/// running process.
///
/// `outputListener` is called for every line of standard output from the
/// process, and is given the [Process] object. This can be used to interrupt
/// an indefinitely running process, for example, by waiting until the process
/// emits certain output.
///
/// `outputMode` controls where the standard output from the command process
/// goes. See [OutputMode].
Future<Command> startCommand(final String executable, final List<String> arguments, {
  final String? workingDirectory,
  final Map<String, String>? environment,
  final OutputMode outputMode = OutputMode.print,
  final bool Function(String)? removeLine,
  final void Function(String, io.Process)? outputListener,
}) async {
  final String commandDescription = '${path.relative(executable, from: workingDirectory)} ${arguments.join(' ')}';
  final String relativeWorkingDir = path.relative(workingDirectory ?? io.Directory.current.path);
  print('RUNNING: cd $cyan$relativeWorkingDir$reset; $green$commandDescription$reset');

  final Stopwatch time = Stopwatch()..start();
  final io.Process process = await io.Process.start(executable, arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  );
  return Command._(
    process,
    time,
    process.stdout
      .transform<String>(const Utf8Decoder())
      .transform(const LineSplitter())
      .where((final String line) => removeLine == null || !removeLine(line))
      .map<String>((final String line) {
        final String formattedLine = '$line\n';
        if (outputListener != null) {
          outputListener(formattedLine, process);
        }
        switch (outputMode) {
          case OutputMode.print:
            print(line);
          case OutputMode.capture:
            break;
        }
        return line;
      })
      .join('\n'),
    process.stderr
      .transform<String>(const Utf8Decoder())
      .transform(const LineSplitter())
      .map<String>((final String line) {
        switch (outputMode) {
          case OutputMode.print:
            print(line);
          case OutputMode.capture:
            break;
        }
        return line;
      })
      .join('\n'),
  );
}

/// Runs the `executable` and waits until the process exits.
///
/// If the process exits with a non-zero exit code and `expectNonZeroExit` is
/// false, calls foundError (which does not terminate execution!).
///
/// `outputListener` is called for every line of standard output from the
/// process, and is given the [Process] object. This can be used to interrupt
/// an indefinitely running process, for example, by waiting until the process
/// emits certain output.
///
/// Returns the result of the finished process.
///
/// `outputMode` controls where the standard output from the command process
/// goes. See [OutputMode].
Future<CommandResult> runCommand(final String executable, final List<String> arguments, {
  final String? workingDirectory,
  final Map<String, String>? environment,
  final bool expectNonZeroExit = false,
  final int? expectedExitCode,
  final String? failureMessage,
  final OutputMode outputMode = OutputMode.print,
  final bool Function(String)? removeLine,
  final void Function(String, io.Process)? outputListener,
}) async {
  final String commandDescription = '${path.relative(executable, from: workingDirectory)} ${arguments.join(' ')}';
  final String relativeWorkingDir = path.relative(workingDirectory ?? io.Directory.current.path);

  final Command command = await startCommand(executable, arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    outputMode: outputMode,
    removeLine: removeLine,
    outputListener: outputListener,
  );

  final CommandResult result = CommandResult._(
    await command.process.exitCode,
    command._time.elapsed,
    await command._savedStdout,
    await command._savedStderr,
  );

  if ((result.exitCode == 0) == expectNonZeroExit || (expectedExitCode != null && result.exitCode != expectedExitCode)) {
    // Print the output when we get unexpected results (unless output was
    // printed already).
    switch (outputMode) {
      case OutputMode.print:
        break;
      case OutputMode.capture:
        print(result.flattenedStdout);
        print(result.flattenedStderr);
    }
    String allOutput;
    if (failureMessage == null) {
      allOutput = '${result.flattenedStdout}\n${result.flattenedStderr}';
      if (allOutput.split('\n').length > 10) {
        allOutput = '(stdout/stderr output was more than 10 lines)';
      }
    } else {
      allOutput = '';
    }
    foundError(<String>[
      if (failureMessage != null)
        failureMessage,
      '${bold}Command: $green$commandDescription$reset',
      if (failureMessage == null)
        '$bold${red}Command exited with exit code ${result.exitCode} but expected ${expectNonZeroExit ? (expectedExitCode ?? 'non-zero') : 'zero'} exit code.$reset',
      '${bold}Working directory: $cyan${path.absolute(relativeWorkingDir)}$reset',
      if (allOutput.isNotEmpty)
        '${bold}stdout and stderr output:\n$allOutput',
    ]);
  } else {
    print('ELAPSED TIME: ${prettyPrintDuration(result.elapsedTime)} for $green$commandDescription$reset in $cyan$relativeWorkingDir$reset');
  }
  return result;
}

/// Specifies what to do with the command output from [runCommand] and [startCommand].
enum OutputMode {
  /// Forwards standard output and standard error streams to the test process'
  /// standard output stream (i.e. stderr is redirected to stdout).
  ///
  /// Use this mode if all you want is print the output of the command to the
  /// console. The output is no longer available after the process exits.
  print,

  /// Saves standard output and standard error streams in memory.
  ///
  /// Captured output can be retrieved from the [CommandResult] object.
  ///
  /// Use this mode in tests that need to inspect the output of a command, or
  /// when the output should not be printed to console.
  capture,
}
