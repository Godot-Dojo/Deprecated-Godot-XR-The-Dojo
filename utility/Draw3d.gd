extends ImmediateGeometry

const IG_SPHERE = preload("res://utility/IG_sphere.tscn")
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


func create_line(points):
	if points == null || points.size()<=1:
		return 
	clear()
	begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in points:
		add_vertex(p)
	end()


	
func create_sphere(points):
	remove_all()
	for p in points:
		var sphere = IG_SPHERE.instance()
		add_child(sphere)
		sphere.global_transform.origin = p 
		sphere.create_ig_sphere(8,8,.1)

func remove_all():
	for s in get_children():
		s.queue_free()
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
