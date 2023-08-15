package io.bimmergestalt.headunit

import android.os.Handler
import android.os.Looper

class HeadunitCallbacks {
	val handler = Handler(Looper.getMainLooper())
	var channel: HeadunitApi? = null

	fun amRegisterApp(appInfo: AMAppInfo) {
		handler.post {
			channel?.amRegisterApp(appInfo) {}
		}
	}

	fun amUnregisterApp(appId: String) {
		handler.post {
			channel?.amUnregisterApp(appId) {}
		}
	}
}