extends ColorRect

# References
@onready var tower_placer = get_node("/root/MainScene/TowerPlacer")
@onready var enemy_spawner = $"/root/MainScene/EnemySpawner"
# UI Elements
@onready var health_label: Label = $MarginContainer/VBoxContainer/LabelHBox/HealthLabel
@onready var money_label: Label = $MarginContainer/VBoxContainer/LabelHBox/MoneyLabel
@onready var wave_label: Label = $MarginContainer/VBoxContainer/LabelHBox/WaveLabel
@onready var tower_hbox = $MarginContainer/VBoxContainer/TowerHBox
@onready var dwmenu = $MarginContainer/VBoxContainer/Control/DeathWinMenu
@onready var golabel = $MarginContainer/VBoxContainer/Control/DeathWinMenu/GameOverLabel

var tower_containers: Array[SubViewportContainer] = []

func _ready() -> void:
	# 4. Generate 3D Previews for each tower
	if tower_placer and tower_placer.tower_scenes:
		for i in range(tower_placer.tower_scenes.size()):
			var container = _create_3d_preview(tower_placer.tower_scenes[i])
			tower_hbox.add_child(container)
			tower_containers.append(container)
	
	update_gui()

func _process(_delta: float) -> void:
	# --- AUTO-UPDATE LOGIC ---
	# We poll the data every frame. This decouples UI from Game Logic perfectly.
	update_gui()
	if is_processing(): # if we didn't lose or win yet
		if Input.is_action_just_pressed("ui_cancel"):
			if dwmenu.visible:
				color = Color(0.122, 0.106, 0.039, 0.459)
				create_tween().tween_property(self, "color", Color(0.122, 0.106, 0.039, 0.0), 0.4)
			else:
				$MarginContainer/VBoxContainer/Control/DeathWinMenu/MainMenuButton.grab_focus()
				color = Color(0.122, 0.106, 0.039, 0.0)
				create_tween().tween_property(self, "color", Color(0.122, 0.106, 0.039, 0.459), 0.4)
			dwmenu.visible = not dwmenu.visible
	
func update_gui():
	# 1. Update Text
	if HealthAndMoney.i:
		health_label.text = "❤️ " + str(HealthAndMoney.i.health)
		money_label.text = str(HealthAndMoney.i.money) + " 🪙"
		if HealthAndMoney.i.is_game_over:
			dwmenu.visible = true
			color = Color(0.396, 0.012, 0.016, 0.0)
			create_tween().tween_property(self, "color", Color(0.396, 0.012, 0.016, 0.251), 0.4)
			golabel.visible = true
			mouse_filter = Control.MOUSE_FILTER_STOP
			set_process(false)
		if enemy_spawner.is_win:
			dwmenu.visible = true
			color = Color(0.012, 0.396, 0.016, 0.0)
			create_tween().tween_property(self, "color", Color(0.012, 0.396, 0.016, 0.251), 0.4)
			golabel.text = "You Win!"
			golabel.label_settings.font_color = Color(0.012, 0.396, 0.016, 1.0)
			golabel.visible = true
			mouse_filter = Control.MOUSE_FILTER_STOP
			set_process(false)
			
	wave_label.text = "Wave " + str(enemy_spawner.current_round + (0 if enemy_spawner.is_in_break else 1))
	
	# 2. Update Tower Selection Highlight
	if tower_placer:
		var selected = tower_placer.chosen_tower
		for i in range(tower_containers.size()):
			var container = tower_containers[i]
			if i == selected:
				# Highlight: Bigger and Fully Opaque
				container.modulate = Color(1, 1, 1, 1)
				container.scale = Vector2(1.2, 1.2)
			else:
				# Dimmed: Smaller and Transparent
				container.modulate = Color(0.7, 0.7, 0.7, 0.8)
				container.scale = Vector2(1.0, 1.0)

func _create_3d_preview(scene: PackedScene) -> SubViewportContainer:
	# 1. Container
	var svc = SubViewportContainer.new()
	svc.custom_minimum_size = Vector2(120, 120)
	svc.pivot_offset = Vector2(60, 60) # Pivot center for scaling
	
	# [FIX] Enable Stretch: Matches internal resolution to UI size (Sharper)
	svc.stretch = true 
	
	# [OPTIONAL] For Voxel games, Nearest Neighbor often looks cleaner than Linear blur
	svc.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# 2. Viewport (The 3D World)
	var sv = SubViewport.new()
	sv.own_world_3d = true # Crucial: Separate world so enemies don't walk here
	sv.transparent_bg = true
	#sv.size = Vector2(120, 120)
	svc.add_child(sv)
	
	# 3. Camera & Light
	var cam = Camera3D.new()
	cam.position = Vector3(2, 2, 2) # Look down-ish
	cam.look_at_from_position(cam.position, Vector3.ZERO)
	sv.add_child(cam)
	
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 45, 0)
	sv.add_child(light)
	
	# 4. The Tower Mesh
	if scene:
		var inst = scene.instantiate()
		inst.set_script(null) # Remove logic so it doesn't shoot or interact
		sv.add_child(inst)
		
	return svc


func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
