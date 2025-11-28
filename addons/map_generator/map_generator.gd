@tool
extends Node3D
class_name MapGenerator

## Advanced procedural world generator with sophisticated biome system

signal map_generated(world_name: String, seed_value: int)
signal map_loaded(world_name: String)
signal chunk_generation_started(chunk_pos: Vector3i)
signal chunk_generation_completed(chunk_pos: Vector3i, blocks_placed: int)
signal biome_added(biome: BiomeData)
signal biome_removed(index: int)
signal generation_progress(current: int, total: int)
signal world_saved(path: String)

# ========== WORLD SETTINGS ==========

@export_category("🌍 World Configuration")
@export_group("Seed & Identity")
@export var world_seed: int = 0:
	set(value):
		world_seed = value
		_setup_all_noise()
		notify_property_list_changed()

@export var world_name: String = "MyWorld":
	set(value):
		world_name = value
		notify_property_list_changed()

@export_multiline var world_description: String = "":
	set(value):
		world_description = value

@export_group("World Boundaries")
@export var min_world_x: float = -2048.0
@export var max_world_x: float = 2048.0
@export var min_world_z: float = -2048.0
@export var max_world_z: float = 2048.0
@export_range(0, 512, 1) var min_world_y: int = 0
@export_range(0, 512, 1) var max_world_y: int = 256

@export_group("Sea Level & Atmosphere")
@export_range(0, 256, 1) var sea_level: int = 64:
	set(value):
		sea_level = value
		notify_property_list_changed()

@export_range(1, 255, 1) var water_block_id: int = 9:
	set(value):
		water_block_id = value

@export var generate_water: bool = true

# ========== TERRAIN GENERATION ==========

@export_category("⛰️ Terrain Generation")
@export_group("Base Terrain")
@export_range(0.0, 100.0, 0.1) var base_terrain_amplitude: float = 32.0:
	set(value):
		base_terrain_amplitude = value

@export_range(0.0001, 0.05, 0.0001) var base_terrain_frequency: float = 0.003:
	set(value):
		base_terrain_frequency = value
		if _base_noise:
			_base_noise.frequency = value

@export_range(1, 8, 1) var terrain_octaves: int = 4:
	set(value):
		terrain_octaves = value
		if _base_noise:
			_base_noise.fractal_octaves = value

@export_enum("Perlin", "Simplex", "Cellular", "Value") var terrain_noise_type: int = 0:
	set(value):
		terrain_noise_type = value
		if _base_noise:
			_base_noise.noise_type = value

@export_group("Terrain Features")
@export var enable_continentalness: bool = true:
	set(value):
		enable_continentalness = value

@export_range(0.0001, 0.01, 0.0001) var continent_frequency: float = 0.0008:
	set(value):
		continent_frequency = value
		if _continent_noise:
			_continent_noise.frequency = value

@export_range(0.0, 100.0, 1.0) var continent_influence: float = 50.0:
	set(value):
		continent_influence = value

@export var enable_erosion: bool = true
@export_range(0.0, 1.0, 0.01) var erosion_strength: float = 0.3

# ========== BIOME SYSTEM ==========

@export_category("🌿 Biome System")
@export_group("Biome Management")
@export var biomes: Array[BiomeData] = []:
	set(value):
		biomes = value
		_update_biome_seeds()
		notify_property_list_changed()

@export_group("Biome Blending")
@export var enable_biome_blending: bool = true:
	set(value):
		enable_biome_blending = value

@export_range(0.0, 128.0, 1.0) var global_blend_radius: float = 32.0:
	set(value):
		global_blend_radius = value

@export_range(0.0, 1.0, 0.01) var blend_smoothness: float = 0.5:
	set(value):
		blend_smoothness = value

@export var use_blend_noise: bool = true:
	set(value):
		use_blend_noise = value

@export_range(0.0001, 0.1, 0.0001) var blend_noise_frequency: float = 0.02:
	set(value):
		blend_noise_frequency = value
		if _blend_noise:
			_blend_noise.frequency = value

@export_range(0.0, 1.0, 0.01) var blend_noise_strength: float = 0.3:
	set(value):
		blend_noise_strength = value

@export_group("Temperature & Humidity System")
@export var use_climate_system: bool = true
@export_range(0.0001, 0.01, 0.0001) var temperature_frequency: float = 0.002
@export_range(0.0001, 0.01, 0.0001) var humidity_frequency: float = 0.003

# ========== CAVE SYSTEM ==========

@export_category("🕳️ Cave System")
@export var cave_settings: CaveSettings = CaveSettings.new():
	set(value):
		cave_settings = value
		if cave_settings and world_seed > 0:
			cave_settings.setup(world_seed)

# ========== STRUCTURE GENERATION ==========

@export_category("🏗️ Structures & Features")
@export_group("Decoration Generation")
@export var enable_decorations: bool = true
@export_range(0, 100, 1) var decoration_attempts_per_column: int = 3

@export_group("Structure Spawning")
@export var enable_structures: bool = true
@export_range(0.0, 1.0, 0.001) var structure_spawn_chance: float = 0.001

# ========== PERSISTENCE ==========

@export_category("💾 Save & Load")
@export_dir var save_directory: String = "user://worlds"
@export var auto_save_interval: float = 300.0 # 5 minutes
@export var compress_save_data: bool = true

# ========== PERFORMANCE ==========

@export_category("⚡ Performance")
@export_range(1, 50, 1) var chunks_per_frame: int = 4
@export var use_multithreading: bool = true
@export_range(1, 8, 1) var worker_threads: int = 4
@export var cache_chunk_data: bool = true
@export_range(10, 1000, 10) var max_cache_size: int = 200

# ========== DEBUG ==========

@export_category("🐛 Debug")
@export var debug_mode: bool = false
@export var log_generation_stats: bool = false
@export var visualize_biomes: bool = false

# ========== INTERNAL VARIABLES ==========

var _voxel_world: Node = null
var _world_data: WorldSaveData = null

# Noise generators
var _base_noise: FastNoiseLite
var _continent_noise: FastNoiseLite
var _erosion_noise: FastNoiseLite
var _blend_noise: FastNoiseLite
var _temperature_noise: FastNoiseLite
var _humidity_noise: FastNoiseLite
var _ore_noise: FastNoiseLite
var _decoration_noise: FastNoiseLite

# Generation tracking
var _generated_chunks: Dictionary = {}
var _generation_queue: Array[Vector3i] = []
var _is_generating: bool = false
var _chunk_cache: Dictionary = {}
var _last_auto_save: float = 0.0

# Statistics
var _total_blocks_generated: int = 0
var _generation_start_time: int = 0

# ========== INITIALIZATION ==========

func _ready():
	if Engine.is_editor_hint():
		return
	
	_setup_all_noise()
	_find_voxel_world()
	
	if world_seed == 0:
		world_seed = randi()
	
	if _voxel_world and _voxel_world.has_signal("chunk_loaded"):
		_voxel_world.chunk_loaded.connect(_on_voxel_chunk_loaded)
	
	if debug_mode:
		print("MapGenerator initialized - Seed: %d, Biomes: %d" % [world_seed, biomes.size()])

func _process(delta):
	if Engine.is_editor_hint():
		return
	
	if auto_save_interval > 0:
		_last_auto_save += delta
		if _last_auto_save >= auto_save_interval:
			_last_auto_save = 0.0
			if _world_data:
				save_world()

func _setup_all_noise():
	# Base terrain noise
	_base_noise = FastNoiseLite.new()
	_base_noise.seed = world_seed
	_base_noise.noise_type = terrain_noise_type
	_base_noise.frequency = base_terrain_frequency
	_base_noise.fractal_octaves = terrain_octaves
	_base_noise.fractal_lacunarity = 2.0
	_base_noise.fractal_gain = 0.5
	
	# Continental features
	_continent_noise = FastNoiseLite.new()
	_continent_noise.seed = world_seed + 1000
	_continent_noise.frequency = continent_frequency
	_continent_noise.fractal_octaves = 3
	
	# Erosion
	_erosion_noise = FastNoiseLite.new()
	_erosion_noise.seed = world_seed + 2000
	_erosion_noise.frequency = 0.01
	
	# Biome blending
	_blend_noise = FastNoiseLite.new()
	_blend_noise.seed = world_seed + 3000
	_blend_noise.frequency = blend_noise_frequency
	
	# Climate
	_temperature_noise = FastNoiseLite.new()
	_temperature_noise.seed = world_seed + 4000
	_temperature_noise.frequency = temperature_frequency
	
	_humidity_noise = FastNoiseLite.new()
	_humidity_noise.seed = world_seed + 5000
	_humidity_noise.frequency = humidity_frequency
	
	# Ore distribution
	_ore_noise = FastNoiseLite.new()
	_ore_noise.seed = world_seed + 6000
	_ore_noise.frequency = 0.05
	_ore_noise.fractal_octaves = 2
	
	# Decoration placement
	_decoration_noise = FastNoiseLite.new()
	_decoration_noise.seed = world_seed + 7000
	_decoration_noise.frequency = 0.1
	
	# Setup cave noise
	if cave_settings:
		cave_settings.setup(world_seed)
	
	# Setup biome noise
	_update_biome_seeds()

func _update_biome_seeds():
	for i in range(biomes.size()):
		if biomes[i]:
			biomes[i].setup_with_seed(world_seed + i * 10000)

func _find_voxel_world():
	if _voxel_world:
		return
	
	_voxel_world = get_node_or_null("../VoxelWorld")
	if not _voxel_world:
		_voxel_world = get_node_or_null("VoxelWorld")
	if not _voxel_world:
		for child in get_parent().get_children():
			if child.has_method("set_block"):
				_voxel_world = child
				break
	
	if not _voxel_world:
		push_warning("MapGenerator: VoxelWorld node not found!")

# ========== PUBLIC API - WORLD MANAGEMENT ==========

## Create a new world with current settings
func create_new_world(p_name: String = "", p_seed: int = -1) -> bool:
	if p_name != "":
		world_name = p_name
	
	if p_seed >= 0:
		world_seed = p_seed
	else:
		world_seed = randi()
	
	_setup_all_noise()
	
	_world_data = WorldSaveData.new()
	_world_data.world_name = world_name
	_world_data.seed_value = world_seed
	_world_data.world_limits_xz = Vector2i(int(min_world_x), int(max_world_x))
	_world_data.world_limits_y = Vector2i(min_world_y, max_world_y)
	_world_data.noise_amplitude = base_terrain_amplitude
	_world_data.noise_frequency = base_terrain_frequency
	_world_data.biome_blend_enabled = enable_biome_blending
	_world_data.blend_transition_radius = global_blend_radius
	_world_data.blend_noise_intensity = blend_noise_strength
	_world_data.blend_noise_frequency = blend_noise_frequency
	
	_save_biomes_to_world_data()
	_save_cave_settings_to_world_data()
	
	_generated_chunks.clear()
	_chunk_cache.clear()
	_total_blocks_generated = 0
	
	save_world()
	
	map_generated.emit(world_name, world_seed)
	
	if debug_mode:
		print("New world '%s' created with seed %d" % [world_name, world_seed])
	
	return true

## Load an existing world
func load_world(world_path: String = "") -> bool:
	var load_path = world_path if world_path != "" else save_directory.path_join(world_name)
	var world_file = load_path.path_join("world_data.json")
	
	if not FileAccess.file_exists(world_file):
		push_error("World file not found: %s" % world_file)
		return false
	
	var file = FileAccess.open(world_file, FileAccess.READ)
	if not file:
		push_error("Failed to open world file")
		return false
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_text) != OK:
		push_error("Failed to parse world JSON")
		return false
	
	_world_data = WorldSaveData.from_dict(json.data)
	
	# Apply loaded settings
	world_seed = _world_data.seed_value
	world_name = _world_data.world_name
	min_world_x = _world_data.world_limits_xz.x
	max_world_x = _world_data.world_limits_xz.y
	min_world_y = _world_data.world_limits_y.x
	max_world_y = _world_data.world_limits_y.y
	base_terrain_amplitude = _world_data.noise_amplitude
	base_terrain_frequency = _world_data.noise_frequency
	enable_biome_blending = _world_data.biome_blend_enabled
	global_blend_radius = _world_data.blend_transition_radius
	blend_noise_strength = _world_data.blend_noise_intensity
	blend_noise_frequency = _world_data.blend_noise_frequency
	_generated_chunks = _world_data.generated_chunks
	
	_load_biomes_from_world_data()
	_load_cave_settings_from_world_data()
	
	_setup_all_noise()
	
	map_loaded.emit(world_name)
	
	if debug_mode:
		print("World '%s' loaded - %d chunks generated" % [world_name, _generated_chunks.size()])
	
	return true

## Save current world state
func save_world() -> bool:
	if not _world_data:
		push_warning("No world data to save")
		return false
	
	_world_data.update_timestamp()
	_world_data.generated_chunks = _generated_chunks
	_save_biomes_to_world_data()
	_save_cave_settings_to_world_data()
	
	var world_dir = save_directory.path_join(world_name)
	if not DirAccess.dir_exists_absolute(world_dir):
		DirAccess.make_dir_recursive_absolute(world_dir)
	
	var world_file = world_dir.path_join("world_data.json")
	var file = FileAccess.open(world_file, FileAccess.WRITE)
	if not file:
		push_error("Failed to save world to: %s" % world_file)
		return false
	
	var json_string = JSON.stringify(_world_data.to_dict(), "\t")
	file.store_string(json_string)
	file.close()
	
	world_saved.emit(world_file)
	
	if debug_mode:
		print("World saved: %s" % world_file)
	
	return true

## Delete world from disk
func delete_world(world_to_delete: String = "") -> bool:
	var delete_name = world_to_delete if world_to_delete != "" else world_name
	var world_dir = save_directory.path_join(delete_name)
	
	if not DirAccess.dir_exists_absolute(world_dir):
		return false
	
	var dir = DirAccess.open(world_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		DirAccess.remove_absolute(world_dir)
		return true
	
	return false

# ========== PUBLIC API - CHUNK GENERATION ==========

## Generate a specific chunk
func generate_chunk(chunk_pos: Vector3i, force_regenerate: bool = false) -> bool:
	if not _voxel_world:
		_find_voxel_world()
		if not _voxel_world:
			return false
	
	var chunk_key = _chunk_key(chunk_pos)
	
	if not force_regenerate and _generated_chunks.has(chunk_key):
		return false
	
	chunk_generation_started.emit(chunk_pos)
	
	if log_generation_stats:
		_generation_start_time = Time.get_ticks_msec()
	
	var blocks = _generate_chunk_blocks(chunk_pos)
	var blocks_placed = blocks.size()
	
	if blocks_placed > 0:
		_voxel_world.set_blocks_bulk(blocks)
		_total_blocks_generated += blocks_placed
	
	_generated_chunks[chunk_key] = true
	if _world_data:
		_world_data.mark_chunk_generated(chunk_pos)
	
	if cache_chunk_data and _chunk_cache.size() < max_cache_size:
		_chunk_cache[chunk_key] = blocks
	
	chunk_generation_completed.emit(chunk_pos, blocks_placed)
	
	if log_generation_stats:
		var time_taken = Time.get_ticks_msec() - _generation_start_time
		print("Chunk %v generated: %d blocks in %dms" % [chunk_pos, blocks_placed, time_taken])
	
	return true

## Generate multiple chunks (queued)
func generate_chunks(chunk_positions: Array[Vector3i]):
	for chunk_pos in chunk_positions:
		if not _generated_chunks.has(_chunk_key(chunk_pos)):
			_generation_queue.append(chunk_pos)
	
	if not _is_generating:
		_process_generation_queue()

## Generate all missing chunks in a region
func generate_region(min_chunk: Vector3i, max_chunk: Vector3i):
	var chunks: Array[Vector3i] = []
	
	for x in range(min_chunk.x, max_chunk.x + 1):
		for y in range(min_chunk.y, max_chunk.y + 1):
			for z in range(min_chunk.z, max_chunk.z + 1):
				var chunk_pos = Vector3i(x, y, z)
				if not is_chunk_generated(chunk_pos):
					chunks.append(chunk_pos)
	
	if chunks.size() > 0:
		if debug_mode:
			print("Generating %d chunks in region" % chunks.size())
		generate_chunks(chunks)

## Check if chunk is generated
func is_chunk_generated(chunk_pos: Vector3i) -> bool:
	return _generated_chunks.has(_chunk_key(chunk_pos))

## Get all generated chunk positions
func get_generated_chunks() -> Array[Vector3i]:
	var chunks: Array[Vector3i] = []
	for key in _generated_chunks.keys():
		var parts = key.split("_")
		if parts.size() == 3:
			chunks.append(Vector3i(int(parts[0]), int(parts[1]), int(parts[2])))
	return chunks

## Clear all generation data
func clear_generation_data():
	_generated_chunks.clear()
	_chunk_cache.clear()
	_generation_queue.clear()
	_total_blocks_generated = 0
	if _world_data:
		_world_data.generated_chunks.clear()

# ========== PUBLIC API - BIOME MANAGEMENT ==========

## Add a new biome
func add_biome(biome_name_str: String = "") -> BiomeData:
	var biome = BiomeData.new()
	biome.biome_name = biome_name_str if biome_name_str != "" else "Biome_%d" % biomes.size()
	biome.biome_id = biomes.size()
	biome.setup_with_seed(world_seed + biomes.size() * 10000)
	biomes.append(biome)
	biome_added.emit(biome)
	notify_property_list_changed()
	return biome

## Remove a biome
func remove_biome(index: int) -> bool:
	if index < 0 or index >= biomes.size():
		return false
	biomes.remove_at(index)
	biome_removed.emit(index)
	notify_property_list_changed()
	return true

## Get biome at world position
func get_biome_at(world_pos: Vector3) -> BiomeData:
	var influences = _calculate_biome_influences(world_pos)
	if influences.size() > 0:
		return influences[0].biome
	return null

## Get all biomes influencing a position
func get_biome_influences(world_pos: Vector3) -> Array:
	return _calculate_biome_influences(world_pos)

# ========== PUBLIC API - TERRAIN QUERIES ==========

## Get terrain height at XZ position
func get_height_at(world_x: float, world_z: float) -> float:
	return _calculate_terrain_height(world_x, world_z)

## Get temperature at position
func get_temperature_at(world_pos: Vector3) -> float:
	if not use_climate_system:
		return 20.0
	var temp_noise = _temperature_noise.get_noise_2d(world_pos.x, world_pos.z)
	return temp_noise * 50.0

## Get humidity at position
func get_humidity_at(world_pos: Vector3) -> float:
	if not use_climate_system:
		return 50.0
	var hum_noise = _humidity_noise.get_noise_2d(world_pos.x, world_pos.z)
	return (hum_noise + 1.0) * 50.0

# ========== INTERNAL - CHUNK GENERATION ==========

func _process_generation_queue():
	if _generation_queue.is_empty():
		_is_generating = false
		return
	
	_is_generating = true
	var chunks_this_frame = mini(chunks_per_frame, _generation_queue.size())
	var total = _generation_queue.size()
	
	for i in range(chunks_this_frame):
		if _generation_queue.is_empty():
			break
		
		var chunk_pos = _generation_queue.pop_front()
		generate_chunk(chunk_pos)
		generation_progress.emit(total - _generation_queue.size(), total)
	
	if not _generation_queue.is_empty():
		call_deferred("_process_generation_queue")
	else:
		_is_generating = false

func _generate_chunk_blocks(chunk_pos: Vector3i) -> Array:
	var blocks = []
	var chunk_size = _get_chunk_size()
	var world_offset = chunk_pos * chunk_size
	
	# Track surface blocks for decorations
	var surface_positions: Dictionary = {}
	
	for x in range(chunk_size.x):
		for z in range(chunk_size.z):
			var world_x = world_offset.x + x
			var world_z = world_offset.z + z
			
			var terrain_height = _calculate_terrain_height(float(world_x), float(world_z))
			var height_int = int(terrain_height)
			
			for y in range(chunk_size.y):
				var world_y = world_offset.y + y
				var world_pos = Vector3i(world_x, world_y, world_z)
				
				# Skip if above terrain
				if world_y > height_int:
					# Water generation
					if generate_water and world_y <= sea_level:
						blocks.append({"position": world_pos, "block_id": water_block_id})
					continue
				
				# Cave check
				if cave_settings and cave_settings.enabled and cave_settings.is_cave(world_pos):
					continue
				
				# Get block from biome system
				var block_id = _get_block_at_position(world_pos, height_int)
				
				if block_id > 0:
					blocks.append({"position": world_pos, "block_id": block_id})
				
				# Track surface
				if world_y == height_int:
					surface_positions[Vector2i(x, z)] = {"pos": world_pos, "block_id": block_id}
	
	# Generate decorations
	if enable_decorations:
		blocks.append_array(_generate_decorations(chunk_pos, surface_positions))
	
	return blocks

func _calculate_terrain_height(world_x: float, world_z: float) -> float:
	var base_height = _base_noise.get_noise_2d(world_x, world_z) * base_terrain_amplitude
	
	# Continental influence
	if enable_continentalness:
		var continent_val = _continent_noise.get_noise_2d(world_x, world_z)
		base_height += continent_val * continent_influence
	
	# Erosion
	if enable_erosion:
		var erosion_val = _erosion_noise.get_noise_2d(world_x, world_z)
		erosion_val = (erosion_val + 1.0) * 0.5
		base_height *= (1.0 - erosion_val * erosion_strength)
	
	# Biome height modifications
	if biomes.size() > 0:
		var biome_influences = _calculate_biome_influences(Vector3(world_x, 0, world_z))
		var biome_height_mod = 0.0
		
		for influence in biome_influences:
			var biome: BiomeData = influence.biome
			var weight: float = influence.weight
			var biome_height = biome.get_height_at_position(world_x, world_z)
			biome_height_mod += biome_height * weight
		
		base_height += biome_height_mod
	
	return base_height + float(sea_level)

func _get_block_at_position(world_pos: Vector3i, surface_height: int) -> int:
	var biome_influences = _calculate_biome_influences(Vector3(world_pos))
	
	if biome_influences.is_empty():
		return 1 # Default stone
	
	# Check each biome's blocks
	for influence in biome_influences:
		var biome: BiomeData = influence.biome
		var weight: float = influence.weight
		
		if randf() > weight:
			continue
		
		# Check surface blocks
		for layer in biome.surface_blocks:
			if layer.should_place_at(world_pos, surface_height, _base_noise):
				return layer.block_id
		
		# Check subsurface
		for layer in biome.subsurface_blocks:
			if layer.should_place_at(world_pos, surface_height, _base_noise):
				return layer.block_id
		
		# Check underground
		for layer in biome.underground_blocks:
			if layer.should_place_at(world_pos, surface_height, _base_noise):
				return layer.block_id
		
		# Check ores
		for ore in biome.ore_deposits:
			if ore.should_spawn_vein(world_pos, _ore_noise, biome.biome_name):
				if randf() < (1.0 / float(ore.veins_per_chunk)):
					return ore.block_id
	
	return 1

func _generate_decorations(chunk_pos: Vector3i, surface_data: Dictionary) -> Array:
	var decoration_blocks = []
	
	for coord in surface_data.keys():
		var data = surface_data[coord]
		var world_pos: Vector3i = data.pos
		var surface_block: int = data.block_id
		
		var biome_influences = _calculate_biome_influences(Vector3(world_pos))
		if biome_influences.is_empty():
			continue
		
		for influence in biome_influences:
			var biome: BiomeData = influence.biome
			
			for decoration in biome.decorations:
				if decoration.should_spawn_at(world_pos, surface_block, _decoration_noise):
					var deco_blocks = decoration.generate_blocks(world_pos + Vector3i(0, 1, 0))
					decoration_blocks.append_array(deco_blocks)
					break
	
	return decoration_blocks

func _calculate_biome_influences(world_pos: Vector3) -> Array:
	if biomes.is_empty():
		return []
	
	var influences = []
	var total_weight = 0.0
	
	for biome in biomes:
		if not biome.is_position_in_bounds(world_pos):
			continue
		
		var distance = biome.get_distance_from_bounds(world_pos)
		var weight = 0.0
		
		# Calculate blend weight
		var blend_radius = global_blend_radius if enable_biome_blending else biome.blend_radius
		
		if distance < blend_radius:
			var t = distance / blend_radius
			weight = 1.0 - smoothstep(0.0, 1.0, pow(t, blend_smoothness))
			
			# Add noise variation
			if use_blend_noise:
				var noise_val = _blend_noise.get_noise_2d(world_pos.x, world_pos.z)
				noise_val = (noise_val + 1.0) * 0.5
				weight += (noise_val - 0.5) * blend_noise_strength
				weight = clampf(weight, 0.0, 1.0)
			
			weight *= biome.priority_factor
			weight *= biome.get_noise_mask_value(world_pos)
		elif distance == 0.0:
			weight = biome.priority_factor
		
		if weight > 0.0:
			influences.append({"biome": biome, "weight": weight})
			total_weight += weight
	
	# Normalize weights
	if total_weight > 0.0:
		for influence in influences:
			influence.weight /= total_weight
	
	# Sort by weight
	influences.sort_custom(func(a, b): return a.weight > b.weight)
	
	return influences

# ========== INTERNAL - HELPERS ==========

func _get_chunk_size() -> Vector3i:
	if _voxel_world and _voxel_world.has_method("get_chunk_size"):
		return Vector3i(
			_voxel_world.chunk_size_xz,
			_voxel_world.chunk_size_y,
			_voxel_world.chunk_size_xz
		)
	return Vector3i(16, 16, 16)

func _chunk_key(chunk_pos: Vector3i) -> String:
	return "%d_%d_%d" % [chunk_pos.x, chunk_pos.y, chunk_pos.z]

func _on_voxel_chunk_loaded(chunk_pos: Vector3i):
	if not is_chunk_generated(chunk_pos):
		generate_chunk(chunk_pos)

# ========== SERIALIZATION ==========

func _save_biomes_to_world_data():
	if not _world_data:
		return
	
	_world_data.biomes_data.clear()
	
	for biome in biomes:
		var biome_dict = {
			"biome_name": biome.biome_name,
			"biome_id": biome.biome_id,
			"description": biome.description,
			"min_x": biome.min_x,
			"max_x": biome.max_x,
			"min_z": biome.min_z,
			"max_z": biome.max_z,
			"min_y": biome.min_y,
			"max_y": biome.max_y,
			"base_height_offset": biome.base_height_offset,
			"height_amplitude": biome.height_amplitude,
			"height_frequency": biome.height_frequency,
			"height_octaves": biome.height_octaves,
			"noise_type": biome.noise_type,
			"terrain_roughness": biome.terrain_roughness,
			"terrain_persistence": biome.terrain_persistence,
			"blend_color": biome.blend_color.to_html(),
			"priority_factor": biome.priority_factor,
			"blend_radius": biome.blend_radius,
			"use_noise_mask": biome.use_noise_mask,
			"mask_frequency": biome.mask_frequency,
			"mask_amplitude": biome.mask_amplitude,
			"mask_threshold": biome.mask_threshold,
			"temperature": biome.temperature,
			"humidity": biome.humidity,
			"surface_blocks": _serialize_block_layers(biome.surface_blocks),
			"subsurface_blocks": _serialize_block_layers(biome.subsurface_blocks),
			"underground_blocks": _serialize_block_layers(biome.underground_blocks),
			"ore_deposits": _serialize_ore_deposits(biome.ore_deposits),
			"decorations": _serialize_decorations(biome.decorations)
		}
		
		_world_data.biomes_data.append(biome_dict)

func _serialize_block_layers(layers: Array[BlockLayerData]) -> Array:
	var result = []
	for layer in layers:
		result.append({
			"layer_name": layer.layer_name,
			"enabled": layer.enabled,
			"block_id": layer.block_id,
			"block_name": layer.block_name,
			"placement_mode": layer.placement_mode,
			"depth_from_surface": layer.depth_from_surface,
			"thickness": layer.thickness,
			"min_height": layer.min_height,
			"max_height": layer.max_height,
			"coverage": layer.coverage,
			"use_noise_distribution": layer.use_noise_distribution,
			"noise_frequency": layer.noise_frequency,
			"noise_threshold": layer.noise_threshold,
			"requires_solid_below": layer.requires_solid_below,
			"requires_air_above": layer.requires_air_above,
			"max_slope": layer.max_slope
		})
	return result

func _serialize_ore_deposits(ores: Array[OreDepositData]) -> Array:
	var result = []
	for ore in ores:
		result.append({
			"ore_name": ore.ore_name,
			"enabled": ore.enabled,
			"block_id": ore.block_id,
			"min_spawn_height": ore.min_spawn_height,
			"max_spawn_height": ore.max_spawn_height,
			"spawn_chance": ore.spawn_chance,
			"veins_per_chunk": ore.veins_per_chunk,
			"vein_shape": ore.vein_shape,
			"min_vein_size": ore.min_vein_size,
			"max_vein_size": ore.max_vein_size,
			"vein_elongation": ore.vein_elongation,
			"distribution_type": ore.distribution_type,
			"noise_frequency": ore.noise_frequency,
			"noise_threshold": ore.noise_threshold,
			"noise_octaves": ore.noise_octaves,
			"peak_probability_height": ore.peak_probability_height,
			"gradient_falloff": ore.gradient_falloff,
			"replace_blocks": ore.replace_blocks,
			"avoid_air": ore.avoid_air,
			"only_in_biomes": ore.only_in_biomes,
			"clustering": ore.clustering
		})
	return result

func _serialize_decorations(decorations: Array[DecorationData]) -> Array:
	var result = []
	for deco in decorations:
		result.append({
			"decoration_name": deco.decoration_name,
			"enabled": deco.enabled,
			"decoration_type": deco.decoration_type,
			"primary_block_id": deco.primary_block_id,
			"secondary_block_id": deco.secondary_block_id,
			"min_height": deco.min_height,
			"max_height": deco.max_height,
			"width": deco.width,
			"spawn_chance": deco.spawn_chance,
			"min_spacing": deco.min_spacing,
			"require_grass_below": deco.require_grass_below,
			"required_surface_blocks": deco.required_surface_blocks,
			"max_slope": deco.max_slope,
			"min_spawn_y": deco.min_spawn_y,
			"max_spawn_y": deco.max_spawn_y,
			"use_noise_distribution": deco.use_noise_distribution,
			"noise_frequency": deco.noise_frequency,
			"noise_threshold": deco.noise_threshold
		})
	return result

func _load_biomes_from_world_data():
	if not _world_data:
		return
	
	biomes.clear()
	
	for biome_dict in _world_data.biomes_data:
		var biome = BiomeData.new()
		biome.biome_name = biome_dict.get("biome_name", "Unknown")
		biome.biome_id = biome_dict.get("biome_id", 0)
		biome.description = biome_dict.get("description", "")
		biome.min_x = biome_dict.get("min_x", -1000.0)
		biome.max_x = biome_dict.get("max_x", 1000.0)
		biome.min_z = biome_dict.get("min_z", -1000.0)
		biome.max_z = biome_dict.get("max_z", 1000.0)
		biome.min_y = biome_dict.get("min_y", 0)
		biome.max_y = biome_dict.get("max_y", 128)
		biome.base_height_offset = biome_dict.get("base_height_offset", 0.0)
		biome.height_amplitude = biome_dict.get("height_amplitude", 10.0)
		biome.height_frequency = biome_dict.get("height_frequency", 0.01)
		biome.height_octaves = biome_dict.get("height_octaves", 3)
		biome.noise_type = biome_dict.get("noise_type", 0)
		biome.terrain_roughness = biome_dict.get("terrain_roughness", 2.0)
		biome.terrain_persistence = biome_dict.get("terrain_persistence", 0.5)
		biome.blend_color = Color.html(biome_dict.get("blend_color", "#ffffff"))
		biome.priority_factor = biome_dict.get("priority_factor", 1.0)
		biome.blend_radius = biome_dict.get("blend_radius", 32.0)
		biome.use_noise_mask = biome_dict.get("use_noise_mask", false)
		biome.mask_frequency = biome_dict.get("mask_frequency", 0.01)
		biome.mask_amplitude = biome_dict.get("mask_amplitude", 1.0)
		biome.mask_threshold = biome_dict.get("mask_threshold", 0.0)
		biome.temperature = biome_dict.get("temperature", 20.0)
		biome.humidity = biome_dict.get("humidity", 50.0)
		
		biome.surface_blocks = _deserialize_block_layers(biome_dict.get("surface_blocks", []))
		biome.subsurface_blocks = _deserialize_block_layers(biome_dict.get("subsurface_blocks", []))
		biome.underground_blocks = _deserialize_block_layers(biome_dict.get("underground_blocks", []))
		biome.ore_deposits = _deserialize_ore_deposits(biome_dict.get("ore_deposits", []))
		biome.decorations = _deserialize_decorations(biome_dict.get("decorations", []))
		
		biome.setup_with_seed(world_seed + biome.biome_id * 10000)
		biomes.append(biome)

func _deserialize_block_layers(data: Array) -> Array[BlockLayerData]:
	var layers: Array[BlockLayerData] = []
	for layer_dict in data:
		var layer = BlockLayerData.new()
		layer.layer_name = layer_dict.get("layer_name", "Layer")
		layer.enabled = layer_dict.get("enabled", true)
		layer.block_id = layer_dict.get("block_id", 1)
		layer.block_name = layer_dict.get("block_name", "Stone")
		layer.placement_mode = layer_dict.get("placement_mode", 0)
		layer.depth_from_surface = layer_dict.get("depth_from_surface", 0)
		layer.thickness = layer_dict.get("thickness", 1)
		layer.min_height = layer_dict.get("min_height", 0)
		layer.max_height = layer_dict.get("max_height", 64)
		layer.coverage = layer_dict.get("coverage", 1.0)
		layer.use_noise_distribution = layer_dict.get("use_noise_distribution", false)
		layer.noise_frequency = layer_dict.get("noise_frequency", 0.01)
		layer.noise_threshold = layer_dict.get("noise_threshold", 0.0)
		layer.requires_solid_below = layer_dict.get("requires_solid_below", false)
		layer.requires_air_above = layer_dict.get("requires_air_above", false)
		layer.max_slope = layer_dict.get("max_slope", 90.0)
		layers.append(layer)
	return layers

func _deserialize_ore_deposits(data: Array) -> Array[OreDepositData]:
	var ores: Array[OreDepositData] = []
	for ore_dict in data:
		var ore = OreDepositData.new()
		ore.ore_name = ore_dict.get("ore_name", "Ore")
		ore.enabled = ore_dict.get("enabled", true)
		ore.block_id = ore_dict.get("block_id", 4)
		ore.min_spawn_height = ore_dict.get("min_spawn_height", 0)
		ore.max_spawn_height = ore_dict.get("max_spawn_height", 64)
		ore.spawn_chance = ore_dict.get("spawn_chance", 0.01)
		ore.veins_per_chunk = ore_dict.get("veins_per_chunk", 3)
		ore.vein_shape = ore_dict.get("vein_shape", 0)
		ore.min_vein_size = ore_dict.get("min_vein_size", 3)
		ore.max_vein_size = ore_dict.get("max_vein_size", 8)
		ore.vein_elongation = ore_dict.get("vein_elongation", 1.0)
		ore.distribution_type = ore_dict.get("distribution_type", 1)
		ore.noise_frequency = ore_dict.get("noise_frequency", 0.05)
		ore.noise_threshold = ore_dict.get("noise_threshold", 0.5)
		ore.noise_octaves = ore_dict.get("noise_octaves", 2)
		ore.peak_probability_height = ore_dict.get("peak_probability_height", 0.5)
		ore.gradient_falloff = ore_dict.get("gradient_falloff", 0.3)
		ore.replace_blocks = ore_dict.get("replace_blocks", [1])
		ore.avoid_air = ore_dict.get("avoid_air", true)
		ore.only_in_biomes = ore_dict.get("only_in_biomes", [])
		ore.clustering = ore_dict.get("clustering", 0.5)
		ores.append(ore)
	return ores

func _deserialize_decorations(data: Array) -> Array[DecorationData]:
	var decorations: Array[DecorationData] = []
	for deco_dict in data:
		var deco = DecorationData.new()
		deco.decoration_name = deco_dict.get("decoration_name", "Decoration")
		deco.enabled = deco_dict.get("enabled", true)
		deco.decoration_type = deco_dict.get("decoration_type", 0)
		deco.primary_block_id = deco_dict.get("primary_block_id", 6)
		deco.secondary_block_id = deco_dict.get("secondary_block_id", 7)
		deco.min_height = deco_dict.get("min_height", 4)
		deco.max_height = deco_dict.get("max_height", 8)
		deco.width = deco_dict.get("width", 3)
		deco.spawn_chance = deco_dict.get("spawn_chance", 0.1)
		deco.min_spacing = deco_dict.get("min_spacing", 2)
		deco.require_grass_below = deco_dict.get("require_grass_below", true)
		deco.required_surface_blocks = deco_dict.get("required_surface_blocks", [2])
		deco.max_slope = deco_dict.get("max_slope", 15.0)
		deco.min_spawn_y = deco_dict.get("min_spawn_y", 60)
		deco.max_spawn_y = deco_dict.get("max_spawn_y", 120)
		deco.use_noise_distribution = deco_dict.get("use_noise_distribution", true)
		deco.noise_frequency = deco_dict.get("noise_frequency", 0.05)
		deco.noise_threshold = deco_dict.get("noise_threshold", 0.3)
		decorations.append(deco)
	return decorations

func _save_cave_settings_to_world_data():
	if not _world_data or not cave_settings:
		return
	
	_world_data.cave_settings_data = {
		"enabled": cave_settings.enabled,
		"min_size": cave_settings.min_size,
		"max_size": cave_settings.max_size,
		"size_variation_frequency": cave_settings.size_variation_frequency,
		"min_y": cave_settings.min_y,
		"max_y": cave_settings.max_y,
		"frequency": cave_settings.frequency,
		"threshold": cave_settings.threshold,
		"octaves": cave_settings.octaves,
		"lacunarity": cave_settings.lacunarity,
		"gain": cave_settings.gain,
		"use_worm_caves": cave_settings.use_worm_caves,
		"worm_frequency": cave_settings.worm_frequency,
		"worm_threshold": cave_settings.worm_threshold
	}

func _load_cave_settings_from_world_data():
	if not _world_data:
		return
	
	var data = _world_data.cave_settings_data
	if data.is_empty():
		return
	
	if not cave_settings:
		cave_settings = CaveSettings.new()
	
	cave_settings.enabled = data.get("enabled", true)
	cave_settings.min_size = data.get("min_size", 0.3)
	cave_settings.max_size = data.get("max_size", 1.0)
	cave_settings.size_variation_frequency = data.get("size_variation_frequency", 0.01)
	cave_settings.min_y = data.get("min_y", 0)
	cave_settings.max_y = data.get("max_y", 64)
	cave_settings.frequency = data.get("frequency", 0.02)
	cave_settings.threshold = data.get("threshold", 0.6)
	cave_settings.octaves = data.get("octaves", 3)
	cave_settings.lacunarity = data.get("lacunarity", 2.0)
	cave_settings.gain = data.get("gain", 0.5)
	cave_settings.use_worm_caves = data.get("use_worm_caves", false)
	cave_settings.worm_frequency = data.get("worm_frequency", 0.005)
	cave_settings.worm_threshold = data.get("worm_threshold", 0.85)
	
	cave_settings.setup(world_seed)
