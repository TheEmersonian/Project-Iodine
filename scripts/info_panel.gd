extends VBoxContainer

@onready var fps_display: Label = $FPS
@onready var position_display: Label = $POSITION
@onready var chunk_position_display: Label = $CHUNK_POSITION
@onready var velocity_and_speed_display: Label = $"VELOCITY&SPEED"

@export var displayed_position: Vector3
@export var displayed_velocity: Vector3

func _physics_process(_delta: float) -> void:
	fps_display.text = "FPS: " + str(Engine.get_frames_per_second())
	position_display.text = "Position: " + str(floor(displayed_position*100)/100)
	velocity_and_speed_display.text = "Velocity: " + str(floor(displayed_velocity*100)/100) + " Speed: " + str(floor(displayed_velocity.length()*100)/100)
	chunk_position_display.text = "Chunk: " + str(Vector3i(floor(displayed_position/16)))
