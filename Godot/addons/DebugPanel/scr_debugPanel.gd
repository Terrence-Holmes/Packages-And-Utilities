@tool
extends Control

#References
@onready var button_checkGizmos : CheckBox = get_node("DrawGizmos")


func _ready():
	button_checkGizmos.button_pressed = Debug.drawGizmos

func _drawGizmos_toggled(button_pressed):
	Debug.drawGizmos = button_pressed
