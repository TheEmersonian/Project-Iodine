extends Node3D

@onready var map_gen: MapGenerator = $MapGenerator
@onready var voxel_world = $VoxelWorld

func _ready():
	# Create a new world
	map_gen.create_new_world("MyWorld", 12345)
	
	# Add a plains biome
	var plains = map_gen.add_biome("Plains")
	plains.min_x = -500
	plains.max_x = 500
	plains.min_z = -500
	plains.max_z = 500
	
	# Add grass surface layer
	var grass = BlockLayerData.new()
	grass.layer_name = "Grass"
	grass.block_id = 2
	grass.placement_mode = 0 # Surface
	grass.thickness = 1
	plains.surface_blocks.append(grass)
	
	# Add dirt subsurface
	var dirt = BlockLayerData.new()
	dirt.layer_name = "Dirt"
	dirt.block_id = 3
	dirt.placement_mode = 1 # Below Surface
	dirt.depth_from_surface = 1
	dirt.thickness = 4
	plains.subsurface_blocks.append(dirt)
	
	# Add stone underground
	var stone = BlockLayerData.new()
	stone.layer_name = "Stone"
	stone.block_id = 1
	stone.placement_mode = 2 # Fixed Depth
	stone.min_height = 0
	stone.max_height = 60
	plains.underground_blocks.append(stone)
	
	# Generate spawn area
	map_gen.generate_region(Vector3i(-3, 0, -3), Vector3i(3, 1, 3))
