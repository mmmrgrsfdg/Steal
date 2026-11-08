
extends CharacterBody3D

@export var SPEED = 2.0
@export var gravity = 20.0

const LERP_VAL = 0.15
const JUMP_VELOCITY = 5.5


@export var camera_sensitivity = 0.005
@export var min_pitch = -60.0
@export var max_pitch = 60.0


@onready var spring_arm = $SpringArm3D
@onready var camera = $SpringArm3D/Camera3D
@onready var joystick = $ui/VirtualJoystick
@onready var jump_button = $ui/JumpButton
@onready var canvas = $ui
@onready var armature = $head

var camera_pitch: float = 0.0


func _ready():
	if is_multiplayer_authority():
		camera.current = true
		canvas.show()
	else:
		camera.current = false
		canvas.hide()



func _physics_process(delta):
	if not is_multiplayer_authority():
		return

	# الجاذبية
	if not is_on_floor():
		velocity.y -= gravity * delta

	# القفز
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# قراءة الجويستك
	var input_dir = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
        "move_back"
	)

	# نفس طريقة الحركة من المشروع الثاني
	var direction = (
		transform.basis *
		Vector3(input_dir.x, 0.0, input_dir.y)
	).normalized()

	direction = direction.rotated(
		Vector3.UP,
		spring_arm.rotation.y
	)

	# الحركة والدوران
	if direction:
		velocity.x = lerp(
			velocity.x,
			direction.x * SPEED,
			LERP_VAL
		)

		velocity.z = lerp(
			velocity.z,
			direction.z * SPEED,
			LERP_VAL
		)

		armature.rotation.y = lerp_angle(
			armature.rotation.y,
			atan2(-velocity.x, -velocity.z),
			LERP_VAL
		)
	else:
		velocity.x = lerp(velocity.x, 0.0, LERP_VAL)
		velocity.z = lerp(velocity.z, 0.0, LERP_VAL)

	move_and_slide()


func _input(event):
	if not is_multiplayer_authority():
		return

	# دوران الكاميرا باللمس
	if event is InputEventScreenDrag:
		var screen_size = get_viewport().get_visible_rect().size

		if event.position.x > screen_size.x * 0.4:
			rotate_camera(event.relative)


func rotate_camera(relative: Vector2):
	camera_pitch -= relative.y * camera_sensitivity

	camera_pitch = clampf(
		camera_pitch,
		deg_to_rad(min_pitch),
		deg_to_rad(max_pitch)
	)

	spring_arm.rotation.x = camera_pitch
	spring_arm.rotation.y -= relative.x * camera_sensitivity


func _on_button_pressed() -> void:
	$ui/Label.text = "BUTTON PRESSED"

	if is_multiplayer_authority():
		$ui/Label.text += "\nAUTHORITY: YES"
	else:
		$ui/Label.text += "\nAUTHORITY: NO"

	$ui/Label.text += "\nID: " + str(multiplayer.get_unique_id())
	$ui/Label.text += "\nPLAYER: " + str(name)
	
