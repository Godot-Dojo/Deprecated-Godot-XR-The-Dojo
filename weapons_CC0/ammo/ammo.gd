extends Node

export var ammo : int;

func _physics_process(delta):
	if ammo <= 0:
		$BulletDummy.visible = false
		#get_parent().queue_free()
