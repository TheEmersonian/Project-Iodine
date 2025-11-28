@tool
extends Resource
class_name OreDepositData

## Advanced ore deposit configuration with realistic generation

@export_category("Ore Identity")
@export var ore_name: String = "Coal Ore":
	set(value):
		ore_name = value
		emit_changed()

@export var enabled: bool = true:
	set(value):
		enabled = value
		emit_changed()

@export_category("Block Type")
@export_range(1, 255, 1) var block_id: int = 4:
	set(value):
		block_id = clampi(value, 1, 255)
		emit_changed()

@export_category("Spawn Conditions")
@export_subgroup("Height Range")
@export_range(0, 512, 1) var min_spawn_height: int = 0:
	set(value):
		min_spawn_height = clampi(value, 0, max_spawn_height - 1)
		emit_changed()

@export_range(0, 512, 1) var max_spawn_height: int = 64:
	set(value):
		max_spawn_height = clampi(value, min_spawn_height + 1, 512)
		emit_changed()

@export_subgroup("Rarity")
@export_range(0.0001, 1.0, 0.0001) var spawn_chance: float = 0.01:
	set(value):
		spawn_chance = clampf(value, 0.0001, 1.0)
		emit_changed()

@export_range(1, 100, 1) var veins_per_chunk: int = 3:
	set(value):
		veins_per_chunk = maxi(1, value)
		emit_changed()

@export_category("Vein Shape")
@export_enum("Sphere", "Ellipsoid", "Blob", "Vein", "Scattered") var vein_shape: int = 0:
	set(value):
		vein_shape = value
		emit_changed()

@export_range(1, 32, 1) var min_vein_size: int = 3:
	set(value):
		min_vein_size = clampi(value, 1, max_vein_size)
		emit_changed()

@export_range(1, 32, 1) var max_vein_size: int = 8:
	set(value):
		max_vein_size = clampi(value, min_vein_size, 32)
		emit_changed()

@export_range(0.0, 2.0, 0.1) var vein_elongation: float = 1.0:
	set(value):
		vein_elongation = clampf(value, 0.1, 2.0)
		emit_changed()

@export_category("Distribution Pattern")
@export_enum("Random", "Noise 3D", "Height Gradient", "Distance from Surface") var distribution_type: int = 1:
	set(value):
		distribution_type = value
		emit_changed()

@export_subgroup("Noise Settings")
@export_range(0.0001, 0.5, 0.0001) var noise_frequency: float = 0.05:
	set(value):
		noise_frequency = value
		emit_changed()

@export_range(-1.0, 1.0, 0.01) var noise_threshold: float = 0.5:
	set(value):
		noise_threshold = value
		emit_changed()

@export_range(1, 4, 1) var noise_octaves: int = 2:
	set(value):
		noise_octaves = value
		emit_changed()

@export_subgroup("Gradient Settings (for Height Gradient mode)")
@export_range(0.0, 1.0, 0.01) var peak_probability_height: float = 0.5:
	set(value):
		peak_probability_height = clampf(value, 0.0, 1.0)
		emit_changed()

@export_range(0.0, 1.0, 0.01) var gradient_falloff: float = 0.3:
	set(value):
		gradient_falloff = clampf(value, 0.01, 1.0)
		emit_changed()

@export_category("Advanced Options")
@export var replace_blocks: Array[int] = [1]: # Can replace these block IDs
	set(value):
		replace_blocks = value
		emit_changed()

@export var avoid_air: bool = true:
	set(value):
		avoid_air = value
		emit_changed()

@export var only_in_biomes: Array[String] = []:
	set(value):
		only_in_biomes = value
		emit_changed()

@export_range(0.0, 1.0, 0.01) var clustering: float = 0.5:
	set(value):
		clustering = clampf(value, 0.0, 1.0)
		emit_changed()

func should_spawn_vein(world_pos: Vector3i, noise: FastNoiseLite, biome_name: String = "") -> bool:
	if not enabled:
		return false
	
	if world_pos.y < min_spawn_height or world_pos.y > max_spawn_height:
		return false
	
	if only_in_biomes.size() > 0 and biome_name not in only_in_biomes:
		return false
	
	match distribution_type:
		0: # Random
			return randf() < spawn_chance
		1: # Noise 3D
			var noise_val = noise.get_noise_3d(
				world_pos.x * noise_frequency,
				world_pos.y * noise_frequency,
				world_pos.z * noise_frequency
			)
			return noise_val > noise_threshold
		2: # Height Gradient
			var height_factor = float(world_pos.y - min_spawn_height) / float(max_spawn_height - min_spawn_height)
			var distance_from_peak = absf(height_factor - peak_probability_height)
			var probability = spawn_chance * (1.0 - (distance_from_peak / gradient_falloff))
			return randf() < max(0.0, probability)
		3: # Distance from Surface
			return randf() < spawn_chance
	
	return false

func get_vein_size() -> int:
	return randi_range(min_vein_size, max_vein_size)

func generate_vein_positions(center: Vector3i, size: int) -> Array[Vector3i]:
	var positions: Array[Vector3i] = []
	
	match vein_shape:
		0: # Sphere
			positions = _generate_sphere(center, size)
		1: # Ellipsoid
			positions = _generate_ellipsoid(center, size)
		2: # Blob
			positions = _generate_blob(center, size)
		3: # Vein
			positions = _generate_vein_shape(center, size)
		4: # Scattered
			positions = _generate_scattered(center, size)
	
	return positions

func _generate_sphere(center: Vector3i, size: int) -> Array[Vector3i]:
	var positions: Array[Vector3i] = []
	var radius = float(size) / 2.0
	
	for x in range(-size, size + 1):
		for y in range(-size, size + 1):
			for z in range(-size, size + 1):
				var dist = Vector3(x, y, z).length()
				if dist <= radius:
					positions.append(center + Vector3i(x, y, z))
	
	return positions

func _generate_ellipsoid(center: Vector3i, size: int) -> Array[Vector3i]:
	var positions: Array[Vector3i] = []
	var radius_xz = float(size) / 2.0
	var radius_y = (float(size) / 2.0) * vein_elongation
	
	for x in range(-size, size + 1):
		for y in range(-int(size * vein_elongation), int(size * vein_elongation) + 1):
			for z in range(-size, size + 1):
				var normalized = Vector3(
					float(x) / radius_xz,
					float(y) / radius_y,
					float(z) / radius_xz
				)
				if normalized.length() <= 1.0:
					positions.append(center + Vector3i(x, y, z))
	
	return positions

func _generate_blob(center: Vector3i, size: int) -> Array[Vector3i]:
	var positions: Array[Vector3i] = []
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.3
	
	var radius = float(size) / 2.0
	
	for x in range(-size, size + 1):
		for y in range(-size, size + 1):
			for z in range(-size, size + 1):
				var dist = Vector3(x, y, z).length()
				var noise_offset = noise.get_noise_3d(x, y, z) * 2.0
				if dist + noise_offset <= radius:
					positions.append(center + Vector3i(x, y, z))
	
	return positions

func _generate_vein_shape(center: Vector3i, size: int) -> Array[Vector3i]:
	var positions: Array[Vector3i] = []
	var segments = int(float(size) * vein_elongation)
	
	var current_pos = Vector3(center)
	var direction = Vector3(randf_range(-1, 1), randf_range(-0.5, 0.5), randf_range(-1, 1)).normalized()
	
	for i in range(segments):
		var segment_radius = max(1, int(float(size) / 3.0 * (1.0 - float(i) / float(segments))))
		
		for x in range(-segment_radius, segment_radius + 1):
			for y in range(-segment_radius, segment_radius + 1):
				for z in range(-segment_radius, segment_radius + 1):
					if Vector3(x, y, z).length() <= segment_radius:
						positions.append(Vector3i(current_pos) + Vector3i(x, y, z))
		
		current_pos += direction * 2.0
		direction += Vector3(randf_range(-0.3, 0.3), randf_range(-0.2, 0.2), randf_range(-0.3, 0.3))
		direction = direction.normalized()
	
	return positions

func _generate_scattered(center: Vector3i, size: int) -> Array[Vector3i]:
	var positions: Array[Vector3i] = []
	var spread = size * 2
	
	for i in range(size):
		var offset = Vector3i(
			randi_range(-spread, spread),
			randi_range(-spread, spread),
			randi_range(-spread, spread)
		)
		positions.append(center + offset)
	
	return positions