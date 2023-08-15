package io.bimmergestalt.headunit

import android.os.Handler
import android.os.Looper

class HeadunitCallbacks {
	val handler = Handler(Looper.getMainLooper())
	var channel: HeadunitApi? = null

	fun amRegisterApp(handle: Int, name: String, icon: ByteArray, category: String) {
		handler.post {

			channel?.amRegisterApp(AMAppInfo(handle.toLong(), name, icon, category)) {}
		}
	}

	fun amUnregisterApp(name: String) {
		handler.post {
			channel?.amUnregisterApp(name) {}
		}
	}
}