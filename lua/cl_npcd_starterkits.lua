module( "npcd", package.seeall )

function GeneratedKit()
	if !CheckClientPerm2( LocalPlayer(), "profiles" ) then
		return
	end
	local pname = "generated profile"
	local c = 0
	
	local prof = ClientCreateProfile( pname, true ) // always returns name of new profile. "generated kit (2)", etc
	if !prof then print( prof, "nil" ) return end
	ClientResetProfile( prof ) // set to defaults
	QuerySettings()

	QueuePostQuery( prof, 30, function()
		PendingSettings[prof] = {}

		for k, v in pairs( list.Get("NPC") ) do
			if !istable( v ) then continue end
			local prsname = v.Name
			local dupc = 1
			while PendingSettings[prof].npc and PendingSettings[prof].npc[prsname] do
				prsname = v.Name.. " (" .. dupc .. ")"
				dupc = dupc + 1
			end
			local ins = {
				["classname"] = {
					type = "NPC",
					name = v.Class
				},
				["model"] = v.Model,
				["maxhealth"] = tonumber(v.Health),
				["numgrenades"] = tonumber(v.Numgrenades),
				["skin"] = tonumber(v.Skin),
				["spawnflags"] = tonumber(v.SpawnFlags),
				["angle"] = v.Rotate,
				["offset"] = v.Offset and Vector( 0, 0, v.Offset ) or nil,
			}
			if v.KeyValues then
				ins["keyvalues"] = {}
				for key, value in pairs( v.KeyValues ) do
					if key == "SquadName" then continue end
					if key == "citizentype" then
						ins["citizentype"] = table.KeyFromValue( t_lookup.class.npc["npc_citizen"]["citizentype"].ENUM, value )
						continue
					end
					table.insert( ins["keyvalues"], { key = tostring(key), value = value } )
				end
				if table.IsEmpty( ins["keyvalues"] ) then ins["keyvalues"] = nil end
			end
			if v.Weapons then
				local wins = {
					["weapons"] = {}
				}
				for _, wep in pairs( v.Weapons ) do
					if wep != "" then
						table.insert( wins["weapons"], {
							classname = wep,
						} )
					end
				end
				if !table.IsEmpty( wins["weapons"] ) then
					c = InsertPending( prof, "weapon_set", prsname.." Weapons", wins ) and c + 1
					ins["weapon_set"] = {
						type = "weapon_set",
						name = prsname.." Weapons"
					}
				end
			end

			c = InsertPending( prof, "npc", prsname, ins ) and c + 1
		end
		for k, v in pairs( list.Get("SpawnableEntities") ) do
			if !istable( v ) then continue end
			local oname = ( v.Category and v.Category != "" and v.Category .. ": " or "" ) .. ( v.PrintName or k )
			local prsname = oname
			local dupc = 1
			while PendingSettings[prof].entity and PendingSettings[prof].entity[prsname] do
				prsname = oname.. " (" .. dupc .. ")"
				dupc = dupc + 1
			end
			local ins = {
				["classname"] = {
					type = "SpawnableEntities",
					name = v.ClassName
				},
				["offset"] = v.NormalOffset and Vector( 0, 0, v.NormalOffset ) or nil,
			}

			c = InsertPending( prof, "entity", prsname, ins ) and c + 1
		end
		for k, v in pairs( weapons.GetList() ) do
			if !v.ClassName then continue end
			local oname = ( v.Category and v.Category != "" and v.Category .. ": " or "" ) .. ( v.PrintName or v.ClassName or k )
			local prsname = oname
			local dupc = 1
			while PendingSettings[prof].weapon_set and PendingSettings[prof].weapon_set[prsname] do
				prsname = oname.. " (" .. dupc .. ")"
				dupc = dupc + 1
			end
			local ins = {
				["weapons"] = {
					{
						["classname"] = v.ClassName,
					}
				}
			}

			c = InsertPending( prof, "weapon_set", prsname, ins ) and c + 1
		end

		print( c .. " presets created" )
		chat.AddText( "Profile \"" .. prof .. "\" added to pending changes")
		StartSettingsPanel()
	end )
end

function StarterKit()
	include( NPCD_LUA_DIR.."profiles/client/npcd_lua_cl_starter_kit.lua" )
	include( NPCD_LUA_DIR.."profiles/client/npcd_lua_cl_chaos_kit.lua" )
	include( NPCD_LUA_DIR.."profiles/client/npcd_lua_cl_vip_defense.lua" )
	npcd.QuerySettings()
	npcd.StartSettingsPanel()
end