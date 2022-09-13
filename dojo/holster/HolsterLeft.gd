extends XRTSnapZone


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	global_transform.origin = global_transform.origin + Vector3(-.33,.7,-.25) # Replace with function body.
	if is_inside_tree() and $HolsterMesh:
		$HolsterMesh.mesh.radius = grab_distance
		$HolsterMesh.mesh.height = grab_distance * 2
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	global_transform.basis.z = get_parent().get_parent().camera_node.global_transform.basis.x


func _on_HolsterLeft_body_entered(body):
	._on_Snap_Zone_body_entered(body)# Replace with function body.


func _on_HolsterLeft_body_exited(body):
	._on_Snap_Zone_body_exited(body) # Replace with function body.
