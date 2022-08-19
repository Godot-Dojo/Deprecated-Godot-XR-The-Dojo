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
var drop_left_item = false
var drop_right_item = false

#signal weapon_picked_up(weapon, weapon_name, holding_controller_name)
#signal weapon_holstered(weapon, weapon_name)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass 


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass



func _on_Slicing_Katana_Long_picked_up(pickable):
	if pickable.picked_up_by != null and pickable.by_controller != null:
		unsheath_sword(pickable)
		if pickable.by_controller.name == "LeftHandController":
			item_in_player_hand_left = pickable
		if pickable.by_controller.name == "RightHandController":
			item_in_player_hand_right = pickable
		shadow_pick_up_weapon(pickable.name, pickable.by_controller)
		#emit_signal("weapon_picked_up", pickable, pickable.name, pickable.by_controller.name)# Replace with function body.
	else:
		sheath_sword(pickable)
		shadow_drop_weapon(pickable.name, pickable.by_controller)
		
		#emit_signal("weapon_holstered", pickable, pickable.name)

func _on_Slicing_Katana_M_picked_up(pickable):
	if pickable.picked_up_by != null and pickable.by_controller != null:
		unsheath_sword(pickable)# Replace with function body.
		if pickable.by_controller.name == "LeftHandController":
			item_in_player_hand_left = pickable
		if pickable.by_controller.name == "RightHandController":
			item_in_player_hand_right = pickable
		shadow_pick_up_weapon(pickable.name, pickable.by_controller)
		#emit_signal("weapon_picked_up", pickable, pickable.name, pickable.by_controller.name)
	else:
		sheath_sword(pickable)
		shadow_drop_weapon(pickable.name, pickable.by_controller)
		
		
		#emit_signal("weapon_holstered", pickable, pickable.name)

func _on_Slicing_Katana_S_picked_up(pickable):
	if pickable.picked_up_by != null and pickable.by_controller != null:
		unsheath_sword(pickable)
		if pickable.by_controller.name == "LeftHandController":
			item_in_player_hand_left = pickable
		if pickable.by_controller.name == "RightHandController":
			item_in_player_hand_right = pickable
		shadow_pick_up_weapon(pickable.name, pickable.by_controller)
		# Replace with function body.
		#emit_signal("weapon_picked_up", pickable, pickable.name, pickable.by_controller.name)
	else:
		sheath_sword(pickable)
		shadow_drop_weapon(pickable.name, pickable.by_controller)
		
		
		#emit_signal("weapon_holstered", pickable, pickable.name)


func unsheath_sword(pickable_sword):
	pickable_sword.get_node("holder").visible = false
	
func sheath_sword(pickable_sword):
	pickable_sword.get_node("holder").visible = true
	

func shadow_pick_up_weapon(weapon_name, which_controller):
	var weapon_to_hold_scene = null
	if weapon_name == "Slicing_Katana_Long":
		weapon_to_hold_scene = long_sword_scene
	if weapon_name == "Slicing_Katana_M":
		weapon_to_hold_scene = medium_sword_scene
	if weapon_name == "Slicing_Katana_S":
		weapon_to_hold_scene = short_sword_scene
		
	shadow_group = get_tree().get_nodes_in_group("shadows")
	for shadow in shadow_group:
		var held_weapon = weapon_to_hold_scene.instance()
		var shadow_controller = shadow.get_node("FPController/"+ which_controller.name)
		var shadow_hand = null
		if which_controller.name == "LeftHandController":
			shadow_hand = shadow_controller.get_node("LeftPhysicsHand") 
		if which_controller.name == "RightHandController":
			shadow_hand = shadow_controller.get_node("RightPhysicsHand")
		shadow_hand.add_child(held_weapon)
		held_weapon.rotation_degrees.y = -90
		held_weapon.rotation_degrees.z = -90
		held_weapon.translation.y = .05
		held_weapon.translation.z = -.05
		if held_weapon.get_node_or_null("holder") != null:
			held_weapon.get_node("holder").visible = false
	
func shadow_drop_weapon(weapon_name, which_controller):
	shadow_group = get_tree().get_nodes_in_group("shadows")
	for shadow in shadow_group:
		if which_controller == null:
			if item_in_player_hand_left == null and item_in_player_hand_right == null:
				return
			
			if item_in_player_hand_left != null:
				if weapon_name == item_in_player_hand_left.name:
					var shadow_controller = shadow.get_node("FPController/LeftHandController")
					var shadow_hand = shadow_controller.get_node("LeftPhysicsHand")
					var shadow_weapon = shadow_hand.get_node(weapon_name)
					shadow_weapon.queue_free()
					drop_left_item = true

			
			if item_in_player_hand_right != null:
				if weapon_name == item_in_player_hand_right.name:
					var shadow_controller = shadow.get_node("FPController/RightHandController")
					var shadow_hand = shadow_controller.get_node("RightPhysicsHand")
					var shadow_weapon = shadow_hand.get_node(weapon_name)
					shadow_weapon.queue_free()
					drop_right_item = true

		
		if which_controller != null:
			var shadow_controller = shadow.get_node("FPController/"+ which_controller.name)
			var shadow_hand = null
			if which_controller.name == "LeftHandController":
				shadow_hand = shadow_controller.get_node("LeftPhysicsHand") 
			if which_controller.name == "RightHandController":
				shadow_hand = shadow_controller.get_node("RightPhysicsHand")
			var shadow_weapon = shadow_hand.get_node(weapon_name)
			shadow_weapon.queue_free()
			if which_controller.name == "LeftHandController":
				drop_left_item = true

			if which_controller.name == "RightHandController":
				drop_right_item = true
	
	
	if drop_left_item == true:			
		item_in_player_hand_left = null	
		drop_left_item = false
		
	if drop_right_item == true:
		item_in_player_hand_right = null
		drop_right_item = false	

func _on_Slicing_Katana_Long_dropped(pickable):
	shadow_drop_weapon(pickable.name, null) # Replace with function body.
	

func _on_Slicing_Katana_M_dropped(pickable):
	shadow_drop_weapon(pickable.name, null) # Replace with function body.


func _on_Slicing_Katana_S_dropped(pickable):
	shadow_drop_weapon(pickable.name, null) # Replace with function body.
