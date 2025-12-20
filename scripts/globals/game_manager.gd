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
	var test_generation = load("res://scenes/voxel_generator_iodine.gd").new()
	var test_ter_vals = test_generation.get_terrain_values(0, 0)
	print("TERRAIN VALUES: " + str(test_ter_vals))
	var test_geo_vals = test_generation.compute_geology(test_ter_vals, 0, 0)
	print("GEOLOGY VALUES: " + str(test_geo_vals))
