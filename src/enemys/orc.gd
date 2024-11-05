extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# 生命值
var health:int = 100


func _ready() -> void:
	print("_ready")
	# 随机设置兽人初始位置
	position = Vector2(randf_range(0, 800), randf_range(0, 600))
	print(position)

#func _physics_process(delta: float) -> void:
	# Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta
#
	## Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
#
	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_axis("ui_left", "ui_right")
	#if direction:
		#velocity.x = direction * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
#
	#move_and_slide()


func _on_area_2d_area_entered(area: Area2D) -> void:
	#print(area.get_groups())
	if area.is_in_group("bullet"):
		var bullet:Sprite2D = area.get_parent().get_parent()
		health-=bullet.BasicDamage
		print("当前血量:",health)
		if health<=0:
			queue_free()
		print("有节点进入兽人的身体")
