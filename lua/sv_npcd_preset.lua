// preset stuff

module( "npcd", package.seeall )

// validate and add preset to given profile
function CreatePreset( typ, preset_name, args_t, profilename, onlyReturn, insert, displayprofname, loading )
	// insert: for tables outside of Profiles or Settings (e.g. newSettings, LoadProfile)
	// if insert is given then profilename shouldn't be given

	if debugged then print("npcd > CreatePreset(", typ, preset_name, args_t, onlyReturn, profilename, insert, displayprofname, loading,")" ) end

	if !typ then
		if debugged then print("npcd > CreatePreset > No type!") end
		return
	end

	local pname = profilename or currentProfile
	if insert != nil and profilename == nil then pname = nil end

	local prof = insert or Profiles[pname]
	if prof == nil and !onlyReturn then
		Error("\nError: npcd > CreatePreset > Profile ",pname," does not exist\n\n")
		return nil, "Profile does not exist: "..( displayprofname or pname or profilename or tostring(insert) )
	end

	if !prof[typ] then
		print("npcd > CreatePreset > " .. ( displayprofname or pname or profilename or tostring(insert) ) .. ": INVALID PRESET \"" .. tostring(preset_name) .. "\": Missing/invalid preset type: " .. typ )
		return nil, "Missing/invalid preset type: " .. tostring( typ )
	end
	
	local insTable = args_t
	local insvalues1 = {}

	// patching
	PresetPatches( typ, preset_name, insTable, profilename, onlyReturn, insert, displayprofname )

	// defaults and invalid values
	for k, baseValTbl in pairs(t_lookup[typ]) do
		if baseValTbl.CLEAR then
			insTable[k] = nil
		end
		insvalues1[k] = true
		if insTable[k] == nil then
			if baseValTbl.DEFAULT != nil and baseValTbl.DEFAULT_SAVE then
				insTable[k] = CopyData( baseValTbl.DEFAULT )
			elseif baseValTbl.REQUIRED == true and baseValTbl.DEFAULT == nil then // required but no value
				print("npcd > CreatePreset > " .. ( displayprofname or pname or profilename or tostring(insert) ) .. ": INVALID PRESET \"" .. tostring(preset_name) .. "\": Missing required value: " .. tostring(k) )
				return nil, "Missing required value: " .. tostring(k)
			end
		end
	end
	
	// class defaults and invalid values
	if t_lookup["class"][typ] and GetPresetName( insTable["classname"] ) and t_lookup["class"][typ][ GetPresetName( insTable["classname"] ) ] then
		for k, baseValTbl in pairs(t_lookup["class"][typ][ GetPresetName( insTable["classname"] ) ]) do
			if baseValTbl.CLEAR then
				insTable[k] = nil
			end
			insvalues1[k] = true
			if insTable[k] == nil then
				if baseValTbl.DEFAULT != nil and baseValTbl.DEFAULT_SAVE then
					insTable[k] = CopyData( baseValTbl.DEFAULT )
				elseif baseValTbl.REQUIRED == true and baseValTbl.DEFAULT == nil then // required but no value
					print("npcd > CreatePreset > " .. ( displayprofname or pname or profilename or tostring(insert) ) .. ": INVALID PRESET \"" .. tostring(preset_name) .. "\": Missing required value: " .. tostring(k) )
					return nil, "Missing required value: " .. tostring(k)
				end
			end
		end
	end

	if insTable["VERSION"] != NPCD_VERSION then
		if insTable["VERSION"] and preset_updatecount then
			-- print( "npcd > CreatePreset > " .. ( displayprofname or pname or profilename or tostring(insert) ) .. " > " .. typ .. " > ".. preset_name .. " has been updated to version "..NPCD_VERSION )
			preset_updatecount = preset_updatecount + 1
		end
		insTable["VERSION"] = NPCD_VERSION		
	end

	// todo: more universal version of all this

	// for each weapon in set add default values
	if typ == "weapon_set" then
		if insTable["weapons"] then
			for wepkey, weptbl in pairs(insTable["weapons"]) do
				local insvalues2 = {}
				// defaults, invalids
				for k, baseValTbl in pairs( t_lookup["weapon"] ) do
					if baseValTbl.CLEAR then
						weptbl[k] = nil
					end
					insvalues2[k] = true
					if weptbl[k] == nil then
						if baseValTbl.DEFAULT != nil and baseValTbl.DEFAULT_SAVE then
							weptbl[k] = CopyData( baseValTbl.DEFAULT )
						-- elseif baseValTbl.REQUIRED == true and baseValTbl.DEFAULT == nil then // required but no value
						-- 	print("npcd > CreatePreset > INVALID PRESET \"" .. tostring(preset_name) .. "\": Missing required value: " .. tostring(k) )
						-- 	return nil, "Missing required value: " .. tostring(k)
						end
					end
					-- if weptbl[k] == nil and baseValTbl.DEFAULT then
					-- 	if istable(baseValTbl.DEFAULT) then
					-- 		weptbl[k] = table.Copy(baseValTbl.DEFAULT)
					-- 	else
					-- 		weptbl[k] = baseValTbl.DEFAULT
					-- 	end
					-- end
					-- if baseValTbl.REQUIRED == true and baseValTbl.DEFAULT == nil then // required but no value
					-- 	print("npcd > CreatePreset > INVALID PRESET \"" .. tostring(preset_name) .. "\": Missing required value: " .. tostring(k) )
					-- 	return nil, "Missing required value: weapons["..wepkey.."] > " .. tostring(k)
					-- end
				end
				for k, v in pairs( weptbl ) do
					if !insvalues2[k] then
						-- print( "npcd > CreatePreset > "..preset_name.." key \""..tostring(k).."\" in insTable.weapons["..wepkey.."] was removed, doesn't exist in lookup" )
						print( "Error: npcd > CreatePreset > " .. ( displayprofname or pname or profilename or tostring(insert) ) .. ": "..preset_name.." key \""..tostring(k).."\" in "..typ..".weapons["..wepkey.."] doesn't exist in lookup, you may have to manually edit the profile file." )
						-- weptbl[k] = nil
					end
				end
			end
		end
	elseif typ == "squad" then
		if ( !pname or pname == currentProfile ) then
			squad_times[preset_name] = nil
		end
	elseif typ == "squadpool" then
		if ( !pname or pname == currentProfile ) then
			pool_times[preset_name] = nil
		end
		if insTable["spawns"] then
			for i, tbl in pairs(insTable["spawns"]) do
				local insvalues2 = {}
				// defaults, invalids
				for k, baseValTbl in pairs( t_lookup.squadpool["spawns"].STRUCT ) do
					if baseValTbl.CLEAR then
						tbl[k] = nil
					end
					insvalues2[k] = true
					if tbl[k] == nil then
						if baseValTbl.DEFAULT != nil and baseValTbl.DEFAULT_SAVE then
							tbl[k] = CopyData( baseValTbl.DEFAULT )
						end
					end
				end
				for k, v in pairs( tbl ) do
					if !insvalues2[k] then
						print( "Error: npcd > CreatePreset > " .. ( displayprofname or pname or profilename or tostring(insert) ) .. ": "..preset_name.." key \""..tostring(k).."\" in "..typ..".spawns["..i.."] doesn't exist in lookup, you may have to manually edit the profile file." )
					end
				end
			end
		end
	// for each drop
	elseif typ == "drop_set" then
		if insTable["drops"] then
			for i, tbl in pairs(insTable["drops"]) do
				local insvalues2 = {}
				// defaults, invalids
				for k, baseValTbl in pairs(t_lookup["drop"]) do
					if baseValTbl.CLEAR then
						tbl[k] = nil
					end
					insvalues2[k] = true
					if tbl[k] == nil then
						if baseValTbl.DEFAULT != nil and baseValTbl.DEFAULT_SAVE then
							tbl[k] = CopyData( baseValTbl.DEFAULT )
						-- elseif baseValTbl.REQUIRED == true and baseValTbl.DEFAULT == nil then // required but no value
						-- 	print("npcd > CreatePreset > INVALID PRESET \"" .. tostring(preset_name) .. "\": Missing required value: " .. tostring(k) )
						-- 	return nil, "Missing required value: " .. tostring(k)
						end
					end
					-- if tbl[k] == nil and baseValTbl.DEFAULT then
					-- 	if istable(baseValTbl.DEFAULT) then
					-- 		tbl[k] = table.Copy(baseValTbl.DEFAULT)
					-- 	else
					-- 		tbl[k] = baseValTbl.DEFAULT
					-- 	end
					-- end
					-- if baseValTbl.REQUIRED == true and baseValTbl.DEFAULT == nil then // required but no value
					-- 	print("npcd > CreatePreset > INVALID PRESET \"" .. tostring(preset_name) .. "\": Missing required value: " .. tostring(k) )
					-- 	return nil, "Missing required value: drops["..i.."] > " .. tostring(k)
					-- end
				end
				for k, v in pairs( tbl ) do
					if !insvalues2[k] then
						-- print( "npcd > CreatePreset > "..preset_name.." key \""..tostring(k).."\" in insTable.drops["..i.."] was removed, doesn't exist in lookup" )
						print( "Error: npcd > CreatePreset > " .. ( displayprofname or pname or profilename or tostring(insert) ) .. ": "..preset_name.." key \""..tostring(k).."\" in "..typ..".drops["..i.."] doesn't exist in lookup, you may have to manually edit the profile file." )
						-- tbl[k] = nil
					end
				end
			end
		end
	end

	// remove invalid values
	for k, v in pairs( insTable ) do
		if !insvalues1[k] then
			-- print( "npcd > CreatePreset > "..preset_name.." key \""..tostring(k).."\" was removed, doesn't exist in lookup" )
			print( "Error: npcd > CreatePreset > " .. ( displayprofname or pname or profilename or tostring(insert) ) .. ": "..preset_name.." key \""..tostring(k).."\" doesn't exist in lookup, you may have to manually edit the profile file." )
			-- insTable[k] = nil
		end
	end

	// classname validation
	-- if (typ == "npc" or typ == "nextbot" or typ == "entity") then
	if ENTITY_SETS[typ] then
		if GetPresetName( insTable["classname"] ) then
			if inited and cvar.preset_test.v:GetBool() then
				local test = ents.Create( GetPresetName( insTable["classname"] ) )
				if IsValid( test ) then --and ( typ == "npc" and test:IsNPC() or typ == "nextbot" and test:IsNextBot() or typ == "entity" and IsEntity( test ) ) then
					test:Remove()
				else
					Error("\nError: npcd > CreatePreset > " .. ( displayprofname or pname or profilename or tostring(insert) ) .. ": Preset \"" .. preset_name .. "\": (type: "..typ..") classname entity not valid: \"".. tostring(GetPresetName( insTable["classname"] )).. "\", preset will be created anyways.\n\n")
				end
			end
		else
			print("npcd > CreatePreset > " .. ( displayprofname or pname or profilename or tostring(insert) ) .. ": INVALID PRESET \"" .. preset_name .. "\": No classname given ")
			return nil, "No classname given"
		end
	end

	if onlyReturn then return insTable end
	
	if pname != nil and prof[typ][preset_name] then
		print("npcd > CreatePreset > OVERWRITING Settings " .. ( pname or "" ) .. " > "..typ.."(".. typ .. ") > "..preset_name) 
	elseif debugged then
		print("npcd > CreatePreset > Settings " .. ( pname or "" ) .. " > "..typ.."(".. typ .. ") ["..(table.Count(prof[typ])+1).."] > "..preset_name)
	end

	prof[typ][preset_name] = insTable
	if pname then // is in Profiles
		updated_profiles[pname] = CurTime() //last updated time
		profile_updated = true

		-- if pname == currentProfile and ( typ == "squad" or typ == "squadpool" ) then
		-- 	RebuildSquadpool()
		-- end

		// reset last known model bounds
		if knownBounds[pname] then
			if typ == "squad" then
				knownBounds[pname][preset_name] = nil
			end

			if ENTITY_SETS[typ] then
				for _, sqkb in pairs( knownBounds[pname] ) do
					sqkb[preset_name] = nil
				end
			end
		end
      if knownBoundsEnt[typ] then
         knownBoundsEnt[typ][preset_name] = nil
      end
	end
	
	return insTable
end

function GetCharacterPresetTable( prsname )
	for _, typ in ipairs( { "npc", "nextbot", "entity" } ) do
		if Settings[typ][prsname] then
			return Settings[typ][prsname], typ
		end
	end
	return nil, nil
end

-- // place squads into squadpool squad tables
-- function RebuildSquadpool( profile )
-- 	if !profile.squadpool or !profile.squad then return end
-- 	for _, ptbl in pairs( profile.squadpool ) do
-- 		ptbl["squads"] = {}
-- 	end
-- 	for prsname, prstbl in pairs( profile.squad ) do
-- 		SetEntValues( nil, prstbl, "squadpools", t_lookup["squad"]["squadpools"] )
-- 		if prstbl["squadpools"] then
-- 			for _, pt in pairs( prstbl["squadpools"] ) do
-- 				 // set default expected if missing
-- 				SetEntValues( nil, pt, "expected", t_lookup["squad"]["squadpools"].STRUCT["expected"] )

-- 				local p = pt["preset"] and ( istable(pt["preset"]) and pt["preset"]["name"] or isstring(pt["preset"]) and pt["preset"] )
-- 				if profile.squadpool[p] then
-- 					profile.squadpool[p]["squads"][prsname] = pt["expected"]
-- 				end
-- 			end
-- 		end
-- 	end
-- 	countupdated = true
-- end

function RecursiveValueSearch(tbl, find, onfind, depth, truth)
   local d = depth or 0
   if d > 10 then return nil end
   local r = truth
   for dk, dv in pairs(tbl) do
      if istable(dv) then
         if dk == find then
            return onfind(dv)
         end
         r = RecursiveValueSearch(dv, find, onfind, d+1, r)
      end
   end
   return r
end

// patch_save_queue[profile name] = RealTime() + delay
local patch_save_queue = {}
function PatchSaver()
   local keepqueue = false
   for p, time in pairs(patch_save_queue) do
      if RealTime() >= time then
         SaveProfile(p)
         patch_save_queue[p] = nil
      else
         keepqueue = true
      end
   end
   if keepqueue then
      timer.Simple( 1, PatchSaver )
   end
end

local f_patches = {
	// 20: squadpools removed from squads preset -> squadpools list their own spawns
	[20] = function( typ, preset_name, insTable, profilename, onlyReturn, insert, displayprofname )
		local profile = insert or profilename and Profiles[profilename] or nil
		if !profile then return nil end
		if typ == "squadpool" then
			insTable["squads"] = nil
		elseif typ == "squad" then
			SetEntValues( nil, insTable, "squadpools", t_old_lookup[20].squad["squadpools"] )
			if insTable["squadpools"] then
				profile.PATCHES = profile.PATCHES or {}
				profile.PATCHES["20SQUADPOOL"] = profile.PATCHES["20SQUADPOOL"] or {}
				for _, pt in pairs( insTable["squadpools"] ) do
					// set default expected if missing
					SetEntValues( nil, pt, "expected", t_old_lookup[20].squad["squadpools"].STRUCT["expected"] )

					local p = pt["preset"] and ( istable(pt["preset"]) and pt["preset"]["name"] or isstring(pt["preset"]) and pt["preset"] ) or nil
					if p then
						profile.PATCHES["20SQUADPOOL"].squadpool = profile.PATCHES["20SQUADPOOL"].squadpool or {}
						profile.PATCHES["20SQUADPOOL"].squadpool[p] = profile.PATCHES["20SQUADPOOL"].squadpool[p] or {}
						profile.PATCHES["20SQUADPOOL"].squadpool[p]["spawns"] = profile.PATCHES["20SQUADPOOL"].squadpool[p]["spawns"] or {}
						local pp = {
							["preset"] = {
								type = typ,
								name = preset_name,
							},
							["expected"] = CopyData( pt["expected"] )
						}
						table.insert( profile.PATCHES["20SQUADPOOL"].squadpool[p]["spawns"], pp )
					end
				end
			end
			insTable["squadpools"] = nil
		end
	end,
   // "inputs" table to struct
   [47] = function(typ, preset_name, insTable, profilename, onlyReturn, insert, displayprofname)
      local f = function(tbl)
         local p = false
         for _, t in pairs(tbl) do
            if !p and (t[1] or t[2] or t[3]) then p = true end
            t["command"] = t["command"] or t[1]
            t[1] = nil
            t["value"] = t["value"] or t[2]
            t[2] = nil
            t["delay"] = t["delay"] or isnumber(t[3]) and t[3] or nil
            t[3] = nil
         end
         return p
      end

      local patched = false
      local profile = insert or profilename and Profiles[profilename] or nil
		if !profile then return nil end
      patched = RecursiveValueSearch(insTable, "inputs", f)
      if patched then
         local msg = "NPCD preset ["..tostring(displayprofname or profilename).." > "..tostring(preset_name).."] has been patched: Restructured \"Inputs\" value"
         AddPatchInform( msg )
         if table.IsEmpty(patch_save_queue) then
            timer.Simple( 2, PatchSaver )
         end
         patch_save_queue[displayprofname or profilename] = RealTime() + 2
      end
   end,
}

function PresetPatches( typ, preset_name, insTable, profilename, onlyReturn, insert, displayprofname )
	for k in pairs( f_patches ) do
		if insTable["VERSION"] and insTable["VERSION"] < k then
			f_patches[k]( typ, preset_name, insTable, profilename, onlyReturn, insert, displayprofname )
		end
	end
end

local f_profile_patches = {
	// 20: squadpools removed from squads preset -> squadpools list their own spawns
	["20SQUADPOOL"] = function( profile, patchTbl, profname )
		-- PrintTable( patchTbl )
		for p, prstbl in pairs( patchTbl.squadpool ) do
			if profile.squadpool[p] and prstbl.spawns then
				profile.squadpool[p]["spawns"] = profile.squadpool[p]["spawns"] or {}
				for _, pp in pairs( prstbl.spawns ) do
					table.insert( profile.squadpool[p]["spawns"], pp )
				end
			end
		end
		local msg = "NPCD Profile \""..tostring(profname).."\" has been patched: Moved squad's squadpool list from squad presets -> squadpool preset"
		AddPatchInform( msg )
		-- print( msg )
		-- net.Start( "npcd_announce" )
		-- 	net.WriteString( msg )
		-- 	net.WriteColor( RandomColor( 50, 55, 0.5, 1, 1, 1 ) )
		-- net.Broadcast()
		-- table.insert( PatchInformList, msg )
		return true
	end,
}

function ProfilePatches( prof, profname )
	if !prof then return nil end
	local patched
	if prof["PATCHES"] then
		for k, v in pairs( prof["PATCHES"] ) do
			if f_profile_patches[k]( prof, v, profname ) then
				patched = true
			end
		end
	end
	prof["PATCHES"] = nil
	return patched
end

// keep patch message for given time (for new connections after patched)
function SetPatchInformTime( time )
	PatchInform = CurTime() + ( time or 60 )
	timer.Simple( ( time and time + 1 or 61 ), function()
		if PatchInform and CurTime() > PatchInform then
			PatchInform = nil
			table.Empty( PatchInformList )
		end
	end )
end

// broadcast patch message
function AddPatchInform( msg, time )
	if !msg then return end
	print( msg )
	net.Start( "npcd_announce" )
		net.WriteString( msg )
		net.WriteColor( RandomColor( 50, 55, 0.5, 1, 1, 1 ) )
	net.Broadcast()
	table.insert( PatchInformList, msg )
	SetPatchInformTime( time )
end