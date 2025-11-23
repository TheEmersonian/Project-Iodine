extends Node

enum ItemType {
	Block,
	Equipment,
	Equipment_Head,
	Equipment_Chest,
	Equipment_Legs,
	Equipment_Feet,
}

## Converts the name of a item, such as "oak_planls" to the id.  Note that that format is required
func item_to_id(item_name: String):
	match item_name:
		"stone": return 1
		"deep_stone": return 2
		"bedrock": return 3
		"dirt": return 4
		"dirt_with_grass": return 5
		"oak_log": return 6
		"oak_planks": return 7
	get_tree().quit(1) #error code 1 is when you interact with a item type that isn't in the game

## Converts the id of a item to the name, such as "oak_planks".  Note that that format is required
func id_to_item(id: int):
	match id:
		1: return "stone"
		2: return "deep_stone"
		3: return "bedrock"
		4: return "dirt"
		5: return "dirt_with_grass"
		6: return "oak_log"
		7: return "oak_planks"
	get_tree().quit(2) #error code 1 is when you interact with a item type that isn't in the game

func id_to_icon(id: int):
	match id:
		1: return preload("res://assets/textures/icons/stone.tres")
		#2: return preload("res://assets/textures/icons/deep_stone.tres")
		3: return preload("res://assets/textures/icons/bedrock.tres")
		4: return preload("res://assets/textures/icons/dirt.png")
		5: return preload("res://assets/textures/icons/dirt_with_grass.tres")
		6: return preload("res://assets/textures/icons/oak_log.tres")
		7: return preload("res://assets/textures/icons/oak_planks.tres")
	print("Invalid item")
	return preload("res://assets/textures/ui/Ether2.png")

func id_to_model(id: int):
	match id:
		1: return preload("res://assets/models/stone.tres")
		2: return preload("res://assets/models/deep_stone.tres")
		3: return preload("res://assets/models/bedrock.tres")
		4: return preload("res://assets/models/dirt.tres")
		5: return preload("res://assets/models/dirt_with_grass.tres")
		6: return preload("res://assets/models/oak_log.tres")
		7: return preload("res://assets/models/oak_planks.tres")

func item_to_mass(item_name: String):
	match item_name:
		"stone": return 3.75
		"deep_stone": return 7
		"bedrock": return 82
		"dirt": return 1.3
		"dirt_with_grass": return 1.325
		"oak_log": return 1.1
		"oak_planks": return 0.6
	return 1.0
