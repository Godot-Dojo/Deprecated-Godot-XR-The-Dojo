extends XRToolsPickable

func get_collider_dict():
	var pickup_center = find_node("PickupCenter")
	var bounding_shape = self.find_node("SwordCollider")
	var shape_translate = pickup_center.transform.xform(bounding_shape.transform.origin)
	var shape_transform = Transform(pickup_center.transform.basis, shape_translate)
	return {bounding_shape : shape_transform}
