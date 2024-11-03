extends Sprite2D

# 蓝色小人
const TILE_0142 = preload("res://assest/kenney_tiny-battle/Tiles/tile_0142.png")
# 红色小人
const TILE_0160 = preload("res://assest/kenney_tiny-battle/Tiles/tile_0160.png")
# 一级子弹
const BULLET_ONE: PackedScene = preload("res://tscns/bullets/bullet_one.tscn")
# 移动速度
const MOVE_SPEED: int = 100
# 玩家相机
@onready var camera: Camera2D = $Camera2D

# 需要移动到的目标位置(一般是指鼠标位置)
var target_pos: Vector2 = Vector2.ZERO
# 定义一个变量来存储摄像机是否处于锁定状态
var is_camera_locked: bool = false
# 鼠标在窗口内的边界阈值
var mouse_border_threshold: int = 2


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
	# 设置鼠标模式 默认将鼠标光标限制在游戏窗口内，并使其可见
	Input.set_mouse_mode(Input.MouseMode.MOUSE_MODE_CONFINED)

	# 不是自己控制的角色不要相机
	var id: int = multiplayer.get_unique_id()
	if str(id) != name:
		camera.free()

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

# 处理输入事件
func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	# 按下ESC可以将鼠标移动到屏幕外面
	if event.is_action_pressed("ESC"):
		Input.set_mouse_mode(Input.MouseMode.MOUSE_MODE_VISIBLE)

	# 按下鼠标左键 将鼠标固定在游戏窗口内
	if event.is_action_pressed("mouse_left") and Input.get_mouse_mode() == Input.MouseMode.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MouseMode.MOUSE_MODE_CONFINED)

	# 锁定/解锁视角
	if event.is_action_pressed("lock_camera"):
		is_camera_locked = not is_camera_locked
		camera.offset.x=0
		camera.offset.y=0

	
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
		if Input.get_mouse_mode() == Input.MouseMode.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MouseMode.MOUSE_MODE_CONFINED)
	# 如果有目标位置就移动到目标位置
	if target_pos != Vector2.ZERO:
		move_towards_target(delta)
	# 到达目的地(两个向量之间的距离小于1就算他到达了 过于追求精准会导致玩家抖动)
	if position.distance_to(target_pos)<1:
		target_pos = Vector2.ZERO
	# 未锁定视角时 且鼠标在游戏窗口内 判断相机移动
	if not is_camera_locked and Input.get_mouse_mode() == Input.MouseMode.MOUSE_MODE_CONFINED:
		change_camera()
	# 按下空格 回到玩家视角
	if Input.is_action_pressed("sapce"):
		camera.offset.x=0
		camera.offset.y=0


# 攻击的方法
func attack():
	# 必须先获取位置后再同步过去 不然两边的子弹方向不一致
	var direction = get_direction()
	async_attack.rpc(direction)


# 同步发射出去的子弹
@rpc("any_peer", "call_local")
func async_attack(direction: Vector2):
	var bullet_one = BULLET_ONE.instantiate()
	bullet_one.direction = direction
	bullet_one.position = position
	# 下面的代码获取了默认朝向(1,0) 是朝向右边的 但是我的子弹图像是朝着上方的 所以差了90°
	#print(cos(bullet_one.rotation),sin(bullet_one.rotation))
	#bullet_one.rotate(direction.angle()+deg_to_rad(90)) #加上90°就刚刚好
	# 这里使用一个向上的向量来计算弧度也可以
	var angle = Vector2(0, -1).angle_to(direction)
	bullet_one.rotate(angle)
	get_parent().add_child(bullet_one)


# 获取鼠标所在位置的方向
func get_direction() -> Vector2:
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	return direction


# 移动到目标位置
func move_towards_target(delta: float):
	var direction = (target_pos - position).normalized()
	position += direction * MOVE_SPEED * delta


# 移动相机
func change_camera():
	var mouse_pos = get_viewport().get_mouse_position()
	#print("鼠标移动的位置:",mouse_pos)
	var screen_size = get_viewport_rect().size
	#print("窗口边界:",screen_size)
	# 计算鼠标与窗口边界的距离
	var left_distance   = mouse_pos.x
	var right_distance  = screen_size.x - mouse_pos.x
	var top_distance    = mouse_pos.y
	var bottom_distance = screen_size.y - mouse_pos.y
	# 根据鼠标与窗口边界的距离来调整摄像机偏移量
	if right_distance<mouse_border_threshold:
		camera.offset.x+=5
	if left_distance<mouse_border_threshold:
		camera.offset.x-=5
	if top_distance<mouse_border_threshold:
		camera.offset.y-=5
	if bottom_distance<mouse_border_threshold:
		camera.offset.y+=5
