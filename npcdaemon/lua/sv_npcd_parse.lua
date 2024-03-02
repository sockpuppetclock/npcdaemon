// parsing stuff

module( "npcd", package.seeall )

local node_x_max, node_x_min, node_y_max, node_y_min --= -math.huge, math.huge, -math.huge, math.huge
local nav_x_max, nav_x_min, nav_y_max, nav_y_min --= -math.huge, math.huge, -math.huge, math.huge

// taken from zombie invasion addon, thx
--Taken from nodegraph addon - thx
--Types:
--1 = ?
--2 = info_nodes
--3 = playerspawns
--4 = wall climbers
local SIZEOF_INT = 4
local SIZEOF_SHORT = 2
local AINET_VERSION_NUMBER = 37
local function toUShort(b)
	local i = {string.byte(b,1,SIZEOF_SHORT)}
	return i[1] +i[2] *256
end
local function toInt(b)
	local i = {string.byte(b,1,SIZEOF_INT)}
	i = i[1] +i[2] *256 +i[3] *65536 +i[4] *16777216
	if(i > 2147483647) then return i -4294967296 end
	return i
end
local function ReadInt(f) return toInt(f:Read(SIZEOF_INT)) end
local function ReadUShort(f) return toUShort(f:Read(SIZEOF_SHORT)) end
function ParseFile()
	if found_ain then
		print("npcd > ParseFile > ALREADY PARSED")
		return true
	end

	f = file.Open("maps/graphs/"..game.GetMap()..".ain","rb","GAME")
	if(!f) then
		print("npcd > ParseFile > No nodegraph")
		return nil
	end

	found_ain = true
	local ainet_ver = ReadInt(f)
	local map_ver = ReadInt(f)
	if(ainet_ver != AINET_VERSION_NUMBER) then
		MsgN("npcd > ParseFile > Unknown graph file")
		return false
	end

	local numNodes = ReadInt(f)
	if(numNodes < 0) then
		MsgN("npcd > ParseFile > Graph file has an unexpected amount of nodes")
		return false
	end
	
	// insert node and minmax node
	for i = 1,numNodes do
		local v = Vector(f:ReadFloat(),f:ReadFloat(),f:ReadFloat())
		local yaw = f:ReadFloat()
		local flOffsets = {}
		for i = 1,NUM_HULLS do
			flOffsets[i] = f:ReadFloat()
		end
		local nodetype = f:ReadByte()
		local nodeinfo = ReadUShort(f)
		local zone = f:ReadShort()

		if nodetype == 4 then
			continue
		end
		
		local node = {
			pos = v,
			yaw = yaw,
			offset = flOffsets,
			type = nodetype,
			info = nodeinfo,
			zone = zone,
			neighbor = {},
			numneighbors = 0,
			link = {},
			numlinks = 0
		}

		if !node_x_max or node.pos.x > node_x_max then node_x_max = node.pos.x	end
		if !node_x_min or node.pos.x < node_x_min then node_x_min = node.pos.x	end
		if !node_y_max or node.pos.y > node_y_max then node_y_max = node.pos.y	end
		if !node_y_min or node.pos.y < node_y_min then node_y_min = node.pos.y	end

		table.insert(Nodes,node)
	end

	
	print("npcd > ParseFile > Node count: ".. table.Count( Nodes ) )
	if debugged and node_x_min then
		print("npcd > ParseFile > Node min/max: x: ", node_x_min, " to ", node_x_max, ", y: ", node_y_min, " to ", node_y_max)
	end
	return true
end

function ParseNavmesh()
	if table.IsEmpty(navmesh.GetAllNavAreas()) then
		print("npcd > ParseNavmesh > No navmesh")
		return false
	end
	// minmax navmesh
	for _, nav in pairs(navmesh.GetAllNavAreas()) do
		for c=0,3 do
			local corner = nav:GetCorner(c)
			if !nav_x_max or corner.x > nav_x_max then nav_x_max = corner.x	end
			if !nav_x_min or corner.x < nav_x_min then nav_x_min = corner.x	end
			if !nav_y_max or corner.y > nav_y_max then nav_y_max = corner.y	end
			if !nav_y_min or corner.y < nav_y_min then nav_y_min = corner.y	end
		end
	end

	print("npcd > ParseFile > Navarea count: " .. table.Count( navmesh.GetAllNavAreas() ) )
	if debugged and nav_x_min then
		print("npcd > ParseFile > NAVM x: ", nav_x_min, ", ", nav_x_max, "\t y: ", nav_y_min, ", ", nav_y_max) 
	end
	return true
end

function CalculateMapScale( scale, spawnscale )
	local ms_base = cvar.mapscale.v:GetFloat()
	local ms_spawnbase = cvar.spawnscale.v:GetFloat()
	local ms_base_area = cvar.mapscale_auto_base.v:GetFloat() or ( 10000 * 10000 )
	if ms_base_area == 0 then ms_base_area = 1e-15 end
	local ms_auto = cvar.mapscale_auto.v:GetBool()
	local ms_auto_spawn = cvar.spawnscale_auto.v:GetBool()

	local ms_auto_min = cvar.mapscale_auto_min.v:GetFloat()
	local ms_auto_max = cvar.mapscale_auto_max.v:GetFloat()

	local ms_spawn_auto_min = cvar.spawnscale_auto_min.v:GetFloat()
	local ms_spawn_auto_max = cvar.spawnscale_auto_max.v:GetFloat()

	local ms = scale or ms_base
	local ss = spawnscale or ms_spawnbase
	local nodearea, navarea, nodescale, navscale
	
	// node area
	if node_x_min then
		nodearea = (node_x_max - node_x_min) * (node_y_max - node_y_min)
		nodescale = nodearea / ms_base_area
	end

	// nav area
	if nav_x_min then
		navarea = (nav_x_max - nav_x_min) * (nav_y_max - nav_y_min)
		navscale = navarea / ms_base_area
	end

	// average of node area and nav area
	if ms_auto and (nodescale or navscale) then
		MapScale = ms * math.Clamp( ( ( nodescale or navscale ) + ( navscale or nodescale ) ) / 2 , ms_auto_min, ms_auto_max )
	else
		MapScale = ms
	end
	if ms_auto_spawn and (nodescale or navscale) then
		SpawnMapScale = ss * math.Clamp( ( ( nodescale or navscale ) + ( navscale or nodescale ) ) / 2 , ms_spawn_auto_min, ms_spawn_auto_max )
	else
		SpawnMapScale = ss
	end

	-- if inited then
		print( "npcd > CalculateMapScale > Radius/Spawn Mapscale: " .. MapScale .. " / " .. SpawnMapScale )
	-- end
end