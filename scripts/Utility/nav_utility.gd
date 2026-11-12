class_name NavUtility
extends RefCounted

var nav_manager: NavManager = null

var nav_server: RID

func _init(new_nav_manager: NavManager):
	nav_manager = new_nav_manager
	nav_server = new_nav_manager.get_nav_server()

#for finding a path through a grid (using AStar) (look at AStar to figure out how this works)
func regional_grid_pathfind(starting_tile: NavTile, target_tile: NavTile) -> Array[NavTile]:
	
	var movement_cost_dict: Dictionary[NavTile, float] = {starting_tile: 0}
	var parent_tile_dict: Dictionary[NavTile, NavTile] = {starting_tile: null}
	
	var tiles_to_check: NavPriorityQueue = NavPriorityQueue.new()
	var tiles_checked: Dictionary[NavTile, bool] = {}
	
	tiles_to_check.insert(starting_tile, get_combined_cost(starting_tile, target_tile, movement_cost_dict[starting_tile]))
	
	#loop variables
	var tile_to_check: NavTile = null
	var tile_cost: float = 1
	var route_found: bool = false
	
	while not tiles_to_check.is_empty():
		#Step 1: pop a tile off the priority queue
		tile_to_check = tiles_to_check.pop()
		tile_cost = movement_cost_dict[tile_to_check]
		
		if(tiles_checked.get(tile_to_check, false)):
			continue
		tiles_checked[tile_to_check] = true
		
		if(tile_to_check == target_tile):
			route_found = true
			break
		
		#Step 3 add neighbouring tile data to dictionary
		for neighbour: NavTile in tile_to_check.get_neighbours():
			
			if (tiles_checked.has(neighbour)): 
				continue
			
			var new_tile_cost: float = tile_cost + get_movement_cost_from_tile(neighbour)
			var tile_overall_score: float = get_combined_cost(neighbour, target_tile, new_tile_cost)
			
			#add data if not already checked
			if new_tile_cost < movement_cost_dict.get(neighbour, INF):
				movement_cost_dict[neighbour] = new_tile_cost
				parent_tile_dict[neighbour] = tile_to_check
				tiles_to_check.insert(neighbour, tile_overall_score)
	
	var final_route: Array[NavTile]
	
	if(route_found):
		var current_tile = target_tile
		
		while current_tile != null:
			final_route.append(current_tile)
			current_tile = parent_tile_dict[current_tile]
		final_route.reverse()
	else:
		final_route = []
	
	#Return array of NavTiles to be used to traverse from starting_tile to target_tile
	return final_route

func get_heuristic_from_tile(starting_tile: NavTile, target_tile: NavTile) -> float:
	var starting_vectori: Vector2i = starting_tile.get_vector() 
	var target_vectori: Vector2i = target_tile.get_vector() 
	
	return starting_vectori.distance_to(target_vectori)

func get_movement_cost_from_tile(target_tile: NavTile) -> float:
	
	return target_tile.get_cost()

func get_combined_cost(starting_tile: NavTile, target_tile: NavTile, movement_score: float) -> float:
	
	return movement_score + get_heuristic_from_tile(starting_tile, target_tile)

##Query of actual coordinates to travel
func point_to_point_pathfind(starting_vector: Vector3, ending_vector: Vector3) -> PackedVector3Array:
	if (nav_manager == null):
		push_error("Nav Manager is Null")
		return [0]
	
	var source_tile: NavTile = nav_manager.get_nav_tile_from_world(starting_vector)
	var destination_tile: NavTile = nav_manager.get_nav_tile_from_world(ending_vector)
	
	var selected_tiles: Array[NavTile] = regional_grid_pathfind(source_tile, destination_tile)
	
	if (selected_tiles.is_empty()):
		return [0]
	
	var selected_regions: Array[RID] = nav_tiles_to_region_rids(selected_tiles)
	
	#Creating Query
	var query: NavigationPathQueryParameters3D = NavigationPathQueryParameters3D.new()
	query.map = nav_server
	query.start_position = starting_vector
	query.target_position = ending_vector
	
	# Only use regions selected by hierarchical Astar
	query.included_regions = selected_regions
	
	# We only need the path positions
	query.metadata_flags = NavigationPathQueryParameters3D.PATH_METADATA_INCLUDE_NONE
	
	# Perform the query.
	var result: NavigationPathQueryResult3D = NavigationPathQueryResult3D.new()
	
	NavigationServer3D.query_path(query, result)
	
	for rid: RID in selected_regions:
		var layers: int = NavigationServer3D.region_get_navigation_layers(rid)
	
	
	return result.path

func nav_tiles_to_region_rids(nav_tiles: Array[NavTile]) -> Array[RID]:
	var nav_region_rids: Array[RID]
	print(nav_tiles)
	
	for nav_tile in nav_tiles:
		var nav_region_data: NavRegionData = nav_tile.get_associated_region()
		var nav_region: NavigationRegion3D = nav_region_data.get_region()
		var nav_region_rid = nav_region.get_rid()
		
		if (not nav_region_rids.has(nav_region_rid)):
			nav_region_rids.append(nav_region_rid)
			#print( "Region: ", nav_region, " | Enabled: ", NavigationServer3D.region_get_enabled(nav_region_rid), " | Connections: ", NavigationServer3D.region_get_connections_count(nav_region_rid)," | Iteration: ", NavigationServer3D.region_get_iteration_id(nav_region_rid))
	
	#print(nav_region_rids)
	return nav_region_rids
