# this implementation of step detection is based on the Paper:
# https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6165345/pdf/sensors-18-02832.pdf
# @article{author = {Lee, Juyoung and Ahn, Sang and Hwang, Jae-In},
#          year = {2018},
#          month = {08},
#          title = {A Walking-in-Place Method for Virtual Reality Using Position and Orientation Tracking},
#          journal = {Sensors}}
#
# See also the python jupyter notebook in the godot_oculus_quest_toolkit repository
# for the data analysis that was used to define the constants below
# This is a port of NeoSparks' excellent work on this prototype for OQ-Toolkit for Godot to the OpenXR-Tools package
# found here: https://github.com/NeoSpark314/godot_oculus_quest_toolkit/tree/master/OQ_Toolkit/OQ_ARVROrigin
# I just changed the terminology to work with XR Tools.

class_name Locomotion_WalkInPlace
extends MovementProvider




## Movement provider order
export var order := 5


##Create global variables for ARVROrigin, Camera and Controllers in case needed in code. 
#export (NodePath) var fpcontroller_path = null
#export (NodePath) var arvrcamera_path = null
#export (NodePath) var l_controller_path = null
#export (NodePath) var r_controller_path = null

#movement speed to use if script detects player walking
export var speed_walking := 2.0

#movement speed to use if script detects player jogging
export var speed_jogging := 4.0

#maximum speed player can move (if using direct movement node; should match max speed in direct movement node)
export var max_speed := 10.0

#movement speed modifier to use when strafing - 1.0 = full walking speed
export var strafe_speed_modifer := .50

#factor impacting lerp regarding how quickly player moves back to zero speed when stopping jogging or between speeds (1.0 = immediate, 0.0-.99 = slower, with .01 being slowest)
export var speed_transition_factor := .80

#turn on ability to use strafing controller to activate strafe
export var controller_strafing := false

#turn on ability to use head titlt to activate strafe
export var headset_tilt_strafe := false

#turn on head tilt back to move back
export var headset_tilt_to_reverse := false

const _height_ringbuffer_size := 15; # full ring buffer is 15; lower latency can be achieved by accessing only a subset
var _height_ringbuffer_pos := 0;
var _height_ringbuffer := Array()

const _num_steps_for_step_estimate := 5;
const _num_steps_for_height_estimate := 15; 


const _step_local_detect_threshold := 0.04; # local difference, original value .04
const _step_height_min_detect_threshold := 0.008; # This might need some tweaking now to avoid missed steps, original value .01
const _step_height_max_detect_threshold := 0.1; # This might need some tweaking now to avoid missed steps, original value .1

const _step_up_min_detect_threshold := 0.012; # This might need some tweaking now to avoid missed steps, original value .012
const _step_up_max_detect_threshold := 0.1; # This might need some tweaking now to avoid missed steps, original value .1

const _variance_height_detect_threshold = 0.001;

var _had_high_step_after_low := false;

var _last_step_time_s := 0.0; # time elapsed after the last step was detected
var _fastest_step_s := 0.0 
var _slowest_step_s := 0.0 


var step_duration := 0.0 
var _step_time := 0.0;

var num_steps_till_jogging := 2;

var _continous_step_count := 0;
const _time_until_continous_step_reset = 2.0; 

# indicator to check if currently in a moving state (means steps detected)
var is_moving = false;
var is_strafing = false

var _current_height_estimate := 0.0;

var step_low_just_detected := false;
var step_high_just_detected := false;

var _last_step_min := 0.0;
var _last_step_max := 0.0;

var headset_refresh_rate = 72.0
var headset_refresh_set = false


onready var fp_controller := ARVRHelpers.get_arvr_origin(self)
onready var vr_camera := ARVRHelpers.get_arvr_camera(fp_controller)
onready var l_controller := ARVRHelpers.get_left_controller(fp_controller)
onready var r_controller := ARVRHelpers.get_right_controller(fp_controller)
onready var player_body = PlayerBody.get_player_body(fp_controller)

signal step_low;
signal step_high;

func _ready():
	
	if fp_controller.get_node("Configuration").get_refresh_rate() != 0:
		headset_refresh_rate = fp_controller.get_node("Configuration").get_refresh_rate()
		print("Walk in place got a headset refresh rate from the headset:")
		print(headset_refresh_rate)
		headset_refresh_set = true
	
	
	_fastest_step_s = .132 * (72.0/headset_refresh_rate); # faster then this will not detect a new step - new TB note - this was 10.0/72.0, e.g., .132, tied to quest 72 refresh
	_slowest_step_s = .347 * (headset_refresh_rate/72.0); # slower than this will not detect a high point step - new TB note - this was 25.0/72.0, e.g., .347, tied to quest 72 refresh
	
	step_duration = (30.0 * (headset_refresh_rate/72.0)) / 72.0 #20.0 / 72.0; # I had ~ 30 frames between steps...   #TB note - this was hard coded at 20/72, trying to match headset refresh rate, was also marked as a const instead of a variable
	
	
	_height_ringbuffer.resize(_height_ringbuffer_size);
	_current_height_estimate = vr_camera.transform.origin.y
	
	
	for i in range(0, _height_ringbuffer_size):
		_height_ringbuffer[i] = _current_height_estimate;


func _store_height_in_buffer(y):
	_height_ringbuffer[_height_ringbuffer_pos] = y;
	_height_ringbuffer_pos = (_height_ringbuffer_pos + 1) % _height_ringbuffer_size;
 

func _get_buffered_height(i):
	return _height_ringbuffer[(_height_ringbuffer_pos - i + _height_ringbuffer_size) % _height_ringbuffer_size];

# these constants were manually tweaked inside the jupyter notebook
# they reflect the correction needed for the quest on my head; more test data would be needed
# how well they fit to other peoples necks and movement
const Cup = -0.06;    
const Cdown = -0.177;


# this is required to adjust for the different headset height based on if the user is looking up, down or straight
func _get_viewdir_corrected_height(h, viewdir_y):
	if (viewdir_y >= 0.0):
		return h + Cup * viewdir_y;
	else:
		return h + Cdown * viewdir_y;


enum {
	NO_STEP,
	STEP_LOW,
	STEP_HIGH,
}


var _time_since_last_step = 0.0;

func _detect_step(dt):
	var min_value = _get_buffered_height(0);
	var max_value = min_value;
	var average = min_value;
	
	_time_since_last_step += dt;


	# find min and max for step detection
	var min_val_pos = 0;
	var max_val_pos = 0;
	for i in range(1, _num_steps_for_step_estimate):
		var val = _get_buffered_height(i);
		if (val < min_value):
			min_value = val;
			min_val_pos = i;
		if (val > max_value):
			max_value = val;
			max_val_pos = i;

	# compute average and variance for current height estimation
	for i in range(1, _num_steps_for_height_estimate):
		var val = _get_buffered_height(i);
		average += val;
	average = average / _num_steps_for_height_estimate;
	var variance = 0.0;
	for i in range(0, _num_steps_for_height_estimate):
		var val = _get_buffered_height(i);
		variance = variance + abs(average - val);
	variance = variance / _num_steps_for_height_estimate;
	
	# if there is not much variation in the last _height_ringbuffer_size values we take the average as our current heigh
	# assuming that we are not in a step process then
	if (variance <= _variance_height_detect_threshold):
		_current_height_estimate = average;
		
	
	var dist_max = max_value - _current_height_estimate;
	
	if (max_val_pos == _num_steps_for_step_estimate / 2 
		and dist_max > _step_up_min_detect_threshold
		and dist_max < _step_up_max_detect_threshold
		and _time_since_last_step <= _slowest_step_s
		and _had_high_step_after_low
		#and (_get_buffered_height(0) - min_value) > _step_local_detect_threshold # this can avoid some local mis predicitons
		): 
		_last_step_max = max_value;
		_had_high_step_after_low = false;
		_current_height_estimate = (_current_height_estimate + (_last_step_max + _last_step_min) * 0.5) * 0.5;
		return STEP_HIGH;
	
	# this is now the actual step detection based on that the center value of the ring buffer is the actual minimum (the turning point)
	# and also the defined thresholds to minimize false detections as much as possible
	var dist_min = _current_height_estimate - min_value;
	if (min_val_pos == _num_steps_for_step_estimate / 2 
		and dist_min > _step_height_min_detect_threshold
		and dist_min < _step_height_max_detect_threshold
		and _time_since_last_step >= _fastest_step_s
		and (_get_buffered_height(0) - min_value) > _step_local_detect_threshold # this can avoid some local mis predicitons
		): 
		_time_since_last_step = 0.0;
		_last_step_min = min_value;
		_had_high_step_after_low = true
		return STEP_LOW;

	return NO_STEP;



func is_jogging() -> bool:
	return _continous_step_count > num_steps_till_jogging;


func physics_movement(delta: float, player_body: PlayerBody, _disabled: bool):
	
	# Apply forwards/backwards ground control

	var view_dir = -vr_camera.global_transform.basis.z;
	view_dir.y = 0.0;
	view_dir = view_dir.normalized();
	
	var speed = speed_walking;
	
	if (is_jogging()):
#		print("jogging detected")
		speed = speed_jogging;
	
	#print("camera_transform.z.y is: ")
	#print(-vr_camera.transform.basis.z.y)
	
	#detect if head tilted far enough back to go backwards instead if head rotate to reverse is turned on
	if headset_tilt_to_reverse == true and -vr_camera.transform.basis.z.y >= .40:
		speed = -speed
			
	#detect if player wants to strafe with controller and if so, strafe direction, by direction of strafe controller
	if controller_strafing == true:
		var solve_controller_direction = vr_camera.global_transform.basis.x.dot(-l_controller.global_transform.basis.z)
		#print(solve_controller_direction)
		if solve_controller_direction > -.70 and solve_controller_direction < .70:
			is_strafing = false
		if solve_controller_direction <= -0.70:
			is_strafing = true
			speed = -speed
		if solve_controller_direction >= .70:
			is_strafing = true
	
	#detect if player wants to strafe with headset tilt, and if so, strafe to direction of head tilt	
	if headset_tilt_strafe == true:
#		print("camera basis x.y is")
#		print(vr_camera.transform.basis.x.y)
			#final angle of the difference, return in degrees to make more human-readable
		#print(str(angle))
		#Subtract 90 from angle to see if moving left or right
		var strafe_direction = vr_camera.transform.basis.x.y
		if strafe_direction > -.30 and strafe_direction < .30:
			is_strafing = false
		if strafe_direction >= .30:
			is_strafing = true
			speed = -speed
		if strafe_direction <= -.30:
			is_strafing = true
			
	
	#only trigger movement if script says player is actually moving
	if is_moving == true:
		#move player at either the walking or jogging speed as appropriate
		player_body.ground_control_velocity.y += speed 
		#player_body.ground_control_velocity.y += lerp(player_body.ground_control_velocity.y, speed, speed_transition_factor)
		
		
		#strafe player if script detects player wants to strafe by head movement
		if is_strafing == true:
			player_body.ground_control_velocity.y = 0
#			player_body.ground_control_velocity.y = lerp(player_body.ground_control_velocity.y, 0, speed_transition_factor)
			player_body.ground_control_velocity.x += strafe_speed_modifer * speed #+=lerp(player_body.ground_control_velocity.x, speed, speed_transition_factor)

		# Clamp ground control like in direct movement script
		player_body.ground_control_velocity.y = clamp(player_body.ground_control_velocity.y, -max_speed, max_speed)
		player_body.ground_control_velocity.x = clamp(player_body.ground_control_velocity.x, -max_speed, max_speed)
		
#		print("player ground control velocity is:")
#		print(player_body.ground_control_velocity)
		
	else:  #this means no steps are detected, player is standing
		player_body.ground_control_velocity.y = 0 
#		player_body.ground_control_velocity.y = lerp(player_body.ground_control_velocity.y, 0, speed_transition_factor)
		
		
# NOTE: this needs to be in the _process as all the values are tied to the actual display framerate of 72hz
#       at the moment

#maybe this should be physics_process??  this was func _process(dt) in original code with a note it was so because values were tied to a 72hz headset refresh rate for quest
func _process(dt):
	if (!enabled): return;
		
		#Get headset refresh rate in the event ready function did not detect it
	if headset_refresh_set == false:
		if fp_controller.get_node("Configuration").get_refresh_rate() != 0:
			headset_refresh_rate = fp_controller.get_node("Configuration").get_refresh_rate()
			print("Walk in place got a headset refresh rate from the headset:")
			print(headset_refresh_rate)
			headset_refresh_set = true
			_fastest_step_s = 10 * dt #.132 * (72.0/headset_refresh_rate); # faster then this will not detect a new step - new TB note - this was 10.0/72.0, e.g., .132, tied to quest 72 refresh
			_slowest_step_s = 50 * dt #.347 * (headset_refresh_rate/72.0); # slower than this will not detect a high point step - new TB note - this was 25.0/72.0, e.g., .347, tied to quest 72 refresh
			step_duration = 30 * dt#(20.0 * (headset_refresh_rate/72.0)) / 72.0 #20.0 / 72.0; # I had ~ 30 frames between steps...   #TB note - this was hard coded at 20/72, trying to match headset refresh rate, was also marked as a const instead of a variable
	
		
	
		
	var headset_height = vr_camera.transform.origin.y;
	
	#adjust height so moving head up or down doesn't stop script from working, ideally
	var corrected_height = _get_viewdir_corrected_height(headset_height, -vr_camera.transform.basis.z.y);
	_store_height_in_buffer(corrected_height);
	
	var step = _detect_step(dt);
	step_low_just_detected = false;
	step_high_just_detected = false;
	
	if (step == STEP_LOW):
		_step_time = step_duration;
		step_low_just_detected = true;
		_continous_step_count += 1;
		emit_signal("step_low");
	elif (step == STEP_HIGH):
		_step_time = step_duration;
		step_high_just_detected = true;
		emit_signal("step_high");
	else:
		_step_time -= dt;
		
		

	if (_step_time > 0.0):
		is_moving = true;
		physics_movement(dt, player_body, true);
		
	else:
		is_moving = false;
		#if (_step_time < -_time_until_continous_step_reset):
		_continous_step_count = 0;
	
	#Debug code	
#	if (is_moving):
#		if (is_jogging()):
#			print("WalkInPlace", "Jogging: %.3f" % _step_time);
#		else:
#			print("WalkInPlace", "Walking: %.3f" % _step_time);
#	else:
#			print("WalkInPlace", "Standing: %.3f" % _step_time);
		
			
func _get_configuration_warning():
	# Check the ARVROrigin node
	var test_origin = get_parent()
	if !test_origin or !test_origin is ARVROrigin:
		return "Unable to find ARVR Origin node - Must place as child of ARVROrigin/FPController"

	# Call base class
	return ._get_configuration_warning()



