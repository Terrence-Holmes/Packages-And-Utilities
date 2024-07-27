extends Resource
class_name AIState

@export_category("AI State")
@export var name : String = "empty_state" #The name of this state
@export var input : String = "null" #The input that executes when this state is active
@export var connections : Array[int] = [] #The index of the state (in AIBehavior.states) that this state is connected to
@export var connectionParameters : Array = [] #Nested array: Array[Array[AIParameter]]

#Creates a connection to a different state
func create_connection(target : int):
	#Ensure this transition doesn't already exist
	for connection in connections:
		if (connection == target):
			return
	#Create transition
	connections.append(target)



#Adds 'parameter' to 'connection'
#NOTE: 'connection' can be the index of the connection that this parameter belongs to, or the instance of the connection (AIState type) itself
func set_parameter(connection, parameterIndex : int, parameterValue, parameterModifier : int = -1):
	#Find the connection index
	var connectionIndex : int = -1
	if (connection is int):
		connectionIndex = connection
	elif (connection is AIState):
		for i in range(connections.size()):
			if (connections[i] == connection):
				connectionIndex = i
				break
	#Set the parameter value
	if (connectionIndex != -1):
		connectionParameters[connectionIndex][parameterIndex].value = parameterValue
		if (parameterModifier != -1):
			connectionParameters[connectionIndex][parameterIndex].modifier = parameterModifier

#Removes the first occurance of a parameter with the name 'parameter' from 'connection'
func remove_parameter(connection, parameterIndex : int):
	#Find the connection index
	var connectionIndex : int = -1
	if (connection is int):
		connectionIndex = connection
	elif (connection is AIState):
		for i in range(connections.size()):
			if (connections[i] == connection):
				connectionIndex = i
				break
	#Set the parameter value
	if (connectionIndex != -1):
		connectionParameters[connectionIndex].remove_at([parameterIndex])


#AIState : Returns a new state if all parameters are met on any connection, or null if they're not
func check_parameters(parameter : Dictionary) -> int:
	#Check each connection until one is found with all conditions met
	for i in range(connections.size()):
		var conditionsMet : bool = true
		for j in range(connectionParameters[i].size()):
			if (parameter.has(connectionParameters[i][j].parameterName)):
				#For int or float parameters, decide whether to check =, > or <
				if (connectionParameters[i][j].valueType == "Int" || connectionParameters[i][j].valueType == "Float"):
					if (connectionParameters[i][j].modifier == 0 and connectionParameters[i][j].value != parameter[connectionParameters[i][j].parameterName]
					|| connectionParameters[i][j].modifier == 1 and connectionParameters[i][j].value >= parameter[connectionParameters[i][j].parameterName]
					|| connectionParameters[i][j].modifier == -1 and connectionParameters[i][j].value <= parameter[connectionParameters[i][j].parameterName]):
						conditionsMet = false
						break
				
				elif (connectionParameters[i][j].value != parameter[connectionParameters[i][j].parameterName]):
					conditionsMet = false
					break
		
		#If all conditions are met, return the index of this transition's target
		if (conditionsMet):
			return connections[i]
	
	return -1


func find_connection_index(stateIndex : int):
	for i in range(connections.size()):
		if (connections[i] == stateIndex):
			return i
	return -1
