import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:headunit/pigeon.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> implements HeadunitApi {
  String _platformVersion = 'Unknown';
  final _headunitPlugin = ServerApi();

  final amApps = List<AMAppInfo>.empty(growable: true);

  @override
  void initState() {
    super.initState();
    initPlatformState();
    HeadunitApi.setup(this, binaryMessenger: ServicesBinding.instance.defaultBinaryMessenger);
    _headunitPlugin.startServer();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _headunitPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: ListView(
          children: [
            Center(
              child: Text('Running on: $_platformVersion\n'),
            ),
            ...amApps.map((e) => AMAppInfoWidget(appInfo: e))
          ],
        )
      ),
    );
  }

  @override
  void amRegisterApp(AMAppInfo appInfo) {
    // TODO: implement amRegisterApp
    setState(() {
      amApps.add(appInfo);
    });
  }

  @override
  void amUnregisterApp(String name) {
    setState(() {
      amApps.removeWhere((element) => element.name == name);
    });
  }
}

class AMAppInfoWidget extends StatelessWidget {
  const AMAppInfoWidget({
    super.key,
    required this.appInfo
  });
  final AMAppInfo appInfo;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        onPressed: null,
        icon: Image.memory(appInfo.iconData),
        label: Text(appInfo.name),
    );
  }

}