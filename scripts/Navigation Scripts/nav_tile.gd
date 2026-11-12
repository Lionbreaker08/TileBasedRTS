class_name NavTile
extends Resource
#Purpose: Logic resource used to store all navigation data (e.g. portals) for a specific tile

@export var associated_tile: GridTile = null
@export var associated_region: NavRegionData = null
@export var nav_type: TileEnums.NavZoneType = TileEnums.NavZoneType.UNSET

@export var cost: float = 1

var portals: Array[NavPortal] = []
var neighbours: Array[NavTile] = []

func _to_string() -> String:
	return "NavTile: %s"  % associated_tile.get_vector_string()

##Register NavTile (step 1: find associated portals from the navtile, step 2: find neighbours)
func register_portals():
	#print("starting register process")
	if (associated_tile == null):
		push_warning("no tile has been associated with this navtile")
	
	#switch for deciding whether to create or set portals
	match nav_type:
		TileEnums.NavZoneType.UNSET:
			push_warning("Nav Tile has not had its type set")
		
		TileEnums.NavZoneType.COMPLEX: #Complex types will already have the portals set, just need to find them
			for child in associated_tile.get_feature_node().find_children("*", "NavPortal", true, false):
				if child is NavPortal:
					register_portal(child)
		
		TileEnums.NavZoneType.OPEN: #Create portals for open terrain
			associated_tile.attach_auto_portals_to_feature()
			for child in associated_tile.get_feature_node().find_children("*", "NavPortal", true, false):
				if child is NavPortal:
					register_portal(child)



func register_portal(new_portal: NavPortal):
	portals.append(new_portal)
	new_portal.set_nav_tile(self)

func register_neighbours(new_neighbours: Array[NavTile]):
	for neighbour in new_neighbours:
		for portal in portals:
			if (portal.is_colliding_with(neighbour) and not neighbours.has(neighbour)):
				neighbours.append(neighbour)
			
	
	if (not neighbours.is_empty()):
		var debug_string: String = "Tile [%s]: Completed Neighbours: %s" % [self, neighbours]
		print(debug_string)


## GETS AND SETS

func get_height() -> int:
	if associated_tile == null:
		push_warning("NavArea has no associated GridTile")
		return 0
	
	return associated_tile.get_height()

func get_nav_type() -> TileEnums.NavZoneType:
	return nav_type

func get_associated_region() -> NavRegionData:
	return associated_region

func set_nav_type(new_nav_type: TileEnums.NavZoneType):
	nav_type = new_nav_type

func set_associated_tile(new_grid_tile: GridTile):
	associated_tile = new_grid_tile

func set_associated_region(new_region_data: NavRegionData):
	associated_region = new_region_data

func get_vector() -> Vector2i:
	return associated_tile.get_vector()

func get_worldspace_height() -> float:
	if associated_tile == null:
		push_warning("NavArea has no associated GridTile")
		return 0
	
	return associated_tile.get_worldspace_height()

func get_tile_size() -> float:
	if associated_tile == null:
		push_warning("NavArea has no associated GridTile")
		return 0
	
	return associated_tile.get_tile_size()


func get_mesh_group() -> String:
	if associated_tile == null:
		push_warning("NavArea has no associated GridTile")
		return "Error"
	
	return associated_tile.get_group()

func set_mesh_group(group_name: String):
	if associated_tile == null:
		push_warning("NavArea has no associated GridTile")
		return 0
	
	associated_tile.set_group(group_name)

func get_neighbours() -> Array[NavTile]:
	return neighbours

func get_cost() -> float:
	return cost

func get_tile_height_modifier() -> float:
	return associated_tile.get_tile_height_modifier()

func get_tile_thickness() -> float:
	return associated_tile.get_tile_thickness()
