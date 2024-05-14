module( "npcd", package.seeall )

if !CLIENT then return end

local cachedEffects = {}
-- local cachedModels = {}
function PrecacheEffect( pcf, name )
	if cachedEffects[pcf] and cachedEffects[pcf][name] then return end // already cached
	game.AddParticles( pcf )
	PrecacheParticleSystem( name )
	cachedEffects[pcf] = cachedEffects[pcf] or {}
	cachedEffects[pcf][name] = true
end

function clientReady()
	timer.Simple( 1, function()
		net.Start( "npcd_cl_ready" )
		net.SendToServer()
	end )
end

net.Receive("npcd_effect_new", function()
	local pcf = net.ReadString()
	local name = net.ReadString()
	game.AddParticles( pcf )
	PrecacheParticleSystem( name )
end)

concommand.Add( "npcd_init", function( ply )
	if CheckClientPerm2( ply, "settings" ) then
		net.Start( "npcd_init" )
		net.SendToServer()
	end
end )
concommand.Add( "npcd_fill", function( ply )
	if CheckClientPerm2( ply, "settings" ) then
		net.Start( "npcd_fill" )
		net.SendToServer()
	end
end )
concommand.Add( "npcd_direct", function( ply )
	if CheckClientPerm2( ply, "settings" ) then
		net.Start( "npcd_direct" )
		net.SendToServer()
	end
end )

concommand.Add( "npcd_kills_clear", function( ply )
	if CheckClientPerm2( ply, "settings" ) then
		net.Start( "npcd_kills_clear" )
		net.SendToServer()
	end
end )

concommand.Add( "npcd_mapscale_check", function( ply )
	if CheckClientPerm2( ply, "settings" ) then
		net.Start( "npcd_mapscale_check" )
		net.SendToServer()
	end
end )


net.Receive("npcd_announce", function()
	local msg = net.ReadString()
	local col = net.ReadColor()
	chat.AddText( Color( col.r, col.g, col.b, col.a ), msg )
end)

// client ready
hook.Add( "InitPostEntity", "NPCD Client Init", clientReady ) 
