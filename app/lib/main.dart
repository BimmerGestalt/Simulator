import 'package:flutter/material.dart';

import "package:collection/collection.dart";
import 'package:flutter/services.dart';

import 'package:headunit/pigeon.dart';
import 'package:headunit_example/rhmi_widgets.dart';
import 'package:headunit_example/state.dart';
import 'package:provider/provider.dart';


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
  final ServerApi _serverPlugin = ServerApi();
  AppList? _appList;

  @override
  void initState() {
    super.initState();
    HeadunitApi.setup(this, binaryMessenger: ServicesBinding.instance.defaultBinaryMessenger);
  }

  @override
  Widget build(BuildContext context) {
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
          child: ChangeNotifierProvider(
            create: (context) {
              _appList = AppList();
              _serverPlugin.startServer();
              return _appList;
            },
            child: MainScreen(serverApi: _serverPlugin),
          )
        )
      ),
    );
  }

  @override
  void amRegisterApp(AMAppInfo appInfo) {
    _appList?.amRegisterApp(appInfo);
  }

  @override
  void amUnregisterApp(String appId) {
    _appList?.amUnregisterApp(appId);
  }

  @override
  void rhmiRegisterApp(RHMIAppInfo appInfo) {
    _appList?.rhmiRegisterApp(appInfo);
  }

  @override
  void rhmiSetData(String appId, int modelId, Object? value) {
    _appList?.rhmiApps[appId]?.description.setData(modelId, value);
  }

  @override
  void rhmiSetProperty(String appId, int componentId, int propertyId, Object? value) {
    final component = _appList?.rhmiApps[appId]?.description.components[componentId];
    if (component == null) return;
    component.properties[propertyId].value = value;
  }

  @override
  void rhmiTriggerEvent(String appId, int eventId, Map<int?, Object?> args) {
    // TODO: implement rhmiTriggerEvent
    final app = _appList?.rhmiApps[appId];
    final event = app?.description.events[eventId];
    if (app != null && event?.type == "focusEvent") {
      final target = args[0];
      final targetState = _appList?.rhmiApps[appId]?.description.states[target];
      if (targetState != null) {
        RHMICallbacks(navKey.currentState!, _serverPlugin, app).openState(targetState.id);
      }
      // TODO: components don't exist yet and won't have focus for a while
    }
  }

  @override
  void rhmiUnregisterApp(String appId) {
    _appList?.rhmiUnregisterApp(appId);
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, required this.serverApi});
  final ServerApi serverApi;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppList>(
        builder: (context, appList, child) {
          final entryButtonsByCategory = updateEntryButtons(appList);
          final categories = entryButtonsByCategory.keys.sortedBy((element) => element);
          return ListView(
            children: [
              ...categories.map((e) => RHMISectionWidget(name: e, buttons: entryButtonsByCategory[e]!))
            ],
          );
        }
    );
  }

  Map<String, List<StatelessWidget>> updateEntryButtons(AppList appList) {
    final Map<String, List<StatelessWidget>> entryButtonsByCategory = {};
    for (final amApp in appList.amApps.values) {
      if (!entryButtonsByCategory.containsKey(amApp.category)) {
        entryButtonsByCategory[amApp.category] = [];
      }
      entryButtonsByCategory[amApp.category]?.add(RHMIEntryButtonWidget.wrapAMAppInfo(serverApi, amApp));
    }
    for (final app in appList.rhmiApps.values) {
      for (final entry in app.description.entryButtons.entries) {
        if (!entryButtonsByCategory.containsKey(entry.key)) {
          entryButtonsByCategory[entry.key] = [];
        }
        entryButtonsByCategory[entry.key]?.add(RHMIEntryButtonWidget.wrapRhmiEntryButton(app, entry.value, RHMICallbacks(navKey.currentState!, serverApi, app), entry.key));
      }
    }
    return entryButtonsByCategory;
  }
}