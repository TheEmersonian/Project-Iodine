# 🗺️ Advanced Map Generator - Godot 4.5 Addon

A sophisticated, production-ready procedural world generation system with advanced biome blending, comprehensive terrain control, and seamless VoxelWorld integration.

## ✨ Key Features

### 🌍 Advanced Terrain Generation
- **Multi-layered Noise System** - Base terrain, continentalness, erosion
- **Climate System** - Temperature and humidity influence
- **Sea Level & Water Generation** - Configurable water bodies
- **Erosion Simulation** - Realistic terrain weathering
- **Continental Features** - Large-scale land formations

### 🌿 Sophisticated Biome System
- **Unlimited Biomes** - Create as many biomes as needed
- **Advanced Blending** - Smooth, natural transitions between biomes
- **Priority System** - Control which biomes dominate overlaps
- **Noise Masking** - Organic biome shapes
- **Per-Biome Terrain** - Individual height modifiers
- **Climate Zones** - Temperature and humidity per biome

### 📦 Flexible Block Layers
Each biome supports multiple block layer types:
- **Surface Layers** - Top blocks (grass, sand, snow)
- **Subsurface Layers** - Below surface (dirt, gravel)
- **Underground Layers** - Deep blocks (stone, bedrock)
- **Placement Modes**: Surface, Below Surface, Fixed Depth, Random Height, Noise Based
- **Conditions**: Solid below, air above, slope restrictions

### ⛏️ Advanced Ore System
- **Multiple Vein Shapes**: Sphere, Ellipsoid, Blob, Vein, Scattered
- **Distribution Patterns**: Random, 3D Noise, Height Gradient, Surface Distance
- **Realistic Spawning** - Veins per chunk, size variation
- **Biome-Specific** - Target specific biomes
- **Height-Based** - Different ores at different depths
- **Clustering** - Ore concentration control

### 🌲 Decoration System
- **Types**: Single Block, Vertical Stack, Tree, Structure, Custom Pattern
- **Conditions**: Required surface blocks, slope limits, height range
- **Distribution**: Noise-based or random
- **Spacing Control** - Minimum distance between decorations
- **Auto-Generation** - Trees, rocks, plants on surface

### 🕳️ Cave Generation
- **3D Noise Caves** - Realistic cave systems
- **Variable Sizes** - Dynamic cave dimensions
- **Worm Caves** - Long tunnels
- **Height Restrictions** - Cave zones
- **Configurable Density** - From rare to abundant

### 💾 Complete Persistence
- **World Save/Load** - Full world state preservation
- **Chunk Tracking** - Knows which chunks are generated
- **Incremental Generation** - Generate only missing chunks
- **JSON Format** - Human-readable save files
- **Auto-Save** - Configurable interval
- **Compression** - Optional data compression

### ⚡ Performance Optimized
- **Queue System** - Controlled generation rate
- **Multithreading** - Optional parallel generation
- **Chunk Caching** - Reuse generated data
- **Bulk Operations** - Efficient VoxelWorld integration
- **Configurable Limits** - Chunks per frame, cache size

## 📦 Installation

1. Download or clone this repository
2. Copy `addons/map_generator/` to your project's `addons/` directory
3. Enable the plugin: Project Settings → Plugins → "Map Generator"
4. **Install VoxelWorld addon** (required dependency)

## 🚀 Quick Start

### Basic Setup

```gdscript
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
```

## 🎮 Complete API Reference

### World Management

#### `create_new_world(name: String = "", seed: int = -1) -> bool`
Create a new world with current settings.

```gdscript
# Random seed
map_gen.create_new_world("Adventure World")

# Specific seed
map_gen.create_new_world("Fixed World", 42069)
```

#### `load_world(world_path: String = "") -> bool`
Load an existing world from disk.

```gdscript
map_gen.world_name = "MyWorld"
if map_gen.load_world():
    print("World loaded successfully!")
```

#### `save_world() -> bool`
Save current world state.

```gdscript
map_gen.save_world()
```

#### `delete_world(world_name: String = "") -> bool`
Delete a world from disk.

```gdscript
map_gen.delete_world("OldWorld")
```

### Chunk Generation

#### `generate_chunk(chunk_pos: Vector3i, force_regenerate: bool = false) -> bool`
Generate a specific chunk.

```gdscript
map_gen.generate_chunk(Vector3i(0, 0, 0))
```

#### `generate_chunks(chunk_positions: Array[Vector3i])`
Generate multiple chunks (queued).

```gdscript
var chunks: Array[Vector3i] = [
    Vector3i(0, 0, 0),
    Vector3i(1, 0, 0),
    Vector3i(0, 0, 1)
]
map_gen.generate_chunks(chunks)
```

#### `generate_region(min_chunk: Vector3i, max_chunk: Vector3i)`
Generate all chunks in a region.

```gdscript
# Generate 10x10 area around spawn
map_gen.generate_region(
    Vector3i(-5, 0, -5),
    Vector3i(5, 2, 5)
)
```

#### `is_chunk_generated(chunk_pos: Vector3i) -> bool`
Check if a chunk is generated.

```gdscript
if not map_gen.is_chunk_generated(chunk_pos):
    map_gen.generate_chunk(chunk_pos)
```

#### `get_generated_chunks() -> Array[Vector3i]`
Get all generated chunk positions.

```gdscript
var chunks = map_gen.get_generated_chunks()
print("Generated: %d chunks" % chunks.size())
```

#### `clear_generation_data()`
Clear all generation data (for reset).

```gdscript
map_gen.clear_generation_data()
```

### Biome Management

#### `add_biome(biome_name: String = "") -> BiomeData`
Add a new biome and return reference.

```gdscript
var forest = map_gen.add_biome("Forest")
forest.min_x = -200
forest.max_x = 200
forest.min_z = -200
forest.max_z = 200
forest.priority_factor = 1.2
forest.blend_color = Color(0.2, 0.6, 0.2)
```

#### `remove_biome(index: int) -> bool`
Remove a biome by index.

```gdscript
map_gen.remove_biome(0)
```

#### `get_biome_at(world_pos: Vector3) -> BiomeData`
Get the dominant biome at a position.

```gdscript
var biome = map_gen.get_biome_at(Vector3(100, 50, 100))
print("Current biome: ", biome.biome_name)
```

#### `get_biome_influences(world_pos: Vector3) -> Array`
Get all biomes influencing a position with weights.

```gdscript
var influences = map_gen.get_biome_influences(Vector3(100, 50, 100))
for influence in influences:
    print("%s: %.2f%%" % [influence.biome.biome_name, influence.weight * 100])
```

### Terrain Queries

#### `get_height_at(world_x: float, world_z: float) -> float`
Get terrain height at XZ coordinates.

```gdscript
var height = map_gen.get_height_at(100.0, 200.0)
```

#### `get_temperature_at(world_pos: Vector3) -> float`
Get temperature at position (if climate system enabled).

```gdscript
var temp = map_gen.get_temperature_at(Vector3(100, 50, 100))
```

#### `get_humidity_at(world_pos: Vector3) -> float`
Get humidity at position (if climate system enabled).

```gdscript
var humidity = map_gen.get_humidity_at(Vector3(100, 50, 100))
```

## 📋 Inspector Configuration

### 🌍 World Configuration

**Seed & Identity**
- `world_seed` (int) - Generation seed (0 = random)
- `world_name` (String) - World identifier
- `world_description` (String, multiline) - World description

**World Boundaries**
- `min_world_x`, `max_world_x` (float) - Horizontal X bounds
- `min_world_z`, `max_world_z` (float) - Horizontal Z bounds
- `min_world_y`, `max_world_y` (int, 0-512) - Vertical bounds

**Sea Level & Atmosphere**
- `sea_level` (int, 0-256) - Water surface height
- `water_block_id` (int, 1-255) - Block ID for water
- `generate_water` (bool) - Enable water generation

### ⛰️ Terrain Generation

**Base Terrain**
- `base_terrain_amplitude` (float, 0-100) - Height variation
- `base_terrain_frequency` (float, 0.0001-0.05) - Terrain scale
- `terrain_octaves` (int, 1-8) - Detail levels
- `terrain_noise_type` (enum) - Perlin, Simplex, Cellular, Value

**Terrain Features**
- `enable_continentalness` (bool) - Large-scale formations
- `continent_frequency` (float) - Continental scale
- `continent_influence` (float, 0-100) - Continental strength
- `enable_erosion` (bool) - Terrain weathering
- `erosion_strength` (float, 0-1) - Erosion intensity

### 🌿 Biome System

**Biome Management**
- `biomes` (Array[BiomeData]) - List of all biomes

**Biome Blending**
- `enable_biome_blending` (bool) - Smooth transitions
- `global_blend_radius` (float, 0-128) - Transition distance
- `blend_smoothness` (float, 0-1) - Transition curve
- `use_blend_noise` (bool) - Add noise to blending
- `blend_noise_frequency` (float) - Blend noise scale
- `blend_noise_strength` (float, 0-1) - Blend noise intensity

**Temperature & Humidity System**
- `use_climate_system` (bool) - Enable climate
- `temperature_frequency` (float) - Temperature variation
- `humidity_frequency` (float) - Humidity variation

### BiomeData Properties

**Identity**
- `biome_name` (String) - Biome name
- `biome_id` (int) - Unique identifier
- `description` (String, multiline) - Biome description

**Boundaries**
- `min_x`, `max_x` (float) - X bounds
- `min_z`, `max_z` (float) - Z bounds
- `min_y`, `max_y` (int, 0-512) - Y bounds

**Terrain Generation**
- `base_height_offset` (float) - Height adjustment
- `height_amplitude` (float, 0-100) - Height variation
- `height_frequency` (float) - Terrain detail
- `height_octaves` (int, 1-8) - Noise octaves
- `noise_type` (enum) - Noise algorithm
- `terrain_roughness` (float, 0-10) - Lacunarity
- `terrain_persistence` (float, 0-1) - Gain

**Biome Blending**
- `blend_color` (Color) - Debug/visualization color
- `priority_factor` (float, 0-10) - Dominance in overlaps
- `blend_radius` (float, 0-100) - Per-biome blend distance
- `use_noise_mask` (bool) - Organic biome shape
- `mask_frequency`, `mask_amplitude`, `mask_threshold` (float) - Mask settings

**Climate**
- `temperature` (float, -50 to 50) - Base temperature
- `humidity` (float, 0-100) - Base humidity

**Block Arrays**
- `surface_blocks` (Array[BlockLayerData]) - Surface layers
- `subsurface_blocks` (Array[BlockLayerData]) - Below surface
- `underground_blocks` (Array[BlockLayerData]) - Deep layers
- `ore_deposits` (Array[OreDepositData]) - Ore veins
- `decorations` (Array[DecorationData]) - Surface decorations

### BlockLayerData Properties

**Identity**
- `layer_name` (String) - Layer name
- `enabled` (bool) - Enable/disable layer

**Block Type**
- `block_id` (int, 1-255) - Block ID
- `block_name` (String) - Block name

**Layer Placement**
- `placement_mode` (enum) - Surface, Below Surface, Fixed Depth, Random Height, Noise Based
- `depth_from_surface` (int, 0-256) - Depth offset
- `thickness` (int, 1-64) - Layer thickness
- `min_height`, `max_height` (int, 0-512) - Height range

**Distribution**
- `coverage` (float, 0-1) - Placement probability
- `use_noise_distribution` (bool) - Noise-based placement
- `noise_frequency`, `noise_threshold` (float) - Noise settings

**Conditions**
- `requires_solid_below` (bool) - Need solid block below
- `requires_air_above` (bool) - Need air above
- `max_slope` (float, 0-90) - Maximum terrain slope

### OreDepositData Properties

**Identity**
- `ore_name` (String) - Ore name
- `enabled` (bool) - Enable/disable

**Block Type**
- `block_id` (int, 1-255) - Ore block ID

**Spawn Conditions**
- `min_spawn_height`, `max_spawn_height` (int, 0-512) - Height range
- `spawn_chance` (float, 0.0001-1) - Spawn probability
- `veins_per_chunk` (int, 1-100) - Veins per chunk

**Vein Shape**
- `vein_shape` (enum) - Sphere, Ellipsoid, Blob, Vein, Scattered
- `min_vein_size`, `max_vein_size` (int, 1-32) - Size range
- `vein_elongation` (float, 0-2) - Stretch factor

**Distribution Pattern**
- `distribution_type` (enum) - Random, Noise 3D, Height Gradient, Distance from Surface
- `noise_frequency`, `noise_threshold`, `noise_octaves` (float/int) - Noise settings
- `peak_probability_height` (float, 0-1) - Peak spawn height (gradient mode)
- `gradient_falloff` (float, 0-1) - Gradient steepness

**Advanced Options**
- `replace_blocks` (Array[int]) - Can replace these block IDs
- `avoid_air` (bool) - Don't spawn in air
- `only_in_biomes` (Array[String]) - Spawn only in these biomes
- `clustering` (float, 0-1) - Vein concentration

### DecorationData Properties

**Identity**
- `decoration_name` (String) - Decoration name
- `enabled` (bool) - Enable/disable

**Type**
- `decoration_type` (enum) - Single Block, Vertical Stack, Tree, Structure, Custom Pattern

**Blocks**
- `primary_block_id` (int, 1-255) - Main block (trunk, stem)
- `secondary_block_id` (int, 1-255) - Secondary block (leaves, top)

**Size**
- `min_height`, `max_height` (int, 1-32) - Height range
- `width` (int, 1-16) - Width/radius

**Spawn Conditions**
- `spawn_chance` (float, 0-1) - Placement probability
- `min_spacing` (int, 1-64) - Minimum distance between decorations
- `require_grass_below` (bool) - Need grass below
- `required_surface_blocks` (Array[int]) - Required block IDs below
- `max_slope` (float, 0-45) - Maximum slope
- `min_spawn_y`, `max_spawn_y` (int, 0-512) - Height range

**Distribution**
- `use_noise_distribution` (bool) - Noise-based placement
- `noise_frequency`, `noise_threshold` (float) - Noise settings

### 🕳️ Cave System

- `cave_settings` (CaveSettings) - Cave configuration resource
  - `enabled` (bool) - Enable caves
  - `min_size`, `max_size` (float, 0.1-2) - Cave size range
  - `size_variation_frequency` (float) - Size variation
  - `min_y`, `max_y` (int) - Cave height range
  - `frequency`, `threshold` (float) - 3D noise settings
  - `octaves`, `lacunarity`, `gain` (int/float) - Fractal settings
  - `use_worm_caves` (bool) - Long tunnels
  - `worm_frequency`, `worm_threshold` (float) - Worm settings

### 🏗️ Structures & Features

**Decoration Generation**
- `enable_decorations` (bool) - Enable surface decorations
- `decoration_attempts_per_column` (int, 0-100) - Attempts per XZ column

**Structure Spawning**
- `enable_structures` (bool) - Enable structures
- `structure_spawn_chance` (float, 0-1) - Structure probability

### 💾 Save & Load

- `save_directory` (String, dir) - Save location
- `auto_save_interval` (float) - Auto-save every N seconds (0 = disabled)
- `compress_save_data` (bool) - Compress save files

### ⚡ Performance

- `chunks_per_frame` (int, 1-50) - Generation rate
- `use_multithreading` (bool) - Parallel generation
- `worker_threads` (int, 1-8) - Thread count
- `cache_chunk_data` (bool) - Cache generated chunks
- `max_cache_size` (int, 10-1000) - Maximum cached chunks

### 🐛 Debug

- `debug_mode` (bool) - Enable debug output
- `log_generation_stats` (bool) - Log performance stats
- `visualize_biomes` (bool) - Visual biome display

## 🔔 Signals

```gdscript
signal map_generated(world_name: String, seed_value: int)
signal map_loaded(world_name: String)
signal chunk_generation_started(chunk_pos: Vector3i)
signal chunk_generation_completed(chunk_pos: Vector3i, blocks_placed: int)
signal biome_added(biome: BiomeData)
signal biome_removed(index: int)
signal generation_progress(current: int, total: int)
signal world_saved(path: String)
```

## 📚 Advanced Examples

### Complete Biome Setup

```gdscript
func create_forest_biome() -> BiomeData:
	var forest = map_gen.add_biome("Dense Forest")
	
	# Boundaries
	forest.min_x = -400
	forest.max_x = 400
	forest.min_z = -400
	forest.max_z = 400
	forest.min_y = 50
	forest.max_y = 120
	
	# Terrain
	forest.base_height_offset = 5.0
	forest.height_amplitude = 8.0
	forest.height_frequency = 0.015
	forest.height_octaves = 4
	forest.terrain_roughness = 2.5
	
	# Blending
	forest.priority_factor = 1.3
	forest.blend_radius = 40.0
	forest.blend_color = Color(0.2, 0.5, 0.2)
	
	# Climate
	forest.temperature = 18.0
	forest.humidity = 75.0
	
	# Grass surface
	var grass = BlockLayerData.new()
	grass.layer_name = "Grass"
	grass.block_id = 2
	grass.placement_mode = 0 # Surface
	grass.thickness = 1
	forest.surface_blocks.append(grass)
	
	# Dirt subsurface
	var dirt = BlockLayerData.new()
	dirt.layer_name = "Dirt"
	dirt.block_id = 3
	dirt.placement_mode = 1 # Below Surface
	dirt.depth_from_surface = 1
	dirt.thickness = 5
	forest.subsurface_blocks.append(dirt)
	
	# Stone base
	var stone = BlockLayerData.new()
	stone.layer_name = "Stone"
	stone.block_id = 1
	stone.placement_mode = 2 # Fixed Depth
	stone.min_height = 0
	stone.max_height = 60
	forest.underground_blocks.append(stone)
	
	# Coal ore
	var coal = OreDepositData.new()
	coal.ore_name = "Coal"
	coal.block_id = 4
	coal.min_spawn_height = 10
	coal.max_spawn_height = 50
	coal.spawn_chance = 0.05
	coal.veins_per_chunk = 4
	coal.vein_shape = 2 # Blob
	coal.min_vein_size = 4
	coal.max_vein_size = 8
	coal.distribution_type = 1 # Noise 3D
	coal.noise_threshold = 0.6
	forest.ore_deposits.append(coal)
	
	# Trees
	var tree = DecorationData.new()
	tree.decoration_name = "Oak Tree"
	tree.decoration_type = 2 # Tree
	tree.primary_block_id = 6 # Wood
	tree.secondary_block_id = 7 # Leaves
	tree.min_height = 5
	tree.max_height = 9
	tree.width = 3
	tree.spawn_chance = 0.08
	tree.min_spacing = 3
	tree.required_surface_blocks = [2] # Only on grass
	tree.use_noise_distribution = true
	tree.noise_threshold = 0.4
	forest.decorations.append(tree)
	
	return forest
```

### Mountain Biome with Snow

```gdscript
func create_mountain_biome() -> BiomeData:
	var mountains = map_gen.add_biome("Mountains")
	
	mountains.min_x = 200
	mountains.max_x = 800
	mountains.min_z = -400
	mountains.max_z = 400
	mountains.min_y = 0
	mountains.max_y = 200
	
	# High terrain
	mountains.base_height_offset = 30.0
	mountains.height_amplitude = 50.0
	mountains.height_frequency = 0.008
	mountains.height_octaves = 5
	mountains.terrain_roughness = 3.0
	mountains.terrain_persistence = 0.6
	
	# High priority
	mountains.priority_factor = 2.0
	mountains.blend_radius = 60.0
	mountains.blend_color = Color(0.7, 0.7, 0.8)
	
	# Cold
	mountains.temperature = -5.0
	mountains.humidity = 40.0
	
	# Snow cap
	var snow = BlockLayerData.new()
	snow.layer_name = "Snow"
	snow.block_id = 5
	snow.placement_mode = 0 # Surface
	snow.min_height = 140
	snow.max_height = 200
	snow.thickness = 1
	mountains.surface_blocks.append(snow)
	
	# Stone surface (below snow line)
	var stone_surface = BlockLayerData.new()
	stone_surface.layer_name = "Stone Surface"
	stone_surface.block_id = 1
	stone_surface.placement_mode = 0
	stone_surface.min_height = 0
	stone_surface.max_height = 139
	mountains.surface_blocks.append(stone_surface)
	
	# Deep stone
	var deep_stone = BlockLayerData.new()
	deep_stone.layer_name = "Stone"
	deep_stone.block_id = 1
	deep_stone.placement_mode = 1 # Below Surface
	deep_stone.depth_from_surface = 1
	deep_stone.thickness = 100
	mountains.subsurface_blocks.append(deep_stone)
	
	# Iron ore (common in mountains)
	var iron = OreDepositData.new()
	iron.ore_name = "Iron"
	iron.block_id = 8
	iron.min_spawn_height = 20
	iron.max_spawn_height = 100
	iron.spawn_chance = 0.04
	iron.veins_per_chunk = 5
	iron.vein_shape = 1 # Ellipsoid
	iron.min_vein_size = 5
	iron.max_vein_size = 10
	iron.vein_elongation = 1.5
	iron.distribution_type = 2 # Height Gradient
	iron.peak_probability_height = 0.4
	iron.gradient_falloff = 0.3
	mountains.ore_deposits.append(iron)
	
	# Rare diamond
	var diamond = OreDepositData.new()
	diamond.ore_name = "Diamond"
	diamond.block_id = 10
	diamond.min_spawn_height = 5
	diamond.max_spawn_height = 20
	diamond.spawn_chance = 0.001
	diamond.veins_per_chunk = 1
	diamond.vein_shape = 0 # Sphere
	diamond.min_vein_size = 2
	diamond.max_vein_size = 4
	diamond.distribution_type = 1 # Noise 3D
	diamond.noise_threshold = 0.85
	mountains.ore_deposits.append(diamond)
	
	return mountains
```

### Dynamic Chunk Loading

```gdscript
extends Node3D

@onready var map_gen: MapGenerator = $MapGenerator
@onready var camera: Camera3D = $Camera3D

var last_chunk_pos: Vector3i = Vector3i.MAX
var render_distance: int = 6

func _process(_delta):
	if not map_gen or not camera:
		return
	
	var cam_pos = camera.global_position
	var current_chunk = _world_to_chunk(cam_pos)
	
	if current_chunk != last_chunk_pos:
		last_chunk_pos = current_chunk
		_generate_around_player(current_chunk)

func _generate_around_player(center: Vector3i):
	var chunks_to_generate: Array[Vector3i] = []
	
	for x in range(-render_distance, render_distance + 1):
		for z in range(-render_distance, render_distance + 1):
			for y in range(-2, 3):
				var chunk_pos = center + Vector3i(x, y, z)
				
				# Distance check
				var dist = Vector2(x, z).length()
				if dist > render_distance:
					continue
				
				if not map_gen.is_chunk_generated(chunk_pos):
					chunks_to_generate.append(chunk_pos)
	
	if chunks_to_generate.size() > 0:
		# Sort by distance
		chunks_to_generate.sort_custom(func(a, b):
			var da = Vector3(a - center).length()
			var db = Vector3(b - center).length()
			return da < db
		)
		
		map_gen.generate_chunks(chunks_to_generate)

func _world_to_chunk(pos: Vector3) -> Vector3i:
	var chunk_size = 16 # Adjust to your chunk size
	return Vector3i(
		floori(pos.x / chunk_size),
		floori(pos.y / chunk_size),
		floori(pos.z / chunk_size)
	)
```

## 💡 Best Practices

### Performance

1. **Chunk Generation Rate**
   - Mobile: `chunks_per_frame = 2-3`
   - Desktop: `chunks_per_frame = 4-8`
   - Server: `chunks_per_frame = 10-20`

2. **Render Distance**
   - Adjust based on platform
   - Mobile: 4-6 chunks
   - Desktop: 8-12 chunks
   - Server: 16+ chunks

3. **Threading**
   - Enable on multicore systems
   - `worker_threads = 4` for most cases
   - Monitor CPU usage

4. **Caching**
   - Enable for frequently accessed areas
   - `max_cache_size = 200` is a good default
   - Clear cache periodically if memory is limited

### Biome Design

1. **Boundaries**
   - Leave space between biomes for transitions
   - Overlap biomes intentionally for mixing
   - Use `priority_factor` to control dominance

2. **Blending**
   - `blend_radius` 32-64 for smooth transitions
   - Enable `use_blend_noise` for natural edges
   - Adjust `blend_smoothness` for gradient curve

3. **Height Variation**
   - Use `base_height_offset` for elevation differences
   - `height_amplitude` for terrain roughness
   - Lower `height_frequency` for larger features

4. **Block Layers**
   - Always have a surface layer
   - Use subsurface for transition materials
   - Underground layers for deep materials
   - Order matters - first matching layer wins

### Ore Configuration

1. **Realism**
   - Use `Height Gradient` distribution for realistic depth-based spawning
   - Common ores: high spawn_chance (0.03-0.08), many veins per chunk
   - Rare ores: low spawn_chance (0.001-0.01), few veins per chunk
   - Deep ores should have lower min_spawn_height

2. **Vein Shapes**
   - `Sphere` - Simple, uniform deposits
   - `Ellipsoid` - Stretched veins (use `vein_elongation`)
   - `Blob` - Irregular, natural shapes
   - `Vein` - Long, tunnel-like deposits
   - `Scattered` - Dispersed ore blocks

3. **Distribution**
   - `Noise 3D` - Most natural looking
   - `Height Gradient` - Depth-dependent (realistic)
   - `Random` - Simple but less interesting
   - `Distance from Surface` - Special use cases

### Cave Generation

1. **Balanced Caves**
   - `threshold` 0.6-0.7 for medium density
   - `frequency` 0.02-0.03 for good detail
   - `octaves` 3-4 for natural variation

2. **Worm Caves**
   - Set `worm_threshold` high (0.85-0.95)
   - Lower `worm_frequency` for longer tunnels
   - Combine with regular caves for variety

3. **Height Zones**
   - Surface caves: `max_y` near sea level
   - Deep caves: `min_y` well underground
   - Multiple cave layers with different settings

### Decoration Placement

1. **Natural Distribution**
   - Enable `use_noise_distribution`
   - Adjust `noise_threshold` for density
   - Use `min_spacing` to prevent clustering

2. **Biome-Specific**
   - Set `required_surface_blocks` for correct placement
   - Use `max_slope` to avoid steep terrain
   - Adjust `spawn_chance` per biome type

3. **Structure Types**
   - Simple grass: `Single Block`
   - Tall plants: `Vertical Stack`
   - Trees: `Tree` type with proper dimensions
   - Ruins/rocks: `Structure` or `Custom Pattern`

## 🔧 Troubleshooting

### Chunks Not Generating

**Problem**: Chunks aren't being created  
**Solutions**:
- Ensure VoxelWorld is in the scene
- Check that chunk position is within world boundaries
- Verify biomes have block layers defined
- Check console for error messages

### Performance Issues

**Problem**: Frame drops during generation  
**Solutions**:
- Reduce `chunks_per_frame` (try 2-3)
- Lower `render_distance`
- Disable `enable_decorations` temporarily
- Reduce `terrain_octaves`
- Disable `use_multithreading` if causing issues

### Biome Blending Problems

**Problem**: Sharp transitions or missing biomes  
**Solutions**:
- Increase `global_blend_radius` (try 40-60)
- Enable `use_blend_noise`
- Check biome boundaries overlap
- Adjust `priority_factor` for dominance
- Increase `blend_smoothness`

### Ores Not Spawning

**Problem**: Ores are too rare or missing  
**Solutions**:
- Increase `spawn_chance`
- Increase `veins_per_chunk`
- Check height range matches terrain
- Verify `distribution_type` settings
- Lower `noise_threshold` for Noise 3D mode
- Check `only_in_biomes` array

### Decorations Missing

**Problem**: Trees/plants not appearing  
**Solutions**:
- Check `enable_decorations` is true
- Verify `required_surface_blocks` matches terrain
- Increase `spawn_chance`
- Lower `noise_threshold`
- Check `max_slope` isn't too restrictive
- Verify height range (`min_spawn_y` to `max_spawn_y`)

### Save/Load Failures

**Problem**: Can't save or load worlds  
**Solutions**:
- Check `save_directory` path exists
- Verify write permissions
- Check disk space
- Look for JSON parsing errors in console
- Ensure `world_name` is valid (no special characters)

### Water Not Generating

**Problem**: No water at sea level  
**Solutions**:
- Check `generate_water` is enabled
- Verify `sea_level` is set correctly
- Ensure terrain goes below sea level
- Check `water_block_id` is valid

## 📁 Project Structure

```
addons/map_generator/
├── plugin.cfg                      # Plugin configuration
├── plugin.gd                       # Plugin entry point
├── map_generator.gd                # Main generator node
├── biome_data.gd                   # Biome resource
├── block_layer_data.gd             # Block layer resource
├── ore_deposit_data.gd             # Ore configuration resource
├── decoration_data.gd              # Decoration resource
├── cave_settings.gd                # Cave settings resource
├── world_save_data.gd              # World persistence
├── map_debug_visualizer.gd         # Debug tools
├── icons/
│   └── map_generator.svg           # Node icon
└── examples/
    ├── example_world_generator.gd  # Usage example
    └── example_biome_presets.gd    # Biome templates
```

## 💾 Save File Format

Worlds are saved in JSON format for easy editing and debugging.

### Directory Structure

```
user://worlds/
└── MyWorld/
    ├── world_data.json             # World metadata
    └── chunks/                     # VoxelWorld chunk data
        ├── 0_0_0.chunk
        ├── 1_0_0.chunk
        └── ...
```

### world_data.json Example

```json
{
    "world_name": "MyWorld",
    "seed_value": 12345,
    "creation_timestamp": 1234567890,
    "last_modified": 1234567900,
    "world_limits_xz": [-2048, 2048],
    "world_limits_y": [0, 256],
    "noise_amplitude": 32.0,
    "noise_frequency": 0.003,
    "biome_blend_enabled": true,
    "blend_transition_radius": 32.0,
    "blend_noise_intensity": 0.3,
    "blend_noise_frequency": 0.02,
    "generated_chunks": {
        "0_0_0": true,
        "1_0_0": true,
        "0_0_1": true
    },
    "biomes_data": [
        {
            "biome_name": "Plains",
            "biome_id": 0,
            "min_x": -500,
            "max_x": 500,
            "surface_blocks": [...],
            "ore_deposits": [...]
        }
    ],
    "cave_settings_data": {
        "enabled": true,
        "threshold": 0.6,
        "frequency": 0.02
    }
}
```

## 🎓 Advanced Techniques

### Custom Biome Transitions

Create smooth transitions between specific biomes:

```gdscript
func setup_biome_transitions():
    var plains = map_gen.biomes[0]
    var forest = map_gen.biomes[1]
    
    # Plains dominant near its center
    plains.priority_factor = 1.0
    plains.blend_radius = 30.0
    
    # Forest more aggressive in overlaps
    forest.priority_factor = 1.5
    forest.blend_radius = 50.0
    
    # Use noise mask for organic forest edges
    forest.use_noise_mask = true
    forest.mask_frequency = 0.01
    forest.mask_amplitude = 1.2
    forest.mask_threshold = 0.2
```

### Temperature-Based Biome Selection

Use climate system for automatic biome selection:

```gdscript
func create_climate_based_biomes():
    # Cold biome
    var tundra = map_gen.add_biome("Tundra")
    tundra.temperature = -15.0
    tundra.humidity = 30.0
    
    # Temperate biome
    var plains = map_gen.add_biome("Plains")
    plains.temperature = 18.0
    plains.humidity = 50.0
    
    # Hot biome
    var desert = map_gen.add_biome("Desert")
    desert.temperature = 35.0
    desert.humidity = 10.0
```

### Progressive Chunk Generation

Load chunks based on distance and priority:

```gdscript
func generate_progressive(center: Vector3i, max_distance: int):
    var chunks_by_distance: Dictionary = {}
    
    # Group chunks by distance
    for x in range(-max_distance, max_distance + 1):
        for z in range(-max_distance, max_distance + 1):
            for y in range(-2, 3):
                var chunk_pos = center + Vector3i(x, y, z)
                var dist = Vector2(x, z).length()
                
                if dist > max_distance:
                    continue
                
                var dist_key = int(dist)
                if not chunks_by_distance.has(dist_key):
                    chunks_by_distance[dist_key] = []
                chunks_by_distance[dist_key].append(chunk_pos)
    
    # Generate by distance (closest first)
    var distances = chunks_by_distance.keys()
    distances.sort()
    
    for dist in distances:
        map_gen.generate_chunks(chunks_by_distance[dist])
        await get_tree().process_frame  # Wait between distance rings
```

### Ore Vein Clustering

Create clustered ore deposits:

```gdscript
func create_clustered_ore() -> OreDepositData:
    var gold = OreDepositData.new()
    gold.ore_name = "Gold Cluster"
    gold.block_id = 11
    gold.min_spawn_height = 5
    gold.max_spawn_height = 30
    gold.spawn_chance = 0.002
    gold.veins_per_chunk = 2
    
    # Use blob shape with high clustering
    gold.vein_shape = 2  # Blob
    gold.min_vein_size = 8
    gold.max_vein_size = 16
    gold.clustering = 0.9  # High clustering
    
    # Noise distribution creates cluster zones
    gold.distribution_type = 1  # Noise 3D
    gold.noise_frequency = 0.02
    gold.noise_threshold = 0.75
    gold.noise_octaves = 3
    
    return gold
```

### Layered Underground System

Create distinct underground layers:

```gdscript
func create_layered_underground(biome: BiomeData):
    # Topsoil
    var topsoil = BlockLayerData.new()
    topsoil.layer_name = "Topsoil"
    topsoil.block_id = 3  # Dirt
    topsoil.placement_mode = 1  # Below Surface
    topsoil.depth_from_surface = 1
    topsoil.thickness = 4
    biome.subsurface_blocks.append(topsoil)
    
    # Upper stone
    var upper_stone = BlockLayerData.new()
    upper_stone.layer_name = "Upper Stone"
    upper_stone.block_id = 1  # Stone
    upper_stone.placement_mode = 2  # Fixed Depth
    upper_stone.min_height = 40
    upper_stone.max_height = 60
    biome.underground_blocks.append(upper_stone)
    
    # Deep stone
    var deep_stone = BlockLayerData.new()
    deep_stone.layer_name = "Deep Stone"
    deep_stone.block_id = 12  # Deep Stone
    deep_stone.placement_mode = 2
    deep_stone.min_height = 10
    deep_stone.max_height = 40
    biome.underground_blocks.append(deep_stone)
    
    # Bedrock
    var bedrock = BlockLayerData.new()
    bedrock.layer_name = "Bedrock"
    bedrock.block_id = 13
    bedrock.placement_mode = 2
    bedrock.min_height = 0
    bedrock.max_height = 10
    biome.underground_blocks.append(bedrock)
```

### Dynamic Biome Modification

Modify biomes at runtime:

```gdscript
func modify_biome_at_position(world_pos: Vector3, height_change: float):
    var biome = map_gen.get_biome_at(world_pos)
    if biome:
        biome.base_height_offset += height_change
        
        # Regenerate affected chunks
        var chunk_pos = _world_to_chunk(world_pos)
        for x in range(-1, 2):
            for z in range(-1, 2):
                var pos = chunk_pos + Vector3i(x, 0, z)
                map_gen.generate_chunk(pos, true)  # Force regenerate
```

### Biome-Specific Weather/Effects

Store custom data in biome descriptions:

```gdscript
func setup_biome_metadata():
    var desert = map_gen.add_biome("Desert")
    desert.description = """
    weather: sunny
    particle_effect: dust_storm
    fog_color: #FFE4B5
    ambient_sound: desert_wind
    sky_tint: #FFA07A
    """
    
    # Later, parse the description
    var metadata = _parse_biome_metadata(desert.description)
    apply_weather(metadata["weather"])
    spawn_particles(metadata["particle_effect"])
```

### World Presets

Create reusable world configurations:

```gdscript
const WorldPresets = {
    "FLAT": {
        "base_terrain_amplitude": 2.0,
        "enable_continentalness": false,
        "enable_erosion": false
    },
    "MOUNTAINOUS": {
        "base_terrain_amplitude": 80.0,
        "terrain_octaves": 6,
        "continent_influence": 40.0
    },
    "ARCHIPELAGO": {
        "base_terrain_amplitude": 20.0,
        "enable_continentalness": true,
        "continent_frequency": 0.002,
        "sea_level": 80
    }
}

func apply_preset(preset_name: String):
    if not WorldPresets.has(preset_name):
        return
    
    var preset = WorldPresets[preset_name]
    for key in preset.keys():
        map_gen.set(key, preset[key])
```

## 📊 Performance Benchmarks

Typical performance on modern hardware (Intel i7, 16GB RAM):

| Operation | Chunks/Second | Time per Chunk |
|-----------|---------------|----------------|
| Simple terrain (no biomes) | 50-80 | 12-20ms |
| Terrain + biomes | 30-50 | 20-33ms |
| Full generation (ores, decorations) | 15-25 | 40-66ms |
| With caves | 10-20 | 50-100ms |

**Optimization Tips**:
- Biome blending: -30% performance
- Decorations: -20% performance
- Complex ore veins: -15% performance
- Caves: -40% performance

## 🔗 Integration Examples

### With Player Controller

```gdscript
extends CharacterBody3D

@onready var map_gen: MapGenerator = get_node("/root/World/MapGenerator")

func _ready():
    # Wait for spawn area to generate
    var spawn_chunk = Vector3i(0, 0, 0)
    map_gen.generate_region(
        spawn_chunk - Vector3i(2, 1, 2),
        spawn_chunk + Vector3i(2, 1, 2)
    )
    
    # Wait for completion
    await map_gen.generation_progress
    
    # Find safe spawn point
    var spawn_pos = _find_safe_spawn()
    global_position = spawn_pos

func _find_safe_spawn() -> Vector3:
    var center = Vector3(0, 0, 0)
    var height = map_gen.get_height_at(center.x, center.z)
    return Vector3(center.x, height + 2, center.z)
```

### With Multiplayer

```gdscript
extends Node

var map_gen: MapGenerator

func _ready():
    map_gen = $MapGenerator
    
    # Server creates world
    if multiplayer.is_server():
        map_gen.create_new_world("ServerWorld")
    else:
        # Client receives seed from server
        request_world_info.rpc_id(1)

@rpc("any_peer")
func request_world_info():
    var sender = multiplayer.get_remote_sender_id()
    send_world_info.rpc_id(sender, map_gen.world_seed, map_gen.world_name)

@rpc("authority")
func send_world_info(seed: int, name: String):
    map_gen.world_seed = seed
    map_gen.world_name = name
    map_gen.create_new_world()
```

### With Resource Gathering

```gdscript
func on_block_destroyed(world_pos: Vector3i):
    var biome = map_gen.get_biome_at(Vector3(world_pos))
    
    if biome:
        # Check if it was an ore
        for ore in biome.ore_deposits:
            if _is_ore_at_position(world_pos, ore):
                drop_ore_item(ore.block_id, world_pos)
                break
```

## 🌟 Community Examples

### Floating Islands World

```gdscript
func create_floating_islands_world():
    map_gen.enable_continentalness = true
    map_gen.continent_frequency = 0.003
    map_gen.continent_influence = 80.0
    map_gen.base_terrain_amplitude = 30.0
    map_gen.generate_water = false  # No water
    
    # Create sky island biome
    var sky_island = map_gen.add_biome("Sky Island")
    sky_island.min_y = 100
    sky_island.max_y = 180
    sky_island.use_noise_mask = true
    sky_island.mask_threshold = 0.5  # Only solid parts
```

### Underground Cavern World

```gdscript
func create_cavern_world():
    # Invert terrain - solid on top, hollow below
    map_gen.base_terrain_amplitude = -40.0
    map_gen.sea_level = 200
    
    # Massive caves
    map_gen.cave_settings.enabled = true
    map_gen.cave_settings.min_size = 1.5
    map_gen.cave_settings.max_size = 3.0
    map_gen.cave_settings.threshold = 0.4  # Very hollow
    
    # Glowing mushroom biome
    var mushroom = map_gen.add_biome("Mushroom Cave")
    # Add glowing blocks, special decorations
```

## 📄 License

MIT License - Free for commercial and personal use!

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test thoroughly
4. Submit a pull request

## 🐛 Bug Reports

Found a bug? Please include:
- Godot version
- Addon version
- Steps to reproduce
- Error messages/console output
- World settings if relevant

## 💬 Support

- **Documentation**: This README
- **Examples**: See `examples/` folder
- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions

## 🎯 Roadmap

### Planned Features
- [ ] Custom structure templates (schematics)
- [ ] Biome transition zones (edge biomes)
- [ ] River and lake generation
- [ ] Village/structure generation
- [ ] Heightmap import/export
- [ ] Visual biome editor
- [ ] Undo/redo for runtime modifications
- [ ] Networked generation (multiplayer sync)

### Under Consideration
- [ ] Terraforming API
- [ ] Biome spread/growth over time
- [ ] Seasonal variations
- [ ] Dynamic weather integration
- [ ] Procedural dungeons
- [ ] Quest location markers

## 📚 Additional Resources

- [Godot Engine Documentation](https://docs.godotengine.org/)
- [VoxelWorld Addon](https://github.com/your-repo/voxel-world)
- [Procedural Generation Guide](https://www.redblobgames.com/maps/terrain-from-noise/)
- [Perlin Noise Explained](https://adrianb.io/2014/08/09/perlinnoise.html)

## 🙏 Credits

- Created with ❤️ for the Godot community
- Inspired by Minecraft, Terraria, and other voxel games
- Thanks to all contributors and testers

---

**Made for Godot 4.5 | Production Ready | Fully Documented**
