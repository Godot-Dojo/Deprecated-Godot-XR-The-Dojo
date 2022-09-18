extends Spatial


var currentPosition;
var movePosition;
var targetPosition;
var distance =  0.02;

export (NodePath) var arvrcamera_path = null
#export var holster_move_speed = 10

var vrCamera = null

# Called when the node enters the scene tree for the first time.
func _ready():
	vrCamera = get_node(arvrcamera_path)
	var viewDir = -vrCamera.global_transform.basis.z;
	var camPos = vrCamera.global_transform.origin;
	currentPosition = camPos + viewDir * distance;
	targetPosition = currentPosition;
	movePosition = currentPosition;
	
	look_at_from_position(currentPosition, camPos, Vector3(0,1,0));
	
	var holsters = get_children()
	for holster in holsters:
		holster.connect("has_picked_up", self, "_on_holster_picked_up_object")
	
#if object in holster has a cover called "holder" apply it when holster snap zone picks up object
func _on_holster_picked_up_object(object):
	if object.get_node_or_null("holder") != null:
		object.get_node("holder").visible = true
		
		#Here you could put other code that is specific to certain weapons or items that might be in the holsters, e.g., to position them

func _process(dt):
	var viewDir = -vrCamera.global_transform.basis.z;
	viewDir.y = 0;
	viewDir = viewDir.normalized();
	
	var camPos = vrCamera.global_transform.origin;


	targetPosition = camPos + viewDir * distance;
#	
	currentPosition = targetPosition 
			

	look_at_from_position(currentPosition, camPos, Vector3(0,1,0));
