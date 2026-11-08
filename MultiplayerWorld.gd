extends Node3D

@onready var ip_label = $ui/ip_adress_label
@onready var ip_addres = $ui/ip_addres
@onready var ui = $ui
const Player = preload("res://Player/player.tscn")
func _ready() -> void:

	# انتظار بدء الجلسة
	Server.session_started.connect(_on_session_started)

	# استقبال أخطاء الاتصال
	Server.join_failed.connect(_on_join_failed)

	# انتظار الاتصال بـ Noray
	await Server.noray_connected

	ip_label.text = Noray.oid


# زر Host
func _on_host_pressed() -> void:

	Server.host()


# زر Join
func _on_join_pressed() -> void:

	Server.join(ip_addres.text)


# زر Share IP
func _on_share_ip_pressed() -> void:

	DisplayServer.clipboard_set(Noray.oid)


# عند بدء الجلسة بنجاح
func _on_session_started() -> void:

	print("Entering world...")
	get_tree().change_scene_to_file("res://test.tscn")


# عند فشل الاتصال
func _on_join_failed() -> void:
	
	print("Could not connect to host!")


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://tt.tscn")
		
