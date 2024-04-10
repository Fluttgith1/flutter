// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() => runApp(const CarouselExample());

class CarouselExample extends StatefulWidget {
  const CarouselExample({super.key});

  @override
  State<CarouselExample> createState() => _CarouselExampleState();
}

class _CarouselExampleState extends State<CarouselExample> {
  final List<int> data = List<int>.generate(20, (int index) => index);

  @override
  Widget build(BuildContext context) {
    print('SCREEN WIDTH: ${MediaQuery.of(context).size.width}');
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Carousel(
            itemSnap: true,
            itemWeights: const <int>[3,3,3,2,1],
            children: List<Card>.generate(data.length, (int index) {
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0)),
                color:
                  Colors.primaries[index % Colors.primaries.length],
                child: Center(
                  child: Text(
                    'Item ${data[index]}',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                    overflow: TextOverflow.clip,
                    softWrap: false,
                  ),
                ),
              );
            }).toList()),
        ),
      ),
    );
  }
}