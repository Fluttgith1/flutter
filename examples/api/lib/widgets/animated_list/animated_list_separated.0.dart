// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [AnimatedListSeparated].

void main() {
  runApp(const AnimatedListSeparatedSample());
}

class AnimatedListSeparatedSample extends StatefulWidget {
  const AnimatedListSeparatedSample({super.key});

  @override
  State<AnimatedListSeparatedSample> createState() => _AnimatedListSeparatedSampleState();
}

class _AnimatedListSeparatedSampleState extends State<AnimatedListSeparatedSample> {
  final GlobalKey<AnimatedListSeparatedState> _listKey = GlobalKey<AnimatedListSeparatedState>();
  late ListModel<int> _list;
  int? _selectedItem;
  late int _nextItem; // The next item inserted when the user presses the '+' button.

  @override
  void initState() {
    super.initState();
    _list = ListModel<int>(
      listKey: _listKey,
      initialItems: <int>[0, 1, 2],
      removedItemBuilder: _buildRemovedItem,
      removedSeparatorBuilder: _buildRemovedSeparator,
    );
    _nextItem = 3;
  }

  // Used to build list items that haven't been removed.
  Widget _buildItem(BuildContext context, int index, Animation<double> animation) {
    return CardItem(
      animation: animation,
      item: _list[index],
      selected: _selectedItem == _list[index],
      onTap: () {
        setState(() {
          _selectedItem = _selectedItem == _list[index] ? null : _list[index];
        });
      },
    );
  }

  // Used to build separators that haven't been removed.
  Widget _buildSeparator(BuildContext context, int index, Animation<double> animation) {
    return ItemSeparator(
      animation: animation,
      item: _list[index],
    );
  }

  /// The builder function used to build items that have been removed.
  ///
  /// Used to build an item after it has been removed from the list. This method
  /// is needed because a removed item remains visible until its animation has
  /// completed (even though it's gone as far as this ListModel is concerned).
  /// The widget will be used by the [AnimatedListSeparatedState.removeSeparatedItem] method's
  /// `itemBuilder` parameter.
  Widget _buildRemovedItem(int item, BuildContext context, Animation<double> animation) {
    return CardItem(
      animation: animation,
      item: item,
      // No gesture detector here: we don't want removed items to be interactive.
    );
  }

  // Build a separator for items that have been removed from the list.
  /// The widget will be used by the [AnimatedListSeparatedState.removeSeparatedItem] method's
  /// `separatorBuilder` parameter.
  Widget _buildRemovedSeparator(int item , BuildContext context, Animation<double> animation) => SizeTransition(
                sizeFactor: animation,
                child: ItemSeparator(
                  animation: animation,
                  item: item,
                )
              );

  // Insert the "next item" into the list model.
  void _insert() {
    final int index = _selectedItem == null ? _list.length : _list.indexOf(_selectedItem!);
    _list.insert(index, _nextItem++);
  }

  // Remove the selected item from the list model.
  void _remove() {
    if (_selectedItem != null) {
      _list.removeAt(_list.indexOf(_selectedItem!));
      setState(() {
        _selectedItem = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AnimatedListSeparated'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _insert,
              tooltip: 'insert a new item',
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle),
              onPressed: _remove,
              tooltip: 'remove the selected item',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AnimatedListSeparated(
            key: _listKey,
            initialItemCount: _list.length,
            itemBuilder: _buildItem,
            separatorBuilder: _buildSeparator,
          ),
        ),
      ),
    );
  }
}

typedef RemovedItemBuilder<T> = Widget Function(T item, BuildContext context, Animation<double> animation);

/// Keeps a Dart [List] in sync with an [AnimatedListSeparated].
///
/// The [insert] and [removeAt] methods apply to both the internal list and
/// the animated list that belongs to [listKey].
///
/// This class only exposes as much of the Dart List API as is needed by the
/// sample app. More list methods are easily added, however methods that
/// mutate the list must make the same changes to the animated list in terms
/// of [AnimatedListSeparatedState.insertItem] and [AnimatedListSeparatedState.removeSeparatedItem].
class ListModel<E> {
  ListModel({
    required this.listKey,
    required this.removedItemBuilder,
    required this.removedSeparatorBuilder,
    Iterable<E>? initialItems,
  }) : _items = List<E>.from(initialItems ?? <E>[]);

  final GlobalKey<AnimatedListSeparatedState> listKey;
  final RemovedItemBuilder<E> removedItemBuilder;
  final RemovedItemBuilder<E> removedSeparatorBuilder;
  final List<E> _items;

  AnimatedListSeparatedState? get _animatedListSeparated => listKey.currentState;

  void insert(int index, E item) {
    _items.insert(index, item);
    _animatedListSeparated!.insertItem(index);
  }

  E removeAt(int index) {
    final E removedItem = _items.removeAt(index);
    if (removedItem != null) {
      final bool isLastItem = index == length;
      // If the removed item is the last item in the list, the separator of the preceding item is removed.
      final E itemOfRemovedSeparator = isLastItem && length > 0 ? _items[index - 1] : removedItem;
      _animatedListSeparated!.removeSeparatedItem(
        index,
        (BuildContext context, Animation<double> animation) {
          return removedItemBuilder(removedItem, context, animation);
        },
        (BuildContext context, Animation<double> animation) {
          return removedSeparatorBuilder(itemOfRemovedSeparator, context, animation);
        },
      );
    }
    return removedItem;
  }

  int get length => _items.length;

  E operator [](int index) => _items[index];

  int indexOf(E item) => _items.indexOf(item);
}

/// Displays its integer item as 'item N' on a Card whose color is based on
/// the item's value.
///
/// The text is displayed in bright green if [selected] is
/// true. This widget's height is based on the [animation] parameter, it
/// varies from 0 to 80 as the animation varies from 0.0 to 1.0.
class CardItem extends StatelessWidget {
  const CardItem({
    super.key,
    this.onTap,
    this.selected = false,
    required this.animation,
    required this.item,
  }) : assert(item >= 0);

  final Animation<double> animation;
  final VoidCallback? onTap;
  final int item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.headlineMedium!;
    if (selected) {
      textStyle = textStyle.copyWith(color: Colors.lightGreenAccent[400]);
    }
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: SizeTransition(
        sizeFactor: animation,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: 80.0,
            child: Card(
              color: Colors.primaries[item % Colors.primaries.length],
              child: Center(
                child: Text('Item $item', style: textStyle),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Displays its integer item as 'separator N' on a Card whose color is based on
/// the corresponding item's value.
///
/// This widget's height is based on the [animation] parameter, it
/// varies from 0 to 40 as the animation varies from 0.0 to 1.0.
class ItemSeparator extends StatelessWidget {
  const ItemSeparator({
    super.key,
    required this.animation,
    required this.item,
  }) : assert(item >= 0);

  final Animation<double> animation;
  final int item;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = Theme.of(context).textTheme.headlineSmall!;
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: SizeTransition(
        sizeFactor: animation,
        child: SizedBox(
          height: 40.0,
          child: Card(
            color: Colors.primaries[item % Colors.primaries.length],
            child: Center(
              child: Text('Separator $item', style: textStyle),
            ),
          ),
        ),
      ),
    );
  }
}
