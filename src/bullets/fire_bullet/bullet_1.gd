extends Sprite2D
# 一级子弹的脚本
@onready var life_timer: Timer = $LifeTimer
# 子弹移动速度
const SPEED: int       = 200
var direction: Vector2 = Vector2.ZERO


func _process(delta: float) -> void:
	# 移动子弹
	position += direction * SPEED * delta
	# 检查子弹是否已经结束
	if life_timer.is_stopped():
		queue_free()
