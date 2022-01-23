extends Spatial
 
var packed_scene_player = preload("res://scenes/Player.tscn")

# Godot uses client-server architecture.
# That means "host" means server, and "peer" (virtually) means client.
 
# Ideally, the peer should always wait for the server to initialize
# proper resources & position. You likely not going to see the
# artifact for simple shapes or identical characters, but when
# you have more of character models, it will start to show artifacts.
 
onready var positions = [$Player1Spawn, $Player2Spawn] # Store all positions the game

func _ready():
	for i in Globals.player_id_list.size(): # Loop and get player_id from list.
		# Retrieves player_id from list of all player's unique ID
		var player_id = Globals.player_id_list[i]
		
		# Initialize each of player, and define unique id from the list.
		var player = packed_scene_player.instance()
		player.name = player.name + "_" + str(player_id) # I was wrong, we need this line to communicate
		player.set_network_master(player_id)
		player.global_transform = positions[i].global_transform
		add_child(player)
