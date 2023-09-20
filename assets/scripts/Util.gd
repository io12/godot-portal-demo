# Static class (namespace) with utility functions

# Dampen the length of a vector if it is above a maximum
static func dampen_vector(vec: Vector3, max_len: float) -> Vector3:
	if vec.length() > max_len:
		return vec.normalized() * max_len
	else:
		return vec
