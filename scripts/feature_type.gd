class_name FeatureType
extends Resource

@export var feature_name: String
@export var feature_scene: PackedScene
@export var nav_type: TileEnums.NavZoneType = TileEnums.NavZoneType.UNSET

##GETS AND SETS##

func get_scene() -> PackedScene:
	return feature_scene

func get_nav_type() -> TileEnums.NavZoneType:
	return nav_type
