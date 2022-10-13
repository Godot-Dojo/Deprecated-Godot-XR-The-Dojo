extends Spatial
#This is an attempt to make a largely modular version of code created by SYBIOTE for the Oculus Toolkit created by NeoSparks314
#for a player VRIK avatar.  This script should be added to the spatial root of the avatar object.

#This code is NOT fully automated.  It does require some actions in the editor to work with the creation of some nodes.  
#It needs an AnimationTree node with proper animation blends set as a child of avatar and pointing to the character AnimationPlayer
#You also need to set the export variables to correspond with nodes in your XR Rig and choose whether you want to use LipSync.
#Detailed information on use will be in the readme of the Godot-XR-Avatar readme.

#set export variables to key elements of XR Rig necessary for avatar movement
export (NodePath) var arvrorigin_path = null
export (NodePath) var arvrcamera_path = null
export (NodePath) var left_controller_path = null
export (NodePath) var right_controller_path = null
export (NodePath) var left_hand_path = null
export (NodePath) var right_hand_path = null
export(Array, NodePath) var head_mesh_node_paths = []

#export variable to decide whether to turn avatar skeelton 180 degrees (on by default)
export var turn_character_180 : bool = true

#export variables to fine tune how to rotate avatar hands with respect to controller position [defaults tend to work with most models]
export var left_hand_rotation_degs : Vector3 = Vector3(0, 90, -90)
export var right_hand_rotation_degs : Vector3 = Vector3(0, -90, 90)

#export variables to hide head or physics hand mesh
export var head_visible : bool = false
export var hand_mesh_visible : bool = false

#export variables for whether someone will use LipSync or not, and if so, identify node that will contain mouth visemes
export var use_automated_lipsync : bool = false
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
export(float, 0.0, 120.0, 5.0) var max_body_angle := 30.0
export(float, 0.1, 5.0) var body_turn_duration := 1.0


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

#variables used for procedural walking animation option
export var use_procedural_walk := false
export var use_procedural_bounce := false
export var step_anim_height := .15
export var step_anim_time := .60
export var step_distance := .15
export var strafe_step_modifier := .5
export var max_legs_spread := .5
export var bounce_factor := .1
var is_walking_legs := false
var legs_anim_timer := 0.0
var l_leg_pos : Vector3
var r_leg_pos : Vector3
var last_l_leg_pos : Vector3
var last_r_leg_pos : Vector3
var default_step_distance := 0.0
var default_step_height := 0.0
var strafe_step_distance := 0.0
var strafe_step_height := 0.0
var body_direction : Vector3

#set all nodes 
onready var arvrorigin := ARVRHelpers.get_arvr_origin(self, arvrorigin_path)
onready var arvrcamera := ARVRHelpers.get_arvr_camera(self, arvrcamera_path)
onready var left_controller := ARVRHelpers.get_left_controller(self, left_controller_path)
onready var right_controller := ARVRHelpers.get_right_controller(self, right_controller_path)
onready var left_hand : Spatial = get_node(left_hand_path)
onready var right_hand : Spatial = get_node(right_hand_path)
onready var player_body = arvrorigin.get_node("PlayerBody")
onready var skeleton : Skeleton = $Armature/Skeleton

#In the ready function we automatically create most of the nodes used for the IK and set them to the right values
func _ready():
	
	#Display warning message if no animation tree or animation player found
	if (get_node_or_null("AnimationTree") == null or get_node_or_null("AnimationPlayer") == null) and auto_anim_choice == AutomaticAnimation.NO:
		print("Either or both of the AnimationTree and AnimationPlayer nodes not found, and auto animation set to no, so animations will not work.")
	
	#turn skeleton by 180 degrees if set by export variable (default) so facing the correct direction
	if turn_character_180 == true:
		skeleton.rotation_degrees.y = 180.0
	
	#set skeleton offset to desired value by player (usually skeletons have to be moved back some so player can see the body when looking down)
	skeleton.translation.z = avatar_z_offset
	
	#find the bones needed to set Skeleton IK nodes (head, head top, left upper arm and hand, right upper arm and hand, left upper leg and foot, right upper leg and foot)
	set_key_skeleton_nodes_for_IK(skeleton)
	
	#if no proper head_top bone found in skeleton try to make do with head bone as head_top bone with some offsets later applied in code
	if head_top_bone == null:
		head_top_bone = head_bone
		substitute_head_bone = true
		
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
	SkeletonIKL.min_distance = .001
	
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
	SkeletonIKR.min_distance = .001
	
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
	SkeletonIKLegL.min_distance = .001
	
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
	SkeletonIKLegR.min_distance = .001
	
	#set avatar height to player
	if substitute_head_bone == false:
		avatar_height = character_height.transform.origin.y
	
	#if we didn't originally find a head end bone in the skeleton, look for alternatives
	else:
		#check for spatial that could be set by dev called "HeadEndBone", if exists, use that instead
		if get_node_or_null("Armature/Skeleton/HeadEndBone") != null:
			avatar_height = get_node("Armature/Skeleton/HeadEndBone").transform.origin.y
		#if there wasn't a head end bone and not a spatial substitute, use rough math for where the head end bone likely would be
		else:
			avatar_height = character_height.transform.origin.y + .25
	
	$Armature.scale *= get_current_player_height()/avatar_height
	armature_scale = $Armature.scale
	max_height = get_current_player_height()
	#print("Armature scale at ready is:")
	#print($Armature.scale)
	
	#create left hand and right hand targets and child them to VR hands, these are used for the upper body Skeleton IK nodes (SkeletonIKR, SkeletonIKL)
	left_hand_target = Position3D.new()
	left_hand_target.name = "left_target"
	left_hand.add_child(left_hand_target, true)
	left_hand_target.rotation_degrees = left_hand_rotation_degs
	
	#VRM values
	#left_hand_target.rotation_degrees.y = -90
	#left_hand_target.rotation_degrees.x = 90
	
	right_hand_target = Position3D.new()
	right_hand_target.name = "right_target"
	right_hand.add_child(right_hand_target, true)
	right_hand_target.rotation_degrees = right_hand_rotation_degs
	
	#VRM values
	#right_hand_target.rotation_degrees.y = 90
	#right_hand_target.rotation_degrees.x = 90
	
	#Automatically generate other helper target nodes used in the IK for the foot IK calculations, LL_c, LL_t, RR_c, Rl_t)
	left_target = Position3D.new()
	left_target.name = "LL_c"
	add_child(left_target, true)
	
		#used when hooking to left leg SkeletonIK
	left_target_transform = Position3D.new()
	left_target_transform.name = "LL_t"
	left_target.add_child(left_target_transform, true)
		#match target rotations to foot bone attachment rotations which are avatar-specific
	left_target_transform.rotation_degrees.x = left_foot.rotation_degrees.x + $Armature/Skeleton.rotation_degrees.x
	left_target_transform.rotation_degrees.y = left_foot.rotation_degrees.y + $Armature/Skeleton.rotation_degrees.y
	left_target_transform.rotation_degrees.z = left_foot.rotation_degrees.z + $Armature/Skeleton.rotation_degrees.z
	
	right_target = Position3D.new()
	right_target.name = "RL_c"
	add_child(right_target, true)
	
		#used when hooking to right leg SkeletonIK
	right_target_transform = Position3D.new()
	right_target_transform.name = "Rl_t"
	right_target.add_child(right_target_transform, true)
		#match target rotations to bone attachment rotations which are avatar-specific
	right_target_transform.rotation_degrees.x = right_foot.rotation_degrees.x + $Armature/Skeleton.rotation_degrees.x
	right_target_transform.rotation_degrees.y = right_foot.rotation_degrees.y + $Armature/Skeleton.rotation_degrees.y
	right_target_transform.rotation_degrees.z = right_foot.rotation_degrees.z + + $Armature/Skeleton.rotation_degrees.z
	
	
	#Set skeleton targets to the automatically generated target nodes
	if left_controller_path != null:
		SkeletonIKL.set_target_node(NodePath("../../../../" + left_controller.name + "/" + left_hand.name + "/left_target"))
	else:
		print("Left controller path not found, assuming just using hand node.")
		SkeletonIKL.set_target_node(NodePath("../../../../" + left_hand.name + "/left_target"))
	
	if right_controller_path != null:
		SkeletonIKR.set_target_node(NodePath("../../../../" + right_controller.name + "/" + right_hand.name + "/right_target"))
	else:
		print("Right controller path not found, assuming just using hand node.")
		SkeletonIKR.set_target_node(NodePath("../../../../" + right_hand.name + "/right_target"))
	
	SkeletonIKLegL.set_target_node(NodePath("../../../LL_c/LL_t"))
	SkeletonIKLegR.set_target_node(NodePath("../../../RL_c/Rl_t"))
	
	#set other used variables in IK
	RL_dB = left_target.transform.basis
	LL_db = right_target.transform.basis
	
	#automatically generate Left and Right RayCast nodes used in IK movement
	Raycast_L = RayCast.new()
	Raycast_L.name = "RayCastL"
	add_child(Raycast_L, true)
	Raycast_L.enabled = true
	Raycast_L.cast_to = Vector3(0,-4,0)
	
	Raycast_R = RayCast.new()
	Raycast_R.name = "RayCastR"
	add_child(Raycast_R, true)
	Raycast_R.enabled = true
	Raycast_R.cast_to = Vector3(0,-4,0)
	
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
		
	
	#hide head to prevent visual glitches if export variable so indicates
	if head_visible == false:
		for mesh_path in head_mesh_node_paths:
			var head_mesh_part : MeshInstance = get_node(mesh_path)
			head_mesh_part.layers = 1 << 19
			
			
	#hide XR tools hand meshes if export variable so indicates
	if hand_mesh_visible == false:
		left_hand.visible = false
		right_hand.visible = false
		
		
	#create automatic animations if option selected
	if auto_anim_choice == AutomaticAnimation.NO:
		print("No automated animations selected. You need to have your own animationplayer and animation tree nodes.")
		
	elif auto_anim_choice == AutomaticAnimation.MAKEHUMAN:
		animationplayer = load("res://addons/godot-xr-avatar/animations/make_human_animations/AnimationPlayer.tscn").instance()
		animationplayer.name = "AnimationPlayer"
		add_child(animationplayer,true)
		animationtree = load("res://addons/godot-xr-avatar/animations/make_human_animations/AnimationTree-MH-Complete.tscn").instance()
		animationtree.name = "AnimationTree"
		add_child(animationtree, true)
		animationtree.active = true
	
	elif auto_anim_choice == AutomaticAnimation.MIXAMO:
		animationplayer = load("res://addons/godot-xr-avatar/animations/mixamo_animations/AnimationPlayer.tscn").instance()
		animationplayer.name = "AnimationPlayer"
		add_child(animationplayer,true)
		animationtree = load("res://addons/godot-xr-avatar/animations/mixamo_animations/AnimationTree-mixamo-complete.tscn").instance()
		animationtree.name = "AnimationTree"
		add_child(animationtree, true)
		animationtree.active = true
		
	elif auto_anim_choice == AutomaticAnimation.READYPLAYERME:
		animationplayer = load("res://addons/godot-xr-avatar/animations/ready_player_animations/AnimationPlayer.tscn").instance()
		animationplayer.name = "AnimationPlayer"
		add_child(animationplayer,true)
		animationtree = load("res://addons/godot-xr-avatar/animations/ready_player_animations/AnimationTree-Readyplayer-Complete.tscn").instance()
		animationtree.name = "AnimationTree"
		add_child(animationtree, true)
		animationtree.active = true	
	
	# Set variables for procedural walk		
	default_step_distance = step_distance
	default_step_height = step_anim_height
	strafe_step_distance = step_distance*strafe_step_modifier
	strafe_step_height = step_anim_height*strafe_step_modifier
	
	#The following line can be uncommented for further tweaking avatar legs/height (prevent "bowed legs")		
	#player_body.player_height_offset = height_offset
	
	# Calculate the body direction (in origin-space) from the head forward direction
	body_direction = Plane.PLANE_XZ.project(arvrcamera.transform.basis.z).normalized()

	
#function use to place avatar feet on surfaces procedurally
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
			target.global_transform.basis = look_at_y(Vector3.ZERO,$Armature.global_transform.basis.z,raycast.get_collision_normal())
	target.rotation.y = $Armature.rotation.y


#function used for LipSync if activated, set visemes to the corresponding blend shapes in the facial mesh
func process_visemes(delta:float) -> void:
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


#function used to generate procedural walk instead of using baked animations
func process_procedural_walk(delta: float, move: Vector2) -> void:
	var is_strafing = false
	var desired_l_leg_pos = Vector3.ZERO
	var desired_r_leg_pos = Vector3.ZERO
	# get initial foot positions when starting procedural walk
	l_leg_pos = left_target.global_transform.origin
	r_leg_pos = right_target.global_transform.origin
	
	# if not moving or if flying, stop walk animation
	if (abs(move.y) <= .1 and abs(move.x) <= .1) or player_body.on_ground == false:
		is_walking_legs = false
		
	# if player character is moving but the procedural animation has not started yet, start it, and set a timer for animation time
	if (abs(move.y) > .1 or abs(move.x) > .1) and is_walking_legs == false:
		last_l_leg_pos = l_leg_pos
		last_r_leg_pos = r_leg_pos
		legs_anim_timer = 0.0
		if abs(move.x) > .35:
			#if mostly strafing, change step height by modifer for strafe and tell walking legs strafing
			step_anim_height = strafe_step_height
			is_strafing = true
		else:
			#if not mostly strafing, use default step height instead and tell walking legs not strafing
			step_anim_height = default_step_height
			is_strafing = false
		is_walking_legs = true
	
	# the actual walking animation code
	if is_walking_legs:
		
		# set where we want the legs to go, set just a bit in the direction ahead of where the player is going
		desired_l_leg_pos = left_target.global_transform.origin + player_body.velocity.normalized()*step_distance
		desired_r_leg_pos = right_target.global_transform.origin + player_body.velocity.normalized()*step_distance
		
		#If not strafing or if strafing to the left, move left leg first
		if is_strafing == false or (is_strafing == true and move.x > 0):
			# half of animation time goes to left leg
			if legs_anim_timer / step_anim_time <= 0.5:
				var l_leg_interpolation_v = legs_anim_timer / step_anim_time * 2.0
				# moving leg in the direction of the player move
				l_leg_pos = last_l_leg_pos.linear_interpolate(desired_l_leg_pos, l_leg_interpolation_v)
				# moving leg up
				l_leg_pos = l_leg_pos + Vector3.UP * step_anim_height * sin(PI * l_leg_interpolation_v)
				# move the skeleton leg into the new position
				left_target.global_transform.origin = l_leg_pos
				# after this left leg has animated, get the position of where the right leg is before starting right leg anim (otherwise leg is in outdated position to start)
				last_r_leg_pos = r_leg_pos
			# half of animation time goes to right leg
			if legs_anim_timer / step_anim_time >= 0.5:
				var r_leg_interpolation_v = (legs_anim_timer / step_anim_time - 0.5) * 2.0
				# moving leg in the direction of the player move
				r_leg_pos = last_r_leg_pos.linear_interpolate(desired_r_leg_pos, r_leg_interpolation_v)
				# moving leg up
				r_leg_pos = r_leg_pos + Vector3.UP * step_anim_height * sin(PI * r_leg_interpolation_v)
				# move the skeleton leg into the new position
				right_target.global_transform.origin = r_leg_pos
			# increase timer time
			legs_anim_timer += delta
			
		# if strafing left, move right leg first rather than left
		elif is_strafing == true and move.x < 0:
		# half of animation time goes to right leg
			if legs_anim_timer / step_anim_time <= 0.5:
				var r_leg_interpolation_v = (legs_anim_timer / step_anim_time) * 2.0
				# moving leg in the direction of the player move
				r_leg_pos = last_r_leg_pos.linear_interpolate(desired_r_leg_pos, r_leg_interpolation_v)
				# moving leg up
				r_leg_pos = r_leg_pos + Vector3.UP * step_anim_height * sin(PI * r_leg_interpolation_v)
				# move the skeleton leg into the new position
				right_target.global_transform.origin = r_leg_pos
				# after this right leg has animated, get the position of where the left leg is before starting left leg anim (otherwise leg is in outdated position to start)
				last_l_leg_pos = l_leg_pos
		# half of animation time goes to left leg
			if legs_anim_timer / step_anim_time <= 0.5:
				var l_leg_interpolation_v = (legs_anim_timer / step_anim_time-0.5) * 2.0
				# moving leg in the direction of the player move
				l_leg_pos = last_l_leg_pos.linear_interpolate(desired_l_leg_pos, l_leg_interpolation_v)
				# moving leg up
				l_leg_pos = l_leg_pos + Vector3.UP * step_anim_height * sin(PI * l_leg_interpolation_v)
				# move the skeleton leg into the new position
				left_target.global_transform.origin = l_leg_pos
			# increase timer time
			legs_anim_timer += delta
		
		
		# if timer time is greater than whole animation time then stop animating
		if legs_anim_timer >= step_anim_time:
			is_walking_legs = false


#This is where the IK movement is actually done
func _physics_process(delta: float) -> void:
	if use_automated_lipsync == true:
		process_visemes(delta)

	# Calculate the head direction, and from it the body angle (from the head)
	var head_direction := Plane.PLANE_XZ.project(arvrcamera.transform.basis.z).normalized()
	var body_angle := rad2deg(head_direction.signed_angle_to(body_direction, Vector3.UP))

	# Clamp the body angle and step it towards zero
	body_angle = clamp(body_angle, -max_body_angle, max_body_angle)
	var turn_scale := clamp(abs(body_angle) / 10.0, 0.2, 1.0)
	var turn_rate := turn_scale * max_body_angle * delta / body_turn_duration
	var body_angle_step := min(abs(body_angle), turn_rate)
	body_angle -= body_angle_step * sign(body_angle)

	# Calculate the new body direction
	body_direction = head_direction.rotated(Vector3.UP, deg2rad(body_angle)).normalized()

	# Move the avatar under the camera and facing in the direction of the body
	var avatar_pos: Vector3 = arvrorigin.global_transform.xform(Plane.PLANE_XZ.project(arvrcamera.transform.origin))
	var avatar_dir_z: Vector3 = arvrorigin.global_transform.basis.xform(body_direction).normalized()
	var avatar_dir_x := Vector3.UP.cross(avatar_dir_z)
	$Armature.global_transform = Transform(avatar_dir_x, Vector3.UP, avatar_dir_z, avatar_pos)
	$Armature.global_scale(armature_scale*self.scale) #without this, armature scale reverts to pre-scaling values
	#print("Armature scale after physics process is:")
	#print($Armature.scale)
	
	# Position the skeleton Y to adjust for the player height
	skeleton.transform.origin.y = get_current_player_height() - avatar_height + height_offset
   
	# Rotate the head Y bone (look up/down)
	var head := skeleton.get_bone_pose(head_bone)
	var angles := arvrcamera.rotation
	angles.x *= -1; angles.z *= -1
	head.basis = Basis(angles)
	skeleton.set_bone_pose(head_bone,head)


	#perform hand grip animations using AnimationTree by adding grip and trigger hand poses to IK animation
	if left_controller_path != null and right_controller_path != null and get_node_or_null("AnimationTree") != null:
		$AnimationTree.set("parameters/lefthandpose/blend_amount", left_controller.get_joystick_axis(JOY_VR_ANALOG_GRIP))
		$AnimationTree.set("parameters/righthandpose/blend_amount", right_controller.get_joystick_axis(JOY_VR_ANALOG_GRIP))
		$AnimationTree.set("parameters/lefthandposetrig/blend_amount", left_controller.get_joystick_axis(JOY_VR_ANALOG_TRIGGER))
		$AnimationTree.set("parameters/righthandposetrig/blend_amount", right_controller.get_joystick_axis(JOY_VR_ANALOG_TRIGGER))
	
		
	# Calculate foot movement based on players actual ground-movement velocity
	#var player_velocity := player_body.velocity# - player_body.ground_velocity
	#player_velocity = $Armature.global_transform.basis.xform_inv(player_velocity)
	#var move := Vector2(player_velocity.x, player_velocity.z)
	
	# Calculate foot movement based on player's requested ground-movement velocity
	var move = player_body.ground_control_velocity

	#switch to squat move pose if moving while in a crouch
	if abs(move.y) > .25 and get_current_player_height() < (.9 * max_height):
		if turn_character_180 == true:
			$Armature/Skeleton/SkeletonIKLegL.magnet = lerp($Armature/Skeleton/SkeletonIKLegL.magnet, Vector3(1,3,3), delta)
			$Armature/Skeleton/SkeletonIKLegR.magnet = lerp($Armature/Skeleton/SkeletonIKLegR.magnet, Vector3(-1,3,3), delta)
		else:
			$Armature/Skeleton/SkeletonIKLegL.magnet = lerp($Armature/Skeleton/SkeletonIKLegL.magnet, Vector3(-1,3,3), delta)
			$Armature/Skeleton/SkeletonIKLegR.magnet = lerp($Armature/Skeleton/SkeletonIKLegR.magnet, Vector3(1,3,3), delta)
	else:
		if turn_character_180 == true:
			$Armature/Skeleton/SkeletonIKLegL.magnet = lerp($Armature/Skeleton/SkeletonIKLegL.magnet, Vector3(.2,0,1), delta)
			$Armature/Skeleton/SkeletonIKLegR.magnet = lerp($Armature/Skeleton/SkeletonIKLegR.magnet, Vector3(-.2,0,1), delta)
		else:
			$Armature/Skeleton/SkeletonIKLegL.magnet = lerp($Armature/Skeleton/SkeletonIKLegL.magnet, Vector3(-.2,0,1), delta)
			$Armature/Skeleton/SkeletonIKLegR.magnet = lerp($Armature/Skeleton/SkeletonIKLegR.magnet, Vector3(.2,0,1), delta)
	
	
	# Perform player movement animation
	if get_node_or_null("AnimationTree") != null and use_procedural_walk == false:
		$AnimationTree.set("parameters/movement/blend_position",lerp(prev_move,move,smoothing))
		$AnimationTree.set("parameters/Add2/add_amount", 1)
	update_ik_anim(left_target,Raycast_L,left_foot,LL_db,ik_raycast_height,foot_offset)
	update_ik_anim(right_target,Raycast_R,right_foot,RL_dB,ik_raycast_height,foot_offset)
	SkeletonIKLegL.interpolation = clamp(1,min_max_interpolation.x,min_max_interpolation.y)
	SkeletonIKLegR.interpolation = clamp(1,min_max_interpolation.x,min_max_interpolation.y)
	
	# Perform procedural walk if option selected
	if use_procedural_walk == true:
		process_procedural_walk(delta, move)
		
	# Perform procedural body bounce if option selected
	# Animate body up and down depending on distance between legs and factor set with variable if option chosen
	if use_procedural_bounce == true:
		skeleton.global_transform.origin += Vector3.DOWN * ((get_legs_spread(left_target.global_transform.origin, right_target.global_transform.origin) / max_legs_spread) * bounce_factor)
	
	prev_move = move





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
				if bone_name.matchn("*left*") or bone_name.matchn("*l_*") or bone_name.ends_with("_l") or bone_name.ends_with("_L"):
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
				
		elif bone_name.matchn("*leg*") or bone_name.matchn("*thigh*"):
			if bone_name.matchn("*upper*") or bone_name.matchn("*up*") or bone_name.matchn("*thigh*"):
				if bone_name.matchn("*left*") or bone_name.matchn("*l_*") or bone_name.ends_with("_l") or bone_name.ends_with("_L"):
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
		
		#fall back to wrist bone as hand if no matching hand bones; don't set l_hand_set = true and r_hand_set = true here, though, so if hand bone is later in bone chain it will still overwrite the wrist-as-hand selection
		elif bone_name.matchn("*wrist*") and check_if_finger_bone(bone_name) == false:
			if bone_name.matchn("*left*") or bone_name.matchn("*l_*") or bone_name.ends_with("_l") or bone_name.ends_with("_L"):
				if l_hand_set == false:
					left_hand_bone = skeleton_node.find_bone(bone_name)
					print(left_hand_bone)
					print("Left hand bone name is:")
					print(skeleton_node.get_bone_name(i))
					
			else:
				if r_hand_set == false:
					right_hand_bone = skeleton_node.find_bone(bone_name)	
					print(right_hand_bone)
					print("Right hand bone is")
					print(skeleton_node.get_bone_name(i))
					
		
		elif bone_name.matchn("*hand*") and check_if_finger_bone(bone_name) == false:
			if bone_name.matchn("*left*") or bone_name.matchn("*l_*") or bone_name.ends_with("_l") or bone_name.ends_with("_L"):
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
			if bone_name.matchn("*left*") or bone_name.matchn("*l_*") or bone_name.ends_with("_l") or bone_name.ends_with("_L"):
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
			
			
#Get distance between legs (used with procedural animation code)			
func get_legs_spread(left_leg_position : Vector3, right_leg_position: Vector3):
	return Vector2(left_leg_position.x, left_leg_position.z).distance_to(Vector2(right_leg_position.x, right_leg_position.z))


#Get current player height
func get_current_player_height() -> float:
	 return arvrcamera.transform.origin.y


#Use to set rotation
func look_at_y(from: Vector3, to: Vector3, up_ref := Vector3.UP) -> Basis:
	var forward := (to-from).normalized()
	var right := up_ref.normalized().cross(forward).normalized()
	forward = right.cross(up_ref).normalized()
	return Basis(right, up_ref, forward)

