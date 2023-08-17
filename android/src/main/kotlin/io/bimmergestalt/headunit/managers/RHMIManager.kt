package io.bimmergestalt.headunit.managers

import de.bmw.idrive.BMWRemoting
import de.bmw.idrive.BMWRemoting.RHMIDataTable
import de.bmw.idrive.BMWRemoting.RHMIResourceData
import de.bmw.idrive.BMWRemoting.RHMIResourceIdentifier
import de.bmw.idrive.BMWRemoting.RHMIResourceType
import de.bmw.idrive.BMWRemotingClient
import io.bimmergestalt.headunit.HeadunitCallbacks
import io.bimmergestalt.headunit.RHMIAppInfo
import io.flutter.Log

class RHMIManager(val callbacks: HeadunitCallbacks) {
	private val TAG = "RHMIManager"
	private val knownApps = HashMap<String, RHMIAppInfo>()
	private val actionHandlers = HashMap<Int, BMWRemotingClient>()
	private val eventHandlers = HashMap<Int, BMWRemotingClient>()

	fun registerApp(handle: Int, appId: String, resources: Map<RHMIResourceType, ByteArray>) {
		val existing = knownApps[appId]
		if (existing != null) {
			throw BMWRemoting.IllegalArgumentException(-1, "RHMI App already registered")
		}
		val appInfo = RHMIAppInfo(handle.toLong(), appId, resources.mapKeys {
			it.key.toString()
		})
		knownApps[appId] = appInfo
		callbacks.rhmiRegisterApp(appInfo)
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
		val existing = knownApps[appId]
		if (existing != null) {
			callbacks.rhmiUnregisterApp(appId)
		}
	}

	fun addActionHandler(handle: Int, client: BMWRemotingClient) {
		actionHandlers[handle] = client
	}
	fun removeActionHandler(handle: Int) {
		actionHandlers.remove(handle)
	}

	fun addEventHandler(handle: Int, client: BMWRemotingClient) {
		eventHandlers[handle] = client
	}
	fun removeEventHandler(handle: Int) {
		eventHandlers.remove(handle)
	}

	private fun simplifyData(value: Any?): Any? {
		return when (value) {
			is RHMIDataTable -> {
				// TODO handle partial table updates :fear:
				value.data.map { row ->
					row.map { cell ->
						simplifyData(cell)
					}
				}
			}
			is RHMIResourceData -> value.data    // assume the destination model is RA
			is RHMIResourceIdentifier -> value.id    // assume the destination model is ID
			is ByteArray -> value
			is Number -> value
			is String -> value
			null -> null
			else -> {
				Log.e(TAG, "Unknown data type $value")
				null
			}
		}
	}
	fun setData(appId: String, modelId: Int, value: Any?) {
		// perhaps type validation should be done?
		// but then Kotlin would need to know
		// or an error callback needs to be handled from Dart
		callbacks.rhmiSetData(appId, modelId, simplifyData(value))
	}
	fun setProperty(appId: String, componentId: Int, propertyId: Int, value: Any?) {
		callbacks.rhmiSetProperty(appId, componentId, propertyId, value)
	}
	fun triggerEvent(appId: String, eventId: Int, args: Map<Int, Any?>) {
		callbacks.rhmiTriggerEvent(appId, eventId, args)
	}
}