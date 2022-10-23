extends Area

signal secondary_grab_area_grabbed(grab_area, grip_point, by_controller)
signal secondary_grab_area_released(grab_area, grip_point, by_controller)

export var secondary_grab_release_distance : float = .05
export var secondary_grab_area_local_position_left : Vector3 = Vector3(-.03, 0, 0) 
export var secondary_grab_area_rotation_degrees_left : Vector3 = Vector3(0, 45, -90)
export var secondary_grab_area_local_position_right : Vector3 = Vector3(.03, 0, 0)
export var secondary_grab_area_rotation_degrees_right : Vector3 = Vector3(180, 135, -90)
var _start_monitoring : bool = false
var _overlapping_bodies : Array = []
var _overlapping_controller : ARVRController = null
var _gripping_controller : ARVRController = null

# Called when the node enters the scene tree for the first time.
func _ready():
	self.connect("body_entered", self, "_on_secondary_grab_area_entered")
	self.connect("body_exited", self, "_on_secondary_grab_area_exited")
	$grip_point.translation = secondary_grab_area_local_position_left
	$grip_point.rotation_degrees = secondary_grab_area_rotation_degrees_left

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
				# Check if overlapping controller already is holding an object; if so, do not trigger signal to pick up secondary area
				if _overlapping_controller.name.matchn("*left*"):
					if _overlapping_controller.get_parent().get_node("avatar/Armature/Skeleton/LeftHandBoneAttachment/Function_Pickup").picked_up_object != null:
						return
				if _overlapping_controller.name.matchn("*right*"):
					if _overlapping_controller.get_parent().get_node("avatar/Armature/Skeleton/RightHandBoneAttachment/Function_Pickup").picked_up_object != null:
						return
				# If hand is empty, trigger secondary area grab signal
				_gripping_controller = _overlapping_controller
				emit_signal("secondary_grab_area_grabbed", self, $grip_point, _gripping_controller)
		
	# If grab button released, trigger release signal
	if _gripping_controller != null:
		if !_gripping_controller.is_button_pressed(2):
			emit_signal("secondary_grab_area_released", self, $grip_point, _gripping_controller)
			_gripping_controller = null	
	
	# If distance from grip point is too far, then trigger release signal			
	if _gripping_controller != null and _gripping_controller.global_transform.origin.distance_to($grip_point.global_transform.origin) > secondary_grab_release_distance:
		emit_signal("secondary_grab_area_released", self, $grip_point, _gripping_controller)
		_gripping_controller = null	

# Only start monitoring the area if a body enters the secondary grab area
func _on_secondary_grab_area_entered(_body):
	_start_monitoring = true
	
func _on_secondary_grab_area_exited(_body):
	_start_monitoring = false

# Public function so other code can release the secondary grab point as necessary	
func release():
	if _gripping_controller != null:
		emit_signal("secondary_grab_area_released", self, $grip_point, _gripping_controller)
