// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../cache.dart';
import '../codegen.dart';
import '../runner/flutter_command.dart';

class GenerateCommand extends FlutterCommand {
  GenerateCommand() {
    usesTargetOption();
  }
  @override
  String get description => 'run code generators.';

  @override
  String get name => 'generate';

  @override
  bool get hidden => true;

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();
    if (!experimentalBuildEnabled) {
      throwToolExit('FLUTTER_EXPERIMENTAL_BUILD is not enabled, codegen is unsupported.');
    }
    final CodegenDaemon codegenDaemon = await codeGenerator.daemon();
    codegenDaemon.startBuild();
    await for (CodegenStatus codegenStatus in codegenDaemon.buildResults) {
      if (codegenStatus == CodegenStatus.Failed) {
        throwToolExit('Code generation failed');
      }
      if (codegenStatus ==CodegenStatus.Succeeded) {
        break;
      }
    }
    return null;
  }
}