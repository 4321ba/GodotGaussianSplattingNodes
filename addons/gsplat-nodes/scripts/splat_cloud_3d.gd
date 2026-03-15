@tool
@icon("res://addons/gsplat-nodes/icons/splat_cloud_3d.svg")
class_name SplatCloud3D extends Node3D

@export var splat_data: SplatCloudData :
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
	
	# Tell Godot to trigger _notification when the node's transform changes
	set_notify_transform(true) 
	
	_update_registration()

func _exit_tree() -> void:
	if visibility_changed.is_connected(_update_registration):
		visibility_changed.disconnect(_update_registration)
	_unregister()

func _notification(what: int) -> void:
	# Instantly pushes transform changes to the GPU manager
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		SplatCompositor.splat_transforms[self] = global_transform

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
	# Cache initial transform and register
	SplatCompositor.splat_transforms[self] = global_transform
	SplatCompositor.register_splat(self)

func _unregister() -> void:
	# Unregister and clean up transform cache
	SplatCompositor.unregister_splat(self)
	SplatCompositor.splat_transforms.erase(self)
