class_name TerrainType
extends Resource

@export var terrain_name: String
@export var terrain_scene: PackedScene

##GETS AND SETS##
	
func get_scene() -> PackedScene:
	return terrain_scene
