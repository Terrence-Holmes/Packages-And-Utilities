@tool
extends Control

#Prefabs
var connection_prefab = preload("res://addons/AIStateMachine/Scenes/AIConnectionNode.tscn")

#References
@onready var root : Control = null
@onready var stateButton : Button = get_node("State")
@onready var plusButton : MenuButton = get_node("Plus")
@onready var connectionContainer : Container = get_node("Connections")
@onready var stateArrow : Label = stateButton.get_node("Arrow")
@onready var countLabel : Label = stateButton.get_node("Count")
@onready var selectPanel : Panel = stateButton.get_node("Select")
@onready var deleteButton : Button = get_node("Delete")

#Colors
var c_count : Color = Color8(0, 255, 0)
var c_count_zero : Color = Color8(70, 70, 70)

var stateName : String = "empty_state"
var input : String = "null"

var dropdownOpen : bool = false

var connectionCount : int:
	get:
		#Get count of all connection nodes NOT marked for delete
		var connections : int = 0
		for connection in connectionContainer.get_children():
			if (not connection.markedForDelete):
				connections += 1
		return connections

var connections : Array[Control]:
	get:
		var returnArray : Array[Control] = []
		for con in connectionContainer.get_children():
			returnArray.append(con)
		return returnArray

var index : int:
	get:
		for i in range(get_parent().get_child_count()):
			if (get_parent().get_child(i) == self):
				return i
		
		return -1


func _ready():
	#Find root
	var i : int = 0
	var nodeToCheck : Node = get_parent()
	while (root == null and i < 10):
		#Root was found
		if (nodeToCheck.name == "AI State Machine"):
			root = nodeToCheck
		#This is not the root
		else:
			nodeToCheck = nodeToCheck.get_parent()
	
	change_name(name)
	plusButton.get_popup().connect("id_pressed", create_connection)


func _process(delta):
	pass

func destroy():
	for connection in connectionContainer.get_children():
		root.connectionNodes.erase(connection)
	queue_free()




func resize_node():
	#Set node size
	if (not dropdownOpen):
		custom_minimum_size.y = 42
	else:
		custom_minimum_size.y = 50 + (47 * connectionCount)
	
	#Set count label
	countLabel.text = str(connectionCount)
	#Set count label color
	var col : Color = c_count if (connectionCount > 0) else c_count_zero
	countLabel.add_theme_color_override("font_color", col)
	#Set count label outline
	var size : int = 6 if (connectionCount > 0) else 0
	countLabel.add_theme_constant_override("outline_size", size)
	#Set count label font size
	size = 24 if (connectionCount > 0) else 20
	countLabel.add_theme_font_size_override("font_size", size)


#MODIFY VALUES

func change_name(newName : String):
	stateName = newName
	stateButton.text = "   " + newName

func change_input(newInput : String):
	input = newInput


#PLUS BUTTON

func set_plus_button():
	plusButton.set_item_count(0)
	for i in range(root.states.size()):
		if (root.states[i] != self): #and not has_connection(root.states[i])
			plusButton.get_popup().add_item(root.states[i].stateName)

func create_connection(id : int, usingPopup : bool = true) -> Control:
	#Create new connection node
	var newConnection : Control = connection_prefab.instantiate()
	#Connection node setup
	connectionContainer.add_child(newConnection)
	if (usingPopup):
		newConnection.assign_state(root.find_state(plusButton.get_popup().get_item_text(id)))
	else:
		newConnection.assign_state(root.states[id])
	newConnection.parent = self
	#Apply new values to properties list
	root.set_state_connection_count_label(connectionCount)
	#Adjust self
	resize_node()
	open_dropdown()
	root.connectionNodes.append(newConnection)
	#Return the connection
	return newConnection



func remove_connection(connection : Control):
	var connectionNode : Control = null
	root.connectionNodes.erase(connection)
	#The node that was passed through is a connection node
	if (connection.is_in_group("ConnectionNode")):
		connectionNode = connection
	#'connection' is a state node; find the connection node
	elif (connection.is_in_group("StateNode")):
		for node in connectionContainer.get_children():
			if (node.state == connection):
				connectionNode = node
	
	#Remove the connection node
	if (connectionNode != null):
		#Unselect connection node
		if (root.selectedNode == connectionNode):
			if (connectionNode.is_in_group("ConnectionNode")):
				root.set_selected(self)
		#Delete node
		connectionNode.markedForDelete = true
		connectionNode.queue_free()
		#Close dropdown if empty
		if (connectionCount == 0):
			close_dropdown()
		#Resize self
		resize_node()
		#Update connection count in the properties field
		if (root.selectedNode == self):
			root.set_state_connection_count_label(connectionCount)

#DROPDOWN

func open_dropdown():
	if (connectionCount > 0 and not dropdownOpen):
		connectionContainer.visible = true
		dropdownOpen = true
#		stateArrow.scale.y = -1
		resize_node()
		root.set_expand_collapse_buttons()


func close_dropdown():
	if (dropdownOpen):
		connectionContainer.visible = false
		dropdownOpen = false
#		stateArrow.scale.y = 1
		resize_node()
		root.set_expand_collapse_buttons()


func toggle_dropdown():
	if (dropdownOpen):
		close_dropdown()
	else:
		open_dropdown()


#SELECTION

func select():
	selectPanel.visible = true

func unselect():
	selectPanel.visible = false


#BUTTONS

func _state_pressed():
	#Dropdown
	if (root.selectedNode == self):
		toggle_dropdown()
	#Select self
	else:
		root.set_selected(self)

func _plus_pressed():
	set_plus_button()
	root.set_selected(self)

func _delete_pressed():
	deleteButton.disabled = true
	root.prepare_to_remove(self)


#RETURNS

func has_connection(state : Control):
	for connection in connectionContainer.get_children():
		if (connection.state == state):
			return true
	
	return false


func get_connection_node(index : int) -> Control:
	if (connectionContainer.get_child_count() > index):
		return connectionContainer.get_child(index)
	return null
