extends Item

class_name Item_bedrock

func _init(COUNT: int = 1) -> void:
	item_count = COUNT
	item_name = "bedrock"
	item_id = ItemProcesser.item_to_id(item_name)
