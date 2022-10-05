class_name FirearmProjectileSpawner
extends Spatial

# scene to instance
export var scene: PackedScene
export var forward_impulse_strength: float = 15
onready var firearm: Gun = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
	if is_instance_valid(firearm):
		firearm.connect("shoot", self, "_shoot")

func _shoot(): 
	# instance scene on shoot and apply impulse 
	var instance = scene.instance()
	firearm.owner.add_child(instance)
	instance.global_transform = global_transform
	
	if instance.get_class() == "RigidBody":
		instance.apply_impulse(
			instance.global_transform.origin,
			(-global_transform.basis.z * get_process_delta_time()) * forward_impulse_strength
		)
		
