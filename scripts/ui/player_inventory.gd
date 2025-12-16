extends Control

@onready var main_inventory_margin: MarginContainer = $MainInventoryMargin
@onready var main_inventory_container: HBoxContainer = $MainInventoryMargin/MainInventoryContainer
@onready var hotbar: PanelContainer = $MainInventoryMargin/MainInventoryContainer/Hotbar
@onready var hotbar_slot_container: VBoxContainer = $MainInventoryMargin/MainInventoryContainer/Hotbar/HotbarSlotContainer
@onready var hotbar_slot_1: ItemSlot = $MainInventoryMargin/MainInventoryContainer/Hotbar/HotbarSlotContainer/HotbarSlot1
@onready var hotbar_slot_2: ItemSlot = $MainInventoryMargin/MainInventoryContainer/Hotbar/HotbarSlotContainer/HotbarSlot2
@onready var hotbar_slot_3: ItemSlot = $MainInventoryMargin/MainInventoryContainer/Hotbar/HotbarSlotContainer/HotbarSlot3
@onready var hotbar_slot_4: ItemSlot = $MainInventoryMargin/MainInventoryContainer/Hotbar/HotbarSlotContainer/HotbarSlot4
@onready var hotbar_slot_5: ItemSlot = $MainInventoryMargin/MainInventoryContainer/Hotbar/HotbarSlotContainer/HotbarSlot5
@onready var hotbar_slot_6: ItemSlot = $MainInventoryMargin/MainInventoryContainer/Hotbar/HotbarSlotContainer/HotbarSlot6
@onready var hotbar_slot_7: ItemSlot = $MainInventoryMargin/MainInventoryContainer/Hotbar/HotbarSlotContainer/HotbarSlot7
@onready var inventory: PanelContainer = $MainInventoryMargin/MainInventoryContainer/Inventory
@onready var h_box_container: HBoxContainer = $MainInventoryMargin/MainInventoryContainer/Inventory/HBoxContainer
@onready var crafting_center_container: CenterContainer = $MainInventoryMargin/MainInventoryContainer/CraftingCenterContainer
@onready var crafting_grid_container: PanelContainer = $MainInventoryMargin/MainInventoryContainer/CraftingCenterContainer/CraftingGridContainer
@onready var crafting_slot_container: GridContainer = $MainInventoryMargin/MainInventoryContainer/CraftingCenterContainer/CraftingGridContainer/CraftingSlotContainer
@onready var conditions_margin: MarginContainer = $ConditionsMargin
@onready var conditions_container: PanelContainer = $ConditionsMargin/ConditionsContainer
@onready var margin_container: MarginContainer = $ConditionsMargin/ConditionsContainer/MarginContainer
@onready var v_box_container: VBoxContainer = $ConditionsMargin/ConditionsContainer/MarginContainer/VBoxContainer
@onready var conditions_title: Label = $ConditionsMargin/ConditionsContainer/MarginContainer/VBoxContainer/ConditionsTitle
@onready var health: Label = $ConditionsMargin/ConditionsContainer/MarginContainer/VBoxContainer/Health
@onready var mana: Label = $ConditionsMargin/ConditionsContainer/MarginContainer/VBoxContainer/Mana
@onready var weight: Label = $ConditionsMargin/ConditionsContainer/MarginContainer/VBoxContainer/Weight
@onready var energy: Label = $ConditionsMargin/ConditionsContainer/MarginContainer/VBoxContainer/Energy


@export var mainhand_slot_index: int = 1
@export var offhand_slot_index: int = 7


func get_selected_item():
	var mainhand_item: Item = get_hotbar_slot_from_index(mainhand_slot_index).stored_item
	if mainhand_item.item_id != 0:
		return mainhand_item
	var offhand_item: Item = get_hotbar_slot_from_index(offhand_slot_index).stored_item
	if offhand_item.item_id != 0:
		return mainhand_item
	

##Utility
func hide_main_inventory():
	inventory.hide()
	crafting_center_container.hide()
	conditions_margin.hide()
func show_main_inventory():
	inventory.show()
	crafting_center_container.show()
	conditions_margin.show()
func get_hotbar_slot_from_index(index: int):
	if !range(1,8).has(index):
		print("Attempted to access invalid hotbar index")
		return
	return get_node("%HotbarSlot" + str(index))
func get_inventory_slot_from_index(index: int):
	if !range(1,29).has(index):
		print("Attemped to access invalid inventory index")
		return
	return get_node("%InventorySlot" + str(index))
func get_inventory_slot_from_pos(pos: Vector2i):
	if not pos > Vector2i.ZERO and not pos < Vector2i(5, 8):
		print("Attempted to access invalid inventory position")
		return
	return get_hotbar_slot_from_index(pos.x * 4 + pos.y * 7)



















#end
