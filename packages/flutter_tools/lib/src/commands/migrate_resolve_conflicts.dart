// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../migrate/migrate_manifest.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import 'migrate.dart';

/// Flutter migrate subcommand that guides the developer through conflicts,
/// allowing them to accept the original, the new lines, or skip and resolve manually.
class MigrateResolveConflictsCommand extends FlutterCommand {
  MigrateResolveConflictsCommand({
    required this.logger,
    required this.fileSystem,
    required this.terminal,
  }) {
    requiresPubspecYaml();
    argParser.addOption(
      'working-directory',
      help: 'Specifies the custom migration working directory used to stage and edit proposed changes. '
            'This path can be absolute or relative to the flutter project root.',
      valueHelp: 'path',
    );
    argParser.addOption(
      'context-lines',
      defaultsTo: '5',
      help: 'The number of lines of context to show around the each conflict. Defaults to 5.',
    );
    argParser.addFlag(
      'confirm-commit',
      defaultsTo: true,
      help: 'Indicates if proposed changes require user verification before writing to disk.',
    );
  }

  final Logger logger;

  final FileSystem fileSystem;

  final Terminal terminal;

  @override
  final String name = 'resolve-conflicts';

  @override
  final String description = 'Prints the current status of the in progress migration.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  static const String _conflictStartMarker = '<<<<<<<';
  static const String _conflictDividerMarker = '=======';
  static const String _conflictEndMarker = '>>>>>>>';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FlutterProject project = FlutterProject.current();
    Directory workingDirectory = project.directory.childDirectory(kDefaultMigrateWorkingDirectoryName);
    final String? customWorkingDirectoryPath = stringArg('working-directory');
    if (customWorkingDirectoryPath != null) {
      if (customWorkingDirectoryPath.startsWith(fileSystem.path.separator) || customWorkingDirectoryPath.startsWith('/')) {
        // Is an absolute path
        workingDirectory = fileSystem.directory(customWorkingDirectoryPath);
      } else {
        workingDirectory = project.directory.childDirectory(customWorkingDirectoryPath);
      }
    }
    if (!workingDirectory.existsSync()) {
      logger.printStatus('No migration in progress. Start a new migration with:');
      printCommandText('flutter migrate start', logger);
      return const FlutterCommandResult(ExitStatus.fail);
    }

    final File manifestFile = MigrateManifest.getManifestFileFromDirectory(workingDirectory);
    final MigrateManifest manifest = MigrateManifest.fromFile(manifestFile);

    final int contextLineCount = int.parse(stringArg('context-lines')!);

    checkAndPrintMigrateStatus(manifest, workingDirectory, logger: logger);

    final List<String> conflictFiles = manifest.remainingConflictFiles(workingDirectory);

    terminal.usesTerminalUi = true;

    for (int i = 0; i < conflictFiles.length; i++) {
      final String localPath = conflictFiles[i];
      final File file = workingDirectory.childFile(localPath);
      final List<String> lines = file.readAsStringSync().split('\n');
      // We write a newline in the output, this counteracts it.
      if (lines.last == '') {
        lines.removeLast();
      }

      // Find all conflicts
      final List<Conflict> conflicts = <Conflict>[];
      Conflict currentConflict = Conflict.empty();
      for (int lineNumber = 0; lineNumber < lines.length; lineNumber++) {
        final String line = lines[lineNumber];
        if (line.contains(_conflictStartMarker)) {
          currentConflict.startLine = lineNumber;
        } else if (line.contains(_conflictDividerMarker)) {
          currentConflict.dividerLine = lineNumber;
        } else if (line.contains(_conflictEndMarker)) {
          currentConflict.endLine = lineNumber;
          assert(currentConflict.startLine! < currentConflict.dividerLine! && currentConflict.dividerLine! < currentConflict.endLine!);
          conflicts.add(currentConflict);
          currentConflict = Conflict.empty();
        }
      }

      // Prompt developer
      int originalCount = 0;
      int newCount = 0;
      int skipCount = 0;
      for (final Conflict conflict in conflicts) {
        assert(conflict.startLine != null && conflict.dividerLine != null && conflict.endLine != null);
        // Print the conflict for reference
        logger.printStatus(terminal.clearScreen(), newline: false);
        logger.printStatus('Cyan', color: TerminalColor.cyan, newline: false);
        logger.printStatus(' = Original lines.  ', newline: false);
        logger.printStatus('Green', color: TerminalColor.green, newline: false);
        logger.printStatus(' = New lines.\n', newline: true);

        // Print the conflict for reference
        for (int lineNumber = (conflict.startLine! - contextLineCount).abs(); lineNumber < conflict.startLine!; lineNumber++) {
          printConflictLine(lines[lineNumber], lineNumber, color: TerminalColor.grey);
        }
        printConflictLine(lines[conflict.startLine!], conflict.startLine!);
        for (int lineNumber = conflict.startLine! + 1; lineNumber < conflict.dividerLine!; lineNumber++) {
          printConflictLine(lines[lineNumber], lineNumber, color: TerminalColor.cyan);
        }
        printConflictLine(lines[conflict.dividerLine!], conflict.dividerLine!);
        for (int lineNumber = conflict.dividerLine! + 1; lineNumber < conflict.endLine!; lineNumber++) {
          printConflictLine(lines[lineNumber], lineNumber, color: TerminalColor.green);
        }
        printConflictLine(lines[conflict.endLine!], conflict.endLine!);
        for (int lineNumber = conflict.endLine! + 1; lineNumber <= (conflict.endLine! + contextLineCount).clamp(0, lines.length - 1); lineNumber++) {
          printConflictLine(lines[lineNumber], lineNumber, color: TerminalColor.grey);
        }

        logger.printStatus('\nConflict in $localPath.');
        // Select action
        String selection = 's';
        try {
          selection = await terminal.promptForCharInput(
            <String>['o', 'n', 's'],
            logger: logger,
            prompt: 'Accept the (o)riginal lines, (n)ew lines, or (S)kip and resolve the conflict manually?',
            defaultChoiceIndex: 2,
          );
        } on StateError catch(e) {
          logger.printError(
            e.message,
            indent: 0,
          );
        }

        switch(selection) {
          case 'o': {
            conflict.chooseOriginal();
            break;
          }
          case 'n': {
            conflict.chooseNew();
            break;
          }
          case 's': {
            conflict.skip();
            break;
          }
        }
      }

      int lastPrintedLine = 0;
      String result = '';
      bool hasChanges = false;
      for (final Conflict conflict in conflicts) {
        if (conflict.keepOriginal != null) {
          hasChanges = true; // don't unecessarily write file if no changes were made.
        }
        for (int lineNumber = lastPrintedLine; lineNumber < conflict.startLine!; lineNumber++) {
          result += '${lines[lineNumber]}\n';
        }
        if (conflict.keepOriginal == null) {
          // Skipped this conflict. Add all lines.
          for (int lineNumber = conflict.startLine!; lineNumber <= conflict.endLine!; lineNumber++) {
            result += '${lines[lineNumber]}\n';
          }
          skipCount++;
        } else if (conflict.keepOriginal!) {
          // Keeping original lines
          for (int lineNumber = conflict.startLine! + 1; lineNumber < conflict.dividerLine!; lineNumber++) {
            result += '${lines[lineNumber]}\n';
          }
          originalCount++;
        } else {
          // Keeping new lines
          for (int lineNumber = conflict.dividerLine! + 1; lineNumber < conflict.endLine!; lineNumber++) {
            result += '${lines[lineNumber]}\n';
          }
          newCount++;
        }
        lastPrintedLine = (conflict.endLine! + 1).clamp(0, lines.length);
      }
      for (int lineNumber = lastPrintedLine; lineNumber < lines.length; lineNumber++) {
        result += '${lines[lineNumber]}\n';
      }
      result.trim();

      // Display conflict summary for this file and confirm with user if the changes should be commited.
      if (boolArg('confirm-commit')) {
        logger.printStatus(terminal.clearScreen(), newline: false);
        logger.printStatus('Conflicts in $localPath complete.\n');
        logger.printStatus('You chose to:\n  Skip $skipCount conflicts\n  Acccept the original lines for $originalCount conflicts\n  Accept the new lines for $newCount conflicts\n');
        String selection = 'y';
        try {
          selection = await terminal.promptForCharInput(
            <String>['y', 'n', 'r'],
            logger: logger,
            prompt: 'Commit the changes to disk? (y)es, (n)o, (r)etry this file',
            defaultChoiceIndex: 1,
          );
        } on StateError catch(e) {
          logger.printError(
            e.message,
            indent: 0,
          );
        }
        switch(selection) {
          case 'y': {
            if (hasChanges) {
              file.writeAsStringSync(result, flush: true);
            }
            break;
          }
          case 'n': {
            break;
          }
          case 'r': {
            i--;
            break;
          }
        }
      } else {
        file.writeAsStringSync(result, flush: true);
      }
    }
    return const FlutterCommandResult(ExitStatus.success);
  }

  void printConflictLine(String text, int lineNumber, {TerminalColor? color}) {
    final String padding = ' ' * (5 - lineNumber.toString().length); // This pads line numbers up to 99,999
    logger.printStatus('$lineNumber$padding', color: TerminalColor.grey, newline: false, indent: 2);
    logger.printStatus(text, color: color);
  }
}

class Conflict {
  Conflict(this.startLine, this.dividerLine, this.endLine);

  Conflict.empty();

  int? startLine;
  int? dividerLine;
  int? endLine;

  bool? keepOriginal;

  void chooseOriginal() {
    keepOriginal = true;
  }

  void skip() {
    keepOriginal = null;
  }

  void chooseNew() {
    keepOriginal = false;
  }
}
