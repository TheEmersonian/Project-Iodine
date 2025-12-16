
extends Node

##Read individually as they may be slightly unintuitive.  
enum GeneratedRotationType {
	##Completely random
	Random,
	##Randomly rotated around the x axis
	XRandom,
	##Randomly rotated around the z axis
	ZRandom,
	##Randomly rotated around the x and z axis's
	HorizontalRandom,
	##Randomly rotated around the y axis
	VerticalRandom,
	##The default that the blocks texture is in
	Fixed,
}

class BlockDef:
	var block_name: String
	var meshlib_id: int
	var item_id: int
	var is_solid: bool
	var generated_rotation: GeneratedRotationType
	var density: float
	var function: Script = null
	var default_metadata = null
	var icon: ImageTexture
	var model: Mesh
	func _init(name: String, mesh_id: int, item_type_id: int, block_icon: ImageTexture, block_model: Mesh, is_block_solid: bool = true, block_density: float = 1.0, generated_orientation: GeneratedRotationType = GeneratedRotationType.Fixed, block_function: Script = null) -> void:
		block_name = name
		meshlib_id = mesh_id
		item_id = item_type_id
		is_solid = is_block_solid
		density = block_density
		generated_rotation = generated_orientation
		function = block_function
		icon = block_icon
		model = block_model


@export var blocks: Dictionary = {}

func register_block(id: int, def: BlockDef):
	blocks[id] = def
	blocks[def.block_name] = def

func get_block_from_id(id: int) -> BlockDef:
	if blocks.keys().has(id):
		return blocks[id]
	print("Invalid id: " + str(id))
	return null

func get_block_from_name(blockname: String) -> BlockDef:
	if blocks.keys().has(blockname):
		return blocks[blockname]
	print("Invalid name: " + blockname)
	return null

func _ready() -> void:
	#0 reserved for air
	register_block(0, BlockDef.new("air", 0, 0,
	null, null, false, 0.0))
	##STONE (1-100 reserved for natural stone blocks) 
	#granite
	##            this and                      this should be the same value
	register_block(1, BlockDef.new("granite", 1, 1,
		preload("res://assets/textures/icons/granite.tres"), 
		preload("res://assets/models/granite.tres"), 
		true))
	#white claystone
	#register_block(2, BlockDef.new("white_claystone", 1, 2,
	#	preload("res://assets/textures/icons/white_claystone.tres"), 
	#	preload("res://assets/models/white_claystone.tres"), 
	#	true))
	#foidolite
	#register_block(3, BlockDef.new("foidolite", 2, 3,
	#preload("res://assets/textures/icons/foidolite.tres"), 
	#preload("res://assets/models/foidolite.tres"), 
	#true))
	#pegmatite
	#register_block(4, BlockDef.new("pegmatite", 3, 4,
	#preload("res://assets/textures/icons/pegmatite.tres"), 
	#preload("res://assets/models/pegmatite.tres"), 
	#true))
	#jaspillite
	#register_block(5, BlockDef.new("jaspillite", 4, 5,
	#preload("res://assets/textures/icons/jaspillite.tres"),
	#preload("res://assets/models/jaspillite.tres"),
	#true))
	
	##DIRT (101-150 reserved for dirt blocks)
	#soil, the healthy version of dirt
	register_block(2, BlockDef.new("soil", 2, 2,
	preload("res://assets/textures/icons/soil.tres"), 
	preload("res://assets/models/soil.tres"), 
	true))
	#dirt
	register_block(3, BlockDef.new("dirt", 3, 3,
	preload("res://assets/textures/icons/dirt.tres"), 
	preload("res://assets/models/dirt.tres"), 
	true))
	#soil with healthy grass, this is generally what will generate, but it can be made less healthy through various processes
	register_block(4, BlockDef.new("grass", 4, 4,
	preload("res://assets/textures/icons/soil_with_healthy_grass.tres"), 
	preload("res://assets/models/soil_with_healthy_grass.tres"), 
	true))
	#sparse grass
	register_block(5, BlockDef.new("sparse_grass", 5, 5,
	preload("res://assets/textures/icons/soil_with_grass.tres"), 
	preload("res://assets/models/soil_with_grass.tres"), 
	true))
	#muddy soil
	register_block(6, BlockDef.new("muddy_soil", 6, 6, 
	ImageTexture.create_from_image(preload("res://assets/textures/block_faces/mud_face.png").get_image()), 
	preload("res://assets/models/muddy_soil.tres"),
	true))
	#Error block, shows up when something goes wrong
	register_block(7, BlockDef.new("ERROR", 7, 7, 
	null, null, true))
	





#end
