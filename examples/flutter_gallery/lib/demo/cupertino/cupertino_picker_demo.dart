// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'cupertino_navigation_demo.dart' show coolColorNames;

const double _kPickerSheetHeight = 216.0;
const double _kPickerItemHeight = 32.0;

class CupertinoPickerDemo extends StatefulWidget {
  static const String routeName = '/cupertino/picker';

  @override
  _CupertinoPickerDemoState createState() => new _CupertinoPickerDemoState();
}

class _CupertinoPickerDemoState extends State<CupertinoPickerDemo> {
  int _selectedItemIndex = 0;

  int _alarmHour = 0;
  int _alarmMinute = 0;

  Widget _buildMenu() {
    return new Container(
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        border: const Border(
          top: const BorderSide(color: const Color(0xFFBCBBC1), width: 0.0),
          bottom: const BorderSide(color: const Color(0xFFBCBBC1), width: 0.0),
        ),
      ),
      height: 44.0,
      child: new Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: new SafeArea(
          top: false,
          bottom: false,
          child: new DefaultTextStyle(
            style: const TextStyle(
              letterSpacing: -0.24,
              fontSize: 17.0,
              color: CupertinoColors.black,
            ),
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text('Favorite Color'),
                new Text(
                  coolColorNames[_selectedItemIndex],
                  style: const TextStyle(color: CupertinoColors.inactiveGray),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPicker() {
    final FixedExtentScrollController scrollController =
        new FixedExtentScrollController(initialItem: _selectedItemIndex);

    return new Container(
      height: _kPickerSheetHeight,
      color: CupertinoColors.white,
      child: new DefaultTextStyle(
        style: const TextStyle(
          color: CupertinoColors.black,
          fontSize: 22.0,
        ),
        child: new GestureDetector(
          // Blocks taps from propagating to the modal sheet and popping.
          onTap: () {},
          child: new SafeArea(
            child: new CupertinoPicker(
              scrollController: scrollController,
              itemExtent: _kPickerItemHeight,
              backgroundColor: CupertinoColors.white,
              onSelectedItemChanged: (int index) {
                setState(() {
                  _selectedItemIndex = index;
                });
              },
              children: new List<Widget>.generate(coolColorNames.length, (int index) {
                return new Center(child:
                  new Text(coolColorNames[index]),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmMenu() {
    String time = _alarmHour.toString().padLeft(2, '0') + ': ' +
                  _alarmMinute.toString().padLeft(2, '0');
    return new Container(
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        border: const Border(
          top: const BorderSide(color: const Color(0xFFBCBBC1), width: 0.0),
          bottom: const BorderSide(color: const Color(0xFFBCBBC1), width: 0.0),
        ),
      ),
      height: 44.0,
      child: new Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: new SafeArea(
          top: false,
          bottom: false,
          child: new DefaultTextStyle(
            style: const TextStyle(
              letterSpacing: -0.24,
              fontSize: 17.0,
              color: CupertinoColors.black,
            ),
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text('Alarm'),
                new Text(
                  time,
                  style: const TextStyle(color: CupertinoColors.inactiveGray),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmBottomPicker() {
    return new Container(
      height: _kPickerSheetHeight,
      color: CupertinoColors.white,
      child: new DefaultTextStyle(
        style: const TextStyle(
          color: CupertinoColors.black,
          fontSize: 22.0,
        ),
        child: new GestureDetector(
          // Blocks taps from propagating to the modal sheet and popping.
          onTap: () {},
          child: new SafeArea(
            child: new MultiColumnCupertinoPicker(
              children: <CupertinoPicker>[
                new CupertinoPicker(
                  scrollController: new FixedExtentScrollController(
                                      initialItem: _alarmHour,
                                    ),
                  centerViewRate: 2.0,
                  magnifyRate: 1.1,
                  itemExtent: _kPickerItemHeight,
                  backgroundColor: CupertinoColors.white,
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _alarmHour = index;
                    });
                  },
                  children: new List<Widget>.generate(24, (int index) {
                    return new Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 32.0),
                      child: new Text(index.toString()),
                    );
                  }),
                ),
                new CupertinoPicker(
                  scrollController: new FixedExtentScrollController(
                                      initialItem: _alarmMinute,
                                    ),
                  centerViewRate: 0.0,
                  magnifyRate: 1.1,
                  itemExtent: _kPickerItemHeight,
                  backgroundColor: CupertinoColors.white,
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _alarmMinute = index;
                    });
                  },
                  children: new List<Widget>.generate(60, (int index) {
                    return new Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(left: 32.0),
                      child: new Text(index.toString()),
                    );
                  }),
                ),
                ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Cupertino Picker'),
      ),
      body: new DefaultTextStyle(
        style: const TextStyle(
          fontFamily: '.SF UI Text',
          fontSize: 17.0,
          color: CupertinoColors.black,
        ),
        child: new DecoratedBox(
          decoration: const BoxDecoration(color: const Color(0xFFEFEFF4)),
          child: new ListView(
            children: <Widget>[
              const Padding(padding: const EdgeInsets.only(top: 32.0)),
              new GestureDetector(
                onTap: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return _buildBottomPicker();
                    },
                  );
                },
                child: _buildMenu(),
              ),
              const Padding(padding: const EdgeInsets.only(top: 4.0)),
              new GestureDetector(
                onTap: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return _buildAlarmBottomPicker();
                    },
                  );
                },
                child: _buildAlarmMenu(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
