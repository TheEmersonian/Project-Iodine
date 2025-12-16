extends Node3D

@export var player_scene: PackedScene = preload("res://scenes/entities/player.tscn")
@export var player: CharacterBody3D

@export var spawn_position: Vector3 = Vector3(0, 280, 0)

@onready var voxel_terrain: VoxelTerrain = $VoxelTerrain
#@onready var map_gen: MapGenerator = $MapGenerator

@onready var voxel_tool: VoxelTool = voxel_terrain.get_voxel_tool()

func _ready() -> void:
	voxel_terrain.stream.directory = "C:/Users/emers/AppData/Roaming/Project Iodine/world"
#	voxel_terrain.generator = preload("res://scenes/voxel_generator_iodine.gd")
	#setup_world()
	spawn_player()

func world_pos_to_block_pos(world_pos: Vector3):
	return Vector3i(world_pos + Vector3(0.5, 0.5, 0.5))

func remove_block(pos: Vector3, drop_block: bool = true):
	print("removing block at " + str(pos))
	if drop_block:
		print("dropping block")
		var block_id: int = voxel_tool.get_voxel(pos)
		var block_def = BlockRegistry.get_block_from_id(block_id)
		var block_item: Item = Item.new(block_def.block_name, block_def.item_id, 1)
		var dropped_item = DroppedItem.new(block_item)
		add_child(dropped_item)
		dropped_item.global_position = pos + Vector3(0.5, 0.5, 0.5)
		dropped_item.give_random_jump()
	voxel_tool.set_voxel(pos, 0)

func place_block(pos: Vector3, block = BlockRegistry.BlockDef):
	voxel_tool.set_voxel(pos, block.meshlib_id)

func spawn_player():
	player = player_scene.instantiate()
	add_child(player)
	player.position = spawn_position

func exit_game():
	print("Exiting world...")
	#remember to add player saving at some point
	player.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	##needs to be done this way instead of change to packed for some reason
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

#placement modes for blocklayerdata:
# 0 = surface
# 1 = below surface
# 2 = fixed depth

#func setup_world():
	##create a new world
	#map_gen.create_new_world("test", 45)
	#
	##add a plains biome
	#var plains: BiomeData = map_gen.add_biome("Plains")
	##add a layer of grass blocks
	#var grass := BlockLayerData.new()
	#grass.block_name = "Grass"
	#grass.block_id = 2
	#grass.placement_mode = 0 #should be the surface
	#grass.thickness = 1
	#plains.surface_blocks.append(grass)
	#
	#map_gen.generate_region(Vector3i(-3, 0, -3), Vector3i(3, 1, 3))
	





















#end
