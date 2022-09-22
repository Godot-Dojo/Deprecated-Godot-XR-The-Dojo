# Author: Malcolm Nixon https://github.com/Malcolmnixon
# GitHub Project Page: To be released as a addon for the Godot Engine
# License: MIT

extends MeshInstance

onready var Viseme_Ch : float 
onready var Viseme_Dd : float 
onready var Viseme_E : float 
onready var Viseme_Ff : float
onready var Viseme_I : float
onready	var Viseme_O : float
onready	var Viseme_Pp : float
onready	var Viseme_Rr : float
onready	var Viseme_Ss : float
onready	var Viseme_Th : float
onready	var Viseme_U : float
onready	var Viseme_AA : float
onready	var Viseme_Kk : float
onready	var Viseme_Nn : float
onready	var Viseme_Sil : float
var blinktime : int = 0
var blink_time_set  := false
var blink_at : int = 0

func _ready():
	pass
	
func _physics_process(delta):
	Viseme_Ch = $LipSync.visemes[LipSync.VISEME.VISEME_CH]
	Viseme_Dd = $LipSync.visemes[LipSync.VISEME.VISEME_DD]
	Viseme_E = $LipSync.visemes[LipSync.VISEME.VISEME_E]
	Viseme_Ff = $LipSync.visemes[LipSync.VISEME.VISEME_FF]
	Viseme_I = $LipSync.visemes[LipSync.VISEME.VISEME_I]
	Viseme_O = $LipSync.visemes[LipSync.VISEME.VISEME_O]
#	Viseme_Pp = $LipSync.visemes[LipSync.VISEME.VISEME_PP]
	Viseme_Rr = $LipSync.visemes[LipSync.VISEME.VISEME_RR]
	Viseme_Ss = $LipSync.visemes[LipSync.VISEME.VISEME_SS]
	Viseme_Th = $LipSync.visemes[LipSync.VISEME.VISEME_TH]
	Viseme_U = $LipSync.visemes[LipSync.VISEME.VISEME_U]
	Viseme_AA = $LipSync.visemes[LipSync.VISEME.VISEME_AA]
	Viseme_Kk = $LipSync.visemes[LipSync.VISEME.VISEME_KK]
	Viseme_Nn = $LipSync.visemes[LipSync.VISEME.VISEME_NN]
	Viseme_Sil = $LipSync.visemes[LipSync.VISEME.VISEME_SILENT]
	
	self.set("blend_shapes/viseme_CH", Viseme_Ch)
	self.set("blend_shapes/viseme_DD", Viseme_Dd)
	self.set("blend_shapes/viseme_E", Viseme_E)
	self.set("blend_shapes/viseme_FF", Viseme_Ff)
	self.set("blend_shapes/viseme_I", Viseme_I)
	self.set("blend_shapes/viseme_O", Viseme_O)
#	self.set("blend_shapes/viseme_PP", Viseme_Pp)
	self.set("blend_shapes/viseme_RR", Viseme_Rr)
	self.set("blend_shapes/viseme_SS", Viseme_Ss)
	self.set("blend_shapes/viseme_TH", Viseme_Th)
	self.set("blend_shapes/viseme_U", Viseme_U)
	self.set("blend_shapes/viseme_aa", Viseme_AA)
	self.set("blend_shapes/viseme_kk", Viseme_Kk)
	self.set("blend_shapes/viseme_nn", Viseme_Nn)
#	self.set("blend_shapes/viseme_sil", Viseme_Sil)
	#lerping the silent value to try for smoother transitions
	self.set("blend_shapes/viseme_sil", lerp(self.get("blend_shapes/viseme_sil"), Viseme_Sil, delta))
	
	#Create random blinking effect
	if blink_time_set == false:
		var random = RandomNumberGenerator.new()
		random.randomize()
		blink_at = random.randi_range(200, 400) # set random blink time, ~every 5 or so seconds, sometimes more, sometimes less
		blink_time_set = true
	blinktime+=1
	if blinktime >= blink_at:
		self.set("blend_shapes/eyeBlinkLeft", 1)   # blink
		self.set("blend_shapes/eyeBlinkRight", 1)
		yield(get_tree().create_timer(.33), "timeout")  # average blink time is 1/3 of a second
		self.set("blend_shapes/eyeBlinkLeft", 0)
		self.set("blend_shapes/eyeBlinkRight", 0)  # unblink
		blinktime = 0
		blink_time_set = false  # set next blink time randomly again

	
	
	
	#Trying with all lerps - too slow but preserving
	#self.set("blend_shapes/viseme_CH", lerp(self.get("blend_shapes/viseme_CH"), Viseme_Ch, 20*delta))

	#self.set("blend_shapes/viseme_E", lerp(self.get("blend_shapes/viseme_E"), Viseme_E, 20*delta))
	#self.set("blend_shapes/viseme_FF", lerp(self.get("blend_shapes/viseme_FF"), Viseme_Ff, 20*delta))
	#self.set("blend_shapes/viseme_I", lerp(self.get("blend_shapes/viseme_I"), Viseme_I, 20*delta))
	#self.set("blend_shapes/viseme_O", lerp(self.get("blend_shapes/viseme_O"), Viseme_O, 20*delta))
	#self.set("blend_shapes/viseme_PP", lerp(self.get("blend_shapes/viseme_PP"), Viseme_Pp, 20*delta))
	#self.set("blend_shapes/viseme_RR", lerp(self.get("blend_shapes/viseme_RR"), Viseme_Rr, 20*delta))
	#self.set("blend_shapes/viseme_SS", lerp(self.get("blend_shapes/viseme_SS"), Viseme_Ss, 20*delta))
	#self.set("blend_shapes/viseme_TH", lerp(self.get("blend_shapes/viseme_TH"), Viseme_Th, 20*delta))
	#self.set("blend_shapes/viseme_U", lerp(self.get("blend_shapes/viseme_U"), Viseme_U, 20*delta))
	#self.set("blend_shapes/viseme_aa", lerp(self.get("blend_shapes/viseme_aa"), Viseme_AA, 20*delta))

	#self.set("blend_shapes/viseme_nn", lerp(self.get("blend_shapes/viseme_nn"), Viseme_Nn, 20*delta))
	#self.set("blend_shapes/viseme_sil", lerp(self.get("blend_shapes/viseme_sil"), Viseme_Sil, 20*delta))

