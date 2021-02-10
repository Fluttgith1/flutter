// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:process/process.dart' as process;

import 'process.dart';

/// Generates an [AppContext] value.
///
/// Generators are allowed to return `null`, in which case the context will
/// store the `null` value as the value for that type.
typedef Generator = dynamic Function();

/// An exception thrown by [AppContext] when you try to get a [Type] value from
/// the context, and the instantiation of the value results in a dependency
/// cycle.
class ContextDependencyCycleException implements Exception {
  ContextDependencyCycleException._(this.cycle);

  /// The dependency cycle (last item depends on first item).
  final List<Type> cycle;

  @override
  String toString() => 'Dependency cycle detected: ${cycle.join(' -> ')}';
}

/// The Zone key used to look up the [AppContext].
@visibleForTesting
const Object contextKey = _Key.key;

/// The current [AppContext], as determined by the [Zone] hierarchy.
///
/// This will be the first context found as we scan up the zone hierarchy, or
/// the "root" context if a context cannot be found in the hierarchy. The root
/// context will not have any values associated with it.
///
/// This is guaranteed to never return `null`.
AppContext get context => Zone.current[contextKey] as AppContext ?? AppContext._root;

/// A lookup table (mapping types to values) and an implied scope, in which
/// code is run.
///
/// [AppContext] is used to define a singleton injection context for code that
/// is run within it. Each time you call [run], a child context (and a new
/// scope) is created.
///
/// Child contexts are created and run using zones. To read more about how
/// zones work, see https://api.dart.dev/stable/dart-async/Zone-class.html.
class AppContext {
  AppContext._(
    this._parent,
    this.name, [
    this._overrides = const <Type, Generator>{},
    this._fallbacks = const <Type, Generator>{},
  ]);

  final String name;
  final AppContext _parent;
  final Map<Type, Generator> _overrides;
  final Map<Type, Generator> _fallbacks;
  final Map<Type, dynamic> _values = <Type, dynamic>{};

  List<Type> _reentrantChecks;

  /// Bootstrap context.
  static final AppContext _root = AppContext._(null, 'ROOT');

  dynamic _boxNull(dynamic value) => value ?? _BoxedNull.instance;

  dynamic _unboxNull(dynamic value) => value == _BoxedNull.instance ? null : value;

  /// Returns the generated value for [type] if such a generator exists.
  ///
  /// If [generators] does not contain a mapping for the specified [type], this
  /// returns `null`.
  ///
  /// If a generator existed and generated a `null` value, this will return a
  /// boxed value indicating null.
  ///
  /// If a value for [type] has already been generated by this context, the
  /// existing value will be returned, and the generator will not be invoked.
  ///
  /// If the generator ends up triggering a reentrant call, it signals a
  /// dependency cycle, and a [ContextDependencyCycleException] will be thrown.
  dynamic _generateIfNecessary(Type type, Map<Type, Generator> generators) {
    if (!generators.containsKey(type)) {
      return null;
    }

    return _values.putIfAbsent(type, () {
      _reentrantChecks ??= <Type>[];

      final int index = _reentrantChecks.indexOf(type);
      if (index >= 0) {
        // We're already in the process of trying to generate this type.
        throw ContextDependencyCycleException._(
            UnmodifiableListView<Type>(_reentrantChecks.sublist(index)));
      }

      _reentrantChecks.add(type);
      try {
        return _boxNull(generators[type]());
      } finally {
        _reentrantChecks.removeLast();
        if (_reentrantChecks.isEmpty) {
          _reentrantChecks = null;
        }
      }
    });
  }

  /// Gets the value associated with the specified [type], or `null` if no
  /// such value has been associated.
  T get<T>() {
    // Convert lookups of old process manager into new process manager.
    // TODO(jonahwilliams): remove once g3 is migrated to flutter process manager.
    // https://github.com/flutter/flutter/issues/75744
    dynamic value;
    if (T == process.ProcessManager) {
      value = ProcessManagerWrapper(_generateIfNecessary(process.ProcessManager, _overrides) as process.ProcessManager);
    } else {
      value = _generateIfNecessary(T, _overrides);
    }
    if (value == null && _parent != null) {
      value = _parent.get<T>();
    }
    return _unboxNull(value ?? _generateIfNecessary(T, _fallbacks)) as T;
  }

  /// Runs [body] in a child context and returns the value returned by [body].
  ///
  /// If [overrides] is specified, the child context will return corresponding
  /// values when consulted via [operator[]].
  ///
  /// If [fallbacks] is specified, the child context will return corresponding
  /// values when consulted via [operator[]] only if its parent context didn't
  /// return such a value.
  ///
  /// If [name] is specified, the child context will be assigned the given
  /// name. This is useful for debugging purposes and is analogous to naming a
  /// thread in Java.
  Future<V> run<V>({
    @required FutureOr<V> body(),
    String name,
    Map<Type, Generator> overrides,
    Map<Type, Generator> fallbacks,
    ZoneSpecification zoneSpecification,
  }) async {
    final AppContext child = AppContext._(
      this,
      name,
      Map<Type, Generator>.unmodifiable(overrides ?? const <Type, Generator>{}),
      Map<Type, Generator>.unmodifiable(fallbacks ?? const <Type, Generator>{}),
    );
    return await runZoned<Future<V>>(
      () async => await body(),
      zoneValues: <_Key, AppContext>{_Key.key: child},
      zoneSpecification: zoneSpecification,
    );
  }

  @override
  String toString() {
    final StringBuffer buf = StringBuffer();
    String indent = '';
    AppContext ctx = this;
    while (ctx != null) {
      buf.write('AppContext');
      if (ctx.name != null) {
        buf.write('[${ctx.name}]');
      }
      if (ctx._overrides.isNotEmpty) {
        buf.write('\n$indent  overrides: [${ctx._overrides.keys.join(', ')}]');
      }
      if (ctx._fallbacks.isNotEmpty) {
        buf.write('\n$indent  fallbacks: [${ctx._fallbacks.keys.join(', ')}]');
      }
      if (ctx._parent != null) {
        buf.write('\n$indent  parent: ');
      }
      ctx = ctx._parent;
      indent += '  ';
    }
    return buf.toString();
  }
}

/// Private key used to store the [AppContext] in the [Zone].
class _Key {
  const _Key();

  static const _Key key = _Key();

  @override
  String toString() => 'context';
}

/// Private object that denotes a generated `null` value.
class _BoxedNull {
  const _BoxedNull();

  static const _BoxedNull instance = _BoxedNull();
}
