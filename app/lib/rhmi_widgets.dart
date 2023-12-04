import 'dart:developer';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:headunit/pigeon.dart';
import 'package:image/image.dart' as image_manips;
import 'package:kotlin_flavor/scope_functions.dart';
import 'package:multi_value_listenable_builder/multi_value_listenable_builder.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'rhmi.dart';

class RHMICallbacks {
  RHMICallbacks(this.navigator, this.client, this.app);

  final NavigatorState navigator;
  final ServerApi client;
  final RHMIApp app;

  bool hasAction(RHMIComponent component) {
    return component.actions['action'] != null;
  }

  openState(int stateId) {
    final targetState = app.description.states[stateId];
    if (targetState != null) {
      navigator.push(MaterialPageRoute(builder: (BuildContext context) {
        return VisibilityDetector(key: Key("visibility-$stateId"),
            onVisibilityChanged: (visibilityInfo) {
              final visible = visibilityInfo.visibleFraction != 0;
              client.rhmiEvent(app.appId, stateId, 1, {4: visible});  // focus
              client.rhmiEvent(app.appId, stateId, 11, {23: visible});  // visibility
            },
            child: RHMIStateWidget(callbacks: this, app: app, state: targetState)
        );
      }));
    }
  }

  Future<bool> dispatchAction(int actionId, {Map<int, Object?>? args}) async {
    final ack = client.rhmiAction(app.appId, actionId, args ?? {});
    ack.timeout(const Duration(seconds: 3), onTimeout: () {
      return false;
    });
    return await ack;
  }

  void listAction(RHMIComponent component, int index) async {
    action(component, args: {1: index});
  }
  void action(RHMIComponent component, {Map<int, Object?>? args}) async {
    final action = component.actions['action'];

    if (action is RHMIRaAction) {
      dispatchAction(action.id, args: args);
    }
    if (action is RHMIHmiAction) {
      final targetModelValue = action.targetModel?.value;
      log("Loaded direct hmiModel ${action.targetModelId}:$targetModelValue");
      final targetStateId = (targetModelValue is int) ? targetModelValue : action.target ?? -1;
      openState(targetStateId);
    }
    if (action is RHMICombinedAction) {
      final raAction = action.raAction;
      log("Triggering raAction $raAction");
      if (raAction != null) {
        if (action.attributes["sync"] == "true") {
          final ack = dispatchAction(action.id, args: args);
          log("Got acknowledgement ${await ack}");
          if (await ack == false) {
            return;
          }
        } else {
          client.rhmiAction(app.appId, raAction.id, {});
        }
      }
      final targetModelValue = action.hmiAction?.targetModel?.value;
      log("Loaded hmiModel ${action.hmiAction?.targetModelId}:$targetModelValue");
      final targetStateId = (targetModelValue is int) ? targetModelValue : action.hmiAction?.target ?? -1;
      openState(targetStateId);
    }
  }
}

class AMButtonClickable extends StatelessWidget {
  const AMButtonClickable({super.key, required this.callbacks, required this.appId, required this.child});

  final ServerApi callbacks;
  final String appId;
  final StatelessWidget child;

  void onTap() async {
    callbacks.amTrigger(appId);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell (  // TODO support other themes
        onTap: () => onTap(),
        child: child
    );
  }
}

class RHMIEntryButton {
  RHMIEntryButton(this.name, this.iconData, this.category);

  final String name;
  final Uint8List? iconData;
  final String category;
}

class RHMISectionWidget extends StatelessWidget {
  const RHMISectionWidget({
    super.key,
    required this.name,
    required this.buttons,
  });
  final String name;
  final List<StatelessWidget> buttons;

  @override
  Widget build(BuildContext context) {

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(name),
        ...buttons
      ]
    );
  }
}

class RHMIEntryButtonWidget extends StatelessWidget {
  const RHMIEntryButtonWidget({
    super.key,
    required this.entryButton,
  });
  final RHMIEntryButton entryButton;

  @override
  Widget build(BuildContext context) {
    final iconData = entryButton.iconData;
    final icon = iconData != null ? TransparentIcon(
      iconData: iconData,
      darkMode: MediaQuery.of(context).platformBrightness == Brightness.dark,
      width: 48,
      height: 48,
    ) : const SizedBox(width: 48, height: 48);
    return ImageLabeled(
      image: icon,
      text: Text(entryButton.name)
    );
  }

  static StatelessWidget wrapAMAppInfo(ServerApi server, AMAppInfo appInfo) {
    final entryButton = RHMIEntryButton(appInfo.name, appInfo.iconData, appInfo.category);
    return AMButtonClickable(
        callbacks: server,
        appId: appInfo.appId,
        child: RHMIEntryButtonWidget(entryButton: entryButton)
    );
  }
  static StatelessWidget wrapRhmiEntryButton(RHMIApp app, RHMIComponent component, RHMICallbacks callbacks, String category) {
    return RHMIButtonWidget(app: app, component: component, callbacks: callbacks);
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
    final image = image_manips.decodeImage(iconData);
    if (image != null && image.channels == image_manips.Channels.rgb) {
      image.channels = image_manips.Channels.rgba;
      final pixels = image.getBytes(format: image_manips.Format.rgba);
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
        image_manips.encodePng(image) as Uint8List,
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

class RHMIStateWidget extends StatelessWidget {
  const RHMIStateWidget({
    super.key,
    required this.callbacks,
    required this.app,
    required this.state,
  });
  final RHMICallbacks callbacks;
  final RHMIApp app;
  final RHMIState state;

  @override
  Widget build(BuildContext context) {
    Drawer? drawer;
    final state = this.state;
    if (state is RHMIToolbarState) {
      List<Widget> toolbar = [];
      toolbar = state.toolbarComponents.map((e) => RHMIButtonWidget(app: app, component: e, callbacks: callbacks)).toList();
      drawer = Drawer(
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 24),
          child: ListView(
            children: [
              Row(
                children: [
                  BackButton(
                    onPressed: () {
                      Navigator.pop(context); // close the sidebar
                      Navigator.pop(context); // back out of the window
                    },
                  )
                ],
              ),
              ... toolbar
            ]
          )
        )
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(state.id.toString()),
            RHMITextModelWidget(app: app, model: state.models["textModel"])
          ],
        )
      ),
      drawer: drawer,
      body: DefaultTextStyle(
        style: const TextStyle(fontSize: 24),
        child: ListView(
          children: [
            ... state.components.map((e) =>
            switch (e.type) {
              "button" => RHMIButtonWidget(app: app, component: e, callbacks: callbacks),
              "label" => RHMITextWidget(app: app, component: e),
              "list" => RHMIListWidget(app: app, listComponent: e, callbacks: callbacks),
              _ => const SizedBox(),
            })
          ],
        )
      )
    );
  }
}

class RHMIButtonWidget extends StatelessWidget {
  const RHMIButtonWidget({
    super.key,
    required this.app,
    required this.component,
    required this.callbacks,
  });

  final RHMIApp app;
  final RHMIComponent component;
  final RHMICallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final model = component.models["model"] ?? component.models["tooltipModel"];
    final imageModel = component.models["imageModel"];
    return Row(
      children: [
        TextButton.icon(
            onPressed: () => callbacks.action(component),
            icon: RHMIImageModelWidget(app: app, model: imageModel),
            label: RHMITextModelWidget(app: app, model: model)
        )
      ],
    );
  }
}

class RHMITextWidget extends StatelessWidget {
  const RHMITextWidget({
    super.key,
    required this.app,
    required this.component,
    this.modelName = "model",
  });

  final RHMIApp app;
  final RHMIComponent component;
  final String modelName;

  @override
  Widget build(BuildContext context) {
    final model = component.models[modelName];
    if (model != null) {
      return RHMITextModelWidget(app: app, model: model);
    }
    return const Text("");
  }
}

class RHMIImageModelWidget extends StatelessWidget {
  const RHMIImageModelWidget({
    super.key,
    required this.app,
    required this.model,
  });

  final RHMIApp app;
  final RHMIModel? model;

  @override
  Widget build(BuildContext context) {
    final model = this.model;
    if (model == null) {
      return const Text("");
    }
    final darkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return ListenableBuilder(
        listenable: model,
        builder: (context, child) {
          if (model.type == "imageIdModel") {
            final imageId = model.attributes["imageId"];
            if (imageId is int) {
              return RHMIImageIdWidget(app: app, imageId: imageId);
            }
          } else {
            final value = model.value;
            if (value is Uint8List) {
              return TransparentIcon(
                  iconData: value, darkMode: darkMode, width: 48, height: 48
              );
            }
          }
          // else
          return const SizedBox(width: 48, height: 48);
        }
    );
  }
}

class RHMIImageIdWidget extends StatelessWidget {
  const RHMIImageIdWidget({
    super.key,
    required this.app,
    required this.imageId,
  });
  final RHMIApp app;
  final int imageId;

  @override
  Widget build(BuildContext context) {
    final darkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final iconData = app.images[imageId];
    if (iconData is Uint8List) {
      return TransparentIcon(
          iconData: iconData, darkMode: darkMode, width: 48, height: 48
      );
    } else {
      return const SizedBox(width: 48, height: 48);
    }
  }
}
class RHMITextModelWidget extends StatelessWidget {
  const RHMITextModelWidget({
    super.key,
    required this.app,
    required this.model,
  });

  final RHMIApp app;
  final RHMIModel? model;

  @override
  Widget build(BuildContext context) {
    final model = this.model;
    if (model == null) {
      return const Text("");
    }
    return ListenableBuilder(
        listenable: model,
        builder: (context, child) {
          if (model.type == "textIdModel") {
            final value = model.value;
            if (value is int) {
              return RHMITextIdWidget(app: app, textId: value);
            } else {
              return const Text("");
            }
          } else {
            return Text(model.value?.toString() ?? "");
          }
        }
    );
  }
}

class RHMITextIdWidget extends StatelessWidget {
  const RHMITextIdWidget({
    super.key,
    required this.app,
    required this.textId,
  });
  final RHMIApp app;
  final int textId;

  @override
  Widget build(BuildContext context) {
    return Text(app.texts["en-US"]?[textId] ?? "");
  }
}

class RHMIListWidget extends StatelessWidget {
  const RHMIListWidget({
    super.key,
    required this.app,
    required this.listComponent,
    required this.callbacks,
    this.modelName = "model",
  });

  final RHMIApp app;
  final RHMICallbacks callbacks;
  final RHMIComponent listComponent;
  final String modelName;

  Widget renderCell(Object value, {required bool darkMode}) {
    if (value is RHMITextId) {
      return RHMITextIdWidget(app: app, textId: value.id);
    } else if (value is RHMIImageId) {
      return RHMIImageIdWidget(app: app, imageId: value.id);
    } else if (value is Uint8List) {
      return TransparentIcon(iconData: value, darkMode: darkMode, width: 96, height: 96);
    } else {
      return Text(value.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = listComponent.models[modelName];
    if (model == null) {
      return const Text("");
    }
    return MultiValueListenableBuilder(
      valueListenables:
        [model, listComponent.properties[RHMIProperty.list_columnwidth]],
      builder: (context, _, child) {
        final darkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
        final value = model.value;
        if (value is List) {
          final columnSizes = listComponent.properties[RHMIProperty.list_columnwidth].value.toString()
              .split(",").map((e) => int.tryParse(e)?.let((self) => FixedColumnWidth(self.toDouble())) ?? const FlexColumnWidth())
              .toList().asMap();
          return Table(
            columnWidths: columnSizes,
            defaultColumnWidth: const FlexColumnWidth(),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              ... value.mapIndexed((index, row) => TableRow(
                  children: [
                    ...(row as List).map((e) => ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 48,
                        maxHeight: 96,
                      ),
                      child: TableRowInkWell(
                        onTap: () => callbacks.listAction(listComponent, index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: renderCell(
                            e,
                            darkMode: darkMode
                          )
                        )
                      )
                    )
                  )
                ]
              ))
            ]
          );
        } else {
          return const Text("");
        }
      }
    );
  }
}

class ImageLabeled extends StatelessWidget {
  const ImageLabeled({super.key, required this.image, required this.text});

  final Widget image;
  final Widget text;

  @override
  Widget build(BuildContext context) {
    final double scale = MediaQuery.textScaleFactorOf(context);
    final double gap = scale <= 1 ? 8 : lerpDouble(8, 4, math.min(scale - 1, 1))!;

    return Padding(
      padding: EdgeInsets.fromLTRB(gap, gap, gap, gap),
      child: Row(
        children: [
          image,
          SizedBox(width: gap, height: gap),
          text
        ]
      )
    );
  }

}