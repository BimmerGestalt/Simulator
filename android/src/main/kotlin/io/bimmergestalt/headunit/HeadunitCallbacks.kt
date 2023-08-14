package io.bimmergestalt.headunit

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel

class HeadunitCallbacks {
	val handler = Handler(Looper.getMainLooper())
	var channel: MethodChannel? = null

	fun amRegisterApp(handle: Int, name: String, icon: ByteArray, category: String) {
		handler.post {
			channel?.invokeMethod("amRegisterApp", mapOf(
				"handle" to handle,
				"name" to name,
				"icon" to icon,
				"category" to category,
			))
		}
	}

	fun amUnregisterApp(name: String) {
		handler.post {
			channel?.invokeMethod("amUnregisterApp", mapOf(
				"name" to name,
			))
		}
	}
}