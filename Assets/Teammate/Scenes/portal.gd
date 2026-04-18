extends Area2D

@export var wolf_scene: PackedScene = preload("res://Scenes/entities/BlackWolf.tscn")
@export_file("*.tscn") var target_scene_path: String

var can_teleport: bool = false
var boss_instance: Node2D = null
var boss_spawned: bool = false

@onready var interaction_label: Label = get_node_or_null("Label")

func _ready():
	# Ensure signals are connected via code to be safe
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	
	if interaction_label:
		interaction_label.hide()

func spawn_boss_sequence(trigger_body: Node2D):
	boss_spawned = true
	
	# 1. Visual/Audio Impact
	if has_node("/root/SystemManager"):
		var sm = get_node("/root/SystemManager")
		sm.trigger_system_crash()
	
	# 2. Instantiate Boss
	if wolf_scene:
		boss_instance = wolf_scene.instantiate()
		get_parent().add_child.call_deferred(boss_instance)
		
		# Spawn relative to the player's current position instead of portal root
		var spawn_pos = trigger_body.global_position + Vector2(-200, -50)
		boss_instance.global_position = spawn_pos
		boss_instance.modulate.a = 0
		
		# 3. Fade In Boss
		var tween = create_tween()
		tween.tween_property(boss_instance, "modulate:a", 1.0, 0.5)
		
		print("[PORTAL] CRITICAL ERROR: Malware detected in transit stream!")
		print("[PORTAL] Spawning boss at: ", spawn_pos)
	else:
		push_error("[PORTAL] wolf_scene not assigned!")

func _process(_delta):
	var boss_alive = is_instance_valid(boss_instance)
	
	if can_teleport:
		if boss_alive:
			if interaction_label:
				interaction_label.text = "ERROR: ACCESS DENIED. MALWARE DETECTED."
				interaction_label.modulate = Color.RED
				interaction_label.show()
		elif Input.is_action_just_pressed("interact"):
			if target_scene_path != "":
				print("[PORTAL] Teleporting to: ", target_scene_path)
				get_tree().change_scene_to_file(target_scene_path)
			else:
				print("[PORTAL] where is your scene?！")
		elif interaction_label:
			interaction_label.text = "Press UP to Exit"
			interaction_label.modulate = Color.WHITE
			interaction_label.show()

func _on_body_entered(body: Node2D):
	if body.is_in_group("Player") or body.is_in_group("player") or "player" in body.name.to_lower():
		can_teleport = true
		if not boss_spawned:
			spawn_boss_sequence(body)
		print("[PORTAL] Player entered. Ready for teleport.") 

func _on_body_exited(body: Node2D):
	if body.is_in_group("Player") or body.is_in_group("player") or "player" in body.name.to_lower():
		can_teleport = false
		print("[PORTAL] Player left.")
