// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'recorder.dart';

/// Creates a [Wrap] inside a ListView.
///
/// Tests large number of DOM nodes since image breaks up large canvas.
class BenchWrapBoxScroll extends WidgetRecorder {
  BenchWrapBoxScroll() : super(name: benchmarkName);

  static const String benchmarkName = 'bench_wrapbox_scroll';

  @override
  Widget createWidget() {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      title: 'WrapBox Scroll Benchmark',
      home: Scaffold(body: const MyHomePage()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ScrollController scrollController;
  int block = 0;
  static const Duration stepDuration = Duration(milliseconds: 500);
  static const double stepDistance = 400;

  @override
  void initState() {
    super.initState();

    scrollController = ScrollController();

    // Without the timer the animation doesn't begin.
    Timer.run(() async {
      while (block < 25) {
        await scrollController.animateTo((block % 5) * stepDistance,
            duration: stepDuration, curve: Curves.easeInOut);
        block++;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
        controller: scrollController,
        children: [
            Wrap(
              children: <Widget>[
                for (int i = 0; i < 30; i++)
                  FractionallySizedBox(
                    widthFactor: 0.2,
                    child: ProductPreview(i)), //need case1
                for (int i = 0; i < 30; i++) ProductPreview(i), //need case2
        ],
      ),
    ]);
  }
}

class ProductPreview extends StatelessWidget {
  const ProductPreview(this.previewIndex);

  final int previewIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => print('tap'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.all(23),
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xfff9f9f9),
              shape: BoxShape.circle,
            ),
            child: Image.network(
              'assets/assets/Icon-192.png',
              width: 100,
              height: 100,
            ),
          ),
          const Text(
            'title',
          ),
          const SizedBox(
            height: 14,
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              ProductOption(
                optionText: '$previewIndex: option1',
              ),
              ProductOption(
                optionText: '$previewIndex: option2',
              ),
              ProductOption(
                optionText: '$previewIndex: option3',
              ),
              ProductOption(
                optionText: '$previewIndex: option4',
              ),
              ProductOption(
                optionText: '$previewIndex: option5',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProductOption extends StatelessWidget {
  final String optionText;
  const ProductOption({
    Key key,
    @required this.optionText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 56),
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(
          width: 1,
          color: const Color(0xffebebeb),
        ),
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      child: Text(
        optionText,
        maxLines: 1,
        // style: Theme.of(context).textTheme.bodyText2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
