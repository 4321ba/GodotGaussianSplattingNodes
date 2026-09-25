extends Node3D

#const SplatCloud3D = preload("res://addons/gsplat-nodes/scripts/splat_cloud_3d.gd")

@export var infantry_resource: SplatCloudData
@export var tank_resource: SplatCloudData
@export var vtb_resource: SplatCloudData

var pools = {
	"infantry": [],
	"tank": [],
	"vtb": []
}

func _ready():
	_create_pool("vtb", vtb_resource, 21)
	_create_pool("infantry", infantry_resource, 10)
	_create_pool("tank", tank_resource, 10)

func _create_pool(type: String, res: SplatCloudData, count: int):
	for i in range(count):
		var splat = SplatCloud3D.new()
		splat.splat_data = res
		add_child(splat)
		splat.position = Vector3(0, 0, 0)
		pools[type].append(splat)

func get_splat(type: String) -> Node3D:
	if pools[type].is_empty():
		printerr("GSPool: Exceeded limit for enemy type: " + type + "!")
		return null
	return pools[type].pop_back()

func return_splat(splat: Node3D, type: String):
	if not is_instance_valid(splat): return
	# NO REPARENTING! Just hide it under the map again.
	splat.position = Vector3(0, 0, 0)
	splat.rotation = Vector3.ZERO
	pools[type].append(splat)
