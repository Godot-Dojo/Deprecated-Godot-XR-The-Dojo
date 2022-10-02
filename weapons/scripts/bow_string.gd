tool
extends Spatial
onready var bow = get_parent();
onready var upper_string = $"../Top"
onready var lower_string  = $"../Bottom"

var _controller : ARVRController = null;
var pulled = false
var pull_distance = 0

func string_orient_lower():
	lower_string.global_transform = lower_string.global_transform.looking_at(global_transform.origin,Vector3.RIGHT)
	lower_string.scale = Vector3.ONE
	var distance = upper_string.global_transform.origin.distance_to(global_transform.origin)
	var rest_distance = (upper_string.global_transform.origin.distance_to(lower_string.global_transform.origin))/2
	var ratio = distance/rest_distance
	lower_string.scale.z = distance/rest_distance
	
func string_orient_upper():
	upper_string.global_transform = upper_string.global_transform.looking_at(global_transform.origin,Vector3.RIGHT)
	upper_string.scale = Vector3.ONE
	var distance = lower_string.global_transform.origin.distance_to(global_transform.origin)
	var rest_distance = (upper_string.global_transform.origin.distance_to(lower_string.global_transform.origin))/2
	var ratio = distance/rest_distance
	upper_string.scale.z = distance/rest_distance
	
func _physics_process(delta):
	string_orient_upper()
	string_orient_lower()
	if pulled:
		pull_distance = bow.global_transform.origin.distance_to(_controller.global_transform.origin)
		pull_distance = clamp(pull_distance,bow.string_rest_offset,bow.string_rest_offset+bow.max_pull_distance)
		global_transform.origin = bow.global_transform.origin - bow.dir.normalized()*pull_distance
	if !pulled:
		pull_distance = bow.global_transform.origin.distance_to(global_transform.origin)
		pull_distance = lerp(pull_distance,bow.string_rest_offset,10*delta)
		global_transform.origin = bow.global_transform.origin - bow.dir.normalized()*pull_distance
