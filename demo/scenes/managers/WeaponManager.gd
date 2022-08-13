extends Node



var sword_group := []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass 


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	



func _on_Slicing_Katana_Long_picked_up(pickable):
	if pickable.picked_up_by != null and pickable.by_controller != null:
		unsheath_sword(pickable)# Replace with function body.
	else:
		sheath_sword(pickable)


func _on_Slicing_Katana_M_picked_up(pickable):
	if pickable.picked_up_by != null and pickable.by_controller != null:
		unsheath_sword(pickable)# Replace with function body.
	else:
		sheath_sword(pickable)

func _on_Slicing_Katana_S_picked_up(pickable):
	if pickable.picked_up_by != null and pickable.by_controller != null:
		unsheath_sword(pickable)# Replace with function body.
	else:
		sheath_sword(pickable)


func unsheath_sword(pickable_sword):
	pickable_sword.get_node("holder").visible = false
	
func sheath_sword(pickable_sword):
	pickable_sword.get_node("holder").visible = true
