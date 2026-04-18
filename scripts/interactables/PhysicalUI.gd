extends RigidBody2D
class_name PhysicalUI

## PhysicalUI.gd
## Implements physics-based UI elements that can be pushed or broken.

@export_group("Physics Parameters")
@export var push_force_factor: float = 100.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var platform: AnimatableBody2D = get_node("../platform")

var _platform_offset: Vector2

func _ready() -> void:
	# Keep the UI element axis-aligned
	lock_rotation = true
	# Define behavior when explicitly frozen
	freeze_mode = FREEZE_MODE_KINEMATIC
	
	# Ensure the UI is on a layer the player can interact with
	# (Typically Layer 2 if Player is on Layer 1)
	collision_layer = 2
	collision_mask = 3 # Collide with world (1) and player (2)
	
	# Initial offset calculation for frame-perfect child synchronization
	if is_instance_valid(platform):
		_platform_offset = platform.global_position - global_position

func _physics_process(_delta: float) -> void:
	# Force platform synchronization in the physics tick to eliminate one-frame delays
	if is_instance_valid(platform):
		platform.global_position = global_position + _platform_offset

## Interaction API called by external systems or player contact
func apply_push_force(force: Vector2) -> void:
	apply_central_impulse(force * push_force_factor)

## Destruction logic: swaps visual state and disables interaction
func break_ui() -> void:
	# Swap to a broken placeholder (red-tinted)
	var broken_texture = PlaceholderTexture2D.new()
	broken_texture.size = Vector2(64, 32) # Standard popup size
	
	if is_instance_valid(sprite):
		sprite.texture = broken_texture
		sprite.modulate = Color(1.0, 0.2, 0.2, 0.8) # Red tint
	
	# Disable interaction by moving to a background layer and disabling shape
	collision_layer = 0
	collision_mask = 1 # Only collide with world/floor
	
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)
	
	print("Physical UI broken.")
