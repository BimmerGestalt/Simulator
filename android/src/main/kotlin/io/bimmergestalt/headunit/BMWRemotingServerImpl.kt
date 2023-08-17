package io.bimmergestalt.headunit

import androidx.collection.SparseArrayCompat
import de.bmw.idrive.BMWRemoting
import de.bmw.idrive.BMWRemotingClient
import de.bmw.idrive.BaseBMWRemotingServer
import io.bimmergestalt.headunit.Utils.values
import io.bimmergestalt.headunit.managers.AMManager
import io.bimmergestalt.headunit.managers.RHMIManager
import io.flutter.Log
import org.apache.etch.util.core.io.Session

class BMWRemotingServerImpl(val client: BMWRemotingClient,
                            val amManager: AMManager,
                            val rhmiManager: RHMIManager,
                            ): BaseBMWRemotingServer() {
	/** The server side of each TCP connection */
	companion object {
		private const val TAG = "BMWRemotingServerImpl"

		// TODO register handles from a global manager (to dispatch events back to the clients)
		private var nextId = 10;
	}

	var amHandle: Int? = null
	var rhmiHandle: Int? = null
	var rhmiAppId: String? = null
	val rhmiResources = HashMap<BMWRemoting.RHMIResourceType, ByteArray>()
	val cdsHandles = HashSet<Int>() // TODO value should be a subscription list or something

	override fun _sessionNotify(event: Any?) {
		Log.d(TAG, "Received remotingServer sessionNotify $event")
		super._sessionNotify(event)

		if (event == Session.DOWN) {
			rhmi_dispose(rhmiHandle)
			am_dispose(amHandle)
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
		if (amHandle != null) {
			throw BMWRemoting.IllegalArgumentException(-1, "Can't make another AM handle")
		}
		val handle = nextId
		nextId++
		amHandle = handle
		return handle
	}

	override fun am_registerApp(handle: Int?, appId: String?, values: MutableMap<*, *>?) {
		Log.i(TAG, "am_registerApp appId:${appId} name:${values?.get(1.toByte())}")
		if (amHandle == null || amHandle != handle) {
			throw BMWRemoting.IllegalArgumentException(-1, "Incorrect AM handle")
		}
		handle ?: return
		appId ?: return
		values ?: return
		val name = values[1.toByte()] as? String ?: return
		val icon = values[2.toByte()] as? ByteArray ?: return
		val category = values[3.toByte()] as? String ?: return
		amManager.registerApp(handle, appId, name, icon, category)
	}

	override fun am_addAppEventHandler(handle: Int?, ident: String?) {
		if (amHandle == null || amHandle != handle) {
			throw BMWRemoting.IllegalArgumentException(-1, "Incorrect AM handle")
		}
		handle ?: return
		amManager.addEventHandler(handle, client)
	}

	override fun am_removeAppEventHandler(handle: Int?, ident: String?) {
		if (amHandle == null || amHandle != handle) {
			throw BMWRemoting.IllegalArgumentException(-1, "Incorrect AM handle")
		}
		val amHandle = amHandle ?: return
		amManager.removeEventHandler(amHandle)
	}

	override fun am_dispose(handle: Int?) {
		Log.i(TAG, "am_dispose")
		if (amHandle != handle) {
			throw BMWRemoting.IllegalArgumentException(-1, "Incorrect AM handle")
		}
		val amHandle = amHandle ?: return
		amManager.unregisterAppsByHandle(amHandle)
		amManager.removeEventHandler(amHandle)
		this.amHandle = null
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
		metaData ?: throw BMWRemoting.IllegalArgumentException()

		val handle = nextId
		nextId++
		rhmiHandle = handle
		rhmiAppId = metaData.name
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
		if (rhmiHandle == null || rhmiHandle != handle) {
			throw BMWRemoting.IllegalArgumentException(-1, "Incorrect RHMI handle")
		}
		type ?: return
		data ?: return
		rhmiResources[type] = data
	}

	override fun rhmi_initialize(handle: Int?) {
		Log.i(TAG, "rhmi_initialize name:$rhmiAppId")
		if (handle == null || rhmiHandle != handle) {
			throw BMWRemoting.IllegalArgumentException(-1, "Incorrect RHMI handle")
		}
		val rhmiAppId = rhmiAppId ?: return
		rhmiManager.registerApp(handle, rhmiAppId, rhmiResources)
	}

	override fun rhmi_addActionEventHandler(handle: Int?, ident: String?, actionId: Int?) {
		if (handle == null || rhmiHandle != handle) {
			throw BMWRemoting.IllegalArgumentException(-1, "Incorrect RHMI handle")
		}
		rhmiManager.addActionHandler(handle, client)
	}

	override fun rhmi_addHmiEventHandler(
		handle: Int?,
		ident: String?,
		componentId: Int?,
		eventId: Int?
	) {
		if (handle == null || rhmiHandle != handle) {
			throw BMWRemoting.IllegalArgumentException(-1, "Incorrect RHMI handle")
		}
		rhmiManager.addEventHandler(handle, client)
	}

	override fun rhmi_setData(handle: Int?, modelId: Int?, value: Any?) {
		if (handle == null || rhmiHandle != handle) {
			throw BMWRemoting.IllegalArgumentException(-1, "Incorrect RHMI handle")
		}
		Log.i(TAG, "rhmi_setData appId:$rhmiAppId modelId:$modelId value:$value")
		val rhmiAppId = rhmiAppId ?: return
		modelId ?: return
		rhmiManager.setData(rhmiAppId, modelId, value)
	}

	override fun rhmi_setProperty(
		handle: Int?,
		componentId: Int?,
		propertyId: Int?,
		values: MutableMap<*, *>?
	) {
		if (handle == null || rhmiHandle != handle) {
			throw BMWRemoting.IllegalArgumentException(-1, "Incorrect RHMI handle")
		}
		if (values?.size != 1) {
			Log.i(TAG, "rhmi_setProperty appId:$rhmiAppId componentId:$componentId propertyId:$propertyId values:$values")
		} else {
			val value = values.values.first()
			Log.i(TAG, "rhmi_setProperty appId:$rhmiAppId componentId:$componentId propertyId:$propertyId values:$value")
		}
		val rhmiAppId = rhmiAppId ?: return
		componentId ?: return
		propertyId ?: return
		values ?: return
		rhmiManager.setProperty(rhmiAppId, componentId, propertyId, values.values.first())
	}

	override fun rhmi_triggerEvent(handle: Int?, eventId: Int?, args: MutableMap<*, *>?) {
		if (handle == null || rhmiHandle != handle) {
			throw BMWRemoting.IllegalArgumentException(-1, "Incorrect RHMI handle")
		}
		Log.i(TAG, "rhmi_triggerEvent appId:$rhmiAppId eventId:$eventId args:$args")
		val rhmiAppId = rhmiAppId ?: return
		eventId ?: return
		args ?: return
		val parsedArgs: Map<Int, Any?> = args.filterKeys { it is Number }.mapKeys { (it.key as Number).toInt() }
		rhmiManager.triggerEvent(rhmiAppId, eventId, parsedArgs)
	}

	override fun rhmi_dispose(handle: Int?) {
		Log.i(TAG, "rhmi_dispose")
		if (rhmiHandle != handle) {
			throw BMWRemoting.IllegalArgumentException(-1, "Incorrect RHMI handle")
		}
		val rhmiHandle = rhmiHandle ?: return
		rhmiManager.unregisterAppsByHandle(rhmiHandle)
		rhmiManager.removeActionHandler(rhmiHandle)
		rhmiManager.removeEventHandler(rhmiHandle)
		this.rhmiHandle = null
		this.rhmiAppId = null
		this.rhmiResources.clear()
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