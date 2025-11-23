extends CharacterBody3D

enum PlayerGamemode {
	Survival,
	Creative
}

@export var selected_position: Vector3
@export var gamemode: PlayerGamemode = PlayerGamemode.Survival

#cameras
@onready var first_person_camera: Camera3D = $FirstPersonCamera
@onready var third_person_camera: Camera3D = $FirstPersonCamera/ThirdPersonCamera
#interaction raycast (for placing, breaking, anc clicking blocks as well as hitting mobs)
@onready var interaction_raycast: RayCast3D = $FirstPersonCamera/InteractionRaycast
#ui stuff&things
@onready var hotbar: PanelContainer = $UI/Hotbar
@onready var health_bar: ProgressBar = $UI/HealthBar
@onready var inventory: PanelContainer = $UI/VBoxContainer/Inventory
@onready var info_panel: VBoxContainer = $UI/InfoPanel
@onready var mouse_item_display: MarginContainer = $UI/FloatingItem

var player_mass: float = 20.0

#stats
var max_health: Statistic
var current_health: float
var movement_speed: Statistic
var sprint_modifier: Statistic
var jump_strength: Statistic
var reach: Statistic

#all the little things
var sprint_timer: float = 0
var sprint_input_period: float = 15
var sprinting: bool = false
var FOV: float = 75.0
#var collision_friction: float = 0.025 #Unused: The amount you slow down per collision

enum Perspective {
	First,
	Third
}


const GRAVITY = Vector3(0.0, -25.0, 0.0)
const mouse_sensitivity = 0.9

var selected_perspective: Perspective = Perspective.First
var inventory_open: bool = false
var selected_item: Item
var selected_slot: int
var mouse_item = Item.new("", 0, 0)

func _ready() -> void:
	setup_stats()
	health_bar.health_attribute = max_health
	health_bar.health_value = current_health
	#sets the mouse in the center of the screen and hides it
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#makes the inventory invisible
	inventory.hide()
	display_mouse_item()

func setup_stats():
	movement_speed = Statistic.new("movement_speed", 5.0)
	sprint_modifier = Statistic.new("sprint_modifier", 1.3)
	jump_strength = Statistic.new("jump_strength", 8.0)
	max_health = Statistic.new("max_health", 10.0)
	current_health = max_health.current_value()
	reach = Statistic.new("reach", 5.0)

func _unhandled_input(event: InputEvent) -> void:
	if inventory_open:
		return
	if event is InputEventMouseMotion:
		# multiplied by 0.01 so it is scaled in a way that makes sense, otherwise we are converting from pixels to radians which is way too fast
		first_person_camera.rotation.y = first_person_camera.rotation.y - (event.relative.x * mouse_sensitivity * 0.01)
		first_person_camera.rotation.x = first_person_camera.rotation.x - (event.relative.y * mouse_sensitivity * 0.01)
		# TODO: Make z axis rotations possible with the scrollbar or something
		first_person_camera.rotation.x = clamp(first_person_camera.rotation.x, deg_to_rad(-85), deg_to_rad(85))
	pass

func get_empty_slot():
	##Cannot be typed, must support both a bool and an item slot
	var empty_slot = hotbar.get_empty_slot()
	if !empty_slot:
		empty_slot = inventory.get_empty_slot()
	return empty_slot

func get_valid_slot(item: Item):
	var valid_slot = hotbar.get_valid_slot(item)
	if !valid_slot:
		valid_slot = inventory.get_valid_slot(item)
	return valid_slot

func _physics_process(delta: float) -> void:
	selected_position = Vector3.ZERO
	update_ui()
	if Input.is_action_just_pressed("Switch Gamemode"):
		match gamemode:
			PlayerGamemode.Survival:
				gamemode = PlayerGamemode.Creative
			PlayerGamemode.Creative:
				gamemode = PlayerGamemode.Survival
	# Add the gravity.
	if !Input.is_action_pressed("Alternative Action Trigger"):
		if not is_on_floor():
			if gamemode == PlayerGamemode.Survival:
				velocity += GRAVITY * delta
	selected_item = hotbar.selected_item
	check_for_ui_inputs()
	if !inventory_open:
		match gamemode:
			PlayerGamemode.Survival:
				check_for_movement()
				check_for_perspective_change()
				check_for_interactions()
			PlayerGamemode.Creative:
				creative_movement()
				check_for_perspective_change()
				check_for_interactions()
	else:
		display_mouse_item()
	if gamemode == PlayerGamemode.Survival:
		_push_away_rigid_bodies()
		move_and_slide()
	else:
		position += velocity * delta

#got this off the internet
func _push_away_rigid_bodies():
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			var push_dir = -c.get_normal()
			# How much velocity the object needs to increase to match player velocity in the push direction
			var velocity_diff_in_push_dir = self.velocity.dot(push_dir) - c.get_collider().linear_velocity.dot(push_dir)
			# Only count velocity towards push dir, away from character
			velocity_diff_in_push_dir = max(0., velocity_diff_in_push_dir)
			# Objects with more mass than us should be harder to push. But doesn't really make sense to push faster than we are going
			var mass_ratio = min(1., player_mass / c.get_collider().mass)
			# Optional add: Don't push object at all if it's 4x heavier or more
			if mass_ratio < 0.1:
				continue
			# Don't push object from above/below
			push_dir.y = 0
			# 5.0 is a magic number, adjust to your needs
			var push_force = mass_ratio * 2.0
			c.get_collider().apply_impulse(push_dir * velocity_diff_in_push_dir * push_force, c.get_position() - c.get_collider().global_position)

func update_ui():
	info_panel.displayed_position = global_position
	info_panel.displayed_velocity = velocity

func check_for_ui_inputs():
	if !Input.is_action_pressed("Alternative Action Trigger"):
		if Input.is_action_just_pressed("Swap Offhand"):
			print("Attempting to swap offhands")
			var offhand: ItemSlot = inventory.offhand_slot
			var mainhand: ItemSlot = hotbar.get_selected_slot()
			if offhand.stored_item.item_id == 0:
				print("Offhand is empty")
				if mainhand.stored_item.item_id == 0:
					print("Mainhand is also empty, returning")
					return
				else:	
					print("Mainhand swapping to offhand")
					offhand.stored_item = mainhand.stored_item.copy()
					mainhand.clear()
					offhand.update_item()
					mainhand.update_item()
			elif mainhand.stored_item.item_id == 0:
				mainhand.stored_item = offhand.stored_item.copy()
				offhand.clear()
				offhand.update_item()
				mainhand.update_item()
			else:
				return
		if Input.is_action_just_pressed("Open Inventory"):
			# If the inventory is open, close it
			if inventory_open:
				inventory_open = false
				inventory.hide()
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			# If the inventory is not open, open it
			else:
				inventory_open = true
				inventory.show()
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			print("Is Inventory Open?: " + str(inventory_open))

func check_for_perspective_change():
	if Input.is_action_just_pressed("Change Perspective"):
		match selected_perspective:
			Perspective.First:
				selected_perspective = Perspective.Third
				first_person_camera.clear_current()
				third_person_camera.make_current()
			Perspective.Third:
				selected_perspective = Perspective.First
				third_person_camera.clear_current()
				first_person_camera.make_current()
	if sprinting:
		var fov_change: float = sprint_modifier.current_value()
		first_person_camera.fov = lerp(first_person_camera.fov, FOV * fov_change, 0.25)
		third_person_camera.fov = lerp(third_person_camera.fov, FOV * fov_change, 0.25)
	else:
		first_person_camera.fov = lerp(first_person_camera.fov, FOV, 0.25)
		third_person_camera.fov = lerp(third_person_camera.fov, FOV, 0.25)

func check_for_movement():
	# Handle jump.
	if Input.is_action_pressed("Jump") and is_on_floor():
		velocity.y = jump_strength.current_value()
	# Handle Sprinting
	sprint_timer -= 1.0
	if Input.is_action_just_pressed("Move Foward"):
		if sprint_timer > 0:
			sprinting = true
		else:
			sprint_timer = sprint_input_period
	elif !Input.is_action_pressed("Move Foward"):
		sprinting = false
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("Move Left", "Move Right", "Move Foward", "Move Backward")
	var direction := (first_person_camera.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction.x *= abs(direction.y)
	direction.z *= abs(direction.y)
	direction.y = 0
	direction = direction.normalized()
	var SPEED: float = movement_speed.current_value()
	if sprinting:
		SPEED *= sprint_modifier.current_value()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func creative_movement():
	velocity *= 0.9
	if Input.is_action_pressed("Jump"):
		velocity.y = 10
	if Input.is_action_pressed("Crouch"):
		velocity.y = -10
	# Handle Sprinting
	sprint_timer -= 1.0
	if Input.is_action_just_pressed("Move Foward"):
		if sprint_timer > 0:
			sprinting = true
		else:
			sprint_timer = sprint_input_period
	elif !Input.is_action_pressed("Move Foward"):
		sprinting = false
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("Move Left", "Move Right", "Move Foward", "Move Backward")
	var direction := (first_person_camera.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction.x *= abs(direction.y)
	direction.z *= abs(direction.y)
	direction.y = 0
	direction = direction.normalized()
	var SPEED: float = 10.0
	if sprinting:
		SPEED *= 3.0
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func check_for_interactions():
	interaction_raycast.target_position.z = -1 * reach.current_value()
	if interaction_raycast.is_colliding():
		var hit_object: Node3D = interaction_raycast.get_collider()
		if hit_object != null:
			if hit_object.has_method("destroy_block"):
				selected_position = interaction_raycast.get_collision_point() - (interaction_raycast.get_collision_normal() * 0.1)
			else:
				selected_position = Vector3.ZERO
		check_for_pickup(hit_object)
		check_for_block_interaction(hit_object)

func check_for_pickup(hit_object: Node3D):
	if Input.is_action_just_pressed("Pick Up"):
		if hit_object == null:
			return
		if hit_object.has_method("pick_up"):
			##Cannot be typed, must support both a bool and an item slot
			var valid_slot = get_valid_slot(hit_object.item)
			if valid_slot is bool:
				return
			hit_object.pick_up(valid_slot)
			interaction_raycast.force_raycast_update()

func check_for_block_interaction(hit_object: Node3D):
	if hit_object == null:
		return
	# check for breaking blocks
	if Input.is_action_just_pressed("Left Click"):
		if hit_object.has_method("destroy_block"):
			#subtract the collision normal for breaking blocks
			var destroy_position: Vector3 = interaction_raycast.get_collision_point() - (interaction_raycast.get_collision_normal() * 0.2)
			hit_object.destroy_block(destroy_position)
			interaction_raycast.force_raycast_update()
	# check for placing blocks
	if Input.is_action_just_pressed("Right Click"):
		if selected_item.item_count > 0:
			if hit_object.has_method("place_block"):
				#add the collision normal for placing blocks
				var place_position: Vector3 = interaction_raycast.get_collision_point() + (interaction_raycast.get_collision_normal() * 0.2)
				place_block(place_position, hit_object)
				interaction_raycast.force_raycast_update()

func display_mouse_item():
	if inventory_open and mouse_item.item_id != 0:
		mouse_item_display.stored_item = mouse_item
		mouse_item_display.set_item(mouse_item)
	else:
		mouse_item_display.hide()

func place_block(place_position: Vector3, gridmap: GridMap):
	gridmap.place_block(place_position, selected_item.item_id)
	hotbar.selected_slot.use_item(1)

func _on_hotbar_selected_item_changed() -> void:
	selected_item = $UI/Hotbar.selected_item

func _on_hotbar_slot_clicked(slot: ItemSlot, button: MouseButton) -> void:
	if button == MOUSE_BUTTON_LEFT:
		# If the slot is empty
		if slot.stored_item.item_id == 0:
			print("Slot Empty")
			#if the mouse has NO items in it then put the mouse items in the slot
			if mouse_item.item_count > 0:
				slot.stored_item = mouse_item.copy()
				#slot.update_item()
				print("Depositing mouse item (" + str(slot.stored_item) + ") into slot")
				mouse_item = Item.new("", 0, 0)
		#If the slot is not empty and the mouse has nothing in it 
		elif slot.stored_item.item_id == mouse_item.item_id:
			slot.stored_item.item_count += mouse_item.item_count
			mouse_item.clear()
		elif mouse_item.item_id == 0:
			print("Mouse Empty")
			#set the mouse item as the slots stored item
			mouse_item = slot.stored_item.copy()
			print("Set Mouse Item to: " + mouse_item.as_string())
			#clear the slot
			slot.clear()
			#hotbar.update_slots()
			print("Cleared slot, Mouse full with: " + mouse_item.as_string())
		else:
			print("Mouse Item Occupied")
		print("Mouse item: " + mouse_item.as_string())

func _on_inventory_slot_clicked(slot: Variant, button: Variant) -> void:
	if button == MOUSE_BUTTON_LEFT:
		# If the slot is empty
		if slot.stored_item.item_id == 0:
			print("Slot Empty")
			#if the mouse has NO items in it then put the mouse items in the slot
			if mouse_item.item_count > 0:
				slot.stored_item = mouse_item.copy()
				#slot.update_item()
				print("Depositing mouse item (" + str(slot.stored_item) + ") into slot")
				mouse_item = Item.new("", 0, 0)
		#If the slot is not empty and the mouse has nothing in it 
		elif mouse_item.item_id == 0:
			print("Mouse Empty")
			#set the mouse item as the slots stored item
			mouse_item = slot.stored_item.copy()
			print("Set Mouse Item to: " + mouse_item.as_string())
			#clear the slot
			slot.clear()
			#hotbar.update_slots()
			print("Cleared slot, Mouse full with: " + mouse_item.as_string())
		else:
			print("Mouse Item Occupied")
		print("Mouse item: " + mouse_item.as_string())
