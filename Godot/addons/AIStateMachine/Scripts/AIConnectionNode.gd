@tool
extends Button

#References
var root : Control:
	get:
		return state.root if (state != null) else null
@onready var selectPanel = get_node("Select")
@onready var deleteButton : Button = get_node("Delete")

var markedForDelete : bool = false

var parent : Node = null #The state that this connection node belongs to
var state : Node = null #The state that this connection node represents
var parameters : Array[AIParameter] = []

var parametersToString : String:
	get:
		var returnString : String = "{ "
		for i in range(parameters.size()):
			returnString += parameters[i].to_string
			if (i < parameters.size() - 1):
				returnString += " | "
		returnString += "}"
		return returnString

var stateIndex : int:
	get:
		if (state == null):
			return -1
		
		for i in range(state.get_parent().get_child_count()):
			if (state.get_parent().get_child(i) == state):
				return i
		return -1


func _process(delta):
	text = "   " + state.stateName


func assign_state(newState : Node):
	state = newState
	text = "   " + newState.stateName


func select():
	selectPanel.visible = true

func unselect():
	selectPanel.visible = false



func _pressed():
	if (root != null):
		root.set_selected(self)
		root.update_connection_labels(parent.stateName, state.stateName)

func _remove_pressed():
	if (root != null):
		deleteButton.disabled = true
		root.prepare_to_remove(self)
