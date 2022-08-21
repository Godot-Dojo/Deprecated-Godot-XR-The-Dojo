extends Spatial
#This is an attempt to make a largely modular version of code created by SYBIOTE for the Oculus Toolkit created by NeoSparks314
#for a player VRIK avatar.  This script should be added to the spatial root of the avatar object.

#This code is NOT fully automated.  It does require some actions in the editor to work with the creation of some nodes.  It needs: 
#(1) an AnimationTree node with proper animation blends set as a child of avatar and pointing to the character AnimationPlayer
#(2) SkeletonIKL node set to Root Bone of left upper arm and Tip Bone set to Left Hand, Use Magnet, Magnet.x = 3, Magnet.y = -5, Magnet z = -10, [old value was just Magnet.x = 10] Interpolation set to 1  
#(3) SkeletonIKR node set to Root Bone of Right Shoulder and Tip Bone set to Right Hand, Use Magnet, Magnet.x = -3, Magnet.y = -5, Magnet.z = -10, [old value was just Magnet.x = -10] Interpolation set to 1 
#(4) SkeletonIKLegL node set to LeftUpLeg and Tip Bone set to LeftFoot, Use Magnet, Magnet (.2,0,1), Interpolation set to 1; 
#(5) SkeletonIKLegR node set to RightUpLeg and Tip Bone set to RightFoot, Use Magnet, Magnet (-.2,0,1), Interpolation set to 1; 
#(6) bone attachment for character_height set to top of avatar head/Head_Top_End
#(7) bone attachment right_foot set to RightFoot; 
#(8) bone attachment left_foot set to LeftFoot

#set export variables to key elements of XR Rig necessary for avatar movement
#this makes this more modular because no longer depends on hardcoded naming of XR rig which players may have changed
export (NodePath) var arvrorigin_path = null
export (NodePath) var arvrcamera_path = null
export (NodePath) var left_controller_path = null
export (NodePath) var right_controller_path = null
export (NodePath) var left_hand_path = null
export (NodePath) var right_hand_path = null
export(Array, NodePath) var head_mesh_node_paths = []


#export variables to hide head or physics hand mesh
export var head_visible := false
export var hand_mesh_visible := false


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

#set all nodes 
onready var arvrorigin := ARVRHelpers.get_arvr_origin(self, arvrorigin_path)
onready var arvrcamera := ARVRHelpers.get_arvr_camera(self, arvrcamera_path)
onready var left_controller := ARVRHelpers.get_left_controller(self, left_controller_path)
onready var right_controller := ARVRHelpers.get_right_controller(self, right_controller_path)
onready var left_hand : Spatial = get_node(left_hand_path)
onready var right_hand : Spatial = get_node(right_hand_path)
onready var player_body := PlayerBody.get_player_body(self)
onready var left_foot : BoneAttachment = $Armature/Skeleton/left_foot
onready var right_foot : BoneAttachment = $Armature/Skeleton/right_foot
onready var LL_ik : SkeletonIK = $Armature/Skeleton/SkeletonIKLegL
onready var RL_ik : SkeletonIK = $Armature/Skeleton/SkeletonIKLegR
onready var skeleton : Skeleton = $Armature/Skeleton

func _ready():
	#set avatar height to player
	avatar_height = $Armature/Skeleton/character_height.transform.origin.y
	$Armature.scale *= get_current_player_height()/$Armature/Skeleton/character_height.transform.origin.y
	armature_scale = $Armature.scale
	max_height = get_current_player_height()
#	print("Armature scale at ready is:")
#	print($Armature.scale)
	
	#create left hand and right hand targets and child them to VR hands (new version to obviate IK reliance on controller nodes)
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
	
	#create left hand and right hand targets automatically that were already set in SYBIOTE's code	
	#left_hand_target = Position3D.new()
	#left_hand_target.name = "left_target"
	#left_controller.add_child(left_hand_target, true)
	#left_hand_target.rotation_degrees.y = 90
	#left_hand_target.rotation_degrees.z = -90
	
	#right_hand_target = Position3D.new()
	#right_hand_target.name = "right_target"
	#right_controller.add_child(right_hand_target, true)
	#right_hand_target.rotation_degrees.y = -90
	#right_hand_target.rotation_degrees.z = 90
	
	
	# match avatar hands to XR Tools hands positions
	#left_controller.get_node("left_target").translation = left_hand.translation
	#right_controller.get_node("right_target").translation = right_hand.translation
	
	#Automatically generate other helper target nodes used in the IK
	left_target = Position3D.new()
	left_target.name = "LL_c"
	add_child(left_target, true)
	
		#used when hooking to left leg SkeletonIK
	left_target_transform = Position3D.new()
	left_target_transform.name = "LL_t"
	left_target.add_child(left_target_transform, true)
		#match target rotations to bone attachment rotations which are avatar-specific
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
		$Armature/Skeleton/SkeletonIKL.set_target_node(NodePath("../../../../" + left_controller.name + "/" + left_hand.name + "/left_target"))
	else:
		print("Left controller path not found, assuming just using hand node.")
		$Armature/Skeleton/SkeletonIKL.set_target_node(NodePath("../../../../" + left_hand.name + "/left_target"))
	
	if right_controller_path != null:
		$Armature/Skeleton/SkeletonIKR.set_target_node(NodePath("../../../../" + right_controller.name + "/" + right_hand.name + "/right_target"))
	else:
		print("Right controller path not found, assuming just using hand node.")
		$Armature/Skeleton/SkeletonIKR.set_target_node(NodePath("../../../../" + right_hand.name + "/right_target"))
	
	LL_ik.set_target_node(NodePath("../../../LL_c/LL_t"))
	RL_ik.set_target_node(NodePath("../../../RL_c/Rl_t"))
	
	#set other used variables
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
	$Armature/Skeleton/SkeletonIKL.start()
	$Armature/Skeleton/SkeletonIKR.start()
	LL_ik.start()
	RL_ik.start()
	
	
	
	#hide head to prevent visual glitches if export variable so indicates; another way to do this might be to change the eyeforward offset
	if head_visible == false:
		for mesh_path in head_mesh_node_paths:
			var head_mesh_part : MeshInstance = get_node(mesh_path)
			head_mesh_part.layers = 1 << 19
			
		
		
	#hide XR tools hand meshes if export variable so indicates
	if hand_mesh_visible == false:
		left_hand.visible = false
		right_hand.visible = false
		
		
		
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
			target.global_transform.basis = look_at_y(Vector3.ZERO,$Armature.global_transform.basis.z,raycast.get_collision_normal())
	target.rotation.y = $Armature.rotation.y


func get_current_player_height() -> float:
	 return arvrcamera.transform.origin.y


func _physics_process(delta: float) -> void:
	# Move the avatar under the camera and facing in the direction of the camera
	var avatar_pos: Vector3 = arvrorigin.global_transform.xform(Plane.PLANE_XZ.project(arvrcamera.transform.origin))
	var avatar_dir_z := Plane.PLANE_XZ.project(arvrcamera.global_transform.basis.z).normalized()
	var avatar_dir_x := Vector3.UP.cross(avatar_dir_z)
	$Armature.global_transform = Transform(avatar_dir_x, Vector3.UP, avatar_dir_z, avatar_pos)
	$Armature.global_scale(armature_scale*self.scale) #without this, armature scale reverts to pre-scaling values
	#print("Armature scale after physics process is:")
	#print($Armature.scale)
	
	# Position the skeleton Y to adjust for the player height
	skeleton.transform.origin.y = get_current_player_height() - avatar_height + height_offset
   
	# Rotate the head Y bone (look up/down)
	var head := skeleton.get_bone_pose(skeleton.find_bone("head"))
	var angles := arvrcamera.rotation
	angles.x *= -1;angles.z *= -1
	angles.y -= lerp_angle(angles.y,arvrcamera.rotation.y,delta)
	head.basis = Basis(angles)
	skeleton.set_bone_pose(skeleton.find_bone("head"),head)


	#perform hand grip animations using AnimationTree by adding grip and trigger hand poses to IK animation
	if left_controller_path != null and right_controller_path != null:
		$AnimationTree.set("parameters/lefthandpose/blend_amount", left_controller.get_joystick_axis(JOY_VR_ANALOG_GRIP))
		$AnimationTree.set("parameters/righthandpose/blend_amount", right_controller.get_joystick_axis(JOY_VR_ANALOG_GRIP))
		$AnimationTree.set("parameters/lefthandposetrig/blend_amount", left_controller.get_joystick_axis(JOY_VR_ANALOG_TRIGGER))
		$AnimationTree.set("parameters/righthandposetrig/blend_amount", right_controller.get_joystick_axis(JOY_VR_ANALOG_TRIGGER))
	else:
		print("Can't find left or right controller path so cannot set hand animation blends")
		

	# Calculate foot movement based on players actual ground-movement velocity
	#var player_velocity := player_body.velocity# - player_body.ground_velocity
	#player_velocity = $Armature.global_transform.basis.xform_inv(player_velocity)
	#var move := Vector2(player_velocity.x, player_velocity.z)
	
	# Calculate foot movement based on playees requested ground-movement velocity
	var move := player_body.ground_control_velocity

	#switch to squat move pose if moving while in a crouch
	if abs(move.y) > .25 and get_current_player_height() < (.9 * max_height):
		$Armature/Skeleton/SkeletonIKLegL.magnet = lerp($Armature/Skeleton/SkeletonIKLegL.magnet, Vector3(1,3,3), delta)
		$Armature/Skeleton/SkeletonIKLegR.magnet = lerp($Armature/Skeleton/SkeletonIKLegR.magnet, Vector3(-1,3,3), delta)
	else:
		$Armature/Skeleton/SkeletonIKLegL.magnet = lerp($Armature/Skeleton/SkeletonIKLegL.magnet, Vector3(.2,0,1), delta)
		$Armature/Skeleton/SkeletonIKLegR.magnet = lerp($Armature/Skeleton/SkeletonIKLegR.magnet, Vector3(-.2,0,1), delta)
	

	# Perform player movement animation
	$AnimationTree.set("parameters/movement/blend_position",lerp(prev_move,move,smoothing))
	$AnimationTree.set("parameters/Add2/add_amount", 1)
	update_ik_anim(left_target,Raycast_L,left_foot,LL_db,ik_raycast_height,foot_offset)
	update_ik_anim(right_target,Raycast_R,right_foot,RL_dB,ik_raycast_height,foot_offset)
	LL_ik.interpolation = clamp(1,min_max_interpolation.x,min_max_interpolation.y)
	RL_ik.interpolation = clamp(1,min_max_interpolation.x,min_max_interpolation.y)
	prev_move = move
