extends VBoxContainer

@onready var fps_display: Label = $FPS
@onready var position_display: Label = $POSITION
@onready var chunk_position_display: Label = $CHUNK_POSITION

@export var displayed_position: Vector3

func _physics_process(_delta: float) -> void:
	fps_display.text = "FPS: " + str(Engine.get_frames_per_second())
	position_display.text = "Position: " + str(displayed_position).pad_decimals(3)
	chunk_position_display.text = "Chunk: " + str(Vector3i(floor(displayed_position/16)))
