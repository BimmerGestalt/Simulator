package io.bimmergestalt.headunit

import android.os.Handler
import android.os.HandlerThread
import io.bimmergestalt.headunit.managers.AMManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

import io.bimmergestalt.idriveconnectkit.RHMIDimensions

/** ServerPlugin */
class ServerPlugin: FlutterPlugin, ServerApi {
  private val ioThread = HandlerThread("toEtchClients").apply { start() }
  private val ioHandler = Handler(ioThread.looper)

  private val headunitCallbacks = HeadunitCallbacks()
  private val amManager = AMManager(headunitCallbacks)
  private val server = CarServer(amManager = amManager)

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    headunitCallbacks.channel = HeadunitApi(flutterPluginBinding.binaryMessenger)
    ServerApi.setUp(flutterPluginBinding.binaryMessenger, this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    headunitCallbacks.channel = null
  }

  override fun getPlatformVersion(): String {
    val dimensions = RHMIDimensions.create(emptyMap())
    return "Android ${android.os.Build.VERSION.RELEASE} on ${dimensions.rhmiWidth}x${dimensions.rhmiHeight}"
  }

  override fun startServer() {
    server.startServer()
  }

  override fun amTrigger(appId: String) {
    ioHandler.post {
      amManager.onAppEvent(appId)
    }
  }
}
