class_name CameraLockUI extends TextureRect

@export var texture_locked: Texture2D
@export var texture_unlocked: Texture2D

var camera_locked: bool = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.button_mask == 1:  # Pressed
				camera_locked = not camera_locked
				%TextureLock.texture = texture_locked if camera_locked else texture_unlocked
				Locomotive.instance.set_camera_locked(camera_locked)
