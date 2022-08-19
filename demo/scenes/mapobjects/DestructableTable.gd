extends Spatial
var destroyed = false
export var collision_layer_of_shard := 131073
export var collision_mask_of_shard := 131073
var scale_of_breakable_object := Vector3(1, 1, 1)
var scale_of_shards := Vector3.ZERO
var pickable_script = null
# Called when the node enters the scene tree for the first time.
func _ready():
	scale_of_breakable_object = $BreakableObject.scale # Replace with function body.
	scale_of_shards = scale_of_breakable_object
#	var pickable_script = load("res://addons/godot-xr-tools/objects/Object_pickable.gd")
#	print(get_parent().get_node("DemoGrabCube").collision_layer)
#	print(get_parent().get_node("DemoGrabCube").collision_mask)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Area_body_entered(body):
	if destroyed == false:
		if body.is_in_group("left_hand") or body.is_in_group("right_hand") or body.is_in_group("swords"):
			destroyed = true 
			$StaticBody.queue_free()
			$BreakableObject/Destruction.destroy()
			var shards = get_children()
			for shard in shards:
				shard.global_scale(scale_of_shards)
				var shard_children = shard.get_children()
				for shard_child in shard_children:
					if shard_child.has_method("set_collision_layer"):
						shard_child.set_collision_layer(collision_layer_of_shard)
						shard_child.set_collision_mask(collision_mask_of_shard)
#						shard_child.set_script(pickable_script)
						
