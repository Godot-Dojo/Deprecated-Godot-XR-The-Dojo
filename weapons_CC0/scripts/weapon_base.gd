class_name Gun
extends XRToolsPickable

export var group_name : String

export var current_ammo : int = 0
export var shot_timer_time : float = .25
export var is_ShotGun : bool = false
export var is_Bolt_Action : bool = false
export var is_FlareGun : bool = false
export var is_full_automatic : bool = false
export(NodePath) var triggerPath # set in the inspector once
onready var trigger = get_node(triggerPath)
onready var mag_zone = $Mag_Zone
onready var _muzzleflash: Particles = $FirearmProjectileSpawner/MuzzleParticles
onready var _smoke: Particles = $FirearmProjectileSpawner/SmokeParticles
var can_shoot : bool = true
var magazine_ammo : int = 0
var grabbed_two_handed : bool = false
var grabbed_two_handed_spatial : Spatial = null
var second_hand_controller : ARVRController = null
var two_handed_recoil_rotation_offset : Vector3
var two_handed_recoil_position_offset : Vector3
# initial transform when grabbed -> used for recoil recovery
var grabbed_transform: Transform = Transform(Basis.IDENTITY, Vector3.ZERO)
# recoil recover speed 
export(float, 0, 1) var recoil_recover_speed = 0.2
# rotation offset to be applied to recoil -> best between 0-1
export var recoil_rotation_offset: Vector3 = Vector3(0.3, 0, 0)
# position offset to be applied to recoil -> best between 0-1
export var recoil_position_offset: Vector3 = Vector3(0, 0, 0.1)
# multiplier for recoil when two handed
export var two_handed_recoil_multiplier: float = .8

signal shoot
signal ammo_depleted
signal grabbed_two_handed(weapon, controller, grab_point)
signal released_two_handed(weapon, controller, grab_point)

func _ready(): 
	hold_method = HoldMethod.REMOTE_TRANSFORM
	connect("picked_up", self, "picked_up")
	two_handed_recoil_rotation_offset = two_handed_recoil_multiplier * recoil_rotation_offset
	two_handed_recoil_position_offset = two_handed_recoil_multiplier * recoil_position_offset
	

func action():
	if can_shoot:
		emit_signal("action_pressed", self)
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
			if _muzzleflash != null:
				_muzzleflash.restart()
			if _smoke != null:
				_smoke.restart()
			if get_node_or_null("GunSound")!= null:
				$GunSound.play(.4)
			recoil()
			emit_signal("shoot")
			
			if current_ammo <= 0:
				emit_signal("ammo_depleted")
				if get_node_or_null("ClickSound") != null:
					$ClickSound.play()
				
		if current_ammo <= 0:
			if get_node_or_null("ClickSound")!=null:
				$ClickSound.play()	
		# Make player wait until time designated for gun to allow next shot
		can_shoot = false
		$ShotTimer.wait_time = shot_timer_time
		$ShotTimer.start()

func recoil(): 
	# apply recoil transform 
	if grabbed_two_handed == false:
		_remote_transform.transform = Transform(
			_remote_transform.transform.basis * Basis(recoil_rotation_offset),
			(_remote_transform.transform.basis.z.normalized() * recoil_position_offset)
		)
	else:
		_remote_transform.transform = Transform(
			_remote_transform.transform.basis * Basis(two_handed_recoil_rotation_offset),
			(_remote_transform.transform.basis.z.normalized() * two_handed_recoil_position_offset)
		)
func recoil_recover(): 
	# lerp transform to grabbed transform 
	
	_remote_transform.transform = _remote_transform.transform.interpolate_with(
		grabbed_transform, recoil_recover_speed
	)
	
#When shot timer expires, allow shot again
func _on_ShotTimer_timeout():
	if current_ammo <= 0:
		if get_node_or_null("ClickSound")!=null:
			$ClickSound.stop()
	can_shoot = true
	
func _on_Mag_Zone_has_picked_up(what):
	if what.get_node_or_null("Ammo") != null:
		magazine_ammo = what.get_node_or_null("Ammo").ammo
		if get_node_or_null("SlideSound") != null:
			$SlideSound.play()
		
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
		
		#make it impossible to grab magazine while holding gun if it has bullets to prevent misfires when trying to use slide
		if mag_zone.picked_up_object == null or magazine_ammo == 0:	
			mag_zone.grap_require = ""
		else:
			mag_zone.grap_require = "none"
		
		if get_node_or_null("Scope_Zone") != null:
			$Scope_Zone.grap_require = ""
		
	if is_full_automatic:
		if picked_up_by != null and by_controller != null:
			if get_fire_input() > 0.5:
				action()
				
				
				
func get_fire_input():
	return by_controller.get_joystick_axis(JOY_VR_ANALOG_TRIGGER)
	
func picked_up(s): 
	grabbed_transform = _remote_transform.transform


func _on_secondary_grab_area_grabbed(grab_area, grip_point, by_controller):
	grabbed_two_handed = true
	grabbed_two_handed_spatial = grip_point
	second_hand_controller =  by_controller
	emit_signal("grabbed_two_handed", self, second_hand_controller, grabbed_two_handed_spatial)
	if second_hand_controller.name.matchn("*right*"):
		grip_point.rotation_degrees = grab_area.secondary_grab_area_rotation_degrees_right 
		grip_point.translation = grab_area.secondary_grab_area_local_position_right
		
	else:
		grip_point.rotation_degrees = grab_area.secondary_grab_area_rotation_degrees_left 
		grip_point.translation = grab_area.secondary_grab_area_local_position_left
		
func _on_secondary_grab_area_released(grab_area, grip_point, by_controller):
	grabbed_two_handed = false
	grabbed_two_handed_spatial = null
	second_hand_controller = by_controller
	emit_signal("released_two_handed", self, second_hand_controller, grip_point)
	
