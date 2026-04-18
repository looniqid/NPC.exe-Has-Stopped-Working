extends Node2D
@export var debug_color_mode: bool:
	set(value):
		debug_color_mode = value
		if SystemManager:
			SystemManager.dev_mode_color = value

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
