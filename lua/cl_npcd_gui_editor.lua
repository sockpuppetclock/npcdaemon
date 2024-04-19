module( "npcd", package.seeall )

if !CLIENT then return end

SettingsWindow = SettingsWindow or nil
PendingView = PendingView or {}
ValueEditors = ValueEditors or {}

local valuelist_queue = {}
local valuelist_storage = {}
local valuelist_all = {}

local showdefaults = false

co_valuelister = nil

function SettingsWindowDefaults()
	-- print( ScreenScale(312), ScrH() * 0.75 )
	-- return math.min( ScrW(), 780 ), ScrH() * 0.75
	-- return math.min( ScrW(), 804 ), ScrH() * 0.75
	return math.min( ScrW(), 804 ), math.min( math.max( 720, ScrH() * 0.75 ), ScrH() * 0.95 )
end

function UpdateSettingsTitle()
	if IsValid( SettingsWindow ) then
		local tab = IsValid( SettingsSheet ) and SettingsSheet:GetActiveTab() or nil
		if tab then
			tab_title = ( tab.Name and ": " .. tab.Name or "" )
		else
			tab_title = ""
		end
		SettingsWindow:SetTitle( 
			settings_title .. 
			tab_title .. 
			( ( cl_receiving or cl_receiving_man ) and " [Updating...]" or "" ) .. 
			( cl_sending and " [Committing...]" or "" ) )
	end
end

local last_panel_w, last_panel_h = SettingsWindowDefaults()

local last_panel_x, last_panel_y
local last_ld_w, last_rd_w

local new_table_add = {
	["struct_table"] = function() return {} end,
	["struct"] = function() return {} end, 
	["number"] = function() return 0 end,
	["int"] = function() return 0 end,
	["string"] = function() return "" end,
	["enum"] = function() return "" end,
	["boolean"] = function() return true end,
	["vector"] = function() return Vector() end,
	["angle"] = function() return Angle() end,
	["color"] = function() return color_white end,
	["any"] = function() return "" end,
	["default"] = function() return {} end,
	["preset"] = function() return {} end,
	["function"] = function() return {} end,
	["info"] = function() return "" end,
}

local lookup_to_valuename = {
	["all"] = true,
	["npc"] = true,
	["entity"] = true,
	["nextbot"] = true,
}

function StartSettingsPanel()
	if table.IsEmpty( cl_Profiles ) then
		QuerySettings( true )
	else
		QuerySettings()
	end

	if !CheckClientPerm( LocalPlayer(), cvar.perm_prof.v:GetInt() ) then
		chat.AddText( RandomColor( 0, 15, 0.75, 1, 1, 1 ),
		"You do not have permission to edit profiles! Permission: " .. ( cvar.perm_prof.v:GetInt() and t_PERM_STR[cvar.perm_prof.v:GetInt()] or "" ) )
		return
	end
	
	if IsValid(SettingsWindow) and ispanel(SettingsWindow) then
		if SettingsWindow:IsVisible() then return end
		ShowValueEditors()
		ShowSettingsPanel()
	else
		CreateSettingsPanel()
	end
end

function ShowSettingsPanel()
	SettingsWindow:Show()
	if !last_panel_x or !last_panel_y then
    	SettingsWindow:Center()
	else
		SettingsWindow:SetPos( last_panel_x, last_panel_y )
	end
	-- if SettingsPane.selectors then
	-- 	for _, p in pairs( SettingsPane.selectors ) do
	-- 		if IsValid( p ) then
	-- 			p:Show()
	-- 		end
	-- 	end
	-- end

	local tab = IsValid( SettingsSheet ) and SettingsSheet:GetActiveTab()
	if tab.panel and isfunction( tab.panel.ShowSelectors ) then
		tab.panel:ShowSelectors()
	end

	SettingsWindow:RequestFocus()
end

function HideSettingsPanel()
	if ispanel(SettingsWindow) and SettingsWindow:IsValid() then
		SettingsWindow:Remove()
	end
end

function ClearPending()
	PendingSettings = {}
	PendingRemove = {}
	PendingAdd = {}
	PendingView = {}
	if ispanel(SettingsWindow) and SettingsWindow:IsValid() and PendingList:IsValid() then
		DeselectPresetsList()
		UpdatePending()
		UpdateProfilesList()
		UpdatePresetSelection( true )
	end
end

function RemoveSettingsPanel()
	-- ClearPending()
	if ispanel(SettingsWindow) and SettingsWindow:IsValid() then
		DeselectValueList()
		SettingsWindow:Remove()
	end
	expanded_cats = {
		[t_CAT.DESC] = false,
	}
	ClearValueEditors()
	last_panel_w, last_panel_h = SettingsWindowDefaults()
	last_panel_x, last_panel_y = nil, nil
	last_ld_w, last_rd_w = nil, nil
end

function UpdateProfilesList()
	if !IsValid(SettingsWindow) or !ispanel(SettingsWindow)
	or !IsValid(SettingsList) or !ispanel(SettingsList) then
		return
	end
	SettingsList:Clear()
	SettingsList.lines = {}
	for pname, ptbl in SortedPairs( cl_Profiles ) do -- "profile 1", ptbl
		local pcount = 0
		for setname in pairs( ptbl ) do -- npc, npctbl
			local pkeys = table.Count( GetSetsPresets( pname, setname ) )
			pcount = pcount + pkeys
		end
		local active = ( pname == cl_currentProfile ) and "*" or ""

		SettingsList.lines[pname] = SettingsList:AddLine( pname , active, pcount )
	end

	if active_prof and SettingsList.lines[active_prof] then
		SettingsList:SelectItem( SettingsList.lines[active_prof] )
	end
end

function DeselectSettingsList()
	if !IsValid(SettingsWindow) or !ispanel(SettingsWindow) then return end
	SettingsList:ClearSelection()
	active_prof = nil

	DeselectSetsList()
end
function DeselectSetsList()
	if !IsValid(SetsList) or !ispanel(SetsList) then return end
	-- SetsList:Clear()
	-- SetsList:ClearSelection()
	-- active_set = nil

	DeselectPresetsList()
end
function DeselectPresetsList()
	if !IsValid(PresetsList) or !ispanel(PresetsList) then return end
	PresetsList:Clear()
	PresetsList:ClearSelection()
	active_prs = nil

	PresetsList.boxes = {}
	PresetsList.list = {}

	DeselectValueList()
end

function DeselectValueList()
	if !IsValid(ValueList) or !ispanel(ValueList) then return end
	-- ValueList:Clear()

	-- if SettingsPane.selectors then
	-- 	for _, p in pairs( SettingsPane.selectors ) do
	-- 		p:Remove()
	-- 	end
	-- end

	-- if isfunction( SettingsPane.RemoveSelectors ) then
	-- 	SettingsPane:RemoveSelectors()
	-- end
	-- SettingsPane.selectors = nil
	if isfunction( RightPanel.RemoveSelectors ) then
		RightPanel:RemoveSelectors()
	end
	RightPanel.selectors = nil

	ClearUnusedPending()
   ValueList.container:Remove()
	ValueList:Remove()
end

function ClearUnusedPending()
	for p, pt in pairs( PendingSettings ) do
		for s, st in pairs( pt ) do
			for prsname in pairs( st ) do
				if !HasPreset( PendingAdd, p, s, prsname ) and !HasPreset( ValueEditors, p, s, prsname ) then
					PendingSettings[p][s][prsname] = nil
				end
			end
		end
	end
end

function GetEnabledPresets( prof, set )
	local enabled_pctbl = {}

	// add pending and existing, exclude removes

	if HasSet( cl_Profiles, prof, set ) then
		for prsname, prstbl in pairs( cl_Profiles[prof][set] ) do
			local status
			if prstbl["npcd_enabled"] == nil then
				status = true
			else
				status = prstbl["npcd_enabled"]
			end
			enabled_pctbl[prsname] = status
		end
	end

	if HasSet( PendingSettings, prof, set ) then
		for prsname, prstbl in pairs( PendingSettings[prof][set] ) do
			local status
			if prstbl["npcd_enabled"] == nil then
				status = true
			else
				status = prstbl["npcd_enabled"]
			end
			enabled_pctbl[prsname] = status
		end
	end

	if HasSet( PendingRemove, prof, set ) then
		for prsname in pairs( PendingRemove[prof][set] ) do
			enabled_pctbl[prsname] = nil
		end
	end

	return enabled_pctbl
end

function GetEnabledPresetsTables( prof, set )
	local enabled_pctbl = {}

	// add pending and existing, exclude removes

	if HasSet( cl_Profiles, prof, set ) then
		for prsname, prstbl in pairs( cl_Profiles[prof][set] ) do
			if prstbl["npcd_enabled"] or prstbl["npcd_enabled"] == nil then
				enabled_pctbl[prsname] = prstbl
			end
		end
	end

	if HasSet( PendingSettings, prof, set ) then
		for prsname, prstbl in pairs( PendingSettings[prof][set] ) do
			if prstbl["npcd_enabled"] or prstbl["npcd_enabled"] == nil then
				enabled_pctbl[prsname] = prstbl
			else // false
				enabled_pctbl[prsname] = nil
			end
		end
	end

	if HasSet( PendingRemove, prof, set ) then
		for prsname in pairs( PendingRemove[prof][set] ) do
			enabled_pctbl[prsname] = nil
		end
	end

	return enabled_pctbl
end

function GetProfPresets( prof )
	local pftbl = {}
	for set in pairs( PROFILE_SETS ) do
		pftbl[set] = GetSetsPresets( prof, set )
	end
	return pftbl
end

function GetAllReferences( prof, t, n )
	local alltbl = GetProfPresets( prof )
	local ref = {}
	for set in pairs( alltbl ) do
		ref[set] = {}
		for prs, prstbl in pairs( alltbl[set] ) do
			ref[set][prs] = RecursivePresetTypeCount( prstbl, t, n )
			if ref[set][prs] == 0 then ref[set][prs] = nil end
		end
	end

	return ref
end

function RenameAllReferences( prof, t, old, new )
	local alltbl = GetProfPresets( prof )
	local ref = {}
	for set in pairs( alltbl ) do
		ref[set] = {}
		for prs, prstbl in pairs( alltbl[set] ) do
			ref[set][prs] = RecursiveRenameType( GetPendingTbl( prof, set, prs ), t, old, new )
			if ref[set][prs] > 0 then
				AddPresetPend( PendingAdd, prof, set, prs )
				print( "npcd > RenameAllReferences > References to \"" .. old .. "\" in <"..set .. "> "..prs.." were renamed to \""..new.."\"")
			else
				ref[set][prs] = nil
				// clearing unused pending is done in DeselectValueList() but not when the renamed has a value editor up
				ClearUnusedPending()
			end
		end
	end

	return ref
end

function RecursivePresetTypeCount( tbl, t, n )
	local send = 0
	for k, v in pairs( tbl ) do
		if istable( v ) then
			if v["name"] == n and v["type"] == t then
				-- print( v["name"], v["type"], n, t )
				send = send + 1
			else
				send = send + RecursivePresetTypeCount( v, t, n )
			end
		end
	end
	return send
end

function RecursiveAnyPresetCount( tbl, counter_t )
	for k, v in pairs( tbl ) do
		if istable( v ) then
			if v["name"] and v["type"] and PROFILE_SETS[v["type"]] then
				counter_t[ v["type"] ] = counter_t[ v["type"] ] or {}
				counter_t[ v["type"] ][ v["name"] ] = counter_t[ v["type"] ][ v["name"] ] or 0
				counter_t[ v["type"] ][ v["name"] ] = counter_t[ v["type"] ][ v["name"] ] + 1
			else
				RecursiveAnyPresetCount( v, counter_t )
			end
		end
	end
end

function RecursiveRenameType( tbl, t, old, new )
	local send = 0
	for k, v in pairs( tbl ) do
		if istable( v ) then
			if v["name"] == old and v["type"] == t then
				v["name"] = new
				send = send + 1
			else
				send = send + RecursiveRenameType( v, t, old, new )
			end
		end
	end
	return send
end

function CheckForPreset( prof, set, prs )
	return HasPreset( GetSetsPresets( prof, set ), prof, set, prs )
end

function GetSetsPresets( prof, set )
	local pctbl = {}

	// add pending and existing, exclude removes
	if HasSet( cl_Profiles, prof, set ) then
		for prsname, prstbl in pairs( cl_Profiles[prof][set] ) do
			pctbl[prsname] = prstbl
			-- pctbl[prsname] = true
		end
	end

	if HasSet( PendingSettings, prof, set ) then
		for prsname, prstbl in pairs( PendingSettings[prof][set] ) do
			pctbl[prsname] = prstbl
			-- pctbl[prsname] = true
		end
	end

	-- if HasSet( PendingAdd, prof, set ) then
	-- 	for prsname in pairs( PendingSettings[prof][set] ) do
	-- 		pctbl[prsname] = prstbl
	-- 		-- pctbl[prsname] = true
	-- 	end
	-- end

	if HasSet( PendingRemove, prof, set ) then
		for prsname in pairs( PendingRemove[prof][set] ) do
			pctbl[prsname] = nil
		end
	end

	return pctbl
end

function ValueWindow( title )
	local x, y = RightPanel:LocalToScreen()
	local ecount = 0
	for _, prof_t in pairs( ValueEditors ) do
		for _, set_t in pairs( prof_t ) do
			for _, ve in pairs( set_t ) do
				if IsValid( ve.Window ) then
					ecount = ecount + 1
				end
			end
		end
	end

	local window = vgui.Create( "DFrame", SettingsWindow )
	window:SetSize( 500, SettingsWindow:GetTall() )
	window:SetPos( math.Clamp( x + 21 + ( ecount * 21 ), 0, ScrW() - window:GetWide() / 4 ), math.Clamp( y + ( ecount * 21 ), 0, ScrH() - window:GetTall() / 4 ) )
	window:SetTitle( title )
	window:SetDraggable( true )
	window:SetSizable( true )
	window:SetMinWidth( 100 )
	window:SetMinHeight( 100 )	
	window:MakePopup()
	window:SetDeleteOnClose( true )

	window.OnClose = function( self )
		timer.Simple( 0, UpdatePresetSelection )
	end

	return window
end

function PanelFadeIn( parentpanel, vpanel, buffer, dur, col )
	local fade = vgui.Create( "Panel", parentpanel )
	local buffer = buffer or engine.TickInterval() * 60
	local start = SysTime() + buffer
	fade:SetSize( vpanel:GetSize() )
	fade:SetPos( vpanel:GetPos() )
	function fade:Paint( w, h )
		if !IsValid( vpanel ) then self:Remove() return end
		local t = SysTime() < start and 255 or Lerp( ( SysTime() - start ) / dur, 255, 0 )
		self:SetSize( vpanel:GetSize() )
		self:SetPos( vpanel:GetPos() )
		surface.SetDrawColor( col.r, col.g, col.b, t )
		surface.DrawRect( 0, 0, w, h )
		if SysTime() - start > dur then self:Remove() end
	end
end

function CreateValueEditor( prof, set, prs, inspanel, parentpanel, windowed )
	if !inspanel and HasPreset( ValueEditors, prof, set, prs ) then
		return
	end

	local panel = inspanel or vgui.Create( "Panel" )
	local parentpanel = parentpanel or panel
	local sheet

	if windowed then
		// floating window

		local window = ValueWindow( prof .. " > " .. set .. " > " .. prs )
		
		panel:SetParent( window )
		panel:Dock( FILL )
		sheet = {}
		sheet.Panel = parentpanel
		sheet.Window = window
		AddPresetPend( ValueEditors, prof, set, prs, sheet )
		
	elseif !inspanel then
		// tab

		sheet = SettingsSheet:AddSheet( prof .. " > " .. set .. " > " .. prs, panel, nil, nil, nil, prof .. " > " .. set .. " > " .. prs )

		sheet.Tab.panel = parentpanel // GetActiveTab()
		sheet.Tab.prof = prof
		sheet.Tab.set = set
		sheet.Tab.prs = prs
		sheet.Tab.Name = sheet.Name
	end

	if !inspanel then
		AddPresetPend( ValueEditors, prof, set, prs, sheet )
	
		parentpanel.OnRemove = function( self )
			RemovePresetPend( ValueEditors, prof, set, prs )
			self:RemoveSelectors()

			// if nothing changed, clear pendingsettings
			if !HasPreset( PendingAdd, prof, set, prs ) and HasPreset( PendingSettings, prof, set, prs ) then
				PendingSettings[prof][set][prs] = nil
				UpdatePending()
			end
		end
	end

	parentpanel.HideSelectors = function( self )
		if self.selectors then
			for _, p in pairs( self.selectors ) do
				if IsValid( p ) then
					p:Hide()
				end
			end
		end
	end

	parentpanel.RemoveSelectors = function( self )
		if self.selectors then
			for _, p in pairs( self.selectors ) do
				if IsValid( p ) then
					p:Remove()
				end
			end
		end
		self.selectors = nil
	end

	parentpanel.ShowSelectors = function( self )
		if self.selectors then
			for _, p in pairs( self.selectors ) do
				if IsValid( p ) then
					p:Show()
				end
			end
		end
	end

	parentpanel.OnSizeChanged = function( self, w, h )
		if IsValid( self.vpanel ) then
			self.vpanel:InvalidateLayout( true )
			self.vpanel:SizeToChildren( false, true )
			self.vpanel:SetTall( self.vpanel:GetTall() + 15 )
			self.vpanel.container:InvalidateLayout( true )
			self.vpanel.container:SizeToChildren( false, true )
			self.vpanel.container:SetTall( self.vpanel.container:GetTall() + 15 )
		end
	end

	local vpanel = CreateValueEditorList( panel, prof, set, prs, parentpanel )

	if !inspanel then
		sheet.ValueList = vpanel
		if !windowed then ValueEditors[prof][set][prs].Panel:HideSelectors() end
	end

	return vpanel
end

local tooltip_uncatagory = {
   ["DESC"] = true,
   ["NAME"] = true,
   ["CATEGORY"] = true,
   ["STRUCT"] = true,
   ["TBLSTRUCT"] = true,
   ["STRUCT_TBLMAINKEY"] = true,
   ["STRUCT_RECURSIVE"] = true,
   ["FUNCTION"] = true,
   ["FUNCTION_GET"] = true,
   ["ENUM"] = true,
   ["ENUM_SORT"] = true,
}

local adder_icon = {
	['*'..t_CAT.REQUIRED] = "icon16/asterisk_yellow.png",
	[t_CAT.REQUIRED] = "icon16/asterisk_yellow.png",
	[t_CAT.PHYSICAL] = "icon16/anchor.png",
	[t_CAT.COMBAT] = "icon16/gun.png",
	[t_CAT.HEALTH] = "icon16/heart.png",
	[t_CAT.BEHAVIOR] = "icon16/group_large.png",
	[t_CAT.CHASE] = "icon16/car.png",
	[t_CAT.VISUAL] = "icon16/palette.png",
	[t_CAT.NPCD] = UI_ICONS.npcd,
	[t_CAT.MISC] = "icon16/lightning.png",
	[t_CAT.OVERRIDE] = "icon16/shape_move_forwards.png",
	[t_CAT.ANNOUNCE] = "icon16/bell.png",
	[t_CAT.DAMAGE] = "icon16/fire.png",
	[t_CAT.MOVEMENT] = "icon16/car.png",
	[t_CAT.EQUIP] = "icon16/bricks.png",
	[t_CAT.SPAWN] = "icon16/wand.png",
}

local UI_STR = {
   classstruct_get = "Show Class-Specific Values",
   classstruct_in = "Class Values Included",
}

function ControlPane( panel, vpanel, prof, set, prs, parentpanel )
	local cpane = vgui.Create( "Panel", panel )
	cpane:Dock( TOP )
	cpane:SetWide( panel:GetWide() )

   cpane.panel = panel
   cpane.vpanel = vpanel
   cpane.prof = prof
   cpane.set = set
   cpane.prs = prs

   local adder = vgui.Create( "DButton", cpane )
   local opts = vgui.Create( "DButton", cpane )
   -- local deffer = vgui.Create( "DCheckBoxLabel", cpane )
   cpane.adder = adder
   cpane.opts = opts
   -- cpane.deffer = deffer
   adder.cpane = cpane
   adder:SetText("Add Value...")
   -- adder:SetIcon("icon16/add.png")
   adder:SetWide( math.min( cpane:GetWide() - 20, 260 ) )
   adder:SetTall( adder:GetTall() + 10 )
   adder:SetPos( math.max(0, cpane:GetWide() - adder:GetWide() + UI_BUTTON_W), 5 )
   
   opts:SetText("")
   opts:SetIcon("icon16/table_gear.png")
   opts:SetSize(UI_ICONBUTTON_W, UI_BUTTON_H)
   opts:SetPos( adder:GetPos() - UI_BUTTON_W, 5 )
   opts:SetTall( adder:GetTall() )

   cpane.AnimationThink = function( self )
		if !IsValid( vpanel ) then
			self:Remove()
		end
      self:SetWide( self.panel:GetWide() )
      self:SizeToChildren( false, true )
      self:SetTall( self:GetTall() + 10 )
      local scroll = self.panel:GetVBar():GetScroll()
      if IsValid(self.vpanel) and IsValid(self.vpanel.infopane) then
         if scroll < self.vpanel.infopane:GetTall() then
            self:SetPos( 0, self.vpanel.infopane:GetTall() )
         else
            self:SetPos( 0, self.panel:GetVBar():GetScroll() )
         end
      end
      self.adder:SetWide( math.min( self:GetWide() - 20 - UI_BUTTON_W, 260 ) )
      self.adder:SetPos( math.max(0, (self:GetWide() - self.adder:GetWide() + UI_BUTTON_W/2)/2), 5 )
      self.opts:SetPos( self.adder:GetPos() - UI_BUTTON_W, 5 )
	end

   opts.ShowDefaultsChanged = function( self )
      local ts = GetPrsTbl(valuelist_all, prof, set, prs )
      local t_key = {}
      for vn, v in pairs(ts) do
         t_key[vn] = string.lower(v.displayname)
      end
      if showdefaults then
         for vn in SortedPairsByValue(t_key) do
            if ts[vn].hasdefault then
               UnstoreValuelist(prof, set, prs, vn, nil, true)
            end
         end
      elseif not cl_cvar.valuelist_showall.v:GetBool() then
         for vn in SortedPairsByValue(t_key) do
            if IsValid(ts[vn].selfpanel) and ts[vn].hasdefault and (!GetPendingTbl(prof, set, prs) or GetPendingTbl(prof, set, prs)[vn] == nil) then
               ts[vn].selfpanel:Remove()
               ts[vn].selfpanel = nil
               ts[vn].forceshow = nil
               GetPrsTbl(valuelist_storage, ts[vn].prof, ts[vn].set, ts[vn].prs)[vn] = ts[vn]
            end
         end
      end
   end

   opts.ShowAllChanged = function( self )
      local t = GetPrsTbl(valuelist_all, prof, set, prs )
      local ts = GetPrsTbl(valuelist_storage, prof, set, prs )
      local t_key = {}
      local ts_key = {}
      for vn, v in pairs(t) do
         t_key[vn] = string.lower(v.displayname)
      end
      if cl_cvar.valuelist_showall.v:GetBool() then
         for vn in SortedPairsByValue(t_key) do
            if ts[vn] then
               UnstoreValuelist(prof, set, prs, vn, nil, true)
            end
         end
      else
         for vn in SortedPairsByValue(t_key) do
            if IsValid(t[vn].selfpanel)
            and (!GetPendingTbl(prof, set, prs) or GetPendingTbl(prof, set, prs)[vn] == nil)
            and (!t[vn].hasdefault or t[vn].hasdefault and !showdefaults)
            and !t[vn].required
            then
               t[vn].selfpanel:Remove()
               t[vn].selfpanel = nil
               t[vn].forceshow = nil
               GetPrsTbl(valuelist_storage, t[vn].prof, t[vn].set, t[vn].prs)[vn] = t[vn]
            end
         end
      end
   end

   opts.DoClick = function( self )
      local menu = DermaMenu()
      local deffer = menu:AddOption("Show values that have defaults", function()
         showdefaults = !showdefaults
         self.ShowDefaultsChanged()
      end)
      deffer:SetIsCheckable(true)
      deffer:SetChecked(showdefaults)
      local aller = menu:AddOption("Always show all values", function()
         cl_cvar.valuelist_showall.v:SetBool(!cl_cvar.valuelist_showall.v:GetBool())
         self.ShowAllChanged()
      end)
      aller:SetIsCheckable(true)
      aller:SetChecked(cl_cvar.valuelist_showall.v:GetBool())
      menu:Open()
   end


   adder.DoClick = function( self )
      local menu = DermaMenu()
      local prof = self.cpane.prof
      local set = self.cpane.set
      local prs = self.cpane.prs
      local pan = self.cpane.panel
      local t = GetPrsTbl(valuelist_all, prof, set, prs )
      local t_stored = GetPrsTbl(valuelist_storage, prof, set, prs )
      local sorted_key = {}
		if t then
         for vn, v in pairs(t) do
            if v.category == t_CAT.DESC then continue end
            sorted_key[v.category] = sorted_key[v.category] or {}
            sorted_key[v.category][vn] = string.lower(v.displayname)
         end
         for cat in SortedPairs(sorted_key) do
            local submenu, subbutt = menu:AddSubMenu(tostring(cat))
            if adder_icon[cat] then
               subbutt:SetIcon(adder_icon[cat])
            end

            for vn in SortedPairsByValue(sorted_key[cat]) do
               local v = t[vn]
               local butt = submenu:AddOption( v.displayname, function()
                  if not UnstoreValuelist(prof, set, prs, vn) then
                     if IsValid(pan) then
                        // note: scroll for new values are done in valuelist routine instead
                        if v.fpanel and !v.fpanel:GetExpanded() then v.fpanel:Toggle() end // open form
                        if IsValid(v.selfpanel) then pan:ScrollToChild(v.selfpanel) end //existing
                     end
                  end
               end )

               -- if not (t_stored and t_stored[vn]) then
               if GetPendingTbl(prof, set, prs) and GetPendingTbl(prof, set, prs)[vn] != nil then
                  butt:SetIsCheckable(true)
                  butt:SetChecked(true)
               end
               
               butt.tooltip = v.displayname
               if v.structTbl.DESC then
                  butt.tooltip = butt.tooltip .. "\n" .. tostring( v.structTbl.DESC )
               end
               for k, v in SortedPairs( v.structTbl ) do
                  if tooltip_uncatagory[k] then
                     continue
                  end
                  local str
                  if istable( v ) then
                     -- str = table.ToString( v )
                     local first = true
                     local c = 0
                     str = ""
                     for kk, vv in pairs( v ) do
                        c = c + 1
                        if c > 10 then
                           str = tostring( v )
                           break
                        end
                        if istable(vv) then
                           str = tostring( v )
                           break
                        end
                        if first then
                           str = str..tostring( vv )
                           first = false
                        else
                           str = str..", "..tostring( vv )
                        end
                     end
                  else
                     str = tostring( v )
                  end
                  butt.extratip = ( butt.extratip and butt.extratip.."\n" or "" ) .. k .. ": " .. str
               end

               butt.tippan = vgui.Create( "Panel", butt )
               butt.tippan:SetVisible( true )
               butt.tippan.Think = function( self )
                  if !IsValid(self) then return end
                  self.text:SetWrap( true )
                  if self.extratext then self.extratext:SetWrap( true ) end
                  self:SetSize( 312.5, self.text:GetTall() + ( self.extratext and self.extratext:GetTall() or 0 ) )
               end
               -- butt.tippan:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
               butt.tippan.text = vgui.Create( "DLabel", butt.tippan )
               butt.tippan.text:SetText( butt.tooltip )
               butt.tippan.text:SetDark( true )
               butt.tippan.text:Dock( TOP )
               butt.tippan.text:SetAutoStretchVertical( true )
               butt.tippan.text:SetWidth( 250 )
               if butt.extratip then
                  butt.tippan.extratext = vgui.Create( "DLabel", butt.tippan )
                  butt.tippan.extratext:SetText( butt.extratip )
                  butt.tippan.extratext:SetColor( Color( 0, 0, 0, 172 ) )
                  butt.tippan.extratext:Dock( TOP )
                  butt.tippan.extratext:SetAutoStretchVertical( true )
                  butt.tippan.extratext:SetWidth( 250 )
               end

               -- butt:SetContentAlignment( 5 )
               butt:SetTooltipPanel( butt.tippan )
               butt:SetTooltipDelay( 0 )

            end
         end
      end
      menu:Open()
   end

end

function InfoPan( panel, vpanel, prof, set, prs, parentpanel )
	local infopane = vgui.Create( "Panel", panel )
	infopane:Dock( TOP )
	infopane:SetWide( panel:GetWide() )
	-- infopane:SetHeight( 150 )
	-- print( "infpane", panel, vpanel )

	local prstbl = GetPendingTbl( prof, set, prs )
	local cname = f_cnameget[set] and f_cnameget[set]( prstbl ) or GetPresetName( prstbl.classname ) or nil
	local mat = isstring( prstbl.icon ) and prstbl.icon or cname and file.Exists( "materials/entities/" .. cname .. ".png", "GAME" ) and "entities/" .. cname .. ".png" or UI_ICONS_SETS[set]
	local left = 0
	local top = marg

	local bwide = 126
	local winwide = 400

	local prof = prof
	local set = set
	local prs = prs

	if SPAWN_SETS[set] then
		left = left+10
		-- infopane.icon = vgui.Create( "DImage", infopane )
		-- infopane.icon:SetMaterial( mat )
		-- infopane.icon:SetSize( 125, 125 )
		-- infopane.icon:SetPos( 10, 10 )
		top = top+3
		infopane.icon = vgui.Create( "ContentIcon", infopane )
		infopane.icon:SetContentType( "npcd_preset" )
		infopane.icon:SetName( prs )
		-- infopane.icon:SetMaterial( mat )
		infopane.icon:SetColor( Color( 205, 92, 92, 255 ) )
		infopane.icon:SetToolTip( prs .. ( prstbl.description and ( "\n" .. tostring( prstbl.description ) ) or "" ) .. "\nClick to edit icon" )
		infopane.icon:SetPos( left, 10 )
		infopane.icon.browser = nil
		function infopane.icon:OnReleased()
			prstbl = GetPendingTbl( prof, set, prs )
			if IsValid( self.browser ) then return end
			self.browser = AssetBrowserBasic( "images", function( path )
				if !IsValid( infopane ) then return end
				prstbl.icon = path
				-- infopane.icon:SetMaterial( path )
				self:RefreshIcon()
				AddPresetPend( PendingAdd, prof, set, prs )
				UpdatePending()
			end )
		end
		left = left+125

		function infopane.icon:RefreshIcon()
			prstbl = GetPendingTbl( prof, set, prs )
			local cname = f_cnameget[set] and f_cnameget[set]( prstbl ) or GetPresetName( prstbl.classname ) or nil
			local mat = isstring( prstbl.icon ) and prstbl.icon or cname and file.Exists( "materials/entities/" .. cname .. ".png", "GAME" ) and "entities/" .. cname .. ".png" or UI_ICONS_SETS[set]
			-- infopane.icon:SetMaterial( mat )
			// set unlit for non-pngs to fix black flickering
			if mat and mat:match("(.+)%.vmt") then
				local unlit_mat = npcd.get_unlit_mat( mat )
				self.Image:SetMaterial( unlit_mat )
			else
				self:SetMaterial( mat )
			end
		end

		infopane.icon:RefreshIcon()

		infopane.b_icon_edit = vgui.Create( "DButton", infopane )
		infopane.b_icon_edit:SetPos( left+10, top )
		infopane.b_icon_edit:SetWide( bwide * 0.6 )
		infopane.b_icon_edit:SetText( "Edit Icon" )
		function infopane.b_icon_edit:OnReleased()
			infopane.icon:OnReleased()
		end
		infopane.b_icon_clear = vgui.Create( "DButton", infopane )
		infopane.b_icon_clear:SetPos( left+10+infopane.b_icon_edit:GetWide(), top )
		infopane.b_icon_clear:SetWide( bwide * 0.4 )
		infopane.b_icon_clear:SetText( "Clear" )
		function infopane.b_icon_clear:OnReleased()
			prstbl = GetPendingTbl( prof, set, prs )
			if prstbl.icon != nil then
				prstbl.icon = nil
				AddPresetPend( PendingAdd, prof, set, prs )
				UpdatePending()
				infopane.icon:RefreshIcon()
			end
		end

		top = top + infopane.b_icon_edit:GetTall()
	else
		infopane.name = vgui.Create( "DLabel", infopane )
		infopane.name:SetText( prs )
		infopane.name:SetPos( left+marg, top )
		infopane.name:SetWide( infopane:GetWide() - left - marg * 2 - 15 )
		infopane.name:SetBright( true )
		infopane.name:SetContentAlignment( left > 0 and 4 or 5 )
		top=top+infopane.name:GetTall()
	end
	// Edit Assigned Spawnpools...

	if POOL_SETS[set] then
		infopane.b_spawnpool = vgui.Create( "DButton", infopane )
		infopane.b_spawnpool:SetPos( left+10, top )
		infopane.b_spawnpool:SetWide( 126 )

		top = top + infopane.b_spawnpool:GetTall()

		infopane.b_spawnpool.pools = {}

		infopane.CheckPools = function( self )
			local pools = GetSetsPresets( prof, "spawnpool" )
			local squads = GetSetsPresets( prof, "squad" )
			infopane.pools = {}
			infopane.poolcount = 0
			for p_prs, p_prstbl in pairs( pools ) do
				local included
				local in_squad
				local count = 0
				if p_prstbl.spawns then
					for k, entry in pairs( p_prstbl.spawns ) do
						if entry.preset then
							if entry.preset.type == set and entry.preset.name == prs then
								included = included or {}
								included[k] = entry.expected and entry.expected.f or 1
								count = count + 1
							elseif entry.preset.type == "squad" then
								if entry.preset.name and squads[entry.preset.name] and squads[entry.preset.name].spawnlist then
									for _, sq_entry in pairs( squads[entry.preset.name].spawnlist ) do
										if sq_entry.preset and sq_entry.preset.type == set and sq_entry.preset.name == prs then
											included = included or {}
											included[k] = entry.expected and entry.expected.f or 1
											in_squad = in_squad or {}
											table.insert( in_squad, entry.preset.name )
										end
									end
								end
							end
						end
					end
				end
				infopane.pools[p_prs] = {
					included = included,
					in_squad = in_squad,
					count = count + (in_squad and #in_squad or 0),
				}
			end
			for p_prs, p in pairs( infopane.pools ) do
				-- print( p.included )
				if p.included then
					infopane.poolcount = infopane.poolcount + 1
				end
			end
			infopane.b_spawnpool:SetText( infopane.poolcount > 0 and "View Pools (".. infopane.poolcount ..")" or "View Pools" )
			infopane.b_spawnpool:SizeToContentsX( 25 )
			infopane:Resize()
			-- infopane.b_spawnpool:SetWide( math.max( bwide, infopane.b_spawnpool:GetWide(), infopane.b_sqd and infopane.b_sqd:GetWide() or 0 ) )
			-- if infopane.b_sqd then
			-- 	infopane.b_sqd:SetWide( math.max( bwide, infopane.b_spawnpool:GetWide(), infopane.b_sqd:GetWide() ) )
			-- end
			-- if infopane.b_icon then
			-- 	infopane.b_icon:SetWide( math.max( 126, infopane.b_spawnpool:GetWide(), infopane.b_sqd and infopane.b_sqd:GetWide() or 0 ) )
			-- end
		end
		
		infopane.b_spawnpool.OnReleased = function( self )
			local frame = vgui.Create( "DFrame", self )
			frame:SetSize( winwide, 100+UI_BUTTON_H )
			local x, y = self:LocalToScreen()
			x = x - frame:GetWide() / 3
			frame:SetPos( x, y )
			frame:SetTitle( "Pools for \""..prs.."\" [Double-click to open in editor]" )
			-- frame:SetTitle( "" )
			frame:SetDraggable( true )
			frame:SetSizable( true )
			frame:MakePopup()
			frame:SetDeleteOnClose( true )
			-- frame:ShowCloseButton( false )

			local goedit = vgui.Create( "DButton", frame )
			goedit:SetText( "Edit spawnpools" )
			goedit:SizeToContentsX( 25 )
			goedit:SetPos( frame:GetWide() - goedit:GetWide(), frame:GetTall() - goedit:GetTall() )
			goedit:SetZPos( 999 )
			goedit:Dock( BOTTOM )
			function goedit:OnReleased()
				for i, line in pairs( SetsList:GetLines() ) do
					if SetsList.data[line:GetColumnText( 1 )] == "spawnpool" then
						SetsList:ClearSelection()
						SetsList:SelectItem( line )
					end
				end
			end

			infopane:CheckPools()

			local pan = vgui.Create( "DListView", frame )
			pan:Dock( FILL )
			local col_name = pan:AddColumn( "Pool Preset" ):SetWidth( frame:GetWide() * 0.4 )
			local col_enabled = pan:AddColumn( "Included" ):SetWidth( frame:GetWide() * 0.4 )
			local col_frac = pan:AddColumn( "Expected" ):SetWidth( frame:GetWide() * 0.3 )
			for p_prs, p in SortedPairs( infopane.pools ) do
				if p.included then
					local chance_t = CompareExpected( prof, "spawnpool", p_prs, "spawns" )
					local str
					for k, chance in pairs( p.included ) do
						-- PrintTable( chance_t[k] )
						if !chance_t[k] then continue end
						-- str = (str and str..", " or "" )..to_frac(chance, true)
						str = (str and str..", " or "" )..chance_t[k][2]
					end
					str = str or ""
					local instr = p.in_squad and tostring(p.count).." ("..( #p.in_squad > 1 and (#p.in_squad .. " Squads") or ("Squad: "..tostring(p.in_squad[1]) ) )..")" or p.included and tostring(p.count) or ""
					pan:AddLine( p_prs, instr, str ):SetToolTip( p_prs .. " | " .. instr .. " | " .. str )
				end
			end

			pan:SortByColumns( 1, true, 2 )
			function pan:DoDoubleClick( id, line )
				GetOrCreateValueEditor( prof, "spawnpool", line:GetColumnText(1), true )
			end

			if infopane.poolcount == 0 then
				local str = Label( "This preset is currently not in any spawnpool presets, and won't be automatically spawned", frame )
				str:DockMargin( marg, 5, marg, 5 )
				str:Dock( BOTTOM )
				str:SetZPos( 1 )
				goedit:SetZPos( -1 )
				str:SetWrap( true )
				str:SetAutoStretchVertical( true )
			end
			frame:SetTall( math.max( 100+UI_BUTTON_H, UI_BUTTON_H + 27 + pan:GetHeaderHeight() + pan:GetDataHeight() * math.min( 10, infopane.poolcount + 1 ) ) )
		end
		
		if set != "squad" then
			infopane.b_sqd = vgui.Create( "DButton", infopane )
			infopane.b_sqd:SetPos( left+10, top )--140+21 )
			infopane.b_sqd:SetText( "View Squads" )
			infopane.b_sqd:SetWide( math.max( 126, infopane.b_spawnpool:GetWide() ) )
			infopane.b_spawnpool:SetWide( math.max( infopane.b_spawnpool:GetWide(), infopane.b_sqd:GetWide() ) )
			top = top + infopane.b_sqd:GetTall()

			infopane.CheckSquads = function( self )
				local squads = GetSetsPresets( prof, "squad" )
				infopane.squads = {}
				infopane.squadcount = 0
				for p_prs, p_prstbl in pairs( squads ) do
					local included
					local in_squad
					local count = 0
					if p_prstbl.spawnlist then
						for k, entry in pairs( p_prstbl.spawnlist ) do
							if entry.preset then
								if entry.preset.type == set and entry.preset.name == prs then
									included = included or {}
									included[k] = entry.chance or {
										["n"] = 1,
										["d"] = 1,
										["f"] = 1,
									}
									count = count + 1
								end
							end
						end
					end
					infopane.squads[p_prs] = {
						included = included,
						count = count,
					}
				end
				for p_prs, p in pairs( infopane.squads ) do
					-- print( p.included )
					if p.included then
						infopane.squadcount = infopane.squadcount + 1
					end
				end
				infopane.b_sqd:SetText( infopane.poolcount > 0 and "View Squads (".. infopane.squadcount ..")" or "View Squads" )
				infopane.b_sqd:SizeToContentsX( 25 )
				infopane:Resize()
				-- infopane.b_sqd:SetWide( math.max( bwide, infopane.b_spawnpool:GetWide(), infopane.b_sqd:GetWide() ) )
				-- infopane.b_spawnpool:SetWide( math.max( bwide, infopane.b_spawnpool:GetWide(), infopane.b_sqd:GetWide() ) )
				-- if infopane.b_icon then
				-- 	infopane.b_icon:SetWide( math.max( 126, infopane.b_spawnpool:GetWide(), infopane.b_sqd and infopane.b_sqd:GetWide() or 0 ) )
				-- end
			end

			infopane.b_sqd.OnReleased = function( self )
				local frame = vgui.Create( "DFrame", self )
				frame:SetSize( winwide, 100+UI_BUTTON_H )
				local x, y = self:LocalToScreen()
				x = x - frame:GetWide() / 3
				frame:SetPos( x, y )
				frame:SetTitle( "Squads for \""..prs.."\" [Double-click to open in editor]" )
				-- frame:SetTitle( "" )
				frame:SetDraggable( true )
				frame:SetSizable( true )
				frame:MakePopup()
				frame:SetDeleteOnClose( true )

				local goedit = vgui.Create( "DButton", frame )
				goedit:SetText( "Edit squads" )
				goedit:SizeToContentsX( 25 )
				goedit:SetPos( frame:GetWide() - goedit:GetWide(), frame:GetTall() - goedit:GetTall() )
				goedit:SetZPos( 999 )
				goedit:Dock( BOTTOM )
				function goedit:OnReleased()
					for i, line in pairs( SetsList:GetLines() ) do
						if SetsList.data[line:GetColumnText( 1 )] == "squad" then
							SetsList:ClearSelection()
							SetsList:SelectItem( line )
						end
					end
				end

				local pan = vgui.Create( "DListView", frame )
				pan:Dock( FILL )
				local col_name = pan:AddColumn( "Squad Preset" ):SetWidth( frame:GetWide() * 0.5 )
				local col_enabled = pan:AddColumn( "Included" ):SetWidth( frame:GetWide() * 0.3 )
				local col_chance = pan:AddColumn( "Chance" ):SetWidth( frame:GetWide() * 0.3 )

				infopane:CheckSquads()
				for p_prs, p in SortedPairs( infopane.squads ) do
					if p.included then
						local str
						for k, chance in pairs( p.included ) do
							-- print( chance )
							str = (str and str..", " or "" )..chance.n.." / "..chance.d --to_frac(chance, true)
						end
						str = str or ""
						pan:AddLine( p_prs, p.included and tostring(p.count) or "", str ):SetToolTip( p_prs .. " | " ..( p.included and tostring(p.count) or "" ) .. " | " .. str )
					end
				end

				pan:SortByColumns( 1, true, 2 )

				if infopane.squadcount == 0 then
					local str = Label( "This preset is currently not in any squad presets", frame )
					str:DockMargin( marg, 5, marg, 5 )
					str:Dock( BOTTOM )
					str:SetZPos( 1 )
					goedit:SetZPos( -1 )
					str:SetWrap( true )
					str:SetAutoStretchVertical( true )
				end

				frame:SetTall( math.max( 100+UI_BUTTON_H, UI_BUTTON_H + 27 + pan:GetHeaderHeight() + pan:GetDataHeight() * math.min( 10, infopane.squadcount + 1 ) ) )

				function pan:DoDoubleClick( id, line )
					GetOrCreateValueEditor( prof, "squad", line:GetColumnText(1), true )
				end
			end
		end
	end

	infopane.Resize = function( self )
		local butwide = math.max( bwide, infopane.b_sqd and infopane.b_sqd:GetWide() or 0, infopane.b_spawnpool and infopane.b_spawnpool:GetWide() or 0 )
		if infopane.b_sqd then
			infopane.b_sqd:SetWide( butwide )
		end
		if infopane.b_spawnpool then
			infopane.b_spawnpool:SetWide( butwide )
		end
		if infopane.b_icon_edit then
			infopane.b_icon_edit:SetWide( math.floor(butwide * 0.6) )
			infopane.b_icon_clear:SetWide( math.ceil(butwide * 0.4) )
			infopane.b_icon_clear:SetPos( left+10+infopane.b_icon_edit:GetWide(), infopane.b_icon_clear:GetY() )
		end
	end

	if isfunction( infopane.CheckPools ) then infopane:CheckPools() end
	if isfunction( infopane.CheckSquads ) then infopane:CheckSquads() end
	infopane:Resize()

		// CheckboxPrompt
	// Show References convar
	// Description TextPrompt (multiline)
	-- if prstbl.description or GetPresetName( prstbl.classname ) then
	-- infopane.descbox = vgui.Create( "Panel", infopane )
	infopane.desc = vgui.Create( "DLabel", infopane )
	infopane.desc:SetWrap( true )
	infopane.desc:SetAutoStretchVertical( true )
	infopane.desc:SetContentAlignment( 5 )
	function infopane.desc:RefreshDesc()
		prstbl = GetPendingTbl( prof, set, prs )
		if infopane.icon then
			infopane.desc:SetPos( marg+left+3, top+marg )
		else
			infopane.desc:SetPos( marg+3, ( infopane.icon and infopane.icon:GetTall() or infopane.name and infopane.name:GetTall() or 0 ) + 17 )
		end
		-- infopane.desc:SetPos( marg+3, 10 )
		-- infopane.desc:SetPos( left+marg+3, top )
		-- infopane.desc:SetPos( marg+3, top )
		infopane.desc:SetText( prstbl.description or GetPresetName( prstbl.classname ) or "" )
		if prstbl.description then
			infopane.desc:SetTextColor( Color( 235, 235, 235 ) )
		else
			infopane.desc:SetTextColor( Color( 210, 210, 210 ) )
		end
		-- infopane.desc:SetWide( infopane:GetWide() - left - marg - 15 - 3 )
		if infopane.icon then
			infopane.desc:SetWide( infopane:GetWide() - left - marg * 2 )
		else
			infopane.desc:SetWide( infopane:GetWide() - marg * 2 )
		end
		infopane.desc:SizeToContentsY( 0 )
		if infopane.desc:GetText() == "" then
			infopane.desc:SetVisible( false )
		else
			infopane.desc:SetVisible( true )
			-- infopane.desc:SetSize( 0 )
			-- infopane.desc:SetPos( 0, 0 )
		end
		-- infopane.desc:SetSize( infopane:GetWide() - marg - 15 - 3, 50 )
		-- infopane.descbox:SetPos( infopane.desc:GetX() - 5, infopane.desc:GetY() - 5 )
		-- infopane.descbox:SetSize( infopane.desc:GetWide() + 10, infopane.desc:GetTall() + 10 )
		-- infopane.desc:SetMultiline( true )
	end
	infopane.desc:RefreshDesc()
	-- end
	-- infopane.desc:SizeToContentsY()
	-- function infopane.descbox:Paint( w, h )
	-- 	self:DrawOutlinedRect()
	-- end
	-- function infopane.desc:Paint( w, h )
		-- surface.SetDrawColor( 255, 255, 255 )
		-- surface.DrawOutlinedRect( 0, 0, w + 10, h + 10 )
		-- self:DrawTextEntryText( Color( 255, 255, 255), Color( 128, 128, 128 ), Color( 255, 255, 255) )
	-- 	derma.SkinHook( "Paint", "TextEntry", self, w, h )
	-- 	return false
	-- end

	// [?] multiline height is based on an invisible Label that has AutostretchVertical that mimics the textentry
	// icon panel

	infopane:InvalidateLayout( true )
	infopane:SizeToChildren( false, true )
	infopane:SetTall( infopane:GetTall() + 10 )

	-- local sbar = panel:GetVBar()
	-- infopane
	-- timer.Create("infopantest", 1, 10, function()
	-- 	print( vpanel, parentpanel.OnSizeChanged )
	-- 	if !IsValid( vpanel ) then
	-- 		timer.Destroy( "infopantest" )
	-- 		return
	-- 	end
	-- 	parentpanel:OnSizeChanged()
	-- end )

	infopane.AnimationThink = function( self )
		if !IsValid( vpanel ) then
			self:Remove()
		end
		-- infopane.desc:SetWide( self:GetWide() - left - marg - 15 )
		if infopane.name then
			infopane.name:SetWide( infopane:GetWide() - left - marg * 2 - 15 )
		end
		if infopane.desc then
			-- infopane.desc:SetWide( self:GetWide() - left - marg - 15 - 3 )
			if infopane.icon then
				infopane.desc:SetWide( infopane:GetWide() - left - marg * 2 )
			else
				infopane.desc:SetWide( infopane:GetWide() - marg * 2 )
			end
			infopane.desc:SizeToContentsY( 0 )
		end
		infopane:SizeToChildren( false, true )
		infopane:SetTall( infopane:GetTall() + 10 )
		-- if isfunction( parentpanel.OnSizeChanged ) and infopane:GetTall() != infopane.lasttall then
			-- parentpanel:OnSizeChanged()
		-- end
		-- infopane.lasttall = infopane:GetTall()
		-- infopane.descbox:SetSize( infopane.desc:GetWide() + 10, infopane.desc:GetTall() + 10 )
		-- if !IsValid( sbar ) then
			-- self:Remove()
			-- infopane.icon:Remove()
			-- return
		-- end
		-- self:SetTall( math.Clamp( 150 - sbar:GetScroll(), 0, 150 ) )
		-- self:AnimationThinkInternal()
	end

	return infopane
end

local expanded_cats = {
	[t_CAT.DESC] = false,
}

// panel must be able to contain the valuelist panel
function CreateValueEditorList( panel, prof, set, prs, parentpanel )
	if !cl_Profiles[prof] then return end
	local valuelist_cat_t = {}
	local valuelist_cat_selectors = {}

	local panpan = vgui.Create( "DScrollPanel", panel )
	panpan:SetVisible( false )
	panpan:Dock( FILL )
	panpan:SetWide( panel:GetWide() )
	local vpanel = vgui.Create( "DPanel", panpan )
	-- local vpanel = vgui.Create( "DCategoryList", panel )
	vpanel:Dock( FILL )
	vpanel:SetWide( panel:GetWide() )
	vpanel.parent = parentpanel
	parentpanel.vpanel = vpanel
	vpanel.container = panpan

	-- local fadein = PanelFadeIn( parentpanel, panpan, 0.1, 0.1, Color( 150, 154, 158 ) ) //#969A9E

	GetPendingTbl( prof, set, prs )
	UpdatePending()
	if !HasPreset( PendingView, prof, set, prs ) then 
		AddPresetPend( PendingView, prof, set, prs, {} )
	end

	vpanel.infopane = InfoPan( panpan, vpanel, prof, set, prs, parentpanel )
   vpanel.controlpane = ControlPane( panpan, vpanel, prof, set, prs, parentpanel )

	panpan:SetVisible( true )

	local tocat = {}
	local catkey = {}

	// categories to include
	for valueName, valueTbl in SortedPairs( t_lookup[ set ] ) do
		if valueTbl.TYPE == "data" then continue end
		local cat = ( valueTbl.REQUIRED or valueTbl.CATEGORY == t_CAT.REQUIRED ) and "*"..t_CAT.REQUIRED or valueTbl.CATEGORY or t_CAT.DEFAULT
		catkey[cat] = valueTbl.CATEGORY or valueTbl.REQUIRED and t_CAT.REQUIRED or t_CAT.DEFAULT
		if valuelist_cat_t[cat] == nil then
			tocat[cat] = true
		end
	end

	// category selectors
	local maxselectw = 0
	local c = 0
	for cat in SortedPairs( tocat ) do
		-- local header = vgui.Create( "Panel", panpan ) // fix for ScrollToChild
		-- header:SetVisible( false ) // breaks functionality
		-- header:SetColor( Color( 0, 0, 0, 0 ) )
		-- if c > 0 then
		-- 	header:SetSize( 0, marg )
		-- else
		-- 	header:SetSize( 0, 0 )
		-- end
		valuelist_cat_t[cat] = vgui.Create( "DForm", vpanel )
		valuelist_cat_t[cat]:SetWidth( vpanel:GetSize() )
		valuelist_cat_t[cat]:SetName( cat )
		valuelist_cat_t[cat]:Dock( TOP )
		valuelist_cat_t[cat].headheight = valuelist_cat_t[cat]:GetHeaderHeight()
      if cat == t_CAT.DESC or cat == t_CAT.REQUIRED then
         valuelist_cat_t[cat]:DockMargin( 2, 5, 2, 5 )
      else 
         valuelist_cat_t[cat]:DockMargin( 0, 0, 0, 0 )
         valuelist_cat_t[cat]:SetHeaderHeight( 0 )
      end
      valuelist_cat_t[cat].list = valuelist_cat_t

		if expanded_cats[catkey[cat]] != nil then
			valuelist_cat_t[cat]:SetExpanded( expanded_cats[catkey[cat]] )
		end
		-- header:SetPos( valuelist_cat_t[cat]:GetPos() )

		-- valuelist_cat_t[cat].OnToggle = function( self )
		-- 	timer.Simple( self:GetAnimTime(), function()
		-- 		parentpanel:OnSizeChanged()
		-- 	end )
		-- end

		valuelist_cat_t[cat].OnSizeChanged = function()
			parentpanel:OnSizeChanged()
		end

		valuelist_cat_t[cat].OnToggle = function( self, expand )
			expanded_cats[catkey[cat]] = expand
			-- print( catkey[cat] )
			-- print( expanded_cats[catkey[cat]] )
		end

		valuelist_cat_t[cat].Update = function()
			AddPresetPend( PendingAdd, prof, set, prs )
		end

		valuelist_cat_selectors[cat] = vgui.Create( "DButton" )
		valuelist_cat_selectors[cat]:SetText( cat )
		valuelist_cat_selectors[cat]:SetTextColor( Color( 255, 255, 255, 0 ) )
		-- valuelist_cat_selectors[cat]:SetHeight( UI_BUTTON_H )
		valuelist_cat_selectors[cat]:SizeToContentsX( 30 )
		-- valuelist_cat_selectors[cat]:SetZPos( 32767 ) // i don't know how to make it stay above the windows
		valuelist_cat_selectors[cat].c = c
		valuelist_cat_selectors[cat].header = valuelist_cat_t[cat]
		c=c+1

		maxselectw = math.max( maxselectw, valuelist_cat_selectors[cat]:GetWide() )

		local x, y = vpanel.parent:LocalToScreen()
		-- valuelist_cat_selectors[cat]:SetPos( x + parentpanel:GetWide() + UI_SELECTOR_X, UI_SELECTOR_Y + y + ( table.Count( valuelist_cat_selectors ) - 1 ) * ( valuelist_cat_selectors[cat]:GetTall() + 2 ) )
		valuelist_cat_selectors[cat]:SetPos( x + vpanel.parent:GetWide() + UI_SELECTOR_X, UI_SELECTOR_Y + y + valuelist_cat_selectors[cat].c * ( valuelist_cat_selectors[cat]:GetTall() + 2 ) )

		valuelist_cat_selectors[cat].Paint = function( self, w, h )
			if !IsValid( vpanel.parent ) then
				self:Remove()
				return
			end

			local x, y = vpanel.parent:LocalToScreen()
			
			// why does the panel delete itself when it goes off screen?
			if x + vpanel.parent:GetWide() + UI_SELECTOR_X + w < ScrW() + w * 0.5 or x < 0 then
				self:SetPos(
					math.Clamp( x + vpanel.parent:GetWide() + UI_SELECTOR_X, 1-w, ScrW()-1 ),
					math.Clamp( UI_SELECTOR_Y + y + self.c * ( h + 2 ), 1, ScrH()-1 )
				)
			else
				self:SetPos(
					math.Clamp( x - w - UI_SELECTOR_X, 1-w, ScrW()-1 ),
					math.Clamp( UI_SELECTOR_Y + y + self.c * ( h + 2 ), 1, ScrH()-1 )
				)
			end
			draw.RoundedBox( 4, 0, 0, w, h, Color( 200, 200, 200 ) )
			draw.RoundedBox( 4, 1, 1, w-2, h-2, Color( 124, 190, 255 ) )
			draw.TextShadow( {
				text = self:GetText(),
				pos = { w / 2, h / 2 },
				xalign = TEXT_ALIGN_CENTER,
				yalign = TEXT_ALIGN_CENTER,
				color = color_white,
			}, 1, 128 )
		end

		valuelist_cat_selectors[cat].OnReleased = function( self )
			-- panpan:ScrollToChild( header )
			if self.header then
				panpan:ScrollToChild( self.header )
			end
		end
	end

	vpanel:SetTall( table.Count( tocat ) * 27 )

	for _, p in pairs( valuelist_cat_selectors ) do
		p:SetWide( maxselectw )
	end

	// parent has the remove/hide/show functions
	parentpanel.selectors = valuelist_cat_selectors

	// add valuenames to categories
	local vn_req = {}
	local vn_other = {}
	for valueName, valueTbl in SortedPairs( t_lookup[set] ) do
		if valueTbl.TYPE == "data" then continue end
		local catstr = ( valueTbl.REQUIRED or valueTbl.CATEGORY == t_CAT.REQUIRED ) and "*"..t_CAT.REQUIRED or valueTbl.CATEGORY or t_CAT.DEFAULT
		if valueTbl.REQUIRED or valueTbl.CATEGORY == t_CAT.REQUIRED then
			vn_req[catstr] = vn_req[catstr] or {}
			vn_req[catstr][valueName] = valueTbl.SORTNAME or string.lower( valueTbl.NAME or valueName )
		else
			vn_other[catstr] = vn_other[catstr] or {}
			vn_other[catstr][valueName] = valueTbl.SORTNAME or string.lower( valueTbl.NAME or valueName )
		end
	end


	-- local cor = 0 // time delay
	-- local cor_iter = 0.3
 
	// create value panels
	for _, vtbl in ipairs( { vn_req, vn_other } ) do
		for cat, vcats in SortedPairs( vtbl ) do
			for valueName in SortedPairsByValue( vcats ) do
				local valueTbl = t_lookup[set][valueName]
				// add to queue
				table.insert( valuelist_queue,
					{
						parentpanel = parentpanel,
						panel = panel,
						vpanel = vpanel,
                  scrollpanel = panpan,

						cat = valuelist_cat_selectors[cat], // selector, not form

                  required = valueTbl.REQUIRED or valueTbl.CATEGORY == t_CAT.REQUIRED or valueTbl.CATEGORY == t_CAT.DESC,
                  hasdefault = valueTbl.DEFAULT != nil,
                  displayname = valueTbl.NAME or valueName,
                  category = cat,

						prof = prof,
						set = set,
						prs = prs,

						//AddValuePanel args
						fpanel = valuelist_cat_t[cat], // form panel
						structTbl = valueTbl,
						typ = nil,
						valueName = valueName,
						existingTbl = cl_Profiles[prof][set][prs],
						pendingTbl = PendingSettings[prof][set][prs],
						viewTbl = GetPrsTbl( PendingView, prof, set, prs ),
						lookupclass = set,
						hierarchy = { prof, set, prs }
					}
				)
			end
		end
	end	

	return vpanel
	-- return panpan
end

function UnstoreValuelist(prof, set, prs, valuename, all, nopan)
   local t = HasPreset(valuelist_storage, prof, set, prs)
   if t and t[valuename] != nil then
      if all then
         for vn, v in pairs(t) do
            v.forceshow = true
            table.insert( valuelist_queue, v )
         end
         return true
      else
         if !nopan then
            t[valuename].forcepan = true
         end
         t[valuename].forceshow = true
         table.insert( valuelist_queue, t[valuename])
         t[valuename] = nil
         return true
      end
   end
   return nil
end

function FillValueListRoutine()
	local valid
	local c = 0
	local done
	while true do
		coroutine.yield()
		if #valuelist_queue == 0 then continue end

		local rate = cl_cvar.valuelist_rate.v:GetInt()
      local showall = cl_cvar.valuelist_showall.v:GetBool()
		rate = math.max( 1, rate )

		for i=1,rate do
			done = nil
			c = 0
			while !done and !table.IsEmpty( valuelist_queue ) and c < 100 do
				c=c+1
				local k, q = next(valuelist_queue)
				if q then
					// a. remake value list
					if q.reset and IsValid( q.npanel ) then
						q.npanel.pendingTbl = q.pendingTbl
						q.npanel.existingTbl = q.existingTbl
						q.npanel.viewTbl = q.viewTbl
						q.npanel:ResetPanel( true, true ) // keep view, no request focus
						done = true
					else
						if cl_Profiles[q.prof]
						and IsValid( q.parentpanel ) and IsValid( q.panel ) and IsValid( q.vpanel )
						and HasPreset( PendingSettings, q.prof, q.set, q.prs ) then
                     local vl_all = GetPrsTbl(valuelist_all, q.prof, q.set, q.prs)
                     vl_all[q.valueName] = q
                     
                     if (!q.hasdefault or q.hasdefault and !showdefaults)
                     and !showall
                     and !q.required
                     and (!q.pendingTbl or q.pendingTbl[q.valueName] == nil)
                     and !q.forceshow then
                        GetPrsTbl(valuelist_storage, q.prof, q.set, q.prs)[q.valueName] = q
                     else
                        q.vpanel.values = q.vpanel.values or {} // aka ValueEditor[prof][set][prs].ValueList.values
                        q.fpanel.values = q.vpanel.values // parent dform

                        local newpanel = AddValuePanel(
                           q.fpanel,
                           q.structTbl,
                           q.typ,
                           q.valueName,
                           q.existingTbl,
                           q.pendingTbl,
                           q.viewTbl,
                           q.lookupclass,
                           q.hierarchy
                        )
                        q.vpanel.values[q.valueName] = newpanel
                        vl_all[q.valueName].selfpanel = newpanel

                        -- q.parentpanel:OnSizeChanged()

                        -- q.vpanel:InvalidateLayout()
                        -- q.vpanel:SizeToChildren( nil, true )
                        -- q.vpanel:SetTall( q.vpanel:GetTall() + 15 )
                        if q.cat and (q.cat.header == q.fpanel or q.cat.header == nil ) then
                           q.cat.header = newpanel
                           // reveal form panel
                           q.fpanel:DockMargin( 2, 5, 2, 5 )
                           q.fpanel:SetHeaderHeight(q.fpanel.headheight)
                        end
                        if q.forcepan and IsValid(q.scrollpanel) then
                           if q.fpanel and !q.fpanel:GetExpanded() then
                              q.fpanel:Toggle()
                           end
                           timer.Simple(engine.TickInterval()*4, function()
                              if IsValid(q.scrollpanel) and IsValid(newpanel) then
                                 q.scrollpanel:ScrollToChild(newpanel)
                              end
                           end )
                        end

                        done = true
                     end
						end
					end
				end
				table.remove( valuelist_queue, k )
			end
		end
	end
end

function GetOrCreateValueEditor( prof, set, prs, windowed )
	if prof and set and prs then
		if !HasPreset( ValueEditors, prof, set, prs ) then

			// move SettingsPane's ValueList panel to new tab
			if prof == active_prof and set == active_set and prs == active_prs and IsValid( ValueList ) then
				local panel = vgui.Create( "Panel" )
				ValueList.container:SetParent( panel )
				ValueList.container:Dock( FILL )
				ValueList.parent = panel // for selector Paint func (CreateValueEditorList)

				local sheet
				if windowed then
					local window = ValueWindow( prof .. " > " .. set .. " > " .. prs )
					panel:SetParent( window )
					panel:Dock( FILL )

					sheet = {}
					sheet.Panel = panel
					-- sheet.Panel.selectors = SettingsPane.selectors
					sheet.Panel.selectors = RightPanel.selectors
					sheet.Window = window
				else
					sheet = SettingsSheet:AddSheet( prof .. " > " .. set .. " > " .. prs, panel, nil, nil, nil, prof .. " > " .. set .. " > " .. prs )

					sheet.Tab.panel = panel // GetActiveTab()
					sheet.Tab.prof = prof
					sheet.Tab.set = set
					sheet.Tab.prs = prs
					sheet.Tab.Name = sheet.Name
					-- sheet.Tab.panel.selectors = SettingsPane.selectors
					sheet.Tab.panel.selectors = RightPanel.selectors
				end

				sheet.ValueList = ValueList

				-- SettingsPane.selectors = nil
				-- SettingsPane.HideSelectors = nil
				-- SettingsPane.RemoveSelectors = nil
				-- SettingsPane.ShowSelectors = nil
				RightPanel.selectors = nil
				RightPanel.HideSelectors = nil
				RightPanel.RemoveSelectors = nil
				RightPanel.ShowSelectors = nil
				ValueList = nil

				DeselectPresetsList()

				AddPresetPend( ValueEditors, prof, set, prs, sheet )
			
				sheet.Panel.OnRemove = function( self )
					RemovePresetPend( ValueEditors, prof, set, prs )
					self:RemoveSelectors()

					// if nothing changed, clear pendingsettings
					if !HasPreset( PendingAdd, prof, set, prs ) and HasPreset( PendingSettings, prof, set, prs ) then
						PendingSettings[prof][set][prs] = nil
						UpdatePending()
					end
				end

				sheet.Panel.HideSelectors = function( self )
					if self.selectors then
						for _, p in pairs( self.selectors ) do
							if IsValid( p ) then
								p:Hide()
							end
						end
					end
				end

				sheet.Panel.RemoveSelectors = function( self )
					if self.selectors then
						for _, p in pairs( self.selectors ) do
							if IsValid( p ) then
								p:Remove()
							end
						end
					end
					self.selectors = nil
				end

				sheet.Panel.ShowSelectors = function( self )
					if self.selectors then
						for _, p in pairs( self.selectors ) do
							if IsValid( p ) then
								p:Show()
							end
						end
					end
				end

			// otherwise create new editor
			else
				CreateValueEditor( prof, set, prs, nil, nil, windowed )
			end
			
			if ValueEditors[prof][set][prs].Tab then
				SettingsSheet:SwitchToName( ValueEditors[prof][set][prs].Name )
			end
			UpdatePresetSelection()
		else // existing editor
			if ValueEditors[prof][set][prs].Tab then
				if windowed then
					SettingsSheet:CloseTab( ValueEditors[prof][set][prs].Tab, true )
					timer.Simple( 0, function()
						GetOrCreateValueEditor( prof, set, prs, windowed )
					end )
				else
					SettingsSheet:SwitchToName( ValueEditors[prof][set][prs].Name )
				end
			end

			if ValueEditors[prof][set][prs].Window then
				if !windowed then
					ValueEditors[prof][set][prs].Window:Close()
					timer.Simple( 0, function()
						GetOrCreateValueEditor( prof, set, prs, windowed )
					end )
				else
					// ui dunno
				end
			end
		end
	end
end


function ClearValueEditors()
	for prof in pairs( ValueEditors ) do
		for set in pairs( ValueEditors[prof] ) do
			for prs in pairs( ValueEditors[prof][set] ) do
				CloseValueEditor( prof, set, prs )
			end
		end
	end
	ValueEditors = {}
	PendingView = {}
end

function HideValueEditors()
	for _, profsets in pairs( ValueEditors ) do
		for _, prss in pairs( profsets ) do
			for _, ve in pairs( prss ) do
				if IsValid( ve.Panel ) then
					ve.Panel:HideSelectors()
					-- ve:Hide()
				end
			end
		end
	end
end

function ShowValueEditors()
	for _, profsets in pairs( ValueEditors ) do
		for _, prss in pairs( profsets ) do
			for _, ve in pairs( prss ) do
				if IsValid( ve.Window ) then
					ve.Panel:ShowSelectors()
					-- ve:Show()
				end
			end
		end
	end
end

function CloseValueEditor( prof, set, prs )
	if HasPreset( ValueEditors, prof, set, prs ) then
		-- ValueEditors[prof][set][prs]:Close()
		if ValueEditors[prof][set][prs].Window then
			ValueEditors[prof][set][prs].Window:Close()
		end
		if ValueEditors[prof][set][prs].Tab then
			SettingsSheet:CloseTab( ValueEditors[prof][set][prs].Tab, true )
		end
		RemovePresetPend( PendingView, prof, set, prs )
		-- RemovePresetPend( ValueEditors, prof, set, prs ) // done in the panel remove function
	end
end

// all editors
function RemakeValueEditors()
	local cor = 0
	for prof, profsets in pairs( ValueEditors ) do
		for set, prss in pairs( profsets ) do
			for prs, ve in pairs( prss ) do
				if IsValid( ve.Panel ) then
					-- -- ve.ValueList:Clear()
					-- ve.ValueList:Remove()
					-- timer.Simple( engine.TickInterval() * cor, function()
					-- 	-- if IsValid( ve ) then
					-- 		ve.ValueList = CreateValueEditor( prof, set, prs, ve.Panel )
					-- 		ve.Panel:HideSelectors()
					-- 	-- end
					-- end )
					-- cor = cor + 1

					// problems: are there cases where npanel may still refer to the old pending table?

					if HasPreset( PendingSettings, prof, set, prs ) then
						PendingSettings[prof][set][prs] = nil
					end
					
					GetPendingTbl( prof, set, prs )
					if !HasPreset( PendingView, prof, set, prs ) then 
						AddPresetPend( PendingView, prof, set, prs, {} )
					end

					// reset value panel, intended for top-level values only
					for _, npanel in pairs( ve.ValueList.values ) do
						-- npanel:ResetPanel()
						table.insert( valuelist_queue, {
								reset = true,
								npanel = npanel,

								existingTbl = cl_Profiles[prof][set][prs],
								pendingTbl = PendingSettings[prof][set][prs],
								viewTbl = GetPrsTbl( PendingView, prof, set, prs ),
							}
						)
					end

				end
			end
		end
	end
	UpdatePending()
	-- RemakePendingList()
end

// single editor
-- function RemakeValueEditor( prof, set, prs )
-- 	local ve = HasPreset( ValueEditors, prof, set, prs )
-- 	if ve and IsValid( ve.Panel ) then
-- 		-- ve.ValueList:Clear()
-- 		ve.ValueList:Remove()
-- 		ve.ValueList = CreateValueEditor( prof, set, prs, ve.Panel )
-- 		ve.Panel:HideSelectors()
-- 	end
-- end

function UpdatePresetSelection( upd ) 
	if !IsValid(SettingsWindow) or !ispanel(SettingsWindow) then return end

	local newselect = active_prof and active_set and active_prs and !HasPreset( PendingSettings, active_prof, active_set, active_prs )

	// profile selection
	local _, settings_line = SettingsList:GetSelectedLine()
	if settings_line ~= nil then
		-- SetsList:SetEnabled( true )
		local settingsname = settings_line:GetValue(1)
		if newselect or active_prof != settingsname then
			newselect = true
			DeselectSetsList()
		end

		active_prof = settingsname
		if active_prof and cl_Profiles[active_prof] then
			// update sets lines			
			SetsList.lines = SetsList.lines or {}
			SetsList.data = SetsList.data or {}
			local setsorter = !cl_cvar.setsort.v:GetBool() and PROFILE_SETS_SORTED or PROFILE_SETS_SORTED_ABC
			for k, setkey in SortedPairs( setsorter ) do
				local setname = PROFILE_SETS[setkey]
				local pkeys = table.Count( GetSetsPresets( active_prof, setkey ) )
				local enabled_p = GetEnabledPresets( active_prof, setkey )
				local numenabled = 0
				for _, v in pairs( enabled_p ) do
					if v then 
						numenabled = numenabled + 1 
					end
				end
				local countstr = pkeys > 0 and pkeys != numenabled and numenabled .. "/" .. pkeys or numenabled
				if !SetsList.lines[setname] then
					SetsList.lines[setname] = SetsList:AddLine( setname, countstr )
					SetsList.data[setname] = setkey
				else
					SetsList.lines[setname]:SetColumnText( 2, countstr )
				end
			end
		else
			-- print("PROFILE NOT FOUND: ", active_prof )
			if SetsList.lines then
				for _, line in pairs( SetsList.lines ) do
					line:SetColumnText( 2, "" )
				end
			end
			DeselectSettingsList()
		end
	-- else
		-- SetsList:SetEnabled( false )
	end

	// set selection
	local _, sets_line = SetsList:GetSelectedLine()
	if sets_line ~= nil then
		PresetsList:SetEnabled( true )
		local setname = sets_line:GetValue( 1 )
		if newselect or active_set != SetsList.data[setname] then
			newselect = true
			DeselectPresetsList()
		end

		active_set = SetsList.data[setname]

		if active_prof and active_set and HasSet( cl_Profiles, active_prof, active_set ) then
			// create/remove presets lines
			local pkeys = GetSetsPresets( active_prof, active_set )
			local plist_toremove = table.Copy( PresetsList.list )

			PresetsHeader.txt:SetText( PROFILE_SETS[active_set] or "" )

			for prsname in SortedPairs( pkeys ) do
				local ve_status = HasPreset( ValueEditors, active_prof, active_set, prsname )
				if ve_status then
					if ve_status.Window then
						ve_status = "//"
					else
						ve_status = "%"
					end
				end

				if !PresetsList.list[prsname] then
					PresetsList.list[prsname] = PresetsList:AddLine( nil, prsname, ve_status or "" )
					PresetsList.list[prsname]:SetToolTip( prsname )

					// enable/disable checkbox
					local status
					if HasPreset( PendingSettings, active_prof, active_set, prsname ) then
						status = PendingSettings[active_prof][active_set][prsname]["npcd_enabled"]
					elseif HasPreset( cl_Profiles, active_prof, active_set, prsname ) then
						status = cl_Profiles[active_prof][active_set][prsname]["npcd_enabled"]
					end					
					if status == nil then status = true end

					PresetsList.boxes[prsname] = vgui.Create( "DCheckBox", PresetsList.list[prsname] )
					PresetsList.boxes[prsname]:SetPos( PresetsList.col_enabled:GetWide() / 8, 1 )
					PresetsList.boxes[prsname]:SetChecked( status )
					PresetsList.boxes[prsname].prof = active_prof
					PresetsList.boxes[prsname].set = active_set
					PresetsList.boxes[prsname].prs = prsname
					PresetsList.boxes[prsname].line = PresetsList.list[prsname]
					PresetsList.boxes[prsname].OnChange = function( self, val )
						if HasPreset( PendingSettings, self.prof, self.set, self.prs ) or HasPreset( cl_Profiles, self.prof, self.set, self.prs ) then
							GetPendingTbl( self.prof, self.set, self.prs )
							PendingSettings[ self.prof ][ self.set ][ self.prs ]["npcd_enabled"] = val
							AddPresetPend( PendingAdd, self.prof, self.set, self.prs )
						end
						UpdatePending()
						UpdatePresetSelection()
					end
				else
					PresetsList.list[prsname]:SetColumnText( 3, ve_status or "" )
					plist_toremove[prsname] = nil
				end
			end

			local todeselect
			for pn, line in pairs( plist_toremove ) do
				local k = line:GetID()

				if PresetsList:GetSelectedLine() == k then
					todeselect = true
				end
				PresetsList:RemoveLine( k )
				PresetsList.boxes[pn] = nil
				PresetsList.list[pn] = nil
			end

			if todeselect then
				DeselectPresetsList()
			end

			PresetsList:SortByColumn( 2 )

		else
			-- print("PROFILE/SET NOT FOUND: ", active_prof, active_set)
			DeselectSettingsList()
		end
	else
		PresetsList:SetEnabled( false )
	end

	// preset selection
	local _, prs_line = PresetsList:GetSelectedLine()
	if prs_line ~= nil then
		RightPanel:SetEnabled( true )
		local prsname = prs_line:GetValue( 2 )
		if newselect or active_prs != prsname then
			newselect = true
			-- print("newselect")
			DeselectValueList()
		end
		active_prs = prsname
		if newselect then
			if active_prof and active_set and active_prs then
				-- print( "active" )
				// create value editor in side panel or new window
				if HasPreset( ValueEditors, active_prof, active_set, active_prs ) then
					-- ValueEditors[active_prof][active_set][active_prs]:RequestFocus()
					-- SettingsSheet:SwitchToName( ValueEditors[active_prof][active_set][active_prs].Name )
				else
					-- ValueList = CreateValueEditor( active_prof, active_set, active_prs, RightPanel, SettingsPane )
					ValueList = CreateValueEditor( active_prof, active_set, active_prs, RightPanel, RightPanel )
				end
			else
				-- print( "noactive" )
				DeselectSettingsList()
			end
		-- else
		-- 	print("no select")
		end
	else
		RightPanel:SetEnabled( false )
	end

	// spawn button
	if CheckClientPerm( LocalPlayer(), cvar.perm_spawn.v:GetInt() ) and active_prof and active_prof == cl_currentProfile and active_set and SPAWN_SETS[active_set] and active_prs then
		PresetsButtons.spawn:SetEnabled( true )
	else
		PresetsButtons.spawn:SetEnabled( false )
	end

	UpdateWarning()

	UpdatePending()
end

function UpdateWarning()
	// check if profile can even do spawn routine
	local invalidprof = false
	local hasnpc
	-- local hassquad
	local haspool
	local hasspawns
	if active_prof then
		for _, setn in ipairs( { "npc", "entity", "nextbot" } ) do
			if !table.IsEmpty( GetSetsPresets( active_prof, setn ) ) then
				hasnpc = true
				break
			end
		end
		if !table.IsEmpty( GetSetsPresets( active_prof, "squad" ) ) then
			hasnpc = true
		end
		local spawnpools = GetSetsPresets( active_prof, "spawnpool" )
		if !table.IsEmpty( spawnpools ) then
			haspool = true
			for pool, pool_t in pairs( spawnpools ) do
				if pool_t.spawns and !table.IsEmpty( pool_t.spawns ) then
					hasspawns = true
					break
				end
			end
		end

		if !hasnpc or !haspool or !hasspawns then
			invalidprof = true
		end
	end

	if invalidprof then
		WarningBox:Show()
		local txt = "Missing Presets Needed For Auto-Spawning:"
		local lines = 1
		if !hasnpc then txt = txt.. "\n- Squad, NPC, Entity, or Nextbot needed" lines = lines + 1 end
		-- if !hassquad then txt = txt.. "\n-  needed" lines = lines + 1 end
		if !haspool then txt = txt.. "\n- Spawnpool needed" lines = lines + 1 end
		if haspool and !hasspawns then txt = txt.."\n- Spawnpool spawnlists are empty" lines = lines + 1 end
		WarningBox.text:SetText( txt )
		WarningBox:SetTall( 15 * lines + marg )
	else
		WarningBox:Hide()
	end
end

lastpends, lastremoves = nil

function UpdatePending()
	if !lastpends then
		RemakePendingList()
		lastpends = table.Copy( PendingSettings )
		lastremoves = table.Copy( PendingRemove )
		return
	end

	local updated
	local empty = true

	for pname, pend_prof in pairs( PendingSettings ) do
		for sname, pend_set in pairs( pend_prof ) do
			for prsname, pend_prs in pairs( pend_set ) do
				empty = false
				local act = "+"
				if HasPreset( cl_Profiles, pname, sname, prsname ) then
					act = "%"
				end
				if !HasPreset( PendingAdd, pname, sname, prsname ) then
					act = "?"
				end
				if HasPreset( lastpends, pname, sname, prsname ) != act then
					RemakePendingList()
					lastpends = table.Copy( PendingSettings )
					lastremoves = table.Copy( PendingRemove )
					return
				end
			end
		end
	end

	for pname, pend_prof in pairs( PendingRemove ) do
		for sname, pend_set in pairs( pend_prof ) do
			for prsname, pend_prs in pairs( pend_set ) do
				empty = false
				if HasPreset( lastremoves, pname, sname, prsname ) != pend_prs then
					RemakePendingList()
					lastpends = table.Copy( PendingSettings )
					lastremoves = table.Copy( PendingRemove )
					return
				end
			end
		end
	end
	
	if empty then
		RemakePendingList()
		lastpends = table.Copy( PendingSettings )
		lastremoves = table.Copy( PendingRemove )
		return
	end
end

function RemakePendingList()
	if !IsValid( PendingList ) then return end
	local count = 0
	PendingList:Clear()
	for pname, pend_prof in pairs( PendingSettings ) do
		for sname, pend_set in pairs( pend_prof ) do
			for prsname, pend_prs in pairs( pend_set ) do
				local act
				if !HasPreset( PendingAdd, pname, sname, prsname ) then
					act = "?"
				else
					if HasPreset( cl_Profiles, pname, sname, prsname ) then
						act = "%"
					else
						act = "+"
					end
					count = count + 1
				end
				
				local line = PendingList:AddLine( act, pname, sname, prsname )
				local a = act == "+" and "[new]" or "[edited]"
				line:SetToolTip( a .. " " .. pname .. " > " .. sname .. " > " .. prsname .. "\nRight-click for menu" )
			end
		end
	end

	for pname, pend_prof in pairs( PendingRemove ) do
		for sname, pend_set in pairs( pend_prof ) do
			for prsname, pend_prs in pairs( pend_set ) do
				if pend_prs then
					local line = PendingList:AddLine( "—", pname, sname, prsname )
					count = count + 1
					line:SetToolTip( "[remove]" .. " " .. pname .. " > " .. sname .. " > " .. prsname .. "\nRight-click for menu" )
				end
			end
		end
	end

	if count > 0 then
		CommitButton:SetText( "Submit Changes ("..count..")")
	else
		CommitButton:SetText( "Submit Changes")
	end
end

function GetPendingTbl( prof, set, prs, nocopy )
	if !prof or !set or !prs then return nil end
	PendingSettings[ prof ] = PendingSettings[ prof ] or {}
	PendingSettings[ prof ][ set ] = PendingSettings[ prof ][ set ] or {}
	-- PendingSettings[ prof ][ set ][ prs ] = PendingSettings[ prof ][ set ][ prs ] or {}

	// new pending settings should be a copy of existing table
	if !nocopy and !PendingSettings[ prof ][ set ][ prs ] then
		if HasPreset( cl_Profiles, prof, set, prs ) then
			PendingSettings[ prof ][ set ][ prs ] = table.Copy( cl_Profiles[ prof ][ set ][ prs ] )
		else
			PendingSettings[ prof ][ set ][ prs ] = {}
		end
	end

	return PendingSettings[ prof ][ set ][ prs ]
end

function GetPrsTbl( tbl, prof, set, prs )
	if !prof or !set or !prs then return nil end
	tbl[ prof ] = tbl[ prof ] or {}
	tbl[ prof ][ set ] = tbl[ prof ][ set ] or {}
	tbl[ prof ][ set ][ prs ] = tbl[ prof ][ set ][ prs ] or {}
	return tbl[ prof ][ set ][ prs ]
end

// VALUE PANEL STUFF

// the primary panel, includes the type-specific panel within it
function AddValuePanel( fpanel, structTbl, typ, valueName, existingTbl, pendingTbl, viewTbl, lookupclass, hierarchy, lastcol, lastvaluename, funcing, focus )
	if !fpanel or !valueName or !structTbl or !pendingTbl then
		ErrorNoHalt("\nError: npcd > AddValuePanel > something's missing:", fpanel," ",structTbl," ",valueName," ",existingTbl," ",pendingTbl,"\n\n")
		if fpanel and fpanel.structTbl then PrintTable( fpanel.structTbl ) end
		return
	end

	if !IsValid( fpanel ) then return end

	if structTbl.TYPE == "data" then
		-- print( "data" )
		return
	end

	local existingTbl = existingTbl or {}
	local npanel = vgui.Create( "DPanel", fpanel )
	
	local col = RandomColor( nil, nil, 0.6, 0.7, 0.9, 1 )
	local alph = 192
	if lastcol then
		-- npanel:SetBackgroundColor( Color( lastcol.r + col.r * 0.1 + 10, lastcol.g + col.g * 0.1 + 10, lastcol.b + col.b * 0.1 + 10, 128 ) )
		local h, s, v = ColorToHSV( lastcol )
		local hshift = math.Rand( 30, 180 ) * ( math.random( 0, 1 ) == 1 and 1 or -1 )
		local ncol = HSVToColor( ( h + hshift ) % 360, math.min( s * 1.05, 1 ) , math.min( v * 1.02, 1 ) )
		npanel:SetBackgroundColor( Color( ncol.r + 5, ncol.g + 5, ncol.b + 5, alph ) )
	else
		npanel:SetBackgroundColor( Color( 128 + col.r * 0.3, 128 + col.g * 0.3, 128 + col.b * 0.3, alph ) )
	end
	npanel.col = npanel:GetBackgroundColor()
	npanel.parent = fpanel 
	npanel.pendingTbl = pendingTbl
	npanel.existingTbl = existingTbl
	npanel.viewTbl = viewTbl
	
	npanel.structTbl = structTbl
	npanel.valueName = valueName
	
	npanel.hierarchy = hierarchy and table.Copy( hierarchy ) or {}
	table.insert( npanel.hierarchy, valueName )

	npanel.lookup = lookupclass
	if npanel.lookup == "all" then npanel.lookup = "entity" end

	if structTbl.TYPE == nil then
		structTbl.TYPE = t_basevalue_format["default"].TYPE
	end
	if structTbl.FUNCTION == nil then
		structTbl.FUNCTION = t_basevalue_format["default"].FUNCTION
	end

	// add default as enum
	-- if npanel.structTbl.DEFAULT then
	-- 	npanel.structTbl.ENUM = npanel.structTbl.ENUM or {}
	-- 	npanel.structTbl.ENUM.DEFAULT = npanel.structTbl.DEFAULT
	-- end

	// value type
	npanel.alltyps = typ or structTbl.TYPE
	if !istable( npanel.alltyps ) then
		npanel.alltyps = { npanel.alltyps }
	end

	// copy existing value, only the pendingTbl is to be edited
	// and set the type
	if npanel.existingTbl[npanel.valueName] != nil then		
		npanel.oldtyp = GetType( npanel.existingTbl[npanel.valueName], npanel.structTbl, npanel.alltyps )
	end

	if npanel.structTbl.DEFAULT != nil then
		npanel.deftyp = GetType( npanel.structTbl.DEFAULT, npanel.structTbl )
	end

	if npanel.pendingTbl[npanel.valueName] != nil then
		local ty, nomatch = GetType( npanel.pendingTbl[npanel.valueName], npanel.structTbl, npanel.alltyps )
		npanel.typ = ty
		if nomatch then
			npanel.pendingTbl[npanel.valueName] = nil
		end
	else
		npanel.typ = npanel.oldtyp or npanel.deftyp or npanel.alltyps[1]
	-- 	npanel.typ = GetType( npanel.structTbl.DEFAULT, npanel.structTbl, npanel.alltyps ) // either default type if it exists or first value of alltyps
	end

	// decoration

	npanel.wide = fpanel:GetWide() - (marg * 2)
	npanel:DockMargin( marg, marg / 2 , marg, marg / 2 )

	npanel.descpanel = vgui.Create( "Panel", npanel ) -- top
	-- npanel.descpanel:SetBackgroundColor( Color( 0, 0, 0, 0 ) )

	npanel.valuepanel = vgui.Create( "Panel", npanel ) -- mid
	-- npanel.valuepanel:SetBackgroundColor( Color( 0, 0, 0, 0 ) )

	npanel.descpanel.title = vgui.Create( "DLabel", npanel.descpanel )
	npanel.descpanel.title:DockMargin( marg, 0, marg, 0 )
	local titlestr = structTbl.NAME or valueName
	if lastvaluename then
		titlestr = lastvaluename .. " " .. titlestr
	end
	if structTbl.REQUIRED then
		titlestr = "*"..titlestr
	end
	npanel.descpanel.title:SetText( titlestr )

	npanel.descpanel.tooltip = titlestr

	npanel.descpanel.title:SetDark( true )
	npanel.descpanel.title:Dock( TOP )
	npanel.descpanel.title:SetHeight( UI_TEXT_H )
	npanel.descpanel.title:SetContentAlignment( 5 )

	if structTbl.DESC != nil then
		npanel.descpanel.desc = vgui.Create( "DLabel", npanel.descpanel )
		npanel.descpanel.desc:DockMargin( marg, 0, marg, 0 )
		-- npanel.descpanel.desc:SetAutoStretchVertical( true )
		-- npanel.descpanel.desc:SetWrap( true )
		npanel.descpanel.desc:Dock( TOP )
		npanel.descpanel.desc:SetText( structTbl.DESC )
		npanel.descpanel.desc:SetColor( Color( 0,0,0, 200 ) )
		npanel.descpanel.desc:SetContentAlignment( 8 )
		npanel.descpanel.desc:SetHeight( UI_TEXT_H * 2 )
	end

	if structTbl.DESC then
		npanel.descpanel.tooltip = npanel.descpanel.tooltip .. "\n" .. tostring( structTbl.DESC )
	end
	for k, v in SortedPairs( structTbl ) do
		if k == "DESC" or k == "NAME" or k == "SORTNAME" then
			continue
		end
		local str
		if istable( v ) then
			-- str = table.ToString( v )
			local first = true
			local c = 0
			str = ""
			for kk, vv in pairs( v ) do
				c = c + 1
				if c > 10 then
					str = tostring( v )
					break
				end
				if istable(vv) then
					str = tostring( v )
					break
				end
				if first then
					str = str..tostring( vv )
					first = false
				else
					str = str..", "..tostring( vv )
				end
			end
		else
			str = tostring( v )
		end
		npanel.descpanel.extratip = ( npanel.descpanel.extratip and npanel.descpanel.extratip.."\n" or "" ) .. k .. ": " .. str
	end

	npanel.descpanel.tippan = vgui.Create( "Panel", npanel.descpanel )
	npanel.descpanel.tippan:SetVisible( false )
	npanel.descpanel.tippan.Think = function( self )
		npanel.descpanel.tippan.text:SetWrap( true )
		if npanel.descpanel.tippan.extratext then npanel.descpanel.tippan.extratext:SetWrap( true ) end
		npanel.descpanel.tippan:SetSize( 312.5, npanel.descpanel.tippan.text:GetTall() + ( npanel.descpanel.tippan.extratext and npanel.descpanel.tippan.extratext:GetTall() or 0) )
	end
	-- npanel.descpanel.tippan:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	npanel.descpanel.tippan.text = vgui.Create( "DLabel", npanel.descpanel.tippan )
	npanel.descpanel.tippan.text:SetText( npanel.descpanel.tooltip )
	npanel.descpanel.tippan.text:SetDark( true )
	npanel.descpanel.tippan.text:Dock( TOP )
	npanel.descpanel.tippan.text:SetAutoStretchVertical( true )
	npanel.descpanel.tippan.text:SetWidth( 250 )
	if npanel.descpanel.extratip then
		npanel.descpanel.tippan.extratext = vgui.Create( "DLabel", npanel.descpanel.tippan )
		npanel.descpanel.tippan.extratext:SetText( npanel.descpanel.extratip )
		npanel.descpanel.tippan.extratext:SetColor( Color( 0, 0, 0, 172 ) )
		npanel.descpanel.tippan.extratext:Dock( TOP )
		npanel.descpanel.tippan.extratext:SetAutoStretchVertical( true )
		npanel.descpanel.tippan.extratext:SetWidth( 250 )
	end

	npanel.descpanel:SetContentAlignment( 5 )
	npanel.descpanel:SetTooltipPanel( npanel.descpanel.tippan )
	npanel.descpanel:SizeToChildren( false, true )

	npanel.optpanel = vgui.Create( "Panel", npanel )
	-- npanel.optpanel:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	npanel.optpanel:SetHeight( UI_ENTRY_H )
	-- npanel.optpanel:DockMargin( marg / 2 , 0, 0, 0 )

	npanel.b_clear = vgui.Create( "DButton", npanel.optpanel )
	npanel.b_clear:SetText( "Clear" )
	npanel.b_restore = vgui.Create( "DButton", npanel.optpanel )
	npanel.b_restore:SetText( "Restore" )
	if existingTbl[valueName] == nil then npanel.b_restore:SetEnabled( true ) end

	npanel.formaticonpan = vgui.Create( "Panel", npanel.optpanel )
	npanel.formaticonpan:SetToolTip( t_TYPE_TIP_DESC[npanel.typ] )
	-- npanel.formaticonpan:SetBackgroundColor( Color( 255, 255, 255, 128 ) )
	npanel.formaticon = vgui.Create( "DImage", npanel.formaticonpan )
	npanel.format = vgui.Create( "DComboBox", npanel.optpanel )

	if t_TYPE_ICON[npanel.typ] then npanel.formaticon:SetImage( t_TYPE_ICON[npanel.typ] ) end
	npanel.formaticonpan:SetSize( UI_ENTRY_H, UI_ENTRY_H )
	npanel.formaticonpan:DockMargin( 0, 0, 0, 0 )
	npanel.formaticon:SetSize( UI_ENTRY_H - UI_ICON_MARGIN*2, UI_ENTRY_H - UI_ICON_MARGIN*2 )
	-- npanel.formaticon:SetContentAlignment( 5 )
	npanel.formaticon:SetKeepAspect( true )
	-- npanel.formaticon:DockPadding( marg, 0, marg, 0 )
	npanel.formaticon:DockMargin( UI_ICON_MARGIN, UI_ICON_MARGIN+1, UI_ICON_MARGIN, UI_ICON_MARGIN-1 )
	-- npanel.formaticon:SetPos( UI_ICON_MARGIN, UI_ICON_MARGIN )
	npanel.formaticonpan:SetZPos( -3 )
	npanel.format:SetZPos( -2 )
	npanel.format:SetWidth( math.min( npanel.wide - UI_ENTRY_H - UI_ICON_MARGIN - npanel.b_clear:GetWide() - npanel.b_restore:GetWide(), UI_TEXT_H * 5 ) )

	npanel.format.count = 0

	npanel:Dock( TOP )
	npanel.descpanel:Dock( TOP )
	npanel.valuepanel:Dock( TOP )
	npanel.optpanel:Dock( TOP )
	npanel.b_clear:Dock( RIGHT )
	npanel.b_restore:Dock( RIGHT )
	npanel.formaticonpan:Dock( LEFT )
	npanel.formaticon:Dock( TOP )
	npanel.format:Dock( LEFT )

	if npanel.typ == "any" then
		npanel.alltyps = table.GetKeys( t_ANY_TYPES )
	end

	// format choices
	if npanel.typ == nil then
		print( valueName,"typ nil???", typ, npanel.typ, npanel.alltyps, structTbl.TBLSTRUCT, structTbl.TBLSTRUCT and structTbl.TBLSTRUCT.TYPE )
	else
		for _, t in ipairs( npanel.alltyps ) do
			npanel.format.count = npanel.format:AddChoice(
				t == "table" and t..( structTbl.TBLSTRUCT and " ("..
				( istable( structTbl.TBLSTRUCT.TYPE ) and table.concat( structTbl.TBLSTRUCT.TYPE, ", " ) or tostring( structTbl.TBLSTRUCT.TYPE ) ) ..")"
				or "" )
				or t == "struct_table" and "table (struct)"
				or t == "preset" and structTbl.PRESETS_ENTITYLIST and "entity"
				or t,
				t, t == npanel.typ or nil, t_TYPE_ICON[t] )
			-- npanel.format.count = npanel.format.count + 1
		end
	end

	local icontyps = {}

	if structTbl.ENUM != nil then
		if !HasType( structTbl.TYPE, "enum" ) then
			npanel.format.count = npanel.format:AddChoice( "enum", "enum", nil, t_TYPE_ICON["enum"] )
		end
		icontyps["enum"] = true		
	end

	// has enums and more than just DEFAULT
	-- if structTbl.ENUM then --and ( structTbl.ENUM.DEFAULT == nil or structTbl.ENUM.DEFAULT != nil and table.Count( structTbl.ENUM ) > 1 ) then
	-- 	icontyps["enum"] = true	
	-- end

	if !funcing and !HasType( structTbl.TYPE, "function" ) and not ( structTbl.NOFUNC or npanel.typ == "any" or ( typ and ( npanel.typ == "table" or npanel.structTbl.TYPE == "table" ) ) ) then
		npanel.format.count = npanel.format:AddChoice( "function", "function", npanel.typ == "function", t_TYPE_ICON["function"] )
	end

	npanel.descpanel.iconpan = vgui.Create( "Panel", npanel.descpanel )
	npanel.descpanel.iconpan:SetHeight( UI_ENTRY_H )
	npanel.descpanel.iconpan:SetWidth( npanel.descpanel:GetWide() )
	-- npanel.descpanel.iconpan:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	-- npanel.descpanel.iconpan:SetPos( 0, 0 )	
	npanel.descpanel.iconpan.icons = {}

	local iconw = UI_ENTRY_H - UI_ICON_MARGIN*2
	-- for k, t in ipairs( npanel.alltyps ) do
		-- if k == 1 then continue end
		-- icontyps[t] = true
	-- end
	-- table.Reverse( icontyps )
	for t in pairs( icontyps ) do
		if !t_TYPE_ICON[t] then continue end
		local icon = vgui.Create( "DPanel", npanel.descpanel.iconpan )
		local img = vgui.Create( "DImage", icon )
		icon:SetBackgroundColor( Color( 255, 255, 255, 64 ) )
		icon:SetSize( UI_ENTRY_H, UI_ENTRY_H )
		icon:SetContentAlignment( 5 )
		icon:Dock( RIGHT )
		table.insert( npanel.descpanel.iconpan.icons, icon ) 
		img:SetSize( iconw, iconw )
		img:Dock( TOP )
		img:DockMargin( UI_ICON_MARGIN, UI_ICON_MARGIN, UI_ICON_MARGIN, UI_ICON_MARGIN )
		img:SetImage( t_TYPE_ICON[t] )
		icon:SetToolTip( t_TYPE_TIP[t] )
	end

	npanel.ClearView = function()
		npanel.viewTbl[npanel.valueName] = nil
	end

	npanel.format.lastselect = npanel.typ

	npanel.format.OnSelect = function( panel, index, text, data )
		if npanel.format.lastselect == nil or npanel.format.lastselect != data then
		
			// value conversion
			local clear = false
			if npanel.pendingTbl[npanel.valueName] != nil then
				if npanel.typ == "enum" and data != "enum" and npanel.structTbl.ENUM
				and npanel.structTbl.ENUM[ npanel.pendingTbl[npanel.valueName] ] != nil then
					-- if istable( npanel.structTbl.ENUM[ npanel.pendingTbl[npanel.valueName] ] ) then
					-- 	npanel.pendingTbl[npanel.valueName] = table.Copy( npanel.structTbl.ENUM[ npanel.pendingTbl[npanel.valueName] ] )
					-- else
					-- 	npanel.pendingTbl[npanel.valueName] = npanel.structTbl.ENUM[ npanel.pendingTbl[npanel.valueName] ]
					-- end
					CopyKeyedData( npanel.pendingTbl, npanel.valueName, npanel.structTbl.ENUM, npanel.pendingTbl[npanel.valueName] )
				elseif !istable( npanel.pendingTbl[npanel.valueName] ) then
					if data == "string" then
						npanel.pendingTbl[npanel.valueName] = tostring( npanel.pendingTbl[npanel.valueName] )
					elseif data == "number" then
						npanel.pendingTbl[npanel.valueName] = tonumber( npanel.pendingTbl[npanel.valueName] )
					elseif npanel.typ == "number" and data == "fraction" then
						// number to fraction
						local val = npanel.pendingTbl[npanel.valueName]
						npanel.pendingTbl[npanel.valueName] = {}
						npanel.pendingTbl[npanel.valueName]["f"] = val
					-- elseif npanel.typ == "vector" and data == "angle" then
					-- 	local newang = Angle()
					-- 	newang.x = npanel.typ.x
					-- 	newang.y = npanel.typ.y
					-- 	newang.z = npanel.typ.z
					-- 	npanel.pendingTbl[npanel.valueName] = newang
					-- 	-- npanel.pendingTbl[npanel.valueName] = nil
					-- elseif npanel.typ == "angle" and data == "vector" then
					-- 	local newvector = Vector()
					-- 	newang.x = npanel.typ.x
					-- 	newang.y = npanel.typ.y
					-- 	newang.z = npanel.typ.z
					-- 	npanel.pendingTbl[npanel.valueName] = newvector
					elseif data == "enum" and npanel.structTbl.ENUM then
						local k = table.KeyFromValue( npanel.structTbl.ENUM, npanel.pendingTbl[npanel.valueName] )
						if k != nil then
							npanel.pendingTbl[npanel.valueName] = k
						else
							npanel.pendingTbl[npanel.valueName] = nil
							clear = true
						end
					else
						// wouldn't really make sense for other data types
						npanel.pendingTbl[npanel.valueName] = nil
						clear = true
					end
				else // is table
					// is function table
					if t_FUNCS[ npanel.pendingTbl[npanel.valueName][1] ] then
						npanel.pendingTbl[npanel.valueName] = nil
						clear = true
					// is table with normal data
					elseif npanel.typ == "preset" and data == "string" and npanel.pendingTbl[npanel.valueName]["name"] then
						npanel.pendingTbl[npanel.valueName] = npanel.pendingTbl[npanel.valueName]["name"]
					elseif GetType( npanel.pendingTbl[npanel.valueName][1], npanel.structTbl, npanel.alltyps ) == data then
						npanel.pendingTbl[npanel.valueName] = npanel.pendingTbl[npanel.valueName][1]
					// fraction to number
					elseif npanel.typ == "fraction" and data == "number" and npanel.pendingTbl[npanel.valueName]["f"] then
						npanel.pendingTbl[npanel.valueName] = npanel.pendingTbl[npanel.valueName]["f"]
					else 
						npanel.pendingTbl[npanel.valueName] = nil
						clear = true
					end
				end
			else
				clear = true
			end

			if clear and npanel.valuepanel.valuer.DoClear then
				npanel.valuepanel.valuer:DoClear()
			end

			npanel.typ = data
			npanel.format.lastselect = data

			npanel:ResetPanel()
			
			npanel:Update()
		end
	end

	// button functions
	npanel.b_clear.OnReleased = function()
		if npanel.valuepanel.valuer.DoClear then
			npanel.valuepanel.valuer.DoClear()
		end

		npanel.pendingTbl[npanel.valueName] = nil

		if npanel.pendingTbl["LOOKUP_REROLL"] then
			npanel.pendingTbl["LOOKUP_REROLL"][npanel.valueName] = nil
		end
		
		if npanel.deftyp then npanel.typ = npanel.deftyp end

		npanel:ResetPanel()

		npanel:Update()
	end

	npanel.b_restore.OnReleased = function()
		if npanel.valuepanel.valuer.DoClear then
			npanel.valuepanel.valuer.DoClear()
		end

		-- if istable( npanel.existingTbl[npanel.valueName] ) then
		-- 	npanel.pendingTbl[npanel.valueName] = table.Copy( npanel.existingTbl[npanel.valueName] )
		-- else
		-- 	npanel.pendingTbl[npanel.valueName] = npanel.existingTbl[npanel.valueName]
		-- end
		CopyKeyedData( npanel.pendingTbl, npanel.valueName, npanel.existingTbl, npanel.valueName )

		if npanel.existingTbl["LOOKUP_REROLL"] and npanel.existingTbl["LOOKUP_REROLL"][npanel.valueName] != nil then
			npanel.pendingTbl["LOOKUP_REROLL"] = npanel.pendingTbl["LOOKUP_REROLL"] or {}
			npanel.pendingTbl["LOOKUP_REROLL"][npanel.valueName] = npanel.existingTbl["LOOKUP_REROLL"][npanel.valueName]
		elseif npanel.pendingTbl["LOOKUP_REROLL"] then
			npanel.pendingTbl["LOOKUP_REROLL"][npanel.valueName] = nil
		end

		if npanel.oldtyp then npanel.typ = npanel.oldtyp end

		npanel:ResetPanel()

		npanel:Update()
	end

	// panel functions

	npanel.ResetPanel = function( self, keepview, nofocus )
		if !keepview then
			npanel:ClearView()
		end

		if npanel.valuepanel.valuer then 
			if npanel.valuepanel.valuer.DoClose then
				npanel.valuepanel.valuer.DoClose()
			end
			npanel.valuepanel.valuer:Remove()
			AddTypedPanel( npanel, nil, !nofocus )
			if t_TYPE_ICON[npanel.typ] then
				npanel.formaticon:SetImage( t_TYPE_ICON[npanel.typ] )
			end
		end

		if npanel.typ != "function" and npanel.pendingTbl["LOOKUP_REROLL"] and npanel.pendingTbl["LOOKUP_REROLL"][npanel.valueName] != nil then
			npanel.pendingTbl["LOOKUP_REROLL"][npanel.valueName] = nil
			if table.IsEmpty( npanel.pendingTbl["LOOKUP_REROLL"] ) then
				npanel.pendingTbl["LOOKUP_REROLL"] = nil
			end
		end


		for i=1,npanel.format.count do
			if npanel.format:GetOptionData( i ) == npanel.typ then
				npanel.format.lastselect = npanel.typ
				npanel.format:ChooseOptionID( i )
			end
		end

		npanel.valuepanel:SizeToChildren( false, true )
		npanel:InvalidateLayout( true )
		npanel:SizeToChildren( false, true )
	end

	-- npanel.Clean = function()
	-- 	npanel.pendingTbl[npanel.valueName] = nil
	-- 	npanel:Remove()
	-- end

	npanel.CheckValue = function()
		-- print( npanel.valueName, npanel.pendingTbl, npanel.existingTbl )
		-- print( npanel.valueName, npanel.pendingTbl[npanel.valueName], npanel.existingTbl[npanel.valueName] )
		if npanel.pendingTbl[npanel.valueName] == nil then
			npanel:SetActivated( false )
			npanel.b_clear:SetEnabled( false )
		else
			npanel:SetActivated( true )
			npanel.b_clear:SetEnabled( true )
		end

		if npanel.existingTbl[npanel.valueName] != nil and npanel.existingTbl[npanel.valueName] != npanel.pendingTbl[npanel.valueName] then
			npanel.b_restore:SetEnabled( true )
		else
			npanel.b_restore:SetEnabled( false )
		end
	end

	npanel.Update = function( panel )
		npanel:CheckValue()

		// propogate upward
		if isfunction( npanel.parent.Update ) then npanel.parent:Update() end

		npanel.updated = true

		UpdatePending()
		if npanel.valueName == "spawns" then UpdateWarning() end
	end

	npanel.SetActivated = function( panel, active )
		if active == nil then return end
		
		if npanel.active != active then
			if active then
				npanel:SetBackgroundColor( npanel.col )
			else
				local p = 0.05
				npanel:SetBackgroundColor( Color( COL_UNCHANGED + npanel.col.r * p, COL_UNCHANGED + npanel.col.g * p, COL_UNCHANGED + npanel.col.b * p, alph ) )
			end
		end
		npanel.active = active
	end

	if funcing then npanel.b_restore:Hide() end // restore seems to bring out the wrong values when funcing (but only when it's the level directly below it)
	
	// create the actual value panel
	AddTypedPanel( npanel, nil, focus )

	if npanel.structTbl.PENDING_SAVE and npanel.pendingTbl[npanel.valueName] == nil and isfunction( npanel.valuepanel.valuer.InitPend ) then
		npanel.valuepanel.valuer:InitPend()
	end

	npanel.valuepanel:InvalidateLayout( true )
	npanel.valuepanel:SizeToChildren( false, true )

	npanel:InvalidateLayout( true )
	npanel:SizeToChildren( false, true )

	npanel:CheckValue()

	if npanel.pendingTbl[npanel.valueName] == npanel.structTbl.DEFAULT then
		npanel:SetActivated( false )
	end

	npanel.OnSizeChanged = function( panel, w, h )
		npanel.format:SetWidth( math.min( npanel:GetWide() - UI_ENTRY_H - npanel.b_clear:GetWide() - npanel.b_restore:GetWide(), UI_TEXT_H * 5 ) )
		npanel.descpanel.iconpan:SetWidth( w )
		npanel.wide = w

		// fpanel
		npanel.parent:InvalidateLayout( true )
		npanel.parent:SizeToChildren( false, true )
		-- if npanel.valuepanel.OnSizeChanged then npanel.valuepanel:OnSizeChanged() end
	end

	return npanel
end

function AddStructPanel( npanel, inspanel, focus, tblk, forced )

	inspanel.valuer = vgui.Create( "Panel", inspanel )
	-- inspanel.valuer:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	inspanel.valuer:Dock( TOP )

	inspanel.valuer:SetWidth( npanel.wide )

	inspanel.valuer.OnSizeChanged = function( panel, w, h )
		inspanel:InvalidateLayout( true )
		inspanel:SizeToChildren( false, true )
		npanel:InvalidateLayout( true )
		npanel:SizeToChildren( false, true )
	end	

	// some of these will need a specific close function
	inspanel.valuer.DoClose = function()
		inspanel.valuer.CloseEditor()
	end

	inspanel.valuer.CloseEditor = function()
		if inspanel.valuer.container == nil then return end

		inspanel.valuer.container:Remove()
		inspanel.valuer.container = nil
		
		inspanel:InvalidateLayout( true )
		inspanel:SizeToChildren( false, true )
		npanel:InvalidateLayout( true )
		npanel:SizeToChildren( false, true )
		
		inspanel.valuer.edit:SetToggle( inspanel.valuer.container == nil )
	end

	inspanel.valuer.Concatenate = function()
		// concat string
		if inspanel.valuer.concat then --and npanel.pendingTbl[npanel.valueName] != nil then
			if npanel.pendingTbl[npanel.valueName] != nil and istable( npanel.pendingTbl[npanel.valueName] ) and !table.IsEmpty( npanel.pendingTbl[npanel.valueName] ) then
				local str = string.sub( table.ToString( npanel.pendingTbl[npanel.valueName] ), 2, -3 )
				inspanel.valuer.concat:SetText( str )
				inspanel.valuer.concatpan:SetToolTip( str )
			// default, not a function
			elseif npanel.structTbl.DEFAULT != nil and istable( npanel.structTbl.DEFAULT ) then
			-- and not ( npanel.structTbl.DEFAULT[1] != nil and t_FUNCS[npanel.structTbl.DEFAULT[1]] ) then
				local str = "<DEFAULT> " .. string.sub( table.ToString( npanel.structTbl.DEFAULT ), 2, -3 )
				inspanel.valuer.concat:SetText( str )
				inspanel.valuer.concatpan:SetToolTip( str )
			else
				inspanel.valuer.concat:SetText("")
			end
		end
	end

	inspanel.valuer.CreateEditor = function()
		-- inspanel.valuer.container = vgui.Create( "DCategoryList", inspanel )	
		inspanel.valuer.container = vgui.Create( "Panel", inspanel )	
		-- inspanel.valuer.container:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
		inspanel.valuer.container:SetWidth( npanel:GetWide() )
		inspanel.valuer.container:Dock( TOP )
		-- inspanel.valuer.container:DockMargin( marg, 0, marg, 0 )
		inspanel.valuer:SizeToChildren( false, true )
		inspanel.valuer:InvalidateLayout( true )
		
		inspanel.valuer.container.OnSizeChanged = function( panel, w, h )
			inspanel:InvalidateLayout( true )
			inspanel:SizeToChildren( false, true )
			npanel:InvalidateLayout( true )
			npanel:SizeToChildren( false, true )
		end

		if !istable( npanel.pendingTbl[npanel.valueName] ) then
			npanel.pendingTbl[npanel.valueName] = {}
			npanel:Update()
		end

		npanel.viewTbl[npanel.valueName] = npanel.viewTbl[npanel.valueName] or {}

		if tblk != nil then
			if !istable( npanel.pendingTbl[npanel.valueName][tblk] ) then
				npanel.pendingTbl[npanel.valueName][tblk] = {}
				npanel:Update()
			end
			npanel.viewTbl[npanel.valueName][tblk] = npanel.viewTbl[npanel.valueName][tblk] or {}
		end

		// struct value names, sorted by req/notreq and sortname/name
		local newstruct_req = {}
		local newstruct_other = {}
		-- local tocat = {}
		-- inspanel.valuer.container.cats = {}
		for sn, stbl in pairs( npanel.structTbl.STRUCT ) do
			if stbl.TYPE == "data" or stbl.TYPE == "info" then continue end

			-- if stbl.CATEGORY then tocat[stbl.CATEGORY] = true end
			if stbl.REQUIRED or stbl.CATEGORY == t_CAT.REQUIRED then
				newstruct_req[sn] = ( stbl.SORTNAME
				or stbl.REQUIRED and "*"..( stbl.CATEGORY != t_CAT.DEFAULT and stbl.CATEGORY or "zzz" )
				or stbl.CATEGORY and stbl.CATEGORY != t_CAT.DEFAULT and stbl.CATEGORY
				or "zzz" )
				.. string.lower( stbl.NAME or sn )
			else
				newstruct_other[sn] = ( stbl.SORTNAME or stbl.CATEGORY and stbl.CATEGORY != t_CAT.DEFAULT and stbl.CATEGORY or "zzz" ) .. string.lower( stbl.NAME or sn )
			end
		end

		-- if tocat[t_CAT.REQUIRED] then
		-- 	inspanel.valuer.container.cats[t_CAT.REQUIRED] = vgui.Create( "DForm", inspanel.valuer.container )
		-- 	inspanel.valuer.container.cats[t_CAT.REQUIRED]:SetName( t_CAT.REQUIRED )
		-- 	inspanel.valuer.container.cats[t_CAT.REQUIRED]:SetAnimTime( 0 )

		-- 	inspanel.valuer.container.cats[t_CAT.REQUIRED].OnToggle = function( self, expanded )
		-- 		npanel.viewTbl[npanel.valueName].__FORMS = npanel.viewTbl[npanel.valueName].__FORMS or {}
		-- 		npanel.viewTbl[npanel.valueName].__FORMS[t_CAT.REQUIRED] = expanded
		-- 		timer.Simple(0, function() if IsValid(npanel) then npanel:OnSizeChanged() end end )
		-- 	end

		-- 	if npanel.viewTbl[npanel.valueName].__FORMS and npanel.viewTbl[npanel.valueName].__FORMS[t_CAT.REQUIRED] != nil then
		-- 		inspanel.valuer.container.cats[t_CAT.REQUIRED]:SetExpanded( npanel.viewTbl[npanel.valueName].__FORMS[t_CAT.REQUIRED] )
		-- 	end
		-- 	tocat[t_CAT.REQUIRED] = nil
		-- end

		-- for cat in SortedPairs( tocat ) do
		-- 	inspanel.valuer.container.cats[cat] = vgui.Create( "DForm", inspanel.valuer.container )
		-- 	inspanel.valuer.container.cats[cat]:SetName( cat )
		-- 	inspanel.valuer.container.cats[cat]:SetAnimTime( 0 )

		-- 	inspanel.valuer.container.cats[cat].OnToggle = function( self, expanded )
		-- 		npanel.viewTbl[npanel.valueName].__FORMS = npanel.viewTbl[npanel.valueName].__FORMS or {}
		-- 		npanel.viewTbl[npanel.valueName].__FORMS[cat] = expanded
		-- 		timer.Simple(0, function() if IsValid(npanel) then npanel:OnSizeChanged() end end )
		-- 	end

		-- 	if npanel.viewTbl[npanel.valueName].__FORMS and npanel.viewTbl[npanel.valueName].__FORMS[cat] != nil then
		-- 		inspanel.valuer.container.cats[cat]:SetExpanded( npanel.viewTbl[npanel.valueName].__FORMS[cat] )
		-- 	end
		-- end

		local existing, pending, view, lookup
		local hierarchy = npanel.hierarchy

		// tblk is for struct tables
		if tblk then
			if !table.IsEmpty( npanel.pendingTbl[npanel.valueName][tblk] ) then
				if npanel.existingTbl != nil and npanel.existingTbl[npanel.valueName] != nil then
					existing = npanel.existingTbl[npanel.valueName][tblk]
				end
			end
			pending = npanel.pendingTbl[npanel.valueName][tblk]
			view = npanel.viewTbl[npanel.valueName][tblk]
			hierarchy = table.Copy( hierarchy )
			table.insert( hierarchy, tblk )
		else
			if !table.IsEmpty( npanel.pendingTbl[npanel.valueName] ) then
				if npanel.existingTbl != nil and npanel.existingTbl[npanel.valueName] != nil then
					existing = npanel.existingTbl[npanel.valueName]
				end
			end
			pending = npanel.pendingTbl[npanel.valueName]
			view = npanel.viewTbl[npanel.valueName]
		end
		// allows editing class structs in overrides
		if lookup_to_valuename[npanel.valueName] then
			lookup = npanel.valueName
		else
			lookup = npanel.lookup
		end

		inspanel.valuer.container.structTbl = npanel.structTbl // for functionpanel lookup_reroll
		
		inspanel.valuer.container.values = {}
		for _, structlist in ipairs( { newstruct_req, newstruct_other } ) do
			for sn, ssn in SortedPairsByValue( structlist ) do
				local stbl = npanel.structTbl.STRUCT[sn]
				-- local newpanel = 
				inspanel.valuer.container.values[sn] = AddValuePanel(
					inspanel.valuer.container,
					stbl, 
					nil,
					sn, 
					existing,
					pending,
					view,
					lookup,
					hierarchy,
					npanel.col,
					"<" .. CutLeftString(npanel.structTbl.NAME or npanel.valueName, UI_STR_LEFT_LIM) .. ">" .. ( stbl.CATEGORY and stbl.CATEGORY != t_CAT.DEFAULT and " <" .. CutLeftString(stbl.CATEGORY, UI_STR_LEFT_LIM) .. ">" or "" )
				)

				-- if newpanel and stbl.CATEGORY and inspanel.valuer.container.cats[stbl.CATEGORY] then
				-- 	newpanel:SetParent( inspanel.valuer.container.cats[stbl.CATEGORY] )
				-- end

				// queue alt method
				-- table.insert( valuelist_queue, {
				-- 		simple = true,
				-- 		moveparent = stbl.CATEGORY and inspanel.valuer.container.cats[stbl.CATEGORY],
				-- 		fpanel = inspanel.valuer.container,
				-- 		structTbl = stbl, 
				-- 		-- typ = nil,
				-- 		valueName = sn, 
				-- 		existingTbl = existing,
				-- 		pendingTbl = pending,
				-- 		viewTbl = view,
				-- 		lookupclass = lookup,
				-- 		hierarchy = hierarchy,
				-- 		lastcol = npanel.col,
				-- 		lastvaluename = "<" .. ( npanel.structTbl.NAME or npanel.valueName ) .. ">" .. ( stbl.CATEGORY and stbl.CATEGORY != t_CAT.DEFAULT and " <" .. stbl.CATEGORY .. ">" or "" )
				-- 	}
				-- )
			end
		end
		npanel.values = inspanel.valuer.container.values

		inspanel.valuer.container.ChangeEditor = function( self, newk )
			if isfunction( inspanel.ChangeEditor ) then
				inspanel:ChangeEditor( newk )
			end
		end

		inspanel.valuer.container.Update = function()
			if isfunction( inspanel.Update ) then inspanel:Update() end

			inspanel.valuer:Concatenate()

			npanel:Update()
		end

		inspanel:InvalidateLayout( true )
		inspanel:SizeToChildren( false, true )
	end

	if forced then // struct tables (AddTablePanel)
		inspanel.valuer.CreateEditor()
	else
		inspanel.valuer:DockMargin( marg, 0, marg, 0)
		inspanel.valuer.toggle = vgui.Create( "DCheckBoxLabel", inspanel.valuer )
		inspanel.valuer.toggle:SetText( "Included" )
		inspanel.valuer.toggle:SetDark( true )
		inspanel.valuer.toggle.OnChange = function( panel, val )
			if val and npanel.pendingTbl[npanel.valueName] == nil then
				inspanel.valuer.CreateEditor()
				inspanel.valuer.edit:SetToggle( inspanel.valuer.container == nil )
			end
			inspanel.valuer.toggle:SetChecked( npanel.pendingTbl[npanel.valueName] != nil )
		end
		inspanel.valuer.toggle:Dock( RIGHT )
		inspanel.valuer.edit = vgui.Create( "DButton", inspanel.valuer )	
		inspanel.valuer.edit:SetIcon( UI_ICONS.edit )
		inspanel.valuer.edit:SetText("")
		inspanel.valuer.edit:SetSize( UI_BUTTON_W, UI_BUTTON_H )
		inspanel.valuer.edit:SetIsToggle( true )
		inspanel.valuer.edit:Dock( LEFT )

		inspanel.valuer.edit.OnReleased = function()
			if inspanel.valuer.container == nil then
				inspanel.valuer.CreateEditor()
				inspanel.valuer.toggle:SetChecked( true )
			else
				npanel:ClearView()
				inspanel.valuer.CloseEditor()
			end
		end

		// concat
		inspanel.valuer.concatpan = vgui.Create( "Panel", inspanel.valuer )
		inspanel.valuer.concat = vgui.Create( "DLabel", inspanel.valuer.concatpan )	
		inspanel.valuer.concatpan:SetWidth( npanel:GetWide() )
		inspanel.valuer.concatpan:Dock( TOP )
		-- inspanel.valuer.concatpan:SetBackgroundColor( Color( 0,0,0,0 ) )
		inspanel.valuer.concat:Dock( FILL )
		inspanel.valuer.concat:SetText( "" )
		inspanel.valuer.concat:SetDark( true )
		inspanel.valuer.concat:DockMargin( marg, 0, marg, 0 )
		inspanel.valuer.concatpan:SetHeight( UI_ENTRY_H )

		inspanel.valuer:Concatenate()

		if npanel.pendingTbl[npanel.valueName] != nil then
			inspanel.valuer.toggle:SetChecked( true )
		end

		if npanel.viewTbl[npanel.valueName] then
			inspanel.valuer.CreateEditor()
		end
	end
end

function AddTablePanel( npanel, inspanel )

	inspanel.valuer = vgui.Create( "Panel", inspanel )
	-- inspanel.valuer:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	inspanel.valuer:Dock( TOP )

	inspanel.valuer.tbl = vgui.Create( "DListView", inspanel.valuer )
	inspanel.valuer.tbl:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	inspanel.valuer.tbl:SetMultiSelect( true )

	// BUTTONS
	inspanel.valuer.btns = vgui.Create( "Panel", inspanel.valuer )
	-- inspanel.valuer.btns:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	inspanel.valuer.btns:SetHeight( UI_BUTTON_H )

	inspanel.valuer.btns.edit = vgui.Create( "DButton", inspanel.valuer.btns )	
	inspanel.valuer.btns.edit:SetIcon( UI_ICONS.edit )
	inspanel.valuer.btns.edit:SetText("")
	inspanel.valuer.btns.edit:SetTooltip("Edit [double-click]")
	inspanel.valuer.btns.edit:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )
	inspanel.valuer.btns.edit:SetIsToggle( true )

	inspanel.valuer.btns.add = vgui.Create( "DButton", inspanel.valuer.btns )
	inspanel.valuer.btns.add:SetIcon( UI_ICONS.add )
	inspanel.valuer.btns.add:SetText("")
	inspanel.valuer.btns.add:SetTooltip("Add")
	inspanel.valuer.btns.add:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )	

	inspanel.valuer.btns.copy = vgui.Create( "DButton", inspanel.valuer.btns )
	inspanel.valuer.btns.copy:SetIcon( UI_ICONS.copy )
	inspanel.valuer.btns.copy:SetText("")
	inspanel.valuer.btns.copy:SetTooltip("Copy")
	inspanel.valuer.btns.copy:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )	

	inspanel.valuer.btns.swap = vgui.Create( "DButton", inspanel.valuer.btns )
	inspanel.valuer.btns.swap:SetIcon( UI_ICONS.swap )
	inspanel.valuer.btns.swap:SetText("")
	inspanel.valuer.btns.swap:SetTooltip("Swap")
	inspanel.valuer.btns.swap:DockMargin( 0, 0, UI_ICONBUTTON_W, 0 )
	inspanel.valuer.btns.swap:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )

	inspanel.valuer.btns.sub = vgui.Create( "DButton", inspanel.valuer.btns )
	inspanel.valuer.btns.sub:SetIcon( UI_ICONS.sub )
	inspanel.valuer.btns.sub:SetText("")
	inspanel.valuer.btns.sub:SetTooltip("Remove")
	inspanel.valuer.btns.sub:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )

	inspanel.valuer.btns.edit:Dock( LEFT )
	inspanel.valuer.btns.add:Dock( LEFT )
	inspanel.valuer.btns.copy:Dock( LEFT )
	inspanel.valuer.btns.swap:Dock( LEFT )
	inspanel.valuer.btns.sub:Dock( LEFT )
	
	// columns
	local col1 = inspanel.valuer.tbl:AddColumn( "##" )
	local colmain
	if npanel.structTbl.STRUCT_TBLMAINKEY then
		colmain = inspanel.valuer.tbl:AddColumn( npanel.structTbl.STRUCT_TBLMAINKEY )
		colmain:SetWide( npanel.wide * 0.5 )
	end
	local col2 = inspanel.valuer.tbl:AddColumn(
		"<"..
		(
			npanel.typ == "struct_table" and "struct"
			or npanel.structTbl.TBLSTRUCT and ( 
				istable( npanel.structTbl.TBLSTRUCT.TYPE ) and table.concat( npanel.structTbl.TBLSTRUCT.TYPE , ", " )
				or npanel.structTbl.TBLSTRUCT.TYPE
			)
			or ( npanel.typ == "function" and ( istable( npanel.structTbl.TYPE ) and table.concat( npanel.structTbl.TYPE , ", " )
			or npanel.structTbl.TYPE ) )
			or "any" 
		)
		.. ">" )
	col1:SetFixedWidth( 30 )
	col2:SetWidth( npanel.wide * 0.5 ) --npanel.wide - ScreenScale( 20 ) )

	// (re)build table list
	inspanel.valuer.tbl.BuildList = function()		
		inspanel.valuer.tbl:Clear()
		inspanel.valuer.tbl:ClearSelection()
		if npanel.pendingTbl[npanel.valueName] != nil then
			if !istable( npanel.pendingTbl[npanel.valueName] ) then
				npanel.pendingTbl[npanel.valueName] = { npanel.pendingTbl[npanel.valueName] }
			end
			for k, v in pairs( npanel.pendingTbl[npanel.valueName] ) do
				local str = tostring( ( istable( v ) and string.sub( table.ToString( v ), 2, -3 ) ) or tostring( v ) )
				local line

				if npanel.structTbl.STRUCT_TBLMAINKEY then
					local main = istable( v ) and v[npanel.structTbl.STRUCT_TBLMAINKEY]
					if GetPresetName( main ) then
						main = istable( main ) and ( "<"..main.type.."> "..main.name ) or tostring(main)
					end
					line = inspanel.valuer.tbl:AddLine( k, main, str )
				else
					line = inspanel.valuer.tbl:AddLine( k, str )
				end
				
				line:SetToolTip( str )
			end

			inspanel.valuer.tbl:SetHeight( inspanel.valuer.tbl:GetDataHeight() * ( table.Count( npanel.pendingTbl[npanel.valueName] ) + UI_TABLE_L_ADD ) )
		else
			if !npanel.funcing and istable( npanel.structTbl.DEFAULT ) then
				for k, v in pairs( npanel.structTbl.DEFAULT ) do
					local str = "<DEFAULT> " .. tostring( ( istable( v ) and string.sub( table.ToString( v ), 2, -3 ) ) or tostring( v ) )
					local line

					if npanel.structTbl.STRUCT_TBLMAINKEY then
						local main = istable( v ) and v[npanel.structTbl.STRUCT_TBLMAINKEY]
						if GetPresetName( main ) then
							main = istable( main ) and ( "<"..main.type.."> "..main.name ) or tostring(main)
						end
						line = inspanel.valuer.tbl:AddLine( k, main, str )
					else
						line = inspanel.valuer.tbl:AddLine( k, str )
					end
					
					line:SetToolTip( str )
				end
				inspanel.valuer.tbl:SetHeight( inspanel.valuer.tbl:GetDataHeight() * ( table.Count( npanel.structTbl.DEFAULT ) + UI_TABLE_L_ADD ) )
			else
				inspanel.valuer.tbl:SetHeight( inspanel.valuer.tbl:GetDataHeight() * 2 )
			end
		end

		inspanel.valuer:SetHeight( inspanel.valuer.tbl:GetTall() + inspanel.valuer.btns:GetTall() )
		inspanel:InvalidateLayout( true )
		inspanel:SizeToChildren( false, true )
		npanel:InvalidateLayout( true )
		npanel:SizeToChildren( false, true )
	end

	inspanel.valuer.tbl:BuildList()

	inspanel.valuer.tbl:Dock( TOP )
	inspanel.valuer.btns:Dock( TOP )

	inspanel.valuer:SetHeight( inspanel.valuer.tbl:GetTall() + inspanel.valuer.btns:GetTall() )

	// add entry
	inspanel.valuer.btns.add.OnReleased = function()
		if !istable( npanel.pendingTbl[npanel.valueName] ) then
			npanel.pendingTbl[npanel.valueName] = {}
		end
		local k = #npanel.pendingTbl[npanel.valueName]+1

		// default empty
		local tbltyp = npanel.structTbl.TBLSTRUCT and npanel.structTbl.TBLSTRUCT.TYPE
		if inspanel.funcing then tbltyp = npanel.structTbl.TYPE end
		if istable( tbltyp ) then tbltyp = tbltyp[1] end

		if npanel.typ == "struct_table" then
			table.insert( npanel.pendingTbl[npanel.valueName], k, {} )
		else
			table.insert( npanel.pendingTbl[npanel.valueName], k, new_table_add[tbltyp] and new_table_add[tbltyp]() or new_table_add["default"]() )
		end

		inspanel.valuer.tbl:BuildList()
		local line = inspanel.valuer.tbl:GetLines()[k]
		inspanel.valuer.tbl:SelectItem( line )
		inspanel.valuer.tbl.lastline = line
		inspanel.valuer:CloseEditor()
		npanel:ClearView()
		inspanel.valuer:OpenEditor()
		inspanel.valuer.btns.edit:SetToggle( inspanel.valuer.editor != nil )

		npanel:Update()
	end
	
	// remove entry
	inspanel.valuer.btns.sub.OnReleased = function()
		if npanel.pendingTbl[npanel.valueName] == nil and !inspanel.funcing and istable( npanel.structTbl.DEFAULT ) then
			npanel.pendingTbl[npanel.valueName] = table.Copy( npanel.structTbl.DEFAULT )
		elseif npanel.pendingTbl[npanel.valueName] == nil then
			return
		end

		// have to delete in reverse to make index "fall" properly
		local todelete = {}
		for i, line in ipairs( inspanel.valuer.tbl:GetSelected() ) do
			local k = line:GetColumnText( 1 )
			if k == 1 and inspanel.funcing then continue end
			table.insert( todelete, k )
		end

		for _, k in ipairs( table.Reverse( todelete ) ) do
			table.remove( npanel.pendingTbl[npanel.valueName], k )
		end

		npanel:ClearView()
		inspanel.valuer:CloseEditor()
		inspanel.valuer.tbl:BuildList()
		inspanel.valuer.btns.edit:SetToggle( inspanel.valuer.editor != nil )

		npanel:Update()
	end
	
	inspanel.valuer.btns.edit.OnReleased = function()
		inspanel.valuer.ToggleEditor()
	end
	
	// copy entry
	inspanel.valuer.btns.copy.OnReleased = function()
		if npanel.pendingTbl[npanel.valueName] == nil and !inspanel.funcing and istable( npanel.structTbl.DEFAULT ) then
			npanel.pendingTbl[npanel.valueName] = table.Copy( npanel.structTbl.DEFAULT )
		elseif npanel.pendingTbl[npanel.valueName] == nil then
			return
		end

		local sk
		local oneline = #inspanel.valuer.tbl:GetSelected() == 1

		for i, line in pairs( inspanel.valuer.tbl:GetSelected() ) do
			local k = line:GetColumnText( 1 )
			if k == 1 and inspanel.funcing then continue end
			if istable( npanel.pendingTbl[npanel.valueName][k] ) then
				sk = table.insert( npanel.pendingTbl[npanel.valueName], table.Copy( npanel.pendingTbl[npanel.valueName][k] ) )
			else
				sk = table.insert( npanel.pendingTbl[npanel.valueName], npanel.pendingTbl[npanel.valueName][k] )
			end
		end

		inspanel.valuer.tbl.BuildList()
		if oneline then
			local line = inspanel.valuer.tbl:GetLines()[sk]
			inspanel.valuer.tbl:SelectItem( line )
			inspanel.valuer.tbl.lastline = line
			inspanel.valuer:CloseEditor()
			npanel:ClearView()
			inspanel.valuer:OpenEditor()
		end

		inspanel.valuer.btns.edit:SetToggle( inspanel.valuer.editor != nil )
		
		npanel:Update()
	end

	// swap entries
	inspanel.valuer.btns.swap.OnReleased = function()
		local selected = inspanel.valuer.tbl:GetSelected()
		if #selected == 0 then return end
		for i, line in ipairs( selected ) do
			if inspanel.funcing and k == 1 then return end
		end

		if npanel.pendingTbl[npanel.valueName] == nil and !inspanel.funcing and istable( npanel.structTbl.DEFAULT ) then
			npanel.pendingTbl[npanel.valueName] = table.Copy( npanel.structTbl.DEFAULT )
		elseif npanel.pendingTbl[npanel.valueName] == nil then
			return
		end

		if #selected > 2 then
			inspanel.valuer.tbl:ClearSelection()
			inspanel.valuer.tbl:SelectItem( selected[1] )
		end

		local a = selected[1]:GetColumnText(1)

		if #selected == 2 then
			local b = selected[2]:GetColumnText(1)
			if npanel.pendingTbl[npanel.valueName][a] != nil and npanel.pendingTbl[npanel.valueName][b] != nil then
				inspanel.valuer.CloseEditor()
				local c = npanel.pendingTbl[npanel.valueName][a]
				npanel.pendingTbl[npanel.valueName][a] = npanel.pendingTbl[npanel.valueName][b]
				npanel.pendingTbl[npanel.valueName][b] = c
				inspanel.valuer.tbl.BuildList()
				inspanel.valuer.tbl:SelectItem( inspanel.valuer.tbl:GetLines()[a] )
				inspanel.valuer.tbl:SelectItem( inspanel.valuer.tbl:GetLines()[b] )

				npanel:Update()
			end
		else
			MovePrompt(
				inspanel.valuer,
				2,
				selected[1]:GetY(),
				"Swap "..a.." with:",
				function( b )
					if inspanel.funcing and ( a == 1 or b == 1 ) then return end
					if npanel.pendingTbl[npanel.valueName][a] != nil and npanel.pendingTbl[npanel.valueName][b] != nil then
						inspanel.valuer.CloseEditor()
						local c = npanel.pendingTbl[npanel.valueName][a]
						npanel.pendingTbl[npanel.valueName][a] = npanel.pendingTbl[npanel.valueName][b]
						npanel.pendingTbl[npanel.valueName][b] = c
						inspanel.valuer.tbl.BuildList()
						inspanel.valuer.tbl:SelectItem( inspanel.valuer.tbl:GetLines()[a] )
						inspanel.valuer.tbl:SelectItem( inspanel.valuer.tbl:GetLines()[b] )

						npanel:Update()
					end				
				end,
				a,
				nil,
				npanel.pendingTbl[npanel.valueName]
			)
		end
	end

	inspanel.valuer.tbl.DoDoubleClick = function( self, i, line )
		if inspanel.valuer.editor and inspanel.valuer.tbl.lastline == line then 
			npanel:ClearView()
			inspanel.valuer.CloseEditor()
		else
			npanel:ClearView()
			inspanel.valuer:CloseEditor()
			inspanel.valuer:OpenEditor()
			inspanel.valuer.tbl.lastline = line
		end
		inspanel.valuer.btns.edit:SetToggle( inspanel.valuer.editor != nil )
	end

	inspanel.valuer.tbl.OnRowSelected = function( self, i, line )
		if inspanel.valuer.editor and inspanel.valuer.tbl.lastline != line then
			npanel:ClearView()
			inspanel.valuer:CloseEditor()
			inspanel.valuer:OpenEditor()
			inspanel.valuer.tbl.lastline = line
			inspanel.valuer.btns.edit:SetToggle( inspanel.valuer.editor != nil )
		end
	end

	inspanel.valuer.Menu = function( self )
		local menu = DermaMenu()
		menu:AddOption( "Toggle Editor", function()
			self.btns.edit:OnReleased()
		end )
		menu:AddOption( "Add New", function()
			self.btns.add:OnReleased()
		end )
		menu:AddOption( "Copy Selected", function()
			self.btns.copy:OnReleased()
		end )
		local selected = inspanel.valuer.tbl:GetSelected()
		local swapopt = "Swap"
		if #selected == 2 then
			swapopt = "Swap \""..selected[1]:GetColumnText(1).. "\" and \""..selected[2]:GetColumnText(1).."\""
		end
		menu:AddOption( swapopt, function()
			self.btns.swap:OnReleased()
		end )
		menu:AddOption( "Remove Selected", function()
			self.btns.sub:OnReleased()
		end )
		menu:Open()
	end

	inspanel.valuer.tbl.OnRowRightClick = function( self, i, line )
		-- inspanel.valuer.btns.swap:OnReleased()
		inspanel.valuer:Menu()
	end

	inspanel.valuer.CloseEditor = function()
		if inspanel.valuer.editor != nil then
			inspanel.valuer.editor:Remove()
			inspanel.valuer.editor = nil
			inspanel.valuer:SetHeight( inspanel.valuer.tbl:GetTall() + inspanel.valuer.btns:GetTall() )

			inspanel:InvalidateLayout( true )
			inspanel:SizeToChildren( false, true )
			npanel:InvalidateLayout( true )
			npanel:SizeToChildren( false, true )

			local oldlinek = inspanel.valuer.tbl:GetSelectedLine()
			if oldlinek then
				inspanel.valuer.tbl:SelectItem( inspanel.valuer.tbl:GetLine( oldlinek ) )
			end

			if npanel.pendingTbl[npanel.valueName] != nil then
				for k, line in pairs( inspanel.valuer.tbl:GetLines() ) do
					local v = npanel.pendingTbl[npanel.valueName][k]
					local str = tostring( ( istable( v ) and string.sub( table.ToString( v ), 2, -3 ) ) or tostring( v ) )

					if npanel.structTbl.STRUCT_TBLMAINKEY then
						local main = istable( v ) and v[npanel.structTbl.STRUCT_TBLMAINKEY]
						if GetPresetName( main ) then
							main = istable( main ) and ( "<"..main.type.."> "..main.name ) or tostring(main)
						end
						line:SetColumnText( 2, main )
						line:SetColumnText( 3, str )
					else
						line:SetColumnText( 2, str )
					end
					
					line:SetToolTip( str )
				end
			end
		end
	end

	inspanel.valuer.OpenEditor = function()
		if inspanel.valuer.editor != nil then
			return
		end

		local ln, line = inspanel.valuer.tbl:GetSelectedLine()
		if line == nil then
			inspanel.valuer.CloseEditor()
			return
		end

		local k = line:GetColumnText( 1 )
		local v = line:GetColumnText( 2 )

		if k == 1 and inspanel.funcing then
			inspanel.valuer.CloseEditor()
			return
		end

		if npanel.pendingTbl[npanel.valueName] == nil and !inspanel.funcing and istable( npanel.structTbl.DEFAULT ) then
			npanel.pendingTbl[npanel.valueName] = table.Copy( npanel.structTbl.DEFAULT )
		elseif npanel.pendingTbl[npanel.valueName] == nil then
			return
		end

		npanel.viewTbl[npanel.valueName] = istable( npanel.viewTbl[npanel.valueName] ) and npanel.viewTbl[npanel.valueName] or {}
		npanel.viewTbl[npanel.valueName][k] = istable( npanel.viewTbl[npanel.valueName][k] ) and npanel.viewTbl[npanel.valueName][k] or {}
		for ok in pairs( npanel.viewTbl[npanel.valueName] ) do
			if k != ok then
				npanel.viewTbl[npanel.valueName][ok] = nil
			end
		end

		inspanel.valuer.editor = vgui.Create("Panel", inspanel.valuer )
		-- inspanel.valuer.editor:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
		inspanel.valuer.editor.title = vgui.Create( "DLabel", inspanel.valuer.editor )
		inspanel.valuer.editor.title:SetDark( true )
		inspanel.valuer.editor.title:SetText( "Editing #" .. k )
		inspanel.valuer.editor.title:Dock( TOP )
		inspanel.valuer.editor.title:SetContentAlignment( 5 )
		-- inspanel.valuer.editor:SetBackgroundColor( Color( 0, 0, 0, 96 ) )
		inspanel.valuer.editor:SetWidth( npanel:GetWide() )

		inspanel.valuer.editor.structTbl = npanel.structTbl // for functionpanel lookup_reroll

		// ADD PANEL

		// if table.random function then
		if inspanel.funcing then
			AddValuePanel(
				inspanel.valuer.editor, //npanel.valuer.editor
				npanel.structTbl, 
				nil,
				k,
				nil, // is this necessary? --istable( npanel.existingTbl[npanel.valueName] ) and npanel.existingTbl[npanel.valueName], //existingTbl
				npanel.pendingTbl[npanel.valueName], //pendingTbl
				npanel.viewTbl[npanel.valueName],
				npanel.lookup,
				npanel.hierarchy,
				npanel.col,
				"<".. CutLeftString(npanel.structTbl.NAME or npanel.valueName, UI_STR_LEFT_LIM) .. ">",
				true, // funcing
				true // focus
			)

		// if struct, add struct panel
		elseif npanel.typ == "struct_table"
		or ( npanel.typ == "table" and npanel.structTbl.TBLSTRUCT and HasType( npanel.structTbl.TBLSTRUCT.TYPE, "struct" ) )
		then
			AddStructPanel( npanel, inspanel.valuer.editor, nil, k, true )

		// else use the tblstruct
		elseif npanel.structTbl.TBLSTRUCT then
			AddValuePanel(
				inspanel.valuer.editor, //npanel.valuer.editor
				npanel.structTbl.TBLSTRUCT, -- npanel.structTbl, 
				nil,
				k, //it's cool that this works lol //npanel.valueName
				istable( npanel.existingTbl[npanel.valueName] ) and npanel.existingTbl[npanel.valueName], //existingTbl
				npanel.pendingTbl[npanel.valueName], //pendingTbl
				npanel.viewTbl[npanel.valueName],
				npanel.lookup,
				npanel.hierarchy,
				npanel.col,
				"<".. CutLeftString(npanel.structTbl.NAME or npanel.valueName, UI_STR_LEFT_LIM) .. ">",
				nil, // funcing
				true // focus
			)
		else
			print( "COULD NOT CREATE PANEL, MISSING SOMETHING", npanel.typ, npanel.structTbl and npanel.structTbl.TBLSTRUCT )
		end

		inspanel.valuer.editor.Update = function()
			for k, line in pairs( inspanel.valuer.tbl:GetLines() ) do
				local v = npanel.pendingTbl[npanel.valueName][k]
				local str = tostring( ( istable( v ) and string.sub( table.ToString( v ), 2, -3 ) ) or tostring( v ) )
				
				if npanel.structTbl.STRUCT_TBLMAINKEY then
					local main = istable( v ) and v[npanel.structTbl.STRUCT_TBLMAINKEY]
					if GetPresetName( main ) then
						main = istable( main ) and ( "<"..main.type.."> "..main.name ) or tostring(main)
					end
					line:SetColumnText( 2, main )
					line:SetColumnText( 3, str )
				else
					line:SetColumnText( 2, str )
				end

				line:SetToolTip( str )
			end
			
			npanel:Update()
		end

		inspanel.valuer.editor.ChangeEditor = function( self, newk )
			inspanel.valuer:CloseEditor()
			inspanel.valuer.tbl:ClearSelection()
			local line = inspanel.valuer.tbl:GetLines()[newk]
			inspanel.valuer.tbl:SelectItem( line )
			inspanel.valuer:OpenEditor()
		end


		inspanel.valuer.editor:Dock( TOP )

		inspanel.valuer.editor.OnSizeChanged = function( panel, w, h )
			inspanel.valuer:SetHeight( inspanel.valuer.editor:GetTall() + inspanel.valuer.tbl:GetTall() + inspanel.valuer.btns:GetTall() )
			inspanel:InvalidateLayout( true )
			inspanel:SizeToChildren( false, true )
			npanel:InvalidateLayout( true )
			npanel:SizeToChildren( false, true )
		end		
	end

	inspanel.valuer.OnSizeChanged = function( panel, w, h )
		inspanel:InvalidateLayout( true )
		inspanel:SizeToChildren( false, true )
		npanel:InvalidateLayout( true )
		npanel:SizeToChildren( false, true )
	end	

	inspanel.valuer.ToggleEditor = function()
		if inspanel.valuer.editor == nil then
			inspanel.valuer:OpenEditor()
		else
			npanel:ClearView()
			inspanel.valuer:CloseEditor()
		end

		inspanel.valuer.btns.edit:SetToggle( inspanel.valuer.editor == nil )
	end

	if npanel.viewTbl[npanel.valueName] then
		for k in pairs( npanel.viewTbl[npanel.valueName] ) do
			local line = inspanel.valuer.tbl:GetLines()[k]
			if line != nil then
				inspanel.valuer.tbl:SelectItem( line )
				inspanel.valuer.tbl.lastline = line
				inspanel.valuer:OpenEditor()
				inspanel.valuer.btns.edit:SetToggle( inspanel.valuer.editor != nil )
				break
			end
		end
	end
end

function AddBoolPanel( npanel, inspanel )
	inspanel.valuer = vgui.Create( "Panel", inspanel )
	-- inspanel.valuer:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	inspanel.valuer:Dock( TOP )

	inspanel.valuer:DockMargin( marg, 0, marg, 0)
	inspanel.valuer.truebox = vgui.Create( "DCheckBoxLabel", inspanel.valuer )
	inspanel.valuer.truebox:SetText( "True" )
	inspanel.valuer.truebox:SetDark( true )
	inspanel.valuer.truebox:SetHeight( UI_TEXT_H )

	inspanel.valuer.falsebox = vgui.Create( "DCheckBoxLabel", inspanel.valuer )
	inspanel.valuer.falsebox:SetText( "False" )
	inspanel.valuer.falsebox:SetDark( true )
	inspanel.valuer.falsebox:SetHeight( UI_TEXT_H )

	inspanel.valuer.truebox.OnChange = function( panel, val )
		npanel.pendingTbl[npanel.valueName] = true
		inspanel.valuer.truebox:SetChecked( true )
		inspanel.valuer.falsebox:SetChecked( false )

		npanel:Update()
	end

	inspanel.valuer.falsebox.OnChange = function( panel, val )
		npanel.pendingTbl[npanel.valueName] = false
		inspanel.valuer.truebox:SetChecked( false )
		inspanel.valuer.falsebox:SetChecked( true )
		
		npanel:Update()
	end

	inspanel.valuer.truebox:Dock( TOP )
	inspanel.valuer.falsebox:Dock( BOTTOM )

	inspanel.valuer:SetHeight( UI_TEXT_H * 2 )

	if npanel.pendingTbl[npanel.valueName] == true or npanel.pendingTbl[npanel.valueName] == nil and npanel.structTbl.DEFAULT == true then
		inspanel.valuer.truebox:SetChecked( true )
		inspanel.valuer.falsebox:SetChecked( false )
	elseif npanel.pendingTbl[npanel.valueName] == false or npanel.pendingTbl[npanel.valueName] == nil and npanel.structTbl.DEFAULT == false then
		inspanel.valuer.truebox:SetChecked( false )
		inspanel.valuer.falsebox:SetChecked( true )
	end
end

function AddAnyPanel( npanel, inspanel )
	inspanel.valuer = vgui.Create( "Panel", inspanel )
	-- inspanel.valuer:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	inspanel.valuer:Dock( TOP )

	inspanel.valuer.wetfloor = vgui.Create( "DLabel", inspanel.valuer )
	inspanel.valuer.wetfloor:SetDark( true )
	inspanel.valuer.wetfloor:SetText( "<any>" .. ( npanel.pendingTbl[npanel.valueName] != nil and "\n"..tostring( npanel.pendingTbl[npanel.valueName] ) or "" ) )
	inspanel.valuer.wetfloor:Dock( FILL )
	inspanel.valuer.wetfloor:SetContentAlignment( 5 )
	inspanel.valuer:SetContentAlignment( 5 )
	inspanel.valuer:SetHeight( UI_TEXT_H )
end

// table key, name, paneltext, min, max, default
local t_function_panels = {
	RandomColor = {
		[1] = nil, // __RANDOMCOLOR
		[2] = { "slider_h_min", "hue:min", 0, 720, 0 },
		[3] = { "slider_h_max", "hue:max", 0, 720, 360 },
		[4] = { "slider_s_min", "saturation:min", 0, 1, 0.5 },
		[5] = { "slider_s_max", "saturation:max", 0, 1, 1 },
		[6] = { "slider_v_min", "value:min", 0, 1, 0.5 },
		[7] = { "slider_v_max", "value:max", 0, 1, 1 },
	},
	RandomVector = {
		[2] = { "slider_x_min", "x:min", -16384, 16384, -1 },
		[3] = { "slider_x_max", "x:max", -16384, 16384, 1 },
		[4] = { "slider_y_min", "y:min", -16384, 16384, -1 },
		[5] = { "slider_y_max", "y:max", -16384, 16384, 1 },
		[6] = { "slider_z_min", "z:min", -16384, 16384, -1 },
		[7] = { "slider_z_max", "z:max", -16384, 16384, 1 },
	},
	RandomAngle = {
		[2] = { "slider_p_min", "p:min", -360, 360, 0 },
		[3] = { "slider_p_max", "p:max", -360, 360, 0 },
		[4] = { "slider_y_min", "y:min", -360, 360, -180 },
		[5] = { "slider_y_max", "y:max", -360, 360, 180 },
		[6] = { "slider_r_min", "r:min", -360, 360, 0 },
		[7] = { "slider_r_max", "r:max", -360, 360, 0 },
	},
}

function AddFunctionPanel( npanel, inspanel )
	inspanel.valuer = vgui.Create( "Panel", inspanel )
	-- inspanel.valuer:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	inspanel.valuer:Dock( TOP )

	// a higher table containing a list of which values should be rerolled every time
	local parentdef_t, pdef
	if npanel.structTbl["LOOKUP_REROLL"] then
		inspanel.valuer.forcedpanel = vgui.Create( "Panel", inspanel.valuer )
		inspanel.valuer.forcedpanel:DockMargin( marg, 0, 0, 0 )
		inspanel.valuer.forcedpanel.toggle = vgui.Create( "DCheckBoxLabel", inspanel.valuer.forcedpanel )
		inspanel.valuer.forcedpanel.toggle:SetText( "Reroll function every call" )
		inspanel.valuer.forcedpanel.toggle:SetDark( true )

		parentdef_t = npanel.parent.structTbl and npanel.parent.structTbl.DEFAULT and npanel.parent.structTbl.DEFAULT["LOOKUP_REROLL"]
		pdef = parentdef_t and parentdef_t[npanel.valueName]

		if npanel.pendingTbl["LOOKUP_REROLL"] and npanel.pendingTbl["LOOKUP_REROLL"][npanel.valueName] != nil or pdef then
			inspanel.valuer.forcedpanel.toggle:SetChecked( npanel.pendingTbl["LOOKUP_REROLL"] and npanel.pendingTbl["LOOKUP_REROLL"][npanel.valueName] or pdef )
		end
		inspanel.valuer.forcedpanel.toggle.OnChange = function( panel, val )
			npanel.pendingTbl["LOOKUP_REROLL"] = npanel.pendingTbl["LOOKUP_REROLL"] or parentdef_t or {}
			npanel.pendingTbl["LOOKUP_REROLL"][npanel.valueName] = val or nil // true or nil

			if inspanel.valuer.funcpanel and isfunction( inspanel.valuer.funcpanel.InitPend ) then
				inspanel.valuer.funcpanel:InitPend()
			else
				inspanel.valuer:InitPend()
			end

			if npanel.pendingTbl["LOOKUP_REROLL"] and table.IsEmpty( npanel.pendingTbl["LOOKUP_REROLL"] ) then npanel.pendingTbl["LOOKUP_REROLL"] = nil end

			npanel:Update()
		end
		inspanel.valuer.forcedpanel:Dock( TOP )
		inspanel.valuer.forcedpanel.toggle:Dock( LEFT )
	end

	inspanel.valuer.funcbox = vgui.Create( "DComboBox", inspanel.valuer )
	inspanel.valuer.funcbox:Dock( TOP )
	inspanel.valuer.funcbox:SetHeight( UI_ENTRY_H )
	
	local t_can = {}

	// check which functions it can do
	for f, ft in pairs( t_FUNCS ) do
		if istable( ft.TYPE ) then
			for _, v in ipairs( ft.TYPE ) do
				if v == "any" then
					t_can[f] = !HasType( npanel.structTbl.TYPE, "function" )
					break
				else
					t_can[f] = HasType( npanel.structTbl.TYPE, v )
				end
				if t_can[f] then break end
			end
		else
			if ft.TYPE == "any" then
				t_can[f] = !HasType( npanel.structTbl.TYPE, "function" )
			else
				t_can[f] = HasType( npanel.structTbl.TYPE, ft.TYPE )
			end
		end
	end

	inspanel.valuer.InitPend = function()
		local def = npanel.pendingTbl[npanel.valueName] == nil and istable( npanel.structTbl.DEFAULT )
			and npanel.structTbl.DEFAULT[1] == inspanel.valuer.func or nil
		npanel.pendingTbl[npanel.valueName] = istable( npanel.pendingTbl[npanel.valueName] ) and npanel.pendingTbl[npanel.valueName]
			or def and CopyData( npanel.structTbl.DEFAULT )
			or {}

		npanel.pendingTbl["LOOKUP_REROLL"] = npanel.pendingTbl["LOOKUP_REROLL"] or parentdef_t or {}
		npanel.pendingTbl["LOOKUP_REROLL"][npanel.valueName] = npanel.pendingTbl["LOOKUP_REROLL"][npanel.valueName] or pdef or nil
		if table.IsEmpty( npanel.pendingTbl["LOOKUP_REROLL"] ) then npanel.pendingTbl["LOOKUP_REROLL"] = nil end

		npanel.pendingTbl[npanel.valueName][1] = inspanel.valuer.func
		npanel:Update()
	end

	inspanel.valuer.TableRandom = function()
		AddTablePanel( npanel, inspanel.valuer.funcpanel )
	end

	inspanel.valuer.RandomAngle = function()
		inspanel.valuer.funcpanel:DockMargin( marg, 0, marg, 0 )

		local def = istable( npanel.structTbl.DEFAULT ) and npanel.structTbl.DEFAULT[1] == inspanel.valuer.func and npanel.structTbl.DEFAULT

		for sk, tbl in SortedPairs( t_function_panels["RandomAngle"] ) do
			local k = tbl[1]
			inspanel.valuer.funcpanel[k] = vgui.Create( "DNumSlider", inspanel.valuer.funcpanel )
			inspanel.valuer.funcpanel[k]:SetDark( true )
			inspanel.valuer.funcpanel[k]:SetText( "<" .. tbl[2] .. ">" )
			inspanel.valuer.funcpanel[k]:SetHeight( UI_TEXT_H * 1.25 )
			inspanel.valuer.funcpanel[k]:SetMinMax( tbl[3], tbl[4] )
			inspanel.valuer.funcpanel[k]:SetDefaultValue( tbl[5] )
			inspanel.valuer.funcpanel[k]:Dock( TOP )
			inspanel.valuer.funcpanel[k]:SetValue(
				npanel.pendingTbl[npanel.valueName] and npanel.pendingTbl[npanel.valueName][sk]
				or def and def[sk]
				or inspanel.valuer.funcpanel[k]:GetDefaultValue() )

			inspanel.valuer.funcpanel[k].OnValueChanged = function( panel, val )
				inspanel.valuer:InitPend()
				npanel.pendingTbl[npanel.valueName][sk] = val
				npanel:Update()
			end
		end

		inspanel.valuer.funcpanel:SetHeight( inspanel.valuer.funcpanel.slider_p_min:GetTall() * 6 )
		inspanel.valuer.funcpanel:InvalidateLayout( true )
	end

	inspanel.valuer.RandomColor = function()
		inspanel.valuer.funcpanel.colortest = vgui.Create( "Panel", inspanel.valuer.funcpanel )
		inspanel.valuer.funcpanel.colortest:DockMargin( marg, marg, marg, marg )
		inspanel.valuer.funcpanel.colortest:SetHeight( UI_ENTRY_H )
		inspanel.valuer.funcpanel.colortest:Dock( TOP )
		-- inspanel.valuer.funcpanel.colortest:SetBackgroundColor( Color(0,0,0,0) )
		inspanel.valuer.funcpanel.colortest.refresh = vgui.Create( "DButton", inspanel.valuer.funcpanel.colortest )
		inspanel.valuer.funcpanel.colortest.refresh:Dock( LEFT )
		inspanel.valuer.funcpanel.colortest.refresh:DockMargin( 0, 0, marg, 0 )
		inspanel.valuer.funcpanel.colortest.refresh:SetWidth( UI_ICONBUTTON_W )
		inspanel.valuer.funcpanel.colortest.refresh:SetText( "" )
		inspanel.valuer.funcpanel.colortest.refresh:SetIcon( UI_ICONS.revert )
		inspanel.valuer.funcpanel.colortest.refresh.OnReleased = function()
			inspanel.valuer.funcpanel.colortest:Recolor()
		end

		inspanel.valuer.funcpanel:DockMargin( marg, 0, marg, 0 )

		local def = istable( npanel.structTbl.DEFAULT ) and npanel.structTbl.DEFAULT[1] == inspanel.valuer.func and npanel.structTbl.DEFAULT

		for sk, tbl in SortedPairs( t_function_panels["RandomColor"] ) do
			local k = tbl[1]
			inspanel.valuer.funcpanel[k] = vgui.Create( "DNumSlider", inspanel.valuer.funcpanel )
			inspanel.valuer.funcpanel[k]:SetDark( true )
			inspanel.valuer.funcpanel[k]:SetText( "<" .. tbl[2] .. ">" )
			inspanel.valuer.funcpanel[k]:SetHeight( UI_TEXT_H * 1.25 )
			inspanel.valuer.funcpanel[k]:SetMinMax( tbl[3], tbl[4] )
			inspanel.valuer.funcpanel[k]:SetDefaultValue( tbl[5] )
			inspanel.valuer.funcpanel[k]:Dock( TOP )
			inspanel.valuer.funcpanel[k]:SetValue(
				npanel.pendingTbl[npanel.valueName] and npanel.pendingTbl[npanel.valueName][sk]
				or def and def[sk]
				or inspanel.valuer.funcpanel[k]:GetDefaultValue() )

			inspanel.valuer.funcpanel[k].OnValueChanged = function( panel, val )
				inspanel.valuer:InitPend()
				if npanel.pendingTbl[npanel.valueName][sk] == val then return end
				npanel.pendingTbl[npanel.valueName][sk] = val
				inspanel.valuer.funcpanel.colortest.Recolor()
				npanel:Update()
			end
		end

		inspanel.valuer.funcpanel.colortest.oldw = 0
		inspanel.valuer.funcpanel.colortest.colors = {}

		// random colors above panel
		inspanel.valuer.funcpanel.colortest.Recolor = function()
			for _, colorbox in pairs( inspanel.valuer.funcpanel.colortest.colors ) do
				colorbox:Remove()
			end
			inspanel.valuer.funcpanel.colortest.colors = {}

			local nw = npanel:GetWide()
			local n = istable( npanel.pendingTbl[npanel.valueName] ) and npanel.pendingTbl[npanel.valueName] or istable( npanel.structTbl.DEFAULT ) and npanel.structTbl.DEFAULT[1] == inspanel.valuer.func and npanel.structTbl.DEFAULT
			for i=1,(nw / UI_COLORTEST_W) do
				local k = table.insert( inspanel.valuer.funcpanel.colortest.colors, vgui.Create( "DPanel", inspanel.valuer.funcpanel.colortest ) )
				inspanel.valuer.funcpanel.colortest.colors[k]:Dock( LEFT )
				inspanel.valuer.funcpanel.colortest.colors[k]:SetWidth( UI_COLORTEST_W )
				inspanel.valuer.funcpanel.colortest.colors[k]:SetBackgroundColor( RandomColor( n[2], n[3], n[4], n[5], n[6], n[7] ) )
				inspanel.valuer.funcpanel.colortest.colors[k].Paint = function( self, w, h )
					local col = self:GetBackgroundColor()
					surface.SetDrawColor( col.r, col.g, col.b, col.a )
					surface.DrawRect( 0, 0, w, h )
				end
			end

			inspanel.valuer.funcpanel.colortest.oldw = nw
		end

		inspanel.valuer.funcpanel.OnSizeChanged = function()
			local nw = npanel:GetWide()
			if math.abs( nw - inspanel.valuer.funcpanel.colortest.oldw ) > UI_COLORTEST_W then
				inspanel.valuer.funcpanel.colortest.Recolor()
			end

			inspanel.valuer:InvalidateLayout( true )
			inspanel.valuer:SizeToChildren( false, true )
			inspanel:InvalidateLayout( true )
			inspanel:SizeToChildren( false, true )
			npanel:InvalidateLayout( true )
			npanel:SizeToChildren( false, true )
		end

		inspanel.valuer.funcpanel:SetHeight( marg*2 + inspanel.valuer.funcpanel.colortest:GetTall() + inspanel.valuer.funcpanel.slider_h_min:GetTall() * 6 )
		inspanel.valuer.funcpanel:InvalidateLayout( true )
	end
	
	inspanel.valuer.RandomVector = function()
		inspanel.valuer.funcpanel:DockMargin( marg, 0, marg, 0 )

		local def = istable( npanel.structTbl.DEFAULT ) and npanel.structTbl.DEFAULT[1] == inspanel.valuer.func and npanel.structTbl.DEFAULT

		for sk, tbl in SortedPairs( t_function_panels["RandomVector"] ) do
			local k = tbl[1]
			inspanel.valuer.funcpanel[k] = vgui.Create( "DNumSlider", inspanel.valuer.funcpanel )
			inspanel.valuer.funcpanel[k]:SetDark( true )
			inspanel.valuer.funcpanel[k]:SetText( "<" .. tbl[2] .. ">" )
			inspanel.valuer.funcpanel[k]:SetHeight( UI_TEXT_H * 1.25 )
			inspanel.valuer.funcpanel[k]:SetMinMax( tbl[3], tbl[4] )
			inspanel.valuer.funcpanel[k]:SetDefaultValue( tbl[5] )
			inspanel.valuer.funcpanel[k]:Dock( TOP )
			inspanel.valuer.funcpanel[k]:SetValue(
				npanel.pendingTbl[npanel.valueName] and npanel.pendingTbl[npanel.valueName][sk]
				or def and def[sk]
				or inspanel.valuer.funcpanel[k]:GetDefaultValue() )

			inspanel.valuer.funcpanel[k].OnValueChanged = function( panel, val )
				inspanel.valuer:InitPend()
				npanel.pendingTbl[npanel.valueName][sk] = val
				npanel:Update()
			end
		end

		inspanel.valuer.funcpanel:SetHeight( inspanel.valuer.funcpanel.slider_x_min:GetTall() * 6 )
		inspanel.valuer.funcpanel:InvalidateLayout( true )
	end

	inspanel.valuer.MathRandom = function()
		inspanel.valuer.funcpanel:DockMargin( marg, 0, marg, 0 )
		
		// num slider if it has a min and max
		if npanel.structTbl.MIN and npanel.structTbl.MAX then
			inspanel.valuer.funcpanel.min = vgui.Create( "DNumSlider", inspanel.valuer.funcpanel )
			inspanel.valuer.funcpanel.min:Dock( TOP )
			inspanel.valuer.funcpanel.min:SetDark( true )
			inspanel.valuer.funcpanel.min:SetDefaultValue( npanel.structTbl.MIN )
			inspanel.valuer.funcpanel.min:SetHeight( UI_TEXT_H * 1.25 )
			inspanel.valuer.funcpanel.min:SetMinMax( npanel.structTbl.MIN, npanel.structTbl.MAX )
			inspanel.valuer.funcpanel.min:SetText( "<min>" )

			inspanel.valuer.funcpanel.max = vgui.Create( "DNumSlider", inspanel.valuer.funcpanel )
			inspanel.valuer.funcpanel.max:Dock( TOP )
			inspanel.valuer.funcpanel.max:SetDark( true )
			inspanel.valuer.funcpanel.max:SetDefaultValue( npanel.structTbl.MAX )
			inspanel.valuer.funcpanel.max:SetHeight( UI_TEXT_H * 1.25 )
			inspanel.valuer.funcpanel.max:SetMinMax( npanel.structTbl.MIN, npanel.structTbl.MAX )
			inspanel.valuer.funcpanel.max:SetText( "<max>" )
		else // numwang otherwise
			inspanel.valuer.funcpanel.minpan = vgui.Create( "Panel", inspanel.valuer.funcpanel )
			inspanel.valuer.funcpanel.minpan.label = vgui.Create( "DLabel", inspanel.valuer.funcpanel.minpan )
			inspanel.valuer.funcpanel.minpan.label:DockMargin( 0, 0, marg, 0 )
			inspanel.valuer.funcpanel.minpan.label:SetDark( true )
			inspanel.valuer.funcpanel.minpan.label:SetText( "<min>" )
			inspanel.valuer.funcpanel.minpan:Dock( TOP )
			-- inspanel.valuer.funcpanel.minpan:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
			inspanel.valuer.funcpanel.min = vgui.Create( "DNumberWang", inspanel.valuer.funcpanel.minpan )
			inspanel.valuer.funcpanel.min:SetHeight( UI_ENTRY_H )
			inspanel.valuer.funcpanel.minpan:SizeToChildren( false, true )

			inspanel.valuer.funcpanel.maxpan = vgui.Create( "Panel", inspanel.valuer.funcpanel )
			inspanel.valuer.funcpanel.maxpan.label = vgui.Create( "DLabel", inspanel.valuer.funcpanel.maxpan )
			inspanel.valuer.funcpanel.maxpan.label:DockMargin( 0, 0, marg, 0 )
			inspanel.valuer.funcpanel.maxpan.label:SetDark( true )
			inspanel.valuer.funcpanel.maxpan.label:SetText( "<max>" )
			inspanel.valuer.funcpanel.maxpan.label:SizeToContentsX( 5 ) -- Must be called after setting the text
			inspanel.valuer.funcpanel.maxpan:Dock( TOP )
			-- inspanel.valuer.funcpanel.maxpan:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
			inspanel.valuer.funcpanel.max = vgui.Create( "DNumberWang", inspanel.valuer.funcpanel.maxpan )
			inspanel.valuer.funcpanel.max:SetHeight( UI_ENTRY_H )
			inspanel.valuer.funcpanel.maxpan:SizeToChildren( false, true )

			inspanel.valuer.funcpanel.minpan.label:SetWidth( inspanel.valuer.funcpanel.maxpan.label:GetWide() )

			if npanel.structTbl.MIN then
				inspanel.valuer.funcpanel.min:SetMin( npanel.structTbl.MIN )
				inspanel.valuer.funcpanel.max:SetMin( npanel.structTbl.MIN )
			else
				inspanel.valuer.funcpanel.min:SetMin( nil )
				inspanel.valuer.funcpanel.max:SetMin( nil )
			end
			if npanel.structTbl.MAX then
				inspanel.valuer.funcpanel.min:SetMax( npanel.structTbl.MAX )
				inspanel.valuer.funcpanel.max:SetMax( npanel.structTbl.MAX )
			else
				inspanel.valuer.funcpanel.min:SetMax( nil )
				inspanel.valuer.funcpanel.max:SetMax( nil )
			end

			inspanel.valuer.funcpanel.max:Dock( FILL )
			inspanel.valuer.funcpanel.maxpan.label:Dock( LEFT )
			inspanel.valuer.funcpanel.min:Dock( FILL )
			inspanel.valuer.funcpanel.minpan.label:Dock( LEFT )
		end

		inspanel.valuer.funcpanel.InitPend = function()
			inspanel.valuer:InitPend()
			npanel.pendingTbl[npanel.valueName][2] = isnumber( npanel.pendingTbl[npanel.valueName][2] ) and npanel.pendingTbl[npanel.valueName][2] 
				or istable( npanel.structTbl.DEFAULT ) and npanel.structTbl.DEFAULT[1] == inspanel.valuer.func and isnumber( npanel.structTbl.DEFAULT[2] ) and npanel.structTbl.DEFAULT[2] or npanel.structTbl.MIN or 0
			npanel.pendingTbl[npanel.valueName][3] = isnumber( npanel.pendingTbl[npanel.valueName][3] ) and npanel.pendingTbl[npanel.valueName][3] 
				or istable( npanel.structTbl.DEFAULT ) and npanel.structTbl.DEFAULT[1] == inspanel.valuer.func and isnumber( npanel.structTbl.DEFAULT[3] ) and npanel.structTbl.DEFAULT[3] or npanel.structTbl.MAX or 1
		end

      // avoids forcing PendingAdd every time value box is loaded
      // MathRandom is a unique case as it uses MIN and MAX and "default" values could be incorrect
      inspanel.valuer.funcpanel.SafeInit = function()
         local low = npanel.pendingTbl[npanel.valueName] != nil and isnumber( npanel.pendingTbl[npanel.valueName][2] ) and npanel.pendingTbl[npanel.valueName][2] 
				or istable( npanel.structTbl.DEFAULT ) and npanel.structTbl.DEFAULT[1] == inspanel.valuer.func and isnumber( npanel.structTbl.DEFAULT[2] ) and npanel.structTbl.DEFAULT[2] or npanel.structTbl.MIN or 0
			local high = npanel.pendingTbl[npanel.valueName] != nil and isnumber( npanel.pendingTbl[npanel.valueName][3] ) and npanel.pendingTbl[npanel.valueName][3] 
				or istable( npanel.structTbl.DEFAULT ) and npanel.structTbl.DEFAULT[1] == inspanel.valuer.func and isnumber( npanel.structTbl.DEFAULT[3] ) and npanel.structTbl.DEFAULT[3] or npanel.structTbl.MAX or 1
         if npanel.pendingTbl[npanel.valueName] and low != npanel.pendingTbl[npanel.valueName][2] and low != 0
         or npanel.pendingTbl[npanel.valueName] and high != npanel.pendingTbl[npanel.valueName][3] and high != 1 then
            inspanel.valuer.funcpanel:InitPend()
         end
      end

		inspanel.valuer.funcpanel.min:SetValue( istable( npanel.pendingTbl[npanel.valueName] ) and isnumber( npanel.pendingTbl[npanel.valueName][2] ) and npanel.pendingTbl[npanel.valueName][2] 
			or istable( npanel.structTbl.DEFAULT ) and npanel.structTbl.DEFAULT[1] == inspanel.valuer.func and isnumber( npanel.structTbl.DEFAULT[2] ) and npanel.structTbl.DEFAULT[2]
			or npanel.structTbl.MIN
			or 0 )

		inspanel.valuer.funcpanel.max:SetValue( istable( npanel.pendingTbl[npanel.valueName] ) and isnumber( npanel.pendingTbl[npanel.valueName][3] ) and npanel.pendingTbl[npanel.valueName][3] 
			or istable( npanel.structTbl.DEFAULT ) and npanel.structTbl.DEFAULT[1] == inspanel.valuer.func and isnumber( npanel.structTbl.DEFAULT[3] ) and npanel.structTbl.DEFAULT[3]
			or npanel.structTbl.MAX
			or 1 )

		inspanel.valuer.funcpanel.min.OnValueChanged = function( panel, val )
			inspanel.valuer.funcpanel:InitPend()
			local val = tonumber(val)
			if npanel.structTbl.MAX and val > npanel.structTbl.MAX then val = npanel.structTbl.MAX end
			if npanel.structTbl.MIN and val < npanel.structTbl.MIN then val = npanel.structTbl.MIN end

			if inspanel.valuer.func == "__RANDOM" then
				npanel.pendingTbl[npanel.valueName][2] = math.Round( val )
			else
				npanel.pendingTbl[npanel.valueName][2] = val
			end
			npanel:Update()
		end
		inspanel.valuer.funcpanel.max.OnValueChanged = function( panel, val )
			inspanel.valuer.funcpanel:InitPend()
			local val = tonumber(val)
			if npanel.structTbl.MAX and val > npanel.structTbl.MAX then val = npanel.structTbl.MAX end
			if npanel.structTbl.MIN and val < npanel.structTbl.MIN then val = npanel.structTbl.MIN end

			if inspanel.valuer.func == "__RANDOM" then
				npanel.pendingTbl[npanel.valueName][3] = math.Round( val )
			else
				npanel.pendingTbl[npanel.valueName][3] = val
			end
			npanel:Update()
		end

		// if int
		if inspanel.valuer.func == "__RANDOM" then
			inspanel.valuer.funcpanel.min:SetDecimals( 0 )
			inspanel.valuer.funcpanel.max:SetDecimals( 0 )
			
			inspanel.valuer.funcpanel:SafeInit()
      elseif inspanel.valuer.func == "__RAND" then
         inspanel.valuer.funcpanel:SafeInit()
		end

		inspanel.valuer.funcpanel:SetHeight( inspanel.valuer.funcpanel.min:GetTall() + inspanel.valuer.funcpanel.max:GetTall() )
	end

	inspanel.valuer.funclist = {
		["__RANDOM"] = inspanel.valuer.MathRandom,
		["__RAND"] = inspanel.valuer.MathRandom,
		["__TBLRANDOM"] = inspanel.valuer.TableRandom,
		["__RANDOMCOLOR"] = inspanel.valuer.RandomColor,
		["__RANDOMANGLE"] = inspanel.valuer.RandomAngle,
		["__RANDOMVECTOR"] = inspanel.valuer.RandomVector,
	}

	inspanel.valuer.ChangeFunc = function( f )
		inspanel.valuer.func = f
		if inspanel.valuer.funcpanel != nil then
			inspanel.valuer.funcpanel:Remove()
		end

		// create func panel
		inspanel.valuer.funcpanel = vgui.Create( "Panel", inspanel.valuer )
		inspanel.valuer.funcpanel:Dock( TOP )
		-- inspanel.valuer.funcpanel:SetBackgroundColor( Color( 0, 0, 0, 0 ) )

		inspanel.valuer.funcpanel.OnSizeChanged = function()
			inspanel.valuer:InvalidateLayout( true )
			inspanel.valuer:SizeToChildren( false, true )
			inspanel:InvalidateLayout( true )
			inspanel:SizeToChildren( false, true )
			npanel:InvalidateLayout( true )
			npanel:SizeToChildren( false, true )
		end

		inspanel.valuer.funcpanel.funcing = true // identifies it is in a function for reasons/fixes

		// function format is a table with the first value being the string referring to the function
		// default if nil
		if not ( istable( npanel.pendingTbl[npanel.valueName] ) and npanel.pendingTbl[npanel.valueName][1] == inspanel.valuer.func )
		and not ( istable( npanel.structTbl.DEFAULT ) and npanel.structTbl.DEFAULT[1] == inspanel.valuer.func ) then
			inspanel.valuer:InitPend()
			-- npanel.pendingTbl[npanel.valueName] = { inspanel.valuer.func }
			-- npanel:Update()
		end

		// create specific func controls
		inspanel.valuer.funclist[inspanel.valuer.func]()		
	end

	inspanel.valuer.funcbox.OnSelect = function( self, index, text, data )
		inspanel.valuer.ChangeFunc( data )
	end

	// fill choices and select existing
	inspanel.valuer.funcbox.count = 0
	for f, can in pairs( t_can ) do
		if can then
			local ischosen
			if npanel.pendingTbl[npanel.valueName] != nil then
				ischosen = istable( npanel.pendingTbl[npanel.valueName] ) and npanel.pendingTbl[npanel.valueName][1] == f
			elseif npanel.structTbl.DEFAULT != nil then
				ischosen = istable( npanel.structTbl.DEFAULT ) and npanel.structTbl.DEFAULT[1] == f
			end
			inspanel.valuer.funcbox.count = inspanel.valuer.funcbox:AddChoice( t_FUNCS[f].NAME, f, ischosen )
			if ischosen then
				inspanel.valuer.ChangeFunc( f )
			end
		end
	end

	inspanel.valuer:InvalidateLayout( true )
	inspanel.valuer:SizeToChildren( false, true )
	inspanel:InvalidateLayout( true )
	inspanel:SizeToChildren( false, true )
	npanel:InvalidateLayout( true )
	npanel:SizeToChildren( false, true )

end

function AddEnumPanel( npanel, inspanel )
	inspanel.valuer = vgui.Create( "Panel", inspanel )
	-- inspanel.valuer:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	inspanel.valuer:Dock( TOP )

	inspanel.valuer.enumbox = vgui.Create( "DComboBox", inspanel.valuer )
	inspanel.valuer.enumbox:SetSortItems( false )

	// can it be sorted?
	local cansort = true // by value
	if npanel.structTbl.ENUM_SORT == true then
		cansort = false
	else
		for k, v in pairs( npanel.structTbl.ENUM ) do
			if !isnumber(v) then
				cansort = false
			end
		end
	end

	// add default first on the list
	local test = npanel.pendingTbl[npanel.valueName] != nil and npanel.pendingTbl[npanel.valueName] or npanel.structTbl.DEFAULT
	-- if npanel.structTbl.ENUM.DEFAULT then
	-- 	local str = "DEFAULT" .. " ("..tostring(npanel.structTbl.ENUM.DEFAULT)..")"
	-- 	inspanel.valuer.enumbox:AddChoice( str, "DEFAULT", test != nil and npanel.structTbl.ENUM[test] == "DEFAULT" )
	-- end
	
	// add the rest
	if cansort then
		for k, v in SortedPairsByValue( npanel.structTbl.ENUM ) do
			-- if k == "DEFAULT" then continue end
			local str = k .. " ("..tostring(v)..")"
			inspanel.valuer.enumbox:AddChoice( str, k, test != nil and npanel.structTbl.ENUM[test] == v )
		end
	else
		for k, v in SortedPairs( npanel.structTbl.ENUM ) do
			-- if k == "DEFAULT" then continue end
			local str = k .. " ("..tostring(v)..")"
			inspanel.valuer.enumbox:AddChoice( str, k, test != nil and npanel.structTbl.ENUM[test] == v )
		end
	end


	inspanel.valuer.valuelabel = vgui.Create( "DLabel", inspanel.valuer )
	inspanel.valuer.valuelabel:SetDark( true )
	inspanel.valuer.valuelabel:SetText( "" )
	inspanel.valuer.valuelabel:SetContentAlignment( 5 )
	inspanel.valuer.valuelabel:Dock( TOP )
	inspanel.valuer.valuelabel:SizeToContentsY( marg - 2.5 )

	inspanel.valuer.enumbox:Dock( TOP )
	inspanel.valuer.enumbox:SetHeight( UI_ENTRY_H )
	inspanel.valuer:SetHeight( UI_ENTRY_H * 2 )

	inspanel.valuer.enumbox.OnSelect = function( self, text, data )
		// bug: text gives v and data gives the text??
		npanel.pendingTbl[npanel.valueName] = select( 2, self:GetSelected() )

		inspanel.valuer.valuelabel:SetText( tostring( npanel.structTbl.ENUM[ npanel.pendingTbl[npanel.valueName] ] ) )
		npanel:Update()
	end

	local selected = inspanel.valuer.enumbox:GetSelected()
	if selected != nil and npanel.structTbl.ENUM[selected] != nil then
		inspanel.valuer.valuelabel:SetText( tostring( npanel.structTbl.ENUM[selected] ) )
	end

	inspanel:InvalidateLayout( true )
	inspanel:SizeToChildren( false, true )
	npanel:InvalidateLayout( true )
	npanel:SizeToChildren( false, true )
end

function AddPresetPanel( npanel, inspanel )
	inspanel.valuer = vgui.Create( "Panel", inspanel )
	-- inspanel.valuer:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	inspanel.valuer:Dock( TOP )

	inspanel.valuer.boxpanel = vgui.Create ( "Panel", inspanel.valuer )
	inspanel.valuer.boxpanel:Dock( TOP )

	inspanel.valuer.typebox = vgui.Create( "DComboBox", inspanel.valuer.boxpanel )
	inspanel.valuer.namebox = vgui.Create( "DComboBox", inspanel.valuer.boxpanel )
	
	inspanel.valuer.typebox:SetText( "<type>" )
	inspanel.valuer.namebox:SetText( "<name>" )

	inspanel.valuer.typebox:SetSortItems( true )
	inspanel.valuer.namebox:SetSortItems( true )

	inspanel.valuer.typebox.count = 0
	inspanel.valuer.namebox.count = 0

	// either entity class list or presets
	if npanel.structTbl.PRESETS_ENTITYLIST == true then
		for _, k in ipairs( list.GetTable() ) do
			-- if npanel.structTbl.PRESETS_ENTITYLIST_ONLY and !npanel.structTbl.PRESETS_ENTITYLIST_ONLY[k] then continue end
			if !isstring( k ) then // who the fuck made their addon put [NULL Panel]s in the list
				continue
			end

			local valid
			for _, tbl in pairs( list.Get( k ) ) do
				if !istable( tbl ) then continue end
				if tbl.class or tbl.Class or tbl.ClassName then
					valid = true
					break
				end
			end
			if !valid then continue end

			inspanel.valuer.typebox.count = inspanel.valuer.typebox:AddChoice( tostring(k), k, istable( npanel.pendingTbl[npanel.valueName] ) and npanel.pendingTbl[npanel.valueName]["type"] == k )
		end
	else
		for _, k in SortedPairsByValue( npanel.structTbl.PRESETS ) do
			inspanel.valuer.typebox.count = inspanel.valuer.typebox:AddChoice( tostring(k), tostring(k), istable( npanel.pendingTbl[npanel.valueName] ) and npanel.pendingTbl[npanel.valueName]["type"] == k )
		end
	end

	if inspanel.valuer.typebox.count == 1 then
		inspanel.valuer.typebox:ChooseOptionID( 1 )
	end

	inspanel.valuer.typebox:Dock( LEFT )
	inspanel.valuer.namebox:Dock( LEFT )
	inspanel.valuer.typebox:SetWidth( npanel:GetWide() * 0.3 )
	inspanel.valuer.namebox:SetWidth( npanel:GetWide() * 0.7 )

	inspanel.valuer.typebox.OnSelect = function( self, text, data )
		if data == nil then return end

		local noupd // will update unless the same
		if istable( npanel.pendingTbl[npanel.valueName] ) then
			if npanel.pendingTbl[npanel.valueName]["type"] == data then
				noupd = true
			end
		else
			npanel.pendingTbl[npanel.valueName] = {}
		end
		
		// fill names and clears class struct
		if npanel.pendingTbl[npanel.valueName]["type"] != data then
			npanel.pendingTbl[npanel.valueName]["name"] = nil
			inspanel.valuer.ClearClassStruct()
			npanel.pendingTbl[npanel.valueName]["type"] = data
			
			inspanel.valuer.namebox:Clear()
			inspanel.valuer.typebox:FillChoices()
		end

		if !noupd then
			npanel:Update()
		end
	end

	inspanel.valuer.typebox.FillChoices = function( self, typ )
		local typ = typ or istable( npanel.pendingTbl[npanel.valueName] ) and npanel.pendingTbl[npanel.valueName]["type"]
		if typ == nil then return end
		if npanel.structTbl.PRESETS_ENTITYLIST == true then
			local ckeys = {}
			for _, tbl in pairs( list.Get( typ ) ) do
				if !istable( tbl ) then continue end
				local cl = tbl.class or tbl.Class or tbl.ClassName
				if cl then
					ckeys[cl] = true
				end
			end
			for k in pairs( ckeys ) do
				inspanel.valuer.namebox.count = inspanel.valuer.namebox:AddChoice( k, k )
			end
		elseif PROFILE_SETS[ typ ] then
			local pkeys = GetSetsPresets( active_prof, typ )
			for k in SortedPairs( pkeys ) do
				inspanel.valuer.namebox.count = inspanel.valuer.namebox:AddChoice( k, k --[[, npanel.pendingTbl[npanel.valueName]["name"] == k ]] )
			end
		elseif t_presetspanel_misc[ typ ] then
			for k, v in SortedPairs( t_presetspanel_misc[ typ ] ) do
				inspanel.valuer.namebox.count = inspanel.valuer.namebox:AddChoice( k, v )
			end
		end
	end

	inspanel.valuer.namebox.OnSelect = function( self, text, data )
		if data == nil then return end
		local class = t_lookup["class"][npanel.lookup] and t_lookup["class"][npanel.lookup][data] or nil
		local clear
		if istable( npanel.pendingTbl[npanel.valueName] ) then
			if npanel.pendingTbl[npanel.valueName]["name"] == data then
				return
			elseif npanel.structTbl.CANCLASS and class == nil then
				clear = true
			end
		else
			npanel.pendingTbl[npanel.valueName] = {}
		end
		npanel.pendingTbl[npanel.valueName]["type"] = select( 2, inspanel.valuer.typebox:GetSelected() )
		npanel.pendingTbl[npanel.valueName]["name"] = data

		npanel:Update()

		if npanel.structTbl.REFRESHICON then
			local prof, set, prs = npanel.hierarchy[1], npanel.hierarchy[2], npanel.hierarchy[3]
			if prof == active_prof and set == active_set and prs == active_prs then
				if ValueList.infopane and IsValid( ValueList.infopane.icon ) then
					-- print( ValueList.infopane.icon )
					ValueList.infopane.icon:RefreshIcon()
				end
			elseif HasPreset( ValueEditors, prof, set, prs ) then
				local ve = HasPreset( ValueEditors, prof, set, prs )
				if ve.ValueList.infopane and IsValid( ve.ValueList.infopane.icon ) then
					ve.ValueList.infopane.icon:RefreshIcon()
				end
			end
		end
		if npanel.structTbl.REFRESHDESC then
			local prof, set, prs = npanel.hierarchy[1], npanel.hierarchy[2], npanel.hierarchy[3]
			if prof == active_prof and set == active_set and prs == active_prs then
				if ValueList.infopane and IsValid( ValueList.infopane.desc ) then
					-- print( ValueList.infopane.icon )
					ValueList.infopane.desc:RefreshDesc()
				end
			elseif HasPreset( ValueEditors, prof, set, prs ) then
				local ve = HasPreset( ValueEditors, prof, set, prs )
				if ve.ValueList.infopane and IsValid( ve.ValueList.infopane.desc ) then
					ve.ValueList.infopane.desc:RefreshDesc()
				end
			end
		end

		if clear or class != nil and inspanel.valuer.classstructed != class then
			inspanel.valuer.ClearClassStruct()
			if isfunction( inspanel.valuer.GetClassStruct ) then
				inspanel.valuer.GetClassStruct()
			end // get class values immediately
		end
	end

	if istable( npanel.pendingTbl[npanel.valueName] ) then
		if npanel.pendingTbl[npanel.valueName]["type"] then
			inspanel.valuer.typebox:FillChoices()
		end
		if npanel.pendingTbl[npanel.valueName]["name"] then
			for i=1,inspanel.valuer.namebox.count do
				if npanel.pendingTbl[npanel.valueName]["name"] == inspanel.valuer.namebox:GetOptionData( i ) then
					inspanel.valuer.namebox:ChooseOptionID( i )
					break
				end
			end
		end
	elseif inspanel.valuer.typebox:GetSelectedID() then
		inspanel.valuer.typebox:FillChoices( select( 2, inspanel.valuer.typebox:GetSelected() ) )
	end

	inspanel.valuer.OnSizeChanged = function()
		inspanel.valuer.typebox:SetWidth( npanel:GetWide() * 0.3 )
		inspanel.valuer.namebox:SetWidth( npanel:GetWide() * 0.7 )
	end

	inspanel.valuer.DoClear = function()
		inspanel.valuer.ClearClassStruct()
	end

	inspanel.valuer.DoClose = function()
		inspanel.valuer.CloseClassStruct()
	end

	inspanel.valuer.CloseClassStruct = function()
		if inspanel.valuer.classstructs then
			for i, p in pairs( inspanel.valuer.classstructs ) do
				p:Remove()
			end
			inspanel.valuer.classstructs = nil
			inspanel.valuer.classstructed = nil
		end
	end

	inspanel.valuer.ClearClassStruct = function()
		if inspanel.valuer.b_classstruct then

			inspanel.valuer.b_classstruct:SetText( UI_STR.classstruct_get )
			if istable( npanel.pendingTbl[npanel.valueName] ) and npanel.pendingTbl[npanel.valueName]["name"]
			and t_lookup["class"][npanel.lookup] and t_lookup["class"][npanel.lookup][npanel.pendingTbl[npanel.valueName]["name"]] then
				inspanel.valuer.b_classstruct:SetEnabled( true )
            inspanel.valuer.b_classstruct:SetVisible( true )
            inspanel.valuer:SetHeight( UI_TEXT_H * 2 )
			else
				inspanel.valuer.b_classstruct:SetEnabled( false )
				inspanel.valuer.b_classstruct:SetVisible( false )
            inspanel.valuer:SetHeight( UI_TEXT_H * 1 )
			end
               
         inspanel:InvalidateLayout( true )
         inspanel:SizeToChildren( false, true )
         npanel:InvalidateLayout( true )
         npanel:SizeToChildren( false, true )

			if inspanel.valuer.classstructed then
				if inspanel.valuer.classstructs then
               // clears class-specific values
               // if i want to track this change any better i should just give unique valuenames
					for i, p in pairs( inspanel.valuer.classstructs ) do
						if p.updated or !IsValid(npanel.parent.values[p.valueName]) or inspanel.valuer.preclassed then
							p.pendingTbl[p.valueName] = nil
							if IsValid(npanel.parent.values[p.valueName]) then
								npanel.parent.values[p.valueName].b_clear:OnReleased()
							end
						end
						// todo: add to queue instead (so that it will always happen after original panel created)
						if IsValid(npanel.parent.values[p.valueName]) then
							npanel.parent.values[p.valueName]:SetDisabled( false )
							npanel.parent.values[p.valueName]:ResetPanel( true, true )
						end
						p:Remove()
					end
					inspanel.valuer.classstructs = nil
				end
				inspanel.valuer.classstructed = nil
			end
		end
		npanel.viewTbl["__CLASS"] = nil
	end

	// classname struct stuff
	if npanel.structTbl.CANCLASS == true then
		inspanel.valuer.classstructed = nil
		inspanel.valuer.b_classstruct = vgui.Create( "DButton", inspanel.valuer )
		inspanel.valuer.b_classstruct:SetText( UI_STR.classstruct_get )
		-- inspanel.valuer.b_classstruct:SetTooltip( "Checks if npcd has class-specific properties for this entity class in this specific entity type. This doesn't check if the classname is valid or not." )
		inspanel.valuer.b_classstruct:Dock( TOP )

		inspanel.valuer.b_classstruct.OnReleased = function()
			inspanel.valuer.GetClassStruct()
			if !inspanel.valuer.classstructed then
				inspanel.valuer.b_classstruct:SetText( "Not available [type: " .. tostring( npanel.lookup ) .. "_class]: " .. tostring( npanel.pendingTbl[npanel.valueName] and npanel.pendingTbl[npanel.valueName]["name"] or "" ) )
				-- timer.Simple( 1.5, function()
				-- 	if inspanel and inspanel.valuer and inspanel.valuer.b_classstruct and !inspanel.valuer.classstructed then
				-- 		inspanel.valuer.b_classstruct:SetText( btxt )
				-- 	end
				-- end)
			end
		end

		inspanel.valuer.GetClassStruct = function()
			local class = npanel.pendingTbl[npanel.valueName] and npanel.pendingTbl[npanel.valueName]["name"] or nil
			inspanel.valuer.classstructs = {}
			if class == nil then return end

			inspanel.valuer.preclassed = !npanel.updated and npanel.existingTbl[npanel.valueName]
			and npanel.existingTbl[npanel.valueName]["name"] and npanel.existingTbl[npanel.valueName]["name"] == class

			// problem: viewtbl conflicts for valuenames with the same name
			// more subtle problem: valuename conflicts
			npanel.viewTbl["__CLASS"] = npanel.viewTbl["__CLASS"] or {}

			if t_lookup["class"][npanel.lookup] and t_lookup["class"][npanel.lookup][class] then
				// insert value panels into parent panel
				-- local ve = HasPreset( ValueEditors, prof, set, prs )

				local newstruct_req = {}
				local newstruct_other = {}

				for valueName, valueTbl in pairs( t_lookup["class"][npanel.lookup][class] ) do
					if valueTbl.TYPE == "data" or valueTbl.TYPE == "info" then continue end

					if valueTbl.REQUIRED or valueTbl.CATEGORY == t_CAT.REQUIRED then
						newstruct_req[valueName] = ( valueTbl.SORTNAME
						or valueTbl.REQUIRED and "*"..( valueTbl.CATEGORY != t_CAT.DEFAULT and valueTbl.CATEGORY or "zzz" )
						or valueTbl.CATEGORY and valueTbl.CATEGORY != t_CAT.DEFAULT and valueTbl.CATEGORY
						or "zzz" )
						.. string.lower( valueTbl.NAME or valueName )
					else
						newstruct_other[valueName] = ( valueTbl.SORTNAME or valueTbl.CATEGORY and valueTbl.CATEGORY != t_CAT.DEFAULT and valueTbl.CATEGORY or "zzz" ) .. string.lower( valueTbl.NAME or valueName )
					end
				end
				
            local vcount = 0
				for _, structlist in ipairs( { newstruct_req, newstruct_other } ) do
					for valueName in SortedPairsByValue( structlist ) do
						local vn = valueName
						local valueTbl = t_lookup["class"][npanel.lookup][class][valueName]
						
						// todo: add this to the queue instead of timer
						timer.Simple( 2, function() // not even gonna bother tracking "when" the other panel is finally created in the queue
							if inspanel.valuer and inspanel.valuer.classstructs and inspanel.valuer.classstructs[vn]
							and IsValid(npanel) and IsValid(npanel.parent) and IsValid(npanel.parent.values[vn]) then
								npanel.parent.values[vn]:SetDisabled( true )
							end
						end )

						-- table.insert( inspanel.valuer.classstructs,
						inspanel.valuer.classstructs[valueName] =
							AddValuePanel(
								npanel.parent, // assuming top level preset panel, so parent is category dform // todo: npanel.parent.list[t_CAT.CLASS]
								valueTbl, 
								nil,
								valueName, //npanel.valueName
								npanel.existingTbl, //existingTbl
								npanel.pendingTbl, //pendingTbl
								npanel.viewTbl["__CLASS"],
								npanel.lookup,
								npanel.hierarchy,
								npanel.col,
								"<"..class..">"
							)
						-- )
                  vcount = vcount + 1
						
						inspanel.valuer.classstructed = class
					end
				end

				if inspanel.valuer.classstructed then
					inspanel.valuer.b_classstruct:SetText( class..": "..tostring(vcount).." "..UI_STR.classstruct_in )
					inspanel.valuer.b_classstruct:SetEnabled( false )
				end
			end
		end

		inspanel.valuer.b_classstruct:SetHeight( UI_TEXT_H )
		inspanel.valuer:SetHeight( UI_TEXT_H * 2 )
      
		if istable( npanel.pendingTbl[npanel.valueName] ) and npanel.pendingTbl[npanel.valueName]["name"]
		and t_lookup["class"][npanel.lookup] and t_lookup["class"][npanel.lookup][npanel.pendingTbl[npanel.valueName]["name"]] then
			inspanel.valuer.b_classstruct:SetEnabled( true )
			inspanel.valuer.b_classstruct:SetVisible( true )
         inspanel.valuer:SetHeight( UI_TEXT_H * 2 )
		else
			inspanel.valuer.b_classstruct:SetEnabled( false )
			inspanel.valuer.b_classstruct:SetVisible( false )
         inspanel.valuer:SetHeight( UI_TEXT_H * 1 )
		end

		inspanel.valuer.GetClassStruct()

		
	end

	inspanel:InvalidateLayout( true )
	inspanel:SizeToChildren( false, true )
	npanel:InvalidateLayout( true )
	npanel:SizeToChildren( false, true )
end

function AddAnglePanel( npanel, inspanel )
	inspanel.valuer = vgui.Create( "Panel", inspanel )
	-- inspanel.valuer:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	inspanel.valuer:Dock( TOP )

	inspanel.valuer:DockMargin( marg, 0, 0, 0)

	inspanel.valuer.slider_p = vgui.Create( "DNumSlider", inspanel.valuer )
	inspanel.valuer.slider_p:SetDark( true )
	inspanel.valuer.slider_p:SetText( "<pitch>" )
	inspanel.valuer.slider_p:SetHeight( UI_TEXT_H * 1.25 )
	inspanel.valuer.slider_p:SetMinMax( -180, 180 )
	inspanel.valuer.slider_y = vgui.Create( "DNumSlider", inspanel.valuer )
	inspanel.valuer.slider_y:SetDark( true )
	inspanel.valuer.slider_y:SetText( "<yaw>" )
	inspanel.valuer.slider_y:SetHeight( UI_TEXT_H * 1.25 )
	inspanel.valuer.slider_y:SetMinMax( -180, 180 )
	inspanel.valuer.slider_r = vgui.Create( "DNumSlider", inspanel.valuer )
	inspanel.valuer.slider_r:SetDark( true )
	inspanel.valuer.slider_r:SetText( "<roll>" )
	inspanel.valuer.slider_r:SetHeight( UI_TEXT_H * 1.25 )
	inspanel.valuer.slider_r:SetMinMax( -180, 180 )

	inspanel.valuer.slider_p:SizeToContentsY( 5 )
	inspanel.valuer.slider_y:SizeToContentsY( 5 )
	inspanel.valuer.slider_r:SizeToContentsY( 5 )

	inspanel.valuer.slider_p:Dock( TOP )
	inspanel.valuer.slider_y:Dock( TOP )
	inspanel.valuer.slider_r:Dock( TOP )

	if isvector( npanel.structTbl.DEFAULT ) then
		inspanel.valuer.slider_p:SetDefaultValue( npanel.structTbl.DEFAULT.p )
		inspanel.valuer.slider_y:SetDefaultValue( npanel.structTbl.DEFAULT.y )
		inspanel.valuer.slider_r:SetDefaultValue( npanel.structTbl.DEFAULT.r )
	else
		inspanel.valuer.slider_p:SetDefaultValue( 0 )
		inspanel.valuer.slider_y:SetDefaultValue( 0 )
		inspanel.valuer.slider_r:SetDefaultValue( 0 )
	end

	if isangle( npanel.pendingTbl[npanel.valueName] ) then
		inspanel.valuer.slider_p:SetValue( npanel.pendingTbl[npanel.valueName].p )
		inspanel.valuer.slider_y:SetValue( npanel.pendingTbl[npanel.valueName].y )
		inspanel.valuer.slider_r:SetValue( npanel.pendingTbl[npanel.valueName].r )
	-- elseif isangle( npanel.structTbl.DEFAULT ) then
	-- 	inspanel.valuer.slider_p:SetValue( npanel.structTbl.DEFAULT.p )
	-- 	inspanel.valuer.slider_y:SetValue( npanel.structTbl.DEFAULT.y )
	-- 	inspanel.valuer.slider_r:SetValue( npanel.structTbl.DEFAULT.r )
	else
		inspanel.valuer.slider_p:SetValue( inspanel.valuer.slider_p:GetDefaultValue() )
		inspanel.valuer.slider_y:SetValue( inspanel.valuer.slider_y:GetDefaultValue() )
		inspanel.valuer.slider_r:SetValue( inspanel.valuer.slider_r:GetDefaultValue() )
	end

	inspanel.valuer.slider_p.OnValueChanged = function( panel, val )
		npanel.pendingTbl[npanel.valueName] = npanel.pendingTbl[npanel.valueName] or Angle()
		-- npanel.pendingTbl[npanel.valueName].p = val // bug: changes existingTbl's Angle
		npanel.pendingTbl[npanel.valueName] = Angle( val, npanel.pendingTbl[npanel.valueName].y, npanel.pendingTbl[npanel.valueName].r )

		npanel:Update()
	end
	inspanel.valuer.slider_y.OnValueChanged = function( panel, val )
		npanel.pendingTbl[npanel.valueName] = npanel.pendingTbl[npanel.valueName] or Angle()
		-- npanel.pendingTbl[npanel.valueName].y = val
		npanel.pendingTbl[npanel.valueName] = Angle( npanel.pendingTbl[npanel.valueName].p, val, npanel.pendingTbl[npanel.valueName].r )
		
		npanel:Update()
	end
	inspanel.valuer.slider_r.OnValueChanged = function( panel, val )
		npanel.pendingTbl[npanel.valueName] = npanel.pendingTbl[npanel.valueName] or Angle()
		-- npanel.pendingTbl[npanel.valueName].r = val
		npanel.pendingTbl[npanel.valueName] = Angle( npanel.pendingTbl[npanel.valueName].p, npanel.pendingTbl[npanel.valueName].y, val )

		npanel:Update()
	end

	inspanel.valuer:SetHeight( inspanel.valuer.slider_p:GetTall() * 3 )
	inspanel.valuer:InvalidateLayout( true )
end

function AddVectorPanel( npanel, inspanel )
	inspanel.valuer = vgui.Create( "Panel", inspanel )
	-- inspanel.valuer:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	inspanel.valuer:Dock( TOP )

	inspanel.valuer:DockMargin( marg, 0, 0, 0)

	inspanel.valuer.slider_x = vgui.Create( "DNumSlider", inspanel.valuer )
	inspanel.valuer.slider_x:SetDark( true )
	inspanel.valuer.slider_x:SetText( "<x>" )
	inspanel.valuer.slider_x:SetHeight( UI_TEXT_H * 1.25 )
	inspanel.valuer.slider_x:SetMinMax( -16384, 16384 )
	inspanel.valuer.slider_y = vgui.Create( "DNumSlider", inspanel.valuer )
	inspanel.valuer.slider_y:SetDark( true )
	inspanel.valuer.slider_y:SetText( "<y>" )
	inspanel.valuer.slider_y:SetHeight( UI_TEXT_H * 1.25 )
	inspanel.valuer.slider_y:SetMinMax( -16384, 16384 )
	inspanel.valuer.slider_z = vgui.Create( "DNumSlider", inspanel.valuer )
	inspanel.valuer.slider_z:SetDark( true )
	inspanel.valuer.slider_z:SetText( "<z>" )
	inspanel.valuer.slider_z:SetHeight( UI_TEXT_H * 1.25 )
	inspanel.valuer.slider_z:SetMinMax( -16384, 16384 )

	inspanel.valuer.slider_x:SizeToContentsY( 5 )
	inspanel.valuer.slider_y:SizeToContentsY( 5 )
	inspanel.valuer.slider_z:SizeToContentsY( 5 )

	inspanel.valuer.slider_x:Dock( TOP )
	inspanel.valuer.slider_y:Dock( TOP )
	inspanel.valuer.slider_z:Dock( TOP )

	if isvector( npanel.structTbl.DEFAULT ) then
		inspanel.valuer.slider_x:SetDefaultValue( npanel.structTbl.DEFAULT.x )
		inspanel.valuer.slider_y:SetDefaultValue( npanel.structTbl.DEFAULT.y )
		inspanel.valuer.slider_z:SetDefaultValue( npanel.structTbl.DEFAULT.z )
	else
		inspanel.valuer.slider_x:SetDefaultValue( 0 )
		inspanel.valuer.slider_y:SetDefaultValue( 0 )
		inspanel.valuer.slider_z:SetDefaultValue( 0 )
	end

	if isvector( npanel.pendingTbl[npanel.valueName] ) then
		inspanel.valuer.slider_x:SetValue( npanel.pendingTbl[npanel.valueName].x )
		inspanel.valuer.slider_y:SetValue( npanel.pendingTbl[npanel.valueName].y )
		inspanel.valuer.slider_z:SetValue( npanel.pendingTbl[npanel.valueName].z )
	elseif isvector( npanel.structTbl.DEFAULT ) then
		inspanel.valuer.slider_x:SetValue( npanel.structTbl.DEFAULT.x )
		inspanel.valuer.slider_y:SetValue( npanel.structTbl.DEFAULT.y )
		inspanel.valuer.slider_z:SetValue( npanel.structTbl.DEFAULT.z )
	else
		inspanel.valuer.slider_x:SetValue( inspanel.valuer.slider_x:GetDefaultValue() )
		inspanel.valuer.slider_y:SetValue( inspanel.valuer.slider_y:GetDefaultValue() )
		inspanel.valuer.slider_z:SetValue( inspanel.valuer.slider_z:GetDefaultValue() )
	end

	-- inspanel.valuer.wanger_x.OnValueChanged = function( panel, val )
	inspanel.valuer.slider_x.OnValueChanged = function( panel, val )
		npanel.pendingTbl[npanel.valueName] = npanel.pendingTbl[npanel.valueName] or Vector()
		-- npanel.pendingTbl[npanel.valueName].x = val // bug: changes existingTbl
		npanel.pendingTbl[npanel.valueName] = Vector( val, npanel.pendingTbl[npanel.valueName].y, npanel.pendingTbl[npanel.valueName].z )

		npanel:Update()
	end
	inspanel.valuer.slider_y.OnValueChanged = function( panel, val )
		npanel.pendingTbl[npanel.valueName] = npanel.pendingTbl[npanel.valueName] or Vector()
		-- npanel.pendingTbl[npanel.valueName].y = val
		npanel.pendingTbl[npanel.valueName] = Vector( npanel.pendingTbl[npanel.valueName].x, val, npanel.pendingTbl[npanel.valueName].z )
		npanel:Update()
	end
	inspanel.valuer.slider_z.OnValueChanged = function( panel, val )
		npanel.pendingTbl[npanel.valueName] = npanel.pendingTbl[npanel.valueName] or Vector()
		-- npanel.pendingTbl[npanel.valueName].z = val
		npanel.pendingTbl[npanel.valueName] = Vector( npanel.pendingTbl[npanel.valueName].x, npanel.pendingTbl[npanel.valueName].y, val )
		npanel:Update()
	end

	-- inspanel.valuer:SetHeight( UI_ENTRY_H )
	inspanel.valuer:InvalidateLayout( true )
	inspanel.valuer:SetHeight( inspanel.valuer.slider_x:GetTall() * 3 )
end


function AddColorPanel( npanel, inspanel )
	inspanel.valuer = vgui.Create( "Panel", inspanel )
	-- inspanel.valuer:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	inspanel.valuer:Dock( TOP )

	inspanel.valuer:DockMargin( marg, 0, marg, 0)

	inspanel.valuer.colorbox = vgui.Create( "DColorMixer", inspanel.valuer )

	inspanel.valuer.colorbox:Dock( TOP )
	inspanel.valuer.colorbox:SetHeight( UI_ENTRY_H * 8 )
	inspanel.valuer.colorbox:SetWangs( true )
	inspanel.valuer.colorbox:SetPalette( true )
	if npanel.structTbl.COLORALPHA == false then
		inspanel.valuer.colorbox:SetAlphaBar( false )
	else
		inspanel.valuer.colorbox:SetAlphaBar( true )
	end

	if IsColor( npanel.pendingTbl[npanel.valueName] ) then
		inspanel.valuer.colorbox:SetColor( npanel.pendingTbl[npanel.valueName] )
	elseif IsColor( npanel.structTbl.DEFAULT ) then
		inspanel.valuer.colorbox:SetColor( CopyData( npanel.structTbl.DEFAULT ) )
	else
		inspanel.valuer.colorbox:SetColor( CopyData( color_white ) )
	end

	inspanel.valuer.colorbox.ValueChanged = function( self, col )
		npanel.pendingTbl[npanel.valueName] = Color( col.r, col.g, col.b, npanel.structTbl.COLORALPHA != false and col.a or nil )
		npanel:Update()
	end

	inspanel.valuer:SizeToChildren( false, true )
end


// shamelessly taken from pac3
function get_unlit_mat(path)
	-- if path:find("%.png$") then
	if path:match("materials/(.+)") then
		return Material(path:match("materials/(.+)"))
	elseif path:match("(.+)%.vmt") then
		local tex = Material(path:match("(.+)%.vmt")):GetTexture("$basetexture")
		if tex then
			local mat = CreateMaterial(path .. "_asset_browser", "UnlitGeneric")
			mat:SetTexture("$basetexture", tex)
			return mat
		end
	end

	return CreateMaterial(path .. "_asset_browser", "UnlitGeneric", {["$basetexture"] = path:match("(.+)%.vtf")})
end
function setup_paint(panel, generate_cb, draw_cb)
	local old = panel.Paint
	panel.Paint = function(self,w,h)
		if not self.setup_material then
			generate_cb(self)
			self.setup_material = true
		end

		draw_cb(self, w, h)
	end
end
function create_texture_icon( path, parent )
	local icon = vgui.Create("DButton", parent)
	icon:SetTooltip(path)
	if parent then
		local squaremax = math.min( parent:GetWide(), parent:GetTall() )
		icon:SetSize( squaremax, squaremax )
		icon:SetPos( 0+(parent:GetWide()-squaremax)/2, 0+(parent:GetTall()-squaremax)/2 )
	else
		icon:SetSize(128,128)
	end
	icon:SetWrap(true)
	icon:SetText("")

	setup_paint(
		icon,
		function(self)
			self.mat = get_unlit_mat(path)
			self.realwidth = self.mat:Width()
			self.realheight = self.mat:Height()
		end,
		function(self, W, H)
			if self.mat then
				local w = math.min(W, self.realwidth)
				local h = math.min(H, self.realheight)

				surface.SetDrawColor(255,255,255,255)
				surface.SetMaterial(self.mat)
				surface.DrawTexturedRect(W/2 - w/2, H/2 - h/2, w, h)
			end
		end
	)

	return icon
end
function create_material_icon( path, parent )
	local mat_path = path:match("materials/(.+)%.vmt")
	-- print( "matpat", mat_path )

	local icon = vgui.Create("DButton", parent)
	icon:SetTooltip(path)
	if parent then
		local squaremax = math.min( parent:GetWide(), parent:GetTall() )
		icon:SetSize( squaremax, squaremax )
		icon:SetPos( 0+(parent:GetWide()-squaremax)/2, 0+(parent:GetTall()-squaremax)/2 )
	else
		icon:SetSize(128,128)
	end
	icon:SetWrap(true)
	icon:SetText("")

	setup_paint(
		icon,
		function(self)
			self:SetupMaterial()
		end,
		function(self, w, h)
			surface.SetDrawColor(0,0,0,240)
			surface.DrawRect(0,0,w,h)
		end
	)

	function icon:SetupMaterial()
		local mat = Material(mat_path)
		local shader = mat:GetShader():lower()

		local pnl
		if shader == "lightmappedgeneric" or shader == "spritecard" then
			pnl = vgui.Create("DPanel", icon)
			pnl:SetMouseInputEnabled(false)
			pnl:Dock(FILL)

			local mat = get_unlit_mat(path)

			pnl.Paint = function(self,w,h)
				surface.SetDrawColor(255,255,255,255)
				surface.SetMaterial(mat)
				surface.DrawTexturedRect(0,0,w,h)
			end

		else
			pnl = vgui.Create("DImage", icon)
			pnl:SetMouseInputEnabled(false)
			pnl:Dock(FILL)
			pnl:SetImage(mat_path)
		end
	end
	
	return icon
end
////

local searches = {
	["models"] = {
		path = "GAME",
		base =  "models",
		-- name = "Models",
		filetypes = "*.mdl",
		modelview = true,
		preview = function( viewer, path )
			viewer:SetModel( path )
			local mn, mx = viewer:GetEntity():GetRenderBounds()
			local size = 0
			size = math.max( size, math.abs(mn.x) + math.abs(mx.x) )
			size = math.max( size, math.abs(mn.y) + math.abs(mx.y) )
			size = math.max( size, math.abs(mn.z) + math.abs(mx.z) )

			viewer:SetFOV( 45 )
			viewer:SetCamPos( Vector( size, size, size ) )
			viewer:SetLookAt( (mn + mx) * 0.5 )
		end,
	},
	["materials"] = {
		path = "GAME",
		base =  "materials",
		-- name = "Materials",
		filetypes = "*.vmt",
		gsub_pattern = "^materials/",
		gsub_replace = "",
		matview = true,
		preview = function( viewer, path )
			if viewer.icon then viewer.icon:Remove() end
			viewer.icon = path:match("materials/(.+)%.vmt") and create_material_icon( path, viewer ) or create_texture_icon( path, viewer )
		-- 	viewer:SetMaterial( Material( path ) )
		end,
	},
	["images"] = {
		path = "GAME",
		base =  "materials",
		filetypes = "*.vmt *.png *.gif *.jpg",
		-- filetypes = "*.png",
		gsub_pattern = "^materials/",
		gsub_replace = "",
		-- manual = true,
		matview = true,
		preview = function( viewer, path )
			if viewer.icon then viewer.icon:Remove() end
			viewer.icon = path:match("materials/(.+)%.vmt") and create_material_icon( path, viewer ) or create_texture_icon( path, viewer )
			
			-- local name = path
			-- local mat = Material( name )

			-- -- Look for the old style material
			-- if ( !mat || mat:IsError() ) then

			-- 	name = name:Replace( "entities/", "VGUI/entities/" )
			-- 	name = name:Replace( ".png", "" )
			-- 	mat = Material( name )

			-- end

			-- -- Couldn't find any material.. just return
			-- if ( !mat || mat:IsError() ) then
			-- 	return
			-- end

			-- viewer:SetMaterial( mat )
		end,
	},
	["textures"] = {
		path = "GAME",
		base =  "materials",
		-- name = "Textures",
		filetypes = "*.vtf",
		gsub_pattern = "^materials/",
		gsub_replace = "",
		matview = true,
		preview = function( viewer, path )
			if viewer.icon then viewer.icon:Remove() end
			viewer.icon = path:match("materials/(.+)%.vmt") and create_material_icon( path, viewer ) or create_texture_icon( path, viewer )
		-- 	local name = path
		-- 	local mat = Material( name )

		-- 	-- Look for the old style material
		-- 	if ( !mat || mat:IsError() ) then

		-- 		name = name:Replace( "entities/", "VGUI/entities/" )
		-- 		name = name:Replace( ".png", "" )
		-- 		mat = Material( name )

		-- 	end

		-- 	-- Couldn't find any material.. just return
		-- 	-- if ( !mat || mat:IsError() ) then
		-- 	-- 	return
		-- 	-- end

		-- 	viewer:SetMaterial( mat )
		end,
	},
	["sounds"] = {
		path = "GAME",
		base =  "sound",
		-- name = "Sounds",
		-- filetypes = "*.vtf",
	},
	["default"] = {
		path = "GAME",
		-- name = "File Browser",
	},
}

function AssetBrowserBasic( stype, submitFunc, npanel, parent )
	local search_t = searches[stype] or searches.default 
	local frame = vgui.Create( "DFrame" ) --, parent or SettingsWindow )
	frame:SetSize( math.min( ScrW(), 800), 400 )
	frame:SetSizable( true )
	frame:MakePopup()
	frame:Center()
	frame:SetTitle( "File Browser (WIP)" )

	-- if search_t.manual then
	-- 	local tree = vgui.Create( "DTree", frame )
	-- 	tree:Dock( FILL )
	-- 	local root = tree:AddNode( "materials" )
	-- 	root:SetExpanded( true )
	-- 	local display = vgui.Create( "DIconLayout", frame )
	-- 	display:Dock( RIGHT )
	-- 	display:SetWide( 500 )
	-- 	local function rsearch( dir, d )
	-- 		local d = d or 0
	-- 		if d > 1 then return false end
	-- 		local found
	-- 		local files, folders = file.Find( dir.."/*", "GAME" )
	-- 		-- if !table.IsEmpty( folders ) then return true end
	-- 		for _, f in ipairs( folders ) do
	-- 			found = rsearch( dir.."/"..f, d+1 )
	-- 			if found then return found end
	-- 		end
	-- 		for _, f in ipairs( files ) do
	-- 			if string.find( f, "%.png$" ) then
	-- 				return true
	-- 			end
	-- 		end
	-- 		-- print(dir.."no found")
	-- 		return false
	-- 	end

	-- 	-- local filelist, folderlist = {}, {}
	-- 	-- rsearch( filelist, folderlist, "materials" )
	-- 	local files, folders = file.Find( "materials/*", "GAME" )
	-- 	for k, f in pairs( folders ) do
	-- 		if !rsearch( "materials/"..f ) then
	-- 			folders[k] = nil
	-- 		else
	-- 			-- local node = tree:AddNode( f )
	-- 			root:AddFolder( f, "materials/"..f, "GAME" )
	-- 		end
	-- 	end
	-- 	function tree:OnNodeSelected( node )
	-- 		for _, c in ipairs( node:GetChildNodes() ) do
	-- 			print( c:GetFileName() )
	-- 		end
	-- 		print( node:GetParentNode() )
	-- 		-- local dir = node:Node
	-- 		-- local point = node
	-- 		-- while point:GetParentNode() do
	-- 		-- 	dir = dir..tostring( point:GetParentNode():GetFileName() )
	-- 		-- 	point = point:GetParentNode()
	-- 		-- end
	-- 		-- print( dir )
	-- 	end
	-- else
		local split = vgui.Create( "DHorizontalDivider", frame )
		split:Dock( FILL )

		local browser = vgui.Create( "DFileBrowser", frame )

		split:SetLeft( browser )
		split:SetLeftWidth( frame:GetWide() )
		split:SetRightMin( 0 )
		split:SetLeftMin( 0 )

		if search_t.path then browser:SetPath( search_t.path ) end -- The access path i.e. GAME, LUA, DATA etc.
		if search_t.base then browser:SetBaseFolder( search_t.base ) end -- The root folder
		if search_t.name then browser:SetName( search_t.name ) end -- Name to display in tree
		if search_t.filetypes then
			browser:SetFileTypes( search_t.filetypes )
		end
		browser:SetOpen( true ) -- Opens the tree (same as double clicking)

		local viewer
		if search_t.modelview then
			browser:SetModels( true )
			-- frame:SetSize( math.min( ScrW(), 800), 400 )
			viewer = vgui.Create( "DModelPanel", frame )
			-- viewer:Dock( FILL )
			-- viewer:SetWide( 300 )
			split:SetRight( viewer )
			split:SetLeftWidth( 550 )
			timer.Simple( engine.TickInterval(), function()
				
				-- viewer:SetLookAt( Vector( 0, 0, 0 ) )
				local prstbl = npanel and GetPendingTbl( npanel.hierarchy[1], npanel.hierarchy[2], npanel.hierarchy[3] )
				local model = prstbl and isstring( prstbl.model ) and prstbl.model or nil --"" or "models/props_borealis/bluebarrel001.mdl"
				-- util.PrecacheModel( model )
				-- viewer:SetEntity( ClientsideModel( model, RENDERGROUP_BOTH ) )
				-- viewer:SetEntity( Entity(6) )
				if model then
					viewer:SetModel( model )
					
						local mn, mx = viewer:GetEntity():GetRenderBounds()
						local size = 0
						size = math.max( size, math.abs(mn.x) + math.abs(mx.x) )
						size = math.max( size, math.abs(mn.y) + math.abs(mx.y) )
						size = math.max( size, math.abs(mn.z) + math.abs(mx.z) )

						viewer:SetFOV( 45 )
						viewer:SetCamPos( Vector( size, size, size ) )
						viewer:SetLookAt( (mn + mx) * 0.5 )
						viewer:DrawModel()
				end
			end )

			-- viewer:SetCamPos(headpos-Vector( -wide, 0, 0))	-- Move cam in front of face
			-- function viewer:LayoutEntity( ent ) return end
		elseif search_t.matview then
			-- viewer = vgui.Create( "Panel", frame )
			viewer = vgui.Create( "DImage", frame )
			-- viewer = vgui.Create( "DSprite", frame )
			split:SetRight( viewer )
			viewer:SetKeepAspect( true )
			split:SetLeftWidth( 550 )
			-- function viewer:AnimationThink()
			-- 	self:SetTall( split:GetWide() - split:GetLeftWidth() )
			-- end
			function viewer:Paint( w, h )
				if !self.icon then return end
				local squaremax = math.min( viewer:GetWide(), viewer:GetTall() )
				self.icon:SetSize( squaremax, squaremax )
				self.icon:SetPos( 0+(w-squaremax)/2, 0+(h-squaremax)/2 )
			-- 	local m = viewer:GetMaterial()
			-- 	if m then
			-- 		local wratio = m:Width() / m:Height()
			-- 		local hratio = m:Height() / m:Width()
					-- local squaremax = math.min( viewer:GetWide(), viewer:GetTall() )
			-- 		surface.SetDrawColor( 255,255,255,255 )
			-- 		surface.SetMaterial( m )
			-- 		surface.DrawTexturedRect( 0+(w-squaremax)/2, 0+(h-squaremax*hratio)/2, squaremax, squaremax * hratio )
			-- 	end
			end
		end

		function browser:OnSelect( path, pnl )
			if viewer and isfunction( search_t.preview ) then
				search_t.preview( viewer, path )			
			end
		end
		function browser:OnRightClick( path, pnl )
			browser:OnDoubleClick( path, pnl )
			// problem: menu shows up at 0,0 screenpos and is "below" frame??
			-- local menu = DermaMenu()
			-- menu:SetPos( pnl:LocalToScreen() )
			-- menu:AddOption( "Choose \""..path.."\"", function() browser:OnDoubleClick( path, pnl ) end )
			-- menu:AddOption( "#spawnmenu.menu.copy", function()
			-- 	SetClipboardText( path )
			-- end )
		end
		function browser:OnDoubleClick( path, pnl )
			if search_t.modelview then viewer:SetEntity( nil ) end
			if isfunction( submitFunc ) then
				local p = path
				if search_t.gsub_pattern then
					p = string.gsub( path, search_t.gsub_pattern, search_t.gsub_replace )
				end
				submitFunc( p )
			end
			frame:Close()
		end
	-- end

	return frame
end

function AddStringPanel( npanel, inspanel, focus )
	inspanel.valuer = vgui.Create( "Panel", inspanel )
	-- inspanel.valuer:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	inspanel.valuer:Dock( TOP )

	inspanel.valuer.textbox = vgui.Create( "DTextEntry", inspanel.valuer )
	inspanel.valuer.textbox:SetHeight( UI_TEXT_H )
	inspanel.valuer:SetHeight( UI_TEXT_H )

	if isstring( npanel.structTbl.DEFAULT ) then
		inspanel.valuer.textbox:SetPlaceholderText( npanel.structTbl.DEFAULT )
	end

	inspanel.valuer.textbox.OnChange = function( self )
		npanel.pendingTbl[npanel.valueName] = inspanel.valuer.textbox:GetValue()
		inspanel.valuer.ClearClassStruct()

		if npanel.structTbl.REFRESHDESC then
			local prof, set, prs = npanel.hierarchy[1], npanel.hierarchy[2], npanel.hierarchy[3]
			local ve = HasPreset( ValueEditors, prof, set, prs )
			if ve then
				if ve.ValueList.infopane and IsValid( ve.ValueList.infopane.desc ) then
					ve.ValueList.infopane.desc:RefreshDesc()
				end
			elseif prof == active_prof and set == active_set and prs == active_prs
			and IsValid(ValueList) and ValueList.infopane and IsValid( ValueList.infopane.desc ) then
				-- print( ValueList.infopane.icon )
				ValueList.infopane.desc:RefreshDesc()
			end
		end

		npanel:Update()
	end

	inspanel.valuer.textbox:SetText( npanel.pendingTbl[npanel.valueName] != nil and tostring( npanel.pendingTbl[npanel.valueName] ) or isstring( npanel.structTbl.DEFAULT ) and npanel.structTbl.DEFAULT or "" )

	if focus then inspanel.valuer.textbox:RequestFocus() end

	inspanel.valuer.DoClear = function()
		inspanel.valuer.ClearClassStruct()
	end

	inspanel.valuer.ClearClassStruct = function()
		if inspanel.valuer.b_classstruct then
		
			inspanel.valuer.b_classstruct:SetText( UI_STR.classstruct_get )
			if t_lookup["class"][npanel.lookup] and t_lookup["class"][npanel.lookup][npanel.pendingTbl[npanel.valueName]] then
				inspanel.valuer.b_classstruct:SetEnabled( true )
			else
				inspanel.valuer.b_classstruct:SetEnabled( false )
			end
			
			if inspanel.valuer.classstructed then
				if inspanel.valuer.classstructs then
					for i, p in pairs( inspanel.valuer.classstructs ) do
						if p.updated or !IsValid(npanel.parent.values[p.valueName]) or inspanel.valuer.preclassed then
							p.pendingTbl[p.valueName] = nil
							if IsValid(npanel.parent.values[p.valueName]) then
								npanel.parent.values[p.valueName].b_clear:OnReleased()
							end
						end
						if IsValid(npanel.parent.values[p.valueName]) then
							npanel.parent.values[p.valueName]:SetDisabled( false )
							npanel.parent.values[p.valueName]:ResetPanel( true, true )
						end
						p:Remove()
					end
					inspanel.valuer.classstructs = nil
				end
				inspanel.valuer.classstructed = nil
			end
		end
		npanel.viewTbl["__CLASS"] = nil
	end

	if npanel.structTbl.ASSET then
		inspanel.valuer.b_assetbrowse = vgui.Create( "DButton", inspanel.valuer )
		inspanel.valuer.b_assetbrowse:SetText( "Browse Assets" )
		inspanel.valuer.b_assetbrowse:Dock( BOTTOM )
		inspanel.valuer.b_assetbrowse:SetTall( UI_TEXT_H )
		inspanel.valuer.b_assetbrowse.OnReleased = function()
			inspanel.valuer.browser = AssetBrowserBasic( npanel.structTbl.ASSET, function( path )
				if IsValid( inspanel.valuer ) then
					inspanel.valuer.textbox:SetEnabled( true )
					inspanel.valuer.textbox:SetValue( path )
					inspanel.valuer.textbox:OnChange()
					inspanel.valuer.b_assetbrowse:SetEnabled( true )
				end
			end, npanel )
			inspanel.valuer.b_assetbrowse:SetEnabled( false )
			inspanel.valuer.textbox:SetEnabled( false )

			inspanel.valuer.browser.OnClose = function()
				inspanel.valuer.textbox:SetEnabled( true )
				inspanel.valuer.b_assetbrowse:SetEnabled( true )
			end
		end
		-- inspanel.valuer.SetAsset = function( self, path )
		-- 	inspanel.valuer.textbox:SetEnabled( true )
		-- 	inspanel.valuer.textbox:SetValue( path )
		-- 	inspanel.valuer.textbox:OnChange()
		-- 	inspanel.valuer.b_assetbrowse:SetEnabled( true )
		-- end
		inspanel.valuer:SetHeight( inspanel.valuer.textbox:GetTall() + UI_TEXT_H )
	end

	// classname struct stuff
	if npanel.structTbl.CANCLASS == true then
		inspanel.valuer.textbox:Dock( TOP )
		inspanel.valuer.textbox:SetZPos( 1 )
		inspanel.valuer.classstructed = nil
		inspanel.valuer.b_classstruct = vgui.Create( "DButton", inspanel.valuer )
		inspanel.valuer.b_classstruct:SetText( UI_STR.classstruct_get )
		-- inspanel.valuer.b_classstruct:SetTooltip( "Checks if npcd has class-specific properties for this entity class in this specific entity type. This doesn't check if the classname is valid or not." )
		inspanel.valuer.b_classstruct:Dock( TOP )
		inspanel.valuer.b_classstruct:SetZPos( 2 )
		inspanel.valuer.b_classstruct:SetTall( UI_TEXT_H )

		if npanel.pendingTbl[npanel.valueName] and t_lookup["class"][npanel.lookup] and t_lookup["class"][npanel.lookup][npanel.pendingTbl[npanel.valueName]] then
			inspanel.valuer.b_classstruct:SetEnabled( true )
			inspanel.valuer.b_classstruct:SetVisible( true )
		else
			inspanel.valuer.b_classstruct:SetEnabled( false )
			-- inspanel.valuer.b_classstruct:SetVisible( false )
		end

		local oldthink = inspanel.valuer.textbox.OnChange
		inspanel.valuer.textbox.OnChange = function( ... )
			oldthink( ... )
			if npanel.pendingTbl[npanel.valueName] and t_lookup["class"][npanel.lookup] and t_lookup["class"][npanel.lookup][npanel.pendingTbl[npanel.valueName]] then
				inspanel.valuer.b_classstruct:SetEnabled( true )
				inspanel.valuer.b_classstruct:SetVisible( true )
			else
				inspanel.valuer.b_classstruct:SetEnabled( false )
				-- inspanel.valuer.b_classstruct:SetVisible( false )
			end
		end

		inspanel.valuer.b_classstruct.OnReleased = function()
			inspanel.valuer.GetClassStruct()
			if !inspanel.valuer.classstructed then
				inspanel.valuer.b_classstruct:SetText( "Not available [type: " .. tostring( npanel.lookup ) .. "_class]: " .. inspanel.valuer.textbox:GetValue() )
				-- timer.Simple( 1.5, function()
				-- 	if inspanel and inspanel.valuer and inspanel.valuer.b_classstruct and !inspanel.valuer.classstructed then
				-- 		inspanel.valuer.b_classstruct:SetText( btxt )
				-- 	end
				-- end)
			end
		end

		inspanel.valuer.GetClassStruct = function()
			local class = inspanel.valuer.textbox:GetValue()
			inspanel.valuer.classstructs = {}

			inspanel.valuer.preclassed = !npanel.updated and npanel.existingTbl[npanel.valueName]
			and npanel.existingTbl[npanel.valueName]["name"] and npanel.existingTbl[npanel.valueName]["name"] == class

			if class == nil then return end
			if t_lookup["class"][npanel.lookup] and t_lookup["class"][npanel.lookup][class] then
				npanel.viewTbl["__CLASS"] = npanel.viewTbl["__CLASS"] or {}
				
				local newstruct_req = {}
				local newstruct_other = {}

				for valueName, valueTbl in pairs( t_lookup["class"][npanel.lookup][class] ) do
					if valueTbl.TYPE == "data" or valueTbl.TYPE == "info" then continue end

					if valueTbl.REQUIRED or valueTbl.CATEGORY == t_CAT.REQUIRED then
						newstruct_req[valueName] = ( valueTbl.SORTNAME
						or valueTbl.REQUIRED and "*"..( valueTbl.CATEGORY != t_CAT.DEFAULT and valueTbl.CATEGORY or "zzz" )
						or valueTbl.CATEGORY and valueTbl.CATEGORY != t_CAT.DEFAULT and valueTbl.CATEGORY
						or "zzz" )
						.. string.lower( valueTbl.NAME or valueName )
					else
						newstruct_other[valueName] = ( valueTbl.SORTNAME or valueTbl.CATEGORY and valueTbl.CATEGORY != t_CAT.DEFAULT and valueTbl.CATEGORY or "zzz" ) .. string.lower( valueTbl.NAME or valueName )
					end
				end

            local vcount = 0
				// insert value panels into parent panel
				for _, structlist in ipairs( { newstruct_req, newstruct_other } ) do
					for valueName in SortedPairsByValue( structlist ) do
						local vn = valueName
						local valueTbl = t_lookup["class"][npanel.lookup][class][valueName]
						
						// todo: add this to the queue instead of timer
						timer.Simple( 2, function() // not even gonna bother tracking "when" the other panel is finally created in the queue
							if inspanel.valuer and inspanel.valuer.classstructs and inspanel.valuer.classstructs[vn]
							and IsValid(npanel) and IsValid(npanel.parent) and IsValid(npanel.parent.values[vn]) then
								npanel.parent.values[vn]:SetDisabled( true )
							end
						end )

						-- table.insert( inspanel.valuer.classstructs,
						inspanel.valuer.classstructs[valueName] =
							AddValuePanel(
								npanel.parent, //npanel.valuer.editor
								valueTbl, 
								nil,
								valueName, //npanel.valueName
								npanel.existingTbl, //existingTbl
								npanel.pendingTbl, //pendingTbl
								npanel.viewTbl["__CLASS"],
								npanel.lookup,
								npanel.hierarchy,
								npanel.col,
								"<"..class..">"
							)
						-- )
						
						inspanel.valuer.classstructed = class
					end
				end

				if inspanel.valuer.classstructed then
					inspanel.valuer.b_classstruct:SetText( class..": "..tostring(vcount).." "..UI_STR.classstruct_in )
					inspanel.valuer.b_classstruct:SetEnabled( false )
				end
			end
		end

		inspanel.valuer.GetClassStruct()

		inspanel.valuer:SetHeight( inspanel.valuer:GetTall() + UI_TEXT_H )
	else
		inspanel.valuer.textbox:Dock( FILL )
		-- inspanel.valuer:SetHeight(  )
	end
end

function AddNumberPanel( npanel, inspanel, focus )
	inspanel.valuer = vgui.Create( "Panel", inspanel )
	-- inspanel.valuer:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	inspanel.valuer:Dock( TOP )

	inspanel.valuer:DockMargin( marg, 0, 0, 0 )

	if ( npanel.structTbl.MIN and npanel.structTbl.MAX ) then --or npanel.structTbl["__NUMBERPANEL"] == "numslider"
		inspanel.valuer.slider = vgui.Create( "DNumSlider", inspanel.valuer )
		inspanel.valuer.slider:SetText( "<"..npanel.typ..">" )
		inspanel.valuer.slider:SetDark( true )

		inspanel.valuer.slider:Dock( TOP )

		if npanel.typ == "int" then
			inspanel.valuer.slider:SetDecimals( 0 )
		else
			inspanel.valuer.slider:SetDecimals( 5 )
		end

		inspanel.valuer:SetHeight( UI_TEXT_H * 1.25 )

		inspanel.valuer.slider:SetMin( npanel.structTbl.MIN or 0 )
		inspanel.valuer.slider:SetMax( npanel.structTbl.MAX or 1024 )
		inspanel.valuer.slider:SetDefaultValue( isnumber( npanel.structTbl.DEFAULT ) and npanel.structTbl.DEFAULT or npanel.structTbl.MIN or 0 )
		inspanel.valuer.slider:SetValue( isnumber( npanel.pendingTbl[npanel.valueName] ) and npanel.pendingTbl[npanel.valueName] or inspanel.valuer.slider:GetDefaultValue() )

		inspanel.valuer.slider.OnValueChanged = function( panel )
			if npanel.typ == "int" then
				npanel.pendingTbl[npanel.valueName] = math.Round( inspanel.valuer.slider:GetValue() )
			else
				npanel.pendingTbl[npanel.valueName] = inspanel.valuer.slider:GetValue()
			end

			npanel:Update()
		end
	else
		inspanel.valuer.pan = vgui.Create( "Panel", inspanel.valuer )
		-- inspanel.valuer.pan:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
		inspanel.valuer.pan:Dock( TOP )
		inspanel.valuer.wanger = vgui.Create( "DNumberWang", inspanel.valuer.pan )
		inspanel.valuer.label = vgui.Create( "DLabel", inspanel.valuer.pan )
		inspanel.valuer.label:SetDark( true )
		inspanel.valuer.label:SetText( "<"..npanel.typ..">" )
		inspanel.valuer.label:SizeToContentsX( 0 ) -- Must be called after setting the text
		inspanel.valuer.label:DockMargin( 0, 0, marg, 0 )
		inspanel.valuer.wanger:SetHeight( UI_ENTRY_H )
		inspanel.valuer.pan:SizeToChildren( false, true )

		if npanel.typ == "int" then
			inspanel.valuer.wanger:SetDecimals( 0 )
		else
			inspanel.valuer.wanger:SetDecimals( 5 )
		end

		if npanel.structTbl.MIN then
			inspanel.valuer.wanger:SetMin( npanel.structTbl.MIN )
		else
			inspanel.valuer.wanger:SetMin( nil )
		end
		if npanel.structTbl.MAX then
			inspanel.valuer.wanger:SetMax( npanel.structTbl.MAX )
		else
			inspanel.valuer.wanger:SetMax( nil )
		end

		if isnumber( npanel.pendingTbl[npanel.valueName] ) then
			inspanel.valuer.wanger:SetValue( npanel.pendingTbl[npanel.valueName] )
		elseif isnumber( npanel.structTbl.DEFAULT ) then
			inspanel.valuer.wanger:SetValue( npanel.structTbl.DEFAULT )
		end

		inspanel.valuer.label:Dock( LEFT )
		inspanel.valuer.wanger:Dock( FILL )

		if focus then inspanel.valuer.wanger:RequestFocus() end

		inspanel.valuer.wanger.OnValueChanged = function( panel, val )
         local val = tonumber(val)
			if npanel.typ == "int" then
				npanel.pendingTbl[npanel.valueName] = math.Round( val )
			else
				npanel.pendingTbl[npanel.valueName] = val
			end

			-- print( type(val), type(tonumber(val)) )

			npanel:Update()
		end
	end
end

function AddInfoPanel( npanel, inspanel, focus )
	inspanel.valuer = vgui.Create( "Panel", inspanel )
	-- inspanel.valuer:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	inspanel.valuer:Dock( TOP )

	npanel.descpanel.title:SetText( npanel.hierarchy[3] ) // presetname

	inspanel.valuer.descpan = vgui.Create( "Panel", inspanel.valuer )
	inspanel.valuer.descpan:Dock( TOP )
	-- inspanel.valuer.descpan:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	inspanel.valuer.descpan:SetHeight( UI_TEXT_H )

	inspanel.valuer.descbox = vgui.Create( "DTextEntry", inspanel.valuer.descpan )
	inspanel.valuer.descbox:Dock( FILL )
	-- inspanel.valuer.descbox:SetMultiline( true ) // problem: ugly text inset

	inspanel.valuer.descbox:SetText( npanel.pendingTbl["description"] or "" )
	inspanel.valuer.descbox.OnChange = function( self )
		-- inspanel.valuer.descbox:UpdateSize()
		local txt = inspanel.valuer.descbox:GetValue()

		if txt == "" then
			npanel.pendingTbl["description"] = nil
		else	
			npanel.pendingTbl["description"] = txt
		end

		if npanel.structTbl.REFRESHDESC then
			local prof, set, prs = npanel.hierarchy[1], npanel.hierarchy[2], npanel.hierarchy[3]
			if prof == active_prof and set == active_set and prs == active_prs then
				if ValueList.infopane and IsValid( ValueList.infopane.desc ) then
					-- print( ValueList.infopane.icon )
					ValueList.infopane.desc:RefreshDesc()
				end
			elseif HasPreset( ValueEditors, prof, set, prs ) then
				local ve = HasPreset( ValueEditors, prof, set, prs )
				if ve.ValueList.infopane and IsValid( ve.ValueList.infopane.desc ) then
					ve.ValueList.infopane.desc:RefreshDesc()
				end
			end
		end
		
		npanel:Update()
	end

	-- inspanel.valuer.descbox.UpdateSize = function()
	-- 	surface.SetFont( inspanel.valuer.descbox:GetFont() )
	-- 	local txt = inspanel.valuer.descbox:GetValue()
	-- 	local tw, th = surface.GetTextSize(txt)
	-- 	local cw, ch = surface.GetTextSize("T")
	-- 	inspanel.valuer.descpan:SetHeight( math.max( UI_TEXT_H, UI_TEXT_H + (th-ch) + ch * math.floor( tw / math.max( 25, inspanel.valuer.descbox:GetWide() ) ) ) )
	-- end

	inspanel.valuer.descpan.OnSizeChanged = function()
		inspanel.valuer:SetHeight( inspanel.valuer.descpan:GetTall() + inspanel.valuer.listsheet:GetTall() )
	end

	if focus then inspanel.valuer.descbox:RequestFocus() end

	-- inspanel.valuer.imagebutt = vgui.Create( "DButton", inspanel.valuer.descpan  )
	-- inspanel.valuer.imagebutt:Dock( LEFT )
	-- inspanel.valuer.imagebutt:SetIcon( UI_ICONS.photo )
	-- inspanel.valuer.imagebutt:SetTooltip( "Change Icon" )
	-- inspanel.valuer.imagebutt:SetText( "" )
	-- inspanel.valuer.imagebutt:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )

	inspanel.valuer.refreshbutt = vgui.Create( "DButton", inspanel.valuer.descpan  )
	inspanel.valuer.refreshbutt:Dock( LEFT )
	inspanel.valuer.refreshbutt:SetIcon( UI_ICONS.references )
	inspanel.valuer.refreshbutt:SetTooltip( "Refresh Preset References\n[double-click line to open editor]" )
	inspanel.valuer.refreshbutt:SetText( "" )
	inspanel.valuer.refreshbutt:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )

	inspanel.valuer.listsheet = vgui.Create( "DPropertySheet", inspanel.valuer )
	inspanel.valuer.listsheet:Dock( FILL )
	inspanel.valuer.outerlist = vgui.Create( "DListView", inspanel.valuer )
	inspanel.valuer.outerlist:Dock( FILL )
	inspanel.valuer.outerlist:AddColumn( "Set" ):SetWidth( npanel.wide * 0.25 )
	inspanel.valuer.outerlist:AddColumn( "Preset" ):SetWidth( npanel.wide * 0.5 )
	inspanel.valuer.outerlist:AddColumn( "References" ):SetWidth( npanel.wide * 0.25 )

	inspanel.valuer.innerlist = vgui.Create( "DListView", inspanel.valuer )
	inspanel.valuer.innerlist:Dock( FILL )
	inspanel.valuer.innerlist:AddColumn( "Set" ):SetWidth( npanel.wide * 0.25 )
	inspanel.valuer.innerlist:AddColumn( "Preset" ):SetWidth( npanel.wide * 0.5 )
	inspanel.valuer.innerlist:AddColumn( "References" ):SetWidth( npanel.wide * 0.25 )

	inspanel.valuer.listsheet.outer = inspanel.valuer.listsheet:AddSheet( "Referenced By", inspanel.valuer.outerlist )
	inspanel.valuer.listsheet.inner = inspanel.valuer.listsheet:AddSheet( "Has References", inspanel.valuer.innerlist )

	local prof = npanel.hierarchy[1]
	local set = npanel.hierarchy[2]
	local prs = npanel.hierarchy[3]

	inspanel.valuer.GetReferences = function()
		inspanel.valuer.outerlist:Clear()
		inspanel.valuer.innerlist:Clear()

		inspanel.valuer.refchart = GetAllReferences( prof, set, prs ) // count any references to this preset, both outside and inside itself
		inspanel.valuer.innerref = {}
		RecursiveAnyPresetCount( GetPendingTbl( prof, set, prs ), inspanel.valuer.innerref ) // count any references inside this

		local outertot = 0
		for rset, settbl in pairs( inspanel.valuer.refchart ) do
			for rprs, c in pairs( settbl ) do
				outertot = outertot + c
				inspanel.valuer.outerlist:AddLine( rset, rprs, c ):SetToolTip( "("..c.." "..( c == 1 and "reference" or "references")..") " .. prof .. " > " .. rset .. " > " .. rprs )
			end
		end

		local innertot = 0
		for type, typetbl in pairs( inspanel.valuer.innerref ) do
			for name, c in pairs( typetbl ) do
				innertot = innertot + c
				inspanel.valuer.innerlist:AddLine( type, name, c ):SetToolTip( "("..c.." "..( c == 1 and "reference" or "references")..") " .. prof .. " > " .. type .. " > " .. name )
			end
		end

		if outertot == 0 then
			inspanel.valuer.listsheet.outer.Tab:SetText( "Referenced By" )
		else
			inspanel.valuer.listsheet.outer.Tab:SetText( "Referenced By ["..outertot.."]" )
		end
		if innertot == 0 then
			inspanel.valuer.listsheet.inner.Tab:SetText( "Has References" )
		else
			inspanel.valuer.listsheet.inner.Tab:SetText( "Has References ["..innertot.."]" )
		end

		inspanel.valuer.outerlist:SetHeight( #inspanel.valuer.outerlist:GetLines() > 0 and ( #inspanel.valuer.outerlist:GetLines() + UI_TABLE_L_ADD ) * inspanel.valuer.outerlist:GetDataHeight() or 0 )
		inspanel.valuer.innerlist:SetHeight( #inspanel.valuer.innerlist:GetLines() > 0 and ( #inspanel.valuer.innerlist:GetLines() + UI_TABLE_L_ADD ) * inspanel.valuer.innerlist:GetDataHeight() or 0 )

		inspanel.valuer.listsheet.inner.Tab.h = inspanel.valuer.innerlist:GetTall()
		inspanel.valuer.listsheet.outer.Tab.h = inspanel.valuer.outerlist:GetTall()

		inspanel.valuer.listsheet:SwitchToName( outertot != 0 and inspanel.valuer.listsheet.outer.Name or innertot != 0 and inspanel.valuer.listsheet.inner.Name or inspanel.valuer.listsheet.outer.Name )

		inspanel.valuer.listsheet:SetHeight( outertot == 0 and innertot == 0 and 0 or inspanel.valuer.listsheet:GetActiveTab().h + 28 )
		inspanel.valuer:SetHeight( inspanel.valuer.descpan:GetTall() + inspanel.valuer.listsheet:GetTall() )
	end

	inspanel.valuer.listsheet.OnActiveTabChanged = function( self, old, new )
		inspanel.valuer.listsheet:SetHeight( new.h + 28 )
	end

	inspanel.valuer.refreshbutt.OnReleased = function()
		inspanel.valuer:GetReferences()
	end

	inspanel.valuer:GetReferences()

	inspanel.valuer.outerlist.DoDoubleClick = function( self, id, line )
		if GetSetsPresets( npanel.hierarchy[1], line:GetColumnText(1) )[ line:GetColumnText(2) ] then
			GetOrCreateValueEditor( npanel.hierarchy[1], line:GetColumnText(1), line:GetColumnText(2) )
		end
	end
	inspanel.valuer.innerlist.DoDoubleClick = function( self, id, line )
		if GetSetsPresets( npanel.hierarchy[1], line:GetColumnText(1) )[ line:GetColumnText(2) ] then
			GetOrCreateValueEditor( npanel.hierarchy[1], line:GetColumnText(1), line:GetColumnText(2) )
		end
	end

	inspanel.valuer.OnSizeChanged = function( panel, w, h )
		inspanel:InvalidateLayout( true )
		inspanel:SizeToChildren( false, true )
		npanel:InvalidateLayout( true )
		npanel:SizeToChildren( false, true )
		-- inspanel.valuer.descbox:UpdateSize()
	end
	
	inspanel.valuer.listsheet.OnSizeChanged = function()
		inspanel.valuer:SetHeight( inspanel.valuer.descpan:GetTall() + inspanel.valuer.listsheet:GetTall() )
	end

	-- inspanel.valuer.descbox:UpdateSize()	

	-- inspanel.valuer.list:SetHeight( #inspanel.valuer.list:GetLines() > 0 and ( #inspanel.valuer.list:GetLines() + UI_TABLE_L_ADD ) * inspanel.valuer.list:GetDataHeight() or 0 )
	-- inspanel.valuer:SetHeight( inspanel.valuer.descpan:GetTall() + inspanel.valuer.list:GetTall() )
end

function AddFractionPanel( npanel, inspanel, focus )
	inspanel.valuer = vgui.Create( "Panel", inspanel )
	-- inspanel.valuer:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	inspanel.valuer:Dock( TOP )

	-- inspanel.valuer:DockMargin( marg, 0, 0, 0)

	// decimal
	inspanel.valuer.decimal = vgui.Create( "Panel", inspanel.valuer )
	-- inspanel.valuer.decimal:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	inspanel.valuer.decimal:Dock( TOP )
	inspanel.valuer.decimal:DockMargin( marg, 0, 0, 0)
	inspanel.valuer.decimal:SetZPos( 1 )

	inspanel.valuer.decimal.label = vgui.Create( "DLabel", inspanel.valuer.decimal )
	inspanel.valuer.decimal.label:SetDark( true )
	inspanel.valuer.decimal.label:SetText( "<decimal>" )
	inspanel.valuer.decimal.label:SizeToContentsX( 5 )

	inspanel.valuer.decimal.wanger = vgui.Create( "DNumberWang", inspanel.valuer.decimal )
	inspanel.valuer.decimal.wanger:SetHeight( UI_ENTRY_H )

	if focus then inspanel.valuer.decimal.wanger:RequestFocus() end

	inspanel.valuer.decimal.label:Dock( LEFT )
	inspanel.valuer.decimal.wanger:Dock( FILL )

	inspanel.valuer.decimal:SizeToChildren( false, true )

	inspanel.valuer.decimal.wanger:SetMin( nil )
	inspanel.valuer.decimal.wanger:SetMax( nil )

	inspanel.valuer.decimal.wanger.OnValueChanged = function( panel, val )
		-- if !panel:HasFocus() then return end
		npanel.pendingTbl[npanel.valueName] = npanel.pendingTbl[npanel.valueName] or {}
		npanel.pendingTbl[npanel.valueName]["f"] = tonumber( val )
		npanel.pendingTbl[npanel.valueName]["n"], npanel.pendingTbl[npanel.valueName]["d"] = to_frac( tonumber( val ) )

		inspanel.valuer:FillValues()
		inspanel.valuer.fractional.wanger_n:SetValue( npanel.pendingTbl[npanel.valueName]["n"] )
		inspanel.valuer.fractional.wanger_d:SetValue( npanel.pendingTbl[npanel.valueName]["d"] )

		if isfunction( inspanel.valuer.CompareValues ) then
			inspanel.valuer:CompareValues()
		end
		npanel:Update()
	end

	// fractional
	inspanel.valuer.fractional = vgui.Create( "Panel", inspanel.valuer )
	-- inspanel.valuer.fractional:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	inspanel.valuer.fractional:Dock( TOP )
	inspanel.valuer.fractional:SetZPos( -1 )
	inspanel.valuer.fractional:DockMargin( marg, 0, 0, 0)

	inspanel.valuer.fractional.label = vgui.Create( "DLabel", inspanel.valuer.fractional )
	inspanel.valuer.fractional.label:SetDark( true )
	inspanel.valuer.fractional.label:SetText( "<fraction>" )
	inspanel.valuer.fractional.label:SetWidth( inspanel.valuer.decimal.label:GetWide() )

	inspanel.valuer.fractional.wanger_n = vgui.Create( "DNumberWang", inspanel.valuer.fractional )
	inspanel.valuer.fractional.wanger_n:SetHeight( UI_ENTRY_H )

	inspanel.valuer.fractional.labeldiv = vgui.Create( "DLabel", inspanel.valuer.fractional )
	inspanel.valuer.fractional.labeldiv:SetDark( true )
	inspanel.valuer.fractional.labeldiv:SetText( " /" )
	inspanel.valuer.fractional.labeldiv:SizeToContentsX( 5 )

	inspanel.valuer.fractional.wanger_d = vgui.Create( "DNumberWang", inspanel.valuer.fractional )
	inspanel.valuer.fractional.wanger_d:SetHeight( UI_ENTRY_H )

	inspanel.valuer.fractional.label:Dock( LEFT )
	inspanel.valuer.fractional.wanger_n:Dock( LEFT )
	inspanel.valuer.fractional.labeldiv:Dock( LEFT )
	inspanel.valuer.fractional.wanger_d:Dock( LEFT )
	local fracwide = ( npanel:GetWide() - inspanel.valuer.fractional.label:GetWide() - inspanel.valuer.fractional.labeldiv:GetWide() - marg + 1 ) * 0.5
	inspanel.valuer.fractional.wanger_n:SetWide( fracwide )
	inspanel.valuer.fractional.wanger_d:SetWide( fracwide )

	inspanel.valuer.fractional:SizeToChildren( false, true )

	inspanel.valuer.fractional.wanger_n:SetMin( nil )
	inspanel.valuer.fractional.wanger_n:SetMax( nil )
	inspanel.valuer.fractional.wanger_d:SetMin( nil )
	inspanel.valuer.fractional.wanger_d:SetMax( nil )
	inspanel.valuer.decimal.wanger:SetDecimals( 16 )
	inspanel.valuer.fractional.wanger_n:SetDecimals( 16 )
	inspanel.valuer.fractional.wanger_d:SetDecimals( 16 )

	inspanel.valuer.InitPend = function()
		if npanel.pendingTbl[npanel.valueName] == nil then
			npanel.pendingTbl[npanel.valueName] = npanel.pendingTbl[npanel.valueName] or {}

			npanel.pendingTbl[npanel.valueName]["d"] = tonumber( inspanel.valuer.fractional.wanger_d:GetValue() )
			if !npanel.pendingTbl[npanel.valueName]["n"] then
				npanel.pendingTbl[npanel.valueName]["n"] = 1
			end
			if npanel.pendingTbl[npanel.valueName]["d"] == 0 then
				npanel.pendingTbl[npanel.valueName]["f"] = 0
			else
				npanel.pendingTbl[npanel.valueName]["f"] = npanel.pendingTbl[npanel.valueName]["n"] / npanel.pendingTbl[npanel.valueName]["d"]
			end

			inspanel.valuer:FillValues()
			inspanel.valuer.decimal.wanger:SetText( npanel.pendingTbl[npanel.valueName]["f"] )
			inspanel.valuer.fractional.wanger_n:SetText( npanel.pendingTbl[npanel.valueName]["n"] )
			inspanel.valuer:CompareValues()
			npanel:Update()
		end
	end	

	inspanel.valuer.fractional.wanger_n.OnValueChanged = function( panel, val )
		-- if !panel:HasFocus() then return end
		npanel.pendingTbl[npanel.valueName] = npanel.pendingTbl[npanel.valueName] or {}

		npanel.pendingTbl[npanel.valueName]["n"] = tonumber( val )

		// invalid denominators
		if !npanel.pendingTbl[npanel.valueName]["d"] then
			npanel.pendingTbl[npanel.valueName]["d"] = 1
		end
		if npanel.pendingTbl[npanel.valueName]["d"] == 0 then
			npanel.pendingTbl[npanel.valueName]["f"] = 0
		else
			npanel.pendingTbl[npanel.valueName]["f"] = npanel.pendingTbl[npanel.valueName]["n"] / npanel.pendingTbl[npanel.valueName]["d"]
		end

		inspanel.valuer:FillValues()
		inspanel.valuer.decimal.wanger:SetText( npanel.pendingTbl[npanel.valueName]["f"] )
		inspanel.valuer.fractional.wanger_d:SetText( npanel.pendingTbl[npanel.valueName]["d"] )

		if isfunction( inspanel.valuer.CompareValues ) then
			inspanel.valuer:CompareValues()
		end
		npanel:Update()
	end
	inspanel.valuer.fractional.wanger_d.OnValueChanged = function( panel, val )
		-- if !panel:HasFocus() then return end
		npanel.pendingTbl[npanel.valueName] = npanel.pendingTbl[npanel.valueName] or {}

		// invalid denominators
		npanel.pendingTbl[npanel.valueName]["d"] = tonumber( val )
		if !npanel.pendingTbl[npanel.valueName]["n"] then
				npanel.pendingTbl[npanel.valueName]["n"] = 1
		end
		if npanel.pendingTbl[npanel.valueName]["d"] == 0 then
			npanel.pendingTbl[npanel.valueName]["f"] = 0
		else
			npanel.pendingTbl[npanel.valueName]["f"] = npanel.pendingTbl[npanel.valueName]["n"] / npanel.pendingTbl[npanel.valueName]["d"]
		end

		inspanel.valuer:FillValues()
		inspanel.valuer.decimal.wanger:SetText( npanel.pendingTbl[npanel.valueName]["f"] )
		inspanel.valuer.fractional.wanger_n:SetText( npanel.pendingTbl[npanel.valueName]["n"] )

		if isfunction( inspanel.valuer.CompareValues ) then
			inspanel.valuer:CompareValues()
		end
		npanel:Update()
	end

	inspanel.valuer.FillValues = function()
		if istable( npanel.pendingTbl[npanel.valueName] ) then
			local e = npanel.pendingTbl[npanel.valueName]
			// fill missing parts
			if e["f"] and ( !e["n"] or !e["d"] ) then
				e["n"], e["d"] = to_frac( e["f"] )
			elseif !e["f"] and ( e["n"] and e["d"] ) then
				if e["d"] == 0 then
					e["f"] = 0
				else
					e["f"] = e["n"] / e["d"]
				end
			end

			inspanel.valuer.decimal.wanger:SetText( e["f"] )
			inspanel.valuer.fractional.wanger_n:SetText( e["n"] )
			inspanel.valuer.fractional.wanger_d:SetText( e["d"] )

		// or set to default
		elseif istable( npanel.structTbl.DEFAULT )
		and ( npanel.structTbl.DEFAULT["f"] or ( npanel.structTbl.DEFAULT["n"] and npanel.structTbl.DEFAULT["d"] ) )
		then
			local e = npanel.structTbl.DEFAULT
			// fill missing parts
			if e["f"] and ( !e["n"] or !e["d"] ) then
				e["n"], e["d"] = to_frac( e["f"] )
			elseif !e["f"] and ( e["n"] and e["d"] ) then
				if e["d"] == 0 then
					e["f"] = 0
				else
					e["f"] = e["n"] / e["d"]
				end
			end

			inspanel.valuer.fractional.wanger_n:SetText( e["n"] )
			inspanel.valuer.fractional.wanger_d:SetText( e["d"] )
			inspanel.valuer.decimal.wanger:SetText( e["f"] )
		end
	end

	inspanel.valuer:FillValues()

	inspanel.valuer:SetHeight( UI_ENTRY_H * 2 )

	// comparison panel (e.g. expected)
	if npanel.structTbl.COMPARECHANCE then
		inspanel.valuer.comparelist = vgui.Create( "DListView", inspanel.valuer )
		inspanel.valuer.comparelist:Dock( TOP )
		if npanel.structTbl.COMPARECHANCE_TABLE then
			inspanel.valuer.comparelist:AddColumn( "##" )
		else
			inspanel.valuer.comparelist:AddColumn( "Preset" )
		end
		inspanel.valuer.comparelist:AddColumn( "Fraction" ):SetWidth( inspanel.valuer:GetWide() * 0.2 )
		inspanel.valuer.comparelist:AddColumn( "Chance" )
		-- inspanel.valuer.comparepan:SetBackgroundColor( Color( 255, 255, 255, 128 ) )
		inspanel.valuer.comparelist:SetZPos( 2 )
		inspanel.valuer.comparelist.lines = {}

		inspanel.valuer.comparelist:SetHeight( 2 * inspanel.valuer.comparelist:GetDataHeight() )
		inspanel.valuer:SetHeight( UI_ENTRY_H * 2 + inspanel.valuer.comparelist:GetTall() )

		inspanel.valuer.comparelist.DoDoubleClick = function( self, id, line )
			if npanel.structTbl.COMPARECHANCE_TABLE then
				if isfunction( npanel.parent.ChangeEditor ) then
					npanel.parent:ChangeEditor( inspanel.valuer.comparelist.keytable[line:GetColumnText(1)] )
				end
			else
				GetOrCreateValueEditor( npanel.hierarchy[1], npanel.hierarchy[2], line:GetColumnText( 1 ) )
			end
		end

		inspanel.valuer.CompareValues = function()
			-- if npanel.pendingTbl[npanel.valueName] == nil then return end
			local compare, dist, keytable
			if npanel.structTbl.COMPARECHANCE_TABLE then
				compare, dist, keytable = GetValueAcrossTable( npanel.hierarchy, npanel.structTbl.COMPARECHANCE_TABLE_KEY )
			else
				compare, dist, keytable = GetValueAcrossPresets( npanel.hierarchy )
			end

			if compare then
				// for table types
				if #npanel.hierarchy - dist == 2 then
					local same
					local nomatch = {}

					// get the secondary value that needs to match
					if npanel.structTbl.COMPARECHANCE_SIDEKEY then
						local point = compare[ npanel.hierarchy[3] ][npanel.hierarchy[#npanel.hierarchy-1]]
						-- print( npanel.hierarchy[#npanel.hierarchy], npanel.hierarchy[ #npanel.hierarchy - 1 ], npanel.hierarchy[#npanel.hierarchy - 2] )

						for _, key in ipairs( npanel.structTbl.COMPARECHANCE_SIDEKEY ) do
							-- print( point, key )
							if point != nil and point[key] != nil then
								point = point[key]
							else
								point = nil
							end
						end
						same = point
						if same == nil then
							inspanel.valuer.comparelist.lines = {}
							inspanel.valuer.comparelist:Clear()
							return
						end

						for prsname, mn in pairs( compare ) do
							for	k, v in pairs( mn ) do
								local point = v
								local val
								for _, key in ipairs( npanel.structTbl.COMPARECHANCE_SIDEKEY ) do
									if point != nil and point[key] != nil then
										point = point[key]
									else
										point = nil
									end
								end
								val = point
								if same == val then
									compare[prsname] = v
									nomatch[prsname] = nil
									break
								else
									nomatch[prsname] = true
								end
							end
						end
					end

					for k in pairs( nomatch ) do
						compare[k] = nil
					end
				end

				// for value types with inner structures (e.g. fraction)
				if npanel.structTbl.COMPARECHANCE_MAINKEY then
					for k, mn in pairs( compare ) do
						local point = mn

						// traverse, stopping and failing when next key doesn't exist
						for _, key in ipairs( npanel.structTbl.COMPARECHANCE_MAINKEY ) do
							-- print( point, key )
							if point != nil and point[key] != nil then
								point = point[key]
							else
								point = nil
							end
						end

						compare[k] = point
					end
				end

				local sum = 0
				for _, v in pairs( compare ) do
					sum = sum + v
				end

				if !npanel.structTbl.COMPARECHANCE_TABLE then
					local unenabled = table.Copy( compare )
					for prs, en in pairs( GetEnabledPresets( npanel.hierarchy[1], npanel.hierarchy[2] ) ) do
						if en then
							unenabled[prs] = nil
						end
					end
					for prs in pairs( unenabled ) do
						compare[prs] = nil
					end
				end

				-- PrintTable( compare )
				-- PrintTable( unenabled )

				local chance_tbl = ShowFracChanceTbl2( sum, compare )
				
				local toremove = table.Copy( inspanel.valuer.comparelist.lines )
				for name, key in SortedPairsByValue( keytable ) do
				-- for name, chances in pairs( chance_tbl ) do
					local chances = chance_tbl[name]
					if chances == nil then continue end
					if !inspanel.valuer.comparelist.lines[name] then
						inspanel.valuer.comparelist.lines[name] = inspanel.valuer.comparelist:AddLine( name, chances[1], chances[2] )
						-- inspanel.valuer.comparelist.lines[name]:SetToolTip( name .. " ( " .. chances[1] .. " )\n[double-click to open editor]" )
					else
						inspanel.valuer.comparelist.lines[name]:SetColumnText( 2, chances[1] )
						inspanel.valuer.comparelist.lines[name]:SetColumnText( 3, chances[2] )
						toremove[name] = nil
					end
				end

				for name, line in pairs( toremove ) do
					local k = line:GetID()

					inspanel.valuer.comparelist:RemoveLine( k )
					inspanel.valuer.comparelist.lines[name] = nil
				end

				inspanel.valuer.comparelist.keytable = keytable

				inspanel.valuer.comparelist:SetHeight( ( table.Count( chance_tbl ) + UI_TABLE_L_ADD ) * inspanel.valuer.comparelist:GetDataHeight() )
				inspanel.valuer:SetHeight( UI_ENTRY_H * 2 + inspanel.valuer.comparelist:GetTall() )
				inspanel:InvalidateLayout( true )
				inspanel:SizeToChildren( false, true )

				npanel:InvalidateLayout( true )
				npanel:SizeToChildren( false, true )
			end
		end

		inspanel.valuer.comparebutt = vgui.Create( "DButton", inspanel.valuer.decimal )
		inspanel.valuer.comparebutt:Dock( LEFT )
		inspanel.valuer.comparebutt:SetIcon( UI_ICONS.refresh )
		inspanel.valuer.comparebutt:SetText( "" )
		inspanel.valuer.comparebutt:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )
		inspanel.valuer.comparebutt.OnReleased = function()
			inspanel.valuer:InitPend()
			inspanel.valuer:CompareValues()
		end
		
		inspanel.valuer:CompareValues()
	end

	inspanel.valuer.OnSizeChanged = function()
		local fracwide = ( npanel:GetWide() - inspanel.valuer.fractional.label:GetWide() - inspanel.valuer.fractional.labeldiv:GetWide() - marg + 1 ) * 0.5
		inspanel.valuer.fractional.wanger_n:SetWide( fracwide )
		inspanel.valuer.fractional.wanger_d:SetWide( fracwide )
		inspanel.valuer.fractional:SizeToChildren( false, true )
	end
end

function CompareExpected( prof, set, prs, value )
	local compare, dist, keytable
	compare, dist, keytable = GetValueAcrossTable( { prof, set, prs, value } )

	if compare then
		// for value types with inner structures (e.g. fraction)
		for k, mn in pairs( compare ) do
			local point = mn

			// traverse, stopping and failing when next key doesn't exist
			for _, key in ipairs( { "expected", "f" } ) do
				if point != nil and point[key] != nil then
					point = point[key]
				else
					point = nil
				end
			end

			compare[k] = point
		end

		local sum = 0
		for _, v in pairs( compare ) do
			sum = sum + v
		end

		return ShowFracChanceTbl2( sum, compare )
	else
		return {}
	end
end

function GetValueAcrossTable( h, keynamer )
	if !h then return nil end
	local results = {}
	local keys = {}
	local tbl = GetSetsPresets( h[1], h[2] )
	local point = tbl[ h[3] ][ h[4] ]
	local lastpoint = point
	local c = 4
	for _, key in ipairs( { select( 5, h ) } ) do
		if isnumber( key ) then break end

		if point ~= nil and point[key] ~= nil then
			c=c+1
			lastpoint = point
			point = point[key]
		else // ???
			return nil
		end
	end

	// this is necessary for some reason about the way table references work which i don't seem to grasp
	for k, v in pairs( lastpoint ) do
		local kk = k
		if keynamer then
			if v[keynamer] then
				if GetPresetName( v[keynamer] ) then
					kk = tostring(k) .. ": " .. ( istable( v[keynamer] ) and ( "<"..tostring(v[keynamer].type).."> "..tostring(v[keynamer].name) ) or tostring(v[keynamer]) )
				else
					kk = tostring(k) .. ": " .. ( istable( v[keynamer] ) and table.concat( v[keynamer], ", " ) or tostring(v[keynamer]) )
				end
			end
		end
		results[kk] = v
		keys[kk] = k
	end
	
	return results, c, keys
end

function GetValueAcrossPresets( h )
	if !h then return nil end
	-- PrintTable( h )
	local results = {}
	local keys = {}
	-- print( h[1], h[2] )
	local tbl = GetSetsPresets( h[1], h[2] )
	-- for k, prstbl in pairs( tbl ) do
	-- 	if prstbl["npcd_enabled"] == false then
	-- 		tbl[k] = nil
	-- 	end
	-- end

	local lh = { h[1], h[2], h[3], h[4] }

	// find original table's furthest pre-table-type
	if tbl[h[3]] then
		local point = tbl[ h[3] ][ h[4] ]
		local lastpoint = point
		if point == nil then return nil end
		
		for _, key in ipairs( { select( 5, h ) } ) do
			-- print( key, point[key] )

			if isnumber( key ) then break end

			if point[key] ~= nil then
				table.insert( lh, key )
				lastpoint = point
				point = point[key]
			else // ???
				return nil
			end
		end
		results[h[3]] = lastpoint
		keys[h[3]] = h[3]
		-- print( "len", #lh )
	end

	for prsname, prstbl in pairs( tbl ) do
		local point = prstbl[ lh[4] ]
		local lastpoint = point
		-- print( point )
		if point == nil then continue end
		
		for _, key in ipairs( { select( 5, lh ) } ) do
			-- print( key, point[key] )

			if point[key] ~= nil then
				lastpoint = point
				point = point[key]
			else
				lastpoint = nil
				point = nil
				break
			end
		end
		if lastpoint != nil then
			results[prsname] = lastpoint
			keys[prsname] = prsname
		end
	end

	return results, #lh, keys
end

local ft_TypePanel = {
	["table"] = AddTablePanel,
	["struct_table"] = AddTablePanel,
	["struct"] = AddStructPanel,
	["number"] = AddNumberPanel,
	["int"] = AddNumberPanel,
	["fraction"] = AddFractionPanel,
	["string"] = AddStringPanel,
	["boolean"] = AddBoolPanel,
	["vector"] = AddVectorPanel,
	["angle"] = AddAnglePanel,
	["color"] = AddColorPanel,
	["any"] = AddAnyPanel,
	["enum"] = AddEnumPanel,
	["preset"] = AddPresetPanel,
	["function"] = AddFunctionPanel,
	["info"] = AddInfoPanel,
}

function AddTypedPanel( npanel, forcetyp, focus )
	if !npanel and ( !npanel.typ and !forcetyp ) then return end
	ft_TypePanel[forcetyp or npanel.typ]( npanel, npanel.valuepanel, focus )
end

function SendSettingsAct( act, prof, has2, np )
	--[[
		int corresponds to actions
		0: SwitchProfile
		1: SaveProfile
		2: LoadProfiles
		3: CreateProfile
		4: DeleteProfile
		5: ClearProfile
		6: SaveAllProfiles
		7: LoadAllProfiles
		8: RenameProfile (oldp, has2, newp)
		9: CopyProfile
		10: CreateEmptyProfile
		11: ResetProfile
	]]

	if cl_cvar.cl_debugged.v:GetBool() then
		print( "SendSettingsAct", act, prof, has2, np )
	end
	if !CheckClientPerm( LocalPlayer(), cvar.perm_prof.v:GetInt() ) then
		print( "Error: You do not have permission to edit profiles!" )
		return
	end

	if !act then return end

	local a = bit.bor( act )
	local p = prof or ""
	net.Start( "npcd_cl_settings_act" )
		net.WriteUInt( a, 5 )
		net.WriteString( p )
		net.WriteBool( has2 )
		if has2 then // rename
			net.WriteString( np )
		end
	net.SendToServer()

	-- timer.Simple( engine.TickInterval() * 3, function() UpdateProfilesList() end )
end

function ClientSwitchProfile( p )
	if !p then return end
	SendSettingsAct( 0, p )
end

function ClientSaveProfile( p )
	if !p then return end
	SendSettingsAct( 1, p )
end

function ClientCreateProfile( pn, loose )
	local p = pn
	if !p then
		local count = table.Count( cl_Profiles )
		local profc = 1
		p = "profile " .. ( count + 1 )
		while cl_Profiles[p] ~= nil do
			profc = profc + 1
			p = "profile " .. ( count + profc )
		end
	end

	local newp = string.lower( string.Trim( p ) )
	local pname = newp
	local copycount = 0
	if loose then
		while cl_Profiles[pname] ~= nil do
			copycount = copycount + 1
			pname = newp .. " (" .. copycount .. ")"
		end
	end

	SendSettingsAct( 3, pname )

	return pname
end

function ClientCreateEmptyProfile( pn, loose )
	local p = pn
	if !p then
		local count = table.Count( cl_Profiles )
		local profc = 1
		p = "profile " .. ( count + 1 )
		while cl_Profiles[p] ~= nil do
			profc = profc + 1
			p = "profile " .. ( count + profc )
		end
	end
	
	local newp = string.lower( string.Trim( p or "profile" ) )
	local pname = newp
	local copycount = 0
	if loose then
		while cl_Profiles[pname] ~= nil do
			copycount = copycount + 1
			pname = newp .. " (" .. copycount .. ")"
		end
	end

	SendSettingsAct( 10, pname )

	return pname
end

function ClientDeleteProfile( p )
	if !p then return end
	SendSettingsAct( 4, p )
end
function ClientClearProfile( p )
	if !p then return end
	SendSettingsAct( 5, p )
end
function ClientResetProfile( p )
	if !p then return end
	SendSettingsAct( 11, p )
end

function ClientRenameProfile( oldp, newp )
	if !oldp or !newp then return end
	SendSettingsAct( 8, oldp, true, newp )
end
function ClientCopyProfile( p )
	if !p then return end
	SendSettingsAct( 9, p )
end

-- function ClientCreatePreset( p, set, prsname, prstbl )
-- 	local prof = p or cl_currentProfile
-- 	if !isstring( prof ) or !isstring( set ) or !isstring( prsname ) or !istable( prstbl ) then
-- 		Error( "Error: npcd > ClientCreatePreset > Invalid value(s). prof: ",prof, "; set: ",typ,"; prsname: ",prsname,"; prstbl: ",prstbl"\n\n" )
-- 		return
-- 	end
-- 	net.Start( "npcd_cl_settings_commit_send" )
-- 		net.WriteString( prof )
-- 		net.WriteString( typ )
-- 		net.WriteString( prsname )
-- 		net.WriteTable( prstbl )
-- 	net.SendToServer()
-- end

function InsertPending( p, set, prsname, prstbl )
	local prof = p or cl_currentProfile
	if !isstring( prof ) or !isstring( set ) or !isstring( prsname ) or !istable( prstbl ) then
		Error( "Error: npcd > ClientCreatePreset > Invalid value(s). prof: ",prof, "; set: ",typ,"; prsname: ",prsname,"; prstbl: ",prstbl"\n\n" )
		return nil
	end
	if !cl_Profiles[prof] then
		Error( "Error: Profile ",prof," does not exist!" )
		return nil
	end
	AddPresetPend( PendingAdd, prof, set, prsname )
	return AddPresetPend( PendingSettings, prof, set, prsname, prstbl )
end


// prompts

function TextPrompt( pan, x, y, old, submitFunc, cancelFunc, exists, placeholder, multiline, framed, noclose )
	local prompt = vgui.Create( "DPanel", pan )
	if framed then
		prompt:Dock( FILL )
	end
	prompt:SetPos( x, y )
	prompt:SetSize( UI_TEXT_H * 8, UI_ENTRY_H )
	prompt:SetZPos( 99 )
	-- prompt:NoClipping( true )

	local tentry = vgui.Create( "DTextEntry", prompt )
	tentry:Dock( FILL )
	tentry:RequestFocus()
	if multiline then
		tentry:SetMultiline( true )
		prompt:SetSize( UI_TEXT_H * 16, UI_ENTRY_H * 5 )
		tentry:SetTall( UI_ENTRY_H * 5 )
	end
	-- tentry:NoClipping( true )

	local cancel = vgui.Create( "DButton", prompt )
	cancel:SetText("")
	cancel:SetWidth( UI_ICONBUTTON_W )
	cancel:Dock( RIGHT )
	cancel:SetImage( UI_ICONS.cancel )
	-- cancel:NoClipping( true )

	local submit = vgui.Create( "DButton", prompt )
	submit:SetText("")
	submit:SetWidth( UI_ICONBUTTON_W )
	submit:Dock( RIGHT )
	submit:SetImage( UI_ICONS.submit )
	-- submit:NoClipping( true )

	cancel.OnReleased = function()
		if !noclose then prompt:Remove() end
		if isfunction(cancelFunc) then
			cancelFunc()
		end
	end

	submit.OnReleased = function()
		tentry:SetValue( tentry:GetValue() )
	end

	if placeholder then
		tentry:SetPlaceholderText( placeholder )
	end
	if old then
		tentry:SetText( old )
	end
	tentry:SetUpdateOnType( false )
	tentry.OnValueChange = function( self, val )
		if val == nil or val == "" then return end
		if exists and exists[tostring(val)] then
			tentry:SetText( "\""..val.."\" already exists" )
			tentry:SetEditable( false )
			submit:SetEnabled( false )
			timer.Simple( 1.33, function() 
				if IsValid( tentry ) then
					tentry:SetText(val)
					tentry:SetEditable( true )
					submit:SetEnabled( true )
				end
			end )
			return
		end
		submitFunc( tostring(val), prompt )
		if !noclose then prompt:Remove() end
	end
end

function ConfirmPrompt( pan, x, y, txt, submitFunc )
	local prompt = vgui.Create( "DPanel", pan )
	prompt:SetPos( x, y )
	prompt:SetZPos( 99 )
	prompt:DockPadding( 10, 0, 0, 0 )
	-- prompt:NoClipping( true )

	local label = vgui.Create( "DLabel", prompt )
	label:Dock( FILL )
	label:SetText( txt or "Are you sure?" )
	label:SetDark( true )
	label:SizeToContentsX( 10 )
	label:SizeToContentsY( 10 )
	-- label:NoClipping( true )

	local cancel = vgui.Create( "DButton", prompt )
	cancel:SetText("")
	cancel:SetWidth( UI_ICONBUTTON_W )
	cancel:Dock( RIGHT )
	cancel:SetImage( UI_ICONS.cancel )
	-- cancel:NoClipping( true )

	local submit = vgui.Create( "DButton", prompt )
	submit:SetText("")
	submit:SetWidth( UI_ICONBUTTON_W )
	submit:Dock( RIGHT )
	submit:SetImage( UI_ICONS.submit )
	-- submit:NoClipping( true )

	prompt:SetSize( label:GetWide() + UI_ICONBUTTON_W * 2 + 10, math.max( label:GetTall(), UI_ENTRY_H ) )

	cancel.OnReleased = function()
		prompt:Remove()
	end

	submit.OnReleased = function()
		submitFunc()
		prompt:Remove()
	end
end

function MovePrompt( pan, x, y, txt, submitFunc, origin, set, tbl, prslist, allowOverwrite )
	local confirm2

	local prompt = vgui.Create( "DPanel", pan )
	prompt:SetPos( x, y )
	prompt:SetZPos( 99 )
	prompt:DockPadding( 10, 0, 0, 0 )
	-- prompt:NoClipping( true )

	local label = vgui.Create( "DLabel", prompt )
	label:Dock( LEFT )
	label:SetText( txt or "Move preset to: " )
	label:SetDark( true )
	label:SizeToContentsX( 10 )
	-- label:NoClipping( true )

	local owlabel // overwrite list

	local lsize = label:GetWide()

	local box = vgui.Create( "DComboBox", prompt )
	box:Dock( FILL )
	box:SetWidth( 120 )
	-- box:NoClipping( true )
	for p in pairs( tbl or cl_Profiles ) do
		if p == origin then continue end
		box:AddChoice( p )
	end
	if tbl then box:SetSortItems( false ) end

	local cancel = vgui.Create( "DButton", prompt )
	cancel:SetText("")
	cancel:SetWidth( UI_ICONBUTTON_W )
	cancel:Dock( RIGHT )
	cancel:SetImage( UI_ICONS.cancel )
	-- cancel:NoClipping( true )

	local submit = vgui.Create( "DButton", prompt )
	submit:SetText("")
	submit:SetWidth( UI_ICONBUTTON_W )
	submit:Dock( RIGHT )
	submit:SetImage( UI_ICONS.submit )
	-- submit:NoClipping( true )

	prompt:SetSize( label:GetWide() + box:GetWide() + UI_ICONBUTTON_W * 2 + 10, UI_ENTRY_H )

	cancel.OnReleased = function()
		if confirm2 then
			confirm2 = nil
			box:SetVisible( true )
			if IsValid( owlabel ) then owlabel:Remove() end
			label:SetText( txt )
			label:SizeToContentsX( 10 )
			prompt:SetSize( label:GetWide() + box:GetWide() + UI_ICONBUTTON_W * 2 + 10, UI_ENTRY_H )
			prompt:SetPos( x, y )
		else
			prompt:Remove()
		end
	end

	submit.OnReleased = function()
		if confirm2 then
			// confirm overwrite
			submitFunc( box:GetSelected() )
			prompt:Remove()
		end

		local label = label
		if box:GetSelected() then
			if tbl then
				local k = box:GetSelected()
				if !tbl[k] then
					label:SetText( "Doesn't exist!" )
					timer.Simple( 1.5, function()
						if ispanel( label ) and label:IsValid() then
							label:SetText( txt )
						end
					end )
					return
				end
			elseif set and prslist then
				local prof = box:GetSelected()
				local pkeys = GetSetsPresets( prof, set )
				local matches = {}
				local lastmatch
				for _, prs in ipairs( prslist ) do
					if pkeys[prs] then
						if allowOverwrite then
							table.insert( matches, prs )
						else
							label:SetText( prs .. " already exists in " .. prof )
							label:SizeToContentsX( 10 )
							prompt:SetWidth( label:GetWide() + box:GetWide() + UI_ICONBUTTON_W * 2 + 10 )
							prompt:SetPos( x-(label:GetWide()-lsize), y)

							timer.Simple( 1.5, function()
								if ispanel( label ) and label:IsValid() then
									label:SetText( txt )
									label:SizeToContentsX( 10 )
									prompt:SetWidth( label:GetWide() + box:GetWide() + UI_ICONBUTTON_W * 2 + 10 )
									prompt:SetPos( x, y )
								end
							end )

							return
						end
					end
				end
				if #matches > 0 then
					label:SetText( ( #matches == 1 and table.GetLastValue(matches) .. " already exists" or #matches .. " presets already exist" ) .. " in " .. prof .. ". Overwrite?" )
					label:SizeToContentsX( 10 )
					prompt:SetPos( x-(label:GetWide()-lsize), y)
					
					if #matches > 1 then
						owlabel = vgui.Create( "DLabel", prompt )
						owlabel:Dock( LEFT )
						owlabel:SetText( table.concat( matches, "\n" ) )
						owlabel:SetAutoStretchVertical( true )
						owlabel:SetDark( true )
						owlabel:DockMargin( 0, 5, 0, 0 )
						owlabel:SizeToContentsX( 10 )
						owlabel:SizeToContentsY( 10 )
						prompt:SetTall( math.max( UI_ENTRY_H, owlabel:GetTall() ) ) --UI_ENTRY_H
					end
					prompt:SetWidth( label:GetWide() + ( IsValid( owlabel ) and owlabel:GetWide() or 0 ) + UI_ICONBUTTON_W * 2 + 10 )
					box:SetVisible( false )
					confirm2 = true
					return
				end
			// unused
			-- elseif set and prs then
			-- 	local prof = box:GetSelected()
			-- 	local pkeys = GetSetsPresets( prof, set )
			-- 	if pkeys[prs] then
			-- 		label:SetText( "Already exists" )
			-- 		timer.Simple( 1.5, function()
			-- 			if ispanel( label ) and label:IsValid() then
			-- 				label:SetText( txt )
			-- 			end
			-- 		end )
			-- 		return
			-- 	end
			else
				Error( "\nError: MovePrompt > error: neither tbl nor prs??","\n\n" )
				return
			end

			// success
			submitFunc( box:GetSelected() )
			prompt:Remove()
		end
	end
end

function HasPreset( tbl, prof, set, prs )
	return tbl and prof and set and prs and tbl[prof] and tbl[prof][set] and tbl[prof][set][prs] or nil
end
function HasSet( tbl, prof, set )
	return tbl and prof and set and tbl[prof] and tbl[prof][set] or nil
end

// insert either "true" or given value
function AddPresetPend( tbl, prof, set, prs, new )
	if not ( tbl and prof and set and prs ) then return nil end
	tbl[prof] = tbl[prof] or {}
	tbl[prof][set] = tbl[prof][set] or {}
	if new != nil then
		tbl[prof][set][prs] = new
	else
		tbl[prof][set][prs] = true
	end
	return tbl[prof][set][prs]
end
function RemovePresetPend( tbl, prof, set, prs )
	if HasPreset( tbl, prof, set, prs ) then
		tbl[prof][set][prs] = nil
	end
end


function CreateSettingsPanel()
    SettingsWindow = vgui.Create( "DFrame" )
	active_prof = nil
	active_set = nil
	active_prs = nil

    SettingsWindow:SetSize( last_panel_w, last_panel_h )
	if !last_panel_x or !last_panel_y then
    	SettingsWindow:Center()
	else
		SettingsWindow:SetPos( last_panel_x, last_panel_y )
	end
	last_panel_x, last_panel_y = SettingsWindow:GetPos()
	UpdateSettingsTitle()
    -- SettingsWindow:SetTitle( settings_title ) --.. ( cl_currentProfile ~= nil and " - Active Profile: " .. cl_currentProfile or "" ))
    SettingsWindow:SetDraggable( true )
	SettingsWindow:SetSizable( true )
	SettingsWindow:SetMinWidth( UI_ICONBUTTON_W * 12 + 58 )
	SettingsWindow:SetMinHeight( 100 )	
    SettingsWindow:MakePopup()
	SettingsWindow:SetDeleteOnClose( false )
	-- SettingsWindow:SetMinimumSize( nil, 27 )

	SettingsSheet = vgui.Create( "DPropertySheet", SettingsWindow )
	SettingsSheet:Dock( FILL )

	SettingsSheet.OnActiveTabChanged = function( self, old, new )
		// sheet.Tab.panel
		if old.panel and isfunction( old.panel.HideSelectors ) then
			old.panel:HideSelectors()
		end
		if new.panel and isfunction( new.panel.ShowSelectors ) then
			new.panel:ShowSelectors()
		end
		-- tab_title = ( new.Name and ": " .. new.Name or "" )
		UpdateSettingsTitle()
	end

	SettingsSheet:SetupCloseButton( function()
		local tab = SettingsSheet:GetActiveTab()
		if tab.prof then
			CloseValueEditor( tab.prof, tab.set, tab.prs )
			timer.Simple( 0, UpdatePresetSelection )
		end
		timer.Simple( engine.TickInterval(), function()
			if !IsValid( SettingsWindow ) then return end
			local tab = SettingsSheet:GetActiveTab()
			-- if tab then
			-- 	tab_title = ( tab.Name and ": " .. tab.Name or "" )
			-- else
			-- 	tab_title = ""
			-- end
			UpdateSettingsTitle()
			if tab and tab.panel and isfunction( tab.panel.ShowSelectors ) then
				tab.panel:ShowSelectors()
			end
		end)
	end )

	SettingsPane = vgui.Create( "Panel", SettingsSheet )
	-- SettingsPane:SetBackgroundColor( Color( 0, 0, 0, 0 ) )

	local ProfilesSheet = SettingsSheet:AddSheet( "Profiles", SettingsPane )
	ProfilesSheet.Tab.panel = SettingsPane // for Hide/ShowSelectors() from CreateValueEditor()

	// three columns from two dividers
	LeftDivider = vgui.Create( "DHorizontalDivider", SettingsPane )
	RightDivider = vgui.Create( "DHorizontalDivider", SettingsPane )
	LeftPanel = vgui.Create( "DPanel", SettingsPane )
	CenterPanel = vgui.Create( "Panel", SettingsPane )
	RightPanel = vgui.Create( "Panel", SettingsPane )
	-- RightPanel = vgui.Create( "DPanel", SettingsPane )
	VertDivider = vgui.Create( "DVerticalDivider", SettingsPane )

	PendingPanel = vgui.Create( "Panel", SettingsPane )
	PendingList = vgui.Create( "DListView", PendingPanel )

	VertDivider:SetTop( LeftDivider )
	VertDivider:SetBottom( PendingPanel )
	VertDivider:SetTopHeight( last_panel_h * 0.65 )
	
	-- LeftDivider:Dock(FILL)
	LeftDivider:SetLeft( LeftPanel )
	-- LeftDivider:SetRight( RightDivider )
	LeftDivider:SetRight( CenterPanel )
	LeftDivider:SetLeftMin( UI_ICONBUTTON_W * 5 )
	LeftDivider:SetRightMin( UI_ICONBUTTON_W * 5 )
	LeftDivider:SetLeftWidth( last_ld_w or 180 )

	RightDivider:Dock(FILL)	
	-- RightDivider:SetLeft( CenterPanel )
	RightDivider:SetLeft( VertDivider )
	RightDivider:SetRight( RightPanel )
	RightDivider:SetLeftMin( LeftDivider:GetLeftMin() + LeftDivider:GetRightMin() + 8 ) --UI_ICONBUTTON_W * 8 )
	-- RightDivider:SetRightMin( 0 )
	RightDivider:SetLeftWidth( last_rd_w or 180 + UI_ICONBUTTON_W * 10 + 8 )

	// LEFT COLUMN

	// profile list
	ProfilePanel = vgui.Create( "Panel", LeftPanel )
	-- ProfilePanel:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	
	SettingsList = vgui.Create( "DListView", ProfilePanel )
	SettingsList:SetMultiSelect( true )
	SettingsList:Dock( FILL )

	// profile buttons
	ProfileButtons = vgui.Create( "Panel", ProfilePanel )
	-- ProfileButtons:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	ProfileButtons:Dock( BOTTOM )
	ProfileButtons:SetHeight( UI_BUTTON_H )

	ProfileButtons.change = vgui.Create( "DButton", ProfileButtons )
	ProfileButtons.change:Dock( LEFT )
	ProfileButtons.change:SetImage( UI_ICONS.change )
	ProfileButtons.change:SetText( "" )
	ProfileButtons.change:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )
	ProfileButtons.change:SetToolTip( "Set as active profile [double-click]" )

	ProfileButtons.add = vgui.Create( "DButton", ProfileButtons )
	ProfileButtons.add:Dock( LEFT )
	ProfileButtons.add:SetImage( UI_ICONS.add )
	ProfileButtons.add:SetText( "" )
	ProfileButtons.add:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )
	ProfileButtons.add:SetToolTip( "Add new profile" )

	ProfileButtons.copy = vgui.Create( "DButton", ProfileButtons )
	ProfileButtons.copy:Dock( LEFT )
	ProfileButtons.copy:SetImage( UI_ICONS.copy )
	ProfileButtons.copy:SetText( "" )
	ProfileButtons.copy:SetToolTip( "Copy selected profile" )
	ProfileButtons.copy:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )

	ProfileButtons.rename = vgui.Create( "DButton", ProfileButtons )
	ProfileButtons.rename:Dock( LEFT )
	ProfileButtons.rename:SetImage( UI_ICONS.rename )
	ProfileButtons.rename:SetText( "" )
	ProfileButtons.rename:SetToolTip( "Rename selected profile" )
	ProfileButtons.rename:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )

	ProfileButtons.sub = vgui.Create( "DButton", ProfileButtons )
	ProfileButtons.sub:Dock( LEFT )
	ProfileButtons.sub:SetImage( UI_ICONS.sub )
	ProfileButtons.sub:SetText( "" )
	ProfileButtons.sub:SetToolTip( "Remove selected profile\nDeleted profiles are sent to a trash folder" )
	ProfileButtons.sub:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )

	ProfileButtons:SizeToChildren( false, true )

	ProfileButtons.change.OnReleased = function( self )
		if CheckClientPerm( LocalPlayer(), cvar.perm_prof.v:GetInt() ) then
			local line = select( 2, SettingsList:GetSelectedLine() )
			if line then ClientSwitchProfile( line:GetColumnText(1) ) end
		end
	end

	ProfileButtons.add.OnReleased = function( self )
		if CheckClientPerm( LocalPlayer() ) then
			local x, y = SettingsList:LocalToScreen()
			local sx, sy = SettingsWindow:LocalToScreen()
			-- y = y + py - sy + SettingsList:GetDataHeight() + math.min( SettingsList:GetInnerTall(), SettingsList:GetTall() - SettingsList:GetDataHeight() - UI_BUTTON_H )
			
			y = math.Clamp( y + SettingsList:GetInnerTall() + SettingsList:GetDataHeight(), y, y + SettingsList:GetTall() ) - sy -- - PresetsButtons:GetTall() )
			x = x - sx - 5

			local count = table.Count( cl_Profiles )
			local copycount = 1
			local defname = "profile " .. ( count + 1 )

			while cl_Profiles[defname] ~= nil do
				copycount = copycount + 1
				defname = "profile " .. ( count + copycount )
			end
			
			TextPrompt(
				SettingsWindow,
				x,
				y,
				defname, -- "profile" .. ( count == 0 and "" or " "..count ) ,
				function( text )
					ClientCreateProfile( string.Trim(text) )
				end
			)
		end
	end

	ProfileButtons.copy.OnReleased = function( self )
		if CheckClientPerm( LocalPlayer() ) then
			for _, line in pairs( SettingsList:GetSelected() ) do
				ClientCopyProfile( line:GetColumnText(1) )
			end
		end
	end

	ProfileButtons.rename.OnReleased = function( self )
		if CheckClientPerm( LocalPlayer() ) and SettingsList:GetSelectedLine() then
			for _, line in pairs( SettingsList:GetSelected() ) do
				-- local line = select( 2, SettingsList:GetSelectedLine() )
				local x, y = line:LocalToScreen()
				local px, py = SettingsList:LocalToScreen()
				local sx, sy = SettingsWindow:LocalToScreen()
				y = math.Clamp( y, py, py + SettingsList:GetTall() ) - sy - SettingsList:GetDataHeight() * 0.25
				x = x - sx - 5

				-- local x, y = line:GetPos()
				-- local px, py = SettingsList:LocalToScreen()
				-- local sx, sy = SettingsWindow:LocalToScreen()
				-- y = y + py - sy + SettingsList:GetDataHeight() * 0.75
				-- x = px - sx - 5
				local oldp = line:GetColumnText( 1 )
				TextPrompt(
					SettingsWindow,
					x,
					y,
					oldp,
					function( text )
						ClientRenameProfile( oldp, string.Trim(text) )
					end,
					nil,
					cl_Profiles
				)
			end
		end
	end

	ProfileButtons.sub.OnReleased = function( self )
		if CheckClientPerm( LocalPlayer() ) and SettingsList:GetSelectedLine() then
			local proflist = {}
			for k, line in pairs( SettingsList:GetSelected() ) do
				table.insert( proflist, line:GetColumnText(1) )
			end

			local line = select( 2, SettingsList:GetSelectedLine() )
			local x, y = line:LocalToScreen()
			local px, py = SettingsList:LocalToScreen()
			local sx, sy = SettingsWindow:LocalToScreen()
			y = math.Clamp( y, py, py + SettingsList:GetTall() ) - sy - SettingsList:GetDataHeight() * 0.25
			x = x - sx - 5

			-- local x, y = line:GetPos()
			-- local px, py = SettingsList:LocalToScreen()
			-- local sx, sy = SettingsWindow:LocalToScreen()
			-- y = y + py - sy + SettingsList:GetDataHeight() * 0.75
			-- x = px - sx - 5

			local p = line:GetColumnText( 1 )
			ConfirmPrompt(
				SettingsWindow,
				x,
				y,
				#proflist > 1 and "Are you sure you want to trash " .. #proflist .. " profiles?\nThe files will be moved to a trash folder."
				or "Are you sure you want to trash \"" .. p .. "\"?\nThe file will be moved to a trash folder.",
				function()
					for _, p in ipairs( proflist ) do
						ClientDeleteProfile( p )
					end
				end
			)
			-- end
		end
	end

	SettingsList.Menu = function( self )
		local multiselect = #SettingsList:GetSelected() > 1
		local line = select( 2, SettingsList:GetSelectedLine() )
		local selectprof = line and line:GetColumnText( 1 )
		local menu = DermaMenu()
		menu:AddOption( "Set \"" .. selectprof .. "\" as active profile", function()
			ProfileButtons.change:OnReleased()
		end )
		menu:AddOption( "Add new profile", function()
			ProfileButtons.add:OnReleased()
		end )
		menu:AddOption( multiselect and "Copy selected profiles" or "Copy profile", function()
			ProfileButtons.copy:OnReleased()
		end )
		menu:AddOption( "#spawnmenu.menu.copy", function()
			local str = ""
			local first = true
			for _, line in ipairs( SettingsList:GetSelected() ) do
				if first then
					str = str .. line:GetColumnText(1)
					first = nil
				else
					str = str .. "\n" .. line:GetColumnText(1)
				end
			end
			SetClipboardText( str )
		end )
		menu:AddOption( multiselect and "Rename selected profiles" or "Rename profile", function()
			ProfileButtons.rename:OnReleased()
		end )
		menu:AddOption( multiselect and "Delete selected profiles" or "Delete profile", function()
			ProfileButtons.sub:OnReleased()
		end )
		menu:Open()
	end

	SettingsList.DoDoubleClick = function( self, id, line )
		ProfileButtons.change:OnReleased()
	end

	SettingsList.OnRowRightClick = function( self, id, line )
		-- ProfileButtons.rename:OnReleased()
		self:Menu()
	end

	SettingsList.OnRowSelected = function( panel, rowIndex, row )
		UpdatePresetSelection()
	end

	SettingsList.col_name = SettingsList:AddColumn( "Profile" )
	SettingsList.col_name:SetToolTip( "Profile" )
	SettingsList.col_active = SettingsList:AddColumn( "*" )
	SettingsList.col_active:SetTooltip( "Active Profile" )
	SettingsList.col_active:SetFixedWidth( UI_TEXT_H / 2 )
	SettingsList.col_num = SettingsList:AddColumn( "##" )
	SettingsList.col_num:SetTooltip( "Number of Presets" )
	SettingsList.col_num:SetMinWidth( 19 )
	SettingsList.col_num:SetMaxWidth( UI_TEXT_H * 2 )
	SettingsList.col_name:SetWidth( LeftDivider:GetLeftWidth() - 20 )
	
	// pending list
	PendingList:Dock( FILL )
	PendingList.col_act = PendingList:AddColumn("")
	PendingList.col_prof = PendingList:AddColumn("Profile")
	PendingList.col_set = PendingList:AddColumn("Type")
	PendingList.col_prs = PendingList:AddColumn("Preset")
	PendingList.col_act:SetFixedWidth( UI_TEXT_H * 0.65 )
	PendingList.col_act:SetToolTip( "Pending Act\n+Add, %Edit, —Remove, ?Viewing" )
	-- PendingList:SetHideHeaders( true )

	PendingList.ClearSelectedPend = function( self )
		if !self:GetSelectedLine() then return end
		local pendlist = {}
		for k, l in pairs( self:GetSelected() ) do
			local act = l:GetColumnText( 1 )
			local p = l:GetColumnText( 2 )
			local s = l:GetColumnText( 3 )
			local prs = l:GetColumnText( 4 )
			table.insert( pendlist, { act, p, s, prs } )
		end

		local line = select( 2, self:GetSelectedLine() )
		-- local x, y = line:GetPos()
		local x, y = line:LocalToScreen()
		local px, py = self:LocalToScreen()
		local sx, sy = SettingsWindow:LocalToScreen()
		-- y = y + py - sy + self:GetDataHeight() * 0.75
		-- x = px - sx - 5
		y = math.Clamp( y, py, py + self:GetTall() ) - sy - ( self:GetDataHeight() * 0.25 ) 
		-- y = y - sy - self:GetDataHeight() * 0.25
		x = x - sx - 5

		ConfirmPrompt(
			SettingsWindow,
			x,
			y,
			#pendlist > 1 and "Are you sure you want to clear " .. #pendlist .. " pending?"
			or pendlist[1] and "Are you sure you want to clear pending \"" .. pendlist[1][2] .. " > " ..  pendlist[1][3] .. " > " .. pendlist[1][4] .. "\"?",
			function()
				for _, pend in ipairs( pendlist ) do
					local act, p, s, prs = pend[1], pend[2], pend[3], pend[4]
					if act == "+" or act == "%" then
						RemovePresetPend( PendingSettings, p, s, prs )
						RemovePresetPend( PendingAdd, p, s, prs )
					elseif act == "—" then
						RemovePresetPend( PendingRemove, p, s, prs )
					end
					CloseValueEditor( p, s, prs )
				end
				UpdateProfilesList()
				UpdatePresetSelection()
			end
		)
	end

	PendingList.OpenEditors = function( self, windowed )
		for k, line in pairs( self:GetSelected() ) do
			local p = line:GetColumnText( 2 )
			local s = line:GetColumnText( 3 )
			local prs = line:GetColumnText( 4 )
			GetOrCreateValueEditor( p, s, prs, windowed )
		end
	end

	PendingList.DoDoubleClick = function( self, id, line )
		for k, line in pairs( PendingList:GetSelected() ) do
			local p = line:GetColumnText( 2 )
			local s = line:GetColumnText( 3 )
			local prs = line:GetColumnText( 4 )
			GetOrCreateValueEditor( p, s, prs )
		end
	end

	PendingList.OnRowRightClick = function( self, id, line )
		PendingList:Menu()
	end

	PendingList.Menu = function( self )
		local menu = DermaMenu()
		menu:AddOption( "Open selected in tabs", function()
			PendingList:OpenEditors()
		end )
		menu:AddOption( "Open selected in windows", function()
			PendingList:OpenEditors( true )
		end )
		menu:AddOption( "#spawnmenu.menu.copy", function()
			local str = ""
			local first = true
			for _, line in ipairs( PendingList:GetSelected() ) do
				local act = line:GetColumnText( 1 )
				local p = line:GetColumnText( 2 )
				local s = line:GetColumnText( 3 )
				local prs = line:GetColumnText( 4 )
				if first then
					str = str .. "[" .. act .. "] " .. p .. " > " .. s .. " > " .. prs
					first = nil
				else
					str = str .. "\n" .. "[" .. act .. "] " .. p .. " > " .. s .. " > " .. prs
				end
			end
			SetClipboardText( str )
		end )
		menu:AddOption( "Print selected to console", function()
			for k, line in pairs( PendingList:GetSelected() ) do
				local p = line:GetColumnText( 2 )
				local s = line:GetColumnText( 3 )
				local prs = line:GetColumnText( 4 )
				
				if HasPreset( PendingRemove, p, s, prs ) then
					print( "<REMOVING> " .. p .. " > " .. s .. " > " .. prs )
				end
				if HasPreset( PendingSettings, p, s, prs ) then
					print( ( HasPreset( PendingAdd, p, s, prs ) and "<PENDING ADD/EDIT> " or "<NONPENDING> " ) .. p .. " > " .. s .. " > " .. prs .. "")
					PrintTable( HasPreset( PendingSettings, p, s, prs ), 1 )
				end
				if HasPreset( PendingView, p, s, prs ) then
					print( "<VIEW TABLE> " .. p .. " > " .. s .. " > " .. prs )
					PrintTable( HasPreset( PendingView, p, s, prs ), 1 )
				end
			end
		end )
		menu:AddOption( "Clear selected", function()
			if IsValid( PendingList ) then
				PendingList:ClearSelectedPend()
			end
		end )
		menu:Open()
	end
		

	// commit/clear
	PendingButtons = vgui.Create( "DPanel", PendingPanel )
	PendingButtons:Dock( BOTTOM )
	PendingButtons:SetHeight( UI_BUTTON_H )

	ClearButton = vgui.Create( "DButton", PendingButtons )
	ClearButton:Dock( LEFT )
	ClearButton:SetText( "Clear All" )
	ClearButton.OnReleased = function()
		ClearPending()
		ClearValueEditors()
		UpdatePresetSelection()
		-- DeselectSettingsList()
	end

	CommitButton = vgui.Create( "DButton", PendingButtons )
	CommitButton:Dock( RIGHT )
	CommitButton:SetText( "Submit Changes" )
	CommitButton.OnReleased = function()
		SendSettingsCommit()
		DeselectPresetsList()
		CommitButton:SetDisabled( true ) // reenabled in SendSettingsCommit
		ClearButton:SetDisabled( true ) // reenabled in SendSettingsCommit
		-- ClearValueEditors()
	end

	CommitButton:SetWidth( RightDivider:GetLeftWidth() / 2 )
	ClearButton:SetWidth( RightDivider:GetLeftWidth() / 2 )

	// missing required presets warning
	WarningBox = vgui.Create( "Panel", PendingPanel )
	-- WarningBox:SetBackgroundColor( Color(0,0,0,0) )
	WarningBox:Dock( BOTTOM )
	WarningBox:DockMargin( marg, marg, marg, marg )
	WarningBox:SetZPos( 1 )
	WarningBox:SetHeight( 0 )
	WarningBox.text = vgui.Create( "DLabel", WarningBox )
	WarningBox.text:SetText( "" )
	WarningBox.text:Dock( FILL )
	WarningBox.text:SetDark( true )
	WarningBox.text:SetWrap( true )
	WarningBox:Hide()

	// preset types
	SetsList = vgui.Create( "DListView", LeftPanel )
	SetsList:SetMultiSelect( false )
	SetsList.col_name = SetsList:AddColumn( "Preset Type" )
	SetsList.col_name:SetToolTip( "Preset Type" )
	SetsList.col_num = SetsList:AddColumn( "##" )
	SetsList.col_num:SetTooltip( "Number of Enabled Presets / Total Presets" )
	SetsList.col_num:SetMinWidth( 19 )
	SetsList.col_num:SetMaxWidth( UI_TEXT_H * 2 )

	SetsList.col_name:SetWidth( LeftDivider:GetLeftWidth() - 42 )
	SetsList.col_num:SetWidth( 42 )

	SetsList.OnRowSelected = function( panel, rowIndex, row )
		UpdatePresetSelection()
	end

	// column vertical dividers
	LeftP_TopDiv = vgui.Create( "DVerticalDivider", LeftPanel )
	-- LeftP_BotDiv = vgui.Create( "DVerticalDivider", LeftPanel )

	LeftP_TopDiv:Dock( FILL )
	-- LeftP_TopDiv:SetBottom( LeftP_BotDiv )

	if cl_cvar.panel_leftvertflip.v:GetBool() then
		LeftP_TopDiv:SetTop( SetsList )
		LeftP_TopDiv:SetBottom( ProfilePanel )
		LeftP_TopDiv:SetTopHeight( SetsList:GetDataHeight() * 9 )
	else
		LeftP_TopDiv:SetTop( ProfilePanel )
		LeftP_TopDiv:SetBottom( SetsList )
		LeftP_TopDiv:SetTopHeight( VertDivider:GetTopHeight() - SetsList:GetDataHeight() * 9 - 8 )
	end

	-- LeftP_BotDiv:Dock( BOTTOM )
	-- LeftP_BotDiv:SetTop( SetsList )
	-- LeftP_BotDiv:SetBottom( PendingPanel )
	-- LeftP_BotDiv:SetTopHeight( SetsList:GetDataHeight() * 9 )

	// MIDDLE COLUMN

	// header
	PresetsHeader = vgui.Create( "DPanel", CenterPanel )
	-- CenterPanel:SetBackgroundColor( Color( 157, 161, 165, 255 ) ) 
	PresetsHeader:SetBackgroundColor( Color( 255, 255, 255, 0 ) ) 
	PresetsHeader.txt = Label( "", PresetsHeader )
	PresetsHeader.txt:Dock( FILL )
	PresetsHeader:Dock( TOP )
	PresetsHeader.txt:SetColor( Color( 255,255,255) )
	PresetsHeader:SetHeight( 21 )
	PresetsHeader.txt:SetContentAlignment( 5 )
	-- PresetsHeader:SetContentAlignment( 5 )

	// presets list
	PresetsList = vgui.Create( "DListView", CenterPanel )
	PresetsList:SetMultiSelect( true )
	PresetsList:Dock( FILL )
	PresetsList.col_enabled = PresetsList:AddColumn( "" )
	PresetsList.col_enabled:SetToolTip("Enabled")
	PresetsList.col_name = PresetsList:AddColumn( "Preset" )
	PresetsList.col_name:SetToolTip( "Preset" )
	PresetsList.col_window = PresetsList:AddColumn( "" )
	PresetsList.col_window:SetToolTip("Has Editor Open\n%Tab, //Window")
	PresetsList.col_enabled:SetMinWidth( 24 )
	PresetsList.col_enabled:SetFixedWidth( 24 )
	PresetsList.col_window:SetMinWidth( 24 )
	PresetsList.col_window:SetFixedWidth( 24 )
	PresetsList.boxes = {}

	// presets buttons
	PresetsButtons = vgui.Create( "Panel", CenterPanel )
	-- PresetsButtons:SetBackgroundColor( Color( 0, 0, 0, 0 ) )
	PresetsButtons:Dock( BOTTOM )

	local pbuttons = {}

	PresetsButtons.row1 = vgui.Create( "Panel", PresetsButtons )
	PresetsButtons.row1:Dock( BOTTOM )
	PresetsButtons.row1:SetTall( 0 )

	PresetsButtons.row2 = vgui.Create( "Panel", PresetsButtons )
	PresetsButtons.row2:Dock( BOTTOM )
	PresetsButtons.row2:SetTall( UI_ICONBUTTON_W )

	PresetsButtons:SetHeight( PresetsButtons.row1:GetTall() + PresetsButtons.row2:GetTall() )

	PresetsButtons.tab = vgui.Create( "DButton", PresetsButtons.row2 )
	PresetsButtons.tab:Dock( LEFT )
	PresetsButtons.tab:SetImage( UI_ICONS.tab )
	PresetsButtons.tab:SetText( "" )
	PresetsButtons.tab:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )
	PresetsButtons.tab:SetToolTip( "Edit preset in new tab [double-click]" )
	table.insert( pbuttons, PresetsButtons.tab )

	PresetsButtons.window = vgui.Create( "DButton", PresetsButtons.row2 )
	PresetsButtons.window:Dock( LEFT )
	PresetsButtons.window:SetImage( UI_ICONS.window )
	PresetsButtons.window:SetText( "" )
	PresetsButtons.window:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )
	PresetsButtons.window:SetToolTip( "Edit preset in new window" )
	table.insert( pbuttons, PresetsButtons.window )

	PresetsButtons.close = vgui.Create( "DButton", PresetsButtons.row2 )
	PresetsButtons.close:Dock( LEFT )
	PresetsButtons.close:SetImage( UI_ICONS.close )
	PresetsButtons.close:SetText( "" )
	PresetsButtons.close:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )
	PresetsButtons.close:SetToolTip( "Close selected editors" )
	table.insert( pbuttons, PresetsButtons.close )

	PresetsButtons.add = vgui.Create( "DButton", PresetsButtons.row2 )
	PresetsButtons.add:Dock( LEFT )
	PresetsButtons.add:SetImage( UI_ICONS.add )
	PresetsButtons.add:SetText( "" )
	PresetsButtons.add:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )
	PresetsButtons.add:SetToolTip( "Add preset" )
	table.insert( pbuttons, PresetsButtons.add )

	PresetsButtons.copy = vgui.Create( "DButton", PresetsButtons.row2 )
	PresetsButtons.copy:Dock( LEFT )
	PresetsButtons.copy:SetImage( UI_ICONS.copy )
	PresetsButtons.copy:SetText( "" )
	PresetsButtons.copy:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )
	PresetsButtons.copy:SetToolTip( "Copy preset" )
	table.insert( pbuttons, PresetsButtons.copy )

	PresetsButtons.rename = vgui.Create( "DButton", PresetsButtons.row2 )
	PresetsButtons.rename:Dock( LEFT )
	PresetsButtons.rename:SetImage( UI_ICONS.rename )
	PresetsButtons.rename:SetText( "" )
	PresetsButtons.rename:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )
	PresetsButtons.rename:SetToolTip( "Rename preset" )
	table.insert( pbuttons, PresetsButtons.rename )

	PresetsButtons.sub = vgui.Create( "DButton", PresetsButtons.row2 )
	PresetsButtons.sub:Dock( LEFT )
	PresetsButtons.sub:SetImage( UI_ICONS.sub )
	PresetsButtons.sub:SetText( "" )
	PresetsButtons.sub:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )
	PresetsButtons.sub:SetToolTip( "Delete preset" )
	table.insert( pbuttons, PresetsButtons.sub )

	PresetsButtons.move = vgui.Create( "DButton", PresetsButtons.row2 )
	PresetsButtons.move:Dock( LEFT )
	PresetsButtons.move:SetImage( UI_ICONS.move )
	PresetsButtons.move:SetText( "" )
	PresetsButtons.move:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )
	PresetsButtons.move:SetToolTip( "Move preset to other profile" )
	table.insert( pbuttons, PresetsButtons.move )

	PresetsButtons.copymove = vgui.Create( "DButton", PresetsButtons.row2 )
	PresetsButtons.copymove:Dock( LEFT )
	PresetsButtons.copymove:SetImage( UI_ICONS.copymove )
	PresetsButtons.copymove:SetText( "" )
	PresetsButtons.copymove:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )
	PresetsButtons.copymove:SetToolTip( "Copy preset to other profile" )
	table.insert( pbuttons, PresetsButtons.copymove )

	PresetsButtons.spawn = vgui.Create( "DButton", PresetsButtons.row2 )
	PresetsButtons.spawn:Dock( LEFT )
	PresetsButtons.spawn:SetImage( UI_ICONS.spawn )
	PresetsButtons.spawn:SetText( "" )
	PresetsButtons.spawn:SetSize( UI_ICONBUTTON_W, UI_ICONBUTTON_W )
	PresetsButtons.spawn:SetToolTip( "Spawn preset\nMust be the active profile\nDoesn't use pending changes" )
	table.insert( pbuttons, PresetsButtons.spawn )

	PresetsButtons.CanRow = false // fix buttons adjusting to initial window size
	PresetsButtons.ReRow = function( self )
		if !PresetsButtons.CanRow then return end
		local c = 1
		local r1
		for i=UI_ICONBUTTON_W,math.max(PresetsButtons:GetParent():GetWide(),UI_ICONBUTTON_W*5),UI_ICONBUTTON_W do
			if !pbuttons[c] then break end
			pbuttons[c]:SetParent( PresetsButtons.row2 )
			pbuttons[c]:Dock( LEFT )
			c=c+1
		end
		for i=c,#pbuttons do
			r1 = true
			pbuttons[c]:SetParent( PresetsButtons.row1 )
			pbuttons[c]:Dock( LEFT )
			c=c+1
		end
		if !r1 then
			PresetsButtons.row1:SetTall( 0 )
		else
			PresetsButtons.row1:SetTall( UI_ICONBUTTON_W )
		end
		PresetsButtons:SetHeight( PresetsButtons.row1:GetTall() + PresetsButtons.row2:GetTall() )
	end

	timer.Simple( engine.TickInterval(), function()
		if IsValid( PresetsButtons ) then
			PresetsButtons.CanRow = true
			PresetsButtons.ReRow()
		end
	end )

	PresetsButtons.add.OnReleased = function()
		if CheckClientPerm( LocalPlayer(), cvar.perm_prof.v:GetInt() ) and active_prof and active_set then
			local x, y = PresetsList:LocalToScreen()
			local sx, sy = SettingsWindow:LocalToScreen()
			-- y = y + math.min( PresetsList:GetInnerTall(), PresetsList:GetTall() - PresetsList:GetDataHeight() - UI_ICONBUTTON_W * 2 ) + PresetsList:GetDataHeight() - sy
			-- x = x - sx
			y = math.Clamp( y + PresetsList:GetInnerTall() + PresetsList:GetDataHeight(), y, y + PresetsList:GetTall() - PresetsButtons:GetTall() - PresetsList:GetDataHeight() * 0.25 ) - sy
			x = x - sx - 5
			local count = 0
			local pctbl = {}
			for k in pairs( cl_Profiles[active_prof][active_set] ) do
				pctbl[k] = true
			end
			if HasSet( PendingSettings, active_prof, active_set ) then
				for k in pairs( PendingSettings[active_prof][active_set] ) do
					pctbl[k] = true
				end
			end
			count = table.IsEmpty( pctbl ) and 0 or table.Count( table.GetKeys( pctbl ) )

			local s = active_set
			local p = active_prof
			TextPrompt(
				SettingsWindow,
				x,
				y,
				"New Preset" .. ( count == 0 and "" or " "..count ) ,
				function( text )
					local newname = string.Trim(text)
					if HasPreset( PendingSettings, p, s, newname ) then
						local c = 2
						local n = newname
						while PendingSettings[p][s][n] do
							n = newname .. " (" .. c .. ")"
							c=c+1
						end
						newname = n
					end
					if HasPreset( PendingRemove, p, s, newname ) then
						PendingRemove[p][s][newname] = nil
					end
					AddPresetPend( PendingAdd, p, s, newname )
					GetPendingTbl( p, s, newname )
					PendingSettings[p][s][newname] = {}
					print( PendingSettings[p][s][newname] )
					UpdateProfilesList()
					UpdatePresetSelection( true )
				end
			)
		end
	end

	PresetsButtons.sub.OnReleased = function()
		if CheckClientPerm( LocalPlayer(), cvar.perm_prof.v:GetInt() ) and PresetsList:GetSelectedLine() and active_prof and active_set then --and active_prof and active_set and active_prs then
			local prslist = {}
			for k, line in pairs( PresetsList:GetSelected() ) do
				table.insert( prslist, line:GetColumnText(2) )
			end

			local line = select( 2, PresetsList:GetSelectedLine() )// first selected line
			-- local x, y = line:GetPos()
			local px, py = PresetsList:LocalToScreen()
			local sx, sy = SettingsWindow:LocalToScreen()
			local x, y = line:LocalToScreen()
			y = math.Clamp( y, py, py + PresetsList:GetTall() - PresetsButtons:GetTall() ) - sy - ( PresetsList:GetDataHeight() * 0.25 ) 
			x = px - sx - 5 
			-- y = y + py - sy + PresetsList:GetDataHeight() * 0.75
			-- x = px - sx - 5
			local s = active_set
			local p = active_prof
			-- local fprs = line:GetColumnText(2) --active_prs
			ConfirmPrompt(
				SettingsWindow,
				x,
				y,
				#prslist > 1 and "Are you sure you want to delete " .. #prslist .. " presets?"
				or "Are you sure you want to delete \"" .. line:GetColumnText(2) .. "\"?",
				function()
					for _, prs in ipairs( prslist ) do
						RemovePresetPend( PendingSettings, p, s, prs )
						RemovePresetPend( PendingAdd, p, s, prs )

						if HasPreset( cl_Profiles, p, s, prs ) then
							AddPresetPend( PendingRemove, p, s, prs )
						end

						CloseValueEditor( p, s, prs )
					end
					UpdateProfilesList()
					UpdatePresetSelection( true )
				end
			)
		end
	end

	PresetsButtons.rename.OnReleased = function()
		if CheckClientPerm( LocalPlayer(), cvar.perm_prof.v:GetInt() ) and PresetsList:GetSelectedLine() and active_prof and active_set then --and active_prof and active_set and active_prs then
			for k, line in pairs( PresetsList:GetSelected() ) do
				-- local x, y = line:GetPos()
				local px, py = PresetsList:LocalToScreen()
				local sx, sy = SettingsWindow:LocalToScreen()
				-- y = y + py - sy + PresetsList:GetDataHeight() * 0.75
				-- x = px - sx - 5
				local x, y = line:LocalToScreen()
				y = math.Clamp( y, py, py + PresetsList:GetTall() - PresetsButtons:GetTall() ) - sy - ( PresetsList:GetDataHeight() * 0.25 ) 
				x = px - sx - 5 
				local s = active_set
				local p = active_prof
				local prs = line:GetColumnText(2) -- active_prs
				TextPrompt(
					SettingsWindow,
					x,
					y,
					prs,
					function( text )
						-- print( text, s, p, prs )
						// if already exists
						local newname = string.Trim(text)
						if GetSetsPresets( p, s )[newname] != nil then
							return
						end

						RemovePresetPend( PendingRemove, p, s, newname ) // not actually necessary because of how settings commit but it just looks wrong on the pending list

						GetPendingTbl( p, s, newname )
						PendingSettings[p][s][newname] = GetPendingTbl( p, s, prs ) --PendingSettings[p][s][prs]
						PendingSettings[p][s][prs] = nil

						AddPresetPend( PendingAdd, p, s, newname )
						RemovePresetPend( PendingAdd, p, s, prs )
						if HasPreset( cl_Profiles, p, s, prs ) then
							AddPresetPend( PendingRemove, p, s, prs )
						end

						CloseValueEditor( p, s, prs )

						RenameAllReferences( p, s, prs, newname )

						UpdateProfilesList()
						if active_prs == prs then
							DeselectPresetsList()
						end
						UpdatePresetSelection( true )
						if prs == active_prs then
							timer.Simple( engine.TickInterval(), function()
								if p == active_prof and s == active_set then
									for i, line in ipairs( PresetsList:GetLines() ) do
										if line:GetColumnText(2) == newname then
											PresetsList:SelectItem( line )
											break
										end
									end
								end
							end )
						end
					end,
					nil,
					GetSetsPresets( p, s )
				)
			end
		end
	end

	PresetsButtons.SetPresetStatus = function( status )
      if CheckClientPerm( LocalPlayer(), cvar.perm_prof.v:GetInt() ) and PresetsList:GetSelectedLine() and active_prof and active_set then
         for k, line in pairs( PresetsList:GetSelected() ) do
				local prs = line:GetColumnText(2) -- active_prs
            if PresetsList.boxes[prs] then
               PresetsList.boxes[prs]:SetValue( status )
            end
         end
      end
   end
	PresetsButtons.RenameRef = function()
		if CheckClientPerm( LocalPlayer(), cvar.perm_prof.v:GetInt() ) and PresetsList:GetSelectedLine() and active_prof and active_set then --and active_prof and active_set and active_prs then
			for k, line in pairs( PresetsList:GetSelected() ) do
				-- local x, y = line:GetPos()
				local px, py = PresetsList:LocalToScreen()
				local sx, sy = SettingsWindow:LocalToScreen()
				-- y = y + py - sy + PresetsList:GetDataHeight() * 0.75
				-- x = px - sx - 5
				local x, y = line:LocalToScreen()
				y = math.Clamp( y, py, py + PresetsList:GetTall() - PresetsButtons:GetTall() ) - sy - ( PresetsList:GetDataHeight() * 0.25 ) 
				x = px - sx - 5 
				local s = active_set
				local p = active_prof
				local prs = line:GetColumnText(2) -- active_prs
				TextPrompt(
					SettingsWindow,
					x,
					y,
					prs,
					function( text )
						RenameAllReferences( p, s, prs, string.Trim(text) )
						UpdatePresetSelection()
					end
				)
			end
		end
	end

	PresetsButtons.copy.OnReleased = function()
		if CheckClientPerm( LocalPlayer(), cvar.perm_prof.v:GetInt() ) and PresetsList:GetSelectedLine() and active_prof and active_set then --and active_prof and active_set and active_prs then
			local p = active_prof
			local s = active_set
			for k, line in ipairs( PresetsList:GetSelected() ) do
				local prs = line:GetColumnText(2)
				local newname = prs --active_prs
				-- print( p, s, prs, newname )
				if GetSetsPresets( p, s )[newname] then
					local c = 2
					local n = newname
					while GetSetsPresets( p, s )[n] do
						n = newname .. " (" .. c .. ")"
						c=c+1
					end
					newname = n
				else
					-- print( prs, newname )
					-- PrintTable( GetSetsPresets( p, s ), 1 )
					return
				end
				-- print( "newname", newname )
				RemovePresetPend( PendingRemove, p, s, newname )

				GetPendingTbl( p, s, newname )
				PendingSettings[p][s][newname] = table.Copy( GetPendingTbl( p, s, prs ) )
				AddPresetPend( PendingAdd, p, s, newname )
			end
			UpdateProfilesList()
			UpdatePresetSelection( true )
		end
	end

	PresetsButtons.move.OnReleased = function()
		if CheckClientPerm( LocalPlayer() ) and PresetsList:GetSelectedLine() and active_prof and active_set then
			local prslist = {}
			for k, line in pairs( PresetsList:GetSelected() ) do
				table.insert( prslist, line:GetColumnText(2) )
			end

			local line = select( 2, PresetsList:GetSelectedLine() )
			-- local x, y = line:GetPos()
			local px, py = PresetsList:LocalToScreen()
			local sx, sy = SettingsWindow:LocalToScreen()
			-- y = y + py - sy + PresetsList:GetDataHeight() * 0.75
			-- x = px - sx - 5
			local x, y = line:LocalToScreen()
			y = math.Clamp( y, py, py + PresetsList:GetTall() - PresetsButtons:GetTall() ) - sy - ( PresetsList:GetDataHeight() * 0.25 ) 
			x = px - sx - 5 
			local s = active_set
			local p = active_prof
			local fprs = line:GetColumnText( 2 )
			MovePrompt(
				SettingsWindow,
				x,
				y,
				#prslist > 1 and "Move ".. #prslist .." presets to: "
				or "Move ".. fprs .." to: ",
				function( prof )
					for _, prs in ipairs( prslist ) do
						GetPendingTbl( prof, s, prs, true ) // don't copy existing at new location
						PendingSettings[prof][s][prs] = table.Copy( GetPendingTbl( p, s, prs ) )
						AddPresetPend( PendingAdd, prof, s, prs )

						RemovePresetPend( PendingSettings, p, s, prs ) // old is removed
						RemovePresetPend( PendingAdd, p, s, prs ) // old is removed
						
						RemovePresetPend( PendingRemove, prof, s, prs ) // new is unremoved

						if HasPreset( cl_Profiles, p, s, prs ) then
							AddPresetPend( PendingRemove, p, s, prs )
						end
						
						CloseValueEditor( p, s, prs )
					end

					UpdateProfilesList()
					UpdatePresetSelection( true )
				end,
				p,
				s,
				nil,
				prslist,
				true
			)
		end
	end

	PresetsButtons.copymove.OnReleased = function()
		if CheckClientPerm( LocalPlayer() ) and PresetsList:GetSelectedLine() and active_prof and active_set then
			local prslist = {}
			for k, line in pairs( PresetsList:GetSelected() ) do
				table.insert( prslist, line:GetColumnText(2) )
			end

			local line = select( 2, PresetsList:GetSelectedLine() )
			-- local x, y = line:GetPos()
			local px, py = PresetsList:LocalToScreen()
			local sx, sy = SettingsWindow:LocalToScreen()
			-- y = y + py - sy + PresetsList:GetDataHeight() * 0.75
			-- x = px - sx - 5
			local x, y = line:LocalToScreen()
			y = math.Clamp( y, py, py + PresetsList:GetTall() - PresetsButtons:GetTall() ) - sy - ( PresetsList:GetDataHeight() * 0.25 ) 
			x = px - sx - 5 
			local s = active_set
			local p = active_prof
			local fprs = line:GetColumnText( 2 )
			MovePrompt(
				SettingsWindow,
				x,
				y,
				#prslist > 1 and "Copy ".. #prslist .." presets to: "
				or "Copy ".. fprs .." to: ",
				function( prof )
					for _, prs in ipairs( prslist ) do
						GetPendingTbl( prof, s, prs, true )
						PendingSettings[prof][s][prs] = table.Copy( GetPendingTbl( p, s, prs ) )
						AddPresetPend( PendingAdd, prof, s, prs )

						RemovePresetPend( PendingRemove, prof, s, prs ) // new is unremoved
					end

					UpdateProfilesList()
					UpdatePresetSelection( true )
				end,
				p,
				s,
				nil,
				prslist,
				true
			)
		end
	end

	PresetsButtons.spawn.OnReleased = function()
		if CheckClientPerm( LocalPlayer() ) and PresetsList:GetSelectedLine()
		-- and active_prof and active_set and active_prs
		and SPAWN_SETS[active_set]
		and cl_currentProfile == active_prof then
			for k, line in pairs( PresetsList:GetSelected() ) do
				RequestSpawn( active_prof, active_set, line:GetColumnText(2) ) --active_prs )
			end
		end
	end

	PresetsButtons.tab.OnReleased = function( self )
		for k, line in pairs( PresetsList:GetSelected() ) do
			GetOrCreateValueEditor( active_prof, active_set, line:GetColumnText(2) )
		end
	end

	PresetsButtons.window.OnReleased = function( self )
		for k, line in pairs( PresetsList:GetSelected() ) do
			GetOrCreateValueEditor( active_prof, active_set, line:GetColumnText(2), true ) //windowed
		end
	end

	PresetsButtons.close.OnReleased = function( self )
		for k, line in pairs( PresetsList:GetSelected() ) do
			CloseValueEditor( active_prof, active_set, line:GetColumnText(2) ) //windowed
			PresetsList:ClearSelection()
			DeselectValueList()
			timer.Simple( 0, UpdatePresetSelection )
		end
	end

	PresetsList.OnRowSelected = function( panel, rowIndex, row )
		UpdatePresetSelection()		
	end

	PresetsList.OnRowRightClick = function( panel, rowIndex, row )
		PresetsButtons:Menu()
	end

	PresetsList.DoDoubleClick = function( self, id, line )
		PresetsButtons.window:OnReleased()
	end

	PresetsButtons.Menu = function( self )
		local multiselect = #PresetsList:GetSelected() > 1
		local menu = DermaMenu()
		menu:AddOption( multiselect and "Open selected in tabs" or "Open in tab", function()
			self.tab:OnReleased()
		end )
		menu:AddOption( multiselect and "Open selected in windows" or "Open in window", function()
			self.window:OnReleased()
		end )
		menu:AddOption( multiselect and "Close selected editors" or "Close editor", function()
			self.close:OnReleased()
		end )
		menu:AddOption( multiselect and "Rename selected" or "Rename", function()
			self.rename:OnReleased()
		end )
		if !multiselect then
			menu:AddOption( "Rename all references to this preset", function()
				self.RenameRef()
			end )
		end
      menu:AddOption( "Enable selected", function()
         self.SetPresetStatus(true)
      end )
      menu:AddOption( "Disable selected", function()
         self.SetPresetStatus(false)
      end )

		menu:AddOption( "Add New", function()
			self.add:OnReleased()
		end )
		
		menu:AddOption( multiselect and "Copy names to clipboard" or "Copy name to clipboard", function()
			local str = ""
			local first = true
			for _, line in ipairs( PresetsList:GetSelected() ) do
				if first then
					str = str .. line:GetColumnText(2)
					first = nil
				else
					str = str .. "\n" .. line:GetColumnText(2)
				end
			end
			SetClipboardText( str )
		end )
		
		menu:AddOption( multiselect and "Duplicate selected presets" or "Duplicate preset", function()
			self.copy:OnReleased()
		end )
		menu:AddOption( multiselect and "Move selected to other profile" or "Move to other profile", function()
			self.move:OnReleased()
		end )
		menu:AddOption( multiselect and "Duplicate selected to other profile" or "Duplicate to other profile", function()
			self.copymove:OnReleased()
		end )
		menu:AddOption( multiselect and "Delete selected" or "Delete", function()
			self.sub:OnReleased()
		end )

		if SPAWN_SETS[active_set] and cl_currentProfile == active_prof then
			menu:AddOption( multiselect and "Spawn selected" or "Spawn", function() 
				self.spawn:OnReleased()
			end )
		end
		menu:Open()
	end

	// valuelist is (re)created via CreateValueEditor now
	-- ValueList = vgui.Create( "DCategoryList", RightPanel )
	-- ValueList:Dock( FILL )

	// size
	SettingsWindow.OnSizeChanged = function( self, w, h )
		local w, h = SettingsWindow:GetSize()
		local nwSub = ( last_panel_w - w )
		LeftDivider:SetLeftWidth( LeftDivider:GetLeftWidth() )
		RightDivider:SetLeftWidth( RightDivider:GetLeftWidth() )

		last_panel_w, last_panel_h = w, h
		last_ld_w = LeftDivider:GetLeftWidth()
		last_rd_w = RightDivider:GetLeftWidth()

		CommitButton:SetWidth( last_rd_w / 2 )
		ClearButton:SetWidth( last_rd_w / 2 )
		PresetsButtons:ReRow()
	end

	PendingPanel.OnSizeChanged = function( self, w, h )
		last_ld_w = LeftDivider:GetLeftWidth()
		last_rd_w = RightDivider:GetLeftWidth()
		CommitButton:SetWidth( last_rd_w / 2 )
		ClearButton:SetWidth( last_rd_w / 2 )
	end

	LeftDivider.OnSizeChanged = function( self, w, h )
		local w, h = SettingsWindow:GetSize()
		local nwSub = ( last_panel_w - w ) * 0.333 
		last_ld_w = LeftDivider:GetLeftWidth()
		last_rd_w = RightDivider:GetLeftWidth()		
		WarningBox:SizeToChildren( false, true )
		PresetsButtons:ReRow()
	end

	LeftP_TopDiv.OnSizeChanged = function( self, w, h )
		PresetsButtons:ReRow()
	end

	RightDivider.OnSizeChanged = function( self, w, h )
		local w, h = SettingsWindow:GetSize()
		local nwSub = ( last_panel_w - w ) * 0.333 
		last_ld_w = LeftDivider:GetLeftWidth()
		last_rd_w = RightDivider:GetLeftWidth()

		CommitButton:SetWidth( last_rd_w / 2 )
		ClearButton:SetWidth( last_rd_w / 2 )
		-- PresetsButtons:ReRow()
	end

	// close
	SettingsWindow.OnClose = function( self )
		last_panel_w, last_panel_h = SettingsWindow:GetSize()
		last_panel_w = math.min( last_panel_w, ScrW() )
		last_panel_h = math.min( last_panel_h, ScrH() )
		last_ld_w = LeftDivider:GetLeftWidth()
		last_rd_w = RightDivider:GetLeftWidth()

		last_panel_x, last_panel_y = SettingsWindow:GetPos()
		last_panel_x = math.Clamp( last_panel_x, 0, ScrW() - last_panel_w )
		last_panel_y = math.Clamp( last_panel_y, 0, ScrH() - last_panel_h )

		-- if SettingsPane.selectors then
		if RightPanel.selectors then
			-- for _, p in pairs( SettingsPane.selectors ) do
			for _, p in pairs( RightPanel.selectors ) do
				if IsValid( p ) then
					p:Hide()
				end
			end
		end

		if cl_cvar.close_settings.v:GetBool() then
			ClearValueEditors()
			RemoveSettingsPanel()
		else
			HideValueEditors()
		end
	end

	UpdateProfilesList()
	UpdatePending()
end