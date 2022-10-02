extends Spatial


var isGrabbed :bool= false;
enum states{IDLE,LOADED,RELEASED,IN_HAND,STUCK} 
var arrow_state = states.IDLE
var _bow_end
var _bow_begin 
var _speed 
var bow_strength
export var gravity_vec = Vector3.DOWN
export var gravity  = 9.8
export var mass =.01
var dir 
var velocity

func load_arrow(bow_end,bow_begin):
	arrow_state = states.LOADED
	_bow_end = bow_end
	_bow_begin = bow_begin
	
func unload_arrow():
	arrow_state = states.IDLE
	_bow_end = null
	_bow_begin = null
	
func release_arrow():
	arrow_state = states.RELEASED
	dir = _bow_begin.global_transform.origin-_bow_end.global_transform.origin
	_speed = bow_strength*(_bow_end.pull_distance-_bow_begin.string_rest_offset)
	velocity = (dir).normalized()*_speed
	_bow_begin = null
	_bow_end = null
	

func _on_disappear_timeout():
	queue_free()

func _physics_process(delta):
	match arrow_state:
		states.IDLE:
			$"../disappear".stop()
			$"../disappear".wait_time =20
		states.LOADED:
			global_transform.origin = _bow_end.global_transform.origin
			global_transform.origin += -global_transform.basis.z.normalized()*.07
			global_transform = global_transform.looking_at(_bow_begin.global_transform.origin,Vector3.RIGHT)
			$"../arrow_body".disabled = true
		states.RELEASED:
			velocity += (gravity*gravity_vec)*mass
			global_transform.origin += velocity*delta
			global_transform = global_transform.looking_at(velocity+global_transform.origin,Vector3.RIGHT)
			$"../arrow_body".disabled = false
			if $"../tip".is_colliding():
				var collider = $"../tip".get_collider()
				print(collider.name)
				if collider is PhysicsBody:
					if collider.has_method("die"):
						print("arrow entered eye")
						collider.die()
						queue_free()
					else:
						velocity = 0
						arrow_state = states.STUCK
		states.STUCK:
			velocity = 0
			$"../disappear".start()


func _on_arrow_picked_up(pickable):
	get_parent().mode = RigidBody.MODE_KINEMATIC
	isGrabbed = true
	pass # Replace with function body.


func _on_arrow_dropped(pickable):
	isGrabbed = false
	if arrow_state != states.LOADED:
		get_parent().mode = RigidBody.MODE_RIGID
	pass # Replace with function body.
