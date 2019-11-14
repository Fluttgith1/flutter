// Copyright 2019-present the Flutter authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';

import 'package:flutter_gallery/demo/rally/data.dart';
import 'package:flutter_gallery/demo/rally/login.dart';

class SettingsView extends StatefulWidget {
  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  List<Widget> items = DummyDataService.getSettingsTitles()
      .map((String title) => _SettingsItem(title))
      .toList();

  @override
  Widget build(BuildContext context) {
    return ListView(children: items);
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      textColor: Colors.white,
      child: SizedBox(
        height: 60,
        child: Row(children: <Widget>[
          Text(title),
        ]),
      ),
      onPressed: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (BuildContext context) => LoginPage()),
        );
      },
    );
  }
}
