// spawning stuff

module( "npcd", package.seeall )

function OverrideValues( tbl, ovr, soft )
	for k, v in pairs( ovr ) do
		if soft and tbl[k] != nil then continue end
		if t_DATAVALUE_NAMES[k] then continue end
		tbl[k] = CopyData( v )
	end
	-- for k, v in pairs( ovr ) do
	-- 	if t_DATAVALUE_NAMES[k] then continue end
	-- 	tbl[k] = nil
	-- end
	-- table.Merge( tbl, ovr )
end

function OverrideTable( tbl, ovr_t, typ, lup_typ, isEnt, copy, lup )
	if !ovr_t or not ( ovr_t["override_soft"] or ovr_t["override_hard"] ) then return nil end

	local o_t
	if copy then
		o_t = {}
		o_t.override_soft = ovr_t["override_soft"] and table.Copy( ovr_t["override_soft"] ) or nil
		o_t.override_hard = ovr_t["override_hard"] and table.Copy( ovr_t["override_hard"] ) or nil
	else
		o_t = ovr_t
	end

	if o_t["override_soft"] then
		SetEntValues( nil, o_t, "override_soft", t_lookup[lup_typ]["override_soft"] )

		if isEnt and o_t["override_soft"]["all"] then
			SetEntValues( nil, o_t["override_soft"], "all", lup and lup["override_soft"].STRUCT["all"] or t_lookup[lup_typ]["override_soft"].STRUCT["all"] )
			OverrideValues( tbl, o_t["override_soft"]["all"], true )
		end
		if typ and o_t["override_soft"][typ] or o_t["override_soft"] then
			SetEntValues( nil, o_t["override_soft"], typ, lup and lup["override_soft"].STRUCT[typ] or t_lookup[lup_typ]["override_soft"].STRUCT[typ] )
			OverrideValues( tbl, typ and o_t["override_soft"][typ] or o_t["override_soft"], true )
		end
	end
	if o_t["override_hard"] then
		SetEntValues( nil, o_t, "override_hard", t_lookup[lup_typ]["override_hard"] )

		if isEnt and o_t["override_hard"]["all"] then
			SetEntValues( nil, o_t["override_hard"], "all", lup and lup["override_hard"].STRUCT["all"] or t_lookup[lup_typ]["override_hard"].STRUCT["all"] )
			OverrideValues( tbl, o_t["override_hard"]["all"], nil )
		end
		if typ and o_t["override_hard"][typ] or o_t["override_hard"] then
			SetEntValues( nil, o_t["override_hard"], typ, lup and lup["override_hard"].STRUCT[typ] or t_lookup[lup_typ]["override_hard"].STRUCT[typ] )
			OverrideValues( tbl, typ and o_t["override_hard"][typ] or o_t["override_hard"], nil )
		end
	end

	return o_t
end

function GetOBB( npc_t )
	if !npc_t then return nil end
	local bounds = {}
	local xmin, xmax, ymin, ymax, zmin, zmax = 0, 0, 0, 0, 0, 0
	local offset = Vector()

	-- local npc_t = table.Copy( nsTbl["npc_t"] )
	// [x] problem: GetGroupOBB and SpawnNPC will come out differently if it has a random value for scale or model

	local npc = ents.Create( GetPresetName( npc_t.classname ) )

	if !IsValid(npc) then return nil end

	npc:SetPos( game.GetWorld():GetPos() )

	if npc_t.model then // set model
		SetEntValues(npc, npc_t, "model", GetLookup( "model", npc_t.entity_type, nil, GetPresetName( npc_t.classname ) ) )
	end
	if npc_t.scale then // set scale
		npc:SetModelScale( npc_t.scale ) // set immediately
	end

	npc:Spawn()
	npc:Activate()
	if npc_t.setboundary then
		SetEntValues(npc, npc_t, "setboundary", GetLookup( "setboundary", npc_t.entity_type, nil, GetPresetName( npc_t.classname ) ) )
		if istable(npc_t.setboundary) then
			npc:SetCollisionBounds( npc_t.setboundary.min, npc_t.setboundary.max )
		end
	end
	local lc, hc = npc:GetCollisionBounds()
	local model = npc:GetModel()
	npc:Remove()
	CoIterate(75)

	if model and !cachedModels[model] then
		cachedModels[model] = true
		CoIterate(100)
	end

	
	for _, c in ipairs( { lc, hc } ) do
		xmax = math.max( xmax, c.x, math.abs( xmin ), ymax )
		xmin = -xmax

		ymax = math.max( ymax, c.y, math.abs( ymin ), xmax )
		ymin = -ymax

		zmax = math.max( zmax, c.z )
		zmin = math.min( zmin, c.z )
	end	

	if zmin < 0 then offset.z = math.abs(zmin) end
	zmax = zmax + 10 // a little off the ground

	bounds[1] = Vector( xmin, ymin, zmin ) + offset
	bounds[2] = Vector( xmax, ymax, zmax ) + offset
	bounds[3] = offset
	bounds[4] = { npc_t.offset } //wtf happens when this is a table

	if debugged then
		print( "npcd > GetOBB\n\tmin: ",bounds[1],"\n\tmax:",bounds[2],"\n\toffset:",bounds[3], "ent_offs:", #bounds[4])
	end
	
	return bounds
end

// model bounds of an entire squad
function GetGroupOBB( group_t )
	if !group_t or table.IsEmpty(group_t["spawns"]) then
		return nil
	end

	local bounds = {}
	local xmin, xmax, ymin, ymax, zmin, zmax = 0, 0, 0, 0, 0, 0
	local spawned = false
	local offset = Vector()
	local ent_offs = {}

	knownBounds[currentProfile] = knownBounds[currentProfile] or {}
	knownBounds[currentProfile][group_t.name] = knownBounds[currentProfile][group_t.name] or {}

	for n, nsTbl in pairs( group_t["spawns"] ) do
		if nsTbl["npc_t"] and nsTbl["npc_t"].offset then
			table.insert( ent_offs, nsTbl["npc_t"].offset )
		end
		// already looked up
		if knownBounds[currentProfile]
		and knownBounds[currentProfile][group_t.name]
		and knownBounds[currentProfile][group_t.name][nsTbl.name] then
			for _, c in ipairs( knownBounds[currentProfile][group_t.name][nsTbl.name] ) do
				xmax = math.max( xmax, c.x, math.abs( xmin ), ymax )
				xmin = -xmax

				ymax = math.max( ymax, c.y, math.abs( ymin ), xmax )
				ymin = -ymax

				zmax = math.max( zmax, c.z )
				zmin = math.min( zmin, c.z )
			end
			spawned = true
			continue
		end

		CoIterate(75)

		-- local npc_t = table.Copy( nsTbl["npc_t"] )
		local npc_t = nsTbl["npc_t"]
		// [x] problem: GetGroupOBB and SpawnNPC will come out differently if it has a random value for scale or model

		local npc = ents.Create( GetPresetName( npc_t.classname ) )

		if !IsValid(npc) then continue end

		npc:SetPos( game.GetWorld():GetPos() )

		if npc_t.model then // set model
			SetEntValues(npc, npc_t, "model", GetLookup( "model", npc_t.entity_type, nil, GetPresetName( npc_t.classname ) ) )
		end
		if npc_t.scale then // set scale
			-- SetEntValues( nil, npc_t, "scale", GetLookup( "scale", npc_t.entity_type, nil, GetPresetName( npc_t.classname ) ) )
			npc:SetModelScale( npc_t.scale ) // set immediately
		end
		-- if npc_t.angle then SetEntValues(npc, npc_t, "angle", GetLookup( "angle", npc_t.entity_type, nil, npc_t.classname ) )
		-- else npc_t.angle = RandomAngle() end

		npc:Spawn()
		npc:Activate()
		if npc_t.setboundary then
			SetEntValues(npc, npc_t, "setboundary", GetLookup( "setboundary", npc_t.entity_type, nil, GetPresetName( npc_t.classname ) ) )
			if istable(npc_t.setboundary) then
				npc:SetCollisionBounds( npc_t.setboundary.min, npc_t.setboundary.max )
			end
		end
		local lc, hc = npc:GetCollisionBounds()
		local model = npc:GetModel()
		npc:Remove()

		if model and !cachedModels[model] then
			cachedModels[model] = true
			CoIterate(100)
		end
		
		for _, c in ipairs( { lc, hc } ) do
			xmax = math.max( xmax, c.x, math.abs( xmin ), ymax )
			xmin = -xmax

			ymax = math.max( ymax, c.y, math.abs( ymin ), xmax )
			ymin = -ymax

			zmax = math.max( zmax, c.z )
			zmin = math.min( zmin, c.z )
		end	

		spawned = true

		if !nsTbl["obb_random"] then
			knownBounds[currentProfile] = knownBounds[currentProfile] or {}
			knownBounds[currentProfile][group_t.name] = knownBounds[currentProfile][group_t.name] or {}
			knownBounds[currentProfile][group_t.name][nsTbl.name] = { lc, hc }
		elseif knownBounds[currentProfile] and knownBounds[currentProfile][group_t.name] then
			knownBounds[currentProfile][group_t.name][nsTbl.name] = nil
		end

	end

	if !spawned then return nil end // didn't spawn anything

	if zmin < 0 then offset.z = math.abs(zmin) end
	zmax = zmax + 10 // a little off the ground

	bounds[1] = Vector( xmin, ymin, zmin ) + offset
	bounds[2] = Vector( xmax, ymax, zmax ) + offset
	bounds[3] = offset
	bounds[4] = ent_offs

	if debugged then
		print( "npcd > GetGroupOBB\n\tmin: ",bounds[1],"\n\tmax:",bounds[2],"\n\toffset:",bounds[3],"ent_offs:", #bounds[4] )
	end
	
	return bounds
end

function AddToSquad( add, squad )
	table.insert( squad, add )
	for k, npc in pairs( squad ) do
		if activeNPC[npc] then
			activeNPC[npc]["squad"] = squad
		-- else
			-- table.remove(squad, k)
		end
	end
	return squad
end

function RemoveFromSquad( sub, squad )
	for k, npc in pairs( squad ) do
		if npc == sub then
			table.remove( squad, k )
			break
		end
	end
	for k, npc in pairs( squad ) do
		if activeNPC[npc] then
			activeNPC[npc]["squad"] = squad
		-- else
		-- 	table.remove(squad, k)
		end
	end
end

// class valuetable and valuetable
function ResolveEntValueTable( npc, npc_t )
	if !npc_t or !npc_t.entity_type then
		Error( "\nnpcd > ResolveEntValueTable > invalid npc_t\n\n" )
		debug.Trace()
		return
	end
	// value table, class table
	local cl = GetPresetName( npc_t.classname )
	local hasclasslup = t_lookup["class"][npc_t.entity_type] and t_lookup["class"][npc_t.entity_type][cl]
	if hasclasslup then
		ApplyValueTable( npc_t, t_lookup["class"][npc_t.entity_type][cl], npc )
	end

	// value table, type table, skipping values that exist in class table
	for valueName, valueTbl in pairs( t_lookup[npc_t.entity_type] ) do
		if hasclasslup and t_lookup["class"][npc_t.entity_type][cl][valueName] then continue end
		SetEntValues( npc, npc_t, valueName, valueTbl )
	end
end

function SpawnNPC( presetName, anpc_t, pos, ang, squad_t, npcOverride, doFadeIns, pool, nocopy, nopoolovr, oldsquad )
	if !anpc_t then Error("\nError: npcd > SpawnNPC > NO NPC_T ",presetName,"\n\n") return nil end
	if debugged then
		print("npcd > SpawnNPC(", presetName, anpc_t, pos, ang, squad_t, npcOverride, doFadeIns, pool, nocopy, nopoolovr, oldsquad,")" )	
	end
	if anpc_t["npcd_enabled"] == false then return nil end

	local i = 0
	local squad_t = squad_t or {
		["values"] = {}
	}
	
	local npc_t = nocopy and anpc_t or table.Copy( anpc_t )

	if !npc_t.entity_type then return nil end

	// pool override
	if !nopoolovr and pool != nil and Settings.squadpool[pool] then
		OverrideTable( npc_t, Settings.squadpool[pool], npc_t.entity_type, "squadpool", true, true )
	end

	// spawn requirements
	if npc_t.spawn_req_navmesh and !HasNavMesh then
		if debugged then print("npcd > SpawnNPC > Spawn requirement not met for \""..presetName.."\": Navmeshes") end
		return nil
	end
	if npc_t.spawn_req_nodes and !HasNodes then
		if debugged then print("npcd > SpawnNPC > Spawn requirement not met for \""..presetName.."\": Nodes") end
		return nil
	end

	// create new or modify existing
	if npcOverride then
		npc = npcOverride
	else
		local cname = GetPresetName( npc_t.classname )
		if cname == nil then return nil end
		npc = ents.Create( cname )
	end

	
	if !IsValid(npc) then
		print("npcd > SpawnNPC > INVALID ENTITY: ",npc)
		return nil
	end
	
	if squad_t["name"] then
		npc:SetName(presetName.." ("..squad_t["name"]..")")
	elseif !npc:IsPlayer() then
		npc:SetName(presetName)
	end

	if pos then npc:SetPos( pos ) end // initial pos

	npc:SetAngles( ang or RandomAngle() ) 

	ResolveEntValueTable( npc, npc_t ) // do value funcs

	if npc_t.offset then
		npc:SetPos( npc:GetPos() + npc_t.offset )
	end
	local startpos = npc:GetPos()

	// prespawn misc
	PreEntitySpawn( npc, npc_t )

	// squadname
	if squad_t["squadID"] then
		npc:SetKeyValue("squadname", squad_t["squadID"])
	end
	
	// weapon set
	local wep, wep_t
	// [x] problem: zombie npcs set to different model holding weapon will crash game when killed
	-- if !modelfixes[npc:GetClass()] or modelfixes[npc:GetClass()] and ( npc:GetModel() == nil or modelfixes[npc:GetClass()] == npc:GetModel() ) then
		if npc_t.weapon_set and npc_t.weapon_set["name"] and Settings["weapon_set"][ npc_t.weapon_set["name"] ] then
			wep, wep_t = SpawnWeaponSet( npc, npc_t.weapon_set["name"], nil, nil, npc_t, squad_t, pool )
		end
		if npc_t.weapon_sets then
			for _, wset in pairs( npc_t.weapon_sets ) do
				if wset["name"] and Settings["weapon_set"][ wset["name"] ] then
					wep, wep_t = SpawnWeaponSet( npc, wset["name"], nil, nil, npc_t, squad_t, pool )
				end
			end
		end
		if npc_t.weapon then
			if isfunction( npc.Give ) then
				wep = npc:Give( GetPresetName(npc_t.weapon) )
			else
				wep = ents.Create( GetPresetName(npc_t.weapon) )
				if IsValid( wep ) then
					wep:SetPos( npc:GetPos() )
					wep:SetAngles( npc:GetAngles() )
					wep:Spawn()
					wep:Activate()
				end
			end
			if !IsValid( wep ) then wep = nil end
		end
		if IsValid( wep ) and wep:IsWeapon() and npc:IsPlayer() then
			npc:SelectWeapon( wep )
		end
	-- else
	-- 	if isfunction( npc.StripWeapons ) then
	-- 		npc:StripWeapons()
	-- 	elseif isfunction( npc.GetWeapons ) then
	-- 		for _, wep in ipairs( npc:GetWeapons() ) do
	-- 			if IsValid( wep ) then
	-- 				wep:Remove()
	-- 			end
	-- 		end
	-- 	end
	-- end

	local doFadeIns = doFadeIns
	-- if doFadeIns == nil and npc_t.fadein ~= nil then
	-- 	doFadeIns = npc_t.fadein
	-- else
	if npc:IsEFlagSet( EF_NODRAW ) then
		doFadeIns = false
	elseif doFadeIns == nil then
		doFadeIns = true
	end

	// add npc/player to active table, spawn
	if npc:IsPlayer() then
		activePly[npc] = {
			["npcpreset"] = presetName,
			["npc_t"] = npc_t,
			["wep_t"] = wep_t,
			["startpos"] = startpos,
			["healthfrac"] = 0,
			["nextregen"] = CurTime() + ( SetTmpEntValues( {}, npc, npc_t, "regendelay", GetLookup( "regendelay", npc_t.entity_type, nil, GetPresetName( npc_t.classname ) ) ) or 0 ),
			["nextact"] = CurTime(),
			["nextseq"] = CurTime(),
			["relations"] = {
				["inward"] = {
					["class"] = {},
					["preset"] = {},
					["preset_squad"] = {},
					-- ["everyone"] = {}, // the check is if this table is included at all
					["self_squad_exclude_class"] = {},
					["everyone_exclude_class"] = {},
					["self_squad_exclude_preset"] = {},
					["everyone_exclude_preset"] = {},
					["self_squad_exclude_preset_squad"] = {},
					["everyone_exclude_preset_squad"] = {},
				},
			},
		}
	else // entity
		activeNPC[npc] = {
			["npcpreset"] = presetName,
			["squadpreset"] = squad_t["name"] or nil,
			["squad_t"] = squad_t,
			["squad"] = oldsquad and AddToSquad( npc, oldsquad ) or nil, --SpawnSquad()
			["npc_t"] = npc_t,
			["wep_t"] = wep_t,
			["weight"] = npc_t.quota_weight,
			["pool"] = pool or squad_t["originpool"] or nil,
			["startpos"] = startpos,
			["spawned"] = nil, --FadeIns()
			["chasing"] = nil, --ManageSchedules()
			["healthfrac"] = 0,
			["seekout"] = nil, --ManageSchedules()
			["sched"] = nil, --ManageSchedules()
			["sched_startpos"] = nil, --ManageSchedules()
			["sched_fails"] = nil, --ManageSchedules()
			["sched_seekout_fails"] = nil, --ManageSchedules()
			["nextregen"] = CurTime() + ( SetTmpEntValues( {}, npc, npc_t, "regendelay", GetLookup( "regendelay", npc_t.entity_type, nil, GetPresetName( npc_t.classname ) ) ) or 0 ),
			["nextact"] = CurTime(),
			["nextseq"] = CurTime(),
			["relations"] = {
				["outward"] = {
					["class"] = {},
					["preset"] = {},
					["preset_squad"] = {},
					-- ["self_squad"] = {},
					-- ["everyone"] = {},
					["self_squad_exclude_class"] = {},
					["everyone_exclude_class"] = {},
					["self_squad_exclude_preset"] = {},
					["everyone_exclude_preset"] = {},
					["self_squad_exclude_preset_squad"] = {},
					["everyone_exclude_preset_squad"] = {},
				},
				["inward"] = {
					["class"] = {},
					["preset"] = {},
					["preset_squad"] = {},
					-- ["self_squad"] = {},
					-- ["everyone"] = {},
					["self_squad_exclude_class"] = {},
					["everyone_exclude_class"] = {},
					["self_squad_exclude_preset"] = {},
					["everyone_exclude_preset"] = {},
					["self_squad_exclude_preset_squad"] = {},
					["everyone_exclude_preset_squad"] = {},
				},
			},
		}

		// non-player fade in and spawning

		if doFadeIns then
			activeNPC[npc]["spawned"] = false
			npc:SetKeyValue( "renderamt", npc_t.startalpha )
			npc:SetNoDraw(true)
			if IsValid( wep ) then
				wep:SetKeyValue( "renderamt", wep_t and wep_t.startalpha or 0 )
				wep:SetNoDraw(true)
			end
			// add to DoFadeIns() table
			activeFade[npc] = {
				npcmax = npc_t.renderamt or 255,
				wepmax = wep_t and wep_t.renderamt or 255,
				starttime = CurTime(),
				ready = false,
				nodelay = squad_t["values"]["fadein_nodelay"]
			}
		else // skip DoFadeIns()
			activeNPC[npc]["spawned"] = true
			npc:SetKeyValue( "renderamt", npc_t.renderamt or 255 )
			if wep_t and wep_t.renderamt and IsValid( wep ) then
				wep:SetKeyValue( "renderamt", wep_t.renderamt )
			end
			if npc_t.spawneffect then
				for _, sf in pairs(npc_t["spawneffect"]) do
					CreateEffect( sf, npc, npc:GetPos() )
				end
			end
		end

		// spawn
		npc:Spawn()
	end
	
	if npc_t.activate != false then npc:Activate() end

	// postspawn misc
	PostEntitySpawn( npc, npc_t )

	if !activeNPC[npc] and !activePly[npc] then
		npc:Remove()
		return nil
	end
	
	// npc only postspawn	
	NPCPostSpawn( npc, npc_t )

	// player only postspawn
	PlayerPostSpawn( npc, npc_t )

	// inward relations
	Relatables( npc, npc_t )

	if !IsValid( npc ) then
		return nil
	elseif npc:GetPos():DistToSqr( startpos ) < 1000 then
		 // fix position offset from coroutine delaying if not too far
		npc:SetPos( startpos )
	end

	if npc:IsPlayer() then
		net.Start( "npcd_ply_preset" ) 
			net.WriteString( presetName )
		net.Send( npc )
	end

	countupdated = true
	return npc
end

// used in damage filter
function ApplyEntityValues( ent, ent_t, old_t, otyp )
	local typ = otyp or "any"
	if !ent or !ent_t or !t_lookup[typ] then return end

	if !ent_t.entity_type then ent_t.entity_type = otyp or "entity" end

	for valueName, value in pairs( ent_t ) do
		SetEntValues( ent, ent_t, valueName, t_lookup[typ][valueName] or t_empty )
		if old_t then old_t[valueName] = CopyData( value ) end
	end

	ent_t.classname = ent_t.classname or ent:GetClass()

	local wset = GetPresetName( ent_t.weapon_set )
	if ( ent:IsNPC() or ent:IsPlayer() ) and wset and Settings["weapon_set"][wset] then
		SpawnWeaponSet( ent, wset, nil, nil, ent_t, nil, nil )
	end


	// post spawns
	PreEntitySpawn( ent, ent_t )
	PostEntitySpawn( ent, ent_t )
	NPCPostSpawn( ent, ent_t ) // will do nothing if not npc
	PlayerPostSpawn( ent, ent_t )
	Relatables( ent, ent_t )
end

function ApplyBonechart( ent, bonetbl )
	for _, bonechart in pairs( bonetbl ) do
	
		ApplyValueTable( bonechart, t_value_structs["bones"].STRUCT )
		if bonechart.bone == nil then continue end

		local id
		if isnumber( bonechart.bone ) then
			local bname = ent:GetBoneName( bonechart.bone )
			if bname == nil or bname == "__INVALIDBONE__" then
				if debugged then print( "npcd > ApplyBonechart > ", bonechart.bone, "invalid bone" ) end
				continue
			else
				id = bonechart.bone
			end
		elseif isstring( bonechart.bone ) then
			id = ent:LookupBone( bonechart.bone )
			if !id then
				if debugged then print( "npcd > ApplyBonechart > ", bonechart.bone, ent:LookupBone( bonechart.bone ), "nil bone" ) end
				continue
			end
		else
			continue
		end

		if bonechart.scale then ent:ManipulateBoneScale( id, bonechart.scale ) end
		if bonechart.offset then ent:ManipulateBonePosition( id, bonechart.offset ) end
		if bonechart.rotate then ent:ManipulateBoneAngles( id, bonechart.rotate ) end
		if bonechart.jiggle != nil then ent:ManipulateBoneJiggle( id, bonechart.jiggle == true and 1 or 0 ) end
	end
end

// for more complex properties that can be applied pre-spawn
function PreEntitySpawn( ent, ent_t )
	if !IsValid( ent ) or !ent_t then return end

	-- local class = GetPresetName( ent_t.classname )

	-- // moved to struct.lua
	-- if ent_t.engineflags then
	-- 	for k in pairs( ent_t.engineflags ) do
	-- 		ent_t.engineflags[k] = bit.band( ent_t.engineflags[k], bit.bnot( EFL_KILLME ) ) // make sure bad flag isn't set
	-- 		ent:AddEFlags( ent_t.engineflags[k] )
	-- 	end
	-- end
	-- if ent_t.entityflags then
	-- 	for k in pairs( ent_t.entityflags ) do
	-- 		ent_t.entityflags[k] = bit.band( ent_t.entityflags[k], bit.bnot( FL_KILLME ) ) // make sure bad flag isn't set
	-- 		ent:AddFlags( ent_t.entityflags[k] )
	-- 	end
	-- end

	if ent:IsNPC() then
		if !ent:HasSpawnFlags( SF_NPC_FALL_TO_GROUND ) then ent:AddSpawnFlag( SF_NPC_FALL_TO_GROUND ) end //bugfix
		if ent_t.long_range != nil then
			if ent_t.long_range == true and !ent:HasSpawnFlags( SF_NPC_LONG_RANGE ) then
				ent:AddSpawnFlag( SF_NPC_LONG_RANGE )
			elseif ent_t.long_range == false and ent:HasSpawnFlags( SF_NPC_LONG_RANGE ) then
				ent:RemoveSpawnFlag( SF_NPC_LONG_RANGE )
			end
		end
		if ent_t.dropweapon != nil then
			if ent_t.dropweapon == true and ent:HasSpawnFlags( SF_NPC_NO_WEAPON_DROP ) then
				ent:RemoveSpawnFlag( SF_NPC_NO_WEAPON_DROP )
			elseif ent_t.dropweapon == false and !ent:HasSpawnFlags( SF_NPC_NO_WEAPON_DROP ) then
				ent:AddSpawnFlag( SF_NPC_NO_WEAPON_DROP )
			end
		end
	end
end

// for more complex properties or those that need to be applied post-spawn
function PostEntitySpawn( ent, ent_t )
	if !IsValid( ent ) or !ent_t then return end
	if isfunction( ent.SetupBones ) then
		ent:SetupBones()
	end

	local class = GetPresetName( ent_t.classname )

	if ent_t.model then
		if ent_t.model != ent:GetModel() then SetEntValues(ent, ent_t, "model", GetLookup( "model", ent_t.entity_type, nil, class ) ) end
	end

	if ent_t.bodygroups then
		-- PrintTable( ent_t.bodygroups )
		for _, bg in pairs( ent_t.bodygroups ) do
			if bg.value == nil then continue end

			local id = bg.group
			if isstring( id ) then
				id = ent:FindBodygroupByName( id )
			end
			if !id or id == -1 then continue end

			ent:SetBodygroup( id, bg.value )
		end
	end

	if ent_t.jiggle_all != nil or ent_t.bone_scale != nil then
		for i=1,ent:GetBoneCount() do
			if ent_t.jiggle_all != nil then
				local j = ent_t.jiggle_all == true and 1 or 0
				ent:ManipulateBoneJiggle(i, j)
			end
			if ent_t.bone_scale != nil then
				ent:ManipulateBoneScale(i, Vector( ent_t.bone_scale, ent_t.bone_scale, ent_t.bone_scale ) )
			end
		end
	end

	if ent_t.bones then
		ApplyBonechart( ent, ent_t.bones )
	end

	if ent_t.physcollide then
		// remove existing callback
		if activeCallback[ent] and activeCallback[ent]["PhysicsCollide"] then
			ent:RemoveCallback( "PhysicsCollide", activeCallback[ent]["PhysicsCollide"] )
		end
		activeCallback[ent] = activeCallback[ent] or {}

		-- if ent:IsPlayer() then
		-- 	activeCallback[ent]["PhysicsCollide"] = ent:GetPhysicsObject():AddCallback( "PhysicsCollide", EntRamming )
		-- else
			activeCallback[ent]["PhysicsCollide"] = ent:AddCallback( "PhysicsCollide", EntRamming )
		-- end

		activeCollide[ent] = ent_t
	end

	if ent_t.physobject then
		local phyo = ent:GetPhysicsObject()
		if IsValid( phyo ) then
			ApplyValueTable( ent_t.physobject, t_basic_values["physobject"].STRUCT, phyo )
			-- phyo:SetMaterial(ent_t.phys_material)
		end
	end

	// health has to be set after spawn for some reason
	if ent_t.numhealth then SetEntValues(ent, ent_t, "numhealth", GetLookup( "numhealth", ent_t.entity_type, nil, class ) ) end --ent:SetMaxHealth(ent_t.maxhealth)
	if ent_t.maxhealth then
		SetEntValues(ent, ent_t, "maxhealth", GetLookup( "maxhealth", ent_t.entity_type, nil, class ) ) --ent:SetHealth(ent_t.numhealth)
		if !ent_t.numhealth then
			ent:SetHealth(ent_t.maxhealth)
		end
	end
	if ent_t.healthmult then
		ent:SetHealth( ent:Health() * ent_t.healthmult )
		ent:SetMaxHealth( ent:GetMaxHealth() * ent_t.healthmult )
	end

	// blood color has to be set after for some reason
	if ent_t.bloodcolor then SetEntValues(ent, ent_t, "bloodcolor", GetLookup( "bloodcolor", ent_t.entity_type, nil, class ) ) end

	if ent_t.inputs then
		for _, itbl in pairs(ent_t.inputs) do // table of tables
			SetEntValues( ent, itbl, "inputs", t_lookup[ent_t.entity_type]["inputs"].TBLSTRUCT )
			-- print( "input", unpack( itbl ) )
			if !table.IsEmpty( itbl ) then
				ent:Fire( unpack( itbl ) )
			end
		end
	end

	if ent_t.keyvalues then
		for _, itbl in pairs(ent_t.keyvalues) do
			SetEntValues( ent, itbl, "key", GetLookup( "keyvalues", ent_t.entity_type, "key", class ) )
			SetEntValues( ent, itbl, "value", GetLookup( "keyvalues", ent_t.entity_type, "value", class ) ) // does it do foreach? yes // ok but value is only one value so why did i try to make it a table
			-- print( "keyvalue", itbl.key, itbl.value )
			if itbl.key != nil and itbl.value != nil then
				ent:SetKeyValue( itbl.key, tostring( itbl.value ) )
			end
		end
	end

	if ent_t.ignite then
		SetEntValues(ent, ent_t, "ignite",  GetLookup( "ignite", ent_t.entity_type, nil, class ) )
	end

	// add to active effects
	if ent_t.effects then
		activeEffect[ent] = table.Copy(ent_t.effects)
	end

	// preresolve some structs
	// todo: preresolve datavalue
	if ent_t.velocity_in then
		ApplyValueTable( ent_t.velocity_in, GetLookup( "velocity_in", ent_t.entity_type, nil, class ).STRUCT )
	end
	if ent_t.velocity_out then
		ApplyValueTable( ent_t.velocity_out, GetLookup( "velocity_out", ent_t.entity_type, nil, class ).STRUCT )
	end

	if ent_t.volatile then
		ApplyValueTable( ent_t.volatile, GetLookup( "volatile", ent_t.entity_type, nil, class ).STRUCT )
	end
	if ent_t.accelerate then
		ApplyValueTable( ent_t.accelerate, GetLookup( "accelerate", ent_t.entity_type, nil, class ).STRUCT, ply )
	end

	if ent_t.spritetrail then
		local lup_t = GetLookup( "spritetrail", ent_t.entity_type, nil, class )
		for _, st in pairs(ent_t.spritetrail) do
			ApplyValueTable( st, lup_t.STRUCT )
			local sw = st["startwidth"] or 25
			local ew = st["endwidth"] or 1
			util.SpriteTrail(ent,
				st["attachment"] or 1,
				st["color"] or Color(255,255,255),
				st["additive"] or false,
				sw,
				ew,
				st["lifetime"] or 5,
				1 / ( sw + ew ) * 0.5,
				st["texture"] or "trails/plasma"
			) 
		end
	end

	if istable( ent_t.submaterial ) then
		for k, v in pairs( ent_t.submaterial ) do
			-- print( v.id, v.material )
			ent:SetSubMaterial( v.id, v.material )
		end
	end

	if ent_t.use == true and #player.GetAll() > 0 then ent:Use( player.GetAll()[1] ) end

	if ent_t.setboundary then
		SetEntValues(ent, ent_t, "setboundary", GetLookup( "setboundary", ent_t.entity_type, nil, class ) )
		if istable(ent_t.setboundary) then
			npc:SetCollisionBounds( ent_t.setboundary.min, ent_t.setboundary.max )
		end
	end

end

function PlayerPostSpawn( ply, ply_t )
	if !IsValid( ply ) or !ply:IsPlayer() then return end

	if ply_t.playercolor then
		local col = ply_t.playercolor
		ply:SetPlayerColor( Vector( col.r / 255, col.g / 255, col.b / 255 ) )
	end
	if ply_t.weaponcolor then
		local col = ply_t.weaponcolor
		ply:SetWeaponColor( Vector( col.r / 255, col.g / 255, col.b / 255 ) )
	end
end

function NPCPostSpawn( npc, npc_t )
	if !IsValid( npc ) or !activeNPC[npc] or !npc:IsNPC() then return end

	local ntbl = activeNPC[npc]

	// relationships, outward (outward is npc only)
	if npc_t.relationships_outward then
		local r_lup_t = GetLookup( "relationships_outward", npc_t.entity_type, nil, cl )
		ApplyValueTable( npc_t.relationships_outward, r_lup_t.STRUCT, npc )

		// class outward
		if npc_t.relationships_outward.by_class ~= nil then
			for k, v in pairs( npc_t.relationships_outward.by_class ) do
				ApplyValueTable( v, r_lup_t.STRUCT["by_class"].STRUCT, npc )
				-- PrintTable( npc_t )

				if GetPresetName( v["classname"] ) == nil or v["disposition"] == nil then continue end

				local cname = GetPresetName( v["classname"] )
				local disp = int_disp_t[ v["disposition"] ] // has to be a string
				local p = v["priority"] or 50

				npc:AddRelationship( cname .." ".. disp .." ".. p )

				// add to npc's lookup table
				ntbl.relations.outward.class[cname] = {
					d = v["disposition"],
					p = p,
				}
			end
		end
		// preset outward
		if npc_t.relationships_outward.by_preset ~= nil then
			for k, v in pairs( npc_t.relationships_outward.by_preset ) do

				ApplyValueTable( v, r_lup_t.STRUCT["by_preset"].STRUCT, npc )

				if v["disposition"] == nil then continue end
				if !istable( v["preset"] ) then continue end


				local cname = v["preset"]["name"]
				local ctyp = v["preset"]["type"]
				if !cname or !ctyp then continue end

				local disp = v["disposition"] // must be an int
				local p = v["priority"] or 50

				if ctyp == "squad" then
					ntbl.relations.outward.preset_squad[cname] = {
						t = ctyp, 
						d = disp, 
						p = p 
					}
				else
					ntbl.relations.outward.preset[cname] = {
						t = ctyp, 
						d = disp, 
						p = p 
					}
				end
			end
		end

		// everyone outward
		if npc_t.relationships_outward.everyone ~= nil then
			ApplyValueTable( npc_t.relationships_outward.everyone, r_lup_t.STRUCT["everyone"].STRUCT, npc )

			//exclude
			if npc_t.relationships_outward.everyone.exclude then
				ApplyValueTable( npc_t.relationships_outward.everyone.exclude, r_lup_t.STRUCT["everyone"].STRUCT["exclude"].STRUCT, npc )

				if npc_t.relationships_outward.everyone.exclude.by_preset then
					for k, v in pairs( npc_t.relationships_outward.everyone.exclude.by_preset ) do
						local cname = v["name"]
						local ctyp = v["type"]
						if cname ~= nil then
							if ctyp == "squad" then
								ntbl.relations.outward.everyone_exclude_preset_squad[cname] = ctyp
							else
								ntbl.relations.outward.everyone_exclude_preset[cname] = ctyp
							end
						end
					end
				end

				if npc_t.relationships_outward.everyone.exclude.by_class then
					for k, v in pairs( npc_t.relationships_outward.everyone.exclude.by_class ) do
						local class = GetPresetName(v)
						if class ~= nil then
							ntbl.relations.outward.everyone_exclude_class[class] = true
						end
					end
				end
			end

			if isnumber( npc_t.relationships_outward.everyone.disposition ) then
				ntbl.relations.outward.everyone = {
					d = npc_t.relationships_outward.everyone.disposition,
					p = npc_t.relationships_outward.everyone.priority or 50
				}
			end
		end

		//self squad outward
		if npc_t.relationships_outward.self_squad ~= nil then
			ApplyValueTable( npc_t.relationships_outward.self_squad, r_lup_t.STRUCT["self_squad"].STRUCT, npc )

			//exclude
			if npc_t.relationships_outward.self_squad.exclude then
				ApplyValueTable( npc_t.relationships_outward.self_squad.exclude, r_lup_t.STRUCT["self_squad"].STRUCT["exclude"].STRUCT, npc )

				if npc_t.relationships_outward.self_squad.exclude.by_preset then
					for k, v in pairs( npc_t.relationships_outward.self_squad.exclude.by_preset ) do
						local cname = v["name"]
						local ctyp = v["type"]
						if cname ~= nil then
							if ctyp == "squad" then
								ntbl.relations.outward.self_squad_exclude_preset_squad[cname] = ctyp
							else
								ntbl.relations.outward.self_squad_exclude_preset[cname] = ctyp
							end
						end
					end
				end

				if npc_t.relationships_outward.self_squad.exclude.by_class then
					for k, v in pairs( npc_t.relationships_outward.self_squad.exclude.by_class ) do
						local class = GetPresetName(v)
						if class ~= nil then
							ntbl.relations.outward.self_squad_exclude_class[class] = true
						end
					end
				end
			end

			if isnumber( npc_t.relationships_outward.self_squad.disposition ) then
				ntbl.relations.outward.self_squad = {
					d = npc_t.relationships_outward.self_squad.disposition,
					p = npc_t.relationships_outward.self_squad.priority or 50
				}
			end
		end
	end
	
	// make wander
	if npc:IsCurrentSchedule( SCHED_NONE ) then
		npc:SetSchedule( SCHED_IDLE_WANDER )
	end
	
	// send towards player
	if npc_t.start_aware then
		local closest
		local mindist = math.huge
		for _, ply in ipairs( player.GetAll() ) do
			local d = ply:GetPos():DistToSqr( npc:GetPos() )
			if ply:Alive() and d < mindist then
				closest = ply
				mindist = d
			end
		end
		if closest then
			timer.Simple(0, function()
				if IsValid(npc) and IsValid(closest) then
					if isfunction( npc.SetEnemy ) then npc:SetEnemy( closest ) end
					if isfunction( npc.SetTarget ) then npc:SetTarget( closest ) end
					if isfunction( npc.SetLastPosition ) then npc:SetLastPosition( closest:GetPos() ) end
					SetScheduleDiligent( npc, npc_t.chase_schedule or { SCHED_TARGET_CHASE, SCHED_CHASE_ENEMY, SCHED_FORCED_GO_RUN }, ntbl )
				end
			end)
		end
	end
end

// relationships between two npcd entities. "from" must be an npc or at least someone with the functions
function Relatio( from, from_t, to, to_t )
	if from == to then return end
	local fcl = from:GetClass()
	local tcl = to:GetClass()
	local fsq = from_t.squadpreset
	local tsq = to_t.squadpreset
	local related

	//outward
	if from_t.relations.outward.self_squad and fsq and fsq == tsq 
	and not (
		from_t.relations.outward.self_squad_exclude_class[tcl]
		or from_t.relations.outward.self_squad_exclude_preset[to_t.npcpreset] and from_t.relations.outward.self_squad_exclude_preset[to_t.npcpreset] == to_t.npc_t.entity_type
		or from_t.relations.outward.self_squad_exclude_preset_squad[tsq] )
	then
		from:AddEntityRelationship( to, from_t.relations.outward.self_squad.d, from_t.relations.outward.self_squad.p )
		related = true
	elseif tsq != nil and from_t.relations.outward.preset_squad[tsq] then
		from:AddEntityRelationship( to, from_t.relations.outward.preset_squad[tsq].d, from_t.relations.outward.preset_squad[tsq].p )
		related = true
	elseif from_t.relations.outward.preset[to_t.npcpreset] and from_t.relations.outward.preset[to_t.npcpreset].t == to_t.npc_t.entity_type then
		from:AddEntityRelationship( to, from_t.relations.outward.preset[to_t.npcpreset].d, from_t.relations.outward.preset[to_t.npcpreset].p )
		related = true
	elseif from_t.relations.outward.class[tcl] and from:Disposition(to) != from_t.relations.outward.class[tcl].d then
		from:AddEntityRelationship( to, from_t.relations.outward.class[tcl].d, from_t.relations.outward.class[tcl].p )
		related = true
	elseif from_t.relations.outward.everyone and ( fsq == nil or tsq == nil or fsq != tsq )
	and not (
		from_t.relations.outward.everyone_exclude_class[tcl]
		or from_t.relations.outward.everyone_exclude_preset[to_t.npcpreset] and from_t.relations.outward.everyone_exclude_preset[to_t.npcpreset] == to_t.npc_t.entity_type
		or from_t.relations.outward.everyone_exclude_preset_squad[tsq] )
	and !t_disp_everyone_exceptions[tcl]
	then
		from:AddEntityRelationship( to, from_t.relations.outward.everyone.d, from_t.relations.outward.everyone.p )
		related = true
	end

	//inward
	if to_t.relations.inward.self_squad and tsq and tsq == fsq
	and not (
		to_t.relations.inward.self_squad_exclude_class[fcl]
		or to_t.relations.inward.self_squad_exclude_preset[from_t.npcpreset] and to_t.relations.inward.self_squad_exclude_preset[from_t.npcpreset] == from_t.npc_t.entity_type
		or to_t.relations.inward.self_squad_exclude_preset_squad[fsq] )
	then
		from:AddEntityRelationship( to, to_t.relations.inward.self_squad.d, to_t.relations.inward.self_squad.p )
		related = true
	elseif fsq != nil and to_t.relations.inward.preset_squad[fsq] then
		from:AddEntityRelationship( to, to_t.relations.inward.preset_squad[fsq].d, to_t.relations.inward.preset_squad[fsq].p )
		related = true
	elseif to_t.relations.inward.preset[from_t.npcpreset] and to_t.relations.inward.preset[from_t.npcpreset].t == from_t.npc_t.entity_type then
		from:AddEntityRelationship( to, to_t.relations.inward.preset[from_t.npcpreset].d, to_t.relations.inward.preset[from_t.npcpreset].p )
		related = true
	elseif to_t.relations.inward.class[fcl] then
		from:AddEntityRelationship( to, to_t.relations.inward.class[fcl].d, to_t.relations.inward.class[fcl].p )
		related = true
	elseif to_t.relations.inward.everyone and ( fsq == nil or tsq == nil or fsq != tsq ) 
	and not (
		to_t.relations.inward.everyone_exclude_class[fcl]
		or to_t.relations.inward.everyone_exclude_preset[from_t.npcpreset] and to_t.relations.inward.everyone_exclude_preset[from_t.npcpreset] == from_t.npc_t.entity_type
		or to_t.relations.inward.everyone_exclude_preset_squad[fsq] )
	and !t_disp_everyone_exceptions[tcl]
	then
		from:AddEntityRelationship( to, to_t.relations.inward.everyone.d, to_t.relations.inward.everyone.p )
		related = true
	end
	
	return related
end

// outward is done in NPCPostSpawn()
function Relatables( npc, npc_t )
	if !IsValid( npc ) or ( !activeNPC[npc] and !activePly[npc] ) then return end

	local ntbl = activeNPC[npc] or activePly[npc]
	if npc_t.relationships_inward then
		local r_lup_t = GetLookup( "relationships_inward", npc_t.entity_type, nil, cl )
		ApplyValueTable( npc_t.relationships_inward, r_lup_t.STRUCT, npc )

		//class inward
		if npc_t.relationships_inward.by_class ~= nil then
			for k, v in pairs( npc_t.relationships_inward.by_class ) do
				ApplyValueTable( v, r_lup_t.STRUCT["by_class"].STRUCT, npc )

				if GetPresetName( v["classname"] ) == nil or v["disposition"] == nil then continue end

				local cname = GetPresetName( v["classname"] )
				local disp = v["disposition"] // NOT a string
				local p = v["priority"] or 50

				ntbl.relations.inward.class[cname] = {
					d = disp,
					p = p,
				}
			end
		end

		//preset inward
		if npc_t.relationships_inward.by_preset ~= nil then
			for k, v in pairs( npc_t.relationships_inward.by_preset ) do
				ApplyValueTable( v, r_lup_t.STRUCT["by_preset"].STRUCT, npc )

				if v["disposition"] == nil then continue end
				if !istable( v["preset"] ) then continue end


				local cname = v["preset"]["name"]
				local ctyp = v["preset"]["type"]
				if !cname or !ctyp then continue end

				local disp = v["disposition"] // can be an int
				local p = v["priority"] or 50

				ntbl.relations.inward.preset[cname] = {
					t = ctyp, 
					d = disp, 
					p = p 
				}
			end
		end

		//everyone inward
		if npc_t.relationships_inward.everyone ~= nil then
			ApplyValueTable( npc_t.relationships_inward.everyone, r_lup_t.STRUCT["everyone"].STRUCT, npc )
			
			// exclude
			if npc_t.relationships_inward.everyone.exclude then
				ApplyValueTable( npc_t.relationships_inward.everyone.exclude, r_lup_t.STRUCT["everyone"].STRUCT["exclude"].STRUCT, npc )

				if npc_t.relationships_inward.everyone.exclude.by_preset then
					for k, v in pairs( npc_t.relationships_inward.everyone.exclude.by_preset ) do
						local cname = v["name"]
						local ctyp = v["type"]
						if cname ~= nil then
							if ctyp == "squad" then
								ntbl.relations.inward.everyone_exclude_preset_squad[cname] = ctyp
							else
								ntbl.relations.inward.everyone_exclude_preset[cname] = ctyp
							end
						end
					end
				end

				if npc_t.relationships_inward.everyone.exclude.by_class then
					for k, v in pairs( npc_t.relationships_inward.everyone.exclude.by_class ) do
						local class = GetPresetName(v)
						if class ~= nil then
							ntbl.relations.inward.everyone_exclude_class[class] = true
						end
					end
				end
			end

			if isnumber( npc_t.relationships_inward.everyone.disposition ) then
				ntbl.relations.inward.everyone = {
					d = npc_t.relationships_inward.everyone.disposition,
					p = npc_t.relationships_inward.everyone.priority or 50
				}
			end
		end

		//self squad inward
		if npc_t.relationships_inward.self_squad ~= nil then
			ApplyValueTable( npc_t.relationships_inward.self_squad, r_lup_t.STRUCT["self_squad"].STRUCT, npc )

			//exclude
			if npc_t.relationships_inward.self_squad.exclude then
				ApplyValueTable( npc_t.relationships_inward.self_squad.exclude, r_lup_t.STRUCT["self_squad"].STRUCT["exclude"].STRUCT, npc )

				if npc_t.relationships_inward.self_squad.exclude.by_preset then
					for k, v in pairs( npc_t.relationships_inward.self_squad.exclude.by_preset ) do
						local cname = v["name"]
						local ctyp = v["type"]
						if cname ~= nil then
							if ctyp == "squad" then
								ntbl.relations.inward.self_squad_exclude_preset_squad[cname] = ctyp
							else
								ntbl.relations.inward.self_squad_exclude_preset[cname] = ctyp
							end
						end
					end
				end

				if npc_t.relationships_inward.self_squad.exclude.by_class then
					for k, v in pairs( npc_t.relationships_inward.self_squad.exclude.by_class ) do
						local class = GetPresetName(v)
						if class ~= nil then
							ntbl.relations.inward.self_squad_exclude_class[class] = true
						end
					end
				end
			end

			if isnumber( npc_t.relationships_inward.self_squad.disposition ) then
				ntbl.relations.inward.self_squad = {
					d = npc_t.relationships_inward.self_squad.disposition,
					p = npc_t.relationships_inward.self_squad.priority or 50
				}
			end
		end
	end

	// apply relations between this and all entities
	local alleveryone = cvar.npc_allrelate.v:GetBool()
	for _, ent in pairs( ents.GetAll() ) do
		if !IsValid( npc ) then break end
		if !IsValid( ent ) then continue end
		if ent == npc then continue end
		if !alleveryone and not ( ent:IsNPC() or ent:IsNextBot() or ent:IsPlayer() ) then continue end
		local related

		if activeNPC[ent] or activePly[ent] then
			local cl = ent:GetClass()
			local ncl = npc:GetClass()
			local nntbl = activeNPC[ent] or activePly[ent]
			local sq = nntbl.squadpreset
			
			if ent:IsNPC() then
				related = Relatio( ent, nntbl, npc, ntbl )
			end
			if npc:IsNPC() then
				related = Relatio( npc, ntbl, ent, nntbl ) or related
			end
		else
			local cl = ent:GetClass()

			// outward
			if npc:IsNPC() then
				if ntbl.relations.outward.class[cl] and npc:Disposition(ent) != ntbl.relations.outward.class[cl].d then
					npc:AddEntityRelationship( ent, ntbl.relations.outward.class[cl].d, ntbl.relations.outward.class[cl].p )
					related = true
				elseif ntbl.relations.outward.everyone and !ntbl.relations.outward.everyone_exclude_class[cl] and !t_disp_everyone_exceptions[cl] then
					npc:AddEntityRelationship( ent, ntbl.relations.outward.everyone.d, ntbl.relations.outward.everyone.p )
					related = true
				end
			end
			
			// inward
			if ent:IsNPC() then
				if ntbl.relations.inward.class[cl] and ent:Disposition(npc) != ntbl.relations.inward.class[cl].d then
					ent:AddEntityRelationship( npc, ntbl.relations.inward.class[cl].d, ntbl.relations.inward.class[cl].p )
					related = true
				elseif ntbl.relations.inward.everyone and !ntbl.relations.inward.everyone_exclude_class[cl] and !t_disp_everyone_exceptions[cl] then
					ent:AddEntityRelationship( npc, ntbl.relations.inward.everyone.d, ntbl.relations.inward.everyone.p )
					related = true
				end
			end
		end

		if related then CoIterate(1) end
	end
end

// squads stuff

local g_squadcount = 0
function GenerateSquad( s, override2_t, pool, squadIDOvr, override3_t )
	if !Settings.squad[s] then print("npcd > GenerateSquad > no squad exists:", s) return nil end

	if Settings.squad[s]["npcd_enabled"] == false then return nil end

	if debugged then
		print( "npcd > GenerateSquad > ", s, override2_t, pool, squadIDOvr )
	end

	local squad_t = {
		["name"] = s,
		["spawns"] = {},
		["squadID"] = nil,
		["values"] = table.Copy( Settings.squad[s] ),
		["originpool"] = pool or nil,
	}

	if squad_t.values.spawn_req_navmesh and !HasNavMesh then return nil end
	if squad_t.values.spawn_req_nodes and !HasNodes then return nil end

	g_squadcount = g_squadcount + 1
	local squadID = Settings.squad[s].squadname or s
	squadID = squadID..g_squadcount
	squad_t["squadID"] = squadIDOvr or squadID

	// squad override 1: squadpool
	// ok i've thought about and if you are going through the trouble of overriding the squad override's override
	//  then you're probably trying to do something different so it doesn't need to be
	//  merged so thoroughly
	local ovr_p
	if pool != nil and Settings.squadpool[pool] then 
		ovr_p = OverrideTable( squad_t["values"], Settings.squadpool[pool], "squad", "squadpool", nil, true )
		// returns copy of override tables
	end

	// squad override 2: drop set
	local ovr2
	if override2_t then // override2_t == dset_t
		ovr2 = OverrideTable( squad_t["values"], override2_t, "squad", "drop_set" )
	end

	// squad override 3: individual drop
	local ovr3
	if override3_t then // override3_t == drop_t.preset_values
		ovr3 = OverrideTable( squad_t["values"], override3_t, "squad", nil, nil, nil, t_lookup["drop"]["preset_values"].STRUCT )
	end

	ApplyValueTable( squad_t.values, t_lookup.squad )

	// fill out spawns from spawnlist that will be passed to SpawnSquad()
	for _, spwnTbl in pairs( squad_t["values"].spawnlist ) do
		ApplyValueTable( spwnTbl, t_lookup["squad"]["spawnlist"].STRUCT )
		ApplyValueTable( spwnTbl["count"], t_lookup["squad"]["spawnlist"].STRUCT["count"].STRUCT )

		if !spwnTbl["preset"] or !spwnTbl["preset"]["type"] or !spwnTbl["preset"]["name"] or !spwnTbl["count"] then
			continue
		end

		if spwnTbl.chance and math.random() >= spwnTbl.chance.f then
			continue
		end

		local typ = spwnTbl["preset"]["type"]
		local npcname = spwnTbl["preset"]["name"]

		local npcTable = Settings[ typ ] and Settings[ typ ][ npcname ] or nil
		if npcTable == nil then
			print("npcd > GenerateSquad > ".. typ .. " PRESET \""..npcname.."\" NOT FOUND")
			continue
		else
			if npcTable["npcd_enabled"] == false then continue end
			npcTable = table.Copy( npcTable )
		end
		
		if GetPresetName( npcTable.classname ) == nil then continue end

		local tospawn = 0
		if !spwnTbl["count"]["median"] then // min , max
			local min = spwnTbl["count"]["min"]
			local max = spwnTbl["count"]["max"]
			tospawn = math.Round(math.random() * (max - min) + min)
		else  // min , median, max
			local min = spwnTbl["count"]["min"]
			local mid = spwnTbl["count"]["median"]
			local max = spwnTbl["count"]["max"]
			local chance = math.random()
			
			if chance < 0.5 then
				tospawn = (mid-min) * (chance/0.5) + min
			elseif chance == 0.5 then
				tospawn = mid
			elseif chance > 0.5 then
				tospawn = (max-mid) * ((chance-0.5)/0.5) + mid
			end
			tospawn = math.Round(tospawn)
		end

		if tospawn < 0 then continue end

		// npc override 1: squad
		OverrideTable( npcTable, squad_t["values"], npcTable.entity_type, "squad", true )

		// npc override 2: squadpool
		if ovr_p then
			OverrideTable( npcTable, ovr_p, npcTable.entity_type, "squadpool", true )
		end

		// npc override 3: drop set
		if ovr2 then 
			OverrideTable( npcTable, ovr2, npcTable.entity_type, "drop_set", true )
		end

		// npc override 3: individual drop
		if ovr3 then 
			OverrideTable( npcTable, ovr3, npcTable.entity_type, nil, true, nil, t_lookup["drop"]["preset_values"].STRUCT )
		end

		for i=1,tospawn do
			local n_t = table.Copy( npcTable )
			local hasrandom = istable( n_t.model ) or istable( n_t.scale )
			ResolveEntValueTable( nil, n_t ) // preestablish npc_t, to keep GroupOBB consistent when using random values
			table.insert( squad_t["spawns"], {
				-- ["count"] = tospawn,
				["name"] = npcname,
				["npc_t"] = n_t,
				["obb_random"] = hasrandom,
			} )
		end
	end

	return squad_t
end

function SpawnSquad( newSquad, pos, announce, fadein )
	if debugged then print("npcd > SpawnSquad(", newSquad, pos, announce, fadein, ")" ) end
	local spawned = {}
	local spawnedcount = 0
	if !pos then print("no pos") return 0 end
	local i = 0
	local fadein = fadein
	if fadein == nil then
		fadein = newSquad["values"]["fadein"]
	end

	local sf_tmp = {}
	local baseang = RandomAngle()
	baseang:Normalize()
	local sc = table.Count( newSquad["spawns"] )
	local si = 0
	local oldcollides = {}

	ApplyValueTable( newSquad["values"]["spawnforce"], t_lookup["squad"]["spawnforce"].STRUCT )

	// spawn npcs and spawnforce and nocollide
	for _, v in RandomPairs(newSquad["spawns"]) do
		local presetName = v["name"]
		local npc_t = v["npc_t"]
		
		local new = SpawnNPC(
			presetName, --presetName, anpc_t, pos, ang, squad_t, npcOverride, doFadeIns, pool, nocopy, nopoolovr, oldsquad
			npc_t, --anpc_t
			pos, --pos
			nil,  --ang
			newSquad, --squad_t
			nil, --npcOverride
			fadein, --doFadeIns
			newSquad["originpool"], --pool
			true, --nocopy
			true, --nopoolovr
			nil --oldsquad
		)

		if IsValid( new ) then
			table.insert( spawned, new )
			si = si + 1

			// spawnforce
			ApplyTmpValueTable( sf_tmp, nil, newSquad["values"]["spawnforce"], t_lookup["squad"]["spawnforce"].STRUCT )
			local vec = Vector(
				sf_tmp["forward"] or 0,
				0,
				sf_tmp["up"] or -5
			)
			if sf_tmp["rotrandom"] then
				vec:Rotate( RandomAngle() )
			else
				vec:Rotate( baseang + Angle(0, 360/sc * si, 0 ) )
			end
			if !new:IsNPC() and IsValid( new:GetPhysicsObject() ) then
				new:GetPhysicsObject():SetVelocity( vec )
			else
				new:SetVelocity(vec)
			end

			// set nocollide collisiongroup
			oldcollides[new] = new:GetCollisionGroup() or COLLISION_GROUP_NONE
			-- print( oldcollides[npc], table.KeyFromValue( t_npc_base_values["collisiongroup"].ENUM, oldcollides[npc] ) )
			new:SetCollisionGroup( COLLISION_GROUP_DEBRIS ) // is there a better collisiongroup?

			// end nocollide collisiongroup, waiting until it is not penetrating something
			timer.Simple( 1, function()
				if IsValid( new ) and oldcollides[new] then
					if activeNPC[new] and newSquad["values"]["spawncollide_fast"] then
						new:SetCollisionGroup(oldcollides[new])
						return
					end
					local timername = "npcd_timer"..timerc
					timer.Create( timername, 0.5, 0, function() -- check every half second
						if !IsValid( new ) then
							timer.Destroy( timername )
							return
						end
						local penetrating = ( IsValid( new:GetPhysicsObject() ) and new:GetPhysicsObject():IsPenetrating() ) or false --if we are penetrating an object
						if !penetrating then
							local mins = new:OBBMins()
							local maxs = new:OBBMaxs()
							local startpos = new:GetPos()
							mins:Rotate( new:GetAngles() )
							maxs:Rotate( new:GetAngles() )
							
							-- local tr = util.TraceHull( {
							-- 	start = startpos,
							-- 	endpos = startpos,
							-- 	maxs = maxs,
							-- 	mins = mins,
							-- 	filter = new,
							-- 	mask = MASK_NPCSOLID,
							-- 	ignoreworld = true,
							-- } )

							local e = ents.FindInBox( mins + startpos, maxs + startpos )

							for _, ent in ipairs( e ) do
								if IsValid( ent ) and ent != new and ent:IsSolid() and IsCharacter( ent ) then
									-- print( new, ent )
									penetrating = true
									break
								end
							end
						end
						if not penetrating then
							new:SetCollisionGroup(oldcollides[new]) -- Stop no-colliding by returning the original collision group (or default player collision)
							timer.Destroy( timername )
						end
					end)
					timerc = timerc + 1
				-- elseif
				-- constraint.RemoveConstraints(new, "NoCollide")
				end
			end)
		end

		CoIterate(75)
	end

	// add nocollide constraint between squad
	// bug(???): when did npcs suddenly start naturally not-colliding with their own types anyways

	if newSquad["values"]["nocollide"] then
		for i=2,#spawned do
			for _, npc in ipairs( { unpack(spawned, i) } ) do
				if !IsValid(spawned[i-1])
				or !IsValid(npc) then
					continue 
				end
				// problem: constraint.NoCollide fails when too many ents made at once
				constraint.NoCollide( spawned[i-1], npc, 0, 0 )
			end
		end
	end

	// check if nextbot spawn grid is needed
	local useNBspawn = false
	local bounds, gc, gw, gh, w, h
	for i, npc in ipairs(spawned) do
		if !IsValid(npc) then
			continue
		end

		if npc:IsNextBot() and newSquad.values.spawngrid != false or newSquad.values.spawngrid then
			
			local eb = newSquad.values.spawngrid_gap or cvar.spawngrid_default.v:GetFloat()

			bounds = newSquad["bounds"] or activeNPC[npc]["squad_t"] and activeNPC[npc]["squad_t"]["bounds"] or GetGroupOBB( newSquad )
			if bounds != nil then
				gc = math.ceil( math.sqrt(#spawned) ) //square grid
				w = (bounds[2].x - bounds[1].x) + eb
				h = (bounds[2].y - bounds[1].y) + eb
				gw =  w * gc / 2
				if #spawned > 2 then
					gh = h * gc / 2
				else
					gh = h
				end
				useNBspawn = true
			end
			break
		end
	end

	// set up queens for hivequeen rope effect placed later
	local queens
	if newSquad["values"]["hivequeen"] and newSquad["values"]["hivequeen"]["name"] and newSquad["values"]["hiverope"] then
		for _, hr in pairs( newSquad["values"]["hiverope"] ) do
			ApplyValueTable( hr, t_lookup["squad"]["hiverope"].STRUCT )
		end
		queens = {}
		for _, qnpc in ipairs(spawned) do
			if !IsValid(qnpc) then continue end
			if activeNPC[qnpc]["npcpreset"] == newSquad["values"]["hivequeen"]["name"]
			and activeNPC[qnpc]["npc_t"]["entity_type"] == newSquad["values"]["hivequeen"]["type"] then
				table.insert(queens, qnpc)
			end
		end
	end

	// set ready, count spawn weight, place in spawn grid if needed, hiverope
	for i, npc in pairs(spawned) do
		if !IsValid(npc) or !activeNPC[npc] then
			-- table.remove( spawned )
			-- if debugged then print("guhuh?") end
			if debugged then print("npcd > SpawnSquad > Entity no longer valid mid squad spawn: ", npc ) end
			continue
		end

		if activeFade[npc] then activeFade[npc].ready = true end // set ready for fade in

		activeNPC[npc]["squad"] = spawned

		spawnedcount = spawnedcount + ( activeNPC[npc]["npc_t"]["quota_fakeweight"] or activeNPC[npc]["weight"] )

		// grid spawn
		if useNBspawn then
			x = -gw + ( w * math.mod( i , gc ) ) + w/2
			y = -gh + ( h * math.floor( (i-1) / gc ) ) + h/2
			local npos = util.TraceLine({
				start = pos + bounds[2],
				endpos = pos + bounds[2] + Vector( x, y, 0 ),
				mask = MASK_NPCSOLID,
			} )
			local tr = util.TraceLine({
				start = npos.HitPos + bounds[2],
				endpos = npos.HitPos - bounds[2],
				mask = MASK_NPCSOLID,
			})
			if not ( tr.HitNoDraw or tr.HitNonWorld or tr.HitSky or !util.IsInWorld(tr.HitPos) )
			and CheckSpawnPos( tr.HitPos + bounds[3], bounds, nil, newSquad.values.spawn_req_water ) then
				npc:SetPos( tr.HitPos + bounds[3] )
			end
		end

		// hiverope
		if queens != nil
		and not ( activeNPC[npc]["npcpreset"] == newSquad["values"]["hivequeen"]["name"] and activeNPC[npc]["npc_t"]["entity_type"] == newSquad["values"]["hivequeen"]["type"] ) then
			for _, qnpc in ipairs(queens) do
				if qnpc == npc then continue end
				if !IsValid( qnpc ) then continue end
				for _, hr in pairs( newSquad["values"]["hiverope"] ) do
					CreateAttachRope( qnpc, hr["attachment_queen"], npc, hr["attachment_servant"], hr["width"], hr["material"] )
				end
			end
		end
		CoIterate( 2 )
	end

	// announce spawn
	if !table.IsEmpty(spawned) then
		squad_times[newSquad["name"]] = CurTime()

		// resolve announce values
		if newSquad["values"]["announce_spawn"] != nil then
			newSquad["announce_spawn"] = newSquad["values"]["announce_spawn"]
		else
			newSquad["announce_spawn"] = newSquad["values"]["announce_all"]
		end

		if newSquad["values"]["announce_death"] != nil then
			newSquad["announce_death"] = newSquad["values"]["announce_death"]
		else
			newSquad["announce_death"] = newSquad["values"]["announce_all"]
		end

		if announce or ( announce == nil and newSquad["announce_spawn"] ) then
			local mname = newSquad["values"]["displayname"] or newSquad["name"] or "The enemy"
			local msg = newSquad["values"]["announce_spawn_message"] or mname .. generic_spawn_announce[ math.random(#generic_spawn_announce) ]
			
			net.Start("npcd_announce")
				net.WriteString( msg )
				net.WriteColor( newSquad["values"]["announce_color"] or RandomColor( nil, nil, nil, nil, 1, 1 ) )
			net.Broadcast()
		end
	end

	return spawnedcount, spawned
end

function SpawnItem( itemclass, drop_t, pos, ang )
	if debugged then print( "npcd > SpawnItem(", itemclass, drop_t, pos, ang,")" ) end
	local pos = pos or PickNode(nil, nil, nil, Nodes) or PickAnywhere() or game.GetWorld():GetPos()
	local ang = ang or RandomAngle( nil, nil, nil, nil, -180, 180 )
	
	local item = ents.Create( itemclass )
	if !IsValid(item) then
		print("npcd > SpawnItem > item invalid")
		return nil
	end

	item:SetPos(pos)
	item:SetAngles(ang)

	local ndrop_t
	if drop_t then
		ndrop_t = table.Copy( drop_t )
		ApplyValueTable( ndrop_t, t_lookup["item"], item )
	end

	if ndrop_t then
		ndrop_t.entity_type = ndrop_t.entity_type or "item"
	end

	PreEntitySpawn( item, ndrop_t )
	
	item:Spawn()
	if ndrop_t == nil or ndrop_t.activate != false then item:Activate() end

	PostEntitySpawn( item, ndrop_t )

	if ndrop_t and ndrop_t.spawneffect then
		for _, sf in pairs(ndrop_t["spawneffect"]) do
			CreateEffect( sf, item, item:GetPos() )
		end
	end

	return item
end

local f_wset_exclude = {
	["all"] = function() return true end,
	["player"] = function( ent ) return ent:IsPlayer() end,
	["npc"] = function( ent ) return ent:IsNPC() end, 
}

function SpawnWeaponSet( ent, wset, pos, ang, npc_t, squad_t, pool )
	if !wset or !Settings["weapon_set"][wset] then
		return nil
	end
	if !ent and !pos then
		return nil
	end

	local wset_t = table.Copy( Settings["weapon_set"][wset] )
	ApplyValueTable( wset_t, t_lookup["weapon_set"] )

	if IsValid( ent ) and wset_t["removeall"] then
		if isfunction( ent.StripWeapons ) then
			ent:StripWeapons()
		elseif isfunction( ent.GetWeapons ) then
			for _, wep in ipairs( ent:GetWeapons() ) do
				if IsValid( wep ) then
					wep:Remove()
				end
			end
		end
	end

	if IsValid( ent ) and wset_t["exclude"] then
		if f_wset_exclude[wset_t["exclude"]]( ent ) then
			return nil
		end
	end

	local fwep, fwep_t
	local wep, wep_t
	local allwep = {}

	if wset_t["weapons"] then
		if wset_t["giveall"] then
			for wi in pairs( wset_t["weapons"] ) do
				wep, wep_t = SpawnWeapon( wset_t, wi, pos, ang, ent, npc_t, squad_t, pool )
				if IsValid( wep ) then
					allwep[wep] = wep_t
					fwep = wep
					fwep_t = wep_t
					CoIterate(3)
				end
			end
		else
			wep, wep_t = SpawnWeapon( wset_t, nil, pos, ang, ent, npc_t, squad_t, pool )
			if IsValid( wep ) then
				allwep[wep] = wep_t
				fwep = wep
				fwep_t = wep_t
			end
		end
	end

	-- print( wep )

	return fwep, fwep_t, allwep
end

function SpawnWeapon( a_wset, windex, pos, ang, wielder, npc_t, squad_t, pool )
	if a_wset == nil then return nil end
	if a_wset["npcd_enabled"] == false then return nil end

	local pos = pos or IsValid(wielder) and wielder:GetPos() or PickNode(nil, nil, nil, Nodes) or PickAnywhere() or game.GetWorld():GetPos()
	local ang = ang or RandomAngle( nil, nil, nil, nil, -180, 180 )

	local wset = table.Copy( a_wset )

	// weapon set override: squad
	if squad_t then
		OverrideTable( wset, squad_t["values"], "weapon_set", "squad", true )
	end

	// weapon set override: pool
	if pool != nil and Settings.squadpool[pool] then --and Settings.squadpool[pool]["override"] then
		OverrideTable( wset, Settings.squadpool[pool], "weapon_set", "squadpool", nil, true )
	end

	if !wset["weapons"] then
		print("npcd > SpawnWeapon > no weapons list in", wset )
		return nil
	end

	// roll or pick given index
	local wi = windex
	if wi != nil then 
		wepname = wset["weapons"][wi]["classname"]
	else
		wepname, wi = RollExpected( wset["weapons"], nil, "classname" )
	end

	wepname = GetPresetName( wepname )

	local wep_t = table.Copy( wset["weapons"][wi] )

	if !wep_t then 
		print( "npcd > SpawnWeapon > no wep_t" )
		return nil 
	end

	// inherit npc values
	if npc_t != nil then
		if npc_t.weapon_inherit then
			for _, wk in ipairs( t_weapon_inherit ) do
				if wep_t[wk] == nil and npc_t[wk] != nil then
					wep_t[wk] = npc_t[wk]
				end
			end
		end
		wep_t.startalpha = wep_t.startalpha or npc_t.startalpha
	end

	// weapon override: weapon set
	OverrideTable( wep_t, wset, "weapon", "weapon_set" )

	// weapon override: squad
	if squad_t then
		OverrideTable( wep_t, squad_t["values"], "weapon", "squad" )
	end

	// weapon override: pool
	if pool != nil and Settings.squadpool[pool] then  --and Settings.squadpool[pool]["override"] and Settings.squadpool[pool]["override"]["weapon"] then
		OverrideTable( wep_t, Settings.squadpool[pool], "weapon", "squadpool", nil, true )
	end

	wep_t.entity_type = wep_t.entity_type or "weapon"

	PreEntitySpawn( wep, wep_t )

	// create and equip weapon
	local wep
	if IsValid(wielder) and isfunction( wielder.Give ) then
		// replace weapon
		if wielder:IsPlayer() and wielder:HasWeapon( wepname ) then
			wielder:StripWeapon( wepname )
		elseif isfunction( wielder.GetWeapon ) and IsValid( wielder:GetWeapon( wepname ) ) then
			wielder:GetWeapon( wepname ):Remove()
		end

		wep = wielder:Give(wepname)
	else
		wep = ents.Create(wepname)
		if IsValid( wep ) then
			wep:SetPos(pos)
			wep:SetAngles(ang)
			wep:Spawn()
			if wep_t.activate != false then wep:Activate() end
		end
	end

	if !IsValid( wep ) then return nil end

	ApplyValueTable( wep_t, t_lookup["weapon"], wep )
	PostEntitySpawn( wep, wep_t )

	// wepon postspawn
	if wielder != nil and wielder:IsPlayer() then
		if wep_t.giveammo_primary then
			wielder:GiveAmmo( wep_t.giveammo_primary, wep:GetPrimaryAmmoType() )
		end
		if wep_t.giveammo_secondary then
			wielder:GiveAmmo( wep_t.giveammo_secondary, wep:GetSecondaryAmmoType() )
		end

		// todo: viewmodel stuff
	end
	
	if wep_t.spawneffect and wielder == nil then
		for _, sf in pairs(wep_t["spawneffect"]) do
			CreateEffect( sf, wep, wep:GetPos() )
		end
	end
	
	return wep, wep_t
end

hook.Add( "PostDrawViewModel", "npcd_viewmodels", function( vm, ply, model )
	print( "vieewmodel",vm, ply, model )
end )


// drop set stuff

function IsDropMaxedOut( dset_t, drop_t )
	return (dset_t["maxdrops"] and dset_t["count"] >= dset_t["maxdrops"]) or (drop_t["max"] and drop_t["count"] >= drop_t["max"])
end

function AddDropQueue( ent, pos, ang, ndset_t, ntbl )
	table.insert( spawnerQueue, {
		drop = ndset_t,
		ent = ent,
		pos = pos,
		ang = ang,
		ntbl = ntbl,
	} )
end

function DoDrops( ent, pos, ang, ndset_t, ntbl, depth )
	local depth = depth and depth + 1 or 1
	if depth > 10 then return nil end
	
	if !ndset_t then return nil end
	if ndset_t["npcd_enabled"] == false then return nil end

	local dset_t = table.Copy( ndset_t )
	ApplyValueTable( dset_t, t_lookup["drop_set"] )

	dset_t["count"] = 0

	local rDropTbl	
	// roll every drop
	for d=1,dset_t["rolls"] do
		// if shuffle, shuffle every roll
		if dset_t.shuffle then
			rDropTbl = shuffle( table.GetKeys(dset_t["drops"]) )
		else
			rDropTbl = table.GetKeys(dset_t["drops"])
		end

		for _, k in ipairs(rDropTbl) do
			dset_t["drops"][k]["count"] = dset_t["drops"][k]["count"] or 0

			local drop_t = table.Copy( dset_t["drops"][k] )
			ApplyValueTable( drop_t, t_lookup["drop"] )

			if !drop_t["forcemin"] and IsDropMaxedOut(dset_t, drop_t) then continue end

			// drop mins
			if drop_t["min"] > drop_t["count"] then
				for i=1,drop_t["min"]-drop_t["count"] do
					if !drop_t["forcemin"] and IsDropMaxedOut(dset_t, drop_t) then break end
					-- print("npcd > DoDrops > drop #"..dset_t["count"]+1)
					-- print( drop_t )
					local dropadd = SpawnDrop( ent, pos, ang, drop_t, ntbl, dset_t, depth )
					if dropadd then
						dset_t["drops"][k]["count"] = dset_t["drops"][k]["count"] + dropadd
						dset_t["count"] = dset_t["count"] + dropadd
					end
				end
				continue
			end

			if IsDropMaxedOut(dset_t, drop_t) then continue end
			
			// roll
			local roll = math.random()
			local chance = drop_t.chance and drop_t.chance["f"] or 1
			if roll < chance then
				local dropadd = SpawnDrop( ent, pos, ang, drop_t, ntbl, dset_t, depth )
				if dropadd then
					dset_t["drops"][k]["count"] = dset_t["drops"][k]["count"] + dropadd
					dset_t["count"] = dset_t["count"] + dropadd
				end
			end
		end
	end

	return true // for validating when recursively spawned
end

function SpawnDrop( ent, dpos, ang, drop_t, ntbl, dset_t, depth )
	// ent = killed npc
	if !dpos or !drop_t then
		Error( "npcd > SpawnDrop > pos or drop_t nil" )
		return nil
	end
	local valid = false // boolean or entity. validation is given through the function return
	local add = 1

	local pos = ( IsValid( ent ) and ent:GetPos() + ( ent:OBBCenter() * 0.33 ) or dpos )

	// preset type drops
	if drop_t.type == "preset" and drop_t.preset_values and drop_t.preset_values.preset
	and t_valid_drop_presets[ drop_t.preset_values.preset["type"] ] and Settings[ drop_t.preset_values.preset["type"] ][ drop_t.preset_values.preset["name"] ] then
		local pr_t = drop_t.preset_values
		local dropType = pr_t.preset["type"]
		local dropPreset = pr_t.preset["name"]
		local dropInherit = pr_t.inherit

		// character
		if ENTITY_SETS[dropType] then
			local npcTable = table.Copy( Settings[dropType][dropPreset] )
			local squadtbl = dropInherit and ntbl and ntbl["squad_t"] and table.Copy( ntbl["squad_t"] ) or {}

			if dropInherit then
				if ntbl != nil and ntbl["squad_t"] then
					OverrideTable( npcTable, ntbl["squad_t"]["values"], dropType, "squad", true )
				end
			end

			// set override
			if dset_t != nil then -- and dset_t.override then
				OverrideTable( npcTable, dset_t, dropType, "drop_set", true )
			end

			// individual override
			OverrideTable( npcTable, pr_t, dropType, nil, true, nil, t_lookup["drop"]["preset_values"].STRUCT )

			squadtbl["values"] = squadtbl["values"] or {}

			valid = SpawnNPC(
				dropPreset, 
				npcTable, 
				pos + ( drop_t.offset or Vector() ), -- ent:GetPos() + ( ent:OBBCenter() * 0.33 ) + ( drop_t.offset or Vector() ), 
				pr_t.keepangle and ang,
				squadtbl,
				nil,
				false,
				ntbl != nil and ( ntbl["pool"] or ntbl["squad_t"] and ntbl["squad_t"]["originpool"] ) or nil,
				true
			)

			if valid and activeNPC[valid] then
				activeNPC[valid]["spawned"] = true
				local vpos = valid:GetPos()
				local bound = valid:OBBMins()
				if bound.z < 0 then
					valid:SetPos( Vector( vpos.x, vpos.y, vpos.z + -bound.z ) )
				end
			end
			if dropInherit and ntbl and ntbl["squad"] then AddToSquad( valid, ntbl["squad"] ) end
		// squad
		elseif dropType == "squad" then
			local sq_spawned
			valid, sq_spawned = SpawnSquad(
				GenerateSquad(
					dropPreset,
					dset_t,
					ntbl and ntbl["squad_t"] and ntbl["squad_t"]["originpool"] or nil,
					dropInherit and ntbl and ntbl["squad_t"] and ( ntbl["squad_t"]["squadID"] or IsValid( ent ) and ent:GetKeyValues()["squadname"] ) or nil,
					pr_t ),
				pos
			)

			if valid then
				if ntbl != nil and ntbl["squad"] and dropInherit then
					for _, sqnpc in pairs(sq_spawned) do
						AddToSquad( sqnpc, ntbl["squad"] )
					end
				end

				if drop_t.squad_disposition then
					timer.Simple( engine.TickInterval() * 2, function()
						for _, sqnpc in pairs( sq_spawned ) do
							if !IsValid( sqnpc ) then continue end

							if IsValid( ent ) then
								if sqnpc:IsNPC() then
									sqnpc:AddEntityRelationship( ent, drop_t.squad_disposition, 99 )
								end
								if ent:IsNPC() then
									ent:AddEntityRelationship( sqnpc, drop_t.squad_disposition, 99 )
								end
							end

							if ntbl != nil and ntbl["squad"] then
								for _, n in pairs( ntbl["squad"] ) do
									if !IsValid( n ) then continue end
									if n == ent then continue end

									if n:IsNPC() then
										n:AddEntityRelationship( sqnpc, drop_t.squad_disposition, 99 )
									end
									if sqnpc:IsNPC() then
										sqnpc:AddEntityRelationship( n, drop_t.squad_disposition, 99 )
									end
								end
							end
						end
					end )
				end	

				if dset_t["count_per_squad_spawn"] then
					add = table.Count( sq_spawned ) //num of spawned
				end
			end
		// weapon set
		elseif dropType == "weapon_set" then
			valid = SpawnWeaponSet(
				nil,
				dropPreset,
				pos + ( drop_t.offset or Vector() ),
				nil,
				dropInherit and npc_t or nil,
				dropInherit and ntbl and ntbl["squad_t"] or nil,
				ntbl and ( ntbl["pool"] or ntbl["squad_t"] and ntbl["squad_t"]["originpool"] ) or nil
			)
		// drop set
		elseif dropType == "drop_set" and Settings[dropType][dropPreset]["drops"] then
			local r_dset_t = Settings[dropType][dropPreset]

			// inherit all overrides
			if dropInherit and dset_t and ( dset_t.override_soft or dset_t.override_hard ) then
				r_dset_t = table.Copy( Settings.drop_set[dropPreset] )
				
				for _, eot in ipairs( { "override_soft", "override_hard" } ) do
					if r_dset_t[eot] then
						SetEntValues( nil, dset_t, eot, t_lookup["drop_set"][eot] )
						SetEntValues( nil, r_dset_t, eot, t_lookup["drop_set"][eot] )
						for o, o_t in pairs( dset_t[eot] ) do
							SetEntValues( nil, dset_t[eot], o, t_lookup["drop_set"][eot].STRUCT[o] )
							if r_dset_t.override[o] then
								SetEntValues( nil, r_dset_t.override, o, t_lookup["drop_set"][eot].STRUCT[o] )
								for k, v in pairs( o_t ) do
									r_dset_t.override[o][k] = CopyData( v )
								end
							end
						end
					end
				end
				-- r_dset_t.override = r_dset_t.override or {}
				-- table.Merge( r_dset_t.override, dset_t.override )
			end
			valid = DoDrops( ent, pos, ang, r_dset_t, ntbl, depth )
		end
	// entity drops
	elseif drop_t.type == "entity" and drop_t.entity_values and GetPresetName( drop_t.entity_values.classname ) then --normal drop
		local newdrop_t = table.Copy( drop_t.entity_values )
		if dset_t != nil then
			OverrideTable( newdrop_t, dset_t, "entity", "drop_set", true )
		end

      ApplyValueTable( newdrop_t, t_lookup.item )

		valid = SpawnItem( GetPresetName( newdrop_t.classname ), newdrop_t, pos + ( drop_t.offset or Vector() ) + ( isvector(newdrop_t.offset) and newdrop_t.offset or Vector() ) )
	else
		print( "npcd > SpawnDrop > neither valid preset nor entity?", drop_t.type, drop_t.preset, drop_t.entity_values )
	end

	if valid then
		if IsEntity(valid) then
			// spawnforce
			if drop_t.spawnforce then
				ApplyValueTable( drop_t.spawnforce, GetLookup( "spawnforce", "drop", nil, nil ).STRUCT )

				local vec = Vector( drop_t.spawnforce["forward"] or 0, 0, drop_t.spawnforce["up"] or -5 )
				vec:Rotate( RandomAngle() )
				if IsValid( valid:GetPhysicsObject() ) then
					valid:GetPhysicsObject():SetVelocity( vec )
				else
					valid:SetVelocity(vec)
				end
			end

			if drop_t.destroydelay then
				local item = valid
				timer.Simple(drop_t.destroydelay, function()
					if IsValid(item) then
						item:Remove()
					end
				end)
			end

			if drop_t.squad_disposition then
				timer.Simple( engine.TickInterval() * 2, function()
					if !IsValid( valid ) then return end

					if IsValid( ent ) then
						if valid:IsNPC() then
							valid:AddEntityRelationship( ent, drop_t.squad_disposition, 99 )
						end
						if ent:IsNPC() then
							ent:AddEntityRelationship( valid, drop_t.squad_disposition, 99 )
						end
					end

					if ntbl != nil and ntbl["squad"] then
						for _, n in pairs( ntbl["squad"] ) do
							if !IsValid( n ) then continue end
							if n:IsNPC() then
								n:AddEntityRelationship( valid, drop_t.squad_disposition, 99 )
							end
							if valid:IsNPC() then
								valid:AddEntityRelationship( n, drop_t.squad_disposition, 99 )
							end
						end
					end
				end )
			end
			CoIterate(25)
		end

		return add
	else
		print("npcd > SpawnDrop >", valid, "NOT DROPPED")
		return nil
	end
end

function DoDropSetNormal( ent, dropSetList, ntbl )
	if !IsValid( ent ) then return end
	local pos = ent:GetPos() + ( ent:OBBCenter() * 0.33 )
	local ang = ent:GetAngles()
	for k, drops in pairs( dropSetList ) do
		ApplyValueTable( drops, t_lookup.struct["drop_set"].STRUCT )

		if !drops.drop_set or !drops.drop_set["name"] then
			continue
		end

		local chance = drops.chance and drops.chance["f"] or 1
		if math.random() < chance then
			if Settings.drop_set[ drops.drop_set["name"] ] then
				AddDropQueue( ent, pos, ang, Settings.drop_set[ drops.drop_set["name"] ], ntbl )
			end
		end
	end
end

function DoDamageFilterDropSet( ent, dmg, dropSetList, ntbl )
	if !IsValid( ent ) or !dmg then return end
	local pos = ent:GetPos() + ( ent:OBBCenter() * 0.33 )
	local ang = ent:GetAngles()
	for k, d_t in pairs( dropSetList ) do
		local drops = table.Copy( d_t )

		ApplyValueTable( drops, t_lookup.struct["damage_drop_set_damagefilter"].STRUCT )

		if !drops.drop_set or !drops.drop_set["name"] then
			continue
		end

		if drops.health_lesser then
			if istable( drops.health_lesser ) and drops.health_lesser["f"] and ( ( ent:Health() - dmg:GetDamage() ) / ent:GetMaxHealth() ) > drops.health_lesser["f"]
			or !istable( drops.health_lesser ) and ( ent:Health() - dmg:GetDamage() ) > drops.health_lesser then
				continue
			end
		end
		if drops.health_greater then
			if istable( drops.health_greater ) and drops.health_greater["f"] and ( ent:Health() / ent:GetMaxHealth() ) <= drops.health_greater["f"]
			or !istable( drops.health_greater ) and ent:Health() <= drops.health_greater then
				continue
			end
		end

		if drops.shot_threshold then
			if istable( drops.shot_threshold ) and drops.shot_threshold["f"] and ( dmg:GetDamage() / ent:GetMaxHealth() ) <= drops.shot_threshold["f"]
			or !istable( drops.shot_threshold ) and dmg:GetDamage() <= drops.shot_threshold then
				continue
			end
		end
		
		local chance = drops.chance and drops.chance["f"] or 1

		if math.random() < chance then
			if Settings.drop_set[ drops.drop_set["name"] ] then
				AddDropQueue( ent, pos, ang, Settings.drop_set[ drops.drop_set["name"] ], ntbl )
			end
		end

		if drops.multidrop_dmg then
			for i=drops.multidrop_dmg,math.min( dmg:GetDamage(), ent:Health() ),drops.multidrop_dmg do
				if math.random() < chance then
					if Settings.drop_set[ drops.drop_set["name"] ] then
						AddDropQueue( ent, pos, ang, Settings.drop_set[ drops.drop_set["name"] ], ntbl )
					end
				end
			end
		end

	end
end

function TargetSpawnSquad( targ, argstr, caller )
	local newSquad = GenerateSquad( argstr, nil, nil )
	if newSquad ~= nil then
		local tr = targ:GetEyeTrace()
		local bounds = GetGroupOBB( newSquad )
		if bounds == nil then return false end
		local SpawnPos = tr.HitPos + bounds[3] + tr.HitNormal * 15 --Vector( 0, 0, 15 )
		local fadein
		if cvar.spawner_fadein.v:GetBool() then
			fadein = newSquad["values"]["fadein"]
		else
			fadein = false
		end
		-- if !fadein then fadein = nil end

		-- SpawnSquad( newSquad, SpawnPos, nil, fadein )
		table.insert( spawnerQueue, {
			squad = newSquad,
			pos = SpawnPos,
			fadein = fadein,
			undo = caller
		} )
		return true
	else
		return false
	end
end

function TargetSpawnPreset( targ, typ, argstr, caller )
	if !IsValid( targ ) then return end
	if typ then
		if Settings[typ] and Settings[typ][argstr] then
			if typ == "squad" then
				TargetSpawnSquad( targ, argstr, caller )
			elseif typ == "weapon_set" then
				local wep = SpawnWeaponSet( targ, argstr )
				if IsValid( wep ) and wep:IsWeapon() and targ:IsPlayer() then
					targ:SelectWeapon( wep )
				end
			elseif typ == "drop_set" then
				AddDropQueue( targ, targ:GetPos() + ( targ:OBBCenter() * 0.33 ), targ:GetAngles(), Settings[typ][argstr], activeNPC[targ] or activePly[targ] or nil )
			elseif typ == "npc" or typ == "entity" or typ == "nextbot" then
				local npc = SpawnNPC(
					argstr,
					Settings[typ][argstr],
					GetPlyTrPos( targ ) + Vector( 0, 0, 15 ),
					nil,
					nil,				
					nil,
					false, //fadeIns
					nil
				)
				if IsValid( npc ) then
					if IsValid( caller ) then
						undo.Create( argstr )
							undo.AddEntity( npc )
							undo.AddFunction( function( tab )
								for _, ent in pairs( tab.Entities ) do
									if IsValid( ent ) then
										activeNPC[ent] = nil
										ent:Remove()
									end
								end
							end )
							undo.SetPlayer( caller )
						undo.Finish()
					end
					if !activeNPC[npc] then
						Error( "what" )
					else
						-- if activeFade[npc] then activeFade[npc].ready = true end
						activeNPC[npc]["spawned"] = true
					end
					local pos = npc:GetPos()
					local bound = npc:OBBMins()
					if bound.z < 0 then
						npc:SetPos( Vector( pos.x, pos.y, pos.z + -bound.z ) )
					end
				end
			elseif typ == "player" and IsValid( targ ) and targ:IsPlayer() then
				if !Settings[typ][argstr]["condition"]
				or !cvar.plyprs_doconds.v:GetBool()
				or CheckPlayerPrsCondition( targ, argstr, Settings[typ][argstr]["condition"] ) then
					FixPlayer( targ )
					activePly[targ] = nil
					local valid = SpawnNPC(
						argstr,
						Settings[typ][argstr],														
						nil,
						nil,
						nil,
						targ,
						false,
						nil
					)
					if valid and IsValid( caller ) then
						undo.Create( argstr )
							undo.SetPlayer( caller )
							undo.AddFunction( function( tab, ply )
								if IsValid( ply ) then
									FixPlayer( ply )
									activePly[ply] = nil
									net.Start( "npcd_ply_preset" )
										net.WriteString( "" )
									net.Send( ply )
								end
							end , targ )
						undo.Finish()
					end
					if valid then
						ply_preset_hist[targ] = ply_preset_hist[targ] or {}
						ply_preset_hist[targ][argstr] = true
					end
				elseif IsValid( caller ) then
					net.Start( "npcd_announce" )
						net.WriteString( "Player \"" .. targ:GetName() .. "\" does not meet conditions for " .. argstr .. "!" )
						net.WriteColor( RandomColor( 180, 190, 0.2, 0.4, 1, 1 ) )
					net.Send( caller )
				end
			end
		end
	else
		if Settings.squad[argstr] then
			TargetSpawnSquad( targ, argstr, caller )
		else
			local npc_t = GetCharacterPresetTable( argstr )
			if npc_t then
				local npc = SpawnNPC(
					argstr,
					npc_t,
					GetPlyTrPos( targ ) + Vector(0, 0, 5),
					nil,
					nil,				
					nil,
					false,
					nil
				)
				if IsValid( npc ) then
					if IsValid( caller ) then
						undo.Create( argstr )
							undo.AddEntity( npc )
							undo.SetPlayer( caller )
						undo.Finish()
					end
					if !activeNPC[npc] then
						Error( "what" )
					else
						-- if activeFade[npc] then activeFade[npc].ready = true end
						activeNPC[npc]["spawned"] = true
					end
					local pos = npc:GetPos()
					local bound = npc:OBBMins()
					if bound.z < 0 then
						npc:SetPos( Vector( pos.x, pos.y, pos.z + -bound.z ) )
					end
				end
			end
		end
	end
end