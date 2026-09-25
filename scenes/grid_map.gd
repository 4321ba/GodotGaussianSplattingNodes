extends GridMap

var templib: MeshLibrary

func _init() -> void:
	templib = mesh_library
	mesh_library = null

func _ready() -> void:
	if mesh_library != null:
		push_error("MeshLibrary was unexpectedly initialized later than _init!")
	mesh_library = templib
