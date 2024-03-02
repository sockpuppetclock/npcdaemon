// NPC DAEMON
// this is my mess

module( "npcd", package.seeall )
AddCSLuaFile()

NPCD_VERSION = 45
--[[
	checkpoints:
		1: initial release
		15: added version numbers
		20: squadpools->spawns profile patch
		26: moved profiles to profiles folder
]]
function RandomColor( huemin, huemax, satmin, satmax, valmin, valmax )
	local hmin = huemin or 0
	local hmax = huemax or 360
	local smin = satmin or 0.5
	local smax = satmax or 1
	local vmin = valmin or 0.5
	local vmax = valmax or 1
	local h = math.Rand( hmin, hmax )
	local s = math.Rand( smin, smax )
	local v = math.Rand( vmin, vmax )
	local col = HSVToColor(h,s,v)
	return Color( col.r, col.g, col.b )
end

function RandomAngle( pmin, pmax, ymin, ymax, rmin, rmax )
	return Angle( math.Rand( pmin or 0, pmax or 0 ), math.Rand( ymin or -180, ymax or 180 ), math.Rand( zmin or 0, zmax or 0 ) )
end

function RandomVector( xmin, xmax, ymin, ymax, zmin, zmax )
	return Vector( math.Rand( xmin or -1, xmax or 1 ), math.Rand( ymin or -1, ymax or 1 ), math.Rand( zmin or -1, zmax or 1 ) )
end

function GetPlyTrPos( ply )
	local ply = ply or SERVER and player.GetAll()[1] or CLIENT and LocalPlayer()
	local tr = ply:GetEyeTrace()
	return tr.HitPos
end

function isint( n )
	return n == math.floor( n )
end

// sequential tables only
function shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

function MaxKey( tbl )
	local max = 0
	for k in pairs( tbl ) do
		if isnumber( k ) then
			max = math.max( max, k )
		end
	end
	return max
end

function IsCharacter( ent )
	return ent:IsNPC() or ent:IsNextBot() or ent:IsPlayer()
end

// https://stackoverflow.com/a/43572223
function to_frac(num, pretty)
	local W = math.floor(num)
	local F = num - W
	local pn, n, N = 0, 1
	local pd, d, D = 1, 0
	local x, err, q, Q
	repeat
		x = x and 1 / (x - q) or F
		q, Q = math.floor(x), math.floor(x + 0.5)
		pn, n, N = n, q*n + pn, Q*n + pn
		pd, d, D = d, q*d + pd, Q*d + pd
		err = F - N/D
	until math.abs(err) < 1e-15
	if pretty then
		return (N + D*W) .. " / " .. D
	else
		return N + D*W, D --, err
	end
end

// iterative table
function ShowFracChanceTbl( total, tbl )
	local debug_ctbl = {}
	-- print("total chance: ".. total)
	for i, e in ipairs(tbl) do
		local d, t, f
		if total != 0 then
			d = e[2] / total
			t, f = to_frac( d )
		else
			d, t, f = 0, 0, 0
		end
		local n = istable( e[1] ) and e[1]["name"] or e[1]
		debug_ctbl[n] = string.format("%d / %d \t ( %d / 100 )", t, f, d * 100 )
	end
	return debug_ctbl
end
// keyvalue table
function ShowFracChanceTbl2( total, tbl, innerkey )
	local debug_ctbl = {}
	-- print("total chance: ".. total)
	for n, ex in pairs( tbl ) do
		local e = innerkey and ex.innerkey or ex
		local d, t, f 		
		if total != 0 then
			d = e / total
			t, f = to_frac( e )
		else
			d, t, f = 0, 0, 0
		end
		
		debug_ctbl[n] = {
			string.format("%d / %d", t, f ),
			string.format("%d / 100", d * 100 )
		}
	end
	return debug_ctbl
end

// roll one winner out of tbl, giving a name (and extra key if included)
function RollExpected(tbl, key, namekey, extrakey)
	if tbl == nil then return nil end
	local chanceTable = {}
	local totalChance = 0
	local newTotalChance = 0
	local winner = nil
	local count = 0
	local key = key or "expected"
	for name, e in pairs( tbl ) do
		local entryname = namekey and e[namekey] or name // what is actually given from winner -- e["presetname"]
		local extra = extrakey and e[extrakey] or nil // extra value given from winner -- e["type"]
		-- print( "roll", entryname, extra )
		if !e[key] then continue end
		if e["npcd_enabled"] == false then continue end

		local chance = e[key]["f"] or 0
		if chance <= 0 then
			continue
		end
		count = count + 1
		totalChance = totalChance + chance
		chanceTable[count] = { entryname, chance, name, extra }
	end

	-- if debugged then PrintTable( ShowFracChanceTbl( totalChance, chanceTable ), 1 ) end
	
	local roll = math.random() * totalChance
	for _, c in pairs(chanceTable) do
		// subtract until <=0
		roll = roll - c[2]
		if roll <= 0 then
			winner = c[1]
			if namekey then
				if extrakey then
					return winner, c[3], c[4] -- + extra
				else
					return winner, c[3] -- winner index
				end
			else
				if extrakey then
					return winner, c[4]
				else
					return winner, c[4]
				end
			end
		end
	end

	-- nothing
	return nil, nil
end

function BuildDatastream( tbl, size )
	local stream = {}
	local c = 1
	local out = util.TableToJSON( tbl )
	// can't compress the full string beforehand because i can't seem to split the compressed data without data lost
	local s = size or cvar.packet_size.v:GetInt() or 2048
	for i=1,#out,s do
		stream[c] = util.Compress( string.sub( out, i, i+s-1 ) )
		c=c+1
	end
	return stream
end

function SendDatastream( netstr, datatbl, ply, server, startdelay )
	if !netstr then return nil end
	local latest = startdelay or 0
	local delay = startdelay or 0
	for i, data in pairs( datatbl ) do
		latest = delay + ( engine.TickInterval() * i )
		timer.Simple( latest, function()
			net.Start( netstr )
				net.WriteFloat( i ) // chknum
				net.WriteUInt( #data, 16 ) // length
				net.WriteData( data, #data ) // data
			if server then
				net.SendToServer()
			elseif IsValid( ply ) then
				net.Send( ply )
			end
		end )
	end
	return latest
end

function FixProfileNames( tbl )
	for pname in pairs( tbl ) do
		for set in pairs( tbl[pname] ) do
			for prs in pairs( tbl[pname][set] ) do
				if isnumber( prs ) then
					local p = tostring( prs )
					tbl[pname][set][p] = tbl[pname][set][prs]
					if tbl[pname][set][prs] == tbl[pname][set][p] then
						tbl[pname][set][prs] = nil
					end
				end
			end
			if isnumber( set ) then
				local s = tostring( set )
				tbl[pname][s] = tbl[pname][set]
				if tbl[pname][set] == tbl[pname][s] then
					tbl[pname][set] = nil
				end
			end
		end
		if isnumber( pname ) then
			local n = tostring( pname )
			tbl[n] = tbl[pname]
			if tbl[pname] == tbl[n] then
				tbl[pname] = nil
			end
		end
	end
end

function FixSingleProfileNames( tbl )
	for set in pairs( tbl ) do
		for prs in pairs( tbl[set] ) do
			if isnumber( prs ) then
				local p = tostring( prs )
				tbl[set][p] = tbl[set][prs]
				if tbl[set][prs] == tbl[set][p] then
					tbl[set][prs] = nil
				end
			end
		end
		if isnumber( set ) then
			local s = tostring( set )
			tbl[s] = tbl[set]
			if tbl[set] == tbl[s] then
				tbl[set] = nil
			end
		end
	end
end

function ReadDatastream( datatbl, total )
	local receive = {}

	local c = 0
	if !table.IsEmpty( datatbl ) then
		for num in ipairs( datatbl ) do
			c = c + 1
		end
	end
	if c != total then
		Error("\nnpcd > INCOMPLETE STREAM RECEIVED: ,", c, " != ", total, "\n" )
		return nil, true
	end

	if !table.IsEmpty( datatbl ) then
		local indat = ""
		for i, data in ipairs( datatbl ) do
			-- print( i, util.Decompress( data ) )
			indat = indat .. util.Decompress( data )
		end
		if CLIENT and cl_cvar.cl_debugged.v:GetBool() or SERVER and debugged then
			print( "data decompressed", #indat )
		end
		receive = util.JSONToTable( indat )
		if receive == "" then
			Error("\nnpcd > INVALID JSON RECEIVED\n" )
			return nil, true
		end
	end

	return receive
end

// fix color metatables recursively
function RecursiveFixUserdata( tbl, hist )
	local h = hist or {}
	for k, v in pairs(tbl) do
		if istable(v) then
			if table.Count(v) == 4 and v["r"] and v["g"] and v["b"] and v["a"] then
				tbl[k] = Color(v["r"], v["g"], v["b"], v["a"])
			end
			if !h[v] then // infinite recursive check
				h[v] = true
				RecursiveFixUserdata( tbl[k], h )
			end
		end
	end
end

// meticulous
local userdata_types = {
	-- ["Entity"]
	-- ["Panel"]
	-- ["Player"]
	["Angle"] = function( t ) return Angle( t[1], t[2], t[3] ) end,
	["Color"] = function( t ) return Color( t[1], t[2], t[3], t[4] ) end,
	["Vector"] = function( t ) return Vector( t[1], t[2], t[3] ) end,
	["default"] = function( t ) return t end,
	["table"] = function( t ) return table.Copy( t ) end,
}

function CopyKeyedData( receive, rk, give, gk )
	-- local typ = type( give[gk] )
	if istable( give[gk] ) then
		receive[rk] = table.Copy( give[gk] )
	-- elseif userdata_types[typ] then
	-- 	print( userdata_types[typ] )
	-- 	receive[rk] = userdata_types[typ]( give[gk] )
	else
		receive[rk] = give[gk]
	end
end

function CopyData( udata )
	local typ = type(udata)
	return istable(udata) and table.Copy(udata) or userdata_types[typ] and userdata_types[typ]( udata ) or userdata_types["default"]( udata )
end

function HasType( test, typ )
	return istable( test ) and table.HasValue( test, typ ) or test == typ
	or t_ANY_TYPES[typ] and ( istable( test ) and table.HasValue( test, "any" ) or test == "any" )
end

function GetType( val, structTbl, fallbackTbl )
	if !structTbl or !structTbl.TYPE then return string.lower( type(val) ) end

	if HasType( structTbl.TYPE, "data" ) then return "data" end
	if HasType( structTbl.TYPE, "info" ) then return "info" end

	if ( val == nil or val == "" ) and HasType( structTbl.TYPE, "any" ) then
		return "any"
	elseif val == nil then
		return fallbackTbl != nil and ( istable( fallbackTbl ) and fallbackTbl[1] ) or nil
	end

	if istable( val ) then
		if HasType( structTbl.TYPE, "preset" ) and ( val["type"] or val["name"] ) then
			return "preset"
		elseif HasType( structTbl.TYPE, "fraction" ) and ( ( val["n"] and val["d"] ) or val["f"] ) then
			return "fraction"
		end

		if val[1] != nil and t_FUNCS[ val[1] ] or isfunction(val[1]) then
			return "function"
		end

		if structTbl.STRUCT then
			if HasType( structTbl.TYPE, "struct_table" ) or ( structTbl.TBLSTRUCT and HasType( structTbl.TBLSTRUCT.TYPE, "struct" ) ) then
				return "struct_table"
			elseif HasType( structTbl.TYPE, "struct" ) then
				return "struct"
			end
		end

		-- if isvector( val ) and HasType( structTbl.TYPE, "vector" ) then
		-- 	return "vector"
		-- else
		-- if isangle( val ) and HasType( structTbl.TYPE, "angle" ) then
		-- 	return "angle"
		-- else
		if IsColor( val ) and HasType( structTbl.TYPE, "color" ) then
			return "color"
		end

		if HasType( structTbl.TYPE, "table" ) then
			return "table"
		end
	else
		if structTbl.ENUM and structTbl.ENUM[val] != nil then
			return "enum"
		elseif isstring( val ) and HasType( structTbl.TYPE, "string" ) then
			return "string"
		elseif isnumber( val ) then
			if isint( val ) and HasType( structTbl.TYPE, "int" ) then
				return "int"
			elseif HasType( structTbl.TYPE, "number" ) then
				return "number"
			end
		elseif isbool( val ) and HasType( structTbl.TYPE, "boolean" ) then
			return "boolean"
		
		// uhh is userdata tables or not?
		elseif isvector( val ) and HasType( structTbl.TYPE, "vector" ) then
			return "vector"
		elseif isangle( val ) and HasType( structTbl.TYPE, "angle" ) then
			return "angle"
		-- elseif IsColor( val ) and HasType( structTbl.TYPE, "color" ) then
		-- 	return "color"
		end
	end

	if !fallbackTbl and structTbl.ENUM_REVERSE and structTbl.ENUM_REVERSE[val] != nil then
		return "enum"
	end

	return fallbackTbl != nil and ( istable( fallbackTbl ) and fallbackTbl[1] ) or nil, true --no match
end

// at some point i feel like my design went out of hand lol
function GetLookup( valueName, typ, structValueName, classname )
	if typ != nil then // entity type
		// has classname
		if classname != nil and t_lookup["class"][typ] and t_lookup["class"][typ][classname] and t_lookup["class"][typ][classname][valueName] then
			// if struct
			if structValueName != nil then
				if t_lookup["class"][typ][classname][valueName].STRUCT and t_lookup["class"][typ][classname][valueName].STRUCT[structValueName] then
					return t_lookup["class"][typ][classname][valueName].STRUCT[structValueName]
				else
					return t_empty
				end
			// not a struct
			elseif t_lookup["class"][typ][classname][valueName] then
				return t_lookup["class"][typ][classname][valueName]
			else
				return t_empty
			end
		// no classname
		elseif t_lookup[typ][valueName] then
			// if struct
			if structValueName != nil then
				if t_lookup[typ][valueName].STRUCT and t_lookup[typ][valueName].STRUCT[structValueName] then
					return t_lookup[typ][valueName].STRUCT[structValueName]
				else
					return t_empty
				end
			else
				return t_lookup[typ][valueName]
			end
		// none of the above
		else
			return t_empty
		end
	else
		// no entity type
		return t_empty
	end
end

// for preset types
function GetPresetName( val )
	return istable( val ) and val["name"] or isstring( val ) and val or nil
end

PERM_CLIENT = 0
PERM_ADMIN = 1
PERM_SUPERADMIN = 2
PERM_NONE = -1
NPCD_DIR = "npcd/"
NPCD_PROFILE_DIR = "npcd/profiles/"
NPCD_LUA_DIR = "npcd/"

t_PERM_STR = {
	[0] = "Client",
	[1] = "Admin",
	[2] = "Superadmin",
	[-1] = "None",
}

spawnpoint_methods = {
	"anywhere",
    "nodes",
	"navmesh",
}

// cvars
cf = { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY }
cfn = { FCVAR_REPLICATED, FCVAR_ARCHIVE }
cvar_order = {
	["TOP"] = 0,
	["Enabled"] = 1,
	["HUD (Client)"] = 2,
	["Auto-Spawner"] = 3,
	["Spawn Radius & Limits"] = 4,
	["Spawning"] = 5,
	["Stress"] = 6,
	["Pressure"] = 7,
	["Player"] = 8,
	["NPC"] = 9,
	["Scheduling"] = 10,
	["Performance"] = 11,
	["Profiles"] = 12,
	["Debug"] = 99,
}

cvar = {
	perm_cvar = {
		v = CreateConVar("npcd_permission_settings", PERM_SUPERADMIN, cf, "ConVar & Actions Permissions. -1: None, 0: Client, 1: Admin, 2: Superadmin. This cvar can only be changed by a superadmin", -1, 2 ),
		t = "int",
		n = "Permissions: Settings",
		c = "Enabled",
		p = PERM_SUPERADMIN,
		sort = "b2",
	},
	perm_prof = {
		v = CreateConVar("npcd_permission_profiles", PERM_SUPERADMIN, cf, "Profile & Preset Configuration Permissions. -1: None, 0: Client, 1: Admin, 2: Superadmin", -1, 2 ),
		t = "int",
		n = "Permissions: Profiles",
		c = "Enabled",
		sort = "b1",
	},
	perm_spawn = {
		v = CreateConVar("npcd_permission_spawning", PERM_SUPERADMIN, cf, "Spawning Permissions. -1: None, 0: Client, 1: Admin, 2: Superadmin", -1, 2 ),
		t = "int",
		n = "Permissions: Spawning",
		c = "Enabled",
		sort = "b3",
	},
	perm_spawn_others = {
		v = CreateConVar("npcd_permission_spawning_others", PERM_SUPERADMIN, cf, "Spawning For Other Players Permissions. -1: None, 0: Client, 1: Admin, 2: Superadmin", -1, 2 ),
		t = "int",
		n = "Permissions: Spawning For Others",
		c = "Enabled",
		sort = "b4",
	},
	debug = {
		v = CreateConVar("npcd_verbose", 0, cf, "Prints more info from functions", 0, 1 ),
		t = "boolean",
		n = "Verbose",
		c = "Debug",
	},
	debug_noplyfix = {
		v = CreateConVar("npcd_ply_nofix", 0, cf, "Some values may remain on players even after respawning or reapplying presets", 0, 1 ),
		t = "boolean",
		n = "Don't Revert Players",
		c = "Player",
	},
	plyprs_doconds = {
		v = CreateConVar("npcd_spawner_ply_conditions", 0, cf, "If true, the player must still pass the player preset's conditions when spawned via spawnmenu", 0, 1 ),
		t = "boolean",
		n = "Require Player Conditions On Spawnmenu",
		c = "Player",
	},
	ply_prs_delay = {
		v = CreateConVar("npcd_ply_preset_delay", 0, cf, "On non-initial player spawn (in ticks)", 0 ),
		t = "int",
		n = "Preset Delay",
		c = "Player",
		altmax = 60,
	},
	ply_prs_delay_first = {
		v = CreateConVar("npcd_ply_preset_delay_first", 2, cf, "On initial player spawn (in ticks)", 0 ),
		t = "int",
		n = "First Preset Delay",
		c = "Player",
		altmax = 60,
	},
	ply_vel = {
		v = CreateConVar("npcd_ply_velocity_ticks", 5, cf, "If greater than 0, tracks player velocity across the given number of ticks. Currently only used in keeping the recent max velocity for damage filter checks" ),
		t = "int",
		n = "Velocity Tracking Ticks",
		c = "Player",
		altmax = 600,
	},
	direct_print = {
		v = CreateConVar("npcd_verbose_spawner", 0, cf, "Print spawn automation results", 0, 1 ),
		t = "boolean",
		n = "Verbose Spawning",
		c = "Debug",
	},
	debug_chase = {
		v = CreateConVar("npcd_verbose_chase", 0, cf, "Verbose and debug NPC scheduling, colors NPCs put on schedule. Blue: idle, Light-blue: forced seekout, Yellow: normal seekout, Green: scheduled, Red: sched fail, Magenta: fail + skip sched", 0, 1 ),
		t = "boolean",
		n = "Debug Chasing",
		c = "Debug",
	},
	cooldown = {
		v = CreateConVar("npcd_spawn_node_cooldown", 12, cf, "Post-spawn cooldown for any recently used map nodes, in seconds" ),
		t = "number",
		n = "Node Cooldown",
		c = "Spawning",
		altmax = 600,
	},
	point_cooldown = {
		v = CreateConVar("npcd_spawn_point_cooldown", 12, cf, "Post-spawn cooldown for the area around any recent navmesh/\"anywhere\" spawnpoints, in seconds" ),
		t = "number",
		n = "Navmesh/Anywhere Cooldown",
		c = "Spawning",
		altmax = 600,
	},
	point_radius = {
		v = CreateConVar("npcd_spawn_point_cooldown_radius", 250, cf, "The radius around any recent navmesh/\"anywhere\" spawnpoint for post-spawn cooldown" ),
		t = "number",
		n = "Navmesh/Anywhere Radius",
		c = "Spawning",
		altmax = 32768,
	},
	preferred_pick = {
		v = CreateConVar("npcd_spawn_pickmethods", "navmesh, nodes, anywhere", { FCVAR_PRINTABLEONLY, FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY }, "All methods the spawnpoint picker will use to determine a spawnpoint. The order written determines priority (first to last). available: nodes, navmesh, anywhere, random. \"random\" overrides other options"),
		t = "string",
		n = "Spawnpoint Pick Methods",
		c = "Spawning",
	},
	fadein = {
		v = CreateConVar("npcd_spawn_fadein_factor", 1.1, cf, "Exponential rate for spawns visually fading in", 1 ),
		t = "number",
		n = "Fade-In Factor",
		c = "Spawning",
		altmax = 2,
	},
	fadein_flat = {
		v = CreateConVar("npcd_spawn_fadein_add", 10, cf, "Flat add for spawns visually fading in" ),
		t = "number",
		n = "Fade-In Add",
		c = "Spawning",
	},
	enabled = {
		v = CreateConVar("npcd_enabled", 1, cf, "Enables all npcd routines", 0, 1),
		t = "boolean",
		n = "NPCD Enabled",
		-- c = "Enabled",
		c = "TOP",
	},
	spawn_enabled = {
		v = CreateConVar("npcd_spawn_enabled", 0, cf, "Enables automated spawning", 0, 1),
		t = "boolean",
		n = "Auto-Spawning",
		-- c = "Enabled",
		c = "TOP",
		sort = "NZ",
	},
	spawn_initdisabled = {
		v = CreateConVar("npcd_spawn_startdisabled", 0, cf, "If true, auto-spawning is always disabled on map start", 0, 1),
		t = "boolean",
		n = "Auto-Spawning Starts Disabled",
		c = "Auto-Spawner",
		sort = "Z",
	},
	chase_enabled = {
		v = CreateConVar("npcd_chase_enabled", 1, cf, "Enables NPCs chasing/seekout", 0, 1),
		t = "boolean",
		n = "NPC Scheduling",
		c = "Enabled",
	},
	stress_enabled = {
		v = CreateConVar("npcd_stress_enabled", 1, cf, "Enables player stress & pressure management, which determines the rate of automatic spawns. If disabled, the spawn rate defaults to the minimum", 0, 1),
		t = "boolean",
		n = "Stress/Pressure",
		c = "Enabled",
	},
	direct_think_range_full = {
		v = CreateConVar("npcd_spawn_think_delay_full", 7, cf, "Min delay between spawns, in seconds (at peak pressure)", 0.1 ),
		t = "number",
		n = "Spawn Rate: Min",
		c = "Auto-Spawner",
		sort = "jSpawn Rate a",
	},
	direct_think_range_zero = {
		v = CreateConVar("npcd_spawn_think_delay_zero", 28, cf, "Max delay between spawns, in seconds (at zero pressure)", 0.1 ),
		t = "number",
		n = "Spawn Rate: Max",
		c = "Auto-Spawner",
		sort = "jSpawn Rate b",
	},
	think_update = {
		v = CreateConVar("npcd_spawn_think_pressureupdate", 0, cf, "If true, update spawn rate whenever pressure changes, instead of after the next time the auto-spawner runs", 0, 1 ),
		t = "boolean",
		n = "Update With Current Pressure",
		c = "Auto-Spawner",
	},
	initspawns = {
		v = CreateConVar("npcd_spawn_on_init", 0, cf, "Number of times to run the spawner on map start"),
		t = "int",
		n = "Runs On Map Start",
		c = "Auto-Spawner",
	},
	initdelay = {
		v = CreateConVar("npcd_spawn_init_delay", 7, cf, "Delay in seconds before spawner begins" ),
		t = "number",
		n = "Start Delay",
		c = "Auto-Spawner",
	},
	spawn_quotaf_min = {
		v = CreateConVar("npcd_spawn_quota_min", 0.05, cf, "Min percentage of pool's limits as entity & squad quotas", 0, 1),
		t = "number",
		n = "Spawn Quota: Min Percent",
		c = "Auto-Spawner",
		sort = "Quota Factor a",
	},
	spawn_quotaf_max = {
		v = CreateConVar("npcd_spawn_quota_max", 0.1, cf, "Max percentage of pool's limits as entity & squad quotas", 0, 1),
		t = "number",
		n = "Spawn Quota: Max Percent",
		c = "Auto-Spawner",
		sort = "Quota Factor b",
	},
	spawn_quotaf_rawmin_spawn = {
		v = CreateConVar("npcd_spawn_quota_raw_min_entity", 1, cf, "If squadpool has entity limit, spawn quota cannot be less than this number" ),
		t = "number",
		n = "Quota Hard Min: Entity",
		c = "Auto-Spawner",
	},
	spawn_quotaf_rawmin_squad = {
		v = CreateConVar("npcd_spawn_quota_raw_min_squad", 1, cf, "If squadpool has squad limit, squad quota cannot be less than this number" ),
		t = "number",
		n = "Quota Hard Min: Squad",
		c = "Auto-Spawner",
	},
	mapscale = {
		v = CreateConVar("npcd_mapscale", 1, cf, "Adjusts all spawn radiuses by this factor. Radiuses that don't allow adjusting are unaffected"),
		t = "number",
		n = "Radius Scale",
		c = "Spawn Radius & Limits",
		altmax = 10,
	},
	spawnscale = {
		v = CreateConVar("npcd_spawnscale_spawn", 1, cf, "Adjusts all spawn limits by this factor. Pools and radiuses that don't allow adjusting are unaffected"),
		t = "number",
		n = "Spawn Scale",
		c = "Spawn Radius & Limits",
		altmax = 10,
	},
	mapscale_auto = {
		v = CreateConVar("npcd_mapscale_auto", 1, cf, "Allow spawn radiuses to be automatically adjusted based on map size", 0, 1),
		t = "boolean",
		n = "Auto-Adjust Radiuses",
		c = "Spawn Radius & Limits",
	},
	spawnscale_auto = {
		v = CreateConVar("npcd_spawnscale_auto", 1, cf, "Allow spawn limits to be automatically adjusted based on map size", 0, 1),
		t = "boolean",
		n = "Auto-Adjust Spawns",
		c = "Spawn Radius & Limits",
	},
	mapscale_auto_base = {
		v = CreateConVar("npcd_mapscale_auto_base", ( 10000 * 10000 ), cf, "Base map area for auto-adjust ratio", 0 ),
		t = "number",
		n = "Auto-Adjust Base",
		c = "Spawn Radius & Limits",
		sort = "bAuto-Adjust Base",
	},
	mapscale_auto_min = {
		v = CreateConVar("npcd_mapscale_auto_min", 0.35, cf, "Min auto-adjust radius scale", 0 ),
		t = "number",
		n = "Radius Auto-Adjust Min",
		c = "Spawn Radius & Limits",
		sort = "Radius Auto-Adjust a",
		altmax = 10,
	},
	mapscale_auto_max = {
		v = CreateConVar("npcd_mapscale_auto_max", 1, cf, "Max auto-adjust radius scale", 0 ),
		t = "number",
		n = "Radius Auto-Adjust Max",
		c = "Spawn Radius & Limits",
		sort = "Radius Auto-Adjust b",
		altmax = 10,
	},
	spawnscale_auto_min = {
		v = CreateConVar("npcd_spawnscale_auto_min", 1, cf, "Min auto-adjust scale for spawn limits", 0 ),
		t = "number",
		n = "Spawn Auto-Adjust Min",
		c = "Spawn Radius & Limits",
		sort = "Spawn Auto-Adjust a",
		altmax = 10,
	},
	spawnscale_auto_max = {
		v = CreateConVar("npcd_spawnscale_auto_max", 1.5, cf, "Max auto-adjust scale for spawn limits", 0 ),
		t = "number",
		n = "Spawn Auto-Adjust Max",
		c = "Spawn Radius & Limits",
		sort = "Spawn Auto-Adjust b",
		altmax = 10,
	},
	idleout = {
		v = CreateConVar("npcd_seekout_idleout_time", 1, cf, "NPCs idle for this many seconds will seekout others. Less than 0 to disable" ),
		t = "number",
		n = "Idle Timeout",
		c = "Scheduling",
		altmin = -1,
	},
	seekout_timeout = {
		v = CreateConVar("npcd_seekout_timeout", 60, cf, "Seekout resets after this many seconds" ),
		t = "number",
		n = "Seekout Timeout",
		c = "Scheduling",
		altmax = 600,
	},
	seekout_timeout_fail = {
		v = CreateConVar("npcd_seekout_timeout_fails", 7, cf, "Seekout resets if schedule doesn't match intended schedule for this many seconds" ),
		t = "int",
		n = "Seekout Fail Timeout",
		c = "Scheduling",
		altmax = 600,
	},
	sched_maxfails = {
		v = CreateConVar("npcd_sched_max_fails", 5, cf, "Will attempt the next schedule down the list if the current intended schedule fails this many times" ),
		t = "int",
		n = "Max Fails",
		c = "Scheduling",
	},
	seekout_mindist_friend = {
		v = CreateConVar("npcd_seekout_idleout_friend_min", 32768, cf, "Seekout ignores NPC's allies within this range. Squadmates are always ignored" ),
		t = "number",
		n = "Seekout: Ally Min Distance",
		c = "Scheduling",
		altmax = 32768,
	},
	seekout_rad_min = {
		v = CreateConVar("npcd_seekout_idleout_rad_min", 300, cf, "Min radius for seekout finding a node around the destination. Does not apply if the map doesn't have a nodegraph" ),
		t = "number",
		n = "Seekout: Node Radius Min",
		c = "Scheduling",
		sort = "Seekout: Node Radius a",
		altmax = 32768,
	},
	seekout_rad_max = {
		v = CreateConVar("npcd_seekout_idleout_rad_max", 1000, cf, "Max radius for seekout finding a node around the destination. Does not apply if the map doesn't have a nodegraph" ),
		t = "number",
		n = "Seekout: Node Radius Max",
		c = "Scheduling",
		sort = "Seekout: Node Radius b",
		altmax = 32768,
	},
	seekout_newposratio = {
		v = CreateConVar("npcd_seekout_forced_newpos_ratio", 1, cf, "When using a forced schedule (SCHED_FORCED_GO, SCHED_FORCED_GO_RUN): If the target's current distance from the last known position is > seeker's distance from target * this ratio, then reset the seekout" ),
		t = "number",
		n = "Seekout: Forced Sched Position Reset Ratio",
		c = "Scheduling",
		altmax = 32768,
	},
	npc_allrelate = {
		v = CreateConVar("npcd_relations_alleveryone", 0, cf, "For NPC relationships. If true, \"everyone\" will also include non-character entities", 0, 1 ),
		t = "boolean",
		n = "\"Everyone\" Relation Includes All",
		c = "NPC",
	},
	coroutineperf = {
		v = CreateConVar("npcd_coroutine_framelimit", 100, cf, "For performance, certain calculations are given \"weight,\" which limits their use per tick. This determines the weight limit before yielding", 1 ),
		t = "number",
		n = "Coroutine Weight Limit",
		c = "Performance",
		altmax = 1000,
	},
	-- groupobb_meticulous = {
	-- 	v = CreateConVar("npcd_spawn_groupobb_meticulous", 0, cf, "For the spawn routine when it is checking potential spawn positions. If true, rechecks the boundaries for all entity presets spawned every time a squad is spawned by spawning a copy of the entity. If false, will reuse the last check for that specific squad/preset combination", 0, 1 ),
	-- 	t = "boolean",
	-- 	n = "Recheck Squad Bounds Every Time",
	-- 	c = "Performance",
	-- },
	plyoverride = {
		v = CreateConVar("npcd_player_presets", 1, cf, "Enables applying player presets on players when they spawn", 0, 1 ),
		t = "boolean",
		n = "Player Presets On Spawn",
		c = "Enabled",
	},
	spawngrid_default = {
		v = CreateConVar("npcd_spawn_spawngrid_default", 50, cf, "When using \"Spawn In Grid\", this is used as the default gap distance. Squads default to spawning in a grid when a nextbot is in the squad"),
		t = "number",
		n = "Spawn Grid Default Gap",
		c = "Spawning",
	},
	rawload = {
		v = CreateConVar("npcd_debug_profile_rawload", 0, cf, "Apply JSON to Profile directly instead of remaking presets internally", 0, 1),
		t = "boolean",
		n = "Load Profile Raw",
		c = "Debug",
	},
	keepold = {
		v = CreateConVar("npcd_debug_profile_keepold", 1, cf, "Keep a copy of the old profile whenever it is saved", 0, 1),
		t = "boolean",
		n = "Keep Profile Copy On Save",
		c = "Profiles",
	},
	stress_breakpoint = {
		v = CreateConVar("npcd_stress_breakpoint", 0.8, cf, nil, 0, 1 ),
		t = "number",
		n = "Breakpoint",
		c = "Stress",
	},
	stress_globalmult = {
		v = CreateConVar("npcd_stress_mult", 1, cf, nil ),
		t = "number",
		n = "Global Multiplier",
		c = "Stress",
		altmin = -256,
	},
	stress_peakmult = {
		v = CreateConVar("npcd_stress_pressurepeak_mult", 1.25, cf, nil ),
		t = "number",
		n = "Peaked Pressure Multiplier",
		c = "Stress",
		altmin = -256,
	},
	stress_decay = {
		v = CreateConVar("npcd_stress_decay", 0, cf ), //0.0018
		t = "number",
		n = "Decay",
		c = "Stress",
		altmin = -1,
		altmax = 1,
	},
	stress_lerpf = {
		v = CreateConVar("npcd_stress_lerpf", 0.51, cf, "Lerp factor for avg to max stress of all players", 0, 1 ),
		t = "number",
		n = "Lerp Factor",
		c = "Stress",
	},
	stress_lerpmethod = {
		v = CreateConVar("npcd_stress_lerpmethod", 1, cf, "Otherwise uses average of all players", 0, 1 ),
		t = "boolean",
		n = "Use Avg-to-Max Lerp",
		c = "Stress",
	},
	stress_plynpc_distdivf = {
		v = CreateConVar("npcd_stress_plydist_divf", 0.2, cf, "add = base / math.max( 1, distance * adjust )" ),
		t = "number",
		n = "Distance: Distance Adjust In Divisor",
		c = "Stress",
		altmin = -256,
	},
	stress_plynpc_distf = {
		v = CreateConVar("npcd_stress_plydist_base", 0.02, cf ),
		t = "number",
		n = "Distance: Base",
		c = "Stress",
		altmin = -256,
	},
	stress_ply_incbase = {
		v = CreateConVar("npcd_stress_ply_dmg_incbase", 0.0028, cf ), //0.0035 
		t = "number",
		n = "Player Incoming Damage Base",
		c = "Stress",
		altmin = -256,
	},
	stress_ply_selfmult = {
		v = CreateConVar("npcd_stress_ply_dmg_selfmult", 0.5, cf ),
		t = "number",
		n = "Player Self Damage Factor",
		c = "Stress",
		altmin = -256,
	},
	stress_ply_outbase = {
		v = CreateConVar("npcd_stress_ply_dmg_outbase", 0.0004, cf ),
		t = "number",
		n = "Player Outgoing Damage Base",
		c = "Stress",
		altmin = -256,
	},
	stress_ply_killf = {
		v = CreateConVar("npcd_stress_ply_dmg_killf", 0.2, cf ),
		t = "number",
		n = "Player Kill Factor",
		c = "Stress",
		altmin = -256,
	},
	stress_ply_death = {
		v = CreateConVar("npcd_stress_ply_death", 0.51, cf ),
		t = "number",
		n = "Player Death",
		c = "Stress",
		altmin = -1,
		altmax = 1,
	},
	prsr_accel_min = {
		v = CreateConVar("npcd_pressure_accel_min", 0.0083, cf, "At peak stress" ),
		t = "number",
		n = "Accel Min",
		c = "Pressure",
		sort = "Accel a1",
		altmin = -1,
		altmax = 1,
	},
	prsr_start = {
		v = CreateConVar("npcd_pressure_init", 0.5, cf, nil, 0, 1 ),
		t = "number",
		n = "Map Start Pressure",
		c = "Pressure",
	},
	prsr_accel_max = {
		v = CreateConVar("npcd_pressure_accel_max", 0.016, cf, "At zero stress" ),
		t = "number",
		n = "Accel Max",
		c = "Pressure",
		sort = "Accel a2",
		altmin = -1,
		altmax = 1,
	},
	prsr_cooldownf = {
		v = CreateConVar("npcd_pressure_cooldownf", 1, cf ),
		t = "number",
		n = "Cooldown Accel Factor",
		c = "Pressure",
		altmin = -256,
	},
	prsr_topf = {
		v = CreateConVar("npcd_pressure_topf", 0.35, cf, "Above half pressure, when rising" ),
		t = "number",
		n = "Top-Half Accel Factor",
		c = "Pressure",
		sort = "Accel factor2",
		altmin = -256,
	},
	prsr_bottomf = {
		v = CreateConVar("npcd_pressure_bottomf", 1, cf, "Below half pressure, when rising" ),
		t = "number",
		n = "Bottom-Half Accel Factor",
		c = "Pressure",
		sort = "Accel factor1",
		altmin = -256,
	},
	chase_mindist = {
		v = CreateConVar("npcd_chase_schedulemin", 0, cf, "Minimum distance from target allowed for scheduling the chaser" ),
		t = "number",
		n = "Chase: Schedule Distance Min",
		c = "Scheduling",
		sort = "Chase: Schedule Distance a",
		altmax = 32768,
	},
	chase_maxdist = {
		v = CreateConVar("npcd_chase_startmax", 32768, cf, "Maximum distance from the potential target allowed for starting a new chase" ),
		t = "number",
		n = "Chase: Start Distance Max",
		c = "Scheduling",
		sort = "Chase: Schedule Distance b",
		altmax = 32768,
	},
	spawner_fadein = {
		v = CreateConVar("npcd_spawner_fadein", 0, cf, "Allow squads fading in when spawned via spawnmenu", 0, 1 ),
		t = "boolean",
		n = "Allow Fade In On Spawnmenu",
		c = "Spawning",
	},
	preset_test = {
		v = CreateConVar("npcd_preset_test", 0, cf, "Tests if preset's classname is valid when creating a preset by attempting to spawn it", 0, 1 ),
		t = "boolean",
		n = "Test Entity Class On Preset Creation",
		c = "Profiles",
	},
	packet_size = {
		v = CreateConVar("npcd_profile_query_size", 4096, cf, "Max network packet size", 1, 15360 ),
		t = "int",
		n = "Query Packet Size",
		c = "Performance",
	},
}

for name, cv in pairs( cvar ) do
	cv.sn = cv.sort or cv.n
end

local perm_chks = {
	[PERM_SUPERADMIN] = function( ply ) return ply:IsSuperAdmin() end,
	[PERM_ADMIN] = function( ply ) return ply:IsAdmin() or ply:IsSuperAdmin() end,
	[PERM_CLIENT] = function( ply ) return ply:IsPlayer() end,
	[PERM_NONE] = function() return false end,
}

function CheckClientPerm( ply, perm )
	local perm = perm or cvar.perm_cvar.v:GetInt()
	return perm_chks[perm] and perm_chks[perm]( ply )
end

include( "npcd_struct.lua" ) // both client and server need this

if SERVER then
	include( "sv_npcd.lua" )
	AddCSLuaFile( "cl_npcd.lua" )
	AddCSLuaFile( "cl_npcd_gui.lua" )
	AddCSLuaFile( "cl_npcd_gui_editor.lua" )
	AddCSLuaFile( "cl_npcd_starterkits.lua" )
	AddCSLuaFile( NPCD_LUA_DIR.."profiles/client/npcd_lua_cl_starter_kit.lua" )
	AddCSLuaFile( NPCD_LUA_DIR.."profiles/client/npcd_lua_cl_chaos_kit.lua" )
	AddCSLuaFile( NPCD_LUA_DIR.."profiles/client/npcd_lua_cl_vip_defense.lua" )
else // CLIENT
	include( "cl_npcd.lua" )
	include( "cl_npcd_gui.lua" )
	include( "cl_npcd_starterkits.lua" )
end