// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show jsonEncode;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:fixnum/fixnum.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import './git.dart';
import './globals.dart';
import './proto/conductor_state.pb.dart' as pb;
import './proto/conductor_state.pbenum.dart' show ReleasePhase;
import './repository.dart';
import './state.dart';
import './stdio.dart';

const String kCandidateOption = 'candidate-branch';
const String kReleaseOption = 'release-channel';
const String kStateOption = 'state-file';
const String kFrameworkMirrorOption = 'framework-mirror';
const String kEngineMirrorOption = 'engine-mirror';
const String kFrameworkUpstreamOption = 'framework-upstream';
const String kEngineUpstreamOption = 'engine-upstream';
const String kFrameworkCherrypicksOption = 'framework-cherrypicks';
const String kEngineCherrypicksOption = 'engine-cherrypicks';

/// Command to print the status of the current Flutter release.
class StartCommand extends Command<void> {
  StartCommand({
    @required this.checkouts,
    @required this.flutterRoot,
  })  : platform = checkouts.platform,
        processManager = checkouts.processManager,
        fileSystem = checkouts.fileSystem,
        stdio = checkouts.stdio {
    final String defaultPath = defaultStateFilePath(platform);
    argParser.addOption(
      kCandidateOption,
      help: 'The candidate branch the release will be based on.',
    );
    argParser.addOption(
      kReleaseOption,
      help: 'The target release channel for the release.',
      allowed: <String>['stable', 'beta', 'dev'],
    );
    argParser.addOption(
      kFrameworkUpstreamOption,
      defaultsTo: FrameworkRepository.defaultUpstream,
      help:
          'Configurable Framework repo upstream remote. Primarily for testing.',
      hide: true,
    );
    argParser.addOption(
      kEngineUpstreamOption,
      defaultsTo: EngineRepository.defaultUpstream,
      help: 'Configurable Engine repo upstream remote. Primarily for testing.',
      hide: true,
    );
    argParser.addOption(
      kFrameworkMirrorOption,
      help: 'Framework repo mirror remote.',
    );
    argParser.addOption(
      kEngineMirrorOption,
      help: 'Engine repo mirror remote.',
    );
    argParser.addOption(
      kStateOption,
      defaultsTo: defaultPath,
      help: 'Path to persistent state file. Defaults to $defaultPath',
    );
    argParser.addMultiOption(
      kEngineCherrypicksOption,
      help: 'Engine cherrypick hashes to be applied.',
      defaultsTo: <String>[],
    );
    argParser.addMultiOption(
      kFrameworkCherrypicksOption,
      help: 'Framework cherrypick hashes to be applied.',
      defaultsTo: <String>[],
    );
    final Git git = Git(processManager);
    conductorVersion = git.getOutput(
      <String>['rev-parse', 'HEAD'],
      'look up the current revision.',
      workingDirectory: flutterRoot.path,
    ).trim();

    assert(conductorVersion.isNotEmpty);
  }

  final Checkouts checkouts;

  /// The root directory of the Flutter repository that houses the Conductor.
  ///
  /// This directory is used to check the git revision of the Conductor.
  final Directory flutterRoot;
  final FileSystem fileSystem;
  final Platform platform;
  final ProcessManager processManager;
  final Stdio stdio;

  /// Git revision for the currently running Conductor.
  String conductorVersion;

  @override
  String get name => 'start';

  @override
  String get description => 'Initialize a new Flutter release.';

  @override
  void run() {
    final File stateFile = checkouts.fileSystem.file(
      getValueFromEnvOrArgs(kStateOption, argResults, platform.environment),
    );
    if (stateFile.existsSync()) {
      throw ConductorException(
          'Error! A persistent state file already found at ${argResults[kStateOption]}.\n\n'
          'Run `conductor cleanup` to cancel a previous release.');
    }
    final String frameworkUpstream = getValueFromEnvOrArgs(
      kFrameworkUpstreamOption,
      argResults,
      platform.environment,
    );
    final String frameworkMirror = getValueFromEnvOrArgs(
      kFrameworkMirrorOption,
      argResults,
      platform.environment,
    );
    final String engineUpstream = getValueFromEnvOrArgs(
      kEngineUpstreamOption,
      argResults,
      platform.environment,
    );
    final String engineMirror = getValueFromEnvOrArgs(
      kEngineMirrorOption,
      argResults,
      platform.environment,
    );
    final String candidateBranch = getValueFromEnvOrArgs(
      kCandidateOption,
      argResults,
      platform.environment,
    );
    final String releaseChannel = getValueFromEnvOrArgs(
      kReleaseOption,
      argResults,
      platform.environment,
    );
    List<String> frameworkCherrypicks = getValuesFromEnvOrArgs(
      kFrameworkCherrypicksOption,
      argResults,
      platform.environment,
    );
    List<String> engineCherrypicks = getValuesFromEnvOrArgs(
      kEngineCherrypicksOption,
      argResults,
      platform.environment,
    );
    if (!releaseCandidateBranchRegex.hasMatch(candidateBranch)) {
      throw ConductorException(
          'Invalid release candidate branch "$candidateBranch". '
          'Text should match the regex pattern /${releaseCandidateBranchRegex.pattern}/.');
    }

    final Int64 unixDate = Int64(DateTime.now().millisecondsSinceEpoch);
    final pb.ConductorState state = pb.ConductorState();

    state.releaseChannel = releaseChannel;
    state.createdDate = unixDate;
    state.lastUpdatedDate = unixDate;

    final EngineRepository engine = EngineRepository(
      checkouts,
      initialRef: candidateBranch,
      fetchRemote: Remote(
        name: RemoteName.upstream,
        url: engineUpstream,
      ),
      pushRemote: Remote(
        name: RemoteName.mirror,
        url: engineMirror,
      ),
    );
    engineCherrypicks = _sortCherrypicks(
      repository: engine,
      cherrypicks: engineCherrypicks,
      upstreamRef: EngineRepository.defaultBranch,
      releaseRef: candidateBranch,
    );
    final String engineHead = engine.reverseParse('HEAD');
    state.engine = pb.Repository(
      candidateBranch: candidateBranch,
      startingGitHead: engineHead,
      currentGitHead: engineHead,
      checkoutPath: engine.checkoutDirectory.path,
      cherrypicks: engineCherrypicks,
    );
    final FrameworkRepository framework = FrameworkRepository(
      checkouts,
      initialRef: candidateBranch,
      fetchRemote: Remote(
        name: RemoteName.upstream,
        url: frameworkUpstream,
      ),
      pushRemote: Remote(
        name: RemoteName.mirror,
        url: frameworkMirror,
      ),
    );
    frameworkCherrypicks = _sortCherrypicks(
      repository: framework,
      cherrypicks: frameworkCherrypicks,
      upstreamRef: FrameworkRepository.defaultBranch,
      releaseRef: candidateBranch,
    );
    final String frameworkHead = framework.reverseParse('HEAD');
    state.framework = pb.Repository(
      candidateBranch: candidateBranch,
      startingGitHead: frameworkHead,
      currentGitHead: frameworkHead,
      checkoutPath: framework.checkoutDirectory.path,
      cherrypicks: frameworkCherrypicks,
    );

    state.lastPhase = ReleasePhase.INITIALIZE;

    state.conductorVersion = conductorVersion;

    stdio.printTrace('Writing state to file ${stateFile.path}...');

    state.logs.addAll(stdio.logs);

    stateFile.writeAsStringSync(
      jsonEncode(state.toProto3Json()),
      flush: true,
    );

    stdio.printStatus(presentState(state));
  }

  // To minimize merge conflicts, sort the commits by rev-list order.
  List<String> _sortCherrypicks({
    @required Repository repository,
    @required List<String> cherrypicks,
    @required String upstreamRef,
    @required String releaseRef,
  }) {
    if (cherrypicks.isEmpty) {
      return cherrypicks;
    }

    // Input cherrypick hashes that failed to be parsed by git.
    final List<String> unknownCherrypicks = <String>[];
    // Full 40-char hashes parsed by git.
    final List<String> validatedCherrypicks = <String>[];
    // Final, validated, sorted list of cherrypicks to be applied.
    final List<String> sortedCherrypicks = <String>[];
    for (final String cherrypick in cherrypicks) {
      try {
        final String fullRef = repository.reverseParse(cherrypick);
        validatedCherrypicks.add(fullRef);
      } on GitException {
        // Catch this exception so that we can validate the rest.
        unknownCherrypicks.add(cherrypick);
      }
    }

    final String branchPoint = repository.branchPoint(
      upstreamRef,
      releaseRef,
    );

    // `git rev-list` returns newest first, so reverse this list
    final List<String> upstreamRevlist = repository.revList(<String>[
      '--ancestry-path',
      '$branchPoint..$upstreamRef',
    ]).reversed.toList();

    stdio.printStatus('upstreamRevList:\n${upstreamRevlist.join('\n')}\n');
    stdio.printStatus('validatedCherrypicks:\n${validatedCherrypicks.join('\n')}\n');
    for (final String upstreamRevision in upstreamRevlist) {
      if (validatedCherrypicks.contains(upstreamRevision)) {
        validatedCherrypicks.remove(upstreamRevision);
        sortedCherrypicks.add(upstreamRevision);
        if (unknownCherrypicks.isEmpty && validatedCherrypicks.isEmpty) {
          return sortedCherrypicks;
        }
      }
    }

    // We were given input cherrypicks that were not present in the upstream
    // rev-list
    stdio.printError('The following cherrypicks were not found in the upstream $upstreamRef branch:');
    for (final String cp in <String>[...validatedCherrypicks, ...unknownCherrypicks]) {
      stdio.printError('\t$cp');
    }
    throw ConductorException(
      '${validatedCherrypicks.length + unknownCherrypicks.length} unknown cherrypicks provided!',
    );
  }
}
