TOOL.Name = "npcd Spawner"
-- TOOL.AddToMenu = false
TOOL.Category = "NPC Daemon"
TOOL.Tab = "Options"
TOOL.Command = nil

if CLIENT then
	language.Add( "tool.npcd_spawner.name", "NPCD Spawner" )
	language.Add( "tool.npcd_spawner.desc", "Spawn presets" )
	language.Add( "tool.npcd_spawner.0", "<no active profile>" )
	language.Add( "tool.npcd_spawner.0",
		npcd.cl_currentProfile != nil and ( npcd.cl_currentProfile .. " <no preset selected>" )
		or "<no active profile>" )
end

TOOL.ClientConVar = {
	set = "",
	prs = "",
}

TOOL.BuildCPanel = function( panel )
	panel:Remove()
	-- npcd.PopulateNPCDToolMenu( panel )
end


-- TOOL.SetSpawn = function( self, set, prs )
--    local p = npcd.cvar.perm_spawn.v:GetInt()
--    if CheckClientPerm( self:GetOwner(), p ) then
--       local svar = GetConVar( "npcd_spawner_set" )
--       local pvar = GetConVar( "npcd_spawner_prs" )
--       if svar and pvar then
--          svar:SetString( set )
--          pvar:SetString( prs )
--          language.Add( "tool.npcd_spawner.0", ( npcd.cl_currentProfile or "" ) .. " > " .. set .. " > " .. prs )
--       end
--    else
--       chat.AddText( RandomColor( 0, 15, 0.75, 1, 1, 1 ), "You do not have permission to spawn presets! Permission: " .. ( p and npcd.t_PERM_STR[p] or "" ) )
--    end
-- end

-- TOOL.ServerConVar = {
-- 	set = "",
-- 	prs = "",
-- }

function TOOL:LeftClick()
	if npcd.CheckClientPerm( self:GetOwner(), npcd.cvar.perm_spawn.v:GetInt() ) then
		return self:DoSpawn()		
	end
end

function TOOL:DoSpawn()
	if not ( ( CLIENT and npcd.cl_currentProfile or npcd.currentProfile )
	and self:GetClientInfo("set") != "" and self:GetClientInfo("prs") != "" ) then
		return false
	end
	
	if CLIENT then
		npcd.RequestSpawn( npcd.cl_currentProfile, self:GetClientInfo("set"), self:GetClientInfo("prs") )
	elseif game.SinglePlayer() then
		npcd.TargetSpawnPreset( self:GetOwner(), self:GetClientInfo("set"), self:GetClientInfo("prs"), self:GetOwner() )
	end
	return true
end

function TOOL:DrawToolScreen( w, h )
   surface.SetFont( "DermaLarge" )
   local prof = CLIENT and npcd.cl_currentProfile or npcd.currentProfile or ""
   local set = self:GetClientInfo("set")
   local prs = self:GetClientInfo("prs")
   if prof == "" or set == "" or prs == "" then
      local tw,th = surface.GetTextSize( "NPC Daemon" )
      surface.SetTextColor( 192, 182, 182, 255 )
      surface.SetTextPos( w/2-tw/2, h/2-th )
      surface.DrawText( "NPC Daemon" )
      return
   end
   
	local rw, rh = surface.GetTextSize( prof )
	local sw, sh = surface.GetTextSize( set )
	local pw, ph = surface.GetTextSize( prs )

   local matname = npcd.MatCacheNames[prof] and npcd.MatCacheNames[prof][set] and npcd.MatCacheNames[prof][set][prs] or nil
   if matname != nil and npcd.MatCache[matname] != nil then
      -- surface.SetTexture(surface.GetTextureID(mat))
      surface.SetMaterial(npcd.MatCache[matname])
      surface.SetDrawColor( 255, 255, 255, 255 )
	   surface.DrawTexturedRect( 0, 0, w, h)
      -- surface.DrawTexturedRect(w/2, h/2, w, h)
      -- print(npcd.MatCache[matname])
      surface.SetDrawColor( 0, 0, 0, 225 )
      surface.DrawRect( w/2-math.max(rw/2,sw/2,pw/2)-10, h/2-rh-sh-10, math.max(rw,sw,pw)+20, rh+sh+ph+20)
   end

   -- surface.SetTextColor( 192, 182, 182, 255 )
   surface.SetTextColor( 224, 212, 212, 255)
	surface.SetTextPos( w/2-rw/2, h/2-rh-sh-5 )
	surface.DrawText( prof )
	surface.SetTextPos( w/2-sw/2, h/2-sh )
	surface.DrawText( set )
	surface.SetTextPos( w/2-pw/2, h/2+5 )
	surface.DrawText( prs )
end