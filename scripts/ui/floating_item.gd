extends MarginContainer

@onready var item_display: NinePatchRect = $ItemDisplay
@onready var slot_count: Label = $SlotCount

@export var stored_item: Item

#func _process(_delta: float) -> void:
#	queue_redraw()
#
#func _draw() -> void:
#	draw_circle(get_local_mouse_position(), 11, Color.RED, false)
#	draw_circle(Vector2.ZERO, 10, Color.AQUA)

func set_item(item: Item):
	stored_item = item
	if item.item_id == 0:
		hide()
		return
	else:
		show()
		item_display.texture = BlockRegistry.get_block_from_id(stored_item.item_id).icon
	if item.item_count > 1:
		slot_count.show()
		slot_count.text = str(item.item_count)
	else:
		slot_count.hide()
