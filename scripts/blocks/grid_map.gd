extends GridMap

@onready var block_overlay: GridMap = %BlockOverlay

@export var player_scene: PackedScene = preload("res://scenes/entities/player.tscn")

#IMPORTANT: The gridmap's values are offset by 1 from the item ids.  Stone in the gridmap is 0, stone in item id's is 1


##DO NOT CHANGE THIS
const CHUNK_SIZE: int = 16
##Region size in chunks
const REGION_SIZE: Vector3i = Vector3(4, 16, 4)

const NUM_CHUNKS_IN_REGION: int = REGION_SIZE.x * REGION_SIZE.y * REGION_SIZE.z

var noise_parameters := {
	"seed": 1,
	"base_height": 128,
	"octaves": 13,
	"base_frequency": 0.01,
	"fractal_gain": 0.03,
	"amplitude": 24.6,
	"domain_warp_enabled": true,
	"domain_warp_amplitude": 15,
	"domain_warp_fractal_gain": 0.5,
	"domain_warp_fractal_lacunarity": 3.0,
	"domain_warp_fractal_octaves": 8,
	"domain_warp_fractal_type": FastNoiseLite.DOMAIN_WARP_FRACTAL_INDEPENDENT,
	"domain_warp_frequency": 0.01,
	"domain_warp_type": FastNoiseLite.DOMAIN_WARP_SIMPLEX_REDUCED,
	"continent_octaves": 3,
	"continent_frequency": 0.0005,
	"continent_fractal_gain": 0.0004,
	"continent_amplitude": 2.6,
}

#so many queues lmao
var generation_queue := {}
var placement_queue := []
var removal_queue := []

##Holds all active chunks, keyed by chunk positions
var world := {}
##Holds all regions with at least 1 active chunk, keyed by region positions
var loaded_regions := {}

var player_ref: CharacterBody3D
var player_position: Vector3            
var player_chunk: Vector3i

var spawn_position := Vector3i(32, 160, 32)

##Render Distance
const RENDER_DISTANCE: int = 3
##Distance at which chunks unload
const UNLOAD_DISTANCE: int = 4

class Region:
	var rpos: Vector3i
	var chunks: Array = []
	
	func _init(region_position: Vector3i) -> void:
		rpos = region_position
		chunks.resize(NUM_CHUNKS_IN_REGION)
	
	static func region_pos_to_file_name(region_pos: Vector3i):
		return "region_" + str(region_pos.x) + "." + str(region_pos.y) + "." + str(region_pos.z)
	
	static func local_chunk_pos_to_index(cpos: Vector3i):
		return cpos.x + cpos.y*REGION_SIZE.x + cpos.z*REGION_SIZE.x*REGION_SIZE.y
	
	static func index_to_local_chunk_pos(i: int) -> Vector3i:
		var x = i % REGION_SIZE.x
		i /= REGION_SIZE.x
		var y = i % REGION_SIZE.y
		i /= REGION_SIZE.y
		var z = i
		return Vector3i(x, y, z)
	
	
	func global_chunk_pos_to_local_chunk_pos(global_pos: Vector3i):
		return global_pos - (rpos * REGION_SIZE)
	
	func add_chunk(chunk: Chunk):
		var chunk_position_in_region: Vector3i = global_chunk_pos_to_local_chunk_pos(chunk.cpos)
		chunks[local_chunk_pos_to_index(chunk_position_in_region)] = chunk
	##THIS FUNCTION EXPECTS LOCAL CHUNK COORDINATES
	func get_chunk(local_chunk_pos: Vector3i):
		var index: int = local_chunk_pos_to_index(local_chunk_pos)
		return chunks[index]


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
	
	func serialize():
		return {
			"blocks": blocks,
			"cpos": [cpos.x, cpos.y, cpos.z],
		}
	
	func deserialize(data):
		blocks = data["blocks"]
	
	func global_block_pos_to_local_block_pos(global_pos: Vector3i):
		return global_pos - (cpos * CHUNK_SIZE)
	
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
	
	func get_block(local_pos: Vector3i) -> int:
		return blocks[bpos_to_index(local_pos)]
	
	func create_tile_entity(pos: Vector3i, script: Script):
		var tile_entity = script.new(self, pos)
		tile_entities[pos] = tile_entity
	
	func generate_chunk(noise_parameters: Dictionary):
		var local_noise: FastNoiseLite = FastNoiseLite.new()
		local_noise.seed = noise_parameters.seed
		local_noise.fractal_octaves = noise_parameters.octaves
		local_noise.frequency = noise_parameters.base_frequency
		local_noise.fractal_gain = noise_parameters.fractal_gain
		local_noise.domain_warp_enabled = noise_parameters.domain_warp_enabled
		local_noise.domain_warp_amplitude = noise_parameters.domain_warp_amplitude
		local_noise.domain_warp_fractal_gain = noise_parameters.domain_warp_fractal_gain
		local_noise.domain_warp_fractal_lacunarity = noise_parameters.domain_warp_fractal_lacunarity
		local_noise.domain_warp_fractal_octaves = noise_parameters.domain_warp_fractal_octaves
		local_noise.domain_warp_fractal_type = noise_parameters.domain_warp_fractal_type
		local_noise.domain_warp_frequency = noise_parameters.domain_warp_frequency
		local_noise.domain_warp_type = noise_parameters.domain_warp_type
		var continent_noise: FastNoiseLite = FastNoiseLite.new()
		continent_noise.seed = local_noise.seed + 1
		continent_noise.fractal_octaves = noise_parameters.continent_octaves
		continent_noise.fractal_gain = noise_parameters.continent_fractal_gain
		continent_noise.frequency = noise_parameters.continent_frequency
		var healthy_grass: int = 103
		var dirt: int = 102
		var soil: int = 101
		var granite: int = 1
		var chunk_offset: Vector3i = cpos_to_bpos(cpos)
		for x in range(CHUNK_SIZE):
			for z in range(CHUNK_SIZE):
				var noise_position: Vector3i = chunk_offset + Vector3i(x, 0, z)
				var continent_value: float = continent_noise.get_noise_2d(noise_position.x, noise_position.z)
				var noise_value: float = local_noise.get_noise_2d(noise_position.x, noise_position.z) * noise_parameters.amplitude
				var final_value: float = continent_value + (noise_value*continent_value)
				var height: int = noise_parameters.base_height + abs(round(final_value))
				@warning_ignore("narrowing_conversion")
				#above this dirt generates instead of stone
				var dirt_height: int = height - (height / 10.0)
				@warning_ignore("narrowing_conversion")
				#above this soil generates instead of dirt
				var soil_height: int = height - (1 + abs(local_noise.get_noise_3dv(noise_position + Vector3i(0, height, 0))))
				for y in range(CHUNK_SIZE):
					var in_chunk_position: Vector3i = Vector3i(x, y, z)
					var tpos: Vector3i = chunk_offset + in_chunk_position
					if tpos.y > height:
						set_block(in_chunk_position, -1)
					elif tpos.y == height:
						set_block(in_chunk_position, healthy_grass)
					elif tpos.y < height:
						if tpos.y > soil_height:
								set_block(in_chunk_position, soil)
						elif tpos.y > dirt_height:
							set_block(in_chunk_position, dirt)
						else:
							set_block(in_chunk_position, granite)

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
		
		if pos.x == 0 or pos.x == 15:
			return true
		if pos.y == 0 or pos.y == 15:
			return true
		if pos.z == 0 or pos.z == 15:
			return true
		
		
		if blocks[bpos_to_index(pos)] == -1:
			return true
		
		var top_block: int = blocks[bpos_to_index(pos + Vector3i(0, 1, 0))]
		if top_block == -1:
			return true
		#if not on the bottom look for air on the bottom
		
		var bottom_block: int = blocks[bpos_to_index(pos + Vector3i(0, -1, 0))]
		if bottom_block == -1:
			return true
		#if not on the side look for air on the side
		
		var left_block: int = blocks[bpos_to_index(pos + Vector3i(1, 0, 0))]
		if left_block == -1:
			return true
		#if not on the other side look for air on the other side:
		
		var right_block: int = blocks[bpos_to_index(pos + Vector3i(-1, 0, 0))]
		if right_block == -1:
			return true
		#same checks but for the z axis
		
		var left_block2: int = blocks[bpos_to_index(pos + Vector3i(0, 0, 1))]
		if left_block2 == -1:
			return true
		
		var right_block2: int = blocks[bpos_to_index(pos + Vector3i(0, 0, -1))]
		if right_block2 == -1:
			return true
		return false
	
	func place_chunk_fast(grid: GridMap):
		var chunk_offset: Vector3i = cpos_to_bpos(cpos)
		for i in blocks.size():
			if blocks[i] == -1:
				continue
			var pos: Vector3i = index_to_bpos(i)
			if is_exposed(pos):
				var blockdef = BlockRegistry.get_block_from_id(blocks[i])
				grid.set_cell_item(chunk_offset + pos, blockdef.meshlib_id)
	
	func regenerate_chunk_visual(grid: GridMap, pos: Vector3i):
		if is_exposed(pos):
			grid.set_cell_item(pos + cpos_to_bpos(cpos), blocks[bpos_to_index(pos)]-1)


func _ready() -> void:
	bake_navigation = false
	print(str(noise_parameters))
	print("Seed: " + str(noise_parameters.seed))
	spawn_player()
	load_new_chunks(calculate_loaded_chunks(block_pos_to_chunk_pos(spawn_position)))
	

func _physics_process(_delta: float) -> void:
	manage_block_overlay()
	if has_player_moved():
		player_position = player_ref.position
		player_chunk = floor(player_position/CHUNK_SIZE)
		var loaded_chunks_list: Array[Vector3i] = calculate_loaded_chunks(player_chunk)
		load_new_chunks(loaded_chunks_list)
		var keep_loaded_chunks_list: Array[Vector3i] = calculate_loaded_chunks(player_chunk, UNLOAD_DISTANCE)
		unload_old_chunks(keep_loaded_chunks_list)
		regenerate_rectangular_prism(Vector3i(player_position)-Vector3i.ONE, Vector3i.ONE*3)

func _process(_delta: float) -> void:
	generate_chunks_efficiently(10)
	place_chunks_efficiently(10)
	var regions_queued_for_unloading: Array[Vector3i] = regions_for_unloading()
	unload_regions_efficiently(10, regions_queued_for_unloading)
	remove_chunks_efficiently(10)
#save the region to the file
#		var filepath: String = GameManager.save_folder + Region.region_pos_to_file_name(rpos) + ".json"
#		save_region_to_file(filepath, region)

func generate_chunks_efficiently(msec_time: int):
	var start_time: float = Time.get_ticks_msec()
	for i in generation_queue.keys():
		var current_chunk: Chunk = generation_queue[i]
		current_chunk.generate_chunk(noise_parameters)
		world[i] = current_chunk
		generation_queue.erase(i)
		placement_queue.append(i)
		if Time.get_ticks_msec() - start_time > msec_time:
			return

func place_chunks_efficiently(msec_time: int):
	var start_time: float = Time.get_ticks_msec()
	for i in placement_queue:
		var current_chunk: Chunk = world[i]
		current_chunk.place_chunk_fast(self)
		placement_queue.erase(i)
		if Time.get_ticks_msec() - start_time > msec_time:
			return

func remove_chunks_efficiently(msec_time: int):
	var start_time: float = Time.get_ticks_msec()
	for cpos in removal_queue:
		unload_chunk_from_world(cpos)
		removal_queue.erase(cpos)
		if Time.get_ticks_msec() - start_time > msec_time:
			return


func regions_for_unloading() -> Array[Vector3i]:
	var regionkeys = loaded_regions.keys()
	var unloaded_regions: Array[Vector3i] = []
	for k in regionkeys:
		var region: Region = loaded_regions[k]
		for c in region.chunks:
			if world.has(c):
				continue
		unloaded_regions.append(k)
	#if unloaded_regions.size() > 0:
	#	print("Setting " + str(unloaded_regions.size()) + " Regions to be unloaded")
	return unloaded_regions

func unload_regions_efficiently(msec_time: int, region_positions: Array[Vector3i]):
	var start_time: float = Time.get_ticks_msec()
	for rpos in region_positions:
		var current_region: Region = loaded_regions[rpos]
		save_region_to_file(GameManager.save_folder + Region.region_pos_to_file_name(rpos) + ".json", current_region)
		loaded_regions.erase(rpos)
		if Time.get_ticks_msec() - start_time > msec_time:
			return

func unload_all_regions():
	for r in loaded_regions:
		save_region_to_file(GameManager.save_folder + Region.region_pos_to_file_name(r.rpos) + ".json", r)
	loaded_regions.clear()

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
	#iterate through all the loaded chunks, if they are in world ignore them, if they are in the queue, ignore them
	for cpos in loaded_chunks_list:
		if world.has(cpos):
			continue
		elif generation_queue.has(cpos):
			continue
		#compute the region
		var rpos: Vector3i = chunk_pos_to_region_pos(cpos)
		var region: Region = null
		#if the region is already loaded, get the rest of it's data, if it's not, get it from a file
		if loaded_regions.has(rpos):
			region = loaded_regions[rpos]
		else:
			var filepath: String = GameManager.save_folder + Region.region_pos_to_file_name(rpos) + ".json"
			region = load_region_from_file(filepath)
			print("Region from file is: " + str(region))
			#if its not in a file initialize it
			if region == null:
				print("Region null, making new region")
				region = Region.new(rpos)
			loaded_regions[rpos] = region
		
		#see if the chunk is already in the region
		var local_pos: Vector3i = region.global_chunk_pos_to_local_chunk_pos(cpos)
		var stored_chunk: Chunk = region.get_chunk(local_pos)
		
		if stored_chunk != null:
			world[cpos] = stored_chunk
			placement_queue.append(cpos)
		else:
			var new_chunk: Chunk = Chunk.new(cpos)
			generation_queue[cpos] = new_chunk
		

func unload_old_chunks(loaded_chunks_list):
	var start: float = Time.get_ticks_msec()
	var worldkeys: Array = world.keys()
	
	for cpos in worldkeys:
		#if the chunk should still be loaded then keep it
		if loaded_chunks_list.has(cpos):
			continue
		
		if removal_queue.has(cpos):
			continue
		
		#Save the chunk, the region pos, and prepare the region object
		var chunk: Chunk = world[cpos]
		var rpos: Vector3i = chunk_pos_to_region_pos(cpos)
		var region: Region
		
		#if the region is already in memory, 
		if loaded_regions.has(rpos):
			region = loaded_regions[rpos]
		else:
			region = Region.new(rpos)
			loaded_regions[rpos] = region
		
		#add the chunk
		region.add_chunk(chunk)
		
		#remove the chunk from the world
		removal_queue.append(cpos) 
	var time_taken: float = Time.get_ticks_msec() - start
	if time_taken > 2.0:
		print("unload_old_chunks took " + str(time_taken) + " milliseconds")
		#looks like this function isnt the optimization problem

func unload_chunk_from_world(cpos):
	var start: float = Time.get_ticks_msec()
	world.erase(cpos)
	var startpos: Vector3i = chunk_pos_to_block_pos(cpos)
	var cells: Array[Vector3i] = get_used_cells()
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			for z in range(CHUNK_SIZE):
				var pos: Vector3i = startpos + Vector3i(x, y, z)
				if cells.has(pos):
					set_cell_item(pos, -1)
	var timetaken: float = Time.get_ticks_msec() - start
	if timetaken > 2.0:
		print("unload_chunk_from_world took " + str(timetaken) + " milliseconds")


##c = center
func calculate_loaded_chunks(c: Vector3i, radius: int = RENDER_DISTANCE) -> Array[Vector3i]:
	var loaded_chunks: Array[Vector3i]
	for x in range(c.x-radius, c.x+radius):
		for y in range(c.y-radius, c.y+radius):
			for z in range(c.z-radius, c.z+radius):
				loaded_chunks.append(Vector3i(x, y, z))
	return loaded_chunks

func regenerate_rectangular_prism(pos: Vector3i, size: Vector3i):
	#print("---Regenerating Rectangle at pos: " + str(pos) + " of size: " + str(size))
	for x in range(pos.x, pos.x+size.x):
		for y in range(pos.y, pos.y+size.y):
			for z in range(pos.z, pos.z+size.z):
				var block_pos: Vector3i = Vector3i(x, y, z)
				var chunk_pos: Vector3i = block_pos_to_chunk_pos(block_pos)
				if !world.has(chunk_pos):
					continue
				var chunk: Chunk = world[chunk_pos]
				var in_chunk_pos: Vector3i = chunk.global_block_pos_to_local_block_pos(block_pos)
				var is_exposed: bool = false
				var i: int = 0 #looping through the directions
				while i <= 6:
					i += 1
					var checkpos: Vector3i = block_pos
					match i:
						1: checkpos += Vector3i.UP
						2: checkpos += Vector3i.DOWN
						3: checkpos += Vector3i.FORWARD
						4: checkpos += Vector3i.BACK
						5: checkpos += Vector3i.LEFT
						6: checkpos += Vector3i.RIGHT
					var check_chunk_pos: Vector3i = block_pos_to_chunk_pos(checkpos)
					if !world.has(check_chunk_pos):
						continue
					var check_chunk: Chunk = world[check_chunk_pos]
					var check_in_chunk_pos: Vector3i = check_chunk.global_block_pos_to_local_block_pos(checkpos)
					if check_chunk.get_block(check_in_chunk_pos) == -1:
						is_exposed = true
						break
				if is_exposed:
					var blockdef = BlockRegistry.get_block_from_id(chunk.get_block(in_chunk_pos))
					set_cell_item(block_pos, blockdef.meshlib_id)

func destroy_block(world_coordinate: Vector3, drop_block: bool = true):
	var block_coordinate: Vector3i = local_to_map(world_coordinate)
	var chunk_coordinate: Vector3i = block_pos_to_chunk_pos(block_coordinate)
	var cbpos: Vector3i = block_coordinate - chunk_pos_to_block_pos(chunk_coordinate)
	print("Destroying block in position: " + str(block_coordinate) + " at chunk: " + str(chunk_coordinate) + " local pos: " + str(cbpos))
	var chunk: Chunk = world[chunk_coordinate]
	print("Current Block: " + str(chunk.get_block(cbpos)))
	
	if drop_block:
		var block_id: int = chunk.get_block(cbpos)
		var block_def = BlockRegistry.get_block_from_id(block_id)
		var block_item: Item = Item.new(block_def.block_name, block_def.item_id, 1)
		var dropped_item = DroppedItem.new(block_item)
		add_child(dropped_item)
		dropped_item.global_position = world_coordinate
		dropped_item.give_random_jump()
	
	chunk.set_block(cbpos, -1)
	regenerate_rectangular_prism(block_coordinate-Vector3i.ONE, Vector3i.ONE * 3)
	set_cell_item(block_coordinate, -1)

func place_block(world_coordinate: Vector3, item_id: int):
	var map_coordinate: Vector3i = local_to_map(world_coordinate)
	var chunk_coordinate: Vector3i = block_pos_to_chunk_pos(map_coordinate)
	var cbpos: Vector3i = map_coordinate - chunk_pos_to_block_pos(chunk_coordinate)
	
	var chunk: Chunk = world[chunk_coordinate]
	chunk.set_block(cbpos, item_id)
	regenerate_rectangular_prism(map_coordinate-Vector3i.ONE, Vector3i.ONE * 3)
	
	var def = BlockRegistry.get_block_from_id(item_id)
	set_cell_item(map_coordinate, def.meshlib_id)
	if def.function:
		chunk.create_tile_entity(map_coordinate, def.function)


func generate_block(pos: Vector3i, index: int):
	set_cell_item(pos, index)

func chunk_pos_to_region_pos(chunk_pos: Vector3i):
	var x = floori(chunk_pos.x / float(REGION_SIZE.x))
	var y = floori(chunk_pos.y / float(REGION_SIZE.y))
	var z = floori(chunk_pos.z / float(REGION_SIZE.z))
	return Vector3i(x, y, z)

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
	player.position = spawn_position
	player_ref = player

func save_region_to_file(filepath: String, region: Region):
	var chunks_arr = []
	for chunk in region.chunks:
		if chunk == null:
			continue
		chunks_arr.append({
			"pos": [chunk.cpos.x, chunk.cpos.y, chunk.cpos.z],
		"data": chunk.serialize()        
		})
	var region_dict = {
		"rpos": [region.rpos.x, region.rpos.y, region.rpos.z],
		"chunks": chunks_arr
	}
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if file == null:
		print("Failed to open file, Error Code: " + str(FileAccess.get_open_error()))
		FileAccess.get_open_error()
		return
	file.store_string(JSON.stringify(region_dict))
	#print("Saved region: " + str(region.rpos) + " to file: " + filepath)
	file.close()


func load_region_from_file(filepath: String) -> Region:
	if not FileAccess.file_exists(filepath):
		return null

	var file = FileAccess.open(filepath, FileAccess.READ)
	var text = file.get_as_text()
	file.close()

	var obj = JSON.parse_string(text)
	if obj == null:
		return null

	var r = obj["rpos"]
	var region = Region.new(Vector3i(r[0], r[1], r[2]))
	
	for chunk_data in obj["chunks"]:
		var p = chunk_data["pos"]
		var d = chunk_data["data"]

		var chunk = Chunk.new(Vector3i(p[0], p[1], p[2]))
		chunk.deserialize(d)
		region.add_chunk(chunk)
	
	return region

func exit_game():
	print("Unloading regions")
	unload_all_regions()
	print("Exiting world...")
	##needs to be done this way instead of change to packed for some reason
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	

#end
