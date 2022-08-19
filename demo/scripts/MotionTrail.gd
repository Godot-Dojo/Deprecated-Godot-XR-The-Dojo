# this script is based upon the work of dbp8890
# GitHub Project Page: https://github.com/dbp8890/motion-trails
# License: MIT
# Edit by DigitalN8m4r3

extends ImmediateGeometry

var points  = []
var widths  = []
var lifePoints = []

export var trailEnabled = false

export var fromWidth = 0.5
export var toWidth = 0.0
export(float, 0.5, 1.5) var scaleAcceleration = 1.0

export var motionDelta = 0.1
export var lifespan = 1.0

export var scaleTexture = true
export var startColor = Color(1.0, 1.0, 1.0, 1.0)
export var endColor = Color(1.0, 1.0, 1.0, 0.0)

var oldPos

func _ready():
	oldPos = get_global_transform().origin

func _process(delta):
	
	if (oldPos - get_global_transform().origin).length() > motionDelta and trailEnabled:
		appendPoint()
		oldPos = get_global_transform().origin
	
	var p = 0
	var max_points = points.size()
	while p < max_points:
		lifePoints[p] += delta
		if lifePoints[p] > lifespan:
			removePoint(p)
			p -= 1
			if (p < 0): p = 0
		
		max_points = points.size()
		p += 1
	
	clear()
	
	if points.size() < 2:
		return
	
	begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range(points.size()):
		var t = float(i) / (points.size() - 1.0)
		var currColor = startColor.linear_interpolate(endColor, 1 - t)
		set_color(currColor)
		
		var currWidth = widths[i][0] - pow(1-t, scaleAcceleration) * widths[i][1]
		
		if scaleTexture:
			var t0 = motionDelta * i
			var t1 = motionDelta * (i + 1)
			set_uv(Vector2(t0, 0))
			add_vertex(to_local(points[i] + currWidth))
			set_uv(Vector2(t1, 1))
			add_vertex(to_local(points[i] - currWidth))
		else:
			var t0 = i / points.size()
			var t1 = t
			
			set_uv(Vector2(t0, 0))
			add_vertex(to_local(points[i] + currWidth))
			set_uv(Vector2(t1, 1))
			add_vertex(to_local(points[i] - currWidth))
	end()

func appendPoint():
	points.append(get_global_transform().origin)
	widths.append([
		get_global_transform().basis.x * fromWidth,
		get_global_transform().basis.x * fromWidth - get_global_transform().basis.x * toWidth])
	lifePoints.append(0.0)
	
func removePoint(i):
	points.remove(i)
	widths.remove(i)
	lifePoints.remove(i)


func _on_Shuriken_dropped(pickable):
	trailEnabled = true


func _on_Shuriken_picked_up(pickable):
	trailEnabled = false
