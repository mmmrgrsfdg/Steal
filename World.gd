
extends Node3D

@export var player_scene: PackedScene

@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner

func _ready():
	spawner.spawn_path = ".."
	spawner.spawn_function = spawn_player

	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

		# إنشاء لاعب الهوست
		create_player(multiplayer.get_unique_id())


func _on_peer_connected(peer_id: int):
	create_player(peer_id)


func create_player(peer_id: int):
	if not multiplayer.is_server():
		return

	spawner.spawn(peer_id)


func spawn_player(peer_id: int) -> Node:
	var player = player_scene.instantiate()
	player.name = str(peer_id)
	player.set_multiplayer_authority(peer_id, true)
	return player


func _on_peer_disconnected(peer_id: int):
	if not multiplayer.is_server():
		return

	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
