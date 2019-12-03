// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:webdriver/sync_io.dart' as sync;

import '../common/error.dart';

const String kChrome = 'chrome';
const String kFirefox = 'firefox';
const String kEdge = 'edge';
const String kSafari = 'safari';
const String kIosSafari = "ios-safari";

/// Creates a WebDriver instance with the given [settings].
sync.WebDriver createDriver(Map<String, dynamic> settings) {
  return _createDriver(
      settings['selenium-port'],
      settings['browser-name'],
      settings['headless']
  );
}

sync.WebDriver _createDriver(String seleniumPort, String browserName, bool headless) {
  return sync.createDriver(
      uri: Uri.parse('http://localhost:$seleniumPort/wd/hub/'),
      desired: _getDesiredCapabilities(browserName, headless),
      spec: browserName != kIosSafari ? sync.WebDriverSpec.JsonWire : sync.WebDriverSpec.W3c
  );
}

Map<String, dynamic> _getDesiredCapabilities(String browserName, bool headless) {
  switch (browserName) {
    case kChrome:
      return <String, dynamic>{
        'acceptInsecureCerts': true,
        'browserName': 'chrome',
        'goog:loggingPrefs': <String, String>{ sync.LogType.performance: 'ALL'},
        'chromeOptions': {
          'args': [
            '--bwsi',
            '--disable-background-timer-throttling',
            '--disable-default-apps',
            '--disable-extensions',
            '--disable-popup-blocking',
            '--disable-translate',
            '--no-default-browser-check',
            '--no-sandbox',
            '--no-first-run',
            if (headless) '--headless'
          ],
          'perfLoggingPrefs': {
            'traceCategories':
              'devtools.timeline,'
              'v8,blink.console,benchmark,blink,'
              'blink.user_timing'
          }
        },
      };
      break;
    case kFirefox:
      return <String, dynamic>{
        'acceptInsecureCerts': true,
        'browserName': 'firefox',
        'moz:firefoxOptions' : {
          'args': [
            if (headless) '-headless'
          ],
          'prefs': {
            'dom.file.createInChild': true,
            'dom.timeout.background_throttling_max_budget': -1,
            'media.autoplay.default': 0,
            'media.gmp-manager.url': '',
            'media.gmp-provider.enabled': false,
            'network.captive-portal-service.enabled': false,
            'security.insecure_field_warning.contextual.enabled': false,
            'test.currentTimeOffsetSeconds': 11491200
          },
          'log': {'level': 'trace'}
        }
      };
      break;
    case kEdge:
      return <String, dynamic>{
        'acceptInsecureCerts': true,
        'browserName': 'edge',
      };
      break;
    case kSafari:
      return <String, dynamic>{
        'browserName': 'safari',
        'safari.options': {
          'skipExtensionInstallation': true,
          'cleanSession': true
        }
      };
      break;
    case kIosSafari:
      return <String, dynamic>{
        'platformName': 'ios',
        'browserName': 'safari',
        'safari:useSimulator': true
      };
    default:
      throw DriverError('Browser $browserName not supported.');
  }
}