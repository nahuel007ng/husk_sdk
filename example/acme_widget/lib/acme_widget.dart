/// Example plugin that wraps the fake, closed-source AcmeWidgetSDK.
///
/// Builds work with or without the vendor binaries; see husk.yaml.
library;

import 'package:flutter/services.dart';

import 'src/acme_widget_sdk_husk.g.dart';

export 'src/acme_widget_sdk_husk.g.dart';

/// Calls into AcmeWidgetSDK when it is linked.
abstract final class AcmeWidget {
  static const MethodChannel _channel = MethodChannel('acme_widget');

  /// Whether this build links AcmeWidgetSDK.
  static Future<bool> isSdkAvailable() => AcmeWidgetSdkHusk.isAvailable();

  /// A greeting from the vendor SDK, or null when it is not linked.
  static Future<String?> greeting(String name) async {
    if (!await AcmeWidgetSdkHusk.isAvailable()) return null;
    return _channel.invokeMethod<String>('greeting', {'name': name});
  }
}
