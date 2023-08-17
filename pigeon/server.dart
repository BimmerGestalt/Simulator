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
  final String appId;
  final String name;
  final Uint8List iconData;
  final String category;

  AMAppInfo(this.handle, this.appId, this.name, this.iconData, this.category);
}

class RHMIAppInfo {
  final int handle;
  final String appId;
  final Map<String?, Uint8List?> resources;

  RHMIAppInfo(this.handle, this.appId, this.resources);
}

@HostApi()
abstract class ServerApi {
  String getPlatformVersion();
  void startServer();

  void amTrigger(String appId);
}
@FlutterApi()
abstract class HeadunitApi {
  void amRegisterApp(AMAppInfo appInfo);
  void amUnregisterApp(String appId);
  void rhmiRegisterApp(RHMIAppInfo appInfo);
  void rhmiUnregisterApp(String appId);
  void rhmiSetData(String appId, int modelId, Object? value);
  void rhmiSetProperty(String appId, int componentId, int propertyId, Object? value);
  void rhmiTriggerEvent(String appId, int eventId, Map<int, Object?> args);
}