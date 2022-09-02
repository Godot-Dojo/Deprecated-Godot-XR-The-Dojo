extends Spatial
#This code was developed by lejar, https://github.com/lejar and adapted for this project


signal entry_selected(entry)


enum Buttons {
	VR_BUTTON_BY = 1,
	VR_GRIP = 2,
	VR_BUTTON_3 = 3,
	VR_BUTTON_4 = 4,
	VR_BUTTON_5 = 5,
	VR_BUTTON_6 = 6,
	VR_BUTTON_AX = 7,
	VR_BUTTON_8 = 8,
	VR_BUTTON_9 = 9,
	VR_BUTTON_10 = 10,
	VR_BUTTON_11 = 11,
	VR_BUTTON_12 = 12,
	VR_BUTTON_13 = 13,
	VR_PAD = 14,
	VR_TRIGGER = 15
}


export var active := true
export (NodePath) var radial_controller_path = null
export(Buttons) var open_radial_menu_button := Buttons.VR_BUTTON_BY
export var menu_entries := []

onready var controller : ARVRController = get_node(radial_controller_path)
onready var radial_menu_open_position : Transform = global_transform
onready var menu_quads = []
onready var icons = {}
onready var last_selected = null
onready var handling_input = false


func _ready():
	hide()
	

	for entry in menu_entries:
		add_entry(entry)

func add_entry(entry: String) -> void:
	if not entry in icons:
		#icons[entry] = load('res://assets/feathericons/' + entry + '.png')
		#icons[entry] = load("res://icon.png")
		icons[entry] = load("res://addons/radial_menu/radial_menu_textures/" + entry + ".png")
		
	var mesh = $IconTemplate.duplicate()
	mesh.material_override = mesh.material_override.duplicate(true)
	mesh.show()
	mesh.material_override.set_shader_param('albedo_texture', icons[entry])

	$Anchor.add_child(mesh)
	menu_quads.append(mesh)

	# Calculate the new layout.
	var arc_size = 2 * PI / len(menu_entries)
	var scale = 0.2
	for i in range(len(menu_quads)):
		menu_quads[i].transform.origin = transform.origin + Vector3(sin(arc_size * i) * scale, cos(arc_size * i) * scale, 0)

func unselect(entry: String) -> void:
	var index = menu_entries.find(entry)
	var mesh = menu_quads[index]
	mesh.material_override.set_shader_param('selected', false)

func select(entry: String) -> void:
	if last_selected != null:
		unselect(last_selected)
		last_selected = null

	var index = menu_entries.find(entry)
	var mesh = menu_quads[index]
	mesh.material_override.set_shader_param('selected', true)
	last_selected = entry

func entry_from_position(position: Vector3) -> String:
	# Get the vector to the controller and to the first entry, and make them be in the menu plane.
	var inverse_transform = radial_menu_open_position.inverse()

	var controller_vector = (inverse_transform * position - inverse_transform * radial_menu_open_position.origin)
	var first_entry_vector = (inverse_transform * menu_quads[0].global_transform.origin - inverse_transform * radial_menu_open_position.origin)

	var radians = controller_vector.angle_to(first_entry_vector)
	# If the controller is left of the middle, then adjust the angle so that we
	# get the angle clockwise from the first entry.
	if controller_vector.x < 0:
		radians = 2 * PI - radians

	var arc_size = 2 * PI / len(menu_entries)

	var index = int(round(radians / arc_size))
	return menu_entries[index % len(menu_entries)]

func _process(_dt) -> void:
	if controller == null:
		return

	# Anchor the menu to the current controller position and display the menu.
	# For some reason the stupid parser keeps giving me errors in the editor about this method not existing.
	if controller.is_button_pressed(open_radial_menu_button) and not handling_input:
		handling_input = true
		radial_menu_open_position = controller.global_transform
		$Anchor.global_transform = radial_menu_open_position
		show()

	elif not controller.is_button_pressed(open_radial_menu_button) and handling_input:
		handling_input = false
		hide()
		var entry = entry_from_position(controller.global_transform.origin)
		if entry != null:
			emit_signal("entry_selected", entry)
			

	# Update the menu with the controller position.
	elif handling_input:
		$Anchor.global_transform = radial_menu_open_position
		var entry = entry_from_position(controller.global_transform.origin)
		if entry != null:
			select(entry)

