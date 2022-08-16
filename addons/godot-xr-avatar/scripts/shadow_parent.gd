extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

#export (NodePath) var player_arvrorigin_path = null
#export (NodePath) var player_arvrcamera_path = null
#export (NodePath) var player_left_controller_path = null
#export (NodePath) var player_right_controller_path = null
#export (NodePath) var player_left_hand_path = null
#export (NodePath) var player_right_hand_path = null
#export (NodePath) var player_playerbody_path = null

#onready var player_arvrorigin = get_node(player_arvrorigin_path)
#onready var player_arvrcamera = get_node(player_arvrcamera_path)
#onready var player_left_controller = get_node(player_left_controller_path)
#onready var player_right_controller = get_node(player_right_controller_path)
#onready var player_left_hand : Spatial = get_node(player_left_hand_path)
#onready var player_right_hand : Spatial = get_node(player_right_hand_path)
#onready var player_player_body = get_node(player_playerbody_path)

var player_arvrorigin = null
var player_arvrcamera = null
var player_left_controller = null
var player_right_controller = null
var player_left_hand = null
var player_right_hand = null
var player_player_body = null
var armature_scale = null
# Called when the node enters the scene tree for the first time.
func _ready():
	#player_arvrorigin = get_node(player_arvrorigin_path)
	#player_arvrcamera = get_node(player_arvrcamera_path)
	#player_left_controller = get_node(player_left_controller_path)
	#player_right_controller = get_node(player_right_controller_path)
	#player_left_hand = get_node(player_left_hand_path)
	#player_right_hand = get_node(player_right_hand_path)
	#player_player_body = get_node(player_playerbody_path)
	
	player_arvrorigin = get_parent().get_node("avatar_player/FPController")
	player_arvrcamera = get_parent().get_node("avatar_player/FPController/ARVRCamera")
	player_left_controller = get_parent().get_node("avatar_player/FPController/LeftHandController")
	player_right_controller = get_parent().get_node("avatar_player/FPController/RightHandController")
	player_left_hand = get_parent().get_node("avatar_player/FPController/LeftHandController/LeftPhysicsHand")
	player_right_hand = get_parent().get_node("avatar_player/FPController/RightHandController/RightPhysicsHand")
	player_player_body = get_parent().get_node("avatar_player/FPController/PlayerBody")
	
	
	#set shadow avatar node transforms
	$FPController/LeftHandController.transform = get_left_controller_transform()
	$FPController/RightHandController.transform = get_right_controller_transform()
	$FPController.transform = get_arvr_origin_transform()
	$FPController/ARVRCamera.transform = get_arvr_camera_transform()
	$FPController/LeftHandController/LeftPhysicsHand.transform = get_left_hand_transform()
	$FPController/RightHandController/RightPhysicsHand.transform = get_right_hand_transform()

func get_current_player_height():
	return player_arvrcamera.transform.origin.y

func get_left_controller_transform():
	return player_left_controller.transform
	
func get_left_hand_transform():
	return player_left_hand.transform

func get_right_controller_transform():
	return player_right_controller.transform
	
func get_right_hand_transform():
	return player_right_hand.transform
		
func get_arvr_origin_transform():
	return player_arvrorigin.transform
	
func get_arvr_camera_transform():
	return player_arvrcamera.transform
	
func get_left_controller_grip():
	return player_left_controller.get_joystick_axis(JOY_VR_ANALOG_GRIP)
	
func get_left_controller_trigger():
	return player_left_controller.get_joystick_axis(JOY_VR_ANALOG_TRIGGER)
	
func get_right_controller_grip():
	return player_right_controller.get_joystick_axis(JOY_VR_ANALOG_GRIP)
	
func get_right_controller_trigger():
	return player_right_controller.get_joystick_axis(JOY_VR_ANALOG_TRIGGER)

func get_player_body_velocity():
	return player_player_body.ground_control_velocity


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	$FPController/LeftHandController.transform = get_left_controller_transform()
	$FPController/RightHandController.transform = get_right_controller_transform()
	$FPController.transform = get_arvr_origin_transform()
	$FPController/ARVRCamera.transform = get_arvr_camera_transform()
	$FPController/LeftHandController/LeftPhysicsHand.transform = get_left_hand_transform()
	$FPController/RightHandController/RightPhysicsHand.transform = get_right_hand_transform()
	
	
		#perform hand grip animations using AnimationTree by adding grip and trigger hand poses to IK animation
	$FPController/avatar/AnimationTree.set("parameters/lefthandpose/blend_amount", get_left_controller_grip())
	$FPController/avatar/AnimationTree.set("parameters/righthandpose/blend_amount", get_right_controller_grip())
	$FPController/avatar/AnimationTree.set("parameters/lefthandposetrig/blend_amount", get_left_controller_trigger()) 
	$FPController/avatar/AnimationTree.set("parameters/righthandposetrig/blend_amount", get_right_controller_trigger())

	
