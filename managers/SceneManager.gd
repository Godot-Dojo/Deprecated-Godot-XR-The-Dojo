extends Node



var current_scene = null
var scene_match = null

# Called when the node enters the scene tree for the first time.
func _ready():
	current_scene = get_tree().current_scene # Replace with function body.
	if current_scene.get_filename() == "res://make_human_demo/scenes/Godot Dojo.tscn":
		scene_match = "three_shadows"
	if current_scene.get_filename() == "res://make_human_demo/scenes/Godot Dojo_Female.tscn":
		scene_match = "female_avatar"
	if current_scene.get_filename() == "res://make_human_demo/scenes/Godot Dojo_Shurikens.tscn":
		scene_match = "weapons"
	if current_scene.get_filename() == "res://mixamo_demo/scenes/Godot_Dojo_Mixamo.tscn":
		scene_match = "mixamo"
	if current_scene.get_filename() == "res://readyplayerme_demo/scenes/Godot_Dojo_ReadyPlayerMe.tscn":
		scene_match = "ready_player"
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Feature_RadialMenu_entry_selected(entry):
	if entry == scene_match:
		return
	elif entry == "three_shadows": 
		get_tree().change_scene("res://make_human_demo/scenes/Godot Dojo.tscn")
	elif entry == "female_avatar":
		get_tree().change_scene("res://make_human_demo/scenes/Godot Dojo_Female.tscn")
	elif entry == "weapons":
		get_tree().change_scene("res://make_human_demo/scenes/Godot Dojo_Shurikens.tscn")
	elif entry == "mixamo":
		get_tree().change_scene("res://mixamo_demo/scenes/Godot_Dojo_Mixamo.tscn")
	elif entry == "ready_player":
		get_tree().change_scene("res://readyplayerme_demo/scenes/Godot_Dojo_ReadyPlayerMe.tscn")
	elif entry == "seated_or_standing": 	
		if get_parent().get_node("avatar_player/FPController/PlayerBody").player_height_offset == 0.0:
			get_parent().get_node("avatar_player/FPController/PlayerBody").player_height_offset = 0.5	
		else:
			get_parent().get_node("avatar_player/FPController/PlayerBody").player_height_offset = 0.0
