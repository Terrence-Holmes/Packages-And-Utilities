@tool
extends EditorPlugin

var ui : Control
var ui_prefab = preload("res://addons/AIStateMachine/Scenes/AIStateMachineUI.tscn")


func _enter_tree():
	ui = ui_prefab.instantiate()
#	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_BL, ui)
	add_control_to_bottom_panel(ui, "AI State Machine")


func _exit_tree():
	remove_control_from_bottom_panel(ui)
	ui.queue_free()
