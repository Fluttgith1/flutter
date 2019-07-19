import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'motion_events_page.dart';
import 'mutation_page.dart';
import 'page.dart';
import 'scroll_vew_nested_platform_view.dart';

final List<Page> _allPages = <Page>[
  const MotionEventsPage(),
  const MutationCompositionPage(),
  const ScrollViewNestedPlatformView(),
];

void main() {
  enableFlutterDriverExtension(handler: driverDataHandler.handleMessage);
  runApp(MaterialApp(home: Home()));
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _allPages.length,
        itemBuilder: (_, int index) => ListTile(
          title: Text(_allPages[index].title),
          key: _allPages[index].tileKey,
          onTap: () => _pushPage(context, _allPages[index]),
        ),
      ),
    );
  }

  void _pushPage(BuildContext context, Page page) {
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => Scaffold(
              body: page,
            )));
  }
}
