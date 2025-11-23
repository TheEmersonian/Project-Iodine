extends Node

@export var game_directory: String = "user://AppData/Roaming/Project Iodine"
@export var save_file: String = ""

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(game_directory)
	save_file = game_directory + "/world"
