
import 'server_platform_interface.dart';

class Server {
  Future<String?> getPlatformVersion() {
    return ServerPlatform.instance.getPlatformVersion();
  }
  Future<void> startServer() {
    return ServerPlatform.instance.startServer();
  }
}
