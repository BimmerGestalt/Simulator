import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:async';

import "package:collection/collection.dart";
import 'package:flutter/services.dart';
import 'package:headunit/pigeon.dart';
import 'package:headunit_example/rhmi.dart';
import 'package:headunit_example/rhmi_widgets.dart';


final GlobalKey<NavigatorState> navKey = GlobalKey();

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
  final entryButtonsByCategory = <String, List<StatelessWidget>>{};

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
      navigatorKey: navKey,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: DefaultTextStyle(
          style: const TextStyle(fontSize: 20),
          child: ListView(
            children: [
              Center(
                child: Text('Running on: $_platformVersion\n'),
              ),
              ...categories.map((e) => RHMISectionWidget(name: e, buttons: entryButtonsByCategory[e]!))
            ],
          )
        )
      ),
    );
  }

  void updateEntryButtons() {
    final Map<String, List<StatelessWidget>> entryButtonsByCategory = {};
    for (final amApp in amApps.values) {
      if (!entryButtonsByCategory.containsKey(amApp.category)) {
        entryButtonsByCategory[amApp.category] = [];
      }
      entryButtonsByCategory[amApp.category]?.add(RHMIEntryButtonWidget.wrapAMAppInfo(_serverPlugin, amApp));
    }
    for (final app in rhmiApps.values) {
      for (final entry in app.description.entryButtons.entries) {
        if (!entryButtonsByCategory.containsKey(entry.key)) {
          entryButtonsByCategory[entry.key] = [];
        }
        entryButtonsByCategory[entry.key]?.add(RHMIEntryButtonWidget.wrapRhmiEntryButton(app, entry.value, RHMICallbacks(navKey.currentState!, _serverPlugin, app), entry.key));
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
    rhmiApps[appId]?.description.setData(modelId, value);
  }

  @override
  void rhmiSetProperty(String appId, int componentId, int propertyId, Object? value) {
    // TODO: implement rhmiSetProperty
  }

  @override
  void rhmiTriggerEvent(String appId, int eventId, Map<int?, Object?> args) {
    // TODO: implement rhmiTriggerEvent
    final app = rhmiApps[appId];
    final event = app?.description.events[eventId];
    if (app != null && event?.type == "focusEvent") {
      final target = args[0];
      final targetState = rhmiApps[appId]?.description.states[target];
      if (targetState != null) {
        RHMICallbacks(navKey.currentState!, _serverPlugin, app).openState(targetState.id);
      }
      // TODO: components don't exist yet and won't have focus for a while
    }
  }

  @override
  void rhmiUnregisterApp(String appId) {
    log("Removed RHMI app $appId");
    setState(() {
      rhmiApps.remove(appId);
    });
  }
}
