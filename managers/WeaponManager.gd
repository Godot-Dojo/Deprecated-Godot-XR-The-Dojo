extends Node

onready var long_sword_scene = load("res://weapons/Slicing_Katana_Long.tscn")
onready var medium_sword_scene = load("res://weapons/Slicing_Katana_M.tscn")
onready var short_sword_scene = load("res://weapons/Slicing_Katana_S.tscn")
onready var shuriken_scene = load("res://weapons/Throwing_Shuriken.tscn")
onready var shuriken_4spike_scene = load("res://weapons/Throwing_Shuriken_4Spike.tscn")
onready var shuriken_4star_scene = load("res://weapons/Throwing_Shuriken_4Star.tscn")
onready var shuriken_8star_scene = load("res://weapons/Throwing_Shuriken_8Star.tscn")
onready var backpack_scene = load("res://dojo/backpack/Backpack.tscn")
onready var backpack = get_parent().get_node_or_null("Backpack")
var shadow_group := []
var sword_group := []
var shuriken_group := []
var item_in_player_hand_left = null
var item_in_player_hand_right = null
var left_function_pickup_node = null
var right_function_pickup_node = null
var throttle_countdown = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	#connect left and right hand pickup functions
	left_function_pickup_node = get_parent().get_node("avatar_player/FPController/LeftHandController/Function_Pickup")
	right_function_pickup_node = get_parent().get_node("avatar_player/FPController/RightHandController/Function_Pickup")
	left_function_pickup_node.connect("has_picked_up", self, "_on_left_function_pickup_picked_up_object")
	left_function_pickup_node.connect("has_dropped", self, "_on_left_function_pickup_dropped_object")
	right_function_pickup_node.connect("has_picked_up", self, "_on_right_function_pickup_picked_up_object")
	right_function_pickup_node.connect("has_dropped", self, "_on_right_function_pickup_dropped_object")
	
	#connect snap zone pick up functions for sword holder 
	get_parent().get_node("HolderForPickableSwords/Snap_Zone").connect("has_picked_up", self, "_on_snap_zone_picked_up_object")
	get_parent().get_node("HolderForPickableSwords/Snap_Zone2").connect("has_picked_up", self, "_on_snap_zone_picked_up_object")
	get_parent().get_node("HolderForPickableSwords/Snap_Zone3").connect("has_picked_up", self, "_on_snap_zone_picked_up_object")
	
	#if scene has a backpack, set the weapon snap zones to require a group that does not exist so player can just pick up backpack without triggering snap zones
	if backpack != null:
		var inner_pack = backpack.get_node("In")
		var outer_pack = backpack.get_node("Out")
		var inner_snaps = inner_pack.get_children()
		var outer_snaps = outer_pack.get_children()
		for snap in inner_snaps:
			snap.grap_require = "disabled"
			snap.connect("has_picked_up", self, "_on_snap_zone_picked_up_object")
		for snap in outer_snaps:
			snap.grap_require = "disabled"
			snap.connect("has_picked_up", self, "_on_snap_zone_picked_up_object")
		
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	pass
	
	
	#example code of how to check if object is a given distance, example: 3 units, from player and if so, place back on player character
	#throttle how often to check for distance of backpack for performance reasons, rather than checking every frame
#	throttle_countdown += 1
#	if throttle_countdown >= 180:
#
#		#if backpack is too far from player, put automatically on shoulder
#		if backpack != null and backpack.is_picked_up() == false and (backpack.global_transform.origin - get_parent().get_node("avatar_player/FPController/ARVRCamera").global_transform.origin).length() >= 3:
#			var shoulder_holsters = get_tree().get_nodes_in_group("ShoulderHolster")
#
#			if shoulder_holsters == null:
#				throttle_countdown = 0
#				return
#
#			for holster in shoulder_holsters:
#				#put on empty shoulder slot if one is available
#				if holster.picked_up_object == null:
#					holster._pick_up_object(backpack)
#					break
#		throttle_countdown = 0	

func _on_left_function_pickup_picked_up_object(object):
	
	var weapon_to_hold_scene = check_weapon_scene(object)
	
	if weapon_to_hold_scene == null:
		return
	
	if weapon_to_hold_scene == backpack_scene:
		var inner_pack = object.get_node("In")
		var outer_pack = object.get_node("Out")
		var inner_snaps = inner_pack.get_children()
		var outer_snaps = outer_pack.get_children()
		for snap in inner_snaps:
			snap.grap_require = ""
		for snap in outer_snaps:
			snap.grap_require = ""
		return
		
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
	
	if item_in_player_hand_left == null:
		return
		
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
	
	if weapon_to_hold_scene == null:
		return
	
	if weapon_to_hold_scene == backpack_scene:
		var inner_pack = object.get_node("In")
		var outer_pack = object.get_node("Out")
		var inner_snaps = inner_pack.get_children()
		var outer_snaps = outer_pack.get_children()
		for snap in inner_snaps:
			snap.grap_require = ""
		for snap in outer_snaps:
			snap.grap_require = ""
		return
	
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

func _on_right_function_pickup_dropped_object():
	
	if item_in_player_hand_right == null:
		return
		
	shadow_group = get_tree().get_nodes_in_group("shadows")
	
	for shadow in shadow_group:
		var shadow_hand = shadow.get_node("FPController/RightHandController/RightPhysicsHand")
		var hand_children = shadow_hand.get_children()
		for child in hand_children:
			if item_in_player_hand_right.name.begins_with(child.name):
				var shadow_weapon = child
				shadow_weapon.queue_free()
	
	item_in_player_hand_right = null

#for weapons with sleeves/covers, put them on when in a snap zone
func _on_snap_zone_picked_up_object(object):
	if object.get_node_or_null("holder") != null:
		object.get_node("holder").visible = true

#compare object to weapon .tscns used in game to determine which it is
func check_weapon_scene(object):
	if object.name.begins_with("Backpack"):
		return backpack_scene
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
	return null

#If backpack dropped, freeze slots so player cannot accidentally grab weapons from slots while picking up backpack
func _on_Backpack_dropped(pickable):
	var inner_pack = pickable.get_node("In")
	var outer_pack = pickable.get_node("Out")
	var inner_snaps = inner_pack.get_children()
	var outer_snaps = outer_pack.get_children()
	for snap in inner_snaps:
		snap.grap_require = "none"
		
	for snap in outer_snaps:
		snap.grap_require = "none"
	
	#example code to automatically return backpack to player holster when dropped
	if pickable.picked_up_by == null and pickable.is_picked_up() == false:
		var shoulder_holsters = get_tree().get_nodes_in_group("ShoulderHolster")

		if shoulder_holsters == null:				
			return

		for holster in shoulder_holsters:
		#put on empty shoulder slot if one is available
			if holster.picked_up_object == null:
				holster._pick_up_object(backpack)
