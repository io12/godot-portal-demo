extends StaticBody

const POWERED_COLOR := Color.green
const UNPOWERED_COLOR := Color.darkgray

var wire_powered := false


func recv_power(powered: bool) -> void:
	# Do nothing if the wire is already in the requested state
	if wire_powered == powered:
		return
	var color := POWERED_COLOR if powered else UNPOWERED_COLOR
	$MeshInstance.get_surface_material(0).albedo_color = color
	wire_powered = powered
	send_power(powered)


func send_power(powered: bool) -> void:
	var bodies: Array = ($PowerConnectorA.get_overlapping_bodies()
			+ $PowerConnectorB.get_overlapping_bodies())
	for body in bodies:
		if body.has_method("recv_power"):
			body.recv_power(powered)
