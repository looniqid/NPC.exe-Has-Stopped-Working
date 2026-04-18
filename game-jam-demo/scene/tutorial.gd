extends Area2D

@onready var prompt_label = $Label

func _ready():
	prompt_label.visible = false

func _on_body_entered(body: Node2D):
	if body.name == "player":
		prompt_label.visible = true

func _on_body_exited(body: Node2D):
	if body.name == "player":

		queue_free()
