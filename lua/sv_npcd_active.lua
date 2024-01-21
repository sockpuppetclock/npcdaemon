// active effects stuff

module( "npcd", package.seeall )

local IN_MOVE = bit.bor( IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT )
local IN_MOVE_SPEED = bit.bor( IN_SPEED, IN_MOVE )

// apply unique npcd properties, every think
function DoActiveEffects()
	local tmp = {}
	for _, tbl in ipairs( { activePly, activeNPC } ) do
		for npc, ntbl in pairs( tbl ) do
			if !IsValid(npc) then continue end
			local npc_t = ntbl["npc_t"]

			// animation
			if npc_t.animspeed then npc:SetPlaybackRate(npc_t.animspeed) end
			if npc_t.force_sequence and CurTime() > ntbl.nextseq then
				SetTmpEntValues( tmp, npc, npc_t, "force_sequence", GetLookup( "force_sequence", npc_t.entity_type, nil, GetPresetName( npc_t.classname ) ) )
				if npc:GetSequence() != tmp.force_sequence then
					npc:SetSequence( tmp.force_sequence )
				end
				tmp.force_sequence = nil

				if npc_t.sequencedelay then
					SetTmpEntValues( tmp, npc, npc_t, "sequencedelay", GetLookup( "sequencedelay", npc_t.entity_type, nil, GetPresetName( npc_t.classname ) ) )
					ntbl.nextseq = CurTime() + ( tmp.sequencedelay or 0 )
					tmp.sequencedelay = nil
				end		

			end

			if npc:IsNPC() and npc_t.activity and CurTime() > ntbl.nextact then
				SetTmpEntValues( tmp, npc, npc_t, "activity", GetLookup( "activity", npc_t.entity_type, nil, GetPresetName( npc_t.classname ) ) )
				if npc:GetActivity() ~= tmp.activity then
					npc:SetActivity( tmp.activity )
				end
				tmp.activity = nil

				if npc_t.actdelay then
					SetTmpEntValues( tmp, npc, npc_t, "actdelay", GetLookup( "actdelay", npc_t.entity_type, nil, GetPresetName( npc_t.classname ) ) )
					ntbl.nextact = CurTime() + ( tmp.actdelay or 0 )
					tmp.actdelay = nil
				end				
			end

			if npc_t.accelerate and !npc:IsPlayer() then
				if npc_t.accelerate.enabled and IsValid( npc:GetPhysicsObject() ) then
					local phys = npc:GetPhysicsObject()

					if phys:GetVelocity():LengthSqr() < ( npc_t.accelerate.accel_threshold * npc_t.accelerate.accel_threshold ) then
						local dp = isfunction( npc.GetAimVector ) and npc:GetAimVector():GetNormalized():Dot(phys:GetVelocity():GetNormalized()) // lol
							or npc:EyeAngles():Forward():Dot(phys:GetVelocity():GetNormalized())
						local ler = (dp / 2) + 0.5
						ler = math.pow( 1 - ler, 1.2 )
						ler = Lerp( ler , npc:GetAimVector() * npc_t.accelerate.accel_rate, Vector() )
						phys:AddVelocity( ler )
					end
				end
			end

			if npc_t.moveact and npc:GetMovementActivity() ~= npc_t.moveact then
				npc:SetMovementActivity( npc_t.moveact )
			end

			// regen
			if npc_t.regen and CurTime() > ntbl.nextregen then
				-- if (npc_t.regen > 0 and npc:Health() < npc:GetMaxHealth()) or npc_t.regen < 0 then
				-- 	local newh, frac = math.modf( npc:Health() + ntbl.regenfraction + npc_t.regen )
				-- 	ntbl.regenfraction = frac
				-- 	npc:SetHealth( math.min( newh, npc:GetMaxHealth() ) )
				-- 	npc:TakeDamage( 0 , npc, npc )
				-- end

				local newh, frac = math.modf( npc:Health() + npc_t.regen )
				ntbl.healthfrac = ntbl.healthfrac + frac
				npc:SetHealth( math.min( newh, npc:GetMaxHealth() ) )	

				if npc:Health() <= 0 then npc:TakeDamage( 0 ) end

				if npc_t.regendelay then
					SetTmpEntValues( tmp, npc, npc_t, "regendelay", GetLookup( "regendelay", npc_t.entity_type, nil, GetPresetName( npc_t.classname ) ) )
				end
				ntbl.nextregen = CurTime() + ( tmp.regendelay or 1 )
				tmp.regendelay = nil
			end

			// apply health fraction because fractional damage doesn't seem to really work right
			if math.abs( ntbl.healthfrac ) >= 1 then
				local newh, frac = math.modf( npc:Health() + ntbl.healthfrac )
				ntbl.healthfrac = frac
				npc:SetHealth( math.min( newh, npc:GetMaxHealth() ) )

				if npc:Health() <= 0 then npc:TakeDamage( 0 ) end // updates health and can trigger death
			end

			// scale to health
			if ( npc_t.scale_proportion or npc_t.scale_bone_proportion ) and ntbl["lasthealth"] != npc:Health() then
				local pp = npc:Health() / npc:GetMaxHealth()
				if npc_t.scale_proportion then
					npc:SetModelScale( Lerp( pp, npc_t.scale_proportion, npc_t.scale or 1 ), 0.1 )
				end
				
				if npc_t.scale_bone_proportion then
					local bs = Lerp( pp, npc_t.scale_bone_proportion, npc_t.bone_scale or 1 ) 
					for i=1,npc:GetBoneCount() do
						npc:ManipulateBoneScale(i, Vector( bs, bs, bs ) )
					end
				end
				ntbl["lasthealth"] = npc:Health()
			end

			// hivequeen too far check
			if ntbl["squad"] and ntbl["squad_t"] and ntbl["squad_t"]["values"]["hivequeen"] and ntbl["squad_t"]["values"]["hivequeen_maxdist"]
			and not ( ntbl["npcpreset"] == ntbl["squad_t"]["values"]["hivequeen"]["name"] and ntbl["npc_t"]["entity_type"] == ntbl["squad_t"]["values"]["hivequeen"]["type"] )
			then
				local toofar = false
				for _, qnpc in pairs(ntbl["squad"]) do
					if !IsValid( qnpc ) then continue end
					// check distance from queen(s)
					local hqmax = ntbl["squad_t"]["values"]["hivequeen_maxdist"]

					if activeNPC[qnpc]
					and activeNPC[qnpc]["npcpreset"] == ntbl["squad_t"]["values"]["hivequeen"]["name"]
					and activeNPC[qnpc]["npc_t"]["entity_type"] == ntbl["squad_t"]["values"]["hivequeen"]["type"] then
						toofar = true
						local dist = npc:GetPos():DistToSqr(qnpc:GetPos())
						if dist <= ( hqmax * hqmax ) then
							toofar = false
							break
						end
					end
				end
				if toofar then // cut link
					npc:SetHealth( -1 )
					npc:TakeDamage( npc:GetMaxHealth() )
				end
			end

		end
	end

	// effects
	for npc, ntbl in pairs(activeEffect) do
		if IsValid(npc) then
			for _, eff_t in pairs(activeEffect[npc]) do
				if eff_t["next"] and eff_t["next"] >= CurTime() then
					continue
				end
				CreateEffect(eff_t, npc, nil, true)
			end
		else
			activeEffect[npc] = nil
		end
	end
end

// code modified from Zenkaku's Sliding Ability addon
function CalcMovement( ply, accel_t, mv )
	local v = ply.npcd_velocity_last or mv:GetVelocity()
	local vel = v:Length()
	local speed = math.max( vel, ply:GetWalkSpeed() )
	local vdir = v:GetNormalized()
	local forward = mv:GetMoveAngles():Forward()
	local aimv = forward
	local movev = Vector()
	if mv:KeyDown( IN_MOVE ) then
		movev = Vector(mv:GetForwardSpeed(), mv:GetSideSpeed(), 0):GetNormalized()
		aimv:Rotate(movev:Angle() * -1)
	end

	local speedref = accel_t.accel_threshold

	local accel_cvar = accel_t.accel_rate
	local accel = accel_cvar * engine.TickInterval()

	// acceleration
	if speed < speedref then
		accel = ( accel ) * ( 1 + speed / speedref )
	else
		accel = 0
	end
	
	local vang = vdir:Angle()
	vang:Normalize()
	local forang = Angle()
	local aimthres = 45
	local aimgrad = 135

	// select movekeys or aim angle or current vector for forward angle lerping
	if mv:KeyDown( IN_MOVE ) then
        forang = aimv:Angle()
	elseif aimthres > 0 or aimgrad > 0 then
		forang = ply:GetAimVector():Angle()
	else
		forang = vang
	end
	forang:Normalize()
	
	local angdiff = forang - vang
	-- print( angdiff.y )
	if math.Round( math.abs(angdiff.y) ) == 180 then
		angdiff.y = 90
	end
	angdiff:Normalize()

	// angle lerping
	if math.abs(angdiff.y) > aimthres then
		-- if aimgrad > 0 then
			angdiff = LerpAngle( (math.abs(angdiff.y) - aimthres) / aimgrad , angdiff, Angle() )
		-- else
			-- angdiff = Angle()
		-- end
	end

	-- print( angdiff.y,  math.abs(angdiff.y) - aimthres, 1 - math.abs(angdiff.y) )
	local maxlerp = 1 - accel_t.player_lerp
	if accel_t.player_lerp_relative then maxlerp = maxlerp * math.max( 1, speedref / speed ) end

	local vecLerpFactor = math.Clamp(maxlerp * ( math.abs(angdiff.y) / 180 ), 0, maxlerp)
	local angLerpFactor = math.Clamp(maxlerp * ( 1 - math.abs(angdiff.y) / 180 ), 0, maxlerp)

	if vel < ply:GetWalkSpeed() then
		vecLerpFactor = 1
		angLerpFactor = 0
	end

	// set vector
	v = LerpVector( vecLerpFactor, vdir, forward ) * ( speed + accel )
	v:Rotate(Angle(0, LerpAngle(angLerpFactor, Angle(0,0,0), angdiff).y , 0))

	return v
end

hook.Add( "SetupMove", "NPCD Movement", function( ply, mv, cmd ) 
	if IsValid( ply ) then

		// track recent velocity, for damage filter check
		local velticks = cvar.ply_vel.v:GetInt()
		if velticks > 0 then
			ply.npcd_velocity_tbl = ply.npcd_velocity_tbl or {}
			table.insert( ply.npcd_velocity_tbl, ply:GetVelocity() )
			if #ply.npcd_velocity_tbl > velticks then
				for i=velticks+1,#ply.npcd_velocity_tbl do
					table.remove( ply.npcd_velocity_tbl, 1 )
				end
			end
			
			-- ply.npcd_velocity_avg = Vector()
			ply.npcd_velocity_recentmax_sqr = 0
			-- ply.npcd_velocity_recentmin_sqr = math.huge

			for _, vel in ipairs( ply.npcd_velocity_tbl ) do
				-- ply.npcd_velocity_avg = ply.npcd_velocity_avg + vel
				ply.npcd_velocity_recentmax_sqr = math.max( ply.npcd_velocity_recentmax_sqr, vel:LengthSqr() )
				-- ply.npcd_velocity_recentmax_sqr = math.min( vel:LengthSqr(), ply.npcd_velocity_recentmin_sqr )
			end
			-- ply.npcd_velocity_avg = ply.npcd_velocity_avg / #ply.npcd_velocity_tbl
			-- print( #ply.npcd_velocity_tbl, ply.npcd_velocity_recentmax_sqr )
		else
			-- ply.npcd_velocity_avg = nil
			ply.npcd_velocity_recentmax_sqr = nil
			-- ply.npcd_velocity_recentmin_sqr = nil
		end

		// preset effects
		if activePly[ply] then
			local npc_t = activePly[ply]["npc_t"]
			// phys object acceleration
			if npc_t.accelerate then
				if npc_t.accelerate.enabled then

					if ply.npcd_accelerate_end then
						ply.npcd_accelerate_end = nil
						if npc_t.accelerate.jump then
							local v = ply.npcd_velocity_last
							v.z = mv:GetVelocity().z
							mv:SetVelocity( v )
						end						
					end

					if !ply:KeyPressed( IN_JUMP ) and !ply:KeyDown( IN_DUCK ) and ply:OnGround() and ( ply:IsSprinting() or ply:KeyDown( npc_t.accelerate.movekeys and IN_MOVE_SPEED or IN_SPEED ) ) then
						mv:SetVelocity( CalcMovement( ply, npc_t.accelerate, mv ) )
						ply.npcd_accelerating = true
					elseif ply.npcd_accelerating then
						ply.npcd_accelerating = nil
						ply.npcd_accelerate_end = true
					end
					ply.npcd_velocity_last = mv:GetVelocity()
				end
			end
		end
	end
end )

// for newly spawned entities, runs every think
function FadeIns()
	local fadeInScalar = cvar.fadein.v:GetFloat()
	local fadeInFlat = cvar.fadein_flat.v:GetFloat()

	for npc, ftbl in pairs(activeFade) do
		local npcmax = ftbl.npcmax // the npc's set alpha
		local wepmax = ftbl.wepmax // the weapon's set alpha
		local starttime = ftbl.starttime
		local ready = ftbl.ready -- SpawnSquad()
		local nodelay = ftbl.nodelay

		if activeNPC[npc] and IsValid( npc ) then
			local ntbl = activeNPC[npc]
			local npcdone = false
			local allwepdone = false
			local numwepdone = 0
			local wep
			if isfunction( npc.GetWeapons ) then wep = npc:GetWeapons() end
			
			// fix for game crashing when npc dies on sky
			if !ntbl["spawned"] then
				if ntbl["squad_t"]["values"]["spawnfix"] or ntbl["npc_t"]["spawnfix"] then
					npc:SetAbsVelocity( Vector(0,0,0) )
					npc:SetPos( ntbl["startpos"] or npc:GetPos() )
				end

				// check if under sky/nodraw
				// try to do only every x frames
				ntbl["spawnfix_checkstate"] = ntbl["spawnfix_checkstate"] or 0

				if ntbl["spawnfix_checkstate"] <= 0 then
					local tr = util.TraceLine({
						start = npc:GetPos(),
						endpos = npc:GetPos() - Vector(0, 0, 32768),
						mask = MASK_NPCSOLID,
					})
					
					if tr.HitSky or tr.HitNoDraw then
						if debugged then print("npcd > FadeIns > NPC UNDER NODRAW, REMOVED ",npc) end
						npc:Remove()
						continue
					end
					ntbl["spawnfix_checkstate"] = 10 // counts down from this
				else
					ntbl["spawnfix_checkstate"] = ntbl["spawnfix_checkstate"] - 1
				end
			end
			
			local npcCurAlpha = npc:GetColor()["a"]

			// wait condition: if not settled within 1 second, then if squad is ready fade in anyways
			// else force fade in after 2 seconds

			// if true, continue waiting
			if !nodelay and !ntbl["spawned"]
			// npc
			and (
				( npc:IsNPC() and ( ( !npc:OnGround() or ( isfunction( npc.HasCapability ) and npc:HasCapability( CAP_MOVE_FLY ) ) ) or npc:GetVelocity():LengthSqr() > 100 ) )
				// nextbot/entity
				or ( !npc:IsNPC() and ( !npc:OnGround() or npc:GetVelocity():LengthSqr() > 100 ) ) 
			)
			// timeout
			and CurTime() - starttime < 1
			then
				if npcCurAlpha <= 0 then
					npc:SetNoDraw( true )
					if npc:IsNPC() or isfunction( npc.GetWeapons ) then
						for _, w in ipairs( npc:GetWeapons() ) do
							w:SetNoDraw( true )
						end
					end
				else
					npc:SetNoDraw( false )
					if npc:IsNPC() or isfunction( npc.GetWeapons ) then
						for _, w in ipairs( npc:GetWeapons() ) do
							w:SetNoDraw( false )
						end
					end
				end
				npc:SetKeyValue("renderamt", ntbl["npc_t"]["startalpha"])
				continue
			end

			// skip waiting for squad to be ready
			if CurTime() - starttime > 2 then
				ready = true
			end 

			if !ready then continue end

			// spawned
			if !ntbl["spawned"] then
				ntbl["spawned"] = true
				npc:SetNoDraw(false)

				if wep then
					for _, w in ipairs( npc:GetWeapons() ) do
						w:SetNoDraw( false )
					end
				end

				// spawn effects
				if ntbl["npc_t"]["spawneffect"] then
					for _, sf in pairs(ntbl["npc_t"]["spawneffect"]) do
						CreateEffect(sf, npc, nil)
					end
				end
			end
			
			// fade in
			// bug: headcrab (and maybe others?) seem to be gaining alpha even when not ready
			if npcCurAlpha < npcmax then
				npcCurAlpha = math.Clamp(npcCurAlpha * fadeInScalar + fadeInFlat, 0, npcmax) --1.4
				npc:SetKeyValue("renderamt", npcCurAlpha)
			else
				npcdone = true
			end

			// wepon
			if wep then
				for _, w in ipairs( wep ) do
					local wepCurAlpha = w:GetColor()["a"]
					if wepCurAlpha < wepmax then
						wepCurAlpha = math.Clamp(wepCurAlpha * fadeInScalar + fadeInFlat, 0, wepmax) --1.4
						w:SetKeyValue("renderamt", wepCurAlpha)
					else
						numwepdone = numwepdone + 1
					end
				end
				if numwepdone >= #wep then
					allwepdone = true
				end
			else
				allwepdone = true
			end

			// done
			if npcdone and allwepdone then
				activeFade[npc] = nil
			end
		else //no longer activenpc
			activeFade[npc] = nil
		end
	end
end


// effects stuff

local eff_exclude_keep = {
	["sound"] = true,
	["delay"] = true,
}

function CreateEffect( aeff_t, npc, pos, useActiveVer )
	if !aeff_t then return end
	local npc = npc
	local pos = pos
	local eff_t		

	-- if !aeff_t.id then
	-- 	eff_lastid = eff_lastid+1
	-- 	aeff_t.id = eff_lastid
	-- end

	-- if useActiveVer then
	-- 	eff_t = aeff_t
	-- else
	eff_t = table.Copy( aeff_t ) // is there a better way?
	-- end

	local lup_t = GetLookup( "effects",
		npc and activeNPC[npc] and activeNPC[npc]["npc_t"]["entity_type"] or "struct",
		nil,
		npc and activeNPC[npc] and GetPresetName( activeNPC[npc]["npc_t"]["classname"] )
	)

	ApplyValueTable( eff_t, lup_t.STRUCT )

	if eff_t["chance"] and math.random() >= eff_t["chance"]["f"] then
		return
	end

	if !eff_t["name"] then
		return
	else
		eff_t["name"] = string.Trim( GetPresetName( eff_t["name"] ) )
	end

	if eff_t["effect_data"] then
		ApplyValueTable( eff_t["effect_data"], lup_t.STRUCT["effect_data"].STRUCT )
	end
	
	if eff_t["sound"] then
		ApplyValueTable( eff_t["sound"], lup_t.STRUCT["sound"].STRUCT )
	end

	// continuous/non-continuous
	if useActiveVer then
		local delay = eff_t["delay"] or 0.1
		if aeff_t["next"] == nil then aeff_t["next"] = CurTime() + delay end
		if aeff_t["next"] < CurTime() then
			if eff_t["type"] == "particle" and eff_t["pcf"] then
				CreateParticle( npc, eff_t, pos, aeff_t )
			elseif eff_t["type"] == "effect" then
				CreateEff( npc, eff_t, pos, aeff_t )
			elseif eff_t["type"] == "sound" then
				CreateSnd( npc, eff_t, pos, aeff_t )
			end
			aeff_t["next"] = CurTime() + delay
		end
		// keep certain values in original table. the others will stay changable
		if !aeff_t.__LOOKEDUP then
			for k, v in pairs( eff_t ) do
				if !eff_exclude_keep[k] then
					aeff_t.k = v
				end
			end
			aeff_t.__LOOKEDUP = true
		end
	else
		// repeats or not
		if eff_t["reps"] and eff_t["reps"] > 0 then
			local delay = eff_t["delay"] or 0.1
			if delay < 0 then delay = engine.TickInterval() end

			for i=1,eff_t["reps"] do
				if eff_t["type"] == "particle" and eff_t["pcf"] then
					timer.Simple(i * delay, function() CreateParticle( npc, eff_t, pos, aeff_t ) end )
				elseif eff_t["type"] == "effect" then
					timer.Simple(i * delay, function() CreateEff( npc, eff_t, pos, aeff_t ) end )
				elseif eff_t["type"] == "sound" then
					timer.Simple(i * delay, function() CreateSnd( npc, eff_t, pos, aeff_t ) end )
				end
			end
		else			
			if eff_t["type"] == "particle" and eff_t["pcf"] then
				if eff_t["delay"] then 
					timer.Simple(eff_t["delay"], function() CreateParticle( npc, eff_t, pos, aeff_t ) end )
				else
					CreateParticle( npc, eff_t, pos )
				end
			elseif eff_t["type"] == "effect" then
				if eff_t["delay"] then 
					timer.Simple(eff_t["delay"], function() CreateEff( npc, eff_t, pos, aeff_t ) end )
				else
					CreateEff( npc, eff_t, pos )
				end
			elseif eff_t["type"] == "sound" then
				if eff_t["delay"] then 
					timer.Simple(eff_t["delay"], function() CreateSnd( npc, eff_t, pos, aeff_t ) end )
				else
					CreateSnd( npc, eff_t, pos )
				end
			end
		end
	end
end

// particle
function CreateParticle( npc, eff_t, pos, aeff_t )
	PrecacheEffect(eff_t["pcf"], eff_t["name"])

	local ppos = IsValid(npc) and npc:GetPos() or pos or Vector()
	local centerpos = eff_t["centered"] and IsValid(npc) and npc:OBBCenter() or Vector()
	local offsetpos = eff_t["offset"] and CopyData( eff_t["offset"] ) or Vector()

	if eff_t["offset_angadd"] then
		offsetpos:Rotate( eff_t["offset_angadd"] )
		aeff_t["offset"] = CopyData( offsetpos )
	end
	if eff_t["offset"] and IsValid(npc) then
		offsetpos:Rotate( npc:GetAngles() )
	end

	local offset2pos = eff_t["offset2"] or Vector()
	if eff_t["offset2"] then 
		offset2pos = CopyData( offset2pos )
		if IsValid(npc) then
			offset2pos:Rotate( npc:GetAngles() )
		end
	end

	if eff_t["attachment"] and IsValid(npc) then
		local attach = npc:GetAttachment( eff_t["attachment"] ) == nil and 1 or eff_t["attachment"]
		ParticleEffectAttach( eff_t["name"], eff_t["pattach"] or 4, npc, attach )
	else
		ParticleEffect(
			eff_t["name"],
			ppos+centerpos+offsetpos+offset2pos,
			eff_t["ang"] or IsValid(npc) and npc:GetAngles() or RandomAngle()
		)
	end
end

// engine effect
function CreateEff( npc, eff_t, pos, aeff_t )
	local ef = eff_t["EffectData"] or EffectData() // different from "effect_data"
	if !eff_t["EffectData"] then
		eff_t["effect_data"] = eff_t["effect_data"] or {}

		// effect data
		if eff_t["attachment"] then ef:SetAttachment( eff_t["attachment"] ) end
		ef:SetColor( eff_t["effect_data"]["color"] or 0 ) // color is an index
		if eff_t["effect_data"]["flags"] then ef:SetFlags( eff_t["flags"] ) end
		-- ef:SetHitBox( number hitBoxIndex )
		ef:SetMagnitude( eff_t["effect_data"]["magnitude"] or 1 )
		-- ef:SetMaterialIndex( number materialIndex )
		ef:SetNormal(eff_t["effect_data"]["normal"] or Vector(0,0,1) )
		ef:SetRadius( eff_t["effect_data"]["radius"] or 1 )
		ef:SetScale( eff_t["effect_data"]["scale"] or 1 )
		-- ef:SetStart( Vector start )
		-- ef:SetSurfaceProp( number surfaceProperties )
	end

	ef:SetAngles( eff_t["ang"] or IsValid(npc) and npc:GetAngles() or RandomAngle() )

	// position
	local ppos = IsValid(npc) and npc:GetPos() or pos or Vector()
	local centerpos = eff_t["centered"] and IsValid(npc) and npc:OBBCenter() or Vector()
	
	local offsetpos =  eff_t["offset"] and CopyData( eff_t["offset"] ) or Vector()
	if eff_t["offset_angadd"] then
		// this used to use the bug(?) that userdata references the original to modify the original offsetpos
		// but it actually affected across all copies of the preset, so multiple copies would multiply the rotation
		offsetpos:Rotate( eff_t["offset_angadd"] )
		aeff_t["offset"] = CopyData( offsetpos )
	end
	if eff_t["offset"] and IsValid(npc) then 
		offsetpos:Rotate( npc:GetAngles() )
	end

	local offset2pos = eff_t["offset2"] or Vector()
	if eff_t["offset2"] then 
		offset2pos = CopyData( offset2pos )
		if IsValid(npc) then
			offset2pos:Rotate( npc:GetAngles() )
		end
	end

	if eff_t["attachment"] then
		local attach = IsValid(npc) and ( npc:GetAttachment( eff_t["attachment"] ) == nil and 1 or eff_t["attachment"] ) or nil
		local apos = attach and npc:GetAttachment( attach ).Pos or ppos
		ef:SetOrigin( apos + offsetpos + offset2pos )
	else
		ef:SetOrigin( ppos + centerpos + offsetpos + offset2pos )
	end

	// not recreating EffectData() every time
	eff_t["EffectData"] = ef

	util.Effect( eff_t["name"], ef, true, true)
end

// sound
function CreateSnd( npc, eff_t, pos, aeff_t )
    eff_t["sound"] = eff_t["sound"] or {}
	if IsValid( npc ) then
		-- eff_t["sound"] = eff_t["sound"] or {}
		-- local sndf = 131 //1+2+128
		if eff_t.sound.restart and activeSound[npc] and activeSound[npc][ eff_t["name"] ] then
			npc:StopSound( eff_t["name"] )
		end
		npc:EmitSound( eff_t["name"], eff_t["sound"]["dist"], eff_t["sound"]["pitch"], eff_t["sound"]["volume"], eff_t["sound"]["channel"] or CHAN_STATIC, 131 )
		activeSound[npc] = activeSound[npc] or {}
		activeSound[npc][ eff_t["name"] ] = true // needed to stop looping sounds
    else
        //EmitSound( string soundName, Vector position, number entity = 0, number channel = CHAN_AUTO, number volume = 1, number soundLevel = 75, number soundFlags = 0, number pitch = 100, number dsp = 0, CRecipientFilter filter = nil )
        // Entity:EmitSound( string soundName, number soundLevel = 75, number pitchPercent = 100, number volume = 1, number channel = CHAN_AUTO, CHAN_WEAPON for weapons, number soundFlags = 0, number dsp = 0, CRecipientFilter filter = nil )
        local soundpoint = ents.Create( "info_null" )
        soundpoint:SetPos(pos)
        EmitSound( eff_t["name"], pos, soundpoint:EntIndex(), eff_t["sound"]["channel"] or CHAN_STATIC, eff_t["sound"]["volume"], eff_t["sound"]["dist"], 131, eff_t["sound"]["pitch"] )
        soundpoint:Remove()
	end
end

function PrecacheEffect( pcf, name )
	if !pcf or !name then return end
	if cachedEffects[pcf] and cachedEffects[pcf][name] then return end // if already cached
	game.AddParticles( pcf )
	PrecacheParticleSystem( name ) 
	cachedEffects[pcf] = cachedEffects[pcf] or {}
	cachedEffects[pcf][name] = true
	net.Start("npcd_effect_new")
		net.WriteString( pcf )
		net.WriteString( name )
	net.Broadcast()
end

function SendPrecachedEffects( ply )
	-- print("SendPrecachedEffects > ",ply)
	if !ply then return end
	local i = 0
	for pcf, name_t in pairs( cachedEffects ) do
		for name, _ in pairs( name_t ) do
			net.Start("npcd_effect_new")
				net.WriteString( pcf )
				net.WriteString( name )
			net.Send( ply )
		end
	end
end

function CreateAttachRope( from, from_a, to, to_a, width, mat )
	local attachf = from_a
	local attacht = to_a
	local frompos
	local topos

	// get offset, either attach point or ent's position
	if attachf and attachf != 0 then
		// validate attachment
		if from:GetAttachment( attachf ) == nil then
			if from:GetAttachment( 1 ) == nil then
				attachf = nil
			else
				attachf = 1
			end
		end
		
		if attachf then
			frompos = WorldToLocal( from:GetAttachment(attachf).Pos, from:GetAttachment(attachf).Ang, from:GetPos(), from:GetAngles() )
		else
			frompos = Vector()
		end
	else
		frompos = Vector()
	end

	if attacht and attacht != 0 then
		if to:GetAttachment( attacht ) == nil then
			if to:GetAttachment( 1 ) == nil then
				attacht = nil
			else
				attacht = 1
			end
		end
		
		if attacht then
			topos = WorldToLocal(to:GetAttachment(attacht).Pos, to:GetAttachment(attacht).Ang, to:GetPos(), to:GetAngles())
		else
			topos = Vector()
		end
	else
		topos = Vector()
	end

	constraint.CreateKeyframeRope( from:GetPos(),
		width,
		mat,
		nil,
		from, frompos, 0,
		to, topos, 0
	)
end

function Explode( ent, exp_t, pos ) --, atkr )
	local exp_t = exp_t or {}
	local pos = pos or IsValid( ent ) and ent:GetPos() + ent:OBBCenter()
	local ex = ents.Create("env_explosion")
	-- if exp_t.physex then
	-- 	ex = ents.Create( "env_physexplosion" )
	-- 	if physex_pushplayers then ex:AddSpawnFlag( 2 ) end
	-- else

	local dmag = exp_t.damage or 0
	local dradius = exp_t.radius or math.pow( dmag, 1.35 )

	// alternate explosion method
	if exp_t.altmethod then
		-- local dmg = DamageInfo()
		-- dmg:SetDamage( dmag )
		-- dmg:SetDamageType( exp_t.altmethod_dmgtype or exp_t.generic and DMG_GENERIC or DMG_BLAST )
		-- dmg:SetReportedPosition( pos )
		-- dmg:SetAttacker( ex )
		-- ex:SetInflictor( ent )

		local dtype = exp_t.altmethod_dmgtype or exp_t.generic and DMG_GENERIC or DMG_BLAST

		-- util.BlastDamageInfo( dmg, pos, dradius )
		-- local c = 0
		-- local latest = 0
		-- PrintTable( ents.GetAll() )
		local orig = ent
		local charonly = exp_t.altmethod_characteronly
		timer.Simple( engine.TickInterval(), function()
			local dmg = DamageInfo()
			for _, hit in ipairs( ents.GetAll() ) do
				if IsValid( hit ) and hit != orig
				-- and ( exp_t.altmethod_characteronly and dmgf_type_chk["character"]( hit )
				-- or !exp_t.altmethod_characteronly and ( hit:IsSolid() or dmgf_type_chk["character"]( hit ) ) )
				and ( charonly and dmgf_type_chk["character"]( hit )
				or !charonly and ( hit:IsSolid() or dmgf_type_chk["character"]( hit ) ) )
				and hit:GetPos():DistToSqr( pos ) <= dradius*dradius then
					-- timer.Simple( engine.TickInterval() * c * 0.01, function()
					if IsValid( hit ) then
						dmg:SetDamage( dmag )
						dmg:SetDamageType( dtype )
						dmg:SetReportedPosition( pos )
						dmg:SetAttacker( hit )
						dmg:SetDamageForce( ( hit:GetPos() - pos ):GetNormalized() * math.min( dmag * 1000, 99999 ) + Vector( 0, 0, math.min( dmag * 250, 99999 ) ) )
						hit:TakeDamageInfo( dmg )
					end
					-- end	)
					-- c=c+1
					-- latest=engine.TickInterval() * c
				end
			end
		end )

		if exp_t.effects then
			for _, df in pairs( exp_t.effects ) do
				CreateEffect( df, ent, pos )
			end
		else
			local effectdata = EffectData()
			effectdata:SetOrigin( pos )
			util.Effect( "Explosion", effectdata, true, true )
		end

		-- timer.Simple( 3, function() if IsValid( ex ) then ex:Remove() end end )
	
	// normal explosion
	else
		if exp_t.generic then ex:AddSpawnFlag( 16384 ) end
			-- ex:AddSpawnFlag( 6272 ) // random orientation, no clamp min/max
		-- end

		if dmag <= 0 then ex:AddSpawnFlag( 1 ) end
		
		ex:SetPos( pos )
		-- ex:SetAngles( Angle() )
		ex:SetKeyValue( "iMagnitude", dmag )
		ex:SetKeyValue( "iRadiusOverride", dradius )


		if exp_t.effects then
			-- ex:SetNoDraw(true)
			-- if !exp_t.physex then
				ex:AddSpawnFlag( 2044 )
			-- end //4+8+16+32+64+256+512+1024
			for _, df in pairs( exp_t.effects ) do
				CreateEffect( df, ent, pos )
			end
		end

		ex:Spawn()
		ex:Activate()
		ex:Fire( "Explode", 0, 0 )
	end

	-- if exp_t.physex then
	-- 	for i=100,dmag,100 do
	-- 		local pex = ents.Create( "env_physexplosion" )
	-- 		pex:SetKeyValue( "iMagnitude", dmag-i % 100 )
	-- 		pex:SetKeyValue( "iRadiusOverride", dradius )
	-- 		pex:Spawn()
	-- 		pex:Activate()
	-- 		pex:Fire( "Explode", 0, 0 )
	-- 	end
	-- end
	
	return ex
end