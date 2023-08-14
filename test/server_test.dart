import 'package:flutter_test/flutter_test.dart';
import 'package:headunit/headunit_callbacks.dart';
import 'package:headunit/server.dart';
import 'package:headunit/server_platform_interface.dart';
import 'package:headunit/server_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockServerPlatform
    with MockPlatformInterfaceMixin
    implements ServerPlatform {


  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<void> startServer() {
    // TODO: implement startServer
    throw UnimplementedError();
  }

  @override
  setEventHandler(HeadunitCallbacks callbacks) {

  }
}

void main() {
  final ServerPlatform initialPlatform = ServerPlatform.instance;

  test('$MethodChannelServer is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelServer>());
  });

  test('getPlatformVersion', () async {
    Server headunitPlugin = Server();
    MockServerPlatform fakePlatform = MockServerPlatform();
    ServerPlatform.instance = fakePlatform;

    expect(await headunitPlugin.getPlatformVersion(), '42');
  });
}
