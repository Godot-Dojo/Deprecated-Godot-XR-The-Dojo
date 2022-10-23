class_name FirearmSlide
extends XRToolsPickable


## endpoint for slide on z translation -> only good for basic slides/charging handles right now ie. pistols, ARs
export var z_end_translation = .05
export var slide_recover_speed: float = 0.4
export var auto_slide_back: bool = true 

onready var start_translation: Vector3 = translation
onready var start_scale : Vector3 = scale
onready var firearm: Gun = get_parent()
export(NodePath) var sfxPath # set in the inspector once
onready var slideSFX = get_node(sfxPath)
var grabbed_offset: Vector3 = Vector3.ZERO
var slide_stopped: bool = false 
signal on_slide_back 


# Called when the node enters the scene tree for the first time.
func _ready():
	# setup 
	reset_transform_on_pickup = false 
	mode = RigidBody.MODE_STATIC
	hold_method = HoldMethod.REMOTE_TRANSFORM
	connect("picked_up", self, "picked_up")
	
	if is_instance_valid(firearm):
		firearm.connect("shoot", self, "_shoot")
		firearm.connect("ammo_depleted", self, "_ammo_depleted")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# disable/enable collider if grabbed or not 
	if is_instance_valid(firearm) and firearm.is_picked_up(): 
		$CollisionShape.disabled = false 
	else: 
		$CollisionShape.disabled = true  
		
	if is_picked_up():
		# set slide z to controller position and clamp  
		_remote_transform.remote_path = NodePath()
		translation.z = get_parent().to_local(by_controller.global_transform.origin + grabbed_offset).z
		translation.z = clamp(translation.z, start_translation.z, z_end_translation)
		scale = start_scale
		if slideSFX:
			slideSFX.play()
		
	else:
		var slide_enabled = !slide_stopped and auto_slide_back
		# return slide to init translation 
		if !translation.is_equal_approx(start_translation) and slide_enabled:
			scale = start_scale
			slide_return()
	
func slide_return():
	# lerp to start translation 
	translation = lerp(translation, start_translation, slide_recover_speed)
	
func set_slide_back():
	# set slide to back position
	translation.z = z_end_translation
	scale = start_scale

func is_back() -> bool: 
	# is slide in back position 
	return translation.is_equal_approx(Vector3(
		start_translation.x, 
		start_translation.y, 
		z_end_translation
	))
	if slideSFX:
		slideSFX.play()
	

func picked_up(s): 
	grabbed_offset = global_transform.origin - by_controller.global_transform.origin
	scale = start_scale
	slide_stopped = false 
	
func _shoot(): 
	set_slide_back()

func _ammo_depleted(): 
	slide_stopped = true
	set_slide_back()
