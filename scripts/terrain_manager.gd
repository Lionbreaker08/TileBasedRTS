class_name TerrainManager
extends Node3D

@export_group("Map Definition")
@export var map: MapDefinition = null

@export_group("Tile Sizing")
@export var tile_size := 1
@export var tile_height_modifier := 4



func init_map_loading():
	if (map == null):
		push_warning("No Map")
		map = MapDefinition.new()
		map.create_auto_map_definition()
		load_map()
	else:
		load_map()

func load_map():
	##Grab Map Size
	var width := map.get_width()
	var depth := map.get_depth()
	
	for x in range(width):
		for z in range(depth):
			var tile: GridTile = map.get_tile_at_int(x, z)
			
			if (tile == null):
				continue
			
			#call upon tile to create itself
			tile.set_vector(Vector2i(x,z))
			tile.create_all()
			
			#retreive tile
			add_child(tile.get_main_node())
			
			tile.set_node_name(tile.to_string())
