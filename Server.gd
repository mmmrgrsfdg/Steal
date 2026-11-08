
extends Node

# الإشارات
signal noray_connected
signal session_started
signal join_failed

# إعدادات Noray
const NORAY_ADDRESS = "tomfol.io"
const NORAY_PORT = 8890

# حالة الاتصال
var is_host = false
var external_oid = ""


func _ready():
	Noray.on_connect_to_host.connect(on_noray_connected)
	Noray.on_connect_nat.connect(handle_nat_connection)
	Noray.on_connect_relay.connect(handle_relay_connection)

	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

	Noray.connect_to_host(NORAY_ADDRESS, NORAY_PORT)


# الاتصال بـ Noray
func on_noray_connected():
	print("Connected to Noray server")

	Noray.register_host()

	await Noray.on_pid

	await Noray.register_remote()

	print("Noray registration completed")

	noray_connected.emit()


# إنشاء السيرفر
func host():
	print("Hosting")

	var peer = ENetMultiplayerPeer.new()

	var err = peer.create_server(Noray.local_port)

	if err != OK:
		print("Host failed: ", err)
		return

	multiplayer.multiplayer_peer = peer
	is_host = true

	print("Server created successfully")

	session_started.emit()


# الانضمام للسيرفر
func join(oid):
	print("Joining: ", oid)

	is_host = false
	external_oid = oid

	Noray.connect_nat(oid)


# نجاح اتصال العميل
func _on_connected_to_server():
	print("Connected to host!")

	session_started.emit()


# فشل اتصال العميل
func _on_connection_failed():
	print("Connection failed!")

	join_failed.emit()


# اتصال NAT
func handle_nat_connection(address, port):
	print("=== NAT SIGNAL ===")
	print("Is Host: ", is_host)
	print("Address: ", address, " Port: ", port)

	var err = await connect_to_server(address, port)

	print("NAT Handshake Result: ", err)

	if err != OK and !is_host:
		print("NAT failed, requesting RELAY")
		Noray.connect_relay(external_oid)

	return err


# اتصال Relay
func handle_relay_connection(address, port):
	print("=== RELAY SIGNAL ===")
	print("Is Host: ", is_host)
	print("Relay Address: ", address, " Port: ", port)

	var err = await connect_to_server(address, port)

	print("RELAY Handshake Result: ", err)

	return err


# إنشاء اتصال ENet
func connect_to_server(address, port):
	print("=== CONNECT TO SERVER ===")
	print("Is Host: ", is_host)
	print("Local Port: ", Noray.local_port)

	if !is_host:

		var udp = PacketPeerUDP.new()

		var bind_err = udp.bind(Noray.local_port)

		print("UDP Bind Result: ", bind_err)

		if bind_err != OK:
			udp.close()
			return bind_err

		udp.set_dest_address(address, port)

		var err = await PacketHandshake.over_packet_peer(udp)

		udp.close()

		print("Client Handshake: ", err)

		if err != OK and err != ERR_BUSY:
			return err

		var peer = ENetMultiplayerPeer.new()

		err = peer.create_client(
			address,
			port,
			0,
			0,
			0,
			Noray.local_port
		)

		print("ENet Client Result: ", err)

		if err != OK:
			return err

		multiplayer.multiplayer_peer = peer

		return OK

	else:

		print("Host starting ENet handshake")

		var peer = multiplayer.multiplayer_peer as ENetMultiplayerPeer

		var err = await PacketHandshake.over_enet(
			peer.host,
			address,
			port
		)

		print("Host Handshake Result: ", err)

		return err
