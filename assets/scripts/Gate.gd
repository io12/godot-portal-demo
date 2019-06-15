extends Spatial

var timer := 0.0
var opening := false
onready var orig_transform: Transform = $Door.transform


func _physics_process(delta: float) -> void:
	timer = min(timer + delta, 1.0)
	var door_height := timer
	if opening:
		door_height = 1.0 - door_height
	var trans := orig_transform.scaled(Vector3(1.0, door_height, 1.0))
	var orig_y := orig_transform.origin.y
	trans.origin.y = orig_y * (2.0 - door_height)
	$Door.transform = trans

	# If the door is opened fully, don't render the mesh (prevents issues)
	if trans.origin.y >= 1.99 * orig_y:
		$Door.visible = false
	else:
		$Door.visible = true


func recv_power(powered: bool) -> void:
	timer = 1.0 - timer
	opening = powered
