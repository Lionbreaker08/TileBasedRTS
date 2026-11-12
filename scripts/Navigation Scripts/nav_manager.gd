class_name NavManager
extends Node

@export_group("Map Definition")
@export var map_definition: MapDefinition = null

@export var vector_neighbours: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

@export_group("Tile Sizing")
@export var tile_size := 1
@export var tile_height_modifier := 4

@export_group("Nav Mesh Settings")
@export var nav_group_name: String = "NavSelectionGroup"

@export var agent_height := 0.6
@export var agent_radius := 0.2
@export var agent_max_climb := 0.25
@export var agent_max_slope := 60.0
@export var cell_size := 0.15
@export var cell_height := 0.15
@export var cell_padding := 1.0
@export var cell_max_error := 10.8
var nav_settings: NavigationSettingVariables #for saving these details

@export_group("Navigation Data")
@export var nav_map: Dictionary[Vector2i, NavTile] = {}
@export var nav_tile_to_region: Dictionary[NavTile, NavRegionData] = {}
@export var nav_region_datas: Array[NavRegionData] = []
@export var nav_region_max_size: Vector2i = Vector2i(3,3)
var nav_server: RID

@export_group("Debug")
@export var enable_debug_prints: bool = false

func _ready() -> void:
	nav_settings = NavigationSettingVariables.new(agent_height, agent_radius, agent_max_climb, agent_max_slope, cell_size, cell_height, cell_padding, cell_max_error)
	
	nav_server = get_viewport().find_world_3d().navigation_map
	NavigationServer3D.map_set_edge_connection_margin(nav_server, 0.25)
	NavigationServer3D.map_set_use_edge_connections(nav_server, true)
	NavigationServer3D.map_set_cell_size(nav_server,nav_settings.cell_size)
	NavigationServer3D.map_set_cell_height(nav_server,nav_settings.cell_height)
	if enable_debug_prints: print("NAV MANAGER SERVER RID:", nav_server)

#creating the dictionary of all nav tiles based on the tile_map, also forcing nav tiles to register their information
func init_nav():
	if enable_debug_prints: print("nav started")
	
	var tile_map: Dictionary[Vector2i, GridTile] = map_definition.get_map()
	
	##Create Nav Map
	create_nav_map(tile_map)
	
	#Wait one physics frame before continuing the neighbour registration
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	##Call NavTiles to register neighbours
	nav_tiles_register_neighbours()
	
	#Wait one physics frame before continuing
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	##Creating the nav regions
	#new node to act as container for region data objects
	var node_region_container: Node3D = Node3D.new()
	node_region_container.name = "NavRegionContainer"
	self.add_child(node_region_container)
	
	#now create the nav data objects
	create_nav_region_data_objects()
	
	#Now use the data reference to create the actual nav region, then add it as a child to the nav manager
	await create_nav_regions(node_region_container)
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	if(enable_debug_prints):
		for nav_tile: NavTile in nav_map.values():
			print("%s, %s" % [nav_tile.to_string(), nav_tile.get_mesh_group()])
		
		for nav_tile: NavTile in nav_map.values():
			print("%s, %s" % [nav_tile.to_string(), nav_tile.get_associated_region().get_region()])


## Functionality for creating the Nav Map Dictionary

func create_nav_map(tile_map: Dictionary[Vector2i, GridTile]):
	for vector: Vector2i in tile_map:
		var tile: GridTile = tile_map[vector]
		var new_nav_tile = NavTile.new()
		
		#Add new nav tile to our nav map
		nav_map[vector] = new_nav_tile
		
		#also set nav type while we have the grid tile referenced
		var tile_feature: FeatureType = tile.get_feature()
		if (tile_feature != null):
			new_nav_tile.set_nav_type(tile_feature.get_nav_type())
		else:
			new_nav_tile.set_nav_type(TileEnums.NavZoneType.OPEN)
		
		#connect the grid and nav tile together
		new_nav_tile.set_associated_tile(tile)
		
		#finally make nav tile register its portals
		new_nav_tile.register_portals()
		
		#Set the group name for selection (needs to be done after associated tile is set)
		new_nav_tile.set_mesh_group(nav_group_name)

##Functionality to call NavTiles to register neighbours
func nav_tiles_register_neighbours():
	for vector: Vector2i in nav_map:
		var nav_tile: NavTile = nav_map[vector]
		var nav_neighbours: Array[NavTile] = []
		
		for neighbouring_vector in vector_neighbours:
			var new_vector: Vector2i = neighbouring_vector + vector
			
			if nav_map.has(new_vector):
				var nav_neighbour: NavTile = nav_map[new_vector]
				nav_neighbours.append(nav_neighbour)
		
		if (nav_neighbours.is_empty()):
			continue
		
		nav_tile.register_neighbours(nav_neighbours)

## Functionality for creating nav region data objects (so they can merge nav areas together)

func create_nav_region_data_objects():
	for vector: Vector2i in nav_map:
		var nav_tile: NavTile = nav_map[vector]
		
		if nav_tile.get_associated_region() != null:
			continue #continue if nav tile already has region set
		
		var nav_region_data: NavRegionData = NavRegionData.new()
		nav_region_datas.append(nav_region_data)
		
		#assign new region
		nav_tile_to_region[nav_tile] = nav_region_data
		nav_tile.set_associated_region(nav_region_data)
		nav_region_data.append_nav_tile(nav_tile)
		
		#logic to expand nav region if it has open terrain type
		if (nav_tile.get_nav_type() == TileEnums.NavZoneType.OPEN):
			var x_expansion_available: bool = true
			var z_expansion_available: bool = true
			
			while true:
				#detecting if regions at max size
				var region_size = nav_region_data.get_region_size()
				if (region_size.x >= nav_region_max_size.x):
					x_expansion_available = false
				
				if (region_size.y >= nav_region_max_size.y):
					z_expansion_available = false
				
				#expanding
				
				if x_expansion_available:
					x_expansion_available = expand_nav_region_x(nav_region_data)
				
				if z_expansion_available:
					z_expansion_available = expand_nav_region_z(nav_region_data)
				
				#break condition (expansion no longer possible in any direction)
				if (not x_expansion_available and not z_expansion_available):
					break
				

			#while loop end

func expand_nav_region_x(nav_region_data: NavRegionData) -> bool:
	var region_neighbours: Array[NavTile] = find_open_neighbours_x(nav_region_data)
	if region_neighbours.is_empty():
		return false
	
	for neighbour in region_neighbours:
		nav_tile_to_region[neighbour] = nav_region_data
		neighbour.set_associated_region(nav_region_data)
		nav_region_data.append_nav_tile(neighbour)
	
	nav_region_data.add_region_size(Vector2i(1,0))
	return true

func expand_nav_region_z(nav_region_data: NavRegionData) -> bool:
	var region_neighbours: Array[NavTile] = find_open_neighbours_z(nav_region_data)
	if region_neighbours.is_empty():
		return false
	
	for neighbour in region_neighbours:
		nav_tile_to_region[neighbour] = nav_region_data
		neighbour.set_associated_region(nav_region_data)
		nav_region_data.append_nav_tile(neighbour)
	
	nav_region_data.add_region_size(Vector2i(0,1))
	return true

func find_open_neighbours_x(nav_region_data: NavRegionData) -> Array[NavTile]:
	var region_neighbours: Array[NavTile] = []
	
	var central_tile: NavTile = nav_region_data.get_original_tile()
	
	var region_size: Vector2i = nav_region_data.get_region_size()
	
	var neighbour_x: int = region_size.x + central_tile.get_vector().x
	
	for z in range(region_size.y): 
		#Finding new neighbour location
		var neighbour_z: int = z + central_tile.get_vector().y
		var neighbour_vector = Vector2i(neighbour_x,neighbour_z)
		
		#if out of bounds, return empty array to indicate expansion not possible
		if (not nav_map.has(neighbour_vector)):
			return []
		
		#find neighbouring nav tile
		var neighbour_nav_tile: NavTile = nav_map[neighbour_vector]
		
		#if nav tile already has associated region, return empty array to indicate expansion not possible
		if (neighbour_nav_tile.associated_region != null):
			return []
		
		#if not of Nav Open type, return empty array to indicate expansion not possible
		if (neighbour_nav_tile.nav_type != TileEnums.NavZoneType.OPEN):
			return []
		
		#if height doesn't match, return empty array to indicate expansion not possible
		if (central_tile.get_height() != neighbour_nav_tile.get_height()):
			return []
		
		region_neighbours.append(neighbour_nav_tile)
	
	return region_neighbours

func find_open_neighbours_z(nav_region_data: NavRegionData) -> Array[NavTile]:
	var region_neighbours: Array[NavTile] = []
	
	var central_tile: NavTile = nav_region_data.get_original_tile()
	
	var region_size: Vector2i = nav_region_data.get_region_size()
	
	var neighbour_z: int = region_size.y + central_tile.get_vector().y
	
	for x in range(region_size.x): 
		#Finding new neighbour location
		var neighbour_x: int = x + central_tile.get_vector().x
		var neighbour_vector = Vector2i(neighbour_x,neighbour_z)
		
		#if out of bounds, return empty array to indicate expansion not possible
		if (not nav_map.has(neighbour_vector)):
			return []
		
		#find neighbouring nav tile
		var neighbour_nav_tile: NavTile = nav_map[Vector2i(neighbour_x,neighbour_z)]
		
		#if nav tile already has associated region, return empty array to indicate expansion not possible
		if (neighbour_nav_tile.associated_region != null):
			return []
		
		#if not of Nav Open type, return empty array to indicate expansion not possible
		if (neighbour_nav_tile.nav_type != TileEnums.NavZoneType.OPEN):
			return []
		
		#if height doesn't match, return empty array to indicate expansion not possible
		if (central_tile.get_height() != neighbour_nav_tile.get_height()):
			return []
		
		region_neighbours.append(neighbour_nav_tile)
	
	return region_neighbours

##Functionality to create actual nav 3d regions
func create_nav_regions(node_container: Node3D):
	var source_geometry: NavigationMeshSourceGeometryData3D = create_server_nav_mesh()
	
	for nav_region_data in nav_region_datas:
		var new_3d_nav_region: NavigationRegion3D = nav_region_data.create_nav_region()
		node_container.add_child(new_3d_nav_region)
		
		var new_nav_mesh: NavigationMesh = nav_region_data.create_nav_mesh(nav_settings)
		
		
		snap_nav_mesh_vertices(new_nav_mesh, new_3d_nav_region)
		
		nav_region_data.attach_baked_nav_mesh(new_nav_mesh)
		
		NavigationServer3D.bake_from_source_geometry_data(new_nav_mesh, source_geometry)

	print("BAKING FINISHED")

#Creating a heirarchal nav mesh for the server, all baking will be done from this one (for consistency)
func create_server_nav_mesh() -> NavigationMeshSourceGeometryData3D:
	#Creating new Nav Mesh (to store mesh data for all the nav region)
	var server_nav_mesh: NavigationMesh = NavigationMesh.new()
	
	server_nav_mesh.cell_size = nav_settings.cell_size
	server_nav_mesh.cell_height = nav_settings.cell_height
	
	# Setting what meshes for the nav to target (will target mesh groups from syncing) (note: changed group name to target everything)
	server_nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	server_nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	
	#setting the groups
	server_nav_mesh.geometry_source_group_name = nav_group_name
	
	var source_geometry: NavigationMeshSourceGeometryData3D = NavigationMeshSourceGeometryData3D.new()
	
	var parse_root: Node3D = get_tree().current_scene as Node3D
	
	NavigationServer3D.parse_source_geometry_data(server_nav_mesh, source_geometry, parse_root)
	
	return source_geometry

func snap_nav_mesh_vertices(nav_mesh: NavigationMesh, nav_region: NavigationRegion3D) -> void:
	var vertices: PackedVector3Array = nav_mesh.vertices
	
	var snap_size: float = nav_settings.cell_size * 0.1
	
	var transform_to_world: Transform3D = nav_region.global_transform
	var transform_to_local: Transform3D = transform_to_world.affine_inverse()
	
	for i in range(vertices.size()):
		# Convert to world space
		var world_vertex: Vector3 = transform_to_world * vertices[i]
		
		# Snap to the same grid across all regions
		world_vertex = world_vertex.snappedf(snap_size)
		
		# Convert back to the region's local coordinates
		vertices[i] = transform_to_local * world_vertex
	nav_mesh.vertices = vertices
	
	
	# Notify Godot that the navigation mesh geometry has changed.
	nav_mesh.emit_changed()

##GETTERS AND SETTERS

func get_tile_vector_position(tile: NavTile) -> Vector2i:
	return nav_map.find_key(tile)

func get_tile_world_position(vector: Vector2i) -> Vector3:
	var world_pos: Vector3 = Vector3(vector.x * tile_size, 5, vector.y * tile_size)
	
	return world_pos

func get_nav_tile_from_grid_tile(grid_tile: GridTile) -> NavTile:
	if grid_tile == null:
		return null

	return nav_map[map_definition.get_map().find_key(grid_tile)]

func get_grid_tile_from_nav_tile(nav_tile: NavTile) -> GridTile:
	if nav_tile == null:
		return null
	
	
	return map_definition.get_map()[nav_map.find_key(nav_tile)]

# Get NavTile from grid coordinates
func get_nav_tile_from_grid(grid_position: Vector2i) -> NavTile:
	return nav_map.get(grid_position, null)

# Get NavTile from world coordinates
func get_nav_tile_from_world(world_position: Vector3) -> NavTile:
	var grid_position: Vector2i = Vector2i(
		roundi(world_position.x / tile_size),
		roundi(world_position.z / tile_size)
	)
	
	return get_nav_tile_from_grid(grid_position)

func get_nav_server() -> RID:
	return nav_server

#Independent Classes
class NavExpansionQuery:
	var direction: Vector2i
	var nav_region_data: NavRegionData
	var valid_expansion_direction: bool

	func _init(new_direction: Vector2i, new_region_data: NavRegionData):
		direction = new_direction
		nav_region_data = new_region_data
		valid_expansion_direction = true

class NavigationSettingVariables:
	var agent_height: float
	var agent_radius: float
	var agent_max_climb: float
	var agent_max_slope: float
	var cell_size: float
	var cell_height: float
	var cell_padding: float
	var cell_max_error: float

	func _init(new_agent_height: float, new_agent_radius: float,new_agent_max_climb: float,new_agent_max_slope: float,new_cell_size: float,new_cell_height: float, new_cell_padding: float, new_cell_max_error: float):
		
		agent_height = new_agent_height
		agent_radius = new_agent_radius
		agent_max_climb = new_agent_max_climb
		agent_max_slope = new_agent_max_slope
		
		cell_size = new_cell_size
		cell_height = new_cell_height
		cell_padding = new_cell_padding
		cell_max_error = new_cell_max_error
