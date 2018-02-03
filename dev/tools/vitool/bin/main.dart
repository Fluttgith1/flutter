// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:vitool/vitool.dart';

const String kCodegenComment =
  '// AUTOGENERATED FILE DO NOT EDIT!\n'
  '// This file was generated by vitool.\n';

void main(List<String> args) {
  final ArgParser parser = new ArgParser();

  parser.addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Display the tool\'s usage instructions and quit.'
  );

  parser.addOption(
      'output',
      abbr: 'o',
      help: 'Target path to write the generated Dart file to.'
  );

  parser.addOption(
      'asset-name',
      abbr: 'n',
      help: 'Name to be used for the generated constant.'
  );

  parser.addOption(
      'part-of',
      abbr: 'p',
      help: 'Library name to add a dart \'part of\' clause for.'
  );

  parser.addOption(
      'header',
      abbr: 'd',
      help: 'File whose contents are to be prepended to the beginning of '
            'the generated Dart file; this can be used for a license comment.'
  );

  parser.addFlag(
      'codegen_comment',
      abbr: 'c',
      defaultsTo: true,
      help: 'Whether to include the following comment after the header:\n'
            '$kCodegenComment'
  );

  parser.addOption(
      'sample-rate',
      abbr: 's',
      defaultsTo: '1',
      help: 'Frame sample rate; E.g if this is 2, every second frame will be sampled.'
  );

  final ArgResults argResults = parser.parse(args);

  if (argResults['help'] ||
    !argResults.wasParsed('output') ||
    !argResults.wasParsed('asset-name') ||
    argResults.rest.isEmpty) {
    printUsage(parser);
    return;
  }

  int sampleRate = int.parse(argResults['sample-rate']);
  // The loop first increases frameIdx and then checks if frameIdx % sampleRate
  // is 0. To make sure we keep the first frame, we initialize this with -1.
  int frameIdx = -1;
  final List<FrameData> frames = <FrameData>[];
  for (String filePath in argResults.rest) {
    frameIdx = frameIdx + 1;
    if (frameIdx % sampleRate != 0)
      continue;
    final FrameData data = interpretSvg(filePath);
    frames.add(data);
  }

  final StringBuffer generatedSb = new StringBuffer();

  if (argResults.wasParsed('header')) {
    generatedSb.write(new File(argResults['header']).readAsStringSync());
    generatedSb.write('\n');
  }

  if (argResults['codegen_comment'])
    generatedSb.write(kCodegenComment);

  if (argResults.wasParsed('part-of'))
    generatedSb.write('part of ${argResults['part-of']};\n');

  final Animation animation = new Animation.fromFrameData(frames);
  generatedSb.write(animation.toDart('_AnimatedIconData', argResults['asset-name']));

  final File outFile = new File(argResults['output']);
  outFile.writeAsStringSync(generatedSb.toString());
}

void printUsage(ArgParser parser) {
  print('Usage: vitool --asset-name=<asset_name> --output=<output_path> <frames_list>');
  print('\nExample: vitool --asset-name=_\$menu_arrow --output=lib/data/menu_arrow.g.dart assets/svg/menu_arrow/*.svg\n');
  print(parser.usage);
}
