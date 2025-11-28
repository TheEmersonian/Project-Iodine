@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type(
		"MapGenerator",
		"Node3D",
		preload("map_generator.gd"),
		preload("icons/map_generator.svg")
	)
	print("MapGenerator plugin loaded")

func _exit_tree():
	remove_custom_type("MapGenerator")
	print("MapGenerator plugin unloaded")