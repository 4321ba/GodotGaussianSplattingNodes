@tool
extends EditorPlugin


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass


# Replace this value with a PascalCase autoload name, as per the GDScript style guide.
const AUTOLOAD_NAME = "GsplatRenderedImage"


func _enable_plugin():
	# The autoload can be a scene or script file.
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/gsplat-nodes/rendered_image.tscn")


func _disable_plugin():
	remove_autoload_singleton(AUTOLOAD_NAME)
