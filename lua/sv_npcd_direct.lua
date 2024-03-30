// directing stuff

module( "npcd", package.seeall )

local dircount = 0

local testpoint // info_null entity
local vector_up = Vector(0,0,32768)

function GetThinkRange()
	local trange = {}
	local i = 1
	trange[1] = cvar.direct_think_range_full.v:GetFloat() // peak pressure
	trange[2] = !cvar.stress_enabled.v:GetBool() and trange[1] or cvar.direct_think_range_zero.v:GetFloat() // zero pressure
	return trange
end

function PrintDirects()
	for p, tbl in pairs( direct_times ) do
		print( p, table.Count( tbl ) )
		PrintTable( tbl, 1 )
	end
end

// each squadpool is directed
function DoDirects( quotaOverride, sqQuotaOverride, spawnLimitOverride, radiusOverride, squadLimitOverride )
	local i = 0
	local quotaOverride = quotaOverride or nil
	local sqQuotaOverride = sqQuotaOverride or nil
	local quotad
	
	local dq = directQueue[1] or nil
	if dq then 
		quotaOverride = dq[1] or nil
		sqQuotaOverride = dq[2] or nil
		table.remove(directQueue, 1)
		if quotaOverride == -1 then quotad = true end
	end

	for p, sptbl in pairs( Settings.squadpool ) do
		if sptbl["npcd_enabled"] == false then
			continue
		end
		
		if !quotad and pool_times[p] and ( CurTime() < pool_times[p] ) then
			if debugged_spawner then print("npcd > DoDirects > Pool "..p.." skipped, CurTime/next: "..math.Round(CurTime(),3).."s / "..math.Round( (pool_times[p] or 0), 3) .."s") end
			continue
		end
		
		// value table
		local ptbl = table.Copy(sptbl)
		ApplyValueTable( ptbl, t_lookup["squadpool"] )

		if !quotad then
			if ptbl["minpressure"] and pressure < ptbl["minpressure"] or ptbl["maxpressure"] and pressure > ptbl["maxpressure"] then
				if debugged_spawner then
					print("npcd > DoDirects > Pool "..p.." pressure out of limit. pressure: ".. pressure, "min/max: ",ptbl["minpressure"],"/",ptbl["maxpressure"] )
				end
				continue
			end

			if !pool_times[p] and ptbl["initdelay"] and ptbl["initdelay"] > ( CurTime() - inittime ) and ( !quotaOverride or !sqQuotaOverride ) then
				if debugged_spawner then print("npcd > DoDirects > Pool "..p.." init delay: ", ptbl["initdelay"], CurTime(), inittime, CurTime() - inittime ) end
				-- pool_times[p] = inittime + ptbl["initdelay"]
				continue
			end
		end

		if !ptbl["spawns"] or table.IsEmpty(ptbl["spawns"]) then
			if debugged or debugged_spawner then print("npcd > DoDirects > Pool "..p.." no spawns") end
			continue
		end

		local spQ, sqQ
		if quotaOverride == -1 and ptbl["pool_spawnlimit"] then
			local sum = NPCMapCount( p )
			spQ = ( ptbl["pool_spawnlimit"] * ( ptbl["spawn_autoadjust"] != false and SpawnMapScale or 1 ) ) - sum
		end
		if sqQuotaOverride == -1 and ptbl["pool_squadlimit"] then
			local _, totalsq = CountSquads( nil, p )
			sqQ = ( ptbl["pool_squadlimit"] * ( ptbl["spawn_autoadjust"] != false and SpawnMapScale or 1 ) ) - totalsq
		end
		if debugged and (spQ or sqQ) then print("npcd > pool: ".. p .. " > fills: " .. tostring(spQ) .. ", ".. tostring(sqQ) ) end

		if debugged then print("npcd > DoDirects > Squadpool "..p, ptbl["pool_spawnlimit"], ptbl["radiuslimits"] ) end

		// direct
		Direct(
			spQ or nil, //numQuota
			sqQ or nil, //numSqQuota
			ptbl, //pool_t
			spawnLimitOverride or ptbl["pool_spawnlimit"] or nil, //mapLimit
			squadLimitOverride or ptbl["pool_squadlimit"] or nil, //squadLimit
			radiusOverride or ptbl["radiuslimits"], //RadiusTable
			p //PoolFilter
		)

		pool_times[p] = CurTime() + ( ptbl["mindelay"] or 0 ) // set pool's next time
		i = i + 1
		CoIterate(100)
	end

	-- if cvar.groupobb_meticulous.v:GetBool() then
	-- 	knownBounds[currentProfile] = {}
	-- end
end

// check squad limits and spawn limits, make quota, check entities in radiuses per player
// sort out valid/invalid positions to spawn at, pick and generate squad, spawn it, repeat until quota filled
function Direct( numQuota, numSqQuota, pool_t, mapLimit, squadLimit, RadiusTable, PoolFilter )
	if !inited or !pool_t then return end

	local directdelay = engine.TickInterval()

	local mapLimit = mapLimit and ( mapLimit * ( pool_t["spawn_autoadjust"] != false and SpawnMapScale or 1 ) ) or nil // spawnlimit
	local squadLimit = squadLimit and ( squadLimit * ( pool_t["spawn_autoadjust"] != false and SpawnMapScale or 1 ) ) or nil // squadlimit
	local SquadPool = pool_t["spawns"] --Settings.squadpool[0]["squads"]
	local RadiusTable = RadiusTable or radiuslimits
	local PoolFilter = PoolFilter

	if table.IsEmpty( SquadPool ) then
		print("npcd > Direct > NO SQUADS IN POOL")
		return
	end

	dircount = dircount + 1

	local poolsquads, totalsquads = CountSquads( nil, PoolFilter )


	// build valid squad table (mapmin, mapmax, mindelay)
	local valid_squads = {}
	local todo_mins = {}

	if pool_t.override and pool_t.override.squad then
		SetEntValues( nil, pool_t.override, "squad", t_lookup["squadpool"]["override"].STRUCT["squad"] )
	end

	local ovr_p
	local sq_tbls = {}
	for k, spwn in pairs( SquadPool ) do
		if spwn.preset == nil then continue end
		local sname = spwn.preset.name
		local styp = spwn.preset.type
		local expect = spwn.expected
		if !expect or !styp or !sname or !Settings[styp] or !Settings[styp][sname] then
			-- print(!expect, !styp, !sname, !Settings[styp], !Settings[styp] and !Settings[styp][sname] )
			if debugged then
				print("npcd > Direct > Squadpool spawn preset had missing values:",
				expect,styp,sname,styp and Settings[styp] and Settings[styp][sname])
			end
			continue
		end
		if Settings[styp][sname]["npcd_enabled"] == false then continue end

		local stbl

		if styp == "squad" then
			sq_tbls[sname] = sq_tbls[sname] or table.Copy( Settings.squad[sname] )
			stbl = sq_tbls[sname]
			CoIterate(1)
			-- if pool_t.override and pool_t.override.squad then
			-- 	for _, k in ipairs( {
			-- 		"mapmax",
			-- 		"mapmin",
			-- 		"mindelay",
			-- 	} ) do
			-- 		if pool_t.override.squad[k] then
			-- 			stbl[k] = CopyData( pool_t.override.squad[k] )
			-- 		end
			-- 	end
			-- end
			if ovr_p then
				OverrideTable( stbl, ovr_p, "squad", "squadpool" )
			else
				ovr_p = OverrideTable( stbl, pool_t, "squad", "squadpool", nil, true )
			end
			
			SetEntValues( nil, stbl, "mapmax", t_lookup["squad"]["mapmax"] )
			SetEntValues( nil, stbl, "mapmin", t_lookup["squad"]["mapmin"] )
			SetEntValues( nil, stbl, "mindelay", t_lookup["squad"]["mindelay"] )

			if ( stbl["mapmax"] and poolsquads[sname] and poolsquads[sname] >= stbl["mapmax"] )
			or ( stbl["mindelay"] and squad_times[sname] and CurTime() < squad_times[sname] + stbl["mindelay"] )
			then
				continue
			else
				if stbl["mapmin"] and poolsquads[sname] and poolsquads[sname] < stbl["mapmin"] then
					todo_mins[styp..sname] = {
						["expected"] = expect,
						["name"] = sname,
						["type"] = styp,
					}
				end
			end
		end
		valid_squads[styp..sname] = {
			["expected"] = expect,
			["name"] = sname,
			["type"] = styp,
			["count"] = stbl and poolsquads[sname] or 0,
			["mapmin"] = stbl and stbl["mapmin"] or nil,
			["mapmax"] = stbl and stbl["mapmax"] or nil,
			["mindelay"] = stbl and stbl["mindelay"] or nil,
		}
	end

	if debugged then
		print("npcd > Direct > valid squads #: ", table.Count(valid_squads) )
      if debugged_more then
         PrintTable( valid_squads )
         PrintTable( todo_mins )
      end
	end
	-- if true then return end
	
	local quota_max = cvar.spawn_quotaf_max.v:GetFloat()
	local quota_min = cvar.spawn_quotaf_min.v:GetFloat()

	local pos_tbl = {}
	local dist_tbl = {}

	// entity quota
	local entityquota
	if mapLimit then
		local psum = NPCMapCount( PoolFilter )
		local rem_spawn = math.max( mapLimit - psum, 0 )
		entityquota = numQuota or math.max(
            0,
			   -- pool_t["quota_entity_min"] and math.min( pool_t["quota_entity_min"], rem_spawn ) or cvar.spawn_quotaf_rawmin_spawn.v:GetFloat(),
			   pool_t["quota_entity_min"] or cvar.spawn_quotaf_rawmin_spawn.v:GetFloat(),
			   math.min( pool_t["quota_entity_max"] or math.huge,
                  -- rem_spawn,
				      mapLimit * math.Rand( quota_min, quota_max ) * ( pool_t["quota_entity_mult"] or 1 )
               )
            )
		entityquota = math.Round( entityquota, 3 )
		-- if debugged_spawner then
		-- 	for _, v in ipairs( { mapLimit, psum, rem_spawn, quota_min, quota_max, math.Rand( quota_min, quota_max ), pool_t["quota_entity_mult"], pool_t["quota_entity_min"] and math.min( pool_t["quota_entity_min"], rem_spawn ) or cvar.spawn_quotaf_rawmin_spawn.v:GetFloat() } ) do
		-- 		print( v )
		-- 	end
		-- end
	end

	// squad quota
	local squadquota
	if squadLimit then
		local rem_squad = math.max( squadLimit - totalsquads, 0 )
		squadquota = numSqQuota or math.max( 0,
			pool_t["quota_squad_min"] and math.min( pool_t["quota_squad_min"], rem_squad) or cvar.spawn_quotaf_rawmin_squad.v:GetFloat(),
			math.min( pool_t["quota_squad_max"] or math.huge,
				rem_squad,
				squadLimit * math.Rand( quota_min, quota_max ) * ( pool_t["quota_squad_mult"] or 1 ) )	)
		squadquota = math.Round( squadquota, 3 )
	end

	local quotadone = false

	// failsafe quota
	if !entityquota and !squadquota then entityquota = 1 end
	
	local spawnedcount = 0
	local despawnedcount = 0
	local squadcount = 0
	local iter = 0

	local beacons = {}
	for _, tbl in ipairs( { activeNPC, activePly } ) do
		for ent, ntbl in pairs( tbl ) do
			if ntbl.npc_t.beacon then
				beacons[ent] = true
			end
		end
	end

	if !pool_t.onlybeacons then
		for _, ply in ipairs( player.GetAll() ) do
			if activePly[ply] and activePly[ply].npc_t.beacon == false then
				continue
			end
			beacons[ply] = true
		end
	end

	local mapCount --= NPCMapCount(PoolFilter)

	// radius tables to values
	local radiuses
	local function RadTable()
		radiuses = {}
		for k, radtbl in pairs( table.Copy( RadiusTable ) ) do
			ApplyValueTable( radtbl, t_lookup["squadpool"]["radiuslimits"].STRUCT )

         local r_npc_lim, r_sq_lim
         // prevent double applying map scale
         if radtbl["radius_entity_limit"] then
            r_npc_lim = radtbl["radius_entity_limit"] * ( radtbl["radius_spawn_autoadjust"] != false and SpawnMapScale or 1 )
         else
            r_npc_lim = mapLimit or math.huge
         end
         if radtbl["radius_squad_limit"] then
            r_sq_lim = radtbl["radius_squad_limit"] * ( radtbl["radius_spawn_autoadjust"] != false and SpawnMapScale or 1 )
         else
            r_sq_lim = squadLimit or math.huge
         end

			local rk = table.insert( radiuses, {
				minRadius = radtbl["minradius"] and ( radtbl["minradius"] * ( radtbl["radius_autoadjust_min"] and MapScale or 1 ) ) or 0,
				radiusNPCLimit = r_npc_lim, // either radius or pool limit
				radiusSqLimit = r_sq_lim,
				toDespawn = radtbl["despawn"] or false,
				toDespawn_near = radtbl["despawn_tooclose"],
				toDespawn_addquota = radtbl["despawn_addquota"],
				chkrad = radtbl["spawn_tooclose"] or 0,
				nospawn = radtbl["nospawn"],
				outside = radtbl["outside"],
				skip = false, // changed when radius has no valid players
			} )

			radiuses[rk].maxRadius = radtbl["maxradius"] and
					( ( radtbl["maxradius"] - radiuses[rk].minRadius ) * ( radtbl["radius_autoadjust_max"] and MapScale or 1 ) + radiuses[rk].minRadius )
					or math.huge

			radiuses[rk].minRadius_sqr = radiuses[rk].minRadius * radiuses[rk].minRadius
			radiuses[rk].maxRadius_sqr = radiuses[rk].maxRadius * radiuses[rk].maxRadius
			radiuses[rk].chkrad_sqr = radiuses[rk].chkrad * radiuses[rk].chkrad
			radiuses[rk].toDespawn_near_sqr = radiuses[rk].toDespawn_near and radiuses[rk].toDespawn_near * radiuses[rk].toDespawn_near or nil
		end
	end
	RadTable()

	local dstime = CurTime()

	local valid_players = {}
	local invalid_players = {}

	local valid_nodes = {}
	-- local valid_nodes_tmp = {}
	local invalid_nodes = {} // no radius key

	local valid_navmesh_tmp = {}
	local valid_navmesh = {}

	local norads = table.IsEmpty( radiuses )

	local endcond = {}
	
	local reason
	local radius_counts = {}

	local lastradscale = MapScale
	local lastspawnscale = SpawnMapScale
	
	while !quotadone and iter < 101 do
		CoIterate(100)

		mapCount = NPCMapCount( PoolFilter )

		if lastradscale != MapScale or lastspawnscale != SpawnMapScale then
			RadTable()
			lastradscale = MapScale
			lastspawnscale = SpawnMapScale
		end
		
		// debug
		-- if mapCount >= mapLimit and !spawning_filled then
		-- 	print("SPAWNFULL IN",CurTime() - spawning_start)
		-- 	spawning_start = CurTime()
		-- 	spawning_filled = true
		-- end
		-- if mapCount <= 0 then 
		-- 	print("SPAWNWIPED IN",CurTime() - spawning_start)
		-- 	spawning_start = CurTime()
		-- 	spawning_filled = false
		-- end

		-- // pick random radius
		-- local k = math.random( #radiuses )
		-- local r = radiuses[k]

		iter = iter + 1

		valid_players = {}
		invalid_players = {}
		
		valid_nodes = {}
		-- valid_nodes_tmp = {}
		invalid_nodes = {} // no radius key

		valid_navmesh_tmp = {} // radius and ply keys
		valid_navmesh = {} // radius and ply keys

		local radded

		for k, r in pairs( radiuses ) do
			if r.skip then
				continue
			end

			local npcs_in = {}
			local sqcount_t = {}
			
			valid_players[k] = {}
			invalid_players[k] = {}

			-- valid_nodes_tmp[k] = {}
			valid_nodes[k] = {}

			if HasNavMesh then
				valid_navmesh_tmp[k] = {}
				valid_navmesh[k] = {}
			end

			// count npcs, add in/valid player radiuses
			for ply in RandomPairs( beacons ) do
				local count = 0
				CoIterate(1)
				if !IsValid(ply) then
					beacons[ply] = nil
					continue
				end
				if ply:IsPlayer() and !ply:Alive() and #player.GetAll() > 1
				or !ply:IsPlayer() and !ply:NotDead() then
					continue
				end
				
				pos_tbl[ply] = pos_tbl[ply] or ply:GetPos()
				dist_tbl[ply] = dist_tbl[ply] or {}
				local ply_pos = pos_tbl[ply]

				// count npcs
				for npc, ntbl in pairs( activeNPC ) do
					CoIterate(2)
					if !IsValid(npc) then continue end
					pos_tbl[npc] = pos_tbl[npc] or npc:GetPos()

					if --[[ PoolFilter == nil or ( PoolFilter ~= nil and ]] ntbl["pool"] == PoolFilter then
						local npc_pos = pos_tbl[npc]
						dist_tbl[ply][npc] = dist_tbl[ply][npc] or npc_pos:DistToSqr(ply_pos)
						local dist_sqr = dist_tbl[ply][npc]

						if (!r.outside and dist_sqr >= r.minRadius_sqr and dist_sqr < r.maxRadius_sqr)
                  or (r.outside and dist_sqr > r.maxRadius_sqr) then
							count = count + ntbl["weight"]
							table.insert(npcs_in, { ["npc"] = npc, ["dist_sqr"] = dist_sqr, ["weight"] = ntbl["weight"], } )

							local kvals = ntbl["squad_t"]["name"] or npc:GetKeyValues()["squadname"]
							if kvals then
								sqcount_t[kvals] = sqcount_t[kvals] or 0
								sqcount_t[kvals] = sqcount_t[kvals] + 1
							end
						end
					end
				end

				local sqcount = #sqcount_t
            local ecount = count - spawnedcount + (r.toDespawn_addquota and entityquota or 0)
            // this only works correctly for certain if despawn radius fills entire map

				// if invalid/valid player
				local overnpcrad = r.radiusNPCLimit and ecount >= r.radiusNPCLimit //the radius limit after the quota
            -- print(r.toDespawn, r.radiusNPCLimit,ecount,entityquota,overnpcrad, r.maxRadius)
				if overnpcrad or ( r.radiusSqLimit and sqcount >= r.radiusSqLimit) then // invalid player
					// despawn until at npc limit
					if r.toDespawn and overnpcrad then
						table.SortByMember(npcs_in, "dist_sqr")
                  local i = 0
                  local j = (ecount - r.radiusNPCLimit)
                  while overnpcrad and i < j do
                     i = i + 1
						-- for i=1,( ecount - r.radiusNPCLimit ) do
							local dnpc = npcs_in[i] and npcs_in[i]["npc"]

							if IsValid( dnpc ) then
								// check if too close to other players to despawn
								if r.toDespawn_near_sqr then
									if npcs_in[i]["dist_sqr"] < r.toDespawn_near_sqr then
										break
									end

									// *all* players
									local ok = true
									for _, ply in ipairs( player.GetAll() ) do
										if !IsValid(ply) then continue end
										if !ply:Alive() then continue end

										dist_tbl[ply] = dist_tbl[ply] or {}
										dist_tbl[ply][dnpc] = dist_tbl[ply][dnpc] or pos_tbl[dnpc]:DistToSqr( pos_tbl[ply] )
										if dist_tbl[ply][dnpc] < r.toDespawn_near_sqr then
											ok = false
											break
										end
									end
									if not ok then continue end
								end

								// despawn
								if debugged then print( "npcd > Direct > ".. tostring( dnpc ) ..  " REMOVED, over limit of radius " .. k .. ", dist_sqr " .. npcs_in[i].dist_sqr ) end

                        despawnedcount = despawnedcount + npcs_in[i]["weight"]
                        ecount = ecount - npcs_in[i]["weight"]
                        count = count - npcs_in[i]["weight"]
                        mapCount = mapCount - npcs_in[i]["weight"]
                        overnpcrad = r.radiusNPCLimit and ecount >= r.radiusNPCLimit
								
								dnpc:Remove()
							end
                     -- print(i,j,ecount,overnpcrad)
						end
                  if r.radiusNPCLimit and count >= r.radiusNPCLimit then
                     table.insert(invalid_players[k], ply)
                     if debugged then MsgN( "npcd > Direct > radius over limit for player ", ply, " at radius ", k, " [",count,"/",r.radiusNPCLimit,"]" ) end
                  else
                     table.insert(valid_players[k], ply)
                     if debugged then print( "npcd > Direct > radius-valid player ", ply, "at radius", k, " with despawned ", despawnedcount) end
                  end
               else
                  if r.radiusNPCLimit and count >= r.radiusNPCLimit then
                     table.insert(invalid_players[k], ply)
                     if debugged then MsgN( "npcd > Direct > radius over limit for player ", ply, " at radius ", k, " [",count,"/",r.radiusNPCLimit,"]" ) end
                  else
                     if debugged then print( "npcd > Direct > radius-valid player ", ply, "at radius", k ) end
      					table.insert(valid_players[k], ply)
                  end
					end
				else // valid player
					if debugged then print( "npcd > Direct > radius-valid player ", ply, "at radius", k ) end
					table.insert(valid_players[k], ply)
				end
			end

			if debugged then print( "npcd > Direct > NPCS in radius "..k..": "..#npcs_in ) end

			if r.nospawn then
				radiuses[k].skip = true
				valid_players[k] = nil
				invalid_players[k] = nil
				valid_nodes[k] = nil
				valid_navmesh_tmp[k] = nil
				valid_navmesh[k] = nil
				continue
			end
         

			// valid players
			for _, ply in ipairs( valid_players[k] ) do
				local ply_pos = pos_tbl[ply]
				// add valid navmeshes
				if HasNavMesh then
					valid_navmesh_tmp[k][ply] = {}

					local vnav
               if r.outside then
                  local c = #navmesh.Find(Entity(1):GetPos(), math.max(0,r.maxRadius-250), math.huge, math.huge)
                  vnav = navmesh.Find(Entity(1):GetPos(), math.huge, math.huge, math.huge)
                  for i=1,c do
                     table.remove(vnav,1)
                  end
               else
                  vnav = navmesh.Find(ply_pos, r.maxRadius, math.huge, math.huge)
               end

               // fill table by key (prevent duplicates)
					if !table.IsEmpty(vnav) then
						for _, nav in pairs( vnav ) do
							valid_navmesh_tmp[k][ply][nav] = true
						end
					end
				end

				// add valid nodes surrounding this valid player
				if !table.IsEmpty(cold_nodes) then
               if r.outside then
					   GetValidNodes( ply_pos, r.maxRadius, nil, cold_nodes, valid_nodes[k] )
               else
					   GetValidNodes( ply_pos, r.minRadius, r.maxRadius, cold_nodes, valid_nodes[k] )
               end
					-- local vnodes = GetValidNodes( ply_pos, r.minRadius, r.maxRadius, cold_nodes )
					-- if !table.IsEmpty(vnodes) then
						-- for nk, node in pairs( vnodes ) do
							-- valid_nodes_tmp[k][nk] = node
							-- valid_nodes[k][nk] = node
						-- end
					-- end
				end
			end
			// invalid players
			for _, ply in ipairs( invalid_players[k] ) do
				// add invalid nodes surrounding invalid players
				if !table.IsEmpty(cold_nodes) then
               if r.outside then
					   GetValidNodes( pos_tbl[ply], r.maxRadius, nil, cold_nodes, invalid_nodes )
               else
					   GetValidNodes( pos_tbl[ply], r.minRadius, r.maxRadius, cold_nodes, invalid_nodes )
               end
					-- local invnodes = GetValidNodes( pos_tbl[ply], r.minRadius, r.maxRadius, cold_nodes )
					-- if !table.IsEmpty(invnodes) then
					-- 	for nk, node in pairs( invnodes ) do
					-- 		invalid_nodes[nk] = node
					-- 	end
					-- end
				end
			end

			// add invalid nodes too close to any players
			if !table.IsEmpty(cold_nodes) then
				for _, ply in ipairs( player.GetAll() ) do
					pos_tbl[ply] = pos_tbl[ply] or ply:GetPos()
					GetValidNodes( pos_tbl[ply], 0, r.chkrad, cold_nodes, invalid_nodes )
					-- local cnodes = GetValidNodes( pos_tbl[ply], 0, r.chkrad, cold_nodes )
					-- if !table.IsEmpty(cnodes) then
					-- 	for nk, node in pairs( cnodes ) do
					-- 		invalid_nodes[nk] = node
					-- 	end
					-- end
				end
			end

			// intersect radius valid & all invalid nodes
			-- if !table.IsEmpty(valid_nodes_tmp[k]) then
			if !table.IsEmpty( valid_nodes[k] ) then
				for nk in pairs(invalid_nodes) do
					-- valid_nodes_tmp[k][nk] = nil
					valid_nodes[k][nk] = nil
				end
				-- for nk, node in pairs(valid_nodes_tmp[k]) do
				-- 	valid_nodes[nk] = node
				-- end
			end

			// valid navmeshes to sequential table
			if HasNavMesh and !table.IsEmpty(valid_navmesh_tmp[k]) then
				for ply in pairs( valid_navmesh_tmp[k] ) do
					valid_navmesh[k][ply] = {}
					for nav in pairs( valid_navmesh_tmp[k][ply] ) do
						table.insert( valid_navmesh[k][ply], nav ) // from key-key to sequential
					end
				end
			end

			// no need to check radius again if no valid players in it
			// and the direct routine doesn't (shouldn't) last long enough for that to change
			if table.IsEmpty(valid_players[k]) then
				-- table.remove(radiuses, k)
				radiuses[k].skip = true
				if debugged then print( "npcd > Direct > skipping radius " ..  k .. " (no valid players)" ) end
				continue
			end

			radded = true
		end

		if !radded then
			norads = true
			if debugged then print( "npcd > Direct > no radiuses used" ) end
			-- continue
		end

		// end conditions
		// after radius check so that despawns can be done
		endcond["Entity Quota Done"] = (entityquota and spawnedcount >= entityquota)
		endcond["Squad Quota Done"] = (squadquota and squadcount >= squadquota)
		endcond["No Valid Squads"] = table.IsEmpty( valid_squads )
		endcond["No Radiuses Left"] = norads
		endcond["Pool Entity Limit"] = ( mapLimit and mapCount >= mapLimit or false )
		endcond["Pool Squad Limit"] = ( squadLimit and totalsquads >= squadLimit or false)

		if debugged then print( "npcd > Direct > End Conditions:") end
		for k, b in pairs( endcond ) do
			if debugged then print( "\t"..k..": "..tostring(b) ) end
			if b then
				quotadone = true
				if debugged_spawner then
					reason = k
				else
					break
				end
			end
		end

		if iter >= 100 then
			quotadone = true
			reason = "Loop Limit"
			print("npcd > Direct > LOOP BREAK!")
		end

		-- if iter < 0 then
		-- 	quotadone = true
		-- 	print("npcd > Direct > debug finish")
		-- end

		// done
		if quotadone then
			direct_times[PoolFilter] = direct_times[PoolFilter] or {}
			local cur = math.Round( CurTime()-inittime, 3 )
			local last_time = #direct_times[PoolFilter] != 0 and math.Round( cur - direct_times[PoolFilter][ #direct_times[PoolFilter] ][1], 3 ) or 0
			table.insert( direct_times[PoolFilter], { cur, last_time } )

			// print results
			if debugged_spawner then
				-- if table.IsEmpty(radiuses) then print("npcd > Direct > "..PoolFilter or "nil".." NO RADIUSES LEFT") end
				-- if table.IsEmpty(valid_squads) then print("npcd > Direct > "..PoolFilter or "nil".." NO VALID SQUADS LEFT") end
				poolsquads, totalsquads = CountSquads( nil, PoolFilter )
				local _, mapsquadtot = CountSquads()
				local psum, pcount = NPCMapCount( PoolFilter )
				local asum, acount = NPCMapCount()
				print("npcd > Direct > DIRECTED IN: "..math.Round( CurTime()-dstime, 3 ).."s\t END: " .. reason .."\t TIME SINCE LAST/INIT: "..math.Round( last_time, 3 ) .. " / " .. cur .."\t POOL: "..(PoolFilter or "Default").."\t ITER:"..iter)
				print("\tSPAWNED/QUOTA/LIMIT: "..spawnedcount.." / "..(entityquota or "nil").." / "..(mapLimit or "nil").."\t SQSPAWNED/SQUOTA/SQLIMIT: "..squadcount.." / "..(squadquota or "nil").." / "..(squadLimit or "nil") .. "\t DESPAWNED: "..despawnedcount ) --.."\t ONMAP/LIMIT: ".. mapCount.."("..table.Count(activeNPC)..") / "..(mapLimit or "nil").."\t SQONMAP/SQLIMIT: ".. totalsquads .." / "..(squadLimit or "nil"))
				print("\tNODES/COOL/HOT: ".. table.Count(Nodes).. " / ".. table.Count(cold_nodes) .. " / " .. table.Count(hot_nodes) .. " | RADIUS/SPAWNSCALE: " .. math.Round( MapScale, 3 ) .. " / " .. math.Round( SpawnMapScale, 3 ) )
				print("\tPOOL/ALL: ".. psum .." / " .. asum .. " (".. pcount .. "/" .. acount ..") | SQPOOL/SQALL: ".. totalsquads .. " / ".. mapsquadtot )
				if !table.IsEmpty( radius_counts ) then
					print("\tRADIUS USE COUNTS:")
					PrintTable( radius_counts, 2 )
				end
				if poolsquads then 
					print("\tSQUAD COUNTS:")
					PrintTable(poolsquads, 2)
				end
			end

			// end loop
			break
		end

		// error check
		for k in pairs( valid_nodes ) do
			for nk, nv in pairs( valid_nodes[k] ) do
				if !cold_nodes[nk] or (cold_nodes[nk] and cold_nodes[nk]["pos"] != nv) then
					table.sort(valid_nodes[k], function(a, b) return b > a end)
					-- table.sort(valid_nodes_tmp[k], function(a, b) return b > a end)
					ErrorNoHalt(
						"\nError: npcd > Direct > VALID/COLD NODES MISMATCH:",
						"\n\tvalid_nodes[",nk,"] = ", nv,
						"\n\tcold_nodes[",nk,"] = ",cold_nodes[nk] and cold_nodes[nk]["pos"] or "nil","\n\n"
					)
					PrintTable( valid_nodes )
					-- PrintTable( valid_nodes_tmp[k] )
					table.Empty( valid_nodes )
					break
				end
			end
		end

		// pick a squad
		local picked_squad, picked_type
		if table.IsEmpty(todo_mins) then
			picked_squad, _, picked_type = RollExpected( valid_squads, nil, "name", "type" )
		else
			picked_squad, _, picked_type = RollExpected( todo_mins, nil, "name", "type" )
		end

		if debugged then print( "npcd > Direct > PICKED:", picked_squad, picked_type ) end
		
		if !picked_squad then 
			if !table.IsEmpty(todo_mins) then
				if debugged then print( "npcd > Direct > todo_mins squad pick failed, picking valid_squads instead" ) end
				picked_squad, _, picked_type = RollExpected( valid_squads, nil, "name", "type" )
			end
			if !picked_squad then
				if debugged then print( "npcd > Direct > No squad picked", PoolFilter ) end
				valid_squads = {}
				todo_mins = {}
				continue
			end
		end

		local pick_key = picked_type..picked_squad
		
		// generate squad
		local newSquad
		if picked_type == "squad" then
			newSquad = GenerateSquad( picked_squad, nil, PoolFilter )
			if !newSquad then
				valid_squads[pick_key] = nil
				todo_mins[pick_key] = nil
				continue
			end
			if istable( newSquad ) and table.IsEmpty( newSquad["spawns"] ) then
				print( "npcd > Empty squad: ", picked_squad )
				valid_squads[pick_key] = nil
				todo_mins[pick_key] = nil
				continue
			end
		else // entity spawn

		end

		// spawn it
		local spawnedadd, radiused = DirectorSpawn( {
				radiuses = radiuses,
				type = picked_type,
				name = picked_squad,
				newSquad = newSquad, // if squad
				valid_players = valid_players,
				invalid_players = invalid_players, --for anywhere/navmesh picker
				valid_nodes = valid_nodes, --for node picker
				valid_navmesh = valid_navmesh, --for navmesh picker
				pool = PoolFilter,
			}
		)

		if spawnedadd == nil then
			if debugged_spawner then
				print( "npcd > Direct > Spawn failed", picked_squad, newSquad, PoolFilter, k )
			end
			continue
		end

		if radiused then radius_counts[radiused] = ( radius_counts[radiused] or 0 ) + 1 end

		spawnedcount = spawnedcount + ( isnumber(spawnedadd) and spawnedadd or 1 )
		squadcount = squadcount + 1
		valid_squads[pick_key]["count"] = valid_squads[pick_key]["count"] + 1

		// clear invalidated squads
		if valid_squads[pick_key]["mindelay"]
		or (valid_squads[pick_key]["mapmax"] and valid_squads[pick_key]["count"] >= valid_squads[pick_key]["mapmax"]) then
			valid_squads[pick_key] = nil
			todo_mins[pick_key] = nil
		end
		// clear todo minimum squads
		if todo_mins[pick_key] and ( !valid_squads[pick_key] or valid_squads[pick_key] and valid_squads[pick_key]["count"] >= valid_squads[pick_key]["mapmin"] ) then
			todo_mins[pick_key] = nil
		end
		
		-- if cvar.debug_spawn.v:GetBool() then
		-- 	iter = -1
		-- end
	end
end

local spawn_base_offsets = { Vector(0,0,15), Vector(0,0,25), Vector(0,0,55) }
local spawn_ceil_offsets = { Vector(0,0,0), Vector(0,0,00), Vector(0,0,000) }
// pick spawnpoint from positions/players given by Direct()
function DirectorSpawn( todo )
	if debugged then
		print( "npcd > DirectorSpawn" )
		if todo then
         MsgN("\tname = ",todo.name)
         MsgN("\ttype = ",todo.type)
         MsgN("\tpool = ",todo.pool)
			-- for k, v in pairs( todo ) do
				-- print( tostring( k ) .. " = " .. tostring( v ) )
			-- end
		end
	end
	if !todo then 
		print("npcd > DirectorSpawn > no todo") 
		return nil 
	end

	local npc_t
	if todo.type != "squad" then
		npc_t = Settings[todo.type] and Settings[todo.type][todo.name] and table.Copy( Settings[todo.type][todo.name] ) or nil
		if npc_t == nil then
			print( "npcd > DirectorSpawn > NO NPC_T" )
			return nil
		end
	end


	local r_t = todo.radiuses

	local valid
	local pos
	local pos_tbl = {}

	local hotpointdist_sqr = cvar.point_radius.v:GetFloat()
	hotpointdist_sqr = hotpointdist_sqr * hotpointdist_sqr
	
	-- if table.IsEmpty( pickMethods ) then
	-- 	print("npcd > SpawnRoutine > NO SPAWN PICKING METHODS!")
	-- 	pickMethods = GetPickMethods()
	-- end
	if pickRandom then
		pickMethods = shuffle( spawnpoint_methods )
	end

	local nmesh_empty = true
	for _, tbl in pairs( todo.valid_navmesh ) do
		if !table.IsEmpty( tbl ) then
			nmesh_empty = false
			break
		end
	end
	local nodes_empty = true
	for _, tbl in pairs( todo.valid_nodes ) do
		if !table.IsEmpty( tbl ) then
			nodes_empty = false
			break
		end
	end
	-- local vply_empty = true // not possible to be false
	-- for _, tbl in pairs( todo.valid_players ) do
	-- 	if !table.IsEmpty( tbl ) then
	-- 		vply_empty = false
	-- 		break
	-- 	end
	-- end

	if debugged then 
		-- print( "valid nodes" )
		-- PrintTable( todo.valid_nodes, 1 )
		-- print( "valid player" )
		-- PrintTable( todo.valid_players, 1 )
		-- print( "valid navmesh" )
		-- PrintTable( todo.valid_navmesh, 1 )
		-- if table.IsEmpty(todo.valid_nodes) then print("npcd > DirectorSpawn > no Nodes") end
		print( "npcd > DirectorSpawn > #pickMethods: ", #pickMethods )
		if nodes_empty then print("npcd > DirectorSpawn > no Nodes") end
		if nmesh_empty then print("npcd > DirectorSpawn > no navmesh") end
		-- if vply_empty then print("npcd > DirectorSpawn > no valid players") end 
	end

	-- if table.IsEmpty(todo.valid_nodes) and nmesh_empty then --and vply_empty then
	-- 	return nil
	-- end

	// group bounds, for making sure spawn doesn't start stuck
	//[1] = mins, [2] = maxs, [3] = neg offset, [4] = all npc_t.offset
	local bounds = todo.newSquad and GetGroupOBB( todo.newSquad )
		or GetOBB( npc_t, todo.name ) or nil
	if bounds == nil then print( "npcd > DirectorSpawn > nil bounds") return nil end

	-- local ent_offs = bounds[4]

	local picked
	local radiused

	local water = todo.newSquad and todo.newSquad.values.spawn_req_water or npc_t and npc_t.spawn_req_water or 0
	if !isnumber(water) then //sigh
		water = t_npc_base_values.spawn_req_water.ENUM[water]
	end

	// iterate through allowed pick methods
	// 1. nodes
	// 2. anywhere
	// 3. navmesh
	for _, picker in pairs( pickMethods ) do
		// node picker
		if picker == "nodes" and !nodes_empty then
			if debugged then print("npcd > DirectorSpawn > picker: nodes") end

			local pos_valid
			local n

			// valid/invalid player checks are done in Direct()
			for rk in RandomPairs( todo.valid_nodes ) do
				// the merged collection of valid nodes for all players for this radius
				for k, npos in RandomPairs( todo.valid_nodes[rk] ) do
					-- CoIterate(0.5)
					// check all entity offsets
               local hitpos, hpos_fail, hpos_sky = CheckCeiling(npos)
					for o, offset in ipairs( spawn_base_offsets ) do
                  -- for b_k in pairs( todo.newSquad["spawns"] ) do
                  for b_k in pairs( bounds ) do
                     if bounds[b_k].ceiling then
                        if !hpos_fail or bounds[b_k].sky and hpos_sky then
                           pos_valid = CheckSpawnPos( hitpos, bounds[b_k], spawn_ceil_offsets[o] - bounds[b_k].maxz + bounds[b_k].offset, water )
                        else
                           pos_valid = false
                        end
                     else
                        pos_valid = CheckSpawnPos( npos, bounds[b_k], offset + bounds[b_k].offset, water )
                     end
                     if !pos_valid then break end
                  end
						-- pos_valid = CheckSpawnPos( npos, bounds[1], offset + bounds[1].offset, water )
						-- if pos_valid then
                  --    for b_k=2,#bounds do
                  --       pos_valid = CheckSpawnPos( npos, bounds[b_k], offset + bounds[b_k].offset, water )
                  --       if !pos_valid then
                  --          break
                  --       end
                  --    end
                  if pos_valid then
							pos = npos + offset
                     // check for too close to any player
							for _, aply in ipairs( player.GetAll() ) do
								if !IsValid( aply ) then continue end
								pos_tbl[aply] = pos_tbl[aply] or aply:GetPos()

								if pos:DistToSqr( pos_tbl[aply] ) < r_t[rk].chkrad_sqr then
									pos_valid = false
									break
								end
							end
							if !pos_valid then
								continue
							end
							
							// check for in radius of invalid players
							// across all radiuses
							for rrk in pairs( todo.invalid_players ) do
								for _, iply in pairs( todo.invalid_players[rrk] ) do
									CoIterate(0.1)
									if !IsValid(iply) then continue end
									pos_tbl[iply] = pos_tbl[iply] or iply:GetPos()

									local invdist = pos:DistToSqr( iply:GetPos() )
									if ( invdist > r_t[rrk].minRadius_sqr and invdist <= r_t[rrk].maxRadius_sqr ) then
										pos_valid = false
										break
									end
								end
								if !pos_valid then break end
							end
                  end
                  if pos_valid then
                     pos = npos + offset
                     n = k
                     radiused = rk
                     break
                  end
						-- end
					end
					if pos_valid then break end
				end
				if pos_valid then break end
			end

			if !pos_valid then 
				if debugged_spawner then print("npcd > DirectorSpawn > no valid nodes found") end
				continue
			else
				valid = true
				HeatNode(n)
				picked = picker
				break
			end
		// anywhere picker
		elseif picker == "anywhere" then --and !vply_empty then
			if debugged then print("npcd > DirectorSpawn > picker: anywhere") end

			local pos_valid
			-- local tall = (bounds[2].z - bounds[1].z)
			local i = 0
			for rk, rply_t in RandomPairs( todo.valid_players ) do
				// valid players for this radius
				for k, ply in RandomPairs( rply_t ) do
					if !IsValid( ply ) then continue end
					
					pos_tbl[ply] = pos_tbl[ply] or ply:GetPos()
					
					while not ( pos_valid or i > 1000 ) do
						CoIterate(5)
						if !IsValid( ply ) then break end
						i = i + 1
						pos = GetAnywhere( pos_tbl[ply], todo.minRadius, todo.maxRadius )
						pos_valid = true
						
						// getanywhere checks
						if !util.IsInWorld(pos) then
							pos_valid = false
							continue
						end
						local tr = util.TraceLine({
							start = pos,
							endpos = pos - vector_up,
							mask = MASK_NPCSOLID,
						})
						-- local trw = util.TraceLine({
						-- 	start = pos,
						-- 	endpos = pos - Vector(0, 0, 32768),
						-- 	mask = MASK_WATER,
						-- })
						-- if trw.HitPos.z > tr.HitPos.z + tall * 0.5 then
						-- 	pos_valid = false
						-- 	continue
						-- end

						-- if tr.HitNoDraw or tr.HitNonWorld or tr.HitSky or !util.IsInWorld(tr.HitPos) then
                  if !util.IsInWorld(tr.HitPos) then
                     pos_valid = false
                     continue
                  end
			
						pos = tr.HitPos

						local distpos_sqr = pos:DistToSqr( pos_tbl[ply] )
						if !pos or not ( distpos_sqr > r_t[rk].minRadius_sqr and distpos_sqr <= r_t[rk].maxRadius_sqr ) then
							pos_valid = false
							-- PrintTable( r_t[rk] )
							-- print( "distpos", distpos_sqr, r_t[rk].minRadius_sqr, r_t[rk].maxRadius_sqr )
							continue
						end

						for _, aply in ipairs( player.GetAll() ) do
							if !IsValid( aply ) then continue end
							pos_tbl[aply] = pos_tbl[aply] or aply:GetPos()

							if pos:DistToSqr( pos_tbl[aply] ) < r_t[rk].chkrad_sqr then
								pos_valid = false
								break
							end
						end
						if !pos_valid then continue end

						// check for in radius of invalid players
						// across all radiuses
						for rrk in pairs( todo.invalid_players ) do
								for _, iply in pairs( todo.invalid_players[rrk] ) do
									CoIterate(0.1)
									if !IsValid(iply) then continue end
									pos_tbl[iply] = pos_tbl[iply] or iply:GetPos()

									local invdist = pos:DistToSqr( iply:GetPos() )
									if ( invdist > r_t[rrk].minRadius_sqr and invdist <= r_t[rrk].maxRadius_sqr ) then
										pos_valid = false
										break
									end
								end
							if !pos_valid then break end
						end
						if !pos_valid then continue end

						// used points
						for k, hp in pairs( hot_points ) do
							if hp.pos:DistToSqr( pos ) < hotpointdist_sqr then
								pos_valid = false
								break
							end
						end
						if !pos_valid then continue end
                  
						// check all entity offsets
                  local hitpos, hpos_fail, hpos_sky = CheckCeiling(pos)
						for o, offset in ipairs( spawn_base_offsets ) do
							-- for b_k in pairs( todo.newSquad["spawns"] ) do
                     for b_k in pairs( bounds ) do
                        if bounds[b_k].ceiling then
                           if !hpos_fail or bounds[b_k].sky and hpos_sky then
                              pos_valid = CheckSpawnPos( hitpos, bounds[b_k], spawn_ceil_offsets[o] - bounds[b_k].maxz + bounds[b_k].offset, water )
                           else
                              pos_valid = false
                           end
                        else
                           pos_valid = CheckSpawnPos( pos, bounds[b_k], offset + bounds[b_k].offset, water )
                        end
                        if !pos_valid then break end
                     end
                     if pos_valid then
                        pos = pos + offset
                        break
                     end
						end
					end

					if pos_valid then
						radiused = rk
						break
					end // end player iterator
				end
				if pos_valid then break end // end radius iterator
			end

			if !pos_valid then 
				if debugged_spawner then print("npcd > DirectorSpawn > no valid anywhere found") end
				continue
			else
				valid = true
				picked = picker
				HeatPoint(pos)
				break
			end
		// navmesh picker
		elseif picker == "navmesh" and !nmesh_empty then
			if debugged then print("npcd > DirectorSpawn > picker: navmesh") end

			local pos_valid = false

			for rk in RandomPairs( todo.valid_navmesh ) do
				// valid players for this radius
				for ply, plynav_t in RandomPairs( todo.valid_navmesh[rk] ) do
					if !IsValid( ply ) then continue end
					pos_tbl[ply] = pos_tbl[ply] or ply:GetPos()

					// the available navmeshes for the player
					for _, nav in RandomPairs( plynav_t ) do
						local i = 0
						// repeat until valid pos chosen
						while not (pos_valid or i > 25) do
							CoIterate(0.1)
							i = i + 1
							pos = nav:GetRandomPoint()
							pos_valid = true
							local distpos_sqr = pos:DistToSqr( pos_tbl[ply] )

							// check distance from player
							if !pos or not (distpos_sqr > r_t[rk].minRadius_sqr and distpos_sqr <= r_t[rk].maxRadius_sqr ) then
								pos_valid = false
								continue
							end

							// check for too close to any player
							for _, aply in ipairs( player.GetAll() ) do
								if !IsValid( aply ) then continue end
								pos_tbl[aply] = pos_tbl[aply] or aply:GetPos()

								if pos:DistToSqr( pos_tbl[aply] ) < r_t[rk].chkrad_sqr then
									pos_valid = false
									break
								end
							end
							if !pos_valid then
								continue
							end
							
							// check for in radius of invalid players
							// across all radiuses
							for rrk in pairs( todo.invalid_players ) do
								for _, iply in pairs( todo.invalid_players[rrk] ) do
									CoIterate(0.1)
									if !IsValid(iply) then continue end
									pos_tbl[iply] = pos_tbl[iply] or iply:GetPos()

									local invdist = pos:DistToSqr( iply:GetPos() )
									if ( invdist > r_t[rrk].minRadius_sqr and invdist <= r_t[rrk].maxRadius_sqr ) then
										pos_valid = false
										break
									end
								end
								if !pos_valid then break end
							end
							if !pos_valid then continue end

							// used points
							for k, hp in pairs( hot_points ) do
								if hp.pos:DistToSqr( pos ) < hotpointdist_sqr then
									pos_valid = false
									break
								end
							end
							if !pos_valid then continue end

							// check all entity offsets
							local hitpos, hpos_fail, hpos_sky = CheckCeiling(pos)
							for o, offset in ipairs( spawn_base_offsets ) do
								-- for b_k in pairs( todo.newSquad["spawns"] ) do
								for b_k in pairs( bounds ) do
                           if bounds[b_k].ceiling then
                              if !hpos_fail or bounds[b_k].sky and hpos_sky then
                                 pos_valid = CheckSpawnPos( hitpos, bounds[b_k], spawn_ceil_offsets[o] - bounds[b_k].maxz + bounds[b_k].offset, water )
                              else
                                 pos_valid = false
                              end
                           else
                              pos_valid = CheckSpawnPos( pos, bounds[b_k], offset + bounds[b_k].offset, water )
                           end
                           if !pos_valid then break end
                        end
                        if pos_valid then
                           pos = pos + offset
                           break
                        end
							end
						end

						if pos_valid then
							radiused = rk
							break
						end // end navs iterator
					end
					if pos_valid then break end // end player iterator
				end
				if pos_valid then break end	// end radius iterator
			end

			if !pos_valid then 
				if debugged_spawner then print("npcd > DirectorSpawn > no valid navmesh point found") end
				continue
			else 
				valid = true
				picked = picker
				HeatPoint(pos)
				break 
			end
		end
	end

	if !valid or !pos then
		if debugged_spawner then print("npcd > DirectorSpawn > spawnqueue failed: no valid found") end
		return nil
	end

	-- pos = pos + Vector( 0, 0, 10 ) // see: GetGroupOBB()

	if debugged_spawner and debugged_more then
		print( "npcd > DirectorSpawn > Radius: ".. tostring(radiused) .. ", Picker used: " .. picked )
	end

	// spawn it
	if todo.type == "squad" then
		if debugged then 
			print("npcd > DirectorSpawn > SpawnSquad(", todo.newSquad, pos,")")
		end
		todo.newSquad["bounds"] = bounds
		-- return SpawnSquad( todo.newSquad, pos + bounds[3] ), radiused
		return SpawnSquad( todo.newSquad, pos ), radiused
	else
		if debugged then 
			print("npcd > DirectorSpawn > SpawnNPC(", todo.name, npc_t, pos + bounds[1].zoff, todo.pool," true )")
		end
		return SpawnNPC({
            presetName =   todo.name,
            anpc_t =       npc_t,
            pos =          pos + bounds[1].zoff,
            pool =         todo.pool,
            maxz =         bounds[1].maxz,
         }),
         radiused
	end
end

function NPCMapCount( poolFilter )
	local sum = 0
	local c = 0
	for _, tbl in pairs(activeNPC) do
		CoIterate(0.05)
		if poolFilter then 
			if poolFilter == tbl["pool"] then
				-- if unweighted then
					-- sum = sum + 1
				-- else
					c = c + 1
					sum = sum + tbl["weight"]
				-- end
			end
		else
			c = c + 1
			sum = sum + tbl["weight"]
		end
	end
	return sum, c
end

function CountSquads( sq, pool )
	// sq: either a preset name or a table of preset names
	local u_counts = {}
	local t_counts = {}
	local q_counts = {}
	local total = 0

	for npc, ntbl in pairs(activeNPC) do
		if !IsValid( npc ) then continue end
		if pool then

			if ntbl["pool"] == pool then
				local s = npc:GetKeyValues()["squadname"]
				if s ~= "" and s ~= nil then
					u_counts[s] = ntbl["squadpreset"]
				else 
					u_counts[npc] = ntbl["squadpreset"]
				end
			end

		else

			if ntbl["squadpreset"] then
				local s = npc:GetKeyValues()["squadname"]
				if s ~= "" and s ~= nil then
					u_counts[s] = ntbl["squadpreset"]
				else 
					u_counts[npc] = ntbl["squadpreset"]
				end
			end
			
		end
	end

	for _, s in pairs( u_counts ) do
		t_counts[s] = t_counts[s] or 0
		t_counts[s] = t_counts[s] + 1
		if !sq then
			total = total + 1
		end
	end

	if pool then // pool count
		return t_counts, total
	elseif sq then
		if istable(sq) then // table of squads, i.e. squadpool squads
			for q in pairs(sq) do
				if t_counts[q] then
					q_counts[q] = t_counts[q] 
					total = total + t_counts[q] 
				end
			end
			return q_counts, total
		else // single squad
			return t_counts[sq] or 0
		end
	else
		// table of all counts
		return t_counts, total
	end
end

// spawn position stuff

function GetPickMethods()
	local posfuncs = {}
	local preferred = {}
	local random

	// break apart cvar value
	for s in string.gmatch(cvar.preferred_pick.v:GetString(), "[^%s,]+") do
		if s == "random" then
			random = true
			preferred = shuffle( spawnpoint_methods )
			break
		else	
			table.insert(preferred, string.lower(s) )
		end
	end
	// build list
	for i, s in pairs( preferred ) do
		-- if spawnpoint_methods[s] then
			table.insert( posfuncs, s )
		-- end
	end

	if debugged then
		print( "npcd > GetPickMethods:" )
		PrintTable( posfuncs )
	end

	return posfuncs, random
end

function GetAnywhere( start_pos, minRadius, maxRadius )
	local start_pos = start_pos or game.GetWorld():GetPos()
	local minRadius = minRadius or 0
	local maxRadius = maxRadius or 32768 --map size max is 32768

	local chk = 0
	chk = chk + 1
	// rotates vector instead of just a vector of random numbers, making potential area circular instead of rectangular
	local pos = Vector( math.Rand(minRadius, maxRadius), 0, math.Rand(minRadius, maxRadius) * ( -1 * math.random(0,1) ) )
	pos:Rotate(	RandomAngle() ) 
	pos = pos + start_pos

	return pos
end

// returns pos, fail_check, sky
function CheckCeiling(pos)
   local tr = util.TraceLine({
      start = pos,
      endpos = pos + vector_up,
      mask = MASK_NPCSOLID,
   })
   -- if !force and (tr.HitNoDraw or tr.HitNonWorld or !sky and tr.HitSky or !util.IsInWorld(tr.HitPos)) then
   --    return nil
   -- else
	return tr.HitPos, (tr.HitNoDraw or tr.HitNonWorld or tr.HitSky or !util.IsInWorld(tr.HitPos)), tr.HitSky
   -- end
end

local vectors_pickany = { Vector(), Vector(0,0,10), Vector(0,0,30) }

function PickAnywhere( vectors, bounds )
	-- local vec_chk = vectors or { Vector(), Vector(0,0,10), Vector(0,0,30) }
	while not (pos_valid or i > 1000) do
		i = i + 1
		local pos = GetAnywhere()
		if !pos then continue end
		for _, offset in ipairs( vectors_pickany ) do
			pos_valid = CheckSpawnPos( pos, bounds, offset )
			if pos_valid then return pos + offset end
		end
	end
	if i > 1000 then print("npcd > PickAnywhere > Limit break (1000)") end
	return nil
end

local f_water_reqs = {
	[-1] = function() return true end, // any
	[0] = function( wl ) return wl < 2 end, // disallow water
	[1] = function( wl ) return wl > 2 end, // water only
}
-- local f_water_reqs = {
-- 	[-1] = function() return true end, // any
-- 	[0] = function( wl ) return not wl end, // disallow water
-- 	[1] = function( wl ) return wl end, // water only
-- }

function CheckSpawnPos( p, bounds, offset, water )
	local offset = offset or Vector()
	if !p then print("npcd > CheckSpawnPos nil") return nil end

	local pos = p + offset

	if water != nil then
        -- if !f_water_reqs[water](
        --     bit.band( util.PointContents( pos ), CONTENTS_WATER ) == CONTENTS_WATER
        -- ) then
        --     return false
        -- end
		testpoint = IsValid( testpoint ) and testpoint or ents.Create( "info_null" )
		testpoint:SetPos( pos )
		if !f_water_reqs[water]( testpoint:WaterLevel() ) then
			return false
		end
	end

	// check if in skybox
	local skycam = ents.FindByClass("sky_camera")
	if skycam[1] then			
		local skytr = util.TraceLine(
			{
				start = pos, --p,
				endpos = skycam[1]:GetPos(), --dest,
				mask = MASK_SOLID_BRUSHONLY,
			}
		)

		CoIterate(3)

		if skytr.Hit then 
			//check from ceiling
			local highlook = util.TraceLine(
				{
					start = pos, --p,
					endpos = Vector(0,0,32768), --dest,
					mask = MASK_SOLID_BRUSHONLY,
				}
			)

			CoIterate(3)
			
			skytr = util.TraceLine(
				{
					start = highlook.HitPos, --p,
					endpos = skycam[1]:GetPos(), --dest,
					mask = MASK_SOLID_BRUSHONLY,
				}
			)

			CoIterate(3)
			if !skytr.HitWorld then return false end //if there is world between sky_camera and the pos
		else
			return false //skycam
		end
	end

	// return whether bound is in world
	if bounds then
		local htr = util.TraceHull(
			{
				start = pos,
				endpos = pos,
				mins = bounds.mino,
				maxs = bounds.maxo,
				mask = MASK_NPCSOLID_BRUSHONLY,
			}
		)

		CoIterate(3)

		return !htr.Hit
	else
		return util.IsInWorld(pos)
	end

	return true
end

function PickNode( pos, minRadius, maxRadius, nodesTbl )
	local nodesTbl = nodesTbl or Nodes
	if table.IsEmpty( nodesTbl ) then return nil end
	local ntbl = GetValidNodes( pos, minRadius, maxRadius, nodesTbl )
	return !table.IsEmpty( ntbl ) and table.Random( ntbl ) or nil
end

function GetValidNodes( pos, minRadius, maxRadius, nodesTbl, existing )
	local pos = pos or game.GetWorld():GetPos()

	local minRadius_sqr = minRadius and minRadius * minRadius or 0
	local maxRadius_sqr = maxRadius and maxRadius * maxRadius or math.huge

	local nodesTbl = nodesTbl or cold_nodes
	local valid_nodes = existing or {}
	for k, n in pairs(nodesTbl) do
		if valid_nodes[k] then continue end
		CoIterate(0.25)
		local valid = false

		local nodpos
		if isvector(n) then
			nodpos = n
		elseif istable(n) then
			nodpos = n["pos"]
		else
			print("ncpd > GetValidNodes > node invalid type?", k .. " = " .. tostring(n) )
			continue 
		end

		// distance check
		local dist = nodpos:DistToSqr(pos)
		if dist <= minRadius_sqr then
			valid = false
			continue
		elseif dist < maxRadius_sqr then
			valid = true
		end

		if valid then
			valid_nodes[k] = nodpos
		end
	end

	return valid_nodes 
end

// send recently used node out of available pool
function HeatNode(k)
	hot_nodes[k] = {
		["node"] = cold_nodes[k],
		["time"] = CurTime(),
	}
	cold_nodes[k] = nil
	if debugged then print("npcd > HeatNode > cold: "..tostring(table.Count(cold_nodes))..", hot: "..tostring(table.Count(hot_nodes)) ) end
end

function HeatPoint(pos)
	table.insert( hot_points, { 
		["pos"] = pos,
		["time"] = CurTime(),
	} )
end

// send used nodes back to available nodes
function CoolNodes()
	local cooled
	for k, n in pairs(hot_nodes) do
		CoIterate(0.1)
		if n["time"] + cvar.cooldown.v:GetFloat() < CurTime() then
			cold_nodes[k] = n["node"]
			hot_nodes[k] = nil
			cooled = ( cooled or 0 ) + 1
		end
	end
	if debugged and cooled then
		print( "npcd > CoolNodes > " .. cooled .. " cooled. cold: "..tostring(table.Count(cold_nodes))..", hot: "..tostring(table.Count(hot_nodes)) )
	end
end

function CoolPoints()
	local cooled = {}
	for k, n in ipairs( hot_points ) do
		CoIterate(0.1)
		if n["time"] + cvar.point_cooldown.v:GetFloat() < CurTime() then
			table.insert( cooled, k )
		end
	end
	for _, k in ipairs( table.Reverse( cooled ) ) do
		table.remove( hot_points, k )
	end
	if debugged and #cooled > 0 then
		print( "npcd > CoolPoints > " .. #cooled .. " cooled. hot: ".. #hot_points )
	end
end