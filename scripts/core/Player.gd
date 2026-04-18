extends CharacterBody2D
class_name Player

## Player.gd
## Main player controller using decoupled input via InputInterceptor.

@export_group("Movement Parameters")
@export var speed: float = 300.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0
@export var jump_velocity: float = -400.0
@export var push_force: float = 80.0

@onready var interceptor: InputInterceptor = $InputInterceptor
@onready var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var jump_count: int = 0

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_on_floor():
		jump_count = 0

	# Handle Jump
	if interceptor.is_jump_just_pressed():
		if is_on_floor():
			velocity.y = jump_velocity
			jump_count = 1
		elif jump_count < 2:
			# Double Jump check
			if SystemManager.is_input_fixed:
				velocity.y = jump_velocity
				jump_count = 2
			else:
				_trigger_glitch_feedback()

	# Get horizontal direction from interceptor
	var direction: float = interceptor.get_movement_direction()
	
	# Apply movement speed penalty if Input system is not fixed
	var current_speed: float = speed
	if not SystemManager.is_input_fixed:
		current_speed *= 0.7
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * current_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	move_and_slide()
	
	# Pushing logic for RigidBody2D objects (like ErrorPopups)
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is RigidBody2D:
			# Apply impulse in the direction of the collision normal
			# Using -normal because normal points towards the player
			collider.apply_central_impulse(-collision.get_normal() * push_force)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact_copy"):
		# Assuming CheckpointManager is registered as an Autoload/Singleton
		if get_tree().root.has_node("CheckpointManager"):
			var manager = get_tree().root.get_node("CheckpointManager")
			manager.save_position(global_position)
		else:
			# Fallback if not yet registered as Autoload (for development/testing)
			push_warning("CheckpointManager Autoload not found.")


func _on_chaos_buddy_chaos_event_triggered(event_type: String) -> void:
	if event_type == "invert":
		if is_instance_valid(interceptor):
			interceptor.is_inverted = not interceptor.is_inverted
			print("Chaos Event: Controls Inverted!" if interceptor.is_inverted else "Chaos Event: Controls Restored!")

func _trigger_glitch_feedback() -> void:
	# Visual "Glitch" feedback (Red modulate for 0.1s)
	modulate = Color.RED
	get_tree().create_timer(0.1).timeout.connect(func(): modulate = Color.WHITE)
	print("ERROR: INPUT.SYS - CAPABILITY_LOCKED [DOUBLE_JUMP]")
