extends Area2D

# 在 Inspector 面板里填入目标场景的路径，例如 "res://levels/level_2.tscn"
@export_file("*.tscn") var target_scene_path: String

func _on_body_entered(body: Node2D) -> void:
	# 检查进入的对象是不是玩家 (假设你的玩家节点叫 "CharacterBody2D")
	if body is CharacterBody2D:
		call_deferred("_change_scene")

func _change_scene():
	if target_scene_path == "":
		print("警告：未设置目标场景路径！")
		return
	get_tree().change_scene_to_file(target_scene_path)
