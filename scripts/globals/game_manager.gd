extends Node

@export var game_directory: String = "user://AppData/Roaming/Project Iodine"
@export var save_folder: String = ""
@export var seeds := []

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(game_directory)
	save_folder = game_directory + "/world/"
	randomize()
	for i in range(20):
		seeds.append(randi())
	print(str(seeds))
