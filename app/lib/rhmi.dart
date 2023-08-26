import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class RHMIApp {
  RHMIApp(this.appId, this.description, this.images, this.texts);

  String appId;
  RHMIAppDescription description;
  Map<int, Uint8List> images;
  Map<String, Map<int, String>> texts;

  static RHMIApp loadResources(String appId, Map<String?, Uint8List?> resources) {
    final descriptionText = resources['DESCRIPTION'];
    final description = descriptionText != null ? RHMIAppDescription.loadXmlBytes(descriptionText) : RHMIAppDescription();
    final images = loadImageDb(resources['IMAGEDB']);
    final Map<String, Map<int, String>> texts = loadTextDb(resources['TEXTDB']);

    return RHMIApp(appId, description, images, texts);
  }

  static Map<int, Uint8List> loadImageDb(Uint8List? imageDb) {
    final Map<int, Uint8List> images = {};
    if (imageDb != null) {
      try {
        final imageArchive = ZipDecoder().decodeBytes(imageDb);
        for (var file in imageArchive.files) {
          final imageId = int.tryParse(file.name.split('.').first);
          if (imageId != null) {
            images[imageId] = file.content;
          }
        }
      } on Exception {
        log("Invalid ImageDb");
      }
    }
    return images;
  }

  static Map<String, Map<int, String>> loadTextDb(Uint8List? textDb) {
    final Map<String, Map<int, String>> texts = {};
    if (textDb != null) {
      try {
        final textArchive = ZipDecoder().decodeBytes(textDb);
        for (var file in textArchive.files) {
          final lang = file.name.split('.').first;
          final Map<int, String> langTexts = {};
          final contents = const Utf8Decoder().convert(file.content);
          final lines = const LineSplitter().convert(contents);
          for (var line in lines) {
            final parts = line.split('=');
            final id = int.tryParse(parts[0]);
            if (parts.length == 2 && id != null) {
              langTexts[id] = parts[1];
            }
          }
          texts[lang] = langTexts;
        }
      } on Exception {
        log("Invalid ImageDb");
      }
    }
    return texts;
  }
}

class RHMIAppDescription {
  Map<String, RHMIComponent> entryButtons = {};
  Map<int, RHMIAction> actions = {};
  Map<int, RHMIEvent> events = {};
  Map<int, RHMIModel> models = {};
  Map<int, RHMIComponent> components = {};
  Map<int, RHMIState> states = {};

  static RHMIAppDescription loadXmlBytes(Uint8List data) {
    return loadXml(const Utf8Decoder().convert(data));
  }
  static RHMIAppDescription loadXml(String data) {
    final app = RHMIAppDescription();
    final description = XmlDocument.parse(data);
    description.getElement('pluginApps')?.findElements('pluginApp').forEach((pluginApp) {
      pluginApp.getElement('models')?.childElements.forEach((node) {
        final parsed = RHMIModel.loadXml(node);
        if (parsed.id > 0) {
          app.models[parsed.id] = parsed;
        }
      });

      pluginApp.getElement('actions')?.childElements.forEach((node) {
        final parsed = RHMIAction.loadXml(node);
        if (parsed.id > 0) {
          app.actions[parsed.id] = parsed;
        }
        if (parsed is RHMIHmiAction) {
          parsed.linkModel(app.models);
        }
        if (parsed is RHMICombinedAction) {
          final hmiAction = parsed.hmiAction;
          if (hmiAction != null) {
            app.actions[hmiAction.id] = hmiAction;
            hmiAction.linkModel(app.models);
          }
          final raAction = parsed.raAction;
          if (raAction != null) {
            app.actions[raAction.id] = raAction;
          }
        }
      });

      pluginApp.getElement('events')?.childElements.forEach((node) {
        final parsed = RHMIEvent.loadXml(node);
        if (parsed.id > 0) {
          app.events[parsed.id] = parsed;
        }
      });

      pluginApp.getElement('hmiStates')?.childElements.forEach((node) {
        final parsed = RHMIState.loadXml(app, node);
        if (parsed.id > 0) {
          app.states[parsed.id] = parsed;
        }
      });

      final appType = pluginApp.attributes.firstWhere((p0) => p0.name.local == 'applicationType',
          orElse: (() => XmlAttribute(XmlName.fromString(""), ""))).value;
      final entryButton = pluginApp.getElement('entryButton');
      if (appType.isNotEmpty && entryButton != null) {
        app.entryButtons[appType] = RHMIComponent.loadXml(app, entryButton);
      }
    });
    return app;
  }

  void setData(int model, Object? value) {
    if (!models.containsKey(model)) {
      log("Unknown model $model from ${models.keys}");
    }
    log("Setting data $model to $value");
    models[model]?.value = value;
  }
}

class RHMIAction {
  RHMIAction(this.id, this.type, this.attributes);
  int id;
  String type;

  Map<String, String?> attributes = {};

  static RHMIAction loadXml(XmlElement node) {
    final idNode = node.attributes.firstWhere((p0) => p0.name.local == 'id',
        orElse: (() => XmlAttribute(XmlName.fromString(""), "-1")));
    final id = int.parse(idNode.value);
    final type = node.localName;
    final attributeNodes = node.attributes.where((p0) => p0.name.local != 'id');
    final attributes = {for (var attr in attributeNodes) attr.name.local: attr.value};

    final action = switch (type) {
      "combinedAction" => RHMICombinedAction(id, type, attributes),
      "hmiAction" => RHMIHmiAction(id, type, attributes),
      _ => RHMIAction(id, type, attributes),
    };
    if (action is RHMICombinedAction) {
      action.loadChildren(node);
    }
    return action;
  }

  static Map<String, RHMIAction> loadReferencedActions(RHMIAppDescription app, Map<String, String> attributes) {
    final Map<String, RHMIAction> actions = {};
    attributes.forEach((attrName, attrValue) {
      final derefAction = app.actions[int.tryParse(attrValue, radix: 10)];
      if (attrName.toLowerCase().endsWith("action") && derefAction != null) {
        actions[attrName] = derefAction;
      }
    });
    return actions;
  }
}

class RHMICombinedAction extends RHMIAction {
  RHMICombinedAction(super.id, super.type, super.attributes);

  RHMIAction? raAction;
  RHMIHmiAction? hmiAction;

  void loadChildren(XmlNode combinedActionNode) {
    combinedActionNode.getElement("actions")?.childElements.forEach((element) {
      final action = RHMIAction.loadXml(element);
      if (action.type == "raAction") {
        raAction = action;
      }
      if (action is RHMIHmiAction && action.type == "hmiAction") {
        hmiAction = action;
      }
    });
  }

  void linkModel(Map<int, RHMIModel> models) {
    hmiAction?.linkModel(models);
  }
}

class RHMIHmiAction extends RHMIAction {
  RHMIHmiAction(super.id, super.type, super.attributes):
      target = int.tryParse(attributes['target'] ?? '', radix: 10),
      targetModelId =  int.tryParse(attributes['targetModel'] ?? '', radix: 10);

  int? target;
  int? targetModelId;
  RHMIModel? targetModel;

  void linkModel(Map<int, RHMIModel> models) {
    if (targetModelId != null) {
      targetModel = models[targetModelId];
    }
  }
}

class RHMIEvent {
  RHMIEvent(this.id, this.type, this.attributes);
  int id;
  String type;

  Map<String, String?> attributes = {};

  static RHMIEvent loadXml(XmlElement node) {
    final idNode = node.attributes.firstWhere((p0) => p0.name.local == 'id',
        orElse: (() => XmlAttribute(XmlName.fromString(""), "-1")));
    final id = int.parse(idNode.value);
    final type = node.localName;
    final attributeNodes = node.attributes.where((p0) => p0.name.local != 'id');
    final attributes = {for (var attr in attributeNodes) attr.name.local: attr.value};
    return RHMIEvent(id, type, attributes);
  }
}

class RHMIModel {
  RHMIModel(this.id, this.type);
  int id;
  String type;
  Object? value;
  Map<String, Object?> attributes = {};

  static RHMIModel loadXml(XmlElement node) {
    final idNode = node.attributes.firstWhere((p0) => p0.name.local == 'id',
        orElse: (() => XmlAttribute(XmlName.fromString(""), "-1")));
    final id = int.parse(idNode.value);
    final type = node.localName;
    final attributeNodes = node.attributes.where((p0) => p0.name.local != 'id');
    final attributes = {for (var attr in attributeNodes) attr.name.local: int.tryParse(attr.value, radix: 10) ?? attr.value};

    final model = RHMIModel(id, type);
    model.attributes.addAll(attributes);
    return model;
  }

  static Map<String, RHMIModel> loadReferencedModels(RHMIAppDescription app, Map<String, String> attributes) {
    final Map<String, RHMIModel> models = {};
    attributes.forEach((attrName, attrValue) {
      final derefModel = app.models[int.tryParse(attrValue, radix: 10)];
      if (attrName.toLowerCase().endsWith("model") && derefModel != null) {
        models[attrName] = derefModel;
      }
    });
    return models;
  }
}

class RHMIProperty {
  static const enabled = 1;
  static const selectable = 2;
  static const visible = 3;

  static Map<int, String> loadProperties(XmlElement? propertiesNode) {
    final Map<int, String> properties = {};
    propertiesNode?.childElements.forEach((element) {
      final idNode = element.attributes.firstWhere((p0) => p0.name.local == 'id',
          orElse: (() => XmlAttribute(XmlName.fromString(""), "-1")));
      final id = int.parse(idNode.value);
      final value = element.attributes.firstWhere((p0) => p0.name.local == 'value',
          orElse: (() => XmlAttribute(XmlName.fromString(""), ""))).value;
      properties[id] = value;

      final condition = element.getElement('condition');
      final assignments = condition?.getElement('assignments');
      if (condition != null && assignments != null) {
        // only have seen LayoutBag conditions, where "0" is widescreen and "1" otherwise
        final assignment = assignments.childElements.first;

        final assignmentValue = element.attributes.firstWhere((p0) => p0.name.local == 'value',
            orElse: (() => XmlAttribute(XmlName.fromString(""), ""))).value;
        properties[id] = assignmentValue;
      }
    });
    return properties;
  }
}

class RHMIComponent {
  RHMIComponent(this.id, this.type);

  int id;
  String type;
  Map<String, RHMIAction> actions = {};
  Map<String, RHMIModel> models = {};
  Map<int, String> properties = {};

  static RHMIComponent loadXml(RHMIAppDescription app, XmlElement node) {
    final idNode = node.attributes.firstWhere((p0) => p0.name.local == 'id',
        orElse: (() => XmlAttribute(XmlName.fromString(""), "-1")));
    final id = int.parse(idNode.value);
    final type = node.localName;
    final attributeNodes = node.attributes.where((p0) => p0.name.local != 'id');
    final attributes = {for (var attr in attributeNodes) attr.name.local: attr.value};

    final component = RHMIComponent(id, type);
    // TODO action
    component.actions.addAll(RHMIAction.loadReferencedActions(app, attributes));
    component.models.addAll(RHMIModel.loadReferencedModels(app, attributes));
    component.properties.addAll(RHMIProperty.loadProperties(node.getElement('properties')));
    return component;
  }
}

class RHMIState {
  RHMIState(this.id, this.type);

  int id;
  String type;
  List<RHMIComponent> components = [];
  Map<String, RHMIModel> models = {}; // usually a title model, but also all of audioHmiState models
  Map<int, String> properties = {};

  static RHMIState loadXml(RHMIAppDescription app, XmlElement node) {
    final idNode = node.attributes.firstWhere((p0) => p0.name.local == 'id',
        orElse: (() => XmlAttribute(XmlName.fromString(""), "-1")));
    final id = int.parse(idNode.value);
    final type = node.localName;
    final attributeNodes = node.attributes.where((p0) => p0.name.local != 'id');
    final attributes = {for (var attr in attributeNodes) attr.name.local: attr.value};

    final List<RHMIComponent> components = node.getElement('components')?.childElements.map((element) {
      return RHMIComponent.loadXml(app, element);
    }).toList(growable: false) ?? [];

    final List<RHMIComponent> toolbarComponents = node.getElement('toolbarComponents')?.childElements.map((element) {
      return RHMIComponent.loadXml(app, element);
    }).toList(growable: false) ?? [];

    final state = toolbarComponents.isNotEmpty ?
      RHMIToolbarState(id, type) : RHMIState(id, type);

    state.components.addAll(components);
    state.properties.addAll(RHMIProperty.loadProperties(node.getElement('properties')));
    state.models.addAll(RHMIModel.loadReferencedModels(app, attributes));
    return state;
  }
}

class RHMIToolbarState extends RHMIState {
  RHMIToolbarState(super.id, super.type);

  List<RHMIComponent> toolbarComponents = [];
}