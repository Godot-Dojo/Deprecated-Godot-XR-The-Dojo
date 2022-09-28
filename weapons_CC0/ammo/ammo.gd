extends Node

export var ammo : int;
export var is_Shell = false

func _physics_process(delta):
	if ammo <= 0:
		$BulletDummy.visible = false
		if is_Shell:
			get_parent().queue_free()
