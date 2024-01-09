
import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:headunit/pigeon.dart';
import 'package:headunit_example/rhmi.dart';

class AppList extends ChangeNotifier {

  final amApps = <String, AMAppInfo>{};
  final rhmiApps = <String, RHMIApp>{};

  void amRegisterApp(AMAppInfo appInfo) {
    amApps[appInfo.appId] = appInfo;
    notifyListeners();
  }

  void amUnregisterApp(String appId) {
    amApps.remove(appId);
    notifyListeners();
  }

  void rhmiRegisterApp(RHMIAppInfo appInfo) {
    log("New RHMI app ${appInfo.appId}");
    final description = appInfo.resources['DESCRIPTION'];
    if (description != null) {
      rhmiApps[appInfo.appId] = RHMIApp.loadResources(appInfo.appId, appInfo.resources);
    }
  }

  void rhmiUnregisterApp(String appId) {
    log("Removed RHMI app $appId");
    rhmiApps.remove(appId);
  }
}