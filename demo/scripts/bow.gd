extends Spatial
class_name OQClass_Object
var isGrabbed:bool= false;
var _controller : ARVRController = null;
onready var upper_string = $bow_handle/Top
onready var lower_string  = $bow_handle/Bottom
onready var bow_string = $bow_string
export var bow_strength = 50
export var max_pull_distance = .6 
export var string_rest_offset  = .219
var arrow_loaded = false
var arrow 
var dir 
var _placeholder_rigidbody: RigidBody = null
var new_arrow = preload("res://scenes/objects/arrow.tscn")
func oq_can_area_object_grab(controller):
	return !isGrabbed;

func oq_area_object_grab_started(controller):
	print("object grabbed")
	global_transform = controller.get_grab_transform();
	isGrabbed = true;
	reparent_from_rigidbody()
	
func oq_area_object_grab_ended(controller):
	isGrabbed = false;
	reparent_to_rigidbody(
			controller.get_linear_velocity(),
			controller.get_angular_velocity())


func is_grabbed():
	return isGrabbed
func string_orient_lower():
	lower_string.global_transform = lower_string.global_transform.looking_at(bow_string.global_transform.origin,Vector3.RIGHT)
	lower_string.scale = Vector3.ONE
	var distance = upper_string.global_transform.origin.distance_to(bow_string.global_transform.origin)
	var rest_distance = (upper_string.global_transform.origin.distance_to(lower_string.global_transform.origin))/2
	var ratio = distance/rest_distance
	lower_string.scale.z = distance/rest_distance
func string_orient_upper():
	upper_string.global_transform = upper_string.global_transform.looking_at(bow_string.global_transform.origin,Vector3.RIGHT)
	upper_string.scale = Vector3.ONE
	var distance = lower_string.global_transform.origin.distance_to(bow_string.global_transform.origin)
	var rest_distance = (upper_string.global_transform.origin.distance_to(lower_string.global_transform.origin))/2
	var ratio = distance/rest_distance
	upper_string.scale.z = distance/rest_distance
func release_arrow():
	if arrow != null:
		arrow.bow_strength = bow_strength
		arrow.release_arrow()
		arrow_loaded = false
		arrow = null

func _ready():
	$bow_handle.connect("area_entered",self,"load_arrow_on_bow")
	
func load_arrow_on_bow():
	if arrow.has_method("load_arrow") and arrow.arrow_state ==  arrow.states.IDLE:
		arrow.load_arrow(bow_string,self)

func _physics_process(delta):
	string_orient_upper()
	string_orient_lower()
	dir = global_transform.origin - $bow_handle/bow.global_transform.origin
	if (bow_string.pull_distance-string_rest_offset)/max_pull_distance > .1 and arrow == null and bow_string.pulled:
		create_arrow()
#	var bodies = $bow_handle.get_overlapping_areas()
#	if len(bodies)>0 and arrow == null and isGrabbed:
#		for body in bodies:
#			if body.get_parent().has_method("load_arrow") and body.get_parent().arrow_state ==  body.get_parent().states.IDLE and body.get_parent().isGrabbed:
#				body.get_parent().load_arrow(bow_string,self)
#				arrow = body.get_parent()

func reparent_to_rigidbody(linear_velocity, angular_velocity):
	var old_transform = global_transform
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


func create_arrow():
	arrow = new_arrow.instance()
	var main_scene = get_tree().get_current_scene().get_node("main_scene")
	main_scene.add_child(arrow)
	arrow.global_transform = bow_string.global_transform
	arrow.scale = Vector3.ONE
	load_arrow_on_bow()
	
