--[[ module( "npcd", package.seeall )
AddCSLuaFile()

NPCD_LANGUAGE = "en"

// ISO 639-1
localized = {
	["en"] = {

	},
	["ru"]
}

function langstr( basestr )
	return localized[NPCD_LANGUAGE] and localized[NPCD_LANGUAGE][basestr]
end ]]