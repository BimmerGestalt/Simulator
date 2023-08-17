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

	fun rhmiRegisterApp(appInfo: RHMIAppInfo) {
		handler.post {
			channel?.rhmiRegisterApp(appInfo) {}
		}
	}

	fun rhmiUnregisterApp(appId: String) {
		handler.post {
			channel?.rhmiUnregisterApp(appId) {}
		}
	}

	fun rhmiSetData(appId: String, modelId: Int, value: Any?) {
		handler.post {
			channel?.rhmiSetData(appId, modelId.toLong(), value) {}
		}
	}

	fun rhmiSetProperty(appId: String, componentId: Int, propertyId: Int, value: Any?) {
		handler.post {
			channel?.rhmiSetProperty(appId, componentId.toLong(), propertyId.toLong(), value) {}
		}
	}

	fun rhmiTriggerEvent(appId: String, eventId: Int, args: Map<Int, Any?>) {
		handler.post {
			channel?.rhmiTriggerEvent(appId, eventId.toLong(), args.mapKeys { it.key.toLong() }) {}
		}
	}
}