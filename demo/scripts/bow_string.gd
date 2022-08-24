extends Spatial
onready var bow = get_parent();
var _controller : ARVRController = null;
var pulled = false
var pull_distance = 0

func oq_can_area_object_grab(controller):
#	print("BowStringGrab");
	return bow.isGrabbed;

func oq_area_object_grab_started(controller):
	if bow.isGrabbed:
		bow.bow_string = self
		_controller = controller
		pulled = true

func oq_area_object_grab_ended(controller):
	if bow.isGrabbed:
		bow.release_arrow()
		pulled = false

func _physics_process(delta):
	pass
	if pulled:
		pull_distance = bow.global_transform.origin.distance_to(_controller.global_transform.origin)
		pull_distance = clamp(pull_distance,bow.string_rest_offset,bow.string_rest_offset+bow.max_pull_distance)
		global_transform.origin = bow.global_transform.origin - bow.dir.normalized()*pull_distance
	if !pulled:
		pull_distance = bow.global_transform.origin.distance_to(global_transform.origin)
		pull_distance = lerp(pull_distance,bow.string_rest_offset,10*delta)
		global_transform.origin = bow.global_transform.origin - bow.dir.normalized()*pull_distance
