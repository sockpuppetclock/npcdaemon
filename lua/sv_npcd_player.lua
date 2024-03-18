// player preset stuff

module( "npcd", package.seeall )

// todo: make sure everything is actually fixed
function FixPlayer( ply )
	if cvar.debug_noplyfix.v:GetBool() then return end
	if !IsValid( ply ) then return end
	for i=1,ply:GetBoneCount() do
		ply:ManipulateBoneJiggle( i, 0 )
		ply:ManipulateBoneScale( i, Vector( 1, 1, 1 ) )
	end
	if ply.npcd_revertvalues then --and ply_preset_hist[ply] then
		ApplyValueTable( ply.npcd_revertvalues, t_lookup["player"], ply, true, true )
	end
	-- PrintTable( ply:GetCallbacks("PhysicsCollide") )
	if activeCallback[ply] then
		for name, id in pairs( activeCallback[ply] ) do
			ply:RemoveCallback( name, id )
		end
	end
	ply.npcd_lastvelocity = nil
end

// player condition check functions
// valid if true
ply_tbl_cfunc = {
	["killed_by_preset"] = function( ply, val, typ, prsname )
		return ( ply_preset_deaths[ply]
		and ply_preset_deaths[ply][currentProfile]
		and ply_preset_deaths[ply][currentProfile][typ]
		and ply_preset_deaths[ply][currentProfile][typ][prsname] == true or false ) == val
	end,
	["teams"] = function( ply, val ) return ply:Team() == val end,
	["usergroups"] = function( ply, val ) return ply:IsUserGroup( val ) end,
}

ply_cfunc = {
	["admin"] = function( ply, val ) return ( ply:IsAdmin() and !ply:IsSuperAdmin() ) == val end,
	["nonadmin"] = function( ply, val ) return ( !ply:IsAdmin() and !ply:IsSuperAdmin() ) == val end,
	["superadmin"] = function( ply, val ) return ply:IsSuperAdmin() == val end,
	["hasgodmode"] = function( ply, val ) return ply:HasGodMode() == val end,
	["isbot"] = function( ply, val ) return ply:IsBot() == val end,
	["listenhost"] = function( ply, val ) return ply:IsListenServerHost() == val end,
	["deaths_greaterthan"] = function( ply, val ) return ply:Deaths() > val end,
	["deaths_lessthan"] = function( ply, val ) return ply:Deaths() < val end,
	["kills_greaterthan"] = function( ply, val ) return ply:Frags() > val end,
	["kills_lessthan"] = function( ply, val ) return ply:Frags() < val end,
	["nepotism"] = function( ply, val ) return ( ply:GetFriendStatus() == "friend" ) == val end,
	["teams"] = function( ply, val )
		for _, v in pairs( val ) do
			if ply_tbl_cfunc["teams"]( ply, v ) then
				return true
			end
		end
		return false
	end,
	["usergroups"] = function( ply, val )
		for _, v in pairs( val ) do
			if ply_tbl_cfunc["usergroups"]( ply, v ) then
				return true
			end
		end
		return false
	end,
	["killed_by_presets"] = function( ply, val )
		ApplyValueTable( val, t_lookup["player"]["condition"].STRUCT["killed_by_presets"].STRUCT )

		local valid = true
		if val["include"] then
			valid = false
			for _, v in pairs( val["include"] ) do
				if ply_tbl_cfunc["killed_by_preset"]( ply, true, v["type"], v["name"] ) then
					valid = true
					break
				end
			end
		end
		if valid and val["exclude"] then
			for _, v in pairs( val["exclude"] ) do
				if ply_tbl_cfunc["killed_by_preset"]( ply, true, v["type"], v["name"] ) then
					valid = false
					break
				end
			end
		end
		return valid
	end,
	["preset_max"] = function( ply, val, prsname )
		local count = 0
		for _, tbl in pairs( activePly ) do
			if tbl["npcpreset"] == prsname then
				count = count + 1
			end
		end
		return count < val
	end,
	["infected"] = function( ply, val )
		for _, v in pairs( val ) do
			if ply_tbl_cfunc["killed_by_preset"]( ply, true, v["type"], v["name"] ) then
				return true
			end
		end
		return false
	end,
}

// player death "infected cure" conditions
ply_cure_cfunc = {
	[1] = function() return true end, // any
	[2] = function( ply, killer ) // any character
			return IsValid( killer ) and killer != ply
			and IsCharacter( killer )
		end,
	[3] = function( ply, killer ) // any non-infected
		if !IsValid( killer ) then return false end
		local ntbl = activeNPC[killer] or activePly[killer] or nil
		if !ntbl then return true end
		
		// if player is killed by infected
		if activePly[ply]["npc_t"]["condition_forced"]["infected"] then
			for _, v in pairs( activePly[ply]["npc_t"]["condition_forced"]["infected"] ) do
				if ntbl["npcpreset"] == v["name"] and ntbl["npc_t"]["entity_type"] == v["type"] then
					return false
				end
			end
		end

		return true
	end,
	[4] = function( ply, killer ) // non-infected player
		if !IsValid( killer ) or !killer:IsPlayer() then return false end
		local ntbl = activePly[killer]
		if !ntbl then return true end

		if activePly[ply]["npc_t"]["condition_forced"]["infected"] then
			for _, v in pairs( activePly[ply]["npc_t"]["condition_forced"]["infected"] ) do
				if ntbl["npcpreset"] == v["name"] and ntbl["npc_t"]["entity_type"] == v["type"] then
					return false
				end
			end
		end

		return true
	end,
	[5] = function( ply, killer ) // infected
		if !IsValid( killer ) then return false end
		local ntbl = activeNPC[killer] or activePly[killer] or nil
		if !ntbl then return false end
		
		if activePly[ply]["npc_t"]["condition_forced"]["infected"] then
			for _, v in pairs( activePly[ply]["npc_t"]["condition_forced"]["infected"] ) do
				if ntbl["npcpreset"] == v["name"] and ntbl["npc_t"]["entity_type"] == v["type"] then
					return true
				end
			end
		end

		return false
	end,
}

// get original player values
function GetRevertValues( ply, printout )
	if !IsValid( ply ) then return end
	ply.npcd_revertvalues = {}
	for vn, vt in pairs( t_lookup["player"] ) do
		if vt.REVERT == false then continue end

		// use pregiven revert value or get-function
		if vt.REVERTVALUE != nil then
			ply.npcd_revertvalues[vn] = vt.REVERTVALUE
		elseif vt.FUNCTION_GET then
			ply.npcd_revertvalues[vn] = DoEntFunc( ply, vt.FUNCTION_GET )
		end
	end
	if debugged or printout then
		print( "npcd > GetRevertValues > Player Revert Values: " .. tostring( ply ) )
		PrintTable( ply.npcd_revertvalues, 1 )
	end
end

hook.Add("PlayerInitialSpawn", "NPCD Player Setup", function( ply )
	ply.npcd_stress = 0

	// get original values for reverting whenever preset is changed/removed
	timer.Simple( engine.TickInterval(), function() GetRevertValues( ply ) end )
end)

function InitSpawns()
	if !readied then
		if cvar.initspawns.v:GetFloat() > 0 then
			print( "npcd > Ready > Init spawns: " .. cvar.initspawns.v:GetFloat() )
			for i=1,cvar.initspawns.v:GetFloat() do
				timer.Simple(init_spawndelay + 0.5 * i, function()
					if cvar.spawn_enabled.v:GetBool() then
						table.insert(directQueue, {})
					end
				end )
			end
		end
		readied = true
	end
end

function CheckPlayerPrsCondition( ply, prsname, acond_t )
	// normal conditions
	if !istable( acond_t ) then return true end
	local cond_t = table.Copy( acond_t )
	local valid = true
	for _, cond in pairs( cond_t ) do // table of condition tables
		ApplyValueTable( cond, t_lookup["player"]["condition"].STRUCT )

		valid = true // valid if any of the condition tables matches

		if valid then
			for k, val in pairs( cond ) do
            if k == nil or ply_cfunc[k] == nil then continue end;
				local chk = ply_cfunc[k]( ply, val, prsname )
				if !chk then
					valid = false
					break
				end
			end
		end

		if valid == true then break end
	end

	return valid
end

hook.Add("PlayerSpawn", "NPCD Player Spawn", function( ply, transition )
	if !IsValid( ply ) then return end
   damageTakenTotals[ply] = 0
   damageTakenTable[ply] = {}
	if !cvar.enabled.v:GetBool() then
		net.Start( "npcd_ply_preset" )
			net.WriteString( "" )
		net.Send( ply )
		return
	end

	InitSpawns()

	if transition then
		print( ply, "in transition", transition )
		return
	end // haven't checked if this is needed yet

	activePly[ply] = nil

	FixPlayer( ply )

	local presetted

	if cvar.plyoverride.v:GetBool() and Settings["player"] and !table.IsEmpty( Settings["player"] ) then
		if debugged then print( "npcd > PlayerSpawn > player presets check" ) end
		local ply_p = {}
		for prsname, prstbl in RandomPairs( Settings["player"] ) do
			-- if debugged then print( prsname, prstbl ) end
			if prstbl["npcd_enabled"] == false then
				continue
			end
			
			// forced conditions
			if prstbl["condition_forced"] then
				local cond = table.Copy( prstbl["condition_forced"] )
				ApplyValueTable( cond, t_lookup["player"]["condition_forced"].STRUCT )
				if cond["infected"] and ply_cfunc["infected"]( ply, cond["infected"] )
				or cond["infected_previous"] == true and ply_preset_hist[ply] and ply_preset_hist[ply][ply_preset] then
					// if forced, replaced all choices with this one and break
					ply_p = {
						[prsname] = prstbl
					}
					break
				end
			end

			// normal conditions
			if !CheckPlayerPrsCondition( ply, prsname, prstbl["condition"] ) then
				if debugged then print( prsname, "failed" ) end
				continue
			end

			if debugged then print( prsname, "passed" ) end

			// else if valid
			ply_p[prsname] = prstbl
		end

		// apply preset
		if !table.IsEmpty( ply_p ) then
			local ply_preset = RollExpected( ply_p )

			if ply_preset then
				if debugged then print("npcd > PlayerSpawn > preset applied: ", ply, ply_preset) end

				// player history and intial/non-intial delay
				ply_preset_hist[ply] = ply_preset_hist[ply] or {}
				local delay
				if table.IsEmpty( ply_preset_hist[ply] ) then
					delay = engine.TickInterval() * ( cvar.ply_prs_delay_first.v:GetInt() )
				else
					delay = engine.TickInterval() * ( cvar.ply_prs_delay.v:GetInt() )
				end

				presetted = true
				timer.Simple( delay, function()
					if SpawnNPC({
                  presetName =   ply_preset,
                  anpc_t =       Settings["player"][ply_preset],
                  npcOverride =  ply,
                  doFadeIns =    false,
               }) then
						// add to history
						ply_preset_hist[ply][ply_preset] = true
					else // failed
						net.Start( "npcd_ply_preset" )
							net.WriteString( "" )
						net.Send( ply )
					end
				end)
			end
		end
	end

	if !presetted then
		net.Start( "npcd_ply_preset" )
			net.WriteString( "" )
		net.Send( ply )
	end
end)

hook.Add("PlayerDeath", "NPCD Player Death", function( ply, wep, killer )

	// add death to player death history
	local ktbl = activePly[killer] or activeNPC[killer] or nil
	if ktbl and ktbl["npcpreset"] then
		local prsname = ktbl["npcpreset"]
		local typ = ktbl["npc_t"]["entity_type"]
		ply_preset_deaths[ply] = ply_preset_deaths[ply] or {}
		ply_preset_deaths[ply][currentProfile] = ply_preset_deaths[ply][currentProfile] or {}
		ply_preset_deaths[ply][currentProfile][typ] = ply_preset_deaths[ply][currentProfile][typ] or {}
		ply_preset_deaths[ply][currentProfile][typ][prsname] = true
	end

	if activePly[ply] then
		NPCKilled( ply, killer )
		
		// infection cure
		if activePly[ply]["npc_t"]["condition_forced"] and activePly[ply]["npc_t"]["condition_forced"]["infected_cure"]
		and ply_cure_cfunc[ activePly[ply]["npc_t"]["condition_forced"]["infected_cure"] ]( ply, killer ) then
			// clear history
			ply_preset_hist[ply][ activePly[ply]["npcpreset"] ] = nil

			// clear relevant deaths
			if activePly[ply]["npc_t"]["condition_forced"]["infected"] != nil then
				for _, v in pairs( activePly[ply]["npc_t"]["condition_forced"]["infected"] ) do
					if ply_preset_deaths[ply] and ply_preset_deaths[ply][currentProfile] and ply_preset_deaths[ply][currentProfile][v.type] then
						ply_preset_deaths[ply][currentProfile][v.type][v.name] = nil
					end
				end
			end
		end

		activePly[ply] = nil
	end

	// stress
	if killer != ply then
		ply.npcd_stress = math.Clamp(ply.npcd_stress + v_stress.stress_ply_death * stress_activemult, 0, 1)
	end
end)