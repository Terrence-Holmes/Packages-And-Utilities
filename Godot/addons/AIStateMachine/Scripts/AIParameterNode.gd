
@tool
extends Panel
#References
var root : Control = null
@onready var parameterContainer : HBoxContainer = get_node("ParameterContainer")
@onready var parameterNameEdit : LineEdit = parameterContainer.get_node("ParameterNameContainer/ParameterName")
@onready var parameterValueContainer : Control = parameterContainer.get_node("ParameterValue")
@onready var valueTrigger : Label = parameterValueContainer.get_node("ValueTrigger")
@onready var valueBool : Label = parameterValueContainer.get_node("ValueBool")
@onready var valueInt : Label = parameterValueContainer.get_node("ValueInt")
@onready var valueFloat : Label = parameterValueContainer.get_node("ValueFloat")
@onready var valueString : Label = parameterValueContainer.get_node("ValueString")
@onready var valueTypeButton : MenuButton = get_node("ValueType")
@onready var deleteButton : Button = get_node("Delete")

var markedForDelete : bool = false
var parameterName : String:
	get:
		return parameterNameEdit.text
	set(value):
		parameterNameEdit.text = value

var valueType : String:
	get:
		var returnString : String = "null"
		if (valueTrigger.visible):
			returnString = "Trigger"
		elif (valueBool.visible):
			returnString = "Bool"
		elif (valueInt.visible):
			returnString = "Int"
		elif (valueFloat.visible):
			returnString = "Float"
		elif (valueString.visible):
			returnString = "String"
		return returnString


func _ready():
	valueTypeButton.get_popup().connect("id_pressed", choose_type)



func _input(event):
	#Unfocus on click
	if (event is InputEventMouseButton and event.pressed):
		unfocus()


func choose_type(id : int):
	#Disable all value setters
	valueTrigger.visible = false
	valueBool.visible = false
	valueInt.visible = false
	valueFloat.visible = false
	valueString.visible = false
	#Enable the correct value setter
	match (id):
		0:
			valueTrigger.visible = true
		1:
			valueBool.visible = true
		2:
			valueInt.visible = true
		3:
			valueFloat.visible = true
		4:
			valueString.visible = true
	root.update_all_parameters()


func unfocus():
	if (root != null and root.focusNode != null):
		#Choose to ignore if focusNode is not part of paramters
		if (root.focusNode != parameterNameEdit):
			return
		_set_parameter_name(parameterNameEdit.text)
		#Release focus
		root.focusNode.release_focus()
		root.focusNode = null


func _parameter_name_focus():
	if (root != null):
		root.focusNode = parameterNameEdit
		root.lastSubmittedText = root.focusNode.text

func _set_parameter_name(newName : String):
	if (root != null):
		var lastName : String = parameterNameEdit.text
		var realName : String = newName if (newName.length() > 0) else (root.lastSubmittedText)
		parameterNameEdit.text = realName
		root.lastSubmittedText = realName
		root.update_all_parameters()
		
		#TODO: Fix this ffs
		#If the name of a parameter is changed, update the reference in this node
		for node in root.connectionNodes:
			for param in node.parameters:
				if (param.parameterName == lastName):
					param.parameterName = realName


func _remove_pressed():
	if (root != null):
		deleteButton.disabled = true
		root.prepare_to_remove(self)
