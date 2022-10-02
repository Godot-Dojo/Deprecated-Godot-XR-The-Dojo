extends ImmediateGeometry

func create_ig_sphere(lats,longs,r):
	clear()
	begin(Mesh.PRIMITIVE_LINES)
	set_color(Color.red)
	add_sphere(lats,longs,r)
	end()
