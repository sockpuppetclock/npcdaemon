// entity values stuff

module( "npcd", package.seeall )

// work out the values in tbl via the lookup table
function ApplyValueTable( tbl, lookup, ent, forced, nodefault )
	for valueName, valueTbl in pairs( lookup ) do
		SetEntValues( ent, tbl, valueName, valueTbl, forced, nodefault )
	end
end

function SetTmpEntValues( tmp, ent, tbl, valueName, valueTbl )
	if tbl[valueName] == nil then return nil end
	tmp[valueName] = CopyData( tbl[valueName] )
	SetEntValues( ent, tmp, valueName, valueTbl, true )
	return tmp[valueName]
end

function ApplyTmpValueTable( tmp, ent, tbl, lookup )
	for valueName, valueTbl in pairs( lookup ) do
		SetTmpEntValues( tmp, ent, tbl, valueName, valueTbl )
	end
end

function TestEntValues( class, typ )
	local validVals = {} // { pass, reason }
	local ent = ents.Create( class )
	if !IsValid(ent) or typ == nil then return validVals end
	for vName, vTbl in pairs( t_lookup[typ] ) do
		if vTbl.TYPE == "data" or vTbl.TYPE == "info" then continue end
		if (vTbl.TESTFUNCTION) then
			if ( isstring(vTbl.TESTFUNCTION) ) then
				local pass = isfunction( ent[vTbl.TESTFUNCTION] )
				validVals[vName] = { pass, !pass and "Missing functions: "..vTbl.TESTFUNCTION or nil }

			elseif ( istable(vTbl.TESTFUNCTION) ) then
				local missing
				local fail
				for _, f in ipairs( vTbl.TESTFUNCTION ) do
					if ( !isfunction(ent[f]) ) then
						fail = true
						if (missing == nil) then
							missing = "Missing functions: "..f
						else
							missing = missing..", "..f
						end
					end
				end
				validVals[vName] = { !fail, missing }

			elseif ( isfunction(vTbl.TESTFUNCTION) ) then
				validVals[vName] = { vTbl.TESTFUNCTION(ent) } // returns pass, reason
			end
		elseif (vTbl.FUNCTION) then
			local f = vTbl.FUNCTION[1]
			if ( isstring(f) ) then
				local pass = isfunction( ent[f] )
				validVals[vName] = { pass, !pass and "Missing functions: "..f or nil }
			elseif ( isfunction(f) ) then
				validVals[vName] = { true }
			end
		else // no funcs and no test
			validVals[vName] = { true }
		end

		validVals[vName] = validVals[vName] or {}
		validVals[vName][3] = vTbl.NAME or vName
	end
	ent:Remove()
	return validVals
end

net.Receive( "npcd_test_request", function( len, ply )
	if IsValid( ply ) and CheckClientPerm( ply, cvar.perm_prof.v:GetInt() ) then
		local class = net.ReadString()
		local set = net.ReadString()

		local validVals = TestEntValues(class, set)

		net.Start("npcd_test_result")
			net.WriteString(class)
			net.WriteString(set)
			net.WriteTable(validVals)
		net.Send(ply)
	end
end )

// resolve function
function GetValueFunc( given )
	// check if tblrandom because tblrandom arg needs to be given as a table
	local tblrandom = given[1] == "__TBLRANDOM"

	local f = t_FUNCS[ given[1] ].FUNCTION

	// problem: unpack stops at nil values
	local maxkey = MaxKey( given )
	-- for k in pairs( given )  do
	-- 	if isnumber( k ) then
	-- 		maxkey = math.max( maxkey, k )
	-- 	end
	-- end

	if maxkey > 1 then
		if tblrandom then
			return f( { unpack( given, 2, maxkey ) } )
		else
			return f( unpack( given, 2, maxkey ) )
		end
	else
		if tblrandom then
			return nil
		else
			return f()
		end
	end
end

// resolves the value and does an associated entity function if included
function SetEntValues( ent, ent_t, valueName, valueTbl, forced, nodefault, hist )
	-- print( "SetEntValues( ",ent, ent_t, valueName, valueTbl, forced, nodefault, hist, ")" )
	if valueTbl == nil then
		debug.Trace()
		ErrorNoHalt("\nnpcd > SetEntValues > invalid: valueTbl NIL.\n",ent," ",ent_t," ",valueName," ",valueTbl,"\n\n")
		return
	end
	if hist and hist[valueTbl] then return end // recursive check
	if valueTbl.NOLOOKUP == true then return end
	if valueTbl.LOOKUP_REROLL == true and ent_t["LOOKUP_REROLL"] and ent_t["LOOKUP_REROLL"][valueName] == true and !forced then return end
	if t_DATAVALUE_NAMES[valueName] then
		Error("\nnpcd > SetEntValues > invalid: datavalue was sent as valuename: ",ent," ",ent_t," ",valueName," ",valueTbl,"\n")
		if istable( ent_t ) then
			PrintTable( ent_t )
		end
		print()
		return
	end

	local valid = true

	if ent_t[valueName] == nil then
		if !nodefault and valueTbl.DEFAULT != nil then
			-- if debugged then print( valueName, "NIL, DEFAULTING to ", valueTbl.DEFAULT ) end
			ent_t[valueName] = CopyData( valueTbl.DEFAULT )
		else
			-- if debugged then print( "NO VALUE, NO DEFAULT" ) end
			return 
		end
	end

	// replace enum with value
	if valueTbl.ENUM and valueTbl.ENUM[ ent_t[valueName] ] ~= nil then
		-- if debugged then 
            -- print( "ENUMING... ", ent_t[valueName], " -> " , valueTbl.ENUM[ ent_t[valueName] ])
        -- end
		ent_t[valueName] = CopyData( valueTbl.ENUM[ ent_t[valueName] ] )
	end

	if valueTbl.TYPE == nil then valueTbl.TYPE = t_basevalue_format["default"].TYPE end // whatever

	// create reverse lookup
	if valueTbl.ENUM and !valueTbl.ENUM_REVERSE then
		valueTbl.ENUM_REVERSE = {}
		for k, v in pairs( valueTbl.ENUM ) do
			valueTbl.ENUM_REVERSE[v] = k
		end
	end

	// replace function with value. functions are received as strings like __RANDOM, __RAND, __TBLRANDOM, etc and replaced with actual function addr
	if istable( ent_t[valueName] ) and t_FUNCS[ ent_t[valueName][1] ] then
		if valueTbl.NOFUNC then
			ErrorNoHalt( "\nnpcd > SetEntValues > Function given for a NOFUNC value. ent: ",  tostring(ent), "\n\tent_type: ", ent_t and tostring(ent_t.entity_type), "\n\tvalueName: ",
					tostring(valueName), "\n\tvalueTbl: ", tostring(valueTbl) , "\n" )
			PrintTable( ent_t[valueName] )
			return
		end

		ent_t[valueName] = GetValueFunc( ent_t[valueName] )
	end

	// 1. table with tbl struct
	// 2. value with function or "not" function
	// 3. value without function
	if valueTbl.TBLSTRUCT and istable( ent_t[valueName] ) then
		if valueTbl.TBLSTRUCT.ENUM and !valueTbl.TBLSTRUCT.ENUM_REVERSE then
			valueTbl.TBLSTRUCT.ENUM_REVERSE = {}
			for k, v in pairs( valueTbl.TBLSTRUCT.ENUM ) do
				valueTbl.TBLSTRUCT.ENUM_REVERSE[v] = k
			end
		end
		for k, g in pairs( ent_t[valueName] ) do
			local given
			local valid = true

			// enum check
			if valueTbl.TBLSTRUCT.ENUM and valueTbl.TBLSTRUCT.ENUM[g] ~= nil then
				given = CopyData( valueTbl.TBLSTRUCT.ENUM[g] )
			else
				given = g
			end
			local func = valueTbl.FUNCTION or t_basevalue_format["default"].FUNCTION

			// replace function
			if istable(given) and t_FUNCS[ given[1] ] then
				if valueTbl.NOFUNC then
					ErrorNoHalt( "\nnpcd > SetEntValues > Function given for a NOFUNC value. ent: ",  tostring(ent), "\n\tent_type: ", ent_t and tostring(ent_t.entity_type), "\n\tvalueName: ",
							tostring(valueName), "\n\tvalueTbl: ", tostring(valueTbl) , "\n" )
					PrintTable( ent_t[valueName] )
					return
				end

				given = GetValueFunc( given )
			end

			// function req, if included
			if valueTbl.FUNCTION_REQ != nil and given ~= valueTbl.FUNCTION_REQ 
			and not ( valueTbl.FUNCTION_REQ_NOT != nil and given == valueTbl.FUNCTION_REQ_NOT ) then
				valid = false
			end

			// function NOT req
			// use "not" function if included, otherwise don't do function
			if valueTbl.FUNCTION_REQ_NOT != nil and given == valueTbl.FUNCTION_REQ_NOT then
				if !valueTbl.FUNCTION_NOT == nil then
					valid = false
				else
					valid = true
					func = valueTbl.FUNCTION_NOT
				end
			end

			if valueTbl.FUNCTION_TABLE and given != nil and valueTbl.FUNCTION_TABLE[given] then
				func = valueTbl.FUNCTION_TABLE[given]
			end

			// type check
			if given != nil then
				local chktyp = GetType( given, valueTbl.TBLSTRUCT )
				if !chktyp then
					ErrorNoHalt( "\nnpcd > SetEntValues > Given data with wrong type!\n\tent: ",  tostring(ent), "\n\tent_type: ", ent_t and tostring(ent_t.entity_type), "\n\tvalueName: ",
						tostring(valueName), "\n\tvalueTbl: ", tostring(valueTbl),
						"\n\tallowed types: ", tostring( istable( valueTbl.TYPE ) and table.concat(valueTbl.TYPE, ", ") or valueTbl.TYPE ),
						"\n\tgiven type: ", type( given ) , "\n\tgiven: ", tostring( given ), "\n\tchktyp: ", tostring( chktyp ),"\n\n" )
                  if istable(given) then
                     print("given table:")
                     for k in pairs(given) do
                        MsgN(tostring(k)," = ",tostring(given[k]))
                     end
                  end
					-- debug.Trace()
					valid = false
					given = nil
				end
			else
				valid = false
			end

			// do func
			if IsValid( ent ) and valid and func and given ~= nil and !table.IsEmpty( func ) then
				DoEntFunc( ent, func, given )
			end

			// place back in table
			ent_t[valueName][k] = given
		end
	elseif valueTbl.FUNCTION and !table.IsEmpty( valueTbl.FUNCTION ) or ( valueTbl.FUNCTION_NOT or valueTbl.FUNCTION_TABLE ) then
		local func = valueTbl.FUNCTION
		local given

		// enum check
		// should be done even with first enum check because table.random can give enums
		if valueTbl.ENUM and valueTbl.ENUM[ ent_t[valueName] ] ~= nil then
			given = CopyData( valueTbl.ENUM[ ent_t[valueName] ] )
		else
			given = ent_t[valueName]
		end

		// example use case: a table.random of material enums that are all table.randoms. just make sure none of those enums have enums inside them
		if istable( given ) and t_FUNCS[ given[1] ] then
			if valueTbl.NOFUNC then
				ErrorNoHalt( "\nnpcd > SetEntValues > Function given for a NOFUNC value. ent: ",  tostring(ent), "\n\tent_type: ", ent_t and tostring(ent_t.entity_type), "\n\tvalueName: ",
						tostring(valueName), "\n\tvalueTbl: ", tostring(valueTbl) , "\n" )
				PrintTable( ent_t[valueName] )
				return
			end
			given = GetValueFunc( given )
		end

		-- if istable( given ) and isfunction( given[1] ) then
		-- 	print(valueName)
		-- 	PrintTable( given,1 )
		-- end
		
		-- if given == nil then return nil end
		
		// function req
		if valueTbl.FUNCTION_REQ != nil and given ~= valueTbl.FUNCTION_REQ 
		and not ( valueTbl.FUNCTION_REQ_NOT != nil and given == valueTbl.FUNCTION_REQ_NOT ) then
			valid = false
		end
		
		// function not req or "not" function
		if valueTbl.FUNCTION_REQ_NOT != nil and given == valueTbl.FUNCTION_REQ_NOT then
			if valueTbl.FUNCTION_NOT == nil then
				valid = false
			else
				valid = true
				func = valueTbl.FUNCTION_NOT
			end
		end

		if valueTbl.FUNCTION_TABLE and given != nil and valueTbl.FUNCTION_TABLE[given] then
			func = valueTbl.FUNCTION_TABLE[given]
		end

		if valueName == "scale" then
			if istable(given) then
				return nil
			end
		end

		// type check
		if given != nil then
			local chktyp = GetType( given, valueTbl )
			if !chktyp then
				ErrorNoHalt( "\nnpcd > SetEntValues > Given data with wrong type!\n\tent: ",  tostring(ent), "\n\tent_type: ", ent_t and tostring(ent_t.entity_type), "\n\tvalueName: ",
					tostring(valueName), "\n\tvalueTbl: ", tostring(valueTbl),
					"\n\tallowed types: ", tostring( istable( valueTbl.TYPE ) and table.concat(valueTbl.TYPE, ", ") or valueTbl.TYPE ),
					"\n\tgiven type: ", type( given ) , "\n\tgiven: ", tostring( given ), "\n\tchktyp: ", tostring( chktyp ),"\n\n" )
               if istable(given) then
                  print("given table:")
                  for k in pairs(given) do
                     MsgN(tostring(k)," = ",tostring(given[k]))
                  end
               end
				-- debug.Trace()
				-- PrintTable( ent_t )
				valid = false
				given = nil
			end
		else
			valid = false
		end

		// do func
		if IsValid( ent ) and valid and func then 
			DoEntFunc( ent, func, given )
		end

		// send value back to ent table
		ent_t[valueName] = given
	else // no function
		local given

		if valueTbl.ENUM and valueTbl.ENUM[ ent_t[valueName] ] ~= nil then
			given = CopyData( valueTbl.ENUM[ ent_t[valueName] ] )
		else
			given = ent_t[valueName]
		end

		if istable( given ) and t_FUNCS[ given[1] ] then
			if valueTbl.NOFUNC then
				ErrorNoHalt( "\nnpcd > SetEntValues > Function given for a NOFUNC value. ent: ",  tostring(ent), "\n\tent_type: ", ent_t and tostring(ent_t.entity_type), "\n\tvalueName: ",
						tostring(valueName), "\n\tvalueTbl: ", tostring(valueTbl) , "\n" )
				PrintTable( ent_t[valueName] )
				return
			end
			given = GetValueFunc( given )
		end

		// type check
		if given != nil then
			local chktyp = GetType( given, valueTbl )
			if !chktyp then
				ErrorNoHalt( "\nnpcd > SetEntValues > Given data with wrong type!\n\tent: ",  tostring(ent), "\n\tent_type: ", ent_t and tostring(ent_t.entity_type), "\n\tvalueName: ",
					tostring(valueName), "\n\tvalueTbl: ", tostring(valueTbl),
					"\n\tallowed types: ", tostring( istable( valueTbl.TYPE ) and table.concat(valueTbl.TYPE, ", ") or valueTbl.TYPE ),
					"\n\tgiven type: ", type( given ) , "\n\tgiven: ", tostring( given ), "\n\tchktyp: ", tostring( chktyp ),"\n\n" )
               if istable(given) then
                  print("given table:")
                  for k in pairs(given) do
                     MsgN(tostring(k)," = ",tostring(given[k]))
                  end
               end
				-- debug.Trace()
				valid = false
				given = nil
			end
		else
			valid = false
		end

		ent_t[valueName] = given
	end

	if valueTbl.STRUCT_RECURSIVE and valueTbl.STRUCT and istable( ent_t[valueName] ) then
		local hist = hist or {}
		hist[valueTbl] = true
		if valueTbl.TYPE == "struct_table" then
			for k in pairs( ent_t[valueName] ) do
				for vn, vt in pairs( valueTbl.STRUCT ) do
					SetEntValues( ent, ent_t[valueName][k], vn, vt, forced, nodefault, hist )
				end
			end
		else
			for vn, vt in pairs( valueTbl.STRUCT ) do
				SetEntValues( ent, ent_t[valueName], vn, vt, forced, nodefault, hist )
			end
		end
		-- PrintTable( ent_t[valueName] )
	else
	end
end

func_insert = {
	["__VALUE"] = function( ent, val )
		return val
	end,
	["__SELF"] = function( ent, val )
		return ent
	end,
	["__NIL"] = function( ent, val )
		return nil
	end,
	["__VALUETOSTRING"] = function( ent, val )
		return tostring( val )
	end,
	["__KEYVALUE"] = function( ent, val )
		Error( "\nnpcd > DoEntFunc > \"__KEYVALUE\" GIVEN AS ARGUMENT, ARGS INVALID. ", ent, val, "\n\n")
		return nil
	end,
}

// builds argument list and then performs the function. ent:func(args) or func(args)
// function should be a string of the function name
function DoEntFunc( ent, func, val )
	-- print( ent, func[1], val )
	if !ent or !func then return nil end
	if func[1] == nil then
		return nil
	end
	local fargs = {}

	// build argument list to function
	-- if val != nil then
		local maxfunc = MaxKey( func )
		if maxfunc > 1 then
			local pvcount = 0 // for packedvalue
			for k, fv in pairs( { unpack( func, 2, maxfunc ) } ) do // "#" stops at nil
				local insert

				-- print( k, fv )

				// variable amount of values
				if fv == "__PACKEDVALUE" then
					if istable( val ) then
						for kk, ffv in pairs( val ) do
							-- insert = nil
							if func_insert[ffv] then
								insert = func_insert[ffv]( ent, val )
							else
								insert = ffv
							end
							fargs[k+kk] = insert
							pvcount = math.max( pvcount, kk )
						end
					end
				// single value
				else 
					if func_insert[fv] then
						insert = func_insert[fv]( ent, val )
					else
						insert = fv
					end
					fargs[k+pvcount] = insert
				end
			end
		end
	-- end

	// if function is an actual function reference then just do that
	if isfunction( func[1] ) then
		-- if table.IsEmpty( fargs ) then
		-- 	return func[1]()
		-- else
		-- print( "simple func", func[1], unpack( fargs, 1, MaxKey( fargs ) ) )
		return func[1]( unpack( fargs, 1, MaxKey( fargs ) ) )
		-- end
	end

	// perform the function on the entity
	-- local fun = "if isfunction( Entity(" .. ent:EntIndex() .. ")."..func[1].." ) then return Entity(" .. ent:EntIndex() .. "):" .. func[1] .. "( unpack( ... ) ) end"
	-- local fun = "local args = { ... } if isfunction( args[1]."..func[1].." ) then return args[1]:" .. func[1] .. "( unpack( args[2] ) ) end"
	-- return isfunction( ent[func[1]] ) and ent[ func[1] ]( fargs ) or nil
	-- local fun = "return Entity(" .. ent:EntIndex() .. "):" .. func[1] .. "( unpack( ... ) )"
	-- print( fun )
	-- print( ent, IsValid( ent ) and IsEntity( ent ), ent[func[1]], isfunction( ent[func[1]] ), unpack( fargs ) )
	
	if !isfunction( ent[func[1]] ) then
		-- if debugged then
		print( "npcd > DoEntFunc > INVALID FUNCTION FOR ENTITY", ent, func[1], ent[func[1]], val, isfunction( ent[func[1]] ) )
		-- end
		-- debug.Trace()
		return nil
	end

	-- print( "child func", ent[func[1]], ent, unpack( fargs, 1, MaxKey( fargs ) ) )
	return ent[func[1]]( ent, unpack( fargs, 1, MaxKey( fargs ) ) ) // does it always require self as the first arg?
	-- return CompileString(fun, "DoEntFunc")( ent, fargs )
end

// apply a preset to an existing entity
function OverrideEntity( ent, p_ntbl, squad_t, preset_type, preset_name, extra_override_hard, extra_override_soft, replace )
	if !IsValid( ent ) then return end
	if !preset_type or !preset_name or !Settings[preset_type][preset_name] then return end
	
	if !ent:NotDead() then return end

	local hadtable = activeNPC[ent] or activePly[ent]
	local squad_t = squad_t or p_ntbl and p_ntbl["squad_t"]
	local pool = hadtable and hadtable.pool or squad_t and squad_t.originpool
	local npc_t = table.Copy( Settings[preset_type][preset_name] )

	// npc override 1: squad
	if squad_t then
		OverrideTable( npc_t, squad_t["values"], npc_t.entity_type, "squad" )
	end
	// npc override 2: spawnpool
	if pool != nil and Settings.spawnpool[pool] then
		OverrideTable( npc_t, Settings.spawnpool[pool], npc_t.entity_type, "spawnpool", true, true ) // copies override tables
	end

	if istable( extra_override_hard ) then
		for k, v in pairs( extra_override_hard ) do
			npc_t[k] = CopyData( v )
		end
	end
	if istable( extra_override_soft ) then
		for k, v in pairs( extra_override_soft ) do
			if npc_t[k] == nil then
				npc_t[k] = CopyData( v )
			end
		end
	end

	local e = ent
	local vel
	if replace then
		e = ents.Create( GetPresetName(npc_t.classname) or ent:GetClass() )
		e:SetPos( ent:GetPos() )
		e:SetAngles( ent:GetAngles() )
		if npc_t.model then // set model
         SetEntValues(e, npc_t, "model", GetLookup( "model", npc_t.entity_type, nil, GetPresetName( npc_t.classname ) ) )
      end
		e:Spawn()
		vel = ent:GetVelocity()
		ent:Remove()
	end

	local prepos = e:GetPos()
	local prebound = e:OBBMins()

	local npc = SpawnNPC({
      presetName =   preset_name,
      anpc_t =       npc_t,
      squad_t =      squad_t,
      npcOverride =  e,
      doFadeIns =    false,
      pool =         squad_t and squad_t["originpool"],
      nocopy =       true,
      oldsquad =     hadtable and hadtable["squad"],
   })
	-- 	preset_name, --preset
	-- 	npc_t, --npc_t
	-- 	nil, -- ent:GetPos(),
	-- 	nil, -- ent:GetAngles(),
	-- 	squad_t, --squad_t
	-- 	e, --npcOverride
	-- 	false, --doFadeIns
	-- 	squad_t and squad_t["originpool"], --poolOverride
	-- 	true, --nocopy
	-- 	nil, --nopoolovr
	-- 	hadtable and hadtable["squad"] --oldsquad
	-- )

	if !IsValid( npc ) then print( "ncpd > OverrideEntity > INVALID NPC", npc ) return end

	// fix negative z offset
	local postpos = npc:GetPos()
	local postbound = npc:OBBMins()
	local posadd = postbound.z < prebound.z and prebound.z - postbound.z or postbound.z - prebound.z
	npc:SetPos( Vector( postpos.x, postpos.y, postpos.z + posadd ) )
	if vel then
		if IsCharacter(npc) then
			npc:SetVelocity(vel)
		else
			local phys = npc:GetPhysicsObject()
			if ( IsValid( phys ) ) then
				phys:SetVelocity(vel)
			end
		end
	end

	if activeNPC[npc] then activeNPC[npc]["spawned"] = true end		

	if !hadtable then
		if p_ntbl and p_ntbl["squad"] then AddToSquad( npc, p_ntbl["squad"] ) end
		
		if squad_t and squad_t["values"]["hivequeen"] and squad_t["values"]["hiverope"] then
			-- print("roping time")
			for _, onpc in pairs( activeNPC[npc]["squad"] ) do
				if !IsValid( onpc ) then continue end
				if npc == onpc then continue end

				local ontbl = activeNPC[onpc]
				if !ontbl then continue end
				// ent is queen
				if preset_name == squad_t["values"]["hivequeen"]["name"] and preset_type == squad_t["values"]["hivequeen"]["type"] then
					for _, hr in pairs( squad_t["values"]["hiverope"] ) do
						CreateAttachRope( npc, hr["attachment_queen"], onpc, hr["attachment_servant"], hr["width"], hr["material"] )
					end
				// other is queen
				elseif ontbl["npcpreset"] == squad_t["values"]["hivequeen"]["name"] and ontbl.npc_t.entity_type == squad_t["values"]["hivequeen"]["type"] then
					for _, hr in pairs( squad_t["values"]["hiverope"] ) do
						CreateAttachRope( onpc, hr["attachment_queen"], npc, hr["attachment_servant"], hr["width"], hr["material"] )
					end
				end
			end
		end
	end
end

// child entities that can be overridden
// parent <str>, search <number>, ovr_s <table>, ovr_h <table>
local override_ents = {
	["npc_manhack"] = {
		parent = "npc_metropolice",
		ovr_s = { ["activate"] = false }, // bugfix: manhack light is active even when model changes
	},
	["npc_grenade_frag"] = {
		parent = "npc_combine_s",
		search = 30,
	},
	["npc_headcrab_poison"] = {
		search = 10,
		parent = "npc_poisonzombie",
	},
	["npc_headcrab_black"] = {
		search = 10,
		parent = "npc_poisonzombie",
	},
}

hook.Add("OnEntityCreated", "NPCD Entity Created", function(ent)
	if !IsValid(ent) then return end
	-- print(ent,ent:GetParent())
	if ent:GetClass() and override_ents[ent:GetClass()] != nil then // only can use this cause none of override_ents are non-npc yet
		// override child entities
		local entovr = override_ents[ent:GetClass()] or nil
		if entovr and !activeNPC[ent] then
			timer.Simple( 0, function()
				if !IsValid(ent) then return end

				local pnpc
				if entovr.search != nil then
					for _, r in ipairs( ents.FindInSphere( ent:GetPos(), entovr.search ) ) do
						if IsValid( r ) and r:GetClass() == entovr.parent then
							pnpc = r
							break
						end
					end
				else
					pnpc = ent:GetParent()
				end
				if !IsValid( pnpc ) or pnpc:GetClass() != entovr.parent then return end

				local partbl = activeNPC[pnpc] or activePly[pnpc]

				if partbl then
					if partbl.npc_t.childpreset then
						local ovr_s = entovr.ovr_s or nil
						local ovr_h = entovr.ovr_h or nil
						if partbl.npc_t.inheritscale then
							ovr_h = ovr_h or {}
							ovr_h["scale"] = pnpc:GetModelScale()
						end

						OverrideEntity(
							ent, 
							partbl, 
							partbl["squad_t"], 
							partbl.npc_t.childpreset["type"], 
							partbl.npc_t.childpreset["name"],
							ovr_h,
							ovr_s,
							partbl.npc_t.childpreset_replace or nil
						)
					elseif partbl.npc_t.inheritscale then
						ent:SetModelScale( pnpc:GetModelScale() )
					end
				end
			end )
		end
	end

	// relationships outward/inward for non-npcd entities
	if cvar.npc_allrelate.v:GetBool() or ( ent:IsNPC() or ent:IsNextBot() or ent:IsPlayer() ) then
		// npcd npcs are done in SpawnNPC()
		timer.Simple( engine.TickInterval(), function()
			if !IsValid( ent ) or activeNPC[ent] or activePly[ent] then return end

			for _, atbl in ipairs( { activeNPC, activePly } ) do
				for npc, ntbl in pairs( atbl ) do
					if !IsValid( npc ) then continue end

					local cl = ent:GetClass()
					// outward
					if npc:IsNPC() then
						if ntbl.relations.outward.class[cl] then
							npc:AddEntityRelationship( ent, ntbl.relations.outward.class[cl].d, ntbl.relations.outward.class[cl].p )
						elseif ntbl.relations.outward.everyone and !ntbl.relations.outward.everyone_exclude_class[cl] and !t_disp_everyone_exceptions[cl] then
							npc:AddEntityRelationship( ent, ntbl.relations.outward.everyone.d, ntbl.relations.outward.everyone.p )
						end
					end
					
					// inward
					if ent:IsNPC() then
						if ntbl.relations.inward.class[cl] then
							ent:AddEntityRelationship( npc, ntbl.relations.inward.class[cl].d, ntbl.relations.inward.class[cl].p )
						elseif ntbl.relations.inward.everyone and !ntbl.relations.inward.everyone_exclude_class[cl] and !t_disp_everyone_exceptions[cl] then
							ent:AddEntityRelationship( npc, ntbl.relations.inward.everyone.d, ntbl.relations.inward.everyone.p )
						end
					end

				end
			end
		end )
	end
end )


// entity death stuff

function AnnounceDeath( ent, ntbl, forced )
	local ent = ent
	local ntbl = ntbl or ent and activeNPC[ent]
	if !ntbl then return end
	
	// announce death
	if ntbl["squad_t"] and ntbl["squad_t"]["announce_death"] or forced then

		local osq = ntbl and ntbl["squad"] or nil
		local oname = ntbl and ( ntbl["squad_t"] and ntbl["squad_t"]["values"]["displayname"] or ntbl["squadpreset"] or ntbl["npcpreset"] ) or IsValid(ent) and ent:GetName() or "The enemy"
		local msg = ntbl and ntbl["squad_t"] and ntbl["squad_t"]["values"]["announce_death_message"] or oname.." have been defeated!"
		local col = ntbl and ntbl["squad_t"] and ntbl["squad_t"]["values"]["announce_color"] or nil

		if osq then
			timer.Simple( engine.TickInterval() * 10, function()
				// only if whole squad is dead
				local sqdead = true
				for _, npc in pairs(osq) do
					if IsValid(npc) and npc != ent and npc:NotDead() then
						-- print( npc, "not dead" )
						-- PrintTable( osq )
						sqdead = false
						break
					end
				end

				-- print( sqdead )

				if sqdead then
					-- print( CurTime(), osq )
					// avoid repeat messages by giving messages a uid
					table.insert(messageQueue, { ["msg"] = msg, ["uid"] = osq, ["col"] = col } )
				end
			end)
		else
			-- print( CurTime(), osq )
			table.insert( messageQueue, { ["msg"] = msg, ["uid"] = nil, ["col"] = col } )
		end
	end
end

function removeNPC(ent)
	if activeSound[ent] then
		for snd in pairs( activeSound[ent] ) do
			ent:StopSound( snd )
		end
		activeSound[ent] = nil
	end

	if activeNPC[ent] then
		local ntbl = activeNPC[ent]
		// announce death
		AnnounceDeath( ent )

		if ntbl["chasing"] then CheckChaseStatus( ntbl["chasing"], ent ) end

		// problem: ent:Remove() makes ent == nil so have to use entindex for removing body
		if !ent:IsPlayer() and ntbl["npc_t"]["removebody"] == true then 
			local toremove = ent
			local index = toremove:EntIndex()

			// queue checking for owner's ragdoll (which is seperate from the owner entity)
			activeRag[index] = ntbl["npc_t"]["removebody_delay"] or true // number delay or boolean

			if ntbl["npc_t"]["removebody_delay"] then
				timer.Simple( ntbl["npc_t"]["removebody_delay"], function()
					if IsValid( toremove ) then
						toremove:Remove()
					end
				end )
			else
				timer.Simple( 0, function()
					if IsValid( toremove ) then
						toremove:Remove() 
					end
				end )
			end

			// failsafe
			timer.Simple( math.max( 30, ntbl["npc_t"]["removebody_delay"] or 30 ), function()
				if IsValid(toremove) then toremove:Remove() end
				if activeRag[index] then activeRag[index] = nil end
			end )
		end
	end
	-- constraint.RemoveAll(ent)
	activeNPC[ent] = nil
	activeFade[ent] = nil
	activeEffect[ent] = nil
	activeCollide[ent] = nil
	activeSound[ent] = nil
	if !ent:IsPlayer() then activeCallback[ent] = nil end
	countupdated = true
end

hook.Add("CreateEntityRagdoll", "NCPD Remove Body", function( owner, ragdoll )
	local ragdoll = ragdoll
	if activeRag[owner:EntIndex()] then
		if activeRag[owner:EntIndex()] == true then
			ragdoll:Remove()
		else // number delay
			timer.Simple( activeRag[owner:EntIndex()], function()
				if IsValid( ragdoll ) then
					ragdoll:Remove()
				end
			end)
		end
		activeRag[owner:EntIndex()] = nil
	end
end)

function NPCKilled( ent, killer, atk )
	if !activeNPC[ent] and !activePly[ent] then return end

	local ntbl = activeNPC[ent] or activePly[ent]
	local npc_t = ntbl["npc_t"]

	// stress
	if IsValid( killer ) and killer:IsPlayer() and ( ( ent:IsNPC() and ent:Disposition( killer ) != D_LI ) or !ent:IsNPC() ) then
		local add = v_stress.stress_ply_killf * v_stress.stress_ply_outbase * math.max( 0, ent:GetMaxHealth() ) * stress_activemult * ( npc_t["stress_mult"] or 1 )
		killer.npcd_stress = math.Clamp( killer.npcd_stress + add, 0, 1 )			
		if debugged_stress then print( "ply kill (active npc)", add, killer.npcd_stress, math.max( 0, ent:GetMaxHealth() ), killer, ent ) end
	end

	// hivequeen
	if ntbl["squad"] and ntbl["squad_t"] and ntbl["squad_t"]["values"]["hivequeen"] then
		// queen is dead
		if ntbl["squad_t"]["values"]["hivequeen"]["name"] == ntbl["npcpreset"] and ntbl["squad_t"]["values"]["hivequeen"]["type"] == ntbl["npc_t"]["entity_type"] then
			local qdead = true
			local servs = {}
			for _, npc in pairs( ntbl["squad"] ) do
				if npc == ent then continue end
				if !IsValid( npc ) then continue end

				if activeNPC[npc] and not ( activeNPC[npc]["npcpreset"] == ntbl["squad_t"]["values"]["hivequeen"]["name"] and activeNPC[npc]["npc_t"]["entity_type"] != ntbl["squad_t"]["values"]["hivequeen"]["type"] )
				and npc:NotDead() then
					table.insert( servs, npc )
				end

				if activeNPC[npc] and ( activeNPC[npc]["npcpreset"] == ntbl["squad_t"]["values"]["hivequeen"]["name"] and activeNPC[npc]["npc_t"]["entity_type"] == ntbl["squad_t"]["values"]["hivequeen"]["type"] )
				and npc:NotDead() then
					qdead = false
				end
			end
			if qdead then
				for _, servant in pairs( servs ) do
					servant:SetHealth( -1 )
					servant:TakeDamage( servant:GetMaxHealth(), IsValid(killer) and killer or nil, IsValid(atk) and atk or nil)
				end
			end
		// servant is dead, and mutual is active
		elseif ntbl["squad_t"]["values"]["hivequeen_mutual"] then
			local sdead = true
			local queens = {}
			for _, npc in pairs( ntbl["squad"] ) do
				if npc == ent then continue end
				if !IsValid( npc ) then continue end

				if activeNPC[npc] and not ( activeNPC[npc]["npcpreset"] == ntbl["squad_t"]["values"]["hivequeen"]["name"] and activeNPC[npc]["npc_t"]["entity_type"] == ntbl["squad_t"]["values"]["hivequeen"]["type"] )
				and npc:NotDead() then
					sdead = false
				end

				if activeNPC[npc] and ( activeNPC[npc]["npcpreset"] == ntbl["squad_t"]["values"]["hivequeen"]["name"] and activeNPC[npc]["npc_t"]["entity_type"] == ntbl["squad_t"]["values"]["hivequeen"]["type"] )
				and npc:NotDead() then
					table.insert( queens, npc )
				end
			end
			if sdead then
				for _, queen in pairs( queens ) do
					queen:SetHealth( -1 )
					queen:TakeDamage( queen:GetMaxHealth(), IsValid(killer) and killer or nil, IsValid(atk) and atk or nil)
				end
			end
		end
	end

	// deathexplode
	if npc_t.deathexplode then
		local lup_t = GetLookup( "deathexplode", npc_t.entity_type, nil, GetPresetName( npc_t.classname ) )
		ApplyValueTable( npc_t.deathexplode, lup_t.STRUCT )

		if npc_t.deathexplode.enabled == true then
			Explode( ent, npc_t.deathexplode, ent:GetPos() + ent:OBBCenter() )
		end
	end

	// deatheffect
	if npc_t.deatheffect then
		for _, df in pairs(npc_t.deatheffect) do
			-- CreateEffect( df, ent, ent:GetPos() )
			CreateEffect( df, nil, ent:GetPos() )
		end
	end	

	// drop sets
	if npc_t.drop_set then
		DoDropSetNormal( ent, npc_t.drop_set, ntbl )
	end

	removeNPC(ent)
end

hook.Add("EntityRemoved", "NPCD Entity Removed", function(ent)
	if activeNPC[ent] then
		local ntbl = activeNPC[ent]
		// npcd prop destroyed
		if ( ntbl["npc_t"]["killonremove"] or ntbl["npc_t"]["entity_type"] == "nextbot" ) then
			NPCKilled( ent, nil, nil )
		else
			removeNPC( ent )
		end
	else
		if activeSound[ent] then
			for snd in pairs( activeSound[ent] ) do
				ent:StopSound( snd )
			end
			activeSound[ent] = nil
		end
		activeCallback[ent] = nil
	end

	-- if activeCollide[ent] then
		activeCollide[ent] = nil
	-- end
end)

hook.Add("OnNPCKilled", "NPCD NPC Killed", function(ent, killer, atk)
	if activeNPC[ent] or activePly[ent] then
		NPCKilled( ent, killer, atk )
	else
		if activeSound[ent] then
			for snd in pairs( activeSound[ent] ) do
				ent:StopSound( snd )
			end
			activeSound[ent] = nil
		end

		activeCallback[ent] = nil

		// stress
		if IsValid( killer ) and killer:IsPlayer() then
			local add = v_stress.stress_ply_killf * v_stress.stress_ply_outbase * math.max( 0, ent:GetMaxHealth() ) * stress_activemult
			killer.npcd_stress = math.Clamp( killer.npcd_stress + add, 0, 1 )			
			if debugged_stress then print( "ply kill (normal npc)", add, killer.npcd_stress, killer, ent ) end
		end
	end
end)