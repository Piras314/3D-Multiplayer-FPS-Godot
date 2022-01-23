extends Control

var max_clients = 2
var net_port = 7070

onready var tree = get_tree()

func _ready():
	tree.connect("network_peer_connected", self, "_player_connected")

func _on_ButtonHost_pressed():
	var net = NetworkedMultiplayerENet.new()
	net.create_server(net_port, max_clients)
	tree.set_network_peer(net)
	print("Hosting")

func _on_ButtonJoin_pressed():
	var net = NetworkedMultiplayerENet.new()
	net.create_client("127.0.0.1", net_port)
	tree.set_network_peer(net)

func _player_connected(id):
	# Check if this is client or server, and set proper unique ID
	if tree.is_network_server(): # If this is server
		Globals.player_id_list[1] = id # Add peer's client ID to second slot
	else: # If not, use its own ID to assign on second slot (because its client, so it uses second slot)
		Globals.player_id_list[1] = tree.get_network_unique_id()
	# Start the game.
	var game = preload("res://scenes/Game.tscn").instance()
	tree.root.add_child(game)
	hide()
