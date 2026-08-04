@tool
extends EditorPlugin

var ply_import_plugin
var gltf_import_plugin

func _enter_tree():
	ply_import_plugin = preload("res://addons/gsplat-nodes/scripts/ply_importer.gd").new()
	gltf_import_plugin = preload("res://addons/gsplat-nodes/scripts/gltf_importer.gd").new()
	add_import_plugin(ply_import_plugin)
	add_import_plugin(gltf_import_plugin)

func _exit_tree():
	remove_import_plugin(ply_import_plugin)
	remove_import_plugin(gltf_import_plugin)
	ply_import_plugin = null
	gltf_import_plugin = null

const AUTOLOAD_NAME = "GsplatRenderedImage"

func _enable_plugin():
	# The autoload can be a scene or script file.
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/gsplat-nodes/rendered_image.tscn")

func _disable_plugin():
	remove_autoload_singleton(AUTOLOAD_NAME)
