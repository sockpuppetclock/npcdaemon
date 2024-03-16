module( "npcd", package.seeall )

if !SERVER then return end

util.AddNetworkString("npcd_announce")

util.AddNetworkString("npcd_spawn_count")
util.AddNetworkString("npcd_spawn_count_end")

util.AddNetworkString("npcd_chased")
util.AddNetworkString("npcd_stress_update")
util.AddNetworkString("npcd_ply_preset")

util.AddNetworkString("npcd_cl_ready")
util.AddNetworkString("npcd_cl_settings_act")
util.AddNetworkString("npcd_cl_settings_commit_start")
util.AddNetworkString("npcd_cl_settings_commit_send")
util.AddNetworkString("npcd_cl_settings_commit_end")
util.AddNetworkString("npcd_cl_settings_remove_start")
util.AddNetworkString("npcd_cl_settings_remove_send")
util.AddNetworkString("npcd_cl_settings_remove_end")
util.AddNetworkString("npcd_settings_report_start")
util.AddNetworkString("npcd_settings_report_send")
util.AddNetworkString("npcd_settings_report_end")
util.AddNetworkString("npcd_cl_settings_query")
util.AddNetworkString("npcd_cl_modelviewer")

util.AddNetworkString("npcd_currentprofile")
util.AddNetworkString("npcd_settings_manifest")
util.AddNetworkString("npcd_settings_manifest_end")
util.AddNetworkString("npcd_settings_manifest_start")
util.AddNetworkString("npcd_settings_send")
util.AddNetworkString("npcd_settings_send_end")
util.AddNetworkString("npcd_settings_send_start")

util.AddNetworkString("npcd_cl_cvar")
util.AddNetworkString("npcd_clean")
util.AddNetworkString("npcd_cvar_update")
util.AddNetworkString("npcd_direct")
util.AddNetworkString("npcd_effect_new")
util.AddNetworkString("npcd_fill")
util.AddNetworkString("npcd_init")
util.AddNetworkString("npcd_mapscale_check")
util.AddNetworkString("npcd_ply_clear_history")
util.AddNetworkString("npcd_ply_revert_recheck")
util.AddNetworkString("npcd_profile_reload_all")
util.AddNetworkString("npcd_spawn")

local meta_ent = FindMetaTable("Entity")
local meta_npc = FindMetaTable("NPC")

function meta_ent:GetKeyValue( key )
	return self:GetKeyValues()[key]
end

function meta_ent:AddSpawnFlag( flag )
	self:SetKeyValue("spawnflags", bit.bor( self:GetSpawnFlags(), flag ) )
end

function meta_ent:RemoveSpawnFlag( flag )
	self:SetKeyValue("spawnflags", bit.bxor( self:GetSpawnFlags(), flag ) )
end

function meta_npc:HasCapability( qcap )
	local caps = self:CapabilitiesGet()
	return bit.band( caps, qcap ) > 0
end

function meta_ent:NotDead()
	return not ( self:IsNPC() and self:GetNPCState() == NPC_STATE_DEAD or self:GetMaxHealth() != self:Health() and self:Health() <= 0 or false )
end

Profiles = Profiles or {} // all loaded profiles

Settings = Settings or { // changes with the currently active profile
	["squad"] = {},
	["squadpool"] = {},
	["npc"] = {},
	["entity"] = {},
	["nextbot"] = {},
	["player"] = {},
	["drop_set"] = {},
	["weapon_set"] = {},
}

generic_spawn_announce = {
	-- " has appeared!",
	" have appeared!",
	" have arrived!",
	" appear!",
	-- " have something to say... in the universal language of violence!",
	-- " may or may not have blood to share!",
	-- " jdfsoisoitsddfff!",
	-- " gotta git-git!",
	-- " are gonna ring-a-ding ding hunga hunga waligazoo... and a smokah!",
	-- " suck hard! Hard enough to KILL!",
}

// needed for NPC:AddRelationship()
int_disp_t = {
	[0] = "D_ER",
	[1] = "D_HT",
	[2] = "D_FR",
	[3] = "D_LI",
	[4] = "D_NU",
}

t_valid_drop_presets = {
	["npc"] = true,
	["squad"] = true,
	["drop_set"] = true,
	["weapon_set"] = true,
	["entity"] = true,
	["nextbot"] = true,
}

t_weapon_inherit = {
	"renderamt",
	"startalpha",
	"scale",
	"rendercolor",
	"rendermode",
	"renderfx",
	"material",
	"jiggle_all",
}

// classes exempt from "everyone" dispositions
t_disp_everyone_exceptions = {
	["npc_bullseye"] = true,
	["bullseye_strider_focus"] = true,
}

inited = false
readied = false
init_spawndelay = 3.5
inittime = nil
direct_start_time = 0
b_FirstRun = nil

preset_updatecount = nil

PatchInform = nil
PatchInformList = {}

thinkTimeRange = { 5, 30 }
lastThink = 0
nextThink = math.huge
lastCool = 0

chaseDelay = 1
stressDelay = 1
lastStress = 0.5
lastChase = 0

countupdated = nil
nextinform = 0

cold_nodes = nil
hot_nodes = nil
hot_points = {}

pickMethods = nil
pickRandom = nil

HasNavMesh = nil
HasNodes = nil

MapScale = 1
SpawnMapScale = 1

cachedEffects = {}
cachedModels = {}
knownBounds = {}
knownBoundsEnt = {}

directQueue = {}
spawnerQueue = {} // for spawnmenu spawns
messageQueue = {}

activeNPC = activeNPC or {} // npcd entities
activePly = activePly or {} // player presets
activeFade = activeFade or {} // spawn fade-ins
activeEffect = activeEffect or {} // continuous effects
activeRag = activeRag or {} // ragdolls to be removed
activeCollide = activeCollide or {} // physics collide callback EntRamming()
activeSound = activeSound or {} // for stopping looping sounds
activeCallback = activeCallback or {} // entity callbacks
ply_preset_deaths = {} // player killed-by-preset history
ply_preset_hist = {} // player preset history

pool_times = {}
squad_times = {}

stress = 0
pressure = 0
prsr_accel = 0
v_stress = v_stress or {} // stress/pressure cvars
stress_activemult = nil

direct_times = {}

currentProfile = nil
lastSwitched = nil

local sent_settings = {} // last sent profile to player
local last_queried = {} // last player query times
local sent_manifest = {} // last sent manifest to player
updated_profiles = {} // last time profile was updated
local prof_manifest = {} // profile manifest with spawn counts
debugged = cvar.debug.v:GetBool()
debugged_more = cvar.debug.v:GetInt() > 1
debugged_spawner = cvar.direct_print.v:GetBool()
debugged_chase = cvar.debug_chase.v:GetBool()

local sending = {}

local reports = {}
local commit_streams = {}
local remove_streams = {}

timerc = timerc or 0

routines = {}
coiter = 0
coiter_limit = cvar.coroutineperf.v:GetFloat()

// attempt to workaround an engine-level bug
modelfixes = {
	["npc_fastzombie"] = "models/zombie/fast.mdl",
	["npc_zombie"] = "models/zombie/classic.mdl",
	["npc_zombine"] = "models/zombie/zombie_soldier.mdl",
}

include( "sv_npcd_active.lua" )
include( "sv_npcd_chase.lua" )
include( "sv_npcd_damage.lua" )
include( "sv_npcd_direct.lua" )
include( "sv_npcd_entity.lua" )
include( "sv_npcd_parse.lua" )
include( "sv_npcd_player.lua" )
include( "sv_npcd_preset.lua" )
include( "sv_npcd_profile.lua" )
include( "sv_npcd_spawn.lua" )
include( "sv_npcd_stress.lua" )

// init and thinking stuff

function Cleanup( clear )
	for ent in pairs( activeNPC ) do
		if !IsValid( ent ) then
			activeNPC[ent] = nil
		elseif clear then
			activeNPC[ent] = nil
			ent:Remove()
		end
	end
	for _, tbl in ipairs( { activePly, activeFade, activeCollide } ) do
		for ent in pairs( tbl ) do
			if clear or !IsValid( ent ) then
				tbl[ent] = nil
			end
		end
	end
	activeRag = {} // k = entity ids

	if clear then
		for ply in pairs( activePly ) do
			if IsValid( ply ) then
				FixPlayer( ply )
				net.Start( "npcd_ply_preset" )
					net.WriteString("")
				net.Send( ply )
			end
		end
		activePly = {}
	end

	ply_preset_deaths = {}
	ply_preset_hist = {}
	
	for ent in pairs( activeCallback ) do
		if IsValid( ent ) then
			if clear or activeNPC[ent] == nil then
				for name, id in pairs( activeCallback[ent] ) do
					ent:RemoveCallback( name, id )
				end
				activeCallback[ent] = nil
			end
		else
			activeCallback[ent] = nil
		end
	end
end

function Init()
	local initst = CurTime()
	if debugged then
		print("npcd > Init > Starting...")
	end
	directQueue = {}
	spawnerQueue = {}
	messageQueue = {}

	Cleanup()	

	sent_settings = {} 
	sent_manifest = {}
	updated_profiles = {}
	prof_manifest = {}

	pool_times = {}
	squad_times = {}
	direct_times = {}

	thinkTimeRange = GetThinkRange()

	UpdateStressCVars()
	UpdateChaseCVars()
	
	// get all nav points
	found_ain = false
	Nodes = {}
	HasNodes = ParseFile()
	if HasNodes == nil then // no file, try again
		timer.Simple(8, function()
			HasNodes = ParseFile()
			if HasNodes == true then cold_nodes = table.Copy(Nodes) end
		end)
	end
	cold_nodes = table.Copy(Nodes)
	hot_nodes = {}
	hot_points = {}

	HasNavMesh = ParseNavmesh()
	CalculateMapScale()
	pickMethods, pickRandom = GetPickMethods()

	cachedEffects = cachedEffects or {}
	cachedModels = cachedModels or {}

	-- for _, ply in ipairs( player.GetAll() ) do
	-- 	ply.npcd_stress = 0
	-- end
	ResetStress( true )
	pressure = cvar.prsr_start.v:GetFloat()
	-- stress = 0
	lastStress = CurTime() + 0.5
	lastChase = CurTime()
	
	// load settings
	StartupLoad()

	// coroutines
	coiter = 0
	coiter_limit = cvar.coroutineperf.v:GetFloat()
	routines = {}

	AddRoutine( "chase", ChaseRoutine )
	AddRoutine( "stress", StressRoutine )
	AddRoutine( "direct", DirectRoutine )
	AddRoutine( "inform", InformClientRoutine )
	AddRoutine( "spawner", SpawnerRoutine )
	AddRoutine( "cooler", CoolerRoutine )

	if cvar.spawn_initdisabled.v:GetBool() then
		cvar.spawn_enabled.v:SetBool( false )
	end
	
	// inited
	-- if debugged then
		print("npcd > Init > Started at ".. math.Round(CurTime(),3) .."s.")
		-- print("\tActive Profile: "..tostring(currentProfile) )-- - initst .. "s")
	-- end
	inited = true
	countupdated = true
	nextinform = CurTime()
	inittime = CurTime()
	direct_start_time = CurTime() + cvar.initdelay.v:GetFloat()
	nextThink = CurTime() + ( thinkTimeRange[1] )
end

function Think()
	if !inited or !cvar.enabled.v:GetBool() then return end

	FadeIns()
	DoActiveEffects()
	
	DoAllRoutines()
	
	// message queue
	DoMessageQueue()
end


// cvar/command stuff

callback_func = {
	["Stress"] = function( var )
		cvars.AddChangeCallback( var, UpdateStressCVars )
	end,
	["Pressure"] = function( var )
		cvars.AddChangeCallback( var, UpdateStressCVars )
	end,
	["Spawn Radius & Limits"] = function( var )
		cvars.AddChangeCallback( var, function() CalculateMapScale() end )
	end,
	["Scheduling"] = function( var )
		cvars.AddChangeCallback( var, UpdateChaseCVars )
	end,
}

for _, cv in pairs( cvar ) do
	local var = cv.v:GetName()

	if callback_func[cv.c] then callback_func[cv.c]( var ) end

	cvars.AddChangeCallback( var, function()
		net.Start( "npcd_cvar_update" )
		net.Broadcast()
	end )
end


// cvar callbacks
cvars.AddChangeCallback( cvar.preferred_pick.v:GetName(), function()
	npcd.pickMethods, npcd.pickRandom = npcd.GetPickMethods()
end)
cvars.AddChangeCallback( cvar.debug.v:GetName(), function( cvar, old, new )
	npcd.debugged = tobool(new)
	print( "npcd_verbose = ", npcd.debugged )
end )
cvars.AddChangeCallback( cvar.coroutineperf.v:GetName(), function( cvar, old, new )
	npcd.coiter_limit = tonumber(new)
end )
cvars.AddChangeCallback("npcd_verbose_spawner", function( cvar, old, new )
	npcd.debugged_spawner = tobool(new)
	print( "npcd_verbose_spawner = ", npcd.debugged_spawner )
end )
cvars.AddChangeCallback("npcd_verbose_chase", function( cvar, old, new )
	npcd.debugged_chase = tobool(new)
	print( "npcd_verbose_chase = ", npcd.debugged_chase )
end )

local netcvar_get = {
	[1] = function() return net.ReadBool() end,
	[2] = function() return net.ReadFloat() end,
	[3] = function() return net.ReadFloat() end,
	[4] = function() return net.ReadString() end,
}
local netcvar_set = {
	[1] = function( cvar, val ) cvar:SetBool( val ) end,
	[2] = function( cvar, val ) cvar:SetFloat( val ) end,
	[3] = function( cvar, val ) cvar:SetInt( val ) end,
	[4] = function( cvar, val ) cvar:SetString( val ) end,
}

// cvar changed by client
net.Receive( "npcd_cl_cvar", function( len, ply )
	if IsValid( ply )  and ply:IsPlayer() then
		local varname = net.ReadString()
		local typ = net.ReadUInt( 4 )
		local val

		if !CheckClientPerm( ply, cvar[varname].p or nil ) then
			print( "npcd > npcd_cl_cvar > ",ply, " does not have permission")
			return
		end

		if !netcvar_get[typ] then return end
		local val = netcvar_get[typ]()
		-- if typ == 1 then // boolean
		-- 	val = net.ReadBool()
		-- elseif typ == 2 or typ == 3 then // number, int
		-- 	val = net.ReadFloat()
		-- elseif typ == 4 then // string
		-- 	val = net.ReadString()
		-- else
		-- 	return
		-- end

		if cvar[varname] != nil then
			netcvar_set[typ]( cvar[varname].v, val )
			-- if typ == 1 then // boolean
			-- 	cvar[varname].v:SetBool( val )
			-- elseif typ == 2 then // number
			-- 	cvar[varname].v:SetFloat( val )
			-- elseif typ == 3 then // int
			-- 	cvar[varname].v:SetInt( val )
			-- elseif typ == 4 then // string
			-- 	cvar[varname].v:SetString( val )
			-- end
		end
	else
		print( "npcd > npcd_cl_cvar > ",ply , " is not valid")
	end
end )


// commands

concommand.Add( "npcd_init", function( ply )
	if CheckClientPerm( ply ) then
		Init()
		InitSpawns()
	end
end )
net.Receive( "npcd_init", function( len, ply )
	if CheckClientPerm( ply ) then
		Init()
		InitSpawns()
	end
end )

concommand.Add( "npcd_clean", function( ply )
	if CheckClientPerm( ply ) then
		Cleanup( true )
	end
end )
net.Receive( "npcd_clean", function( len, ply )
	if CheckClientPerm( ply ) then
		Cleanup( true )
	end
end )

concommand.Add( "npcd_mapscale_check", function( ply )
	if CheckClientPerm( ply ) then
		CalculateMapScale()
	end
end )
net.Receive( "npcd_mapscale_check", function( len, ply )
	if CheckClientPerm( ply ) then
		CalculateMapScale()
	end
end )

concommand.Add( "npcd_fill", function( ply )
	if CheckClientPerm( ply, cvar.perm_spawn.v:GetInt() ) then
		table.insert(directQueue, {-1, -1} )
	end
end )
net.Receive( "npcd_fill", function( len, ply )
	if CheckClientPerm( ply, cvar.perm_spawn.v:GetInt() ) then
		table.insert(directQueue, {-1, -1} )
	end
end )

concommand.Add( "npcd_direct", function( ply )
	if CheckClientPerm( ply, cvar.perm_spawn.v:GetInt() ) then
		table.insert(directQueue, {} )
	end
end )
net.Receive( "npcd_direct", function( len, ply )
	if CheckClientPerm( ply, cvar.perm_spawn.v:GetInt() ) then
		table.insert(directQueue, {} )
	end
end )

concommand.Add( "npcd_ply_clear_history", function( ply )
	if CheckClientPerm( ply ) then
		ply_preset_deaths = {}
		ply_preset_hist = {}
	end
end )
net.Receive( "npcd_ply_clear_history", function( len, ply )
	if CheckClientPerm( ply ) then
		local str = net.ReadString()
		ply_preset_deaths = {}
		ply_preset_hist = {}
	end
end )

concommand.Add( "npcd_ply_revert_recheck", function( ply )
	if CheckClientPerm( ply ) then
		for _, p in ipairs( player.GetAll() ) do
			GetRevertValues( p, true )
		end
	end
end )
net.Receive( "npcd_ply_revert_recheck", function( len, ply )
	if CheckClientPerm( ply ) then
		for _, p in ipairs( player.GetAll() ) do
			GetRevertValues( p, true )
		end
	end
end )

net.Receive( "npcd_spawn", function( len, ply )
	if CheckClientPerm( ply, cvar.perm_spawn.v:GetInt() ) then
		local prof = net.ReadString()
		local typ = net.ReadString()
		local str = net.ReadString()
		local targ = net.ReadEntity()

		if prof != currentProfile then
			net.Start( "npcd_announce" )
				net.WriteString( "Spawn request does not match with current profile. " .. prof .. " != " .. currentProfile )
				net.WriteColor( RandomColor( 0, 15, 0.75, 1, 1, 1 ) )
			net.Send( ply )
			return
		end
		
		if !IsValid( targ ) then
			net.Start( "npcd_announce" )
				net.WriteString( "Target is invalid" )
				net.WriteColor( RandomColor( 0, 15, 0.75, 1, 1, 1 ) )
			net.Send( ply )
			return
		end
		
		if !CheckClientPerm( ply, cvar.perm_spawn.v:GetInt() ) and targ != ply then
			net.Start( "npcd_announce" )
				net.WriteString( "You do not have permission to spawn presets on other players!" )
				net.WriteColor( RandomColor( 0, 15, 0.75, 1, 1, 1 ) )
			net.Send( ply )
			return
		end
		
		if typ == "" then typ = nil end

		// do spawn
		TargetSpawnPreset( targ, typ, str, ply )		

	elseif IsValid( ply ) then
		net.Start( "npcd_announce" )
			net.WriteString( "You do not have permission to spawn presets!" )
			net.WriteColor( RandomColor( 0, 15, 0.75, 1, 1, 1 ) )
		net.Send( ply )
	end
end )
concommand.Add( "npcd_spawn", function( ply, cmd, args, argstr )
	TargetSpawnPreset( ply, nil, argstr, ply )
end,
function(cmd, stringargs)
	if table.IsEmpty( Settings ) then return end
	stringargs = string.Trim( stringargs )
	stringargs = string.lower( stringargs )

	local tbl = {}
	local keyt = {}
	for _, t in pairs( table.GetKeys(Settings.squad) ) do
		keyt[t] = t
	end
	for _, typ in ipairs( { "npc", "nextbot", "entity" } ) do
		for _, t in pairs( table.GetKeys(Settings[typ]) ) do
			keyt[t] = t
		end
	end
	for k, v in SortedPairs(keyt) do
		if string.StartWith( string.lower( v ), stringargs ) then				
			table.insert(tbl, cmd .. " " .. v )
		end
	end
	return tbl
end,
"Spawn given squad/entity preset. If names conflict, will prefer squad > npc > nextbot > entity.",
{ FCVAR_PRINTABLEONLY } )


// coroutines stuff

function DoAllRoutines()
	for name in pairs( routines ) do
		DoRoutine( name )
	end
end

function AddRoutine( name, func )
	if !name or !isfunction( func ) then return end
	routines[name] = {}
	routines[name].func = func
	-- routines[name].cr = nil
end

-- routine_dead = {
--    ["dead"] = true
-- }

function DoRoutine( name )
	if !routines[name] then
		Error( "npcd > DoRoutine > Invalid routine: ", name )
		return
	end
	local noerred, err
   if routines[name].cr then
		noerred, err = coroutine.resume( routines[name].cr )
		if !noerred or err then Error("\n[NPC Daemon] [Coroutine \"" .. name .. "\"]", err,"\n\n") end
	end
	if ( !routines[name].cr or !noerred ) then
		routines[name].cr = coroutine.create( routines[name].func )
	end
end

function CoIterate( add )
	if coroutine.running() then
		coiter = coiter + (add or 100)
		if coiter >= coiter_limit then
			coiter = 0
			coroutine.yield()
		end
	end
end

function DirectRoutine()
	if !coroutine.running() then return end
	local drtime = nil
	while true do
		coroutine.yield()
		local dq = directQueue

		if ( cvar.spawn_enabled.v:GetBool() and ( CurTime() > direct_start_time and CurTime() > nextThink ) or !table.IsEmpty(dq) ) then
			drtime = drtime or CurTime()

			DoDirects()

			if table.IsEmpty(dq) then
				if debugged then print("npcd > DirectRoutine > Finished thunk in ".. CurTime() - (drtime or 0) ) end
				drtime = nil
			end

			if CurTime() > nextThink then
				lastThink = CurTime()
				thinkTimeRange = GetThinkRange()
				nextThink = CurTime() + Lerp(1 - pressure, thinkTimeRange[1], thinkTimeRange[2]) --more pressure = faster

				if debugged then
					print("npcd > t:"..CurTime().."\t nextthunk in: "..(nextThink - lastThink).." ("..math.Round(lastThink,3).." -> "..math.Round(nextThink,3)..")")
					print("npcd > stress:"..stress.."\t pressure:"..pressure.."\t prsr_accel:"..prsr_accel)
				end
			end
		else
			table.Empty( directQueue )
		end
	end
end

function CoolerRoutine()
	if !coroutine.running() then return end
	while true do
		coroutine.yield()
		CoolNodes()
		CoolPoints()
	end
end

function SpawnerRoutine()
	if !coroutine.running() then return end
	local drtime = nil
	while true do
		coroutine.yield()
		local sq = spawnerQueue

		if !table.IsEmpty(sq) then
			-- local k, todo = next(sq)
			local done = {}
			for k, todo in ipairs( sq ) do
				-- local s = CurTime()
				if todo.squad then
					local _, newsquad = SpawnSquad( todo.squad, todo.pos, todo.announce, todo.fadein )
					if newsquad and !table.IsEmpty( newsquad ) then
						if todo.undo then
							undo.Create( todo.squad.name )
								for _, ent in pairs( newsquad ) do
									undo.AddEntity( ent )
								end
								undo.AddFunction( function( tab )
									for _, ent in pairs( newsquad ) do
										if !IsValid( ent ) then
											activeNPC[ent] = nil
										else
											activeNPC[ent] = nil
											ent:Remove()
										end
									end
								end )
								undo.SetPlayer( todo.undo )
							undo.Finish()
						end
					end
				end
				if todo.drop then
					DoDrops( todo.ent, todo.pos, todo.ang, todo.drop, todo.ntbl )
				end
				done[k] = k
				-- print( k.." in " .. math.Round(CurTime() - s,3) )
			end
			for _, k in pairs( table.Reverse( done ) ) do
				table.remove( spawnerQueue, k )
			end
		end
	end
end

function ChaseRoutine()
	if !coroutine.running() then return end
	while true do
		coroutine.yield()
		if cvar.chase_enabled.v:GetBool() and CurTime() - lastChase > chaseDelay then
			ManageSchedules()
			lastChase = CurTime()
		end
	end
end

function StressRoutine()
	if !coroutine.running() then return end
	while true do
		coroutine.yield()
		if CurTime() - lastStress > stressDelay then
			StressOut()
			lastStress = CurTime()
		end
	end
end

local uids = {}
function DoMessageQueue()
	for i, msgtbl in ipairs(messageQueue) do
		if msgtbl["msg"] then
			if msgtbl["uid"] then
				// skip if already sent or mark as sent
				if uids[msgtbl["uid"]] then
					continue
				else
					uids[msgtbl["uid"]] = true
				end
			end
			net.Start("npcd_announce")
				net.WriteString( msgtbl["msg"] )
				net.WriteColor( msgtbl["col"] or RandomColor( nil, nil, nil, nil, 1, 1 ) )
			net.Broadcast()
		end
	end
	messageQueue = {}
end


// client inform stuff

net.Receive("npcd_cl_ready", function( len, ply )
	if IsValid(ply) and ply:IsPlayer() then
		ply.npcd_stress = 0
		countupdated = true
		SendSettingsQuery( ply, true )
		SendPrecachedEffects( ply )
		if b_FirstRun then
			net.Start( "npcd_announce" )
				net.WriteString( "NPC Daemon is now installed, NPCD tab & toolmenu have been added.\nAuto-spawning is initially disabled, and can be enabled in the tab or toolmenu options." )
				net.WriteColor( RandomColor( 50, 55, 0.5, 1, 1, 1 ) )
			net.Send( ply )
		end
      // inform of preset patches that occured before loading in
		if PatchInform and CurTime() <= PatchInform then
			for _, msg in ipairs( PatchInformList ) do
				net.Start( "npcd_announce" )
					net.WriteString( msg )
					net.WriteColor( RandomColor( 50, 55, 0.5, 1, 1, 1 ) )
				net.Send( ply )
			end
		end
	end
end)

function InformClientRoutine()
	countupdated = true
	while true do
		coroutine.yield()
		
		if CurTime() > nextinform then
			// send spawn counts
			if countupdated then
				for p, ptbl in pairs( Settings.squadpool ) do
					if ptbl["npcd_enabled"] == false then continue end
					local sqc = Settings.squadpool[p]["squads"] and select( 2, CountSquads( nil, p ) ) or 0
					local psum, pcount = NPCMapCount( p )
					net.Start("npcd_spawn_count")
						net.WriteString( p )
						net.WriteFloat( psum )
						net.WriteFloat( pcount ) //unweighted
						net.WriteFloat( sqc )
						net.WriteFloat( ptbl["pool_spawnlimit"] and ( ptbl["pool_spawnlimit"] * ( ptbl["spawn_autoadjust"] != false and SpawnMapScale or 1 ) ) or -1 )
						net.WriteFloat( ptbl["pool_squadlimit"] and ( ptbl["pool_squadlimit"] * ( ptbl["spawn_autoadjust"] != false and SpawnMapScale or 1 ) ) or -1 )
					net.Broadcast()
					// todo: player-specific radius counts
					CoIterate(25)
				end
				net.Start("npcd_spawn_count_end")
				net.Broadcast()
				countupdated = false
			end

			// send updated profiles
			for _, ply in ipairs( player.GetAll() ) do
				if IsValid( ply ) then
					if profile_updated or !sent_settings[ply] then
						SendSettingsQuery( ply )
						CoIterate(25)
					else
						if sent_settings[ply] then
							local upd
							for p in pairs( updated_profiles ) do
								if !sent_settings[ply][p] or sent_settings[ply][p] < updated_profiles[p] then
									print( !sent_settings[ply][p], sent_settings[ply][p] < updated_profiles[p], sent_settings[ply][p], updated_profiles[p] )
									upd = true
									break
								end
							end
							if upd then
								SendSettingsQuery( ply )
								CoIterate(25)
							end
						end
					end
				end
			end
			profile_updated = nil

			nextinform = CurTime() + 1 // + 0.2
		end
	end
end

modelview_funcs = {
	["material"] = function( ent, path )
		ent:SetMaterial( path )
		print( ent:GetMaterial() )
	end,
}

local viewerents = {}

net.Receive( "npcd_cl_modelviewer", function( len, ply )
	if IsValid( ply ) then
		local func = net.ReadString()
		local model = net.ReadString()
		local path = net.ReadString()

		local ent = ents.Create( "prop_dynamic" )
		ent:SetModel( model )
		print( func, model, path )

		if modelview_funcs[func] then modelview_funcs[func]( ent, path ) end
	end
end )

function SendSettingsQuery( ply, updateall )
	if !inited then return end
	if !IsValid( ply ) then return end
	
	if sending[ply] then
		print( "npcd > ALREADY SENDING TO "..tostring(ply) )
		return
	end
	sending[ply] = true

	local queried_profiles = {}
	
	net.Start("npcd_settings_manifest_start")
	net.Send(ply)

	// [x] problem: channel overflow on singleplayer when too much data sent
	local man_latest = 0 // furthest out time
	local p_latest = 0 // furthest out time

	-- local mc = 0
	local mt = {} // batches of manifests
	local mi = 1 // index
	local mlim = 10 // max manifest per tick

	for s, v in pairs( Profiles ) do
		sent_settings[ply] = sent_settings[ply] or {}
		sent_manifest[ply] = sent_manifest[ply] or {}
		-- updated_profiles[s] = updated_profiles[s] or ( CurTime() + engine.TickInterval() ) // ?
		updated_profiles[s] = updated_profiles[s] or ( CurTime() )

		// sending a manifest is probably better than sending every single profile every time

		prof_manifest[s] = {
			["drop_set"] = table.Count(v.drop_set),
			["player"] = table.Count(v.player),
			["npc"] = table.Count(v.npc),
			["entity"] = table.Count(v.entity),
			["nextbot"] = table.Count(v.nextbot),
			["squad"] = table.Count(v.squad),
			["squadpool"] = table.Count(v.squadpool),
			["weapon_set"] = table.Count(v.weapon_set),
		}

		-- timer.Simple( engine.TickInterval() * mc * 0.1, function()
		-- 	net.Start("npcd_settings_manifest")
		-- 		net.WriteString( s )
		-- 		net.WriteFloat( prof_manifest[s].drop_set )
		-- 		net.WriteFloat( prof_manifest[s].player )
		-- 		net.WriteFloat( prof_manifest[s].npc )
		-- 		net.WriteFloat( prof_manifest[s].entity )
		-- 		net.WriteFloat( prof_manifest[s].nextbot )
		-- 		net.WriteFloat( prof_manifest[s].squad )
		-- 		net.WriteFloat( prof_manifest[s].squadpool )
		-- 		net.WriteFloat( prof_manifest[s].weapon_set )
		-- 	net.Send(ply)
		-- end )

		if mt[mi] and #mt[mi] > mlim then
			mi = mi + 1
		end
		mt[mi] = mt[mi] or {}

		table.insert( mt[mi], {
			pname = s,
			drop_set = prof_manifest[s].drop_set,
			player = prof_manifest[s].player,
			npc = prof_manifest[s].npc,
			entity = prof_manifest[s].entity,
			nextbot = prof_manifest[s].nextbot,
			squad = prof_manifest[s].squad,
			squadpool = prof_manifest[s].squadpool,
			weapon_set = prof_manifest[s].weapon_set
		} )

		sent_manifest[ply][s] = CurTime()

		// grab profiles to be sent. only send profiles that were updated since last sent
		if updateall or !sent_settings[ply][s] or sent_settings[ply][s] < updated_profiles[s] then
			if debugged then print( "npcd > SendSettingsQuery > sending ", s, " to ", ply, CurTime() ) end
			queried_profiles[s] = Profiles[s]
			sent_settings[ply][s] = CurTime()
		end

		-- mc = mc + 1
	end

	// send manifest in batches
	for i in ipairs( mt ) do
		man_latest = engine.TickInterval() * (i-1)
		timer.Simple( man_latest, function()
			if !IsValid( ply ) then return end
			-- print( "mt", i, CurTime(), #util.TableToJSON(mt[i]) )
			for _, m in pairs( mt[i] ) do
				net.Start("npcd_settings_manifest")
					net.WriteString( m.pname )
					net.WriteFloat( m.drop_set )
					net.WriteFloat( m.player )
					net.WriteFloat( m.npc )
					net.WriteFloat( m.entity )
					net.WriteFloat( m.nextbot )
					net.WriteFloat( m.squad )
					net.WriteFloat( m.squadpool )
					net.WriteFloat( m.weapon_set )
				net.Send(ply)
			end
		end )
	end

	-- local qd = !table.IsEmpty( queried_profiles )
	-- if qd then
	net.Start("npcd_settings_send_start")
	net.Send( ply )

	local profiles_send = {}
	if !table.IsEmpty( queried_profiles ) then
		profiles_send = BuildDatastream( queried_profiles )
	end

	// send presets in batches
	p_latest = SendDatastream( "npcd_settings_send", profiles_send, ply, nil, man_latest )
	
	timer.Simple( math.max( p_latest, man_latest ), function()
		if !IsValid( ply ) then return end
		net.Start("npcd_settings_manifest_end")
		net.Send( ply )
		-- if qd then
			net.Start("npcd_settings_send_end")
				net.WriteFloat( table.Count( profiles_send ) )
			net.Send( ply )
		-- end

		if currentProfile then
			net.Start("npcd_currentprofile")
				net.WriteString( currentProfile )
			net.Send( ply )
		end
		sending[ply] = nil
	end )
end

// client requests profiles
net.Receive("npcd_cl_settings_query", function( len, ply )
	if IsValid(ply) and ply:IsPlayer() then
		local updateall = net.ReadBool()
		
		// query spam
		if updateall and last_queried[ply] and CurTime() < last_queried[ply] + 0.5 then
			print( "npcd > too recent query request from "..tostring(ply), last_queried[ply], CurTime() )
			return
		elseif updateall then
			last_queried[ply] = CurTime() // non-full queries should be fine
		end		

		SendSettingsQuery( ply, updateall )
	end
end)


// client commit stuff

net.Receive( "npcd_cl_settings_act", function( len, ply )
	if IsValid(ply) and ply:IsPlayer() and CheckClientPerm( ply, cvar.perm_prof.v:GetInt() ) then
		local act = net.ReadUInt( 5 ) // settings_acts[int] = function
		local prof = net.ReadString()
		local has2 = net.ReadBool()
		local np
		if has2 then
			np = net.ReadString()
		end

		print( "npcd > npcd_cl_settings_act > ply:" .. tostring(ply:GetName())
		.. " act:" .. tostring( act and settings_acts_names[act] or nil )
		.. " prof:" .. tostring( prof ) .. " prof2:" .. tostring( np ) )

		if prof == "" then prof = nil end
		if np == "" then np = nil end

		if settings_acts[act] ~= nil then
			settings_acts[act]( tostring( prof ), np )
		end
	end

	-- SendSettingsQuery( ply )
end )

// receive commit to create preset
net.Receive( "npcd_cl_settings_commit_start", function( len, ply )
	if !IsValid(ply) then
		return
	end
	reports[ply] = {}
	reports[ply].suc = {}
	reports[ply].err = {}
	commit_streams[ply] = {}
end )

net.Receive( "npcd_cl_settings_commit_send", function( len, ply )
	if !IsValid(ply) or !ply:IsPlayer() then
		return
	end

	local chknum = net.ReadFloat( c )
	local len = net.ReadUInt( 16 )
	local data = net.ReadData( len )

	commit_streams[ply][chknum] = data
	
end)

net.Receive( "npcd_cl_settings_commit_end", function( len, ply )
	if !IsValid(ply) or !ply:IsPlayer() then
		return
	end

	local commit_tbl, erred = ReadDatastream( commit_streams[ply], net.ReadFloat() )

	if erred then
		Error("npcd > npcd_cl_settings_commit_end > Invalid client commit from ",ply,"\n" )
		return
	end

	FixProfileNames( commit_tbl )

	-- for pname in pairs( commit_tbl ) do
	-- 	if isnumber( pname ) then
	-- 		local n = tostring( pname )
	-- 		commit_tbl[n] = commit_tbl[pname]
	-- 		if commit_tbl[pname] != commit_tbl[n] then
	-- 			commit_tbl[pname] = nil
	-- 		end
	-- 	end
	-- end

	for prof in pairs( commit_tbl ) do
		-- print( prof, isnumber(prof) )
		for set in pairs( commit_tbl[prof] ) do
			for prsname, prstbl in pairs( commit_tbl[prof][set] ) do
				print("npcd > npcd_cl_settings_commit > Received from ",ply,":",prof, set, prsname, prstbl)

				if !CheckClientPerm( ply, cvar.perm_prof.v:GetInt() ) then
					table.insert( reports[ply].err, { prof, set, prsname, "Player does not have permission" } )
					print( "npcd > npcd_cl_settings_commit > Commit failed: ", ply, " does not have permission" )
					continue
				end

				if !Profiles[prof] then
					table.insert( reports[ply].err, { prof, set, prsname, "Profile "..tostring(prof).." does not exist" } )
					print( "npcd > npcd_cl_settings_commit > Commit failed: Profile ", prof, " does not exist" )
					continue
				end

				RecursiveFixUserdata( prstbl )

				local success, reason = CreatePreset( set, prsname, prstbl, prof )
				-- print( success, set, prsname, prstbl, prof )
				if success then
					table.insert( reports[ply].suc, { prof, set, prsname } )
				else
					table.insert( reports[ply].err, { prof, set, prsname, reason } )
				end
			end
		end
		ProfilePatches( Profiles[prof], prof )
	end

	SendSettingsQuery( ply )
	
	// send errors and successes
	net.Start( "npcd_settings_report_start" )
	net.Send( ply )
	local report = BuildDatastream( reports[ply] )
	local latest = SendDatastream( "npcd_settings_report_send", report, ply, nil )
	timer.Simple( latest, function()
		if IsValid( ply ) then 
			net.Start( "npcd_settings_report_end" )
				net.WriteFloat( table.Count( report ) )
			net.Send( ply )
		end
	end )

	-- net.Start( "npcd_settings_report" )
	-- 	net.WriteTable( commit_suc[ply] or {} )
	-- 	net.WriteBool( table.IsEmpty( commit_err[ply] ) ) // if no errors
	-- 	if !table.IsEmpty( commit_err[ply] ) then
	-- 		net.WriteTable( commit_err[ply] )
	-- 	end
	-- net.Send( ply )
	-- commit_err[ply] = {}
end )

// receive commit to create preset
net.Receive( "npcd_cl_settings_remove_start", function( len, ply )
	if !IsValid(ply) then
		return
	end
	remove_streams[ply] = {}
end )

net.Receive( "npcd_cl_settings_remove_send", function( len, ply )
	if !IsValid(ply) or !ply:IsPlayer() then
		return
	end

	local chknum = net.ReadFloat( c )
	local len = net.ReadUInt( 16 )
	local data = net.ReadData( len )

	remove_streams[ply][chknum] = data
	
end)

// receive commit to remove preset
net.Receive( "npcd_cl_settings_remove_end", function( len, ply )
	if !IsValid(ply) or !ply:IsPlayer() or !CheckClientPerm( ply, cvar.perm_prof.v:GetInt() ) then
		return
	end

	if debugged then print( "npcd_cl_settings_remove_end", ply ) end

	local remove_tbl, erred = ReadDatastream( remove_streams[ply], net.ReadFloat() )

	if erred then
		Error("npcd > npcd_cl_settings_remove_end > Invalid client commit from ",ply,"\n" )
		return
	end

	FixProfileNames( remove_tbl )

	-- local pname = net.ReadString()
	-- local mani = net.ReadTable()

	for prof in pairs( remove_tbl ) do
		if !Profiles[prof] then
			continue
		end
		for set in pairs( remove_tbl[prof] ) do
			for prsname in pairs( remove_tbl[prof][set] ) do
				print("npcd > Removing preset ", prof, set, prsname )
				Profiles[prof][set][prsname] = nil
			end
		end
		updated_profiles[prof] = CurTime()
	end
end )


// "kill themn all" - heavy weapons guy
function pop( target )
	local dfactor = 100000
	local d = DamageInfo()
	d:SetAttacker( player.GetAll()[math.random(1,#player.GetAll())] )
	d:SetDamageType( DMG_ALWAYSGIB )

	if target == nil then
		for k, v in pairs( ents.GetAll() ) do
			local ent = v
			if ( ent:IsNPC() or ent:IsNextBot() or ent:IsRagdoll() or ent:IsVehicle() ) and IsValid(ent) then
				d:SetDamage( ent:Health() )
				d:SetDamageForce( Vector(math.Rand(dfactor*-1,dfactor), math.Rand(dfactor*-1,dfactor), math.Rand(0,dfactor)) )
				d:SetReportedPosition( ent:GetPos() )
				d:SetDamagePosition( ent:GetPos() )
				ent:SetHealth(-1)
				ent:TakeDamageInfo(d)
			end
		end
	elseif IsValid(target) then
		local ent = target
		d:SetDamage( ent:Health() )
		d:SetDamageForce( Vector(math.Rand(dfactor*-1,dfactor), math.Rand(dfactor*-1,dfactor), math.Rand(0,dfactor)) )
		d:SetReportedPosition( ent:GetPos() )
		d:SetDamagePosition( ent:GetPos() )
		ent:SetHealth(-1)
		ent:TakeDamageInfo(d)
	end
end

hook.Add( "Initialize", "NPCD Init", Init )
hook.Add( "Think", "NPCD Think", Think )