extends Node2D


func _ready():
	if GameState.last_time <= 0.0:
		$LastTimeValue.text = "-:--.-"
	else:
		$LastTimeValue.text = "%d:%2.1f" % [ GameState.last_time / 60.0, fmod(GameState.last_time, 60.0) ]

	if GameState.best_time <= 0.0:
		$BestTimeValue.text = "-:--.-"
	else:
		$BestTimeValue.text = "%d:%2.1f" % [ GameState.best_time / 60.0, fmod(GameState.best_time, 60.0) ]

# Start Button
func _on_StartButton_pressed():
	GameSignals.emit_signal("game_started")

# Options Button
func _on_OptionsButton_pressed():
	GameSignals.emit_signal("game_options")
	yield(get_tree().create_timer(0.5), "timeout")
	$Options.visible = true
	$Main.visible = false
	
# Credits Button
func _on_CreditsButton_pressed():
	GameSignals.emit_signal("game_credits")
	yield(get_tree().create_timer(0.5), "timeout")
	$Credits.visible = true
	$Main.visible = false

# Back Button
func _on_BackToMain_pressed():
	GameSignals.emit_signal("game_options")
	yield(get_tree().create_timer(0.5), "timeout")
	$Options.visible = false
	$Credits.visible = false
	$Main.visible = true

## Toggle Standing/ Sitting
func _on_CheckButton_pressed():
	GameSignals.emit_signal("options_toggle")

# Audio Volume
func _on_masterSlider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)


func _on_musicSlider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)


func _on_afxSlider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("aFX"), value)
