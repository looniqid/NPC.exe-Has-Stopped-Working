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
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D

var jump_count: int = 0
var is_attacking: bool = false
var has_control: bool = true
const ATTACK_AREA_OFFSET_X: float = 32.0  # Horizontal offset of the AttackArea from center

func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)
	if attack_area:
		attack_area.body_entered.connect(_on_attack_hit)

func _on_attack_hit(body: Node2D):
	if body.has_method("take_damage"):
		body.take_damage()
		print("[PLAYER] Hit ", body.name)

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_on_floor():
		jump_count = 0

	# Handle Jump
	if has_control and interceptor.is_jump_just_pressed():
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

	# Handle Attack
	handle_attack_input()

	# Get horizontal direction from interceptor
	var direction: float = interceptor.get_movement_direction() if has_control else 0.0
	
	# Handle horizontal movement (Locked if attacking)
	if not is_attacking:
		# Apply movement speed penalty if Input system is not fixed
		var current_speed: float = speed
		if not SystemManager.is_input_fixed:
			current_speed *= 0.7
		
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * current_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
	else:
		# Optionally keep some friction or stop immediately
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	move_and_slide()
	
	update_animations()
	
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


func handle_attack_input() -> void:
	if not has_control:
		return
	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		sprite.play("attack")
		if attack_collision:
			attack_collision.set_deferred("disabled", false)

func update_animations() -> void:
	# Gate 1: Action Lock
	if is_attacking:
		return
	
	# Gate 2: Flip Logic + Attack Area synchronization
	if abs(velocity.x) > 0:
		var facing_right: bool = velocity.x > 0
		sprite.flip_h = not facing_right
		# Mirror AttackArea position to match facing direction
		if attack_area:
			attack_area.position.x = ATTACK_AREA_OFFSET_X if facing_right else -ATTACK_AREA_OFFSET_X
	
	# Gate 3: Physics State Priority
	if not is_on_floor():
		sprite.play("jump")
	elif velocity.x != 0:
		sprite.play("walking")
	else:
		sprite.play("idle")

func _on_animation_finished() -> void:
	if sprite.animation == "attack":
		is_attacking = false
		if attack_collision:
			attack_collision.set_deferred("disabled", true)
		# Restore the attack area to the current facing direction after the animation ends
		if attack_area:
			var facing_right: bool = not sprite.flip_h
			attack_area.position.x = ATTACK_AREA_OFFSET_X if facing_right else -ATTACK_AREA_OFFSET_X

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
