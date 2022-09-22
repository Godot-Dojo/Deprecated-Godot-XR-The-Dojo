tool
extends Area


var plane_point_a:Vector3
var plane_point_b:Vector3
var plane_point_c:Vector3
var entered_mesh = false
var cut_plane:Plane
	


	

func _on_SlicingArea_body_exited(body):
	if body is sliceable and entered_mesh == true:
#		plane_point_a = $mesh/A.global_transform.origin
#		plane_point_b = $mesh/B.global_transform.origin
#		plane_point_c = $mesh/C.global_transform.origin
#		body.cut_object(Plane(plane_point_a,plane_point_b,plane_point_c))# Replace with function body.
		body.cut_object(cut_plane)
		entered_mesh = false

#create cutting plane on enter instead of exit to better meet user's expectations of how slice will happen
func _on_SlicingArea_body_entered(body):
	if body is sliceable:
		if entered_mesh == false:
			plane_point_a = $mesh/A.global_transform.origin
			plane_point_b = $mesh/B.global_transform.origin
			plane_point_c = $mesh/C.global_transform.origin
			cut_plane = Plane(plane_point_a,plane_point_b,plane_point_c)
			entered_mesh = true
