import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:async';

import "package:collection/collection.dart";
import 'package:flutter/services.dart';
import 'package:headunit/pigeon.dart';
import 'package:headunit_example/rhmi.dart';
import 'package:headunit_example/rhmi_widgets.dart';

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
  final rhmiApps = <String, RHMIApp>{};
  final entryButtonsByCategory = <String, List<RHMIEntryButtonClickable>>{};

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
    final categories = entryButtonsByCategory.keys.sortedBy((element) => element);

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
            ...categories.map((e) => RHMISectionWidget(name: e, buttons: entryButtonsByCategory[e]!))
          ],
        )
      ),
    );
  }

  void updateEntryButtons() {
    final entryButtonsByCategory = amApps.values.map((e) => RHMIEntryButtonClickable.wrapAMAppInfo(_serverPlugin, e)).groupListsBy((e) => e.category);
    for (final app in rhmiApps.values) {
      for (final entry in app.description.entryButtons.entries) {
        if (!entryButtonsByCategory.containsKey(entry.key)) {
          entryButtonsByCategory[entry.key] = [];
        }
        entryButtonsByCategory[entry.key]?.add(RHMIEntryButtonClickable.wrapRhmiEntryButton(_serverPlugin, app, entry.value, entry.key));
      }
    }
    this.entryButtonsByCategory.clear();
    this.entryButtonsByCategory.addAll(entryButtonsByCategory);
  }
  @override
  void amRegisterApp(AMAppInfo appInfo) {
    setState(() {
      amApps[appInfo.appId] = appInfo;
      updateEntryButtons();
    });
  }

  @override
  void amUnregisterApp(String appId) {
    setState(() {
      amApps.remove(appId);
      updateEntryButtons();
    });
  }

  @override
  void rhmiRegisterApp(RHMIAppInfo appInfo) {
    log("New RHMI app ${appInfo.appId}");
    final description = appInfo.resources['DESCRIPTION'];
    if (description != null) {
      setState(() {
        rhmiApps[appInfo.appId] = RHMIApp.loadResources(appInfo.appId, appInfo.resources);
        updateEntryButtons();
      });
    }
  }

  @override
  void rhmiSetData(String appId, int modelId, Object? value) {
    // TODO: implement rhmiSetData
  }

  @override
  void rhmiSetProperty(String appId, int componentId, int propertyId, Object? value) {
    // TODO: implement rhmiSetProperty
  }

  @override
  void rhmiTriggerEvent(String appId, int eventId, Map<int?, Object?> args) {
    // TODO: implement rhmiTriggerEvent
  }

  @override
  void rhmiUnregisterApp(String appId) {
    log("Removed RHMI app $appId");
    setState(() {
      rhmiApps.remove(appId);
    });
  }
}
