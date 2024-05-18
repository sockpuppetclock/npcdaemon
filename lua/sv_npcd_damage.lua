// damage stuff

module( "npcd", package.seeall )

local env_entities = {
	["env_ar2explosion"] = true,
	["env_beam"] = true,
	["env_beverage"] = true,
	["env_blood"] = true,
	["env_bubbles"] = true,
	["env_citadel_energy_core"] = true,
	["env_credits"] = true,
	["env_cubemap"] = true,
	["env_dustpuff"] = true,
	["env_effectscript"] = true,
	["env_embers"] = true,
	["env_entity_dissolver"] = true,
	["env_entity_igniter"] = true,
	["env_entity_maker"] = true,
	["env_explosion"] = true,
	["env_extinguisherjet"] = true,
	["env_fade"] = true,
	["env_fire"] = true,
	["env_firesensor"] = true,
	["env_firesource"] = true,
	["env_flare"] = true,
	["env_fog_controller"] = true,
	["env_funnel"] = true,
	["env_global"] = true,
	["env_gunfire"] = true,
	["env_headcrabcanister"] = true,
	["env_hudhint"] = true,
	["env_laser"] = true,
	["env_lightglow"] = true,
	["env_message"] = true,
	["env_microphone"] = true,
	["env_muzzleflash"] = true,
	["env_particlelight"] = true,
	["env_particlescript"] = true,
	["env_physexplosion"] = true,
	["env_physimpact"] = true,
	["env_player_surface_trigger"] = true,
	["env_rotorshooter"] = true,
	["env_rotorwash"] = true,
	["env_screenoverlay"] = true,
	["env_shake"] = true,
	["env_shooter"] = true,
	["env_smokestack"] = true,
	["env_smoketrail"] = true,
	["env_soundscape"] = true,
	["env_soundscape_proxy"] = true,
	["env_soundscape_triggerable"] = true,
	["env_spark"] = true,
	["env_speaker"] = true,
	["env_splash"] = true,
	["env_sprite"] = true,
	["env_spritetrail"] = true,
	["env_starfield"] = true,
	["env_steam"] = true,
	["env_sun"] = true,
	["env_terrainmorph"] = true,
	["env_texturetoggle"] = true,
	["env_tonemap_controller"] = true,
	["env_wind"] = true,
	["env_zoom"] = true,
	["entityflame"] = true,
}

local func_entities = {
	["func_areaportal"] = true,
	["func_areaportalwindow"] = true,
	["func_breakable"] = true,
	["func_breakable_surf"] = true,
	["func_brush"] = true,
	["func_button"] = true,
	["func_capturezone"] = true,
	["func_changeclass"] = true,
	["func_clip_vphysics"] = true,
	["func_combine_ball_spawner"] = true,
	["func_conveyor"] = true,
	["func_detail"] = true,
	["func_door"] = true,
	["func_door_rotating"] = true,
	["func_dustcloud"] = true,
	["func_dustmotes"] = true,
	["func_extinguishercharger"] = true,
	["func_guntarget"] = true,
	["func_healthcharger"] = true,
	["func_illusionary"] = true,
	["func_ladder"] = true,
	["func_ladderendpoint"] = true,
	["func_lod"] = true,
	["func_lookdoor"] = true,
	["func_monitor"] = true,
	["func_movelinear"] = true,
	["func_nobuild"] = true,
	["func_nogrenades"] = true,
	["func_occluder"] = true,
	["func_physbox"] = true,
	["func_physbox_multiplayer"] = true,
	["func_platrot"] = true,
	["func_precipitation"] = true,
	["func_proprespawnzone"] = true,
	["func_recharge"] = true,
	["func_reflective_glass"] = true,
	["func_regenerate"] = true,
	["func_respawnroom"] = true,
	["func_respawnroomvisualizer"] = true,
	["func_rot_button"] = true,
	["func_rotating"] = true,
	["func_smokevolume"] = true,
	["func_tank"] = true,
	["func_tankairboatgun"] = true,
	["func_tankapcrocket"] = true,
	["func_tanklaser"] = true,
	["func_tankmortar"] = true,
	["func_tankphyscannister"] = true,
	["func_tankpulselaser"] = true,
	["func_tankrocket"] = true,
	["func_tanktrain"] = true,
	["func_trackautochange"] = true,
	["func_trackchange"] = true,
	["func_tracktrain"] = true,
	["func_traincontrols"] = true,
	["func_useableladder"] = true,
	["func_vehicleclip"] = true,
	["func_viscluster"] = true,
	["func_wall"] = true,
	["func_wall_toggle"] = true,
	["func_water_analog"] = true,
}

// damage filter check functions
// instead of manually elseifing everything

local dmgf_condtables = {
	["attacker"] = true,
	["victim"] = true,
	["damage"] = true,
}

dmgf_type_chk = { // simpler checks
	["nextbot"] = function( chk, dmg ) return chk:IsNextBot() end,
	["npc"] = function( chk, dmg ) return chk:IsNPC() end,
	["entity"] = function( chk, dmg ) return chk:IsEntity() and !chk:IsWorld() end,
	["player"] = function( chk, dmg ) return chk:IsPlayer() end,
	["self"] = function( chk, dmg, other ) return other == chk end,
	["worldspawn"] = function( chk, dmg ) return chk:IsWorld() end,
	["environment"] = function( chk, dmg ) return env_entities[chk:GetClass()] end,
	["brush"] = function( chk, dmg ) return chk:GetBrushPlane(0) != nil or func_entities[chk:GetClass()] end,

	["character"] = function( chk, dmg ) return chk:IsNPC() or chk:IsNextBot() or chk:IsPlayer() end,
	["non-character entity"] = function( chk, dmg ) return !chk:IsNPC() and !chk:IsNextBot() and !chk:IsPlayer() and IsEntity(chk) and !chk:IsWorld() and chk:GetClass() != "env_explosion" end,

	// checking both ways
	["enemy"] = function( chk, dmg, other ) return
		( other:IsNPC() or other:IsNextBot() or other:IsPlayer() ) and 
		( isfunction( chk.GetRelationship ) and chk:GetRelationship( other ) == D_HT
		or isfunction( chk.Disposition ) and chk:Disposition( other ) == D_HT
		or isfunction( other.GetRelationship ) and other:GetRelationship( chk ) == D_HT
		or isfunction( other.Disposition ) and other:Disposition( chk ) == D_HT )
	end,
	["friendly"] = function( chk, dmg, other ) return
		( other:IsNPC() or other:IsNextBot() or other:IsPlayer() ) and 
		( isfunction( chk.GetRelationship ) and chk:GetRelationship( other ) == D_LI
		or isfunction( chk.Disposition ) and chk:Disposition( other ) == D_LI
		or isfunction( other.GetRelationship ) and other:GetRelationship( chk ) == D_LI
		or isfunction( other.Disposition ) and other:Disposition( chk ) == D_LI )
	end,
	["fear"] = function( chk, dmg, other ) return
		( other:IsNPC() or other:IsNextBot() or other:IsPlayer() ) and 
		( isfunction( chk.GetRelationship ) and chk:GetRelationship( other ) == D_FR
		or isfunction( chk.Disposition ) and chk:Disposition( other ) == D_FR
		or isfunction( other.GetRelationship ) and other:GetRelationship( chk ) == D_FR
		or isfunction( other.Disposition ) and other:Disposition( chk ) == D_FR )
	end,
	["neutral"] = function( chk, dmg, other ) return
		( other:IsNPC() or other:IsNextBot() or other:IsPlayer() ) and 
		( isfunction( chk.GetRelationship ) and chk:GetRelationship( other ) == D_NU
		or isfunction( chk.Disposition ) and chk:Disposition( other ) == D_NU
		or isfunction( other.GetRelationship ) and other:GetRelationship( chk ) == D_NU
		or isfunction( other.Disposition ) and other:Disposition( chk ) == D_NU )
	end,
	["preset"] = function( chk, v )
		return activeNPC[chk]
		and activeNPC[chk]["npcpreset"]
		and activeNPC[chk]["npcpreset"] == v["name"]
		and activeNPC[chk]["npc_t"]["entity_type"] == v["type"]
		or false
	end,
	["classname"] = function( chk, v )
		local class = GetPresetName( v )
		if class == chk:GetClass() then
			return true
		end
	end,
	["dmgtype"] = function( dmg, v ) return dmg:IsDamageType( v ) end,
}

dmgf_cond_struct_chk = { // include/exclude
	["valuechk"] = function( lup_t, ckey, val, chk )
		local valid = true
		if val["include"] and !table.IsEmpty( val["include"] ) then
			valid = false
			for _, v in pairs( val["include"] ) do
				if dmgf_type_chk[ckey]( chk, v ) then
					valid = true
					break
				end
			end
		end

		if valid and val["exclude"] and !table.IsEmpty( val["exclude"] ) then
			for _, v in pairs( val["exclude"] ) do
				if dmgf_type_chk[ckey]( chk, v ) then
					valid = false
					break
				end
			end
		end

		return valid
	end,
	["types"] = function( lup_t, other, val, chk, dmg )
		local valid = true
		if val["include"] and !table.IsEmpty( val["include"] ) then
			valid = false
			for _, v in pairs( val["include"] ) do
				if dmgf_type_chk[v]( chk, dmg, other ) then
					valid = true
					break
				end
			end
		end

		if valid and val["exclude"] and !table.IsEmpty( val["exclude"] ) then
			for _, v in pairs( val["exclude"] ) do
				if dmgf_type_chk[v]( chk, dmg, other ) then
					valid = false
					break
				end
			end
		end

		return valid
	end,
	["weapon_classes"] = function( lup_t, val, chk )
		local valid = true
		local wep = isfunction( chk.GetActiveWeapon ) and IsValid( chk:GetActiveWeapon() ) and chk:GetActiveWeapon() or nil
		
		if wep then
			if val["include"] and !table.IsEmpty( val["include"] ) then
				valid = false
				for _, v in pairs( val["include"] ) do
					if dmgf_type_chk["classname"]( wep, v ) then
						valid = true
						break
					end
				end
			end

			if valid and val["exclude"] and !table.IsEmpty( val["exclude"] ) then
				for _, v in pairs( val["exclude"] ) do
					if dmgf_type_chk["classname"]( wep, v ) then
						valid = false
						break
					end
				end
			end
		elseif val["include"] then
			valid = false
		end

		return valid
	end,
	["weapon_sets"] = function( lup_t, val, chk )
		local valid = true
		local wep = isfunction( chk.GetActiveWeapon ) and IsValid( chk:GetActiveWeapon() ) and chk:GetActiveWeapon() or nil
		
		if wep then
			if val["include"] and !table.IsEmpty( val["include"] ) then
				valid = false
				for _, v in pairs( val["include"] ) do
					local wset = GetPresetName( v )
					if Settings["weapon_set"][wset] and Settings["weapon_set"][wset]["weapons"] then
						for k, w in pairs( Settings["weapon_set"][wset]["weapons"] ) do
							local cl = GetPresetName( w["classname"] )
							if cl == wep:GetClass() then
								valid = true
								break
							end
						end
					end
					if valid then
						break
					end
				end
			end

			if valid and val["exclude"] and !table.IsEmpty( val["exclude"] ) then
				for _, v in pairs( val["exclude"] ) do
					local wset = GetPresetName( v )
					if Settings["weapon_set"][wset] and Settings["weapon_set"][wset]["weapons"] then
						for k, w in pairs( Settings["weapon_set"][wset]["weapons"] ) do
							local cl = GetPresetName( w["classname"] )
							if cl == wep:GetClass() then
								valid = false
								break
							end
						end
					end
					if !valid then
						break
					end
				end
			end
		elseif val["include"] then
			valid = false
		end

		return valid
	end,
}

dmgf_cond_chks_gl = { // greater/lesser
	["spin_greater"] = function( val, chk )
		local val_sqr = val*val
		if !chk:IsPlayer() and IsValid( chk:GetPhysicsObject() ) then
			return chk:GetPhysicsObject():GetAngleVelocity():LengthSqr() > val_sqr
		else
			return chk:GetLocalAngularVelocity():LengthSqr() > val_sqr
		end
	end,
	["spin_lesser"] = function( val, chk )
		local val_sqr = val*val
		if !chk:IsPlayer() and IsValid( chk:GetPhysicsObject() ) then
			return chk:GetPhysicsObject():GetAngleVelocity():LengthSqr() > val_sqr
		else
			return chk:GetLocalAngularVelocity():LengthSqr() > val_sqr
		end
	end,
	["velocity_greater"] = function( val, chk )
		local val_sqr = val*val
		if !chk:IsPlayer() and IsValid( chk:GetPhysicsObject() ) then
			return chk:GetPhysicsObject():GetVelocity():LengthSqr() > val_sqr
		else
			-- print( val_sqr, chk.npcd_velocity_recentmax_sqr )
			return chk:GetVelocity():LengthSqr() > val_sqr
			or chk.npcd_velocity_recentmax_sqr and chk.npcd_velocity_recentmax_sqr > val_sqr
			-- or chk.npcd_velocity_avg and chk.npcd_velocity_avg:LengthSqr() > val_sqr
			-- or chk.npcd_velocity_last and chk.npcd_velocity_last:LengthSqr() > val_sqr
		end
	end,
	["velocity_lesser"] = function( val, chk )
		local val_sqr = val*val
		if !chk:IsPlayer() and IsValid( chk:GetPhysicsObject() ) then
			return chk:GetPhysicsObject():GetVelocity():LengthSqr() <= val_sqr
		else
			return chk:GetVelocity():LengthSqr() <= val_sqr
			or chk.npcd_velocity_recentmax_sqr and chk.npcd_velocity_recentmax_sqr <= val_sqr // recentmax is intentional
			-- or chk.npcd_velocity_avg and chk.npcd_velocity_avg:LengthSqr() <= val_sqr
			-- or chk.npcd_velocity_last and chk.npcd_velocity_last:LengthSqr() <= val_sqr
		end
	end,
	["health_greater"] = function( val, chk )
		if istable( val ) and val["f"] then
			return chk:Health() / chk:GetMaxHealth() > val["f"]
		else
			return chk:Health() > val
		end
	end,
	["health_lesser"] = function( val, chk )
		if istable( val ) and val["f"] then
			return chk:Health() / chk:GetMaxHealth() <= val["f"]
		else
			return chk:Health() <= val
		end
	end,
}

// *sniff* i've learned so much. update: nevermind

compare_funcs = {
   [-2] = function(a,b) return a < b  end,
   [-1] = function(a,b) return a <= b end,
   [-0] = function(a,b) return a == b end,
   [1]  = function(a,b) return a >= b end,
   [2]  = function(a,b) return a > b  end,
}

// true if valid
dmgf_cond_chks = {
	["attacker"] = {
		["spin_greater"] = function( val, atkr, victim, dmg ) return dmgf_cond_chks_gl["spin_greater"]( val, atkr ) end,
		["spin_lesser"] = function( val, atkr, victim, dmg ) return dmgf_cond_chks_gl["spin_lesser"]( val, atkr ) end,
		["velocity_greater"] = function( val, atkr, victim, dmg ) return dmgf_cond_chks_gl["velocity_greater"]( val, atkr ) end,
		["velocity_lesser"] = function( val, atkr, victim, dmg ) return dmgf_cond_chks_gl["velocity_lesser"]( val, atkr ) end,
		["health_greater"] = function( val, atkr, victim, dmg ) return dmgf_cond_chks_gl["health_greater"]( val, atkr ) end,
		["health_lesser"] = function( val, atkr, victim, dmg ) return dmgf_cond_chks_gl["health_lesser"]( val, atkr ) end,
		["onfire"] = function( val, atkr, victim, dmg ) return atkr:IsOnFire() == val end,
		["grounded"] = function( val, atkr, victim, dmg ) return atkr:IsOnGround() == val end,
      ["cumulative_damage"] = function( val, atkr, victim, dmg )
         if val.compare_cond == nil then return false end
         
         local taken = 0
         if val.timelimit then
            local backtime = CurTime() - val.timelimit
            if damageTakenTable[atkr] then
               for t, d in pairs(damageTakenTable[atkr]) do
                  if t >= backtime then
                     taken = taken + d
                  end
               end
            end
         else
            taken = damageTakenTotals[atkr] or 0
         end

         local pass = compare_funcs[val.compare_cond] and compare_funcs[val.compare_cond](
            taken, val.damage
         )
         if pass and val.reset_on_pass then
            damageTakenTotals[atkr] = 0
         end
         return pass
      end,
		["presets"] = function( val, atkr, victim, dmg )
			return dmgf_cond_struct_chk["valuechk"]( 
				t_value_structs["damagefilter"].STRUCT["condition"].STRUCT["attacker"].STRUCT["presets"].STRUCT,
				"preset", 
				val, 
				atkr 
			)
		end,
		["types"] = function( val, atkr, victim, dmg )
			-- print( "types", val, atkr, victim, dmg )
			return dmgf_cond_struct_chk["types"]( 
				t_value_structs["damagefilter"].STRUCT["condition"].STRUCT["attacker"].STRUCT["types"].STRUCT, 
				victim, 
				val, 
				atkr,
				dmg 
			)
		end,
		["classnames"] = function( val, atkr, victim, dmg )
			return dmgf_cond_struct_chk["valuechk"]( 
				t_value_structs["damagefilter"].STRUCT["condition"].STRUCT["attacker"].STRUCT["classnames"].STRUCT, 
				"classname", 
				val, 
				atkr 
			)
		end,
		["weapon_classes"] = function( val, atkr, victim, dmg )
			return dmgf_cond_struct_chk["weapon_classes"]( 
				t_value_structs["damagefilter"].STRUCT["condition"].STRUCT["attacker"].STRUCT["weapon_classes"].STRUCT, 
				"classname", 
				val, 
				atkr 
			)
		end,
		["weapon_sets"] = function( val, atkr, victim, dmg )
			return dmgf_cond_struct_chk["weapon_sets"]( 
				t_value_structs["damagefilter"].STRUCT["condition"].STRUCT["attacker"].STRUCT["weapon_sets"].STRUCT, 
				val, 
				atkr 
			)
		end,
	},

	["victim"] = {
		["spin_greater"] = function( val, atkr, victim, dmg ) return dmgf_cond_chks_gl["spin_greater"]( val, victim ) end,
		["spin_lesser"] = function( val, atkr, victim, dmg ) return dmgf_cond_chks_gl["spin_lesser"]( val, victim ) end,
		["velocity_greater"] = function( val, atkr, victim, dmg ) return dmgf_cond_chks_gl["velocity_greater"]( val, victim ) end,
		["velocity_lesser"] = function( val, atkr, victim, dmg ) return dmgf_cond_chks_gl["velocity_lesser"]( val, victim ) end,
		["health_greater"] = function( val, atkr, victim, dmg ) return dmgf_cond_chks_gl["health_greater"]( val, victim ) end,
		["health_lesser"] = function( val, atkr, victim, dmg ) return dmgf_cond_chks_gl["health_lesser"]( val, victim ) end,
		["onfire"] = function( val, atkr, victim, dmg ) return victim:IsOnFire() == val end,
		["grounded"] = function( val, atkr, victim, dmg ) return victim:IsOnGround() == val end,
      ["cumulative_damage"] = function( val, atkr, victim, dmg )
         if val.compare_cond == nil then return false end
         
         local taken = 0
         if val.timelimit then
            local backtime = CurTime() - val.timelimit
            if damageTakenTable[victim] then
               for t, d in pairs(damageTakenTable[victim]) do
                  if t >= backtime then
                     taken = taken + d
                  end
               end
            end
         else
            taken = damageTakenTotals[victim] or 0
         end

         local pass = compare_funcs[val.compare_cond] and compare_funcs[val.compare_cond](
            taken, val.damage
         )
         if pass and val.reset_on_pass then
            damageTakenTotals[victim] = 0
         end
         return pass
      end,
		["presets"] = function( val, atkr, victim, dmg )
			return dmgf_cond_struct_chk["valuechk"](
				t_value_structs["damagefilter"].STRUCT["condition"].STRUCT["victim"].STRUCT["presets"].STRUCT,
				"preset",
				val,
				victim 
			)
		end,
		["types"] = function( val, atkr, victim, dmg )
			return dmgf_cond_struct_chk["types"]( 
				t_value_structs["damagefilter"].STRUCT["condition"].STRUCT["victim"].STRUCT["types"].STRUCT,
				atkr,
				val,
				victim,
				dmg 
			)
		end,
		["classnames"] = function( val, atkr, victim, dmg )
			return dmgf_cond_struct_chk["valuechk"]( 
				t_value_structs["damagefilter"].STRUCT["condition"].STRUCT["victim"].STRUCT["classnames"].STRUCT,
				"classname",
				val,
				victim
			)
		end,
		["weapon_classes"] = function( val, atkr, victim, dmg )
			return dmgf_cond_struct_chk["weapon_classes"]( 
				t_value_structs["damagefilter"].STRUCT["condition"].STRUCT["victim"].STRUCT["weapon_classes"].STRUCT,
				"classname",
				val,
				victim 
			)
		end,
	},

	["damage"] = {
		["explosion"] = function( val, atkr, victim, dmg ) return dmg:IsExplosionDamage() == val end,
		["bullet"] = function( val, atkr, victim, dmg ) return dmg:IsBulletDamage() == val end,
		["greater"] = function( val, atkr, victim, dmg ) return dmg:GetDamage() > val end,
		["lesser"] = function( val, atkr, victim, dmg ) return dmg:GetDamage() <= val end,
		["greater_than_health"] = function( val, atkr, victim, dmg ) return ( dmg:GetDamage() >= victim:Health() ) == val end,
		["dmg_types"] = function( val, atkr, victim, dmg )
			return dmgf_cond_struct_chk["valuechk"](
				t_value_structs["damagefilter"].STRUCT["condition"].STRUCT["damage"].STRUCT["dmg_types"].STRUCT,
				"dmgtype",
				val,
				dmg
			)
		end,
		["taken"] = function( val, atkr, victim, dmg, took )
			return val == took
		end,
		["ignore_took"] = function( val, atkr, victim, dmg, took )
			return true // already checked earlier
			-- return took or !took and val
		end,
	},
}

// DamageInfo copy metatable
local DamageCopy = {}
local DamageCopy_meta = {}
DamageCopy.__index = DamageCopy_meta
function DamageCopy_meta.AddDamage( self, add )
   self.Damage = self.Damage + add
end
function DamageCopy_meta.GetAmmoType( self )
   return self.AmmoType
end
function DamageCopy_meta.GetAttacker( self )
   return self.Attacker
end
function DamageCopy_meta.GetBaseDamage( self )
   return self.BaseDamage
end
function DamageCopy_meta.GetDamage( self )
   return self.Damage
end
function DamageCopy_meta.GetDamageBonus( self )
   return self.DamageBonus
end
function DamageCopy_meta.GetDamageCustom( self )
   return self.DamageCustom
end
function DamageCopy_meta.GetDamageForce( self )
   return self.DamageForce
end
function DamageCopy_meta.GetDamagePosition( self )
   return self.DamagePosition
end
function DamageCopy_meta.GetDamageType( self )
   return self.DamageType
end
function DamageCopy_meta.GetInflictor( self )
   return self.Inflictor
end
function DamageCopy_meta.GetMaxDamage( self )
   return self.MaxDamage
end
function DamageCopy_meta.GetReportedPosition( self )
   return self.ReportedPosition
end
function DamageCopy_meta.IsBulletDamage( self )
   return bit.band(self:GetDamageType(), DMG_BULLET) != 0
end
function DamageCopy_meta.IsDamageType( self, dmgType )
   return bit.band(self:GetDamageType(), dmgType) != 0
end
function DamageCopy_meta.IsExplosionDamage( self )
   return bit.band(self:GetDamageType(), DMG_BLAST) != 0
end
function DamageCopy_meta.IsFallDamage( self )
   return bit.band(self:GetDamageType(), DMG_FALL) != 0
end
function DamageCopy_meta.ScaleDamage( self, scale )
   self.Damage = self.Damage * scale
end
function DamageCopy_meta.SetAmmoType( self, ammoType )
   self.AmmoType = ammoType
end
function DamageCopy_meta.SetAttacker( self, ent )
   self.Attacker = ent
end
function DamageCopy_meta.SetBaseDamage( self, number )
   self.BaseDamage = number
end
function DamageCopy_meta.SetDamage( self, damage )
   self.Damage = damage
end
function DamageCopy_meta.SetDamageBonus( self, damage )
   self.DamageBonus = damage
end
function DamageCopy_meta.SetDamageCustom( self, dmgType )
   self.DamageType = dmgType
end
function DamageCopy_meta.SetDamageForce( self, forcevector )
   self.DamageForce = forcevector
end
function DamageCopy_meta.SetDamagePosition( self, pos )
   self.DamagePosition = pos
end
function DamageCopy_meta.SetDamageType( self, type )
   self.DamageType = type
end
function DamageCopy_meta.SetInflictor( self, inflictor )
   self.Inflictor = inflictor
end
function DamageCopy_meta.SetMaxDamage( self, maxDamage )
   self.MaxDamage = maxDamage
end
function DamageCopy_meta.SetReportedPosition( self, pos )
   self.ReportedPosition = pos
end
function DamageCopy_meta.SubtractDamage( self, damage )
   self.Damage = self.Damage - damage
end
function DamageCopy_meta.DamageInfo( self )
   local dmg = DamageInfo()
   dmg:SetAmmoType(self.AmmoType)
   dmg:SetAttacker(self.Attacker)
   dmg:SetBaseDamage(self.BaseDamage)
   dmg:SetDamage(self.Damage)
   dmg:SetDamageBonus(self.DamageBonus)
   dmg:SetDamageCustom(self.DamageCustom)
   dmg:SetDamageForce(self.DamageForce)
   dmg:SetDamagePosition(self.DamagePosition)
   dmg:SetDamageType(self.DamageType)
   dmg:SetInflictor(self.Inflictor)
   dmg:SetMaxDamage(self.MaxDamage)
   dmg:SetReportedPosition(self.ReportedPosition)
   return dmg
end

// returns stable copy of DamageInfo
function CopyDamageInfo(dmg)
   local copy = {
      AmmoType = dmg:GetAmmoType(),
      Attacker = dmg:GetAttacker(),
      BaseDamage = dmg:GetBaseDamage(),
      Damage = dmg:GetDamage(),
      DamageBonus = dmg:GetDamageBonus(),
      DamageCustom = dmg:GetDamageCustom(),
      DamageForce = dmg:GetDamageForce(),
      DamagePosition = dmg:GetDamagePosition(),
      DamageType = dmg:GetDamageType(),
      Inflictor = dmg:GetInflictor(),
      MaxDamage = dmg:GetMaxDamage(),
      ReportedPosition = dmg:GetReportedPosition()
   }
   setmetatable(copy, DamageCopy)
   return copy
end

function ApplyDamageFilters( dmg, filter_tbl, atkr, victim, apply, restore, took )
	local olddmg

	if restore then
		// only what is changed
		olddmg = {
			-- AmmoType = dmg:GetAmmoType(),
			-- Attacker = dmg:GetAttacker(),
			-- BaseDamage = dmg:GetBaseDamage(),
			Damage = dmg:GetDamage(),
			-- DamageBonus = dmg:GetDamageBonus(),
			-- DamageCustom = dmg:GetDamageCustom(),
			DamageForce = dmg:GetDamageForce(),
			-- DamagePosition = dmg:GetDamagePosition(),
			DamageType = dmg:GetDamageType(),
			-- Inflictor = dmg:GetInflictor(),
			-- MaxDamage = dmg:GetMaxDamage(),
			-- ReportedPosition = dmg:GetReportedPosition()
		}
	end

	for k, filter in pairs( filter_tbl ) do --first come first serve
		if DamageFilter( dmg, filter, atkr, victim, apply, took ) then
			break
		end
	end

	if restore then
		-- dmg:SetAmmoType( olddmg.AmmoType )
		-- dmg:SetAttacker( olddmg.Attacker )
		-- dmg:SetBaseDamage( olddmg.BaseDamage )
		dmg:SetDamage( olddmg.Damage )
		-- dmg:SetDamageBonus( olddmg.DamageBonus )
		-- dmg:SetDamageCustom( olddmg.DamageCustom )
		dmg:SetDamageForce( olddmg.DamageForce )
		-- dmg:SetDamagePosition( olddmg.DamagePosition )
		dmg:SetDamageType( olddmg.DamageType )
		-- dmg:SetInflictor( olddmg.Inflictor )
		-- dmg:SetMaxDamage( olddmg.MaxDamage )
		-- dmg:SetReportedPosition( olddmg.ReportedPosition )
	end
end

function DamageFilter( dmg, afilter, atkr, victim, apply, took )

	if !dmg or !afilter or !IsValid( atkr ) or !IsValid( victim ) then
		-- if debugged then print( "npcd > DamageFilter > failed:", dmg, afilter, atkr, victim ) end
		return
	end

	if atkr == game.GetWorld() then
		-- if debugged then print( "npcd > DamageFilter > worldspawn, skipped:", dmg, afilter, atkr, victim ) end
		return
	end

	local filter = table.Copy( afilter )
	filter.condition = afilter.condition // condition should stay consistent

	local lup_t = t_value_structs["damagefilter"]
	ApplyValueTable( filter, lup_t.STRUCT )

	local valid = true

	if filter["maxpasses"] and ( filter["count"] and filter["count"] >= filter["maxpasses"] or filter["maxpasses"] <= 0 ) then
		-- if debugged then print( "npcd > DamageFilter > filter between ", atkr, "and", victim," past maxpasses limit")
		return false
	end

	// conditions
	if filter["condition"] then
		// only need to establish this stuff once
		if !filter.condition.__LOOKEDUP then
			ApplyValueTable( filter["condition"], lup_t.STRUCT["condition"].STRUCT )

			// inner values
			for vn in pairs( filter["condition"] ) do // attacker/victim
				if lup_t.STRUCT["condition"].STRUCT[vn].STRUCT then
					ApplyValueTable( filter["condition"][vn], lup_t.STRUCT["condition"].STRUCT[vn].STRUCT )
					for cvn in pairs( filter["condition"][vn] ) do
						if lup_t.STRUCT["condition"].STRUCT[vn].STRUCT[cvn].STRUCT then
							ApplyValueTable( filter["condition"][vn][cvn], lup_t.STRUCT["condition"].STRUCT[vn].STRUCT[cvn].STRUCT )
						end
					end
				end
			end
			
			filter.condition.__LOOKEDUP = true
		end

		if filter["condition"]["chance"] and math.random() >= filter["condition"]["chance"]["f"] then
			return false
		end
		
		// postdamage took check
		if took == false and ( !filter["condition"]["damage"] or filter["condition"]["damage"] and !filter["condition"]["damage"]["ignore_took"] ) then
			return false
		end
		
		local old_dmg

		// preapply for check
		if filter["condition"]["preapply"] then
			old_dmg = dmg:GetDamage()

			if filter["damagescale"] then 
				dmg:ScaleDamage( filter["damagescale"] )
			end

			if filter["damageadd"] then 
				dmg:SetDamage( dmg:GetDamage() + filter["damageadd"] )
			end

			if ( dmg:GetDamage() != 0 or !filter["minmax_zero"] ) and ( filter["min"] or filter["max"] ) then
				dmg:SetDamage(math.Clamp(dmg:GetDamage(), filter["min"] or -math.huge, filter["max"] or math.huge ))
			end
		end

		// do the checks, if cond is false then fail
		for k, c in pairs( filter["condition"] ) do
			-- if k == "__LOOKEDUP" then continue end
			if !dmgf_condtables[k] then continue end
			for ck, val in pairs( c ) do
				if dmgf_cond_chks[k] and !dmgf_cond_chks[k][ck]( val, atkr, victim, dmg, took ) then
					valid = false
					break
				end
				-- print( "passed", k, ck, val )
			end
			if !valid then
				-- print( "failed", k, ck, val )
				break
			end
		end

		// revert preapply
		if filter["condition"]["preapply"] then
			dmg:SetDamage( old_dmg )
		end

		if filter["condition"]["invert"] then
			valid = !valid
		end
	elseif took == false then
		return false
	end

	if !valid then return valid end

	// do stuff to damage
	if filter["new_dmg_type"] then
		dmg:SetDamageType( filter["new_dmg_type"] )
	end

	if filter["damagescale"] then 
		dmg:ScaleDamage( filter["damagescale"] )
	end

	if filter["damageadd"] then 
		dmg:SetDamage( dmg:GetDamage() + filter["damageadd"] )
	end
   
	// >0 or ~=0 ? the purpose is because other filters may set dmg to 0, e.g. hitgroup filter
	if ( dmg:GetDamage() != 0 or !filter["minmax_zero"] ) and ( filter["min"] or filter["max"] ) then
		dmg:SetDamage(math.Clamp(dmg:GetDamage(), filter["min"] or -math.huge, filter["max"] or math.huge ))
	end

	if filter["damageforce"] then
		local ply_yaw = dmg:GetDamagePosition() - atkr:GetPos()
		ply_yaw = ply_yaw:Angle().y

		ApplyValueTable( filter["damageforce"], lup_t.STRUCT["damageforce"].STRUCT )
		if filter["damageforce"]["new"] then
			local vec = CopyData( filter["damageforce"]["new"] )
			vec:Rotate( Angle( 0, ply_yaw, 0 ) )
			dmg:SetDamageForce( vec )
		end
		if filter["damageforce"]["add"] then
			local vec = CopyData( filter["damageforce"]["add"] )
			vec:Rotate( Angle( 0, ply_yaw, 0 ) )
			dmg:SetDamageForce( dmg:GetDamageForce() + vec )
		end
		if filter["damageforce"]["mult"] then
			dmg:SetDamageForce( dmg:GetDamageForce() * filter["damageforce"]["mult"] )
		end
	end

	// todo: anything other than this many if-thens

	// do stuff to attacker
	if filter["attacker"] then
		local ntbl = IsValid(atkr) and ( activeNPC[atkr] or activePly[atkr] ) or nil

		ApplyValueTable( filter["attacker"], lup_t.STRUCT["attacker"].STRUCT )

		if filter["attacker"]["setenemy"] and atkr:IsNPC() then
			atkr:SetEnemy( victim )
		end
		if filter["attacker"]["settarget"] and atkr:IsNPC() then
			atkr:SetTarget( victim )
		end

		if filter["attacker"]["ignite"] then
			if isnumber(filter["attacker"]["ignite"]) then
				timer.Simple( engine.TickInterval(), function() if IsValid(atkr) then atkr:Ignite( filter["attacker"]["ignite"] ) end end)
			else
				timer.Simple( engine.TickInterval(), function() if IsValid(atkr) then atkr:Fire("Ignite") end end)
			end
		end

		if filter["attacker"]["freeze"] != nil and isfunction(atkr.Freeze) then
			if isnumber(filter["attacker"]["freeze"]) then
				atkr:Freeze(true)
				timer.Simple( filter["attacker"]["freeze"], function() if IsValid(atkr) then atkr:Freeze(false) end end)
			else
				atkr:Freeze(filter["attacker"]["freeze"])
			end
		end

		if filter["attacker"]["drop_weapon"] then
			if isfunction( atkr.DropWeapon ) then
				atkr:DropWeapon()
			end
		end


		if filter["attacker"]["explode"] and !IsValid( atkr.npcd_explosion ) then
			ApplyValueTable( filter["attacker"]["explode"], t_value_structs["explode"].STRUCT )
			if filter["attacker"]["explode"]["enabled"] then
				local expos = atkr:GetPos() + atkr:OBBCenter()
				timer.Simple( engine.TickInterval(), function()
					atkr.npcd_explosion = Explode( atkr, filter["attacker"]["explode"], expos )
				end )
			end
		end

		if filter["attacker"]["reflect"] then
			local d = DamageInfo()
			d:SetAttacker( victim )
			d:SetReportedPosition( atkr:GetPos() )
			d:SetDamagePosition( atkr:GetPos() )
			d:SetDamage( dmg:GetDamage() * filter["attacker"]["reflect"] )
			d:SetDamageType( dmg:GetDamageType() )
			timer.Simple( engine.TickInterval(), function() if IsValid(atkr) then atkr:TakeDamageInfo(d) end end)
		end

		if filter["attacker"]["resetregen"] and ntbl then
			ntbl.nextregen = CurTime() + ( SetTmpEntValues( {}, nil, ntbl.npc_t, "regendelay", GetLookup( "regendelay", ntbl.npc_t.entity_type, nil, GetPresetName( ntbl.npc_t.classname ) ) ) or 0 )
		end

		if filter["attacker"]["heal"] then
			local healed = istable( filter["attacker"]["heal"] ) and filter["attacker"]["heal"]["f"]
				and ( atkr:GetMaxHealth() * filter["attacker"]["heal"]["f"] )
				or isnumber( filter["attacker"]["heal"] ) and filter["attacker"]["heal"]

			if ntbl then
				ntbl.healthfrac = ntbl.healthfrac + healed
			else
				atkr:SetHealth( math.min( atkr:Health() + healed, atkr:GetMaxHealth() ) )
				if atkr:Health() <= 0 then
					timer.Simple( engine.TickInterval(), function() if IsValid(atkr) then atkr:TakeDamage( 0 ) end end )
				end
			end
		end

		if filter["attacker"]["healarmor"] and atkr:IsPlayer() then
			local healed = istable( filter["attacker"]["healarmor"] ) and filter["attacker"]["healarmor"]["f"]
				and ( atkr:GetMaxArmor() * filter["attacker"]["healarmor"]["f"] )
				or isnumber( filter["attacker"]["healarmor"] ) and filter["attacker"]["healarmor"]

			atkr:SetArmor( math.min( atkr:Armor() + healed, atkr:GetMaxArmor() ) )
		end

		if filter["attacker"]["leech"] and filter["attacker"]["leech"] != 0 then
			local le = math.Clamp( dmg:GetDamage(), 0, victim:GetMaxHealth() * 2 ) * filter["attacker"]["leech"]
			local le = math.Clamp( dmg:GetDamage(), 0, victim:GetMaxHealth() * 2 ) * filter["attacker"]["leech"]
			if ntbl then
				ntbl.healthfrac = ntbl.healthfrac + le
			else
				atkr:SetHealth( math.min( atkr:Health() + le, atkr:GetMaxHealth() ) )
				if atkr:Health() <= 0 then
					timer.Simple( engine.TickInterval(), function() if IsValid(atkr) then atkr:TakeDamage( 0 ) end end )
				end
			end
		end

		if filter["attacker"]["leecharmor"] and atkr:IsPlayer() and filter["attacker"]["leecharmor"] != 0 then
			local le = math.Clamp( dmg:GetDamage(), 0, victim:GetMaxHealth() * 2 ) * filter["attacker"]["leecharmor"]

			atkr:SetArmor( math.min( atkr:Armor() + le, atkr:GetMaxArmor() ) )
		end

		if filter["attacker"]["takedamage"] and filter["attacker"]["takedamage"] > 0 then
			timer.Simple( engine.TickInterval(), function() if IsValid(atkr) then atkr:TakeDamage( filter["attacker"]["takedamage"] ) end end )
		end

		if filter["attacker"]["effects"] then
			for _, eff_t in pairs( filter["attacker"]["effects"] ) do
				CreateEffect( eff_t, atkr, atkr:GetPos() )
			end
		end
		
		if filter["attacker"]["scale_mult"] then
			if atkr:GetModelScale() != nil then
				if filter["attacker"]["scale_mult"] < 1 and atkr:GetModelScale() * filter["attacker"]["scale_mult"] < 0.09 then
					atkr:SetHealth( -1 )
					timer.Simple( engine.TickInterval(), function() if IsValid(atkr) then atkr:TakeDamage( atkr:GetMaxHealth() ) end end)
				else
					atkr:SetModelScale( atkr:GetModelScale() * filter["attacker"]["scale_mult"], 0.1 )
					-- if not ( atkr:IsNPC() or atkr:IsNextBot() or atkr:IsPlayer() ) then
					-- 	atkr:Activate()
					-- end
				end
			end
		end

		if filter["attacker"]["jigglify"] then
			for i=1,atkr:GetBoneCount() do
				atkr:ManipulateBoneJiggle(i, 1)
			end
		end

		if filter["attacker"]["bones"] then
			ApplyBonechart( atkr, filter["attacker"]["bones"] )
		end

		if filter["attacker"]["instakill"] then
			atkr:SetHealth( -1 )
			timer.Simple( engine.TickInterval(), function() if IsValid(atkr) then atkr:TakeDamage( atkr:GetMaxHealth() ) end end )
		end

		if filter["attacker"]["remove"] then
			if atkr:IsPlayer() then
				atkr:SetHealth( -1 )
				timer.Simple( engine.TickInterval(), function() if IsValid(atkr) then atkr:TakeDamage( atkr:GetMaxHealth() ) end end )
			elseif !atkr:IsWorld() then
				atkr:Remove()
			end
		end

		if filter["attacker"]["drop_set"] then
			DoDropSetNormal( atkr, filter["attacker"]["drop_set"], ntbl )
		end
		if filter["attacker"]["damage_drop_set"] then
			DoDamageFilterDropSet( atkr, dmg, filter["attacker"]["damage_drop_set"], ntbl )
		end

		// should i
		// i should
		if filter["attacker"]["apply_preset"] and filter["attacker"]["apply_preset"]["name"] and filter["attacker"]["apply_preset"]["type"] and IsEntity( atkr ) and !atkr:IsWorld() then
			local preset_type = filter["attacker"]["apply_preset"]["type"]
			local preset_name = filter["attacker"]["apply_preset"]["name"]

			if dmgf_type_chk[preset_type]( atkr ) and ( !ntbl or ( ntbl and not ( ntbl["npcpreset"] == preset_name and ntbl["npc_t"]["entity_type"] == preset_type ) ) ) then
				timer.Simple( 0, function()
					OverrideEntity(
						atkr,
						ntbl,
						ntbl and ntbl["squad_t"],
						preset_type,
						preset_name,
						nil,
						{ ["activate"] = false, }
					)
				end )
			end
		end

		if filter["attacker"]["apply_values"] then
			local typ = ntbl and ntbl.npc_t.entity_type or atkr:IsNPC() and "npc" or atkr:IsNextBot() and "nextbot" or atkr:IsPlayer() and "player" or "entity"
			ApplyEntityValues( atkr, filter["attacker"]["apply_values"]["all"], ntbl, nil ) // all
			ApplyEntityValues( atkr, filter["attacker"]["apply_values"][typ], ntbl, typ )
		end

		if filter["attacker"]["change_squad"] then
			local antbl = IsValid(victim) and ( activeNPC[victim] or activePly[victim] )
			-- local ontbl = table.Copy( ntbl )
			if antbl and antbl["squad"] then
				AddToSquad( atkr, antbl["squad"] )
			end
			if ntbl then
				if ntbl["squad"] then
					RemoveFromSquad( atkr, ntbl["squad"] )
				end
				ntbl["squad_t"] = antbl and antbl["squad_t"] or { ["values"] = {} }
			end
			if isfunction( atkr.SetSquad ) and isfunction( victim.GetSquad ) and IsValid( victim:GetSquad() ) then atkr:SetSquad( victim:GetSquad() ) end
		end

		if filter["attacker"]["announce_death"] then
			timer.Simple( engine.TickInterval(), function() AnnounceDeath( atkr, ntbl, true ) end )
		end

		if filter["attacker"]["ent_funcs"] then
			CallEntityFunction( atkr, filter["attacker"]["ent_funcs"], lup_t.STRUCT.attacker.STRUCT.ent_funcs )
		end
	end

	// do stuff to victim
	if filter["victim"] then
		local ntbl = IsValid(victim) and ( activeNPC[victim] or activePly[victim] ) or nil

		ApplyValueTable( filter["victim"], lup_t.STRUCT["victim"].STRUCT )

		if filter["victim"]["setenemy"] and victim:IsNPC() then
			victim:SetEnemy( atkr )
		end
		if filter["victim"]["settarget"] and victim:IsNPC() then
			victim:SetTarget( atkr )
		end

		if filter["victim"]["resetregen"] and ntbl then
			ntbl.nextregen = CurTime() + ( SetTmpEntValues( {}, nil, ntbl.npc_t, "regendelay", GetLookup( "regendelay", ntbl.npc_t.entity_type, nil, GetPresetName( ntbl.npc_t.classname ) ) ) or 0 )
		end

		if filter["victim"]["heal"] then
			local healed = istable( filter["victim"]["heal"] ) and filter["victim"]["heal"]["f"]
				and ( victim:GetMaxHealth() * filter["victim"]["heal"]["f"] )
				or isnumber( filter["victim"]["heal"] ) and filter["victim"]["heal"]
			if ntbl then
				ntbl.healthfrac = ntbl.healthfrac + healed
			else
				victim:SetHealth( math.min( victim:Health() + healed, victim:GetMaxHealth() ) )
				-- if healed < 0 or victim:Health() <= 0 then
				-- timer.Simple( engine.TickInterval(), function() if IsValid(victim) then victim:TakeDamage( -1 ) end end) // is taking damage anyways
				-- end
			end
		end

		if filter["victim"]["healarmor"] and victim:IsPlayer() then
			local healed = istable( filter["victim"]["healarmor"] ) and filter["victim"]["healarmor"]["f"]
				and ( victim:GetMaxArmor() * filter["victim"]["healarmor"]["f"] )
				or isnumber( filter["victim"]["healarmor"] ) and filter["victim"]["healarmor"]

			victim:SetArmor( math.min( victim:Armor() + healed, victim:GetMaxArmor() ) )
		end

		if filter["victim"]["leech"] and filter["victim"]["leech"] != 0 then
			-- local le = math.Round( math.Clamp( dmg:GetDamage(), 0, victim:Health() ) * filter["victim"]["leech"] )
			local le = math.Clamp( dmg:GetDamage(), 0, victim:GetMaxHealth() * 2 ) * filter["victim"]["leech"]
			if ntbl then
				ntbl.healthfrac = ntbl.healthfrac + le
			else
				victim:SetHealth( math.min( victim:Health() + le, victim:GetMaxHealth() ) )
				if victim:Health() <= 0 then
					timer.Simple( engine.TickInterval(), function() if IsValid(victim) then victim:TakeDamage( 0 ) end end )
				end
			end
		end
		
		if filter["victim"]["takedamage"] and filter["victim"]["takedamage"] > 0 then
			timer.Simple( engine.TickInterval(), function() if IsValid(victim) then victim:TakeDamage( filter["victim"]["takedamage"] ) end end)
		end

		if filter["victim"]["ignite"] then
			if isnumber( filter["victim"]["ignite"] ) then
				timer.Simple( engine.TickInterval(), function() if IsValid(victim) then victim:Ignite( filter["victim"]["ignite"] ) end end)
			else
				timer.Simple( engine.TickInterval(), function() if IsValid(victim) then victim:Fire("Ignite") end end)
			end
		end

		if filter["victim"]["freeze"] != nil and isfunction(victim.Freeze) then
			if isnumber(filter["attacker"]["freeze"]) then
				victim:Freeze(true)
				timer.Simple( filter["attacker"]["freeze"], function() if IsValid(victim) then victim:Freeze(false) end end)
			else
				victim:Freeze(filter["attacker"]["freeze"])
			end
		end

		if filter["victim"]["drop_weapon"] then
			if isfunction( victim.DropWeapon ) then
				victim:DropWeapon()
			end
		end

		if filter["victim"]["explode"] and !IsValid( victim.npcd_explosion ) then
			ApplyValueTable( filter["victim"]["explode"], t_value_structs["explode"].STRUCT )
			if filter["victim"]["explode"]["enabled"] then
				local expos = victim:GetPos() + victim:OBBCenter()
				timer.Simple( engine.TickInterval(), function()
					victim.npcd_explosion = Explode( victim, filter["victim"]["explode"], expos )
				end)
			end
		end

		if filter["victim"]["scale_mult"] then
			if victim:GetModelScale() != nil then
				if filter["victim"]["scale_mult"] < 1 and victim:GetModelScale() * filter["victim"]["scale_mult"] < 0.09 then
					victim:SetHealth( -1 )
					timer.Simple( engine.TickInterval(), function() if IsValid(victim) then victim:TakeDamage( victim:GetMaxHealth() ) end end)
				else
					victim:SetModelScale( victim:GetModelScale() * filter["victim"]["scale_mult"], 0.1 )
				end
			end
		end
		
		if filter["victim"]["effects"] then
			for _, eff_t in pairs(filter["victim"]["effects"]) do
				CreateEffect( eff_t, victim, victim:GetPos() )
			end
		end

		if filter["victim"]["jigglify"] then
			for i=1,victim:GetBoneCount() do
				victim:ManipulateBoneJiggle(i, 1)
			end
		end

		if filter["victim"]["bones"] then
			ApplyBonechart( victim, filter["victim"]["bones"] )
		end

		if filter["victim"]["instakill"] then
			victim:SetHealth( -1 )
			timer.Simple( engine.TickInterval(), function() if IsValid(victim) then victim:TakeDamage( victim:GetMaxHealth() ) end end )
		end

		if filter["victim"]["remove"] then
			if victim:IsPlayer() then
				victim:SetHealth( -1 )
				timer.Simple( engine.TickInterval(), function() if IsValid(victim) then victim:TakeDamage( victim:GetMaxHealth() ) end end )
			elseif !victim:IsWorld() then
				victim:Remove()
			end
		end

		if filter["victim"]["drop_set"] then
			DoDropSetNormal( victim, filter["victim"]["drop_set"], ntbl )
		end
		if filter["victim"]["damage_drop_set"] then
			DoDamageFilterDropSet( victim, dmg, filter["victim"]["damage_drop_set"], ntbl )
		end

		if filter["victim"]["apply_preset"] and filter["victim"]["apply_preset"]["name"] and filter["victim"]["apply_preset"]["type"]
		and ( IsEntity( victim ) and !victim:IsWorld() ) then
			local preset_type = filter["victim"]["apply_preset"]["type"]
			local preset_name = filter["victim"]["apply_preset"]["name"]

			if dmgf_type_chk[preset_type]( victim ) and ( !ntbl or ( ntbl and not ( ntbl["npcpreset"] == preset_name and ntbl["npc_t"]["entity_type"] == preset_type ) ) ) then
				timer.Simple( 0, function()
					OverrideEntity(
						victim,
						ntbl,
						ntbl and ntbl["squad_t"],
						preset_type,
						preset_name,
						nil,
						{ ["activate"] = false, }
					)
				end )
			end
		end

		if filter["victim"]["apply_values"] then
			local typ = ntbl and ntbl.npc_t.entity_type or victim:IsNPC() and "npc" or victim:IsNextBot() and "nextbot" or victim:IsPlayer() and "player" or "entity"
			ApplyEntityValues( victim, filter["victim"]["apply_values"]["all"], ntbl, nil ) // all
			ApplyEntityValues( victim, filter["victim"]["apply_values"][typ], ntbl, typ )
		end

		if filter["victim"]["change_squad"] then
			local antbl = IsValid(atkr) and ( activeNPC[atkr] or activePly[atkr] )
			-- local ontbl = table.Copy( ntbl )
			if antbl and antbl["squad"] then
				AddToSquad( victim, antbl["squad"] )
			end
			if ntbl then 
				if ntbl["squad"] then
					RemoveFromSquad( victim, ntbl["squad"] )
				end
				ntbl["squad_t"] = antbl and antbl["squad_t"] or { ["values"] = {} }
			end
			if isfunction( victim.SetSquad ) and isfunction( atkr.GetSquad ) and IsValid( atkr:GetSquad() ) then victim:SetSquad( atkr:GetSquad() ) end
		end
		if filter["victim"]["announce_death"] then
			timer.Simple( engine.TickInterval(), function() AnnounceDeath( victim, ntbl, true ) end )
		end

		if filter["victim"]["ent_funcs"] then
			CallEntityFunction( victim, filter["victim"]["ent_funcs"], lup_t.STRUCT.victim.STRUCT.ent_funcs )
		end

	end

	if apply and IsValid( victim ) then victim:TakeDamageInfo( dmg ) end // do not use in TakeDamage hook!!

	afilter["count"] = ( afilter["count"] or 0 ) + 1

	if filter["continue"] == true then
		return false
	else
		return valid
	end
end

hook.Add("EntityTakeDamage", "NPCD Damage", function( ent, dmg )
	local atkr = dmg:GetAttacker()

	// npcd attacks (outgoing)
	if activeNPC[atkr] or activePly[atkr] then

		local npc_t = activeNPC[atkr] and activeNPC[atkr]["npc_t"] or activePly[atkr] and activePly[atkr]["npc_t"]
		if npc_t.damagescale_out then dmg:ScaleDamage( npc_t.damagescale_out ) end

		if npc_t.velocity_out then
			local s = atkr:GetVelocity():Length() - npc_t.velocity_out.minspeed
			if npc_t.velocity_out.exponent then
				s = math.pow( s, npc_t.velocity_out.exponent )
			end
			local f = math.max( 0, s / npc_t.velocity_out.ratio )
			if npc_t.velocity_out.increase then
				dmg:ScaleDamage( 1 + f )
			else
				dmg:ScaleDamage( 1 / ( 1 + f ) )
			end
		end

		if npc_t["damagefilter_out"] then
			ApplyDamageFilters( dmg, npc_t["damagefilter_out"], atkr, ent )
		end
	end

	// npcd damaged (incoming)
	if activeNPC[ent] or activePly[ent] then
		local ntbl = activeNPC[ent] or activePly[ent]
		local npc_t = ntbl and ntbl["npc_t"]

		if ntbl["seekout"]
		and ( ntbl["sched"] and ent:IsCurrentSchedule( ntbl["sched"] ) )
		and npc_t["seekout_clear_dmg"] then
			ClearScheduleDiligent( ent, ntbl )
			ntbl["lastidle"] = nil
		-- elseif debugged_chase and ntbl["seekout"] then
		-- 	print( "SEEKOUT TOOK DMG, NO CLEAR.", ent, "onseekout", ntbl["seekout"], "chasesched", GetScheduleName( ntbl["sched"] ), "sched", GetScheduleName( GetNPCSchedule( ent ) ) )
		end

	
		if ent:IsNPC() and IsCharacter( atkr ) and !friend_disp[ent:Disposition(atkr)] then
			if npc_t.dmg_setenemy then
				ent:SetEnemy( atkr )
			end
			if npc_t.dmg_settarget then
				ent:SetTarget( atkr )
			end
			if npc_t.dmg_setchase then
				ntbl["chasing"] = atkr
				ntbl["sched_startpos"] = nil
			end
		end
		
		if npc_t.damagescale_in then dmg:ScaleDamage( npc_t.damagescale_in ) end

		if npc_t.velocity_in then
			local s = ent:GetVelocity():Length() - npc_t.velocity_in.minspeed
			if npc_t.velocity_in.exponent then
				s = math.pow( s, npc_t.velocity_in.exponent )
			end
			local f = math.max( 0, s / npc_t.velocity_in.ratio )
			if npc_t.velocity_in.increase then
				dmg:ScaleDamage( 1 + f )
			else
				dmg:ScaleDamage( 1 / ( 1 + f ) )
			end
		end
		
		if atkr then
			if npc_t["damagefilter_in"] then
				ApplyDamageFilters( dmg, npc_t["damagefilter_in"], atkr, ent )
			end

			if npc_t.damage_drop_set then
				local lup_t = GetLookup( "damage_drop_set", npc_t.entity_type, vn, GetPresetName( npc_t.classname ) )
				for k, d_t in pairs( npc_t.damage_drop_set ) do
					d_t["count"] = d_t["count"] or 0
					local drops = table.Copy( d_t )

					ApplyValueTable( drops, lup_t.STRUCT )

					if !drops.drop_set or !drops.drop_set["name"] then
						continue
					end

					if drops.max and drops.count >= drops.max then
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
					local pos = ent:GetPos() + ( ent:OBBCenter() * 0.33 )
					local ang = ent:GetAngles()

					if math.random() < chance then
						if Settings.drop_set[ drops.drop_set["name"] ] then
							AddDropQueue( ent, pos, ang, Settings.drop_set[ drops.drop_set["name"] ], ntbl )
							d_t["count"] = d_t["count"] + 1
						end
					end

					if drops.multidrop_dmg then
						for i=drops.multidrop_dmg,math.min( dmg:GetDamage(), ent:Health() ),math.max(1,drops.multidrop_dmg) do
							if math.random() < chance then
								if Settings.drop_set[ drops.drop_set["name"] ] then
									AddDropQueue( ent, pos, ang, Settings.drop_set[ drops.drop_set["name"] ], ntbl )
									d_t["count"] = d_t["count"] + 1
								end
							end
						end
					end

				end
			end
		end

		// volatile/ignite
      local ignited
		if npc_t.volatile and atkr:GetClass() != "entityflame" then
			if npc_t.volatile.enabled then
				if npc_t.volatile.threshold_shot and npc_t.volatile.threshold_shot > 0 then
					if dmg:GetDamage() >= npc_t.volatile.threshold_shot then
						if npc_t.volatile.duration != nil then
							ent:Ignite( npc_t.volatile.duration )
						else
							ent:Fire("Ignite")
						end
                  ignited = true
					end
				end
				if !ignited and npc_t.volatile.threshold_total and npc_t.volatile.threshold_total > 0 then
					-- if ent:GetMaxHealth() - ent:Health() > npc_t.volatile.threshold_total
               if dmg:GetDamage() > npc_t.volatile.threshold_total
               or damageTakenTotals[ent] and damageTakenTotals[ent] + dmg:GetDamage() > npc_t.volatile.threshold_total then
						if npc_t.volatile.duration != nil then
							ent:Ignite( npc_t.volatile.duration )
						else
							ent:Fire("Ignite")
						end
					end
				end
			end
		end
	end

	// player attacks non-friendly npc
	if atkr:IsPlayer() then
		if activeNPC[ent] or ( ent:IsNPC() and ent:Disposition( atkr ) != D_LI ) or ent:IsNextBot() then
			local add = v_stress.stress_ply_outbase * math.Clamp( dmg:GetDamage(), 0, math.max( ent:Health(), 0 ) ) * stress_activemult
			if activeNPC[ent] and activeNPC[ent]["npc_t"]["stress_mult"] then
				add = add * activeNPC[ent]["npc_t"]["stress_mult"]
			end
			atkr.npcd_stress = math.Clamp(atkr.npcd_stress + add, 0, 1)
			if debugged_stress then print( "ply atkr", add, atkr.npcd_stress, math.Clamp( dmg:GetDamage(), 0, math.max( ent:Health(), 0 ) ), dmg:GetDamage(), ent, atkr ) end
		end
	end

	// player damaged
	if ent:IsPlayer() then
		local atkrmult = activeNPC[atkr] and activeNPC[atkr]["npc_t"]["stress_mult"] or 1
		local add = v_stress.stress_ply_incbase * math.Clamp( dmg:GetDamage(), 0, math.max( ent:Health(), 0 ) ) * stress_activemult * atkrmult
		if atkr == ent then
			add = add * v_stress.stress_ply_selfmult
		end
		ent.npcd_stress = math.min( ent.npcd_stress + add, 1 )
		if debugged_stress then print( "ply damaged", add, ent.npcd_stress, math.Clamp( dmg:GetDamage(), 0, math.max( ent:Health(), 0 ) ), dmg:GetDamage(), ent, atkr ) end
	end

	-- if modelfixes[ent:GetClass()] and isfunction( ent.GetActiveWeapon ) and IsValid( ent:GetActiveWeapon() )
	-- and modelfixes[ent:GetClass()] != ent:GetModel() and dmg:GetDamage() > ent:Health() then
		-- local olddmg = {
			-- AmmoType = dmg:GetAmmoType(),
			-- Attacker = dmg:GetAttacker(),
			-- BaseDamage = dmg:GetBaseDamage(),
			-- Damage = dmg:GetDamage(),
			-- DamageBonus = dmg:GetDamageBonus(),
			-- DamageCustom = dmg:GetDamageCustom(),
			-- DamageForce = dmg:GetDamageForce(),
			-- DamagePosition = dmg:GetDamagePosition(),
			-- DamageType = dmg:GetDamageType(),
			-- Inflictor = dmg:GetInflictor(),
			-- MaxDamage = dmg:GetMaxDamage(),
			-- ReportedPosition = dmg:GetReportedPosition()
		-- }
		-- local oldhealth = ent:Health()
		-- dmg:SetDamage( 0 )
		-- ent:SetHealth( math.max( 1, ent:Health() ) )
		-- ent:SetModel( modelfixes[ent:GetClass()] )
		-- timer.Simple( engine.TickInterval(), function() 
			-- if IsValid( ent ) then
				-- if ent:Health() > oldhealth then ent:SetHealth( oldhealth ) end
				-- local d = DamageInfo()
				-- d:SetAmmoType( olddmg.AmmoType )
				-- d:SetAttacker( olddmg.Attacker )
				-- d:SetBaseDamage( olddmg.BaseDamage )
				-- d:SetDamage( olddmg.Damage )
				-- d:SetDamageBonus( olddmg.DamageBonus )
				-- d:SetDamageCustom( olddmg.DamageCustom )
				-- d:SetDamageForce( olddmg.DamageForce )
				-- d:SetDamagePosition( olddmg.DamagePosition )
				-- d:SetDamageType( olddmg.DamageType )
				-- d:SetInflictor( olddmg.Inflictor )
				-- d:SetMaxDamage( olddmg.MaxDamage )
				-- d:SetReportedPosition( olddmg.ReportedPosition )
				-- ent:TakeDamageInfo( d )
			-- end
		-- end )
	-- end
end)

function HitBoxFilterCheck( hitgroup, hbtbl )
	local valid = true

	if hbtbl.hitgroups then
		ApplyValueTable( hbtbl.hitgroups, t_value_structs["damagefilter_hitbox"].STRUCT["hitgroups"].STRUCT )

		if hbtbl.hitgroups["include"] and !table.IsEmpty( hbtbl.hitgroups["include"] ) then
			valid = false
			for _, v in pairs( hbtbl.hitgroups["include"] ) do
				if hitgroup == v then
					valid = true
					break
				end
			end
		end

		if valid and hbtbl.hitgroups["exclude"] and !table.IsEmpty( hbtbl.hitgroups["exclude"] ) then
			for _, v in pairs( hbtbl.hitgroups["exclude"] ) do
				if hitgroup == v then
					valid = false
					break
				end
			end
		end
	end

	return valid	
end

function HitgroupHook( ent, hitgroup, dmg )
	local atkr = dmg:GetAttacker()

	// outgoing
	if activeNPC[atkr] or activePly[atkr] then
		local ntbl = activeNPC[atkr] or activePly[atkr]
		if ntbl.npc_t.damagefilter_hitbox_out then
			for _, hbtbl in pairs( ntbl.npc_t.damagefilter_hitbox_out ) do
				ApplyValueTable( hbtbl, t_value_structs["damagefilter_hitbox"].STRUCT )
				//hitbox check and apply filters
				if hbtbl.damagefilter and HitBoxFilterCheck( hitgroup, hbtbl ) then
					ApplyDamageFilters( dmg, hbtbl.damagefilter, atkr, ent )
				end
			end
		end
	end

	// incoming
	if activeNPC[ent] or activePly[ent] then
		local ntbl = activeNPC[ent] or activePly[ent]
		if ntbl.npc_t.damagefilter_hitbox_in then
			for _, hbtbl in pairs( ntbl.npc_t.damagefilter_hitbox_in ) do
				ApplyValueTable( hbtbl, t_value_structs["damagefilter_hitbox"].STRUCT )
				//hitbox check and apply filters
				if hbtbl.damagefilter and HitBoxFilterCheck( hitgroup, hbtbl ) then
					ApplyDamageFilters( dmg, hbtbl.damagefilter, atkr, ent )
				end
			end
		end
	end
end

hook.Add("ScaleNPCDamage", "NPCD NPC Hitgroup", function( ent, hitgroup, dmg )
	HitgroupHook( ent, hitgroup, dmg )
end )
hook.Add("ScalePlayerDamage", "NPCD Player Hitgroup", function( ent, hitgroup, dmg )
	HitgroupHook( ent, hitgroup, dmg )
end )

hook.Add("PostEntityTakeDamage", "NPCD Post-Damage", function( ent, dmgInfo, took )
	if !IsValid(ent) then return end

	local atkr = dmgInfo:GetAttacker()
	local ent = ent
	-- local dmg = dmg
	local dmg = CopyDamageInfo(dmgInfo)
	local took = took

   if took then
      damageTakenTotals[ent] = (damageTakenTotals[ent] or 0) + dmg:GetDamage()

      // yippee
      damageTakenTable[ent] = damageTakenTable[ent] or {}
      local time = math.Round(CurTime(),1)
      damageTakenTable[ent][time] = (damageTakenTable[ent][time] or 0) + dmg:GetDamage()
   end

	timer.Simple( engine.TickInterval(), function()
		if IsValid( atkr ) and ( activeNPC[atkr] or activePly[atkr] ) then
			local ntbl = activeNPC[atkr] or activePly[atkr]
			if ntbl.npc_t.damagefilter_post_out then
				ApplyDamageFilters( dmg, ntbl.npc_t.damagefilter_post_out, atkr, ent, nil, nil, took )
			end
		end
		
		if IsValid( ent ) and ( activeNPC[ent] or activePly[ent] ) then
			local ntbl = activeNPC[ent] or activePly[ent]
			if ntbl.npc_t.damagefilter_post_in then
				ApplyDamageFilters( dmg, ntbl.npc_t.damagefilter_post_in, atkr, ent, nil, nil, took )
			end

			if ntbl.npc_t.postdamage_drop_set then
				local lup_t = GetLookup( "postdamage_drop_set", ntbl.npc_t.entity_type, vn, GetPresetName( ntbl.npc_t.classname ) )
				for k, d_t in pairs( ntbl.npc_t.postdamage_drop_set ) do
					d_t["count"] = d_t["count"] or 0
					local drops = table.Copy( d_t )

					ApplyValueTable( drops, lup_t.STRUCT )

					if !took and !drops.ignore_took then
						continue
					end

					if !drops.drop_set or !drops.drop_set["name"] then
						continue
					end

					if drops.max and drops.count >= drops.max then
						continue
					end

					if drops.health_lesser then
						if istable( drops.health_lesser ) and drops.health_lesser["f"] and ( ent:Health() / ent:GetMaxHealth() ) > drops.health_lesser["f"]
						or !istable( drops.health_lesser ) and ( ent:Health() ) > drops.health_lesser then
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
					local pos = ent:GetPos() + ( ent:OBBCenter() * 0.33 )
					local ang = ent:GetAngles()

					if math.random() < chance then
						if Settings.drop_set[ drops.drop_set["name"] ] then
							AddDropQueue( ent, pos, ang, Settings.drop_set[ drops.drop_set["name"] ], ntbl )
							d_t["count"] = d_t["count"] + 1
						end
					end

					if drops.multidrop_dmg then
						for i=drops.multidrop_dmg,math.min( dmg:GetDamage(), ent:Health() ),drops.multidrop_dmg do
							if math.random() < chance then
								if Settings.drop_set[ drops.drop_set["name"] ] then
									AddDropQueue( ent, pos, ang, Settings.drop_set[ drops.drop_set["name"] ], ntbl )
									d_t["count"] = d_t["count"] + 1
								end
							end
						end
					end

				end
			end
		end
	end )

	// triggers post-death for entities/nextbots
	// but not npc and players because those are handled in their own hooks
	if activeNPC[ent] and !ent:IsNPC() and !ent:IsPlayer() and !ent:NotDead() then
		NPCKilled( ent, dmg:GetAttacker() )
	end

end)

// physics collisions callback
function EntRamming( ent, data )
	if !IsValid(ent) or !data or !IsEntity(data.HitEntity) or data.HitEntity == game.GetWorld()
	or !activeCollide[ent] then
		return
	end
	
	local npc_t = activeCollide[ent]

	local physcollides = table.Copy( npc_t["physcollide"] )
	
	local lup_t = GetLookup( "physcollide", npc_t.entity_type, nil, GetPresetName( npc_t.classname ) )

	for k, ram_t in pairs( physcollides ) do
		ApplyValueTable( ram_t, lup_t.STRUCT, ent )

		local hitent = data.HitEntity

		//checks
		-- if data.DeltaTime < (ram_t.delay_min or 0.24) then return end
		if ram_t.next and CurTime() < ram_t.next then continue end

		local speed = data.OurOldVelocity:Length()
		if speed < ( ram_t.speed_min or 0 ) then continue end

		local d = DamageInfo()
		d:SetDamageType( ram_t.damage_type or DMG_VEHICLE ) -- or DMG_CLUB

		// set damage
		if ram_t.flat_damage then
			d:SetDamage( ram_t.flat_damage )
		else
			d:SetDamage( math.pow( speed - ram_t.speed_min , ram_t.speed_exp or 1) * (ram_t.damage_scale or 0.0025) )
		end
		-- d:SetDamageForce( data.OurOldVelocity * 1000 )

		-- print( "ram", speed, ram_t.speed_min, ram_t.speed_exp, ram_t.damage_scale )
		-- print( "dmg", d:GetDamage() )

		d:SetAttacker( ent )
		d:SetDamagePosition( data.HitPos )
		d:SetReportedPosition( ent:GetPos() )
		if ram_t.effects then
			for _, eff_t in pairs( ram_t.effects ) do
				CreateEffect( eff_t, nil, data.HitPos )
			end
		end

		if ram_t.impact_radius and ram_t.impact_radius > 0 then 
			for _, radent in ipairs( ents.FindInSphere( data.HitPos, ram_t.impact_radius ) ) do
				if !IsValid( radent ) then continue end
				
				if radent != ent and radent != hitent and radent:IsSolid()
				and ( ram_t.npc_only == nil or ram_t.npc_only == true and dmgf_type_chk["character"]( radent ) or ram_t.npc_only == false and !dmgf_type_chk["character"]( radent ) ) then

					local radialramv = (radent:GetPos() - data.HitPos):GetNormalized() * speed * ( ram_t.newvelocity_mult or 1 )
					if !ram_t.no_impact then
						radent:SetVelocity( radialramv + Vector( 0, 0, 251 ) )
						d:SetDamageForce( radialramv * 100 )
					end
					-- radent:SetLocalAngularVelocity( radent:GetLocalAngularVelocity() + data.OurOldAngularVelocity )

					// damage filter
					if ram_t.damagefilter_out and !ram_t.filter_onlyimpact then
						// apply to each and restore afterward because it's shared
						ApplyDamageFilters( d, ram_t.damagefilter_out, ent, radent, ram_t.no_zero and d:GetDamage() > 0 or !ram_t.no_zero, true )
					end
				end
			end			
		end
		
		if ram_t.npc_only == nil or ram_t.npc_only == true and dmgf_type_chk["character"]( hitent ) or ram_t.npc_only == false and !dmgf_type_chk["character"]( hitent ) then
			local ramv = data.OurOldVelocity * ( ram_t.newvelocity_mult or 1 )
			if !ram_t.no_impact then
				d:SetDamageForce( ramv * 100 )
				hitent:SetVelocity( data.TheirNewVelocity + ramv + Vector( 0, 0, 251 ) )
			end
			-- hitent:SetLocalAngularVelocity( (data.TheirOldAngularVelocity + data.OurOldAngularVelocity) * 1.1 )

			// damage filter
			if ram_t.damagefilter_out then
				ApplyDamageFilters( d, ram_t.damagefilter_out, ent, hitent ) // apply dmg
			end
			if ram_t.no_zero and d:GetDamage() > 0 or !ram_t.no_zero then hitent:TakeDamageInfo( d ) end
		end

		// set delay on the original table
		npc_t["physcollide"][k].next = CurTime() + ( ram_t.mindelay or 0.24 )
	end
end