import 'dart:async';

import 'package:flutter/src/painting/text_span.dart';
import 'package:flutter/src/painting/text_style.dart';
import 'package:flutter/src/services/spell_check.dart';
import 'package:flutter/src/services/message_codec.dart';
import 'package:flutter/src/services/platform_channel.dart';
import 'package:flutter/src/services/system_channels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'text_selection_toolbar.dart';
import 'text_selection_toolbar_text_button.dart';

class MaterialSpellCheckService implements SpellCheckService {
  late MethodChannel spellCheckChannel;

  StreamController<List<SpellCheckerSuggestionSpan>> controller = StreamController<List<SpellCheckerSuggestionSpan>>.broadcast();

  MaterialSpellCheckService() {
    spellCheckChannel = SystemChannels.spellCheck;    
    spellCheckChannel.setMethodCallHandler(_handleSpellCheckInvocation);
  }

    Future<dynamic> _handleSpellCheckInvocation(MethodCall methodCall) async {
    final String method = methodCall.method;
    final List<dynamic> args = methodCall.arguments as List<dynamic>;

    switch (method) {
      //TODO(camillesimon): Rename all spellcheckER names to spellcheck
      case 'SpellCheck.updateSpellCheckResults':
        List<String> results = args.cast<String>();
        List<SpellCheckerSuggestionSpan> spellCheckerSuggestionSpans = <SpellCheckerSuggestionSpan>[];

        results.forEach((String result) {
          List<String> resultParsed = result.split(".");
          print('RAW SPELLCHECK RESULTS: ${resultParsed}');
          print(resultParsed[2].split("/n"));
          spellCheckerSuggestionSpans.add(SpellCheckerSuggestionSpan(int.parse(resultParsed[0]), int.parse(resultParsed[1]), resultParsed[2].split("/n")));
        });
        print("---------------------------------------------------------------");

        controller.sink.add(spellCheckerSuggestionSpans);
        break;
      default:
        throw MissingPluginException();
    }
  }

    @override
    Future<List<SpellCheckerSuggestionSpan>> fetchSpellCheckSuggestions(Locale locale, TextEditingValue value) async {
    assert(locale != null);
    assert(value.text != null);

    List<SpellCheckerSuggestionSpan> spellCheckResults = <SpellCheckerSuggestionSpan>[];

    spellCheckChannel.invokeMethod<void>(
        'SpellCheck.initiateSpellCheck',
        <String>[ locale.toLanguageTag(), value.text],
      );
    
    await for (final result in controller.stream) {
      TextRange composingRange = value.composing;
      result.forEach((SpellCheckerSuggestionSpan span) {
        bool isWithinComposingRegion = composingRange.start == span.start && composingRange.end == span.end;

        if (!isWithinComposingRegion) {
            spellCheckResults.add(span);
        }
      });

      return spellCheckResults;
    }
    
    //TODO(camillesimon): Maybe return an exception
    return spellCheckResults;
  }
}