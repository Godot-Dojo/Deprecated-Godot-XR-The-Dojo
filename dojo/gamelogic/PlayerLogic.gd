extends Spatial


func _ready():
	GameSignals.connect("game_started", self, "_on_game_started")
	GameSignals.connect("game_options", self, "_on_game_options")
	GameSignals.connect("game_credits", self, "_on_game_credits")
	GameSignals.connect("options_toggle", self, "_on_options_toggle")
	GameSignals.connect("death_by_bombs", self, "_on_death_by_bombs")
	GameSignals.connect("death_by_falling", self, "_on_death_by_falling")
	GameSignals.connect("death_by_drowning", self, "_on_death_by_drowning")
	# Enable screen controls
	$"../RightHandController/Function_pointer".enabled = true
	# Disable game controls
	$"../LeftHandController/Function_Direct_movement".enabled = false
	$"../RightHandController/Function_Direct_movement".enabled = false
	# commented Turn false - for demoing purposes
	#$"../RightHandController/Function_Turn_movement".enabled = false
	#$"../RightHandController/Function_Grapple_movement".enabled = true
	$"../RightHandController/Function_Jump_movement".enabled = false
	#$"../Function_Climb_movement".enabled = true
	#$"../Function_Glide_movement".enabled = true
	#$"../Function_Fall_damage".enabled = true
func _on_game_started():
	$Sword.stop()
	$Sword.play()
	# Disable screen controls
	$"../RightHandController/Function_pointer".enabled = false
	# Enable game controls
	$"../LeftHandController/Function_Direct_movement".enabled = true
	$"../RightHandController/Function_Direct_movement".enabled = true
	$"../RightHandController/Function_Turn_movement".enabled = true
	#$"../RightHandController/Function_Grapple_movement".enabled = true
	$"../RightHandController/Function_Jump_movement".enabled = true
	#$"../Function_Climb_movement".enabled = true
	#$"../Function_Glide_movement".enabled = true
	#$"../Function_Fall_damage".enabled = true
	$Gong.play()
	yield(get_tree().create_timer(1.50), "timeout")
	$Sword.stop()
	yield(get_tree().create_timer(8.50), "timeout")
	$Gong.stop()
	
func _on_game_options():
		$Sword.stop()
		$Sword.play()
		yield(get_tree().create_timer(1.50), "timeout")
		$Sword.stop()

func _on_game_credits():
		$Sword.stop()
		$Sword.play()
		yield(get_tree().create_timer(1.50), "timeout")
		$Sword.stop()
		
func _on_options_toggle():
	if	$"../PlayerBody".player_height_offset == 0.0:
		$"../PlayerBody".player_height_offset = 0.5	
	else:
		$"../PlayerBody".player_height_offset = 0.0

# currently not in use
func _on_death_by_bombs():
	$"../ARVRCamera/DeathFade".death_fade(Color.red, 5.0)
	$"../PlayerBody".enabled = false


func _on_death_by_falling():
	$Fall.play()
	$"../ARVRCamera/DeathFade".death_fade(Color.red, 2.0)
	$"../PlayerBody".enabled = false


func _on_death_by_drowning():
	$Drown.play()
	$"../ARVRCamera/DeathFade".death_fade(Color.darkblue, 0.5)
	$"../PlayerBody".enabled = false


func _on_Function_Grapple_movement_grapple_started():
	$GrappleFire.play()
	$GrappleSwing.play()


func _on_Function_Grapple_movement_grapple_finished():
	$GrappleFire.stop()
	$GrappleSwing.stop()


func _on_Function_Glide_movement_player_glide_start():
	$GlideSound.play()


func _on_Function_Glide_movement_player_glide_end():
	$GlideSound.stop()


func _on_Function_Fall_damage_player_fall_damage(_damage: float):
	GameSignals.emit_signal("death_by_falling")
