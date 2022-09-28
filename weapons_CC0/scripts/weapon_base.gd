class_name Weapon
extends XRToolsPickable

export var group_name : String
export(PackedScene) var bullet_scene
export(PackedScene) var casing_scene
var can_shoot = true
var bullet = null
var casing = null
export var bullets : int;
export var bullet_speed = 10.0
export var max_bullets : int;
export var is_Bolt_Action = false
export var is_FlareGun = false

func action():
	emit_signal("action_pressed", self)
	# Get audio node
	var audio = owner.get_node("{}/audio".format([name], "{}"));
	# Get effects node
	var effect = owner.get_node("{}/effect".format([name], "{}"));

	if bullets > 0 && can_shoot:
		bullets -= 1
		$GunSound.play(.4)
		bullet = bullet_scene.instance()
		get_owner().add_child(bullet)
		bullet.global_transform = $BulletSpawnPoint.global_transform
		bullet.linear_velocity = -bullet.global_transform.basis.z * bullet_speed

		if is_Bolt_Action and is_FlareGun == false:
			casing = casing_scene.instance()
			get_owner().add_child(casing)
			casing.global_transform = $CasingSpawnPoint.global_transform
			casing.apply_impulse(Vector3.DOWN, casing.global_transform.basis.y *.15)

		can_shoot = false
		$ShotTimer.start()

func _on_ShotTimer_timeout():
	can_shoot = true
	
func _on_Mag_Zone_body_entered(body):
	var currentAmmo = body.get_node_or_null("Ammo")
	if currentAmmo and bullets < max_bullets:
	    # Check how many bullets we can transfer
	    var reload = min(max_bullets - bullets, currentAmmo.ammo)
	    bullets += reload
	    currentAmmo.ammo -= reload
