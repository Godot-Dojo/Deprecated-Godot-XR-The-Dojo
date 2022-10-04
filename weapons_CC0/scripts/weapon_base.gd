class_name Gun
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
export(NodePath) var triggerPath # set in the inspector once
onready var trigger = get_node(triggerPath)
onready var mag_zone = $Mag_Zone
var can_shoot : bool = true
var bullet = null
var casing = null
var magazine_ammo : int = 0
# Trigger - true/false
var trigger_time = false

# initial transform when grabbed -> used for recoil recovery
var grabbed_transform: Transform = Transform(Basis.IDENTITY, Vector3.ZERO)
# recoil recover speed 
export(float, 0, 1) var recoil_recover_speed = 0.2
# rotation offset to be applied to recoil -> best between 0-1
export var recoil_rotation_offset: Vector3 = Vector3(0.3, 0, 0)
# position offset to be applied to recoil -> best between 0-1
export var recoil_position_offset: Vector3 = Vector3(0, 0, 0.1)

func _ready(): 
	hold_method = HoldMethod.REMOTE_TRANSFORM
	connect("picked_up", self, "picked_up")

func action():
	emit_signal("action_pressed", self)
	if can_shoot:
		_trigger_down()
		# Get audio node
		var audio = owner.get_node("{}/audio".format([name], "{}"));
		# Get effects node
		var effect = owner.get_node("{}/effect".format([name], "{}"));
		
		# If shot timer has expired, and either magazine clip has bullets or gun has "one in the chamber", allow shooting
		if magazine_ammo >= 1 or current_ammo >= 1:
			# First check if magazine has the ammo, and if so, subtract bullet from magazine ammo count and from actual magazine
			if magazine_ammo >= 1:
				magazine_ammo-= 1
				current_ammo = magazine_ammo
				var magazine = mag_zone.picked_up_object
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
			# Trigger - Set Rotation to false
			trigger_time = false
			recoil()
		# Make player wait until time designated for gun to allow next shot
		can_shoot = false
		$ShotTimer.wait_time = shot_timer_time
		$ShotTimer.start()

func recoil(): 
	# apply recoil transform 
	_remote_transform.transform = Transform(
		_remote_transform.transform.basis * Basis(recoil_rotation_offset),
		(_remote_transform.transform.basis.z.normalized() * recoil_position_offset)
	)

func recoil_recover(): 
	# lerp transform to grabbed transform 
	_remote_transform.transform = _remote_transform.transform.interpolate_with(
		grabbed_transform, recoil_recover_speed
	)

#When shot timer expires, allow shot again
func _on_ShotTimer_timeout():
	# Trigger Rotation - CHECK
	if !trigger_time:
		_trigger_up()
	_trigger_reset()
	can_shoot = true
	
# > Trigger Rotation - START
func _trigger_reset():
	trigger.transform.basis = trigger.transform.basis.rotated(Vector3(1,0,0), 0.00)
	# Trigger - Set Rotation to true
	trigger_time = true
	
func _trigger_down():
		# failsafe to stop trigger from rotating
		trigger.transform.basis = trigger.transform.basis.rotated(Vector3(-1,0,0), 0.3)
		trigger.transform.basis = trigger.transform.basis.rotated(Vector3(1,0,0), 0.00)
		trigger_time = false
func _trigger_up():
	trigger.transform.basis = trigger.transform.basis.rotated(Vector3(1,0,0), 0.3)
# < Trigger END

func _on_Mag_Zone_has_picked_up(what):
	if what.get_node_or_null("Ammo") != null:
		magazine_ammo = what.get_node_or_null("Ammo").ammo
		print(magazine_ammo)
		

func _on_Mag_Zone_has_dropped():
	if current_ammo > 1:
		current_ammo = 1
	magazine_ammo = 0

func _process(delta):
	
	if !is_picked_up():
		mag_zone.grap_require = "none"
		if get_node_or_null("Scope_Zone") != null:
			$Scope_Zone.grap_require = "none"

	if is_picked_up():
		# recover transform from recoil if not at grabbed transform
		if !_remote_transform.transform.is_equal_approx(grabbed_transform): 
			recoil_recover()
			
		mag_zone.grap_require = ""
		if get_node_or_null("Scope_Zone") != null:
			$Scope_Zone.grap_require = ""
		
	if is_full_automatic:
		if picked_up_by != null and by_controller != null:
			if by_controller.is_button_pressed(by_controller.get_node("Function_Pickup").action_button_id):
				action()
	
func picked_up(s): 
	grabbed_transform = _remote_transform.transform
