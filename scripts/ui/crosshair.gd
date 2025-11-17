extends Control


func _draw() -> void:
	draw_line(Vector2(-10,0), Vector2(10,0), Color.WHITE)
	draw_line(Vector2(0,-10), Vector2(0,10), Color.WHITE)
