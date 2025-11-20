extends GridMap

@onready var block_overlay: GridMap = %BlockOverlay

@export var player_scene: PackedScene = preload("res://scenes/entities/player.tscn")

@export var world_size: Vector3i = Vector3i(3,3,3)

##DO NOT CHANGE THIS
const CHUNK_SIZE: int = 16

@export var noise1: FastNoiseLite = FastNoiseLite.new()
@export var noise2: FastNoiseLite = FastNoiseLite.new()
@export var noise3: FastNoiseLite = FastNoiseLite.new()
@export var noise4: FastNoiseLite = FastNoiseLite.new()
@export var noise5: FastNoiseLite = FastNoiseLite.new()

var world := {}

var player_ref: CharacterBody3D

class Chunk:
	var cpos: Vector3i
	var blocks: PackedInt32Array
	var metadata := {}
	var tile_entities := {} 
	
	func _init(chunk_position: Vector3i) -> void:
		cpos = chunk_position
		blocks.resize(CHUNK_SIZE*CHUNK_SIZE*CHUNK_SIZE)
	
	func cpos_to_bpos(chunk_position: Vector3i):
		return chunk_position*16
	
	func bpos_to_index(pos: Vector3i) -> int:
		return pos.x + pos.y*CHUNK_SIZE + pos.z*CHUNK_SIZE*CHUNK_SIZE
	
	func index_to_bpos(index: int) -> Vector3i:
		var x = index % CHUNK_SIZE
		@warning_ignore("integer_division")
		var y = (index / CHUNK_SIZE) % CHUNK_SIZE
		@warning_ignore("integer_division")
		var z = index / (CHUNK_SIZE * CHUNK_SIZE)
		return Vector3i(x, y, z)
	
	func set_block(pos: Vector3i, id: int):
		var index: int = bpos_to_index(pos)
		blocks.set(index, id)
	
	func create_tile_entity(pos: Vector3i, script: Script):
		var tile_entity = script.new(self, pos)
		tile_entities[pos] = tile_entity
	
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
		for x in range(CHUNK_SIZE):
			for y in range(CHUNK_SIZE):
				for z in range(CHUNK_SIZE):
					var in_chunk_position: Vector3i = Vector3i(x, y, z)
					var noise_position: Vector3i = chunk_offset + Vector3i(x, 0, z)
					var noise_value: float = calculate_layered_noise(Vector2(noise_position.x, noise_position.z), noisearray, -5)
					var height: int = 5 + abs(round(noise_value*10.0))
					var tpos: Vector3i = chunk_offset + in_chunk_position
					
					if tpos.y == height:
						set_block(in_chunk_position, grass)
					elif tpos.y < height:
						@warning_ignore("narrowing_conversion")
						var dirt_height: int = height-(height/10.0)
						if tpos.y > dirt_height:
							set_block(in_chunk_position, dirt)
						if cpos.y == 0:
							if tpos.y <= noisearray[4].get_noise_3d(tpos.x, tpos.y, tpos.z)*12.0 + (5-y) - ((noisearray[4].get_noise_3d(tpos.x*100.0, tpos.y*100.0, tpos.z*100.0)*10.0)):
								set_block(in_chunk_position, bedrock)
							else:
								set_block(in_chunk_position, deep_stone)
						elif tpos.y <= height*0.5:
							set_block(in_chunk_position, deep_stone)
						else:
							set_block(in_chunk_position, stone)
					else:
						set_block(in_chunk_position, -1)
	
	func place_chunk(grid: GridMap):
		var chunk_offset: Vector3i = cpos_to_bpos(cpos)
		for i in blocks.size():
			var pos: Vector3i = index_to_bpos(i)
			var block: int = blocks[i]
			grid.set_cell_item(chunk_offset + pos, block-1)


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
	var chunk: Chunk = world[chunk_coordinate]
	chunk.set_block(cbpos, -1)
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
	var chunk: Chunk = world[chunk_coordinate]
	chunk.set_block(cbpos, item_id)
	
	var def = BlockRegistry.get_block(item_id)
	if def.function:
		chunk.create_tile_entity(map_coordinate, def.function)
	
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
	for chunk_x in range(world_size.x):
		for chunk_y in range(world_size.y):
			for chunk_z in range(world_size.z):
				var new_chunk: Chunk = Chunk.new(Vector3i(chunk_x, chunk_y, chunk_z))
				new_chunk.generate_chunk([noise1, noise2, noise3,noise4,noise5])
				new_chunk.place_chunk(self)
				world[Vector3i(chunk_x, chunk_y, chunk_z)] = new_chunk

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

func save_chunk_to_file(filepath: String, chunk: Chunk):
	#check if the path exists
	if not FileAccess.file_exists(filepath):
		print("Error: No file at path")
		return
	#save the chunk in a specific structure with the position easy to reach
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	var json = {
		"pos": [chunk.cpos.x, chunk.cpos.y, chunk.cpos.z],
		"data": JSON.stringify(chunk)
	}
	#store the line and close the file, this only appends, which is why we need update_chunk_in_file()
	file.store_line(json)
	file.close()


func load_chunk_from_file(filepath: String, cpos: Vector3i):
	#check if the file exists
	if not FileAccess.file_exists(filepath):
		return {}
	#go through the lines, skipping empty ones
	var file = FileAccess.open(filepath, FileAccess.READ)
	while file.get_position() < file.get_length():
		var line: String = file.get_line()
		if line.is_empty():
			continue
		
		var parsed_line = JSON.parse_string(line)
		if parsed_line == null:
			continue
		var p = parsed_line.get("pos")
		if p and Vector3i(p[0], p[1], p[2]) == cpos:
			file.close()
			return parsed_line["data"]
	file.close()
	return {}

func update_chunk_in_file(filepath: String, chunk: Chunk):
	if not FileAccess.file_exists(filepath):
		return
	
	var file = FileAccess.open(filepath, FileAccess.READ)
	var stored_chunks: Array[String] = []
	var target_chunk_pos: Vector3i = chunk.cpos
	
	while file.get_position() < file.get_length():
		var line: String = file.get_line()
		if line.is_empty():
			continue
		
		var parsed_line = JSON.parse_string(line)
		if parsed_line:
			var p: Array[int] = parsed_line.get("pos")
			if p and Vector3i(p[0], p[1], p[2]) == target_chunk_pos:
				parsed_line["data"] = JSON.stringify(chunk)
				line = JSON.stringify(parsed_line)
		stored_chunks.append(line)
	file.close()
	
	var out = FileAccess.open(filepath, FileAccess.WRITE)
	for c in stored_chunks:
		out.store_line(c)
	out.close()


#end
