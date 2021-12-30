
//this class tries to clean the streets of 2x2 street tiles.
//

class StreetCleaner
{
	_tickTimerId = null;
	_monthTimerId = null;
	_cityList = null;		// when a city finished processing, it is removed from this list
	_currentCity = null;
	_removedSomething = null;
	_worldsize = null;
	
	constructor()
	{
		_cityList = [];
		_removedSomething = false;
		_worldsize = world.get_size();
		_tickTimerId = 0;
		_monthTimerId = 0;
	}

	function start()
	{
		debugmsg("starting streetcleaner")
		if (_tickTimerId == 0)
			_tickTimerId = gTickRatio.addCallback(tick.bindenv(this), 50);
		if (_monthTimerId == 0)
			_monthTimerId = gTickRatio.addMonthCallback(fillCityList.bindenv(this), 100);
			
		if (_cityList.len() == 0)
			fillCityList();
	}

	function stop()
	{
		debugmsg("stopping streetcleaner")
		gTickRatio.removeCallback(_tickTimerId);
		_tickTimerId = 0;
		gTickRatio.removeCallback(_monthTimerId);
		_monthTimerId = 0;
	}

	function tick()
	{
		//if (_cityList.len() == 0)	// if _cityList empty, get all cities again and start processing again.
		//	fillCityList();

		if (_currentCity == null)
		{
			if(_cityList.len() == 0)
				return; // no cities on map?
			_currentCity = _cityList.pop();
		}
		
		_removedSomething = false;
		process(_currentCity);
		if (!_removedSomething)
			_currentCity = null; // city finished.
	}
	
	function fillCityList()
	{
		local list = city_list_x();
		foreach (c in list)
		{
			//if (c.get_name() == "Radeberg")	//DEBUG
			_cityList.push(c);
		}
		debugmsg("streetcleaner: filling city list. new count: " + _cityList.len())
	}
	
	function process(city)
	{
		// get city borders
		local posNw = city.get_pos_nw();
		local posSe = city.get_pos_se();
		
		debugmsg("city: " + city.get_name() + " cityborder: NW: " + posNw + " SE: " + posSe); 
		
		if (posNw.x > posSe.x)
		{
			local temp = posNw.x;
			posNw.x = posSe.x;
			posSe.x = temp;
		}
		
		if (posNw.y > posSe.y)
		{
			local temp = posNw.y;
			posNw.y = posSe.y;
			posSe.y = temp;
		}
		
		local threeWayTiles = [];
		getThreeWayTiles(posNw, posSe, threeWayTiles);
		
		// search for two adjacent tiles with 2 ways and one adjacent tile with 3 ways.
		debugmsg("search_2_2_3_pattern");
		search_2_2_3_pattern(threeWayTiles);
		
		// search for crossings (4 ways), with diagonal curves.
		if (!_removedSomething)
		{
			debugmsg("search_crossing_with_curve");
			search_crossing_with_curve(threeWayTiles);
		}
		
		if (!_removedSomething)
		{
			debugmsg("search_3way_with_curve");
			search_3way_with_curve(threeWayTiles);
		}
		
		if (!_removedSomething)
		{
			debugmsg("search_crossing_with_3way");
			search_crossing_with_3way(threeWayTiles)
		}
	}
	
	function getThreeWayTiles(posNw, posSe, threeWayTiles)
	{
		for (local x = posNw.x; x <= posSe.x; ++x)
		{
			for (local y = posNw.y; y <= posSe.y; ++y)
			{
				local s = square_x(x,y);
				if (!s.is_valid())
					continue;
					
				local t = s.get_ground_tile();
				if (!t.has_way(wt_road))
					continue;
					
				local dirs = t.get_way_dirs(wt_road);
				if (!dir.is_threeway(dirs))
					continue;
				//if (!is_threeway_only(dirs))
				//	continue;
				
				threeWayTiles.push(t);
			}
		}	
	}
	
	function search_2_2_3_pattern(threeWayTiles)
	{
		foreach (tile in threeWayTiles)
		{
			if (!tile.has_way(wt_road))
				continue;
				
			local dirs = tile.get_way_dirs(wt_road);
			if (!is_threeway_only(dirs))
				continue;
				
			//debugmsg("checking tile: " + coord_to_string(tile));
		
			local two = 0;
			local three = 0;
			local threeDir = 0;
			if (dirs & dir.north)
			{
				//north = y--
				local adjacent = square_x(tile.x, tile.y - 1); //TODO: safety check
				local adjecenttile = adjacent.get_ground_tile();
				
				if (tile_is_twoway_only(adjecenttile))
					++two;
				else if (tile_is_threeway_only(adjecenttile))
				{
					++three;
					threeDir = dir.north;
				}
			}
			if (dirs & dir.east)
			{
				//east = x++
				local adjacent = square_x(tile.x + 1, tile.y); //TODO: safety check
				local adjecenttile = adjacent.get_ground_tile();
				
				if (tile_is_twoway_only(adjecenttile))
					++two;
				else if (tile_is_threeway_only(adjecenttile))
				{
					++three;
					threeDir = dir.east;
				}
			}
			if (dirs & dir.south)
			{
				//south = y++
				local adjacent = square_x(tile.x, tile.y + 1); //TODO: safety check
				local adjecenttile = adjacent.get_ground_tile();
				
				if (tile_is_twoway_only(adjecenttile))
					++two;
				else if (tile_is_threeway_only(adjecenttile))
				{
					++three;
					threeDir = dir.south;
				}
			}
			if (dirs & dir.west)
			{
				//west = x--
				local adjacent = square_x(tile.x - 1, tile.y); //TODO: safety check
				local adjecenttile = adjacent.get_ground_tile();
				
				if (tile_is_twoway_only(adjecenttile))
					++two;
				else if (tile_is_threeway_only(adjecenttile))
				{
					++three;
					threeDir = dir.west;
				}
			}
			
			if (two == 2 && three == 1)
			{
				// remove direction where the 3 is
				dirs = dirs & ~threeDir; 
				
				// remove opposite direction of 3
				local oppositeDir = dir.backward(threeDir);
				if (!(dirs & oppositeDir))
				{
					// we dont have the opposite dir; skip it.
					continue;
				}
				dirs = dirs & ~oppositeDir;
				
				// there can only be one direction left.
				if (!dir.is_single(dirs))
				{
					debugmsg("not a single direction!: " + dirs);
					continue;
					// we have to remove one direction.
					// currently we have two directions and they are opposing; eg N+S, or E+W
				}
				
				//	x x 1 x
				//	x x 2 x x x x x x x x x x
				//	2 3 4 3 3 3 3 2 2 2 1
				//	2 3 3 3 3>3<2 x x x x
				//	x x x x x x x
				//
				// inbetween the 3 and the 2 (in diagonal), there must be another 3.
				
				local diagDir = dirs | threeDir;
				local diagSq = getSquareInDir(tile, diagDir);
				if (diagSq == null)
					continue;
				//debugmsg("checking diagSq: " + coord_to_string(diagSq));
				if (!tile_is_threeway_only(diagSq.get_ground_tile()))   //  && !tile_is_twoway_only(diagSq.get_ground_tile())
				{
					//debugmsg("diag tile " + coord_to_string(diagSq) + " is not a threeway or twoway road tile");
					continue;
				}
			
				
				local sq = getSquareInDir(tile, dirs);
				if (sq == null)
					continue;
				removeRoadFromSquare(sq)
				if (_removedSomething)
					return;
			}
		}
	}
	
	function search_crossing_with_curve(threeWayTiles)
	{
		foreach (tile in threeWayTiles)
		{
			if (!tile.has_way(wt_road))
				continue;
				
			local dirs = tile.get_way_dirs(wt_road);
			if (dirs != dir.all)
				continue;
			
			local curveSq = getCurveOnCrossing(tile, dir.northeast, false);
			if (curveSq != null)
			{
				removeRoadFromSquare(curveSq);
				
			}
			
			curveSq = getCurveOnCrossing(tile, dir.southeast, false);
			if (curveSq != null)
			{
				removeRoadFromSquare(curveSq);
				
			}
				
			curveSq = getCurveOnCrossing(tile, dir.southwest, false);
			if (curveSq != null)
			{
				removeRoadFromSquare(curveSq);
				
			}
				
			curveSq = getCurveOnCrossing(tile, dir.northwest, false);
			if (curveSq != null)
			{
				removeRoadFromSquare(curveSq);
				
			}
			
			if (_removedSomething)
				return;
		}
	}
	
	// returns a square.
	function getCurveOnCrossing(tile, dirs, allow3way)
	{
		local sq = getSquareInDir(tile, dirs);
		if(sq == null)
			return null;
		//debugmsg("getCurveOnCrossing: " + coord_to_string(sq));
		local checkDir = dir.backward(dirs);
		local tile = sq.get_ground_tile();
		if (!tile.has_way(wt_road))
			return null;
		local wayDir = tile.get_way_dirs(wt_road);
		if (!allow3way)
		{
			if (checkDir != wayDir)
				return null;
			return sq;
		}
		
		if ((checkDir & wayDir) != checkDir)
			return null;
			
		if (!is_threeway_only(wayDir))
			return null;
			
		return sq;
	}
	
	//  	
	//  
	//		  
	function search_3way_with_curve(threeWayTiles)
	{
		foreach (tile in threeWayTiles)
		{
			if (!tile.has_way(wt_road))
				continue;
				
			local dirs = tile.get_way_dirs(wt_road);
			if (!is_threeway_only(dirs))
				continue;
				
			//debugmsg("checking tile: " + coord_to_string(tile));
				
			if ((dirs & dir.northeast) == dir.northeast)
			{
				local curveSq = getCurveOnCrossing(tile, dir.northeast, false);
				if (curveSq != null)
					removeRoadFromSquare(curveSq);
			}
			if ((dirs & dir.northwest) == dir.northwest)
			{
				local curveSq = getCurveOnCrossing(tile, dir.northwest, false);
				if (curveSq != null)
					removeRoadFromSquare(curveSq);
			}
			if ((dirs & dir.southeast) == dir.southeast)
			{
				local curveSq = getCurveOnCrossing(tile, dir.southeast, false);
				if (curveSq != null)
					removeRoadFromSquare(curveSq);
			}
			if ((dirs & dir.southwest) == dir.southwest)
			{
				local curveSq = getCurveOnCrossing(tile, dir.southwest, false);
				if (curveSq != null)
					removeRoadFromSquare(curveSq);
			}
			
			if (_removedSomething)
				return;
		}
	}
	
	function search_crossing_with_3way(threeWayTiles)
	{
		foreach (tile in threeWayTiles)
		{
			if (!tile.has_way(wt_road))
				continue;
				
			local dirs = tile.get_way_dirs(wt_road);
			if (dirs != dir.all)
				continue;
			
			
			check3way(tile, dir.northeast);
			check3way(tile, dir.southeast);
			check3way(tile, dir.southwest);
			check3way(tile, dir.northwest);
			
			if (_removedSomething)
				return;
		}
	}
	
	function check3way(tile, dirs)
	{
		local curveSq = getCurveOnCrossing(tile, dirs, true);
		if (curveSq != null)
		{
			local curveTile = curveSq.get_ground_tile();
			local wayDir = curveTile.get_way_dirs(wt_road);
			local remainDir = wayDir & ~dir.backward(dirs); // get the one remaining dir
			local remainSq = getSquareInDir(tile, remainDir); // from source tile in the remaining direction.
			if (remainSq == null)
				return;
			local remainTile = remainSq.get_ground_tile();
			if (remainTile.has_way(wt_road))
			{
				local compareDir = remainTile.get_way_dirs(wt_road);
				if (compareDir & remainDir)
					removeRoadFromSquare(curveSq);
			}
		}
	}
	
	function is_threeway_only(dirs)
	{
		return dir.is_threeway(dirs) && dirs != dir.all;
	}
	
	function is_twoway_only(dirs)
	{
		return dir.is_twoway(dirs) && !dir.is_threeway(dirs) && dirs != dir.all;
	}
	
	function tile_is_twoway_only(tile)
	{
		local dirs = tile.get_way_dirs(wt_road);
		return is_twoway_only(dirs);
	}
	
	function tile_is_threeway_only(tile)
	{
		local dirs = tile.get_way_dirs(wt_road);
		return is_threeway_only(dirs);
	}
	
	function removeRoadFromSquare(square)
	{
		debugmsg("trying to remove way: " + coord_to_string(square));
		local tile = square.get_ground_tile();
		local way = tile.get_way(wt_road);
		if (way == null)
		{
			debugmsg("removeRoadFromSquare: way is null");
			return false;
		}
		if (way.get_owner().nr != 16)
		{
			debugmsg("public player is not owner of " + coord_to_string(square) + " owner: " + way.get_owner().nr);
			return false; // only remove roads from public player
		}
		
		local publicPlayer = player_x(1);
		local cmd = command_x(tool_remover);
		local result = cmd.work(publicPlayer, tile);
		
		_removedSomething = true;
		if (result != null)
			debugmsg(result);
			
		return true; // when we get error from cmd.work, we also say we removed something
	}
	
	function getSquareInDir(tileStart, dirs)
	{
		local x = tileStart.x;
		local y = tileStart.y;
		
		if (dirs & dir.north)
			--y;
		if (dirs & dir.east)
			++x;
		if (dirs & dir.south)
			++y;
		if (dirs & dir.west)
			--x;
			
		local sq = square_x(x,y);
		if (!world.is_coord_valid(sq))
			return null;
		return sq;
	}
}