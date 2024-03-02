// profile stuff

module( "npcd", package.seeall )

function SettingsCount()
	Msg("npcd > Settings > "..tostring(currentProfile) .. ": ")
	local kc = 0
	local kt = table.Count( Settings )
	for k, v in SortedPairs( Settings ) do
		Msg( table.Count(v) .." "..k.."s" )
		kc=kc+1
		if kc != kt then 
			Msg(", ")
		end
	end
	MsgN()
end

function PreProfileLoad()
	if debugged then print( "npcd > PreProfileLoad" ) end
	if !file.IsDir( "npcd", "DATA" ) then
		file.CreateDir( "npcd" )
		if !file.IsDir( "npcd", "DATA" ) then
			Error("\nError: NPCD DIRECTORY garrysmod/data/npcd DOES NOT EXIST AND CANNOT BE CREATED\n\n" )
		end
	end

	// create profile dir and rename old profile names (npcd_profile_)
	if !file.IsDir( NPCD_PROFILE_DIR, "DATA" ) then
		file.CreateDir( NPCD_PROFILE_DIR )
		if !file.IsDir( NPCD_PROFILE_DIR, "DATA" ) then
			Error("\nError: NPCD DIRECTORY garrysmod/data/npcd/profiles DOES NOT EXIST AND CANNOT BE CREATED\n\n" )
		else
			local flist = file.Find( NPCD_DIR.."npcd_profile_*.json", "DATA")
			if flist and !table.IsEmpty( flist ) then
				for k, f in pairs( flist ) do
					local pname = string.sub( f, 14 )
					file.Rename( NPCD_DIR..f, NPCD_PROFILE_DIR..pname )
					AddPatchInform( "NPCD Profile has been moved: garrysmod/data/"..NPCD_DIR..f.." -> garrysmod/data/".. NPCD_PROFILE_DIR..pname )
				end
				Profiles, patched = LoadAllProfiles()
			end
		end
	end
end

function FirstRun()
	if debugged then print( "npcd > FirstRun" ) end
	local frf = NPCD_DIR.."npcd_firstrun.txt"
	if !file.Exists( frf, "DATA" ) then
		file.Write( frf, tostring( system.SteamTime() or "" ) )

		print( "npcd > FIRST RUN, CREATING STARTER KITS" )
		// starter kits
		local starter = include( NPCD_LUA_DIR.."profiles/server/npcd_lua_sv_starter kit.lua" ) // returns profile name
		include( NPCD_LUA_DIR.."profiles/server/npcd_lua_sv_chaos kit.lua" )
		include( NPCD_LUA_DIR.."profiles/server/npcd_lua_sv_vip defense.lua" )
		SwitchProfile( starter )
		return true
	else
		return false
	end
end

function StartupLoad()
	if debugged then print( "npcd > StartupLoad" ) end
	Settings = {}
	local patched
	PreProfileLoad()
	Profiles, patched = LoadAllProfiles()

	b_FirstRun = FirstRun()

	if patched then SaveAllProfiles() end

	if b_FirstRun then return end

	lastSwitched = nil
	if !file.Exists(NPCD_DIR.."npcd_last_profile.txt", "DATA") then 
		file.Write(NPCD_DIR.."npcd_last_profile.txt", "default")
		currentProfile = "default"
	else
		currentProfile = file.Read(NPCD_DIR.."npcd_last_profile.txt", "DATA")
		if currentProfile == nil or !Profiles[currentProfile] then
			currentProfile = "default"
		end
	end

	if Profiles[currentProfile] then
		SwitchProfile( currentProfile )
	else
		print("npcd > Init > Profile ",currentProfile," does not exist, using default")
		CreateDefaultProfile()
		SwitchProfile( "default" )
	end
end

function CreateDefaultProfile()
	if debugged then print("npcd > CreateDefaultProfile") end
	if !Profiles["default"] then
		print("npcd > Init > Creating default profile")
		Profiles["default"] = DefaultSettings()
		SaveProfile( "default" )
	end
end

function EmptySettings()
	return {
		["squad"] = {},
		["squadpool"] = {},
		["npc"] = {},
		["entity"] = {},
		["nextbot"] = {},
		["weapon_set"] = {},
		["drop_set"] = {},
		["player"] = {},
	}
end

function DefaultSettings()
	local newSettings = EmptySettings()

	CreatePreset("squadpool", "Default", { ["pool_spawnlimit"] = 50, }, nil, nil, newSettings)

	return newSettings
end

function ResetProfile( p )
	return ClearProfile( p, true )
end

function ClearProfile( p, def )
	if debugged then print("npcd > ClearProfile", p, def ) end
	local p = p and tostring( p ) or nil
	if !p then return nil end
	if Profiles[p] then
		Profiles[p] = def and DefaultSettings() or EmptySettings()
		SaveProfile( p )
		if p == currentProfile then Settings = Profiles[p] end // keep table reference
	else
		print("ClearProfile > Profile ",p," does not exist!")
		return nil
	end
	print( "npcd > RESET PROFILE: " .. p )

	updated_profiles[p] = CurTime()
	profile_updated = true

	return true
end

function CreateEmptyProfile( p, loose )
	return CreateProfile( p, nil, loose, true )
end

function CopyProfile( p )
	return CreateProfile( p, true )
end

function CreateProfile( p, copy, loose, empty )
	local pname
	local copycount = 0
	local p = p and tostring(p) or nil

	if copy then
		if !p or !Profiles[p] then
			print( p, " does not exist to copy from!")
			return nil
		end

		local newp = string.lower(p)
		pname = newp
		while Profiles[pname] ~= nil do
			copycount = copycount + 1
			pname = newp .. " (" .. copycount .. ")"
		end
		Profiles[pname] = table.Copy( Profiles[p] )
	else
		if p then
			local newp = string.lower(p)
			pname = newp

			if loose then
				while Profiles[pname] ~= nil do
					copycount = copycount + 1
					pname = newp .. " (" .. copycount .. ")"
				end
			end
		else
			pname = "profile " .. ( table.Count(Profiles) + 1 )
			while Profiles[pname] ~= nil do
				copycount = copycount + 1
				pname = "profile " .. ( table.Count(Profiles) + copycount )
			end
		end

		if Profiles[pname] then
			print( "Profile " .. pname .. " already exists!")
			return pname
		end

		Profiles[pname] = empty and EmptySettings() or DefaultSettings()
	end

	PrintTable( table.GetKeys(Profiles), 1 )

	SaveProfile( pname )

	updated_profiles[pname] = CurTime()
	profile_updated = true

	return pname
end

function RenameProfile( oldp, newp )
	print( "npcd > RenameProfile >",oldp,newp)
	local oldp = oldp and tostring( oldp ) or nil
	if !oldp or !newp then return end
	local newp = string.lower( newp )
	if Profiles[newp] then
		print("npcd > RenameProfile > " .. newp .. " already exists!")
		return
	end
	if !Profiles[oldp] then
		print("npcd > RenameProfile > " .. oldp .. " does not exist!")
		return
	end

	// rename
	local success = file.Rename( NPCD_PROFILE_DIR..oldp..".json", NPCD_PROFILE_DIR..newp..".json" )
	if !success then
		Error("\nnpcd > RenameProfile > file.Rename failed! garrysmod/data/", NPCD_PROFILE_DIR..oldp..".json" , " -> garrysmod/data/", NPCD_PROFILE_DIR..newp..".json" )
		return
	end

	Profiles[newp] = Profiles[oldp]

	Profiles[oldp] = nil

	print( "npcd > RenameProfile > Renamed files: garrysmod/data/"..NPCD_PROFILE_DIR..oldp..".json" .. " -> garrysmod/data/".. NPCD_PROFILE_DIR..newp..".json")

	if currentProfile == oldp then
		SwitchProfile( newp )
	end

	updated_profiles[oldp] = nil
	knownBounds[oldp] = nil
	updated_profiles[newp] = CurTime()
	profile_updated = true
end

function LoadAllProfiles()
	if debugged then print("npcd > LoadAllProfiles") end
	local flist = file.Find(NPCD_PROFILE_DIR.."*.json", "DATA")
	if !flist then
		Error( "\nnpcd > Could not load profiles folder!\n\n" )
		return nil
	end
	local ptbl = {}
	local patched
	for _, f in SortedPairsByValue(flist) do
		preset_updatecount = 0

		-- local pname = string.sub( string.StripExtension( f ), 14 ) 
		local pname = string.StripExtension( f )
		local ptch
		ptbl[pname], ptch = LoadProfile( f, cvar.rawload.v:GetBool(), pname )
		if ptch then patched = true end

		if ptch and preset_updatecount > 0 then
			print( "npcd > LoadProfile > " .. pname .. ": " .. preset_updatecount .. " presets have been patched to version "..NPCD_VERSION )
		end
		preset_updatecount = nil
	end
	if !table.IsEmpty(ptbl) and inited then
		print("npcd > Profiles Loaded:\n\t" .. table.concat( table.GetKeys( ptbl ), "\n\t" ) )
	elseif table.IsEmpty(ptbl) then
		print("npcd > LoadAllProfiles > No profiles")
	end
	return ptbl, patched
end

function ProfileExists( pname )
	return file.Exists( NPCD_PROFILE_DIR .. string.lower( pname ) .. ".json", "DATA")
end

function LoadProfile( f, raw, profname )
	if debugged then print("npcd > LoadProfile", f, raw, profname ) end
	local f = f and tostring( f ) or nil
	if !f then return nil end
	local new_profile

	if !file.Exists(NPCD_PROFILE_DIR..f, "DATA") then
		Error("\nError: npcd > LoadProfile > garrysmod/data/", NPCD_PROFILE_DIR , tostring(f)," does not exist.\n\n")
		return nil
	end

	// read file
	local j = file.Read(NPCD_PROFILE_DIR..f, "DATA")
	if !string.StartWith(j, "{") then
		Error("\nError: npcd > LoadProfile > garrysmod/data/", NPCD_PROFILE_DIR , tostring(f)," not loaded, it may be invalid.\n\n")
		return nil
	end

	// convert json to table
	local profile = util.JSONToTable( j )
	if !profile then
		Error( "\nError: npcd > LoadProfile > garrysmod/data/", NPCD_PROFILE_DIR , tostring(f)," returned invalid json\n\n" )
		return nil
	end
	FixSingleProfileNames( profile )
	// fixup
	RecursiveFixUserdata( profile )

	if debugged then print( "npcd > LoadProfile > ", f ) end

	// rebuild the hole damn thing
	if !raw then
		new_profile = EmptySettings()
		for setk, settbl in pairs( profile ) do
			for prs, prstbl in pairs( settbl ) do
				local p, err = CreatePreset( setk, prs, prstbl, nil, nil, new_profile, profname ) // places the created presets in the new profile
				if !p or err then
					Error( "\nnpcd > LoadProfile > CreatePreset > Error: ", err,"\n\n" )
				end
			end
		end
	else
		new_profile = profile
	end
	
	if debugged then print("npcd > Loaded profile: " .. NPCD_PROFILE_DIR .. f) end

	return new_profile, ProfilePatches( new_profile, profname )
end

function SwitchProfile( p )
	if debugged then print("npcd > SwitchProfile", p ) end
	local p = p and tostring( p ) or nil
	if !p then return nil end
	if p == lastSwitched then return nil end

	if Profiles[p] then
		Settings = Profiles[p]
	else
		print("npcd > SwitchProfile > Profile ",p," does not exist!")
		return nil
	end

	if debugged then print("npcd > SwitchProfile > Settings<->Profiles tblref: ",Settings, Profiles[p], Settings == Profiles[p]) end

	lastSwitched = p
	if currentProfile ~= p then
		currentProfile = p
		file.Write( NPCD_DIR.."npcd_last_profile.txt", currentProfile)
	end

	if inited then print("npcd > Current Profile: " .. currentProfile ) end

	net.Start("npcd_currentprofile")
		net.WriteString( currentProfile )
	net.Broadcast()

	squad_times = {}
	pool_times = {}

	SettingsCount()

	if inited then
		net.Start( "npcd_announce" )
			net.WriteString( "Profile switched to \"".. currentProfile .. "\"" )
			net.WriteColor( Color( 200, 200, 200 ) )
		net.Broadcast()
	end

	return true
end

function PatchProfile( p )
	local p = p and tostring( p ) or nil
	return ProfilePatches( p and Profiles[p] or Profiles[currentProfile], p or currentProfile )
end

function SaveProfile( p )
	if debugged then print("npcd > SaveProfile", p ) end
	local p = p and tostring( p ) or nil
	if !p then return end
	if Profiles[p] then
		local pname = p..".json"

		// save old copy
		if cvar.keepold.v:GetBool() then
			local oldpath = NPCD_DIR.."old/".. p .. ".json"
			if file.Exists( NPCD_PROFILE_DIR..pname, "DATA") then
				file.CreateDir( NPCD_DIR .. "old" )
				local c = 1
				while file.Exists( oldpath, "DATA" ) do
					oldpath = NPCD_DIR.."old/".. p .. "." .. c .. ".json"
					c=c+1
					if c > 65536 then
						ErrorNoHalt( "\nnpcd > SaveProfile > too many old files!! aarrgh!!\n\n" )
						break
					end
				end
				file.Rename( NPCD_PROFILE_DIR..pname, oldpath )
				print( "npcd > Saved profile copy: garrysmod/data/" .. oldpath )
			end
		end

		file.Write( NPCD_PROFILE_DIR..pname, util.TableToJSON(Profiles[p], true) )
	else
		print("SaveProfile > Profile ",p," does not exist!")
		return
	end
	print( "npcd > Saved profile: garrysmod/data/" .. NPCD_PROFILE_DIR ..p..".json" )

	-- RebuildSquadpool()
end

function SaveAllProfiles()
	for p in pairs(Profiles) do
		SaveProfile(p)
	end
end

function DeleteProfile( p )
	if debugged then print("npcd > DeleteProfile", p ) end
	local p = p and tostring( p ) or nil
	if !p then
		if debugged then print("npcd > DeleteProfile > no profile given" ) end
		return
	end
	if Profiles[p] then
		Profiles[p] = nil
		local pname = p..".json"
		local trashname = NPCD_DIR.."trash/"..p .. ".json"
		if file.Exists( NPCD_PROFILE_DIR..pname, "DATA") then
			-- file.Delete( NPCD_DIR..pname )
			file.CreateDir( NPCD_DIR .. "trash" )
			local c = 1
			while file.Exists( trashname, "DATA" ) do
				trashname = NPCD_DIR.."trash/"..p .. "." .. c .. ".json"
				c=c+1
				if c > 65536 then
					ErrorNoHalt( "\nnpcd > DeleteProfile > too much trash!! what are you even doing\n\n" )
					break
				end
			end
			file.Rename( NPCD_PROFILE_DIR..pname, trashname )
		end
		if currentProfile == p then
			if Profiles["default"] then
				SwitchProfile( "default" )
			else
				local pkeys = table.GetKeys( Profiles )
				table.sort( pkeys )
				if !table.IsEmpty( pkeys ) then
					SwitchProfile( pkeys[1] )
				else
					CreateDefaultProfile()
					SwitchProfile( "default" )
				end
			end
		end

		print("npcd > TRASHED PROFILE: garrysmod/data/" .. NPCD_PROFILE_DIR .. pname .. " -> garrysmod/data/" .. trashname )
	else
		print("ncpd > DeleteProfile > Profile ",p," does not exist!")
		return
	end

	updated_profiles[p] = nil
	knownBounds[p] = nil
	profile_updated = true
end

settings_acts = {
	[0] = SwitchProfile,
	[1] = SaveProfile,
	[2] = LoadProfile,
	[3] = CreateProfile,
	[4] = DeleteProfile,
	[5] = ClearProfile,
	[6] = SaveAllProfiles,
	[7] = LoadAllProfiles,
	[8] = RenameProfile,
	[9] = CopyProfile,
	[10] = CreateEmptyProfile,
	[11] = ResetProfile,
}
settings_acts_names = {
	[0] = "SwitchProfile",
	[1] = "SaveProfile",
	[2] = "LoadProfile",
	[3] = "CreateProfile",
	[4] = "DeleteProfile",
	[5] = "ClearProfile",
	[6] = "SaveAllProfiles",
	[7] = "LoadAllProfiles",
	[8] = "RenameProfile",
	[9] = "CopyProfile",
	[10] = "CreateEmptyProfile",
	[11] = "ResetProfile",
}

local function ProfilesAutocomplete( cmd, stringargs )
	stringargs = string.Trim( stringargs )
	stringargs = string.lower( stringargs )

	local tbl = {}
	for k, v in pairs(Profiles) do
		if string.StartWith( string.lower( k ), stringargs ) then
			table.insert(tbl, cmd .. " " .. k)
		end
	end
	
	return tbl
end

concommand.Add( "npcd_profile_save_all", function( ply, cmd, args, argstr )
	if ply:IsAdmin() or ply:IsSuperAdmin() then
		SaveAllProfiles()
	end
end)

concommand.Add( "npcd_profile_save", function( ply, cmd, args, argstr )
	if ply:IsAdmin() or ply:IsSuperAdmin() then
		if #argstr == 0 then argstr = nil end
		if argstr then SaveProfile( argstr ) end
	end
end,
ProfilesAutocomplete)

concommand.Add( "npcd_profile_copy", function( ply, cmd, args, argstr )
	if ply:IsAdmin() or ply:IsSuperAdmin() then
		if #argstr == 0 then argstr = nil end
		if argstr then CreateProfile( argstr, true ) end
	end
end,
ProfilesAutocomplete)

concommand.Add( "npcd_profile_change", function( ply, cmd, args, argstr )
	if ply:IsAdmin() or ply:IsSuperAdmin() then
		if #argstr == 0 then argstr = nil end
		if argstr then SwitchProfile( argstr ) end
	end
end,
ProfilesAutocomplete)

concommand.Add( "npcd_profile_new", function( ply, cmd, args, argstr )
	if ply:IsAdmin() or ply:IsSuperAdmin() then
		if #argstr == 0 then argstr = nil end
		CreateProfile( argstr )
	end
end)

concommand.Add( "npcd_profile_reload_all", function( ply, cmd, args, argstr )
	if ply:IsAdmin() or ply:IsSuperAdmin() then
		StartupLoad()

		updated_profiles = {}
		profile_updated = true
	end
end,
ProfilesAutocomplete)
net.Receive( "npcd_profile_reload_all", function( len, ply ) 
	if ply:IsAdmin() or ply:IsSuperAdmin() then
		StartupLoad()

		updated_profiles = {}
		profile_updated = true
	end
end )

concommand.Add( "npcd_profile_remove", function( ply, cmd, args, argstr )
	if ply:IsAdmin() or ply:IsSuperAdmin() then
		if #argstr == 0 then return end
		if argstr then DeleteProfile( argstr ) end
	end
end,
ProfilesAutocomplete)