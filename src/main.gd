extends Node2D

# ENet是一个网络库 只使用UDP
# ENetMultiplayerPeer是MultiplayerPeer 的一种实现
var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
const PLAYER: PackedScene     = preload("res://src/players/player.tscn")
const ORC = preload("res://src/enemys/orc.tscn")
@onready var players: Node = $Players
@onready var enemys: Node = $Enemys
@onready var create_game_server_button: Button = $UI/Control/CreateGameServerButton
@onready var join_game_server_button: Button = $UI/Control/JoinGameServerButton
@onready var network_latency_label: Label = $UI/Control/NetworkLatencyLabel
@onready var fps_label: Label = $UI/Control/FPSLabel
@onready var network_latency_timer: Timer = $NetworkLatencyTimer
# ping的发送时间
var ping_time: float

func _ready() -> void:
	pass
	# 设置游戏语言为英文
#	TranslationServer.set_locale("ja")

func _process(delta: float) -> void:
	# 显示FPS
	fps_label.text="FPS %s" % Engine.get_frames_per_second()

# 创建游戏服务器
func _on_create_game_server_button_button_down() -> void:
	# 创建服务器
	var error: int = peer.create_server(7788)
	if error != OK:
		print("创建服务器失败")
		return
	else:
		print("创建服务器成功")
	# 删除延迟标签(服务器不需要延迟检测)
	network_latency_label.queue_free()
	# 删除延迟检测定时器
	network_latency_timer.queue_free()
	# 取消按钮的焦点
	create_game_server_button.focus_mode=Control.FOCUS_NONE
	join_game_server_button.focus_mode=Control.FOCUS_NONE
	# 绑定服务器
	# 每个节点都会有一个multiplayer属性 它是对场景树为其配置的MultiplayerAPI实例的引用 multiplayer_peer就是MultiplayerAPI的一个属性 也就是说MultiplayerAPI管理着multiplayer_peer

	# MultiplayerPeer是管理与一个或多个作为服务器或客户端的远程对等体的连接
	# 根据对等体本身的不同，该 MultiplayerAPI 
	# 可能会成为网络服务器（使用 is_server 判断）并将根节点的网络模式设置为控制者，也可能会成为普通的客户端对等体。所有子节点默认会继承其网络模式。
	# 那么这段代码的含义就是:让当前节点(包括子节点)加入网络 成为网络的控制者(create_server)或普通参与者(create_client)
	multiplayer.multiplayer_peer = peer
	# 添加服务端的玩家
	add_player(multiplayer.get_unique_id())
	# 添加敌人
	for i in 20:
		var orc =  ORC.instantiate()
		orc.name=str(i)+"orc"
		enemys.add_child(orc)
	# 作为服务端 监听玩家加入事件
	multiplayer.peer_connected.connect(_on_peer_connected)

func add_player(id: int) -> void:
	print("开始添加玩家"+str(id))
	# 实例化一个玩家场景
	print("开始实例化场景")
	var player: Node = PLAYER.instantiate()
	print("场景实例化完成")
	player.name = str(id)
	print("添加玩家到场景树")
	players.add_child(player)
	print("添加玩家到场景树完成")


func _on_peer_connected(id: int) -> void:
	print("玩家"+str(id)+"加入服务器")
	# 添加玩家
	add_player(id)


# 加入游戏服务器
func _on_join_game_server_button_button_down() -> void:
	var error:int = peer.create_client("127.0.0.1", 7788)
	if error!=OK:
		print("加入服务器失败")
		return
	multiplayer.multiplayer_peer = peer
	# 取消按钮的焦点
	create_game_server_button.focus_mode=Control.FOCUS_NONE
	join_game_server_button.focus_mode=Control.FOCUS_NONE
	# 开启延迟检测定时器
	network_latency_timer.start()
	

# 获取实时延迟
func _on_network_latency_timer_timeout() -> void:
	ping_time = Time.get_unix_time_from_system()
	ping.rpc_id(1)
	
# 用于发送ping给服务器 服务器接收到后会调用客户端的pong方法
@rpc("any_peer","call_remote")	
func ping():
	var sender_id = multiplayer.get_remote_sender_id()
	pong.rpc_id(sender_id)
# 只能服务器调用 服务器本地不执行 只会在对应的客户端执行
@rpc("authority","call_remote")
func pong()->void:
	#ceil向上取整
	var latency = ceil((Time.get_unix_time_from_system() - ping_time)/1000)
	network_latency_label.text = str(latency,"ms")
	
