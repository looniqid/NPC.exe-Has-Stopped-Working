extends Area2D

@export_file("*.tscn") var target_scene_path: String

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		call_deferred("_change_scene")

func _change_scene():
	if target_scene_path == "":
		print("bro, where is your scene...")
		return
	get_tree().change_scene_to_file(target_scene_path)
