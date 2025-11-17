extends PanelContainer

@onready var hotbar_slot_container: HBoxContainer = $HotbarSlotContainer
#slots
@export var item_slot_1: ItemSlot
@export var item_slot_2: ItemSlot
@export var item_slot_3: ItemSlot
@export var item_slot_4: ItemSlot
@export var item_slot_5: ItemSlot
@export var item_slot_6: ItemSlot
@export var item_slot_7: ItemSlot
@export var item_slot_8: ItemSlot
@export var item_slot_9: ItemSlot


##made this one based instead of zero based, may get annoying but I think it's worth it
@export var selected_slot_index: int = 1
@export var selected_item: Item
@export var hotbar_full: bool = false

#WARNING: INCREDIBLY SCUFFED CODE
var scroll_up: bool = false
var scroll_down: bool = false

@onready var selected_slot: PanelContainer = $HotbarSlotContainer/ItemSlot1

signal selected_item_changed
signal slot_clicked(slot, button)

func _ready() -> void: 
	setup_slots()
	var test = Item_stone.new(34)
	item_slot_1.stored_item = test
	item_slot_1.update_item()
	set_selected_slot(1)

func setup_slots():
	item_slot_1 = $HotbarSlotContainer/ItemSlot1
	item_slot_1.connect("item_changed", update_selected_item)
	item_slot_1.connect("clicked", hotbar_slot_clicked)
	item_slot_2 = $HotbarSlotContainer/ItemSlot2
	item_slot_2.connect("item_changed", update_selected_item)
	item_slot_2.connect("clicked", hotbar_slot_clicked)
	item_slot_3 = $HotbarSlotContainer/ItemSlot3
	item_slot_3.connect("item_changed", update_selected_item)
	item_slot_3.connect("clicked", hotbar_slot_clicked)
	item_slot_4 = $HotbarSlotContainer/ItemSlot4
	item_slot_4.connect("item_changed", update_selected_item)
	item_slot_4.connect("clicked", hotbar_slot_clicked)
	item_slot_5 = $HotbarSlotContainer/ItemSlot5
	item_slot_5.connect("item_changed", update_selected_item)
	item_slot_5.connect("clicked", hotbar_slot_clicked)
	item_slot_6 = $HotbarSlotContainer/ItemSlot6
	item_slot_6.connect("item_changed", update_selected_item)
	item_slot_6.connect("clicked", hotbar_slot_clicked)
	item_slot_7 = $HotbarSlotContainer/ItemSlot7
	item_slot_7.connect("item_changed", update_selected_item)
	item_slot_7.connect("clicked", hotbar_slot_clicked)
	item_slot_8 = $HotbarSlotContainer/ItemSlot8
	item_slot_8.connect("item_changed", update_selected_item)
	item_slot_8.connect("clicked", hotbar_slot_clicked)
	item_slot_9 = $HotbarSlotContainer/ItemSlot9
	item_slot_9.connect("item_changed", update_selected_item)
	item_slot_9.connect("clicked", hotbar_slot_clicked)

func _process(_delta: float) -> void:
	if scroll_down:
		shift_selection(-1)
		scroll_down = false
	elif scroll_up:
		shift_selection(1)
		scroll_up = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_down = true
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_up = true

func shift_selection(change: int):
	var new_selected_slot: int = selected_slot_index + change
	if new_selected_slot > 9:
		new_selected_slot -= 9
	elif new_selected_slot < 1:
		new_selected_slot += 9
	set_selected_slot(new_selected_slot)
	#print("Selected slot " + str(selected_slot_index))

func set_selected_slot(new_slot: int):
	#remove the highlight
	selected_slot.deselect()
	selected_slot_index = new_slot
	selected_slot = hotbar_slot_container.get_children()[selected_slot_index-1]
	selected_item = selected_slot.stored_item
	#add the highlight to the next slot
	selected_slot.select()

func update_selected_item():
	selected_item = selected_slot.stored_item
	emit_signal("selected_item_changed")
	if get_empty_slot() is bool:
		hotbar_full = true
	else:
		hotbar_full = false

func get_empty_slot():
	for i in range(9):
		var slot: ItemSlot = get_node("HotbarSlotContainer/ItemSlot" + str(i+1))
		if slot.stored_item.item_id == 0:
			return slot
	return false

func get_valid_slot(item: Item):
	for i in range(9):
		var slot: ItemSlot = get_node("HotbarSlotContainer/ItemSlot" + str(i+1))
		if slot.stored_item.item_id == 0 or slot.stored_item.item_id == item.item_id:
			return slot
	return false

func hotbar_slot_clicked(slot: ItemSlot, button: MouseButton):
	print("Hotbar Slot Clicked")
	emit_signal("slot_clicked", slot, button)

func set_slot_item(slot_index: int, item: Item):
	var target_slot = hotbar_slot_container.get_children()[slot_index-1]
	target_slot.stored_item = item
	target_slot.update_item()

func update_slots():
	for i in range(9):
		var slot: ItemSlot = get_node("HotbarSlotContainer/ItemSlot" + str(i+1))
		slot.update_item()

#end
