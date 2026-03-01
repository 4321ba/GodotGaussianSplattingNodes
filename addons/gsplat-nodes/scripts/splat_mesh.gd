@tool
class_name SplatMesh extends Node3D

@export var splat_data: GaussianSplatData :
	set(value):
		if splat_data != value:
			# Unregister the old data first
			_unregister()
			splat_data = value
			# Register with the new data
			_update_registration()

func _enter_tree() -> void:
	# Listen for visibility toggles (the eye icon in the editor, or hide() in-game)
	if not visibility_changed.is_connected(_update_registration):
		visibility_changed.connect(_update_registration)
	_update_registration()

func _exit_tree() -> void:
	if visibility_changed.is_connected(_update_registration):
		visibility_changed.disconnect(_update_registration)
	_unregister()

func _update_registration() -> void:
	# If no resource is assigned, ensure it is unregistered and abort
	if not splat_data:
		_unregister()
		return
		
	# is_visible_in_tree() checks this node AND all parent visibilities
	if is_inside_tree() and is_visible_in_tree():
		_register()
	else:
		_unregister()

func _register() -> void:
	GsplatRenderedImage.register_splat(self)

func _unregister() -> void:
	GsplatRenderedImage.unregister_splat(self)
