@tool
extends Node2D

## Main.gd
## Root scene script to manage level-specific debug and initialization logic.

@export var debug_color_mode: bool = false:
	set(value):
		debug_color_mode = value
		if Engine.is_editor_hint() or is_inside_tree():
			# Update the singleton state
			SystemManager.dev_mode_color = value
			print("[DEBUG] Editor Color Mode: ", "ENABLED" if value else "DISABLED")

func _ready() -> void:
	# Sync the singleton state on scene load
	SystemManager.dev_mode_color = debug_color_mode
