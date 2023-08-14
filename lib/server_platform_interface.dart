import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'headunit_callbacks.dart';
import 'server_method_channel.dart';

abstract class ServerPlatform extends PlatformInterface {
  /// Constructs a ServerPlatform.
  ServerPlatform() : super(token: _token);

  static final Object _token = Object();

  static ServerPlatform _instance = MethodChannelServer();

  /// The default instance of [ServerPlatform] to use.
  ///
  /// Defaults to [MethodChannelServer].
  static ServerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ServerPlatform] when
  /// they register themselves.
  static set instance(ServerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  setEventHandler(HeadunitCallbacks callbacks);

  Future<String?> getPlatformVersion();

  Future<void> startServer();
}
