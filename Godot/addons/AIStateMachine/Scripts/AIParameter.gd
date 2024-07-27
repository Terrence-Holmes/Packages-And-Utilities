extends Resource
class_name AIParameter

@export_category("AI Parameter")
@export var parameterName : String = "null"
@export var valueType : String = "Bool"
@export var valueBool : bool = false
@export var valueInt : int = 0
@export var valueFloat : float = 0.0
@export var valueString : String = "null"
@export var modifier : int = 0 #Used for int and float values to determine when the parameter is triggered. 0 = equals, 1 = more than, -1 = less than


var value:
	set(newVal):
		if (newVal is bool):
			valueBool = newVal
			valueType = "Bool"
		elif (newVal is int):
			valueInt = newVal
			valueType = "Int"
		elif (newVal is float):
			valueFloat = newVal
			valueType = "Float"
		elif (newVal is String):
			valueString = newVal
			valueType = "String"
	get:
		if (valueType == "Bool" || valueType == "Trigger"):
			return valueBool
		elif (valueType == "Int"):
			return valueInt
		elif (valueType == "Float"):
			return valueFloat
		elif (valueType == "String"):
			return valueString


var to_string : String:
	get:
		var valueString = str(value)
		if (value is int or value is float):
			match (modifier):
				(0):
					valueString = "=" + str(value)
				(1):
					valueString = ">" + str(value)
				(-1):
					valueString = "<" + str(value)
		return "Name: " + parameterName + ", Value: " + valueString
