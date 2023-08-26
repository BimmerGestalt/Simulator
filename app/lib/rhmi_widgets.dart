import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:headunit/pigeon.dart';
import 'package:image/image.dart' as image_manips;

import 'rhmi.dart';

class RHMIEntryButtonClickable {
  RHMIEntryButtonClickable(this.name, this.iconData, this.category, this.onClick);

  final String name;
  final Uint8List? iconData;
  final String category;
  final Future<void> Function(BuildContext) onClick;

  static RHMIEntryButtonClickable wrapAMAppInfo(ServerApi server, AMAppInfo appInfo) {
    return RHMIEntryButtonClickable(appInfo.name, appInfo.iconData, appInfo.category, (context) async {
      server.amTrigger(appInfo.appId);
    });
  }
  static RHMIEntryButtonClickable wrapRhmiEntryButton(ServerApi server, RHMIApp app, RHMIComponent entryButton, String category) {
    final textId = entryButton.models['model']?.attributes['textId'];
    log("Loaded textId $textId for entryButton for ${app.appId}");
    final String name = app.texts['en-US']?[textId] ?? "";
    log("Loaded name $name for entryButton for ${app.appId} from ${app.texts['en-US']}");
    final imageId = entryButton.models['imageModel']?.attributes['imageId'];
    log("Loaded imageId $imageId for entryButton for ${app.appId}");
    final Uint8List? iconData = app.images[imageId];

    return RHMIEntryButtonClickable(name, iconData, category, (context) async {
      final navigator = Navigator.of(context);
      final action = entryButton.actions["action"];
      if (action is RHMIAction) {
        final ack = server.rhmiAction(app.appId, action.id, {});
        ack.timeout(const Duration(seconds: 3), onTimeout: () {
          return false;
        });
        await ack;
      }
      if (action is RHMIHmiAction) {
        final targetModelValue = action.targetModel?.value;
        log("Loaded direct hmiModel ${action.targetModelId}:$targetModelValue");
        final targetStateId = (targetModelValue is int) ? targetModelValue : action.target ?? -1;
        final targetState = app.description.states[targetStateId];
        if (targetState != null) {
          Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
            return RHMIStateWidget(state: targetState);
          }));
        }
      }
      if (action is RHMICombinedAction) {
        final raAction = action.raAction;
        log("Triggering raAction $raAction");
        if (raAction != null) {
          final ack = server.rhmiAction(app.appId, raAction.id, {});
          if (action.attributes["sync"] == "true") {
            ack.timeout(const Duration(seconds: 3), onTimeout: () {
              return false;
            });
            log("Got acknowledgement ${await ack}");
            if (await ack == false) {
              return;
            }
          }
        }
        final targetModelValue = action.hmiAction?.targetModel?.value;
        log("Loaded hmiModel ${action.hmiAction?.targetModelId}:$targetModelValue");
        final targetStateId = (targetModelValue is int) ? targetModelValue : action.hmiAction?.target ?? -1;
        final targetState = app.description.states[targetStateId];
        if (targetState != null) {
          navigator.push(MaterialPageRoute(builder: (BuildContext context) {
            return RHMIStateWidget(state: targetState);
          }));
        }
      }
    });
  }
}

class RHMISectionWidget extends StatelessWidget {
  const RHMISectionWidget({
    super.key,
    required this.name,
    required this.buttons,
  });
  final String name;
  final List<RHMIEntryButtonClickable> buttons;

  @override
  Widget build(BuildContext context) {

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(name),
        ...buttons.map((e) => RHMIEntryButtonWidget(entryButton: e))
      ]
    );
  }
}

class RHMIEntryButtonWidget extends StatelessWidget {
  const RHMIEntryButtonWidget({
    super.key,
    required this.entryButton,
  });
  final RHMIEntryButtonClickable entryButton;

  @override
  Widget build(BuildContext context) {
    final iconData = entryButton.iconData;
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => entryButton.onClick(context),
          icon: iconData != null ? TransparentIcon(
            iconData: iconData,
            darkMode: MediaQuery.of(context).platformBrightness == Brightness.dark,
            width: 48,
            height: 48,
          ) : const SizedBox(width: 48, height: 48),
          label: Text(entryButton.name),
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
    required this.state,
  });
  final RHMIState state;

  @override
  Widget build(BuildContext context) {
    final id = state.id.toString();
    final title = state.models["textModel"]?.value?.toString();   // TODO some apps don't update this until HmiEvent says they are visible
    return Scaffold(
      appBar: AppBar(
        title: Text("$id $title"),
      ),
      body: ListView(
      )
    );
  }
}