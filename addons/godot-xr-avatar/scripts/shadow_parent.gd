extends Spatial


##player variables
var player_arvrorigin = null
var player_arvrcamera = null
var player_left_controller = null
var player_right_controller = null
var player_left_hand = null
var player_right_hand = null
var player_player_body = null

##avatar variables

#variables for avatar components
onready var arvrorigin = $FPController
onready var arvrcamera = $FPController/ARVRCamera
onready var left_controller = $FPController/LeftHandController
onready var right_controller = $FPController/RightHandController
onready var left_hand = $FPController/LeftHandController/LeftPhysicsHand
onready var right_hand = $FPController/RightHandController/RightPhysicsHand
onready var left_foot : BoneAttachment = $FPController/avatar/Armature/Skeleton/left_foot
onready var right_foot : BoneAttachment = $FPController/avatar/Armature/Skeleton/right_foot
onready var LL_ik : SkeletonIK = $FPController/avatar/Armature/Skeleton/SkeletonIKLegL
onready var RL_ik : SkeletonIK = $FPController/avatar/Armature/Skeleton/SkeletonIKLegR
onready var skeleton : Skeleton = $FPController/avatar/Armature/Skeleton


#export variables to fine tune avatar movement
export var height_offset := 0.0
export var foot_offset := 0.15
export var ik_raycast_height := 2.0
export var min_max_interpolation := Vector2(0.03, 0.9)
export var smoothing := 0.3


#Other variables needed for IK
var max_height : float
var avatar_height : float
var prev_move := Vector2.ZERO

#variables used for automatic creation of targets for IK and Raycasts
var left_hand_target : Position3D = null
var right_hand_target : Position3D = null
var left_target : Position3D = null
var right_target : Position3D = null
var left_target_transform : Position3D = null
var right_target_transform : Position3D = null
var Raycast_L : RayCast = null
var Raycast_R : RayCast = null
var RL_dB := Basis.IDENTITY
var LL_db := Basis.IDENTITY
var armature_scale := Vector3.ONE





# Called when the node enters the scene tree for the first time.
func _ready():
	
	#get player nodes - need to probably change these to export variables or proper terminology for hands when hand tracking
	player_arvrorigin = get_parent().get_node("avatar_player/FPController")
	player_arvrcamera = get_parent().get_node("avatar_player/FPController/ARVRCamera")
	player_left_controller = get_parent().get_node_or_null("avatar_player/FPController/LeftHandController")
	player_right_controller = get_parent().get_node_or_null("avatar_player/FPController/RightHandController")
	if player_left_controller != null:
		player_left_hand = get_parent().get_node("avatar_player/FPController/LeftHandController/LeftPhysicsHand")
	else:
		player_left_hand = get_parent().get_node("avatar_player/FPController/LeftPhysicsHand")
	if player_right_controller != null:
		player_right_hand = get_parent().get_node("avatar_player/FPController/RightHandController/RightPhysicsHand")
	else:
		player_right_hand = get_parent().get_node("avatar_player/FPController/RightPhysicsHand")
	player_player_body = get_parent().get_node("avatar_player/FPController/PlayerBody")
	
	#set avatar height and scale
	# Set shadow avatar scale
	avatar_height = $FPController/avatar/Armature/Skeleton/character_height.transform.origin.y
	$FPController/avatar/Armature.scale *= get_current_player_height() / avatar_height
	armature_scale = $FPController/avatar/Armature.scale
	max_height = get_current_player_height()
	
	
	#create all other nodes underneath avatar
	
	#create left hand and right hand targets automatically 	
	left_hand_target = Position3D.new()
	left_hand_target.name = "left_target"
	left_hand.add_child(left_hand_target, true)
	left_hand_target.rotation_degrees.y = 90
	left_hand_target.rotation_degrees.z = -90
	
	right_hand_target = Position3D.new()
	right_hand_target.name = "right_target"
	right_hand.add_child(right_hand_target, true)
	right_hand_target.rotation_degrees.y = -90
	right_hand_target.rotation_degrees.z = 90
	
	
	# match avatar hands to XR Tools hands positions
	#left_controller.get_node("left_target").translation = left_hand.translation
	#right_controller.get_node("right_target").translation = right_hand.translation
	
	#Automatically generate other helper target nodes used in the IK
	left_target = Position3D.new()
	left_target.name = "LL_c"
	$FPController/avatar.add_child(left_target, true)
	
		#used when hooking to left leg SkeletonIK
	left_target_transform = Position3D.new()
	left_target_transform.name = "LL_t"
	left_target.add_child(left_target_transform, true)
		
		#match target rotations to bone attachment rotations which are avatar-specific
	left_target_transform.rotation_degrees.x = left_foot.rotation_degrees.x + $FPController/avatar/Armature/Skeleton.rotation_degrees.x
	left_target_transform.rotation_degrees.y = left_foot.rotation_degrees.y + $FPController/avatar/Armature/Skeleton.rotation_degrees.y
	left_target_transform.rotation_degrees.z = left_foot.rotation_degrees.z + $FPController/avatar/Armature/Skeleton.rotation_degrees.z
	
	right_target = Position3D.new()
	right_target.name = "RL_c"
	$FPController/avatar.add_child(right_target, true)
	
		#used when hooking to right leg SkeletonIK
	right_target_transform = Position3D.new()
	right_target_transform.name = "Rl_t"
	right_target.add_child(right_target_transform, true)
		#match target rotations to bone attachment rotations which are avatar-specific
	right_target_transform.rotation_degrees.x = right_foot.rotation_degrees.x + $FPController/avatar/Armature/Skeleton.rotation_degrees.x
	right_target_transform.rotation_degrees.y = right_foot.rotation_degrees.y + $FPController/avatar/Armature/Skeleton.rotation_degrees.y
	right_target_transform.rotation_degrees.z = right_foot.rotation_degrees.z + + $FPController/avatar/Armature/Skeleton.rotation_degrees.z
	
	
	#Set skeleton targets to the automatically generated target nodes
	$FPController/avatar/Armature/Skeleton/SkeletonIKL.set_target_node(NodePath("../../../../" + left_controller.name + "/" + left_hand.name + "/left_target"))
	$FPController/avatar/Armature/Skeleton/SkeletonIKR.set_target_node(NodePath("../../../../" + right_controller.name + "/" + right_hand.name + "/right_target"))
	LL_ik.set_target_node(NodePath("../../../LL_c/LL_t"))
	RL_ik.set_target_node(NodePath("../../../RL_c/Rl_t"))
	
	#set other used variables
	RL_dB = left_target.transform.basis
	LL_db = right_target.transform.basis
	
	#automatically generate Left and Right RayCast nodes used in IK movement
	Raycast_L = RayCast.new()
	Raycast_L.name = "RayCastL"
	$FPController/avatar.add_child(Raycast_L, true)
	Raycast_L.enabled = true
	Raycast_L.cast_to = Vector3(0,-4,0)
	
	Raycast_R = RayCast.new()
	Raycast_R.name = "RayCastR"
	$FPController/avatar.add_child(Raycast_R, true)
	Raycast_R.enabled = true
	Raycast_R.cast_to = Vector3(0,-4,0)
	
	
	
	#set shadow avatar node transforms
	$FPController/LeftHandController.transform = get_left_controller_transform()
	$FPController/RightHandController.transform = get_right_controller_transform()
	$FPController.transform = get_arvr_origin_transform()
	$FPController/ARVRCamera.transform = get_arvr_camera_transform()
	$FPController/LeftHandController/LeftPhysicsHand.transform = get_left_hand_transform()
	$FPController/RightHandController/RightPhysicsHand.transform = get_right_hand_transform()

	#start the IK
	$FPController/avatar/Armature/Skeleton/SkeletonIKL.start()
	$FPController/avatar/Armature/Skeleton/SkeletonIKR.start()
	LL_ik.start()
	RL_ik.start()
	
	
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

func get_left_handpose_blend():
	return player_arvrorigin.get_node("avatar/AnimationTree").get("parameters/lefthandpose/blend_amount")
	
func get_left_trigger_blend():
	return player_arvrorigin.get_node("avatar/AnimationTree").get("parameters/lefthandposetrig/blend_amount")
	
	
func get_right_handpose_blend():
	return player_arvrorigin.get_node("avatar/AnimationTree").get("parameters/righthandpose/blend_amount")
	
func get_right_trigger_blend():
	return player_arvrorigin.get_node("avatar/AnimationTree").get("parameters/righthandposetrig/blend_amount")

		
		
func look_at_y(from: Vector3, to: Vector3, up_ref := Vector3.UP) -> Basis:
	var forward := (to-from).normalized()
	var right := up_ref.normalized().cross(forward).normalized()
	forward = right.cross(up_ref).normalized()
	return Basis(right, up_ref, forward)


func update_ik_anim(target: Spatial, raycast: RayCast, bone_attach: BoneAttachment, d_b: Basis, avatar_height: float, hit_offset: float) -> void:
	var bone_pos = bone_attach.global_transform.origin
	raycast.global_transform.origin = bone_pos + Vector3.UP*avatar_height
	target.global_transform.origin = bone_pos
	raycast.global_transform.origin
	target.global_transform.basis = d_b
	var hit_point = raycast.get_collision_point().y + hit_offset
	if raycast.is_colliding():
		target.global_transform.origin.y = hit_point
		if raycast.get_collision_normal() != Vector3.UP:
			target.global_transform.basis = look_at_y(Vector3.ZERO,$FPController/avatar/Armature.global_transform.basis.z,raycast.get_collision_normal())
	target.rotation.y = $FPController/avatar/Armature.rotation.y



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	#update transforms
	$FPController/LeftHandController.transform = get_left_controller_transform()
	$FPController/RightHandController.transform = get_right_controller_transform()
	$FPController.transform = get_arvr_origin_transform()
	$FPController/ARVRCamera.transform = get_arvr_camera_transform()
	$FPController/LeftHandController/LeftPhysicsHand.transform = get_left_hand_transform()
	$FPController/RightHandController/RightPhysicsHand.transform = get_right_hand_transform()
	
	# Move the avatar under the camera and facing in the direction of the camera
	var avatar_pos: Vector3 = arvrorigin.global_transform.xform(Plane.PLANE_XZ.project(arvrcamera.transform.origin))
	var avatar_dir_z := Plane.PLANE_XZ.project(arvrcamera.global_transform.basis.z).normalized()
	var avatar_dir_x := Vector3.UP.cross(avatar_dir_z)
	$FPController/avatar/Armature.global_transform = Transform(avatar_dir_x, Vector3.UP, avatar_dir_z, avatar_pos)
	$FPController/avatar/Armature.global_scale(armature_scale) #without this, armature scale reverts to pre-scaling values
	#print("Armature scale after physics process is:")
	#print($FPController/avatar/Armature.scale)
	
	
	# Position the skeleton Y to adjust for the player height
	skeleton.transform.origin.y = get_current_player_height() - avatar_height + height_offset
	
	
	# Rotate the head Y bone (look up/down)
	var head = skeleton.get_bone_pose(skeleton.find_bone("head"))
	var angles = arvrcamera.rotation
	angles.x *= -1;angles.z *= -1
	angles.y -= lerp_angle(angles.y,arvrcamera.rotation.y,delta)
	head.basis = Basis(angles)
	skeleton.set_bone_pose(skeleton.find_bone("head"),head)

	

	# Calculate foot movement based on players actual ground-movement velocity
	#var player_velocity := player_body.velocity# - player_body.ground_velocity
	#player_velocity = $Armature.global_transform.basis.xform_inv(player_velocity)
	#var move := Vector2(player_velocity.x, player_velocity.z)
	
	# Calculate foot movement based on playees requested ground-movement velocity
	var move = get_player_body_velocity()
	
	
	#switch to squat move pose if moving while in a crouch
	if abs(move.y) > .25 and get_current_player_height() < (.9 * max_height):
		$FPController/avatar/Armature/Skeleton/SkeletonIKLegL.magnet = lerp($FPController/avatar/Armature/Skeleton/SkeletonIKLegL.magnet, Vector3(1,3,3), delta)
		$FPController/avatar/Armature/Skeleton/SkeletonIKLegR.magnet = lerp($FPController/avatar/Armature/Skeleton/SkeletonIKLegR.magnet, Vector3(-1,3,3), delta)
	else:
		$FPController/avatar/Armature/Skeleton/SkeletonIKLegL.magnet = lerp($FPController/avatar/Armature/Skeleton/SkeletonIKLegL.magnet, Vector3(.2,0,1), delta)
		$FPController/avatar/Armature/Skeleton/SkeletonIKLegR.magnet = lerp($FPController/avatar/Armature/Skeleton/SkeletonIKLegR.magnet, Vector3(-.2,0,1), delta)

	
	# Perform player movement animation
	$FPController/avatar/AnimationTree.set("parameters/movement/blend_position",lerp(prev_move,move,smoothing))
	$FPController/avatar/AnimationTree.set("parameters/Add2/add_amount", 1)
	update_ik_anim(left_target,Raycast_L,left_foot,LL_db,ik_raycast_height,foot_offset)
	update_ik_anim(right_target,Raycast_R,right_foot,RL_dB,ik_raycast_height,foot_offset)
	LL_ik.interpolation = clamp(1,min_max_interpolation.x,min_max_interpolation.y)
	RL_ik.interpolation = clamp(1,min_max_interpolation.x,min_max_interpolation.y)
	
	
	prev_move = move

	
	#perform hand grip animations using AnimationTree by adding grip and trigger hand poses to IK animation
	$FPController/avatar/AnimationTree.set("parameters/lefthandpose/blend_amount", get_left_handpose_blend()) #get_left_controller_grip())
	$FPController/avatar/AnimationTree.set("parameters/righthandpose/blend_amount", get_right_handpose_blend()) #get_right_controller_grip())
	$FPController/avatar/AnimationTree.set("parameters/lefthandposetrig/blend_amount", get_left_trigger_blend()) #get_left_controller_trigger()) 
	$FPController/avatar/AnimationTree.set("parameters/righthandposetrig/blend_amount", get_right_trigger_blend()) #get_right_controller_trigger())

	
