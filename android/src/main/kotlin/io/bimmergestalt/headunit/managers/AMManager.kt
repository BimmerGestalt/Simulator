package io.bimmergestalt.headunit.managers

import de.bmw.idrive.BMWRemoting
import de.bmw.idrive.BMWRemotingClient
import io.bimmergestalt.headunit.AMAppInfo
import io.bimmergestalt.headunit.HeadunitCallbacks
import io.flutter.Log

class AMManager(val callbacks: HeadunitCallbacks) {
	private val TAG = "AMManager"
	private val knownApps = HashMap<String, AMAppInfo>()
	private val eventHandlers = HashMap<Int, BMWRemotingClient>()

	fun registerApp(handle: Int, appId: String, name: String, icon: ByteArray, category: String) {
		val existing = knownApps[appId]
		if (existing != null && existing.handle != handle.toLong()) {
			throw BMWRemoting.IllegalArgumentException(-1, "Incorrect AM handle")
		}
		if (existing != null && existing.category != category) {
			throw BMWRemoting.IllegalArgumentException(-1, "AM AppId already registered")
		}
		val appInfo = AMAppInfo(handle.toLong(), appId, name, icon, category)
		knownApps[appId] = appInfo
		callbacks.amRegisterApp(appInfo)
	}

	fun unregisterAppsByHandle(handle: Int) {
		val appIds = knownApps.values.filter {
			it.handle == handle.toLong()
		}.map {
			it.appId
		}
		appIds.forEach {
			unregisterApp(it)
		}
	}

	fun unregisterApp(appId: String) {
		val existing = knownApps.remove(appId)
		if (existing != null) {
			callbacks.amUnregisterApp(appId)
		}
	}

	fun addEventHandler(handle: Int, client: BMWRemotingClient) {
		eventHandlers[handle] = client
	}
	fun removeEventHandler(handle: Int) {
		eventHandlers.remove(handle)
	}
	fun onAppEvent(appId: String) {
		val appInfo = knownApps[appId]
		if (appInfo == null) {
			Log.e(TAG, "onAppEvent can't find app id $appId")
			return
		}
		val handler = eventHandlers[appInfo.handle.toInt()]
		if (handler == null) {
			Log.w(TAG, "onAppEvent doesn't know event handler for $appId")
			return
		}
		handler.am_onAppEvent(appInfo.handle.toInt(), "", appInfo.appId, BMWRemoting.AMEvent.AM_APP_START)
	}
}