// chasing stuff
// todo: figure out how schedules work

module( "npcd", package.seeall )

function GetNPCSchedule( npc )
	if(!IsValid(npc)) then return end
	for s = 0, LAST_SHARED_SCHEDULE-1 do
		if(npc:IsCurrentSchedule(s)) then return s end
	end
	return 0
end

function GetScheduleName( sched )
	return sched and table.KeyFromValue( t_enums["schedule"], sched ) or nil
end

local chaseDist = {
	min = 0,
	max = 12500,
}
chaseDist.min_sqr = chaseDist.min * chaseDist.min
chaseDist.max_sqr = chaseDist.max * chaseDist.max

function UpdateChaseCVars()
	chaseDist = {
		-- close = 500,
		min = cvar.chase_mindist.v:GetFloat(), --1500,
		max = cvar.chase_maxdist.v:GetFloat(), --7500,
	}
	-- chaseDist.close_sqr = chaseDist.close * chaseDist.close,
	chaseDist.min_sqr = chaseDist.min * chaseDist.min
	chaseDist.max_sqr = chaseDist.max * chaseDist.max
end

function CheckChaseStatus( ply, exclude )
	if !ply or !IsValid(ply) or !ply:IsPlayer() then return end
	local status = false
	for npc, ntbl in pairs(activeNPC) do
		if npc == exclude then continue end
		if ntbl["chasing"] and ntbl["chasing"] == ply then
			status = true
			break
		end
	end
	net.Start("npcd_chased")
		net.WriteBool(status)
	net.Send(ply)
end

function SetScheduleDiligent( npc, sched, ntbl, force )
	if !IsValid( npc ) or !sched then return nil end
	-- if nt["scheduling"] then return end

	local cursched = GetNPCSchedule( npc )
	if debugged_chase then print( npc, "current sched: ", GetScheduleName( cursched ) ) end
	if cursched and action_scheds[cursched] then
		return nil
	end

	local k, v = next(sched)

	if v == SCHED_NONE then return v end

	// try schedule, if it fails too many times then move onto the next one
	if v and ( cursched != v or force ) then
	--and nt and ( nt["chasing"] or nt["seekout"] )

		npc:SetSchedule( v )

		if debugged_chase then npc:SetColor( Color( 0, 255, 0 ) ) end

		-- nt["scheduling"] = true

		local sch = sched
		local n = npc
		local nt = ntbl
		timer.Simple( 0.51, function() // schedule seems to only fail after some time
			if IsValid( n ) and nt
			-- and !n:IsCurrentSchedule( v ) then
			and nt["sched"] and !n:IsCurrentSchedule( nt["sched"] ) and ( n:IsCurrentSchedule( SCHED_FAIL ) or n:IsCurrentSchedule( SCHED_NONE )
			or v == SCHED_CHASE_ENEMY and n:IsCurrentSchedule( SCHED_CHASE_ENEMY_FAILED ) ) then
				nt["sched_fails"] = ( nt["sched_fails"] or 0 ) + 1
				if debugged_chase then
					print( "SCHED FAILED:", n, GetScheduleName(nt["sched"]), GetScheduleName( GetNPCSchedule( n ) ) )
					npc:SetColor( Color( 255, 0, 0 ) )
				end
				-- ClearScheduleDiligent( n, nt ) // ???
				ntbl["sched"] = nil
				if nt["sched_fails"] >= cvar.sched_maxfails.v:GetInt() then // if too many fails, remove schedule
					nt["sched_fails"] = 0

					if debugged_chase then npc:SetColor( Color( 255, 0, 255 ) ) end
					
					-- sch[k] = nil
					// push to end
					table.insert( sch, v )
					table.remove( sch, k )
				end
				-- nt["scheduling"] = nil
				-- SetScheduleDiligent( n, sch, nt )
			-- elseif nt then
				-- nt["scheduling"] = nil
			end
		end )

		nt["sched"] = v
		if debugged_chase then print( "NEW SCHED:", npc, GetScheduleName(v) ) end
	-- elseif nt then
	-- 	nt["scheduling"] = nil
	end

	return v
end

function ClearScheduleDiligent( npc, ntbl )
	if debugged_chase then
		print( "SCHED CLEARED:", npc, GetScheduleName( ntbl["sched"] ), GetScheduleName( GetNPCSchedule( npc ) ) )
		npc:SetColor( ntbl["npc_t"]["rendercolor"] or color_white )
	end
	npc:ClearSchedule()
	ntbl["chasing"] = nil
	ntbl["sched"] = nil
	ntbl["sched_startpos"] = nil
	ntbl["seekout"] = nil
end

action_scheds = {
	[SCHED_RELOAD] = true,
	-- [SCHED_HIDE_AND_RELOAD] = true,
	[SCHED_MELEE_ATTACK1] = true,
	[SCHED_MELEE_ATTACK2] = true,
	-- [SCHED_RANGE_ATTACK1] = true,
	-- [SCHED_RANGE_ATTACK2] = true,
	-- [SCHED_SPECIAL_ATTACK1] = true,
	-- [SCHED_SPECIAL_ATTACK2] = true,
}

force_scheds = {
	[SCHED_FORCED_GO] = true,
	[SCHED_FORCED_GO_RUN] = true,
}

friend_disp = {
	[D_LI] = true,
	[D_NU] = true,
}

function ManageSchedules()
	local valid_chase = {}
	local alive_ply = {}
	for _, ply in ipairs(player.GetAll()) do
		if ply:Alive() then table.insert(alive_ply, ply) end
	end
	if table.IsEmpty(alive_ply) then
		alive_ply = player.GetAll()
	end
	
	local alleveryone = cvar.npc_allrelate.v:GetBool()
	local ignoreplayers = GetConVar("ai_ignoreplayers"):GetBool()
	local mindist_friend = cvar.seekout_mindist_friend.v:GetFloat()
	mindist_friend = mindist_friend * mindist_friend
	local seekout_minrad = cvar.seekout_rad_min.v:GetFloat()
	local seekout_maxrad = cvar.seekout_rad_max.v:GetFloat()
	local seekout_timeout = cvar.seekout_timeout.v:GetFloat()
	local seekout_timeout_fail = cvar.seekout_timeout_fail.v:GetInt()

	local pos_tbl = {}
	local characters = {}
	// character list for seekout check
	for _, ent in ipairs( ents.GetAll() ) do
		if not ( activeNPC[ent] or ent:IsNPC() or ent:IsNextBot() ) or ent:IsPlayer() then continue end
		CoIterate(1)
		if !IsValid(npc) then break end
		if !IsValid(ent) then continue end
		table.insert( characters, ent )
	end

	// manage all npc schedules
	for npc, ntbl in pairs( activeNPC ) do
		CoIterate(2)
		if !IsValid(npc) or !npc:IsNPC() then continue end
		pos_tbl[npc] = pos_tbl[npc] or npc:GetPos()

		-- local idling
		local force_seekout
		local closest
		local idleout_time = ntbl.npc_t.idleout or cvar.idleout.v:GetFloat()
		-- local cursched = GetNPCSchedule( npc )
		local sched_seekout = ntbl["npc_t"]["seekout_schedule"] or { SCHED_FORCED_GO, SCHED_TARGET_CHASE, SCHED_CHASE_ENEMY }
		local sched_chase = ntbl["npc_t"]["chase_schedule"] or { SCHED_TARGET_CHASE, SCHED_CHASE_ENEMY, SCHED_FORCED_GO_RUN }
		local hasenemy = IsValid( npc:GetEnemy() )
		local hastarget = IsValid( npc:GetTarget() )

		if debugged_chase then print( math.Round( CurTime(), 3 ), npc, "enemy", npc:GetEnemy(), "target", npc:GetTarget(), "schedfail",ntbl["sched_fails"], "seekout", ntbl["seekout"], "chasing", ntbl["chasing"], "sched", GetScheduleName( ntbl["sched"] ), "realsched", GetScheduleName( GetNPCSchedule( npc ) ) ) end

		// mark for searching if idle for too long
		if !ntbl.npc_t.noidle and idleout_time >= 0 and ( !hasenemy and !hastarget ) then
			if debugged_chase then npc:SetColor( Color( 0, 0, 255 ) ) end
			if !ntbl["lastidle"] then
				ntbl["lastidle"] = CurTime()
			end

			// set for seekout
			if CurTime() - ntbl["lastidle"] >= idleout_time then
				force_seekout = true
				if debugged_chase then npc:SetColor( Color( 255, 255, 0 ) ) end
			end
		else
			-- if debugged_chase then print( npc, "not idle" ) end
			if ntbl["npc_t"]["seekout_clear"] and !ntbl["chasing"] and ntbl["seekout"]
			and ( hasenemy or hastarget ) then
				if ( ntbl["sched"] and npc:IsCurrentSchedule( ntbl["sched"] ) ) then
					ClearScheduleDiligent( npc, ntbl )
				end
				ntbl["seekout"] = nil
			end
			
			if debugged_chase then npc:SetColor( ntbl["npc_t"]["rendercolor"] or color_white ) end

			ntbl["lastidle"] = nil
		end

		// force seekout
		if ntbl["npc_t"]["force_approach"] then
			force_seekout = true
			if debugged_chase then npc:SetColor( Color( 0, 255, 255 ) ) end
		end

		local npc_pos = pos_tbl[npc]

		local chase_reset

		local fsched
		for f in pairs( force_scheds ) do
			if npc:IsCurrentSchedule( f ) then
				fsched = true
				break
			end
		end

		if fsched then --force_scheds[cursched] then
			// anti idiot measures
			if ntbl["npc_t"]["seekout_clear"] and ntbl["chasing"] == nil then
				for _, ent in ipairs( ents.FindInSphere( npc_pos, 300 ) ) do
					if !IsValid( ent ) then continue end
					if ignoreplayers and ent:IsPlayer() then continue end

					if npc:Disposition( ent ) == D_HT then
						ClearScheduleDiligent( npc, ntbl )
						-- cursched = GetNPCSchedule( npc )
						break
					end
				end
			end
			// make sure debug schedules keeps with current enemy position
			local cn = IsValid( ntbl["chasing"] ) and ntbl["chasing"]
			local sn = IsValid( ntbl["seekout"] ) and ntbl["seekout"]
			local n = cn or sn
			if n then
				pos_tbl[n] = pos_tbl[n] or n:GetPos()
                if ntbl["sched_startpos"] then
                    local newpos_change = pos_tbl[n]:DistToSqr( ntbl["sched_startpos"] ) * cvar.seekout_newposratio.v:GetFloat()
                    if newpos_change > math.max( pos_tbl[n]:DistToSqr( pos_tbl[npc] ), 90000 ) then // 300, 250000 500
                        if debugged_chase then print( "SEEKOUT NEW POS", npc, n, GetScheduleName( GetNPCSchedule(npc) ) ) end
                        -- ClearScheduleDiligent( npc, ntbl )
                        chase_reset = true
                        ntbl["sched_startpos"] = nil
                        ntbl["seekout"] = nil // force new schedule to new pos
                        -- cursched = GetNPCSchedule( npc )
                        if !cn then force_seekout = true end
                    end
                end
			end
		end
		
		// don't need to do anything if already seeking out normally
		if IsValid( ntbl["seekout"] ) then
			if !ntbl["npc_t"]["force_approach"]
			and ( !ntbl["lastidle"] or CurTime() - ntbl["lastidle"] < seekout_timeout ) then
				if ( ntbl["sched"] and !npc:IsCurrentSchedule( ntbl["sched"] ) ) then
					if debugged_chase then npc:SetColor( Color( 255, 0, 0 ) ) end

					ntbl["sched_seekout_fails"] = ( ntbl["sched_seekout_fails"] or 0 ) + 1
					if debugged_chase then print( "seekout sched mismatch", npc, GetScheduleName(ntbl["sched"]), GetScheduleName(cursched), ntbl["sched_seekout_fails"], seekout_timeout_fail  ) end
					if ntbl["sched_seekout_fails"] >= seekout_timeout_fail then
						ntbl["seekout"] = nil
						ntbl["sched_seekout_fails"] = 0
						ntbl["sched_fails"] = ( ntbl["sched_fails"] or 0 ) + 1
					else
						continue
					end
				else
					continue
				end
			end
		else
			ntbl["seekout"] = nil
		end

		// chasing: already chasing
		if ntbl["chasing"] ~= nil then			
			local c_ply = ntbl["chasing"]

			// check if still valid
			if IsValid( c_ply )
			and ( !ignoreplayers and c_ply:IsPlayer() and c_ply:Alive()
			or !c_ply:IsPlayer() and c_ply:NotDead()
			or !IsCharacter(c_ply) ) then
				pos_tbl[c_ply] = pos_tbl[c_ply] or c_ply:GetPos()
				local dist = npc_pos:DistToSqr( pos_tbl[c_ply] )
				if dist > chaseDist.min_sqr then
					npc:SetLastPosition( pos_tbl[c_ply] )
					if !ntbl["sched_startpos"] then chase_reset = true end
					ntbl["sched_startpos"] = ntbl["sched_startpos"] or pos_tbl[c_ply]
					if ntbl["npc_t"]["chase_setenemy"] and npc:GetEnemy() != c_ply then npc:SetEnemy(c_ply) end
					if ntbl["npc_t"]["chase_settarget"] and npc:GetTarget() != c_ply then npc:SetTarget(c_ply) end
					SetScheduleDiligent( npc, sched_chase, ntbl, chase_reset )
				end
				continue
			// else end chase
			else 
				if debugged_chase then print ( "npcd > end chase", npc, c_ply ) end
				ClearScheduleDiligent( npc, ntbl )
				-- cursched = GetNPCSchedule( npc )
				ntbl["chasing"] = nil
				if c_ply:IsPlayer() then CheckChaseStatus( c_ply ) end
			end
		end

		// find players and npcs
		if ntbl["npc_t"]["chase_preset"] or ntbl["npc_t"]["chase_players"] or force_seekout then

			// looking for players
			if !ignoreplayers then
				for _, ply in pairs(alive_ply) do
					CoIterate(1)
					if !IsValid(npc) or !IsValid(ply) then continue end
					if !ply:Alive() and #player.GetAll() > 1 then continue end

					pos_tbl[ply] = pos_tbl[ply] or ply:GetPos()
					local ply_pos = pos_tbl[ply]
					local dist = npc_pos:DistToSqr(ply_pos)
 
					// normal seeking out
					if force_seekout and ( !friend_disp[npc:Disposition(ply)] or dist > mindist_friend ) then
						closest = closest or {}
						-- if #closest < 3 then
							-- table.insert(closest, 1, { ply, dist } )
							table.insert(closest, { ply, dist } )
						-- else
						-- 	for i, c in ipairs(closest) do
						-- 		if dist < c[2] then
						-- 			table.insert(closest, i, { ply, dist } )
						-- 			table.remove(closest, 4)
						-- 			break
						-- 		end
						-- 	end
						-- end
					end

					// chasing: looking for new chase
					if ( ntbl["npc_t"]["chase_players"] or ntbl["npc_t"]["chase_preset"] ) and ntbl["chasing"] == nil
					and dist <= chaseDist.max_sqr then
						if ntbl["npc_t"]["chase_players"] == true then
							valid_chase[npc] = valid_chase[npc] or {}
							table.insert( valid_chase[npc], ply )
						elseif ntbl["npc_t"]["chase_preset"] != nil then
							for _, pr in pairs( ntbl["npc_t"]["chase_preset"] ) do
								if pr["type"] == "player" and activePly[ply] and pr["name"] == activePly[ply]["npcpreset"] then
									valid_chase[npc] = valid_chase[npc] or {}
									table.insert( valid_chase[npc], ply )
									break
								end
							end
						end
					end
				end

				if !IsValid(npc) then continue end
			end

			// looking for other npcs
			if ntbl["npc_t"]["chase_preset"] or force_seekout then
				closest = closest or {}
				-- for ent, enttbl in pairs( activeNPC ) do
				for _, ent in ipairs( characters ) do
					if ent == npc then continue end
					CoIterate(1)
					if !IsValid(npc) then break end
					if !IsValid(ent) then continue end

					local enttbl = activeNPC[ent] or nil
					
					pos_tbl[ent] = pos_tbl[ent] or ent:GetPos()

					local dist = npc_pos:DistToSqr( pos_tbl[ent] )
					local disp = npc:Disposition( ent )
					local chaseadded

					if enttbl and ntbl["npc_t"]["chase_preset"] != nil and dist <= chaseDist.max_sqr then
						for _, pr in pairs( ntbl["npc_t"]["chase_preset"] ) do
							if pr["type"] == enttbl["npc_t"]["entity_type"] and pr["name"] == enttbl["npcpreset"] then
								valid_chase[npc] = valid_chase[npc] or {}
								table.insert( valid_chase[npc], ent )
								chaseadded = true
								break
							end
						end						
					end

					if ntbl["npc_t"]["chase_anything"] and !chaseadded then
						valid_chase[npc] = valid_chase[npc] or {}
						table.insert( valid_chase[npc], ent )
					end

					if ( enttbl and enttbl["npc_t"]["allow_chased"] != false and ( enttbl["squad"] == nil or ntbl["squad"] == nil or enttbl["squad"] ~= ntbl["squad"] )
					or !enttbl and ent:GetKeyValues()["squadname"] != npc:GetKeyValues()["squadname"] )
					and ( !friend_disp[disp] or dist > mindist_friend ) then
						-- if #closest < 3 then
							-- table.insert(closest, 1, { ent, dist } )
							table.insert(closest, { ent, dist } )
						-- else
						-- 	for i, c in ipairs(closest) do
						-- 		if dist < c[2] then
						-- 			table.insert(closest, i, { ent, dist } )
						-- 			table.remove(closest, 4)
						-- 			break
						-- 		end
						-- 	end
						-- end
					end
				end
			end

			if !IsValid(npc) then continue end
			
			// chasing: initiate chase
			if valid_chase[npc] then
				local c_ply = valid_chase[npc][math.random(1,#valid_chase[npc])]
				if IsValid( c_ply ) then
					activeNPC[npc]["chasing"] = c_ply
					npc:SetLastPosition( pos_tbl[c_ply] )
					ntbl["sched_startpos"] = pos_tbl[c_ply]
					if ntbl["npc_t"]["chase_setenemy"] and npc:GetEnemy() != c_ply then npc:SetEnemy(c_ply) end
					if ntbl["npc_t"]["chase_settarget"] and npc:GetTarget() != c_ply then npc:SetTarget(c_ply) end
					// set schedule
					SetScheduleDiligent( npc, sched_chase, ntbl )

					if debugged_chase then print( "NEW CHASE:", npc, "chasing", c_ply, "dist", npc:GetPos():Distance( c_ply:GetPos() ) ) end

					// inform player
					if c_ply:IsPlayer() then
						net.Start("npcd_chased")
							net.WriteBool(true)
						net.Send(c_ply)
					end
				end
			// seekout: go to whoever is closest
			elseif closest and !table.IsEmpty(closest) then
				table.SortByMember( closest, 2, true )
				CoIterate(5)
				local winner
				if ntbl["npc_t"]["force_approach"] then
					winner = closest[1]
				else
					winner = closest[math.random( 1, math.min( #closest, 3 ) )]
				end
				local winner_ent = winner[1]
				-- local winner_dist = winner[2]
				-- PrintTable( closest )
				if IsValid( winner_ent ) and IsValid( npc ) then
					local tpos
					if ntbl["npc_t"]["seekout_setenemy"] and npc:GetEnemy() != winner_ent then npc:SetEnemy(winner_ent) end
					if ntbl["npc_t"]["seekout_settarget"] and npc:GetTarget() != winner_ent then npc:SetTarget(winner_ent) end

					local new = winner_ent != ntbl["seekout"]

					if ntbl["npc_t"]["force_approach"] then
						npc:SetLastPosition( pos_tbl[winner_ent] )
						if new or !ntbl["sched_startpos"] then
							ntbl["sched_startpos"] = pos_tbl[winner_ent]
						end
					else
						tpos = PickNode( pos_tbl[winner_ent], seekout_minrad, seekout_maxrad, Nodes ) or pos_tbl[winner_ent]						
						if IsValid( npc ) then
							npc:SetLastPosition( tpos )
							ntbl["sched_startpos"] = new and pos_tbl[winner_ent] or ntbl["sched_startpos"] or pos_tbl[winner_ent]
						else
							continue
						end
					end

					if SetScheduleDiligent( npc, sched_seekout, ntbl, new ) then
						ntbl["seekout"] = winner_ent
						ntbl["lastidle"] = nil
						if debugged_chase then
							print( npc, "seekoutwinner", winner_ent, npc:GetPos(), winner_ent:GetPos(), tpos )
							-- print( npc, "enemies", npc:GetEnemy(), npc:GetTarget() )
						end
					end					
				end
			-- elseif debugged_chase and npc:GetColor() == Color( 255, 255, 0 ) then
			-- 	npc:SetColor( Color( 0, 0, 255 ) )
			end
		-- else
			-- print( npc, "no seekout", ntbl["npc_t"]["force_approach"] , ntbl["npc_t"]["chase_players"] , force_seekout )
		end

		if !IsValid( npc ) then continue end

		if debugged_chase and force_seekout and ntbl["seekout"] == nil then
			npc:SetColor( Color( 0, 0, 255 ) )
		end

		// otherwise, wander
		if npc:IsCurrentSchedule( SCHED_NONE ) and !ntbl["seekout"] and !ntbl["chasing"] and !hasenemy and !hastarget then
			npc:SetSchedule( SCHED_IDLE_WANDER )
			// alt schedule
			if npc:IsCurrentSchedule( SCHED_NONE ) then
				npc:SetSchedule( SCHED_PATROL_RUN )
			end
		end

		-- local s = GetNPCSchedule( npc )
		-- print( npc, s, table.KeyFromValue( t_npc_base_values["chase_schedule"].ENUM , s ) )
	end
end