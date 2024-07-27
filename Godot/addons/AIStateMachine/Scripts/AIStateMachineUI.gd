@tool
extends Control

#References
@onready var mainScroll : ScrollContainer = get_node("MainScroll")
@onready var mainHBox : HBoxContainer = mainScroll.get_node("MainHBox")
@onready var statePanel : Panel = mainHBox.get_node("StatePanel")
@onready var stateScroll : ScrollContainer = statePanel.get_node("StateScroll")
@onready var expandButton : Button = stateScroll.get_node("VBox/ExpandAndCollapse/ExpandButton")
@onready var collapseButton : Button = stateScroll.get_node("VBox/ExpandAndCollapse/CollapseButton")
@onready var stateContainer : Container = stateScroll.get_node("VBox/StateContainer")
@onready var prepareDelete : MenuButton = get_node("PrepareDelete")
#Parameters
@onready var parameterPanel : Panel = mainHBox.get_node("ParametersPanel")
@onready var parameterScroll : ScrollContainer = parameterPanel.get_node("ParametersScroll")
@onready var createParameterButton : Button = parameterScroll.get_node("VBox/CreateButton")
@onready var parameterContainer : VBoxContainer = parameterScroll.get_node("VBox/ParameterContainer")
#State properties
@onready var propertiesPanel : Panel = mainHBox.get_node("PropertiesPanel")
@onready var propertiesScroll : ScrollContainer = propertiesPanel.get_node("PropertiesScroll")
@onready var propertiesContainer : PanelContainer = propertiesScroll.get_node("VBox/PropertiesContainer")
@onready var statePropertyContainer : Container = propertiesContainer.get_node("StateProperties")
@onready var stateNameField : LineEdit = statePropertyContainer.get_node("StateName/StateNameField")
@onready var stateInputField : LineEdit = statePropertyContainer.get_node("StateInput/StateInputField")
@onready var stateConnectionCountLabel : Label = statePropertyContainer.get_node("StateConnectionCount/ConnectionCountLabel")
#Connection properties
@onready var connectionPropertyContainer : Container = propertiesContainer.get_node("ConnectionProperties")
@onready var connectionFromLabel : Label = connectionPropertyContainer.get_node("ConnectionLabel/ConnectionFrom")
@onready var connectionToLabel : Label = connectionPropertyContainer.get_node("ConnectionLabel/ConnectionTo")
@onready var parameterDropdown : Button = connectionPropertyContainer.get_node("ParameterDropdown")
@onready var parameterCountLabel : Label = parameterDropdown.get_node("ParameterCount")
@onready var parameterArrow : Label = parameterDropdown.get_node("Arrow")
@onready var parameterConnectionPlus : MenuButton = parameterDropdown.get_node("Plus")
@onready var parameterConnectionContainer : VBoxContainer = connectionPropertyContainer.get_node("ParameterContainer")
#Save
@onready var savePanel : Panel = mainHBox.get_node("SavePanel")
@onready var saveScroll : ScrollContainer = savePanel.get_node("SaveScroll")
@onready var fileName : LineEdit = saveScroll.get_node("VBox/FileNameLabel/FileName")
@onready var filePath : LineEdit = saveScroll.get_node("VBox/FilePathLabel/FilePath")
@onready var loadFieldContainer : Container = saveScroll.get_node("VBox/LoadLabel/ObjectFieldContainer")
@onready var createButton : Button = saveScroll.get_node("VBox/CreateButton")
var loadField : EditorResourcePicker

#Prefabs
var stateNode_prefab = preload("res://addons/AIStateMachine/Scenes/AIStateNode.tscn")
var parameterNode_prefab = preload("res://addons/AIStateMachine/Scenes/AIParameterNode.tscn")
var parameterConnection_prefab = preload("res://addons/AIStateMachine/Scenes/AIParameterConnection.tscn")


var states : Array[Node]:
	get:
		return stateContainer.get_children()

var _selectedNode : Node = null
var selectedNode : Node:
	get:
		return _selectedNode
	set(value):
		_selectedNode = value
		if (value.is_in_group("ConnectionNode")):
			update_property_parameters()

var focusNode : Control = null

#Parameters
var parameters : Dictionary = {}
var parameterCount : int:
	get:
		var count : int = 0
		for child in parameterConnectionContainer.get_children():
			if (not child.markedForDelete):
				count += 1
		return count
var parametersOpen : bool = false

#Text field
var lastSubmittedText : String = "empty_state"

#Delete
var nodeToDelete : Control = null #The state that you're attempting to delete

#Colors
var c_count : Color = Color8(0, 255, 0)
var c_count_zero : Color = Color8(160, 160, 160)

var connectionNodes : Array[Control] = []

var creationFilepath : String = ""
const creationDuration : float = 0.1
var creationTimer : float = 0

func _ready():
	prepareDelete.get_popup().connect("id_pressed", remove_option_selected)
	parameterConnectionPlus.get_popup().connect("id_pressed", create_parameter_connection)
	loadField = EditorResourcePicker.new()
	loadFieldContainer.add_child(loadField)
	loadField.base_type = "AIBehavior"
	loadField.connect("resource_changed", resource_loaded)


func _process(delta):
	_set_children_height()
	_disable_prepare_delete()
	
	if (creationTimer > 0):
		creationTimer -= get_process_delta_time()
		if (creationTimer <= 0):
			creationTimer = 0
			set_and_save_object()

func _set_children_height():
	if (mainScroll != null):
		mainScroll.size.x = size.x - mainScroll.position.x
		mainScroll.size.y = size.y - mainScroll.position.y
		mainHBox.size.y = size.y - mainHBox.position.y
		
		#Properties
		parameterPanel.size.y = size.y - parameterPanel.position.y
		parameterScroll.size.y = size.y - parameterScroll.position.y
		
		#State
		statePanel.size.y = size.y - statePanel.position.y
		stateScroll.size.y = size.y - stateScroll.position.y
		
		#Properties
		propertiesPanel.size.y = size.y - propertiesPanel.position.y
		propertiesScroll.size.y = size.y - propertiesScroll.position.y
		
		#Save
		savePanel.size.y = size.y - savePanel.position.y
		saveScroll.size.y = size.y - saveScroll.position.y

func _disable_prepare_delete():
	if (prepareDelete.visible and not prepareDelete.get_popup().visible):
		unprepare_to_remove()

func _input(event):
	#Unfocus on click
	if (event is InputEventMouseButton and event.pressed):
		unfocus()


func unfocus():
	if (focusNode != null):
		#Choose to ignore if focusNode is part of paramters
		var ignore : bool = (focusNode != stateNameField and focusNode != stateInputField
		and focusNode != fileName and focusNode != filePath)
		#Set text if focus is a text field
		if (focusNode is LineEdit and not ignore):
			var realText : String = focusNode.text if (focusNode.text.length() > 0) else (lastSubmittedText)
			if (focusNode == stateNameField):
				set_state_name(realText)
			elif (focusNode == stateInputField):
				set_state_input(realText)
			#Remove the ending slash from file path
			if (focusNode == filePath):
				_file_path_changed(filePath.text)
			#Release focus
			focusNode.release_focus()
			focusNode = null


func create_state() -> Control:
	var newNode : Control = stateNode_prefab.instantiate()
	stateContainer.add_child(newNode)
	newNode.size = Vector2.ZERO
	newNode.change_name("empty_state")
	set_expand_collapse_buttons()
	return newNode

func remove_state(stateNode : Control):
	if (stateNode != null):
		#Unselect state
		if (selectedNode == stateNode):
			set_selected(null)
		
		#Remove all references of the state
		for state in states:
			if (state != stateNode and state.has_connection(stateNode)):
				state.remove_connection(stateNode)
		
		#Destroy state node
		stateNode.destroy()
		
		set_expand_collapse_buttons()

func prepare_to_remove(node : Control):
	if (node != null):
		#Setup the prepare to delete menu
		var x_offset : float = 350 if (node.is_in_group("StateNode")) else 300
		prepareDelete.global_position = node.global_position + Vector2(x_offset, 5)
		prepareDelete.visible = true
		prepareDelete.show_popup()
		#Cache the state you want to delete
		nodeToDelete = node

func unprepare_to_remove():
	nodeToDelete.deleteButton.disabled = false
	nodeToDelete = null
	prepareDelete.visible = false

func remove_option_selected(option : int):
	#'YES' was chosen
	if (option == 0):
		if (nodeToDelete.is_in_group("StateNode")):
			remove_state(nodeToDelete)
		elif (nodeToDelete.is_in_group("ConnectionNode")):
			nodeToDelete.parent.remove_connection(nodeToDelete)
		elif (nodeToDelete.is_in_group("ParameterNode")):
			nodeToDelete.markedForDelete = true
			nodeToDelete.queue_free()
		elif (nodeToDelete.is_in_group("ParameterConnection")):
			nodeToDelete.markedForDelete = true
			nodeToDelete.queue_free()
			set_parameter_count_label(parameterCount)
			#Close dropdown
			if (parameterCount == 0):
				close_parameters()
			#Update connection node parameters
			update_connection_parameters()
	
	#Hide prepare to delete menu
	unprepare_to_remove()

func set_selected(newSelected : Control):
	#Unselect old node
	if (selectedNode != null):
		selectedNode.unselect()
	
	#Select new node
	if (newSelected != null):
		newSelected.select()
	selectedNode = newSelected
	
	#Change properties field
	set_properties_field(newSelected)


#PROPERTY SETTERS

func set_properties_field(object : Control):
	#State node selected
	if (object != null and object.is_in_group("StateNode")):
		statePropertyContainer.visible = true
		connectionPropertyContainer.visible = false
		#Set name
		stateNameField.text = object.stateName
		#Set input
		stateInputField.text = object.input
		#Set connection count
		set_state_connection_count_label(object.connectionCount)
	elif (object != null and object.is_in_group("ConnectionNode")):
		statePropertyContainer.visible = false
		connectionPropertyContainer.visible = true
	else:
		statePropertyContainer.visible = false
		connectionPropertyContainer.visible = false

func set_state_connection_count_label(count : int):
	stateConnectionCountLabel.text = "Connections: " + str(count)

func set_parameter_count_label(count : int):
	parameterCountLabel.text = str(count)
	#Set count label color
	var col : Color = c_count if (count > 0) else c_count_zero
	parameterCountLabel.add_theme_color_override("font_color", col)
	#Set count label outline
	var size : int = 6 if (count > 0) else 0
	parameterCountLabel.add_theme_constant_override("outline_size", size)
	#Close dropdown
	if (count == 0):
		close_parameters()


#TEXT FIELDS

func _state_name_focus():
	focusNode = stateNameField
	lastSubmittedText = focusNode.text

func _state_name_changed(newName : String):
	var realName : String = newName if (newName.length() > 0) else (lastSubmittedText)
	set_state_name(realName)

func _state_input_focus():
	focusNode = stateInputField
	lastSubmittedText = stateInputField.text

func _state_input_changed(newInput : String):
	var realInput : String = newInput if (newInput.length() > 0) else (lastSubmittedText)
	set_state_input(realInput)



#MODIFY VALUES

func set_state_name(newName : String):
	stateNameField.text = newName
	lastSubmittedText = newName
	#Set name of the state node
	if (selectedNode != null and selectedNode.is_in_group("StateNode")):
		selectedNode.change_name(newName)

func set_state_input(newInput: String):
	stateInputField.text = newInput
	lastSubmittedText = newInput
	#Set input of the state node
	if (selectedNode != null and selectedNode.is_in_group("StateNode")):
		selectedNode.change_input(newInput)

func update_connection_parameters():
	if (selectedNode.is_in_group("ConnectionNode")):
		selectedNode.parameters.clear()
		#Add all the parameters to the connection node
		for param in parameterConnectionContainer.get_children():
			var newParam : AIParameter = AIParameter.new()
			newParam.parameterName = param.parameterName
			newParam.value = param.value
			newParam.modifier = param.modifier
			selectedNode.parameters.append(newParam)
			

func update_property_parameters():
	if (selectedNode.is_in_group("ConnectionNode")):
		#Remove all container children
		for param in parameterConnectionContainer.get_children():
			parameterConnectionContainer.remove_child(param)
			param.queue_free()
		#Create new parameters
		for param in selectedNode.parameters:
			#This is annoying, idk why it can't just get the parameter's 'value' variable
			var paramValue
			var valueType : String = param.valueType
			if (valueType == "Bool" || valueType == "Trigger"):
				paramValue = param.valueBool
			elif (valueType == "Int"):
				paramValue = param.valueInt
			elif (valueType == "Float"):
				paramValue = param.valueFloat
			elif (valueType == "String"):
				paramValue = param.valueString
			#Create parameter connection
			create_and_set_parameter_connection(param.parameterName, paramValue, param.modifier)
		#Set count label
		set_parameter_count_label(parameterCount)


#EXPAND AND COLLAPSE BUTTONS

func set_expand_collapse_buttons():
	#Buttons will be disabled by default
	expandButton.disabled = true
	collapseButton.disabled = true
	
	if (states.size() > 0):
		#States exist; find out if any states can be opened or collapsed
		for state in states:
			if (state.connectionCount > 0):
				#State can be collapsed
				if (state.dropdownOpen):
					collapseButton.disabled = false
				#State can be open
				else:
					expandButton.disabled = false
			#Break out of loop if both buttons are enabled (no reason to continue checking)
			if (not expandButton.disabled and not collapseButton.disabled):
				break

func _expand_pressed():
	for state in states:
		state.open_dropdown()

func _collapse_pressed():
	for state in states:
		state.close_dropdown()


#CONNECTION PROPERTIES

func update_connection_labels(from : String, to : String):
	connectionFromLabel.text = from
	connectionToLabel.text = to

func open_parameters():
	if (not parametersOpen and parameterCount > 0):
		parameterConnectionContainer.visible = true
		parameterArrow.scale.y = -1
		parametersOpen = true

func close_parameters():
	if (parametersOpen):
		parameterConnectionContainer.visible = false
		parameterArrow.scale.y = 1
		parametersOpen = false

func _parameter_pressed():
	if (parametersOpen):
		close_parameters()
	else:
		open_parameters()

func set_type_button(button : MenuButton):
	button.get_popup().clear()
	for param in parameterContainer.get_children():
		button.get_popup().add_item(param.parameterName)

func _parameter_connection_plus():
	set_type_button(parameterConnectionPlus)

#Creates a new parameter node for the connection node properties
func create_parameter_connection(param : int, updateConnectionParams : bool = true) -> Control:
	var newParameter : Control = parameterConnection_prefab.instantiate()
	parameterConnectionContainer.add_child(newParameter)
	newParameter.root = self
	newParameter.set_values(parameterContainer.get_child(param), updateConnectionParams)
	set_parameter_count_label(parameterCount)
	open_parameters()
	if (updateConnectionParams):
		update_connection_parameters()
	return newParameter

func create_and_set_parameter_connection(paramName : String, paramValue, paramModifier : int = 0):
	if (get_parameter_index(paramName) != -1):
		var newParameter : Control = create_parameter_connection(get_parameter_index(paramName), false)
		newParameter.value = paramValue
		newParameter.modifier = paramModifier
		newParameter.set_operator_labels()

func update_all_parameters():
	for param in parameterConnectionContainer.get_children():
		param.set_values()



#PARAMETER

func create_parameter() -> Control:
	var newParameter : Control = parameterNode_prefab.instantiate()
	parameterContainer.add_child(newParameter)
	newParameter.root = self
	return newParameter


#SAVING

func _file_name_focus():
	focusNode = fileName
	lastSubmittedText = focusNode.text

func _file_path_focus():
	focusNode = filePath
	lastSubmittedText = focusNode.text

func _file_path_changed(newPath : String):
	filePath.text = newPath
	if (newPath.ends_with("/")):
		filePath.text = newPath.left(-1)

func create_button_pressed():
#	if (creationTimer.is_stopped())
	var fullFilePath : String = filePath.text + "/" + fileName.text + ".tres"
	if (fileName.text.length() > 0):
		#Remove object if already exists
#		var dir = DirAccess.open("res://")
#		if (dir.file_exists(fullFilePath.right(-6))):
#			dir.remove(fullFilePath.right(-6))
#
#		var plugin : EditorPlugin = EditorPlugin.new()
#		plugin.get_editor_interface().get_resource_filesystem().scan()
		
		creationFilepath = fullFilePath
		creationTimer = creationDuration

func set_and_save_object():
	#SET OBJECT'S STATS
	
	#Create new object
	var newBehaviorObject : AIBehavior = AIBehavior.new()
	
	#Parameters
	var parameterDict : Dictionary = {}
	for i in range(parameterContainer.get_child_count()):
		var p_name : String = parameterContainer.get_child(i).parameterName
		var p_type : String = parameterContainer.get_child(i).valueType
		var value
		match (p_type):
			("Trigger"):
				value = null
			("Bool"):
				value = bool(false)
			("Int"):
				value = int(0)
			("Float"):
				value = float(0)
			("String"):
				value = String("null")
		#Add to dictionary
		var addDict : Dictionary = { p_name : value }
		parameterDict.merge(addDict)
	#Add parameters to the object
	newBehaviorObject.parameters = parameterDict
	
	#States
	newBehaviorObject.states = []
	for i in range(stateContainer.get_child_count()):
		#Create state
		var state_i : Node = stateContainer.get_child(i)
		var newState : AIState = AIState.new()
		newState.name = state_i.stateName
		newState.input = state_i.input
		#Add new state to the object
		newBehaviorObject.states.append(newState)
		
	#Connections
	for i in range(stateContainer.get_child_count()):
		newBehaviorObject.states[i].connectionParameters = []
		for j in range(stateContainer.get_child(i).connectionCount):
			
			#Attach each state's connection
			var connectionIndex : int = stateContainer.get_child(i).get_connection_node(j).stateIndex#newBehaviorObject.states[stateContainer.get_child(i).get_connection_node(j).stateIndex].duplicate()
			newBehaviorObject.states[i].connections.append(connectionIndex) 
			
			#Ensure state always has an array for each connection note (even if the array is empty)
			#This array represents the connection nodes existence, the contents of the array represents the parameters attached to the connection node
			newBehaviorObject.states[i].connectionParameters.append([])
			
			#Set each state's connection parameters
			for k in range(stateContainer.get_child(i).get_connection_node(j).parameters.size()):
				newBehaviorObject.states[i].connectionParameters[j].append(stateContainer.get_child(i).get_connection_node(j).parameters[k])
		
		#Save new object
		var saveResult = ResourceSaver.save(newBehaviorObject, creationFilepath)
		if (saveResult != OK):
			print_rich("[color=red]ERROR: Failed to create AIBehavior object. Error code: " + str(saveResult) + "[color=white]")



#LOADING

func resource_loaded(resource : AIBehavior):
	var path : String = resource.resource_path
	var lastSlashPosition : int = path.rfind("/")
	#Set file path
	filePath.text = path.left(lastSlashPosition)
	#Set file name
	fileName.text = path.right(-lastSlashPosition - 1).left(-5)
	
	#Erase old stats
	
	#Create parameters
	for parameter in resource.parameters:
		#Get the parameter info
		var paramValue = resource.parameters[parameter]
		var paramType : int = 0
		if (paramValue == null):
			paramType = 0
		elif (paramValue is bool):
			paramType = 1
		elif (paramValue is int):
			paramType = 2
		elif (paramValue is float):
			paramType = 3
		elif (paramValue is String):
			paramType = 4
		#Create the parameter node
		var newParameter : Control = create_parameter()
		newParameter.parameterName = parameter
		newParameter.choose_type(paramType)
	
	#Create states
	for state in resource.states:
		var newStateNode : Control = create_state()
		newStateNode.change_name(state.name)
		newStateNode.change_input(state.input)
	
	#Create connections
	for i in range(resource.states.size()):
		for j in range(resource.states[i].connections.size()):
			#Create connection
			var newConnection : Control = stateContainer.get_child(i).create_connection(resource.states[i].connections[j], false)
			
			#Create parameters
			if (resource.states[i].connectionParameters.size() > j):
				for k in range(resource.states[i].connectionParameters[j].size()): #For each parameter in this connection
					newConnection.parameters.append(resource.states[i].connectionParameters[j][k].duplicate())



#RETURNS

func find_state(stateID : String):
	for state in states:
		if (state.stateName == stateID):
			return state
	
	return null

func get_parameter_index(parameterName : String):
	for i in range(parameterContainer.get_child_count()):
		if (parameterContainer.get_child(i).parameterName == parameterName):
			return i
	return -1
