package io.bimmergestalt.headunit

import de.bmw.idrive.BMWRemotingHelper
import de.bmw.idrive.BMWRemotingServer
import de.bmw.idrive.RemoteBMWRemotingClient
import org.apache.etch.bindings.java.support.ServerFactory
import org.apache.etch.util.core.io.Transport
import java.io.IOException

class CarServer(val host: String = "127.0.0.1", val port: Int = 4006, val callbacks: HeadunitCallbacks) {
	private val uri = "tcp://$host:$port?Packetizer.maxPktSize=8388608&TcpTransport.noDelay=true"
	private var serverFactory: ServerFactory? = null

	fun startServer() {
		if (serverFactory != null) {
			return
		}
		try {
			val serverFactory = BMWRemotingHelper.newListener(uri, null, BMWRemotingListener(callbacks))
			serverFactory.transportControl(Transport.START, 4000)
			this.serverFactory = serverFactory
		} catch (e: Exception) {
			throw IOException(e)
		}
	}

	fun stopServer() {
		serverFactory?.transportControl(Transport.STOP, 4000)
		serverFactory = null
	}

	class BMWRemotingListener(val callbacks: HeadunitCallbacks): BMWRemotingHelper.BMWRemotingServerFactory {
		/** Listens for new Etch connections */

		override fun newBMWRemotingServer(client: RemoteBMWRemotingClient?): BMWRemotingServer {
			return BMWRemotingServerImpl(client!!, callbacks);
		}
	}
}