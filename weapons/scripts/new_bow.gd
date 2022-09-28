tool
extends Spatial
var isGrabbed:bool= false;
var _controller : ARVRController = null;
export var bow_strength = 50
export var max_pull_distance = .6 
export var string_rest_offset  = .219
onready var bow_string = $bow_string
var arrow_loaded = false
var arrow 
var arrow_logic
var dir 
var _placeholder_rigidbody: RigidBody = null
#var new_arrow = preload("res://scenes/objects/arrow.tscn")

func release_arrow():
	if arrow != null:
		arrow.bow_strength = bow_strength
		arrow.release_arrow()
		arrow_loaded = false
		arrow = null

#func _ready():
#	$bow_handle.connect("area_entered",self,"load_arrow_on_bow")

func load_arrow_on_bow():
	if arrow_logic.has_method("load_arrow") and arrow_logic.arrow_state ==  arrow.states.IDLE:
		arrow.load_arrow(bow_string,self)

func _physics_process(delta):
	dir = global_transform.origin - $bow_string.global_transform.origin
	#if (bow_string.pull_distance-string_rest_offset)/max_pull_distance > .1 and arrow == null and bow_string.pulled:
		#create_arrow()

func create_arrow():
	#arrow = new_arrow.instance()
	arrow = null
	var main_scene = get_tree().get_current_scene().get_node("main_scene")
	main_scene.add_child(arrow)
	arrow.global_transform = bow_string.global_transform
	arrow.scale = Vector3.ONE
	#load_arrow_on_bow()

func _on_bow_dropped(pickable):
	isGrabbed = false;
	pass # Replace with function body.


func _on_bow_picked_up(pickable):
	isGrabbed = true;
	pass # Replace with function body.


func _on_bow_body_entered(body):
	if body.name == "arrow":
		print("load this arrow")
		arrow = body
		arrow_logic = body.get_node("logic")
		arrow_loaded = true
		load_arrow_on_bow()
	pass # Replace with function body.
