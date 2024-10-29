extends Sprite2D

# 蓝色小人
const TILE_0142 = preload("res://assest/kenney_tiny-battle/Tiles/tile_0142.png")
# 红色小人
const TILE_0160 = preload("res://assest/kenney_tiny-battle/Tiles/tile_0160.png")
# 一级子弹
const BULLET_ONE = preload("res://tscns/bullets/bullet_one.tscn")
# 移动速度
const MOVE_SPEED = 100
# 玩家相机
@onready var camera_2d: Camera2D = $Camera2D
# 需要移动到的目标位置(一般是指鼠标位置)
var target_pos: Vector2 = Vector2.ZERO

# 最先调用 实例化的时候
func _init() -> void:
	print("_init")

# 其次调用 当节点进入场景树时调用
func _enter_tree() -> void:
	print("_enter_tree:设置该节点权限"+name)
	# 设置该节点的多人权限
	set_multiplayer_authority(name.to_int())
	

# 在节点及其所有子节点都已添加到场景树后调用
func _ready() -> void:
	print("_ready")
	
	# 不是自己控制的角色不要相机
	print(camera_2d)
	var id = multiplayer.get_unique_id()
	if str(id) != name:
		camera_2d.free()
		
	# 服务器是红色小人
	if name == "1":
		texture = TILE_0160
	else:
		texture = TILE_0142
	print(texture.resource_name)
	# texture = TILE_0142
	# 随机设置玩家初始位置
	position = Vector2(randf_range(0, 800), randf_range(0, 600))
	print(position)
	# position = Vector2(300, 300)

		
func _process(delta: float) -> void:
	# 如果不是该节点的控制者 不做任何处理
	# 根据设置的节点的权限id 与 本身的唯一id作对比
	if not is_multiplayer_authority():
		return
	# 攻击
	if Input.is_action_just_pressed("attack"):
		attack()
	# 玩家移动(鼠标右键点击)
	# 不使用Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) 因为鼠标按下不松手会一直返回true 一直触发
	if Input.is_action_just_pressed("mouse_right"):
		target_pos = get_global_mouse_position()
	# 如果有目标位置就移动到目标位置
	if target_pos != Vector2.ZERO:
		move_towards_target(delta)
	# 到达目的地(两个向量之间的距离小于1就算他到达了 过于追求精准会导致玩家抖动)
	if position.distance_to(target_pos)<1:
		target_pos = Vector2.ZERO


# 攻击的方法
func attack():
	# 必须先获取位置后再同步过去 不然两边的子弹方向不一致
	var direction = get_direction()
	async_attack.rpc(direction)

# 同步发射出去的子弹
@rpc("any_peer","call_local")
func async_attack(direction:Vector2):
	var bullet_one = BULLET_ONE.instantiate()
	bullet_one.direction = direction
	bullet_one.position = position
	get_parent().add_child(bullet_one)
	

# 获取鼠标所在位置的方向
func get_direction() -> Vector2:
	var mouse_pos = get_local_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	return direction

# 移动到目标位置
func move_towards_target(delta: float):
	var direction = (target_pos - global_position).normalized()
	position += direction * MOVE_SPEED * delta
	
