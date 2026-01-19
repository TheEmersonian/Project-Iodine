extends Control

@onready var new_game: Button = $"CenterContainer/VBoxContainer/New Game"
@onready var load_game: Button = $"CenterContainer/VBoxContainer/Load Game"
@onready var settings: Button = $CenterContainer/VBoxContainer/Settings
@onready var quit_game: Button = $"CenterContainer/VBoxContainer/Quit Game"

const WORLD = preload("res://testplayer.tscn") #preload("res://scenes/world.tscn")

func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_packed(WORLD)


func _on_load_pressed() -> void:
	pass # Replace with function body.


func _on_settings_pressed() -> void:
	pass # Replace with function body.


func _on_quit_game_pressed() -> void:
	get_tree().quit()
