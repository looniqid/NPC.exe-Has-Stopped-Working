extends CanvasLayer

@onready var panel = $Panel
@onready var label = $Panel/Label

func _ready():
	# 游戏刚开始时，对话框是隐藏的
	panel.visible = false

# 导演调用这个函数来显示对话
func show_dialogue(text: String):
	panel.visible = true
	label.text = text
	
	# 【打字机效果魔法】
	# 核心原理：先让文字可见度变 0，然后用 Tween 动画让它慢慢变成 1 (100%)
	label.visible_characters = 0 
	
	var tween = create_tween()
	# 假设每个字花费 0.05 秒，文字越多时间越长
	var duration = text.length() * 0.05 
	tween.tween_property(label, "visible_ratio", 1.0, duration)

# 导演调用这个函数来关掉对话框
func hide_dialogue():
	panel.visible = false
