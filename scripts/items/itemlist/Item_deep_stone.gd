extends Item

class_name Item_deep_stone

func _init(COUNT: int = 1) -> void:
	item_count = COUNT
	item_name = "deep_stone"
	item_id = ItemProcesser.item_to_id(item_name)
