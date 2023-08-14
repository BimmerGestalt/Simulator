import 'dart:typed_data';

import 'package:flutter/material.dart';

class AMAppInfo {
  int handle;
  String name;
  Image icon;
  String category;
  AMAppInfo(this.handle, this.name, this.icon, this.category);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AMAppInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          category == other.category;

  @override
  int get hashCode => name.hashCode ^ category.hashCode;

  static AMAppInfo? from(dynamic arguments) {
    if (arguments is Map) {
      var handle = arguments["handle"];
      var name = arguments["name"];
      var iconData = arguments["icon"];
      var category = arguments["category"];
      if (handle is int &&
          name is String &&
          iconData is Uint8List &&
          category is String) {
        var icon = Image.memory(iconData);
        return AMAppInfo(handle, name, icon, category);
      }
    }
    return null;
  }
}

abstract class HeadunitCallbacks {
  void amRegisterApp(AMAppInfo appInfo);
  void amUnregisterApp(String name);
}