import 'package:pigeon/pigeon.dart';

// run with flutter pub run pigeon --input pigeon/server.dart
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/pigeon.dart',
  kotlinOut: 'android/src/main/kotlin/io/bimmergestalt/headunit/Pigeon.kt',
  kotlinOptions: KotlinOptions(
    package: 'io.bimmergestalt.headunit'
  )
))

class AMAppInfo {
  final int handle;
  final String name;
  final Uint8List iconData;
  final String category;

  AMAppInfo(this.handle, this.name, this.iconData, this.category);
}

@HostApi()
abstract class ServerApi {
  String getPlatformVersion();
  void startServer();
}
@FlutterApi()
abstract class HeadunitApi {
  void amRegisterApp(AMAppInfo appInfo);
  void amUnregisterApp(String name);
}