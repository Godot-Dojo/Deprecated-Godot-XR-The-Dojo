extends XRToolsPickable

onready var last_position = global_transform.origin
#export var impulse_factor = 5.0
export var enabled:bool = true
export var path_base:NodePath
export var path_tip:NodePath 
export var velocity_threshold:float # accepted velocity of object along point of entry 
export var angle_threshold:float # accepted angle from the normal in degrees 

var raycast:RayCast
enum states{STUCK,NOT_STUCK} 
var state = states.NOT_STUCK
var joint:Generic6DOFJoint = null
var base:Position3D
var tip:Position3D

# Called when the node enters the scene tree for the first time.
func _ready():
	if not enabled:
		return 
	base = get_node(path_base)
	tip = get_node(path_tip)
	for child in get_children():# starts from base 
		if child is RayCast:
			raycast = child
			break

func _physics_process(delta):
	if not enabled:
		return
	match state:
		states.STUCK:
			if not raycast.is_colliding():# need to constraint to axis when pulling out, need to figure that out 
				print("unstuck")
				#joint.queue_free()
				state = states.NOT_STUCK
		states.NOT_STUCK:
#			if !is_picked_up() and movement.length() > 0.001:
#				var forward = global_transform.basis.z
#				# dot product is 0.0 if perpendicular and 1.0 or -1.0 if parallel
#				var dot_inv = 1.0 - abs(forward.dot(movement.normalized()))
#				var impulse = -movement * dot_inv * impulse_factor
#				apply_impulse($spear_base.global_transform.origin - new_position, impulse)
			var velocity:Vector3 = self.linear_velocity
			var entry_direction:Vector3 = tip.global_transform.origin - base.global_transform.origin
			#project the linear velocity on entry_direction 
			var projected_vector = velocity.project(entry_direction)
			if joint:
				return
			if raycast.is_colliding() and projected_vector.length() >= velocity_threshold:
				# colliding and has enough velocity along axis we constraint 
				var collider = raycast.get_collider()
				var collision_normal = raycast.get_collision_normal()
				var entry_angle = rad2deg((-1*entry_direction).angle_to(collision_normal)) 
				print(entry_angle)
				if  entry_angle > angle_threshold:
					return  
				#var collision_point = raycast.get_collision_point()
				if collider is PhysicsBody:
					print("stuck")
					#joint = Generic6DOFJoint.new()
					#joint.set("nodes/node_a",collider)
					#joint.set("nodes/node_b",grab_object)
					#grab_object.get_parent().add_child(joint)
					#joint.global_transform.origin = collision_point
					#joint.global_transform.basis = grab_object.global_transform.basis
					self.sleeping = true
					#Draw3d.create_sphere([joint.global_transform.origin])
					state = states.STUCK
			
	
	
		
