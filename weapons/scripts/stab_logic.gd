extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var tip_raycast = $"../tip"
onready var rigid_body = $"../"
# Called when the node enters the scene tree for the first time.
func _ready():
	print(tip_raycast.name)
	print(rigid_body.name)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
