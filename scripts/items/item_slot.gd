extends PanelContainer

class_name ItemSlot

@onready var slot_count: Label = $MarginContainer/SlotCount
@onready var item_display: NinePatchRect = $MarginContainer/ItemDisplay
@onready var highlight: ColorRect = $Highlight

@export var stored_item: Item = Item.new("", 0, 0)
@export var is_highlighted: bool = false
@export var background_visible: bool = true

signal item_changed
signal clicked(slot, button)

func _ready() -> void:
	if !background_visible:
		$SlotBackgroundDisplay.hide()
	update_item()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			print("---")
			print("Slot Clicked with button: " + str(event.button_index))
			emit_signal("clicked", self, event.button_index)
		update_item()


func use_item(amount: int):
	stored_item.item_count -= amount
	update_item()

func clear():
	stored_item.clear()
	update_item()

func swap_slots(other_slot: ItemSlot):
	var temp_item: Item = other_slot.stored_item
	other_slot.stored_item = stored_item
	stored_item = temp_item
	update_item()
	other_slot.update_item()

func update_item():
	if stored_item.item_count <= 0:
		stored_item.item_id = 0
	if stored_item.item_id != 0:
		slot_count.text = str(stored_item.item_count)
		slot_count.show()
		item_display.texture = BlockRegistry.get_block_from_id(stored_item.item_id).icon
		#print("Texture path: " + str(item_display.texture.resource_path))
		emit_signal("item_changed")
	else:
		item_display.texture = null
		stored_item.item_name = ""
		slot_count.hide()

func select():
	is_highlighted = true
	highlight.show()

func deselect():
	is_highlighted = false
	highlight.hide()

#end
