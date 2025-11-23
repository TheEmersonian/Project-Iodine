extends GridMap

@onready var block_overlay: GridMap = %BlockOverlay

@export var player_scene: PackedScene = preload("res://scenes/entities/player.tscn")


##DO NOT CHANGE THIS
const CHUNK_SIZE: int = 16
##Region size in chunks
const REGION_SIZE: Vector3i = Vector3(4, 16, 4)

@export var noise_parameters := {
	"seed": 1,
	"octaves": 5,
	"base_frequency": 0.01,
	"fractal_gain": 0.3,
	"amplitude": 3.4,
	"domain_warp_enabled": true,
	"domain_warp_amplitude": 15,
	"domain_warp_fractal_gain": 0.5,
	"domain_warp_fractal_lacunarity": 3.0,
	"domain_warp_fractal_octaves": 3,
	"domain_warp_fractal_type": FastNoiseLite.DOMAIN_WARP_FRACTAL_PROGRESSIVE,
	"domain_warp_frequency": 0.01,
	"domain_warp_type": FastNoiseLite.DOMAIN_WARP_SIMPLEX_REDUCED,
}

var generation_queue := {}

var world := {}

var player_ref: CharacterBody3D
var player_position: Vector3
var player_chunk: Vector3i
##Render Distance
const R_D: int = 3

class Region:
	var rpos: Vector3
	var chunks: Dictionary = {}
	
	func add_chunk(chunk: Chunk):
		var chunk_position_in_region: Vector3i = Vector3i(chunk.cpos.x % REGION_SIZE.x, chunk.cpos.y % REGION_SIZE.y, chunk.cpos.z % REGION_SIZE.z)
		chunks[chunk_position_in_region] = chunk

class Chunk:
	var cpos: Vector3i
	var blocks: PackedInt32Array
	var difficulty: float
	var base_difficulty: float
	var tempature: float
	var humidity: float
	var metadata := {}
	var tile_entities := {} 
	
	func _init(chunk_position: Vector3i, chunk_blocks: PackedInt32Array = []) -> void:
		cpos = chunk_position
		if chunk_blocks.is_empty():
			blocks.resize(CHUNK_SIZE*CHUNK_SIZE*CHUNK_SIZE)
		else:
			blocks = chunk_blocks
	
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
	
	func get_block(pos: Vector3i):
		return blocks[bpos_to_index(pos)]
	
	func create_tile_entity(pos: Vector3i, script: Script):
		var tile_entity = script.new(self, pos)
		tile_entities[pos] = tile_entity
	
	func generate_chunk(noise_parameters: Dictionary):
		var noise: FastNoiseLite = FastNoiseLite.new()
		noise.seed = noise_parameters.seed
		noise.fractal_octaves = noise_parameters.octaves
		noise.frequency = noise_parameters.base_frequency
		noise.fractal_gain = noise_parameters.fractal_gain
		noise.domain_warp_enabled = noise_parameters.domain_warp_enabled
		noise.domain_warp_amplitude = noise_parameters.domain_warp_amplitude
		noise.domain_warp_fractal_gain = noise_parameters.domain_warp_fractal_gain
		noise.domain_warp_fractal_lacunarity = noise_parameters.domain_warp_fractal_lacunarity
		noise.domain_warp_fractal_octaves = noise_parameters.domain_warp_fractal_octaves
		noise.domain_warp_fractal_type = noise_parameters.domain_warp_fractal_type
		noise.domain_warp_frequency = noise_parameters.domain_warp_frequency
		noise.domain_warp_type = noise_parameters.domain_warp_type
		var grass: int = ItemProcesser.item_to_id("dirt_with_grass")
		var dirt: int = ItemProcesser.item_to_id("dirt")
		var stone: int = ItemProcesser.item_to_id("stone")
		var deep_stone: int = ItemProcesser.item_to_id("deep_stone")
		var bedrock: int = ItemProcesser.item_to_id("bedrock")
		var chunk_offset: Vector3i = cpos_to_bpos(cpos)
		for x in range(CHUNK_SIZE):
			for z in range(CHUNK_SIZE):
				var noise_position: Vector3i = chunk_offset + Vector3i(x, 0, z)
				var noise_value: float = noise.get_noise_2d(noise_position.x, noise_position.z) * noise_parameters.amplitude
				var height: int = 5 + abs(round(noise_value*10.0))
				for y in range(CHUNK_SIZE):
					var in_chunk_position: Vector3i = Vector3i(x, y, z)
					var tpos: Vector3i = chunk_offset + in_chunk_position
					
					if tpos.y == height:
						set_block(in_chunk_position, grass)
					elif tpos.y < height:
						@warning_ignore("narrowing_conversion")
						var dirt_height: int = height-(height/10.0)
						if tpos.y > dirt_height:
							set_block(in_chunk_position, dirt)
						if cpos.y == 0:
							if tpos.y <= -30:
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
			#  For block orientation later
			#var blockinfo = BlockRegistry.get_block(block)
			#if blockinfo.generated_rotation != BlockRegistry.GeneratedRotationType.Fixed:
			#	match blockinfo.generated_rotation:
			#		BlockRegistry.GeneratedRotationType.Random: pass
						
			grid.set_cell_item(chunk_offset + pos, block-1)
	
	##Autimatically assumes it is exposed if it is at the edge of the chunk
	func is_exposed(pos: Vector3i):
		#if do_print:
		#	var worldpos: Vector3i = cpos_to_bpos(cpos)
		#	print("checking exposure of pos: " + str(pos) + " is within chunk: " + str(AABB(worldpos, Vector3i.ONE*CHUNK_SIZE).has_point(worldpos+pos)))
		#	return true
		
		if blocks[bpos_to_index(pos)] == -1:
			return true
		if pos.y != 15:
			var top_block: int = blocks[bpos_to_index(pos + Vector3i(0, 1, 0))]
			if top_block == -1:
				return true
		#if not on the bottom look for air on the bottom
		if pos.y != 0:
			var bottom_block: int = blocks[bpos_to_index(pos + Vector3i(0, -1, 0))]
			if bottom_block == -1:
				return true
		#if not on the side look for air on the side
		if pos.x != 15:
			var left_block: int = blocks[bpos_to_index(pos + Vector3i(1, 0, 0))]
			if left_block == -1:
				return true
		#if not on the other side look for air on the other side:
		if pos.x != 0:
			var right_block: int = blocks[bpos_to_index(pos + Vector3i(-1, 0, 0))]
			if right_block == -1:
				return true
		#same checks but for the z axis
		if pos.z != 15:
			var left_block: int = blocks[bpos_to_index(pos + Vector3i(0, 0, 1))]
			if left_block == -1:
				return true
		if pos.z != 0:
			var right_block: int = blocks[bpos_to_index(pos + Vector3i(0, 0, -1))]
			if right_block == -1:
				return true
		return false
	
	func place_chunk_fast(grid: GridMap):
		var chunk_offset: Vector3i = cpos_to_bpos(cpos)
		for i in blocks.size():
			if blocks[i] == -1:
				continue
			var pos: Vector3i = index_to_bpos(i)
			if is_exposed(pos):
				grid.set_cell_item(chunk_offset + pos, blocks[i]-1)
	
	func regenerate_chunk_visual(grid: GridMap, pos: Vector3i):
		if is_exposed(pos):
			grid.set_cell_item(pos + cpos_to_bpos(cpos), blocks[bpos_to_index(pos)]-1)



func _ready() -> void:
	load_new_chunks(calculate_loaded_chunks(Vector3i(0,0,0)))
	spawn_player()

func _physics_process(_delta: float) -> void:
	manage_block_overlay()
	if has_player_moved():
		player_position = player_ref.position
		player_chunk = floor(player_position/CHUNK_SIZE)
		var loaded_chunks_list: Array[Vector3i] = calculate_loaded_chunks(player_chunk)
		load_new_chunks(loaded_chunks_list)
		unload_old_chunks(loaded_chunks_list)

func _process(_delta: float) -> void:
	var start_time: float = Time.get_ticks_msec()
	for i in generation_queue.keys():
		var current_chunk: Chunk = generation_queue[i]
		current_chunk.generate_chunk(noise_parameters)
		world[i] = current_chunk
		current_chunk.place_chunk_fast(self)
		generation_queue.erase(i)
		if Time.get_ticks_msec() - start_time > 10:
			return

func manage_block_overlay():
	block_overlay.clear()
	var hpos: Vector3 = player_ref.selected_position
	if hpos != Vector3.ZERO:
		var bpos: Vector3i = block_overlay.local_to_map(hpos)
		block_overlay.set_cell_item(bpos, 0)

func has_player_moved() -> bool:
	if player_position == player_ref.position:
		return false
	return true

func load_new_chunks(loaded_chunks_list: Array[Vector3i]):
	for l in loaded_chunks_list:
		if world.has(l):
			continue
		elif generation_queue.has(l):
			continue
		else:
			var new_chunk: Chunk = Chunk.new(l)
			generation_queue[l] = new_chunk

func unload_old_chunks(loaded_chunks_list):
	for l in loaded_chunks_list:
		if !world.has(l):
			pass
	

##c = center
func calculate_loaded_chunks(c: Vector3i) -> Array[Vector3i]:
	var loaded_chunks: Array[Vector3i]
	for x in range(c.x-R_D, c.x+R_D):
		for y in range(c.y-R_D, c.y+R_D):
			for z in range(c.z-R_D, c.z+R_D):
				loaded_chunks.append(Vector3i(x, y, z))
	return loaded_chunks

func regenerate_rectangular_prism(pos: Vector3i, size: Vector3i):
	print("---Regenerating Rectangle at pos: " + str(pos) + " of size: " + str(size))
	for x in range(pos.x, pos.x+size.x):
		for y in range(pos.y, pos.y+size.y):
			for z in range(pos.z, pos.z+size.z):
				var block_pos: Vector3i = Vector3i(x, y, z)
				var chunk_pos: Vector3i = block_pos_to_chunk_pos(block_pos)
				var chunk: Chunk = world[chunk_pos]
				var in_chunk_pos = block_pos - (chunk_pos * CHUNK_SIZE)
				chunk.regenerate_chunk_visual(self, in_chunk_pos)
				#print("block_pos: " + str(block_pos) + " chunk pos: " + str(chunk_pos) + " local pos: " + str(in_chunk_pos))

func destroy_block(world_coordinate: Vector3, drop_block: bool = true):
	var block_coordinate: Vector3i = local_to_map(world_coordinate)
	var chunk_coordinate: Vector3i = block_pos_to_chunk_pos(block_coordinate)
	var cbpos: Vector3i = block_coordinate - chunk_pos_to_block_pos(chunk_coordinate)
	print("Destroying block in position: " + str(block_coordinate) + " at chunk: " + str(chunk_coordinate) + " local pos: " + str(cbpos))
	var chunk: Chunk = world[chunk_coordinate]
	chunk.set_block(cbpos, -1)
	
	regenerate_rectangular_prism(block_coordinate-Vector3i.ONE, Vector3i.ONE * 3)
	print("Current Block: " + str(chunk.get_block(cbpos)))
		
	#if drop_block:
		##var block_id: int = chunk.blocks[chunk.bpos_to_index(cbpos)]
		##var block_item: Item = Item.new(ItemProcesser.id_to_item(block_id), block_id, 1)
		##var dropped_item = DroppedItem.new(block_item)
		##add_child(dropped_item)
		##dropped_item.global_position = world_coordinate
		#dropped_item.give_random_jump()
	#set_cell_item(block_coordinate, -1)

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


func chunk_pos_to_block_pos(chunk_pos: Vector3i):
	return Vector3i(chunk_pos * CHUNK_SIZE)

func block_pos_to_chunk_pos(block_pos: Vector3i):
	var x: int = floori(block_pos.x / float(CHUNK_SIZE))
	var y: int = floori(block_pos.y / float(CHUNK_SIZE))
	var z: int = floori(block_pos.z / float(CHUNK_SIZE))
	return Vector3i(x, y, z)

func spawn_player():
	var player = player_scene.instantiate()
	add_child(player)
	player.position = Vector3(0, 30, 0)
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
