class_name LipSync
extends Node


##  Overview
##
## This module provides lip-sync services by classifying mouth shapes using a 
## spectrum analyzer listening to the microphone.
##
##
## Node Usage
## 
## This node constructs the necessary audio components to detect visemes when
## processed. It does require the project have the Audio Input Enabled option
## turned on.
##
## This module outputs the following fields:
##  - energy_raw[] for instantaneous energy (tuning/debugging)
##  - fingerprint[] for audio fingerprint (tuning/debugging)
##  - visemes[] for viseme weights


# List of standard visemes
enum VISEME {
	VISEME_SILENT = 0,	# Mouth closed (silent)
	VISEME_CH = 1,		# /tS/ (CHeck, CHoose) /dZ/ (Job, aGe) /S/ (She, puSh)
	VISEME_DD = 2,		# /t/ (Take, haT) /d/ (Day, haD)
	VISEME_E = 3,		# /e/ (Ever, bEd)
	VISEME_FF = 4,		# /f/ (Fan) /v/ (Van)
	VISEME_I = 5,		# /ih/ (fIx, offIce)
	VISEME_O = 6,		# /o/ (Otter, stOp)
	VISEME_PP = 7,		# /p/ (Pat, Put) /b/ (Bat, tuBe) /m/ (Mat, froM)
	VISEME_RR = 8,		# /r/ (Red, fRom)
	VISEME_SS = 9,		# /s/ (Sir, See) /z/ (aS, hiS)
	VISEME_TH = 10,		# /th/ (THink, THat)
	VISEME_U = 11,		# /ou/ (tOO, feW)
	VISEME_AA = 12,		# /A:/ (cAr, Art)
	VISEME_KK = 13,		# /k/ (Call, weeK) /g/ (Gas, aGo)
	VISEME_NN = 14,		# /n/ (Not, aNd) /l/ (Lot, chiLd)
	COUNT = 15
}

# Detection band ranges
const BANDS_RANGE = [
	[280.0, 25.0],
	[330.0, 25.0],
	[405.0, 30.0],
	[600.0, 40.0],
	[680.0, 40.0],
	[980.0, 50.0],
	[1260.0, 25.0],
	[1310.0, 25.0],
	[1550.0, 50.0],
	[1930.0, 50.0],
	[5000.0, 100.0]
]

# Detection bands count
const BANDS_COUNT = 11

# Table of reference fingerprints for the different mouth-shape sounds. Note that
# if the frequency bands or filtering is modified then these reference sounds will
# need to be updated. Additionally it is possible to add as many reference 
# audio-fingerprints to each mouth-shape, and doing so may increase the accuracy
# of the lip-sync results at the cost of increased computation.
const REFERENCES = {
	VISEME.VISEME_CH: [
		# /tS/ (CHeck, CHoose)
		[0, 0, 0, 0, 0, 0, 0.182233, 0.282583, 0.799365, 0.102279, 0.734584],
		# /dZ/ (Job, aGe)
		[0.347242, 0.216439, 0.264105, 0, 0, 0, 0, 0, 0.870648, 0.909387, 0.214404],
		# /S/ (She, puSh)
		[0, 0, 0, 0, 0, 0, 0.044587, 0.169253, 0.998294, 0.126679, 0.347826],
	],
	
	# Can't detect stop sound at this point
	#VISEME.VISEME_DD: [
	#	# /t/ (Take, haT)
	#	[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
	#	# /d/ (Day, haD)
	#	[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
	#],

	VISEME.VISEME_E: [
		# /e/ (Ever, bEd)
		[0.25422, 0.085497, 0.210144, 0.93685, 0.602294, 0.042456, 0.003305, 0.01159, 0.327482, 0.588085, 0],
	],

	VISEME.VISEME_FF: [
		# /f/ (Fan)
		[0.255648, 0.114284, 0.058918, 0.00006, 0.000022, 0.001046, 0.11012, 0.102804, 0.422762, 0.195262, 0.707652],
		# /v/ (Van)
		[0.491734, 0.348142, 0.370854, 0.073046, 0.053362, 0.284562, 0.249565, 0.139837, 0.033329, 0.004774, 0.0669],
	],
	
	VISEME.VISEME_I: [
		# /ih/ (fIx, offIce)
		[0.157123, 0.075783, 0.427328, 0.059475, 0.017625, 0, 0, 0, 0, 0.927563, 0],
	],

	VISEME.VISEME_O: [
		# /o/ (Otter, stOp)
		[0.015538, 0.104395, 0.602415, 0.930156, 0.840831, 0, 0, 0, 0, 0, 0],
	],
	
	VISEME.VISEME_PP: [
		# /p/ (Pat, Put) - Can't detect stop sound at this point
		#[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
		# /b/ (Bat, tuBe) - Can't detect stop sound at this point
		#[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
		# /m/ (Mat, froM)
		[0.504635, 0.23507, 0.09796, 0, 0, 0.018921, 0.407709, 0.247505, 0.627087, 0.342055, 0],
	],
	
	VISEME.VISEME_RR: [
		# /r/ (Red, fRom)
		[0.229323, 0.429268, 0.477367, 0.086681, 0.048044, 0.686111, 0.183987, 0.225395, 0.47989, 0, 0],
	],
	
	VISEME.VISEME_SS: [
		# /s/ (Sir, See)
		[0, 0, 0, 0, 0, 0, 0.005933, 0, 0.041186, 0, 0.961519],
		# /z/ (aS, hiS)
		[0.056344, 0.050053, 0.041431, 0.012309, 0, 0, 0.107074, 0.156547, 0.00046, 0, 0.945026],
	],

	VISEME.VISEME_TH: [
		# /th/ (THink, THat)
		[0.464307, 0.297907, 0.233567, 0.063131, 0.028015, 0.000034, 0.012875, 0.011093, 0.024088, 0.000001, 0.721035],
	],
	
	VISEME.VISEME_U: [
		# /ou/ (tOO, feW)
		[0.671332, 0.601132, 0.363994, 0.003564, 0.024449, 0.00137, 0, 0, 0, 0, 0],
	],
	
	VISEME.VISEME_AA: [
		# /A:/ (cAr, Art)
		[0.037338, 0.001947, 0.003749, 0.501244, 0.602046, 0.98699, 0.071917, 0.032218, 0.000027, 0, 0],
	],
	
	# Can't detect stop sound at this point
	#VISEME.VISEME_KK: [
	#	# /k/ (Call, weeK)
	#	[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
	#	# /g/ (Gas, aGo)
	#	[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
	#],
	
	VISEME.VISEME_NN: [
		# /n/ (Not, aNd)
		[0.691917, 0.299824, 0.042061, 0, 0, 0, 0.147797, 0.26852, 0.356389, 0.171189, 0],
		# /l/ (Lot, chiLd)
		[0.037952, 0.214629, 0.9767, 0.172632, 0.119215, 0.249349, 0, 0, 0, 0, 0],
	],
}

# Energy minimum dB
const ENERGY_DB_MIN = -60.0

# Energy dB range
const ENERGY_DB_RANGE = 15.0

# Bands default array
const BANDS_DEF = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
const VISEMES_DEF = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]


## Audio bus name
export var audio_bus_name := "Mic"

# Audio-Match precision
export var precision := 2.0


# Raw energy for each band (0..1)
var energy_raw := BANDS_DEF.duplicate()

# Audio fingerprint
var fingerprint := BANDS_DEF.duplicate()

# Visemes
var visemes := VISEMES_DEF.duplicate()

# Audio stream player
var _player : AudioStreamPlayer

# Spectrum analyzer effect instance
var _effect : AudioEffectSpectrumAnalyzerInstance


# Sort class for sorting [shape,distance] array by distance
class DistanceSorter:
	static func sort_ascending(a: Array, b: Array) -> bool:
		return true if a[1] < b[1] else false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Verify audio input is enabled
	if not ProjectSettings.get_setting("audio/enable_audio_input"):
		printerr("LipSync: Audio input not enabled in project")
		return

	# Get and configure the audio bus
	var bus := _get_or_create_audio_bus(audio_bus_name)
	AudioServer.set_bus_mute(bus, true)

	# Get and configure the spectrum analyzer
	var idx := _get_or_create_spectrum_analyzer(bus)
	var spectrum_cfg := AudioServer.get_bus_effect(bus, idx) as AudioEffectSpectrumAnalyzer
	spectrum_cfg.buffer_length = 0.1
	spectrum_cfg.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_512
	spectrum_cfg.tap_back_pos = 0.1

	# Get the spectrum analyzer instance
	_effect = AudioServer.get_bus_effect_instance(bus, idx)

	# Create the audio stream player
	_player = AudioStreamPlayer.new()
	_player.set_name("LipSyncInput")
	_player.stream = AudioStreamMicrophone.new()
	_player.bus = audio_bus_name
	add_child(_player)
	
	# Start playing the microphone into the audio bus
	_player.play()


# Process the lip-sync audio
func _process(_delta: float) -> void:
	# Calculate absolute dB energy
	var energy_db := BANDS_DEF.duplicate()
	for i in BANDS_COUNT:
		var center_hz: float = BANDS_RANGE[i][0]
		var width_hz: float = BANDS_RANGE[i][1]
		var magnitude := _effect.get_magnitude_for_frequency_range(center_hz - width_hz, center_hz + width_hz, 1)
		var energy := 0.000001 + magnitude.length() * center_hz / 500.0
		energy_db[i] = linear2db(energy)

	# Calculate normalized energy
	var energy_db_max: float = energy_db.max()
	var energy_db_floor := max(energy_db_max - ENERGY_DB_RANGE, ENERGY_DB_MIN)
	for i in BANDS_COUNT:
		energy_raw[i] = clamp((energy_db[i] - energy_db_floor) / ENERGY_DB_RANGE, 0.0, 1.0)

	# Calculate filtered energy
	for i in BANDS_COUNT:
		var filt: float = fingerprint[i]
		var raw: float = energy_raw[i]
		fingerprint[i] = lerp(filt, raw, 0.2)

	# Populate initial mouth-shape weights
	visemes = VISEMES_DEF.duplicate()

	# Handle silence
	if energy_db_max <= ENERGY_DB_MIN:
		visemes[VISEME.VISEME_SILENT] = 1.0
		return

	# Build array of distances
	var distances := []
	distances.append([VISEME.VISEME_SILENT, precision])
	for shape in REFERENCES:
		# Calculate the shortest distance from the fingerprint to the mouth-shape
		var distance := 1000.0
		for reference in REFERENCES[shape]:
			distance = min(distance, _fingerprint_distance(fingerprint, reference))

		# Save the distance
		distances.append([shape, distance])

	# Sort distances in ascending order (first two will be closest mouth-shapes)
	distances.sort_custom(DistanceSorter, "sort_ascending")

	# Perform smooth-voronoi weighting between the mouth-shape regions
	var shape1: int = distances[0][0]
	var shape2: int = distances[1][0]
	var distance1: float = distances[0][1]
	var distance2: float = distances[1][1]
	var ratio := distance2 / (distance1 + distance2)
	var weight1 := smoothstep(0.2, 0.8, ratio)
	var weight2 := 1.0 - weight1
	visemes[shape1] = weight1
	visemes[shape2] = weight2


# Get or create an audio bus with the specified name
static func _get_or_create_audio_bus(name: String) -> int:
	# Find the audio bus
	var bus := AudioServer.get_bus_index(name)
	if bus >= 0:
		print("LipSync: Found existing audio bus ", bus, " (", name, ")")
		return bus

	# Create new bus	
	bus = AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(bus, name)
	AudioServer.set_bus_mute(bus, true)

	# Return bus
	print("LipSync: Created new audio bus ", bus, " (", name, ")")
	return bus


# Get or create a spectrum analyzer on the specified audio bus
static func _get_or_create_spectrum_analyzer(bus: int) -> int:
	# Search through existing effects
	for i in AudioServer.get_bus_effect_count(bus):
		var effect := AudioServer.get_bus_effect(bus, i) as AudioEffectSpectrumAnalyzer
		if effect:
			print("LipSync: Found existing spectrum analyzer effect ", bus, ":", i)
			return i

	# Create the spectrum analyzer
	var idx := AudioServer.get_bus_effect_count(bus)
	AudioServer.add_bus_effect(bus, AudioEffectSpectrumAnalyzer.new())

	# Return spectrum analyzer effect
	print("LipSync: Created new spectrum analyzer effect ", bus, ":", idx)
	return idx


# Calculate the distance between two fingerprints
static func _fingerprint_distance(a: Array, b: Array) -> float:
	# Calculate the sum-of-squares of the error between bins
	var distance := 0.0
	for i in BANDS_COUNT:
		var err: float = a[i] - b[i];
		distance += err * err

	# Return the distance (squared)
	return distance
