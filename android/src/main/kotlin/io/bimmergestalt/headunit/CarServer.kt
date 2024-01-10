package io.bimmergestalt.headunit

import de.bmw.idrive.BMWRemotingHelper
import de.bmw.idrive.BMWRemotingServer
import de.bmw.idrive.RemoteBMWRemotingClient
import io.bimmergestalt.headunit.managers.AMManager
import io.bimmergestalt.headunit.managers.RHMIManager
import io.flutter.Log
import org.apache.etch.bindings.java.support.ServerFactory
import org.apache.etch.util.core.io.Transport
import java.io.IOException

class CarServer(val host: String = "0.0.0.0", val port: Int = 4006, val amManager: AMManager, val rhmiManager: RHMIManager) {
	private val uri = "tcp://$host:$port?Packetizer.maxPktSize=8388608&TcpTransport.noDelay=true"
	private var listener: BMWRemotingListener? = null
	private var serverFactory: ServerFactory? = null

	fun startServer() {
		if (serverFactory != null) {
			stopServer()
		}
		try {
			val listener = BMWRemotingListener(amManager, rhmiManager)
			this.listener = listener
			val serverFactory = BMWRemotingHelper.newListener(uri, null, listener)
			serverFactory.transportControl(Transport.START, 4000)
			this.serverFactory = serverFactory
		} catch (e: Exception) {
			throw IOException(e)
		}
	}

	fun stopServer() {
		listener?.shutdown()
		listener = null
		serverFactory?.transportControl(Transport.STOP_AND_WAIT_DOWN, 4000)
		serverFactory?.transportControl(Transport.RESET, 4000)
		serverFactory = null
	}

	class BMWRemotingListener(val amManager: AMManager, val rhmiManager: RHMIManager): BMWRemotingHelper.BMWRemotingServerFactory {
		/** Listens for new Etch connections */
		private val connections = ArrayList<RemoteBMWRemotingClient?>()

		override fun newBMWRemotingServer(client: RemoteBMWRemotingClient?): BMWRemotingServer {
			connections.add(client)
			val server = BMWRemotingServerImpl(client!!, amManager, rhmiManager)
			return server
		}

		fun shutdown() {
			connections.forEach {
				try {
					it?._stopAndWaitDown(2000)
				} catch (e: IllegalStateException) {
					// already shut down
//					Log.e("BMWRemoting", "Exception while stopping $it", e)
				}
			}
		}
	}
}