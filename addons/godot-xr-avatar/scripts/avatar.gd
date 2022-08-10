extends Spatial
#This is an attempt to make a largely modular version of code created by SYBIOTE for the Oculus Toolkit created by NeoSparks314
#for a player VRIK avatar.  This script should be added to the spatial root of the avatar object.

#This code is NOT fully automated.  It does require some actions in the editor to work with the creation of some nodes.  It needs: 
#(1) an AnimationTree node with proper animation blends set as a child of avatar and pointing to the character AnimationPlayer
#(2) SkeletonIKL node set to Root Bone of Left Shoulder and Tip Bone set to Left Hand, Use Magnet, Magnet.X = 10, Interpolation set to 1  
#(3) SkeletonIKR node set to Root Bone of Right Shoulder and Tip Bone set to Right Hand, Use Magnet, Magnet.X = -10, Interpolation set to 1 
#(4) SkeletonIKLegL node set to LeftUpLeg and Tip Bone set to LeftFoot, Use Magnet, Magnet (.2,0,1), Interpolation set to 1; 
#(5) SkeletonIKLegR node set to RightUpLeg and Tip Bone set to RightFoot, Use Magnet, Magnet (-.2,0,1), Interpolation set to 1; 
#(6) bone attachment for character_height set to top of avatar head/Head_Top_End
#(7) bone attachment right_foot set to RightFoot; 
#(8) bone attachment left_foot set to LeftFoot

#new TB code to set export variables to key elements of XR Rig necessary for avatar movement
#this makes this more modular because no longer depends on hardcoded naming of XR rig which players may have changed
export (NodePath) var arvrorigin_path = null
export (NodePath) var arvrcamera_path = null
export (NodePath) var left_controller_path = null
export (NodePath) var right_controller_path = null
export (NodePath) var left_hand_path = null
export (NodePath) var right_hand_path = null
export(Array, NodePath) var head_mesh_node_paths = []

## new TB code - enum and set avatar movement controller - the one that has the direct movement function
enum Avatar_Move_Controller {
	LEFT,		# Use left controller
	RIGHT,		# Use right controler
}

export (Avatar_Move_Controller) var avatar_move_controller: int = Avatar_Move_Controller.LEFT

# new TB code - variables for export nodes relating to XRRig
var arvrorigin : ARVROrigin
var arvrcamera : ARVRCamera
var left_controller :ARVRController
var right_controller : ARVRController
var left_hand = null
var right_hand = null
var _avatar_move_controller : ARVRController

#new TB code export variables to hide head or physics hand mesh
export var head_visible := false
export var hand_mesh_visible := false


#original SYBIOTE export variables to finetune avatar movement
export var height_offset:float = 0
export var foot_offset:float = .15
export var ik_raycast_height:float = 2
export var min_max_interpolation:Vector2 = Vector2(0.03,.9)
export var smoothing = 0.3

#set all nodes 

onready var left_foot = $Armature/Skeleton/left_foot
onready var right_foot = $Armature/Skeleton/right_foot
onready var LL_ik =$Armature/Skeleton/SkeletonIKLegL
onready var RL_ik = $Armature/Skeleton/SkeletonIKLegR
onready var skeleton = $Armature/Skeleton

#Other variables needed for IK
var max_height 
var avatar_height
var prev_move = Vector2(0,0)


#new TB variables used for automatic creation of targets for IK and Raycasts
var left_hand_target = null
var right_hand_target = null
var left_target = null
var right_target = null
var left_target_transform = null
var right_target_transform = null
var RL_dB = null
var LL_db = null
var Raycast_L = null
var Raycast_R = null

func _ready():
	#new TB code to set all nodes properly from export variables
	arvrorigin = get_node(arvrorigin_path)
	arvrcamera = get_node(arvrcamera_path)
	left_controller = get_node(left_controller_path)
	right_controller = get_node(right_controller_path)
	left_hand = get_node(left_hand_path)
	right_hand = get_node(right_hand_path)
	if avatar_move_controller == Avatar_Move_Controller.LEFT:
		_avatar_move_controller = left_controller
	else:
		_avatar_move_controller = right_controller
	
	#TB code to create left hand and right hand targets automatically that were already set in SYBIOTE's code	
	left_hand_target = Position3D.new()
	left_hand_target.name = "left_target"
	left_controller.add_child(left_hand_target, true)
	left_hand_target.rotation_degrees.y = 90
	left_hand_target.rotation_degrees.z = -90
	
	right_hand_target = Position3D.new()
	right_hand_target.name = "right_target"
	right_controller.add_child(right_hand_target, true)
	right_hand_target.rotation_degrees.y = -90
	right_hand_target.rotation_degrees.z = 90
	
	
	#TB code to match avatar hands to physics hands recommended positions
	left_controller.get_node("left_target").translation = left_hand.translation
	right_controller.get_node("right_target").translation = right_hand.translation
	
	#TB code to automatically generate other helper target nodes used in the IK
	left_target = Position3D.new()
	left_target.name = "LL_c"
	add_child(left_target, true)
	
		#used when hooking to left leg SkeletonIK
	left_target_transform = Position3D.new()
	left_target_transform.name = "LL_t"
	left_target.add_child(left_target_transform, true)
		#match target rotations to bone attachment rotations which are avatar-specific
	left_target_transform.rotation_degrees.x = left_foot.rotation_degrees.x + $Armature/Skeleton.rotation_degrees.x
			#add 180 here to account for new rotation of skeleton 180 degrees instead of avatar
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
		#add 180 here to account for new rotation of skeleton 180 degrees instead of avatar
	right_target_transform.rotation_degrees.y = right_foot.rotation_degrees.y + $Armature/Skeleton.rotation_degrees.y
	right_target_transform.rotation_degrees.z = right_foot.rotation_degrees.z + + $Armature/Skeleton.rotation_degrees.z
	
	
	#TB code to set skeleton targets to the automatically generated target nodes
	$Armature/Skeleton/SkeletonIKL.set_target_node(NodePath("../../../../" + left_controller.name + "/left_target"))
	$Armature/Skeleton/SkeletonIKR.set_target_node(NodePath("../../../../" + right_controller.name + "/right_target"))
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
	
	#set avatar height to player
	avatar_height= $Armature/Skeleton/character_height.global_transform.origin.y
	$Armature.scale *= get_current_player_height()/$Armature/Skeleton/character_height.global_transform.origin.y
	max_height = get_current_player_height()
	print($Armature.scale)
	
	#new TB code to hide head to prevent visual glitches if export variable so indicates; another way to do this might be to change the eyeforward offset
	if head_visible == false:
		for mesh_path in head_mesh_node_paths:
			var head_mesh_part = get_node(mesh_path)
			head_mesh_part.visible = false
		
		
	#new TB code to hide hands if export variable so indicates
	if hand_mesh_visible == false:
		left_hand.visible = false
		right_hand.visible = false
		
		
		
func look_at_y(from:Vector3 , to:Vector3, up_ref:Vector3 = Vector3.UP):
	var forward = (to-from).normalized()
	var right = up_ref.normalized().cross(forward).normalized()
	forward = right.cross(up_ref).normalized()
	return Basis(right,up_ref,forward)


func update_ik_anim(target,raycast,bone_attach,d_b,avatar_height,hit_offset):
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

func get_current_player_height():
	 return arvrcamera.transform.origin.y


func _physics_process(delta):
		# Move the avatar under the camera and facing in the direction of the camera
	var avatar_pos: Vector3 = arvrorigin.global_transform.xform(Plane.PLANE_XZ.project(arvrcamera.transform.origin))
	var avatar_dir_z := Plane.PLANE_XZ.project(arvrcamera.global_transform.basis.z).normalized()
	var avatar_dir_x := Vector3.UP.cross(avatar_dir_z)
	$Armature.global_transform = Transform(avatar_dir_x, Vector3.UP, avatar_dir_z, avatar_pos)
   
	# Position the skeleton Y to adjust for the player height
	skeleton.transform.origin.y = get_current_player_height() - avatar_height + height_offset
   
	# Rotate the head Y bone (look up/down)
	var head = skeleton.get_bone_pose(skeleton.find_bone("head"))
	var angles = arvrcamera.rotation
	angles.x *= -1;angles.z *= -1
	angles.y -= lerp_angle(angles.y,arvrcamera.rotation.y,delta)
	head.basis = Basis(angles)
	skeleton.set_bone_pose(skeleton.find_bone("head"),head)

	# Perform player movement animation
	var dx = -_avatar_move_controller.get_joystick_axis(0);
	var dy = _avatar_move_controller.get_joystick_axis(1);
	#var player_velocity_normalized = PlayerBody.get_player_body(arvrorigin).velocity.normalized()
	#var dx = player_velocity_normalized.x
	#var dy = player_velocity_normalized.z
	var move = Vector2(dx,dy)
	print(move)
	$AnimationTree.set("parameters/movement/blend_position",lerp(prev_move,move,smoothing))
	$AnimationTree.set("parameters/Add2/add_amount", 1)
	update_ik_anim(left_target,Raycast_L,left_foot,LL_db,ik_raycast_height,foot_offset)
	update_ik_anim(right_target,Raycast_R,right_foot,RL_dB,ik_raycast_height,foot_offset)
	LL_ik.interpolation = clamp(1,min_max_interpolation.x,min_max_interpolation.y)
	RL_ik.interpolation = clamp(1,min_max_interpolation.x,min_max_interpolation.y)
	var prev_move = move
	
