#tool
extends Node

onready var portals := [$PortalA, $PortalB]
onready var links := {
	$PortalA: $PortalB,
	$PortalB: $PortalA,
}

# Dictionary between regular bodies and their clones
var clones := {}


func init_portal(portal: Node) -> void:
	# TODO: Update comment
	# Connect the mesh material shader to the viewport of the linked portal
	var viewport: Viewport = portal.get_node("Viewport")
	var tex := viewport.get_texture()
	var mat = portal.get_node("MeshInstance").material_override
	mat.set_shader_param("texture_albedo", tex)


# Init portals
func _ready() -> void:
	for portal in portals:
		init_portal(portal)


func get_camera() -> Camera:
	#if Engine.is_editor_hint():
		#return get_node("/root/EditorCameraProvider").get_camera()
	#else:
	return get_viewport().get_camera()


# Project a point onto a portal plane, returning the projected point
func project_portal_plane(portal: Spatial, point: Vector3) -> Vector3:
	var p_trans := portal.global_transform
	var p_pos := p_trans.origin
	var p_norm := p_trans.basis.z
	var plane := Plane(p_norm, p_pos.dot(p_norm))
	return plane.project(point)


# Move the camera to a location near the linked portal; this is done by
# taking the position of the player relative to the linked portal, and
# rotating it pi radians
func move_camera(portal: Spatial) -> void:
	var linked: Spatial = links[portal]
	var trans: Transform = portal.global_transform.inverse() \
		* get_camera().global_transform
	var up := Vector3(0, 1, 0)
	trans = trans.rotated(up, PI)
	trans = linked.global_transform * trans
	portal.get_node("CameraHolder").global_transform = trans
	var cam_trans: Transform = portal.get_node("CameraHolder").global_transform
	var proj := project_portal_plane(linked, cam_trans.origin)
	up = -linked.global_transform.basis.y
	cam_trans = cam_trans.looking_at(proj, up)
	portal.get_node("Viewport/Camera").global_transform = cam_trans


# Use an oblique near plane to prevent anything behind a portal from being
# visible through the linked portal
#
# TODO: Handle other camera modes
func update_near_plane(portal: Spatial) -> void:
	var linked: Spatial = links[portal]
	var viewport: Viewport = linked.get_node("Viewport")
	var cam: Camera = viewport.get_node("Camera")
	var p_trans := portal.global_transform
	var p_pos := p_trans.origin
	var cam_pos := cam.global_transform.origin

	var proj_pos := project_portal_plane(portal, cam_pos)
	var near := proj_pos.distance_to(cam_pos)
	var off_3d: Vector3 = p_trans.xform_inv(cam_pos)
	var off := Vector2(-off_3d.x, off_3d.y)
	var size = portal.get_node("MeshInstance").mesh.size.x
	cam.set_frustum(size, off, near, 1000.0)


# Get the vertices of a portal screen (in local coords)
func get_portal_verts(portal: Spatial) -> PoolVector3Array:
	var meshinst: MeshInstance = portal.get_node("MeshInstance")
	var mesh := meshinst.mesh
	var verts := mesh.get_faces()
	assert verts.size() == 6
	return verts


# Get the resolution of a portal screen
func get_portal_res(portal: Spatial) -> float:
	var verts := get_portal_verts(portal)
	var cam := get_camera()

	var first: Vector2 = cam.unproject_position(verts[0])

	var max_x := first.x
	var min_x := first.x
	var max_y := first.y
	var min_y := first.y

	for vert in verts:
		# Transform to world coords
		vert = portal.global_transform.xform(vert)
		# Transform to screen coords
		vert = cam.unproject_position(vert)
		max_x = max(vert.x, max_x)
		min_x = min(vert.x, min_x)
		max_y = max(vert.y, max_y)
		min_y = min(vert.y, min_y)

	var delta_x := max_x - min_x
	var delta_y := max_y - min_y

	return max(delta_x, delta_y)


# Sync the viewport size with the window size
func sync_viewport(portal: Spatial) -> void:
	var linked: Spatial = links[portal]
	var viewport: Viewport = portal.get_node("Viewport")
	var linked_viewport: Viewport = linked.get_node("Viewport")
	var res := max(get_portal_res(portal), get_portal_res(linked))
	var size := Vector2(res, res)
	print(res)
	viewport.size = size
	linked_viewport.size = size


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	# TODO: figure out why this is needed
	if Engine.is_editor_hint():
		if get_camera() == null:
			return
		_ready()

	for portal in portals:
		move_camera(portal)
		update_near_plane(portal)
		sync_viewport(portal)


# Return whether the position is in front of a portal
func in_front_of_portal(portal: Node, pos: Transform) -> bool:
	var portal_pos = portal.global_transform
	return portal_pos.xform_inv(pos.origin).z < 0


# Swap the velocities and positions of a body and its clone
func swap_body_clone(body: RigidBody, clone: RigidBody) -> void:
	body.sleeping = true
	clone.sleeping = true
	var body_pos := body.global_transform
	var clone_pos := clone.global_transform
	var body_vel: Vector3 = body.linear_velocity
	var clone_vel: Vector3 = clone.linear_velocity
	clone.global_transform = body_pos
	clone.linear_velocity = body_vel
	body.global_transform = clone_pos
	body.linear_velocity = clone_vel


func handle_body_overlap_portal(portal: Node, body: PhysicsBody) -> void:
	var linked: Node = links[portal]

	var body_pos := body.global_transform
	var portal_pos = portal.global_transform
	var linked_pos = linked.global_transform
	var up := Vector3(0, 1, 0)

	# Position of body relative to portal
	var rel_pos = portal_pos.inverse() * body_pos

	var clone: PhysicsBody
	if body in clones.keys():
		clone = clones[body]
	elif body in clones.values():
		return
	else:
		clone = body.duplicate(0)
		clone.mode = RigidBody.MODE_KINEMATIC
		clones[body] = clone
		add_child(clone)
		clone.linear_velocity = clone.linear_velocity.rotated(up, PI)

	clone.global_transform = linked_pos \
		* rel_pos.rotated(up, PI)

	# Swap clone and actual if the actual object is more than halfway through 
	# the portal
	if not in_front_of_portal(portal, body_pos):
		swap_body_clone(body, clone)


# warning-ignore:unused_argument
func _physics_process(delta: float) -> void:
	# Don't handle physics while in the editor
	if Engine.is_editor_hint():
		return

	# Check for bodies overlapping portals
	for portal in portals:
		for body in portal.get_node("Area").get_overlapping_bodies():
			handle_body_overlap_portal(portal, body)


func handle_body_exit_portal(portal: Node, body: PhysicsBody) -> void:
	if not body in clones:
		return
	var clone: Node = clones[body]
	clones.erase(body)
	clone.queue_free()


func _on_portal_a_body_exited(body: PhysicsBody) -> void:
	handle_body_exit_portal($PortalA, body)


func _on_portal_b_body_exited(body: PhysicsBody) -> void:
	handle_body_exit_portal($PortalB, body)
