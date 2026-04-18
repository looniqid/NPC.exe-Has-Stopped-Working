extends Node2D
class_name ChaosBuddy

@export var is_active: bool = true
## ChaosBuddy.gd
## Autonomous floating companion that emits localized "chaos" events.

signal chaos_event_triggered(event_type: String)

@export_group("Follow Parameters")
@export var target_node: Node2D
@export var follow_offset: Vector2 = Vector2(0, -50)
@export var follow_speed: float = 5.0

@onready var chaos_timer: Timer = $ChaosTimer

func _ready() -> void:
	# Connect timer signal
	chaos_timer.timeout.connect(_on_timer_timeout)
	
	# Start randomized initial loop
	_start_random_timer()

func _physics_process(delta: float) -> void:
	if is_instance_valid(target_node):
		var target_pos = target_node.global_position + follow_offset
		# Frame-rate independent smooth lerp
		global_position = global_position.lerp(target_pos, follow_speed * delta)

func _start_random_timer() -> void:
	var random_time = randf_range(5.0, 10.0)
	chaos_timer.start(random_time)

func _on_timer_timeout() -> void:
	if not is_active:
		
		return
	# Trigger the chaos event
	chaos_event_triggered.emit("invert")
	
	# Loop with a new random interval
	_start_random_timer()
