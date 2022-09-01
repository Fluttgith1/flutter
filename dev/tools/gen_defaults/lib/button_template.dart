// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class ButtonTemplate extends TokenTemplate {
<<<<<<< HEAD
  const ButtonTemplate(this.tokenGroup, String fileName, Map<String, dynamic> tokens)
    : super(fileName, tokens,
        colorSchemePrefix: '_colors.',
      );
=======
  const ButtonTemplate(this.tokenGroup, super.blockName, super.fileName, super.tokens, {
    super.colorSchemePrefix = '_colors.',
  });
>>>>>>> ffccd96b62ee8cec7740dab303538c5fc26ac543

  final String tokenGroup;

  String _backgroundColor() {
    if (tokens.containsKey('$tokenGroup.container.color')) {
      return '''

    MaterialStateProperty.resolveWith((Set<MaterialState> states) {
<<<<<<< HEAD
      if (states.contains(MaterialState.disabled))
        return ${componentColor('$tokenGroup.disabled.container')};
=======
      if (states.contains(MaterialState.disabled)) {
        return ${componentColor('$tokenGroup.disabled.container')};
      }
>>>>>>> ffccd96b62ee8cec7740dab303538c5fc26ac543
      return ${componentColor('$tokenGroup.container')};
    })''';
    }
    return '''

    ButtonStyleButton.allOrNull<Color>(Colors.transparent)''';
  }

  String _elevation() {
    if (tokens.containsKey('$tokenGroup.container.elevation')) {
      return '''

    MaterialStateProperty.resolveWith((Set<MaterialState> states) {
<<<<<<< HEAD
      if (states.contains(MaterialState.disabled))
        return ${elevation("$tokenGroup.disabled.container")};
      if (states.contains(MaterialState.hovered))
        return ${elevation("$tokenGroup.hover.container")};
      if (states.contains(MaterialState.focused))
        return ${elevation("$tokenGroup.focus.container")};
      if (states.contains(MaterialState.pressed))
        return ${elevation("$tokenGroup.pressed.container")};
=======
      if (states.contains(MaterialState.disabled)) {
        return ${elevation("$tokenGroup.disabled.container")};
      }
      if (states.contains(MaterialState.hovered)) {
        return ${elevation("$tokenGroup.hover.container")};
      }
      if (states.contains(MaterialState.focused)) {
        return ${elevation("$tokenGroup.focus.container")};
      }
      if (states.contains(MaterialState.pressed)) {
        return ${elevation("$tokenGroup.pressed.container")};
      }
>>>>>>> ffccd96b62ee8cec7740dab303538c5fc26ac543
      return ${elevation("$tokenGroup.container")};
    })''';
    }
    return '''

    ButtonStyleButton.allOrNull<double>(0.0)''';
  }

  @override
  String generate() => '''
<<<<<<< HEAD
// Generated version ${tokens["version"]}
class _TokenDefaultsM3 extends ButtonStyle {
  _TokenDefaultsM3(this.context)
=======
class _${blockName}DefaultsM3 extends ButtonStyle {
  _${blockName}DefaultsM3(this.context)
>>>>>>> ffccd96b62ee8cec7740dab303538c5fc26ac543
   : super(
       animationDuration: kThemeChangeDuration,
       enableFeedback: true,
       alignment: Alignment.center,
     );

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  MaterialStateProperty<TextStyle?> get textStyle =>
<<<<<<< HEAD
    MaterialStateProperty.all<TextStyle?>(${textStyle("$tokenGroup.label-text")});
=======
    MaterialStatePropertyAll<TextStyle?>(${textStyle("$tokenGroup.label-text")});
>>>>>>> ffccd96b62ee8cec7740dab303538c5fc26ac543

  @override
  MaterialStateProperty<Color?>? get backgroundColor =>${_backgroundColor()};

  @override
  MaterialStateProperty<Color?>? get foregroundColor =>
    MaterialStateProperty.resolveWith((Set<MaterialState> states) {
<<<<<<< HEAD
      if (states.contains(MaterialState.disabled))
        return ${componentColor('$tokenGroup.disabled.label-text')};
=======
      if (states.contains(MaterialState.disabled)) {
        return ${componentColor('$tokenGroup.disabled.label-text')};
      }
>>>>>>> ffccd96b62ee8cec7740dab303538c5fc26ac543
      return ${componentColor('$tokenGroup.label-text')};
    });

  @override
  MaterialStateProperty<Color?>? get overlayColor =>
    MaterialStateProperty.resolveWith((Set<MaterialState> states) {
<<<<<<< HEAD
      if (states.contains(MaterialState.hovered))
        return ${componentColor('$tokenGroup.hover.state-layer')};
      if (states.contains(MaterialState.focused))
        return ${componentColor('$tokenGroup.focus.state-layer')};
      if (states.contains(MaterialState.pressed))
        return ${componentColor('$tokenGroup.pressed.state-layer')};
=======
      if (states.contains(MaterialState.hovered)) {
        return ${componentColor('$tokenGroup.hover.state-layer')};
      }
      if (states.contains(MaterialState.focused)) {
        return ${componentColor('$tokenGroup.focus.state-layer')};
      }
      if (states.contains(MaterialState.pressed)) {
        return ${componentColor('$tokenGroup.pressed.state-layer')};
      }
>>>>>>> ffccd96b62ee8cec7740dab303538c5fc26ac543
      return null;
    });

${tokens.containsKey("$tokenGroup.container.shadow-color") ? '''
  @override
  MaterialStateProperty<Color>? get shadowColor =>
    ButtonStyleButton.allOrNull<Color>(${color("$tokenGroup.container.shadow-color")});''' : '''
  // No default shadow color'''}

${tokens.containsKey("$tokenGroup.container.surface-tint-layer.color") ? '''
  @override
  MaterialStateProperty<Color>? get surfaceTintColor =>
    ButtonStyleButton.allOrNull<Color>(${color("$tokenGroup.container.surface-tint-layer.color")});''' : '''
  // No default surface tint color'''}

  @override
  MaterialStateProperty<double>? get elevation =>${_elevation()};

  @override
  MaterialStateProperty<EdgeInsetsGeometry>? get padding =>
    ButtonStyleButton.allOrNull<EdgeInsetsGeometry>(_scaledPadding(context));

  @override
  MaterialStateProperty<Size>? get minimumSize =>
    ButtonStyleButton.allOrNull<Size>(const Size(64.0, ${tokens["$tokenGroup.container.height"]}));

  // No default fixedSize

  @override
  MaterialStateProperty<Size>? get maximumSize =>
    ButtonStyleButton.allOrNull<Size>(Size.infinite);

${tokens.containsKey("$tokenGroup.outline.color") ? '''
  @override
  MaterialStateProperty<BorderSide>? get side =>
    MaterialStateProperty.resolveWith((Set<MaterialState> states) {
<<<<<<< HEAD
    if (states.contains(MaterialState.disabled))
      return ${border("$tokenGroup.disabled.outline")};
=======
    if (states.contains(MaterialState.disabled)) {
      return ${border("$tokenGroup.disabled.outline")};
    }
>>>>>>> ffccd96b62ee8cec7740dab303538c5fc26ac543
    return ${border("$tokenGroup.outline")};
  });''' : '''
  // No default side'''}

  @override
  MaterialStateProperty<OutlinedBorder>? get shape =>
    ButtonStyleButton.allOrNull<OutlinedBorder>(${shape("$tokenGroup.container")});

  @override
  MaterialStateProperty<MouseCursor?>? get mouseCursor =>
    MaterialStateProperty.resolveWith((Set<MaterialState> states) {
<<<<<<< HEAD
      if (states.contains(MaterialState.disabled))
        return SystemMouseCursors.basic;
=======
      if (states.contains(MaterialState.disabled)) {
        return SystemMouseCursors.basic;
      }
>>>>>>> ffccd96b62ee8cec7740dab303538c5fc26ac543
      return SystemMouseCursors.click;
    });

  @override
  VisualDensity? get visualDensity => Theme.of(context).visualDensity;

  @override
  MaterialTapTargetSize? get tapTargetSize => Theme.of(context).materialTapTargetSize;

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;
}
''';
}
