extends XRToolsPickable
class_name StabWeapon

onready var last_position = global_transform.origin
onready var debug = $debug
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
	print("stuck",collider.name,collision_point,collision_mormal)
	joint = SliderJoint.new()
	joint.set("nodes/node_a",collider.get_path())
	joint.set("nodes/node_b",self.get_path())
	print(" tip:",tip.global_transform.origin ," point:",collision_point," base:",base.global_transform.origin)
	print("collsiion_to_tip ",(collision_point-tip.global_transform.origin).length())
	print("collsiion_to_base ",(collision_point-base.global_transform.origin).length())
	#joint.set("linear_limit/upper_distance",0)
	#joint.set("linear_limit/lower_distance",0)
	get_parent().add_child(joint)
	joint.global_transform.origin = collision_point
	joint.transform = look_at_with_x(joint.transform,collision_mormal,Vector3.UP)
	#self.sleeping = true
	print(joint.transform.basis.x)
	print(joint,joint,global_transform.origin)

func lock_axes(value):
	axis_lock_angular_x = value
	axis_lock_angular_z = value
	axis_lock_linear_x = value
	axis_lock_linear_z = value

func _physics_process(delta):
	if not enabled:
		return
	match state:
		states.STUCK:
			if raycast.is_colliding():# need to constraint to axis when pulling out, need to figure that out 
				return
			print("unstuck")
			joint.queue_free()
			newMaterial.albedo_color = Color.red
			debug.material_override = newMaterial
			#lock_axes(false)
			state = states.NOT_STUCK
		states.NOT_STUCK:
			if joint:
				return
			var velocity:Vector3 = self.linear_velocity
			var entry_direction:Vector3 = tip.global_transform.origin - base.global_transform.origin
			#project the linear velocity on entry_direction 
			var projected_vector = velocity.project(entry_direction.normalized())
			print(velocity,entry_direction.normalized(),projected_vector,projected_vector.length())
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
			#lock_axes(true)
			newMaterial.albedo_color = Color.green
			debug.material_override = newMaterial
			print("stuck")
			linear_velocity = Vector3.ZERO
			state = states.STUCK
			
func _integrate_forces(state):
	match state:
		states.STUCK:
			var velocity:Vector3 = state.get_linear_velocity()
			var entry_direction:Vector3 = tip.global_transform.origin - base.global_transform.origin
			var projected_vector = velocity.project(entry_direction.normalized())
			state.set_linear_velocity(projected_vector)
