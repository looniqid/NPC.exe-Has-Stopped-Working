extends Area2D

@export_file("*.tscn") var target_scene_path: String

var can_teleport: bool = false  

func _process(delta):
	if can_teleport and Input.is_action_just_pressed("interact"):
		if target_scene_path != "":
			get_tree().change_scene_to_file(target_scene_path)
		else:
			print("where is your scene?！")

func _on_body_entered(body: Node2D):
	if body.name == "player":
		can_teleport = true
		print("press up arrow and let's go") 

func _on_body_exited(body: Node2D):
	if body.name == "player":
		can_teleport = false
		print("player leave")
