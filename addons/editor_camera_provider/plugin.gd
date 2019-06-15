tool
extends EditorPlugin

var _camera: Camera


func _enter_tree() -> void:
	var path = self.get_script().get_path()
	add_autoload_singleton("EditorCameraProvider", path)
	set_input_event_forwarding_always_enabled()


# warning-ignore:unused_argument
func handles(obj: Object) -> bool:
    return true


# warning-ignore:unused_argument
func forward_spatial_gui_input(camera: Camera, event: InputEvent) -> bool:
	_camera = camera
	return false


func get_camera() -> Camera:
	return _camera
