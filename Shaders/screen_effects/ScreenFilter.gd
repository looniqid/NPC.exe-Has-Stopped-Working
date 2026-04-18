extends ColorRect

## ScreenFilter.gd
## Connects to SystemManager to transition the game's visual state.
## This script should be attached to a ColorRect covering the screen.

func _ready() -> void:
	# Connect to the SystemManager singleton
	if get_tree().root.has_node("SystemManager"):
		var manager = get_tree().root.get_node("SystemManager")
		manager.system_updated.connect(_on_system_updated)
	else:
		push_warning("[SCREEN_FILTER] SystemManager Autoload not found at _ready.")

func _on_system_updated(module_name: String, status: bool) -> void:
	if module_name == "graphics" and status == true:
		_trigger_graphics_restoration_tween()

func _trigger_graphics_restoration_tween() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Priority 1: Shift shader saturation if a ShaderMaterial is present
	if material is ShaderMaterial:
		# Assumes a shader parameter named "saturation" or "intensity"
		# Defaulting to "saturation" as per standard grayscale shader patterns
		tween.tween_property(material, "shader_parameter/saturation", 1.0, 1.5).from(0.0)
	
	# Priority 2: Fallback to fading out the ColorRect (useful for simple B&W overlay)
	else:
		# If no shader, we assume this Rect IS the filter. Fading it out reveals normal color.
		tween.tween_property(self, "modulate:a", 0.0, 1.5).from(1.0)
	
	print("[SCREEN_FILTER] Graphics restoration visual triggered.")
