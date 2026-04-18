extends Area2D
class_name Installer

## Installer.gd
## A collectible item that restores system modules (Graphics, Audio, Input).

@export_enum("graphics", "audio", "input") var module_type: String = "graphics"

@export_group("Animation Parameters")
@export var hover_amplitude: float = 10.0
@export var hover_speed: float = 2.0
@export var collection_chime: AudioStream

@onready var sprite: Sprite2D = $Sprite2D
@onready var initial_y: float = 0.0

func _ready() -> void:
	if is_instance_valid(sprite):
		initial_y = sprite.position.y
		
	# Connect signal for collection
	body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	# Smooth floating animation using sine wave
	if is_instance_valid(sprite):
		var time = Time.get_ticks_msec() * 0.001
		sprite.position.y = initial_y + sin(time * hover_speed) * hover_amplitude

func _on_body_entered(body: Node2D) -> void:
	# Verify pickup criteria
	if body.is_in_group("player"):
		_collect()

func _collect() -> void:
	print("[INSTALLER] Picking up module: " + module_type)
	
	# Interact with SystemManager singleton
	if get_tree().root.has_node("SystemManager"):
		var manager = get_tree().root.get_node("SystemManager")
		
		if module_type == "graphics":
			manager.fix_graphics_visuals()
		elif module_type == "input":
			manager.is_input_fixed = true
			manager.repair_input()
		elif module_type == "audio":
			manager.is_audio_fixed = true
			manager.restore_audio_systems()
			# Play high-quality chime (special case that bypasses initial silence)
			if collection_chime:
				manager.play_system_sound(collection_chime)
		else:
			manager.install_module(module_type)
	else:
		push_error("[INSTALLER] SystemManager not found during collection.")
		
	# Feedback: Spawn effect (particles or label)
	# For now, we instantiate a simple feedback string if possible, or just particles
	_spawn_feedback()
	
	# Self-destruct
	queue_free()

func _spawn_feedback() -> void:
	# Implementation of a simple "burst" effect placeholder
	if has_node("CPUParticles2D"):
		var particles: CPUParticles2D = $CPUParticles2D
		# Explode current location then remove
		# We need to reparent to world so it doesn't free with us immediately, or use top-level
		particles.reparent(get_parent())
		particles.emitting = true
		# Particles will free themselves if set to one_shot and finished (manually or via script)
		# For simplicity here, we assume one_shot is set in scene.
