// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [TextButton].

void main() {
  runApp(const TextButtonExampleApp());
}

class TextButtonExampleApp extends StatefulWidget {
  const TextButtonExampleApp({ super.key });

  @override
  State<TextButtonExampleApp> createState() => _TextButtonExampleAppState();
}

class _TextButtonExampleAppState extends State<TextButtonExampleApp> {
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TextButtonExample(
            darkMode: darkMode,
            updateDarkMode: (bool value) {
              setState(() { darkMode = value; });
            },
          ),
        ),
      ),
    );
  }
}

class TextButtonExample extends StatefulWidget {
  const TextButtonExample({ super.key, required this.darkMode, required this.updateDarkMode });

  final bool darkMode;
  final ValueChanged<bool> updateDarkMode;

  @override
  State<TextButtonExample> createState() => _TextButtonExampleState();
}

class _TextButtonExampleState extends State<TextButtonExample> {
  TextDirection textDirection = TextDirection.ltr;
  ThemeMode themeMode = ThemeMode.light;
  VisualDensity visualDensity = VisualDensity.standard;

  static const Widget verticalSpacer = SizedBox(height: 16);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // Adapt colors that are not part of the color scheme to
    // the current dark/light mode. Used to define TextButton #7's
    // gradients.
    final Color color1;
    final Color color2;
    final Color color3;
    switch (colorScheme.brightness) {
      case Brightness.light:
        color1 = Colors.blue.withOpacity(0.5);
        color2 = Colors.orange.withOpacity(0.5);
        color3 = Colors.yellow.withOpacity(0.5);
      case Brightness.dark:
        color1 = Colors.purple.withOpacity(0.5);
        color2 = Colors.cyan.withOpacity(0.5);
        color3 = Colors.yellow.withOpacity(0.5);
    }

    // This gradient's appearance reflects the button's state.
    // Always return a gradient decoration so that AnimatedContainer
    // can interpolorate in between. Used by TextButton #7.
    Decoration? statesToDecoration(Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        return BoxDecoration(
          gradient: LinearGradient(colors: <Color>[color2, color2]), // solid fill
        );
      }
      return BoxDecoration(
        gradient: LinearGradient(
          colors: switch (states.contains(MaterialState.hovered)) {
            true => <Color>[color1, color2],
            false => <Color>[color2, color1],
          },
        ),
      );
    }

    return Row(
      children: <Widget> [
        // The dark/light and LTR/RTL switches. We use the updateDarkMode function
        // provided by the parent TextButtonExampleApp to rebuild the MaterialApp
        // in the appropriate dark/light ThemeMdoe. The directionality of the rest
        // of the UI is controlled by the Directionality widget below, and the
        // textDirection local state variable.
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: IntrinsicWidth(
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(child: Text('Dark Mode')),
                      const SizedBox(width: 4),
                      Switch(
                        value: widget.darkMode,
                        onChanged: (bool value) {
                          widget.updateDarkMode(value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      const Expanded(child: Text('RTL Text')),
                      const SizedBox(width: 4),
                      Switch(
                        value: textDirection == TextDirection.rtl,
                        onChanged: (bool value) {
                          setState(() {
                            textDirection = value ? TextDirection.rtl : TextDirection.ltr;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // All of the button examples appear below. They're arranged in two columns.

        // This theme defines default property overrides for all of the buttons
        // that follow.
        TextButtonTheme(
          data: TextButtonThemeData(
            style: TextButton.styleFrom(
              visualDensity: visualDensity,
              textStyle: theme.textTheme.labelLarge,
            ),
          ),
          child: Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Directionality(
                  textDirection: textDirection,
                  child: Column(
                    children: <Widget>[
                      TextButton(
                        onPressed: () {},
                        child: const Text('Enabled'),
                      ),
                      verticalSpacer,

                      const TextButton(
                        onPressed: null,
                        child: Text('Disabled'),
                      ),
                      verticalSpacer,

                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.access_alarm),
                        label: const Text('TextButton.icon #1'),
                      ),
                      verticalSpacer,

                      // Override the foreground and background colors.
                      //
                      // In this example, and most of the ones that follow, we're using
                      // the TextButton.styleFrom() convenience method to create a ButtonStyle.
                      // The styleFrom method is a little easier because it creates
                      // ButtonStyle MaterialStateProperty parameters for you.
                      // In this case, Specifying foregroundColor overrides the text,
                      // icon and overlay (splash and highlight) colors a little differently
                      // depending on the button's state. BackgroundColor is just the background
                      // color for all states.
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.onError,
                          backgroundColor: colorScheme.error,
                        ),
                        onPressed: () { },
                        icon: const Icon(Icons.access_alarm),
                        label: const Text('TextButton.icon #2'),
                      ),
                      verticalSpacer,

                      // Override the button's shape and its border.
                      //
                      // In this case we've specified a shape that has border - the
                      // RoundedRectangleBorder's side parameter. If the styleFrom
                      // side parameter was also specified, or if the TextButtonTheme
                      // defined above included a side parameter, then that would
                      // override the RoundedRectangleBorder's side.
                      TextButton(
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                            side: BorderSide(
                              color: colorScheme.primary,
                              width: 5,
                            ),
                          ),
                        ),
                        onPressed: () { },
                        child: const Text('TextButton #3'),
                      ),
                      verticalSpacer,

                      // Override overlay: the ink splash and highlight colors.
                      //
                      // The styleFrom method turns the specified overlayColor
                      // into a value MaterialStyleProperty<Color> ButtonStyle.overlay
                      // value that uses opacities depending on the button's state.
                      // If the overlayColor was Colors.transparent, no splash
                      // or highlights would be shown.
                      TextButton(
                        style: TextButton.styleFrom(
                          overlayColor: Colors.yellow,
                        ),
                        onPressed: () { },
                        child: const Text('TextButton #4'),
                      ),
                    ],
                  ),
                ),

                Directionality(
                  textDirection: textDirection,
                  child: Column(
                    children: <Widget>[
                      // Override the foregroundBuilder: apply a ShaderMask.
                      //
                      // Apply a ShaderMask to the button's child. This kind of thing
                      // can be applied to one button easily enough by just wrapping the
                      // button's child directly. However to affect all buttons in this
                      // way you can specify a similar foregroundBuilder in a TextButton
                      // theme or the MaterialApp theme's ThemeData.textButtonTheme.
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundBuilder: (BuildContext context, Set<MaterialState> states, Widget? child) {
                            return ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: <Color>[
                                    colorScheme.primary,
                                    colorScheme.onPrimary,
                                  ],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.srcATop,
                              child: child,
                            );
                          },
                        ),
                        onPressed: () { },
                        child: const Text('TextButton #5'),
                      ),
                      verticalSpacer,

                      // Override the foregroundBuilder: add an underline.
                      //
                      // Add a border around button's child. In this case the
                      // border only appears when the button is hovered or pressed
                      // (if it's pressed it's always hovered too). Not that this
                      // border is different than the one specified with the styleFrom
                      // side parameter (or the ButtonStyle.side property). The foregroundBuilder
                      // is applied to a widget that contains the child and has already
                      // included the button's padding. It is unaffected by the button's shape.
                      // The styleFrom side parameter controls the button's outermost border and it
                      // outlines the button's shape.
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundBuilder: (BuildContext context, Set<MaterialState> states, Widget? child) {
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                border: states.contains(MaterialState.hovered)
                                  ? Border(bottom: BorderSide(color: colorScheme.primary))
                                  : const Border(), // essentially "no border"
                              ),
                              child: child,
                            );
                          },
                        ),
                        onPressed: () { },
                        child: const Text('TextButton #6'),
                      ),
                      verticalSpacer,

                      // Override the backgroundBuilder to add a state specific gradient background
                      // and add an outline that only appears when the button is hovered or pressed.
                      //
                      // The gradient background decoration is computed by the statesToDecoration()
                      // method. The gradient flips horizontally when the button is hovered (watch
                      // closely). Because we want the outline to only appear when the button is hovered
                      // we can't use the styleFrom() side parameter, because that creates the same
                      // outline for all states. The ButtonStyle.copyWith() method is used to add
                      // a MaterialState<BorderSide?> property that does the right thing.
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          overlayColor: color2,
                          backgroundBuilder: (BuildContext context, Set<MaterialState> states, Widget? child) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              decoration: statesToDecoration(states),
                              child: child,
                            );
                          },
                        ).copyWith(
                          side: MaterialStateProperty.resolveWith<BorderSide?>((Set<MaterialState> states) {
                            if (states.contains(MaterialState.hovered)) {
                              return BorderSide(width: 3, color: color3);
                            }
                            return null; // defer to the default
                          }),
                        ),
                        child: const Text('TextButton #7'),
                      ),
                      verticalSpacer,

                      // Override the backgroundBuilder to add a burlap image background.
                      //
                      // The image is clipped to the button's shape. We've included an Ink widget
                      // because the background image is opaque and would otherwise obscure the splash
                      // and highlight overlays that are painted on the button's Material widget
                      // by default. They're drawn on the Ink widget instead. The foreground color
                      // was overridden as well because black shows up a little better on the mottled
                      // brown background.
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundBuilder: (BuildContext context, Set<MaterialState> states, Widget? child) {
                            return Ink(
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(burlapUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: child,
                            );
                          },
                        ),
                        child: const Text('TextButton #8'),
                      ),
                      verticalSpacer,

                      // Override the foregroundBuilder to specify images for the button's pressed
                      // hovered and inactive states.
                      //
                      // This is an example of completely changing the default appearance of a button
                      // by specifying images for each state and by turning off the overlays by
                      // overlayColor: Colors.transparent. AnimatedContainer takes care of the
                      // fade in and out segues between images.
                      //
                      // This foregroundBuilder function ignores its child parameter. Unfortunately
                      // TextButton's child parameter is required, so we still have
                      // to provide one.
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          overlayColor: Colors.transparent,
                          foregroundBuilder: (BuildContext context, Set<MaterialState> states, Widget? child) {
                            String url = states.contains(MaterialState.hovered) ? smiley3Url : smiley1Url;
                            if (states.contains(MaterialState.pressed)) {
                              url = smiley2Url;
                            }
                            return AnimatedContainer(
                              width: 64,
                              height: 64,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.fastOutSlowIn,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(url),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          },
                        ),
                        child: const Text('This child is not used'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

const String burlapUrl = 'https://media.istockphoto.com/id/152949844/photo/a-tan-burlap-textile-background-can-you-be-used-for-a-sack.jpg?s=612x612&w=0&k=20&c=AmUxRFPqpjzoi5D6r3flsRYANARdLQmyB5qt_LoryRs=';
const String smiley1Url = 'https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/626f7f20-56da-4a6c-9996-50364c8b9ae2/dbc4dre-9244e67e-5e6b-44af-89e3-63cec6d18521.png/v1/fit/w_375,h_351/just_another_happy_smiley_____by_mondspeer_dbc4dre-375w.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7ImhlaWdodCI6Ijw9NTYxIiwicGF0aCI6IlwvZlwvNjI2ZjdmMjAtNTZkYS00YTZjLTk5OTYtNTAzNjRjOGI5YWUyXC9kYmM0ZHJlLTkyNDRlNjdlLTVlNmItNDRhZi04OWUzLTYzY2VjNmQxODUyMS5wbmciLCJ3aWR0aCI6Ijw9NjAwIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmltYWdlLm9wZXJhdGlvbnMiXX0.w7Xx-DmFGXjb6kbWn5_jXqcI6VKNZICN18hmkU8WmlQ';
const String smiley2Url = 'https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/i/626f7f20-56da-4a6c-9996-50364c8b9ae2/d8gvlso-4b7bf222-1560-4f13-85b0-6a6371191aa3.png';
const String smiley3Url = 'https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/i/626f7f20-56da-4a6c-9996-50364c8b9ae2/d8hfwwe-801502fe-7457-473e-9df2-b62e7bfdb1ff.png';
