extends XRToolsPickable
class_name StabWeapon

onready var last_position = global_transform.origin
onready var debug = $debug
onready var joint_debug = $'../debug'
#export var impulse_factor = 5.0
export var enabled:bool = true
export var path_base:NodePath
export var path_tip:NodePath 
export var velocity_threshold:float # accepted velocity of object along point of entry 
export var angle_threshold:float # accepted angle from the normal in degrees 

var raycast:RayCast
enum states{STUCK,NOT_STUCK} 
var state = states.NOT_STUCK
var joint:Joint = null
var base:Position3D
var tip:Position3D
var newMaterial = SpatialMaterial.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	if not enabled:
		return 
	newMaterial.flags_unshaded = true
	base = get_node(path_base)
	tip = get_node(path_tip)
	for child in get_children():# starts from base 
		if child is RayCast:
			raycast = child
	

func look_at_with_x(trans,new_x,v_up):
	trans.basis.x=new_x.normalized()
	trans.basis.z=v_up*-1
	trans.basis.y = trans.basis.z.cross(trans.basis.x).normalized();
	#Recompute z = y cross X
	trans.basis.z = trans.basis.x.cross(trans.basis.y).normalized();
	#trans.basis.y = trans.basis.y * -1   # <======= ADDED THIS LINE
	trans.basis = trans.basis.orthonormalized() # make sure it is valid 
	return trans

func create_joint(collider,collision_mormal,collision_point):
	joint = SliderJoint.new()
	joint.global_transform.origin = collision_point
	joint.transform = look_at_with_x(joint.transform,collision_mormal,Vector3.UP)
	joint_debug.global_transform = joint.transform
	joint.set("nodes/node_a",collider.get_path())
	joint.set("nodes/node_b",get_path())
	joint.set("linear_limit/upper_distance",0)
	joint.set("linear_limit/lower_distance",-.1)
	joint.set("linear_limit/softness",.01)
	joint.set("linear_limit/restitution",.01)
	joint.set("linear_limit/damping",16)
	joint.set("linear_ortho/softness",.01)
	joint.set("linear_ortho/restitution",.01)
	joint.set("linear_ortho/damping",16)
	joint.set("linear_motion/softness",.01)
	joint.set("linear_motion/restitution",.01)
	joint.set("linear_motion/damping",16)
	joint.set("collision/excluse_nodes",true)
	get_parent().add_child(joint)
	#self.sleeping = true

func _physics_process(delta):
	if not enabled:
		return
	match state:
		states.STUCK:
			if raycast.is_colliding():# need to constraint to axis when pulling out, need to figure that out 
				return
			joint.queue_free()
			newMaterial.albedo_color = Color.red
			debug.material_override = newMaterial
			state = states.NOT_STUCK
		states.NOT_STUCK:
			var velocity:Vector3 = self.linear_velocity
			var entry_direction:Vector3 = tip.global_transform.origin - base.global_transform.origin
			#project the linear velocity on entry_direction 
			var projected_vector = velocity.project(entry_direction.normalized())
			#print(velocity,entry_direction.normalized(),projected_vector,projected_vector.length())
			if projected_vector.length() < velocity_threshold:
				return
			newMaterial.albedo_color = Color.yellow
			debug.material_override = newMaterial
			if not raycast.is_colliding():
				return
			newMaterial.albedo_color = Color.yellowgreen
			debug.material_override = newMaterial
			# colliding and has enough velocity along axis we constraint 
			var collider = raycast.get_collider()
			if not collider is PhysicsBody:
				return
			newMaterial.albedo_color = Color.greenyellow
			debug.material_override = newMaterial
			var collision_normal = raycast.get_collision_normal()
			var collision_point = raycast.get_collision_point()
			var entry_angle = rad2deg((-1*entry_direction).angle_to(collision_normal)) 
			if  entry_angle > angle_threshold:
				return  
			create_joint(collider,entry_direction,collision_point)
			newMaterial.albedo_color = Color.green
			debug.material_override = newMaterial
			state = states.STUCK

#func _integrate_forces(s):
#	if state == states.STUCK:
#		var velocity = s.get_linear_velocity()
#		var angular_vel = s.get_angular_velocity()
#		var lvelocity = global_transform.basis.xform_inv(velocity)
#		var langvelocity = global_transform.basis.xform_inv(angular_vel)
#		lvelocity.x = 0 
#		lvelocity.z = 0
#		langvelocity.x = 0 
#		langvelocity.z = 0
#		velocity = global_transform.basis.xform(lvelocity)
#		angular_vel = global_transform.basis.xform(langvelocity)
#		s.set_linear_velocity(velocity) 
#		s.set_linear_velocity(angular_vel) 
