class_name Weapon
extends XRToolsPickable

export var group_name : String
export(PackedScene) var bullet_scene
export(PackedScene) var casing_scene

export var current_ammo : int = 0
export var bullet_speed = 40.0
export var max_bullets : int
export var is_ShotGun = false
export var is_Bolt_Action = false
export var is_FlareGun = false
var can_shoot = true
var bullet = null
var casing = null
var magazine_ammo : int = 0

func action():
	emit_signal("action_pressed", self)
	# Get audio node
	var audio = owner.get_node("{}/audio".format([name], "{}"));
	# Get effects node
	var effect = owner.get_node("{}/effect".format([name], "{}"));
	
	if can_shoot and (magazine_ammo >= 1 or current_ammo >= 1):
		if magazine_ammo >= 1:
			magazine_ammo-= 1
			current_ammo = magazine_ammo
		else:
			current_ammo -= 1
		$GunSound.play(.4)
		bullet = bullet_scene.instance()
		get_owner().add_child(bullet)
		bullet.global_transform = $BulletSpawnPoint.global_transform
		bullet.linear_velocity = -bullet.global_transform.basis.z * bullet_speed

		if is_Bolt_Action == false and is_FlareGun == false:
			casing = casing_scene.instance()
			get_owner().add_child(casing)
			casing.global_transform = $CasingSpawnPoint.global_transform
			casing.apply_impulse(Vector3.DOWN, casing.global_transform.basis.y *.15)

		can_shoot = false
		$ShotTimer.start()

func _on_ShotTimer_timeout():
	can_shoot = true
	

func _on_Mag_Zone_has_picked_up(what):
	if what.get_node_or_null("Ammo") != null:
		magazine_ammo = what.get_node_or_null("Ammo").ammo
		print(magazine_ammo)
		

func _on_Mag_Zone_has_dropped():
	if current_ammo > 1:
		current_ammo = 1
	magazine_ammo = 0
