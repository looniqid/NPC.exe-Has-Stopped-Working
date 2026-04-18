extends CanvasLayer

## DebugOverlay.gd
## Provides a UI for testing player movement and checkpoint mechanics.

@onready var btn_invert: Button = $Control/VBoxContainer/BtnInvert
@onready var btn_delay: Button = $Control/VBoxContainer/BtnDelay
@onready var btn_kill: Button = $Control/VBoxContainer/BtnKill

@export_group("God Mode Settings")
@export var debug_mode: bool = true

var player: Player = null
var btn_crash: Button = null
var btn_fix: Button = null

func _ready() -> void:
	# Ensure the layer is set correctly (requirement: 100)
	layer = 100
	
	# Connect signals using Godot 4 syntax
	btn_invert.pressed.connect(_on_btn_invert_pressed)
	btn_delay.pressed.connect(_on_btn_delay_pressed)
	btn_kill.pressed.connect(_on_btn_kill_pressed)
	
	# God Mode: Specialized System Test Buttons
	_setup_system_test_buttons()
	
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

## Programmatically creates and connects buttons if they don't exist in the scene.
func _setup_system_test_buttons() -> void:
	var container = $Control/VBoxContainer
	if not container: return
	
	# Crash Button Setup
	btn_crash = container.find_child("BtnCrash", false, false)
	if not btn_crash:
		btn_crash = Button.new()
		btn_crash.name = "BtnCrash"
		btn_crash.text = "GSYS: CRASH"
		container.add_child(btn_crash)
	
	# Fix Button Setup
	btn_fix = container.find_child("BtnFix", false, false)
	if not btn_fix:
		btn_fix = Button.new()
		btn_fix.name = "BtnFix"
		btn_fix.text = "GSYS: REBOOT"
		container.add_child(btn_fix)
		
	# Connections
	if not btn_crash.pressed.is_connected(_on_btn_crash_pressed):
		btn_crash.pressed.connect(_on_btn_crash_pressed)
	if not btn_fix.pressed.is_connected(_on_btn_fix_pressed):
		btn_fix.pressed.connect(_on_btn_fix_pressed)
		
	# Visibility based on debug_mode
	btn_crash.visible = debug_mode
	btn_fix.visible = debug_mode

func _on_btn_crash_pressed() -> void:
	if get_tree().root.has_node("SystemManager"):
		get_tree().root.get_node("SystemManager").trigger_system_crash()
	else:
		push_error("DebugOverlay: SystemManager Autoload not found.")

func _on_btn_fix_pressed() -> void:
	if get_tree().root.has_node("SystemManager"):
		get_tree().root.get_node("SystemManager").fix_audio_visuals()
	else:
		push_error("DebugOverlay: SystemManager Autoload not found.")
