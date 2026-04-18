extends CharacterBody2D

## BlackWolf.gd
## Boss wolf enemy with state machine AI, pounce attack, and frame-accurate hitbox.

enum State { IDLE, CHASE, ATTACK, HIT, DEATH }
var current_state: State = State.IDLE

@export_group("Movement")
@export var speed: float = 150.0
@export var slowdown_radius_multiplier: float = 1.5  # fraction of attack_range where wolf slows

@export_group("Combat")
@export var health: int = 3
@export var attack_range: float = 60.0
@export var lunge_speed: float = 280.0   # forward burst speed during pounce
@export var lunge_duration: float = 0.15  # seconds of lunge impulse

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $HitBox
@onready var hitbox_shape: CollisionShape2D = $HitBox/CollisionShape2D
@onready var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

var _sprite_default_pos: Vector2  # Cached on _ready for clean restore

# ─── Attack State ────────────────────────────────────────────────────────────
## is_attacking is the MASTER flag — all movement/chase logic defers to it.
var is_attacking: bool = false
var _hit_landed: bool = false        # Prevents double-hits in a single swing
var _attack_timer: float = 0.0
var _lunge_timer: float = 0.0
var _lunge_dir: float = 0.0          # +1 right, -1 left
var _attack_cooldown: float = 0.0

const ATTACK_DURATION: float = 0.9
const ATTACK_COOLDOWN: float = 1.2
const HITBOX_ACTIVE_AFTER: float = 0.3  # Seconds into attack before hitbox activates

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED

	# ── Collision layer setup ─────────────────────────────────────────────────
	# Wolf body: layer 1 (floor) + layer 3 (so Player's AttackArea mask=4 can hit it)
	collision_layer = 1 | 4   # = 5
	collision_mask  = 1       # Only collide with floor (layer 1)

	# HitBox must detect the Player which is on collision_layer 2
	hitbox.collision_layer = 0  # Area2D doesn't need its own layer
	hitbox.collision_mask  = 2  # Detect layer 2 (Player body)

	hitbox_shape.set_deferred("disabled", true)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	sprite.animation_finished.connect(_on_animation_finished)
	_sprite_default_pos = sprite.position  # Cache sprite default position
	print("[WOLF] Ready — body_layer=", collision_layer,
			" | HitBox_mask=", hitbox.collision_mask)

# ─── Physics Loop ─────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	# Always apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Tick cooldown
	if _attack_cooldown > 0:
		_attack_cooldown -= delta

	# ── MASTER FLAG: skip all movement when attacking ──
	if is_attacking:
		_run_attack(delta)
		return

	match current_state:
		State.IDLE:   _idle_behavior()
		State.CHASE:  _chase_behavior()
		State.HIT:
			velocity.x = move_toward(velocity.x, 0, speed * 3.0)
			move_and_slide()
		State.DEATH:
			velocity.x = move_toward(velocity.x, 0, speed * 3.0)
			move_and_slide()

	# Animation sync for non-attack states
	_sync_animation()

# ─── Helper ──────────────────────────────────────────────────────────────────
func _get_player() -> Node2D:
	var p: Node2D = get_tree().get_first_node_in_group("player")
	if not p:
		p = get_tree().get_first_node_in_group("Player")
	return p

func _sync_animation() -> void:
	match current_state:
		State.CHASE:
			sprite.play("CHASE" if velocity.length() > 10 else "IDLE")
		State.IDLE:
			sprite.play("IDLE")
		# HIT and DEATH animations are set explicitly in take_damage / _die

# ─── State Behaviors ─────────────────────────────────────────────────────────
func _idle_behavior() -> void:
	velocity.x = move_toward(velocity.x, 0, speed * 2.0)
	move_and_slide()
	var player := _get_player()
	if player and global_position.distance_to(player.global_position) < 800:
		current_state = State.CHASE

func _chase_behavior() -> void:
	var player := _get_player()
	if not player:
		current_state = State.IDLE
		return

	var dist := global_position.distance_to(player.global_position)

	# ── Attack trigger ──
	if dist < attack_range and _attack_cooldown <= 0:
		_begin_attack(player)
		return

	# ── Slowdown radius — damp velocity when close to avoid jitter/push ──
	var slowdown_radius := attack_range * slowdown_radius_multiplier
	var speed_scale := 1.0
	if dist < slowdown_radius:
		speed_scale = clampf(dist / slowdown_radius, 0.05, 1.0)

	var direction := (player.global_position - global_position).normalized()
	velocity.x = direction.x * speed * speed_scale
	sprite.flip_h = direction.x < 0
	move_and_slide()

# ─── Attack Sequence ─────────────────────────────────────────────────────────
func _begin_attack(player: Node2D) -> void:
	is_attacking = true
	_hit_landed = false
	_attack_timer = ATTACK_DURATION
	_lunge_timer = lunge_duration
	current_state = State.ATTACK

	# Kill all current momentum before pounce
	velocity = Vector2.ZERO

	# Face the player
	var dir: float = signf(player.global_position.x - global_position.x)
	sprite.flip_h = dir < 0
	_lunge_dir = dir

	# NOTE: We do NOT add_collision_exception here — doing so causes the wolf
	# to teleport through the player. Instead we stop the lunge on contact.

	# Shift SPRITE down to match the taller attack frame (CollisionShape stays fixed)
	sprite.position.y = _sprite_default_pos.y - 25.0

	print("[WOLF] Initiating pounce attack towards player at ", player.global_position)
	sprite.play("ATTACK")

func _run_attack(delta: float) -> void:
	_attack_timer -= delta

	# ── Phase 1: Lunge burst ──
	if _lunge_timer > 0:
		_lunge_timer -= delta
		var player := _get_player()
		# Stop lunge if we've made contact — prevents tunnelling through player
		if player and global_position.distance_to(player.global_position) < attack_range * 0.6:
			_lunge_timer = 0.0
			velocity.x = 0
			print("[WOLF] Lunge contact stop at distance: ",
					snapped(global_position.distance_to(player.global_position), 0.1))
		else:
			velocity.x = _lunge_dir * lunge_speed
	else:
		# After lunge, brake hard
		velocity.x = move_toward(velocity.x, 0, lunge_speed * 4.0 * delta)

	move_and_slide()

	# ── Activate hitbox after the lead-up frames ──
	var elapsed := ATTACK_DURATION - _attack_timer
	if elapsed >= HITBOX_ACTIVE_AFTER and not _hit_landed:
		if hitbox_shape.disabled:  # Only log once per activation
			print("[WOLF] Hitbox ENABLED — elapsed: ", snapped(elapsed, 0.01),
					"s | mask=", hitbox.collision_mask)
		hitbox_shape.set_deferred("disabled", false)

	# ── Exit attack ──
	if _attack_timer <= 0:
		_end_attack()

func _end_attack() -> void:
	is_attacking = false
	_hit_landed = false
	hitbox_shape.set_deferred("disabled", true)
	_attack_cooldown = ATTACK_COOLDOWN
	# Restore sprite to its default position
	sprite.position = _sprite_default_pos
	print("[WOLF] Attack ended — returning to CHASE (cooldown: ", ATTACK_COOLDOWN, "s)")
	current_state = State.CHASE

# ─── Signal Callbacks ─────────────────────────────────────────────────────────
func _on_animation_finished() -> void:
	match sprite.animation:
		"HIT":
			if current_state == State.HIT:
				current_state = State.CHASE
		"DEATH":
			queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not is_attacking or _hit_landed:
		return
	if body.is_in_group("player") or body.is_in_group("Player"):
		_hit_landed = true
		hitbox_shape.set_deferred("disabled", true)  # One hit per swing
		print("[WOLF → PLAYER] Pounce HIT! Wolf pos: ", snapped(global_position, Vector2(0.1, 0.1)),
				" | Player pos: ", snapped(body.global_position, Vector2(0.1, 0.1)))
		if body.has_method("take_damage"):
			body.take_damage(1)

# ─── Public API ──────────────────────────────────────────────────────────────
func take_damage() -> void:
	if current_state == State.DEATH:
		return

	# If interrupted mid-attack, restore sprite and clean up
	if is_attacking:
		is_attacking = false
		_hit_landed = false
		hitbox_shape.set_deferred("disabled", true)
		_attack_cooldown = ATTACK_COOLDOWN
		sprite.position = _sprite_default_pos  # Restore sprite position

	health -= 1
	print("[PLAYER → WOLF] Hit landed! Wolf health now: ", health, " / 3")

	if health <= 0:
		current_state = State.DEATH
		hitbox_shape.set_deferred("disabled", true)
		# Shift sprite UP for death animation (wolf collapsing upward is visually cleaner)
		sprite.position.y = _sprite_default_pos.y - 10.0
		print("[WOLF] Defeated! Playing death animation.")
		sprite.play("DEATH")
		_die()
	else:
		current_state = State.HIT
		sprite.play("HIT")

func _die() -> void:
	print("[BOSS] Black Wolf defeated!")
	# queue_free triggered by animation_finished for DEATH anim
	# Safety fallback
	get_tree().create_timer(2.5).timeout.connect(func():
		if is_instance_valid(self): queue_free()
	)
