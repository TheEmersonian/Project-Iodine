
extends Node

class BlockDef:
	var name: String
	var solid: bool
	var function: Script = null
	var default_metadata = null
	func _init(block_name: String, is_solid: bool = true, block_function: Script = null) -> void:
		name = block_name
		solid = is_solid
		function = block_function


@export var blocks: Dictionary = {}

func register_block(id: int, def: BlockDef):
	blocks[id] = def

func get_block(id: int):
	return blocks[id]

func _ready() -> void:
	register_block(0, BlockDef.new("stone"))
	register_block(1, BlockDef.new("deep_stone"))
	register_block(2, BlockDef.new("bedrock"))
	register_block(3, BlockDef.new("dirt"))
	register_block(4, BlockDef.new("dirt_with_grass"))






#end
