// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'diagnostics_tree.dart';
import 'error.dart';
import 'find.dart';
import 'frame_sync.dart';
import 'geometry.dart';
import 'gesture.dart';
import 'health.dart';
import 'layer_tree.dart';
import 'message.dart';
import 'render_tree.dart';
import 'request_data.dart';
import 'semantics.dart';
import 'text.dart';
import 'text_input_action.dart';
import 'wait.dart';

/// A factory for deserializing [SerializableFinder]s.
mixin DeserializeFinderFactory {
  /// Deserializes the finder from JSON generated by [SerializableFinder.serialize].
  SerializableFinder deserializeFinder(Map<String, String> json) {
    return switch (json['finderType']) {
      'ByType'           => ByType.deserialize(json),
      'ByValueKey'       => ByValueKey.deserialize(json),
      'ByTooltipMessage' => ByTooltipMessage.deserialize(json),
      'BySemanticsLabel' => BySemanticsLabel.deserialize(json),
      'ByText'           => ByText.deserialize(json),
      'PageBack'         => const PageBack(),
      'Descendant'       => Descendant.deserialize(json, this),
      'Ancestor'         => Ancestor.deserialize(json, this),
      _ => throw DriverError('Unsupported search specification type ${json['finderType']}'),
    };
  }
}

/// A factory for deserializing [Command]s.
mixin DeserializeCommandFactory {
  /// Deserializes the finder from JSON generated by [Command.serialize] or [CommandWithTarget.serialize].
  Command deserializeCommand(Map<String, String> params, DeserializeFinderFactory finderFactory) {
    return switch (params['command']) {
      'get_health'                    => GetHealth.deserialize(params),
      'get_layer_tree'                => GetLayerTree.deserialize(params),
      'get_render_tree'               => GetRenderTree.deserialize(params),
      'enter_text'                    => EnterText.deserialize(params),
      'send_text_input_action'        => SendTextInputAction.deserialize(params),
      'get_text'                      => GetText.deserialize(params, finderFactory),
      'request_data'                  => RequestData.deserialize(params),
      'scroll'                        => Scroll.deserialize(params, finderFactory),
      'scrollIntoView'                => ScrollIntoView.deserialize(params, finderFactory),
      'set_frame_sync'                => SetFrameSync.deserialize(params),
      'set_semantics'                 => SetSemantics.deserialize(params),
      'set_text_entry_emulation'      => SetTextEntryEmulation.deserialize(params),
      'tap'                           => Tap.deserialize(params, finderFactory),
      'waitFor'                       => WaitFor.deserialize(params, finderFactory),
      'waitForAbsent'                 => WaitForAbsent.deserialize(params, finderFactory),
      'waitForTappable'               => WaitForTappable.deserialize(params, finderFactory),
      'waitForCondition'              => WaitForCondition.deserialize(params),
      'waitUntilNoTransientCallbacks' => WaitForCondition.deserialize(params),
      'waitUntilNoPendingFrame'       => WaitForCondition.deserialize(params),
      'waitUntilFirstFrameRasterized' => WaitForCondition.deserialize(params),
      'get_semantics_id'              => GetSemanticsId.deserialize(params, finderFactory),
      'get_offset'                    => GetOffset.deserialize(params, finderFactory),
      'get_diagnostics_tree'          => GetDiagnosticsTree.deserialize(params, finderFactory),
      final String? kind => throw DriverError('Unsupported command kind $kind'),
    };
  }
}
