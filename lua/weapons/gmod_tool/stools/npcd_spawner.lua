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
	surface.SetDrawColor( Color( 128, 128, 128 ) )
	surface.DrawRect( 0, 0, w, h )

	surface.SetFont( "DermaLarge" )
	surface.SetTextColor( 192, 182, 182 )
	local prof = CLIENT and npcd.cl_currentProfile or npcd.currentProfile or ""
	local rw, rh = surface.GetTextSize( prof )
	local sw, sh = surface.GetTextSize( self:GetClientInfo("set") )
	local pw, ph = surface.GetTextSize( self:GetClientInfo("prs") )

	surface.SetTextPos( w/2-rw/2, h/2-rh-sh-5 )
	surface.DrawText( prof )
	surface.SetTextPos( w/2-sw/2, h/2-sh )
	surface.DrawText( self:GetClientInfo("set") )
	surface.SetTextPos( w/2-pw/2, h/2+5 )
	surface.DrawText( self:GetClientInfo("prs") )
end