extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_footstep: AudioStreamPlayer = $SFX_Footstep
@onready var footstep_timer: Timer = $FootstepTimer

var is_attacking: bool = false

var has_control: bool = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta


	if not has_control:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()

		if animated_sprite.animation != "idle" and not is_attacking:
			animated_sprite.play("idle")
		return 



	if Input.is_action_just_pressed("attack") and is_on_floor() and not is_attacking:
		attack()


	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_attacking:
		if Input.is_action_pressed("move_down"):
			position.y += 2
		else:
			velocity.y = JUMP_VELOCITY


	var direction := Input.get_axis("move_left", "move_right")

	if not is_attacking: 
		if direction:
			velocity.x = direction * SPEED
			animated_sprite.flip_h = (direction < 0)
			if is_on_floor() and footstep_timer.is_stopped():
				sfx_footstep.play()      
				footstep_timer.start()
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			
			footstep_timer.stop()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		footstep_timer.stop()

	move_and_slide()
	

	update_animations(direction)


func update_animations(direction):
	if is_attacking:
		return
		
	if not is_on_floor():
		animated_sprite.play("jump")
	elif direction != 0:
		animated_sprite.play("walking")
	else:
		animated_sprite.play("idle")


func attack():
	is_attacking = true
	animated_sprite.play("attack")


func _on_animated_sprite_2d_animation_finished():
	print("animation is: ", animated_sprite.animation) 
	
	if animated_sprite.animation == "attack":
		is_attacking = false
		print("stop attack status！")


func _on_footstep_timer_timeout() -> void:
	if is_on_floor():
		sfx_footstep.play()
