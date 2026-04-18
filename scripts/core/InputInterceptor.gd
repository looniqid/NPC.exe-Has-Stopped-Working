extends Node
class_name InputInterceptor

## InputInterceptor.gd
## Decouples the Player from direct Input calls and handles control modifications.

@export var is_inverted: bool = false
var current_delay_ms: int = 0

# Buffer structure: { "dir": float, "jump": bool, "time": int }
var _input_buffer: Array[Dictionary] = []
var _last_delayed_jump: bool = false

func _physics_process(_delta: float) -> void:
	var current_state = {
		"dir": Input.get_axis("move_left", "move_right"),
		"jump": Input.is_action_pressed("jump"),
		"time": Time.get_ticks_msec()
	}
	_input_buffer.push_back(current_state)
	
	# Cleanup buffer (keep up to 2 seconds of lag)
	if _input_buffer.size() > 120: 
		_input_buffer.pop_front()

## Calculates the horizontal movement direction (-1, 0, or 1).
func get_movement_direction() -> float:
	var target_time = Time.get_ticks_msec() - current_delay_ms
	var direction := 0.0
	
	if current_delay_ms <= 0 or _input_buffer.is_empty():
		direction = Input.get_axis("move_left", "move_right")
	else:
		# Find the latest input that is older than the delay
		for i in range(_input_buffer.size() - 1, -1, -1):
			if _input_buffer[i].time <= target_time:
				direction = _input_buffer[i].dir
				break
				
	if is_inverted:
		direction *= -1.0
	return direction

## Returns true if the jump action was just pressed (with delay applied).
func is_jump_just_pressed() -> bool:
	var target_time = Time.get_ticks_msec() - current_delay_ms
	var current_jump_state := false
	
	if current_delay_ms <= 0:
		return Input.is_action_just_pressed("jump")
	
	if _input_buffer.is_empty():
		return false

	# Find delayed jump state
	for i in range(_input_buffer.size() - 1, -1, -1):
		if _input_buffer[i].time <= target_time:
			current_jump_state = _input_buffer[i].jump
			break
			
	var is_just_pressed = current_jump_state and not _last_delayed_jump
	_last_delayed_jump = current_jump_state
	return is_just_pressed

## Sets or adds to the input delay.
func add_input_delay(seconds: float) -> void:
	current_delay_ms += int(seconds * 1000)
