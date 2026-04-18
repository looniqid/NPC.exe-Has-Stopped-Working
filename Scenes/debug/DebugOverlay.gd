extends CanvasLayer

## DebugOverlay.gd
## Provides a UI for testing player movement and checkpoint mechanics.

@onready var btn_invert: Button = $Control/VBoxContainer/BtnInvert
@onready var btn_delay: Button = $Control/VBoxContainer/BtnDelay
@onready var btn_kill: Button = $Control/VBoxContainer/BtnKill

var player: Player = null

func _ready() -> void:
	# Ensure the layer is set correctly (requirement: 100)
	layer = 100
	
	# Connect signals using Godot 4 syntax
	btn_invert.pressed.connect(_on_btn_invert_pressed)
	btn_delay.pressed.connect(_on_btn_delay_pressed)
	btn_kill.pressed.connect(_on_btn_kill_pressed)
	
	# Initial player discovery
	_find_player()

func _find_player() -> void:
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node is Player:
		player = player_node
	else:
		push_warning("DebugOverlay: Player not found in 'player' group.")

func _on_btn_invert_pressed() -> void:
	if not player: _find_player()
	
	if player and is_instance_valid(player.interceptor):
		player.interceptor.is_inverted = not player.interceptor.is_inverted
		btn_invert.text = "Invert: " + ("ON" if player.interceptor.is_inverted else "OFF")

func _on_btn_delay_pressed() -> void:
	if not player: _find_player()
	
	if player and is_instance_valid(player.interceptor):
		player.interceptor.add_input_delay(0.5)
		var total_delay = player.interceptor.current_delay_ms / 1000.0
		btn_delay.text = "Delay: " + str(total_delay) + "s"

func _on_btn_kill_pressed() -> void:
	if not player: _find_player()
	
	if player:
		# CheckpointManager is expected to be an Autoload
		if get_tree().root.has_node("CheckpointManager"):
			get_tree().root.get_node("CheckpointManager").paste_player(player)
		else:
			push_error("DebugOverlay: CheckpointManager Autoload not found.")
