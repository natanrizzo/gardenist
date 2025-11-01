extends CharacterBody3D

@export_category("Movement")
var speed := 0.0
@export var walk_speed := 5.0
@export var sprint_speed := 8.0
@export var jump_force := 4.5

@export var gravity := 9.8
@export var sensitivity := 0.01

@export_category("Camera BOB")
@export var bob_freq := 2.0
@export var bob_amp := 0.08
var bob_time = 0.0

@export_category("FOV")
@export var base_fov = 75.0
@export var fov_change = 1.5

@onready var head := $Head
@onready var camera := $Head/Camera3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta: float) -> void:
	move(delta)
	handle_headbob(delta)
	move_and_slide()

func handle_headbob(delta):
	bob_time += delta * velocity.length() * float(is_on_floor())
	head.transform.origin = _headbob(bob_time)

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_freq) * bob_amp
	pos.x = cos(time * bob_freq / 2) * bob_amp
	return pos

func move(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
	
	if Input.is_action_pressed("run"):
		speed = sprint_speed
	else:
		speed = walk_speed
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_foward", "move_backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var velocity_clamped = clamp(velocity.length(), 0.5, sprint_speed * 2)
	var target_fov = base_fov + fov_change * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
