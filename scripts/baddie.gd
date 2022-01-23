extends KinematicBody

export(int) var health = 50

func _physics_process(_delta):
	if health <= 0:
		queue_free()
