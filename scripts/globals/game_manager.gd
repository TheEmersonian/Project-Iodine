extends Node

@export var game_directory: String = "C:/Users/emers/AppData/Roaming/Project Iodine"
@export var save_folder: String = ""

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(game_directory)
	save_folder = game_directory + "/world/"
