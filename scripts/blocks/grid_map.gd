extends GridMap

@onready var block_overlay: GridMap = %BlockOverlay

@export var player_scene: PackedScene = preload("res://scenes/entities/player.tscn")

@export var world_size: Vector3i = Vector3i(5,5,5)

##DO NOT CHANGE THIS
@export var chunk_size: Vector3i = Vector3i(16,16,16)
@export var noise1: FastNoiseLite = FastNoiseLite.new()
@export var noise2: FastNoiseLite = FastNoiseLite.new()
@export var noise3: FastNoiseLite = FastNoiseLite.new()
@export var noise4: FastNoiseLite = FastNoiseLite.new()
@export var noise5: FastNoiseLite = FastNoiseLite.new()

var world: Array = []

var player_ref: CharacterBody3D

class Chunk:
	var cpos: Vector3i
	var blocks: Array = []
	
	func _init(chunk_position: Vector3i) -> void:
		cpos = chunk_position
	
	func cpos_to_bpos(chunk_position: Vector3i):
		return chunk_position*16
	
	func set_block(pos: Vector3i, id: int):
		blocks[pos.x][pos.y].set(pos.z, id)
	
	func calculate_layered_noise(pos: Vector2, noisearray: Array[FastNoiseLite], base_height: float):
		var x: float = pos.x
		var y: float = pos.y
		var value: float = base_height
		var multiplier: float = 2.0
		var multi_start: float = multiplier
		var size: int = noisearray.size()
		for n in noisearray:
			value += abs(n.get_noise_2d(x, y) * multiplier)
			multiplier *= 1.0 - 1.0/float(size)
		return value / (multi_start - multiplier)
	
	func check_noise_spikes(pos: Vector2, noisearray: Array[FastNoiseLite], spike_threshold: float = 0.9):
		var x: float = pos.x
		var y: float = pos.y
		var spike_stacks: int = 0
		var spike_height: float = 0
		for n in noisearray:
			var value: float = n.get_noise_2d(x*5, y*5)
			if value > spike_threshold:
				spike_stacks += 1
				spike_height += value
				spike_height = pow(spike_height, value*2.0)
		if spike_stacks >= 0: #noisearray.size()*0.5:
			return spike_height
		else:
			return 0.0
	
	func generate_chunk(noisearray: Array[FastNoiseLite]):
		var grass: int = ItemProcesser.item_to_id("dirt_with_grass")
		var dirt: int = ItemProcesser.item_to_id("dirt")
		var stone: int = ItemProcesser.item_to_id("stone")
		var deep_stone: int = ItemProcesser.item_to_id("deep_stone")
		var bedrock: int = ItemProcesser.item_to_id("bedrock")
		var chunk_offset: Vector3i = cpos_to_bpos(cpos)
		blocks.resize(16)
		for x in range(16):
			blocks.set(x, [])
			blocks[x].resize(16)
			for y in range(16):
				blocks[x].set(y, [])
				blocks[x][y].resize(16)
				for z in range(16):
					var noise_position = chunk_offset + Vector3i(x, 0, z)
					var noise_value: float = calculate_layered_noise(Vector2(noise_position.x, noise_position.z), noisearray, -5)
					var height: int = 5 + abs(round(noise_value*10.0))
					var tpos: Vector3i = chunk_offset + Vector3i(x, y, z)
					
					if tpos.y == height:
						blocks[x][y][z] = grass
					elif tpos.y < height:
						@warning_ignore("narrowing_conversion")
						var dirt_height: int = height-(height/10.0)
						if tpos.y > dirt_height:
							blocks[x][y][z] = dirt
						if cpos.y == 0:
							if tpos.y <= noisearray[4].get_noise_3d(tpos.x, tpos.y, tpos.z)*12.0 + (5-y) - ((noisearray[4].get_noise_3d(tpos.x*100.0, tpos.y*100.0, tpos.z*100.0)*10.0)):
								blocks[x][y][z] = bedrock
							else:
								blocks[x][y][z] = deep_stone
						elif tpos.y <= height*0.5:
							blocks[x][y][z] = deep_stone
						else:
							blocks[x][y][z] = stone
					elif tpos.y <= check_noise_spikes(Vector2(x, z), noisearray, 0.5):
						blocks[x][y][z] = bedrock
					else:
						blocks[x][y][z] = -1
	func place_chunk(grid: GridMap):
		var chunk_offset: Vector3i = cpos_to_bpos(cpos)
		var pos: Vector3i = Vector3i.ZERO
		for x in blocks:
			pos.x += 1
			for y in x:
				pos.y += 1
				for z in y:
					pos.z += 1
					var block: int = blocks[pos.x-1][pos.y-1][pos.z-1] - 1
					grid.set_cell_item(chunk_offset + pos, block)
				pos.z = 0
			pos.y = 0
		pos.x = 0

func _ready() -> void:
	setup_noise()
	generate_world()
	spawn_player()

func _physics_process(_delta: float) -> void:
	block_overlay.clear()
	var hpos: Vector3 = player_ref.selected_position
	if hpos != Vector3.ZERO:
		var bpos: Vector3i = block_overlay.local_to_map(hpos)
		block_overlay.set_cell_item(bpos, 0)

func destroy_block(world_coordinate: Vector3, drop_block: bool = true):
	var map_coordinate: Vector3i = local_to_map(world_coordinate)
	var chunk_coordinate: Vector3i = block_pos_to_chunk_pos(map_coordinate)
	var cbpos: Vector3i = map_coordinate - chunk_pos_to_block_pos(chunk_coordinate)
	world[chunk_coordinate.x][chunk_coordinate.y][chunk_coordinate.z].set_block(cbpos, -1)
	if drop_block:
		var block_id: int = get_cell_item(map_coordinate) + 1
		var block_item: Item = Item.new(ItemProcesser.id_to_item(block_id), block_id, 1)
		var dropped_item = DroppedItem.new(block_item)
		add_child(dropped_item)
		dropped_item.global_position = world_coordinate
		dropped_item.give_random_jump()
	set_cell_item(map_coordinate, -1)

func place_block(world_coordinate: Vector3, item_id: int):
	var map_coordinate: Vector3i = local_to_map(world_coordinate)
	var chunk_coordinate: Vector3i = block_pos_to_chunk_pos(map_coordinate)
	var cbpos: Vector3i = map_coordinate - chunk_pos_to_block_pos(chunk_coordinate)
	world[chunk_coordinate.x][chunk_coordinate.y][chunk_coordinate.z].set_block(cbpos, item_id-1)
	#subtract 1 because the mesh library starts with 0 but block id's start with 1
	set_cell_item(map_coordinate, item_id-1)

func generate_block(pos: Vector3i, index: int):
	set_cell_item(pos, index)

func setup_noise():
	noise1.seed = randi()
	noise2.seed = randi()
	noise3.seed = randi()
	noise4.seed = randi()
	noise5.seed = randi()
	
	noise1.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise2.noise_type = FastNoiseLite.TYPE_PERLIN
	noise3.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise4.noise_type = FastNoiseLite.TYPE_PERLIN
	noise5.noise_type = FastNoiseLite.TYPE_CELLULAR
	
	noise1.frequency = 0.0001
	noise2.frequency = 0.0005
	noise3.frequency = 0.0025
	noise4.frequency = 0.0125
	noise5.frequency = 0.0625

func generate_world():
	world.resize(world_size.x)
	for chunk_x in range(world_size.x):
		world.set(chunk_x, [])
		world[chunk_x].resize(world_size.y)
		for chunk_y in range(world_size.y):
			world[chunk_x].set(chunk_y, [])
			world[chunk_x][chunk_y].resize(world_size.z)
			for chunk_z in range(world_size.z):
				var new_chunk: Chunk = Chunk.new(Vector3i(chunk_x, chunk_y, chunk_z))
				new_chunk.generate_chunk([noise1, noise2, noise3,noise4,noise5])
				new_chunk.place_chunk(self)
				world[chunk_x][chunk_y].set(chunk_z, new_chunk)

func chunk_pos_to_block_pos(chunk_pos: Vector3i):
	return Vector3i(chunk_pos * 16)

func block_pos_to_chunk_pos(block_pos: Vector3i):
	return Vector3i(block_pos / 16)

func spawn_player():
	var y_level: int = 0
	while y_level < 100:
		y_level += 1
		@warning_ignore("narrowing_conversion")
		if get_cell_item(Vector3i(world_size.x/2.0,y_level,world_size.z/2.0)) == INVALID_CELL_ITEM:
			break
	var player = player_scene.instantiate()
	add_child(player)
	player.position = Vector3(world_size.x/2.0,y_level+1,world_size.z/2.0)
	player_ref = player

#end
