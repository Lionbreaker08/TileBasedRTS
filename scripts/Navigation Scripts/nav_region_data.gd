class_name NavRegionData
extends Resource

@export_group("Region Dimensions")
@export var region_size: Vector2i = Vector2i(1, 1)

@export_group("Navigation Data")
@export var nav_type: TileEnums.NavZoneType = TileEnums.NavZoneType.UNSET
@export var contained_tiles: Array[NavTile] = []

# Runtime reference - not saved
var region_node: NavigationRegion3D = null


func _to_string() -> String:
	if contained_tiles.is_empty():
		return "Nav Region Base: None | Attached Regions: []"

	return "Nav Region Base: %s | Attached Regions: %s" % [
		get_original_tile().get_vector(),
		get_contained_tiles()
	]

func change_nav_settings(nav_settings: NavManager.NavigationSettingVariables, nav_mesh: NavigationMesh):
	nav_mesh.agent_height = nav_settings.agent_height
	nav_mesh.agent_radius = nav_settings.agent_radius
	nav_mesh.agent_max_climb = nav_settings.agent_max_climb
	nav_mesh.agent_max_slope = nav_settings.agent_max_slope
	
	nav_mesh.cell_size = nav_settings.cell_size
	nav_mesh.cell_height = nav_settings.cell_height

func create_nav_region() -> NavigationRegion3D:
	# Avoid creating duplicate regions
	if is_instance_valid(region_node):
		return region_node

	if region_size.x <= 0 or region_size.y <= 0:
		push_error("Cannot create navigation region with invalid size.")
		return null
	
	#Creating physical nav node and setting its name
	var new_region: NavigationRegion3D = NavigationRegion3D.new()
	new_region.name = "NavRegion: %s - %s" % [get_original_tile().get_vector(), (get_original_tile().get_vector() + (region_size - Vector2i.ONE) )]
	region_node = new_region
	
	return new_region

func create_nav_mesh(nav_settings: NavManager.NavigationSettingVariables) -> NavigationMesh:
	#Creating new Nav Mesh (to store mesh data for the nav region)
	var nav_mesh: NavigationMesh = NavigationMesh.new()
	
	change_nav_settings(nav_settings, nav_mesh)
	
	# Setting what meshes for the nav to target (will target mesh groups from syncing) (note: changed group name to target everything)
	nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	
	#Create the variables for nav boundry
	var world_min_y: float = -10.0
	var world_max_y: float = 30.0
	
	var nav_width: float = (get_original_tile().get_tile_size() * region_size.x) + (nav_settings.cell_padding * 2)
	var nav_depth: float = (get_original_tile().get_tile_size() * region_size.y) + (nav_settings.cell_padding * 2)
	var nav_height: float = world_max_y - world_min_y
	
	var region_center: Vector3 = get_region_centre()
	
	var nav_width_offset: float = (nav_width / -2) + get_region_centre().x
	var nav_depth_offset: float = (nav_depth / -2) + get_region_centre().z
	var nav_height_offset: float = world_min_y
	
	#now set the actual nav bounds with AABB
	var nav_bounds: AABB = AABB(Vector3(nav_width_offset, nav_height_offset, nav_depth_offset), Vector3(nav_width, nav_height, nav_depth))
	nav_mesh.filter_baking_aabb = nav_bounds
	
	#extra nav variables
	nav_mesh.border_size = nav_settings.cell_padding
	nav_mesh.edge_max_error = nav_settings.cell_max_error
	
	return nav_mesh

## Getters and Setters

func attach_baked_nav_mesh(baked_nav_mesh: NavigationMesh):
	if (region_node == null):
		push_error("No Region Node Attached (Call create_nav_region)")
	
	#connecting the region
	region_node.navigation_mesh = baked_nav_mesh
	
func append_nav_tile(new_nav_tile: NavTile):
	contained_tiles.append(new_nav_tile)

func get_region_size() -> Vector2i:
	return region_size

func get_region() -> NavigationRegion3D:
	if region_node == null:
		push_error("Region Node not Set")
	
	return region_node

func get_contained_tiles() -> Array[NavTile]:
	return contained_tiles

func get_original_tile() -> NavTile:
	if contained_tiles.is_empty():
		return null
	
	return contained_tiles[0]

func add_region_size(region_increase: Vector2i):
	region_size += region_increase

func get_tile_size() -> float:
	if contained_tiles.is_empty():
		return 1
	
	return get_original_tile().get_tile_size()

func get_nav_mesh() -> NavigationMesh:
	return region_node.navigation_mesh

func get_region_centre() -> Vector3:
	var region_x: float = ((region_size.x - 1) / 2.0) * (get_tile_size())
	var region_z: float = ((region_size.y - 1) / 2.0) * (get_tile_size())
	var centre_point: Vector3 = Vector3(region_x, 0, region_z)
	
	if contained_tiles.is_empty():
		return centre_point
	else:
		var offset_x: float = (get_original_tile().get_vector().x) * get_tile_size()
		var offset_z: float = (get_original_tile().get_vector().y) * get_tile_size()
		return centre_point + Vector3(offset_x, get_original_tile().get_worldspace_height(), offset_z)
