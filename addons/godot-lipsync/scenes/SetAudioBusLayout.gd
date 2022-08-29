extends Node


export var audio_layout: AudioBusLayout


# Called when the node enters the scene tree for the first time.
func _ready():
	if audio_layout:
		AudioServer.set_bus_layout(audio_layout)
