extends Node3D

var main_scene = preload("res://scenes/main_scene.tscn")

func _ready() -> void:
	$CanvasLayer/ColorRect/VBoxContainer/VBoxContainer/SfxCheckButton.button_pressed = not AudioServer.is_bus_mute(AudioServer.get_bus_index("Sfx"))
	$CanvasLayer/ColorRect/VBoxContainer/VBoxContainer/MusicCheckButton.button_pressed = Music.playing
	
	# 1. Instantiate the game scene
	var background_world = main_scene.instantiate()
	
	# 2. Strip out the gameplay elements
	var spawner = background_world.get_node_or_null("EnemySpawner")
	if spawner:
		spawner.free()
		
	var ui_layer = background_world.get_node_or_null("CanvasLayer")
	if ui_layer:
		ui_layer.free()
		
	background_world.get_node("TowerPlacer").free()
	#background_world.get_node("GridMap").mesh_library = null
	#background_world.get_node("GridMap").bake_navigation = false
	#background_world.get_node("GridMap").free()
	
	# 3. Replace the Camera Controller with a simple auto-rotator
	# We target the "Pivot" node (the parent of Camera3D) so it orbits the center
	var cam = background_world.get_node_or_null("Pivot/Camera3D")
		
	
	if cam:
		# Create a new script programmatically
		var auto_rotate = GDScript.new()
		auto_rotate.source_code = """
extends Node3D
func _process(delta: float) -> void:
	# Rotate slowly around the Y axis (Orbit)
	get_parent().rotate_y(0.05 * delta)
		"""
		auto_rotate.reload()
		
		# Apply the new script, effectively deleting the old input-based one
		cam.set_script(auto_rotate)
		
		# Ensure the node is processing
		cam.set_process(true)
		cam.set_physics_process(false)
		cam.set_process_input(false)
		cam.set_process_unhandled_input(false)
		
	add_child(background_world)
	
	$CanvasLayer/ColorRect/VBoxContainer/VBoxContainer/PlayButton.grab_focus()


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_scene.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_return_button_pressed() -> void:
	$CanvasLayer/ColorRect/ControlsContainer.visible = false
	$CanvasLayer/ColorRect/VBoxContainer.visible = true
	$CanvasLayer/ColorRect/VBoxContainer/VBoxContainer/PlayButton.grab_focus()


func _on_controls_button_pressed() -> void:
	$CanvasLayer/ColorRect/ControlsContainer.visible = true
	$CanvasLayer/ColorRect/VBoxContainer.visible = false
	$CanvasLayer/ColorRect/ControlsContainer/ReturnButton.grab_focus()


func _on_music_check_button_toggled(toggled_on: bool) -> void:
	Music.playing = toggled_on


func _on_sfx_check_button_toggled(toggled_on: bool) -> void:
	var bus_idx = AudioServer.get_bus_index("Sfx")
	AudioServer.set_bus_mute(bus_idx, not toggled_on)
