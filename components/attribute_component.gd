##A class that stores a base value and a list of modifers.  Statistics may also be referred to as Attributes
extends Component

class_name Statistic

##Acts as a name and identifier for this statistic
@export var id: String
##The base value of the statistic
@export var base: float
##The list of modifiers affecting the statistic
@export var modifiers: Array

##The type of operation preformed on an attribute
enum modifier_type {
	##Adds the value to the base value of the attribute.  Calculated before anything else [br]
	add_base,		#as an example if we start with 1 and add 0.7 we get 1.0 + 0.7 = 1.7
	##Multiplies the value into the base value of the attribute.  Calculated after [add_base]  [br]
	multiply_base,	#as an example if we multiply by 2.58 then we get (1.0 + 0.7) * 2.58 = 4.386
	##Adds the value of the modifer to the attribute after [add_base] and [multiply_base]  [br]
	add_total,		#as an example if we add 1.23 then we get (1.0 + 0.7) * 2.58 + 1.23 = 5.616
	##Multiplies into the value of the modifier after [add_base], [multiply_base], and [add_total]  [br]
	multiply_total,	#as an example if we multiply by 3.74 then we get ((1.0 + 0.7) * 2.58 + 1.23) * 3.74 = 21.00384
	##Adds to the value of the attribute once everything else has been calculated  [br]
	bonus,			#as an example if we add 1.5 then we get ((1.0 + 0.7) * 2.58 + 1.23) * 3.74 + 1.5 = 22.50384
}

##A modifer that changes the value of an attribute, it can be any float and operate with any of the 5 modifier types
class Modifier:
	##The id for targeting/identifying a modifier, 2 modifiers cannot have the same id
	var id: String
	##A list of tags that can also be used to target the modifier, they can be things like #armor, #debuff, or #temp
	var tags: Array[String]
	##The value of the modifier as a [float], depending on the operation it may have different affects
	var value: float
	##The type of operation performed on the statistic
	var operation: modifier_type
	
	func _init(ID: String, Value: float, Operation: modifier_type, TagList: Array[String] = []) -> void:
		id = ID
		tags = TagList
		value = Value
		operation = Operation


func _init(Name: String, Base: float, Modifiers: Array[Modifier] = []) -> void:
	id = Name
	base = Base
	modifiers = Modifiers

func add_modifier(modID: String, modVal: float, modOp: modifier_type, modTags: Array[String] = []):
	var mod: Modifier = Modifier.new(modID,modVal,modOp,modTags)
	modifiers.append(mod)

##Get a modfier from it's id
func get_modifier_from_id(modID: String):
	for i in range(modifiers.size()):
		var mod: Modifier = modifiers[i]
		if match_id(modID,mod.id):
			return modifiers[i]

##Get a modifier from one of it's tags
func get_modifier_from_tag(modTag: String):
	for i in range(modifiers.size()):
		var mod: Modifier = modifiers[i]
		var mtags: Array[String] = mod.tags
		if mtags.has(modTag):
			return modifiers[i]


func match_id(id1: String,id2: String):
	if id1.similarity(id2) == 1.0:
		return true

##Get the current value [b]NOT OPTIMIZED (fix that at some point)[/b]
func current_value() -> float:
	var val: float = base
	#add base
	for mod in modifiers: 
		if mod.operation == modifier_type.add_base:
			val += mod.value
	#multiply base
	for mod in modifiers:
		if mod.operation == modifier_type.multiply_base:
			val *= mod.value
	#add total
	for mod in modifiers:
		if mod.operation == modifier_type.add_total:
			val += mod.value
	#multiply total
	for mod in modifiers:
		if mod.operation == modifier_type.multiply_total:
			val *= mod.value
	#bonus
	for mod in modifiers:
		if mod.operation == modifier_type.bonus:
			val += mod.value
	return val
	
