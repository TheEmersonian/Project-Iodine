extends ProgressBar

@export var health_attribute: Statistic
@export var health_value: float

func _process(_delta: float) -> void:
	if health_attribute is Statistic:
		max_value = health_attribute.current_value()
	if health_value is float:
		value = health_value
	
	
	
