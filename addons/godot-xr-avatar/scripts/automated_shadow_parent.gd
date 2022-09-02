extends Spatial
#This script helps create a "shadow" or "mirror" avatar relatively automatically.  To use, click on the automated_shadow_player.tscn and mark "editable children", then
#Attach your avatar GLB or GLTF file as a child to the "FPController" position 3D node.  Make it local.  If you are using automated animations, then delete the animation player node.
#Make sure your avatar has the following structure: root node spatial called "avatar", then child node called "Armature" then node called "Skeleton."  Rename to make those nodes named that way if not.
#Export variables should appear and you can set the player_XXXX export variables to the node paths of the corresponding nodes in your player scene.  The playeravatar body path is for the root node of your avatar model IN THE PLAYER XR RIG, not the one for the shadow.
#The same types of other export variables appear as with the player automated avatar script to position the avatar, choose automatic animations, and choose lipsync

#set export variables to key elements of XR Rig necessary to link to shadow movement
export (NodePath) var player_arvrorigin_path = null
export (NodePath) var player_arvrcamera_path = null
export (NodePath) var player_left_controller_path = null
export (NodePath) var player_right_controller_path = null
export (NodePath) var player_left_hand_path = null
export (NodePath) var player_right_hand_path = null
export (NodePath) var player_avatar_body_path = null


#export variable to decide whether to turn avatar skeelton 180 degrees (on by default)
export var turn_character_180 := true


#export variables for whether someone will use LipSync or not, and if so, identify node that will contain mouth visemes
export var use_automated_lipsync := false
export (NodePath) var face_mesh_with_visemes_path = null

#export variable for whether using automated animation player and animation tree creation based on provided Godot-XR-avatar animations
enum AutomaticAnimation {
	NO,		# Don't use automatic animation creation, dev needs to create own animation player and tree nodes
	MAKEHUMAN,		# Use automatic animation creation for make human avatar
	MIXAMO,			# Use automatic animation creation for mixamo avatar
	READYPLAYERME   # Use automatic animation creation for readyplayerme avatar
}

#set default not to create animations so as to not overwrite what may have been custom created for imported avatar
export (AutomaticAnimation) var auto_anim_choice: int = AutomaticAnimation.NO


#export variables to fine tune avatar movement
export var height_offset := 0.25
export var foot_offset := 0.10
export var ik_raycast_height := 2.0
export var min_max_interpolation := Vector2(0.03, 0.9)
export var smoothing := 0.8
export var avatar_z_offset := .125


#variables used for SkeletonIK nodes and bone attachment nodes
var left_foot : BoneAttachment = null
var right_foot : BoneAttachment = null
var character_height : BoneAttachment = null
var SkeletonIKL : SkeletonIK = null
var SkeletonIKR : SkeletonIK = null
var SkeletonIKLegL : SkeletonIK = null
var SkeletonIKLegR : SkeletonIK = null


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


#variables used for bone references in SkeletonIK nodes and bone attachment nodes
var head_bone = null
var head_top_bone = null
var left_hand_bone = null
var right_hand_bone = null
var left_upper_arm_bone = null
var right_upper_arm_bone = null
var left_upper_leg_bone = null
var right_upper_leg_bone = null
var left_foot_bone = null
var right_foot_bone = null
var num_of_skeleton_bones = null
var substitute_head_bone = false

#variables used for lipsync if activated
var lipsync_node = null
var face_mesh : MeshInstance = null
var Viseme_Ch : float 
var Viseme_Dd : float 
var Viseme_E : float 
var Viseme_Ff : float
var Viseme_I : float
var Viseme_O : float
var Viseme_Pp : float
var Viseme_Rr : float
var Viseme_Ss : float
var Viseme_Th : float
var Viseme_U : float
var Viseme_AA : float
var Viseme_Kk : float
var Viseme_Nn : float
var Viseme_Sil : float
var blinktime : int = 0
var blink_time_set  := false
var blink_at : int = 0

#variables used for automatic animation player and tree if selected
var animationplayer : AnimationPlayer = null
var animationtree : AnimationTree = null


##player variables
onready var player_arvrorigin = get_node(player_arvrorigin_path)
onready var player_arvrcamera = get_node(player_arvrcamera_path)
onready var player_left_controller = get_node_or_null(player_left_controller_path)
onready var player_right_controller = get_node_or_null(player_right_controller_path)
onready var player_left_hand = get_node_or_null(player_left_hand_path)
onready var player_right_hand = get_node_or_null(player_right_hand_path)
onready var player_player_body = player_arvrorigin.get_node("PlayerBody")
onready var player_avatar_body = get_node(player_avatar_body_path)
##avatar variables

#variables for avatar components
onready var arvrorigin = $FPController
onready var arvrcamera = $FPController/ARVRCamera
onready var left_controller = $FPController/LeftHandController
onready var right_controller = $FPController/RightHandController
onready var left_hand = $FPController/LeftHandController/LeftPhysicsHand
onready var right_hand = $FPController/RightHandController/RightPhysicsHand
onready var skeleton : Skeleton = $FPController/avatar/Armature/Skeleton




# Called when the node enters the scene tree for the first time.
func _ready():

	#Display warning message if no animation tree or animation player found
	if (get_node_or_null("AnimationTree") == null or get_node_or_null("AnimationPlayer") == null) and auto_anim_choice == AutomaticAnimation.NO:
		print("Either or both of the AnimationTree and AnimationPlayer nodes not found, animations will not work.")
	
	#turn skeleton by 180 degrees if set by export variable (default) so facing the correct direction
	if turn_character_180 == true:
		skeleton.rotation_degrees.y = 180.0
	
	#set skeleton offset to desired value by player (usually skeletons have to be moved back some so player can see the body when looking down)
	skeleton.translation.z = avatar_z_offset
	
	
	#find the bones needed to set Skeleton IK nodes (head, head top, left upper arm and hand, right upper arm and hand, left upper leg and foot, right upper leg and foot)
	set_key_skeleton_nodes_for_IK(skeleton)
	
		
	if head_top_bone == null:
		head_top_bone = head_bone
		substitute_head_bone = true
	

	
	#create all other nodes underneath avatar
	#create bone attachment nodes and direct them to left and right foot bones
	left_foot = BoneAttachment.new()
	left_foot.name = "left_foot"
	skeleton.add_child(left_foot, true)
	left_foot.set_bone_name(skeleton.get_bone_name(left_foot_bone))
	
	
	right_foot = BoneAttachment.new()
	right_foot.name = "right_foot"
	skeleton.add_child(right_foot, true)
	right_foot.set_bone_name(skeleton.get_bone_name(right_foot_bone))
	
	
	
	#create character height bone attachment node and attach it to avatar head top end bone
	character_height = BoneAttachment.new()
	character_height.name = "character_height"
	skeleton.add_child(character_height, true)
	character_height.set_bone_name(skeleton.get_bone_name(head_top_bone))
	
	#set avatar height and scale
	# Set shadow avatar scale
	if substitute_head_bone == false:
		avatar_height = $FPController/avatar/Armature/Skeleton/character_height.transform.origin.y
	#if we didn't originally find a head end bone in the skeleton, look for alternatives
	else:
		#check for spatial that could be set by dev called "HeadEndBone", if exists, use that instead
		if get_node_or_null("FPController/avatar/Armature/Skeleton/HeadEndBone") != null:
			avatar_height = get_node("FPController/avatar/Armature/Skeleton/HeadEndBone").transform.origin.y
		#if there wasn't a head end bone and not a spatial substitute, use rough math for where the head end bone likely would be
		else:
			avatar_height = $FPController/avatar/Armature/Skeleton/character_height.transform.origin.y + .25
			
	$FPController/avatar/Armature.scale *= get_current_player_height() / avatar_height
	armature_scale = $FPController/avatar/Armature.scale
	max_height = get_current_player_height()
	
	
	#create SkeletonIK node called SkeletonIKL and set it to use the upper arm and hand bones with a magnet for IK
	SkeletonIKL = SkeletonIK.new()
	SkeletonIKL.name = "SkeletonIKL"
	skeleton.add_child(SkeletonIKL)
	SkeletonIKL.set_root_bone(skeleton.get_bone_name(left_upper_arm_bone))
	SkeletonIKL.set_tip_bone(skeleton.get_bone_name(left_hand_bone))
	SkeletonIKL.use_magnet = true
	if turn_character_180 == true:
		SkeletonIKL.set_magnet_position(Vector3(3,-5,-10))
	else:
		SkeletonIKL.set_magnet_position(Vector3(-3, -5, -10))
	
	
	#create SkeletonIK node called SkeletonIKR and set it to use the upper arm and hand bones with a magnet for IK
	SkeletonIKR = SkeletonIK.new()
	SkeletonIKR.name = "SkeletonIKR"
	skeleton.add_child(SkeletonIKR)
	SkeletonIKR.set_root_bone(skeleton.get_bone_name(right_upper_arm_bone))
	SkeletonIKR.set_tip_bone(skeleton.get_bone_name(right_hand_bone))
	SkeletonIKR.use_magnet = true
	if turn_character_180 == true:
		SkeletonIKR.set_magnet_position(Vector3(-3,-5,-10))
	else:
		SkeletonIKR.set_magnet_position(Vector3(3, -5, -10))
	
	#create SkeletonIK node called SkeletonIKLegL and set it to use the upper leg and foot with a magnet for IK
	SkeletonIKLegL = SkeletonIK.new()
	SkeletonIKLegL.name = "SkeletonIKLegL"
	skeleton.add_child(SkeletonIKLegL)
	SkeletonIKLegL.set_root_bone(skeleton.get_bone_name(left_upper_leg_bone))
	SkeletonIKLegL.set_tip_bone(skeleton.get_bone_name(left_foot_bone))
	SkeletonIKLegL.use_magnet = true
	if turn_character_180 == true:
		SkeletonIKLegL.set_magnet_position(Vector3(.2,0,1))
	else:
		SkeletonIKLegL.set_magnet_position(Vector3(-.2,0,1))
	
	#create SkeletonIK node called SkeletonIKLegR and set it to use the upper leg and foot with a magnet for IK
	SkeletonIKLegR = SkeletonIK.new()
	SkeletonIKLegR.name = "SkeletonIKLegR"
	skeleton.add_child(SkeletonIKLegR)
	SkeletonIKLegR.set_root_bone(skeleton.get_bone_name(right_upper_leg_bone))
	SkeletonIKLegR.set_tip_bone(skeleton.get_bone_name(right_foot_bone))
	SkeletonIKLegR.use_magnet = true
	if turn_character_180 == true:
		SkeletonIKLegR.set_magnet_position(Vector3(-.2,0,1))
	else:
		SkeletonIKLegR.set_magnet_position(Vector3(.2,0,1))
	
	#create left hand and right hand targets automatically 	
	left_hand_target = Position3D.new()
	left_hand_target.name = "left_target"
	left_hand.add_child(left_hand_target, true)
	left_hand_target.rotation_degrees.y = 90
	left_hand_target.rotation_degrees.z = -90
	
	#VRM values
	#left_hand_target.rotation_degrees.y = -90
	#left_hand_target.rotation_degrees.x = 90
	
	
	right_hand_target = Position3D.new()
	right_hand_target.name = "right_target"
	right_hand.add_child(right_hand_target, true)
	right_hand_target.rotation_degrees.y = -90
	right_hand_target.rotation_degrees.z = 90
	
	#VRM values
	#right_hand_target.rotation_degrees.y = 90
	#right_hand_target.rotation_degrees.x = 90
	
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
	if player_left_controller_path != null:
		SkeletonIKL.set_target_node(NodePath("../../../../" + left_controller.name + "/" + left_hand.name + "/left_target"))
	else:
		print("Left controller path not found, assuming just using hand node.")
		SkeletonIKL.set_target_node(NodePath("../../../../" + left_hand.name + "/left_target"))
	
	if player_right_controller_path != null:
		SkeletonIKR.set_target_node(NodePath("../../../../" + right_controller.name + "/" + right_hand.name + "/right_target"))
	else:
		print("Right controller path not found, assuming just using hand node.")
		SkeletonIKR.set_target_node(NodePath("../../../../" + right_hand.name + "/right_target"))
	
	SkeletonIKLegL.set_target_node(NodePath("../../../LL_c/LL_t"))
	SkeletonIKLegR.set_target_node(NodePath("../../../RL_c/Rl_t"))
	
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
	if player_left_controller_path != null:
		$FPController/LeftHandController.transform = get_left_controller_transform()
	
	if player_right_controller_path != null:
		$FPController/RightHandController.transform = get_right_controller_transform()
	
	$FPController.transform = get_arvr_origin_transform()
	$FPController/ARVRCamera.transform = get_arvr_camera_transform()
	$FPController/LeftHandController/LeftPhysicsHand.transform = get_left_hand_transform()
	$FPController/RightHandController/RightPhysicsHand.transform = get_right_hand_transform()

	#start the IK
	SkeletonIKL.start()
	SkeletonIKR.start()
	SkeletonIKLegL.start()
	SkeletonIKLegR.start()
	
	
	#if player chose to use LipSync in the export variables, create LipSync node
	if use_automated_lipsync == true:
		face_mesh = get_node_or_null(face_mesh_with_visemes_path)
		if face_mesh == null:
			print("LipSync activated but face mesh with visemes not chosen; will not work.")
		lipsync_node = LipSync.new()
		lipsync_node.name = "LipSync"
		add_child(lipsync_node,true)
		#### WILL NEED SOME CODE HERE TO SET VARIABLE OF SHADOW TO USE PLAYER'S MICROPHONE FOR LIPSYNC ###
		
	#create automatic animations if option selected
	if auto_anim_choice == AutomaticAnimation.NO:
		print("No automated animations selected. You need to have your own animationplayer and animation tree nodes.")
		
	elif auto_anim_choice == AutomaticAnimation.MAKEHUMAN:
		animationplayer = load("res://addons/godot-xr-avatar/animations/make_human_animations/AnimationPlayer.tscn").instance()
		animationplayer.name = "AnimationPlayer"
		$FPController/avatar.add_child(animationplayer,true)
		animationtree = load("res://addons/godot-xr-avatar/animations/make_human_animations/AnimationTree-MH-Complete.tscn").instance()
		animationtree.name = "AnimationTree"
		$FPController/avatar.add_child(animationtree, true)
		animationtree.active = true
	
	elif auto_anim_choice == AutomaticAnimation.MIXAMO:
		animationplayer = load("res://addons/godot-xr-avatar/animations/mixamo_animations/AnimationPlayer.tscn").instance()
		animationplayer.name = "AnimationPlayer"
		$FPController/avatar.add_child(animationplayer,true)
		animationtree = load("addons/godot-xr-avatar/animations/mixamo_animations/AnimationTree-mixamo-complete.tscn").instance()
		animationtree.name = "AnimationTree"
		$FPController/avatar.add_child(animationtree, true)
		animationtree.active = true
		
	elif auto_anim_choice == AutomaticAnimation.READYPLAYERME:
		animationplayer = load("res://addons/godot-xr-avatar/animations/ready_player_animations/AnimationPlayer.tscn").instance()
		animationplayer.name = "AnimationPlayer"
		$FPController/avatar.add_child(animationplayer,true)
		animationtree = load("res://addons/godot-xr-avatar/animations/ready_player_animations/AnimationTree-Readyplayer-Complete.tscn").instance()
		animationtree.name = "AnimationTree"
		$FPController/avatar.add_child(animationtree, true)
		animationtree.active = true	
		
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
	return player_avatar_body.get_node("AnimationTree").get("parameters/lefthandpose/blend_amount")
	
func get_left_trigger_blend():
	return player_avatar_body.get_node("AnimationTree").get("parameters/lefthandposetrig/blend_amount")
	
	
func get_right_handpose_blend():
	return player_avatar_body.get_node("AnimationTree").get("parameters/righthandpose/blend_amount")
	
func get_right_trigger_blend():
	return player_avatar_body.get_node("AnimationTree").get("parameters/righthandposetrig/blend_amount")

		
		
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


#function used for LipSync if activated, set visemes to the corresponding blend shapes in the facial mesh
func process_visemes(delta):
	Viseme_Ch = $LipSync.visemes[LipSync.VISEME.VISEME_CH]
	Viseme_Dd = $LipSync.visemes[LipSync.VISEME.VISEME_DD]
	Viseme_E = $LipSync.visemes[LipSync.VISEME.VISEME_E]
	Viseme_Ff = $LipSync.visemes[LipSync.VISEME.VISEME_FF]
	Viseme_I = $LipSync.visemes[LipSync.VISEME.VISEME_I]
	Viseme_O = $LipSync.visemes[LipSync.VISEME.VISEME_O]
#	Viseme_Pp = $LipSync.visemes[LipSync.VISEME.VISEME_PP]
	Viseme_Rr = $LipSync.visemes[LipSync.VISEME.VISEME_RR]
	Viseme_Ss = $LipSync.visemes[LipSync.VISEME.VISEME_SS]
	Viseme_Th = $LipSync.visemes[LipSync.VISEME.VISEME_TH]
	Viseme_U = $LipSync.visemes[LipSync.VISEME.VISEME_U]
	Viseme_AA = $LipSync.visemes[LipSync.VISEME.VISEME_AA]
	Viseme_Kk = $LipSync.visemes[LipSync.VISEME.VISEME_KK]
	Viseme_Nn = $LipSync.visemes[LipSync.VISEME.VISEME_NN]
	Viseme_Sil = $LipSync.visemes[LipSync.VISEME.VISEME_SILENT]
	
	face_mesh.set("blend_shapes/viseme_CH", Viseme_Ch)
	face_mesh.set("blend_shapes/viseme_DD", Viseme_Dd)
	face_mesh.set("blend_shapes/viseme_E", Viseme_E)
	face_mesh.set("blend_shapes/viseme_FF", Viseme_Ff)
	face_mesh.set("blend_shapes/viseme_I", Viseme_I)
	face_mesh.set("blend_shapes/viseme_O", Viseme_O)
#	face_mesh.set("blend_shapes/viseme_PP", Viseme_Pp)
	face_mesh.set("blend_shapes/viseme_RR", Viseme_Rr)
	face_mesh.set("blend_shapes/viseme_SS", Viseme_Ss)
	face_mesh.set("blend_shapes/viseme_TH", Viseme_Th)
	face_mesh.set("blend_shapes/viseme_U", Viseme_U)
	face_mesh.set("blend_shapes/viseme_aa", Viseme_AA)
	face_mesh.set("blend_shapes/viseme_kk", Viseme_Kk)
	face_mesh.set("blend_shapes/viseme_nn", Viseme_Nn)
#	face_mesh.set("blend_shapes/viseme_sil", Viseme_Sil)
	
	#lerping the silent value to try for smoother transitions
	face_mesh.set("blend_shapes/viseme_sil", lerp(face_mesh.get("blend_shapes/viseme_sil"), Viseme_Sil, delta))
	
	#Create random blinking effect
	if blink_time_set == false:
		var random = RandomNumberGenerator.new()
		random.randomize()
		blink_at = random.randi_range(200, 400) # set random blink time, ~every 5 or so seconds, sometimes more, sometimes less
		blink_time_set = true
	blinktime+=1
	if blinktime >= blink_at:
		face_mesh.set("blend_shapes/eyeBlinkLeft", 1)   # blink
		face_mesh.set("blend_shapes/eyeBlinkRight", 1)
		yield(get_tree().create_timer(.33), "timeout")  # average blink time is 1/3 of a second
		face_mesh.set("blend_shapes/eyeBlinkLeft", 0)
		face_mesh.set("blend_shapes/eyeBlinkRight", 0)  # unblink
		blinktime = 0
		blink_time_set = false  # set next blink time randomly again


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if use_automated_lipsync == true:
		process_visemes(delta)
	
	
	#update transforms
	if player_left_controller_path != null:
		$FPController/LeftHandController.transform = get_left_controller_transform()
	
	if player_right_controller_path != null:
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
	var head = skeleton.get_bone_pose(head_bone)
	var angles = arvrcamera.rotation
	angles.x *= -1;angles.z *= -1
	angles.y -= lerp_angle(angles.y,arvrcamera.rotation.y,delta)
	head.basis = Basis(angles)
	skeleton.set_bone_pose(head_bone,head)

	

	# Calculate foot movement based on players actual ground-movement velocity
	#var player_velocity := player_body.velocity# - player_body.ground_velocity
	#player_velocity = $Armature.global_transform.basis.xform_inv(player_velocity)
	#var move := Vector2(player_velocity.x, player_velocity.z)
	
	# Calculate foot movement based on playees requested ground-movement velocity
	var move = get_player_body_velocity()
	
	
	#switch to squat move pose if moving while in a crouch
	if abs(move.y) > .25 and get_current_player_height() < (.9 * max_height):
		if turn_character_180 == true:
			SkeletonIKLegL.magnet = lerp(SkeletonIKLegL.magnet, Vector3(1,3,3), delta)
			SkeletonIKLegR.magnet = lerp(SkeletonIKLegR.magnet, Vector3(-1,3,3), delta)
		else:
			SkeletonIKLegL.magnet = lerp(SkeletonIKLegL.magnet, Vector3(-1,3,3), delta)
			SkeletonIKLegR.magnet = lerp(SkeletonIKLegR.magnet, Vector3(1,3,3), delta)
	else:
		if turn_character_180 == true:
			SkeletonIKLegL.magnet = lerp(SkeletonIKLegL.magnet, Vector3(.2,0,1), delta)
			SkeletonIKLegR.magnet = lerp(SkeletonIKLegR.magnet, Vector3(-.2,0,1), delta)
		else:
			SkeletonIKLegL.magnet = lerp(SkeletonIKLegL.magnet, Vector3(-.2,0,1), delta)
			SkeletonIKLegR.magnet = lerp(SkeletonIKLegR.magnet, Vector3(.2,0,1), delta)
	
	
	# Perform player movement animation
	if $FPController/avatar.get_node_or_null("AnimationTree") != null:
		$FPController/avatar/AnimationTree.set("parameters/movement/blend_position",lerp(prev_move,move,smoothing))
		$FPController/avatar/AnimationTree.set("parameters/Add2/add_amount", 1)
	update_ik_anim(left_target,Raycast_L,left_foot,LL_db,ik_raycast_height,foot_offset)
	update_ik_anim(right_target,Raycast_R,right_foot,RL_dB,ik_raycast_height,foot_offset)
	SkeletonIKLegL.interpolation = clamp(1,min_max_interpolation.x,min_max_interpolation.y)
	SkeletonIKLegR.interpolation = clamp(1,min_max_interpolation.x,min_max_interpolation.y)
	
	prev_move = move

	
	#perform hand grip animations using AnimationTree by adding grip and trigger hand poses to IK animation
	if player_left_controller_path != null and player_right_controller_path != null and $FPController/avatar.get_node_or_null("AnimationTree") != null:
		$FPController/avatar/AnimationTree.set("parameters/lefthandpose/blend_amount", get_left_handpose_blend()) #get_left_controller_grip())
		$FPController/avatar/AnimationTree.set("parameters/righthandpose/blend_amount", get_right_handpose_blend()) #get_right_controller_grip())
		$FPController/avatar/AnimationTree.set("parameters/lefthandposetrig/blend_amount", get_left_trigger_blend()) #get_left_controller_trigger()) 
		$FPController/avatar/AnimationTree.set("parameters/righthandposetrig/blend_amount", get_right_trigger_blend()) #get_right_controller_trigger())

	
###Helper functions
#Used to find the proper naming of the bone nodes needed for IK, whicy may vary based on the avatar source
		
func set_key_skeleton_nodes_for_IK(skeleton_node):
	num_of_skeleton_bones = skeleton_node.get_bone_count()
	var head_set = false
	var head_top_set = false
	var l_upperarm_set = false
	var l_hand_set = false
	var r_upperarm_set = false
	var r_hand_set = false
	var l_upperleg_set = false
	var l_foot_set = false
	var r_upperleg_set = false
	var r_foot_set = false
	
	for i in range(0, num_of_skeleton_bones-1):
		var bone_name = skeleton_node.get_bone_name(i)
	#	print("Bone working on now is:")
	#	print(bone_name)
		
		if head_set == true and head_top_set == true and l_upperarm_set == true and l_hand_set == true and l_upperleg_set == true and l_foot_set == true and r_upperarm_set == true and r_hand_set == true and r_upperleg_set == true and r_foot_set == true:
			print("done looking at bones")
			return
		
		if bone_name.matchn("*head*"):
			if !(bone_name.matchn("*top*")) and !(bone_name.matchn("*end*")):
				if head_set == false:
					head_bone = skeleton_node.find_bone(bone_name)
					print(head_bone)
					print("Head bone name is:")
					print(skeleton_node.get_bone_name(i))
					head_set = true
				
			else:
				if head_top_set == false:
					head_top_bone = skeleton_node.find_bone(bone_name)
					print(head_top_bone)
					print("Head top bone name is:")
					print(skeleton_node.get_bone_name(i))
					head_top_set = true
				
		
		elif bone_name.matchn("*bicep*" ) or bone_name.matchn("*arm*"):
			if !(bone_name.matchn("*fore*")) and !(bone_name.matchn("*lower*")):
				if bone_name.matchn("*left*") or bone_name.matchn("*l_*") or bone_name.ends_with("_l"):
					if l_upperarm_set == false:
						left_upper_arm_bone = skeleton_node.find_bone(bone_name)
						print(left_upper_arm_bone)
						print("Left upper arm bone name is:")
						print(skeleton_node.get_bone_name(i))
						l_upperarm_set = true
				
				else:
					if r_upperarm_set == false:
						right_upper_arm_bone = skeleton_node.find_bone(bone_name)
						print(right_upper_arm_bone)
						print("Right upper arm bone name is:")
						print(skeleton_node.get_bone_name(i))
						r_upperarm_set = true
				
		elif bone_name.matchn("*upperleg*") or bone_name.matchn("*upper leg*") or bone_name.matchn("*upleg*") or bone_name.matchn("*thigh*"):
			if bone_name.matchn("*left*") or bone_name.matchn("*l_*") or bone_name.ends_with("_l"):
				if l_upperleg_set == false:
					left_upper_leg_bone = skeleton_node.find_bone(bone_name)
					print(left_upper_leg_bone)
					print("Left upper leg bone name is:")
					print(skeleton_node.get_bone_name(i))
					l_upperleg_set = true
				
			else:
				if r_upperleg_set == false:
					right_upper_leg_bone = skeleton_node.find_bone(bone_name)
					print(right_upper_leg_bone)
					print("Right upper leg bone name is:")
					print(skeleton_node.get_bone_name(i))
					r_upperleg_set = true
		
		elif bone_name.matchn("*hand*") and check_if_finger_bone(bone_name) == false:
			if bone_name.matchn("*left*") or bone_name.matchn("*l_*") or bone_name.ends_with("_l"):
				if l_hand_set == false:
					left_hand_bone = skeleton_node.find_bone(bone_name)
					print(left_hand_bone)
					print("Left hand bone name is:")
					print(skeleton_node.get_bone_name(i))
					l_hand_set = true
			else:
				if r_hand_set == false:
					right_hand_bone = skeleton_node.find_bone(bone_name)	
					print(right_hand_bone)
					print("Right hand bone is")
					print(skeleton_node.get_bone_name(i))
					r_hand_set = true
				
		elif bone_name.matchn("*foot*") or bone_name.matchn("*ankle*"):
			if bone_name.matchn("*left*") or bone_name.matchn("*l_*") or bone_name.ends_with("_l"):
				if l_foot_set == false:
					left_foot_bone = skeleton_node.find_bone(bone_name)
					print(left_foot_bone)
					print("Left foot bone is")
					print(skeleton_node.get_bone_name(i))
					l_foot_set = true
				
			else:
				if r_foot_set == false:
					right_foot_bone = skeleton_node.find_bone(bone_name)
					print(right_foot_bone)
					print("Right foot bone is")
					print(skeleton_node.get_bone_name(i))
					r_foot_set = true

#mini function to check if a bone is a hand bone or really a finger bone since some avatars may use the word "hand" in finger bones as well		
func check_if_finger_bone(bone):
	if bone.matchn("*index*") or bone.matchn("*pinky*") or bone.matchn("*ring*") or bone.matchn("*thumb*") or bone.matchn("*middle*"):
		#print("Possible hand bone detected, but turns out it was a finger")
		return true
	else:
		#print("Possible hand bone detected, checked if it was a finger and it was not")
		return false
			
