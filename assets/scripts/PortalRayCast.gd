extends RayCast
class_name PortalRayCast

# Dictionary storing information about the current collision, in the format
# returned by PhysicsDirectSpaceState.intersect_ray(). The exception is an
# additional field `through_portal`, a `bool` describing whether the ray
# teleported through a portal.
var _collision_info := {}


# This basically calls PhysicsDirectSpaceState.intersect_ray(), but using our
# member variables for config. The only exception is it always collides with
# areas. Note that this function ignores portals. The returned dictionary is
# of the format returned by PhysicsDirectSpaceState.intersect_ray().
func _basic_cast_ray(from: Vector3, to: Vector3) -> Dictionary:
	var space_state := get_world().direct_space_state
	var exclude := []
	var parent := get_parent()
	if parent is PhysicsBody and exclude_parent:
		exclude.append(parent)

	return space_state.intersect_ray(from, to, exclude, collision_mask,
			collide_with_bodies, true)


# Same as _basic_cast_ray(), but it uses the RayCast position and `cast_to` and
# properly handles portals. If a portal intersects the ray, the raycasting
# continues at the other portal.
# TODO: fix this
func _get_collision_info() -> Dictionary:
	var start_pos := global_transform.origin
	var end_pos = global_transform.xform(cast_to)
	var through_portal := false
	while true:
		var info := _basic_cast_ray(start_pos, end_pos)
		if info.empty():
			# No collisions; we are done!
			break

		info.through_portal = through_portal
		if not info.collider.is_in_group('portal_area'):
			# No collision with portal; we are done!
			return info

		# RayCast intersected portal, continue raycasting out the other end
		through_portal = true
		var portal = info.collider.get_parent()
		var portal_pair = portal.get_parent()
		var linked = portal_pair.links[portal]
		var portal_pos = portal.global_transform
		# Transform from one portal to the other
		var dist = portal_pos.inverse() * linked.global_transform
		start_pos = dist.xform(info.position)
		# TODO: make sure this is right (it probably isn't)
		var up = portal_pos.basis.y
		end_pos = dist.xform((end_pos - info.position).rotated(up, PI))

	return {}


func force_raycast_update() -> void:
	_collision_info = _get_collision_info()


func _physics_process(delta: float) -> void:
	force_raycast_update()


# Somewhat-safe dictionary lookup function; if the dict is empty, a default
# value is returned
func _dict_or(dict: Dictionary, field: String, default_val):
	if dict.empty():
		return default_val
	else:
		return dict[field]


func _collision_field_or(field: String, default_val):
	return _dict_or(_collision_info, field, default_val)


func get_collider() -> Object:
	return _collision_field_or("collider", null)


func get_collider_shape() -> int:
	return _collision_field_or("shape", 0)


func get_collision_normal() -> Vector3:
	return _collision_field_or("normal", Vector3())


func get_collision_point() -> Vector3:
	return _collision_field_or("position", Vector3())


func is_colliding() -> bool:
	return not _collision_info.empty()


func through_portal() -> bool:
	return _collision_field_or("through_portal", false)
