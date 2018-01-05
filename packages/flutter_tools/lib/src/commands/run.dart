// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../device.dart';
import '../globals.dart';
import '../ios/mac.dart';
import '../resident_runner.dart';
import '../run_cold.dart';
import '../run_hot.dart';
import '../runner/flutter_command.dart';
import 'daemon.dart';

abstract class RunCommandBase extends FlutterCommand {
  // Used by run and drive commands.
  RunCommandBase() {
    addBuildModeFlags(defaultToRelease: false);
    usesFlavorOption();
    argParser.addFlag('trace-startup',
        negatable: false,
        help: 'Start tracing during startup.');
    argParser.addFlag('ipv6',
        hide: true,
        negatable: false,
        help: 'Binds to IPv6 localhost instead of IPv4 when the flutter tool\n'
              'forwards the host port to a device port.');
    argParser.addOption('route',
        help: 'Which route to load when running the app.');
    usesTargetOption();
    usesPortOptions();
    usesPubOption();
  }

  bool get traceStartup => argResults['trace-startup'];
  bool get ipv6 => argResults['ipv6'];
  String get route => argResults['route'];

  void usesPortOptions() {
    argParser.addOption('observatory-port',
        help: 'Listen to the given port for an observatory debugger connection.\n'
              'Specifying port 0 will find a random free port.\n'
              'Defaults to the first available port after $kDefaultObservatoryPort.'
    );
  }

  int get observatoryPort {
    if (argResults['observatory-port'] != null) {
      try {
        return int.parse(argResults['observatory-port']);
      } catch (error) {
        throwToolExit('Invalid port for `--observatory-port`: $error');
      }
    }
    return null;
  }
}

class RunCommand extends RunCommandBase {
  @override
  final String name = 'run';

  @override
  final String description = 'Run your Flutter app on an attached device.';

  RunCommand({ bool verboseHelp: false }) {
    requiresPubspecYaml();

    argParser.addFlag('full-restart',
        defaultsTo: true,
        help: 'Stop any currently running application process before running the app.');
    argParser.addFlag('start-paused',
        negatable: false,
        help: 'Start in a paused mode and wait for a debugger to connect.');
    argParser.addFlag('enable-software-rendering',
        negatable: false,
        help: 'Enable rendering using the Skia software backend. This is useful\n'
              'when testing Flutter on emulators. By default, Flutter will\n'
              'attempt to either use OpenGL or Vulkan and fall back to software\n'
              'when neither is available.');
    argParser.addFlag('trace-skia',
        negatable: false,
        help: 'Enable tracing of Skia code. This is useful when debugging\n'
              'the GPU thread. By default, Flutter will not log skia code.');
    argParser.addFlag('use-test-fonts',
        negatable: true,
        help: 'Enable (and default to) the "Ahem" font. This is a special font\n'
              'used in tests to remove any dependencies on the font metrics. It\n'
              'is enabled when you use "flutter test". Set this flag when running\n'
              'a test using "flutter run" for debugging purposes. This flag is\n'
              'only available when running in debug mode.');
    argParser.addFlag('build',
        defaultsTo: true,
        help: 'If necessary, build the app before running.');
    argParser.addOption('use-application-binary',
        hide: !verboseHelp,
        help: 'Specify a pre-built application binary to use when running.');
    argParser.addFlag('preview-dart-2',
        hide: !verboseHelp,
        help: 'Preview Dart 2.0 functionality.');
    argParser.addFlag('strong',
        hide: !verboseHelp,
        help: 'Turn on strong mode semantics.\n'
              'Valid only when --preview-dart-2 is also specified');
    argParser.addOption('packages',
        hide: !verboseHelp,
        valueHelp: 'path',
        help: 'Specify the path to the .packages file.');
    argParser.addOption('project-root',
        hide: !verboseHelp,
        help: 'Specify the project root directory.');
    argParser.addOption('project-assets',
        hide: !verboseHelp,
        help: 'Specify the project assets relative to the root directory.');
    argParser.addFlag('machine',
        hide: !verboseHelp,
        negatable: false,
        help: 'Handle machine structured JSON command input and provide output\n'
              'and progress in machine friendly format.');
    argParser.addFlag('hot',
        negatable: true,
        defaultsTo: kHotReloadDefault,
        help: 'Run with support for hot reloading.');
    argParser.addOption('pid-file',
        help: 'Specify a file to write the process id to.\n'
              'You can send SIGUSR1 to trigger a hot reload\n'
              'and SIGUSR2 to trigger a full restart.');
    argParser.addFlag('resident',
        negatable: true,
        defaultsTo: true,
        hide: !verboseHelp,
        help: 'Stay resident after launching the application.');

    argParser.addFlag('benchmark',
      negatable: false,
      hide: !verboseHelp,
      help: 'Enable a benchmarking mode. This will run the given application,\n'
            'measure the startup time and the app restart time, write the\n'
            'results out to "refresh_benchmark.json", and exit. This flag is\n'
            'intended for use in generating automated flutter benchmarks.');

    argParser.addOption(FlutterOptions.kExtraFrontEndOptions, hide: true);
    argParser.addOption(FlutterOptions.kExtraGenSnapshotOptions, hide: true);
  }

  List<Device> devices;

  @override
  Future<String> get usagePath async {
    final String command = shouldUseHotMode() ? 'hotrun' : name;

    if (devices == null)
      return command;

    // Return 'run/ios'.
    if (devices.length > 1)
      return '$command/all';
    else
      return '$command/${getNameForTargetPlatform(await devices[0].targetPlatform)}';
  }

  @override
  Future<Map<String, String>> get usageValues async {
    final bool isEmulator = await devices[0].isLocalEmulator;
    final String deviceType = devices.length == 1
            ? getNameForTargetPlatform(await devices[0].targetPlatform)
            : 'multiple';

    return <String, String>{ 'cd3': '$isEmulator', 'cd4': deviceType };
  }

  @override
  void printNoConnectedDevices() {
    super.printNoConnectedDevices();
    if (getCurrentHostPlatform() == HostPlatform.darwin_x64 &&
        xcode.isInstalledAndMeetsVersionCheck) {
      printStatus('');
      printStatus('To run on a simulator, launch it first: open -a Simulator.app');
      printStatus('');
      printStatus('If you expected your device to be detected, please run "flutter doctor" to diagnose');
      printStatus('potential issues, or visit https://flutter.io/setup/ for troubleshooting tips.');
    }
  }

  @override
  bool get shouldRunPub {
    // If we are running with a prebuilt application, do not run pub.
    if (runningWithPrebuiltApplication)
      return false;

    return super.shouldRunPub;
  }

  bool shouldUseHotMode() {
    final bool hotArg = argResults['hot'] ?? false;
    final bool shouldUseHotMode = hotArg;
    return getBuildInfo().isDebug && shouldUseHotMode;
  }

  bool get runningWithPrebuiltApplication =>
      argResults['use-application-binary'] != null;

  bool get stayResident => argResults['resident'];

  @override
  Future<Null> validateCommand() async {
    // When running with a prebuilt application, no command validation is
    // necessary.
    if (!runningWithPrebuiltApplication)
      await super.validateCommand();
    devices = await findAllTargetDevices();
    if (devices == null)
      throwToolExit(null);
    if (deviceManager.hasSpecifiedAllDevices && runningWithPrebuiltApplication)
      throwToolExit('Using -d all with --use-application-binary is not supported');
  }

  DebuggingOptions _createDebuggingOptions() {
    final BuildInfo buildInfo = getBuildInfo();
    if (buildInfo.isRelease) {
      return new DebuggingOptions.disabled(buildInfo);
    } else {
      return new DebuggingOptions.enabled(
        buildInfo,
        startPaused: argResults['start-paused'],
        useTestFonts: argResults['use-test-fonts'],
        enableSoftwareRendering: argResults['enable-software-rendering'],
        traceSkia: argResults['trace-skia'],
        observatoryPort: observatoryPort,
      );
    }
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();

    // Enable hot mode by default if `--no-hot` was not passed and we are in
    // debug mode.
    final bool hotMode = shouldUseHotMode();

    if (argResults['machine']) {
      if (devices.length > 1)
        throwToolExit('--machine does not support -d all.');
      final Daemon daemon = new Daemon(stdinCommandStream, stdoutCommandResponse,
          notifyingLogger: new NotifyingLogger(), logToStdout: true);
      AppInstance app;
      try {
        app = await daemon.appDomain.startApp(
          devices.first, fs.currentDirectory.path, targetFile, route,
          _createDebuggingOptions(), hotMode,
          applicationBinary: argResults['use-application-binary'],
          projectRootPath: argResults['project-root'],
          packagesFilePath: argResults['packages'],
          projectAssets: argResults['project-assets']
        );
      } catch (error) {
        throwToolExit(error.toString());
      }
      final DateTime appStartedTime = clock.now();
      final int result = await app.runner.waitForAppToFinish();
      if (result != 0)
        throwToolExit(null, exitCode: result);
      return new FlutterCommandResult(
        ExitStatus.success,
        timingLabelParts: <String>['daemon'],
        endTimeOverride: appStartedTime,
      );
    }

    for (Device device in devices) {
      if (await device.isLocalEmulator && !isEmulatorBuildMode(getBuildMode()))
        throwToolExit('${toTitleCase(getModeName(getBuildMode()))} mode is not supported for emulators.');
    }

    if (hotMode) {
      for (Device device in devices) {
        if (!device.supportsHotMode)
          throwToolExit('Hot mode is not supported by ${device.name}. Run with --no-hot.');
      }
    }

    final String pidFile = argResults['pid-file'];
    if (pidFile != null) {
      // Write our pid to the file.
      fs.file(pidFile).writeAsStringSync(pid.toString());
    }

    final List<FlutterDevice> flutterDevices = devices.map((Device device) {
      return new FlutterDevice(device,
                               previewDart2: argResults['preview-dart-2'],
                               strongMode : argResults['strong']);
    }).toList();

    ResidentRunner runner;
    if (hotMode) {
      runner = new HotRunner(
        flutterDevices,
        target: targetFile,
        debuggingOptions: _createDebuggingOptions(),
        benchmarkMode: argResults['benchmark'],
        applicationBinary: argResults['use-application-binary'],
        previewDart2: argResults['preview-dart-2'],
        strongMode: argResults['strong'],
        projectRootPath: argResults['project-root'],
        packagesFilePath: argResults['packages'],
        projectAssets: argResults['project-assets'],
        stayResident: stayResident,
        ipv6: ipv6,
      );
    } else {
      runner = new ColdRunner(
        flutterDevices,
        target: targetFile,
        debuggingOptions: _createDebuggingOptions(),
        traceStartup: traceStartup,
        applicationBinary: argResults['use-application-binary'],
        previewDart2: argResults['preview-dart-2'],
        strongMode: argResults['strong'],
        stayResident: stayResident,
        ipv6: ipv6,
      );
    }

    DateTime appStartedTime;
    // Sync completer so the completing agent attaching to the resident doesn't
    // need to know about analytics.
    //
    // Do not add more operations to the future.
    final Completer<Null> appStartedTimeRecorder = new Completer<Null>.sync();
    // This callback can't throw.
    appStartedTimeRecorder.future.then( // ignore: unawaited_futures
      (_) { appStartedTime = clock.now(); }
    );

    final int result = await runner.run(
      appStartedCompleter: appStartedTimeRecorder,
      route: route,
      shouldBuild: !runningWithPrebuiltApplication && argResults['build'],
    );
    if (result != 0)
      throwToolExit(null, exitCode: result);
    return new FlutterCommandResult(
      ExitStatus.success,
      timingLabelParts: <String>[
        hotMode ? 'hot' : 'cold',
        getModeName(getBuildMode()),
        devices.length == 1
            ? getNameForTargetPlatform(await devices[0].targetPlatform)
            : 'multiple',
        devices.length == 1 && await devices[0].isLocalEmulator ? 'emulator' : null
      ],
      endTimeOverride: appStartedTime,
    );
  }
}
