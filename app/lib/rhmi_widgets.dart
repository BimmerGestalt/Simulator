import 'dart:developer';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:headunit/pigeon.dart';
import 'package:image/image.dart' as image_manips;
import 'package:visibility_detector/visibility_detector.dart';

import 'rhmi.dart';

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
class RHMIButtonClickable extends StatelessWidget {
  const RHMIButtonClickable({super.key, required this.callbacks, required this.app, required this.component, required this.child});

  final ServerApi callbacks;
  final RHMIApp app;
  final RHMIComponent component;
  final StatelessWidget child;

  Future<bool> dispatchAction(int actionId) async {
    final ack = callbacks.rhmiAction(app.appId, actionId, {});
    ack.timeout(const Duration(seconds: 3), onTimeout: () {
      return false;
    });
    return await ack;
  }

  openState(NavigatorState navigator, int stateId) {
    final targetState = app.description.states[stateId];
    if (targetState != null) {
      navigator.push(MaterialPageRoute(builder: (BuildContext context) {
        return VisibilityDetector(key: Key("visibility-$stateId"),
          onVisibilityChanged: (visibilityInfo) {
            final visible = visibilityInfo.visibleFraction != 0;
            callbacks.rhmiEvent(app.appId, stateId, 1, {4: visible});  // focus
            callbacks.rhmiEvent(app.appId, stateId, 11, {23: visible});  // visibility
          },
          child: RHMIStateWidget(callbacks: callbacks, app: app, state: targetState)
        );
      }));
    }
  }

  void onTap(NavigatorState navigator) async {
    final action = component.actions['action'];

    if (action is RHMIAction) {
      dispatchAction(action.id);
    }
    if (action is RHMIHmiAction) {
      final targetModelValue = action.targetModel?.value;
      log("Loaded direct hmiModel ${action.targetModelId}:$targetModelValue");
      final targetStateId = (targetModelValue is int) ? targetModelValue : action.target ?? -1;
      openState(navigator, targetStateId);
    }
    if (action is RHMICombinedAction) {
      final raAction = action.raAction;
      log("Triggering raAction $raAction");
      if (raAction != null) {
        if (action.attributes["sync"] == "true") {
          final ack = dispatchAction(action.id);
          log("Got acknowledgement ${await ack}");
          if (await ack == false) {
            return;
          }
        } else {
          callbacks.rhmiAction(app.appId, raAction.id, {});
        }
      }
      final targetModelValue = action.hmiAction?.targetModel?.value;
      log("Loaded hmiModel ${action.hmiAction?.targetModelId}:$targetModelValue");
      final targetStateId = (targetModelValue is int) ? targetModelValue : action.hmiAction?.target ?? -1;
      openState(navigator, targetStateId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = component.actions['action'];
    if (action != null) {
      return InkWell (  // TODO support other themes
        onTap: () => onTap(Navigator.of(context)),
        child: child
      );
    } else {
      return child;
    }
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
  static StatelessWidget wrapRhmiEntryButton(ServerApi server, RHMIApp app, RHMIComponent entryButtonComponent, String category) {
    final textId = entryButtonComponent.models['model']?.attributes['textId'];
    log("Loaded textId $textId for entryButton for ${app.appId}");
    final String name = app.texts['en-US']?[textId] ?? "";
    log("Loaded name $name for entryButton for ${app.appId} from ${app.texts['en-US']}");
    final imageId = entryButtonComponent.models['imageModel']?.attributes['imageId'];
    log("Loaded imageId $imageId for entryButton for ${app.appId}");
    final Uint8List? iconData = app.images[imageId];

    final entryButton = RHMIEntryButton(name, iconData, category);
    return RHMIButtonClickable(
        callbacks: server,
        app: app,
        component: entryButtonComponent,
        child: RHMIEntryButtonWidget(entryButton: entryButton)
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
  final ServerApi callbacks;
  final RHMIApp app;
  final RHMIState state;

  @override
  Widget build(BuildContext context) {
    Drawer? drawer;
    final state = this.state;
    if (state is RHMIToolbarState) {
      List<Widget> toolbar = [];
      toolbar = state.toolbarComponents.map((e) =>  RHMIButtonClickable(
          callbacks: callbacks,
          app: app,
          component: e,
          child: RHMIButtonWidget(app: app, component: e))).toList();
      drawer = Drawer(
          child: ListView(
            children: [
              Row(
                children: [
                  BackButton(
                    onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                  )
                ],
              ),
              ... toolbar
            ]
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
      body: ListView(
        children: [
          ... state.components.map((e) =>
          switch (e.type) {
            "button" => RHMIButtonClickable(
                callbacks: callbacks,
                app: app,
                component: e,
                child: RHMIButtonWidget(app: app, component: e)),
            "label" => RHMITextWidget(app: app, component: e),
            "list" => RHMIListWidget(listComponent: e),
            _ => const SizedBox(),
          })
        ],
      )
    );
  }
}

class RHMIButtonWidget extends StatelessWidget {
  const RHMIButtonWidget({
    super.key,
    required this.app,
    required this.component,
  });

  final RHMIApp app;
  final RHMIComponent component;

  @override
  Widget build(BuildContext context) {
    final model = component.models["model"] ?? component.models["tooltipModel"];
    final imageModel = component.models["imageModel"];
    List<Widget> widgets = [];
    if (imageModel != null) {
      widgets.add(RHMIImageModelWidget(app: app, model: imageModel));
    }
    if (model != null) {
      widgets.add(RHMITextModelWidget(app: app, model: model));
    }
    return Row(
      children: widgets,
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
          final value = model.type == "imageIdModel"
              ? app.images[model.value] ?? app.images[model.attributes["imageId"]]
              : model.value;
          if (value is Uint8List) {
            return TransparentIcon(
                iconData: value, darkMode: darkMode, width: 48, height: 48
            );
          }
          return const SizedBox(width: 48, height: 48);
        }
    );
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
            return Text(app.texts["en-US"]?[model.value] ?? "");
          } else {
            return Text(model.value?.toString() ?? "");
          }
        }
    );
  }
}

class RHMIListWidget extends StatelessWidget {
  const RHMIListWidget({
    super.key,
    required this.listComponent,
    this.modelName = "model",
  });

  final RHMIComponent listComponent;
  final String modelName;

  Widget renderCell(Object value, {required bool darkMode}) {
    if (value is Uint8List) {
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
    return ListenableBuilder(
      listenable: model,
      builder: (context, child) {
        final value = model.value;
        if (value is List) {
          return Table(
            // TODO ColumnWidths based on RHMI Property
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: [
              ... value.map((row) => TableRow(
                  children: [
                    ...(row as List).map((e) => renderCell(
                      e,
                      darkMode: MediaQuery.of(context).platformBrightness == Brightness.dark
                    ))
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