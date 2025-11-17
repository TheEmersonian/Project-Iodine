extends Item

class_name Item_dirt_with_grass

func _init(COUNT: int = 1) -> void:
	item_count = COUNT
	item_name = "dirt_with_grass"
	item_id = ItemProcesser.item_to_id(item_name)
