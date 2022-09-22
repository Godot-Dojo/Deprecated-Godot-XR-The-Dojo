extends PathFollow

var runSpeed = 1
var isOn := true
var on_Rail := true
onready var player = $avatar_player
onready var root = get_node("/root/")

func _process(delta: float) -> void:
	if isOn:
		if on_Rail:
			set_offset(get_offset() + runSpeed * delta)
		else:
			get_parent().remove_child(player)
			root.add_child(player)
			isOn = false

func _on_Area_area_entered(area):
	on_Rail = false
