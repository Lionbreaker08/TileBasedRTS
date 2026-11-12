class_name MapDefinition
extends Resource

@export_group("Map Size")
@export var width := 10
@export var depth := 10

@export var map: Dictionary[Vector2i, GridTile] = {}

#temp
var grass := preload("res://Resources/Terrains/Grass.tres")
var rock := preload("res://Resources/Terrains/Rock.tres")

func create_auto_map_definition():
	for x in range(width):
		for y in range(depth):
			var tile: GridTile = GridTile.new()
			
			if randi_range(0, 1) == 0:
				tile.set_terrain(grass)
			else:
				tile.set_terrain(rock)
				
			tile.set_height(randi_range(0, 3))
			
			var new_vector_location:= Vector2i(x,y)
			
			tile.set_vector(new_vector_location)
			
			map[new_vector_location] = tile


##GETS AND SETS##

func get_width() -> int:
	return width

func get_depth() -> int:
	return depth

func get_map() -> Dictionary[Vector2i, GridTile]:
	return map

func get_tile_at_int(current_width: int, current_depth: int) -> GridTile:
	var current_tile: GridTile = map.get(Vector2i(current_width, current_depth))
	return current_tile

func get_tile_at_vector(current_vector: Vector2i) -> GridTile:
	var current_tile: GridTile = map.get(current_vector)
	return current_tile

func set_width(new_width: int):
	width = new_width

func set_depth(new_depth: int):
	depth = new_depth

func set_map(new_map: Dictionary[Vector2i, GridTile]):
	map = new_map.duplicate()
