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
	left_controller.get_node("Function_Pickup").connect("has_picked_up", self, "left_haptic_pulse_on_pickup")
	right_controller.get_node("Function_Pickup").connect("has_picked_up", self, "right_haptic_pulse_on_pickup")


func left_haptic_pulse_on_pickup(_what):
	left_controller.set_rumble(0.2)
	yield(get_tree().create_timer(0.2), "timeout")
	left_controller.set_rumble(0.0)

func right_haptic_pulse_on_pickup(_what):
	right_controller.set_rumble(0.2)
	yield(get_tree().create_timer(0.2), "timeout")
	right_controller.set_rumble(0.0)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
