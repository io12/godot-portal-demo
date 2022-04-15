extends RigidBody

const Holdable = preload("res://assets/scripts/Holdable.gd")

const WALK_SPEED = 5.0
const WALK_FORCE = 50.0
const GRAV_ACCEL = 9.8
const JUMP_SPEED = 5.0
const MOUSE_SENSITIVITY = 0.1

# Object the player is currently holding
var held_obj: Holdable = null


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_pressed("use"):
		use_action()


func move_player() -> void:
	# Use down ray to ensure the player is standing
	if Input.is_action_pressed("jump") and $DownRay.is_colliding():
		linear_velocity.y = JUMP_SPEED

	# Apply force to move player

	var dir = Vector3()
	var basis = $Body.get_global_transform().basis

	# Use relative `basis` for movement so it's relative to player direction
	if Input.is_action_pressed("move_fd"):
		dir -= basis.z
	if Input.is_action_pressed("move_bk"):
		dir += basis.z
	if Input.is_action_pressed("move_left"):
		dir -= basis.x
	if Input.is_action_pressed("move_right"):
		dir += basis.x

	var force: Vector3 = dir.normalized() * WALK_FORCE
	add_central_force(force)


# TODO: rename this
func move_held_object(delta):
	if held_obj == null:
		return

	# Drop object if the forward ray is no longer in contact with it
	var collider: PhysicsBody = $Body/Head/ForwardRay.get_collider()
	if collider != held_obj:
		drop_object()


func _physics_process(delta):
	move_player()
	move_held_object(delta)


func pick_up_object() -> void:
	var body = $Body/Head/ForwardRay.get_collider()
	if not body is Holdable:
		return
	body.hold($Body/Head/ObjectHolder)
	held_obj = body


func drop_object() -> void:
	held_obj.drop()
	held_obj = null


# Player inputted the "use" action
func use_action():
	if held_obj == null:
		pick_up_object()
	else:
		drop_object()


func _integrate_forces(state: PhysicsDirectBodyState) -> void:
	# Clamp lateral velocity
	var lin_vel := state.linear_velocity
	var lateral_velocity := Vector2(lin_vel.x, lin_vel.z)
	if lateral_velocity.length() > WALK_SPEED:
		var v := lateral_velocity.normalized() * WALK_SPEED
		state.linear_velocity.x = v.x
		state.linear_velocity.z = v.y


func _input(event):
	if event is InputEventMouseMotion:
		$Body.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		$Body/Head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		$Body/Head.rotation.x = clamp($Body/Head.rotation.x, -PI / 2, PI / 2)
