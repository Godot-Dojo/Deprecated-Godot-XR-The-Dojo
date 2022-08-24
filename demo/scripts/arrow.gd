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
var _placeholder_rigidbody: RigidBody = null
var dir 
var velocity
var hand
func oq_can_area_object_grab(controller):
	return true;

func oq_area_object_grab_started(controller):
	global_transform = controller.get_grab_transform();
	isGrabbed = true;
	reparent_from_rigidbody()

func oq_area_object_grab_ended(controller):
	isGrabbed= false;
	if arrow_state != states.LOADED:
		reparent_to_rigidbody(
				controller.get_linear_velocity(),
				controller.get_angular_velocity())
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
	
func _controller_set(id):
	if id == vr.leftController.controller_id:
		hand = vr.leftController
	elif id == vr.rightController.controller_id:
		hand = vr.rightController
func _on_disappear_timeout():
	queue_free()
func _physics_process(delta):
	match arrow_state:
		states.IDLE:
			$disappear.stop()
			$disappear.wait_time =20
		states.LOADED:
			global_transform.origin = _bow_end.global_transform.origin
			global_transform.origin += -global_transform.basis.z.normalized()*.07
			global_transform = global_transform.looking_at(_bow_begin.global_transform.origin,Vector3.RIGHT)
			$Arrow_body/CollisionShape.disabled = true
		states.RELEASED:
			velocity += (gravity*gravity_vec)*mass
			global_transform.origin += velocity*delta
			global_transform = global_transform.looking_at(velocity+global_transform.origin,Vector3.RIGHT)
			$Arrow_body/CollisionShape.disabled = false
			if $tip.is_colliding():
				var collider = $tip.get_collider()
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
			$disappear.start()

func reparent_to_rigidbody(linear_velocity, angular_velocity):
	var old_transform = get_node("Arrow_body").global_transform
	global_transform = Transform.IDENTITY
	_placeholder_rigidbody = RigidBody.new()
	var children = get_children()
	for child in children:
		if not child is CollisionObject:
			continue
		for shape_owner_id in child.get_shape_owners():
			var body_shape_owner_id = _placeholder_rigidbody.create_shape_owner(_placeholder_rigidbody)
			
			var count = child.shape_owner_get_shape_count(shape_owner_id)
			_placeholder_rigidbody.shape_owner_set_transform(
				body_shape_owner_id,
				child.shape_owner_get_transform(shape_owner_id)
			)
			for idx in range(count):
				_placeholder_rigidbody.shape_owner_add_shape(
					body_shape_owner_id,
					child.shape_owner_get_shape(shape_owner_id, idx).duplicate()
				)
	_placeholder_rigidbody.set_global_transform(old_transform)
	_placeholder_rigidbody.set_axis_velocity(linear_velocity)
	_placeholder_rigidbody.angular_velocity = angular_velocity
	var old_parent = get_parent()
	old_parent.remove_child(self)
	old_parent.add_child(_placeholder_rigidbody)
	_placeholder_rigidbody.add_child(self)
	set_owner(_placeholder_rigidbody)

func reparent_from_rigidbody():
	if not _placeholder_rigidbody:
		return
	var new_parent = _placeholder_rigidbody.get_parent()
	_placeholder_rigidbody.remove_child(self)
	_placeholder_rigidbody.free()
	_placeholder_rigidbody = null
	new_parent.remove_child(_placeholder_rigidbody)
	new_parent.add_child(self)
	set_owner(new_parent)


func _on_blade_area_entered(area):
	if area != null and area.owner != null:
		if area.owner.has_method("dismember"):
			area.owner.dismember(area.name)
			print("dismembering in arrow")
