extends RigidBody

var has_created_hole = false
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_BulletCleanUpTimer_timeout():
	queue_free() # Replace with function body.
	#pass


func _on_Bullet_body_entered(body):
	
	#approach with Decal0 addon/plugin
	if has_created_hole == false and body.is_in_group("enemies") == false:
		#var new_bullet_hole = load("res://scenes/BulletHole.tscn").instance()
		#get_tree().current_scene.add_child(new_bullet_hole)
		#new_bullet_hole.global_transform = transform
		#new_bullet_hole.global_scale(Vector3(.07,.07,.07))
		#has_created_hole = true 
		
		#approach with Sprite3D
		#var new_bullet_hole = load("res://scenes/BulletHoleSprite3D.tscn").instance()
		#get_tree().current_scene.add_child(new_bullet_hole)
		#new_bullet_hole.global_transform = transform
		#new_bullet_hole.global_transform.origin = transform.origin - Vector3(0,0,.2)
		#new_bullet_hole.global_scale(Vector3(.01,.01,.01))
		#has_created_hole = true # Replace with function body.

		
		#Approach with raycast and planemesh
		if $BulletRayCast.is_colliding():
			var new_bullet_hole = load("res://scenes/BulletHolePlaneMesh.tscn").instance()
	#		get_tree().current_scene.add_child(new_bullet_hole)
			var normal_scale = new_bullet_hole.get_scale() #new line
			$BulletRayCast.get_collider().add_child(new_bullet_hole)
			new_bullet_hole.global_transform = $BulletRayCast.get_collider().global_transform
			new_bullet_hole.set_scale(normal_scale) #new line
			new_bullet_hole.global_transform.origin = $BulletRayCast.get_collision_point()
			new_bullet_hole.look_at($BulletRayCast.get_collision_point() + $BulletRayCast.get_collision_normal(), Vector3.UP)
			new_bullet_hole.global_scale(Vector3(.03,.03,.03))
			new_bullet_hole.rotation_degrees.x = 90
			has_created_hole = true
