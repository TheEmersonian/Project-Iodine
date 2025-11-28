extends RigidBody3D

class_name DroppedItem

@export var item: Item

var sprite: Sprite3D
var model: MeshInstance3D
var collisionshape: CollisionShape3D
var area: Area3D

func _ready() -> void:
	update_visual()

#bad code ik lol
func _init(dropped_item: Item) -> void:
	item = dropped_item
	sprite = Sprite3D.new()
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	add_child(sprite)
	
	collisionshape = CollisionShape3D.new()
	collisionshape.shape = BoxShape3D.new()
	collisionshape.shape.size = Vector3(0.5, 0.5, 0.5)
	add_child(collisionshape)
	
	model = MeshInstance3D.new()
	model.scale = Vector3.ONE * 0.5
	add_child(model)
	
	area = Area3D.new()
	add_child(area)
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.shape.radius = 1.0
	area.add_child(shape)
	
	update_mass()

func give_random_jump():
	apply_impulse(Vector3(randf_range(-2,2), randf_range(1,3), randf_range(-2,2)), Vector3(randf_range(-10,10), randf_range(-1,1), randf_range(-1,1)))
	angular_velocity = Vector3(randf_range(-20,20), randf_range(-20,20), randf_range(-20,20))

func _physics_process(_delta: float) -> void:
	if is_queued_for_deletion():
		return
	if Engine.get_physics_frames() % item.item_count == 0:
		if randf() > 0.1/item.item_count:
			return
		var bodies = area.get_overlapping_bodies()
		for b in bodies:
			if b != self:
				if b is DroppedItem:
					if b.item.item_id == item.item_id:
						merge_items(b)
						break

func merge_items(dropped_item: DroppedItem):
	var a_count: int = item.item_count
	var b_count: int = dropped_item.item.item_count
	var total_items: int = a_count + b_count
	item.item_count = total_items
	#var a_weight: float = a_count / float(total_items)
	var b_weight: float = b_count / float(total_items)
	var new_position: Vector3 = lerp(position, dropped_item.position, b_weight)
	position = new_position
	dropped_item.queue_free()
	sleeping = false
	update_mass()

func update_mass():
	mass = ItemProcesser.item_to_mass(item.item_name) * item.item_count

func set_item(new_item: Item):
	item = new_item
	update_visual()

func pick_up(slot: ItemSlot):
	if slot.stored_item.item_id == 0:
		slot.stored_item = item
	elif slot.stored_item.item_id == item.item_id:
		slot.stored_item.item_count += item.item_count
	else:
		print("Invalid slot")
	slot.update_item()
	queue_free()

func despawn():
	queue_free()

func update_visual():
	if item.item_id > 0:
		sprite.hide()
		model.show()
		model.mesh = BlockRegistry.get_block_from_id(item.item_id).model
	else:
		sprite.show()
		model.hide()
		sprite.texture = BlockRegistry.get_block_from_id(item.item_id).icon
