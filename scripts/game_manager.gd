class_name GameManager
extends Node3D

@export_group("Sub-Managers")
@export var nav_manager: NavManager = null
@export var terrain_manager: TerrainManager = null



####Utility Managers
var nav_utility_manager: NavUtility = null

##Temp Ball prototype
@export var debug_ball: PackedScene = null
var debug_node: Node3D = null
var source_vector: Vector3 = Vector3(0, 0, 0)
var destination_vector: Vector3 = Vector3(10, 0.375, 10)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Confirming managers are set
	if (terrain_manager == null):
		push_error("Terrain Manager not given to Game Manager")
	
	if (nav_manager == null):
		push_error("Navigation Manager not given to Game Manager")
	
	#awaiting manager init
	await terrain_manager.init_map_loading()
	
	await nav_manager.init_nav()
	
	#Creating Utilities
	nav_utility_manager = NavUtility.new(nav_manager)
	
	#Confirming utilities are set
	if (nav_utility_manager == null):
		push_error("Navigation Utility not given to Game Manager")
		
	
	#GAME
	debug_node = Node3D.new()
	self.add_child(debug_node)


#INPUT HANDLE
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.alt_pressed:
			source_vector = get_world_from_mouse()
			initiate_path()
			
		if event.button_index == MOUSE_BUTTON_RIGHT and event.alt_pressed:
			destination_vector = get_world_from_mouse()
			initiate_path()
	
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
			get_tree().change_scene_to_file("res://MainMenu/main_menu.tscn")


## Place Ball
func initiate_path():
	if debug_node != null:
		self.remove_child(debug_node)
	debug_node = Node3D.new()
	self.add_child(debug_node)
	
	print("QUERY BEGUN")
	var packed_coords: PackedVector3Array = nav_utility_manager.point_to_point_pathfind(source_vector, destination_vector)
	
	if (packed_coords.is_empty()):
		print("no path found")
			
	#print(packed_coords)
	for coord in packed_coords:
		#print("Inserted Coord: ", coord)
		var ball_node: Node3D = debug_ball.instantiate()
		debug_node.add_child(ball_node)
		ball_node.position = coord

 
## Getting world position from mouse click
func get_world_from_mouse() -> Vector3:
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
		return result.position

	return Vector3.INF
