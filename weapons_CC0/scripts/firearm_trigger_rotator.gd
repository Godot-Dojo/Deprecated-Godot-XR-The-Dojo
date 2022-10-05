class_name FirearmTriggerRotator
extends Spatial

export var enabled: bool = true 
export var end_rotation_degrees: Vector3

onready var tween = Tween.new()
onready var firearm: Gun = get_parent()


# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(tween)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !enabled: 
		return 
	
	if is_instance_valid(firearm) and firearm.is_picked_up(): 
		tween.start()
		tween.interpolate_property(
			self, 
			"rotation_degrees",
			Vector3.ONE,
			end_rotation_degrees, 
			1  
			)
		tween.seek(firearm.get_fire_input())
