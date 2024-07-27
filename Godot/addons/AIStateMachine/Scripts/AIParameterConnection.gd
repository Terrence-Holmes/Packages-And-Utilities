
@tool
extends Panel
#References
var root : Control = null
@onready var parameterContainer : HBoxContainer = get_node("ParameterContainer")
@onready var parameterNameLabel : Label = parameterContainer.get_node("ParameterName")
@onready var parameterValueContainer : Control = parameterContainer.get_node("ParameterValue")
@onready var valueTrigger : Label = parameterValueContainer.get_node("ValueTrigger")
@onready var valueBool : CheckBox = parameterValueContainer.get_node("ValueBool")
@onready var valueIntLabel : Label = parameterValueContainer.get_node("ValueInt")
@onready var valueInt : LineEdit = valueIntLabel.get_node("IntField")
@onready var valueFloatLabel : Label = parameterValueContainer.get_node("ValueFloat")
@onready var valueFloat : LineEdit = valueFloatLabel.get_node("FloatField")
@onready var valueString : LineEdit = parameterValueContainer.get_node("ValueString")
@onready var loadButton : MenuButton = get_node("LoadButton")
@onready var deleteButton : Button = get_node("Delete")
@onready var intOperatorLabel : Label = valueIntLabel.get_node("IntOperator/OperatorLabel")
@onready var floatOperatorLabel : Label = valueFloatLabel.get_node("FloatOperator/OperatorLabel")

var valueOwner : Control = null

var markedForDelete : bool = false

var parameterName : String:
	get:
		return parameterNameLabel.text
var valueType : String:
	get:
		var returnString : String = "null"
		if (valueTrigger.visible):
			returnString = "Trigger"
		elif (valueBool.visible):
			returnString = "Bool"
		elif (valueIntLabel.visible):
			returnString = "Int"
		elif (valueFloatLabel.visible):
			returnString = "Float"
		elif (valueString.visible):
			returnString = "String"
		return returnString
var value:
	get:
		match (valueType):
			("Trigger"):
				return true
			("Bool"):
				return valueBool.button_pressed
			("Int"):
				return valueInt.text.to_int()
			("Float"):
				return valueFloat.text.to_float()
			("String"):
				return valueString.text
	set(val):
		match (valueType):
			("Bool"):
				valueBool.button_pressed = val
			("Int"):
				valueInt.text = str(val)
				set_operator_labels()
			("Float"):
				valueFloat.text = str(val)
				set_operator_labels()
			("String"):
				valueString.text = val

var modifier : int = 0

func _ready():
	loadButton.get_popup().connect("id_pressed", choose_type)


func _input(event):
	#Unfocus on click
	if (event is InputEventMouseButton and event.pressed):
		unfocus()

func choose_type(param : int):
	set_values(root.parameterContainer.get_child(param))

func set_values(param : Control = valueOwner, updateConnectionParameters : bool = true):
	if (param == null):
		queue_free()
		root.update_connection_parameters(updateConnectionParameters)
		return
	valueOwner = param
	#Set name
	parameterNameLabel.text = param.parameterName
	#Reset value if value type was changed
	if (valueType != param.valueType):
		#Reset values
		valueBool.button_pressed = false
		valueInt.text = "0"
		valueFloat.text = "0"
		valueString.text = ""
	#Set value type
	valueTrigger.visible = false
	valueBool.visible = false
	valueIntLabel.visible = false
	valueFloatLabel.visible = false
	valueString.visible = false
	match (param.valueType):
		("Trigger"):
			valueTrigger.visible = true
		("Bool"):
			valueBool.visible = true
		("Int"):
			valueIntLabel.visible = true
			set_operator_labels()
		("Float"):
			valueFloatLabel.visible = true
			set_operator_labels()
		("String"):
			valueString.visible = true


func unfocus():
	if (root != null and root.focusNode != null):
		#Choose to ignore if focusNode is not part of paramters
		var ignore : bool = (root.focusNode != valueInt
		and root.focusNode != valueFloat and root.focusNode != valueString)
		#Set text if focus is a text field
		if (root.focusNode is LineEdit and not ignore):
			match (root.focusNode):
				(valueInt):
					_int_value_changed(root.focusNode.text)
				(valueFloat):
					_float_value_changed(root.focusNode.text)
			#Release focus
			root.focusNode.release_focus()
			root.focusNode = null
			root.update_connection_parameters()


#OPERATORS
func set_operator_labels():
	match (modifier):
		(0):
			intOperatorLabel.text = "="
			floatOperatorLabel.text = "="
		(1):
			intOperatorLabel.text = ">"
			floatOperatorLabel.text = ">"
		(-1):
			intOperatorLabel.text = "<"
			floatOperatorLabel.text = "<"


#BUTTONS

func _int_value_focus():
	if (root != null):
		root.focusNode = valueInt
		root.lastSubmittedText = root.focusNode.text

func _int_value_changed(newString : String):
	if (root != null):
		var realString : String = str(newString.to_int())
		if (realString.length() == 0):
			realString = root.lastSubmittedText
		valueInt.text = realString
		root.lastSubmittedText = realString
		root.update_connection_parameters()


func _float_value_focus():
	if (root != null):
		root.focusNode = valueFloat
		root.lastSubmittedText = root.focusNode.text

func _float_value_changed(newString : String):
	if (root != null):
		var realString : String = str(newString.to_float())
		if (realString.length() == 0):
			realString = root.lastSubmittedText
		valueFloat.text = realString
		root.lastSubmittedText = realString
		root.update_connection_parameters()


func _string_value_focus():
	if (root != null):
		root.focusNode = valueString
		root.lastSubmittedText = root.focusNode.text


func _bool_value_changed():
	root.update_connection_parameters()

func _load_button_pressed():
	root.set_type_button(loadButton)


func _operator_pressed():
	match (modifier):
		(0):
			modifier = 1
		(1):
			modifier = -1
		(-1):
			modifier = 0
	set_operator_labels()
	root.update_connection_parameters()


func _remove_pressed():
	if (root != null):
		deleteButton.disabled = true
		root.prepare_to_remove(self)
