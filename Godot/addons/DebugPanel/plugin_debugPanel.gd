@tool
extends EditorPlugin
class_name Debug

const debug_panel = preload("res://addons/DebugPanel/debug_panel.tscn")

static var panel : Control = null
static var drawGizmos : bool = true


func _enter_tree():
	panel = debug_panel.instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_BL, panel)


func _exit_tree():
	if (panel != null):
		remove_control_from_docks(panel)
		panel.queue_free()
