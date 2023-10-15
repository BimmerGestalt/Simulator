// Autogenerated from Pigeon (v10.1.6), do not edit directly.
// See also: https://pub.dev/packages/pigeon

package io.bimmergestalt.headunit

import android.util.Log
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MessageCodec
import io.flutter.plugin.common.StandardMessageCodec
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

private fun wrapResult(result: Any?): List<Any?> {
  return listOf(result)
}

private fun wrapError(exception: Throwable): List<Any?> {
  if (exception is FlutterError) {
    return listOf(
      exception.code,
      exception.message,
      exception.details
    )
  } else {
    return listOf(
      exception.javaClass.simpleName,
      exception.toString(),
      "Cause: " + exception.cause + ", Stacktrace: " + Log.getStackTraceString(exception)
    )
  }
}

/**
 * Error class for passing custom error details to Flutter via a thrown PlatformException.
 * @property code The error code.
 * @property message The error message.
 * @property details The error details. Must be a datatype supported by the api codec.
 */
class FlutterError (
  val code: String,
  override val message: String? = null,
  val details: Any? = null
) : Throwable()

/** Generated class from Pigeon that represents data sent in messages. */
data class AMAppInfo (
  val handle: Long,
  val appId: String,
  val name: String,
  val iconData: ByteArray,
  val category: String

) {
  companion object {
    @Suppress("UNCHECKED_CAST")
    fun fromList(list: List<Any?>): AMAppInfo {
      val handle = list[0].let { if (it is Int) it.toLong() else it as Long }
      val appId = list[1] as String
      val name = list[2] as String
      val iconData = list[3] as ByteArray
      val category = list[4] as String
      return AMAppInfo(handle, appId, name, iconData, category)
    }
  }
  fun toList(): List<Any?> {
    return listOf<Any?>(
      handle,
      appId,
      name,
      iconData,
      category,
    )
  }
}

/** Generated class from Pigeon that represents data sent in messages. */
data class RHMIAppInfo (
  val handle: Long,
  val appId: String,
  val resources: Map<String?, ByteArray?>

) {
  companion object {
    @Suppress("UNCHECKED_CAST")
    fun fromList(list: List<Any?>): RHMIAppInfo {
      val handle = list[0].let { if (it is Int) it.toLong() else it as Long }
      val appId = list[1] as String
      val resources = list[2] as Map<String?, ByteArray?>
      return RHMIAppInfo(handle, appId, resources)
    }
  }
  fun toList(): List<Any?> {
    return listOf<Any?>(
      handle,
      appId,
      resources,
    )
  }
}

/** Generated class from Pigeon that represents data sent in messages. */
data class RHMIImageId (
  val id: Long

) {
  companion object {
    @Suppress("UNCHECKED_CAST")
    fun fromList(list: List<Any?>): RHMIImageId {
      val id = list[0].let { if (it is Int) it.toLong() else it as Long }
      return RHMIImageId(id)
    }
  }
  fun toList(): List<Any?> {
    return listOf<Any?>(
      id,
    )
  }
}

/** Generated class from Pigeon that represents data sent in messages. */
data class RHMITextId (
  val id: Long

) {
  companion object {
    @Suppress("UNCHECKED_CAST")
    fun fromList(list: List<Any?>): RHMITextId {
      val id = list[0].let { if (it is Int) it.toLong() else it as Long }
      return RHMITextId(id)
    }
  }
  fun toList(): List<Any?> {
    return listOf<Any?>(
      id,
    )
  }
}

@Suppress("UNCHECKED_CAST")
private object ServerApiCodec : StandardMessageCodec() {
  override fun readValueOfType(type: Byte, buffer: ByteBuffer): Any? {
    return when (type) {
      128.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          AMAppInfo.fromList(it)
        }
      }
      129.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          RHMIAppInfo.fromList(it)
        }
      }
      130.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          RHMIImageId.fromList(it)
        }
      }
      131.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          RHMITextId.fromList(it)
        }
      }
      else -> super.readValueOfType(type, buffer)
    }
  }
  override fun writeValue(stream: ByteArrayOutputStream, value: Any?)   {
    when (value) {
      is AMAppInfo -> {
        stream.write(128)
        writeValue(stream, value.toList())
      }
      is RHMIAppInfo -> {
        stream.write(129)
        writeValue(stream, value.toList())
      }
      is RHMIImageId -> {
        stream.write(130)
        writeValue(stream, value.toList())
      }
      is RHMITextId -> {
        stream.write(131)
        writeValue(stream, value.toList())
      }
      else -> super.writeValue(stream, value)
    }
  }
}

/** Generated interface from Pigeon that represents a handler of messages from Flutter. */
interface ServerApi {
  fun getPlatformVersion(): String
  fun startServer()
  fun amTrigger(appId: String)
  fun rhmiAction(appId: String, actionId: Long, args: Map<Long, Any?>, callback: (Result<Boolean>) -> Unit)
  fun rhmiEvent(appId: String, componentId: Long, eventId: Long, args: Map<Long, Any?>)

  companion object {
    /** The codec used by ServerApi. */
    val codec: MessageCodec<Any?> by lazy {
      ServerApiCodec
    }
    /** Sets up an instance of `ServerApi` to handle messages through the `binaryMessenger`. */
    @Suppress("UNCHECKED_CAST")
    fun setUp(binaryMessenger: BinaryMessenger, api: ServerApi?) {
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.headunit.ServerApi.getPlatformVersion", codec)
        if (api != null) {
          channel.setMessageHandler { _, reply ->
            var wrapped: List<Any?>
            try {
              wrapped = listOf<Any?>(api.getPlatformVersion())
            } catch (exception: Throwable) {
              wrapped = wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.headunit.ServerApi.startServer", codec)
        if (api != null) {
          channel.setMessageHandler { _, reply ->
            var wrapped: List<Any?>
            try {
              api.startServer()
              wrapped = listOf<Any?>(null)
            } catch (exception: Throwable) {
              wrapped = wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.headunit.ServerApi.amTrigger", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val appIdArg = args[0] as String
            var wrapped: List<Any?>
            try {
              api.amTrigger(appIdArg)
              wrapped = listOf<Any?>(null)
            } catch (exception: Throwable) {
              wrapped = wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.headunit.ServerApi.rhmiAction", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val appIdArg = args[0] as String
            val actionIdArg = args[1].let { if (it is Int) it.toLong() else it as Long }
            val argsArg = args[2] as Map<Long, Any?>
            api.rhmiAction(appIdArg, actionIdArg, argsArg) { result: Result<Boolean> ->
              val error = result.exceptionOrNull()
              if (error != null) {
                reply.reply(wrapError(error))
              } else {
                val data = result.getOrNull()
                reply.reply(wrapResult(data))
              }
            }
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.headunit.ServerApi.rhmiEvent", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val appIdArg = args[0] as String
            val componentIdArg = args[1].let { if (it is Int) it.toLong() else it as Long }
            val eventIdArg = args[2].let { if (it is Int) it.toLong() else it as Long }
            val argsArg = args[3] as Map<Long, Any?>
            var wrapped: List<Any?>
            try {
              api.rhmiEvent(appIdArg, componentIdArg, eventIdArg, argsArg)
              wrapped = listOf<Any?>(null)
            } catch (exception: Throwable) {
              wrapped = wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
    }
  }
}
@Suppress("UNCHECKED_CAST")
private object HeadunitApiCodec : StandardMessageCodec() {
  override fun readValueOfType(type: Byte, buffer: ByteBuffer): Any? {
    return when (type) {
      128.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          AMAppInfo.fromList(it)
        }
      }
      129.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          RHMIAppInfo.fromList(it)
        }
      }
      130.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          RHMIImageId.fromList(it)
        }
      }
      131.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          RHMITextId.fromList(it)
        }
      }
      else -> super.readValueOfType(type, buffer)
    }
  }
  override fun writeValue(stream: ByteArrayOutputStream, value: Any?)   {
    when (value) {
      is AMAppInfo -> {
        stream.write(128)
        writeValue(stream, value.toList())
      }
      is RHMIAppInfo -> {
        stream.write(129)
        writeValue(stream, value.toList())
      }
      is RHMIImageId -> {
        stream.write(130)
        writeValue(stream, value.toList())
      }
      is RHMITextId -> {
        stream.write(131)
        writeValue(stream, value.toList())
      }
      else -> super.writeValue(stream, value)
    }
  }
}

/** Generated class from Pigeon that represents Flutter messages that can be called from Kotlin. */
@Suppress("UNCHECKED_CAST")
class HeadunitApi(private val binaryMessenger: BinaryMessenger) {
  companion object {
    /** The codec used by HeadunitApi. */
    val codec: MessageCodec<Any?> by lazy {
      HeadunitApiCodec
    }
  }
  fun amRegisterApp(appInfoArg: AMAppInfo, callback: () -> Unit) {
    val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.headunit.HeadunitApi.amRegisterApp", codec)
    channel.send(listOf(appInfoArg)) {
      callback()
    }
  }
  fun amUnregisterApp(appIdArg: String, callback: () -> Unit) {
    val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.headunit.HeadunitApi.amUnregisterApp", codec)
    channel.send(listOf(appIdArg)) {
      callback()
    }
  }
  fun rhmiRegisterApp(appInfoArg: RHMIAppInfo, callback: () -> Unit) {
    val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.headunit.HeadunitApi.rhmiRegisterApp", codec)
    channel.send(listOf(appInfoArg)) {
      callback()
    }
  }
  fun rhmiUnregisterApp(appIdArg: String, callback: () -> Unit) {
    val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.headunit.HeadunitApi.rhmiUnregisterApp", codec)
    channel.send(listOf(appIdArg)) {
      callback()
    }
  }
  fun rhmiSetData(appIdArg: String, modelIdArg: Long, valueArg: Any?, callback: () -> Unit) {
    val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.headunit.HeadunitApi.rhmiSetData", codec)
    channel.send(listOf(appIdArg, modelIdArg, valueArg)) {
      callback()
    }
  }
  fun rhmiSetProperty(appIdArg: String, componentIdArg: Long, propertyIdArg: Long, valueArg: Any?, callback: () -> Unit) {
    val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.headunit.HeadunitApi.rhmiSetProperty", codec)
    channel.send(listOf(appIdArg, componentIdArg, propertyIdArg, valueArg)) {
      callback()
    }
  }
  fun rhmiTriggerEvent(appIdArg: String, eventIdArg: Long, argsArg: Map<Long, Any?>, callback: () -> Unit) {
    val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.headunit.HeadunitApi.rhmiTriggerEvent", codec)
    channel.send(listOf(appIdArg, eventIdArg, argsArg)) {
      callback()
    }
  }
  fun _dummy(aArg: RHMITextId, bArg: RHMIImageId, callback: () -> Unit) {
    val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.headunit.HeadunitApi._dummy", codec)
    channel.send(listOf(aArg, bArg)) {
      callback()
    }
  }
}
