// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'find.dart';
import 'message.dart';

/// A Flutter Driver command that reads the text from a given element.
class GetText extends CommandWithTarget {
  /// [finder] looks for an element that contains a piece of text.
  GetText(super.finder, { super.timeout });

  /// Deserializes this command from the value generated by [serialize].
  GetText.deserialize(super.json, super.finderFactory) : super.deserialize();

  @override
  String get kind => 'get_text';
}

/// The result of the [GetText] command.
class GetTextResult extends Result {
  /// Creates a result with the given [text].
  const GetTextResult(this.text);

  /// The text extracted by the [GetText] command.
  final String text;

  /// Deserializes the result from JSON.
  static GetTextResult fromJson(final Map<String, dynamic> json) {
    return GetTextResult(json['text'] as String);
  }

  @override
  Map<String, dynamic> toJson() => <String, String>{
    'text': text,
  };
}

/// A Flutter Driver command that enters text into the currently focused widget.
class EnterText extends Command {
  /// Creates a command that enters text into the currently focused widget.
  const EnterText(this.text, { super.timeout });

  /// Deserializes this command from the value generated by [serialize].
  EnterText.deserialize(super.json)
    : text = json['text']!,
      super.deserialize();

  /// The text extracted by the [GetText] command.
  final String text;

  @override
  String get kind => 'enter_text';

  @override
  Map<String, String> serialize() => super.serialize()..addAll(<String, String>{
    'text': text,
  });
}

/// A Flutter Driver command that enables and disables text entry emulation.
class SetTextEntryEmulation extends Command {
  /// Creates a command that enables and disables text entry emulation.
  const SetTextEntryEmulation(this.enabled, { super.timeout });

  /// Deserializes this command from the value generated by [serialize].
  SetTextEntryEmulation.deserialize(super.json)
    : enabled = json['enabled'] == 'true',
      super.deserialize();

  /// Whether text entry emulation should be enabled.
  final bool enabled;

  @override
  String get kind => 'set_text_entry_emulation';

  @override
  Map<String, String> serialize() => super.serialize()..addAll(<String, String>{
    'enabled': '$enabled',
  });
}
