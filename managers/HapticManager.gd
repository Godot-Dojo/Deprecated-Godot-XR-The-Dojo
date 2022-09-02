extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var left_controller : ARVRController = null
var right_controller : ARVRController = null
var arvrorigin : ARVROrigin = null


# Called when the node enters the scene tree for the first time.
func _ready():
	arvrorigin = get_parent().get_node("avatar_player").get_node("FPController") # Replace with function body.
	left_controller = ARVRHelpers.get_left_controller(arvrorigin)
	right_controller = ARVRHelpers.get_right_controller(arvrorigin)
	left_controller.get_node("Function_Pickup").connect("has_picked_up", self, "haptic_pulse_on_pickup")
	right_controller.get_node("Function_Pickup").connect("has_picked_up", self, "haptic_pulse_on_pickup")


func haptic_pulse_on_pickup(what):
	#What is passed as a parameter by the has_picked_up signal and is the object pickable, in turn that has a _by_controller property that yield the picked up controller
	what.by_controller.set_rumble(0.2)
	yield(get_tree().create_timer(0.2), "timeout")
	what.by_controller.set_rumble(0.0)# Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
