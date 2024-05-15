module( "npcd", package.seeall )

if !CLIENT then return end

local cl_cf = FCVAR_ARCHIVE
cl_cvar = {
	show_limits = {
		v = CreateConVar("npcd_hud_spawncount", 0, cl_cf, "Show spawn and squad counts on HUD", 0, 1),
		t = "boolean",
		n = "Show Spawn Counts",
		c = "HUD (Client)",
		p = PERM_CLIENT,
	},
	show_stress = {
		v = CreateConVar("npcd_hud_stress", 0, cl_cf, "Show stress/pressure", 0, 1),
		t = "boolean",
		n = "Show Stress & Pressure",
		c = "HUD (Client)",
		p = PERM_CLIENT,
	},
	show_preset = {
		v = CreateConVar("npcd_hud_preset", 1, cl_cf, "Show player's active preset constantly", 0, 1),
		t = "boolean",
		n = "Show Player Preset",
		c = "HUD (Client)",
		p = PERM_CLIENT,
	},
	close_settings = {
		v = CreateConVar("npcd_settings_window_reset_on_close", 0, cl_cf, nil, 0, 1),
		t = "boolean",
		n = "Reset Settings Window On Close (Client)",
		c = "Profiles",
		p = PERM_CLIENT,
	},
	spawner_toolgunner = {
		v = CreateConVar("npcd_spawner_toolgunning", 0, cl_cf, "If true, left-click in spawnmenu activates the toolgun instead of spawning the preset", 0, 1),
		t = "boolean",
		n = "Prefer Toolgun On Spawnmenu (Client)",
		c = "Spawning",
		p = PERM_CLIENT,
	},
	-- show_chase = {
	-- 	v = CreateConVar("npcd_hud_chase", 0, FCVAR_ARCHIVE, "Show if enemies are chasing you", 0, 1)
	-- 	t = "boolean",
	-- 	n = "Chase Status",
	-- 	c = "HUD",
	-- },
	valuelist_rate = {
		v = CreateConVar("npcd_settings_window_valuelist_fillrate", 3, cl_cf, "Fill preset value lists at a rate of this many panels per tick across all editors", 1 ),
		t = "int",
		n = "Value List Fill Rate (Client)",
		c = "Performance",
		p = PERM_CLIENT,
	},
	cl_debugged = {
		v = CreateConVar("npcd_verbose_cl", 0, cl_cf, nil, 0, 1),
		t = "boolean",
		n = "Verbose Client",
		c = "Debug",
		p = PERM_CLIENT,
	},
	panel_leftvertflip = {
		v = CreateConVar("npcd_settings_window_leftcolumnflip", 0, cl_cf, "UI design, requires window reset", 0, 1),
		t = "boolean",
		n = "Swap Profiles/Types Selection Column Order (Client)",
		c = "Profiles",
		p = PERM_CLIENT,
	},
	setsort = {
		v = CreateConVar("npcd_settings_window_typesort", 0, cl_cf, "UI design, requires window reset", 0, 1),
		t = "boolean",
		n = "Sort Preset Type Selector Alphabetically (Client)",
		c = "Profiles",
		p = PERM_CLIENT,
	},
	valuelist_showall = {
		v = CreateConVar("npcd_settings_window_valuelist_showall", 0, cl_cf, "If unchecked, only pending or existing values are shown in the preset editor", 0, 1),
		t = "boolean",
		n = "Always Show All Values (Client)",
		c = "Profiles",
		p = PERM_CLIENT,
	},
}

for name, cv in pairs( cl_cvar ) do
	cv.sn = cv.sort or cv.n
end

local all_cvar_p_t = {}

local NPCDSpawnMenu = nil
settings_title = "npcd Settings"
tab_title = ""

local proflabel
local profselect

local cvar_forms = {}
local cvar_cats = {}
local tog_expand = false

cl_profiles_manifest = {}
cl_Profiles = {}
local tmp_Profiles = {}
cl_currentProfile = nil
local cl_lastProfile = nil
local prof_changed = false
local cl_ply_preset = ""

local lastquery = -1024
query_delay = 3
cl_sending, cl_receiving, cl_receiving_man = nil
cl_committed = nil

local postqueryQueue = {}

active_prof, active_set, active_prs = nil

PendingSettings = PendingSettings or {}
PendingRemove = PendingRemove or {}
PendingAdd = PendingAdd or {}

MatCache = {}
MatCacheNames = {}

local npcd_nodes = {}

local spawnpools = {}
local tmp_spawnpools = {}

local chase_status = false
local cl_stress
local cl_pressure
-- local cl_enabled
-- local cl_enabled_spawn
-- local cl_enabled_chase
-- local cl_enabled_stress

-- local lastupd = CurTime()

-- local lastchknum
local query_stream = {}
local report_stream = {}

drawhud = GetConVar("cl_drawhud")

local scoreboard = false

// ui enums
COL_UNCHANGED = 172 --164
UI_BUTTON_W = 30 --ScreenScale(12)
UI_ICONBUTTON_W = 24
UI_BUTTON_H = 30 --ScreenScale(12)
UI_TEXT_H = 30 --ScreenScale(12)
UI_ENTRY_H = 25 --ScreenScale(10)
UI_ICON_MARGIN = 5 --ScreenScale(2)
UI_COLORTEST_W = UI_ENTRY_H
marg = 12.5 --ScreenScale( 5 )
UI_SELECTOR_X, UI_SELECTOR_Y = 14, 30
UI_TABLE_L_ADD = 1.65 --2
UI_STR_LEFT_LIM = 20

local bar_w = ScreenScale( 5 )
local stress_bar_w = bar_w * 1.5

UI_ICONS = {
	-- npcd = "icon16/tux.png",
	-- npcd = "icon16/monkeytux.png",
	npcd = "icon16/monkey_weird.png",
	menunode = "icon16/weirdmonkey.png",
	add = "icon16/add.png",
	sub = "icon16/delete.png",
	edit = "icon16/application_form_edit.png",
	revert = "icon16/arrow_rotate_clockwise.png",
	rename = "icon16/textfield_rename.png",
	copy = "icon16/page_copy.png",
	change = "icon16/asterisk_orange.png",
	submit = "icon16/accept.png",
	cancel = "icon16/cancel.png",
	move = "icon16/book_go.png",
	spawn = "icon16/wand.png",
	swap = "icon16/arrow_switch.png",
	tab = "icon16/application_form.png",
	window = "icon16/application_double.png",
	refresh = "icon16/arrow_refresh.png",
	close = "icon16/application_form_delete.png",
	references = "icon16/book_addresses.png",
	copymove = "icon16/book_next.png",
	photo = "icon16/photo.png",
}

local npcd_icon_mat = Material( UI_ICONS.npcd )

UI_ICONS_SETS = {
	drop_set = "icon16/briefcase.png",
	entity = "icon16/bricks.png",
	nextbot = "icon16/monkeytux.png",
	npc = "icon16/monkeytux.png",
	player = "icon16/user_suit.png",
	squad = "icon16/color_swatch.png",
	weapon_set = "icon16/gun.png",
}

SPAWN_SETS = {
	["squad"] = "Squads",
	["npc"] = "NPCs",
	["entity"] = "Entities",
	["nextbot"] = "Nextbots",
	["weapon_set"] = "Weapon Sets",
	["drop_set"] = "Drop Sets",
	["player"] = "Player Presets",
}

t_TYPE_ICON = {
	["angle"] = "icon16/gun.png",
	["any"] = "icon16/rainbow.png",
	["boolean"] = "icon16/lightbulb_off.png",
	["color"] = "icon16/color_wheel.png",
	["enum"] = "icon16/table_relationship.png",
	["fraction"] = "icon16/hourglass.png",
	["function"] = "icon16/chart_line.png",
	["int"] = "icon16/calculator_link.png",
	["number"] = "icon16/calculator.png",
	["struct"] = "icon16/chart_organisation.png",
	["struct_table"] = "icon16/table_multiple.png",
	["table"] = "icon16/chart_bar.png",
	-- ["table"] = "icon16/table.png",
	["vector"] = "icon16/car.png",
	-- ["vector"] = "icon16/vector.png",
	["string"] = "icon16/spellcheck.png",
	-- ["preset"] = "icon16/folder_heart.png",
	["preset"] = "icon16/folder_table.png",
}

t_TYPE_TIP = {
	["angle"] = "Angle",
	["any"] = "Any (Angle, Boolean, Color, Int, Number, Vector)",
	["boolean"] = "Boolean",
	["color"] = "Color",
	["enum"] = "Has Enums",
	["fraction"] = "Fraction",
	["function"] = "Function",
	["int"] = "Integer",
	["number"] = "Number",
	["struct"] = "Struct",
	["struct_table"] = "Table (Struct)",
	["table"] = "Table",
	["vector"] = "Vector",
	["preset"] = "Preset",
	["entity"] = "Entity Class",
	["string"] = "String",
}

t_TYPE_TIP_DESC = {
	["angle"] = "Angle: Direction",
	["any"] = "Any (Angle, Boolean, Color, Int, Number, Vector)",
	["boolean"] = "Boolean: True or false",
	["color"] = "Color: RGB",
	["enum"] = "Enums: Preselected values",
	["fraction"] = "Fraction: A version of a number value that can be written as either a fraction or a decimal. The fraction and the decimal are the same number in different forms",
	["function"] = "Function: Allows the value to be the result of a function",
	["int"] = "Integer: Numbers without decimals",
	["number"] = "Number: An amount",
	["struct"] = "Struct: A value consisting of multiple values",
	["struct_table"] = "Table (Struct): A list of entries each containing multiple values",
	["table"] = "Table: A list of values",
	["vector"] = "Vector: Position, velocity, etc",
	["entity"] = "Entity Class: The kind of entity it is",
	["preset"] = "Preset: A type and name from an existing category",
	["string"] = "String: Text",
}

f_cnameget = {
	["weapon_set"] = function( prstbl )
		if !prstbl["weapons"] then return nil end
		local k, v = next( prstbl["weapons"] )
		if v then
			return GetPresetName( v.classname )
		else
			return nil
		end
	end,
	["drop_set"] = function( prstbl )
		if !prstbl["drops"] then return nil end
		local k, v = next( prstbl["drops"] )
		if v then
			return v.entity_values and GetPresetName( v.entity_values.classname ) or nil
		else
			return nil
		end
	end,
}

include( "cl_npcd_gui_editor.lua" )

function NPCDClientThink()
	if IsValid( SettingsWindow ) and SettingsWindow:IsVisible() then 
		local noerred, err
		if co_valuelister then
			noerred, err = coroutine.resume( co_valuelister )
			if !noerred or err then Error("\nError: coroutine \"valuelister\" did something weird: ", err,"\n\n") end
		end
		if ( !co_valuelister or !noerred ) then
			co_valuelister = coroutine.create( FillValueListRoutine )
		end
	end
end

function QueuePostQuery( prof, timeout, func )
	table.insert( postqueryQueue, {
		prof = prof,
		func = func,
		timeout = timeout,
		start = CurTime(),
	} )
end

function RunPostQuery()
	if cl_cvar.cl_debugged.v:GetBool() and table.Count( postqueryQueue ) > 0 then
		print( "RUNNING "..table.Count( postqueryQueue ).." POST QUERY FUNCS" )
	end
	local completed = {}
	for k, f in ipairs( postqueryQueue ) do
		if f.prof and cl_Profiles[f.prof] == nil then continue end
		if f.timeout and CurTime() > f.start + f.timeout then
			completed[k] = k
			continue
		end
		if isfunction( f.func ) then f.func() end
		completed[k] = k
	end
	for k in SortedPairs( completed, true ) do
		table.remove( postqueryQueue, k )
	end
end

net.Receive( "npcd_stress_update", function()
	cl_stress = net.ReadFloat()
	cl_pressure = net.ReadFloat()
end )

net.Receive( "npcd_ply_preset", function() 
	cl_ply_preset = net.ReadString()
end )

net.Receive( "npcd_settings_send_start", function()
	print( "npcd > Receiving update..." )
	UpdateSettingsTitle()
	if cl_cvar.cl_debugged.v:GetBool() then print( "settings start", CurTime() ) end
	tmp_Profiles = {}
	table.Empty( query_stream )
	cl_receiving = true
end)

net.Receive( "npcd_settings_send", function()
	-- local pname = net.ReadString()
	-- local tblname = net.ReadString()
	-- local emptyset = net.ReadBool()
	-- local prsname
	-- local prstbl
	-- if !emptyset then
	-- 	prsname = net.ReadString()
	-- 	prstbl = net.ReadTable()
	-- end
	local chknum = net.ReadFloat( c )
	local len = net.ReadUInt( 16 )
	local data = net.ReadData( len )

	-- if lastchknum != chknum-1 then
	-- 	Error("\nnpcd > npcd_settings_send > invalid receive sequence: ", lastchknum, " -> ", chknum, " ( ",pname," ",tblname," ",prsname," ",prstbl," )\n\n" )
	-- 	query_erred = true
	-- end

	-- lastchknum = chknum

	if cl_cvar.cl_debugged.v:GetBool() then print( "settings received", chknum, len, #data, CurTime() ) end

	query_stream[chknum] = data

	-- tmp_Profiles[pname] = tmp_Profiles[pname] or {}
	-- tmp_Profiles[pname][tblname] = tmp_Profiles[pname][tblname] or {}
	-- if prsname and prstbl then
	-- 	tmp_Profiles[pname][tblname][prsname] = prstbl
	-- end
end)

net.Receive( "npcd_settings_send_end", function()
	if cl_cvar.cl_debugged.v:GetBool() then print( "settings end", CurTime() ) end

	local totalcount = net.ReadFloat()

	local query_erred

	tmp_Profiles, query_erred = ReadDatastream( query_stream, totalcount )

	if query_erred then
		Error("\nError: npcd > npcd_settings_send_end > INCOMPLETE QUERY ", c, totalcount,"\n\n" )
		cl_receiving = nil
		timer.Simple( query_delay, function() QuerySettings( true ) end )
		-- SettingsWindow:Close()
		return
	end

	local pk_t = {}
	local changed = false

	if !table.IsEmpty( tmp_Profiles ) then
		changed = true
	end

	FixProfileNames( tmp_Profiles )
	-- for pname, ptbl in pairs( tmp_Profiles ) do
	-- 	if isnumber( pname ) then
	-- 		local n = tostring( pname )
	-- 		tmp_Profiles[n] = tmp_Profiles[pname]
	-- 		if tmp_Profiles[pname] != tmp_Profiles[n] then
	-- 			tmp_Profiles[pname] = nil
	-- 		end
	-- 	end
	-- end
	for pname, ptbl in pairs( tmp_Profiles ) do
		cl_Profiles[pname] = {}
		for set in pairs( PROFILE_SETS ) do
			-- tmp_Profiles[pname][set] = tmp_Profiles[pname][set] or {}
			cl_Profiles[pname][set] = tmp_Profiles[pname][set] or {}
		end
		
	end

	// remove deleted profiles
	for pname in pairs( cl_profiles_manifest ) do
		pk_t[pname] = true
	end
	for pname in pairs( cl_Profiles ) do		
		if pk_t[pname] then
			continue
		else
			-- print( pname, " has been removed!" )
			print( "npcd > Profile removed: "..pname)
			changed = true
			cl_Profiles[pname] = nil
		end
	end

	for pname, ptbl in SortedPairs( cl_Profiles ) do
		for sets, settbl in SortedPairs( ptbl ) do
			if cl_profiles_manifest[pname][sets] != table.Count( settbl ) then
				cl_Profiles = {}
				if IsValid(SettingsWindow) and ispanel(SettingsWindow) then
					SettingsWindow:Close()
				end
				ErrorNoHalt( "\nError: npcd profile counts mismatch with manifest... manifest count:", cl_profiles_manifest[pname][sets], " prof:", pname, " ptbl:",ptbl, " sets:",sets," settbl:", settbl, " settblcount:",table.Count( settbl ), "\n\n" )
				PrintTable( cl_profiles_manifest )
				PrintTable( table.GetKeys( settbl ) )
				return
			end
		end
	end

	if changed then
		local updc = table.Count(tmp_Profiles)
		if updc > 0 then 
			print( "npcd > Profiles updated (" .. updc .."): "..table.concat( table.GetKeys(tmp_Profiles), ", ") )
		end
		prof_changed = true // for npcd spawnmenu populate
		RecursiveFixUserdata( cl_Profiles )
		if cl_Profiles[active_prof] == nil then DeselectSettingsList() end

		local svar = GetConVar( "npcd_spawner_set" )
		local pvar = GetConVar( "npcd_spawner_prs" )
		if svar != nil then
			-- svar:SetString( "" )
			-- pvar:SetString( "" )
			local sv = svar:GetString()
			local pv = pvar:GetString()
			language.Add( "tool.npcd_spawner.0",
				npcd.cl_currentProfile != nil and ( npcd.cl_currentProfile
				.. ( sv != "" and " > " .. sv .. " > " .. pv or " <no preset selected>" ) )
				or "<no active profile>"
			)
		end
	else
		print( "npcd > No profile changes in update" )
	end
	-- print( "npcd > Profiles query complete")

	UpdateProfilesList()
	UpdatePresetSelection()

	if NPCDSpawnMenu then NPCDSpawnMenu:CallPopulateHook( "PopulateNPCD" ) end
	if NPCDSideBar and NPCDSideBar.Options then NPCDSideBar.Options:Recount() end

	timer.Simple( 0, function()
		cl_receiving = nil
		if !cl_sending and cl_committed then
			RemakeValueEditors()
			cl_committed = nil
		end
		UpdateSettingsTitle()
		RunPostQuery()
	end )
end)

net.Receive("npcd_currentprofile", function()
	if cl_cvar.cl_debugged.v:GetBool() then print( "currentprofile", CurTime() ) end
	cl_lastProfile = cl_currentProfile
	cl_currentProfile = net.ReadString()
	if cl_lastProfile != cl_currentProfile then
		-- print( "npcd > Current Profile: " .. cl_currentProfile ) // announced in chat
		prof_changed = true // for NPCD populate hook

		local svar = GetConVar( "npcd_spawner_set" )
		local pvar = GetConVar( "npcd_spawner_prs" )
		if svar != nil then
			svar:SetString( "" )
			pvar:SetString( "" )
			local sv = svar:GetString()
			local pv = pvar:GetString()
			language.Add( "tool.npcd_spawner.0",
				npcd.cl_currentProfile != nil and ( npcd.cl_currentProfile
				.. ( sv != "" and " > " .. sv .. " > " .. pv or " <no preset selected>" ) )
				or "<no active profile>"
			)
		end
	end
	if NPCDSideBar and NPCDSideBar.Options then NPCDSideBar.Options:Recount() end
	if SettingsList then UpdateProfilesList() end
	if NPCDSpawnMenu and prof_changed then NPCDSpawnMenu:CallPopulateHook( "PopulateNPCD" ) end
end )

// profile manifest and preset counts
net.Receive( "npcd_settings_manifest_start", function()
	if cl_cvar.cl_debugged.v:GetBool() then print( "manifest start", CurTime() ) end
	cl_profiles_manifest = {}
	cl_receiving_man = true
end)

net.Receive( "npcd_settings_manifest", function()
    local pname = net.ReadString()
    local c_drop_set = net.ReadFloat()
    local c_player = net.ReadFloat()
    local c_npc = net.ReadFloat()
    local c_entity = net.ReadFloat()
    local c_nextbot = net.ReadFloat()
    local c_squad = net.ReadFloat()
    local c_spawnpool = net.ReadFloat()
    local c_weapon_set = net.ReadFloat()

    cl_profiles_manifest[pname] = {
        ["drop_set"] = c_drop_set,
        ["player"] = c_player,
        ["npc"] = c_npc,
        ["entity"] = c_entity,
        ["nextbot"] = c_nextbot,
        ["squad"] = c_squad,
        ["spawnpool"] = c_spawnpool,
        ["weapon_set"] = c_weapon_set,
    }
end)

net.Receive( "npcd_settings_manifest_end", function()
	if cl_cvar.cl_debugged.v:GetBool() then print( "manifest end", CurTime() ) end
	cl_receiving_man = nil
	if SettingsList and !cl_receiving then UpdateProfilesList() end
end )

--[[
    Changes are SEPERATE from the received profiles until the user commits
    which allows the profile to be reloaded without losing pending changes
    server will use CreatePreset() for each preset in the commit
]]

local commit_delay = 3
local lastcommit = -commit_delay

function SendSettingsCommit()
	if cl_sending or CurTime() - lastcommit < commit_delay then
		if IsValid( CommitButton ) then
			CommitButton:SetDisabled( false )
			ClearButton:SetDisabled( false )
		end
		return
	end
	cl_sending = true

	UpdateSettingsTitle()

	local stime = CurTime()
	local latest = 0
	local sent = 0

	local dosave = {}

	for p, pt in pairs( PendingSettings ) do
		for s, st in pairs( pt ) do
			for prsname in pairs( st ) do
				if !HasPreset( PendingAdd, p, s, prsname ) then
					PendingSettings[p][s][prsname] = nil
				else
					dosave[p] = true
					sent = sent + 1
				end
			end
		end
	end

	for pname, ptbl in pairs( PendingRemove ) do
		for set in pairs( ptbl ) do
			for prs in pairs( ptbl[set] ) do
				sent = sent + 1
			end
		end
		dosave[pname] = true
	end

	local remove_send = !table.IsEmpty( PendingRemove ) and BuildDatastream( PendingRemove ) or nil
	if remove_send then
		net.Start( "npcd_cl_settings_remove_start" )
		net.SendToServer()
		latest = SendDatastream( "npcd_cl_settings_remove_send", remove_send, nil, true, latest )
		timer.Simple( latest, function()
			net.Start( "npcd_cl_settings_remove_end" )
				net.WriteFloat( table.Count( remove_send ) )
			net.SendToServer()
		end )
	end

	local commit_send = {}
	if !table.IsEmpty( PendingSettings ) then
		commit_send = BuildDatastream( PendingSettings )
	end
	
	net.Start( "npcd_cl_settings_commit_start" )
	net.SendToServer()

	// send presets in batches
	latest = SendDatastream( "npcd_cl_settings_commit_send", commit_send, nil, true, latest )

	timer.Simple( latest, function()
		if cl_cvar.cl_debugged.v:GetBool() then print( "commit end", CurTime() ) end
		net.Start( "npcd_cl_settings_commit_end" )
			net.WriteFloat( table.Count( commit_send ) )
		net.SendToServer()

		for prof in pairs( dosave ) do
			if cl_cvar.cl_debugged.v:GetBool() then print( "saving: "..prof ) end
			ClientSaveProfile( prof )
		end

		lastcommit = CurTime()
		cl_committed = true

		timer.Simple( commit_delay, function()
			if IsValid( CommitButton ) then
				CommitButton:SetDisabled( false )
				ClearButton:SetDisabled( false )
			end
		end )

		print( "npcd commit: " .. sent .. " sent in " .. math.Round( CurTime() - stime, 2 ) .. "s" )
	end )

	PendingRemove = {}
end

net.Receive( "npcd_settings_report_start", function()
	print( "npcd > Receiving commit report..." )
	if cl_cvar.cl_debugged.v:GetBool() then print( "report start", CurTime() ) end
	table.Empty( report_stream )
end)

net.Receive( "npcd_settings_report_send", function()
	local chknum = net.ReadFloat( c )
	local len = net.ReadUInt( 16 )
	local data = net.ReadData( len )

	if cl_cvar.cl_debugged.v:GetBool() then print( "report received", chknum, len, #data, CurTime() ) end

	report_stream[chknum] = data
end)

net.Receive( "npcd_settings_report_end", function()
	if cl_cvar.cl_debugged.v:GetBool() then print( "settings end", CurTime() ) end

	local totalcount = net.ReadFloat()

	local report_tbl, query_erred = ReadDatastream( report_stream, totalcount )

	if query_erred then
		Error("\nError: npcd > npcd_settings_report_end > INCOMPLETE COMMIT REPORT ", totalcount,"\n\n" )
		-- cl_receiving = nil
		-- timer.Simple( query_delay, function() QuerySettings( true ) end )
		-- SettingsWindow:Close()
		return
	end

-- // commit error report and final confirmation
-- net.Receive( "npcd_settings_report", function()
-- 	local suctbl = net.ReadTable()
-- 	local noerr = net.ReadBool()
-- 	local errtbl

	if cl_cvar.cl_debugged.v:GetBool() then 
		print( "commit report", "count:"..tostring( table.Count( report_tbl.suc ) + table.Count( report_tbl.err ) ), CurTime() ) 
	end

	if !table.IsEmpty( report_tbl.err ) then
		print("npcd > Commit errors occurred:")
		local errtbl = report_tbl.err
		if cl_cvar.cl_debugged.v:GetBool() then PrintTable( errtbl ) end
		if ispanel( SettingsWindow ) and SettingsWindow:IsValid() then
			local errnotif = vgui.Create( "DFrame", SettingsWindow )
			local errscrpan = vgui.Create( "DScrollPanel", errnotif )
			local errtext = vgui.Create( "DLabel", errscrpan )
			local errpan = vgui.Create( "DPanel", errnotif )
			errnotif:SetDraggable( true )
			errnotif:SetSizable( true )
			errnotif:SetTitle( "npcd error" )
			errpan:SetZPos( -1 )
			errscrpan:DockMargin( marg, marg, marg, marg )

			errnotif:MakePopup()
			errscrpan:Dock( FILL )
			errpan:Dock( FILL )
			local lines = 2
			local txt = "The following presets could not be created:"
			local tw = #txt
			table.sort( errtbl, function( a, b )
				return tostring(a[1])..tostring(a[2])..tostring(a[3]) < tostring(b[1])..tostring(b[2])..tostring(b[3]) 
			end )
			for _, err in pairs( errtbl ) do
				txt = txt .. "\n<".. tostring(err[1]) .."> ["..tostring(err[2]).."] ".. tostring(err[3]) .. ( tostring(err[4]) and " (" .. tostring(err[4]) .. ")" or "" )
				print( txt )
				lines = lines + 1
			end
			errtext:SetText( txt )
			errtext:SetDark( true )
			errtext:SetAutoStretchVertical( true )
			errtext:SetWrap( true )
			errtext:Dock( FILL )
			local x, y = PendingList:LocalToScreen()
			errnotif:SetPos( x - 50, y )

			surface.SetFont( errtext:GetFont() )
			local w, h = surface.GetTextSize( "txt" )
	
			errnotif:SetWidth( 450 )
			errnotif:SetTall( math.min( 24 + ( 1 + lines ) * h + marg * 2, 500 ) )
		end
	-- else // no errors
	-- 	PendingSettings = {}
	-- 	PendingAdd = {}
	end

	// keep nonsuccesses pending
	-- local newpending = {}
	-- local newpendingadd = {}
	-- for _, err in pairs( errtbl ) do
	-- 	local p = err[1]
	-- 	local s = err[2]
	-- 	local prs = err[3]
	-- 	if HasPreset( PendingSettings, p, s, prs ) then
	-- 		AddPresetPend( newpending, p, s, prs, PendingSettings[p][s][prs] )
	-- 		AddPresetPend( newpendingadd, p, s, prs )
	-- 	end
	-- end
	-- PendingSettings = newpending
	-- PendingAdd = newpendingadd

	local succ_count
	for _, succ in pairs( report_tbl.suc ) do

		local p = succ[1]
		local s = succ[2]
		local prs = succ[3]
		succ_count = ( succ_count or 0 ) + 1
		-- if cl_cvar.cl_debugged.v:GetBool() then print("preset sucess: ",p,s,prs ) end
		RemovePresetPend( PendingSettings, p, s, prs )
		RemovePresetPend( PendingAdd, p, s, prs )
	end

	if succ_count then
		print( succ_count, " presets successfully committed" )
	end

	timer.Simple( 0, function()
		cl_sending = nil
		if !cl_receiving and cl_committed then
			RemakeValueEditors()
			cl_committed = nil
		end
		UpdateSettingsTitle()
	end )

end )

net.Receive( "npcd_chased", function()
    chase_status = net.ReadBool()
end)

net.Receive( "npcd_spawn_count", function()
    local pool = net.ReadString()
    local wcount = net.ReadFloat()
    local count = net.ReadFloat()
    local sqcount = net.ReadFloat()
    local spawnlimit = net.ReadFloat()
    local splimited = true
    local squadlimit = net.ReadFloat()
    local sqlimited = true

    if spawnlimit < 0 then
        splimited = false
        spawnlimit = squadlimit
    end
    if squadlimit < 0 then
        sqlimited = false
        squadlimit = spawnlimit
    end

    tmp_spawnpools[pool] = {
        ["wcount"] = wcount,
        ["count"] = count,
        ["sqcount"] = sqcount,
        ["spawnlimit"] = spawnlimit,
        ["splimited"] = splimited,
        ["sqlimited"] = sqlimited,
        ["squadlimit"] = squadlimit,
    }
end )

net.Receive( "npcd_spawn_count_end", function()
    spawnpools = tmp_spawnpools
    tmp_spawnpools = {}
end)

function ShowSquadLimits()
    local i = 0
    -- print(table.Count(spawnpools))
    for p, ptbl in SortedPairs(spawnpools) do
        local bar_h = ScrH() * 0.1 -- * 0.75 / table.Count(spawnpools)
        local bar_x = ScreenScale( 10 ) + ( bar_w * i ) + ( ScreenScale(2) * i )
		if cl_cvar.show_stress.v:GetBool() then bar_x = bar_x + stress_bar_w + ScreenScale(2) end

		local font_h = draw.GetFontHeight("DermaDefault")
		local bar_gap = font_h / 2 + 1

        -- local bar_gap = ScreenScale(5) / 2
        local bar_mid = ScrH() / 2 
        local txt_ofs = bar_w / 2

        draw.DrawText( string.sub(p, 1, 3), nil, bar_x + txt_ofs, bar_mid - bar_gap, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )

        //spawnlimit
        if ptbl.spawnlimit then
            local cperc = ptbl.count / ptbl.spawnlimit
            local wperc = ptbl.wcount / ptbl.spawnlimit            
            local bar_y = bar_mid - bar_h - bar_gap

            if ptbl.splimited then
                draw.DrawText( math.Round( ptbl.spawnlimit ), nil, bar_x + txt_ofs, bar_y - font_h - 2, Color( 255, 222, 222, 54 ), TEXT_ALIGN_CENTER )
            end

            surface.SetDrawColor( 64,0,0,256 )
            surface.DrawRect( bar_x , bar_y , bar_w , bar_h )
            if cperc < 1 then surface.SetDrawColor( 0, 0, 128 + ( 128 * cperc ), 128 ) else surface.SetDrawColor( 0, 0, 255, 64 ) end 
            surface.DrawRect( bar_x , ( bar_y + bar_h ) - bar_h * cperc , bar_w , bar_h * cperc )
            if wperc < 1 or !ptbl.splimited then surface.SetDrawColor( 0, 128 + ( 128 * wperc ), 0, 75 ) else surface.SetDrawColor( 255, 255, 0, 128 ) end
            surface.DrawRect( bar_x , ( bar_y + bar_h ) - ( bar_h * wperc ) , bar_w , bar_h * wperc )
        end

		//squadlimit
        if ptbl.squadlimit then
            local sperc = ptbl.sqcount / ptbl.squadlimit

            local sq_bar_x = ScreenScale( 10 ) + ( bar_w * i ) + ( ScreenScale(2) * i )
			if cl_cvar.show_stress.v:GetBool() then sq_bar_x = sq_bar_x + stress_bar_w + ScreenScale(2) end
            local sq_bar_y = bar_mid + bar_gap

            if ptbl.sqlimited then
                draw.DrawText( math.Round( ptbl.squadlimit ), nil, bar_x + txt_ofs, sq_bar_y + bar_h, Color( 255, 222, 222, 54 ), TEXT_ALIGN_CENTER )
            end

            surface.SetDrawColor( 64,0,0,256 )
            surface.DrawRect( sq_bar_x , sq_bar_y , bar_w , bar_h )
            if sperc < 1 or !ptbl.sqlimited then surface.SetDrawColor( 0, 128 + ( 128 * sperc ), 0, 75 ) else surface.SetDrawColor( 255, 255, 0, 128 ) end
            surface.DrawRect( sq_bar_x , sq_bar_y , bar_w , bar_h * sperc )
        end
        
        i = i + 1
    end
end

function ShowChaseStatus()
    draw.DrawText( chase_status, nil, ScrW() / 2 , ScrH() / 2 , Color( 255, 222, 222, 128 ), TEXT_ALIGN_CENTER )
end

function ShowStress()
	if !cl_stress or !cl_pressure then return end

	local bar_h = ScrH() * 0.1 -- * 0.75 / table.Count(spawnpools)
	local bar_x = ScreenScale( 10 )
	local font_h = draw.GetFontHeight("DermaDefault")
	local bar_gap = font_h / 2 + 1
	-- local bar_gap = ScreenScale(5) / 2
	local bar_mid = ScrH() / 2 
	local txt_ofs = stress_bar_w / 2

	local sperc = cl_stress / 1
	local pperc = cl_pressure / 1
	local bar_y = bar_mid - bar_h - bar_gap
	

	-- local p_bar_x = ScreenScale( 10 )
	local p_bar_y = bar_mid + bar_gap

	surface.SetDrawColor( 64,0,0,256 )
	surface.DrawRect( bar_x , bar_y , stress_bar_w , bar_h )
	if sperc < ( cvar.stress_breakpoint.v:GetFloat() ) then surface.SetDrawColor( 128 + ( 128 * sperc ), 128, 128, 128 ) else surface.SetDrawColor( 255, 0, 0, 128 ) end 
	surface.DrawRect( bar_x , ( bar_y + bar_h ) - bar_h * sperc , stress_bar_w , bar_h * sperc )

	surface.SetDrawColor( 64,0,0,256 )
	surface.DrawRect( bar_x , p_bar_y , stress_bar_w , bar_h )
	if pperc < 1 then surface.SetDrawColor( 128 + ( 128 * pperc ), 128 + ( 128 * pperc ), 0, 128 ) else surface.SetDrawColor( 255, 0, 0, 128 ) end 
	surface.DrawRect( bar_x , p_bar_y , stress_bar_w , bar_h * pperc )
end

function ShowPreset()
	local font
	if ScrH() <= 800 then
		font = "Trebuchet18"
	else
		font = "Trebuchet24"
	end
	surface.SetFont( font )
	local w, h = surface.GetTextSize( cl_ply_preset )
	local x, y = 10, ScrH() - ScreenScale(65) //162.5

	draw.RoundedBox( 4, -4, y-6, h+w+x+24, h+12, Color( 0, 0, 0, 100 ) )
	draw.DrawText( cl_ply_preset, font, x+h+8, y, Color( 255, 255, 100, 200 ) )

	surface.SetMaterial( npcd_icon_mat )
	surface.SetDrawColor( 255, 255, 255, 100 )
	surface.DrawTexturedRect( x, y+1, h, h )
end

hook.Add( "HUDPaint", "NPCD HUD", function()
	if drawhud:GetBool() then
		if cl_cvar.show_limits.v:GetBool() then ShowSquadLimits() end
		if cl_cvar.show_stress.v:GetBool() then ShowStress() end

		if ( scoreboard or cl_cvar.show_preset.v:GetBool() ) and cl_ply_preset != "" then ShowPreset() end
	end
end )

hook.Add( "ScoreboardShow", "NPCD Show Scoreboard", function()
	scoreboard = true
end )
hook.Add("ScoreboardHide", "NPCD Hide Scoreboard", function()
	scoreboard = false
end )

function QuerySettings( updateall )
	if cl_cvar.cl_debugged.v:GetBool() then print("Querying settings...") end
	if CurTime() - lastquery >= query_delay and !cl_receiving then
		local ua = updateall
		if ua == nil then ua = false end
		net.Start("npcd_cl_settings_query")
			net.WriteBool( ua )
		net.SendToServer()
		lastquery = CurTime()
	-- else
	-- 	debug.Trace()
	-- 	print( "Query denied: ", CurTime() - lastquery > 3, !cl_receiving )
	end
end

function RequestEntTest( class, set )
	print("npcd > Requesting value test: "..tostring(set)..": "..tostring(class))
	net.Start("npcd_test_request")
		net.WriteString(class)
		net.WriteString(set)
	net.SendToServer()
end

function ShowHelpWindow()
	local HelpWin = vgui.Create( "DFrame" )

    HelpWin:SetSize( 500, 300 )
	HelpWin:Center()

    HelpWin:SetTitle( "npcd Help" )
    HelpWin:SetDraggable( true )
	HelpWin:SetSizable( true )
    HelpWin:MakePopup()	

	local helppan = vgui.Create( "DScrollPanel", HelpWin )
	helppan:Dock( FILL )
	helppan:DockMargin( 5, 0, 0, 0 )

	// label string size limit
	local helptext = {
		[1] = "--- General Overview ---" 
		.. "\n\nNPC Daemon can:"
		.. "\n - Customize entity and player presets with 100+ different properties"
		.. "\n - Automatically spawn squads, smartly, around the map"
		.. "\n - Manipulate spawned NPC schedules to seek out or chase enemies"
		.. "\n - Create drop sets for entities and players"
		.. "\n - Create equippable weapon sets for NPCs and players"
		.. "\n - Tweak A LOT of options",

		[2] = "\n\n--- Quick Start For Adding New Automatic Spawns ---"
		.. "\n\n 0. Open \"Configure Profiles\""
		.. "\n 1. Create a squad/npc/entity/nextbot preset"
		.. "\n 2. Edit or create a spawnpool preset"
		.. "\n 3. Add the preset you want to have spawn to the spawnpool's list of spawns",

		[3] = "\n\n--- Spawning ---"
		.. "\n\nThe spawnmenu can be used to manually spawn presets. The right click menu has options for using the toolgun or spawning for other players."
		.. "\n\nThe automatic spawner goes through all active spawnpools, picking presets to fulfill each pool's quotas. Only the active profile is used."
		.. "\n\nPresets must be assigned to the spawnpool to be automatically spawned. That means you need a spawnpool and a squad/npc/entity/nextbot preset to start automatically spawning entities."
		-- .. "\n\nThe frequency of spawns is affected by \"pressure,\" and pressure is affected by \"stress.\""
		.. "\n\nTo help with the gameplay flow, the frequency of spawns is affected by a global \"Pressure\" value, and Pressure is affected by a player \"Stress\" value."
      .. "\n - Pressure directly determines how frequently the autospawner spawns. Pressure increases or decreases over time based on the average player Stress."
      .. "\n - Stress increases for each player when things happen in combat, such as taking/receiving damage and kills.",

		[4] = "\n\n--- NPC Scheduling ---"
		.. "\n\nNPCs have various options to their behavior that can be manipulated, primarily through the use of the game's NPC schedules. By default, an idle NPC will be sent to seek out a nearby enemy. You can also customize an NPC to constantly chase someone."
      .. "\n\nThe NPC must be using the Source engine's scheduling system for this to work on them. Most Lua-based NPCs don't use this, unfortunately.",

		[5] = "\n\n--- Configuration ---"
		.. "\n\nNPCD Options are avaiable in the options tab of the spawnmenu sidebar."
		.. "\n\nThe profile editor lets you create profiles, presets, and edit preset values."
		.. "\n\nProfiles allow switching between entire collections of presets. Profiles are placed in the 'garrysmod/data/npcd' folder, consider sharing your profiles!"
		.. "\n\nProfiles actions (add/duplicate/remove/rename) are done in file immediately. Removed profiles are actually moved to the 'garrysmod/data/npcd/trash' folder. Profiles are automatically saved when any pending changes are committed."
      .. "\n\nIn the profile editor, selecting a preset in the presets list opens the preset editor."
		.. "\n\nMost values allow for different data types. The dropdown box in the bottom left of each value box allows changing between available data types."
		.. "This includes enums (preselected values) and functions to allow randomness. Enums can be converted to their real value by changing to the real value's data type with the enum selected."
      .. "\n\nYou must submit changes for preset changes to take effect. Presets can be copied, renamed, and moved between profiles.",

		[6] = "\nValues can be restored to the original value or cleared to the nil/default value. Buttons, descriptions, and icons can be hovered over for more info. Right-clicking on lists often has various options."
		.. "\n\nMake sure NPCs, Nextbots, and (other) Entities are placed in their correct preset types, otherwise errors could occur."
		.. "\n\n\n--- Preset Types ---"
		.. "\n\nSpawnpool: The main source of spawns during autospawning. Any presets assigned to the pool will be spawned within the given radius limits around players and spawn beacons."
		.. "Includes spawn limits and when & where things can be spawned. All spawnpools are iterated through during a run of automatic spawns.",
		
		[7] = "\nSquad: Contains any number of npc/nextbot/entity presets."
		.. "\n\nNPC: Intended for NPC entities only. Some entity classes have class-specific values."
		.. "\n\nNextBot: Intended for NextBot entities only.",

		[8] = "\nEntity: Intended for non-NPC/non-NextBot entities, like props or items. NPC/NextBots can be safely placed in this preset type,"
		.. "but they may have less values available than in NPC/Nextbot preset types. Some default values differ from NPCs/NextBots presets (e.g. stress multiplier). Can contain class-specific values."
		.. "\n\nPlayer: Allows players to have npcd entity properties applied to them on spawn or manually through the spawnmenu. When applied on spawn, the preset is chosen randomly from the available presets and can have required player conditions."
		.. "\n\nWeapon Set: A NPC or player can be given a weapon set. By default, a single weapon from the set is picked to be given. Only applies to NPCs and players."
		.. "\n\nDrop Set: Any entity can have a drop set containing a variety of possible things, dropped either on death or on damage.",

		[9] = "\n\n--- Included Class Specific Properties (WIP!) ---\n",
	}

	for i, help in ipairs( helptext ) do
		local t = vgui.Create( "DLabel", helppan )
		t:SetWrap( true )
		t:SetAutoStretchVertical( true )
		t:SetText( help )
		t:Dock( TOP )
	end

	for tname in pairs( t_lookup["class"] ) do
		for cn in SortedPairs( t_lookup["class"][tname] ) do
			local t = vgui.Create( "DLabel", helppan )
			t:SetWrap( true )
			t:SetAutoStretchVertical( true )
			t:SetText( "<".. tname .. "> " .. cn )
			t:Dock( TOP )
		end
	end

	local credits = {
		[1] = "\n\n--- Credits ---"
		.. "\n\ncreated by sockpuppetclock"
		.. "\ninspired by Jason's \"Zombie/NPC Invasion\" addon and Kiddoneshon & moomoohk's \"Zombie/NPC Invasion+\" update and SMOD's mapadd system\n"
	}

	for i, help in ipairs( credits ) do
		local t = vgui.Create( "DLabel", helppan )
		t:SetWrap( true )
		t:SetAutoStretchVertical( true )
		t:SetText( help )
		t:Dock( TOP )
	end

end

concommand.Add( "npcd_settings_open", StartSettingsPanel )
concommand.Add( "npcd_settings_close", function()
	if IsValid( SettingsWindow ) and ispanel( SettingsWindow ) then
		SettingsWindow:Close()
	end
end )
concommand.Add( "npcd_settings_window_toggle", function()
	if IsValid(SettingsWindow) and ispanel(SettingsWindow) then
		if SettingsWindow:IsVisible() then
			SettingsWindow:Close()
		else
			StartSettingsPanel()
		end
	else
		StartSettingsPanel()
	end
end )
concommand.Add( "npcd_profile_query", function()
	-- if CurTime() - lastquery > 3 then
		QuerySettings( true )
	-- 	lastquery = CurTime()
	-- end
end )
concommand.Add( "npcd_settings_help", ShowHelpWindow )
concommand.Add( "npcd_settings_commit", SendSettingsCommit )
concommand.Add( "npcd_settings_window_reset", function()
	RemoveSettingsPanel()
end )

concommand.Add( "npcd_fill", function( ply )
	if CheckClientPerm2( ply, "settings" ) then
		net.Start("npcd_fill")
		net.SendToServer()
	end
end )

concommand.Add( "npcd_clean", function( ply )
	if CheckClientPerm2( ply, "settings" ) then
		net.Start("npcd_clean")
		net.SendToServer()
	end
end )

concommand.Add( "npcd_direct", function( ply )
	if CheckClientPerm2( ply, "settings" ) then
		net.Start("npcd_direct")
		net.SendToServer()
	end
end )
concommand.Add( "npcd_ply_clear_history", function( ply )
	if CheckClientPerm2( ply, "settings" ) then
		net.Start("npcd_ply_clear_history")
		net.SendToServer()
	end
end )
concommand.Add( "npcd_ply_clear_history", function( ply )
	if CheckClientPerm2( ply, "settings" ) then
		net.Start("npcd_ply_revert_recheck")
		net.SendToServer()
	end
end )
concommand.Add( "npcd_profile_reload_all", function( ply )
	if CheckClientPerm2( ply, "settings" ) then
		net.Start("npcd_profile_reload_all")
		net.SendToServer()
	end
end )

cl_playerPerms = {}
cl_playerPerms_pend = {}
cl_playerPerms_send = {}

function SendPermsCommit()
	table.Empty(cl_playerPerms_send)
	for _, p in ipairs(cl_playerPerms_pend) do
		cl_playerPerms_send[p.id] = p.actions
	end
	-- PrintTable(cl_playerPerms_send)

	net.Start("npcd_perms_commit")
		net.WriteTable(cl_playerPerms_send)
	net.SendToServer()
end

function UpdatePendingClientPerms()
	table.Empty(cl_playerPerms_pend)
	for i, a in SortedPairs(cl_playerPerms) do
		table.insert(cl_playerPerms_pend, {
			id = i,
			actions = table.Copy(a),
		})
	end
end

function RequestClientPerms()
	net.Start("npcd_perms_query")
	net.SendToServer()
end

local PermList

net.Receive("npcd_perms_send", function()
	print("npcd > Receiving client permission list")
	cl_playerPerms = net.ReadTable()
	-- PrintTable(cl_playerPerms)
	UpdatePendingClientPerms()
	if IsValid(PermList) then
		PermList:RebuildList()
	end
	UpdateOptions()
end)

function GetPlayerRole( ply )
	if !IsValid(ply) then
		return ""
	elseif ply:IsSuperAdmin() then
		return "Superadmin"
	elseif ply:IsAdmin() then
		return "Admin"
	elseif ply:IsPlayer() then
		return "Client"
	end
end

perm_boolstr = {
	["true"] = "Allow",
	["nil"] = "Default",
	["false"] = "Deny"
}

function PermEditor()
	UpdatePendingClientPerms()

	local PermWindow = vgui.Create("DFrame")
	PermWindow:SetTitle("npcd > Permissions Editor")
	PermWindow:SetSize(700,500)
	PermWindow:Center()
	PermWindow:SetDraggable(true)
	PermWindow:SetSizable(true)
	PermWindow:SetMinWidth(100)
	PermWindow:SetMinHeight(100)
	
	PermWindow:MakePopup()

	PermList = vgui.Create("DListView", PermWindow)
	PermList:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	PermList:Dock(FILL)
	PermList:SetMultiSelect(false)
	PermList.id = PermList:AddColumn("Steam ID")
	PermList.id:SetFixedWidth(120)
	PermList.name = PermList:AddColumn("Name")
	PermList.name:SetWide(100)
	PermList.role = PermList:AddColumn("Role")
	PermList.role:SetWide()
	PermList:Dock(FILL)

	RequestClientPerms()

	local PermValues = vgui.Create( "DPanel", PermWindow )
	PermValues:SetWide(PermWindow:GetWide())
	PermValues:SetTall(150)
	PermValues:Dock(BOTTOM)

	PermList.columns = {}
	PermValues.actions = {}
	PermValues.labels = {}

	local str_allow = "Allow"
	local str_def = "Default"
	local str_deny = "Deny"

	PermList.buttons = vgui.Create("Panel", PermList)
	PermList.buttons:SetTall(UI_BUTTON_H)
	PermList.buttons:Dock(BOTTOM)

	PermList.buttons.add = vgui.Create("DButton", PermList.buttons)
	PermList.buttons.add:SetText("Add Player")
	PermList.buttons.add:SetSize(UI_BUTTON_W * 3,UI_BUTTON_H)
	PermList.buttons.add:Dock(LEFT)
	PermList.buttons.add:DockMargin(10,0,0,0)

	local precolumns = 3

	PermList.buttons.add.DoClick = function( self )
		local menu = DermaMenu()

			local c = 0
			for _, p in ipairs( player.GetAll() ) do
				if !IsValid(p) then continue end
				local ply = p
				local name = ply:Name()
				local id = ply:SteamID64()
				local skip

				for _,pt in ipairs(cl_playerPerms_pend) do
					if pt.id == id then
						skip = true
						break
					end
				end
				if skip then continue end

				menu:AddOption( tostring( name ) .. " ["..tostring(id).."]", function()
					local line = PermList:AddLine(id, name, GetPlayerRole( ply ))
					for k, act in ipairs(perm_actions) do
						line:SetColumnText(k+precolumns,perm_boolstr[tostring(nil)])
					end
					
					local t = { id = id, actions = {} }
					table.insert(cl_playerPerms_pend,t)
					PermList.buttons.commit:SetEnabled(true)

					PermList:ClearSelection()
					PermList:SelectItem(line)
				end )
				c = c + 1
			end

			menu:AddOption( "<New empty entry> [0]", function()
					local line = PermList:AddLine("0","[Player not in server]")
					for k, act in ipairs(perm_actions) do
						line:SetColumnText(k+precolumns,perm_boolstr[tostring(nil)])
					end

					local t = { id = "0", actions = {} }
					table.insert(cl_playerPerms_pend,t)
					PermList.buttons.commit:SetEnabled(true)

					PermList:ClearSelection()
					PermList:SelectItem(line)
			end)
		menu:Open()
	end

	PermList.buttons.remove = vgui.Create("DButton", PermList.buttons)
	PermList.buttons.remove:SetText("Remove")
	PermList.buttons.remove:SetSize(UI_BUTTON_W * 3,UI_BUTTON_H)
	PermList.buttons.remove:Dock(LEFT)
	PermList.buttons.remove:DockMargin(10,0,0,0)

	PermList.ClearOptions = function( self )
		PermValues.entry:SetEnabled(false)
		PermValues.entry:SetText("")

		for i, act in ipairs(perm_actions) do
			PermValues.actions[act].allow:SetEnabled(false)
			PermValues.actions[act].def:SetEnabled(false)
			PermValues.actions[act].deny:SetEnabled(false)

			PermValues.actions[act].allow:SetChecked(false)
			PermValues.actions[act].def:SetChecked(false)
			PermValues.actions[act].deny:SetChecked(false)
		end
	end
	PermList.buttons.remove.DoClick = function( self )
		local k, line = PermList:GetSelectedLine()
		if line then
			PermList:RemoveLine(k)
			print(k)
			table.remove(cl_playerPerms_pend, k)
		end

		k, line = PermList:GetSelectedLine()

		PermList:ClearOptions()		
		PermList.buttons.commit:SetEnabled(true)
		PermList:RebuildList() // necessary because line ID does not "fall" on remove
	end

	PermList.buttons.commit = vgui.Create("DButton", PermList.buttons)
	PermList.buttons.commit:SetText("Commit Changes")
	PermList.buttons.commit:SetSize(UI_BUTTON_W * 4,UI_BUTTON_H)
	PermList.buttons.commit:Dock(RIGHT)
	PermList.buttons.commit:DockMargin(0,0,10,0)
	PermList.buttons.commit:SetEnabled(false)

	PermList.buttons.commit.DoClick = function( self )
		SendPermsCommit()
		PermList.buttons.commit:SetEnabled(false)
	end

	PermValues.entry = vgui.Create("DTextEntry", PermValues)
	PermValues.entry:SetEnabled(false)
	PermValues.entry:SetPlaceholderText("Steam ID (64-bit number)")

	PermValues.entry.OnChange = function( self )
		local k, line = PermList:GetSelectedLine()
		if line then
			local p = cl_playerPerms_pend[k]
			p.id = self:GetValue()
			local ply = player.GetBySteamID64(p.id)
			line:SetColumnText(1,p.id)
			line:SetColumnText(2, IsValid(ply) and ply:Name() or "[Player not in server]")
			line:SetColumnText(3, GetPlayerRole( ply ))
			PermList.buttons.commit:SetEnabled(true)
		end
	end

	PermValues.labels.allow = vgui.Create("DLabel", PermValues)
	PermValues.labels.allow:SetText(str_allow)
	PermValues.labels.allow:SetDark(true)
	PermValues.labels.allow:SetContentAlignment(5)
	PermValues.labels.allow:SizeToContents()
	PermValues.labels.def = vgui.Create("DLabel", PermValues)
	PermValues.labels.def:SetText(str_def)
	PermValues.labels.def:SetDark(true)
	PermValues.labels.def:SetContentAlignment(5)
	PermValues.labels.def:SizeToContents()
	PermValues.labels.deny = vgui.Create("DLabel", PermValues)
	PermValues.labels.deny:SetText(str_deny)
	PermValues.labels.deny:SetDark(true)
	PermValues.labels.deny:SetContentAlignment(5)
	PermValues.labels.deny:SizeToContents()

	local lineheight = 20
	for i, act in ipairs(perm_actions) do
		local name = perm_actions_name[act]
		PermList.columns[act] = PermList:AddColumn(name)
		surface.SetFont( PermValues.labels.allow:GetFont() )
		local w = surface.GetTextSize( name )
		PermList.columns[act]:SetFixedWidth(w+14)
		PermValues.actions[act] = {}
		PermValues.actions[act].label = vgui.Create("DLabel",PermValues)
		PermValues.actions[act].label:SetText(name)
		PermValues.actions[act].label:SetDark(true)
		PermValues.actions[act].label:SetContentAlignment(5)
		PermValues.actions[act].label:SizeToContents()

		PermValues.actions[act].allow = vgui.Create( "DCheckBox", PermValues )
		PermValues.actions[act].def = vgui.Create( "DCheckBox", PermValues )
		PermValues.actions[act].deny = vgui.Create( "DCheckBox", PermValues )

		PermValues.actions[act].allow.OnChange = function( self, checked )
			PermValues.actions[act].allow:SetChecked(true)
			PermValues.actions[act].def:SetChecked(false)
			PermValues.actions[act].deny:SetChecked(false)
			local k, line = PermList:GetSelectedLine()
			if line then
				cl_playerPerms_pend[k].actions[act] = true
				PermList.buttons.commit:SetEnabled(true)
				line:SetColumnText(i+precolumns,perm_boolstr[tostring(cl_playerPerms_pend[k].actions[act])])
			end
		end
		PermValues.actions[act].def.OnChange = function( self, checked )
			PermValues.actions[act].allow:SetChecked(false)
			PermValues.actions[act].def:SetChecked(true)
			PermValues.actions[act].deny:SetChecked(false)
			local k, line = PermList:GetSelectedLine()
			if line then
				cl_playerPerms_pend[k].actions[act] = nil
				PermList.buttons.commit:SetEnabled(true)
				line:SetColumnText(i+precolumns,perm_boolstr[tostring(cl_playerPerms_pend[k].actions[act])])
			end
		end
		PermValues.actions[act].deny.OnChange = function( self, checked )
			PermValues.actions[act].allow:SetChecked(false)
			PermValues.actions[act].def:SetChecked(false)
			PermValues.actions[act].deny:SetChecked(true)
			local k, line = PermList:GetSelectedLine()
			if line then
				cl_playerPerms_pend[k].actions[act] = false
				PermList.buttons.commit:SetEnabled(true)
				line:SetColumnText(i+precolumns,perm_boolstr[tostring(cl_playerPerms_pend[k].actions[act])])
			end
		end

		PermValues.actions[act].allow:SetEnabled(false)
		PermValues.actions[act].def:SetEnabled(false)
		PermValues.actions[act].deny:SetEnabled(false)
	end

	PermWindow.OnSizeChanged = function( self )
		if !IsValid(PermValues) then return end
		PermValues:SetWide(PermWindow:GetWide())

		PermValues.entry:SetWide(240)
		PermValues.entry:SetPos(PermValues:GetWide()/2 - PermValues.entry:GetWide()/2,10)
		PermValues.entry:GetTall()

		local h1 = PermValues.entry:GetTall() + 10

		for i, act in ipairs(perm_actions) do
			PermValues.actions[act].label:SetPos(PermValues:GetWide()/2 - PermValues.actions[act].label:GetWide() - 30, h1+10+i*lineheight)
			PermValues.actions[act].allow:SetPos(PermValues:GetWide()/2 - 10, h1+10+i*lineheight)
			PermValues.actions[act].def:SetPos(PermValues:GetWide()/2 + 40, h1+10+i*lineheight)
			PermValues.actions[act].deny:SetPos(PermValues:GetWide()/2 + 90, h1+10+i*lineheight)
		end

		surface.SetFont( PermValues.labels.allow:GetFont() )
		local w = surface.GetTextSize( str_allow )
		PermValues.labels.allow:SetPos(PermValues:GetWide()/2 - 10 - w/4, h1+10)
		w = surface.GetTextSize( str_def )
		PermValues.labels.def:SetPos(PermValues:GetWide()/2 + 40 - w/4, h1+10)
		w = surface.GetTextSize( str_deny )
		PermValues.labels.deny:SetPos(PermValues:GetWide()/2 + 90 - w/4, h1+10)
	end

	PermList.OnRowSelected = function( self, rowIndex, line )
		if !line then return end
		cl_playerPerms_pend[rowIndex] = cl_playerPerms_pend[rowIndex] or {}
		
		local p = cl_playerPerms_pend[rowIndex]
		PermValues.entry:SetEnabled(true)
		PermValues.entry:SetText(p.id or "")

		p.actions = p.actions or {}
		for i, act in ipairs(perm_actions) do
			PermValues.actions[act].allow:SetEnabled(true)
			PermValues.actions[act].def:SetEnabled(true)
			PermValues.actions[act].deny:SetEnabled(true)

			if p.actions[act] == true then
				PermValues.actions[act].allow:SetChecked(true)
				PermValues.actions[act].def:SetChecked(false)
				PermValues.actions[act].deny:SetChecked(false)
			elseif p.actions[act] == false then
				PermValues.actions[act].allow:SetChecked(false)
				PermValues.actions[act].def:SetChecked(false)
				PermValues.actions[act].deny:SetChecked(true)
			elseif p.actions[act] == nil then
				PermValues.actions[act].allow:SetChecked(false)
				PermValues.actions[act].def:SetChecked(true)
				PermValues.actions[act].deny:SetChecked(false)
			end
		end
	end

	PermList.RebuildList = function( self )
		PermList:ClearOptions()
		for k, line in pairs(self:GetLines()) do
			self:RemoveLine(line:GetID())
		end
		for i, p in ipairs(cl_playerPerms_pend) do
			local ply = player.GetBySteamID64(p.id)

			local line = self:AddLine(
				p.id,
				IsValid(ply) and ply:Name() or "[Player not in server]",
				GetPlayerRole( ply )
			)
			for k, act in ipairs(perm_actions) do
				line:SetColumnText(k+precolumns,perm_boolstr[tostring(p.actions[act])])
			end
		end
		local allowed = CheckClientPerm2( LocalPlayer(), "settings" ) or LocalPlayer():IsSuperAdmin()
		PermList:SetEnabled( allowed )
		PermList.buttons.commit:SetVisible( allowed )
		PermList.buttons.add:SetVisible( allowed )
		PermList.buttons.remove:SetVisible( allowed )
	end

	PermList:RebuildList()
	PermWindow:OnSizeChanged()
	PermWindow:RequestFocus()
end

concommand.Add( "npcd_permission_edit", PermEditor ) 

function RequestSpawn( prof, set, prs, target )
	if !prof or prof != cl_currentProfile then return end
	if target != nil and !CheckClientPerm2( LocalPlayer(), "spawn_other" ) then
		chat.AddText( RandomColor( 0, 15, 0.75, 1, 1, 1 ), "You do not have permission to spawn presets for others! Permission: " .. ( t_PERM_STR[cvar.perm_spawn_others.v:GetInt()] or "" ) )
		return
	end
	net.Start( "npcd_spawn" )
		net.WriteString( prof )
		net.WriteString( set )
		net.WriteString( prs )
		-- net.WriteVector( pos or GetPlyTrPos( LocalPlayer() ) )
		net.WriteEntity( target or LocalPlayer() )
	net.SendToServer()
end

concommand.Add( "npcd_spawn",
	function( ply, cmd, args, argstr )
		if cl_currentProfile and CheckClientPerm2( ply, "spawn_self" ) then
			RequestSpawn( cl_currentProfile, "", argstr )
		end
	end,
	function(cmd, stringargs)
		if !cl_currentProfile then return end
		if !cl_Profiles[cl_currentProfile] then return end
		stringargs = string.Trim( stringargs ) -- Remove any spaces before or after.
		stringargs = string.lower( stringargs )

		local tbl = {}
		local keyt = {}
		for _, t in pairs( table.GetKeys( cl_Profiles[cl_currentProfile].squad ) ) do
			keyt[t] = t
		end
		for _, typ in ipairs( { "npc", "nextbot", "entity" } ) do
			for _, t in pairs( table.GetKeys( cl_Profiles[cl_currentProfile][typ]) ) do
				keyt[t] = t
			end
		end

		for k, v in SortedPairs( keyt ) do
			if string.StartWith( string.lower( v ), stringargs ) then				
				table.insert(tbl, cmd .. " " .. v )
			end
		end
		return tbl
	end,
	"Spawn given squad/entity preset. If names conflict, will prefer squad > npc > nextbot > entity.",
	{ FCVAR_PRINTABLEONLY }
)

function SendCvar( name, val, typ )
	net.Start( "npcd_cl_cvar" )
		net.WriteString( name )
		net.WriteUInt(
			typ == "boolean" and 1
			or typ == "number" and 2
			or typ == "int" and 3
			or typ == "string" and 4
			, 4 )
		if typ == "boolean" then
			net.WriteBool( val )
		elseif typ == "number" or typ == "int" then
			net.WriteFloat( val )
		elseif typ == "string" then
			net.WriteString( val )
		end
	net.SendToServer()
end

concommand.Add( "npcd_cvar_reset_all", function( ply )
	for tname, p in pairs( all_cvar_p_t ) do
		if IsValid( p.panel ) and IsValid( p.button ) then
			p.button:OnReleased()
		end
	end
end )

concommand.Add( "npcd_printout_cvar", function( ply )
	file.CreateDir( NPCD_DIR .. "export" )
	local estr = ""
	local sort_l = {}
	for tname, var in pairs( cvar ) do
		sort_l[var.v:GetName()] = var.v:GetString()
	end
	for name, str in SortedPairs( sort_l ) do
		-- print( name .. "\t" .. str )
		estr = estr .. name .. "\t\"" .. str .. "\"\n"
	end
	local f = NPCD_DIR .. "export/npcd_cvars.txt"
	file.Write( NPCD_DIR .. "export/npcd_cvars.txt", estr )
	
	local tout = "Server ConVars exported: garrysmod/data/" .. f .. " (" .. file.Size( f, "DATA" ) .. " bytes)"
	-- print( "npcd > "..tout )
	chat.AddText( RandomColor( 50, 55, 0.5, 1, 1, 1 ), tout )
end )

local revlup = {
	["struct"] = true,
	["active"] = true,
	["basic"] = true,
}

local function RecursiveLuaExport( str, a, d, hist )
	local d = d or 0
	-- for i=1,d do
	-- 	Msg("\t")
	-- end
	-- if d == 0 then
	-- end
	str = str .. "{\n"
	for k, v in SortedPairs( a ) do
		-- if hist and #str > 32768 then
		-- 	return str
		-- end
		
		for i=1,d do
			str = str .. "\t"
		end
		str = str .. "\t"

		if t_DATAVALUE_NAMES[k] then
			str = str .. string.JavascriptSafe(tostring(k)) .. " = "
		elseif isstring(k) then
			str = str .. "[\"" .. string.JavascriptSafe(tostring(k)) .. "\"] = "
		elseif isnumber(k) then
			str = str .. "[".. tostring(k) .. "] = "
		elseif isvector(k) then
			str = str .. "[Vector( " .. k.x .. ", " .. k.y .. ", " .. k.z .." )]"
		elseif isangle(k) then
			str = str .. "[Angle( " .. k.p .. ", " .. k.y .. ", " .. k.r .." )]"
		elseif IsColor(k) then 
			str = str .. "[Color( " .. k.r .. ", " .. k.g .. ", " .. k.b .. ( k.a != 255 and ", " .. k.a or "" ) .. " )]"
		else
			str = str .. "[".. string.JavascriptSafe(tostring(k)) .. "] = "
		end

		-- if hist and hist[v] then // anti recursive
		-- 	print( v, "already exported" )
		-- 	str = str .. tostring(v)
		-- else
		if istable( v ) and !IsColor( v ) then
			
			if hist then
				local found
				for tk, t in pairs( t_lookup ) do
					if tk == "class" then
						for ctk, ct in pairs( t ) do
							if v == t then
								hist[v] = true
								str = str .. "t_lookup.class."..ctk..",\n"
								break
							end
							for dn, dv in pairs( ct ) do
								if v == dv then
									hist[v] = true
									str = str .. "t_lookup.class."..ctk.."["..dn.."],\n"
									break
								end
							-- 	for pdn, pdv in pairs( dv ) do
							-- 		if v == pdv then
							-- 			hist[v] = true
							-- 			str = str .. "t_lookup.class."..ctk.."["..dn.."]."..pdn..",\n"
							-- 			break
							-- 		end
							-- 	end
								-- if hist[v] then break end
							end
							if hist[v] then break end
						end
						if hist[v] then break end
					else
						if v == t then
							hist[v] = true
							str = str .. "t_lookup."..tk..",\n"
							break
						end

						if revlup[tk] then
							for dn, dv in pairs( t ) do
								if v == dv then
									hist[v] = true
									str = str .. "t_lookup."..tk.."["..dn.."],\n"
									break
								end
								for pdn, pdv in pairs( dv ) do
									if v == pdv then
										hist[v] = true
										str = str .. "t_lookup."..tk.."["..dn.."]."..pdn..",\n"
										break
									end
								end
								if hist[v] then break end
							end
							if hist[v] then break end
						end						
					end
				end

				if hist[v] then
					continue
				end	
			end

			str = RecursiveLuaExport( str, v, d + 1, hist )
		else
			if isstring(v) then
				str = str .. "\"" .. string.JavascriptSafe(tostring(v)) .. "\""
			elseif isvector(v) then
				str = str .. "Vector( " .. v.x .. ", " .. v.y .. ", " .. v.z .." )"
			elseif isangle(v) then
				str = str .. "Angle( " .. v.p .. ", " .. v.y .. ", " .. v.r .." )"
			elseif IsColor(v) then 
				str = str .. "Color( " .. v.r .. ", " .. v.g .. ", " .. v.b .. ( v.a != 255 and ", " .. v.a or "" ) .. " )"
			else
				str = str .. string.JavascriptSafe(tostring(v))
			end
		end
		str = str .. ",\n"
	end
	for i=1,d do
		str = str .."\t"
	end
	str = str .. "}"
	return str
end

concommand.Add( "npcd_printout_profile_lua", function( ply )
	file.CreateDir( NPCD_DIR .. "export" )

	local cl_exported = {}

	// client file
	for prof in pairs( cl_Profiles ) do
		local estr = "// (CLIENT) " .. prof
		.."\n\nif !CLIENT then return false end"
		.."\nif !npcd.CheckClientPerm2( LocalPlayer(), \"profiles\" ) then return false end"
		.."\n\n// The function will insert the presets as pending changes into the given profile." --You can uncomment the commands below to switch to or create a new profile"
		.."\n\n// Returns existing profile or creates empty profile"
		.."\n// 1st arg: profile name, or generic name if nil."
		.."\n// 2nd arg: always create a new profile (true) or return the name without changes if existing (false/nil)"
		.."\nlocal profile_name = npcd.ClientCreateEmptyProfile( \"" .. prof .. "\", true ) // set profile_name to nil to insert into the currently active profile"
		.."\n\n-- npcd.ClientClearProfile( profile_name ) // (optional) empty out existing profile"
		.."\n-- npcd.ClientSwitchProfile( profile_name ) // (optional) set as active profile"
		.."\n\n-- npcd.QuerySettings()"
		.."\n// runs function once after profiles update is received"
		.."\n// 1st arg: profile that must exist before it can run, or nil for no requirement"
		.."\nnpcd.QueuePostQuery( profile_name, 30, function()"
		for set in pairs( cl_Profiles[prof] ) do
			for prs, prstbl in pairs( cl_Profiles[prof][set] ) do
				estr = estr .. "\n\tnpcd.InsertPending( profile_name, \"" .. set .. "\", \""..prs.."\", "
				estr = RecursiveLuaExport( estr, prstbl, 1 )
				estr = estr .. " )\n"
			end
		end
		estr = estr.."\n\tnpcd.StartSettingsPanel()"
		.."\n\nend )"
		.."\n\nreturn profile_name"

		// AddCSLuaFile cannot have whitespace in the filename		
		local newname = string.gsub( prof, " ", "_" )
		local eprof = newname
		local c = 0
		while cl_exported[eprof] do
			c=c+1
			eprof = newname .. "_" .. c
		end
		cl_exported[eprof] = true

		local f = NPCD_DIR .. "export/npcd_lua_cl_"..eprof..".txt"
		local c = 0
		while file.Exists( f, "DATA" ) do
			c = c + 1
			f = NPCD_DIR .. "export/npcd_lua_cl_"..eprof.."."..c..".txt"
			if c > 65536 then
				break
			end
		end
		file.Write( f, estr )

		local tout = "Profile Lua exported: garrysmod/data/" .. f .. " (" .. file.Size( f, "DATA" ) .. " bytes)"
		-- print( "npcd > "..tout )
		chat.AddText( RandomColor( 50, 55, 0.5, 1, 1, 1 ), tout )
	end

	// server file
	for prof in pairs( cl_Profiles ) do
		local estr = "// (SERVER) " .. prof
		.."\n\nif !SERVER then return false end"
		.."\n\n// The CreatePreset functions will immediately overwrite the presets in the given profile." --You can uncomment the commands below to switch to or create a new profile"
		.."\n\n// Creates empty profile and does nothing to existing profiles. Returns name of profile"
		.."\n// 1st arg: profile name, or new generic name if nil."
		.."\n// 2nd arg: always create a new profile (true) or return the name without changes if existing (false/nil)"
		.."\nlocal profile_name = npcd.CreateEmptyProfile( \"" .. prof .. "\", true ) // set profile_name to nil to use currently active profile"
		.."\n\n-- npcd.ClearProfile( profile_name ) // (optional) empty out existing profile"
		.."\n-- npcd.SwitchProfile( profile_name )\n"
		for set in pairs( cl_Profiles[prof] ) do
			for prs, prstbl in pairs( cl_Profiles[prof][set] ) do
				estr = estr .. "\nnpcd.CreatePreset( \"" .. set .. "\", \""..prs.."\", "
				estr = RecursiveLuaExport( estr, prstbl )
				estr = estr .. ", profile_name )\n"
			end
		end
		estr = estr.."\nnpcd.PatchProfile( profile_name )"
		.."\nnpcd.SaveProfile( profile_name )"
		.."\n\nreturn profile_name"
		
		local f = NPCD_DIR .. "export/npcd_lua_sv_"..prof..".txt"
		local c = 0
		while file.Exists( f, "DATA" ) do
			c = c + 1
			f = NPCD_DIR .. "export/npcd_lua_sv_"..prof.."."..c..".txt"
			if c > 65536 then
				break
			end
		end
		file.Write( f, estr )

		local tout = "Profile Lua exported: garrysmod/data/" .. f .. " (" .. file.Size( f, "DATA" ) .. " bytes)"
		-- print( "npcd > "..tout )
		chat.AddText( RandomColor( 50, 55, 0.5, 1, 1, 1 ), tout )
	end

end, nil, "Exports all presets in all profiles as lua functions to garrysmod/data/export/."
.."\nnpcd.CreatePreset( presetType, presetName, values, profileName or currentProfile, onlyReturnTable, insertTable or Profiles ) "
.."\nnpcd.ClientCreatePreset( profileName or currentProfile, presetType, presetName, values ) " )

-- concommand.Add( "npcd_printout_struct_lua", function( ply )
-- 	file.CreateDir( NPCD_DIR .. "export" )
-- 	local hist = {}
-- 	-- local estr = ""
-- 	for k, lup in SortedPairs( t_lookup ) do
-- 		if k == "class" then
-- 			for ck, clup in SortedPairs( lup ) do
-- 				local estr = ""
-- 				for dn, dv in SortedPairs( clup ) do
-- 					-- print( k, ck, dn )
-- 					estr = estr .. "\nt_lookup.class."..ck.."[\""..dn.."\"] = "
-- 					estr = RecursiveLuaExport( estr, dv, nil, {} )
-- 					estr = estr .. "\n"
-- 				end
-- 				local f = NPCD_DIR .. "export/npcd_export_struct_".. k .. "_" ..ck  ..".txt"
-- 				file.Write( f, estr )
-- 				print( "npcd > Profile exported: garrysmod/data/" .. f .. " (" .. file.Size( f, "DATA" ) .. " bytes)" )
-- 			end
-- 		else
-- 			local estr = ""
-- 			for dn, dv in SortedPairs( lup ) do
-- 				-- print( k, dn )
-- 				estr = estr .. "\nt_lookup."..k.."[\""..dn.."\"] = "
-- 				estr = RecursiveLuaExport( estr, dv, nil, {} )
-- 				estr = estr .. "\n"
-- 			end
-- 			local f = NPCD_DIR .. "export/npcd_export_struct_".. k ..".txt"
-- 			file.Write( f, estr )
-- 			print( "npcd > Profile exported: garrysmod/data/" .. f .. " (" .. file.Size( f, "DATA" ) .. " bytes)" )
-- 		end
-- 	end

-- 	-- local f = NPCD_DIR .. "export/npcd_export_struct.txt"
-- 	-- file.Write( f, estr )
-- 	-- print( "npcd > Profile exported: garrysmod/data/" .. f .. " (" .. file.Size( f, "DATA" ) .. " bytes)" )
-- end, nil, "(WIP) Exports the entire datavalue struct as a lua table to garrysmod/data/export/" )

concommand.Add( "npcd_generate_autoprofile", function( ply )
	if CheckClientPerm2( LocalPlayer(), "profiles" ) then
		GeneratedKit()
	end
end )
concommand.Add( "npcd_generate_starterkits", function( ply )
	if CheckClientPerm2( LocalPlayer(), "profiles" ) then
		StarterKit()
	end
end )

concommand.Add( "npcd_profile_import", function( ply )
	if CheckClientPerm2( LocalPlayer(), "profiles" ) then
		local frame = vgui.Create( "DFrame" )

		frame:SetSize( 500, 300 )
		frame:Center()

		frame:SetTitle( "npcd Import JSON" )
		frame:SetDraggable( true )
		frame:SetSizable( true )
		frame:MakePopup()
		local namebox = vgui.Create( "DTextEntry", frame )
		local name = ""
		namebox:Dock( TOP )
		namebox:SetPlaceholderText( "Profile Name" )
		namebox.OnChange = function( self )
			name = string.lower( self:GetValue() )
		end
		TextPrompt(
			frame,
			ScrW()/2,
			ScrH()/2,
			nil,
			function( text, prompt )
				if name == "" then
					chat.AddText( "Import error: No profile name given" )
					return
				end
				if cl_Profiles[name] then
					chat.AddText( "Import error: Profile \"".. name .."\" already exists" )
					return
				end
				local import = util.JSONToTable( text )
				if !import then
					chat.AddText( "Import error: Text returned invalid json" )
					return
				end
				// fixup
				RecursiveFixUserdata( import )
				
                chat.AddText( "Import in progress..." )
				ClientCreateProfile( name )
				QueuePostQuery( name, 30, function()
					
					// import prepatch
					if import["squadpool"] then
						import["spawnpool"] = import["squadpool"]
						import["squadpool"] = nil
					end

					for set in pairs( PROFILE_SETS ) do
						if import[set] then
							for prs in pairs( import[set] ) do
								npcd.InsertPending( name, set, prs, import[set][prs] )
							end
						end
					end
					StartSettingsPanel()
                    chat.AddText( "Imported profile \"".. name .."\""  )
				end )
				frame:Close()
			end,
			function( prompt )
				frame:Close()
			end,
            nil,
			"Paste JSON code here. Pasting lots of text may temporarily freeze the game",
			true,
			true,
			true
		 )
	end
end )

concommand.Add( "npcd_printout_profile_json", function( ply )
	file.CreateDir( NPCD_DIR .. "export" )
	for prof in pairs( cl_Profiles ) do
		local f = NPCD_DIR .. "export/"..prof..".json"
		local c = 0
		while file.Exists( f, "DATA" ) do
			c = c + 1
			f = NPCD_DIR .. "export/"..prof.."."..c..".json"
			if c > 65536 then
				break
			end
		end
		file.Write( f, util.TableToJSON(cl_Profiles[prof], true) )

		local tout = "Profile exported: garrysmod/data/" .. f .. " (" .. file.Size( f, "DATA" ) .. " bytes)"
		-- print( "npcd > "..tout )
		chat.AddText( RandomColor( 50, 55, 0.5, 1, 1, 1 ), tout )
	end
end, nil, "Exports all profiles as json to garrysmod/data/export/" )

function UpdateOptions()
	for tname, p in pairs( all_cvar_p_t ) do
		if IsValid( p.panel ) then
			local perm = p.perm
			local action = p.action
			
			local allowed
			allowed = perm and CheckClientPerm( LocalPlayer(), perm )
						 or !perm and CheckClientPerm2( LocalPlayer(), action or "settings" )

			local v = cvar[tname] and cvar[tname].v or nil

			p.panel:SetEnabled( allowed )
			if p.button and IsValid( p.button ) then
				p.button:SetEnabled( allowed )
			end

			if v then
				if p.typ == "boolean" then
					p.panel:SetChecked( v:GetBool() )
				elseif p.typ == "number" then
					p.panel:SetValue( v:GetFloat() )
				elseif p.typ == "int" then
					p.panel:SetValue( v:GetInt() )
				elseif p.typ == "string" then
					p.panel:SetValue( v:GetString() )
				end
			end
		end
	end
end

net.Receive( "npcd_cvar_update", UpdateOptions )

hook.Add( "AddToolMenuCategories", "NPCD Tool Category", function()
	spawnmenu.AddToolCategory( "Options", "NPC Daemon", "#NPC Daemon" )
end )

hook.Add( "PopulateToolMenu", "NPCD Tool Menu", function()
	spawnmenu.AddToolMenuOption( "Options", "NPC Daemon", "npcd Options", "#npcd Options", nil, nil, PopulateNPCDToolMenu )
end )

// populate tool menu options
function PopulateNPCDToolMenu( panel )
	all_cvar_p_t = {}
    panel:ClearControls()
	-- panel:ControlHelp("plis biz a sinkin masenchur")
	all_cvar_p_t["npcd_settings_open"] = {}
	all_cvar_p_t["npcd_settings_open"].panel = panel:Button( "Configure Profiles", "npcd_settings_open" )
	all_cvar_p_t["npcd_settings_open"].action = "profiles"

	panel:Button( "Help", "npcd_settings_help" )
	local expandbutt = panel:Button( "Toggle Expand All", nil )
	expandbutt.OnReleased = function()
		local c = 0
		tog_expand = !tog_expand
		for _, form in pairs( cvar_forms ) do
			timer.Simple( engine.TickInterval() * c, function()
				form:DoExpansion( tog_expand )
			end )
			c = c + 1
		end
	end

	local topliner = vgui.Create("Panel")
	topliner:SetSize( 0, 0 )
	panel:AddItem( topliner )

	-- local cvarman = vgui.Create( "ControlPresets", panel )
	-- for tname, var in pairs( cvar ) do
	-- 	cvarman:AddConVar( var.v:GetName() )
	-- end
	-- panel:AddItem( cvarman )

	// categorizes all cvars (see: npcd.lua)
	local sortedvars = {}
	local cats
	local cc = 0
	for _, t in ipairs( { cvar, cl_cvar } ) do
		for tname, var in pairs( t ) do
			if !var.c then 
				ErrorNoHalt( "Error: npcd > PopulateNPCDToolMenu > ",tname, " is nil category")
				continue
			end
			cvar_cats[var.c] = cvar_order[var.c] or 999+cc
			cc=cc+1
			sortedvars[var.c] = sortedvars[var.c] or {}
			sortedvars[var.c][tname] = var
		end
	end
	if table.IsEmpty( sortedvars ) then return end

	// adds panel for each cvar
	local pretop = true
	for cat in SortedPairsByValue( cvar_cats ) do
		if table.IsEmpty( sortedvars[cat] ) then continue end
		local cform
		if cat == "TOP" then
			cform = panel
		else
			cform = vgui.Create( "DForm", panel )
			panel:AddItem( cform )
			cform:SetName( cat )
			cform:SetExpanded( false )
		end

		local butt
		// buttons for categories
		if cat == "Stress" then
			cform:ControlHelp( "Stress is a measure of activity (damage, killing, dying, etc), and affects pressure (the rate of spawns)" ):DockMargin( 0, 5, 0, 0 )
		elseif cat == "Enabled" then
			all_cvar_p_t["npcd_permission_edit"] = {
				panel = cform:Button( "Edit Player Permissions...", "npcd_permission_edit" ),
				perm = PERM_CLIENT,
			}
			butt = true
		elseif cat == "Pressure" then
			cform:ControlHelp( "Pressure affects how often things automatically spawn, and is constantly rising. Pressure lowers when stress is too high" ):DockMargin( 0, 5, 0, 0 )
		elseif cat == "Profiles" then
			all_cvar_p_t["npcd_profile_query"] = {
				panel = cform:Button( "Query All Profiles", "npcd_profile_query" ),
				perm = PERM_CLIENT,
			}
			all_cvar_p_t["npcd_profile_import"] = {
				panel = cform:Button( "Import Profile", "npcd_profile_import" ),
				action = "profiles",
			}
			all_cvar_p_t["npcd_printout_profile_json"] = {
				panel = cform:Button( "Export Profiles As JSON", "npcd_printout_profile_json" ),
				perm = PERM_CLIENT,
			}
			all_cvar_p_t["npcd_printout_profile_lua"] = {
				panel = cform:Button( "Export Profiles Presets As Lua", "npcd_printout_profile_lua" ),
				perm = PERM_CLIENT,
			}
			all_cvar_p_t["npcd_generate_autoprofile"] = {
				panel = cform:Button( "Generate Profile From Current Install To Pending", "npcd_generate_autoprofile" ),
				action = "profiles",
			}
			all_cvar_p_t["npcd_generate_starterkits"] = {
				panel = cform:Button( "Recreate Starter Profiles To Pending", "npcd_generate_starterkits" ),
				action = "profiles",
			}
			all_cvar_p_t["npcd_profile_reload_all"] = {
				panel = cform:Button( "Reload All Profiles", "npcd_profile_reload_all" ),
				action = "profiles",
			}
			all_cvar_p_t["npcd_settings_window_reset"] = {
				panel = cform:Button( "Reset Settings Window", "npcd_settings_window_reset" ),
				perm = PERM_CLIENT,
			}
			butt = true
		elseif cat == "Auto-Spawner" then // "Spawn Routine"
			cform:ControlHelp( "The auto-spawner spawns entities automatically around the map. When it runs, it makes a spawn quota for every spawnpool and attempts to fulfill each quota using the pool's spawns list and radiuses" ):DockMargin( 0, 5, 0, 0 )
			
			all_cvar_p_t["npcd_direct"] = {
				panel = cform:Button( "Force Spawn Routine", "npcd_direct" ),
				action = "spawn_self",
			}
			all_cvar_p_t["npcd_fill"] = {
				panel = cform:Button( "Fill All Spawnpools", "npcd_fill" ),
				action = "spawn_self",
			}
			butt = true
		elseif cat == "Player" then
			all_cvar_p_t["npcd_ply_clear_history"] = {
				panel = cform:Button( "Clear Player Death/Preset History", "npcd_ply_clear_history" ),
			}
			all_cvar_p_t["npcd_ply_revert_recheck"] = {
				panel = cform:Button( "Capture All Current Player Values As Revert Values", "npcd_ply_revert_recheck" ),
			}
			butt = true
		elseif cat == "Debug" then
			all_cvar_p_t["npcd_clean"] = {
				panel = cform:Button( "Cleanup NPCD Entities", "npcd_clean" ),
			}
			all_cvar_p_t["npcd_init"] = {
				panel = cform:Button( "Re-Initialize", "npcd_init" ),
			}
			all_cvar_p_t["npcd_printout_cvar"] = {
				panel = cform:Button( "Export Server ConVars", "npcd_printout_cvar" ),
				perm = PERM_CLIENT,
			}
			all_cvar_p_t["npcd_cvar_reset_all"] = {
				panel = cform:Button( "Reset All ConVars", "npcd_cvar_reset_all" ),
			}
			butt = true
		end
		
		if butt then
			local liner = vgui.Create("Panel")
			liner:SetSize( 0, 0 )
			cform:AddItem( liner )
		end
		
		for tname, var in SortedPairsByMemberValue( sortedvars[cat], "sn" ) do
			local name = var.n or ""
			local v = var.v
			local varname = var.v:GetName()
			local min = var.v:GetMin()
			local max = var.v:GetMax()
			local altmax = var.altmax
			local altmin = var.altmin
			local help = var.v:GetHelpText()
			local typ = var.t
			local priv = var.v:IsFlagSet( FCVAR_REPLICATED )
			local perm = var.p // forced perm
			local action = var.action

			local new
			local label

			local catbutton = vgui.Create( "DButton", cform )
			catbutton:SetImage( UI_ICONS.revert )
			catbutton:SetSize( UI_ICONBUTTON_W, UI_BUTTON_H )
			catbutton:DockMargin( marg, 0, 0, 0 )
			catbutton:SetText("")
			catbutton.OnReleased = function( self )
				if perm and CheckClientPerm( LocalPlayer(), perm )
				or !perm and CheckClientPerm2( LocalPlayer(), action or "settings" ) then
					if typ == "boolean" then
						new:SetChecked( v:GetBool() )
					elseif typ == "number" then
						new:SetValue( v:GetFloat() )
					elseif typ == "int" then
						new:SetValue( v:GetInt() )
					elseif typ == "string" then
						new:SetValue( v:GetString() )
					end
					return
				end

				local val = v:GetDefault()
				if !priv then
					if typ == "boolean" then
						v:SetBool( tobool( val ) )
						new:SetChecked( tobool( val ) )
					elseif typ == "number" then
						v:SetFloat( val )
						new:SetValue( val )
					elseif typ == "int" then
						v:SetInt( val )
						new:SetValue( val )
					elseif typ == "string" then
						v:SetString( val )
						new:SetValue( val )
					end
					return
				end

				if typ == "boolean" then
					SendCvar( tname, tobool(val), typ )
					new:SetChecked( tobool(val) )
				else
					SendCvar( tname, val, typ )
					if new:GetValue() != val then new:SetValue( val ) end
				end
			end

			if typ == "boolean" then
				new = vgui.Create( "DCheckBoxLabel", cform )
				new:SetText( name )
				new:SetDark( true )

				new:SetChecked( v:GetBool() )
				new.OnChange = function( self, val )
					if val == v:GetBool() then return end
					if !priv then
						v:SetBool( tobool( val ) )
						return
					end
					if perm and CheckClientPerm( LocalPlayer(), perm )
					or !perm and CheckClientPerm2( LocalPlayer(), action or"settings" ) then
						SendCvar( tname, val, typ )
					else
						new:SetChecked( v:GetBool() )
					end
				end
			elseif typ == "number" or typ == "int" then
				local max = altmax or max or math.max( 65536, ( v:GetDefault() or 0 ) * 2 )
				local min = altmin or min or 0
				new = cform:NumSlider( name, nil, min, max, typ == "int" and 0 or nil ) --vgui.Create( "DNumSlider", panel )
				if typ == "int" then 
					new:SetDecimals( 0 )
				else
					new:SetDecimals( 5 )
				end

				new:SetValue( typ == "int" and v:GetInt() or v:GetFloat() )

				new.OnValueChanged = function( self, val )
					if val == v:GetFloat() then return end
					if !priv then
						if typ == "int" then
							v:SetInt( val )
						elseif typ == "number" then
							v:SetFloat( val )
						end
						return
					end
					
					if perm and CheckClientPerm( LocalPlayer(), perm )
					or !perm and CheckClientPerm2( LocalPlayer(), action or"settings" ) then
						SendCvar( tname, val, typ )
					else
						new:SetValue( val )
					end
				end
			elseif typ == "string" then
				label = vgui.Create( "DLabel", cform )
				label:SetText( name )
				label:SetDark( true )
				new = vgui.Create( "DTextEntry", cform )
				new:SetUpdateOnType( true )
				if v:GetString() then new:SetValue( v:GetString() ) end
				new.OnValueChange = function( self, val )
					if val == v:GetString() then return end
					if !priv then
						v:SetString( val )
						return
					end

					if perm and CheckClientPerm( LocalPlayer(), perm )
					or !perm and CheckClientPerm2( LocalPlayer(), action or"settings" ) then
						SendCvar( tname, val, typ )
					else
						new:SetValue( v:GetString() )
					end
				end
			end
			local p = vgui.Create( "Panel", cform )
			-- p:SetBackgroundColor( Color(0,0,0,0) )
			p:DockMargin( marg, 0, marg, 0 )

			if label != nil then	
				label:SetParent( p )
				new:SetParent( p )
				catbutton:SetParent( p )
				label:Dock( LEFT )
				new:Dock( FILL )
				catbutton:Dock( RIGHT )
			else
				new:SetParent( p )
				catbutton:SetParent( p )
				catbutton:Dock( RIGHT )
				new:Dock( FILL )
			end

			p:Dock( TOP )

			if help then
				cform:ControlHelp( help )
			end

			all_cvar_p_t[tname] = {
				panel = new,
				perm = perm,
				action = action,
				typ = typ,
				button = catbutton,
			}
		end

		if cat != "TOP" then
			cvar_forms[cat] = cform
		end
	end

	UpdateOptions()
end

// based on garrysmod/gamemodes/sandbox/gamemode/spawnmenu/creationmenu/content/contenticon.lua
spawnmenu.AddContentType( "npcd_preset", function( container, obj_t )
	if !obj_t.set and !obj_t.name then return nil end

	local icon = vgui.Create( "ContentIcon", container )
	icon:SetContentType( "npcd_preset" )
	icon:SetName( obj_t.name )
	// set unlit for non-pngs to fix black flickering
	if obj_t.material and obj_t.material:match("(.+)%.vmt") then
		local mat = npcd.get_unlit_mat( obj_t.material )
		icon.Image:SetMaterial( mat )
	else
		icon:SetMaterial( obj_t.material )
	end
   if obj_t.material then
      MatCache[obj_t.material] = icon.Image:GetMaterial()
   end

	icon:SetColor( Color( 205, 92, 92, 255 ) )
	if obj_t.desc then icon:SetToolTip( obj_t.name .. "\n" .. tostring( obj_t.desc ) ) end


	icon.SetToolCvar = function( self )
		local svar = GetConVar( "npcd_spawner_set" )
		local pvar = GetConVar( "npcd_spawner_prs" )
		if svar and pvar then
			svar:SetString( obj_t.set )
			pvar:SetString( obj_t.name )
			language.Add( "tool.npcd_spawner.0", ( cl_currentProfile or "" ) .. " > " .. obj_t.set .. " > " .. obj_t.name )
		end
	end

	icon.ToolGun = function( self )
		spawnmenu.ActivateTool( "npcd_spawner" )
		icon:SetToolCvar()
		-- local svar = GetConVar( "npcd_spawner_set" )
		-- local pvar = GetConVar( "npcd_spawner_prs" )
		-- if svar and pvar then
		-- 	svar:SetString( obj_t.set )
		-- 	pvar:SetString( obj_t.name )
		-- 	language.Add( "tool.npcd_spawner.0", ( cl_currentProfile or "" ) .. " > " .. obj_t.set .. " > " .. obj_t.name )
		-- end
	end


	icon.DoSpawn = function( self )
		local p = cvar.perm_spawn.v:GetInt()
		if CheckClientPerm2( LocalPlayer(), "spawn_self" ) then
			if !cl_cvar.spawner_toolgunner.v:GetBool() then
				icon:SetToolCvar()
				RequestSpawn( cl_currentProfile, obj_t.set, obj_t.name )
			else
				self:ToolGun()
			end
			surface.PlaySound( "ui/buttonclickrelease.wav" )
		else
			chat.AddText( RandomColor( 0, 15, 0.75, 1, 1, 1 ), "You do not have permission to spawn presets! Permission: " .. ( p and t_PERM_STR[p] or "" ) )
		end
	end

	icon.DoClick = function()
		icon:DoSpawn()
	end

	-- icon.DoRightClick = function()
	-- 	icon:DoSpawn( true )
	-- end

	local perm = cvar.perm_spawn.v:GetInt()
	if perm == PERM_ADMIN or perm == PERM_SUPERADMIN then
		icon:SetAdminOnly( true )
	end

	icon.OpenMenu = function( self )
		local menu = DermaMenu()
			menu:AddOption( "#spawnmenu.menu.copy", function()
				SetClipboardText( obj_t.name )
			end ):SetIcon( "icon16/page_copy.png" )

			menu:AddOption( "#spawnmenu.menu.spawn_with_toolgun", function()
				self:ToolGun()
			end ):SetIcon( "icon16/brick_add.png" )

			local submenu_spawnon, option_spawnon = menu:AddSubMenu( "Spawn For Other Player" )
			option_spawnon:SetIcon( UI_ICONS.spawn )

			for _, p in ipairs( player.GetAll() ) do
				local ply = p
				submenu_spawnon:AddOption( tostring( ply:GetName() ), function()
					RequestSpawn( cl_currentProfile, obj_t.set, obj_t.name, ply )
				end )
			end			

			menu:AddOption( "Spawn For All Players", function()
				if CheckClientPerm2( LocalPlayer(), "spawn_other" ) then
					for _, ply in ipairs( player.GetAll() ) do
						RequestSpawn( cl_currentProfile, obj_t.set, obj_t.name, ply )
					end
				else
					chat.AddText( RandomColor( 0, 15, 0.75, 1, 1, 1 ), "You do not have permission to spawn presets for others! Permission: " .. ( t_PERM_STR[cvar.perm_spawn_others.v:GetInt()] or "" ) )
				end
			end ):SetIcon( UI_ICONS.spawn )

		menu:Open()
	end

	if ( IsValid( container ) ) then
		container:Add( icon )
	end

	return icon
end )

local spwn_open

hook.Add( "OnSpawnMenuOpen", "NPCD Spawnmenu Open", function()
	spwn_open = true
	if NPCDSpawnMenu then NPCDSpawnMenu:CallPopulateHook( "PopulateNPCD" ) end
end )
hook.Add( "OnSpawnMenuClose", "NPCD Spawnmenu Close", function()
	spwn_open = nil
end )

// based on garrysmod/gamemodes/sandbox/gamemode/spawnmenu/creationmenu/content/contenttypes/npcs.lua
hook.Add( "PopulateNPCD", "NPCD Spawnmenu Content", function( pnlContent, tree, node )
	if !spwn_open then return end

	if not ( cl_currentProfile and cl_Profiles[cl_currentProfile] ) then
		if cl_cvar.cl_debugged.v:GetBool() then
			print( "PopulateNPCD > no current profile" )
		end
		timer.Simple( query_delay, function() QuerySettings( true ) end )
		return
	end

	-- Create an icon for each one and put them on the panel
	for setn, settbl in SortedPairs( cl_Profiles[cl_currentProfile] ) do
		if SPAWN_SETS[setn] then

			-- Add a node to the tree
			if !npcd_nodes[setn] then
				npcd_nodes[setn] = tree:AddNode( SPAWN_SETS[setn], UI_ICONS_SETS[setn] ) --UI_ICONS.menunode )
				npcd_nodes[setn].count = 0
				npcd_nodes[setn].icons = {}
				npcd_nodes[setn].set = setn

				-- When we click on the node - populate it using this function
				npcd_nodes[setn].DoPopulate = function( self )
					-- If we've already populated it replace it
					if self.PropPanel then self.PropPanel:Remove() end

					-- Create the container panel
					self.PropPanel = vgui.Create( "ContentContainer", pnlContent )
					self.PropPanel:SetVisible( false )
					self.PropPanel:SetTriggerSpawnlistChange( false )

					self.count = 0
					if ( cl_currentProfile and cl_Profiles[cl_currentProfile] ) then
						for name, prstbl in SortedPairs( cl_Profiles[cl_currentProfile][self.set] ) do
							if prstbl["npcd_enabled"] == false then
								continue
							end

							local cname = f_cnameget[setn] and f_cnameget[setn]( prstbl ) or GetPresetName( prstbl.classname ) or nil
							local mat = isstring( prstbl.icon ) and prstbl.icon or cname and file.Exists( "materials/entities/" .. cname .. ".png", "GAME" ) and "entities/" .. cname .. ".png" or UI_ICONS_SETS[self.set]
                     MatCacheNames[cl_currentProfile] = MatCacheNames[cl_currentProfile] or {}
                     MatCacheNames[cl_currentProfile][self.set] = MatCacheNames[cl_currentProfile][self.set] or {}
                     MatCacheNames[cl_currentProfile][self.set][name] = mat
							-- local icon = isstring( prstbl.icon ) and prstbl.icon

							if spawnmenu.CreateContentIcon( "npcd_preset", self.PropPanel, {
								name		= name,
								set      = setn,
								material	= mat,
								desc		= prstbl.description,
								-- icon		= icon
								-- enabled		= active,
							} ) then
								self.count = self.count + 1
							end
						end
					end
					self:SetText( SPAWN_SETS[self.set].." ("..tostring(self.count)..")" )
				end

				-- If we click on the node populate it and switch to it.
				npcd_nodes[setn].DoClick = function( self )
					self:DoPopulate()
					pnlContent:SwitchPanel( self.PropPanel )
				end

			// exists, and update signalled elsewhere (npcd_settings_send_end)
			elseif prof_changed and pnlContent.SelectedPanel != nil and pnlContent.SelectedPanel == npcd_nodes[setn].PropPanel then
				npcd_nodes[setn]:DoPopulate()
				pnlContent:SwitchPanel( npcd_nodes[setn].PropPanel )
				prof_changed = false
			end

			// update counts
			if IsValid( npcd_nodes[setn] ) then
				npcd_nodes[setn].count = 0
				if ( cl_currentProfile and cl_Profiles[cl_currentProfile] ) then
					for name, prstbl in SortedPairs( cl_Profiles[cl_currentProfile][setn] ) do
						if prstbl["npcd_enabled"] == false then
							continue
						end
						npcd_nodes[setn].count = npcd_nodes[setn].count + 1
					end
					npcd_nodes[setn]:SetText( SPAWN_SETS[setn].." ("..tostring(npcd_nodes[setn].count)..")" )
				end
			end
		end
	end
	prof_changed = false

end )

local PANEL = {}

Derma_Hook( PANEL, "Paint", "Paint", "Tree" )
PANEL.m_bBackground = true -- Hack for above

function PANEL:AddCheckbox( text, cname, nvar )
	local DermaCheckbox = self:Add( "DCheckBoxLabel", self )
	
	DermaCheckbox:Dock( TOP )
	DermaCheckbox:SetText( text )
	DermaCheckbox:SetDark( true )
	
	if nvar then // normal cvar
		DermaCheckbox:SetConVar( nvar )
	else
		local var = cvar[cname]
		DermaCheckbox:SetConVar( var.v:GetName() )
		DermaCheckbox:SetChecked( var.v:GetBool() )
		DermaCheckbox.OnChange = function( self, val )
			if val == var.v:GetBool() then return end

			if !var.v:IsFlagSet( FCVAR_REPLICATED ) then
				var.v:SetBool( tobool( val ) )
				return
			end

			if var.p and CheckClientPerm( LocalPlayer(), var.p ) 
			or !var.p and CheckClientPerm2( LocalPlayer(), "settings" ) then
				SendCvar( cname, val, var.t )
			end
		end
	end
	DermaCheckbox:SizeToContents()
	DermaCheckbox:DockMargin( 0, 5, 0, 0 )
end



function PANEL:Init()

	self:SetOpenSize( 190 ) --175 ) --150
	self:DockPadding( 15, 15, 15, 10 )

	self.proflabel = self:Add( "DLabel", self )
	self.proflabel:SetDark( true )
	self.proflabel:SetText( "Active Profile" )
	-- self.proflabel:SetText( cl_currentProfile and "Profile: "..cl_currentProfile or "No active profile" )
	self.proflabel:Dock( TOP )
	self.proflabel:SetContentAlignment( 8 )
	self.proflabel:SizeToContentsY()
	self.proflabel:DockMargin( 0, 0, 0, 5 )

	self.profselect = vgui.Create( "DComboBox", self )
	self.profselect:Dock( TOP )
	self.profselect:DockMargin( 0, 0, 0, 5 )
	self.profselect:SetSortItems( true )
	self.profselect:SetText( cl_currentProfile and "Profile: "..cl_currentProfile or "No active profile" )

	self.profselect.Recount = function( self )
		self:Clear()
		for prof in pairs( cl_Profiles ) do
			self:AddChoice( prof, prof, cl_currentProfile == prof )
		end
	end
	self.profselect:Recount()

	self.profselect.OnSelect = function( self, index, value )
		if cl_currentProfile != value and CheckClientPerm2( LocalPlayer(), "profiles" ) then
			ClientSwitchProfile( value )
		end
	end

	local button = self:Add( "DButton", self )
	button:SetText("Configure Profiles")
	button.OnReleased = function()
		LocalPlayer():ConCommand( "npcd_settings_open" )
	end
	button:Dock( TOP )
	button:DockMargin( 0, 0, 0, 5 )
	
	local helpbutton = self:Add( "DButton", self )
	helpbutton:SetText("Help")
	helpbutton.OnReleased = function()
		LocalPlayer():ConCommand( "npcd_settings_help" )
	end
	helpbutton:Dock( TOP )

	self:AddCheckbox( "Auto-Spawning Enabled", "spawn_enabled" )
	self:AddCheckbox( "#menubar.npcs.disableai", nil, "ai_disabled" )
	self:AddCheckbox( "#menubar.npcs.ignoreplayers", nil, "ai_ignoreplayers" )

	self:Open()

end

function PANEL:Recount()
	self.profselect:Recount()
	-- self.proflabel:SetText( cl_currentProfile and "Profile: "..cl_currentProfile or "No active profile" )
end

function PANEL:PerformLayout()
end

vgui.Register( "NPCDSidebarToolbox", PANEL, "DDrawer" )

spawnmenu.AddCreationTab( "NPCD", function()
		NPCDSpawnMenu = vgui.Create( "SpawnmenuContentPanel" )
		-- NPCDSpawnMenu.HorizontalDivider:SetLeftWidth( 100 )
		NPCDSpawnMenu:EnableSearch( "npcd_presets", "PopulateNPCD" ) // needed for tab to work. todo: search.AddProvider(), etc
		NPCDSpawnMenu:CallPopulateHook( "PopulateNPCD" )

		NPCDSideBar = NPCDSpawnMenu.ContentNavBar
		NPCDSideBar.Options = vgui.Create( "NPCDSidebarToolbox", NPCDSideBar )

		return NPCDSpawnMenu
	end,
	UI_ICONS.npcd,
	21
)

hook.Add( "Think", "NPCD Client Think", NPCDClientThink )