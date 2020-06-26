// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'editable_text.dart';
import 'restoration.dart';

/// A [RestorableProperty] that makes the wrapped value accessible to the
/// owning [State] object via the [value] getter and setter.
///
/// Whenever a new [value] is set, [didUpdateValue] is called. Subclasses
/// should call [notifyListeners] from this method if the new value changes
/// what [toPrimitives] returns.
///
/// See also:
///
///  * [RestorableProperty], which is the super class of this class.
///  * [RestorationMixin], to which a [RestorableValue] needs to be registered
///    in order to work.
///  * [RestorationManager], which provides an overview of how state restoration
///    works in Flutter.
abstract class RestorableValue<T> extends RestorableProperty<T> {
  /// The current value stored in this property.
  ///
  /// A representation of the current value is stored in the restoration data.
  /// During state restoration, the property will restore the value to what it
  /// was when the restoration data it is getting restored from was collected.
  ///
  /// The [value] can only be accessed after the property has been registered
  /// with a [RestorationMixin] by calling
  /// [RestorationMixin.registerForRestoration].
  T get value {
    assert(isRegistered);
    return _value;
  }
  T _value;
  set value(T newValue) {
    assert(isRegistered);
    if (newValue != _value) {
      final T oldValue = _value;
      _value = newValue;
      didUpdateValue(oldValue);
    }
  }

  @mustCallSuper
  @override
  void initWithValue(T value) {
    _value = value;
  }

  /// Called whenever a new value is assigned to [value].
  ///
  /// The new value can be accessed via the regular [value] getter and the
  /// previous value is provided as `oldValue`.
  ///
  /// Subclasses should call [notifyListeners] from this method, if the new
  /// value changes what [toPrimitives] returns.
  @protected
  void didUpdateValue(T oldValue);
}

class _RestorablePrimitiveValue<T> extends RestorableValue<T> {
  _RestorablePrimitiveValue(this._defaultValue)
    : assert(debugIsSerializableForRestoration(_defaultValue)),
      super();

  final T _defaultValue;

  @override
  T createDefaultValue() => _defaultValue;

  @override
  void didUpdateValue(T oldValue) {
    assert(debugIsSerializableForRestoration(value));
    notifyListeners();
  }

  @override
  T fromPrimitives(Object serialized) {
    return serialized as T;
  }

  @override
  Object toPrimitives() {
    return value;
  }
}

/// A [RestorableProperty] that knows how to store and restore a [num].
///
/// {@template flutter.widgets.restoration.primitivevalue}
/// The current [value] of this property is stored in the restoration data.
/// During state restoration the property is restored to the value it had when
/// the restoration data it is getting restored from was collected.
///
/// If no restoration data is available, [value] is initialized to the
/// `defaultValue` given in the constructor.
/// {@endtempalte}
///
/// See also:
///
///  * [RestorableDouble], which can store and restore a [double].
///  * [RestorableInt], which can store and restore an [int].
class RestorableNum<T extends num> extends _RestorablePrimitiveValue<T> {
  /// Creates a [RestorableNum].
  ///
  /// {@tempalte flutter.widgets.restoration.primitivevalue.constructor}
  /// If no restoration data is available to restore the value in this property
  /// from, the property will be initialized with the provided `defaultValue`.
  /// {@endtemplate}
  RestorableNum(T defaultValue) : super(defaultValue);
}

/// A [RestorableProperty] that knows how to store and restore a [double].
///
/// {@macro flutter.widgets.restoration.primitivevalue}
class RestorableDouble extends RestorableNum<double> {
  /// Creates a [RestorableDouble].
  ///
  /// {@macro flutter.widgets.restoration.primitivevalue.constructor}
  RestorableDouble(double defaultValue) : super(defaultValue);
}

/// A [RestorableProperty] that knows how to store and restore an [int].
///
/// {@macro flutter.widgets.restoration.primitivevalue}
class RestorableInt extends RestorableNum<int> {
  /// Creates a [RestorableInt].
  ///
  /// {@macro flutter.widgets.restoration.primitivevalue.constructor}
  RestorableInt(int defaultValue) : super(defaultValue);
}

/// A [RestorableProperty] that knows how to store and restore an [String].
///
/// {@macro flutter.widgets.restoration.primitivevalue}
class RestorableString extends _RestorablePrimitiveValue<String> {
  /// Creates a [RestorableString].
  ///
  /// {@macro flutter.widgets.restoration.primitivevalue.constructor}
  RestorableString(String defaultValue) : super(defaultValue);
}

/// A [RestorableProperty] that knows how to store and restore an [bool].
///
/// {@macro flutter.widgets.restoration.primitivevalue}
class RestorableBool extends _RestorablePrimitiveValue<bool> {
  /// Creates a [RestorableBool].
  ///
  /// {@macro flutter.widgets.restoration.primitivevalue.constructor}
  RestorableBool(bool defaultValue) : super(defaultValue);
}

/// A base class for creating a [RestorableProperty] that stores and restores
/// a [Listenable].
///
/// This class may be used to implement a [RestorableProperty] for a
/// [Listenable], whose information it needs to store in the restoration data
/// change whenever the [Listenable] notifies its listeners.
///
/// The [RestorationMixin] this property is registered with will call
/// [toPrimitives] whenever the wrapped [Listenable] notifies its listeners
/// to update the information that this property has stored in the restoration
/// data.
abstract class RestorableListenable<T extends Listenable> extends RestorableProperty<T> {
  /// The [Listenable] stored in this property.
  ///
  /// A representation of the current value of the [Listenable] is stored in the
  /// restoration data. During state restoration, the [Listenable] returned by
  /// this getter will be restored to the state it had when the restoration data
  /// the property is getting restored from was collected.
  ///
  /// The [value] can only be accessed after the property has been registered
  /// with a [RestorationMixin] by calling
  /// [RestorationMixin.registerForRestoration].
  T get value {
    assert(isRegistered);
    return _value;
  }
  T _value;

  @override
  void initWithValue(T value) {
    assert(value != null);
    _value?.removeListener(notifyListeners);
    _value = value;
    _value.addListener(notifyListeners);
  }

  @override
  void dispose() {
    super.dispose();
    _value?.removeListener(notifyListeners);
  }
}

/// A [RestorableProperty] that knows how to store and restore a
/// [TextEditingController].
///
/// The [TextEditingController] is accessible via the [value] getter. During
/// state restoration, the property will restore [TextEditingController.text]
/// to the value it had when the restoration data it is getting restored from
/// was collected.
class RestorableTextEditingController extends RestorableListenable<TextEditingController> {
  /// Creates a [RestorableTextEditingController].
  ///
  /// This constructor treats a null `text` argument as if it were the empty
  /// string.
  factory RestorableTextEditingController({String text}) => RestorableTextEditingController.fromValue(
    text == null ? TextEditingValue.empty : TextEditingValue(text: text),
  );

  /// Creates a [RestorableTextEditingController] from an initial
  /// [TextEditingValue].
  ///
  /// This constructor treats a null `value` argument as if it were
  /// [TextEditingValue.empty].
  RestorableTextEditingController.fromValue(TextEditingValue value) : _initialValue = value;

  final TextEditingValue _initialValue;

  @override
  TextEditingController createDefaultValue() {
    return TextEditingController.fromValue(_initialValue);
  }

  @override
  TextEditingController fromPrimitives(Object data) {
    return TextEditingController(text: data as String);
  }

  @override
  Object toPrimitives() {
    return value.text;
  }

  @override
  void dispose() {
    super.dispose();
    if (isRegistered) {
      value.dispose();
    }
  }
}
