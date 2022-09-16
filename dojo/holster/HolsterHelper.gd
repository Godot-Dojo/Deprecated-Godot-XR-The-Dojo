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
	
	
	pass # Replace with function body.



func _process(dt):
	var viewDir = -vrCamera.global_transform.basis.z;
	viewDir.y = 0;
	viewDir = viewDir.normalized();
	
	var camPos = vrCamera.global_transform.origin;


	targetPosition = camPos + viewDir * distance;
#	
	currentPosition = targetPosition 
			

	look_at_from_position(currentPosition, camPos, Vector3(0,1,0));
