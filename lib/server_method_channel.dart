import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'server_platform_interface.dart';

/// An implementation of [ServerPlatform] that uses method channels.
class MethodChannelServer extends ServerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('server');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> startServer() async {
    await methodChannel.invokeMethod('startServer');
  }
}
