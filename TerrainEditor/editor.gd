extends Node3D

@export_group("Terrain Palette")
@export var grass: TerrainType
@export var rock: TerrainType

@export_group("Feature Palette")
@export var ramp: FeatureType
@export var building_a: FeatureType
@export var forest: FeatureType

@export_group("Tile Sizing")
@export var tile_size := 1
@export var tile_height_modifier := 2

@export_group("Saving")
@export var save_path: String = "res://Resources/Maps/test_map.tres"

#UI SELECTION
enum EditorMode {
	TERRAIN,
	FEATURES
}
var selected_mode: EditorMode = EditorMode.TERRAIN

#terrain
var selected_terrain: TerrainType = null
var selected_height: int = 0

@onready var selected_terrain_label: Label = $CanvasLayer/VBoxContainer/HBoxContainer/LabelTerrain
@onready var selected_height_label: Label = $CanvasLayer/VBoxContainer/HBoxContainer/LabelHeight

#features
var selected_feature: FeatureType = null
var selected_rotation: TileEnums.TileRotation = TileEnums.TileRotation.NORTH;

#MAP DEFINITION VARIABLES
var map: Dictionary[Vector2i, GridTile] = {}

func _ready():
	print("Map editor ready")
	
##Getting target result from mouse click (rounded to integer values)
func get_grid_from_mouse() -> GridTargetResult:
	var mouse_pos := get_viewport().get_mouse_position()
	var camera := get_viewport().get_camera_3d()

	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_direction := camera.project_ray_normal(mouse_pos)

	var ray_end := ray_origin + ray_direction * 1000.0

	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_end
	)

	var result := get_world_3d().direct_space_state.intersect_ray(query)

	if result:
		var hit_position: Vector3 = result.position

		#print("Clicked world position: ", hit_position)
		var hit_grid: Vector2i = Vector2i(roundi(hit_position.x / tile_size), roundi(hit_position.z / tile_size))
		return GridTargetResult.new(hit_grid, true)
		
	return GridTargetResult.new(Vector2i.ZERO, false)
	
##Creating Grid Tiles
func create_grid_tile(new_height: int, grid_result: GridTargetResult) -> GridTile:
	var tile: GridTile = GridTile.new()
	tile.init_node(grid_result.target, new_height, tile_height_modifier, tile_size)
	add_child(tile.get_main_node())
	return tile

##Placing/Deleting Tiles
func place_terrain(tile: GridTile, grid_result: GridTargetResult):
	tile.set_terrain(selected_terrain)
	tile.create_terrain()
	
	map_add_tile(tile, grid_result)
	
	#print("finished placing tile, position: ", grid_result.target)

func place_feature(tile: GridTile):
	print("adding feature")
	tile.set_feature(selected_feature)
	
	tile.set_rotation(selected_rotation)
	
	tile.create_feature()

func remove_feature(tile: GridTile):
	print("deleting feature")
	tile.delete_feature()

##deleting existing tile on map
func map_remove_tile(grid_result: GridTargetResult):
	#return if no tile at map location
	if not map.has(grid_result.target):
		return

	#collect old tile
	var old_tile: GridTile = map[grid_result.target]

	#delete the scene object through the destroy command, and delete its reference
	old_tile.destroy()
	map.erase(grid_result.target)

##Adding Tile to Map
func map_add_tile(tile: GridTile, grid_result: GridTargetResult):
	map_remove_tile(grid_result)
	map[grid_result.target] = tile
	
##Saving the Map as a proper Map Definition
func map_save():
	if map.is_empty():
		push_warning("Cannot save an empty map")
		return
		
	#firstly, create the map definition resource
	var min_coords: Vector2i = find_min_coords()
	
	var max_x := min_coords.x
	var max_y := min_coords.y
	
	var saved_map: Dictionary[Vector2i, GridTile] = {}
		
	for key: Vector2i in map:
		# Move minimum coordinate to (0, 0)
		var new_key := key - min_coords
		var current_tile = map[key]
		saved_map[new_key] = current_tile
		
		#renaming tile vector
		current_tile.set_vector(new_key)
		
		#finding width/depth
		if key.x > max_x:
			max_x = key.x

		if key.y > max_y:
			max_y = key.y
			
	var width := max_x - min_coords.x + 1
	var depth := max_y - min_coords.y + 1
	
	var new_map_definition: MapDefinition = create_map_definition(saved_map, width, depth)
	
	#Saving the map
	var error := ResourceSaver.save( new_map_definition, save_path )
	
	#Process Save Success
	if error != OK:
		push_error("Failed to save map. Error: " + str(error))
	else:
		print("Map successfully saved to: ", save_path)

func create_map_definition(new_map: Dictionary[Vector2i, GridTile], width: int, depth: int) -> MapDefinition:
	var map_definition: MapDefinition = MapDefinition.new()
	
	map_definition.set_map(new_map)
	map_definition.set_width(width)
	map_definition.set_depth(depth)
	
	return map_definition
	

func find_min_coords() -> Vector2i: # The offset to adjust the map to starting from 0,0 instead of a negative value
	if map.is_empty():
		return Vector2i.ZERO
	
	var min_x: int = map.keys()[0].x
	var min_y: int = map.keys()[0].y
	
	for key in map:
		if (min_x > key.x):
			min_x = key.x
		
		if (min_y > key.y):
			min_y = key.y
	
	return Vector2i(min_x, min_y)

## Process Actions
func process_terrain_action():
	#Get clicked on grid position
	var grid_result = get_grid_from_mouse()
	
	if(grid_result.valid_return == false):
		return
	
	#if selection was successful: place new terrain and add it to the list
	if (selected_terrain != null):
		#print("selected grid tile: ", grid_result.target)
		var new_grid_tile: GridTile = create_grid_tile(selected_height, grid_result)
		place_terrain(new_grid_tile, grid_result)
	
	elif (selected_terrain == null):
		map_remove_tile(grid_result)

func process_feature_action():
	#Get clicked on grid position
	var grid_result = get_grid_from_mouse()
	
	if (grid_result.valid_return == false):
		return
	
	if (map.has(grid_result.target) == false):
		return
	
	var grid_tile: GridTile = map[grid_result.target]
	if (selected_feature != null):
		print("features placement started")
		remove_feature(grid_tile)
		place_feature(grid_tile)
	
	elif (selected_feature == null):
		remove_feature(grid_tile)
	

## UI HANDLE
func _on_tab_container_tab_changed(tab: int) -> void:
	match tab:
		0:
			selected_mode = EditorMode.TERRAIN
		1:
			print("set to features")
			selected_mode = EditorMode.FEATURES


func _on_grass_selected():
	selected_terrain = grass
	selected_terrain_label.text = "Terrain: [Grass]"
	
func _on_dirt_selected():
	selected_terrain = rock
	selected_terrain_label.text = "Terrain: [Dirt]"
	
func _on_blank_selected():
	selected_terrain = null
	selected_terrain_label.text = "Terrain: [Blank]"


func _on_height_updated(value: float):
	selected_height = value
	selected_height_label.text = "Height: [%d]" % selected_height


func _on_feature_ramp_selected():
	selected_feature = ramp
	selected_terrain_label.text = "Feature: [Ramp]"

func _on_feature_building_a_selected():
	selected_feature = building_a
	selected_terrain_label.text = "Feature: [Building A]"

func _on_feature_forest_selected():
	selected_feature = forest
	selected_terrain_label.text = "Feature: [Forest]"

func _on_feature_blank_selected():
	selected_feature = null
	selected_terrain_label.text = "Feature: [Blank]"


func _on_rotation_option_button_item_selected(index: int):
	match index:
		0:
			selected_rotation = TileEnums.TileRotation.NORTH
		1:
			selected_rotation = TileEnums.TileRotation.EAST
		2:
			selected_rotation = TileEnums.TileRotation.SOUTH
		3:
			selected_rotation = TileEnums.TileRotation.WEST

#INPUT HANDLE
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			
			match selected_mode:
				EditorMode.TERRAIN:
					process_terrain_action()
			
				EditorMode.FEATURES:
					print("features selected")
					process_feature_action()
					
	
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
			get_tree().change_scene_to_file("res://MainMenu/main_menu.tscn")

#Independent Classes
class GridTargetResult:
	var target: Vector2i
	var valid_return: bool

	func _init(new_target: Vector2i, is_valid: bool):
		target = new_target
		valid_return = is_valid
