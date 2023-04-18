// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/utils.dart';
import '../../globals.dart' as globals;

/// The caching strategy for the generated service worker.
enum ServiceWorkerStrategy implements CliEnum {
  /// Download the app shell eagerly and all other assets lazily.
  /// Prefer the offline cached version.
  offlineFirst,

  /// Do not generate a service worker,
  none;

  @override
  String get cliName => snakeCase(name, '-');

  static ServiceWorkerStrategy fromCliName(final String? value) => value == null
      ? ServiceWorkerStrategy.offlineFirst
      : values.singleWhere(
          (final ServiceWorkerStrategy element) => element.cliName == value,
          orElse: () =>
              throw ArgumentError.value(value, 'value', 'Not supported.'),
        );

  @override
  String get helpText => switch (this) {
        ServiceWorkerStrategy.offlineFirst =>
          'Attempt to cache the application shell eagerly and then lazily '
              'cache all subsequent assets as they are loaded. When making a '
              'network request for an asset, the offline cache will be '
              'preferred.',
        ServiceWorkerStrategy.none =>
          'Generate a service worker with no body. This is useful for local '
              'testing or in cases where the service worker caching '
              'functionality is not desirable'
      };
}

/// Generate a service worker with an app-specific cache name a map of
/// resource files.
///
/// The tool embeds file hashes directly into the worker so that the byte for byte
/// invalidation will automatically reactivate workers whenever a new
/// version is deployed.
String generateServiceWorker(
  final String fileGeneratorsPath,
  final Map<String, String> resources,
  final List<String> coreBundle, {
  required final ServiceWorkerStrategy serviceWorkerStrategy,
}) {
  if (serviceWorkerStrategy == ServiceWorkerStrategy.none) {
    return '';
  }

  final String flutterServiceWorkerJsPath = globals.localFileSystem.path.join(
    fileGeneratorsPath,
    'js',
    'flutter_service_worker.js',
  );
  return globals.localFileSystem
      .file(flutterServiceWorkerJsPath)
      .readAsStringSync()
      .replaceAll(
        r'$$RESOURCES_MAP',
        '{${resources.entries.map((final MapEntry<String, String> entry) => '"${entry.key}": "${entry.value}"').join(",\n")}}',
      )
      .replaceAll(
        r'$$CORE_LIST',
        '[${coreBundle.map((final String file) => '"$file"').join(',\n')}]',
      );
}
