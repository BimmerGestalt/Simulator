package io.bimmergestalt.headunit

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import io.bimmergestalt.idriveconnectkit.RHMIDimensions
import java.io.IOException

/** ServerPlugin */
class ServerPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  private val server = CarServer()

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "server")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    val dimensions = RHMIDimensions.create(emptyMap())
    when (call.method) {
      "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE} on ${dimensions.rhmiWidth}x${dimensions.rhmiHeight}")
      "startServer" -> startServer(result)
      else -> result.notImplemented()
    }
  }

  fun startServer(result: Result) {
    try {
      server.startServer()
    } catch (e: IOException) {
      result.error("StartServerException", e.toString(), e)
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
