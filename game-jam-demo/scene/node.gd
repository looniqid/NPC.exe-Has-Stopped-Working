extends Node

@export var player: CharacterBody2D
@export var hero: Node2D
@export var tree: Node2D
@export var bgm_player: AudioStreamPlayer

func _ready():
	play_opening_cutscene()

func play_opening_cutscene():
	print("【cutscene start】")
	player.has_control = false 
	
	
	var hero_animated_sprite = hero.get_node_or_null("AnimatedSprite2D")
	if hero_animated_sprite:
		hero_animated_sprite.flip_h = true 
		hero_animated_sprite.play("run") 
	
	player.get_node("ChatBubble").text = ""
	hero.get_node("ChatBubble").text = ""
	
	var tween_hero_in = create_tween()
	tween_hero_in.tween_property(hero, "global_position:x", player.global_position.x + 60, 2.0)
	await tween_hero_in.finished 
	
	if hero_animated_sprite:
		hero_animated_sprite.play("idle") 
	
	await get_tree().create_timer(0.5).timeout
	hero.get_node("ChatBubble").text = "Hero: Hey fellow villager, how do I get to the Demon King's Castle?"
	await get_tree().create_timer(2.5).timeout
	hero.get_node("ChatBubble").text = "" 
	
	player.get_node("ChatBubble").text = "Player(Auto replied) :Head north along this road...\nMay the holy light deceive you."
	await get_tree().create_timer(3.0).timeout
	player.get_node("ChatBubble").text = "" 
	
	await get_tree().create_timer(1.0).timeout
	if hero_animated_sprite:
		hero_animated_sprite.play("run")
		hero_animated_sprite.flip_h = false 
	
	var tween_hero_out = create_tween()
	tween_hero_out.tween_property(hero, "global_position:x", hero.global_position.x + 300, 3.0)
	await tween_hero_out.finished
	hero.queue_free() 
	
	var is_tree_on_left = tree.global_position.x < player.global_position.x
	player.get_node("AnimatedSprite2D").flip_h = is_tree_on_left
	
	var tween_patrol = create_tween()
	player.get_node("AnimatedSprite2D").play("walking") 
	tween_patrol.tween_property(player, "global_position:x", tree.global_position.x + (20 if is_tree_on_left else -20), 1.5)
	await tween_patrol.finished
	
	for i in range(3):
		player.get_node("AnimatedSprite2D").play("idle") 
		player.position.x += (-5 if is_tree_on_left else 5) 
		print("砰！")
		await get_tree().create_timer(0.1).timeout
		player.position.x += (5 if is_tree_on_left else -5) 
		player.get_node("AnimatedSprite2D").play("walking") 
		await get_tree().create_timer(0.4).timeout

	print("【觉醒触发！】")
	player.get_node("AnimatedSprite2D").play("idle")
	
	var quest_marker = player.get_node_or_null("QuestMarker2")
	var break_effect = player.get_node_or_null("BreakEffect2")
	
	if quest_marker and break_effect:
		quest_marker.visible = false 
		break_effect.emitting = true 
	
	if bgm_player:
		var pitch_tween = create_tween()
		pitch_tween.tween_property(bgm_player, "pitch_scale", 0.1, 0.5)
		await pitch_tween.finished
		bgm_player.stop() 
		
	
	await get_tree().create_timer(0.5).timeout 
	
	player.get_node("ChatBubble").text = "[System command crash]\n...Out of control..."
	
	await get_tree().create_timer(2.0).timeout
	
	player.get_node("ChatBubble").text = ""
	
	player.has_control = true
