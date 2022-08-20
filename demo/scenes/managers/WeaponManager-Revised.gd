extends Node

onready var long_sword_scene = load("res://demo/scenes/weapons/Slicing_Katana_Long.tscn")
onready var medium_sword_scene = load("res://demo/scenes/weapons/Slicing_Katana_M.tscn")
onready var short_sword_scene = load("res://demo/scenes/weapons/Slicing_Katana_S.tscn")
onready var shuriken_scene = load("res://demo/scenes/weapons/Throwing_Shuriken.tscn")
onready var shuriken_4spike_scene = load("res://demo/scenes/weapons/Throwing_Shuriken_4Spike.tscn")
onready var shuriken_4star_scene = load("res://demo/scenes/weapons/Throwing_Shuriken_4Star.tscn")
onready var shuriken_8star_scene = load("res://demo/scenes/weapons/Throwing_Shuriken_8Star.tscn")

var shadow_group := []
var sword_group := []
var shuriken_group := []
var item_in_player_hand_left = null
var item_in_player_hand_right = null
var left_function_pickup_node = null
var right_function_pickup_node = null



# Called when the node enters the scene tree for the first time.
func _ready():
	left_function_pickup_node = get_parent().get_node("avatar_player/FPController/LeftHandController/Function_Pickup")
	right_function_pickup_node = get_parent().get_node("avatar_player/FPController/RightHandController/Function_Pickup")
	left_function_pickup_node.connect("has_picked_up", self, "_on_left_function_pickup_picked_up_object")
	left_function_pickup_node.connect("has_dropped", self, "_on_left_function_pickup_dropped_object")
	right_function_pickup_node.connect("has_picked_up", self, "_on_right_function_pickup_picked_up_object")
	right_function_pickup_node.connect("has_dropped", self, "on_right_function_pickup_dropped_object")
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass
func _on_left_function_pickup_picked_up_object(object):
	var weapon_to_hold_scene = check_weapon_scene(object)
	if object.get_node_or_null("holder") != null:
		object.get_node("holder").visible = false
	shadow_group = get_tree().get_nodes_in_group("shadows")
	for shadow in shadow_group:
		var held_weapon = weapon_to_hold_scene.instance()
		var shadow_hand = shadow.get_node("FPController/LeftHandController/LeftPhysicsHand")
		shadow_hand.add_child(held_weapon)
		if object.name.begins_with("Slicing"):
			held_weapon.rotation_degrees.y = -90
			held_weapon.rotation_degrees.z = -90
			held_weapon.translation.y = .05
			held_weapon.translation.z = -.05
		if object.name.begins_with("Shuriken"):
			held_weapon.translation.z = -.15
		if held_weapon.get_node_or_null("holder") != null:
			held_weapon.get_node("holder").visible = false
	item_in_player_hand_left = object
	
func _on_left_function_pickup_dropped_object():
	if item_in_player_hand_left.get_node_or_null("holder") != null:
		item_in_player_hand_left.get_node("holder").visible = true
	
	shadow_group = get_tree().get_nodes_in_group("shadows")
	
	for shadow in shadow_group:
		var shadow_hand = shadow.get_node("FPController/LeftHandController/LeftPhysicsHand")
		var hand_children = shadow_hand.get_children()
		for child in hand_children:
			if item_in_player_hand_left.name.begins_with(child.name):
				var shadow_weapon = child
				shadow_weapon.queue_free()
	
	item_in_player_hand_left = null
	
func _on_right_function_pickup_picked_up_object(object):
	var weapon_to_hold_scene = check_weapon_scene(object)
	if object.get_node_or_null("holder") != null:
		object.get_node("holder").visible = false
	shadow_group = get_tree().get_nodes_in_group("shadows")
	for shadow in shadow_group:
		var held_weapon = weapon_to_hold_scene.instance()
		var shadow_hand = shadow.get_node("FPController/RightHandController/RightPhysicsHand")
		shadow_hand.add_child(held_weapon)
		if object.name.begins_with("Slicing"):
			held_weapon.rotation_degrees.y = -90
			held_weapon.rotation_degrees.z = -90
			held_weapon.translation.y = .05
			held_weapon.translation.z = -.05
		if object.name.begins_with("Shuriken"):
			held_weapon.translation.z = -.15
		if held_weapon.get_node_or_null("holder") != null:
			held_weapon.get_node("holder").visible = false
	item_in_player_hand_right = object

func on_right_function_pickup_dropped_object():
	if item_in_player_hand_right.get_node_or_null("holder") != null:
		item_in_player_hand_right.get_node("holder").visible = true
	
	shadow_group = get_tree().get_nodes_in_group("shadows")
	
	for shadow in shadow_group:
		var shadow_hand = shadow.get_node("FPController/RightHandController/RightPhysicsHand")
		var hand_children = shadow_hand.get_children()
		for child in hand_children:
			if item_in_player_hand_right.name.begins_with(child.name):
				var shadow_weapon = child
				shadow_weapon.queue_free()
	
	item_in_player_hand_right = null

func check_weapon_scene(object):
	if object.name.begins_with("Slicing_Katana_Long"):
		return long_sword_scene
	elif object.name.begins_with("Slicing_Katana_M"):
		return medium_sword_scene
	elif object.name.begins_with("Slicing_Katana_S"):
		return short_sword_scene
	elif object.name.begins_with("Shuriken_4Spike"):
		return shuriken_4spike_scene 
	elif object.name.begins_with("Shuriken_4Star"):
		return shuriken_4star_scene
	elif object.name.begins_with("Shuriken_8Star"):
		return shuriken_8star_scene
	elif object.name.begins_with("Shuriken"):
		return shuriken_scene
