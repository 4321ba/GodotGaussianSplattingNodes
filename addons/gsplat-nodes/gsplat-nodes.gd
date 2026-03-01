@tool
extends EditorPlugin


var import_plugin

func _enter_tree():
	import_plugin = preload("res://addons/gsplat-nodes/scripts/ply_importer.gd").new()
	add_import_plugin(import_plugin)

func _exit_tree():
	remove_import_plugin(import_plugin)
	import_plugin = null


# Replace this value with a PascalCase autoload name, as per the GDScript style guide.
const AUTOLOAD_NAME = "GsplatRenderedImage"


func _enable_plugin():
	# The autoload can be a scene or script file.
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/gsplat-nodes/rendered_image.tscn")


func _disable_plugin():
	remove_autoload_singleton(AUTOLOAD_NAME)
