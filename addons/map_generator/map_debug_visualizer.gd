@tool
extends Node3D
class_name MapDebugVisualizer

## Debug and visualization tool for MapGenerator

@export var map_generator: MapGenerator
@export_group("Visualization")
@export var show_biome_bounds: bool = false:
	set(value):
		show_biome_bounds = value
		queue_redraw_3d()
@export var show_chunk_grid: bool = false:
	set(value):
		show_chunk_grid = value
		queue_redraw_3d()
@export var show_height_map: bool = false:
	set(value):
		show_height_map = value
		_update_height_map()
@export var height_map_resolution: int = 64:
	set(value):
		height_map_resolution = clampi(value, 16, 256)
		if show_height_map:
			_update_height_map()

@export_group("Info Display")
@export var show_stats: bool = true
@export var update_interval: float = 0.5

var _immediate_mesh: ImmediateMesh
var _mesh_instance: MeshInstance3D
var _material: StandardMaterial3D
var _update_timer: float = 0.0
var _stats_label: Label
var _height_map_sprite: Sprite3D

func _ready():
	if Engine.is_editor_hint():
		return
	
	_setup_visualization()
	_setup_stats_display()

func _setup_visualization():
	_immediate_mesh = ImmediateMesh.new()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _immediate_mesh
	add_child(_mesh_instance)
	
	_material = StandardMaterial3D.new()
	_material.vertex_color_use_as_albedo = true
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mesh_instance.material_override = _material

func _setup_stats_display():
	if not show_stats:
		return
	
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	_stats_label = Label.new()
	_stats_label.position = Vector2(10, 10)
	_stats_label.add_theme_color_override("font_color", Color.WHITE)
	_stats_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_stats_label.add_theme_constant_override("shadow_offset_x", 1)
	_stats_label.add_theme_constant_override("shadow_offset_y", 1)
	canvas_layer.add_child(_stats_label)

func _process(delta):
	if Engine.is_editor_hint():
		return
	
	_update_timer += delta
	if _update_timer >= update_interval:
		_update_timer = 0.0
		_update_stats()
	
	if show_biome_bounds or show_chunk_grid:
		queue_redraw_3d()

func _update_stats():
	if not show_stats or not _stats_label or not map_generator:
		return
	
	var stats_text = "=== MAP GENERATOR STATS ===\n"
	stats_text += "World: %s\n" % map_generator.world_name
	stats_text += "Seed: %d\n" % map_generator.seed_value
	stats_text += "Generated Chunks: %d\n" % map_generator._generated_chunks.size()
	stats_text += "Biomes: %d\n" % map_generator.biomes.size()
	stats_text += "\n"
	
	if map_generator.biomes.size() > 0:
		stats_text += "=== BIOMES ===\n"
		for biome in map_generator.biomes:
			stats_text += "- %s (Priority: %.1f)\n" % [biome.biome_name, biome.priority_factor]
			stats_text += "  Blocks: %d\n" % biome.blocks.size()
	
	_stats_label.text = stats_text

func queue_redraw_3d():
	if Engine.is_editor_hint():
		return
	
	if not _immediate_mesh:
		return
	
	_immediate_mesh.clear_surfaces()
	
	if show_biome_bounds:
		_draw_biome_bounds()
	
	if show_chunk_grid:
		_draw_chunk_grid()

func _draw_biome_bounds():
	if not map_generator or map_generator.biomes.size() == 0:
		return
	
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for biome in map_generator.biomes:
		var color = biome.blend_color
		color.a = 0.6
		
		var min_x = biome.min_xz.x
		var max_x = biome.max_xz.x
		var min_z = biome.min_xz.y
		var max_z = biome.max_xz.y
		var min_y = float(biome.min_y)
		var max_y = float(biome.max_y)
		
		# Bottom rectangle
		_add_line(Vector3(min_x, min_y, min_z), Vector3(max_x, min_y, min_z), color)
		_add_line(Vector3(max_x, min_y, min_z), Vector3(max_x, min_y, max_z), color)
		_add_line(Vector3(max_x, min_y, max_z), Vector3(min_x, min_y, max_z), color)
		_add_line(Vector3(min_x, min_y, max_z), Vector3(min_x, min_y, min_z), color)
		
		# Top rectangle
		_add_line(Vector3(min_x, max_y, min_z), Vector3(max_x, max_y, min_z), color)
		_add_line(Vector3(max_x, max_y, min_z), Vector3(max_x, max_y, max_z), color)
		_add_line(Vector3(max_x, max_y, max_z), Vector3(min_x, max_y, max_z), color)
		_add_line(Vector3(min_x, max_y, max_z), Vector3(min_x, max_y, min_z), color)
		
		# Vertical lines
		_add_line(Vector3(min_x, min_y, min_z), Vector3(min_x, max_y, min_z), color)
		_add_line(Vector3(max_x, min_y, min_z), Vector3(max_x, max_y, min_z), color)
		_add_line(Vector3(max_x, min_y, max_z), Vector3(max_x, max_y, max_z), color)
		_add_line(Vector3(min_x, min_y, max_z), Vector3(min_x, max_y, max_z), color)
	
	_immediate_mesh.surface_end()

func _draw_chunk_grid():
	if not map_generator:
		return
	
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	var voxel_world = map_generator._voxel_world
	if not voxel_world:
		_immediate_mesh.surface_end()
		return
	
	var chunk_size = map_generator._get_chunk_size()
	var grid_color = Color(0.5, 0.5, 0.5, 0.3)
	var render_distance = 8
	
	for x in range(-render_distance, render_distance + 1):
		for z in range(-render_distance, render_distance + 1):
			var chunk_pos = Vector3i(x, 0, z)
			if map_generator.is_chunk_generated(chunk_pos):
				grid_color = Color(0.3, 1.0, 0.3, 0.5)
			else:
				grid_color = Color(0.5, 0.5, 0.5, 0.3)
			
			var world_pos = Vector3(
				x * chunk_size.x,
				0,
				z * chunk_size.z
			)
			
			var min_corner = world_pos
			var max_corner = world_pos + Vector3(chunk_size.x, 0, chunk_size.z)
			
			# Draw chunk boundary
			_add_line(min_corner, Vector3(max_corner.x, 0, min_corner.z), grid_color)
			_add_line(Vector3(max_corner.x, 0, min_corner.z), max_corner, grid_color)
			_add_line(max_corner, Vector3(min_corner.x, 0, max_corner.z), grid_color)
			_add_line(Vector3(min_corner.x, 0, max_corner.z), min_corner, grid_color)
	
	_immediate_mesh.surface_end()

func _add_line(from: Vector3, to: Vector3, color: Color):
	_immediate_mesh.surface_set_color(color)
	_immediate_mesh.surface_add_vertex(from)
	_immediate_mesh.surface_set_color(color)
	_immediate_mesh.surface_add_vertex(to)

func _update_height_map():
	if not show_height_map or not map_generator:
		if _height_map_sprite:
			_height_map_sprite.queue_free()
			_height_map_sprite = null
		return
	
	if not _height_map_sprite:
		_height_map_sprite = Sprite3D.new()
		_height_map_sprite.pixel_size = 1.0
		_height_map_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		_height_map_sprite.position = Vector3(0, 100, 0)
		_height_map_sprite.rotation_degrees = Vector3(-90, 0, 0)
		add_child(_height_map_sprite)
	
	var image = Image.create(height_map_resolution, height_map_resolution, false, Image.FORMAT_RGB8)
	var half_res = height_map_resolution / 2
	
	for x in range(height_map_resolution):
		for y in range(height_map_resolution):
			var world_x = (x - half_res) * 4
			var world_z = (y - half_res) * 4
			
			var height = map_generator._calculate_height(world_x, world_z)
			var normalized_height = clampf(float(height) / float(map_generator.world_limits_y.y), 0.0, 1.0)
			
			var color = Color(normalized_height, normalized_height, normalized_height)
			
			if map_generator.biomes.size() > 0:
				var biome = map_generator.get_biome_at_position(Vector3(world_x, 0, world_z))
				if biome:
					color = biome.blend_color
					color = color.lerp(Color.WHITE, normalized_height * 0.5)
			
			image.set_pixel(x, y, color)
	
	var texture = ImageTexture.create_from_image(image)
	_height_map_sprite.texture = texture

## Generate a 2D heightmap preview
func generate_heightmap_preview(size: int = 256) -> Image:
	if not map_generator:
		return null
	
	var image = Image.create(size, size, false, Image.FORMAT_RGB8)
	var half_size = size / 2
	
	for x in range(size):
		for y in range(size):
			var world_x = (x - half_size) * 2
			var world_z = (y - half_size) * 2
			
			var height = map_generator._calculate_height(world_x, world_z)
			var normalized = clampf(float(height) / 128.0, 0.0, 1.0)
			
			var color = Color(normalized, normalized, normalized)
			image.set_pixel(x, y, color)
	
	return image

## Export heightmap to PNG
func export_heightmap(path: String, size: int = 512):
	var image = generate_heightmap_preview(size)
	if image:
		image.save_png(path)
		print("Heightmap saved to: ", path)

## Print detailed biome info
func print_biome_info():
	if not map_generator:
		return
	
	print("\n=== BIOME INFORMATION ===")
	for i in range(map_generator.biomes.size()):
		var biome = map_generator.biomes[i]
		print("\nBiome #%d: %s" % [i, biome.biome_name])
		print("  Bounds XZ: (%.0f, %.0f) to (%.0f, %.0f)" % [
			biome.min_xz.x, biome.min_xz.y,
			biome.max_xz.x, biome.max_xz.y
		])
		print("  Bounds Y: %d to %d" % [biome.min_y, biome.max_y])
		print("  Priority: %.2f" % biome.priority_factor)
		print("  Noise Mask: %s" % ("Yes" if biome.use_noise_mask else "No"))
		print("  Blocks: %d" % biome.blocks.size())
		
		for block in biome.blocks:
			var ore_info = ""
			if block.is_rare_ore:
				ore_info = " (ORE: size=%d, rarity=%.3f)" % [block.cluster_size, block.rarity]
			print("    - Block %d: %s%s" % [block.block_id, block.block_name, ore_info])

## Test biome at specific position
func test_biome_at_position(world_pos: Vector3):
	if not map_generator:
		return
	
	var biome = map_generator.get_biome_at_position(world_pos)
	if biome:
		print("\nBiome at position %v: %s" % [world_pos, biome.biome_name])
		
		var influences = map_generator._calculate_biome_influence(world_pos)
		print("Biome influences:")
		for influence in influences:
			print("  - %s: %.2f%%" % [influence.biome.biome_name, influence.weight * 100.0])
	else:
		print("No biome found at position %v" % world_pos)
