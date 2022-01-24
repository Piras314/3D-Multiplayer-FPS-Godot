extends KinematicBody

export(int) var start_health = 200

var health = start_health
var checkhealth = true

func _physics_process(_delta):
	if checkhealth:
		if health <= 0:
			$Timer.wait_time = rand_range(7, 13)
			hide()
			$Timer.start()
			$CollisionShape.disabled = true
			checkhealth = false

func _on_Timer_timeout():
	show()
	$CollisionShape.disabled = false
	health = start_health
	checkhealth = true
