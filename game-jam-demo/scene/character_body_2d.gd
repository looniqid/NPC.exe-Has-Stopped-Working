extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# 1. 获取动画节点的引用
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# 增加一个变量记录是否正在攻击，防止攻击动画被移动动画打断
var is_attacking: bool = false

func _physics_process(delta: float) -> void:
	# 添加重力
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 处理攻击输入 (假设你在 Input Map 里设置了 "attack" 键，比如鼠标左键)
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

	# 处理跳跃
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 获取输入方向
	var direction := Input.get_axis("ui_left", "ui_right")
	
	# 处理移动和左右翻转
	if direction:
		velocity.x = direction * SPEED
		# 根据移动方向翻转图片
		if not is_attacking: # 攻击时通常保持朝向
			animated_sprite.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	# 2. 更新动画逻辑
	update_animations(direction)

# 处理动画切换的函数
func update_animations(direction):
	# 如果正在攻击，就让攻击动画播完，不执行下面的逻辑
	if is_attacking:
		return
		
	if not is_on_floor():
		# 在空中播跳跃动画
		animated_sprite.play("jump")
	elif direction != 0:
		# 在地面且有位移播走路动画
		animated_sprite.play("walking")
	else:
		# 否则播待机动画
		animated_sprite.play("idle")

# 攻击函数
func attack():
	is_attacking = true
	animated_sprite.play("attack")

# 3. 关键：连接动画完成的信号
# 在 AnimatedSprite2D 的信号面板里连接 animation_finished 到这里

func _on_animated_sprite_2d_animation_finished():
	print("收到信号了！当前结束的动画是: ", animated_sprite.animation) # 加这一行测试
	
	if animated_sprite.animation == "attack":
		is_attacking = false
		print("成功解除攻击状态！") # 加这一行测试
