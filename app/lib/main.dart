import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:headunit/pigeon.dart';
import 'package:image/image.dart' as ImageManips;

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
  final _serverPlugin = ServerApi();

  final amApps = <String, AMAppInfo>{};

  @override
  void initState() {
    super.initState();
    initPlatformState();
    HeadunitApi.setup(this, binaryMessenger: ServicesBinding.instance.defaultBinaryMessenger);
    _serverPlugin.startServer();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _serverPlugin.getPlatformVersion() ?? 'Unknown platform version';
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
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: ListView(
          children: [
            Center(
              child: Text('Running on: $_platformVersion\n'),
            ),
            ...amApps.entries.map((e) => AMAppInfoWidget(
                server: _serverPlugin,
                appInfo: e.value
            ))
          ],
        )
      ),
    );
  }

  @override
  void amRegisterApp(AMAppInfo appInfo) {
    setState(() {
      amApps[appInfo.appId] = appInfo;
    });
  }

  @override
  void amUnregisterApp(String appId) {
    setState(() {
      amApps.remove(appId);
    });
  }
}

class AMAppInfoWidget extends StatelessWidget {
  const AMAppInfoWidget({
    super.key,
    required this.server,
    required this.appInfo,
  });
  final ServerApi server;
  final AMAppInfo appInfo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () {
            server.amTrigger(appInfo.appId);
          },
          icon: TransparentIcon(
            iconData: appInfo.iconData,
            darkMode: MediaQuery.of(context).platformBrightness == Brightness.dark,
            width: 48,
            height: 48,
          ),
          label: Text(appInfo.name),
        )
      ],
    );
  }
}

class TransparentIcon extends StatelessWidget {
  const TransparentIcon({
    super.key,
    required this.iconData,
    required this.darkMode,
    required this.width,
    required this.height,
  });
  final Uint8List iconData;
  final bool darkMode;
  final int width;
  final int height;

  Future<Image> filter(Uint8List iconData) async {
    // https://stackoverflow.com/q/71817119/169035
    final image = ImageManips.decodeImage(iconData);
    if (image != null && image.channels == ImageManips.Channels.rgb) {
      image.channels = ImageManips.Channels.rgba;
      final pixels = image.getBytes(format: ImageManips.Format.rgba);
      for (var i = 0; i < pixels.lengthInBytes; i += 4) {
        if (pixels[i+0] < 3 && pixels[i+1] < 3 && pixels[i+2] < 3) {
          pixels[i+3] = 0;  // full transparent
        }
        if (!darkMode) {
          // switch from dark mode to light mode
          pixels[i + 0] = 255 - pixels[i + 0];
          pixels[i + 1] = 255 - pixels[i + 1];
          pixels[i + 2] = 255 - pixels[i + 2];
          // TODO maybe UI tinting support?
        }
      }
      return Image.memory(
        ImageManips.encodePng(image) as Uint8List,
        width: width.toDouble(),
        height: height.toDouble(),
      );
    } else {
      return Image.memory(
        iconData,
        width: width.toDouble(),
        height: height.toDouble(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: filter(iconData),
      builder: (_, AsyncSnapshot<Image> parsedImage) {
        return parsedImage.data != null ? parsedImage.data! : SizedBox(
          height: height.toDouble(),
          width: width.toDouble(),
        );
      }
    );
  }
}