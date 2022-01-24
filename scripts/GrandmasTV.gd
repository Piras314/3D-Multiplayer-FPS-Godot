extends Spatial

# Called when the node enters the scene tree for the first time.
func _ready():
	var scene_anim = get_node("AnimationPlayer").get_animation("Scene")
	var anim = get_node("AnimationPlayer")
	scene_anim.set_loop(true)
	anim.play("Scene")
