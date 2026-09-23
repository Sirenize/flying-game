extends Node3D

@onready var main_menu: PanelContainer = $CanvasLayer/MainMenu
@onready var hud: Control = $CanvasLayer/HUD
@onready var health_bar: ProgressBar = $CanvasLayer/HUD/HealthBar
@onready var address: LineEdit = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/HBoxContainer/AddressEntry
@onready var check_box: CheckBox = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/HBoxContainer/CheckBox
@onready var username_entry: TextEdit = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/UsernameEntry
@onready var username_label: Label = $CanvasLayer/HUD/Username

const PLAYER = preload("uid://dnwwlqjqwkig")

const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()
var localhost: bool
var username

func _on_singleplayer_button_pressed() -> void:
	main_menu.hide()
	hud.show()
	username = username_entry.text
	username_label.text = username
	add_player(0, username)

func _on_host_button_pressed() -> void:
	main_menu.hide()
	hud.show()
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	username = username_entry.text
	username_label.text = username
	add_player(multiplayer.get_unique_id(), username)
	
	upnp_setup()

func _on_join_button_pressed() -> void:
	main_menu.hide()
	hud.show()
	
	var joinaddress: String
	if !localhost:
		if address.text == null:
			joinaddress = "localhost"
		else:
			joinaddress = address.text
	else:
		joinaddress = "localhost"
	
	username = username_entry.text
	username_label.text = username
	enet_peer.create_client(joinaddress, PORT)
	multiplayer.multiplayer_peer = enet_peer

func add_player(peer_id, username):
	var player = PLAYER.instantiate()
	if username == null: username = str(peer_id)
	player.name = username
	add_child(player)
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)

func update_health_bar(health):
	health_bar.value = health

func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)

func remove_player(username):
	var player = get_node_or_null(str(username))
	if player:
		player.queue_free()

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")
	
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join Address: %s" % upnp.query_external_address())

func _on_check_box_toggled(toggled_on: bool) -> void:
	address.visible = !toggled_on
	localhost = toggled_on
