import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'headunit_callbacks.dart';
import 'server_platform_interface.dart';

/// An implementation of [ServerPlatform] that uses method channels.
class MethodChannelServer extends ServerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('server');

  HeadunitCallbacks? _callbacks;

  @override
  setEventHandler(HeadunitCallbacks callbacks) {
    methodChannel.setMethodCallHandler(nativeHandler);
    _callbacks = callbacks;
  }

  Future<dynamic> nativeHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'amRegisterApp':
        AMAppInfo? val = AMAppInfo.from(methodCall.arguments);
        if (val != null) {
          _callbacks?.amRegisterApp(val);
        } else {
          log("Received invalid amRegisterApp ${methodCall.arguments}");
        }
      case 'amUnregisterApp':
        if (methodCall.arguments is Map) {
          var name = methodCall.arguments["name"];
          if (name is String) {
            _callbacks?.amUnregisterApp(name);
          }
        }

      default:
        throw MissingPluginException('notImplemented');
    }
  }

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
