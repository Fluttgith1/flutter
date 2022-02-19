// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';

/// Spacer creates an adjustable, empty spacer that can be used to tune the
/// spacing between widgets in a [Flex] container, like [Row] or [Column].
///
/// The [Spacer] widget will take up any available space, so setting the
/// [Flex.mainAxisAlignment] on a flex container that contains a [Spacer] to
/// [MainAxisAlignment.spaceAround], [MainAxisAlignment.spaceBetween], or
/// [MainAxisAlignment.spaceEvenly] will not have any visible effect: the
/// [Spacer] has taken up all of the additional space, therefore there is none
/// left to redistribute.
///
/// {@tool snippet}
///
/// ```dart
/// Row(
///   children: const <Widget>[
///     Text('Begin'),
///     Spacer(), // Defaults to a flex of one.
///     Text('Middle'),
///     // Gives twice the space between Middle and End than Begin and Middle.
///     Spacer(flex: 2),
///     Text('End'),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=7FJgd7QN1zI}
///
/// See also:
///
///  * [Row] and [Column], which are the most common containers to use a Spacer
///    in.
///  * [SizedBox], to create a box with a specific size and an optional child.
class Spacer extends Flexible {
  const Spacer({
    Key? key,
    int flex = 1,
  })  : assert(flex > 0),
        super(
          key: key,
          flex: flex,
          fit: FlexFit.tight,
          child: const SizedBox.shrink(),
        );
}
