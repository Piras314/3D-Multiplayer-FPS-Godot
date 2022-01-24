extends KinematicBody

const MAX_CAM_SHAKE = 0.3
const SWAY = 30
const VSWAY = 15
const ADS_LERP = 5


export(int) var start_health = 100
export(int) var health = start_health
export(int) var damage = 10
export(int) var speed = 10
export(int) var h_acceleration = 6
export(int) var air_acceleration = 1
export(int) var normal_acceleration = 6
export(float) var mouse_sensitivity = 0.03
export(int) var gravity = 20
export(int) var jump = 10
export(int) var friction = 0.9
export(bool) var gun_equipped = false
export(int) var sway_threshhold = 3
export(int) var sway_lerp = 5
export(Vector3) var sway_left
export(Vector3) var sway_right
export(Vector3) var sway_normal
export(Vector3) var default_position
export(Vector3) var ads_position
export(Dictionary) var fview = {"DEFAULT": 70, "ADS": 50}


onready var head = $Head
onready var ground_check = $GroundCheck
onready var anim_player = $AnimationPlayer
onready var camera = $Head/Camera
onready var raycast = $Head/Camera/Hand/RayCast
onready var hand = $Head/Camera/Hand
onready var shootsound = $Head/Camera/Hand/RayCast/ShootSound


onready var b_decal = preload("res://scenes/BulletDecal.tscn")


var physics_good
var mouse_mov
var full_contact = false
var direction = Vector3.ZERO
var h_velocity = Vector3.ZERO
var movement = Vector3.ZERO
var gravity_vec = Vector3.ZERO



func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# If this peer has control on this player
	if is_network_master():
		$Head/Camera.make_current() # Also set the camera, or all peers will use a camera from same player.
	# If not, disable every process in the game.
	else:
		set_process(false)
		set_process_input(false)
		set_physics_process(false)

remote func _set_position(pos):
	global_transform.origin = pos

# Separated function to do rotation job.
remote func _set_rotation(rot: Vector2): 
	rotate_y(deg2rad(-rot.x * mouse_sensitivity))
	head.rotate_x(deg2rad(-rot.y * mouse_sensitivity))
	head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))

func _input(event):
	if event is InputEventMouseMotion:
		mouse_mov = -event.relative.x
		
		_set_rotation(event.relative) # call function locally.
		rpc_unreliable("_set_rotation", event.relative) # also, make a call to all other machines.
	
	if Input.is_action_just_pressed("fire"):
		if not anim_player.is_playing():
			shootsound.play()
			camera.translation = lerp(camera.translation, 
				Vector3(rand_range(MAX_CAM_SHAKE, -MAX_CAM_SHAKE), 
				rand_range(MAX_CAM_SHAKE, -MAX_CAM_SHAKE), 0), 0.5)
			if raycast.is_colliding():
				var target = raycast.get_collider()
				if target.is_in_group("Enemies") or target.is_in_group("Players"):
					target.health -= damage
				
				else:
					var b = b_decal.instance()
					raycast.get_collider().add_child(b)
					b.global_transform.origin = raycast.get_collision_point()
					if is_on_floor():
						b.rotation_degrees.x = 90
					else:
						b.look_at_from_position(raycast.get_collision_point(), raycast.get_collision_point() + raycast.get_collision_normal(), Vector3.UP)
			anim_player.play("AssaultFire")
		
		else:
			camera.translation = Vector3()
			anim_player.stop()
	
	else:
		camera.translation = Vector3()
		anim_player.stop()

func _process(delta):
	if Input.is_action_pressed("alt_fire"):
		hand.transform.origin = hand.transform.origin.linear_interpolate(ads_position, ADS_LERP * delta)
		camera.fov = lerp(camera.fov, fview["ADS"], ADS_LERP * delta)
	else:
		hand.transform.origin = hand.transform.origin.linear_interpolate(default_position, ADS_LERP * delta)
		camera.fov = lerp(camera.fov, fview["DEFAULT"], ADS_LERP * delta)
		if mouse_mov != null:
			if mouse_mov > sway_threshhold:
				hand.rotation = hand.rotation.linear_interpolate(sway_left, sway_lerp * delta)
			
			elif mouse_mov < -sway_threshhold:
				 hand.rotation = hand.rotation.linear_interpolate(sway_right, sway_lerp * delta)
				
			else:
				hand.rotation = hand.rotation.linear_interpolate(sway_normal, sway_lerp * delta)
		
		else:
			hand.rotation = hand.rotation.linear_interpolate(sway_normal, sway_lerp * delta)

#	rpc_unreliable("_gun_equipped", gun_equipped)
	rpc_unreliable("_set_position", global_transform.origin)
	mouse_mov = null

func _physics_process(dt):
	direction = Vector3.ZERO
	
	if ground_check.is_colliding():
		full_contact = true
	else:
		full_contact = false
	
	if not is_on_floor():
		gravity_vec += Vector3.DOWN * gravity * dt
		h_acceleration = air_acceleration
	elif is_on_floor() and full_contact:
		gravity_vec = -get_floor_normal() * gravity
		h_acceleration = normal_acceleration
	else:
		gravity_vec = -get_floor_normal()
		h_acceleration = normal_acceleration
	
	if Input.is_action_just_pressed("jump") and (is_on_floor() or ground_check.is_colliding()):
		gravity_vec = Vector3.UP * jump
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	elif Input.is_action_pressed("move_right"):
		direction += transform.basis.x
	
	direction = direction.normalized()
	h_velocity = h_velocity.linear_interpolate(direction * speed, h_acceleration * dt)
	movement.z = h_velocity.z + gravity_vec.z
	movement.x = h_velocity.x + gravity_vec.x
	movement.y = gravity_vec.y

	physics_good = move_and_slide(movement, Vector3.UP)
