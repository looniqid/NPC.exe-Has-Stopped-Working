extends Node

## CheckpointManager.gd
## Handles player position persistence and "glitch" respawn logic.
## Intended to be used as an Autoload (Singleton).

signal signal_pasted

var last_safe_position: Vector2 = Vector2.ZERO

## Saves the current position as the last safe position.
func save_position(pos: Vector2) -> void:
	last_safe_position = pos

## Teleports the player to the last safe position and briefly freezes physics.
func paste_player(player: CharacterBody2D) -> void:
	signal_pasted.emit()
	
	player.global_position = last_safe_position
	
	# "Glitch" freeze: brief physics suspension
	player.set_physics_process(false)
	
	# Wait for 0.2 seconds before re-enabling
	await get_tree().create_timer(0.2).timeout
	
	if is_instance_valid(player):
		player.set_physics_process(true)
