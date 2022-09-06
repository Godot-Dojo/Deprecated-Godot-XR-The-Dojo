extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var player_body : PlayerBody = $"../Player/PlayerBody"

var targets : Array
var targets_remaining : int
var countdown : Timer
var alive := true
var taunt := 0
var start_ms := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect game signals
	GameSignals.connect("game_started", self, "_on_game_started")
	GameSignals.connect("game_options", self, "_on_game_options")
	GameSignals.connect("game_credits", self, "_on_game_credits")
	GameSignals.connect("options_toggle", self, "_on_options_toggle")
	GameSignals.connect("death_by_bombs", self, "_on_death_by_bombs")
	GameSignals.connect("death_by_falling", self, "_on_death_by_falling")
	GameSignals.connect("death_by_drowning", self, "_on_death_by_drowning")

	# Connect all target diffused signals
	targets = get_tree().get_nodes_in_group("target")
	targets_remaining = targets.size()
	for t in targets:
		t.connect("target_diffused", self, "_on_target_diffused")


#func _process(var _delta):
#	if alive and player_body.kinematic_node.transform.origin.y < 0.0:
#		alive = false
#		GameSignals.emit_signal("death_by_drowning")


func _stop_all():
	# Stop game timers and sounds
	$ThreatMessage.stop()
	$Taunt1.stop()
	$Taunt2.stop()
	$Taunt3.stop()
	$TauntTimer.stop()
	$BombsTimer.stop()


func _on_game_started():
	$StartScreen.queue_free()
	yield(get_tree().create_timer(0.25), "timeout")
	#$GodotDojo_Logo/Smoke_01.visible = true
	$GodotDojo_Logo/AnimationTree.active = true
	$GodotDojo_Logo/AnimationTree.set("parameters/enterShot/active",true)
	yield(get_tree().create_timer(0.25), "timeout")
	$GodotDojo_Logo/Smoke_02.visible = true
	yield(get_tree().create_timer(0.5), "timeout")
	$GodotDojo_Logo/Smoke_01.visible = true
	yield(get_tree().create_timer(0.3), "timeout")
	$GodotDojo_Logo.queue_free()
	#$TauntTimer.start(10.0)
	#start_ms = OS.get_ticks_msec()
	
func _on_game_options():
	yield(get_tree().create_timer(0.25), "timeout")
	#$GodotDojo_Logo/Smoke_01.visible = true
	$GodotDojo_Logo/AnimationTree.active = true
	$GodotDojo_Logo/AnimationTree.set("parameters/linkShot/active",true)
	#$TauntTimer.start(10.0)
	#start_ms = OS.get_ticks_msec()#
	
func _on_game_credits():
	yield(get_tree().create_timer(0.25), "timeout")
	#$GodotDojo_Logo/Smoke_01.visible = true
	$GodotDojo_Logo/AnimationTree.active = true
	$GodotDojo_Logo/AnimationTree.set("parameters/linkShot/active",true)
	#$TauntTimer.start(10.0)
	#start_ms = OS.get_ticks_msec()#
	
func _on_target_diffused():
	# Count down until all targets diffused
	targets_remaining -= 1
	if targets_remaining != 0:
		return

	# Stop game timers and sounds
	_stop_all()
	
	# Calculate duration and best time
	GameState.last_time = (OS.get_ticks_msec() - start_ms) * 0.001
	if GameState.best_time <= 0 or GameState.last_time < GameState.best_time:
		GameState.best_time = GameState.last_time
	
	# Play the victory sound
	$Victory.play()


func _on_death_by_bombs():
	# Play explosion sound
	_stop_all()
	$Explosion.play()


func _on_Explosion_finished():
	get_tree().reload_current_scene()


func _on_death_by_falling():
	# Stop game timers and sounds
	_stop_all()

	# Wait for 5 seconds then restart the game
	yield(get_tree().create_timer(5.0), "timeout")
	get_tree().reload_current_scene()


func _on_death_by_drowning():
	# Stop game timers and sounds
	_stop_all()

	# Wait for 5 seconds then restart the game
	yield(get_tree().create_timer(5.0), "timeout")
	get_tree().reload_current_scene()


func _on_Victory_finished():
	# Wait for 30 seconds
	yield(get_tree().create_timer(10.0), "timeout")

	# Restart the game
	get_tree().reload_current_scene()


func _on_ThreatMessage_finished():
	# Enable all targets
	for t in targets:
		t.enable()

	# Start the game countdown
	$BombsTimer.start()


func _on_BombsTimer_timeout():
	GameSignals.emit_signal("death_by_bombs")


func _on_TauntTimer_timeout():
	match taunt:
		0:
			# Play initial threat
			$ThreatMessage.play()
			taunt = 1
			$TauntTimer.start(45)

		1:
			$Taunt1.play()
			taunt = 2
			$TauntTimer.start(45)

		2:
			$Taunt2.play()
			taunt = 3
			$TauntTimer.start(45)

		3:
			$Taunt3.play()
			taunt = 3
