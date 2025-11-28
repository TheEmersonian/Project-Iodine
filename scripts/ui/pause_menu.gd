extends PanelContainer

@export var player: CharacterBody3D

signal game_exited
signal game_continued

func _on_continue_button_pressed() -> void:
	emit_signal("game_continued")


func _on_settings_button_pressed() -> void:
	pass # Replace with function body.


func _on_main_menu_button_pressed() -> void:
	emit_signal("game_exited")
