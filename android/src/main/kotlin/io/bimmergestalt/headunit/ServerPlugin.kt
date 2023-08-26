package io.bimmergestalt.headunit

import android.os.Handler
import android.os.HandlerThread
import io.bimmergestalt.headunit.managers.AMManager
import io.bimmergestalt.headunit.managers.RHMIManager
import io.flutter.embedding.engine.plugins.FlutterPlugin

import io.bimmergestalt.idriveconnectkit.RHMIDimensions

/** ServerPlugin */
class ServerPlugin: FlutterPlugin, ServerApi {
  private val ioThread = HandlerThread("toEtchClients").apply { start() }
  private val ioHandler = Handler(ioThread.looper)

  private val headunitCallbacks = HeadunitCallbacks()
  private val amManager = AMManager(headunitCallbacks)
  private val rhmiManager = RHMIManager(headunitCallbacks)
  private val server = CarServer(amManager = amManager, rhmiManager = rhmiManager)

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

  override fun rhmiAction(appId: String, actionId: Long, args: Map<Long, Any?>, callback: (Result<Boolean>) -> Unit) {
    ioHandler.post {
      rhmiManager.onActionEvent(appId, actionId.toInt(), args, callback)
    }
  }

  override fun rhmiEvent(appId: String, componentId: Long, eventId: Long, args: Map<Long, Any?>) {
    ioHandler.post {
      rhmiManager.onHmiEvent(appId, componentId.toInt(), eventId.toInt(), args)
    }
  }
}
