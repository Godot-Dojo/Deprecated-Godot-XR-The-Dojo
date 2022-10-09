extends KinematicBody
onready var skeleton = $root/Skeleton
onready var anim_tree = $root/AnimationTree
onready var state_machine = anim_tree.get("parameters/playback")
var action_state = null
onready var nav = get_parent()
var path=[]
var path_node=0
var del = 0

export (bool) var enabled = true
export var speed:float = 0
export var max_walk_speed:float = 3
export var max_run_speed:float = 5
export var acc:float = 2
export var turn_interpolation:float = .3
export var pursue_radius:float = 50
export var walk_radius:float = 20
export var attack_radius:float = 1.5
export (NodePath) var skeleton_path
signal dead
var zero_basis = Basis(Vector3.ZERO,Vector3.ZERO,Vector3.ZERO)
var target 
var target_transform 
enum ACTION{
	IDLE,
	PURSUE,
	ATTACKING,
	DYING
}
enum MOVE_TYPE{
	RUN,WALK
}
var move_type
func _ready():
	#physical_bones_setup()
	target = get_tree().get_root().get_camera()
	print(target)
	print(target.name)
	action_state = ACTION.IDLE

func pathfinding(delta):
	if path_node<path.size():
		var direction = (path[path_node] - global_transform.origin)
		if direction.length() <1:
			path_node+=1
		else:
			speed+=acc*delta
			move_and_slide(direction.normalized()*speed,Vector3.UP)
			if !path.empty():
				align_body(path[path_node])
	else:
		speed-=acc*delta
	match move_type:
		MOVE_TYPE.WALK:
			speed = clamp(speed,0,max_walk_speed)
		MOVE_TYPE.RUN:
			speed = clamp(speed,0,max_run_speed)

func move_to(pos:Vector3):
	path=nav.get_simple_path(global_transform.origin,pos)
	path_node=0
	
func align_body(target):
	var desired = global_transform.looking_at(target,Vector3.UP)
	var desired_rot= desired.basis.get_euler()
	desired_rot.y+=deg2rad(180)
	rotation.y=lerp_angle(rotation.y,desired_rot.y,turn_interpolation)

func attack():
	speed = 0
	var random = randf()
	if random < .25:
		state_machine.travel("attack_left")
	elif random < .5:
		state_machine.travel("attack_right")
	elif random < .75:
		state_machine.travel("attack_up")
	else:
		state_machine.travel("attack_down")

func behaviour(delta):
	target_transform = target.global_transform.origin
	#vr.vrCamera.global_transform.origin
	target_transform.y = 0 
	var dist_from_player = global_transform.origin.distance_to(target_transform)
	match action_state:
		ACTION.IDLE:
			if dist_from_player > pursue_radius:
				move_type = MOVE_TYPE.RUN
				return 
			if dist_from_player < walk_radius:
				move_type = MOVE_TYPE.WALK
				state_machine.travel("walk")
			else:
				move_type = MOVE_TYPE.RUN
				state_machine.travel("run")
			action_state = ACTION.PURSUE
		ACTION.PURSUE:
			pathfinding(delta)
			# attack radius  <  walk_radius  <  pursue radius 
			if dist_from_player > pursue_radius:
				action_state = ACTION.IDLE
				state_machine.travel("idle")
			match move_type:
				MOVE_TYPE.RUN:
					if dist_from_player < walk_radius:
						move_type = MOVE_TYPE.WALK
						state_machine.travel("walk")
				MOVE_TYPE.WALK:
					if dist_from_player < attack_radius:
						action_state = ACTION.ATTACKING
					state_machine.travel("walk")
			if del>3:
				del = 0
				move_to(target_transform)
		ACTION.ATTACKING:
			if dist_from_player > attack_radius:
				action_state = ACTION.PURSUE
				move_type = MOVE_TYPE.WALK
			attack()
			align_body(target)
		ACTION.DYING:
			set_physics_process(false) # start rigid body simulation i guess

func _physics_process(delta):
	if not enabled:
		return
	del+=delta
	behaviour(delta)

var bone_offsets = {
	"Hips":Transform(Vector3(1,0,0),Vector3(0,1,-.1),Vector3(0,.1,1),Vector3(0,5,-.5)*.01),
	"Spine":Transform(Basis(),Vector3(0,6,0)*.01),
	"Spine1":Transform(Basis(),Vector3(0,6.6,0)*.01),
	"Spine2":Transform(Basis(),Vector3(0,7.5,0)*.01),
	"Neck":Transform(Vector3(1,0,0),Vector3(0,1,.35),Vector3(0,-.35,1),Vector3(0,3.5,1.2)*.01),
	"Head":Transform(Vector3(1,0,0),Vector3(0,1,.35),Vector3(0,-.35,1),Vector3(0,10.5,4)*.01),
	"Shoulders":Transform(Basis(),Vector3(0,7,0)*.01),
	"Arms":Transform(Basis(),Vector3(0,14,0)*.01),
	"ForeArms":Transform(Basis(),Vector3(0,12,0)*.01),
	"Hands":Transform(Basis(),Vector3(0,9,0)*.01),
	"UpLegs":Transform(Basis(),Vector3(0,21,0)*.01),
	"Legs":Transform(Vector3(0,0,1),Vector3(0,1,0),Vector3(-1,0,0),Vector3(0,21,0)*.01),
	"Foots":Transform(Basis(),Vector3(0,9,0)*.01),
	"ToeBases":Transform(Vector3(0,0,1),Vector3(0,1,0),Vector3(-1,0,0),Vector3(0,3.5,0)*.01),
}

var joint_prop = {
	"Hips":[PhysicalBone.JOINT_TYPE_CONE,[10,30]],
	"Spine":[PhysicalBone.JOINT_TYPE_CONE,[20,30]],
	"Spine1":[PhysicalBone.JOINT_TYPE_CONE,[45,30]],
	"Spine2":[PhysicalBone.JOINT_TYPE_CONE,[45,30]],
	"Neck":[PhysicalBone.JOINT_TYPE_CONE,[60,90]],
	"Head":[PhysicalBone.JOINT_TYPE_CONE,[45,0]],
	"LeftShoulder":[PhysicalBone.JOINT_TYPE_CONE,[50,20]],
	"RightShoulder":[PhysicalBone.JOINT_TYPE_CONE,[50,20]],
	"LeftArm":[PhysicalBone.JOINT_TYPE_CONE,[80,180]],
	"RightArm":[PhysicalBone.JOINT_TYPE_CONE,[80,180]],
	"LeftForeArm":[PhysicalBone.JOINT_TYPE_HINGE,[170,0]],
	"RightForeArm":[PhysicalBone.JOINT_TYPE_HINGE,[0,-170]],
	"LeftHand":[PhysicalBone.JOINT_TYPE_CONE,[60,30]],
	"RightHand":[PhysicalBone.JOINT_TYPE_CONE,[60,30]],
	"LeftUpLeg":[PhysicalBone.JOINT_TYPE_CONE,[45,20]],
	"RightUpLeg":[PhysicalBone.JOINT_TYPE_CONE,[45,20]],
	"LeftLeg":[PhysicalBone.JOINT_TYPE_HINGE,[-170,0]],
	"RightLeg":[PhysicalBone.JOINT_TYPE_HINGE,[0,-170]],
	"LeftFoot":[PhysicalBone.JOINT_TYPE_CONE,[45,30]], 
	"RightFoot":[PhysicalBone.JOINT_TYPE_CONE,[45,30]],
	"LeftToeBase":[PhysicalBone.JOINT_TYPE_HINGE,[30,-30]],
	"RightToeBase":[PhysicalBone.JOINT_TYPE_HINGE,[-30,30]],
}


func single_bone_setup(bone_name , side = null):
	var path 
	var bone_dict_key
	var joint_prop_dict_key
	path = skeleton_path
	if side == "R":
		path =  str(skeleton_path) +"Physical Bone" + " Right" + bone_name
		bone_dict_key = bone_name+"s"
		joint_prop_dict_key = "Right" + bone_name
	elif side == "L":
		path = str(skeleton_path) +"Physical Bone" + " Left" + bone_name
		bone_dict_key = bone_name+"s"
		joint_prop_dict_key = "Left" + bone_name
	else:
		path = str(skeleton_path) +"Physical Bone" + " " + bone_name
		bone_dict_key = bone_name
		joint_prop_dict_key = bone_name
	get_node(path).body_offset = bone_offsets[bone_dict_key]
	print(bone_offsets[bone_dict_key])
	get_node(path).joint_type = joint_prop[joint_prop_dict_key][0]
	if joint_prop[joint_prop_dict_key][0] == PhysicalBone.JOINT_TYPE_CONE:
		get_node(path).set("joint_constraints/swing_span", joint_prop[joint_prop_dict_key][1][0])
		get_node(path).set("joint_constraints/twist_span", joint_prop[joint_prop_dict_key][1][1])
	elif joint_prop[joint_prop_dict_key][0] == PhysicalBone.JOINT_TYPE_HINGE:
		get_node(path).set("joint_constraints/angular_limit_enabled", true)
		get_node(path).set("joint_constraints/angular_limit_upper", joint_prop[joint_prop_dict_key][1][0])
		get_node(path).set("joint_constraints/angular_limit_lower", joint_prop[joint_prop_dict_key][1][1])


# can be used to auto setup phtsical bones later 
func physical_bones_setup():
	single_bone_setup("Hips")
	single_bone_setup("Spine")
	single_bone_setup("Spine1")
	single_bone_setup("Spine2")
	single_bone_setup("Neck")
	single_bone_setup("Head")
	single_bone_setup("Shoulder","L")
	single_bone_setup("Shoulder","R")
	single_bone_setup("Arm","L")
	single_bone_setup("Arm","R")
	single_bone_setup("ForeArm","L")
	single_bone_setup("ForeArm","R")
	single_bone_setup("Hand","L")
	single_bone_setup("Hand","R")
	single_bone_setup("UpLeg","L")
	single_bone_setup("UpLeg","R")
	single_bone_setup("Leg","L")
	single_bone_setup("Leg","R")
	single_bone_setup("Foot","L")
	single_bone_setup("Foot","R")
	single_bone_setup("ToeBase","L")
	single_bone_setup("ToeBase","R")

#func bone_transform():
#	for i in range(0,skeleton.get_bone_count()):
#		pass

#func die(emit = true):
#	if emit:
#		emit_signal("dead")
#	anim_tree.active = false
#	skeleton.physical_bones_start_simulation()
#	yield(get_tree().create_timer(4.0), "timeout")
#	queue_free()

