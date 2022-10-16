extends Area

signal secondary_grab_area_grabbed(grab_area, grip_point, by_controller)
signal secondary_grab_area_released(grab_area, grip_point, by_controller)

var _start_monitoring : bool = false
var _overlapping_bodies : Array = []
var _overlapping_controller : ARVRController = null
var _gripping_controller : ARVRController = null

# Called when the node enters the scene tree for the first time.
func _ready():
	self.connect("body_entered", self, "_on_secondary_grab_area_entered")
	self.connect("body_exited", self, "_on_secondary_grab_area_exited")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _start_monitoring == true:
		_overlapping_bodies = get_overlapping_bodies()
		for _body in _overlapping_bodies:
			if _body.is_in_group("left_hand"):
				_overlapping_controller = ARVRHelpers.get_left_controller(_body)
				
			elif _body.is_in_group("right_hand"):
				_overlapping_controller = ARVRHelpers.get_right_controller(_body)
		
		if _overlapping_controller != null:
			if _overlapping_controller.is_button_pressed(2):
				_gripping_controller = _overlapping_controller
				emit_signal("secondary_grab_area_grabbed", self, $grip_point, _gripping_controller)
		
		if _gripping_controller != null:
			if !_gripping_controller.is_button_pressed(2):
				emit_signal("secondary_grab_area_released", self, $grip_point, _gripping_controller)
				_gripping_controller = null	
				
	if _gripping_controller != null and _gripping_controller.global_transform.origin.distance_to($grip_point.global_transform.origin) > ($CollisionShape.shape.radius*2):
		emit_signal("secondary_grab_area_released", self, $grip_point, _gripping_controller)
		_gripping_controller = null	

func _on_secondary_grab_area_entered(_body):
	_start_monitoring = true
	
func _on_secondary_grab_area_exited(_body):
	_start_monitoring = false
	
func release():
	if _gripping_controller != null:
		emit_signal("secondary_grab_area_released", self, $grip_point, _gripping_controller)
