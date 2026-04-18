extends Area2D

@export_file("*.tscn") var target_scene_path: String

var can_teleport: bool = false  

func _ready():
	# Ensure signals are connected via code to be safe
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _process(_delta):
	if can_teleport and Input.is_action_just_pressed("interact"):
		if target_scene_path != "":
			get_tree().change_scene_to_file(target_scene_path)
		else:
			print("[PORTAL] where is your scene?！")

func _on_body_entered(body: Node2D):
	# Flexible detection: works for "player", "Player", or "PlayerBody"
	if body.is_in_group("Player") or body.is_in_group("player") or "player" in body.name.to_lower():
		can_teleport = true
		print("[PORTAL] Player entered. Ready for teleport.") 

func _on_body_exited(body: Node2D):
	if body.is_in_group("Player") or body.is_in_group("player") or "player" in body.name.to_lower():
		can_teleport = false
		print("[PORTAL] Player left.")
