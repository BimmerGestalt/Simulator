
import 'package:headunit/headunit_callbacks.dart';

import 'server_platform_interface.dart';

class Server {
  void setCallback(HeadunitCallbacks callbacks) {
    ServerPlatform.instance.setEventHandler(callbacks);
  }
  Future<String?> getPlatformVersion() {
    return ServerPlatform.instance.getPlatformVersion();
  }
  Future<void> startServer() {
    return ServerPlatform.instance.startServer();
  }
}
