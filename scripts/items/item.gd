extends Node2D

class_name Item

@export var item_name: String
@export var item_id: int
@export var item_count: int


func _init(NAME: String, ID: int, COUNT: int) -> void:
	item_name = NAME
	item_id = ID
	item_count = COUNT

func copy():
	var item_copy: Item = Item.new(item_name, item_id, item_count)
	return item_copy

func clear():
	item_name = ""
	item_count = 0
	item_id = 0

func as_string():
	return "<|" + str(item_name) + ", #" + str(item_id) + ", ID: " + str(item_id) + "|>"

func on_pickup():
	pass

func on_drop():
	pass

func on_land():
	pass

func in_slot_tick():
	pass
