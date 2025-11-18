extends CharacterBody3D

@onready var head := $Head
@onready var camera := $Head/Camera3D
@onready var hand_target: Marker3D = $Head/HandTarget

@export_category("Movement")
var speed := 0.0
@export var walk_speed := 5.0
@export var sprint_speed := 8.0
@export var jump_force := 4.5

@export var gravity := 9.8
@export var sensitivity := 0.005

@export_category("Camera BOB")
@export var bob_freq := 2.0
@export var bob_amp := 0.08
var bob_time = 0.0

@export_category("FOV")
@export var base_fov := 75.0
@export var fov_change := 1.5

@export_category("Construction")
@export var grid_size := 0.25
var ghost_block: Node3D = null
var objects : Array[Node3D] = []
var cur_obj_idx = 0
@export var ghost_block_ofset := 1.0 # Global position -= this value.

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta: float) -> void:
	move(delta)
	
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
	
	handle_headbob(delta)
	
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
	
	move_and_slide()

func handle_headbob(delta):
	bob_time += delta * velocity.length() * float(is_on_floor())
	head.transform.origin = _headbob(bob_time)

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_freq) * bob_amp
	pos.x = cos(time * bob_freq / 2) * bob_amp
	return pos

func spawn_ghost_block():
	ghost_block = objects[cur_obj_idx].instantiate()
	get_parent().add_child(ghost_block)
	ghost_block.global_position = self.global_position
	ghost_block.global_position.y -= ghost_block_ofset

func snap_to_grid(pos: Vector3, grid_snap: float) -> Vector3:
	var x = round(pos.x / grid_snap) * grid_size
	var y = round(pos.y / grid_snap) * grid_size
	var z = round(pos.z / grid_snap) * grid_size
	return Vector3(x, y, z)

func building(delta: float):
	var snap_pos: Vector3 = snap_to_grid(hand_target.global_position, grid_size)
	
	pass
