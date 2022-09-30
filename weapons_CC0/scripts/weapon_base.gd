class_name Weapon
extends XRToolsPickable

export var group_name : String
export(PackedScene) var bullet_scene
export(PackedScene) var casing_scene

export var current_ammo : int = 0
export var bullet_speed = 40.0
export var shot_timer_time : float = .25
export var max_bullets : int
export var is_ShotGun : bool = false
export var is_Bolt_Action : bool = false
export var is_FlareGun : bool = false
export var is_full_automatic : bool = false

var can_shoot : bool = true
var bullet = null
var casing = null
var magazine_ammo : int = 0

func action():
	emit_signal("action_pressed", self)
	# Get audio node
	var audio = owner.get_node("{}/audio".format([name], "{}"));
	# Get effects node
	var effect = owner.get_node("{}/effect".format([name], "{}"));
	
	# If shot timer has expired, and either magazine clip has bullets or gun has "one in the chamber", allow shooting
	if can_shoot and (magazine_ammo >= 1 or current_ammo >= 1):
		# First check if magazine has the ammo, and if so, subtract bullet from magazine ammo count and from actual magazine
		if magazine_ammo >= 1:
			magazine_ammo-= 1
			current_ammo = magazine_ammo
			var magazine = $Mag_Zone.picked_up_object
			if magazine != null:
				magazine.get_node("Ammo").ammo = magazine_ammo
		# If magazine doesn't have bullet, that means there must be "one in the chamber" so use up that bullet instead
		else:
			current_ammo -= 1
		$GunSound.play(.4)
		bullet = bullet_scene.instance()
		get_owner().add_child(bullet)
		bullet.global_transform = $BulletSpawnPoint.global_transform
		bullet.linear_velocity = -bullet.global_transform.basis.z * bullet_speed
		
		#Expel casing unless a bolt action rifle or flare gun
		if is_Bolt_Action == false and is_FlareGun == false:
			casing = casing_scene.instance()
			get_owner().add_child(casing)
			casing.global_transform = $CasingSpawnPoint.global_transform
			casing.apply_impulse(Vector3.DOWN, casing.global_transform.basis.y *.15)

		# Make player wait until time designated for gun to allow next shot
		can_shoot = false
		$ShotTimer.wait_time = shot_timer_time
		$ShotTimer.start()

#When shot timer expires, allow shot again
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

func _process(delta):
	if !is_full_automatic:
		return
	
	if is_full_automatic:
		if picked_up_by != null and by_controller != null:
			if by_controller.is_button_pressed(by_controller.get_node("Function_Pickup").action_button_id):
				action()
