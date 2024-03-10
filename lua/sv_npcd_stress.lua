// stress stuff

module( "npcd", package.seeall )

local prsr_rise_start = CurTime()
local prsr_start = CurTime()
local stress_start = CurTime()
local prsr_down = false
local prsr_peaked = false

// because i don't feel like checking the cvar every single time
function UpdateStressCVars()
	for cn, cv in pairs( cvar ) do
		if cv.c == "Stress" or cv.c == "Pressure" then
			v_stress[cn] = cv.v:GetFloat()
		end
	end

	stress_activemult = cvar.stress_enabled.v:GetBool() and v_stress.stress_globalmult * ( prsr_peaked and v_stress.stress_peakmult or 1 ) or 0
end

local friend_dispo = {
	[D_LI] = true,
	[D_NU] = true,
}

function ResetStress( full )
	if full then
		for _, ply in ipairs( player.GetAll() ) do
			ply.npcd_stress = 0
		end
	end
	stress = 0
	pressure = 0
	prsr_rise_start = CurTime()
	prsr_start = CurTime()
	stress_start = CurTime()
	prsr_down = false
	prsr_peaked = false
	net.Start("npcd_stress_update")
		net.WriteFloat(stress)
		net.WriteFloat(pressure)
	net.Broadcast()
end

// default is once a second
function StressOut()
	local maxstress = 0
	local minstress = 1
	local totalstress = 0
	local plyc = 0

	local enabled = cvar.stress_enabled.v:GetBool()

	stress_activemult = enabled and v_stress.stress_globalmult * ( prsr_peaked and v_stress.stress_peakmult or 1 ) or 0

	if !enabled then
		if cvar.spawn_enabled.v:GetBool() then
			thinkTimeRange = GetThinkRange()
			nextThink = lastThink + Lerp(1 - pressure, thinkTimeRange[1], thinkTimeRange[2])
		end
		-- for _, ply in ipairs( player.GetAll() ) do
		-- 	ply.npcd_stress = 0
		-- end
		ResetStress()
		-- stress = 0
		-- pressure = 0
		-- net.Start("npcd_stress_update")
		-- 	net.WriteFloat(stress)
		-- 	net.WriteFloat(pressure)
		-- net.Broadcast()
		return
	end

	// stress from enemy distance
	for _, ply in ipairs( player.GetAll() ) do
		if !IsValid(ply) then continue end
		plyc = plyc + 1

		-- ply.npcd_stress = ply.npcd_stress or 0
		ply.npcd_stress = math.Clamp( ply.npcd_stress - v_stress.stress_decay, 0, 1 )

		local ply_pos = ply:GetPos()

		// enemy npc count
		for npc, ntbl in pairs( activeNPC ) do
			CoIterate(3)
			if !IsValid(npc) then continue end
			local dispo = npc:IsNPC() and npc:Disposition( ply ) or nil
			if dispo and friend_dispo[dispo] then continue end
			local stress_mult = ntbl["npc_t"]["stress_mult"] and ntbl["npc_t"]["stress_mult"] * stress_activemult or stress_activemult
			local npc_pos = npc:GetPos()
			local dist = npc_pos:Distance(ply_pos)
			local add = v_stress.stress_plynpc_distf / math.max(1, dist * v_stress.stress_plynpc_distdivf ) * stress_mult 
			ply.npcd_stress = math.Clamp( ply.npcd_stress + add, 0, 1 )
		end

		maxstress = math.max( maxstress, ply.npcd_stress)
		minstress = math.min( minstress, ply.npcd_stress)
		totalstress = totalstress + ply.npcd_stress
	end

	// lerp average or pure average
	local avg = totalstress / plyc
	if tobool( v_stress.stress_lerpmethod ) then
		stress = Lerp( v_stress.stress_lerpf, avg, maxstress )
	else
		stress = avg
	end

	// pressure

	// depressurize
	if prsr_down then
		if pressure > 0 then
			prsr_accel = Lerp( math.max( stress, v_stress.stress_breakpoint ), v_stress.prsr_accel_min, v_stress.prsr_accel_max ) * v_stress.prsr_cooldownf
			pressure = math.Clamp( pressure - prsr_accel, 0, 1 )
		else
			if debugged_spawner then
				print("npcd > StressOut > PRESSURE DROPPED in",CurTime() - prsr_start)
				PrintDirects() 
			end
			direct_times = {}
			
			prsr_down = false
			prsr_rise_start = CurTime()

			// reset stress
			for _, ply in ipairs( player.GetAll() ) do
				ply.npcd_stress = 0
			end

			stress_start = CurTime()
		end

	// pressurize
	else
		if stress >= v_stress.stress_breakpoint then
			if debugged_spawner then
				print("npcd > StressOut > STRESSED in ", CurTime() - stress_start)
			end
			prsr_down = true
			prsr_start = CurTime()
		else
			// max at zero stress, min at full stress
			prsr_accel = Lerp( 1 - stress, v_stress.prsr_accel_min, v_stress.prsr_accel_max ) * ( pressure > 0.5 and v_stress.prsr_topf or v_stress.prsr_bottomf )
			pressure = math.Clamp( pressure + prsr_accel, 0, 1)
		end
	end

	// peak check
	if pressure >= 1 and !prsr_peaked then
		if debugged_spawner then
			print("npcd > StressOut > PRESSURE PEAKED in ",CurTime() - prsr_rise_start)
			PrintDirects()
		end
		direct_times = {}
		prsr_peaked = true
	elseif pressure < 1 then
		prsr_peaked = false
	end

	net.Start("npcd_stress_update")
		net.WriteFloat(stress)
		net.WriteFloat(pressure)
	net.Broadcast()

	// update next direct think
	if cvar.think_update.v:GetBool() then
		thinkTimeRange = GetThinkRange()
		nextThink = lastThink + Lerp(1 - pressure, thinkTimeRange[1], thinkTimeRange[2])
	end
end