extends Camera3D

@export var move_speed := 10.0
@export var rotation_speed := 0.005

var rotating := false
var yaw := 0.0
var pitch := 0.0


func _ready():
	yaw = rotation.y
	pitch = rotation.x


func _process(delta):
	var direction := Vector3.ZERO

	if Input.is_key_pressed(KEY_W):
		direction.z -= 1

	if Input.is_key_pressed(KEY_S):
		direction.z += 1

	if Input.is_key_pressed(KEY_A):
		direction.x -= 1

	if Input.is_key_pressed(KEY_D):
		direction.x += 1

	if Input.is_key_pressed(KEY_SPACE):
		direction.y += 1

	if Input.is_key_pressed(KEY_SHIFT):
		direction.y -= 1

	if direction != Vector3.ZERO:
		direction = direction.normalized()

		var movement := global_transform.basis * direction
		global_position += movement * move_speed * delta


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			rotating = event.pressed

	if event is InputEventMouseMotion and rotating:
		yaw -= event.relative.x * rotation_speed
		pitch -= event.relative.y * rotation_speed

		rotation = Vector3(
			pitch,
			yaw,
			0.0
		)
