package io.bimmergestalt.headunit

import android.util.SparseIntArray
import androidx.collection.SparseArrayCompat
import de.bmw.idrive.BMWRemoting
import de.bmw.idrive.BMWRemotingClient
import de.bmw.idrive.BaseBMWRemotingServer
import io.bimmergestalt.headunit.Utils.values
import io.flutter.Log
import org.apache.etch.util.core.io.Session

class BMWRemotingServerImpl(val client: BMWRemotingClient, val callbacks: HeadunitCallbacks): BaseBMWRemotingServer() {
	/** The server side of each TCP connection */
	companion object {
		private const val TAG = "BMWRemotingServerImpl"

		// TODO register handles from a global manager (to dispatch events back to the clients)
		private var nextId = 10;
	}

	val amHandles = SparseIntArray()
	val amApps = HashSet<String>()
	val rhmiHandles = SparseArrayCompat<String>()
	val cdsHandles = HashSet<Int>() // TODO value should be a subscription list or something

	override fun _sessionNotify(event: Any?) {
		Log.d(TAG, "Received remotingServer sessionNotify $event")
		super._sessionNotify(event)

		if (event == Session.DOWN) {
			Log.i(TAG, "Cleaning up disconnected rhmiApps: ${rhmiHandles.values().joinToString(",")}")

			// clear out all the AM apps
			Log.i(TAG, "Cleaning up disconnected amApps: ${amApps.joinToString(",")}")
			amApps.forEach {
				callbacks.amUnregisterApp(it)
			}
			amApps.clear()
		}
		// TODO Callback

	}

	override fun sas_certificate(data: ByteArray?): ByteArray {
		// ignore the cert, we'll be wide open
		return ByteArray(16)
	}
	override fun sas_login(data: ByteArray?) {
		// i'm sure it's fine
	}
	override fun sas_logout(data: ByteArray?) {
		// ignored
	}

	override fun ver_getVersion(): BMWRemoting.VersionInfo {
		return BMWRemoting.VersionInfo(4, 0, 0)
	}

	override fun am_create(deviceId: String?, bluetoothAddress: ByteArray?): Int {
		Log.i(TAG, "am_create")
		val handle = nextId
		nextId++
		amHandles.put(handle, handle)
		return handle
	}

	override fun am_registerApp(handle: Int?, appId: String?, values: MutableMap<*, *>?) {
		// TODO
		Log.i(TAG, "am_registerApp appId:${appId} name:${values?.get(1.toByte())}")
		handle ?: return
		appId ?: return
		values ?: return
		val name = values[1.toByte()] as? String ?: return
		val icon = values[2.toByte()] as? ByteArray ?: return
		val category = values[3.toByte()] as? String ?: return
		callbacks.amRegisterApp(handle, name, icon, category)
		amApps.add(name)
	}

	override fun am_addAppEventHandler(handle: Int?, ident: String?) {
		// TODO
	}

	override fun am_removeAppEventHandler(handle: Int?, ident: String?) {
		// TODO
	}

	override fun am_dispose(handle: Int?) {
		Log.i(TAG, "am_dispose")
		amHandles.delete(handle ?: -1)
		// clear out all the apps too
		amApps.forEach {
			callbacks.amUnregisterApp(it)
		}
		amApps.clear()
	}

	override fun cds_create(): Int {
		Log.i(TAG, "cds_create")
		val handle = nextId
		nextId++
		cdsHandles.add(handle)
		return handle
	}

	override fun cds_addPropertyChangedEventHandler(
		handle: Int?,
		propertyName: String?,
		ident: String?,
		intervalLimit: Int?
	) {
		// TODO
	}

	override fun cds_getPropertyAsync(handle: Int?, ident: String?, propertyName: String?) {
		// TODO
		Log.i(TAG, "cds_getPropertyAsync ident:$ident propertyName:$propertyName")
		if (propertyName == "vehicle.language") {
			client.cds_onPropertyChangedEvent(handle, ident, propertyName, "{\"language\":3}")
		}
	}

	override fun cds_removePropertyChangedEventHandler(
		handle: Int?,
		propertyName: String?,
		ident: String?
	) {
		// TODO
	}

	override fun cds_dispose(handle: Int?) {
		cdsHandles.remove(handle)
	}

	override fun rhmi_getCapabilities(component: String?, handle: Int?): Map<*, *> {
		return mapOf(
			"vehicle.type" to "A01",
			"hmi.type" to "BMW Fake",
		)
	}

	override fun rhmi_create(token: String?, metaData: BMWRemoting.RHMIMetaData?): Int {
		Log.i(TAG, "rhmi_create vendor:${metaData?.vendor} id:${metaData?.id} name:${metaData?.name}")

		// TODO check for duplicate names

		val handle = nextId
		nextId++
		rhmiHandles.put(handle, metaData?.name ?: "")
		return handle
	}

	override fun rhmi_checkResource(
		hash: ByteArray?,
		handle: Int?,
		size: Int?,
		name: String?,
		type: BMWRemoting.RHMIResourceType?
	): Boolean {
		// no caching implemented yet
		return false
	}

	override fun rhmi_setResource(
		handle: Int?,
		data: ByteArray?,
		type: BMWRemoting.RHMIResourceType?
	) {
		val rhmiApp = rhmiHandles[handle ?: 0]
		// TODO add resource to the rhmi app
	}

	override fun rhmi_initialize(handle: Int?) {
		val rhmiApp = rhmiHandles[handle ?: 0]
		Log.i(TAG, "rhmi_initialize name:$rhmiApp")
		// TODO finalize the app and send callback to host
	}

	override fun rhmi_addActionEventHandler(handle: Int?, ident: String?, actionId: Int?) {
		// TODO
	}

	override fun rhmi_addHmiEventHandler(
		handle: Int?,
		ident: String?,
		componentId: Int?,
		eventId: Int?
	) {
		// TODO
	}

	override fun rhmi_setData(handle: Int?, modelId: Int?, value: Any?) {
		// TODO
		val rhmiApp = rhmiHandles[handle ?: 0]
		Log.i(TAG, "rhmi_setData name:$rhmiApp modelId:$modelId value:$value")
	}

	override fun rhmi_setProperty(
		handle: Int?,
		componentId: Int?,
		propertyId: Int?,
		values: MutableMap<*, *>?
	) {
		// TODO
		val rhmiApp = rhmiHandles[handle ?: 0]
		if (values?.size != 1) {
			Log.i(TAG, "rhmi_setProperty name:$rhmiApp componentId:$componentId propertyId:$propertyId values:$values")
		} else {
			val value = values.values.first()
			Log.i(TAG, "rhmi_setProperty name:$rhmiApp componentId:$componentId propertyId:$propertyId values:$value")
		}
	}

	override fun rhmi_triggerEvent(handle: Int?, eventId: Int?, args: MutableMap<*, *>?) {
		val rhmiApp = rhmiHandles[handle ?: 0]
		Log.i(TAG, "rhmi_triggerEvent name:$rhmiApp eventId:$eventId args:$args")
	}

	override fun rhmi_dispose(handle: Int?) {
		// TODO
		val rhmiApp = rhmiHandles[handle ?: 0]
		Log.i(TAG, "rhmi_dispose name:$rhmiApp")

		rhmiHandles.remove(handle ?: 0)
	}

	override fun av_create(instanceID: Int?, id: String?): Int = 0
	override fun av_requestConnection(handle: Int?, connectionType: BMWRemoting.AVConnectionType?) {}
	override fun av_closeConnection(handle: Int?, connectionType: BMWRemoting.AVConnectionType?) {}
	override fun av_playerStateChanged(
		handle: Int?,
		connectionType: BMWRemoting.AVConnectionType?,
		playerState: BMWRemoting.AVPlayerState?
	) {}
	override fun av_dispose(handle: Int?) {}
}