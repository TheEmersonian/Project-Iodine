extends PanelContainer

@onready var inventory_slot_container: GridContainer = $VBoxContainer/InventorySlotContainer

@export var head_slot: EquipmentSlot
@export var chest_slot: EquipmentSlot
@export var legs_slot: EquipmentSlot
@export var feet_slot: EquipmentSlot

@export var neck_slot: EquipmentSlot
@export var back_slot: EquipmentSlot
@export var waist_slot: EquipmentSlot
@export var ankle_slot: EquipmentSlot

@export var offhand_slot: ItemSlot

signal slot_clicked(slot, button)

func _ready() -> void:
	setup_slots()

func setup_slots():
	for i in range(inventory_slot_container.get_child_count()):
		var slot: ItemSlot = get_node("VBoxContainer/InventorySlotContainer/ItemSlot" + str(1+i))
		slot.connect("clicked", inventory_slot_clicked)
	head_slot = $VBoxContainer/HBoxContainer/EquipmentContainer1/HeadSlot
	head_slot.connect("clicked", inventory_slot_clicked)
	chest_slot = $VBoxContainer/HBoxContainer/EquipmentContainer1/ChestSlot
	chest_slot.connect("clicked", inventory_slot_clicked)
	legs_slot = $VBoxContainer/HBoxContainer/EquipmentContainer1/LegsSlot
	legs_slot.connect("clicked", inventory_slot_clicked)
	feet_slot = $VBoxContainer/HBoxContainer/EquipmentContainer1/FeetSlot
	feet_slot.connect("clicked", inventory_slot_clicked)
	
	neck_slot = $VBoxContainer/HBoxContainer/EquipmentContainer2/NeckSlot
	neck_slot.connect("clicked", inventory_slot_clicked)
	back_slot = $VBoxContainer/HBoxContainer/EquipmentContainer2/BackSlot
	back_slot.connect("clicked", inventory_slot_clicked)
	waist_slot = $VBoxContainer/HBoxContainer/EquipmentContainer2/WaistSlot
	waist_slot.connect("clicked", inventory_slot_clicked)
	ankle_slot = $VBoxContainer/HBoxContainer/EquipmentContainer2/AnkleSlot
	ankle_slot.connect("clicked", inventory_slot_clicked)
	
	offhand_slot = $VBoxContainer/HBoxContainer/VBoxContainer/OffHand
	offhand_slot.connect("clicked", inventory_slot_clicked)

func get_empty_slot():
	for i in range(get_child_count()):
		var slot: ItemSlot = get_node("InventorySlotContainer/ItemSlot" + str(i+1))
		if slot.stored_item.item_id == 0:
			return slot
	return false

func get_valid_slot(item: Item):
	for i in range(get_child_count()):
		var slot: ItemSlot = get_node("InventorySlotContainer/ItemSlot" + str(i+1))
		if slot.stored_item.item_id == 0 or slot.stored_item.item_id == item.item_id:
			return slot
	return false

func inventory_slot_clicked(slot: ItemSlot, button: MouseButton):
	print("Inventory Slot Clicked")
	emit_signal("slot_clicked", slot, button)



#end
