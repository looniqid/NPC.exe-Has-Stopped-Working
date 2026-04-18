@tool
extends Node

## SystemManager.gd
## Central status singleton for managing game system modules (Graphics, Audio, Input).

signal system_updated(module_name: String, status: bool)

var modules: Dictionary = {
	"graphics": false,
	"audio": false,
	"input": false
}

var is_graphics_fixed: bool = false
var is_input_fixed: bool = false
var is_audio_fixed: bool = false
var is_graphics_fixed_running: bool = false

@export var dev_mode_color: bool = false:
	set(value):
		dev_mode_color = value
		update_environment_visuals()

@export_group("Audio Resources")
@export var clean_bgm_stream: AudioStream
@export var glitch_bgm_stream: AudioStream
@export var crash_sfx_stream: AudioStream


var env_node_cache: WorldEnvironment = null

@onready var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
var bgm_normal: AudioStreamPlayer = null
var bgm_glitch: AudioStreamPlayer = null
var is_restoring_audio: bool = false


func _ready() -> void:
	# Initialize global SFX player
	if not Engine.is_editor_hint():
		add_child(sfx_player)
		sfx_player.bus = "Master"
		sfx_player.name = "GlobalSFXPlayer"
		
		# Specialized BGM Players
		bgm_normal = AudioStreamPlayer.new()
		bgm_normal.name = "BGM_Normal"
		bgm_normal.stream = clean_bgm_stream
		bgm_normal.bus = "Master"
		add_child(bgm_normal)
		
		bgm_glitch = AudioStreamPlayer.new()
		bgm_glitch.name = "BGM_Glitch"
		bgm_glitch.stream = glitch_bgm_stream
		bgm_glitch.bus = "Master"
		bgm_glitch.volume_db = -80.0 # Start muted
		add_child(bgm_glitch)
		
		# Start with clean BGM (Intro state)
		if clean_bgm_stream:
			bgm_normal.play()
	
	update_environment_visuals()

## Installs a module and broadcasts the status change.
func install_module(module_name: String) -> void:
	if not modules.has(module_name):
		push_warning("[SYSTEM] Attempted to install unknown module: " + module_name)
		return
		
	modules[module_name] = true
	
	# Sync the boolean flags
	match module_name:
		"graphics": is_graphics_fixed = true
		"input": is_input_fixed = true
		"audio": is_audio_fixed = true
		
	system_updated.emit(module_name, true)
	print("[SYSTEM] Module " + module_name + " installed.")
	
	update_environment_visuals()

## Returns whether a specific module is installed/fixed.
func is_module_installed(module_name: String) -> bool:
	return modules.get(module_name, false)

func update_environment_visuals():
	# Defensive check for scene tree access
	if not is_inside_tree():
		return
		
	var root_node = null
	if Engine.is_editor_hint():
		root_node = get_tree().edited_scene_root
	else:
		root_node = get_tree().root
		
	if not root_node:
		return

	# Re-validate cache or find node
	if not is_instance_valid(env_node_cache):
		env_node_cache = root_node.find_child("WorldEnvironment", true, false) as WorldEnvironment
	
	if env_node_cache and env_node_cache.environment:
		if dev_mode_color:
			env_node_cache.environment.adjustment_saturation = 1.0
		else:
			# If the module is fixed, saturation is 1.0, otherwise 0.0
			env_node_cache.environment.adjustment_saturation = 1.0 if is_graphics_fixed else 0.0
	else:
		# If we can't find it yet, clear cache to try again later
		env_node_cache = null

## Dynamically finds the WorldEnvironment and restores saturation via a smooth transition.
func fix_graphics_visuals() -> void:
	# Guard clause: prevent multiple triggers during transition
	if is_graphics_fixed_running or is_graphics_fixed:
		return
	
	# Attempt to find the environment
	update_environment_visuals() # This ensures env_node_cache is populated
	
	if is_instance_valid(env_node_cache) and env_node_cache.environment:
		is_graphics_fixed_running = true
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		
		# Animate saturation from current state (usually 0.0) to 1.0
		tween.tween_property(env_node_cache.environment, "adjustment_saturation", 1.0, 1.5)
		
		# Finalize state once animation finishes
		tween.finished.connect(func():
			is_graphics_fixed = true
			is_graphics_fixed_running = false
			update_environment_visuals()
			print("[SYSTEM] Graphics transition complete.")
		)
		
		print("[SYSTEM] Graphics visuals restoration tween started.")
	else:
		# Fallback if no environment found
		is_graphics_fixed = true
		update_environment_visuals()
		push_warning("[SYSTEM] fix_graphics_visuals could not find a valid environment for tweening.")
	
	# Emit signal to notify other filters
	system_updated.emit("graphics", true)

## Repairs the input module and enables the double jump capability.
func repair_input() -> void:
	is_input_fixed = true
	system_updated.emit("input", true)
	print("[SYSTEM] INPUT.SYS REPAIRED: DOUBLE JUMP ENABLED")

## Plays a sound only if the audio system is repaired.
func play_system_sound(stream: AudioStream) -> void:
	if is_audio_fixed and is_instance_valid(stream):
		sfx_player.stream = stream
		sfx_player.play()
	else:
		# Silence or static fallback (if implemented)
		pass

## Swaps the game from the main theme to the glitched/corrupted state.
func trigger_system_crash() -> void:
	if is_instance_valid(bgm_normal):
		bgm_normal.stop()
	
	# Play crash SFX once
	if is_instance_valid(crash_sfx_stream):
		sfx_player.stream = crash_sfx_stream
		sfx_player.play()
	
	# Start looping glitch background
	if is_instance_valid(bgm_glitch):
		bgm_glitch.volume_db = 0.0
		bgm_glitch.play()
	
	is_audio_fixed = false
	print("[SYSTEM] CRITICAL ERROR: INPUT.sys/AUDIO.dll integrity check failed.")

## Professional cross-fade from glitched ambiance back to restored theme.
func fix_audio_visuals() -> void:
	# Guard clause: prevent overlapping restorations
	if is_restoring_audio or is_audio_fixed:
		return
		
	is_restoring_audio = true
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Cross-fade logic (2.0 seconds)
	if is_instance_valid(bgm_glitch):
		tween.tween_property(bgm_glitch, "volume_db", -80.0, 2.0)
	
	if is_instance_valid(bgm_normal):
		bgm_normal.volume_db = -80.0
		bgm_normal.play()
		tween.tween_property(bgm_normal, "volume_db", 0.0, 2.0)
	
	# Finalize state once cross-fade completes
	tween.chain().finished.connect(func():
		is_audio_fixed = true
		is_restoring_audio = false
		if is_instance_valid(bgm_glitch):
			bgm_glitch.stop()
		print("[SYSTEM] Audio stabilization successful.")
	)
	
	# Notify other potential listeners (UI, etc.)
	system_updated.emit("audio", true)
