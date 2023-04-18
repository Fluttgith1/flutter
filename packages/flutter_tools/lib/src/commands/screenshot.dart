// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../base/common.dart';
import '../base/file_system.dart';
import '../convert.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';
import '../vmservice.dart';

const String _kOut = 'out';
const String _kType = 'type';
const String _kVmServiceUrl = 'vm-service-url';
const String _kDeviceType = 'device';
const String _kSkiaType = 'skia';
const String _kRasterizerType = 'rasterizer';

class ScreenshotCommand extends FlutterCommand {
  ScreenshotCommand({required this.fs}) {
    argParser.addOption(
      _kOut,
      abbr: 'o',
      valueHelp: 'path/to/file',
      help: 'Location to write the screenshot.',
    );
    argParser.addOption(
      _kVmServiceUrl,
      aliases: <String>[ 'observatory-url' ], // for historical reasons
      valueHelp: 'URI',
      help: 'The VM Service URL to which to connect.\n'
          'This is required when "--$_kType" is "$_kSkiaType" or "$_kRasterizerType".\n'
          'To find the VM service URL, use "flutter run" and look for '
          '"A Dart VM Service ... is available at" in the output.',
    );
    argParser.addOption(
      _kType,
      valueHelp: 'type',
      help: 'The type of screenshot to retrieve.',
      allowed: const <String>[_kDeviceType, _kSkiaType, _kRasterizerType],
      allowedHelp: const <String, String>{
        _kDeviceType: "Delegate to the device's native screenshot capabilities. This "
                      'screenshots the entire screen currently being displayed (including content '
                      'not rendered by Flutter, like the device status bar).',
        _kSkiaType: 'Render the Flutter app as a Skia picture. Requires "--$_kVmServiceUrl".',
        _kRasterizerType: 'Render the Flutter app using the rasterizer. Requires "--$_kVmServiceUrl."',
      },
      defaultsTo: _kDeviceType,
    );
    usesDeviceTimeoutOption();
    usesDeviceConnectionOption();
  }

  final FileSystem fs;

  @override
  String get name => 'screenshot';

  @override
  String get description => 'Take a screenshot from a connected device.';

  @override
  final String category = FlutterCommandCategory.tools;

  @override
  bool get refreshWirelessDevices => true;

  @override
  final List<String> aliases = <String>['pic'];

  Device? device;

  Future<void> _validateOptions(final String? screenshotType, final String? vmServiceUrl) async {
    switch (screenshotType) {
      case _kDeviceType:
        if (vmServiceUrl != null) {
          throwToolExit('VM Service URI cannot be provided for screenshot type $screenshotType');
        }
        device = await findTargetDevice();
        if (device == null) {
          throwToolExit('Must have a connected device for screenshot type $screenshotType');
        }
        if (!device!.supportsScreenshot) {
          throwToolExit('Screenshot not supported for ${device!.name}.');
        }
      default:
        if (vmServiceUrl == null) {
          throwToolExit('VM Service URI must be specified for screenshot type $screenshotType');
        }
        if (vmServiceUrl.isEmpty || Uri.tryParse(vmServiceUrl) == null) {
          throwToolExit('VM Service URI "$vmServiceUrl" is invalid');
        }
    }
  }

  @override
  Future<FlutterCommandResult> verifyThenRunCommand(final String? commandPath) async {
    await _validateOptions(stringArg(_kType), stringArg(_kVmServiceUrl));
    return super.verifyThenRunCommand(commandPath);
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    File? outputFile;
    if (argResults?.wasParsed(_kOut) ?? false) {
      outputFile = fs.file(stringArg(_kOut));
    }

    bool success = true;
    switch (stringArg(_kType)) {
      case _kDeviceType:
        await runScreenshot(outputFile);
      case _kSkiaType:
        success = await runSkia(outputFile);
      case _kRasterizerType:
        success = await runRasterizer(outputFile);
    }

    return success ? FlutterCommandResult.success()
                   : FlutterCommandResult.fail();
  }

  Future<void> runScreenshot(File? outputFile) async {
    outputFile ??= globals.fsUtils.getUniqueFile(
      fs.currentDirectory,
      'flutter',
      'png',
    );

    try {
      await device!.takeScreenshot(outputFile);
    } on Exception catch (error) {
      throwToolExit('Error taking screenshot: $error');
    }

    checkOutput(outputFile, fs);

    try {
      _showOutputFileInfo(outputFile);
    } on Exception catch (error) {
      throwToolExit(
        'Error with provided file path: "${outputFile.path}"\n'
        'Error: $error'
      );
    }
  }

  Future<bool> runSkia(File? outputFile) async {
    final Uri vmServiceUrl = Uri.parse(stringArg(_kVmServiceUrl)!);
    final FlutterVmService vmService = await connectToVmService(vmServiceUrl, logger: globals.logger);
    final vm_service.Response? skp = await vmService.screenshotSkp();
    if (skp == null) {
      globals.printError(
        'The Skia picture request failed, probably because the device was '
        'disconnected',
      );
      return false;
    }
    outputFile ??= globals.fsUtils.getUniqueFile(
      fs.currentDirectory,
      'flutter',
      'skp',
    );
    final IOSink sink = outputFile.openWrite();
    sink.add(base64.decode(skp.json?['skp'] as String));
    await sink.close();
    _showOutputFileInfo(outputFile);
    ensureOutputIsNotJsonRpcError(outputFile);
    return true;
  }

  Future<bool> runRasterizer(File? outputFile) async {
    final Uri vmServiceUrl = Uri.parse(stringArg(_kVmServiceUrl)!);
    final FlutterVmService vmService = await connectToVmService(vmServiceUrl, logger: globals.logger);
    final vm_service.Response? response = await vmService.screenshot();
    if (response == null) {
      globals.printError(
        'The screenshot request failed, probably because the device was '
        'disconnected',
      );
      return false;
    }
    outputFile ??= globals.fsUtils.getUniqueFile(
      fs.currentDirectory,
      'flutter',
      'png',
    );
    final IOSink sink = outputFile.openWrite();
    sink.add(base64.decode(response.json?['screenshot'] as String));
    await sink.close();
    _showOutputFileInfo(outputFile);
    ensureOutputIsNotJsonRpcError(outputFile);
    return true;
  }

  static void checkOutput(final File outputFile, final FileSystem fs) {
    if (!fs.file(outputFile.path).existsSync()) {
      throwToolExit(
          'File was not created, ensure path is valid\n'
          'Path provided: "${outputFile.path}"'
      );
    }
  }

  @visibleForTesting
  static void ensureOutputIsNotJsonRpcError(final File outputFile) {
    if (outputFile.lengthSync() >= 1000) {
      return;
    }
    final String content = outputFile.readAsStringSync(
      encoding: const AsciiCodec(allowInvalid: true),
    );
    if (content.startsWith('{"jsonrpc":"2.0", "error"')) {
      throwToolExit('It appears the output file contains an error message, not valid output.');
    }
  }

  void _showOutputFileInfo(final File outputFile) {
    final int sizeKB = (outputFile.lengthSync()) ~/ 1024;
    globals.printStatus('Screenshot written to ${fs.path.relative(outputFile.path)} (${sizeKB}kB).');
  }
}
