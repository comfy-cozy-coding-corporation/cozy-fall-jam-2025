extends CanvasLayer

@onready var pause_overlay = %PauseOverlay

func _process(_delta: float) -> void:
	if pause_overlay.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
