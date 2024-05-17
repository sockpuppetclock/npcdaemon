module( "npcd", package.seeall )
AddCSLuaFile()

--[[	Contains the structure for all npcd keyvalues
		t_lookup has the table of value tables
		t_DATAVALUE_NAMES explains the data value structure	
		
		["npcdvalue"] = {
			DATAVALUE = "whatever",
			STRUCT = {
				["morevalues"] = {
					MOREDATAVALUES = 1024,
					DEFAULT = 123,
				},
			},
			TYPE = { "string", "number" },
		}
]]

// todo: make this all not a mess


// adds missing datavalues to keyvalue structures
function InheritBaseFormat(tbl, ref)
	for vName, vTbl in pairs(tbl) do
		for dName, dVal in pairs(ref) do
			if vTbl[dName] == nil then
				local insert = nil
				// replace placeholders from t_basevalue_format
				if istable(dVal) then
					insert = {}
					for k, v in pairs(dVal) do
						if v == "__KEYVALUE" then
							insert[k] = vName
						else
							insert[k] = v
						end
					end
				else
					insert = dVal
				end
				vTbl[dName] = insert
			end
		end
	end
end

// if a class keyvalues has a base keyvalue counterpart then it inherits any missing data values
function InheritExistingValues( target, ref )
	for tName, tTbl in pairs(target) do
		if ref[tName] ~= nil then
			for _, chk in pairs(t_DATAVALUE_NAMES) do
				if ref[tName][chk] ~= nil and tTbl[chk] == nil then
					tTbl[chk] = ref[tName][chk]
					break
				end
			end
		end
	end
end

--// wip
-- dv_refs = {}
-- dv_copies = {}

-- function CopyValueTable( tbl, add )
-- 	if add then
-- 		local t = table.Copy( tbl )
-- 		for k, v in pairs( add ) do
-- 			t[k] = v
-- 		end
-- 		dv_copies[t] = tbl
-- 		return t
-- 	else
-- 		dv_refs[tbl] = true
-- 		return tbl
-- 	end
-- end

-- function AddDataValue( lup, cl, vn, tbl )
-- 	if !lup or !t_lookup[lup] then
-- 		Error( "\nError: npcd > AddDataValue > Lookup ", lup," does not exist\n\n" )
-- 		return nil
-- 	end
-- 	if cl then
-- 		t_lookup.class[lup][cl] = t_lookup.class[lup][cl] or {}
-- 		if t_lookup.class[lup][cl][vn] then print( "Overwriting datavalue:", lup, cl, vn ) end
-- 		t_lookup.class[lup][cl][vn] = tbl
-- 	else
-- 		if t_lookup[lup][vn] then print( "Overwriting datavalue:", lup, vn ) end
-- 		t_lookup[lup][vn] = tbl
-- 	end
-- end

// preset types
PROFILE_SETS = {
	["drop_set"] = "Drop Sets",
	["entity"] = "Entities",
	["nextbot"] = "NextBots",
	["npc"] = "NPCs",
	["player"] = "Player Presets",
	["squad"] = "Squads",
	["spawnpool"] = "Spawnpools",
	["weapon_set"] = "Weapon Sets",
}

PROFILE_SETS_SORTED = {
	[1] = "spawnpool",
	[2] = "squad",
	[3] = "npc",
	[4] = "entity",
	[5] = "nextbot",
	[7] = "player",
	[6] = "weapon_set",
	[8] = "drop_set",
}
PROFILE_SETS_SORTED_ABC = {
	[1] = "drop_set",
	[2] = "entity",
	[3] = "nextbot",
	[4] = "npc",
	[5] = "player",
	[7] = "squad",
	[6] = "spawnpool",
	[8] = "weapon_set",
}

ENTITY_SETS = {
	["entity"] = true,
	["nextbot"] = true,
	["npc"] = true,
}

POOL_SETS = {
	["squad"] = true,
	["npc"] = true,
	["entity"] = true,
	["nextbot"] = true,
}

BASIC_TYPES = {
	["entity"] = true,
	["any"] = true,
	["player"] = true, 
	["npc"] = true, 
	["nextbot"] = true,
	["weapon"] = true,
	["item"] = true,
}

ACTIVE_TYPES = {
	["entity"] = true,
	["any"] = true,
	["player"] = true, 
	["npc"] = true, 
	["nextbot"] = true,
}

// categories
t_CAT = {
	["DESC"] = " Description ",
	["REQUIRED"] = "Required",
	["DEFAULT"] = "Unsorted",
	["PHYSICAL"] = "Physical",
	["COMBAT"] = "Combat",
	["HEALTH"] = "Health",
	["BEHAVIOR"] = "Relations & Behavior",
	["CHASE"] = "Chasing",
	["VISUAL"] = "Visual",
	["NPCD"] = "NPCD",
	["MISC"] = "Miscellaneous",
	["OVERRIDE"] = "Overrides",
	["ANNOUNCE"] = "Announce",
	["DAMAGE"] = "Damage",
	["MOVEMENT"] = "Movement",
	["EQUIP"] = "Equipment",
	["SPAWN"] = "Spawning",
}

t_DATAVALUE_TYPES = {
	["number"] = true,
	["boolean"] = true,
	["string"] = true,
	["table"] = true,
	["struct_table"] = true,
	["vector"] = true,
	["angle"] = true,
	["color"] = true,
	["int"] = true,
	["any"] = true,
	["enum"] = true,
	["function"] = true,
	["fraction"] = true,
	["preset"] = true,
	["data"] = true, // hidden data type
}

// case sensitive
t_DATAVALUE_NAMES = {
	["FUNCTION"] = true, // <table> function and arguments to call when the property has a value, either as a string or a function. the function name should be a string if it is a child function of the entity. if FUNCTION_REQ or FUNCTION_REQ_NOT are given then the property's value must meet the requirements to be called
	// the 1st value in the FUNCTION table should be the function or the string name of the child function
	// followed by any arguments and placeholders, which will be placed in order
	["FUNCTION_NOT"] = true, // <table> alternate function. fires only if REQ_NOT is true
	["FUNCTION_REQ"] = true, // <any> does FUNCTION only if value == req
	["FUNCTION_REQ_NOT"] = true, // <any> does FUNCTION_NOT if value == req_not. as in, will either fire FUNCTION_NOT (if it exists) or not do FUNCTION
	["NOLOOKUP"] = true, // <boolean> don't resolve value or do a function or anything, the value won't be changed
	["LOOKUP_REROLL"] = true, // <boolean> if true, allows user to set if function will be rerolled every time it is called, which may require SetTmpEntValues()
	["FUNCTION_TABLE"] = true, // <keyvalue table> if value matches key, run key's function

	["FUNCTION_GET"] = true, // <table> function for getting the value. is used for getting the values need to revert player values
	["REVERTVALUE"] = true, // <any> the value used when reverting player values, instead of using FUNCTION_GET
	["REVERT"] = true, // <boolean> whether to allow player value reverting for this property. default is true

	// FUNCTION placeholders
	["__KEYVALUE"] = true, // placeholder for t_basevalue_format and InheritBaseFormat(): inserts the name of the keyvalue itself. do not use in FUNCTION or it will fail
	["__VALUE"] = true, // placeholder for FUNCTION: inserts the value of the property
	["__VALUETOSTRING"] = true, // placeholder for FUNCTION: inserts the value of the property converted to a string
	["__SELF"] = true, // placeholder for FUNCTION: inserts the entity itself
	["__PACKEDVALUE"] = true, // placeholder for FUNCTION: (only if value is a table) inserts the values's values as the function's args

	["DEFAULT"] = true, // <any> the default value if value is nil
	["DEFAULT_SAVE"] = true, // <boolean> save the default value in the original preset table. currently only for top-level keys
	["PENDING_SAVE"] = true, // <boolean> run the pending init in the pending table, if the pending value is nil, as soon as the value editor is opened
	["CLEAR"] = true, // <boolean> set value to nil when creating preset
	["REQUIRED"] = true, // <boolean> (only for top-level values) preset will fail if not included
	["TYPE"] = true, // <string/string table> determines what value panels can be used. If a table, the first value is the default type
	["CATEGORY"] = true, // <string> gui categorization (t_CAT)
	["NAME"] = true, // <string> nice name
	["SORTNAME"] = true, // <string> used for sorting in gui
	["DESC"] = true, // <string> description

	["ENUM"] = true, // <keyvalue table> table of enum key-values
	["ENUM_REVERSE"] = true, // <keyvalue table> (made automatically in SetEntValues) the reverse lookup for enums, value-key
	["ENUM_SORT"] = true, // <boolean> whether to force sort by enum name instead of value (if it even can be sorted by value)
	["TBLSTRUCT"] = true, // <keyvalue table> required for table types, contains structure for every table value
	["STRUCT"] = true, // <keyvalue table> required for struct and struct_table types, containing more properties
	["STRUCT_TBLMAINKEY"] = true, // <string> for struct-table panels, the main key displayed on the table list
	["STRUCT_RECURSIVE"] = true, // <boolean> for struct-table panels, whether to lookup the inside values too
	["PRESETS"] = true, // <string table> for preset types, a table of preset types to include. can also include t_presetspanel_misc tables
	["PRESETS_ENTITYLIST"] = true, // <boolean> for preset types, uses list.Get() instead of preset types
	["PRESETS_ENTITYLIST_ONLY"] = true, // <key table> only use these lists
	["ASSET"] = true, // <string> for string types, allow a file browser to select paths. if not an existing search keyword, it will browse the entire directory. see: AssetBrowserBasic(). available keywords: models, materials, textures
	["REFRESHICON"] = true, // <boolean>
	["REFRESHDESC"] = true, // <boolean>

	["MIN"] = true, // <number> minimum value
	["MAX"] = true, // <number> maximum value

	["NOFUNC"] = true, // <boolean> function value type is not allowed

	["CANCLASS"] = true, // <boolean> for string and preset panels. allows adding class value structs to the value list
	["COLORALPHA"] = true, // <boolean> for color panels: allow/disallow alpha color. default is allow

	["COMPARECHANCE"] = true, // <boolean> show the comparison panel if the panel supports it (fractional). comparison panel compares the same value across presets in the set
	["COMPARECHANCE_MAINKEY"] = true, // <string table> if included, the table of key strings is navigated to bring out the comparison value (e.g. fractional.f )
	["COMPARECHANCE_SIDEKEY"] = true, // <string table> if included, this is a secondary key that must match the original to be included in the comparison
	["COMPARECHANCE_TABLE"] = true, // <boolean> only for struct tables, whether or not the things being compared are in the same table
	["COMPARECHANCE_TABLE_KEY"] = true, // <string> key will be listed using this adjacent key
}

// "any" type includes these types
t_ANY_TYPES = {
	["number"] = true,
	["boolean"] = true,
	["string"] = true,
	["vector"] = true,
	["angle"] = true,
	["color"] = true,
	["int"] = true,
}

// fallback lookup
t_empty = {
	NAME = "Empty Lookup",
	STRUCT = {},
}

str_entnofunc = "Entity missing function: "

f_test_chase = {
	"GetEnemy",
	"SetEnemy",
	"GetTarget",
	"SetTarget",
	"IsCurrentSchedule",
	"SetSchedule",
	"SetLastPosition",
	"Disposition"
}

f_test_npcspawnflag = function(ent)
	local pass = ent:IsNPC()
	if (pass) then
		return true
	else
		return false, "Entity is not considered an NPC, spawnflags may differ from NPC default"
	end
end

// if keyvalue is missing data
t_basevalue_format = {
	-- ["npc"] = {
	-- 	FUNCTION = { "SetKeyValue", "__KEYVALUE", "__VALUE" },
	-- 	TYPE = "number",
	-- },
	-- ["nextbot"] = {
	-- 	FUNCTION = { "SetKeyValue", "__KEYVALUE", "__VALUE" },
	-- 	TYPE = "number",
	-- },
	-- ["entity"] = {
	-- 	FUNCTION = { "SetKeyValue", "__KEYVALUE", "__VALUE" },
	-- 	TYPE = "number",
	-- },
	-- ["player"] = {
	-- 	FUNCTION = { "SetKeyValue", "__KEYVALUE", "__VALUE" },
	-- 	TYPE = "number",
	-- },
	-- ["weapon"] = {
	-- 	FUNCTION = { "SetKeyValue", "__KEYVALUE", "__VALUE" },
	-- 	TYPE = "number",
	-- },
	-- ["drop"] = {
	-- 	FUNCTION = { "SetKeyValue", "__KEYVALUE", "__VALUE" },
	-- 	TYPE = "number",
	-- },
	["default"] = {
		CATEGORY = t_CAT.DEFAULT,
		TYPE = "number",
	},
	-- ["struct"] = {
	-- 	TYPE = "number",
	-- },
}

// functions aren't able to be saved in json so i decided to do stuff like this
// a keyvalue with a value like { "__RANDOM", 1, 5 } will have the value replaced with the result of the function, using the 2nd and onward keys as args
// see CreateFunctionPanel() in cl_npcd_gui_editor.lua and SetEntValues() in sv_npcd.lua 
t_FUNCS = {
	["__RANDOM"] = {
		NAME = "math.random (int)",
		FUNCTION = RandomInt,
		-- STRUCT = {
		-- 	["min"] = {
		-- 		DEFAULT = 0,
		-- 		REQUIRED = true,
		-- 	},
		-- 	["max"] = {
		-- 		DEFAULT = 1,
		-- 		REQUIRED = true,
		-- 	},
		-- },
		TYPE = { "number", "int" },
	},
	["__RAND"] = {
		NAME = "math.Rand (decimal)",
		FUNCTION = RandomDecimal,
		-- STRUCT = {
		-- 	["min"] = {
		-- 		DEFAULT = 0,
		-- 		REQUIRED = true,
		-- 	},
		-- 	["max"] = {
		-- 		DEFAULT = 1,
		-- 		REQUIRED = true,
		-- 	},
		-- },
		TYPE = "number",
	},
	["__TBLRANDOM"] = {
		NAME = "table.Random",
		FUNCTION = table.Random,
		TYPE = "any",
	},
	["__RANDOMCOLOR"] = {
		NAME = "RandomColor",
		FUNCTION = RandomColor,
		-- STRUCT = {
		-- 	["huemin"] = {}, 
		-- 	["huemax"] = {}, 
		-- 	["satmin"] = {}, 
		-- 	["satmax"] = {}, 
		-- 	["valmin"] = {}, 
		-- 	["valmax"] = {},
		-- },
		TYPE = "color",
	},
	["__RANDOMANGLE"] = {
		NAME = "RandomAngle",
		FUNCTION = RandomAngle,
		-- STRUCT = {
		-- 	["pitch"] = {
		-- 		DESC = "Number is specific direction. If true (boolean), then pick any random direction.",
		-- 		TYPE = { "boolean", "number" },
		-- 		DEFAULT = 0,
		-- 	},
		-- 	["yaw"] = {
		-- 		DESC = "Number is specific direction. If true (boolean), then pick any random direction.",
		-- 		TYPE = { "boolean", "number" },
		-- 		DEFAULT = true,
		-- 	},
		-- 	["roll"] = {
		-- 		DESC = "Number is specific direction. If true (boolean), then pick any random direction.",
		-- 		TYPE = { "boolean", "number" },
		-- 		DEFAULT = 0,
		-- 	},
		-- },
		TYPE = "angle",
	},
	["__RANDOMVECTOR"] = {
		NAME = "RandomVector",
		FUNCTION = RandomVector,
		-- STRUCT = {
		-- 	["xmin"] = {
		-- 		DEFAULT = -1,
		-- 	},
		-- 	["xmax"] = {
		-- 		DEFAULT = 1,
		-- 	},
		-- 	["ymin"] = {
		-- 		DEFAULT = -1,
		-- 	},
		-- 	["ymax"] = {
		-- 		DEFAULT = 1,
		-- 	},
		-- 	["zmin"] = {
		-- 		DEFAULT = -1,
		-- 	},
		-- 	["zmax"] = {
		-- 		DEFAULT = 1,
		-- 	},
		-- },
		TYPE = "vector",
	},
}

// enums used in multiple places
t_enums = {
	["dmg_type"] = {
		["DMG_GENERIC"] = 0,
		["DMG_CRUSH"] = 1,
		["DMG_BULLET"] = 2,
		["DMG_SLASH"] = 4,
		["DMG_BURN"] = 8,
		["DMG_VEHICLE"] = 16,
		["DMG_FALL"] = 32,
		["DMG_BLAST"] = 64,
		["DMG_CLUB"] = 128,
		["DMG_SHOCK"] = 256,
		["DMG_SONIC"] = 512,
		["DMG_ENERGYBEAM"] = 1024,
		["DMG_PREVENT_PHYSICS_FORCE"] = 2048,
		["DMG_NEVERGIB"] = 4096,
		["DMG_ALWAYSGIB"] = 8192,
		["DMG_DROWN"] = 16384,
		["DMG_PARALYZE"] = 32768,
		["DMG_NERVEGAS"] = 65536,
		["DMG_POISON"] = 131072,
		["DMG_RADIATION"] = 262144,
		["DMG_DROWNRECOVER"] = 524288,
		["DMG_ACID"] = 1048576,
		["DMG_SLOWBURN"] = 2097152,
		["DMG_REMOVENORAGDOLL"] = 4194304,
		["DMG_PHYSGUN"] = 8388608,
		["DMG_PLASMA"] = 16777216,
		["DMG_AIRBOAT"] = 33554432,
		["DMG_DISSOLVE"] = 67108864,
		["DMG_BLAST_SURFACE"] = 134217728,
		["DMG_DIRECT"] = 268435456,
		["DMG_BUCKSHOT"] = 536870912,
		["DMG_SNIPER"] = 1073741824,
		["DMG_MISSILEDEFENSE"] = 2147483648,
	},
	["schedule"] = {
		["SCHED_AISCRIPT"] = 56,
		["SCHED_ALERT_FACE"] = 5,
		["SCHED_ALERT_FACE_BESTSOUND"] = 6,
		["SCHED_ALERT_REACT_TO_COMBAT_SOUND"] = 7,
		["SCHED_ALERT_SCAN"] = 8,
		["SCHED_ALERT_STAND"] = 9,
		["SCHED_ALERT_WALK"] = 10,
		["SCHED_AMBUSH"] = 52,
		["SCHED_ARM_WEAPON"] = 48,
		["SCHED_BACK_AWAY_FROM_ENEMY"] = 24,
		["SCHED_BACK_AWAY_FROM_SAVE_POSITION"] = 26,
		["SCHED_BIG_FLINCH"] = 23,
		["SCHED_CHASE_ENEMY"] = 17,
		["SCHED_CHASE_ENEMY_FAILED"] = 18,
		["SCHED_COMBAT_FACE"] = 12,
		["SCHED_COMBAT_PATROL"] = 75,
		["SCHED_COMBAT_STAND"] = 15,
		["SCHED_COMBAT_SWEEP"] = 13,
		["SCHED_COMBAT_WALK"] = 16,
		["SCHED_COWER"] = 40,
		["SCHED_DIE"] = 53,
		["SCHED_DIE_RAGDOLL"] = 54,
		["SCHED_DISARM_WEAPON"] = 49,
		["SCHED_DROPSHIP_DUSTOFF"] = 79,
		["SCHED_DUCK_DODGE"] = 84,
		["SCHED_ESTABLISH_LINE_OF_FIRE"] = 35,
		["SCHED_ESTABLISH_LINE_OF_FIRE_FALLBACK"] = 36,
		["SCHED_FAIL"] = 81,
		["SCHED_FAIL_ESTABLISH_LINE_OF_FIRE"] = 38,
		["SCHED_FAIL_NOSTOP"] = 82,
		["SCHED_FAIL_TAKE_COVER"] = 31,
		["SCHED_FALL_TO_GROUND"] = 78,
		["SCHED_FEAR_FACE"] = 14,
		["SCHED_FLEE_FROM_BEST_SOUND"] = 29,
		["SCHED_FLINCH_PHYSICS"] = 80,
		["SCHED_FORCED_GO"] = 71,
		["SCHED_FORCED_GO_RUN"] = 72,
		["SCHED_GET_HEALTHKIT"] = 66,
		["SCHED_HIDE_AND_RELOAD"] = 50,
		["SCHED_IDLE_STAND"] = 1,
		["SCHED_IDLE_WALK"] = 2,
		["SCHED_IDLE_WANDER"] = 3,
		["SCHED_INTERACTION_MOVE_TO_PARTNER"] = 85,
		["SCHED_INTERACTION_WAIT_FOR_PARTNER"] = 86,
		["SCHED_INVESTIGATE_SOUND"] = 11,
		["SCHED_MELEE_ATTACK1"] = 41,
		["SCHED_MELEE_ATTACK2"] = 42,
		["SCHED_MOVE_AWAY"] = 68,
		["SCHED_MOVE_AWAY_END"] = 70,
		["SCHED_MOVE_AWAY_FAIL"] = 69,
		["SCHED_MOVE_AWAY_FROM_ENEMY"] = 25,
		["SCHED_MOVE_TO_WEAPON_RANGE"] = 34,
		["SCHED_NEW_WEAPON"] = 63,
		["SCHED_NEW_WEAPON_CHEAT"] = 64,
		["SCHED_NONE"] = 0,
		["SCHED_NPC_FREEZE"] = 73,
		["SCHED_PATROL_RUN"] = 76,
		["SCHED_PATROL_WALK"] = 74,
		["SCHED_PRE_FAIL_ESTABLISH_LINE_OF_FIRE"] = 37,
		["SCHED_RANGE_ATTACK1"] = 43,
		["SCHED_RANGE_ATTACK2"] = 44,
		["SCHED_RELOAD"] = 51,
		["SCHED_RUN_FROM_ENEMY"] = 32,
		["SCHED_RUN_FROM_ENEMY_FALLBACK"] = 33,
		["SCHED_RUN_FROM_ENEMY_MOB"] = 83,
		["SCHED_RUN_RANDOM"] = 77,
		["SCHED_SCENE_GENERIC"] = 62,
		["SCHED_SCRIPTED_CUSTOM_MOVE"] = 59,
		["SCHED_SCRIPTED_FACE"] = 61,
		["SCHED_SCRIPTED_RUN"] = 58,
		["SCHED_SCRIPTED_WAIT"] = 60,
		["SCHED_SCRIPTED_WALK"] = 57,
		["SCHED_SHOOT_ENEMY_COVER"] = 39,
		["SCHED_SLEEP"] = 87,
		["SCHED_SMALL_FLINCH"] = 22,
		["SCHED_SPECIAL_ATTACK1"] = 45,
		["SCHED_SPECIAL_ATTACK2"] = 46,
		["SCHED_STANDOFF"] = 47,
		["SCHED_SWITCH_TO_PENDING_WEAPON"] = 65,
		["SCHED_TAKE_COVER_FROM_BEST_SOUND"] = 28,
		["SCHED_TAKE_COVER_FROM_ENEMY"] = 27,
		["SCHED_TAKE_COVER_FROM_ORIGIN"] = 30,
		["SCHED_TARGET_CHASE"] = 21,
		["SCHED_TARGET_FACE"] = 20,
		["SCHED_VICTORY_DANCE"] = 19,
		["SCHED_WAIT_FOR_SCRIPT"] = 55,
		["SCHED_WAIT_FOR_SPEAK_FINISH"] = 67,
		["SCHED_WAKE_ANGRY"] = 4,
	},
	["activity"] = {
		["ACT_INVALID"] = ACT_INVALID,
		["ACT_RESET"] = ACT_RESET,
		["ACT_IDLE"] = ACT_IDLE,
		["ACT_TRANSITION"] = ACT_TRANSITION,
		["ACT_COVER"] = ACT_COVER,
		["ACT_COVER_MED"] = ACT_COVER_MED,
		["ACT_COVER_LOW"] = ACT_COVER_LOW,
		["ACT_WALK"] = ACT_WALK,
		["ACT_WALK_AIM"] = ACT_WALK_AIM,
		["ACT_WALK_CROUCH"] = ACT_WALK_CROUCH,
		["ACT_WALK_CROUCH_AIM"] = ACT_WALK_CROUCH_AIM,
		["ACT_RUN"] = ACT_RUN,
		["ACT_RUN_AIM"] = ACT_RUN_AIM,
		["ACT_RUN_CROUCH"] = ACT_RUN_CROUCH,
		["ACT_RUN_CROUCH_AIM"] = ACT_RUN_CROUCH_AIM,
		["ACT_RUN_PROTECTED"] = ACT_RUN_PROTECTED,
		["ACT_SCRIPT_CUSTOM_MOVE"] = ACT_SCRIPT_CUSTOM_MOVE,
		["ACT_RANGE_ATTACK1"] = ACT_RANGE_ATTACK1,
		["ACT_RANGE_ATTACK2"] = ACT_RANGE_ATTACK2,
		["ACT_RANGE_ATTACK1_LOW"] = ACT_RANGE_ATTACK1_LOW,
		["ACT_RANGE_ATTACK2_LOW"] = ACT_RANGE_ATTACK2_LOW,
		["ACT_DIESIMPLE"] = ACT_DIESIMPLE,
		["ACT_DIEBACKWARD"] = ACT_DIEBACKWARD,
		["ACT_DIEFORWARD"] = ACT_DIEFORWARD,
		["ACT_DIEVIOLENT"] = ACT_DIEVIOLENT,
		["ACT_DIERAGDOLL"] = ACT_DIERAGDOLL,
		["ACT_FLY"] = ACT_FLY,
		["ACT_HOVER"] = ACT_HOVER,
		["ACT_GLIDE"] = ACT_GLIDE,
		["ACT_SWIM"] = ACT_SWIM,
		["ACT_SWIM_IDLE"] = ACT_SWIM_IDLE,
		["ACT_JUMP"] = ACT_JUMP,
		["ACT_HOP"] = ACT_HOP,
		["ACT_LEAP"] = ACT_LEAP,
		["ACT_LAND"] = ACT_LAND,
		["ACT_CLIMB_UP"] = ACT_CLIMB_UP,
		["ACT_CLIMB_DOWN"] = ACT_CLIMB_DOWN,
		["ACT_CLIMB_DISMOUNT"] = ACT_CLIMB_DISMOUNT,
		["ACT_SHIPLADDER_UP"] = ACT_SHIPLADDER_UP,
		["ACT_SHIPLADDER_DOWN"] = ACT_SHIPLADDER_DOWN,
		["ACT_STRAFE_LEFT"] = ACT_STRAFE_LEFT,
		["ACT_STRAFE_RIGHT"] = ACT_STRAFE_RIGHT,
		["ACT_ROLL_LEFT"] = ACT_ROLL_LEFT,
		["ACT_ROLL_RIGHT"] = ACT_ROLL_RIGHT,
		["ACT_TURN_LEFT"] = ACT_TURN_LEFT,
		["ACT_TURN_RIGHT"] = ACT_TURN_RIGHT,
		["ACT_CROUCH"] = ACT_CROUCH,
		["ACT_CROUCHIDLE"] = ACT_CROUCHIDLE,
		["ACT_STAND"] = ACT_STAND,
		["ACT_USE"] = ACT_USE,
		["ACT_SIGNAL1"] = ACT_SIGNAL1,
		["ACT_SIGNAL2"] = ACT_SIGNAL2,
		["ACT_SIGNAL3"] = ACT_SIGNAL3,
		["ACT_SIGNAL_ADVANCE"] = ACT_SIGNAL_ADVANCE,
		["ACT_SIGNAL_FORWARD"] = ACT_SIGNAL_FORWARD,
		["ACT_SIGNAL_GROUP"] = ACT_SIGNAL_GROUP,
		["ACT_SIGNAL_HALT"] = ACT_SIGNAL_HALT,
		["ACT_SIGNAL_LEFT"] = ACT_SIGNAL_LEFT,
		["ACT_SIGNAL_RIGHT"] = ACT_SIGNAL_RIGHT,
		["ACT_SIGNAL_TAKECOVER"] = ACT_SIGNAL_TAKECOVER,
		["ACT_LOOKBACK_RIGHT"] = ACT_LOOKBACK_RIGHT,
		["ACT_LOOKBACK_LEFT"] = ACT_LOOKBACK_LEFT,
		["ACT_COWER"] = ACT_COWER,
		["ACT_SMALL_FLINCH"] = ACT_SMALL_FLINCH,
		["ACT_BIG_FLINCH"] = ACT_BIG_FLINCH,
		["ACT_MELEE_ATTACK1"] = ACT_MELEE_ATTACK1,
		["ACT_MELEE_ATTACK2"] = ACT_MELEE_ATTACK2,
		["ACT_RELOAD"] = ACT_RELOAD,
		["ACT_RELOAD_START"] = ACT_RELOAD_START,
		["ACT_RELOAD_FINISH"] = ACT_RELOAD_FINISH,
		["ACT_RELOAD_LOW"] = ACT_RELOAD_LOW,
		["ACT_ARM"] = ACT_ARM,
		["ACT_DISARM"] = ACT_DISARM,
		["ACT_DROP_WEAPON"] = ACT_DROP_WEAPON,
		["ACT_DROP_WEAPON_SHOTGUN"] = ACT_DROP_WEAPON_SHOTGUN,
		["ACT_PICKUP_GROUND"] = ACT_PICKUP_GROUND,
		["ACT_PICKUP_RACK"] = ACT_PICKUP_RACK,
		["ACT_IDLE_ANGRY"] = ACT_IDLE_ANGRY,
		["ACT_IDLE_RELAXED"] = ACT_IDLE_RELAXED,
		["ACT_IDLE_STIMULATED"] = ACT_IDLE_STIMULATED,
		["ACT_IDLE_AGITATED"] = ACT_IDLE_AGITATED,
		["ACT_IDLE_STEALTH"] = ACT_IDLE_STEALTH,
		["ACT_IDLE_HURT"] = ACT_IDLE_HURT,
		["ACT_WALK_RELAXED"] = ACT_WALK_RELAXED,
		["ACT_WALK_STIMULATED"] = ACT_WALK_STIMULATED,
		["ACT_WALK_AGITATED"] = ACT_WALK_AGITATED,
		["ACT_WALK_STEALTH"] = ACT_WALK_STEALTH,
		["ACT_RUN_RELAXED"] = ACT_RUN_RELAXED,
		["ACT_RUN_STIMULATED"] = ACT_RUN_STIMULATED,
		["ACT_RUN_AGITATED"] = ACT_RUN_AGITATED,
		["ACT_RUN_STEALTH"] = ACT_RUN_STEALTH,
		["ACT_IDLE_AIM_RELAXED"] = ACT_IDLE_AIM_RELAXED,
		["ACT_IDLE_AIM_STIMULATED"] = ACT_IDLE_AIM_STIMULATED,
		["ACT_IDLE_AIM_AGITATED"] = ACT_IDLE_AIM_AGITATED,
		["ACT_IDLE_AIM_STEALTH"] = ACT_IDLE_AIM_STEALTH,
		["ACT_WALK_AIM_RELAXED"] = ACT_WALK_AIM_RELAXED,
		["ACT_WALK_AIM_STIMULATED"] = ACT_WALK_AIM_STIMULATED,
		["ACT_WALK_AIM_AGITATED"] = ACT_WALK_AIM_AGITATED,
		["ACT_WALK_AIM_STEALTH"] = ACT_WALK_AIM_STEALTH,
		["ACT_RUN_AIM_RELAXED"] = ACT_RUN_AIM_RELAXED,
		["ACT_RUN_AIM_STIMULATED"] = ACT_RUN_AIM_STIMULATED,
		["ACT_RUN_AIM_AGITATED"] = ACT_RUN_AIM_AGITATED,
		["ACT_RUN_AIM_STEALTH"] = ACT_RUN_AIM_STEALTH,
		["ACT_CROUCHIDLE_STIMULATED"] = ACT_CROUCHIDLE_STIMULATED,
		["ACT_CROUCHIDLE_AIM_STIMULATED"] = ACT_CROUCHIDLE_AIM_STIMULATED,
		["ACT_CROUCHIDLE_AGITATED"] = ACT_CROUCHIDLE_AGITATED,
		["ACT_WALK_HURT"] = ACT_WALK_HURT,
		["ACT_RUN_HURT"] = ACT_RUN_HURT,
		["ACT_SPECIAL_ATTACK1"] = ACT_SPECIAL_ATTACK1,
		["ACT_SPECIAL_ATTACK2"] = ACT_SPECIAL_ATTACK2,
		["ACT_COMBAT_IDLE"] = ACT_COMBAT_IDLE,
		["ACT_WALK_SCARED"] = ACT_WALK_SCARED,
		["ACT_RUN_SCARED"] = ACT_RUN_SCARED,
		["ACT_VICTORY_DANCE"] = ACT_VICTORY_DANCE,
		["ACT_DIE_HEADSHOT"] = ACT_DIE_HEADSHOT,
		["ACT_DIE_CHESTSHOT"] = ACT_DIE_CHESTSHOT,
		["ACT_DIE_GUTSHOT"] = ACT_DIE_GUTSHOT,
		["ACT_DIE_BACKSHOT"] = ACT_DIE_BACKSHOT,
		["ACT_FLINCH_HEAD"] = ACT_FLINCH_HEAD,
		["ACT_FLINCH_CHEST"] = ACT_FLINCH_CHEST,
		["ACT_FLINCH_STOMACH"] = ACT_FLINCH_STOMACH,
		["ACT_FLINCH_LEFTARM"] = ACT_FLINCH_LEFTARM,
		["ACT_FLINCH_RIGHTARM"] = ACT_FLINCH_RIGHTARM,
		["ACT_FLINCH_LEFTLEG"] = ACT_FLINCH_LEFTLEG,
		["ACT_FLINCH_RIGHTLEG"] = ACT_FLINCH_RIGHTLEG,
		["ACT_FLINCH_PHYSICS"] = ACT_FLINCH_PHYSICS,
		["ACT_IDLE_ON_FIRE"] = ACT_IDLE_ON_FIRE,
		["ACT_WALK_ON_FIRE"] = ACT_WALK_ON_FIRE,
		["ACT_RUN_ON_FIRE"] = ACT_RUN_ON_FIRE,
		["ACT_RAPPEL_LOOP"] = ACT_RAPPEL_LOOP,
		["ACT_180_LEFT"] = ACT_180_LEFT,
		["ACT_180_RIGHT"] = ACT_180_RIGHT,
		["ACT_90_LEFT"] = ACT_90_LEFT,
		["ACT_90_RIGHT"] = ACT_90_RIGHT,
		["ACT_STEP_LEFT"] = ACT_STEP_LEFT,
		["ACT_STEP_RIGHT"] = ACT_STEP_RIGHT,
		["ACT_STEP_BACK"] = ACT_STEP_BACK,
		["ACT_STEP_FORE"] = ACT_STEP_FORE,
		["ACT_GESTURE_RANGE_ATTACK1"] = ACT_GESTURE_RANGE_ATTACK1,
		["ACT_GESTURE_RANGE_ATTACK2"] = ACT_GESTURE_RANGE_ATTACK2,
		["ACT_GESTURE_MELEE_ATTACK1"] = ACT_GESTURE_MELEE_ATTACK1,
		["ACT_GESTURE_MELEE_ATTACK2"] = ACT_GESTURE_MELEE_ATTACK2,
		["ACT_GESTURE_RANGE_ATTACK1_LOW"] = ACT_GESTURE_RANGE_ATTACK1_LOW,
		["ACT_GESTURE_RANGE_ATTACK2_LOW"] = ACT_GESTURE_RANGE_ATTACK2_LOW,
		["ACT_MELEE_ATTACK_SWING_GESTURE"] = ACT_MELEE_ATTACK_SWING_GESTURE,
		["ACT_GESTURE_SMALL_FLINCH"] = ACT_GESTURE_SMALL_FLINCH,
		["ACT_GESTURE_BIG_FLINCH"] = ACT_GESTURE_BIG_FLINCH,
		["ACT_GESTURE_FLINCH_BLAST"] = ACT_GESTURE_FLINCH_BLAST,
		["ACT_GESTURE_FLINCH_BLAST_SHOTGUN"] = ACT_GESTURE_FLINCH_BLAST_SHOTGUN,
		["ACT_GESTURE_FLINCH_BLAST_DAMAGED"] = ACT_GESTURE_FLINCH_BLAST_DAMAGED,
		["ACT_GESTURE_FLINCH_BLAST_DAMAGED_SHOTGUN"] = ACT_GESTURE_FLINCH_BLAST_DAMAGED_SHOTGUN,
		["ACT_GESTURE_FLINCH_HEAD"] = ACT_GESTURE_FLINCH_HEAD,
		["ACT_GESTURE_FLINCH_CHEST"] = ACT_GESTURE_FLINCH_CHEST,
		["ACT_GESTURE_FLINCH_STOMACH"] = ACT_GESTURE_FLINCH_STOMACH,
		["ACT_GESTURE_FLINCH_LEFTARM"] = ACT_GESTURE_FLINCH_LEFTARM,
		["ACT_GESTURE_FLINCH_RIGHTARM"] = ACT_GESTURE_FLINCH_RIGHTARM,
		["ACT_GESTURE_FLINCH_LEFTLEG"] = ACT_GESTURE_FLINCH_LEFTLEG,
		["ACT_GESTURE_FLINCH_RIGHTLEG"] = ACT_GESTURE_FLINCH_RIGHTLEG,
		["ACT_GESTURE_TURN_LEFT"] = ACT_GESTURE_TURN_LEFT,
		["ACT_GESTURE_TURN_RIGHT"] = ACT_GESTURE_TURN_RIGHT,
		["ACT_GESTURE_TURN_LEFT45"] = ACT_GESTURE_TURN_LEFT45,
		["ACT_GESTURE_TURN_RIGHT45"] = ACT_GESTURE_TURN_RIGHT45,
		["ACT_GESTURE_TURN_LEFT90"] = ACT_GESTURE_TURN_LEFT90,
		["ACT_GESTURE_TURN_RIGHT90"] = ACT_GESTURE_TURN_RIGHT90,
		["ACT_GESTURE_TURN_LEFT45_FLAT"] = ACT_GESTURE_TURN_LEFT45_FLAT,
		["ACT_GESTURE_TURN_RIGHT45_FLAT"] = ACT_GESTURE_TURN_RIGHT45_FLAT,
		["ACT_GESTURE_TURN_LEFT90_FLAT"] = ACT_GESTURE_TURN_LEFT90_FLAT,
		["ACT_GESTURE_TURN_RIGHT90_FLAT"] = ACT_GESTURE_TURN_RIGHT90_FLAT,
		["ACT_BARNACLE_HIT"] = ACT_BARNACLE_HIT,
		["ACT_BARNACLE_PULL"] = ACT_BARNACLE_PULL,
		["ACT_BARNACLE_CHOMP"] = ACT_BARNACLE_CHOMP,
		["ACT_BARNACLE_CHEW"] = ACT_BARNACLE_CHEW,
		["ACT_DO_NOT_DISTURB"] = ACT_DO_NOT_DISTURB,
		["ACT_VM_DRAW"] = ACT_VM_DRAW,
		["ACT_VM_HOLSTER"] = ACT_VM_HOLSTER,
		["ACT_VM_IDLE"] = ACT_VM_IDLE,
		["ACT_VM_FIDGET"] = ACT_VM_FIDGET,
		["ACT_VM_PULLBACK"] = ACT_VM_PULLBACK,
		["ACT_VM_PULLBACK_HIGH"] = ACT_VM_PULLBACK_HIGH,
		["ACT_VM_PULLBACK_LOW"] = ACT_VM_PULLBACK_LOW,
		["ACT_VM_THROW"] = ACT_VM_THROW,
		["ACT_VM_PULLPIN"] = ACT_VM_PULLPIN,
		["ACT_VM_PRIMARYATTACK"] = ACT_VM_PRIMARYATTACK,
		["ACT_VM_SECONDARYATTACK"] = ACT_VM_SECONDARYATTACK,
		["ACT_VM_RELOAD"] = ACT_VM_RELOAD,
		["ACT_VM_DRYFIRE"] = ACT_VM_DRYFIRE,
		["ACT_VM_HITLEFT"] = ACT_VM_HITLEFT,
		["ACT_VM_HITLEFT2"] = ACT_VM_HITLEFT2,
		["ACT_VM_HITRIGHT"] = ACT_VM_HITRIGHT,
		["ACT_VM_HITRIGHT2"] = ACT_VM_HITRIGHT2,
		["ACT_VM_HITCENTER"] = ACT_VM_HITCENTER,
		["ACT_VM_HITCENTER2"] = ACT_VM_HITCENTER2,
		["ACT_VM_MISSLEFT"] = ACT_VM_MISSLEFT,
		["ACT_VM_MISSLEFT2"] = ACT_VM_MISSLEFT2,
		["ACT_VM_MISSRIGHT"] = ACT_VM_MISSRIGHT,
		["ACT_VM_MISSRIGHT2"] = ACT_VM_MISSRIGHT2,
		["ACT_VM_MISSCENTER"] = ACT_VM_MISSCENTER,
		["ACT_VM_MISSCENTER2"] = ACT_VM_MISSCENTER2,
		["ACT_VM_HAULBACK"] = ACT_VM_HAULBACK,
		["ACT_VM_SWINGHARD"] = ACT_VM_SWINGHARD,
		["ACT_VM_SWINGMISS"] = ACT_VM_SWINGMISS,
		["ACT_VM_SWINGHIT"] = ACT_VM_SWINGHIT,
		["ACT_VM_IDLE_TO_LOWERED"] = ACT_VM_IDLE_TO_LOWERED,
		["ACT_VM_IDLE_LOWERED"] = ACT_VM_IDLE_LOWERED,
		["ACT_VM_LOWERED_TO_IDLE"] = ACT_VM_LOWERED_TO_IDLE,
		["ACT_VM_RECOIL1"] = ACT_VM_RECOIL1,
		["ACT_VM_RECOIL2"] = ACT_VM_RECOIL2,
		["ACT_VM_RECOIL3"] = ACT_VM_RECOIL3,
		["ACT_VM_PICKUP"] = ACT_VM_PICKUP,
		["ACT_VM_RELEASE"] = ACT_VM_RELEASE,
		["ACT_VM_ATTACH_SILENCER"] = ACT_VM_ATTACH_SILENCER,
		["ACT_VM_DETACH_SILENCER"] = ACT_VM_DETACH_SILENCER,
		["ACT_SLAM_STICKWALL_IDLE"] = ACT_SLAM_STICKWALL_IDLE,
		["ACT_SLAM_STICKWALL_ND_IDLE"] = ACT_SLAM_STICKWALL_ND_IDLE,
		["ACT_SLAM_STICKWALL_ATTACH"] = ACT_SLAM_STICKWALL_ATTACH,
		["ACT_SLAM_STICKWALL_ATTACH2"] = ACT_SLAM_STICKWALL_ATTACH2,
		["ACT_SLAM_STICKWALL_ND_ATTACH"] = ACT_SLAM_STICKWALL_ND_ATTACH,
		["ACT_SLAM_STICKWALL_ND_ATTACH2"] = ACT_SLAM_STICKWALL_ND_ATTACH2,
		["ACT_SLAM_STICKWALL_DETONATE"] = ACT_SLAM_STICKWALL_DETONATE,
		["ACT_SLAM_STICKWALL_DETONATOR_HOLSTER"] = ACT_SLAM_STICKWALL_DETONATOR_HOLSTER,
		["ACT_SLAM_STICKWALL_DRAW"] = ACT_SLAM_STICKWALL_DRAW,
		["ACT_SLAM_STICKWALL_ND_DRAW"] = ACT_SLAM_STICKWALL_ND_DRAW,
		["ACT_SLAM_STICKWALL_TO_THROW"] = ACT_SLAM_STICKWALL_TO_THROW,
		["ACT_SLAM_STICKWALL_TO_THROW_ND"] = ACT_SLAM_STICKWALL_TO_THROW_ND,
		["ACT_SLAM_STICKWALL_TO_TRIPMINE_ND"] = ACT_SLAM_STICKWALL_TO_TRIPMINE_ND,
		["ACT_SLAM_THROW_IDLE"] = ACT_SLAM_THROW_IDLE,
		["ACT_SLAM_THROW_ND_IDLE"] = ACT_SLAM_THROW_ND_IDLE,
		["ACT_SLAM_THROW_THROW"] = ACT_SLAM_THROW_THROW,
		["ACT_SLAM_THROW_THROW2"] = ACT_SLAM_THROW_THROW2,
		["ACT_SLAM_THROW_THROW_ND"] = ACT_SLAM_THROW_THROW_ND,
		["ACT_SLAM_THROW_THROW_ND2"] = ACT_SLAM_THROW_THROW_ND2,
		["ACT_SLAM_THROW_DRAW"] = ACT_SLAM_THROW_DRAW,
		["ACT_SLAM_THROW_ND_DRAW"] = ACT_SLAM_THROW_ND_DRAW,
		["ACT_SLAM_THROW_TO_STICKWALL"] = ACT_SLAM_THROW_TO_STICKWALL,
		["ACT_SLAM_THROW_TO_STICKWALL_ND"] = ACT_SLAM_THROW_TO_STICKWALL_ND,
		["ACT_SLAM_THROW_DETONATE"] = ACT_SLAM_THROW_DETONATE,
		["ACT_SLAM_THROW_DETONATOR_HOLSTER"] = ACT_SLAM_THROW_DETONATOR_HOLSTER,
		["ACT_SLAM_THROW_TO_TRIPMINE_ND"] = ACT_SLAM_THROW_TO_TRIPMINE_ND,
		["ACT_SLAM_TRIPMINE_IDLE"] = ACT_SLAM_TRIPMINE_IDLE,
		["ACT_SLAM_TRIPMINE_DRAW"] = ACT_SLAM_TRIPMINE_DRAW,
		["ACT_SLAM_TRIPMINE_ATTACH"] = ACT_SLAM_TRIPMINE_ATTACH,
		["ACT_SLAM_TRIPMINE_ATTACH2"] = ACT_SLAM_TRIPMINE_ATTACH2,
		["ACT_SLAM_TRIPMINE_TO_STICKWALL_ND"] = ACT_SLAM_TRIPMINE_TO_STICKWALL_ND,
		["ACT_SLAM_TRIPMINE_TO_THROW_ND"] = ACT_SLAM_TRIPMINE_TO_THROW_ND,
		["ACT_SLAM_DETONATOR_IDLE"] = ACT_SLAM_DETONATOR_IDLE,
		["ACT_SLAM_DETONATOR_DRAW"] = ACT_SLAM_DETONATOR_DRAW,
		["ACT_SLAM_DETONATOR_DETONATE"] = ACT_SLAM_DETONATOR_DETONATE,
		["ACT_SLAM_DETONATOR_HOLSTER"] = ACT_SLAM_DETONATOR_HOLSTER,
		["ACT_SLAM_DETONATOR_STICKWALL_DRAW"] = ACT_SLAM_DETONATOR_STICKWALL_DRAW,
		["ACT_SLAM_DETONATOR_THROW_DRAW"] = ACT_SLAM_DETONATOR_THROW_DRAW,
		["ACT_SHOTGUN_RELOAD_START"] = ACT_SHOTGUN_RELOAD_START,
		["ACT_SHOTGUN_RELOAD_FINISH"] = ACT_SHOTGUN_RELOAD_FINISH,
		["ACT_SHOTGUN_PUMP"] = ACT_SHOTGUN_PUMP,
		["ACT_SMG2_IDLE2"] = ACT_SMG2_IDLE2,
		["ACT_SMG2_FIRE2"] = ACT_SMG2_FIRE2,
		["ACT_SMG2_DRAW2"] = ACT_SMG2_DRAW2,
		["ACT_SMG2_RELOAD2"] = ACT_SMG2_RELOAD2,
		["ACT_SMG2_DRYFIRE2"] = ACT_SMG2_DRYFIRE2,
		["ACT_SMG2_TOAUTO"] = ACT_SMG2_TOAUTO,
		["ACT_SMG2_TOBURST"] = ACT_SMG2_TOBURST,
		["ACT_PHYSCANNON_UPGRADE"] = ACT_PHYSCANNON_UPGRADE,
		["ACT_RANGE_ATTACK_AR1"] = ACT_RANGE_ATTACK_AR1,
		["ACT_RANGE_ATTACK_AR2"] = ACT_RANGE_ATTACK_AR2,
		["ACT_RANGE_ATTACK_AR2_LOW"] = ACT_RANGE_ATTACK_AR2_LOW,
		["ACT_RANGE_ATTACK_AR2_GRENADE"] = ACT_RANGE_ATTACK_AR2_GRENADE,
		["ACT_RANGE_ATTACK_HMG1"] = ACT_RANGE_ATTACK_HMG1,
		["ACT_RANGE_ATTACK_ML"] = ACT_RANGE_ATTACK_ML,
		["ACT_RANGE_ATTACK_SMG1"] = ACT_RANGE_ATTACK_SMG1,
		["ACT_RANGE_ATTACK_SMG1_LOW"] = ACT_RANGE_ATTACK_SMG1_LOW,
		["ACT_RANGE_ATTACK_SMG2"] = ACT_RANGE_ATTACK_SMG2,
		["ACT_RANGE_ATTACK_SHOTGUN"] = ACT_RANGE_ATTACK_SHOTGUN,
		["ACT_RANGE_ATTACK_SHOTGUN_LOW"] = ACT_RANGE_ATTACK_SHOTGUN_LOW,
		["ACT_RANGE_ATTACK_PISTOL"] = ACT_RANGE_ATTACK_PISTOL,
		["ACT_RANGE_ATTACK_PISTOL_LOW"] = ACT_RANGE_ATTACK_PISTOL_LOW,
		["ACT_RANGE_ATTACK_SLAM"] = ACT_RANGE_ATTACK_SLAM,
		["ACT_RANGE_ATTACK_TRIPWIRE"] = ACT_RANGE_ATTACK_TRIPWIRE,
		["ACT_RANGE_ATTACK_THROW"] = ACT_RANGE_ATTACK_THROW,
		["ACT_RANGE_ATTACK_SNIPER_RIFLE"] = ACT_RANGE_ATTACK_SNIPER_RIFLE,
		["ACT_RANGE_ATTACK_RPG"] = ACT_RANGE_ATTACK_RPG,
		["ACT_MELEE_ATTACK_SWING"] = ACT_MELEE_ATTACK_SWING,
		["ACT_RANGE_AIM_LOW"] = ACT_RANGE_AIM_LOW,
		["ACT_RANGE_AIM_SMG1_LOW"] = ACT_RANGE_AIM_SMG1_LOW,
		["ACT_RANGE_AIM_PISTOL_LOW"] = ACT_RANGE_AIM_PISTOL_LOW,
		["ACT_RANGE_AIM_AR2_LOW"] = ACT_RANGE_AIM_AR2_LOW,
		["ACT_COVER_PISTOL_LOW"] = ACT_COVER_PISTOL_LOW,
		["ACT_COVER_SMG1_LOW"] = ACT_COVER_SMG1_LOW,
		["ACT_GESTURE_RANGE_ATTACK_AR1"] = ACT_GESTURE_RANGE_ATTACK_AR1,
		["ACT_GESTURE_RANGE_ATTACK_AR2"] = ACT_GESTURE_RANGE_ATTACK_AR2,
		["ACT_GESTURE_RANGE_ATTACK_AR2_GRENADE"] = ACT_GESTURE_RANGE_ATTACK_AR2_GRENADE,
		["ACT_GESTURE_RANGE_ATTACK_HMG1"] = ACT_GESTURE_RANGE_ATTACK_HMG1,
		["ACT_GESTURE_RANGE_ATTACK_ML"] = ACT_GESTURE_RANGE_ATTACK_ML,
		["ACT_GESTURE_RANGE_ATTACK_SMG1"] = ACT_GESTURE_RANGE_ATTACK_SMG1,
		["ACT_GESTURE_RANGE_ATTACK_SMG1_LOW"] = ACT_GESTURE_RANGE_ATTACK_SMG1_LOW,
		["ACT_GESTURE_RANGE_ATTACK_SMG2"] = ACT_GESTURE_RANGE_ATTACK_SMG2,
		["ACT_GESTURE_RANGE_ATTACK_SHOTGUN"] = ACT_GESTURE_RANGE_ATTACK_SHOTGUN,
		["ACT_GESTURE_RANGE_ATTACK_PISTOL"] = ACT_GESTURE_RANGE_ATTACK_PISTOL,
		["ACT_GESTURE_RANGE_ATTACK_PISTOL_LOW"] = ACT_GESTURE_RANGE_ATTACK_PISTOL_LOW,
		["ACT_GESTURE_RANGE_ATTACK_SLAM"] = ACT_GESTURE_RANGE_ATTACK_SLAM,
		["ACT_GESTURE_RANGE_ATTACK_TRIPWIRE"] = ACT_GESTURE_RANGE_ATTACK_TRIPWIRE,
		["ACT_GESTURE_RANGE_ATTACK_THROW"] = ACT_GESTURE_RANGE_ATTACK_THROW,
		["ACT_GESTURE_RANGE_ATTACK_SNIPER_RIFLE"] = ACT_GESTURE_RANGE_ATTACK_SNIPER_RIFLE,
		["ACT_GESTURE_MELEE_ATTACK_SWING"] = ACT_GESTURE_MELEE_ATTACK_SWING,
		["ACT_IDLE_RIFLE"] = ACT_IDLE_RIFLE,
		["ACT_IDLE_SMG1"] = ACT_IDLE_SMG1,
		["ACT_IDLE_ANGRY_SMG1"] = ACT_IDLE_ANGRY_SMG1,
		["ACT_IDLE_PISTOL"] = ACT_IDLE_PISTOL,
		["ACT_IDLE_ANGRY_PISTOL"] = ACT_IDLE_ANGRY_PISTOL,
		["ACT_IDLE_ANGRY_SHOTGUN"] = ACT_IDLE_ANGRY_SHOTGUN,
		["ACT_IDLE_STEALTH_PISTOL"] = ACT_IDLE_STEALTH_PISTOL,
		["ACT_IDLE_PACKAGE"] = ACT_IDLE_PACKAGE,
		["ACT_WALK_PACKAGE"] = ACT_WALK_PACKAGE,
		["ACT_IDLE_SUITCASE"] = ACT_IDLE_SUITCASE,
		["ACT_WALK_SUITCASE"] = ACT_WALK_SUITCASE,
		["ACT_IDLE_SMG1_RELAXED"] = ACT_IDLE_SMG1_RELAXED,
		["ACT_IDLE_SMG1_STIMULATED"] = ACT_IDLE_SMG1_STIMULATED,
		["ACT_WALK_RIFLE_RELAXED"] = ACT_WALK_RIFLE_RELAXED,
		["ACT_RUN_RIFLE_RELAXED"] = ACT_RUN_RIFLE_RELAXED,
		["ACT_WALK_RIFLE_STIMULATED"] = ACT_WALK_RIFLE_STIMULATED,
		["ACT_RUN_RIFLE_STIMULATED"] = ACT_RUN_RIFLE_STIMULATED,
		["ACT_IDLE_AIM_RIFLE_STIMULATED"] = ACT_IDLE_AIM_RIFLE_STIMULATED,
		["ACT_WALK_AIM_RIFLE_STIMULATED"] = ACT_WALK_AIM_RIFLE_STIMULATED,
		["ACT_RUN_AIM_RIFLE_STIMULATED"] = ACT_RUN_AIM_RIFLE_STIMULATED,
		["ACT_IDLE_SHOTGUN_RELAXED"] = ACT_IDLE_SHOTGUN_RELAXED,
		["ACT_IDLE_SHOTGUN_STIMULATED"] = ACT_IDLE_SHOTGUN_STIMULATED,
		["ACT_IDLE_SHOTGUN_AGITATED"] = ACT_IDLE_SHOTGUN_AGITATED,
		["ACT_WALK_ANGRY"] = ACT_WALK_ANGRY,
		["ACT_POLICE_HARASS1"] = ACT_POLICE_HARASS1,
		["ACT_POLICE_HARASS2"] = ACT_POLICE_HARASS2,
		["ACT_IDLE_MANNEDGUN"] = ACT_IDLE_MANNEDGUN,
		["ACT_IDLE_MELEE"] = ACT_IDLE_MELEE,
		["ACT_IDLE_ANGRY_MELEE"] = ACT_IDLE_ANGRY_MELEE,
		["ACT_IDLE_RPG_RELAXED"] = ACT_IDLE_RPG_RELAXED,
		["ACT_IDLE_RPG"] = ACT_IDLE_RPG,
		["ACT_IDLE_ANGRY_RPG"] = ACT_IDLE_ANGRY_RPG,
		["ACT_COVER_LOW_RPG"] = ACT_COVER_LOW_RPG,
		["ACT_WALK_RPG"] = ACT_WALK_RPG,
		["ACT_RUN_RPG"] = ACT_RUN_RPG,
		["ACT_WALK_CROUCH_RPG"] = ACT_WALK_CROUCH_RPG,
		["ACT_RUN_CROUCH_RPG"] = ACT_RUN_CROUCH_RPG,
		["ACT_WALK_RPG_RELAXED"] = ACT_WALK_RPG_RELAXED,
		["ACT_RUN_RPG_RELAXED"] = ACT_RUN_RPG_RELAXED,
		["ACT_WALK_RIFLE"] = ACT_WALK_RIFLE,
		["ACT_WALK_AIM_RIFLE"] = ACT_WALK_AIM_RIFLE,
		["ACT_WALK_CROUCH_RIFLE"] = ACT_WALK_CROUCH_RIFLE,
		["ACT_WALK_CROUCH_AIM_RIFLE"] = ACT_WALK_CROUCH_AIM_RIFLE,
		["ACT_RUN_RIFLE"] = ACT_RUN_RIFLE,
		["ACT_RUN_AIM_RIFLE"] = ACT_RUN_AIM_RIFLE,
		["ACT_RUN_CROUCH_RIFLE"] = ACT_RUN_CROUCH_RIFLE,
		["ACT_RUN_CROUCH_AIM_RIFLE"] = ACT_RUN_CROUCH_AIM_RIFLE,
		["ACT_RUN_STEALTH_PISTOL"] = ACT_RUN_STEALTH_PISTOL,
		["ACT_WALK_AIM_SHOTGUN"] = ACT_WALK_AIM_SHOTGUN,
		["ACT_RUN_AIM_SHOTGUN"] = ACT_RUN_AIM_SHOTGUN,
		["ACT_WALK_PISTOL"] = ACT_WALK_PISTOL,
		["ACT_RUN_PISTOL"] = ACT_RUN_PISTOL,
		["ACT_WALK_AIM_PISTOL"] = ACT_WALK_AIM_PISTOL,
		["ACT_RUN_AIM_PISTOL"] = ACT_RUN_AIM_PISTOL,
		["ACT_WALK_STEALTH_PISTOL"] = ACT_WALK_STEALTH_PISTOL,
		["ACT_WALK_AIM_STEALTH_PISTOL"] = ACT_WALK_AIM_STEALTH_PISTOL,
		["ACT_RUN_AIM_STEALTH_PISTOL"] = ACT_RUN_AIM_STEALTH_PISTOL,
		["ACT_RELOAD_PISTOL"] = ACT_RELOAD_PISTOL,
		["ACT_RELOAD_PISTOL_LOW"] = ACT_RELOAD_PISTOL_LOW,
		["ACT_RELOAD_SMG1"] = ACT_RELOAD_SMG1,
		["ACT_RELOAD_SMG1_LOW"] = ACT_RELOAD_SMG1_LOW,
		["ACT_RELOAD_SHOTGUN"] = ACT_RELOAD_SHOTGUN,
		["ACT_RELOAD_SHOTGUN_LOW"] = ACT_RELOAD_SHOTGUN_LOW,
		["ACT_GESTURE_RELOAD"] = ACT_GESTURE_RELOAD,
		["ACT_GESTURE_RELOAD_PISTOL"] = ACT_GESTURE_RELOAD_PISTOL,
		["ACT_GESTURE_RELOAD_SMG1"] = ACT_GESTURE_RELOAD_SMG1,
		["ACT_GESTURE_RELOAD_SHOTGUN"] = ACT_GESTURE_RELOAD_SHOTGUN,
		["ACT_BUSY_LEAN_LEFT"] = ACT_BUSY_LEAN_LEFT,
		["ACT_BUSY_LEAN_LEFT_ENTRY"] = ACT_BUSY_LEAN_LEFT_ENTRY,
		["ACT_BUSY_LEAN_LEFT_EXIT"] = ACT_BUSY_LEAN_LEFT_EXIT,
		["ACT_BUSY_LEAN_BACK"] = ACT_BUSY_LEAN_BACK,
		["ACT_BUSY_LEAN_BACK_ENTRY"] = ACT_BUSY_LEAN_BACK_ENTRY,
		["ACT_BUSY_LEAN_BACK_EXIT"] = ACT_BUSY_LEAN_BACK_EXIT,
		["ACT_BUSY_SIT_GROUND"] = ACT_BUSY_SIT_GROUND,
		["ACT_BUSY_SIT_GROUND_ENTRY"] = ACT_BUSY_SIT_GROUND_ENTRY,
		["ACT_BUSY_SIT_GROUND_EXIT"] = ACT_BUSY_SIT_GROUND_EXIT,
		["ACT_BUSY_SIT_CHAIR"] = ACT_BUSY_SIT_CHAIR,
		["ACT_BUSY_SIT_CHAIR_ENTRY"] = ACT_BUSY_SIT_CHAIR_ENTRY,
		["ACT_BUSY_SIT_CHAIR_EXIT"] = ACT_BUSY_SIT_CHAIR_EXIT,
		["ACT_BUSY_STAND"] = ACT_BUSY_STAND,
		["ACT_BUSY_QUEUE"] = ACT_BUSY_QUEUE,
		["ACT_DUCK_DODGE"] = ACT_DUCK_DODGE,
		["ACT_DIE_BARNACLE_SWALLOW"] = ACT_DIE_BARNACLE_SWALLOW,
		["ACT_GESTURE_BARNACLE_STRANGLE"] = ACT_GESTURE_BARNACLE_STRANGLE,
		["ACT_PHYSCANNON_DETACH"] = ACT_PHYSCANNON_DETACH,
		["ACT_PHYSCANNON_ANIMATE"] = ACT_PHYSCANNON_ANIMATE,
		["ACT_PHYSCANNON_ANIMATE_PRE"] = ACT_PHYSCANNON_ANIMATE_PRE,
		["ACT_PHYSCANNON_ANIMATE_POST"] = ACT_PHYSCANNON_ANIMATE_POST,
		["ACT_DIE_FRONTSIDE"] = ACT_DIE_FRONTSIDE,
		["ACT_DIE_RIGHTSIDE"] = ACT_DIE_RIGHTSIDE,
		["ACT_DIE_BACKSIDE"] = ACT_DIE_BACKSIDE,
		["ACT_DIE_LEFTSIDE"] = ACT_DIE_LEFTSIDE,
		["ACT_OPEN_DOOR"] = ACT_OPEN_DOOR,
		["ACT_DI_ALYX_ZOMBIE_MELEE"] = ACT_DI_ALYX_ZOMBIE_MELEE,
		["ACT_DI_ALYX_ZOMBIE_TORSO_MELEE"] = ACT_DI_ALYX_ZOMBIE_TORSO_MELEE,
		["ACT_DI_ALYX_HEADCRAB_MELEE"] = ACT_DI_ALYX_HEADCRAB_MELEE,
		["ACT_DI_ALYX_ANTLION"] = ACT_DI_ALYX_ANTLION,
		["ACT_DI_ALYX_ZOMBIE_SHOTGUN64"] = ACT_DI_ALYX_ZOMBIE_SHOTGUN64,
		["ACT_DI_ALYX_ZOMBIE_SHOTGUN26"] = ACT_DI_ALYX_ZOMBIE_SHOTGUN26,
		["ACT_READINESS_RELAXED_TO_STIMULATED"] = ACT_READINESS_RELAXED_TO_STIMULATED,
		["ACT_READINESS_RELAXED_TO_STIMULATED_WALK"] = ACT_READINESS_RELAXED_TO_STIMULATED_WALK,
		["ACT_READINESS_AGITATED_TO_STIMULATED"] = ACT_READINESS_AGITATED_TO_STIMULATED,
		["ACT_READINESS_STIMULATED_TO_RELAXED"] = ACT_READINESS_STIMULATED_TO_RELAXED,
		["ACT_READINESS_PISTOL_RELAXED_TO_STIMULATED"] = ACT_READINESS_PISTOL_RELAXED_TO_STIMULATED,
		["ACT_READINESS_PISTOL_RELAXED_TO_STIMULATED_WALK"] = ACT_READINESS_PISTOL_RELAXED_TO_STIMULATED_WALK,
		["ACT_READINESS_PISTOL_AGITATED_TO_STIMULATED"] = ACT_READINESS_PISTOL_AGITATED_TO_STIMULATED,
		["ACT_READINESS_PISTOL_STIMULATED_TO_RELAXED"] = ACT_READINESS_PISTOL_STIMULATED_TO_RELAXED,
		["ACT_IDLE_CARRY"] = ACT_IDLE_CARRY,
		["ACT_WALK_CARRY"] = ACT_WALK_CARRY,
		["ACT_STARTDYING"] = ACT_STARTDYING,
		["ACT_DYINGLOOP"] = ACT_DYINGLOOP,
		["ACT_DYINGTODEAD"] = ACT_DYINGTODEAD,
		["ACT_RIDE_MANNED_GUN"] = ACT_RIDE_MANNED_GUN,
		["ACT_VM_SPRINT_ENTER"] = ACT_VM_SPRINT_ENTER,
		["ACT_VM_SPRINT_IDLE"] = ACT_VM_SPRINT_IDLE,
		["ACT_VM_SPRINT_LEAVE"] = ACT_VM_SPRINT_LEAVE,
		["ACT_FIRE_START"] = ACT_FIRE_START,
		["ACT_FIRE_LOOP"] = ACT_FIRE_LOOP,
		["ACT_FIRE_END"] = ACT_FIRE_END,
		["ACT_CROUCHING_GRENADEIDLE"] = ACT_CROUCHING_GRENADEIDLE,
		["ACT_CROUCHING_GRENADEREADY"] = ACT_CROUCHING_GRENADEREADY,
		["ACT_CROUCHING_PRIMARYATTACK"] = ACT_CROUCHING_PRIMARYATTACK,
		["ACT_OVERLAY_GRENADEIDLE"] = ACT_OVERLAY_GRENADEIDLE,
		["ACT_OVERLAY_GRENADEREADY"] = ACT_OVERLAY_GRENADEREADY,
		["ACT_OVERLAY_PRIMARYATTACK"] = ACT_OVERLAY_PRIMARYATTACK,
		["ACT_OVERLAY_SHIELD_UP"] = ACT_OVERLAY_SHIELD_UP,
		["ACT_OVERLAY_SHIELD_DOWN"] = ACT_OVERLAY_SHIELD_DOWN,
		["ACT_OVERLAY_SHIELD_UP_IDLE"] = ACT_OVERLAY_SHIELD_UP_IDLE,
		["ACT_OVERLAY_SHIELD_ATTACK"] = ACT_OVERLAY_SHIELD_ATTACK,
		["ACT_OVERLAY_SHIELD_KNOCKBACK"] = ACT_OVERLAY_SHIELD_KNOCKBACK,
		["ACT_SHIELD_UP"] = ACT_SHIELD_UP,
		["ACT_SHIELD_DOWN"] = ACT_SHIELD_DOWN,
		["ACT_SHIELD_UP_IDLE"] = ACT_SHIELD_UP_IDLE,
		["ACT_SHIELD_ATTACK"] = ACT_SHIELD_ATTACK,
		["ACT_SHIELD_KNOCKBACK"] = ACT_SHIELD_KNOCKBACK,
		["ACT_CROUCHING_SHIELD_UP"] = ACT_CROUCHING_SHIELD_UP,
		["ACT_CROUCHING_SHIELD_DOWN"] = ACT_CROUCHING_SHIELD_DOWN,
		["ACT_CROUCHING_SHIELD_UP_IDLE"] = ACT_CROUCHING_SHIELD_UP_IDLE,
		["ACT_CROUCHING_SHIELD_ATTACK"] = ACT_CROUCHING_SHIELD_ATTACK,
		["ACT_CROUCHING_SHIELD_KNOCKBACK"] = ACT_CROUCHING_SHIELD_KNOCKBACK,
		["ACT_TURNRIGHT45"] = ACT_TURNRIGHT45,
		["ACT_TURNLEFT45"] = ACT_TURNLEFT45,
		["ACT_TURN"] = ACT_TURN,
		["ACT_OBJ_ASSEMBLING"] = ACT_OBJ_ASSEMBLING,
		["ACT_OBJ_DISMANTLING"] = ACT_OBJ_DISMANTLING,
		["ACT_OBJ_STARTUP"] = ACT_OBJ_STARTUP,
		["ACT_OBJ_RUNNING"] = ACT_OBJ_RUNNING,
		["ACT_OBJ_IDLE"] = ACT_OBJ_IDLE,
		["ACT_OBJ_PLACING"] = ACT_OBJ_PLACING,
		["ACT_OBJ_DETERIORATING"] = ACT_OBJ_DETERIORATING,
		["ACT_OBJ_UPGRADING"] = ACT_OBJ_UPGRADING,
		["ACT_DEPLOY"] = ACT_DEPLOY,
		["ACT_DEPLOY_IDLE"] = ACT_DEPLOY_IDLE,
		["ACT_UNDEPLOY"] = ACT_UNDEPLOY,
		["ACT_GRENADE_ROLL"] = ACT_GRENADE_ROLL,
		["ACT_GRENADE_TOSS"] = ACT_GRENADE_TOSS,
		["ACT_HANDGRENADE_THROW1"] = ACT_HANDGRENADE_THROW1,
		["ACT_HANDGRENADE_THROW2"] = ACT_HANDGRENADE_THROW2,
		["ACT_HANDGRENADE_THROW3"] = ACT_HANDGRENADE_THROW3,
		["ACT_SHOTGUN_IDLE_DEEP"] = ACT_SHOTGUN_IDLE_DEEP,
		["ACT_SHOTGUN_IDLE4"] = ACT_SHOTGUN_IDLE4,
		["ACT_GLOCK_SHOOTEMPTY"] = ACT_GLOCK_SHOOTEMPTY,
		["ACT_GLOCK_SHOOT_RELOAD"] = ACT_GLOCK_SHOOT_RELOAD,
		["ACT_RPG_DRAW_UNLOADED"] = ACT_RPG_DRAW_UNLOADED,
		["ACT_RPG_HOLSTER_UNLOADED"] = ACT_RPG_HOLSTER_UNLOADED,
		["ACT_RPG_IDLE_UNLOADED"] = ACT_RPG_IDLE_UNLOADED,
		["ACT_RPG_FIDGET_UNLOADED"] = ACT_RPG_FIDGET_UNLOADED,
		["ACT_CROSSBOW_DRAW_UNLOADED"] = ACT_CROSSBOW_DRAW_UNLOADED,
		["ACT_CROSSBOW_IDLE_UNLOADED"] = ACT_CROSSBOW_IDLE_UNLOADED,
		["ACT_CROSSBOW_FIDGET_UNLOADED"] = ACT_CROSSBOW_FIDGET_UNLOADED,
		["ACT_GAUSS_SPINUP"] = ACT_GAUSS_SPINUP,
		["ACT_GAUSS_SPINCYCLE"] = ACT_GAUSS_SPINCYCLE,
		["ACT_TRIPMINE_GROUND"] = ACT_TRIPMINE_GROUND,
		["ACT_TRIPMINE_WORLD"] = ACT_TRIPMINE_WORLD,
		["ACT_VM_PRIMARYATTACK_SILENCED"] = ACT_VM_PRIMARYATTACK_SILENCED,
		["ACT_VM_RELOAD_SILENCED"] = ACT_VM_RELOAD_SILENCED,
		["ACT_VM_DRYFIRE_SILENCED"] = ACT_VM_DRYFIRE_SILENCED,
		["ACT_VM_IDLE_SILENCED"] = ACT_VM_IDLE_SILENCED,
		["ACT_VM_DRAW_SILENCED"] = ACT_VM_DRAW_SILENCED,
		["ACT_VM_IDLE_EMPTY_LEFT"] = ACT_VM_IDLE_EMPTY_LEFT,
		["ACT_VM_DRYFIRE_LEFT"] = ACT_VM_DRYFIRE_LEFT,
		["ACT_PLAYER_IDLE_FIRE"] = ACT_PLAYER_IDLE_FIRE,
		["ACT_PLAYER_CROUCH_FIRE"] = ACT_PLAYER_CROUCH_FIRE,
		["ACT_PLAYER_CROUCH_WALK_FIRE"] = ACT_PLAYER_CROUCH_WALK_FIRE,
		["ACT_PLAYER_WALK_FIRE"] = ACT_PLAYER_WALK_FIRE,
		["ACT_PLAYER_RUN_FIRE"] = ACT_PLAYER_RUN_FIRE,
		["ACT_IDLETORUN"] = ACT_IDLETORUN,
		["ACT_RUNTOIDLE"] = ACT_RUNTOIDLE,
		["ACT_SPRINT"] = ACT_SPRINT,
		["ACT_GET_DOWN_STAND"] = ACT_GET_DOWN_STAND,
		["ACT_GET_UP_STAND"] = ACT_GET_UP_STAND,
		["ACT_GET_DOWN_CROUCH"] = ACT_GET_DOWN_CROUCH,
		["ACT_GET_UP_CROUCH"] = ACT_GET_UP_CROUCH,
		["ACT_PRONE_FORWARD"] = ACT_PRONE_FORWARD,
		["ACT_PRONE_IDLE"] = ACT_PRONE_IDLE,
		["ACT_DEEPIDLE1"] = ACT_DEEPIDLE1,
		["ACT_DEEPIDLE2"] = ACT_DEEPIDLE2,
		["ACT_DEEPIDLE3"] = ACT_DEEPIDLE3,
		["ACT_DEEPIDLE4"] = ACT_DEEPIDLE4,
		["ACT_VM_RELOAD_DEPLOYED"] = ACT_VM_RELOAD_DEPLOYED,
		["ACT_VM_RELOAD_IDLE"] = ACT_VM_RELOAD_IDLE,
		["ACT_VM_DRAW_DEPLOYED"] = ACT_VM_DRAW_DEPLOYED,
		["ACT_VM_DRAW_EMPTY"] = ACT_VM_DRAW_EMPTY,
		["ACT_VM_PRIMARYATTACK_EMPTY"] = ACT_VM_PRIMARYATTACK_EMPTY,
		["ACT_VM_RELOAD_EMPTY"] = ACT_VM_RELOAD_EMPTY,
		["ACT_VM_IDLE_EMPTY"] = ACT_VM_IDLE_EMPTY,
		["ACT_VM_IDLE_DEPLOYED_EMPTY"] = ACT_VM_IDLE_DEPLOYED_EMPTY,
		["ACT_VM_IDLE_8"] = ACT_VM_IDLE_8,
		["ACT_VM_IDLE_7"] = ACT_VM_IDLE_7,
		["ACT_VM_IDLE_6"] = ACT_VM_IDLE_6,
		["ACT_VM_IDLE_5"] = ACT_VM_IDLE_5,
		["ACT_VM_IDLE_4"] = ACT_VM_IDLE_4,
		["ACT_VM_IDLE_3"] = ACT_VM_IDLE_3,
		["ACT_VM_IDLE_2"] = ACT_VM_IDLE_2,
		["ACT_VM_IDLE_1"] = ACT_VM_IDLE_1,
		["ACT_VM_IDLE_DEPLOYED"] = ACT_VM_IDLE_DEPLOYED,
		["ACT_VM_IDLE_DEPLOYED_8"] = ACT_VM_IDLE_DEPLOYED_8,
		["ACT_VM_IDLE_DEPLOYED_7"] = ACT_VM_IDLE_DEPLOYED_7,
		["ACT_VM_IDLE_DEPLOYED_6"] = ACT_VM_IDLE_DEPLOYED_6,
		["ACT_VM_IDLE_DEPLOYED_5"] = ACT_VM_IDLE_DEPLOYED_5,
		["ACT_VM_IDLE_DEPLOYED_4"] = ACT_VM_IDLE_DEPLOYED_4,
		["ACT_VM_IDLE_DEPLOYED_3"] = ACT_VM_IDLE_DEPLOYED_3,
		["ACT_VM_IDLE_DEPLOYED_2"] = ACT_VM_IDLE_DEPLOYED_2,
		["ACT_VM_IDLE_DEPLOYED_1"] = ACT_VM_IDLE_DEPLOYED_1,
		["ACT_VM_UNDEPLOY"] = ACT_VM_UNDEPLOY,
		["ACT_VM_UNDEPLOY_8"] = ACT_VM_UNDEPLOY_8,
		["ACT_VM_UNDEPLOY_7"] = ACT_VM_UNDEPLOY_7,
		["ACT_VM_UNDEPLOY_6"] = ACT_VM_UNDEPLOY_6,
		["ACT_VM_UNDEPLOY_5"] = ACT_VM_UNDEPLOY_5,
		["ACT_VM_UNDEPLOY_4"] = ACT_VM_UNDEPLOY_4,
		["ACT_VM_UNDEPLOY_3"] = ACT_VM_UNDEPLOY_3,
		["ACT_VM_UNDEPLOY_2"] = ACT_VM_UNDEPLOY_2,
		["ACT_VM_UNDEPLOY_1"] = ACT_VM_UNDEPLOY_1,
		["ACT_VM_UNDEPLOY_EMPTY"] = ACT_VM_UNDEPLOY_EMPTY,
		["ACT_VM_DEPLOY"] = ACT_VM_DEPLOY,
		["ACT_VM_DEPLOY_8"] = ACT_VM_DEPLOY_8,
		["ACT_VM_DEPLOY_7"] = ACT_VM_DEPLOY_7,
		["ACT_VM_DEPLOY_6"] = ACT_VM_DEPLOY_6,
		["ACT_VM_DEPLOY_5"] = ACT_VM_DEPLOY_5,
		["ACT_VM_DEPLOY_4"] = ACT_VM_DEPLOY_4,
		["ACT_VM_DEPLOY_3"] = ACT_VM_DEPLOY_3,
		["ACT_VM_DEPLOY_2"] = ACT_VM_DEPLOY_2,
		["ACT_VM_DEPLOY_1"] = ACT_VM_DEPLOY_1,
		["ACT_VM_DEPLOY_EMPTY"] = ACT_VM_DEPLOY_EMPTY,
		["ACT_VM_PRIMARYATTACK_8"] = ACT_VM_PRIMARYATTACK_8,
		["ACT_VM_PRIMARYATTACK_7"] = ACT_VM_PRIMARYATTACK_7,
		["ACT_VM_PRIMARYATTACK_6"] = ACT_VM_PRIMARYATTACK_6,
		["ACT_VM_PRIMARYATTACK_5"] = ACT_VM_PRIMARYATTACK_5,
		["ACT_VM_PRIMARYATTACK_4"] = ACT_VM_PRIMARYATTACK_4,
		["ACT_VM_PRIMARYATTACK_3"] = ACT_VM_PRIMARYATTACK_3,
		["ACT_VM_PRIMARYATTACK_2"] = ACT_VM_PRIMARYATTACK_2,
		["ACT_VM_PRIMARYATTACK_1"] = ACT_VM_PRIMARYATTACK_1,
		["ACT_VM_PRIMARYATTACK_DEPLOYED"] = ACT_VM_PRIMARYATTACK_DEPLOYED,
		["ACT_VM_PRIMARYATTACK_DEPLOYED_8"] = ACT_VM_PRIMARYATTACK_DEPLOYED_8,
		["ACT_VM_PRIMARYATTACK_DEPLOYED_7"] = ACT_VM_PRIMARYATTACK_DEPLOYED_7,
		["ACT_VM_PRIMARYATTACK_DEPLOYED_6"] = ACT_VM_PRIMARYATTACK_DEPLOYED_6,
		["ACT_VM_PRIMARYATTACK_DEPLOYED_5"] = ACT_VM_PRIMARYATTACK_DEPLOYED_5,
		["ACT_VM_PRIMARYATTACK_DEPLOYED_4"] = ACT_VM_PRIMARYATTACK_DEPLOYED_4,
		["ACT_VM_PRIMARYATTACK_DEPLOYED_3"] = ACT_VM_PRIMARYATTACK_DEPLOYED_3,
		["ACT_VM_PRIMARYATTACK_DEPLOYED_2"] = ACT_VM_PRIMARYATTACK_DEPLOYED_2,
		["ACT_VM_PRIMARYATTACK_DEPLOYED_1"] = ACT_VM_PRIMARYATTACK_DEPLOYED_1,
		["ACT_VM_PRIMARYATTACK_DEPLOYED_EMPTY"] = ACT_VM_PRIMARYATTACK_DEPLOYED_EMPTY,
		["ACT_DOD_DEPLOYED"] = ACT_DOD_DEPLOYED,
		["ACT_DOD_PRONE_DEPLOYED"] = ACT_DOD_PRONE_DEPLOYED,
		["ACT_DOD_IDLE_ZOOMED"] = ACT_DOD_IDLE_ZOOMED,
		["ACT_DOD_WALK_ZOOMED"] = ACT_DOD_WALK_ZOOMED,
		["ACT_DOD_CROUCH_ZOOMED"] = ACT_DOD_CROUCH_ZOOMED,
		["ACT_DOD_CROUCHWALK_ZOOMED"] = ACT_DOD_CROUCHWALK_ZOOMED,
		["ACT_DOD_PRONE_ZOOMED"] = ACT_DOD_PRONE_ZOOMED,
		["ACT_DOD_PRONE_FORWARD_ZOOMED"] = ACT_DOD_PRONE_FORWARD_ZOOMED,
		["ACT_DOD_PRIMARYATTACK_DEPLOYED"] = ACT_DOD_PRIMARYATTACK_DEPLOYED,
		["ACT_DOD_PRIMARYATTACK_PRONE_DEPLOYED"] = ACT_DOD_PRIMARYATTACK_PRONE_DEPLOYED,
		["ACT_DOD_RELOAD_DEPLOYED"] = ACT_DOD_RELOAD_DEPLOYED,
		["ACT_DOD_RELOAD_PRONE_DEPLOYED"] = ACT_DOD_RELOAD_PRONE_DEPLOYED,
		["ACT_DOD_PRIMARYATTACK_PRONE"] = ACT_DOD_PRIMARYATTACK_PRONE,
		["ACT_DOD_SECONDARYATTACK_PRONE"] = ACT_DOD_SECONDARYATTACK_PRONE,
		["ACT_DOD_RELOAD_CROUCH"] = ACT_DOD_RELOAD_CROUCH,
		["ACT_DOD_RELOAD_PRONE"] = ACT_DOD_RELOAD_PRONE,
		["ACT_DOD_STAND_IDLE"] = ACT_DOD_STAND_IDLE,
		["ACT_DOD_STAND_AIM"] = ACT_DOD_STAND_AIM,
		["ACT_DOD_CROUCH_IDLE"] = ACT_DOD_CROUCH_IDLE,
		["ACT_DOD_CROUCH_AIM"] = ACT_DOD_CROUCH_AIM,
		["ACT_DOD_CROUCHWALK_IDLE"] = ACT_DOD_CROUCHWALK_IDLE,
		["ACT_DOD_CROUCHWALK_AIM"] = ACT_DOD_CROUCHWALK_AIM,
		["ACT_DOD_WALK_IDLE"] = ACT_DOD_WALK_IDLE,
		["ACT_DOD_WALK_AIM"] = ACT_DOD_WALK_AIM,
		["ACT_DOD_RUN_IDLE"] = ACT_DOD_RUN_IDLE,
		["ACT_DOD_RUN_AIM"] = ACT_DOD_RUN_AIM,
		["ACT_DOD_STAND_AIM_PISTOL"] = ACT_DOD_STAND_AIM_PISTOL,
		["ACT_DOD_CROUCH_AIM_PISTOL"] = ACT_DOD_CROUCH_AIM_PISTOL,
		["ACT_DOD_CROUCHWALK_AIM_PISTOL"] = ACT_DOD_CROUCHWALK_AIM_PISTOL,
		["ACT_DOD_WALK_AIM_PISTOL"] = ACT_DOD_WALK_AIM_PISTOL,
		["ACT_DOD_RUN_AIM_PISTOL"] = ACT_DOD_RUN_AIM_PISTOL,
		["ACT_DOD_PRONE_AIM_PISTOL"] = ACT_DOD_PRONE_AIM_PISTOL,
		["ACT_DOD_STAND_IDLE_PISTOL"] = ACT_DOD_STAND_IDLE_PISTOL,
		["ACT_DOD_CROUCH_IDLE_PISTOL"] = ACT_DOD_CROUCH_IDLE_PISTOL,
		["ACT_DOD_CROUCHWALK_IDLE_PISTOL"] = ACT_DOD_CROUCHWALK_IDLE_PISTOL,
		["ACT_DOD_WALK_IDLE_PISTOL"] = ACT_DOD_WALK_IDLE_PISTOL,
		["ACT_DOD_RUN_IDLE_PISTOL"] = ACT_DOD_RUN_IDLE_PISTOL,
		["ACT_DOD_SPRINT_IDLE_PISTOL"] = ACT_DOD_SPRINT_IDLE_PISTOL,
		["ACT_DOD_PRONEWALK_IDLE_PISTOL"] = ACT_DOD_PRONEWALK_IDLE_PISTOL,
		["ACT_DOD_STAND_AIM_C96"] = ACT_DOD_STAND_AIM_C96,
		["ACT_DOD_CROUCH_AIM_C96"] = ACT_DOD_CROUCH_AIM_C96,
		["ACT_DOD_CROUCHWALK_AIM_C96"] = ACT_DOD_CROUCHWALK_AIM_C96,
		["ACT_DOD_WALK_AIM_C96"] = ACT_DOD_WALK_AIM_C96,
		["ACT_DOD_RUN_AIM_C96"] = ACT_DOD_RUN_AIM_C96,
		["ACT_DOD_PRONE_AIM_C96"] = ACT_DOD_PRONE_AIM_C96,
		["ACT_DOD_STAND_IDLE_C96"] = ACT_DOD_STAND_IDLE_C96,
		["ACT_DOD_CROUCH_IDLE_C96"] = ACT_DOD_CROUCH_IDLE_C96,
		["ACT_DOD_CROUCHWALK_IDLE_C96"] = ACT_DOD_CROUCHWALK_IDLE_C96,
		["ACT_DOD_WALK_IDLE_C96"] = ACT_DOD_WALK_IDLE_C96,
		["ACT_DOD_RUN_IDLE_C96"] = ACT_DOD_RUN_IDLE_C96,
		["ACT_DOD_SPRINT_IDLE_C96"] = ACT_DOD_SPRINT_IDLE_C96,
		["ACT_DOD_PRONEWALK_IDLE_C96"] = ACT_DOD_PRONEWALK_IDLE_C96,
		["ACT_DOD_STAND_AIM_RIFLE"] = ACT_DOD_STAND_AIM_RIFLE,
		["ACT_DOD_CROUCH_AIM_RIFLE"] = ACT_DOD_CROUCH_AIM_RIFLE,
		["ACT_DOD_CROUCHWALK_AIM_RIFLE"] = ACT_DOD_CROUCHWALK_AIM_RIFLE,
		["ACT_DOD_WALK_AIM_RIFLE"] = ACT_DOD_WALK_AIM_RIFLE,
		["ACT_DOD_RUN_AIM_RIFLE"] = ACT_DOD_RUN_AIM_RIFLE,
		["ACT_DOD_PRONE_AIM_RIFLE"] = ACT_DOD_PRONE_AIM_RIFLE,
		["ACT_DOD_STAND_IDLE_RIFLE"] = ACT_DOD_STAND_IDLE_RIFLE,
		["ACT_DOD_CROUCH_IDLE_RIFLE"] = ACT_DOD_CROUCH_IDLE_RIFLE,
		["ACT_DOD_CROUCHWALK_IDLE_RIFLE"] = ACT_DOD_CROUCHWALK_IDLE_RIFLE,
		["ACT_DOD_WALK_IDLE_RIFLE"] = ACT_DOD_WALK_IDLE_RIFLE,
		["ACT_DOD_RUN_IDLE_RIFLE"] = ACT_DOD_RUN_IDLE_RIFLE,
		["ACT_DOD_SPRINT_IDLE_RIFLE"] = ACT_DOD_SPRINT_IDLE_RIFLE,
		["ACT_DOD_PRONEWALK_IDLE_RIFLE"] = ACT_DOD_PRONEWALK_IDLE_RIFLE,
		["ACT_DOD_STAND_AIM_BOLT"] = ACT_DOD_STAND_AIM_BOLT,
		["ACT_DOD_CROUCH_AIM_BOLT"] = ACT_DOD_CROUCH_AIM_BOLT,
		["ACT_DOD_CROUCHWALK_AIM_BOLT"] = ACT_DOD_CROUCHWALK_AIM_BOLT,
		["ACT_DOD_WALK_AIM_BOLT"] = ACT_DOD_WALK_AIM_BOLT,
		["ACT_DOD_RUN_AIM_BOLT"] = ACT_DOD_RUN_AIM_BOLT,
		["ACT_DOD_PRONE_AIM_BOLT"] = ACT_DOD_PRONE_AIM_BOLT,
		["ACT_DOD_STAND_IDLE_BOLT"] = ACT_DOD_STAND_IDLE_BOLT,
		["ACT_DOD_CROUCH_IDLE_BOLT"] = ACT_DOD_CROUCH_IDLE_BOLT,
		["ACT_DOD_CROUCHWALK_IDLE_BOLT"] = ACT_DOD_CROUCHWALK_IDLE_BOLT,
		["ACT_DOD_WALK_IDLE_BOLT"] = ACT_DOD_WALK_IDLE_BOLT,
		["ACT_DOD_RUN_IDLE_BOLT"] = ACT_DOD_RUN_IDLE_BOLT,
		["ACT_DOD_SPRINT_IDLE_BOLT"] = ACT_DOD_SPRINT_IDLE_BOLT,
		["ACT_DOD_PRONEWALK_IDLE_BOLT"] = ACT_DOD_PRONEWALK_IDLE_BOLT,
		["ACT_DOD_STAND_AIM_TOMMY"] = ACT_DOD_STAND_AIM_TOMMY,
		["ACT_DOD_CROUCH_AIM_TOMMY"] = ACT_DOD_CROUCH_AIM_TOMMY,
		["ACT_DOD_CROUCHWALK_AIM_TOMMY"] = ACT_DOD_CROUCHWALK_AIM_TOMMY,
		["ACT_DOD_WALK_AIM_TOMMY"] = ACT_DOD_WALK_AIM_TOMMY,
		["ACT_DOD_RUN_AIM_TOMMY"] = ACT_DOD_RUN_AIM_TOMMY,
		["ACT_DOD_PRONE_AIM_TOMMY"] = ACT_DOD_PRONE_AIM_TOMMY,
		["ACT_DOD_STAND_IDLE_TOMMY"] = ACT_DOD_STAND_IDLE_TOMMY,
		["ACT_DOD_CROUCH_IDLE_TOMMY"] = ACT_DOD_CROUCH_IDLE_TOMMY,
		["ACT_DOD_CROUCHWALK_IDLE_TOMMY"] = ACT_DOD_CROUCHWALK_IDLE_TOMMY,
		["ACT_DOD_WALK_IDLE_TOMMY"] = ACT_DOD_WALK_IDLE_TOMMY,
		["ACT_DOD_RUN_IDLE_TOMMY"] = ACT_DOD_RUN_IDLE_TOMMY,
		["ACT_DOD_SPRINT_IDLE_TOMMY"] = ACT_DOD_SPRINT_IDLE_TOMMY,
		["ACT_DOD_PRONEWALK_IDLE_TOMMY"] = ACT_DOD_PRONEWALK_IDLE_TOMMY,
		["ACT_DOD_STAND_AIM_MP40"] = ACT_DOD_STAND_AIM_MP40,
		["ACT_DOD_CROUCH_AIM_MP40"] = ACT_DOD_CROUCH_AIM_MP40,
		["ACT_DOD_CROUCHWALK_AIM_MP40"] = ACT_DOD_CROUCHWALK_AIM_MP40,
		["ACT_DOD_WALK_AIM_MP40"] = ACT_DOD_WALK_AIM_MP40,
		["ACT_DOD_RUN_AIM_MP40"] = ACT_DOD_RUN_AIM_MP40,
		["ACT_DOD_PRONE_AIM_MP40"] = ACT_DOD_PRONE_AIM_MP40,
		["ACT_DOD_STAND_IDLE_MP40"] = ACT_DOD_STAND_IDLE_MP40,
		["ACT_DOD_CROUCH_IDLE_MP40"] = ACT_DOD_CROUCH_IDLE_MP40,
		["ACT_DOD_CROUCHWALK_IDLE_MP40"] = ACT_DOD_CROUCHWALK_IDLE_MP40,
		["ACT_DOD_WALK_IDLE_MP40"] = ACT_DOD_WALK_IDLE_MP40,
		["ACT_DOD_RUN_IDLE_MP40"] = ACT_DOD_RUN_IDLE_MP40,
		["ACT_DOD_SPRINT_IDLE_MP40"] = ACT_DOD_SPRINT_IDLE_MP40,
		["ACT_DOD_PRONEWALK_IDLE_MP40"] = ACT_DOD_PRONEWALK_IDLE_MP40,
		["ACT_DOD_STAND_AIM_MP44"] = ACT_DOD_STAND_AIM_MP44,
		["ACT_DOD_CROUCH_AIM_MP44"] = ACT_DOD_CROUCH_AIM_MP44,
		["ACT_DOD_CROUCHWALK_AIM_MP44"] = ACT_DOD_CROUCHWALK_AIM_MP44,
		["ACT_DOD_WALK_AIM_MP44"] = ACT_DOD_WALK_AIM_MP44,
		["ACT_DOD_RUN_AIM_MP44"] = ACT_DOD_RUN_AIM_MP44,
		["ACT_DOD_PRONE_AIM_MP44"] = ACT_DOD_PRONE_AIM_MP44,
		["ACT_DOD_STAND_IDLE_MP44"] = ACT_DOD_STAND_IDLE_MP44,
		["ACT_DOD_CROUCH_IDLE_MP44"] = ACT_DOD_CROUCH_IDLE_MP44,
		["ACT_DOD_CROUCHWALK_IDLE_MP44"] = ACT_DOD_CROUCHWALK_IDLE_MP44,
		["ACT_DOD_WALK_IDLE_MP44"] = ACT_DOD_WALK_IDLE_MP44,
		["ACT_DOD_RUN_IDLE_MP44"] = ACT_DOD_RUN_IDLE_MP44,
		["ACT_DOD_SPRINT_IDLE_MP44"] = ACT_DOD_SPRINT_IDLE_MP44,
		["ACT_DOD_PRONEWALK_IDLE_MP44"] = ACT_DOD_PRONEWALK_IDLE_MP44,
		["ACT_DOD_STAND_AIM_GREASE"] = ACT_DOD_STAND_AIM_GREASE,
		["ACT_DOD_CROUCH_AIM_GREASE"] = ACT_DOD_CROUCH_AIM_GREASE,
		["ACT_DOD_CROUCHWALK_AIM_GREASE"] = ACT_DOD_CROUCHWALK_AIM_GREASE,
		["ACT_DOD_WALK_AIM_GREASE"] = ACT_DOD_WALK_AIM_GREASE,
		["ACT_DOD_RUN_AIM_GREASE"] = ACT_DOD_RUN_AIM_GREASE,
		["ACT_DOD_PRONE_AIM_GREASE"] = ACT_DOD_PRONE_AIM_GREASE,
		["ACT_DOD_STAND_IDLE_GREASE"] = ACT_DOD_STAND_IDLE_GREASE,
		["ACT_DOD_CROUCH_IDLE_GREASE"] = ACT_DOD_CROUCH_IDLE_GREASE,
		["ACT_DOD_CROUCHWALK_IDLE_GREASE"] = ACT_DOD_CROUCHWALK_IDLE_GREASE,
		["ACT_DOD_WALK_IDLE_GREASE"] = ACT_DOD_WALK_IDLE_GREASE,
		["ACT_DOD_RUN_IDLE_GREASE"] = ACT_DOD_RUN_IDLE_GREASE,
		["ACT_DOD_SPRINT_IDLE_GREASE"] = ACT_DOD_SPRINT_IDLE_GREASE,
		["ACT_DOD_PRONEWALK_IDLE_GREASE"] = ACT_DOD_PRONEWALK_IDLE_GREASE,
		["ACT_DOD_STAND_AIM_MG"] = ACT_DOD_STAND_AIM_MG,
		["ACT_DOD_CROUCH_AIM_MG"] = ACT_DOD_CROUCH_AIM_MG,
		["ACT_DOD_CROUCHWALK_AIM_MG"] = ACT_DOD_CROUCHWALK_AIM_MG,
		["ACT_DOD_WALK_AIM_MG"] = ACT_DOD_WALK_AIM_MG,
		["ACT_DOD_RUN_AIM_MG"] = ACT_DOD_RUN_AIM_MG,
		["ACT_DOD_PRONE_AIM_MG"] = ACT_DOD_PRONE_AIM_MG,
		["ACT_DOD_STAND_IDLE_MG"] = ACT_DOD_STAND_IDLE_MG,
		["ACT_DOD_CROUCH_IDLE_MG"] = ACT_DOD_CROUCH_IDLE_MG,
		["ACT_DOD_CROUCHWALK_IDLE_MG"] = ACT_DOD_CROUCHWALK_IDLE_MG,
		["ACT_DOD_WALK_IDLE_MG"] = ACT_DOD_WALK_IDLE_MG,
		["ACT_DOD_RUN_IDLE_MG"] = ACT_DOD_RUN_IDLE_MG,
		["ACT_DOD_SPRINT_IDLE_MG"] = ACT_DOD_SPRINT_IDLE_MG,
		["ACT_DOD_PRONEWALK_IDLE_MG"] = ACT_DOD_PRONEWALK_IDLE_MG,
		["ACT_DOD_STAND_AIM_30CAL"] = ACT_DOD_STAND_AIM_30CAL,
		["ACT_DOD_CROUCH_AIM_30CAL"] = ACT_DOD_CROUCH_AIM_30CAL,
		["ACT_DOD_CROUCHWALK_AIM_30CAL"] = ACT_DOD_CROUCHWALK_AIM_30CAL,
		["ACT_DOD_WALK_AIM_30CAL"] = ACT_DOD_WALK_AIM_30CAL,
		["ACT_DOD_RUN_AIM_30CAL"] = ACT_DOD_RUN_AIM_30CAL,
		["ACT_DOD_PRONE_AIM_30CAL"] = ACT_DOD_PRONE_AIM_30CAL,
		["ACT_DOD_STAND_IDLE_30CAL"] = ACT_DOD_STAND_IDLE_30CAL,
		["ACT_DOD_CROUCH_IDLE_30CAL"] = ACT_DOD_CROUCH_IDLE_30CAL,
		["ACT_DOD_CROUCHWALK_IDLE_30CAL"] = ACT_DOD_CROUCHWALK_IDLE_30CAL,
		["ACT_DOD_WALK_IDLE_30CAL"] = ACT_DOD_WALK_IDLE_30CAL,
		["ACT_DOD_RUN_IDLE_30CAL"] = ACT_DOD_RUN_IDLE_30CAL,
		["ACT_DOD_SPRINT_IDLE_30CAL"] = ACT_DOD_SPRINT_IDLE_30CAL,
		["ACT_DOD_PRONEWALK_IDLE_30CAL"] = ACT_DOD_PRONEWALK_IDLE_30CAL,
		["ACT_DOD_STAND_AIM_GREN_FRAG"] = ACT_DOD_STAND_AIM_GREN_FRAG,
		["ACT_DOD_CROUCH_AIM_GREN_FRAG"] = ACT_DOD_CROUCH_AIM_GREN_FRAG,
		["ACT_DOD_CROUCHWALK_AIM_GREN_FRAG"] = ACT_DOD_CROUCHWALK_AIM_GREN_FRAG,
		["ACT_DOD_WALK_AIM_GREN_FRAG"] = ACT_DOD_WALK_AIM_GREN_FRAG,
		["ACT_DOD_RUN_AIM_GREN_FRAG"] = ACT_DOD_RUN_AIM_GREN_FRAG,
		["ACT_DOD_PRONE_AIM_GREN_FRAG"] = ACT_DOD_PRONE_AIM_GREN_FRAG,
		["ACT_DOD_SPRINT_AIM_GREN_FRAG"] = ACT_DOD_SPRINT_AIM_GREN_FRAG,
		["ACT_DOD_PRONEWALK_AIM_GREN_FRAG"] = ACT_DOD_PRONEWALK_AIM_GREN_FRAG,
		["ACT_DOD_STAND_AIM_GREN_STICK"] = ACT_DOD_STAND_AIM_GREN_STICK,
		["ACT_DOD_CROUCH_AIM_GREN_STICK"] = ACT_DOD_CROUCH_AIM_GREN_STICK,
		["ACT_DOD_CROUCHWALK_AIM_GREN_STICK"] = ACT_DOD_CROUCHWALK_AIM_GREN_STICK,
		["ACT_DOD_WALK_AIM_GREN_STICK"] = ACT_DOD_WALK_AIM_GREN_STICK,
		["ACT_DOD_RUN_AIM_GREN_STICK"] = ACT_DOD_RUN_AIM_GREN_STICK,
		["ACT_DOD_PRONE_AIM_GREN_STICK"] = ACT_DOD_PRONE_AIM_GREN_STICK,
		["ACT_DOD_SPRINT_AIM_GREN_STICK"] = ACT_DOD_SPRINT_AIM_GREN_STICK,
		["ACT_DOD_PRONEWALK_AIM_GREN_STICK"] = ACT_DOD_PRONEWALK_AIM_GREN_STICK,
		["ACT_DOD_STAND_AIM_KNIFE"] = ACT_DOD_STAND_AIM_KNIFE,
		["ACT_DOD_CROUCH_AIM_KNIFE"] = ACT_DOD_CROUCH_AIM_KNIFE,
		["ACT_DOD_CROUCHWALK_AIM_KNIFE"] = ACT_DOD_CROUCHWALK_AIM_KNIFE,
		["ACT_DOD_WALK_AIM_KNIFE"] = ACT_DOD_WALK_AIM_KNIFE,
		["ACT_DOD_RUN_AIM_KNIFE"] = ACT_DOD_RUN_AIM_KNIFE,
		["ACT_DOD_PRONE_AIM_KNIFE"] = ACT_DOD_PRONE_AIM_KNIFE,
		["ACT_DOD_SPRINT_AIM_KNIFE"] = ACT_DOD_SPRINT_AIM_KNIFE,
		["ACT_DOD_PRONEWALK_AIM_KNIFE"] = ACT_DOD_PRONEWALK_AIM_KNIFE,
		["ACT_DOD_STAND_AIM_SPADE"] = ACT_DOD_STAND_AIM_SPADE,
		["ACT_DOD_CROUCH_AIM_SPADE"] = ACT_DOD_CROUCH_AIM_SPADE,
		["ACT_DOD_CROUCHWALK_AIM_SPADE"] = ACT_DOD_CROUCHWALK_AIM_SPADE,
		["ACT_DOD_WALK_AIM_SPADE"] = ACT_DOD_WALK_AIM_SPADE,
		["ACT_DOD_RUN_AIM_SPADE"] = ACT_DOD_RUN_AIM_SPADE,
		["ACT_DOD_PRONE_AIM_SPADE"] = ACT_DOD_PRONE_AIM_SPADE,
		["ACT_DOD_SPRINT_AIM_SPADE"] = ACT_DOD_SPRINT_AIM_SPADE,
		["ACT_DOD_PRONEWALK_AIM_SPADE"] = ACT_DOD_PRONEWALK_AIM_SPADE,
		["ACT_DOD_STAND_AIM_BAZOOKA"] = ACT_DOD_STAND_AIM_BAZOOKA,
		["ACT_DOD_CROUCH_AIM_BAZOOKA"] = ACT_DOD_CROUCH_AIM_BAZOOKA,
		["ACT_DOD_CROUCHWALK_AIM_BAZOOKA"] = ACT_DOD_CROUCHWALK_AIM_BAZOOKA,
		["ACT_DOD_WALK_AIM_BAZOOKA"] = ACT_DOD_WALK_AIM_BAZOOKA,
		["ACT_DOD_RUN_AIM_BAZOOKA"] = ACT_DOD_RUN_AIM_BAZOOKA,
		["ACT_DOD_PRONE_AIM_BAZOOKA"] = ACT_DOD_PRONE_AIM_BAZOOKA,
		["ACT_DOD_STAND_IDLE_BAZOOKA"] = ACT_DOD_STAND_IDLE_BAZOOKA,
		["ACT_DOD_CROUCH_IDLE_BAZOOKA"] = ACT_DOD_CROUCH_IDLE_BAZOOKA,
		["ACT_DOD_CROUCHWALK_IDLE_BAZOOKA"] = ACT_DOD_CROUCHWALK_IDLE_BAZOOKA,
		["ACT_DOD_WALK_IDLE_BAZOOKA"] = ACT_DOD_WALK_IDLE_BAZOOKA,
		["ACT_DOD_RUN_IDLE_BAZOOKA"] = ACT_DOD_RUN_IDLE_BAZOOKA,
		["ACT_DOD_SPRINT_IDLE_BAZOOKA"] = ACT_DOD_SPRINT_IDLE_BAZOOKA,
		["ACT_DOD_PRONEWALK_IDLE_BAZOOKA"] = ACT_DOD_PRONEWALK_IDLE_BAZOOKA,
		["ACT_DOD_STAND_AIM_PSCHRECK"] = ACT_DOD_STAND_AIM_PSCHRECK,
		["ACT_DOD_CROUCH_AIM_PSCHRECK"] = ACT_DOD_CROUCH_AIM_PSCHRECK,
		["ACT_DOD_CROUCHWALK_AIM_PSCHRECK"] = ACT_DOD_CROUCHWALK_AIM_PSCHRECK,
		["ACT_DOD_WALK_AIM_PSCHRECK"] = ACT_DOD_WALK_AIM_PSCHRECK,
		["ACT_DOD_RUN_AIM_PSCHRECK"] = ACT_DOD_RUN_AIM_PSCHRECK,
		["ACT_DOD_PRONE_AIM_PSCHRECK"] = ACT_DOD_PRONE_AIM_PSCHRECK,
		["ACT_DOD_STAND_IDLE_PSCHRECK"] = ACT_DOD_STAND_IDLE_PSCHRECK,
		["ACT_DOD_CROUCH_IDLE_PSCHRECK"] = ACT_DOD_CROUCH_IDLE_PSCHRECK,
		["ACT_DOD_CROUCHWALK_IDLE_PSCHRECK"] = ACT_DOD_CROUCHWALK_IDLE_PSCHRECK,
		["ACT_DOD_WALK_IDLE_PSCHRECK"] = ACT_DOD_WALK_IDLE_PSCHRECK,
		["ACT_DOD_RUN_IDLE_PSCHRECK"] = ACT_DOD_RUN_IDLE_PSCHRECK,
		["ACT_DOD_SPRINT_IDLE_PSCHRECK"] = ACT_DOD_SPRINT_IDLE_PSCHRECK,
		["ACT_DOD_PRONEWALK_IDLE_PSCHRECK"] = ACT_DOD_PRONEWALK_IDLE_PSCHRECK,
		["ACT_DOD_STAND_AIM_BAR"] = ACT_DOD_STAND_AIM_BAR,
		["ACT_DOD_CROUCH_AIM_BAR"] = ACT_DOD_CROUCH_AIM_BAR,
		["ACT_DOD_CROUCHWALK_AIM_BAR"] = ACT_DOD_CROUCHWALK_AIM_BAR,
		["ACT_DOD_WALK_AIM_BAR"] = ACT_DOD_WALK_AIM_BAR,
		["ACT_DOD_RUN_AIM_BAR"] = ACT_DOD_RUN_AIM_BAR,
		["ACT_DOD_PRONE_AIM_BAR"] = ACT_DOD_PRONE_AIM_BAR,
		["ACT_DOD_STAND_IDLE_BAR"] = ACT_DOD_STAND_IDLE_BAR,
		["ACT_DOD_CROUCH_IDLE_BAR"] = ACT_DOD_CROUCH_IDLE_BAR,
		["ACT_DOD_CROUCHWALK_IDLE_BAR"] = ACT_DOD_CROUCHWALK_IDLE_BAR,
		["ACT_DOD_WALK_IDLE_BAR"] = ACT_DOD_WALK_IDLE_BAR,
		["ACT_DOD_RUN_IDLE_BAR"] = ACT_DOD_RUN_IDLE_BAR,
		["ACT_DOD_SPRINT_IDLE_BAR"] = ACT_DOD_SPRINT_IDLE_BAR,
		["ACT_DOD_PRONEWALK_IDLE_BAR"] = ACT_DOD_PRONEWALK_IDLE_BAR,
		["ACT_DOD_STAND_ZOOM_RIFLE"] = ACT_DOD_STAND_ZOOM_RIFLE,
		["ACT_DOD_CROUCH_ZOOM_RIFLE"] = ACT_DOD_CROUCH_ZOOM_RIFLE,
		["ACT_DOD_CROUCHWALK_ZOOM_RIFLE"] = ACT_DOD_CROUCHWALK_ZOOM_RIFLE,
		["ACT_DOD_WALK_ZOOM_RIFLE"] = ACT_DOD_WALK_ZOOM_RIFLE,
		["ACT_DOD_RUN_ZOOM_RIFLE"] = ACT_DOD_RUN_ZOOM_RIFLE,
		["ACT_DOD_PRONE_ZOOM_RIFLE"] = ACT_DOD_PRONE_ZOOM_RIFLE,
		["ACT_DOD_STAND_ZOOM_BOLT"] = ACT_DOD_STAND_ZOOM_BOLT,
		["ACT_DOD_CROUCH_ZOOM_BOLT"] = ACT_DOD_CROUCH_ZOOM_BOLT,
		["ACT_DOD_CROUCHWALK_ZOOM_BOLT"] = ACT_DOD_CROUCHWALK_ZOOM_BOLT,
		["ACT_DOD_WALK_ZOOM_BOLT"] = ACT_DOD_WALK_ZOOM_BOLT,
		["ACT_DOD_RUN_ZOOM_BOLT"] = ACT_DOD_RUN_ZOOM_BOLT,
		["ACT_DOD_PRONE_ZOOM_BOLT"] = ACT_DOD_PRONE_ZOOM_BOLT,
		["ACT_DOD_STAND_ZOOM_BAZOOKA"] = ACT_DOD_STAND_ZOOM_BAZOOKA,
		["ACT_DOD_CROUCH_ZOOM_BAZOOKA"] = ACT_DOD_CROUCH_ZOOM_BAZOOKA,
		["ACT_DOD_CROUCHWALK_ZOOM_BAZOOKA"] = ACT_DOD_CROUCHWALK_ZOOM_BAZOOKA,
		["ACT_DOD_WALK_ZOOM_BAZOOKA"] = ACT_DOD_WALK_ZOOM_BAZOOKA,
		["ACT_DOD_RUN_ZOOM_BAZOOKA"] = ACT_DOD_RUN_ZOOM_BAZOOKA,
		["ACT_DOD_PRONE_ZOOM_BAZOOKA"] = ACT_DOD_PRONE_ZOOM_BAZOOKA,
		["ACT_DOD_STAND_ZOOM_PSCHRECK"] = ACT_DOD_STAND_ZOOM_PSCHRECK,
		["ACT_DOD_CROUCH_ZOOM_PSCHRECK"] = ACT_DOD_CROUCH_ZOOM_PSCHRECK,
		["ACT_DOD_CROUCHWALK_ZOOM_PSCHRECK"] = ACT_DOD_CROUCHWALK_ZOOM_PSCHRECK,
		["ACT_DOD_WALK_ZOOM_PSCHRECK"] = ACT_DOD_WALK_ZOOM_PSCHRECK,
		["ACT_DOD_RUN_ZOOM_PSCHRECK"] = ACT_DOD_RUN_ZOOM_PSCHRECK,
		["ACT_DOD_PRONE_ZOOM_PSCHRECK"] = ACT_DOD_PRONE_ZOOM_PSCHRECK,
		["ACT_DOD_DEPLOY_RIFLE"] = ACT_DOD_DEPLOY_RIFLE,
		["ACT_DOD_DEPLOY_TOMMY"] = ACT_DOD_DEPLOY_TOMMY,
		["ACT_DOD_DEPLOY_MG"] = ACT_DOD_DEPLOY_MG,
		["ACT_DOD_DEPLOY_30CAL"] = ACT_DOD_DEPLOY_30CAL,
		["ACT_DOD_PRONE_DEPLOY_RIFLE"] = ACT_DOD_PRONE_DEPLOY_RIFLE,
		["ACT_DOD_PRONE_DEPLOY_TOMMY"] = ACT_DOD_PRONE_DEPLOY_TOMMY,
		["ACT_DOD_PRONE_DEPLOY_MG"] = ACT_DOD_PRONE_DEPLOY_MG,
		["ACT_DOD_PRONE_DEPLOY_30CAL"] = ACT_DOD_PRONE_DEPLOY_30CAL,
		["ACT_DOD_PRIMARYATTACK_RIFLE"] = ACT_DOD_PRIMARYATTACK_RIFLE,
		["ACT_DOD_SECONDARYATTACK_RIFLE"] = ACT_DOD_SECONDARYATTACK_RIFLE,
		["ACT_DOD_PRIMARYATTACK_PRONE_RIFLE"] = ACT_DOD_PRIMARYATTACK_PRONE_RIFLE,
		["ACT_DOD_SECONDARYATTACK_PRONE_RIFLE"] = ACT_DOD_SECONDARYATTACK_PRONE_RIFLE,
		["ACT_DOD_PRIMARYATTACK_PRONE_DEPLOYED_RIFLE"] = ACT_DOD_PRIMARYATTACK_PRONE_DEPLOYED_RIFLE,
		["ACT_DOD_PRIMARYATTACK_DEPLOYED_RIFLE"] = ACT_DOD_PRIMARYATTACK_DEPLOYED_RIFLE,
		["ACT_DOD_PRIMARYATTACK_BOLT"] = ACT_DOD_PRIMARYATTACK_BOLT,
		["ACT_DOD_SECONDARYATTACK_BOLT"] = ACT_DOD_SECONDARYATTACK_BOLT,
		["ACT_DOD_PRIMARYATTACK_PRONE_BOLT"] = ACT_DOD_PRIMARYATTACK_PRONE_BOLT,
		["ACT_DOD_SECONDARYATTACK_PRONE_BOLT"] = ACT_DOD_SECONDARYATTACK_PRONE_BOLT,
		["ACT_DOD_PRIMARYATTACK_TOMMY"] = ACT_DOD_PRIMARYATTACK_TOMMY,
		["ACT_DOD_PRIMARYATTACK_PRONE_TOMMY"] = ACT_DOD_PRIMARYATTACK_PRONE_TOMMY,
		["ACT_DOD_SECONDARYATTACK_TOMMY"] = ACT_DOD_SECONDARYATTACK_TOMMY,
		["ACT_DOD_SECONDARYATTACK_PRONE_TOMMY"] = ACT_DOD_SECONDARYATTACK_PRONE_TOMMY,
		["ACT_DOD_PRIMARYATTACK_MP40"] = ACT_DOD_PRIMARYATTACK_MP40,
		["ACT_DOD_PRIMARYATTACK_PRONE_MP40"] = ACT_DOD_PRIMARYATTACK_PRONE_MP40,
		["ACT_DOD_SECONDARYATTACK_MP40"] = ACT_DOD_SECONDARYATTACK_MP40,
		["ACT_DOD_SECONDARYATTACK_PRONE_MP40"] = ACT_DOD_SECONDARYATTACK_PRONE_MP40,
		["ACT_DOD_PRIMARYATTACK_MP44"] = ACT_DOD_PRIMARYATTACK_MP44,
		["ACT_DOD_PRIMARYATTACK_PRONE_MP44"] = ACT_DOD_PRIMARYATTACK_PRONE_MP44,
		["ACT_DOD_PRIMARYATTACK_GREASE"] = ACT_DOD_PRIMARYATTACK_GREASE,
		["ACT_DOD_PRIMARYATTACK_PRONE_GREASE"] = ACT_DOD_PRIMARYATTACK_PRONE_GREASE,
		["ACT_DOD_PRIMARYATTACK_PISTOL"] = ACT_DOD_PRIMARYATTACK_PISTOL,
		["ACT_DOD_PRIMARYATTACK_PRONE_PISTOL"] = ACT_DOD_PRIMARYATTACK_PRONE_PISTOL,
		["ACT_DOD_PRIMARYATTACK_C96"] = ACT_DOD_PRIMARYATTACK_C96,
		["ACT_DOD_PRIMARYATTACK_PRONE_C96"] = ACT_DOD_PRIMARYATTACK_PRONE_C96,
		["ACT_DOD_PRIMARYATTACK_MG"] = ACT_DOD_PRIMARYATTACK_MG,
		["ACT_DOD_PRIMARYATTACK_PRONE_MG"] = ACT_DOD_PRIMARYATTACK_PRONE_MG,
		["ACT_DOD_PRIMARYATTACK_PRONE_DEPLOYED_MG"] = ACT_DOD_PRIMARYATTACK_PRONE_DEPLOYED_MG,
		["ACT_DOD_PRIMARYATTACK_DEPLOYED_MG"] = ACT_DOD_PRIMARYATTACK_DEPLOYED_MG,
		["ACT_DOD_PRIMARYATTACK_30CAL"] = ACT_DOD_PRIMARYATTACK_30CAL,
		["ACT_DOD_PRIMARYATTACK_PRONE_30CAL"] = ACT_DOD_PRIMARYATTACK_PRONE_30CAL,
		["ACT_DOD_PRIMARYATTACK_DEPLOYED_30CAL"] = ACT_DOD_PRIMARYATTACK_DEPLOYED_30CAL,
		["ACT_DOD_PRIMARYATTACK_PRONE_DEPLOYED_30CAL"] = ACT_DOD_PRIMARYATTACK_PRONE_DEPLOYED_30CAL,
		["ACT_DOD_PRIMARYATTACK_GREN_FRAG"] = ACT_DOD_PRIMARYATTACK_GREN_FRAG,
		["ACT_DOD_PRIMARYATTACK_PRONE_GREN_FRAG"] = ACT_DOD_PRIMARYATTACK_PRONE_GREN_FRAG,
		["ACT_DOD_PRIMARYATTACK_GREN_STICK"] = ACT_DOD_PRIMARYATTACK_GREN_STICK,
		["ACT_DOD_PRIMARYATTACK_PRONE_GREN_STICK"] = ACT_DOD_PRIMARYATTACK_PRONE_GREN_STICK,
		["ACT_DOD_PRIMARYATTACK_KNIFE"] = ACT_DOD_PRIMARYATTACK_KNIFE,
		["ACT_DOD_PRIMARYATTACK_PRONE_KNIFE"] = ACT_DOD_PRIMARYATTACK_PRONE_KNIFE,
		["ACT_DOD_PRIMARYATTACK_SPADE"] = ACT_DOD_PRIMARYATTACK_SPADE,
		["ACT_DOD_PRIMARYATTACK_PRONE_SPADE"] = ACT_DOD_PRIMARYATTACK_PRONE_SPADE,
		["ACT_DOD_PRIMARYATTACK_BAZOOKA"] = ACT_DOD_PRIMARYATTACK_BAZOOKA,
		["ACT_DOD_PRIMARYATTACK_PRONE_BAZOOKA"] = ACT_DOD_PRIMARYATTACK_PRONE_BAZOOKA,
		["ACT_DOD_PRIMARYATTACK_PSCHRECK"] = ACT_DOD_PRIMARYATTACK_PSCHRECK,
		["ACT_DOD_PRIMARYATTACK_PRONE_PSCHRECK"] = ACT_DOD_PRIMARYATTACK_PRONE_PSCHRECK,
		["ACT_DOD_PRIMARYATTACK_BAR"] = ACT_DOD_PRIMARYATTACK_BAR,
		["ACT_DOD_PRIMARYATTACK_PRONE_BAR"] = ACT_DOD_PRIMARYATTACK_PRONE_BAR,
		["ACT_DOD_RELOAD_GARAND"] = ACT_DOD_RELOAD_GARAND,
		["ACT_DOD_RELOAD_K43"] = ACT_DOD_RELOAD_K43,
		["ACT_DOD_RELOAD_BAR"] = ACT_DOD_RELOAD_BAR,
		["ACT_DOD_RELOAD_MP40"] = ACT_DOD_RELOAD_MP40,
		["ACT_DOD_RELOAD_MP44"] = ACT_DOD_RELOAD_MP44,
		["ACT_DOD_RELOAD_BOLT"] = ACT_DOD_RELOAD_BOLT,
		["ACT_DOD_RELOAD_M1CARBINE"] = ACT_DOD_RELOAD_M1CARBINE,
		["ACT_DOD_RELOAD_TOMMY"] = ACT_DOD_RELOAD_TOMMY,
		["ACT_DOD_RELOAD_GREASEGUN"] = ACT_DOD_RELOAD_GREASEGUN,
		["ACT_DOD_RELOAD_PISTOL"] = ACT_DOD_RELOAD_PISTOL,
		["ACT_DOD_RELOAD_FG42"] = ACT_DOD_RELOAD_FG42,
		["ACT_DOD_RELOAD_RIFLE"] = ACT_DOD_RELOAD_RIFLE,
		["ACT_DOD_RELOAD_RIFLEGRENADE"] = ACT_DOD_RELOAD_RIFLEGRENADE,
		["ACT_DOD_RELOAD_C96"] = ACT_DOD_RELOAD_C96,
		["ACT_DOD_RELOAD_CROUCH_BAR"] = ACT_DOD_RELOAD_CROUCH_BAR,
		["ACT_DOD_RELOAD_CROUCH_RIFLE"] = ACT_DOD_RELOAD_CROUCH_RIFLE,
		["ACT_DOD_RELOAD_CROUCH_RIFLEGRENADE"] = ACT_DOD_RELOAD_CROUCH_RIFLEGRENADE,
		["ACT_DOD_RELOAD_CROUCH_BOLT"] = ACT_DOD_RELOAD_CROUCH_BOLT,
		["ACT_DOD_RELOAD_CROUCH_MP44"] = ACT_DOD_RELOAD_CROUCH_MP44,
		["ACT_DOD_RELOAD_CROUCH_MP40"] = ACT_DOD_RELOAD_CROUCH_MP40,
		["ACT_DOD_RELOAD_CROUCH_TOMMY"] = ACT_DOD_RELOAD_CROUCH_TOMMY,
		["ACT_DOD_RELOAD_CROUCH_BAZOOKA"] = ACT_DOD_RELOAD_CROUCH_BAZOOKA,
		["ACT_DOD_RELOAD_CROUCH_PSCHRECK"] = ACT_DOD_RELOAD_CROUCH_PSCHRECK,
		["ACT_DOD_RELOAD_CROUCH_PISTOL"] = ACT_DOD_RELOAD_CROUCH_PISTOL,
		["ACT_DOD_RELOAD_CROUCH_M1CARBINE"] = ACT_DOD_RELOAD_CROUCH_M1CARBINE,
		["ACT_DOD_RELOAD_CROUCH_C96"] = ACT_DOD_RELOAD_CROUCH_C96,
		["ACT_DOD_RELOAD_BAZOOKA"] = ACT_DOD_RELOAD_BAZOOKA,
		["ACT_DOD_ZOOMLOAD_BAZOOKA"] = ACT_DOD_ZOOMLOAD_BAZOOKA,
		["ACT_DOD_RELOAD_PSCHRECK"] = ACT_DOD_RELOAD_PSCHRECK,
		["ACT_DOD_ZOOMLOAD_PSCHRECK"] = ACT_DOD_ZOOMLOAD_PSCHRECK,
		["ACT_DOD_RELOAD_DEPLOYED_FG42"] = ACT_DOD_RELOAD_DEPLOYED_FG42,
		["ACT_DOD_RELOAD_DEPLOYED_30CAL"] = ACT_DOD_RELOAD_DEPLOYED_30CAL,
		["ACT_DOD_RELOAD_DEPLOYED_MG"] = ACT_DOD_RELOAD_DEPLOYED_MG,
		["ACT_DOD_RELOAD_DEPLOYED_MG34"] = ACT_DOD_RELOAD_DEPLOYED_MG34,
		["ACT_DOD_RELOAD_DEPLOYED_BAR"] = ACT_DOD_RELOAD_DEPLOYED_BAR,
		["ACT_DOD_RELOAD_PRONE_PISTOL"] = ACT_DOD_RELOAD_PRONE_PISTOL,
		["ACT_DOD_RELOAD_PRONE_GARAND"] = ACT_DOD_RELOAD_PRONE_GARAND,
		["ACT_DOD_RELOAD_PRONE_M1CARBINE"] = ACT_DOD_RELOAD_PRONE_M1CARBINE,
		["ACT_DOD_RELOAD_PRONE_BOLT"] = ACT_DOD_RELOAD_PRONE_BOLT,
		["ACT_DOD_RELOAD_PRONE_K43"] = ACT_DOD_RELOAD_PRONE_K43,
		["ACT_DOD_RELOAD_PRONE_MP40"] = ACT_DOD_RELOAD_PRONE_MP40,
		["ACT_DOD_RELOAD_PRONE_MP44"] = ACT_DOD_RELOAD_PRONE_MP44,
		["ACT_DOD_RELOAD_PRONE_BAR"] = ACT_DOD_RELOAD_PRONE_BAR,
		["ACT_DOD_RELOAD_PRONE_GREASEGUN"] = ACT_DOD_RELOAD_PRONE_GREASEGUN,
		["ACT_DOD_RELOAD_PRONE_TOMMY"] = ACT_DOD_RELOAD_PRONE_TOMMY,
		["ACT_DOD_RELOAD_PRONE_FG42"] = ACT_DOD_RELOAD_PRONE_FG42,
		["ACT_DOD_RELOAD_PRONE_RIFLE"] = ACT_DOD_RELOAD_PRONE_RIFLE,
		["ACT_DOD_RELOAD_PRONE_RIFLEGRENADE"] = ACT_DOD_RELOAD_PRONE_RIFLEGRENADE,
		["ACT_DOD_RELOAD_PRONE_C96"] = ACT_DOD_RELOAD_PRONE_C96,
		["ACT_DOD_RELOAD_PRONE_BAZOOKA"] = ACT_DOD_RELOAD_PRONE_BAZOOKA,
		["ACT_DOD_ZOOMLOAD_PRONE_BAZOOKA"] = ACT_DOD_ZOOMLOAD_PRONE_BAZOOKA,
		["ACT_DOD_RELOAD_PRONE_PSCHRECK"] = ACT_DOD_RELOAD_PRONE_PSCHRECK,
		["ACT_DOD_ZOOMLOAD_PRONE_PSCHRECK"] = ACT_DOD_ZOOMLOAD_PRONE_PSCHRECK,
		["ACT_DOD_RELOAD_PRONE_DEPLOYED_BAR"] = ACT_DOD_RELOAD_PRONE_DEPLOYED_BAR,
		["ACT_DOD_RELOAD_PRONE_DEPLOYED_FG42"] = ACT_DOD_RELOAD_PRONE_DEPLOYED_FG42,
		["ACT_DOD_RELOAD_PRONE_DEPLOYED_30CAL"] = ACT_DOD_RELOAD_PRONE_DEPLOYED_30CAL,
		["ACT_DOD_RELOAD_PRONE_DEPLOYED_MG"] = ACT_DOD_RELOAD_PRONE_DEPLOYED_MG,
		["ACT_DOD_RELOAD_PRONE_DEPLOYED_MG34"] = ACT_DOD_RELOAD_PRONE_DEPLOYED_MG34,
		["ACT_DOD_PRONE_ZOOM_FORWARD_RIFLE"] = ACT_DOD_PRONE_ZOOM_FORWARD_RIFLE,
		["ACT_DOD_PRONE_ZOOM_FORWARD_BOLT"] = ACT_DOD_PRONE_ZOOM_FORWARD_BOLT,
		["ACT_DOD_PRONE_ZOOM_FORWARD_BAZOOKA"] = ACT_DOD_PRONE_ZOOM_FORWARD_BAZOOKA,
		["ACT_DOD_PRONE_ZOOM_FORWARD_PSCHRECK"] = ACT_DOD_PRONE_ZOOM_FORWARD_PSCHRECK,
		["ACT_DOD_PRIMARYATTACK_CROUCH"] = ACT_DOD_PRIMARYATTACK_CROUCH,
		["ACT_DOD_PRIMARYATTACK_CROUCH_SPADE"] = ACT_DOD_PRIMARYATTACK_CROUCH_SPADE,
		["ACT_DOD_PRIMARYATTACK_CROUCH_KNIFE"] = ACT_DOD_PRIMARYATTACK_CROUCH_KNIFE,
		["ACT_DOD_PRIMARYATTACK_CROUCH_GREN_FRAG"] = ACT_DOD_PRIMARYATTACK_CROUCH_GREN_FRAG,
		["ACT_DOD_PRIMARYATTACK_CROUCH_GREN_STICK"] = ACT_DOD_PRIMARYATTACK_CROUCH_GREN_STICK,
		["ACT_DOD_SECONDARYATTACK_CROUCH"] = ACT_DOD_SECONDARYATTACK_CROUCH,
		["ACT_DOD_SECONDARYATTACK_CROUCH_TOMMY"] = ACT_DOD_SECONDARYATTACK_CROUCH_TOMMY,
		["ACT_DOD_SECONDARYATTACK_CROUCH_MP40"] = ACT_DOD_SECONDARYATTACK_CROUCH_MP40,
		["ACT_DOD_HS_IDLE"] = ACT_DOD_HS_IDLE,
		["ACT_DOD_HS_CROUCH"] = ACT_DOD_HS_CROUCH,
		["ACT_DOD_HS_IDLE_30CAL"] = ACT_DOD_HS_IDLE_30CAL,
		["ACT_DOD_HS_IDLE_BAZOOKA"] = ACT_DOD_HS_IDLE_BAZOOKA,
		["ACT_DOD_HS_IDLE_PSCHRECK"] = ACT_DOD_HS_IDLE_PSCHRECK,
		["ACT_DOD_HS_IDLE_KNIFE"] = ACT_DOD_HS_IDLE_KNIFE,
		["ACT_DOD_HS_IDLE_MG42"] = ACT_DOD_HS_IDLE_MG42,
		["ACT_DOD_HS_IDLE_PISTOL"] = ACT_DOD_HS_IDLE_PISTOL,
		["ACT_DOD_HS_IDLE_STICKGRENADE"] = ACT_DOD_HS_IDLE_STICKGRENADE,
		["ACT_DOD_HS_IDLE_TOMMY"] = ACT_DOD_HS_IDLE_TOMMY,
		["ACT_DOD_HS_IDLE_MP44"] = ACT_DOD_HS_IDLE_MP44,
		["ACT_DOD_HS_IDLE_K98"] = ACT_DOD_HS_IDLE_K98,
		["ACT_DOD_HS_CROUCH_30CAL"] = ACT_DOD_HS_CROUCH_30CAL,
		["ACT_DOD_HS_CROUCH_BAZOOKA"] = ACT_DOD_HS_CROUCH_BAZOOKA,
		["ACT_DOD_HS_CROUCH_PSCHRECK"] = ACT_DOD_HS_CROUCH_PSCHRECK,
		["ACT_DOD_HS_CROUCH_KNIFE"] = ACT_DOD_HS_CROUCH_KNIFE,
		["ACT_DOD_HS_CROUCH_MG42"] = ACT_DOD_HS_CROUCH_MG42,
		["ACT_DOD_HS_CROUCH_PISTOL"] = ACT_DOD_HS_CROUCH_PISTOL,
		["ACT_DOD_HS_CROUCH_STICKGRENADE"] = ACT_DOD_HS_CROUCH_STICKGRENADE,
		["ACT_DOD_HS_CROUCH_TOMMY"] = ACT_DOD_HS_CROUCH_TOMMY,
		["ACT_DOD_HS_CROUCH_MP44"] = ACT_DOD_HS_CROUCH_MP44,
		["ACT_DOD_HS_CROUCH_K98"] = ACT_DOD_HS_CROUCH_K98,
		["ACT_DOD_STAND_IDLE_TNT"] = ACT_DOD_STAND_IDLE_TNT,
		["ACT_DOD_CROUCH_IDLE_TNT"] = ACT_DOD_CROUCH_IDLE_TNT,
		["ACT_DOD_CROUCHWALK_IDLE_TNT"] = ACT_DOD_CROUCHWALK_IDLE_TNT,
		["ACT_DOD_WALK_IDLE_TNT"] = ACT_DOD_WALK_IDLE_TNT,
		["ACT_DOD_RUN_IDLE_TNT"] = ACT_DOD_RUN_IDLE_TNT,
		["ACT_DOD_SPRINT_IDLE_TNT"] = ACT_DOD_SPRINT_IDLE_TNT,
		["ACT_DOD_PRONEWALK_IDLE_TNT"] = ACT_DOD_PRONEWALK_IDLE_TNT,
		["ACT_DOD_PLANT_TNT"] = ACT_DOD_PLANT_TNT,
		["ACT_DOD_DEFUSE_TNT"] = ACT_DOD_DEFUSE_TNT,
		["ACT_VM_FIZZLE"] = ACT_VM_FIZZLE,
		["ACT_MP_STAND_IDLE"] = ACT_MP_STAND_IDLE,
		["ACT_MP_CROUCH_IDLE"] = ACT_MP_CROUCH_IDLE,
		["ACT_MP_CROUCH_DEPLOYED_IDLE"] = ACT_MP_CROUCH_DEPLOYED_IDLE,
		["ACT_MP_CROUCH_DEPLOYED"] = ACT_MP_CROUCH_DEPLOYED,
		["ACT_MP_DEPLOYED_IDLE"] = ACT_MP_DEPLOYED_IDLE,
		["ACT_MP_RUN"] = ACT_MP_RUN,
		["ACT_MP_WALK"] = ACT_MP_WALK,
		["ACT_MP_AIRWALK"] = ACT_MP_AIRWALK,
		["ACT_MP_CROUCHWALK"] = ACT_MP_CROUCHWALK,
		["ACT_MP_SPRINT"] = ACT_MP_SPRINT,
		["ACT_MP_JUMP"] = ACT_MP_JUMP,
		["ACT_MP_JUMP_START"] = ACT_MP_JUMP_START,
		["ACT_MP_JUMP_FLOAT"] = ACT_MP_JUMP_FLOAT,
		["ACT_MP_JUMP_LAND"] = ACT_MP_JUMP_LAND,
		["ACT_MP_DOUBLEJUMP"] = ACT_MP_DOUBLEJUMP,
		["ACT_MP_SWIM"] = ACT_MP_SWIM,
		["ACT_MP_DEPLOYED"] = ACT_MP_DEPLOYED,
		["ACT_MP_SWIM_DEPLOYED"] = ACT_MP_SWIM_DEPLOYED,
		["ACT_MP_VCD"] = ACT_MP_VCD,
		["ACT_MP_SWIM_IDLE"] = ACT_MP_SWIM_IDLE,
		["ACT_MP_ATTACK_STAND_PRIMARYFIRE"] = ACT_MP_ATTACK_STAND_PRIMARYFIRE,
		["ACT_MP_ATTACK_STAND_PRIMARYFIRE_DEPLOYED"] = ACT_MP_ATTACK_STAND_PRIMARYFIRE_DEPLOYED,
		["ACT_MP_ATTACK_STAND_SECONDARYFIRE"] = ACT_MP_ATTACK_STAND_SECONDARYFIRE,
		["ACT_MP_ATTACK_STAND_GRENADE"] = ACT_MP_ATTACK_STAND_GRENADE,
		["ACT_MP_ATTACK_CROUCH_PRIMARYFIRE"] = ACT_MP_ATTACK_CROUCH_PRIMARYFIRE,
		["ACT_MP_ATTACK_CROUCH_PRIMARYFIRE_DEPLOYED"] = ACT_MP_ATTACK_CROUCH_PRIMARYFIRE_DEPLOYED,
		["ACT_MP_ATTACK_CROUCH_SECONDARYFIRE"] = ACT_MP_ATTACK_CROUCH_SECONDARYFIRE,
		["ACT_MP_ATTACK_CROUCH_GRENADE"] = ACT_MP_ATTACK_CROUCH_GRENADE,
		["ACT_MP_ATTACK_SWIM_PRIMARYFIRE"] = ACT_MP_ATTACK_SWIM_PRIMARYFIRE,
		["ACT_MP_ATTACK_SWIM_SECONDARYFIRE"] = ACT_MP_ATTACK_SWIM_SECONDARYFIRE,
		["ACT_MP_ATTACK_SWIM_GRENADE"] = ACT_MP_ATTACK_SWIM_GRENADE,
		["ACT_MP_ATTACK_AIRWALK_PRIMARYFIRE"] = ACT_MP_ATTACK_AIRWALK_PRIMARYFIRE,
		["ACT_MP_ATTACK_AIRWALK_SECONDARYFIRE"] = ACT_MP_ATTACK_AIRWALK_SECONDARYFIRE,
		["ACT_MP_ATTACK_AIRWALK_GRENADE"] = ACT_MP_ATTACK_AIRWALK_GRENADE,
		["ACT_MP_RELOAD_STAND"] = ACT_MP_RELOAD_STAND,
		["ACT_MP_RELOAD_STAND_LOOP"] = ACT_MP_RELOAD_STAND_LOOP,
		["ACT_MP_RELOAD_STAND_END"] = ACT_MP_RELOAD_STAND_END,
		["ACT_MP_RELOAD_CROUCH"] = ACT_MP_RELOAD_CROUCH,
		["ACT_MP_RELOAD_CROUCH_LOOP"] = ACT_MP_RELOAD_CROUCH_LOOP,
		["ACT_MP_RELOAD_CROUCH_END"] = ACT_MP_RELOAD_CROUCH_END,
		["ACT_MP_RELOAD_SWIM"] = ACT_MP_RELOAD_SWIM,
		["ACT_MP_RELOAD_SWIM_LOOP"] = ACT_MP_RELOAD_SWIM_LOOP,
		["ACT_MP_RELOAD_SWIM_END"] = ACT_MP_RELOAD_SWIM_END,
		["ACT_MP_RELOAD_AIRWALK"] = ACT_MP_RELOAD_AIRWALK,
		["ACT_MP_RELOAD_AIRWALK_LOOP"] = ACT_MP_RELOAD_AIRWALK_LOOP,
		["ACT_MP_RELOAD_AIRWALK_END"] = ACT_MP_RELOAD_AIRWALK_END,
		["ACT_MP_ATTACK_STAND_PREFIRE"] = ACT_MP_ATTACK_STAND_PREFIRE,
		["ACT_MP_ATTACK_STAND_POSTFIRE"] = ACT_MP_ATTACK_STAND_POSTFIRE,
		["ACT_MP_ATTACK_STAND_STARTFIRE"] = ACT_MP_ATTACK_STAND_STARTFIRE,
		["ACT_MP_ATTACK_CROUCH_PREFIRE"] = ACT_MP_ATTACK_CROUCH_PREFIRE,
		["ACT_MP_ATTACK_CROUCH_POSTFIRE"] = ACT_MP_ATTACK_CROUCH_POSTFIRE,
		["ACT_MP_ATTACK_SWIM_PREFIRE"] = ACT_MP_ATTACK_SWIM_PREFIRE,
		["ACT_MP_ATTACK_SWIM_POSTFIRE"] = ACT_MP_ATTACK_SWIM_POSTFIRE,
		["ACT_MP_STAND_PRIMARY"] = ACT_MP_STAND_PRIMARY,
		["ACT_MP_CROUCH_PRIMARY"] = ACT_MP_CROUCH_PRIMARY,
		["ACT_MP_RUN_PRIMARY"] = ACT_MP_RUN_PRIMARY,
		["ACT_MP_WALK_PRIMARY"] = ACT_MP_WALK_PRIMARY,
		["ACT_MP_AIRWALK_PRIMARY"] = ACT_MP_AIRWALK_PRIMARY,
		["ACT_MP_CROUCHWALK_PRIMARY"] = ACT_MP_CROUCHWALK_PRIMARY,
		["ACT_MP_JUMP_PRIMARY"] = ACT_MP_JUMP_PRIMARY,
		["ACT_MP_JUMP_START_PRIMARY"] = ACT_MP_JUMP_START_PRIMARY,
		["ACT_MP_JUMP_FLOAT_PRIMARY"] = ACT_MP_JUMP_FLOAT_PRIMARY,
		["ACT_MP_JUMP_LAND_PRIMARY"] = ACT_MP_JUMP_LAND_PRIMARY,
		["ACT_MP_SWIM_PRIMARY"] = ACT_MP_SWIM_PRIMARY,
		["ACT_MP_DEPLOYED_PRIMARY"] = ACT_MP_DEPLOYED_PRIMARY,
		["ACT_MP_SWIM_DEPLOYED_PRIMARY"] = ACT_MP_SWIM_DEPLOYED_PRIMARY,
		["ACT_MP_ATTACK_STAND_PRIMARY"] = ACT_MP_ATTACK_STAND_PRIMARY,
		["ACT_MP_ATTACK_STAND_PRIMARY_DEPLOYED"] = ACT_MP_ATTACK_STAND_PRIMARY_DEPLOYED,
		["ACT_MP_ATTACK_CROUCH_PRIMARY"] = ACT_MP_ATTACK_CROUCH_PRIMARY,
		["ACT_MP_ATTACK_CROUCH_PRIMARY_DEPLOYED"] = ACT_MP_ATTACK_CROUCH_PRIMARY_DEPLOYED,
		["ACT_MP_ATTACK_SWIM_PRIMARY"] = ACT_MP_ATTACK_SWIM_PRIMARY,
		["ACT_MP_ATTACK_AIRWALK_PRIMARY"] = ACT_MP_ATTACK_AIRWALK_PRIMARY,
		["ACT_MP_RELOAD_STAND_PRIMARY"] = ACT_MP_RELOAD_STAND_PRIMARY,
		["ACT_MP_RELOAD_STAND_PRIMARY_LOOP"] = ACT_MP_RELOAD_STAND_PRIMARY_LOOP,
		["ACT_MP_RELOAD_STAND_PRIMARY_END"] = ACT_MP_RELOAD_STAND_PRIMARY_END,
		["ACT_MP_RELOAD_CROUCH_PRIMARY"] = ACT_MP_RELOAD_CROUCH_PRIMARY,
		["ACT_MP_RELOAD_CROUCH_PRIMARY_LOOP"] = ACT_MP_RELOAD_CROUCH_PRIMARY_LOOP,
		["ACT_MP_RELOAD_CROUCH_PRIMARY_END"] = ACT_MP_RELOAD_CROUCH_PRIMARY_END,
		["ACT_MP_RELOAD_SWIM_PRIMARY"] = ACT_MP_RELOAD_SWIM_PRIMARY,
		["ACT_MP_RELOAD_SWIM_PRIMARY_LOOP"] = ACT_MP_RELOAD_SWIM_PRIMARY_LOOP,
		["ACT_MP_RELOAD_SWIM_PRIMARY_END"] = ACT_MP_RELOAD_SWIM_PRIMARY_END,
		["ACT_MP_RELOAD_AIRWALK_PRIMARY"] = ACT_MP_RELOAD_AIRWALK_PRIMARY,
		["ACT_MP_RELOAD_AIRWALK_PRIMARY_LOOP"] = ACT_MP_RELOAD_AIRWALK_PRIMARY_LOOP,
		["ACT_MP_RELOAD_AIRWALK_PRIMARY_END"] = ACT_MP_RELOAD_AIRWALK_PRIMARY_END,
		["ACT_MP_ATTACK_STAND_GRENADE_PRIMARY"] = ACT_MP_ATTACK_STAND_GRENADE_PRIMARY,
		["ACT_MP_ATTACK_CROUCH_GRENADE_PRIMARY"] = ACT_MP_ATTACK_CROUCH_GRENADE_PRIMARY,
		["ACT_MP_ATTACK_SWIM_GRENADE_PRIMARY"] = ACT_MP_ATTACK_SWIM_GRENADE_PRIMARY,
		["ACT_MP_ATTACK_AIRWALK_GRENADE_PRIMARY"] = ACT_MP_ATTACK_AIRWALK_GRENADE_PRIMARY,
		["ACT_MP_STAND_SECONDARY"] = ACT_MP_STAND_SECONDARY,
		["ACT_MP_CROUCH_SECONDARY"] = ACT_MP_CROUCH_SECONDARY,
		["ACT_MP_RUN_SECONDARY"] = ACT_MP_RUN_SECONDARY,
		["ACT_MP_WALK_SECONDARY"] = ACT_MP_WALK_SECONDARY,
		["ACT_MP_AIRWALK_SECONDARY"] = ACT_MP_AIRWALK_SECONDARY,
		["ACT_MP_CROUCHWALK_SECONDARY"] = ACT_MP_CROUCHWALK_SECONDARY,
		["ACT_MP_JUMP_SECONDARY"] = ACT_MP_JUMP_SECONDARY,
		["ACT_MP_JUMP_START_SECONDARY"] = ACT_MP_JUMP_START_SECONDARY,
		["ACT_MP_JUMP_FLOAT_SECONDARY"] = ACT_MP_JUMP_FLOAT_SECONDARY,
		["ACT_MP_JUMP_LAND_SECONDARY"] = ACT_MP_JUMP_LAND_SECONDARY,
		["ACT_MP_SWIM_SECONDARY"] = ACT_MP_SWIM_SECONDARY,
		["ACT_MP_ATTACK_STAND_SECONDARY"] = ACT_MP_ATTACK_STAND_SECONDARY,
		["ACT_MP_ATTACK_CROUCH_SECONDARY"] = ACT_MP_ATTACK_CROUCH_SECONDARY,
		["ACT_MP_ATTACK_SWIM_SECONDARY"] = ACT_MP_ATTACK_SWIM_SECONDARY,
		["ACT_MP_ATTACK_AIRWALK_SECONDARY"] = ACT_MP_ATTACK_AIRWALK_SECONDARY,
		["ACT_MP_RELOAD_STAND_SECONDARY"] = ACT_MP_RELOAD_STAND_SECONDARY,
		["ACT_MP_RELOAD_STAND_SECONDARY_LOOP"] = ACT_MP_RELOAD_STAND_SECONDARY_LOOP,
		["ACT_MP_RELOAD_STAND_SECONDARY_END"] = ACT_MP_RELOAD_STAND_SECONDARY_END,
		["ACT_MP_RELOAD_CROUCH_SECONDARY"] = ACT_MP_RELOAD_CROUCH_SECONDARY,
		["ACT_MP_RELOAD_CROUCH_SECONDARY_LOOP"] = ACT_MP_RELOAD_CROUCH_SECONDARY_LOOP,
		["ACT_MP_RELOAD_CROUCH_SECONDARY_END"] = ACT_MP_RELOAD_CROUCH_SECONDARY_END,
		["ACT_MP_RELOAD_SWIM_SECONDARY"] = ACT_MP_RELOAD_SWIM_SECONDARY,
		["ACT_MP_RELOAD_SWIM_SECONDARY_LOOP"] = ACT_MP_RELOAD_SWIM_SECONDARY_LOOP,
		["ACT_MP_RELOAD_SWIM_SECONDARY_END"] = ACT_MP_RELOAD_SWIM_SECONDARY_END,
		["ACT_MP_RELOAD_AIRWALK_SECONDARY"] = ACT_MP_RELOAD_AIRWALK_SECONDARY,
		["ACT_MP_RELOAD_AIRWALK_SECONDARY_LOOP"] = ACT_MP_RELOAD_AIRWALK_SECONDARY_LOOP,
		["ACT_MP_RELOAD_AIRWALK_SECONDARY_END"] = ACT_MP_RELOAD_AIRWALK_SECONDARY_END,
		["ACT_MP_ATTACK_STAND_GRENADE_SECONDARY"] = ACT_MP_ATTACK_STAND_GRENADE_SECONDARY,
		["ACT_MP_ATTACK_CROUCH_GRENADE_SECONDARY"] = ACT_MP_ATTACK_CROUCH_GRENADE_SECONDARY,
		["ACT_MP_ATTACK_SWIM_GRENADE_SECONDARY"] = ACT_MP_ATTACK_SWIM_GRENADE_SECONDARY,
		["ACT_MP_ATTACK_AIRWALK_GRENADE_SECONDARY"] = ACT_MP_ATTACK_AIRWALK_GRENADE_SECONDARY,
		["ACT_MP_STAND_MELEE"] = ACT_MP_STAND_MELEE,
		["ACT_MP_CROUCH_MELEE"] = ACT_MP_CROUCH_MELEE,
		["ACT_MP_RUN_MELEE"] = ACT_MP_RUN_MELEE,
		["ACT_MP_WALK_MELEE"] = ACT_MP_WALK_MELEE,
		["ACT_MP_AIRWALK_MELEE"] = ACT_MP_AIRWALK_MELEE,
		["ACT_MP_CROUCHWALK_MELEE"] = ACT_MP_CROUCHWALK_MELEE,
		["ACT_MP_JUMP_MELEE"] = ACT_MP_JUMP_MELEE,
		["ACT_MP_JUMP_START_MELEE"] = ACT_MP_JUMP_START_MELEE,
		["ACT_MP_JUMP_FLOAT_MELEE"] = ACT_MP_JUMP_FLOAT_MELEE,
		["ACT_MP_JUMP_LAND_MELEE"] = ACT_MP_JUMP_LAND_MELEE,
		["ACT_MP_SWIM_MELEE"] = ACT_MP_SWIM_MELEE,
		["ACT_MP_ATTACK_STAND_MELEE"] = ACT_MP_ATTACK_STAND_MELEE,
		["ACT_MP_ATTACK_STAND_MELEE_SECONDARY"] = ACT_MP_ATTACK_STAND_MELEE_SECONDARY,
		["ACT_MP_ATTACK_CROUCH_MELEE"] = ACT_MP_ATTACK_CROUCH_MELEE,
		["ACT_MP_ATTACK_CROUCH_MELEE_SECONDARY"] = ACT_MP_ATTACK_CROUCH_MELEE_SECONDARY,
		["ACT_MP_ATTACK_SWIM_MELEE"] = ACT_MP_ATTACK_SWIM_MELEE,
		["ACT_MP_ATTACK_AIRWALK_MELEE"] = ACT_MP_ATTACK_AIRWALK_MELEE,
		["ACT_MP_ATTACK_STAND_GRENADE_MELEE"] = ACT_MP_ATTACK_STAND_GRENADE_MELEE,
		["ACT_MP_ATTACK_CROUCH_GRENADE_MELEE"] = ACT_MP_ATTACK_CROUCH_GRENADE_MELEE,
		["ACT_MP_ATTACK_SWIM_GRENADE_MELEE"] = ACT_MP_ATTACK_SWIM_GRENADE_MELEE,
		["ACT_MP_ATTACK_AIRWALK_GRENADE_MELEE"] = ACT_MP_ATTACK_AIRWALK_GRENADE_MELEE,
		["ACT_MP_GESTURE_FLINCH"] = ACT_MP_GESTURE_FLINCH,
		["ACT_MP_GESTURE_FLINCH_PRIMARY"] = ACT_MP_GESTURE_FLINCH_PRIMARY,
		["ACT_MP_GESTURE_FLINCH_SECONDARY"] = ACT_MP_GESTURE_FLINCH_SECONDARY,
		["ACT_MP_GESTURE_FLINCH_MELEE"] = ACT_MP_GESTURE_FLINCH_MELEE,
		["ACT_MP_GESTURE_FLINCH_HEAD"] = ACT_MP_GESTURE_FLINCH_HEAD,
		["ACT_MP_GESTURE_FLINCH_CHEST"] = ACT_MP_GESTURE_FLINCH_CHEST,
		["ACT_MP_GESTURE_FLINCH_STOMACH"] = ACT_MP_GESTURE_FLINCH_STOMACH,
		["ACT_MP_GESTURE_FLINCH_LEFTARM"] = ACT_MP_GESTURE_FLINCH_LEFTARM,
		["ACT_MP_GESTURE_FLINCH_RIGHTARM"] = ACT_MP_GESTURE_FLINCH_RIGHTARM,
		["ACT_MP_GESTURE_FLINCH_LEFTLEG"] = ACT_MP_GESTURE_FLINCH_LEFTLEG,
		["ACT_MP_GESTURE_FLINCH_RIGHTLEG"] = ACT_MP_GESTURE_FLINCH_RIGHTLEG,
		["ACT_MP_GRENADE1_DRAW"] = ACT_MP_GRENADE1_DRAW,
		["ACT_MP_GRENADE1_IDLE"] = ACT_MP_GRENADE1_IDLE,
		["ACT_MP_GRENADE1_ATTACK"] = ACT_MP_GRENADE1_ATTACK,
		["ACT_MP_GRENADE2_DRAW"] = ACT_MP_GRENADE2_DRAW,
		["ACT_MP_GRENADE2_IDLE"] = ACT_MP_GRENADE2_IDLE,
		["ACT_MP_GRENADE2_ATTACK"] = ACT_MP_GRENADE2_ATTACK,
		["ACT_MP_PRIMARY_GRENADE1_DRAW"] = ACT_MP_PRIMARY_GRENADE1_DRAW,
		["ACT_MP_PRIMARY_GRENADE1_IDLE"] = ACT_MP_PRIMARY_GRENADE1_IDLE,
		["ACT_MP_PRIMARY_GRENADE1_ATTACK"] = ACT_MP_PRIMARY_GRENADE1_ATTACK,
		["ACT_MP_PRIMARY_GRENADE2_DRAW"] = ACT_MP_PRIMARY_GRENADE2_DRAW,
		["ACT_MP_PRIMARY_GRENADE2_IDLE"] = ACT_MP_PRIMARY_GRENADE2_IDLE,
		["ACT_MP_PRIMARY_GRENADE2_ATTACK"] = ACT_MP_PRIMARY_GRENADE2_ATTACK,
		["ACT_MP_SECONDARY_GRENADE1_DRAW"] = ACT_MP_SECONDARY_GRENADE1_DRAW,
		["ACT_MP_SECONDARY_GRENADE1_IDLE"] = ACT_MP_SECONDARY_GRENADE1_IDLE,
		["ACT_MP_SECONDARY_GRENADE1_ATTACK"] = ACT_MP_SECONDARY_GRENADE1_ATTACK,
		["ACT_MP_SECONDARY_GRENADE2_DRAW"] = ACT_MP_SECONDARY_GRENADE2_DRAW,
		["ACT_MP_SECONDARY_GRENADE2_IDLE"] = ACT_MP_SECONDARY_GRENADE2_IDLE,
		["ACT_MP_SECONDARY_GRENADE2_ATTACK"] = ACT_MP_SECONDARY_GRENADE2_ATTACK,
		["ACT_MP_MELEE_GRENADE1_DRAW"] = ACT_MP_MELEE_GRENADE1_DRAW,
		["ACT_MP_MELEE_GRENADE1_IDLE"] = ACT_MP_MELEE_GRENADE1_IDLE,
		["ACT_MP_MELEE_GRENADE1_ATTACK"] = ACT_MP_MELEE_GRENADE1_ATTACK,
		["ACT_MP_MELEE_GRENADE2_DRAW"] = ACT_MP_MELEE_GRENADE2_DRAW,
		["ACT_MP_MELEE_GRENADE2_IDLE"] = ACT_MP_MELEE_GRENADE2_IDLE,
		["ACT_MP_MELEE_GRENADE2_ATTACK"] = ACT_MP_MELEE_GRENADE2_ATTACK,
		["ACT_MP_STAND_BUILDING"] = ACT_MP_STAND_BUILDING,
		["ACT_MP_CROUCH_BUILDING"] = ACT_MP_CROUCH_BUILDING,
		["ACT_MP_RUN_BUILDING"] = ACT_MP_RUN_BUILDING,
		["ACT_MP_WALK_BUILDING"] = ACT_MP_WALK_BUILDING,
		["ACT_MP_AIRWALK_BUILDING"] = ACT_MP_AIRWALK_BUILDING,
		["ACT_MP_CROUCHWALK_BUILDING"] = ACT_MP_CROUCHWALK_BUILDING,
		["ACT_MP_JUMP_BUILDING"] = ACT_MP_JUMP_BUILDING,
		["ACT_MP_JUMP_START_BUILDING"] = ACT_MP_JUMP_START_BUILDING,
		["ACT_MP_JUMP_FLOAT_BUILDING"] = ACT_MP_JUMP_FLOAT_BUILDING,
		["ACT_MP_JUMP_LAND_BUILDING"] = ACT_MP_JUMP_LAND_BUILDING,
		["ACT_MP_SWIM_BUILDING"] = ACT_MP_SWIM_BUILDING,
		["ACT_MP_ATTACK_STAND_BUILDING"] = ACT_MP_ATTACK_STAND_BUILDING,
		["ACT_MP_ATTACK_CROUCH_BUILDING"] = ACT_MP_ATTACK_CROUCH_BUILDING,
		["ACT_MP_ATTACK_SWIM_BUILDING"] = ACT_MP_ATTACK_SWIM_BUILDING,
		["ACT_MP_ATTACK_AIRWALK_BUILDING"] = ACT_MP_ATTACK_AIRWALK_BUILDING,
		["ACT_MP_ATTACK_STAND_GRENADE_BUILDING"] = ACT_MP_ATTACK_STAND_GRENADE_BUILDING,
		["ACT_MP_ATTACK_CROUCH_GRENADE_BUILDING"] = ACT_MP_ATTACK_CROUCH_GRENADE_BUILDING,
		["ACT_MP_ATTACK_SWIM_GRENADE_BUILDING"] = ACT_MP_ATTACK_SWIM_GRENADE_BUILDING,
		["ACT_MP_ATTACK_AIRWALK_GRENADE_BUILDING"] = ACT_MP_ATTACK_AIRWALK_GRENADE_BUILDING,
		["ACT_MP_STAND_PDA"] = ACT_MP_STAND_PDA,
		["ACT_MP_CROUCH_PDA"] = ACT_MP_CROUCH_PDA,
		["ACT_MP_RUN_PDA"] = ACT_MP_RUN_PDA,
		["ACT_MP_WALK_PDA"] = ACT_MP_WALK_PDA,
		["ACT_MP_AIRWALK_PDA"] = ACT_MP_AIRWALK_PDA,
		["ACT_MP_CROUCHWALK_PDA"] = ACT_MP_CROUCHWALK_PDA,
		["ACT_MP_JUMP_PDA"] = ACT_MP_JUMP_PDA,
		["ACT_MP_JUMP_START_PDA"] = ACT_MP_JUMP_START_PDA,
		["ACT_MP_JUMP_FLOAT_PDA"] = ACT_MP_JUMP_FLOAT_PDA,
		["ACT_MP_JUMP_LAND_PDA"] = ACT_MP_JUMP_LAND_PDA,
		["ACT_MP_SWIM_PDA"] = ACT_MP_SWIM_PDA,
		["ACT_MP_ATTACK_STAND_PDA"] = ACT_MP_ATTACK_STAND_PDA,
		["ACT_MP_ATTACK_SWIM_PDA"] = ACT_MP_ATTACK_SWIM_PDA,
		["ACT_MP_GESTURE_VC_HANDMOUTH"] = ACT_MP_GESTURE_VC_HANDMOUTH,
		["ACT_MP_GESTURE_VC_FINGERPOINT"] = ACT_MP_GESTURE_VC_FINGERPOINT,
		["ACT_MP_GESTURE_VC_FISTPUMP"] = ACT_MP_GESTURE_VC_FISTPUMP,
		["ACT_MP_GESTURE_VC_THUMBSUP"] = ACT_MP_GESTURE_VC_THUMBSUP,
		["ACT_MP_GESTURE_VC_NODYES"] = ACT_MP_GESTURE_VC_NODYES,
		["ACT_MP_GESTURE_VC_NODNO"] = ACT_MP_GESTURE_VC_NODNO,
		["ACT_MP_GESTURE_VC_HANDMOUTH_PRIMARY"] = ACT_MP_GESTURE_VC_HANDMOUTH_PRIMARY,
		["ACT_MP_GESTURE_VC_FINGERPOINT_PRIMARY"] = ACT_MP_GESTURE_VC_FINGERPOINT_PRIMARY,
		["ACT_MP_GESTURE_VC_FISTPUMP_PRIMARY"] = ACT_MP_GESTURE_VC_FISTPUMP_PRIMARY,
		["ACT_MP_GESTURE_VC_THUMBSUP_PRIMARY"] = ACT_MP_GESTURE_VC_THUMBSUP_PRIMARY,
		["ACT_MP_GESTURE_VC_NODYES_PRIMARY"] = ACT_MP_GESTURE_VC_NODYES_PRIMARY,
		["ACT_MP_GESTURE_VC_NODNO_PRIMARY"] = ACT_MP_GESTURE_VC_NODNO_PRIMARY,
		["ACT_MP_GESTURE_VC_HANDMOUTH_SECONDARY"] = ACT_MP_GESTURE_VC_HANDMOUTH_SECONDARY,
		["ACT_MP_GESTURE_VC_FINGERPOINT_SECONDARY"] = ACT_MP_GESTURE_VC_FINGERPOINT_SECONDARY,
		["ACT_MP_GESTURE_VC_FISTPUMP_SECONDARY"] = ACT_MP_GESTURE_VC_FISTPUMP_SECONDARY,
		["ACT_MP_GESTURE_VC_THUMBSUP_SECONDARY"] = ACT_MP_GESTURE_VC_THUMBSUP_SECONDARY,
		["ACT_MP_GESTURE_VC_NODYES_SECONDARY"] = ACT_MP_GESTURE_VC_NODYES_SECONDARY,
		["ACT_MP_GESTURE_VC_NODNO_SECONDARY"] = ACT_MP_GESTURE_VC_NODNO_SECONDARY,
		["ACT_MP_GESTURE_VC_HANDMOUTH_MELEE"] = ACT_MP_GESTURE_VC_HANDMOUTH_MELEE,
		["ACT_MP_GESTURE_VC_FINGERPOINT_MELEE"] = ACT_MP_GESTURE_VC_FINGERPOINT_MELEE,
		["ACT_MP_GESTURE_VC_FISTPUMP_MELEE"] = ACT_MP_GESTURE_VC_FISTPUMP_MELEE,
		["ACT_MP_GESTURE_VC_THUMBSUP_MELEE"] = ACT_MP_GESTURE_VC_THUMBSUP_MELEE,
		["ACT_MP_GESTURE_VC_NODYES_MELEE"] = ACT_MP_GESTURE_VC_NODYES_MELEE,
		["ACT_MP_GESTURE_VC_NODNO_MELEE"] = ACT_MP_GESTURE_VC_NODNO_MELEE,
		["ACT_MP_GESTURE_VC_HANDMOUTH_BUILDING"] = ACT_MP_GESTURE_VC_HANDMOUTH_BUILDING,
		["ACT_MP_GESTURE_VC_FINGERPOINT_BUILDING"] = ACT_MP_GESTURE_VC_FINGERPOINT_BUILDING,
		["ACT_MP_GESTURE_VC_FISTPUMP_BUILDING"] = ACT_MP_GESTURE_VC_FISTPUMP_BUILDING,
		["ACT_MP_GESTURE_VC_THUMBSUP_BUILDING"] = ACT_MP_GESTURE_VC_THUMBSUP_BUILDING,
		["ACT_MP_GESTURE_VC_NODYES_BUILDING"] = ACT_MP_GESTURE_VC_NODYES_BUILDING,
		["ACT_MP_GESTURE_VC_NODNO_BUILDING"] = ACT_MP_GESTURE_VC_NODNO_BUILDING,
		["ACT_MP_GESTURE_VC_HANDMOUTH_PDA"] = ACT_MP_GESTURE_VC_HANDMOUTH_PDA,
		["ACT_MP_GESTURE_VC_FINGERPOINT_PDA"] = ACT_MP_GESTURE_VC_FINGERPOINT_PDA,
		["ACT_MP_GESTURE_VC_FISTPUMP_PDA"] = ACT_MP_GESTURE_VC_FISTPUMP_PDA,
		["ACT_MP_GESTURE_VC_THUMBSUP_PDA"] = ACT_MP_GESTURE_VC_THUMBSUP_PDA,
		["ACT_MP_GESTURE_VC_NODYES_PDA"] = ACT_MP_GESTURE_VC_NODYES_PDA,
		["ACT_MP_GESTURE_VC_NODNO_PDA"] = ACT_MP_GESTURE_VC_NODNO_PDA,
		["ACT_VM_UNUSABLE"] = ACT_VM_UNUSABLE,
		["ACT_VM_UNUSABLE_TO_USABLE"] = ACT_VM_UNUSABLE_TO_USABLE,
		["ACT_VM_USABLE_TO_UNUSABLE"] = ACT_VM_USABLE_TO_UNUSABLE,
		["ACT_GMOD_GESTURE_AGREE"] = ACT_GMOD_GESTURE_AGREE,
		["ACT_GMOD_GESTURE_BECON"] = ACT_GMOD_GESTURE_BECON,
		["ACT_GMOD_GESTURE_BOW"] = ACT_GMOD_GESTURE_BOW,
		["ACT_GMOD_GESTURE_DISAGREE"] = ACT_GMOD_GESTURE_DISAGREE,
		["ACT_GMOD_TAUNT_SALUTE"] = ACT_GMOD_TAUNT_SALUTE,
		["ACT_GMOD_GESTURE_WAVE"] = ACT_GMOD_GESTURE_WAVE,
		["ACT_GMOD_TAUNT_PERSISTENCE"] = ACT_GMOD_TAUNT_PERSISTENCE,
		["ACT_GMOD_TAUNT_MUSCLE"] = ACT_GMOD_TAUNT_MUSCLE,
		["ACT_GMOD_TAUNT_LAUGH"] = ACT_GMOD_TAUNT_LAUGH,
		["ACT_GMOD_GESTURE_POINT"] = ACT_GMOD_GESTURE_POINT,
		["ACT_GMOD_TAUNT_CHEER"] = ACT_GMOD_TAUNT_CHEER,
		["ACT_HL2MP_RUN_FAST"] = ACT_HL2MP_RUN_FAST,
		["ACT_HL2MP_RUN_CHARGING"] = ACT_HL2MP_RUN_CHARGING,
		["ACT_HL2MP_RUN_PANICKED"] = ACT_HL2MP_RUN_PANICKED,
		["ACT_HL2MP_RUN_PROTECTED"] = ACT_HL2MP_RUN_PROTECTED,
		["ACT_HL2MP_IDLE_MELEE_ANGRY"] = ACT_HL2MP_IDLE_MELEE_ANGRY,
		["ACT_HL2MP_ZOMBIE_SLUMP_IDLE"] = ACT_HL2MP_ZOMBIE_SLUMP_IDLE,
		["ACT_HL2MP_ZOMBIE_SLUMP_RISE"] = ACT_HL2MP_ZOMBIE_SLUMP_RISE,
		["ACT_HL2MP_WALK_ZOMBIE_01"] = ACT_HL2MP_WALK_ZOMBIE_01,
		["ACT_HL2MP_WALK_ZOMBIE_02"] = ACT_HL2MP_WALK_ZOMBIE_02,
		["ACT_HL2MP_WALK_ZOMBIE_03"] = ACT_HL2MP_WALK_ZOMBIE_03,
		["ACT_HL2MP_WALK_ZOMBIE_04"] = ACT_HL2MP_WALK_ZOMBIE_04,
		["ACT_HL2MP_WALK_ZOMBIE_05"] = ACT_HL2MP_WALK_ZOMBIE_05,
		["ACT_HL2MP_WALK_CROUCH_ZOMBIE_01"] = ACT_HL2MP_WALK_CROUCH_ZOMBIE_01,
		["ACT_HL2MP_WALK_CROUCH_ZOMBIE_02"] = ACT_HL2MP_WALK_CROUCH_ZOMBIE_02,
		["ACT_HL2MP_WALK_CROUCH_ZOMBIE_03"] = ACT_HL2MP_WALK_CROUCH_ZOMBIE_03,
		["ACT_HL2MP_WALK_CROUCH_ZOMBIE_04"] = ACT_HL2MP_WALK_CROUCH_ZOMBIE_04,
		["ACT_HL2MP_WALK_CROUCH_ZOMBIE_05"] = ACT_HL2MP_WALK_CROUCH_ZOMBIE_05,
		["ACT_HL2MP_IDLE_CROUCH_ZOMBIE_01"] = ACT_HL2MP_IDLE_CROUCH_ZOMBIE_01,
		["ACT_HL2MP_IDLE_CROUCH_ZOMBIE_02"] = ACT_HL2MP_IDLE_CROUCH_ZOMBIE_02,
		["ACT_GMOD_GESTURE_RANGE_ZOMBIE"] = ACT_GMOD_GESTURE_RANGE_ZOMBIE,
		["ACT_GMOD_GESTURE_TAUNT_ZOMBIE"] = ACT_GMOD_GESTURE_TAUNT_ZOMBIE,
		["ACT_GMOD_TAUNT_DANCE"] = ACT_GMOD_TAUNT_DANCE,
		["ACT_GMOD_TAUNT_ROBOT"] = ACT_GMOD_TAUNT_ROBOT,
		["ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL"] = ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL,
		["ACT_GMOD_GESTURE_RANGE_FRENZY"] = ACT_GMOD_GESTURE_RANGE_FRENZY,
		["ACT_HL2MP_RUN_ZOMBIE_FAST"] = ACT_HL2MP_RUN_ZOMBIE_FAST,
		["ACT_HL2MP_WALK_ZOMBIE_06"] = ACT_HL2MP_WALK_ZOMBIE_06,
		["ACT_ZOMBIE_LEAP_START"] = ACT_ZOMBIE_LEAP_START,
		["ACT_ZOMBIE_LEAPING"] = ACT_ZOMBIE_LEAPING,
		["ACT_ZOMBIE_CLIMB_UP"] = ACT_ZOMBIE_CLIMB_UP,
		["ACT_ZOMBIE_CLIMB_START"] = ACT_ZOMBIE_CLIMB_START,
		["ACT_ZOMBIE_CLIMB_END"] = ACT_ZOMBIE_CLIMB_END,
		["ACT_HL2MP_IDLE_MAGIC"] = ACT_HL2MP_IDLE_MAGIC,
		["ACT_HL2MP_WALK_MAGIC"] = ACT_HL2MP_WALK_MAGIC,
		["ACT_HL2MP_RUN_MAGIC"] = ACT_HL2MP_RUN_MAGIC,
		["ACT_HL2MP_IDLE_CROUCH_MAGIC"] = ACT_HL2MP_IDLE_CROUCH_MAGIC,
		["ACT_HL2MP_WALK_CROUCH_MAGIC"] = ACT_HL2MP_WALK_CROUCH_MAGIC,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_MAGIC"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_MAGIC,
		["ACT_HL2MP_GESTURE_RELOAD_MAGIC"] = ACT_HL2MP_GESTURE_RELOAD_MAGIC,
		["ACT_HL2MP_JUMP_MAGIC"] = ACT_HL2MP_JUMP_MAGIC,
		["ACT_HL2MP_SWIM_IDLE_MAGIC"] = ACT_HL2MP_SWIM_IDLE_MAGIC,
		["ACT_HL2MP_SWIM_MAGIC"] = ACT_HL2MP_SWIM_MAGIC,
		["ACT_HL2MP_IDLE_REVOLVER"] = ACT_HL2MP_IDLE_REVOLVER,
		["ACT_HL2MP_WALK_REVOLVER"] = ACT_HL2MP_WALK_REVOLVER,
		["ACT_HL2MP_RUN_REVOLVER"] = ACT_HL2MP_RUN_REVOLVER,
		["ACT_HL2MP_IDLE_CROUCH_REVOLVER"] = ACT_HL2MP_IDLE_CROUCH_REVOLVER,
		["ACT_HL2MP_WALK_CROUCH_REVOLVER"] = ACT_HL2MP_WALK_CROUCH_REVOLVER,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER,
		["ACT_HL2MP_GESTURE_RELOAD_REVOLVER"] = ACT_HL2MP_GESTURE_RELOAD_REVOLVER,
		["ACT_HL2MP_JUMP_REVOLVER"] = ACT_HL2MP_JUMP_REVOLVER,
		["ACT_HL2MP_SWIM_IDLE_REVOLVER"] = ACT_HL2MP_SWIM_IDLE_REVOLVER,
		["ACT_HL2MP_SWIM_REVOLVER"] = ACT_HL2MP_SWIM_REVOLVER,
		["ACT_HL2MP_IDLE_CAMERA"] = ACT_HL2MP_IDLE_CAMERA,
		["ACT_HL2MP_WALK_CAMERA"] = ACT_HL2MP_WALK_CAMERA,
		["ACT_HL2MP_RUN_CAMERA"] = ACT_HL2MP_RUN_CAMERA,
		["ACT_HL2MP_IDLE_CROUCH_CAMERA"] = ACT_HL2MP_IDLE_CROUCH_CAMERA,
		["ACT_HL2MP_WALK_CROUCH_CAMERA"] = ACT_HL2MP_WALK_CROUCH_CAMERA,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_CAMERA"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_CAMERA,
		["ACT_HL2MP_GESTURE_RELOAD_CAMERA"] = ACT_HL2MP_GESTURE_RELOAD_CAMERA,
		["ACT_HL2MP_JUMP_CAMERA"] = ACT_HL2MP_JUMP_CAMERA,
		["ACT_HL2MP_SWIM_IDLE_CAMERA"] = ACT_HL2MP_SWIM_IDLE_CAMERA,
		["ACT_HL2MP_SWIM_CAMERA"] = ACT_HL2MP_SWIM_CAMERA,
		["ACT_HL2MP_IDLE_ANGRY"] = ACT_HL2MP_IDLE_ANGRY,
		["ACT_HL2MP_WALK_ANGRY"] = ACT_HL2MP_WALK_ANGRY,
		["ACT_HL2MP_RUN_ANGRY"] = ACT_HL2MP_RUN_ANGRY,
		["ACT_HL2MP_IDLE_CROUCH_ANGRY"] = ACT_HL2MP_IDLE_CROUCH_ANGRY,
		["ACT_HL2MP_WALK_CROUCH_ANGRY"] = ACT_HL2MP_WALK_CROUCH_ANGRY,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_ANGRY"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_ANGRY,
		["ACT_HL2MP_GESTURE_RELOAD_ANGRY"] = ACT_HL2MP_GESTURE_RELOAD_ANGRY,
		["ACT_HL2MP_JUMP_ANGRY"] = ACT_HL2MP_JUMP_ANGRY,
		["ACT_HL2MP_SWIM_IDLE_ANGRY"] = ACT_HL2MP_SWIM_IDLE_ANGRY,
		["ACT_HL2MP_SWIM_ANGRY"] = ACT_HL2MP_SWIM_ANGRY,
		["ACT_HL2MP_IDLE_SCARED"] = ACT_HL2MP_IDLE_SCARED,
		["ACT_HL2MP_WALK_SCARED"] = ACT_HL2MP_WALK_SCARED,
		["ACT_HL2MP_RUN_SCARED"] = ACT_HL2MP_RUN_SCARED,
		["ACT_HL2MP_IDLE_CROUCH_SCARED"] = ACT_HL2MP_IDLE_CROUCH_SCARED,
		["ACT_HL2MP_WALK_CROUCH_SCARED"] = ACT_HL2MP_WALK_CROUCH_SCARED,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_SCARED"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_SCARED,
		["ACT_HL2MP_GESTURE_RELOAD_SCARED"] = ACT_HL2MP_GESTURE_RELOAD_SCARED,
		["ACT_HL2MP_JUMP_SCARED"] = ACT_HL2MP_JUMP_SCARED,
		["ACT_HL2MP_SWIM_IDLE_SCARED"] = ACT_HL2MP_SWIM_IDLE_SCARED,
		["ACT_HL2MP_SWIM_SCARED"] = ACT_HL2MP_SWIM_SCARED,
		["ACT_HL2MP_IDLE_ZOMBIE"] = ACT_HL2MP_IDLE_ZOMBIE,
		["ACT_HL2MP_WALK_ZOMBIE"] = ACT_HL2MP_WALK_ZOMBIE,
		["ACT_HL2MP_RUN_ZOMBIE"] = ACT_HL2MP_RUN_ZOMBIE,
		["ACT_HL2MP_IDLE_CROUCH_ZOMBIE"] = ACT_HL2MP_IDLE_CROUCH_ZOMBIE,
		["ACT_HL2MP_WALK_CROUCH_ZOMBIE"] = ACT_HL2MP_WALK_CROUCH_ZOMBIE,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_ZOMBIE"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_ZOMBIE,
		["ACT_HL2MP_GESTURE_RELOAD_ZOMBIE"] = ACT_HL2MP_GESTURE_RELOAD_ZOMBIE,
		["ACT_HL2MP_JUMP_ZOMBIE"] = ACT_HL2MP_JUMP_ZOMBIE,
		["ACT_HL2MP_SWIM_IDLE_ZOMBIE"] = ACT_HL2MP_SWIM_IDLE_ZOMBIE,
		["ACT_HL2MP_SWIM_ZOMBIE"] = ACT_HL2MP_SWIM_ZOMBIE,
		["ACT_HL2MP_IDLE_SUITCASE"] = ACT_HL2MP_IDLE_SUITCASE,
		["ACT_HL2MP_WALK_SUITCASE"] = ACT_HL2MP_WALK_SUITCASE,
		["ACT_HL2MP_RUN_SUITCASE"] = ACT_HL2MP_RUN_SUITCASE,
		["ACT_HL2MP_IDLE_CROUCH_SUITCASE"] = ACT_HL2MP_IDLE_CROUCH_SUITCASE,
		["ACT_HL2MP_WALK_CROUCH_SUITCASE"] = ACT_HL2MP_WALK_CROUCH_SUITCASE,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_SUITCASE"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_SUITCASE,
		["ACT_HL2MP_GESTURE_RELOAD_SUITCASE"] = ACT_HL2MP_GESTURE_RELOAD_SUITCASE,
		["ACT_HL2MP_JUMP_SUITCASE"] = ACT_HL2MP_JUMP_SUITCASE,
		["ACT_HL2MP_SWIM_IDLE_SUITCASE"] = ACT_HL2MP_SWIM_IDLE_SUITCASE,
		["ACT_HL2MP_SWIM_SUITCASE"] = ACT_HL2MP_SWIM_SUITCASE,
		["ACT_HL2MP_IDLE"] = ACT_HL2MP_IDLE,
		["ACT_HL2MP_WALK"] = ACT_HL2MP_WALK,
		["ACT_HL2MP_RUN"] = ACT_HL2MP_RUN,
		["ACT_HL2MP_IDLE_CROUCH"] = ACT_HL2MP_IDLE_CROUCH,
		["ACT_HL2MP_WALK_CROUCH"] = ACT_HL2MP_WALK_CROUCH,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK"] = ACT_HL2MP_GESTURE_RANGE_ATTACK,
		["ACT_HL2MP_GESTURE_RELOAD"] = ACT_HL2MP_GESTURE_RELOAD,
		["ACT_HL2MP_JUMP"] = ACT_HL2MP_JUMP,
		["ACT_HL2MP_SWIM"] = ACT_HL2MP_SWIM,
		["ACT_HL2MP_IDLE_PISTOL"] = ACT_HL2MP_IDLE_PISTOL,
		["ACT_HL2MP_WALK_PISTOL"] = ACT_HL2MP_WALK_PISTOL,
		["ACT_HL2MP_RUN_PISTOL"] = ACT_HL2MP_RUN_PISTOL,
		["ACT_HL2MP_IDLE_CROUCH_PISTOL"] = ACT_HL2MP_IDLE_CROUCH_PISTOL,
		["ACT_HL2MP_WALK_CROUCH_PISTOL"] = ACT_HL2MP_WALK_CROUCH_PISTOL,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL,
		["ACT_HL2MP_GESTURE_RELOAD_PISTOL"] = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
		["ACT_HL2MP_JUMP_PISTOL"] = ACT_HL2MP_JUMP_PISTOL,
		["ACT_HL2MP_SWIM_IDLE_PISTOL"] = ACT_HL2MP_SWIM_IDLE_PISTOL,
		["ACT_HL2MP_SWIM_PISTOL"] = ACT_HL2MP_SWIM_PISTOL,
		["ACT_HL2MP_IDLE_SMG1"] = ACT_HL2MP_IDLE_SMG1,
		["ACT_HL2MP_WALK_SMG1"] = ACT_HL2MP_WALK_SMG1,
		["ACT_HL2MP_RUN_SMG1"] = ACT_HL2MP_RUN_SMG1,
		["ACT_HL2MP_IDLE_CROUCH_SMG1"] = ACT_HL2MP_IDLE_CROUCH_SMG1,
		["ACT_HL2MP_WALK_CROUCH_SMG1"] = ACT_HL2MP_WALK_CROUCH_SMG1,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1,
		["ACT_HL2MP_GESTURE_RELOAD_SMG1"] = ACT_HL2MP_GESTURE_RELOAD_SMG1,
		["ACT_HL2MP_JUMP_SMG1"] = ACT_HL2MP_JUMP_SMG1,
		["ACT_HL2MP_SWIM_IDLE_SMG1"] = ACT_HL2MP_SWIM_IDLE_SMG1,
		["ACT_HL2MP_SWIM_SMG1"] = ACT_HL2MP_SWIM_SMG1,
		["ACT_HL2MP_IDLE_AR2"] = ACT_HL2MP_IDLE_AR2,
		["ACT_HL2MP_WALK_AR2"] = ACT_HL2MP_WALK_AR2,
		["ACT_HL2MP_RUN_AR2"] = ACT_HL2MP_RUN_AR2,
		["ACT_HL2MP_IDLE_CROUCH_AR2"] = ACT_HL2MP_IDLE_CROUCH_AR2,
		["ACT_HL2MP_WALK_CROUCH_AR2"] = ACT_HL2MP_WALK_CROUCH_AR2,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2,
		["ACT_HL2MP_GESTURE_RELOAD_AR2"] = ACT_HL2MP_GESTURE_RELOAD_AR2,
		["ACT_HL2MP_JUMP_AR2"] = ACT_HL2MP_JUMP_AR2,
		["ACT_HL2MP_SWIM_IDLE_AR2"] = ACT_HL2MP_SWIM_IDLE_AR2,
		["ACT_HL2MP_SWIM_AR2"] = ACT_HL2MP_SWIM_AR2,
		["ACT_HL2MP_IDLE_SHOTGUN"] = ACT_HL2MP_IDLE_SHOTGUN,
		["ACT_HL2MP_WALK_SHOTGUN"] = ACT_HL2MP_WALK_SHOTGUN,
		["ACT_HL2MP_RUN_SHOTGUN"] = ACT_HL2MP_RUN_SHOTGUN,
		["ACT_HL2MP_IDLE_CROUCH_SHOTGUN"] = ACT_HL2MP_IDLE_CROUCH_SHOTGUN,
		["ACT_HL2MP_WALK_CROUCH_SHOTGUN"] = ACT_HL2MP_WALK_CROUCH_SHOTGUN,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN,
		["ACT_HL2MP_GESTURE_RELOAD_SHOTGUN"] = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
		["ACT_HL2MP_JUMP_SHOTGUN"] = ACT_HL2MP_JUMP_SHOTGUN,
		["ACT_HL2MP_SWIM_IDLE_SHOTGUN"] = ACT_HL2MP_SWIM_IDLE_SHOTGUN,
		["ACT_HL2MP_SWIM_SHOTGUN"] = ACT_HL2MP_SWIM_SHOTGUN,
		["ACT_HL2MP_IDLE_RPG"] = ACT_HL2MP_IDLE_RPG,
		["ACT_HL2MP_WALK_RPG"] = ACT_HL2MP_WALK_RPG,
		["ACT_HL2MP_RUN_RPG"] = ACT_HL2MP_RUN_RPG,
		["ACT_HL2MP_IDLE_CROUCH_RPG"] = ACT_HL2MP_IDLE_CROUCH_RPG,
		["ACT_HL2MP_WALK_CROUCH_RPG"] = ACT_HL2MP_WALK_CROUCH_RPG,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG,
		["ACT_HL2MP_GESTURE_RELOAD_RPG"] = ACT_HL2MP_GESTURE_RELOAD_RPG,
		["ACT_HL2MP_JUMP_RPG"] = ACT_HL2MP_JUMP_RPG,
		["ACT_HL2MP_SWIM_IDLE_RPG"] = ACT_HL2MP_SWIM_IDLE_RPG,
		["ACT_HL2MP_SWIM_RPG"] = ACT_HL2MP_SWIM_RPG,
		["ACT_HL2MP_IDLE_GRENADE"] = ACT_HL2MP_IDLE_GRENADE,
		["ACT_HL2MP_WALK_GRENADE"] = ACT_HL2MP_WALK_GRENADE,
		["ACT_HL2MP_RUN_GRENADE"] = ACT_HL2MP_RUN_GRENADE,
		["ACT_HL2MP_IDLE_CROUCH_GRENADE"] = ACT_HL2MP_IDLE_CROUCH_GRENADE,
		["ACT_HL2MP_WALK_CROUCH_GRENADE"] = ACT_HL2MP_WALK_CROUCH_GRENADE,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE,
		["ACT_HL2MP_GESTURE_RELOAD_GRENADE"] = ACT_HL2MP_GESTURE_RELOAD_GRENADE,
		["ACT_HL2MP_JUMP_GRENADE"] = ACT_HL2MP_JUMP_GRENADE,
		["ACT_HL2MP_SWIM_IDLE_GRENADE"] = ACT_HL2MP_SWIM_IDLE_GRENADE,
		["ACT_HL2MP_SWIM_GRENADE"] = ACT_HL2MP_SWIM_GRENADE,
		["ACT_HL2MP_IDLE_DUEL"] = ACT_HL2MP_IDLE_DUEL,
		["ACT_HL2MP_WALK_DUEL"] = ACT_HL2MP_WALK_DUEL,
		["ACT_HL2MP_RUN_DUEL"] = ACT_HL2MP_RUN_DUEL,
		["ACT_HL2MP_IDLE_CROUCH_DUEL"] = ACT_HL2MP_IDLE_CROUCH_DUEL,
		["ACT_HL2MP_WALK_CROUCH_DUEL"] = ACT_HL2MP_WALK_CROUCH_DUEL,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_DUEL"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_DUEL,
		["ACT_HL2MP_GESTURE_RELOAD_DUEL"] = ACT_HL2MP_GESTURE_RELOAD_DUEL,
		["ACT_HL2MP_JUMP_DUEL"] = ACT_HL2MP_JUMP_DUEL,
		["ACT_HL2MP_SWIM_IDLE_DUEL"] = ACT_HL2MP_SWIM_IDLE_DUEL,
		["ACT_HL2MP_SWIM_DUEL"] = ACT_HL2MP_SWIM_DUEL,
		["ACT_HL2MP_IDLE_PHYSGUN"] = ACT_HL2MP_IDLE_PHYSGUN,
		["ACT_HL2MP_WALK_PHYSGUN"] = ACT_HL2MP_WALK_PHYSGUN,
		["ACT_HL2MP_RUN_PHYSGUN"] = ACT_HL2MP_RUN_PHYSGUN,
		["ACT_HL2MP_IDLE_CROUCH_PHYSGUN"] = ACT_HL2MP_IDLE_CROUCH_PHYSGUN,
		["ACT_HL2MP_WALK_CROUCH_PHYSGUN"] = ACT_HL2MP_WALK_CROUCH_PHYSGUN,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_PHYSGUN"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_PHYSGUN,
		["ACT_HL2MP_GESTURE_RELOAD_PHYSGUN"] = ACT_HL2MP_GESTURE_RELOAD_PHYSGUN,
		["ACT_HL2MP_JUMP_PHYSGUN"] = ACT_HL2MP_JUMP_PHYSGUN,
		["ACT_HL2MP_SWIM_IDLE_PHYSGUN"] = ACT_HL2MP_SWIM_IDLE_PHYSGUN,
		["ACT_HL2MP_SWIM_PHYSGUN"] = ACT_HL2MP_SWIM_PHYSGUN,
		["ACT_HL2MP_IDLE_CROSSBOW"] = ACT_HL2MP_IDLE_CROSSBOW,
		["ACT_HL2MP_WALK_CROSSBOW"] = ACT_HL2MP_WALK_CROSSBOW,
		["ACT_HL2MP_RUN_CROSSBOW"] = ACT_HL2MP_RUN_CROSSBOW,
		["ACT_HL2MP_IDLE_CROUCH_CROSSBOW"] = ACT_HL2MP_IDLE_CROUCH_CROSSBOW,
		["ACT_HL2MP_WALK_CROUCH_CROSSBOW"] = ACT_HL2MP_WALK_CROUCH_CROSSBOW,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW,
		["ACT_HL2MP_GESTURE_RELOAD_CROSSBOW"] = ACT_HL2MP_GESTURE_RELOAD_CROSSBOW,
		["ACT_HL2MP_JUMP_CROSSBOW"] = ACT_HL2MP_JUMP_CROSSBOW,
		["ACT_HL2MP_SWIM_IDLE_CROSSBOW"] = ACT_HL2MP_SWIM_IDLE_CROSSBOW,
		["ACT_HL2MP_SWIM_CROSSBOW"] = ACT_HL2MP_SWIM_CROSSBOW,
		["ACT_HL2MP_IDLE_MELEE"] = ACT_HL2MP_IDLE_MELEE,
		["ACT_HL2MP_WALK_MELEE"] = ACT_HL2MP_WALK_MELEE,
		["ACT_HL2MP_RUN_MELEE"] = ACT_HL2MP_RUN_MELEE,
		["ACT_HL2MP_IDLE_CROUCH_MELEE"] = ACT_HL2MP_IDLE_CROUCH_MELEE,
		["ACT_HL2MP_WALK_CROUCH_MELEE"] = ACT_HL2MP_WALK_CROUCH_MELEE,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE,
		["ACT_HL2MP_GESTURE_RELOAD_MELEE"] = ACT_HL2MP_GESTURE_RELOAD_MELEE,
		["ACT_HL2MP_JUMP_MELEE"] = ACT_HL2MP_JUMP_MELEE,
		["ACT_HL2MP_SWIM_IDLE_MELEE"] = ACT_HL2MP_SWIM_IDLE_MELEE,
		["ACT_HL2MP_SWIM_MELEE"] = ACT_HL2MP_SWIM_MELEE,
		["ACT_HL2MP_IDLE_SLAM"] = ACT_HL2MP_IDLE_SLAM,
		["ACT_HL2MP_WALK_SLAM"] = ACT_HL2MP_WALK_SLAM,
		["ACT_HL2MP_RUN_SLAM"] = ACT_HL2MP_RUN_SLAM,
		["ACT_HL2MP_IDLE_CROUCH_SLAM"] = ACT_HL2MP_IDLE_CROUCH_SLAM,
		["ACT_HL2MP_WALK_CROUCH_SLAM"] = ACT_HL2MP_WALK_CROUCH_SLAM,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM,
		["ACT_HL2MP_GESTURE_RELOAD_SLAM"] = ACT_HL2MP_GESTURE_RELOAD_SLAM,
		["ACT_HL2MP_JUMP_SLAM"] = ACT_HL2MP_JUMP_SLAM,
		["ACT_HL2MP_SWIM_IDLE_SLAM"] = ACT_HL2MP_SWIM_IDLE_SLAM,
		["ACT_HL2MP_SWIM_SLAM"] = ACT_HL2MP_SWIM_SLAM,
		["ACT_VM_CRAWL"] = ACT_VM_CRAWL,
		["ACT_VM_CRAWL_EMPTY"] = ACT_VM_CRAWL_EMPTY,
		["ACT_VM_HOLSTER_EMPTY"] = ACT_VM_HOLSTER_EMPTY,
		["ACT_VM_DOWN"] = ACT_VM_DOWN,
		["ACT_VM_DOWN_EMPTY"] = ACT_VM_DOWN_EMPTY,
		["ACT_VM_READY"] = ACT_VM_READY,
		["ACT_VM_ISHOOT"] = ACT_VM_ISHOOT,
		["ACT_VM_IIN"] = ACT_VM_IIN,
		["ACT_VM_IIN_EMPTY"] = ACT_VM_IIN_EMPTY,
		["ACT_VM_IIDLE"] = ACT_VM_IIDLE,
		["ACT_VM_IIDLE_EMPTY"] = ACT_VM_IIDLE_EMPTY,
		["ACT_VM_IOUT"] = ACT_VM_IOUT,
		["ACT_VM_IOUT_EMPTY"] = ACT_VM_IOUT_EMPTY,
		["ACT_VM_PULLBACK_HIGH_BAKE"] = ACT_VM_PULLBACK_HIGH_BAKE,
		["ACT_VM_HITKILL"] = ACT_VM_HITKILL,
		["ACT_VM_DEPLOYED_IN"] = ACT_VM_DEPLOYED_IN,
		["ACT_VM_DEPLOYED_IDLE"] = ACT_VM_DEPLOYED_IDLE,
		["ACT_VM_DEPLOYED_FIRE"] = ACT_VM_DEPLOYED_FIRE,
		["ACT_VM_DEPLOYED_DRYFIRE"] = ACT_VM_DEPLOYED_DRYFIRE,
		["ACT_VM_DEPLOYED_RELOAD"] = ACT_VM_DEPLOYED_RELOAD,
		["ACT_VM_DEPLOYED_RELOAD_EMPTY"] = ACT_VM_DEPLOYED_RELOAD_EMPTY,
		["ACT_VM_DEPLOYED_OUT"] = ACT_VM_DEPLOYED_OUT,
		["ACT_VM_DEPLOYED_IRON_IN"] = ACT_VM_DEPLOYED_IRON_IN,
		["ACT_VM_DEPLOYED_IRON_IDLE"] = ACT_VM_DEPLOYED_IRON_IDLE,
		["ACT_VM_DEPLOYED_IRON_FIRE"] = ACT_VM_DEPLOYED_IRON_FIRE,
		["ACT_VM_DEPLOYED_IRON_DRYFIRE"] = ACT_VM_DEPLOYED_IRON_DRYFIRE,
		["ACT_VM_DEPLOYED_IRON_OUT"] = ACT_VM_DEPLOYED_IRON_OUT,
		["ACT_VM_DEPLOYED_LIFTED_IN"] = ACT_VM_DEPLOYED_LIFTED_IN,
		["ACT_VM_DEPLOYED_LIFTED_IDLE"] = ACT_VM_DEPLOYED_LIFTED_IDLE,
		["ACT_VM_DEPLOYED_LIFTED_OUT"] = ACT_VM_DEPLOYED_LIFTED_OUT,
		["ACT_VM_RELOADEMPTY"] = ACT_VM_RELOADEMPTY,
		["ACT_VM_IRECOIL1"] = ACT_VM_IRECOIL1,
		["ACT_VM_IRECOIL2"] = ACT_VM_IRECOIL2,
		["ACT_VM_FIREMODE"] = ACT_VM_FIREMODE,
		["ACT_VM_ISHOOT_LAST"] = ACT_VM_ISHOOT_LAST,
		["ACT_VM_IFIREMODE"] = ACT_VM_IFIREMODE,
		["ACT_VM_DFIREMODE"] = ACT_VM_DFIREMODE,
		["ACT_VM_DIFIREMODE"] = ACT_VM_DIFIREMODE,
		["ACT_VM_SHOOTLAST"] = ACT_VM_SHOOTLAST,
		["ACT_VM_ISHOOTDRY"] = ACT_VM_ISHOOTDRY,
		["ACT_VM_DRAW_M203"] = ACT_VM_DRAW_M203,
		["ACT_VM_DRAWFULL_M203"] = ACT_VM_DRAWFULL_M203,
		["ACT_VM_READY_M203"] = ACT_VM_READY_M203,
		["ACT_VM_IDLE_M203"] = ACT_VM_IDLE_M203,
		["ACT_VM_RELOAD_M203"] = ACT_VM_RELOAD_M203,
		["ACT_VM_HOLSTER_M203"] = ACT_VM_HOLSTER_M203,
		["ACT_VM_HOLSTERFULL_M203"] = ACT_VM_HOLSTERFULL_M203,
		["ACT_VM_IIN_M203"] = ACT_VM_IIN_M203,
		["ACT_VM_IIDLE_M203"] = ACT_VM_IIDLE_M203,
		["ACT_VM_IOUT_M203"] = ACT_VM_IOUT_M203,
		["ACT_VM_CRAWL_M203"] = ACT_VM_CRAWL_M203,
		["ACT_VM_DOWN_M203"] = ACT_VM_DOWN_M203,
		["ACT_VM_ISHOOT_M203"] = ACT_VM_ISHOOT_M203,
		["ACT_VM_RELOAD_INSERT"] = ACT_VM_RELOAD_INSERT,
		["ACT_VM_RELOAD_INSERT_PULL"] = ACT_VM_RELOAD_INSERT_PULL,
		["ACT_VM_RELOAD_END"] = ACT_VM_RELOAD_END,
		["ACT_VM_RELOAD_END_EMPTY"] = ACT_VM_RELOAD_END_EMPTY,
		["ACT_VM_RELOAD_INSERT_EMPTY"] = ACT_VM_RELOAD_INSERT_EMPTY,
		["ACT_CROSSBOW_HOLSTER_UNLOADED"] = ACT_CROSSBOW_HOLSTER_UNLOADED,
		["ACT_VM_FIRE_TO_EMPTY"] = ACT_VM_FIRE_TO_EMPTY,
		["ACT_VM_UNLOAD"] = ACT_VM_UNLOAD,
		["ACT_VM_RELOAD2"] = ACT_VM_RELOAD2,
		["ACT_GMOD_NOCLIP_LAYER"] = ACT_GMOD_NOCLIP_LAYER,
		["ACT_HL2MP_IDLE_FIST"] = ACT_HL2MP_IDLE_FIST,
		["ACT_HL2MP_WALK_FIST"] = ACT_HL2MP_WALK_FIST,
		["ACT_HL2MP_RUN_FIST"] = ACT_HL2MP_RUN_FIST,
		["ACT_HL2MP_IDLE_CROUCH_FIST"] = ACT_HL2MP_IDLE_CROUCH_FIST,
		["ACT_HL2MP_WALK_CROUCH_FIST"] = ACT_HL2MP_WALK_CROUCH_FIST,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST,
		["ACT_HL2MP_GESTURE_RELOAD_FIST"] = ACT_HL2MP_GESTURE_RELOAD_FIST,
		["ACT_HL2MP_JUMP_FIST"] = ACT_HL2MP_JUMP_FIST,
		["ACT_HL2MP_SWIM_IDLE_FIST"] = ACT_HL2MP_SWIM_IDLE_FIST,
		["ACT_HL2MP_SWIM_FIST"] = ACT_HL2MP_SWIM_FIST,
		["ACT_HL2MP_SIT"] = ACT_HL2MP_SIT,
		["ACT_HL2MP_FIST_BLOCK"] = ACT_HL2MP_FIST_BLOCK,
		["ACT_DRIVE_AIRBOAT"] = ACT_DRIVE_AIRBOAT,
		["ACT_DRIVE_JEEP"] = ACT_DRIVE_JEEP,
		["ACT_GMOD_SIT_ROLLERCOASTER"] = ACT_GMOD_SIT_ROLLERCOASTER,
		["ACT_HL2MP_IDLE_KNIFE"] = ACT_HL2MP_IDLE_KNIFE,
		["ACT_HL2MP_WALK_KNIFE"] = ACT_HL2MP_WALK_KNIFE,
		["ACT_HL2MP_RUN_KNIFE"] = ACT_HL2MP_RUN_KNIFE,
		["ACT_HL2MP_IDLE_CROUCH_KNIFE"] = ACT_HL2MP_IDLE_CROUCH_KNIFE,
		["ACT_HL2MP_WALK_CROUCH_KNIFE"] = ACT_HL2MP_WALK_CROUCH_KNIFE,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE,
		["ACT_HL2MP_GESTURE_RELOAD_KNIFE"] = ACT_HL2MP_GESTURE_RELOAD_KNIFE,
		["ACT_HL2MP_JUMP_KNIFE"] = ACT_HL2MP_JUMP_KNIFE,
		["ACT_HL2MP_SWIM_IDLE_KNIFE"] = ACT_HL2MP_SWIM_IDLE_KNIFE,
		["ACT_HL2MP_SWIM_KNIFE"] = ACT_HL2MP_SWIM_KNIFE,
		["ACT_HL2MP_IDLE_PASSIVE"] = ACT_HL2MP_IDLE_PASSIVE,
		["ACT_HL2MP_WALK_PASSIVE"] = ACT_HL2MP_WALK_PASSIVE,
		["ACT_HL2MP_RUN_PASSIVE"] = ACT_HL2MP_RUN_PASSIVE,
		["ACT_HL2MP_IDLE_CROUCH_PASSIVE"] = ACT_HL2MP_IDLE_CROUCH_PASSIVE,
		["ACT_HL2MP_WALK_CROUCH_PASSIVE"] = ACT_HL2MP_WALK_CROUCH_PASSIVE,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_PASSIVE"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_PASSIVE,
		["ACT_HL2MP_GESTURE_RELOAD_PASSIVE"] = ACT_HL2MP_GESTURE_RELOAD_PASSIVE,
		["ACT_HL2MP_JUMP_PASSIVE"] = ACT_HL2MP_JUMP_PASSIVE,
		["ACT_HL2MP_SWIM_PASSIVE"] = ACT_HL2MP_SWIM_PASSIVE,
		["ACT_HL2MP_SWIM_IDLE_PASSIVE"] = ACT_HL2MP_SWIM_IDLE_PASSIVE,
		["ACT_HL2MP_IDLE_MELEE2"] = ACT_HL2MP_IDLE_MELEE2,
		["ACT_HL2MP_WALK_MELEE2"] = ACT_HL2MP_WALK_MELEE2,
		["ACT_HL2MP_RUN_MELEE2"] = ACT_HL2MP_RUN_MELEE2,
		["ACT_HL2MP_IDLE_CROUCH_MELEE2"] = ACT_HL2MP_IDLE_CROUCH_MELEE2,
		["ACT_HL2MP_WALK_CROUCH_MELEE2"] = ACT_HL2MP_WALK_CROUCH_MELEE2,
		["ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2,
		["ACT_HL2MP_GESTURE_RELOAD_MELEE2"] = ACT_HL2MP_GESTURE_RELOAD_MELEE2,
		["ACT_HL2MP_JUMP_MELEE2"] = ACT_HL2MP_JUMP_MELEE2,
		["ACT_HL2MP_SWIM_IDLE_MELEE2"] = ACT_HL2MP_SWIM_IDLE_MELEE2,
		["ACT_HL2MP_SWIM_MELEE2"] = ACT_HL2MP_SWIM_MELEE2,
		["ACT_HL2MP_SIT_PISTOL"] = ACT_HL2MP_SIT_PISTOL,
		["ACT_HL2MP_SIT_SHOTGUN"] = ACT_HL2MP_SIT_SHOTGUN,
		["ACT_HL2MP_SIT_SMG1"] = ACT_HL2MP_SIT_SMG1,
		["ACT_HL2MP_SIT_AR2"] = ACT_HL2MP_SIT_AR2,
		["ACT_HL2MP_SIT_PHYSGUN"] = ACT_HL2MP_SIT_PHYSGUN,
		["ACT_HL2MP_SIT_GRENADE"] = ACT_HL2MP_SIT_GRENADE,
		["ACT_HL2MP_SIT_RPG"] = ACT_HL2MP_SIT_RPG,
		["ACT_HL2MP_SIT_CROSSBOW"] = ACT_HL2MP_SIT_CROSSBOW,
		["ACT_HL2MP_SIT_MELEE"] = ACT_HL2MP_SIT_MELEE,
		["ACT_HL2MP_SIT_SLAM"] = ACT_HL2MP_SIT_SLAM,
		["ACT_HL2MP_SIT_FIST"] = ACT_HL2MP_SIT_FIST,
		["ACT_GMOD_IN_CHAT"] = ACT_GMOD_IN_CHAT,
		["ACT_GMOD_GESTURE_ITEM_GIVE"] = ACT_GMOD_GESTURE_ITEM_GIVE,
		["ACT_GMOD_GESTURE_ITEM_DROP"] = ACT_GMOD_GESTURE_ITEM_DROP,
		["ACT_GMOD_GESTURE_ITEM_PLACE"] = ACT_GMOD_GESTURE_ITEM_PLACE,
		["ACT_GMOD_GESTURE_ITEM_THROW"] = ACT_GMOD_GESTURE_ITEM_THROW,
		["ACT_GMOD_GESTURE_MELEE_SHOVE_2HAND"] = ACT_GMOD_GESTURE_MELEE_SHOVE_2HAND,
		["ACT_GMOD_GESTURE_MELEE_SHOVE_1HAND"] = ACT_GMOD_GESTURE_MELEE_SHOVE_1HAND,
		["ACT_HL2MP_SWIM_IDLE"] = ACT_HL2MP_SWIM_IDLE,
	},
	["hitgroups"] = {
		["HITGROUP_GENERIC"] = 0,
		["HITGROUP_HEAD"] = 1,
		["HITGROUP_CHEST"] = 2,
		["HITGROUP_STOMACH"] = 3,
		["HITGROUP_LEFTARM"] = 4,
		["HITGROUP_RIGHTARM"] = 5,
		["HITGROUP_LEFTLEG"] = 6,
		["HITGROUP_RIGHTLEG"] = 7,
		["HITGROUP_GEAR"] = 10,
	},
}

// structs should be table copied if you want to edit them uniquely
// except if it contains a reference to another values table, because that would only copy the table from before the basic and active values are added

// structs used in multiple places
t_value_structs = {
	["classname_nonclass"] = {
		NOFUNC = true,
		DESC = "The kind of entity it is. Can also be typed as a string. For example, props are \"prop_physics\" or \"prop_physics_multiplayer\"",
		CATEGORY = t_CAT.REQUIRED,
		NAME = "Entity Class Name", 
		TYPE = { "preset", "string" }, 
		PRESETS_ENTITYLIST = true,
		REQUIRED = true,
		CANCLASS = false,
	},
	["effects"] = {
		CATEGORY = t_CAT.VISUAL,
		DESC = "Creates engine effects, sounds, and particle effects",
		-- FUNCTION = {}, --[[ DoActiveEffects() ]]
		TYPE = "struct_table",
		STRUCT_TBLMAINKEY = "name",
		STRUCT =  {
			["type"] = {
				SORTNAME = "a",
				TYPE = "enum",
				ENUM = {
					["particle"] = "particle",
					["effect"] = "effect",
					["sound"] = "sound",
				},
				REQUIRED = true,
			},
			["pcf"] = {
				NAME = "Particle: Particles File",
				DESC = "Required for particle type effects. The path of the file to get particles from, must be a .pcf file",
				TYPE = "string",
			},
			["name"] = {
				SORTNAME = "b",
				NAME = "Effect/Particle/Sound Name",
				DESC = "Name of either the particle system (within the particle file) or the engine effect or the sound name, depending on the type selected",
				TYPE = { "string", "preset" },
				PRESETS = { "effects" },
				REQUIRED = true,
			},
			["delay"] = {
				DESC = "Delay before the effect and between repetitions. If function, rerolls every time it is called",
				TYPE = "number",
				-- DEFAULT = 0.1,
			},
			["reps"] = {
				DESC = "Only applies to non-continuous uses. The number of times the effect will repeat",
				TYPE = "int",
			},
			["centered"] = {
				TYPE = "boolean",
				DESC = "If true and attachment is not specified, center the effect position",
				DEFAULT = true,
			},
			["sound"] = {
				TYPE = "struct",
				NAME = "Sound Specific Data",
				STRUCT = {
					["pitch"] = {
						DESC = "Unchanged is 100",
						MIN = 0,
						MAX = 255,
					},
					["volume"] = {
						MIN = 0,
						MAX = 1,
					},
					["dist"] = {
						NAME = "Distance Modifier",
						DESC = "Unchanged is 100",
						MIN = 0,
						MAX = 511,
						DEFAULT = 75,
					},
					["restart"] = {
						NAME = "Restart On Repeat",
						TYPE = "boolean",
						DEFAULT = true,
					},
					["channel"] = {
						TYPE = { "emum", "int" },
						ENUM = {
							["CHAN_REPLACE"] = -1,
							["CHAN_AUTO"] = 0,
							["CHAN_WEAPON"] = 1,
							["CHAN_VOICE"] = 2,
							["CHAN_ITEM"] = 3,
							["CHAN_BODY"] = 4,
							["CHAN_STREAM"] = 5,
							["CHAN_STATIC"] = 6,
							["CHAN_VOICE2"] = 7,							
						},
						DEFAULT = "CHAN_STATIC",
					},
				},
			},	
			["effect_data"] = {
				TYPE = "struct",
				NAME = "Engine Effect Specific Data",
				STRUCT = {
					["radius"] = {
						NAME = "Radius",
						TYPE = "number",
					},
					["magnitude"] = {
						NAME = "Magnitude",
						TYPE = "number",
					},
					["scale"] = {
						NAME = "Scale",
						TYPE = "number",
					},
					["normal"] = {
						NAME = "Normal",
						DESC = "Determines the effect direction if applicable.",
						TYPE = "vector",
					},
					["color"] = {
						NAME = "Color Byte",
						TYPE = "int",
					},
					["flags"] = {
						NAME = "Flags",
						DESC = "Each effect has their own flags",
						TYPE = "table",
						TBLSTRUCT = {
							TYPE = "int",
						},
					},
				},
			},
			["ang"] = {
				NAME = "Angle",
				TYPE = "angle",
			},
			["offset_angadd"] = {
				NAME = "Offset 1 Angle Add",
				DESC = "Rotates offset 1 every repetition",
				TYPE = "angle",
			},
			["offset"] = {
				NAME = "Offset 1",
				TYPE = "vector",
			},
			["offset2"] = {
				NAME = "Offset 2",
				TYPE = "vector",
			},
			["attachment"] = {
				NAME = "Attachment Point ID",
				DESC = "If given, the effect will be affixed to the given attachment id on the entity. Attachment ids vary between entities",
				TYPE = "int",
			},
			["pattach"] = {
				NAME = "Particle: Attach Type",
				TYPE = "enum",
				ENUM = {
					["PATTACH_ABSORIGIN"] = PATTACH_ABSORIGIN,
					["PATTACH_ABSORIGIN_FOLLOW"] = PATTACH_ABSORIGIN_FOLLOW,
					["PATTACH_CUSTOMORIGIN"] = PATTACH_CUSTOMORIGIN,
					["PATTACH_POINT"] = PATTACH_POINT,
					["PATTACH_POINT_FOLLOW"] = PATTACH_POINT_FOLLOW,
					["PATTACH_WORLDORIGIN"] = PATTACH_WORLDORIGIN,
				},
				DEFAULT = PATTACH_POINT_FOLLOW,
			},
			-- ["chance"] = nil,
		},
	},
	["expected"] = {
		CATEGORY = t_CAT.REQUIRED,
		NOFUNC = true,
		NAME = "Expected Chance",
		DESC = "[double-click line to switch editor] Chance for this item out of all items within the available set. The chance will be proportional to the sum of all chances within that set",
		REQUIRED = true,
		TYPE = "fraction",
		PENDING_SAVE = true,
		DEFAULT = {
			["n"] = 1,
			["d"] = 1,
			["f"] = 1,
		},
		COMPARECHANCE = true,
		COMPARECHANCE_MAINKEY = { "f" },
	},
	["chance"] = {
		NAME = "Chance",
		DESC = "If given, rolls the chance for this item, singularly",
		TYPE = "fraction",
	},
	["bones"] = {
		CATEGORY = t_CAT.PHYSICAL,
		NAME = "Bones",
		DESC = "Edit individual bones",
		TYPE = "struct_table",
		STRUCT_TBLMAINKEY = "bone",
		STRUCT = {
			["bone"] = { 
				NAME = "Bone ID/Name",
				DESC = "If number, bone id. If string, bone name",
				TYPE = { "int", "string" },
				DEFAULT = 1,
				ENUM = {
					["Pelvis"] = "ValveBiped.Bip01_Pelvis",
					["Spine"] = "ValveBiped.Bip01_Spine",
					["Spine1"] = "ValveBiped.Bip01_Spine1",
					["Spine2"] = "ValveBiped.Bip01_Spine2",
					["Spine4"] = "ValveBiped.Bip01_Spine4",
					["Neck1"] = "ValveBiped.Bip01_Neck1",
					["Head1"] = "ValveBiped.Bip01_Head1",
					["forward"] = "ValveBiped.forward",
					["R_Clavicle"] = "ValveBiped.Bip01_R_Clavicle",
					["R_UpperArm"] = "ValveBiped.Bip01_R_UpperArm",
					["R_Forearm"] = "ValveBiped.Bip01_R_Forearm",
					["R_Hand"] = "ValveBiped.Bip01_R_Hand",
					["Anim_Attachment_RH"] = "ValveBiped.Anim_Attachment_RH",
					["L_Clavicle"] = "ValveBiped.Bip01_L_Clavicle",
					["L_UpperArm"] = "ValveBiped.Bip01_L_UpperArm",
					["L_Forearm"] = "ValveBiped.Bip01_L_Forearm",
					["L_Hand"] = "ValveBiped.Bip01_L_Hand",
					["Anim_Attachment_LH"] = "ValveBiped.Anim_Attachment_LH",
					["R_Thigh"] = "ValveBiped.Bip01_R_Thigh",
					["R_Calf"] = "ValveBiped.Bip01_R_Calf",
					["R_Foot"] = "ValveBiped.Bip01_R_Foot",
					["R_Toe0"] = "ValveBiped.Bip01_R_Toe0",
					["L_Thigh"] = "ValveBiped.Bip01_L_Thigh",
					["L_Calf"] = "ValveBiped.Bip01_L_Calf",
					["L_Foot"] = "ValveBiped.Bip01_L_Foot",
					["L_Toe0"] = "ValveBiped.Bip01_L_Toe0",
					["L_Finger4"] = "ValveBiped.Bip01_L_Finger4",
					["L_Finger41"] = "ValveBiped.Bip01_L_Finger41",
					["L_Finger42"] = "ValveBiped.Bip01_L_Finger42",
					["L_Finger3"] = "ValveBiped.Bip01_L_Finger3",
					["L_Finger31"] = "ValveBiped.Bip01_L_Finger31",
					["L_Finger32"] = "ValveBiped.Bip01_L_Finger32",
					["L_Finger2"] = "ValveBiped.Bip01_L_Finger2",
					["L_Finger21"] = "ValveBiped.Bip01_L_Finger21",
					["L_Finger22"] = "ValveBiped.Bip01_L_Finger22",
					["L_Finger1"] = "ValveBiped.Bip01_L_Finger1",
					["L_Finger11"] = "ValveBiped.Bip01_L_Finger11",
					["L_Finger12"] = "ValveBiped.Bip01_L_Finger12",
					["L_Finger0"] = "ValveBiped.Bip01_L_Finger0",
					["L_Finger01"] = "ValveBiped.Bip01_L_Finger01",
					["L_Finger02"] = "ValveBiped.Bip01_L_Finger02",
					["R_Finger4"] = "ValveBiped.Bip01_R_Finger4",
					["R_Finger41"] = "ValveBiped.Bip01_R_Finger41",
					["R_Finger42"] = "ValveBiped.Bip01_R_Finger42",
					["R_Finger3"] = "ValveBiped.Bip01_R_Finger3",
					["R_Finger31"] = "ValveBiped.Bip01_R_Finger31",
					["R_Finger32"] = "ValveBiped.Bip01_R_Finger32",
					["R_Finger2"] = "ValveBiped.Bip01_R_Finger2",
					["R_Finger21"] = "ValveBiped.Bip01_R_Finger21",
					["R_Finger22"] = "ValveBiped.Bip01_R_Finger22",
					["R_Finger1"] = "ValveBiped.Bip01_R_Finger1",
					["R_Finger11"] = "ValveBiped.Bip01_R_Finger11",
					["R_Finger12"] = "ValveBiped.Bip01_R_Finger12",
					["R_Finger0"] = "ValveBiped.Bip01_R_Finger0",
					["R_Finger01"] = "ValveBiped.Bip01_R_Finger01",
					["R_Finger02"] = "ValveBiped.Bip01_R_Finger02",
					["L_Elbow"] = "ValveBiped.Bip01_L_Elbow",
					["L_Ulna"] = "ValveBiped.Bip01_L_Ulna",
					["R_Ulna"] = "ValveBiped.Bip01_R_Ulna",
					["R_Shoulder"] = "ValveBiped.Bip01_R_Shoulder",
					["L_Shoulder"] = "ValveBiped.Bip01_L_Shoulder",
					["R_Trapezius"] = "ValveBiped.Bip01_R_Trapezius",
					["R_Wrist"] = "ValveBiped.Bip01_R_Wrist",
					["R_Bicep"] = "ValveBiped.Bip01_R_Bicep",
					["L_Bicep"] = "ValveBiped.Bip01_L_Bicep",
					["L_Trapezius"] = "ValveBiped.Bip01_L_Trapezius",
					["L_Wrist"] = "ValveBiped.Bip01_L_Wrist",
					["R_Elbow"] = "ValveBiped.Bip01_R_Elbow",
				}
			},
			["rotate"] = {
				TYPE = "angle",
			},
			["scale"] = {
				DESC = "Note: Vector normalizes if above 32 units",
				TYPE = "vector",
			},
			["offset"] = {
				TYPE = "vector",
			},
			["jiggle"] = {
				TYPE = "boolean",
			},
		},
	},
}

t_any_values = {}
t_item_values = {
	["entity_type"] = {
		TYPE = "data",
		DEFAULT = "item",
		-- DEFAULT_SAVE = true,
	},
}

t_value_structs["effects"].STRUCT["chance"] = table.Copy( t_value_structs["chance"] )

t_value_structs["explode"] = {
	NAME = "Explode",
	TYPE = "struct",
	STRUCT = {
		["enabled"] = {
			TYPE = "boolean", 
			DEFAULT = true,
			SORTNAME = "aabled",
		},
		["effects"] = {
			DESC = "If included, explosion effect will be replaced with effects",
			-- FUNCTION = {}, --[[ hook.Call("OnNPCKilled") ]]
			TYPE = "struct_table",
			STRUCT_TBLMAINKEY = "name",
			STRUCT = t_value_structs["effects"].STRUCT,
		},
		["damage"] = {
			DEFAULT = 50,
		},
		["altmethod"] = {
			TYPE = "boolean",
			DESC = "Alt explosion method that ignores line-of-sight",
		},
		["altmethod_characteronly"] = {
			TYPE = "boolean",
			DESC = "If true, alt explosion method only damages characters instead of all solid entities",
		},
		["altmethod_dmgtype"] = {
			TYPE = { "enum", "int" },
			DESC = "Damage type for alt explosion method",
			ENUM = t_enums["dmg_type"],
		},
		-- ["physex"] = {
		-- 	NAME = "Physics Explosion",
		-- 	DESC = "Replace explosion with physics explosion. Damage will refer to physics force instead",
		-- 	TYPE = "boolean",
		-- },
		-- ["physex_pushplayers"] = {
		-- 	NAME = "Physics Explosion: Push Players",
		-- 	TYPE = "boolean",
		-- },
		-- ["ignore_class"] = {
		-- 	DESC = "TBD",
		-- 	TYPE = "int",
		-- 	ENUM = {
		-- 		["CLASS_NONE"] = CLASS_NONE,
		-- 		["CLASS_PLAYER"] = CLASS_PLAYER,
		-- 		["CLASS_PLAYER_ALLY"] = CLASS_PLAYER_ALLY,
		-- 		["CLASS_PLAYER_ALLY_VITAL"] = CLASS_PLAYER_ALLY_VITAL,
		-- 		["CLASS_ANTLION"] = CLASS_ANTLION,
		-- 		["CLASS_BARNACLE"] = CLASS_BARNACLE,
		-- 		["CLASS_BULLSEYE"] = CLASS_BULLSEYE,
		-- 		["CLASS_CITIZEN_PASSIVE"] = CLASS_CITIZEN_PASSIVE,
		-- 		["CLASS_CITIZEN_REBEL"] = CLASS_CITIZEN_REBEL,
		-- 		["CLASS_COMBINE"] = CLASS_COMBINE,
		-- 		["CLASS_COMBINE_GUNSHIP"] = CLASS_COMBINE_GUNSHIP,
		-- 		["CLASS_CONSCRIPT"] = CLASS_CONSCRIPT,
		-- 		["CLASS_HEADCRAB"] = CLASS_HEADCRAB,
		-- 		["CLASS_MANHACK"] = CLASS_MANHACK,
		-- 		["CLASS_METROPOLICE"] = CLASS_METROPOLICE,
		-- 		["CLASS_MILITARY"] = CLASS_MILITARY,
		-- 		["CLASS_SCANNER"] = CLASS_SCANNER,
		-- 		["CLASS_STALKER"] = CLASS_STALKER,
		-- 		["CLASS_VORTIGAUNT"] = CLASS_VORTIGAUNT,
		-- 		["CLASS_ZOMBIE"] = CLASS_ZOMBIE,
		-- 		["CLASS_PROTOSNIPER"] = CLASS_PROTOSNIPER,
		-- 		["CLASS_MISSILE"] = CLASS_MISSILE,
		-- 		["CLASS_FLARE"] = CLASS_FLARE,
		-- 		["CLASS_EARTH_FAUNA"] = CLASS_EARTH_FAUNA,
		-- 		["CLASS_HACKED_ROLLERMINE"] = CLASS_HACKED_ROLLERMINE,
		-- 		["CLASS_COMBINE_HUNTER"] = CLASS_COMBINE_HUNTER,
		-- 		["CLASS_MACHINE"] = CLASS_MACHINE,
		-- 		["CLASS_HUMAN_PASSIVE"] = CLASS_HUMAN_PASSIVE,
		-- 		["CLASS_HUMAN_MILITARY"] = CLASS_HUMAN_MILITARY,
		-- 		["CLASS_ALIEN_MILITARY"] = CLASS_ALIEN_MILITARY,
		-- 		["CLASS_ALIEN_MONSTER"] = CLASS_ALIEN_MONSTER,
		-- 		["CLASS_ALIEN_PREY"] = CLASS_ALIEN_PREY,
		-- 		["CLASS_ALIEN_PREDATOR"] = CLASS_ALIEN_PREDATOR,
		-- 		["CLASS_INSECT"] = CLASS_INSECT,
		-- 		["CLASS_PLAYER_BIOWEAPON"] = CLASS_PLAYER_BIOWEAPON,
		-- 		["CLASS_ALIEN_BIOWEAPON"] = CLASS_ALIEN_BIOWEAPON,   
		-- 	},
		-- },
		["radius"] = {
			DESC = "Default radius is damage^1.35",
			MIN = 0,
		},
		["generic"] = {
			NAME = "Generic Damage Type",
			TYPE = "boolean",
		},
	},
}

t_value_structs["drop_set"] = {
	NAME = "Drop Set",
	DESC = "Drop these sets",
	TYPE = "struct_table",
	STRUCT_TBLMAINKEY = "drop_set",
	STRUCT = {
		["chance"] = table.Copy( t_value_structs["chance"] ),
		["drop_set"] = {
			TYPE = "preset",
			PRESETS = { "drop_set" },
		},
	},
}
t_value_structs["damage_drop_set"] = {
	NAME = "Drop Set: On Damage",
	DESC = "On damage, drop these sets",
	-- FUNCTION = {}, --[[ hook.Call("OnNPCDeath") ]]
	TYPE = "struct_table",
	STRUCT_TBLMAINKEY = "drop_set",
	STRUCT = {
		["max"] = {
			DESC = "Max times this drop set can drop from this entity",
			TYPE = "number",
		},
		["multidrop_dmg"] = {
			NAME = "Multiple-Drop Damage Ratio",
			DESC = "If given, drop or roll multiple times based on how many times the damage is over this amount",
			TYPE = "number",
			MIN = 1,
		},
		["shot_threshold"] = {
			DESC = "If number, specific damage. If fraction, proportional to max health. If included, shot damage must be greater than this",
			TYPE = { "fraction", "number" },
		},
		["health_greater"] = {
			DESC = "If number, specific number. If fraction, proportional to max health. Health must be greater than this",
			TYPE = { "fraction", "number" },
		},
		["health_lesser"] = {
			DESC = "If number, specific number. If fraction, proportional to max health. Health must be less than or equal to this",
			TYPE = { "fraction", "number" },
		},
		["chance"] = table.Copy( t_value_structs["chance"] ),
		["drop_set"] = {
			TYPE = "preset",
			ENUM = {},
			PRESETS = { "drop_set" },
		},
	},
}
t_value_structs["damage_drop_set_damagefilter"] = table.Copy( t_value_structs["damage_drop_set"] )
t_value_structs["damage_drop_set_damagefilter"].STRUCT["max"] = nil

t_value_structs["damagefilter"] = {  
	CATEGORY = t_CAT.DAMAGE,
	NAME = "Damage Filter",
	DESC = "Filters, if passed, conditionally adjust damage and allow other effects to both attacker and victim. The filters are tested from top to bottom, succeeding after any filter passes",
	-- FUNCTION = {}, --[[ hook.Call("EntityTakeDamage") ]]        
	TYPE = "struct_table",
	STRUCT = {
		["maxpasses"] = {
         NAME = "Disable After Pass",
			DESC = "If given, this filter is disabled after this many passes",
			TYPE = "int",
		},
		-- ["count"] = {
		-- 	TYPE = "data",
		-- 	NOLOOKUP = true,
		-- },
		["condition"] = {
			DESC = "If given, damage info must pass all conditions given for this filter to be applied",
			TYPE = "struct",
         SORTNAME = "AC",
			STRUCT = {
				["chance"] = table.Copy( t_value_structs["chance"] ),
				["invert"] = {
					DESC = "Invert the final condition result",
					TYPE = "boolean",
				},
				["preapply"] = {
					NAME = "Test Filters With Scaled Damage",
					DESC = "Filter condition checks will use the amount of damage it would be if it passed. Basically, applying damage scale, added damage, and min/max before the check (then reverting if it fails)",
					TYPE = "boolean",
				},
				["attacker"] = {
               NAME = "Attacker Conditions",
					-- DESC = "Conditions about the attacker",
					TYPE = "struct",
               SORTNAME = "AA",
					STRUCT = {
						["health_greater"] = {
							DESC = "If number, specific number. If fraction, proportional to max health. Health must be greater than this",
							TYPE = { "fraction", "number" },
						},
						["health_lesser"] = {
							DESC = "If number, specific number. If fraction, proportional to max health. Health must be less than or equal to this",
							TYPE = { "fraction", "number" },
						},
                  ["cumulative_damage"] = {
                     DESC = "Count damage taken within a timeframe",
                     TYPE = "struct",
                     STRUCT = {
                        ["damage"] = {
                           TYPE = "number",
                           DEFAULT = 0,
                        },
                        ["compare_cond"] = {
                           DESC = "Comparison condition for passing",
                           TYPE = "enum",
                           ENUM = {
                              ["Less"] = -2,
                              ["Less or equal"] = -1,
                              ["Equal"] = 0,
                              ["Greater or equal"] = 1,
                              ["Greater"] = 2,
                           },
                           REQUIRED = true,
                        },
                        ["timelimit"] = {
                           DESC = "If given, damage must be within this timeframe in seconds",
                           TYPE = "number",
                        },
                        ["reset_on_pass"] = {
                           DESC = "Reset damage count whenever this subcondition passes. Note: This may or may not trigger if another filter passes before it",
                           TYPE = "boolean",
                           DEFAULT = true,
                        },
                     },
                  },
                  -- ["cumulative_kills"] = {
                  --    DESC = "Count kills by this entity within a timeframe",
                  --    TYPE = "struct",
                  --    STRUCT = {
                  --       ["kills"] = {
                  --          TYPE = "number",
                  --          DEFAULT = 0,
                  --       },
                  --       ["compare_cond"] = {
                  --          DESC = "Comparison condition for passing",
                  --          TYPE = "enum",
                  --          ENUM = {
                  --             ["Less"] = -2,
                  --             ["Less or equal"] = -1,
                  --             ["Equal"] = 0,
                  --             ["Greater or equal"] = 1,
                  --             ["Greater"] = 2,
                  --          },
                  --          REQUIRED = true,
                  --       },
                  --       ["timelimit"] = {
                  --          DESC = "If given, must be within this timeframe in seconds",
                  --          TYPE = "number",
                  --       },
                  --       ["reset_on_pass"] = {
                  --          DESC = "Reset kill count whenever this subcondition passes. Note: This may or may not trigger if another filter passes before it",
                  --          TYPE = "boolean",
                  --          DEFAULT = true,
                  --       },
                  --    },
                  -- },
						["grounded"] = {
							TYPE = "boolean",
							DESC = "Only works correctly for NPCs and players. True to pass when grounded, false to fail when grounded",
						},
						["spin_greater"] = {
							DESC = "Angular velocity. Greater than",
							TYPE = "number",
						},
						["velocity_greater"] = {
							DESC = "Positional velocity. Greater than",
							TYPE = "number",
						},
						["spin_lesser"] = {
							DESC = "Angular velocity. Less than or equal to",
							TYPE = "number",
						},
						["velocity_lesser"] = {
							DESC = "Positional velocity. Less than or equal to",
							TYPE = "number",
						},
						["presets"] = {
							DESC = "Include/exclude attacker based on their npcd preset. Pass if any in \"include\" match, fail if any in \"exclude\" match",
							TYPE = "struct",
							STRUCT = {
								["include"] = {
									TYPE = "table",
									TBLSTRUCT = {
										TYPE = "preset",
										PRESETS = {
											"npc",
											"entity",
											"nextbot",
											"player",
										},
									},
								},
								["exclude"] = {
									TYPE = "table",
									TBLSTRUCT = {
										TYPE = "preset",
										PRESETS = {
											"npc",
											"entity",
											"nextbot",
											"player",
										},
									},
								},
							},
						},
						["types"] = {
							DESC = "Include/exclude attacker types and dispositions. Pass if any in \"include\" match, fail if any in \"exclude\" match. Dispositions are what the attacker thinks of the victim, and are only available for entities that have them (mostly NPCs)",
							TYPE = "struct",
							STRUCT = {
								["exclude"] = {
									TYPE = "table",
									DEFAULT = { "worldspawn", "environment" },
									TBLSTRUCT = {
										TYPE = "enum",
										ENUM = {
											["character"] = "character",
											["nextbot"] = "nextbot",
											["non-character entity"] = "non-character entity",
											["npc"] = "npc",
											["player"] = "player",
											["self"] = "self",
											["worldspawn"] = "worldspawn",
											["environment"] = "environment",
											["brush"] = "brush",
											["enemy (only if entity can check disposition)"] = "enemy",
											["friendly (only if entity can check disposition)"] = "friendly",
											["fear (only if entity can check disposition)"] = "fear",
											["neutral (only if entity can check disposition)"] = "neutral",
										},
									},
								},
								["include"] = {
									TYPE = "table",
									TBLSTRUCT = {
										TYPE = "enum",
										ENUM = {
											["character"] = "character",
											["nextbot"] = "nextbot",
											["non-character entity"] = "non-character entity",
											["npc"] = "npc",
											["player"] = "player",
											["self"] = "self",
											["worldspawn"] = "worldspawn",
											["environment"] = "environment",
											["brush"] = "brush",
											["enemy (only if entity can check disposition)"] = "enemy",
											["friendly (only if entity can check disposition)"] = "friendly",
											["fear (only if entity can check disposition)"] = "fear",
											["neutral (only if entity can check disposition)"] = "neutral",
										},
									},
								},
							},
						},
						["classnames"] = {
							DESC = "Include/exclude attacker entity class names. Pass if any in \"include\" match, fail if any in \"exclude\" match",
							TYPE = "struct",
							STRUCT = {
								["include"] = {
									TYPE = "table",
									TBLSTRUCT = {
										TYPE = { "preset", "string" },
										PRESETS_ENTITYLIST = true,
									},
								},
								["exclude"] = {
									TYPE = "table",
									TBLSTRUCT = {
										TYPE = { "preset", "string" },
										PRESETS_ENTITYLIST = true,
									},
								},
							},
						},
						["weapon_classes"] = {
							DESC = "Include/exclude based on attacker's held weapon. Pass if any in \"include\" match, fail if any in \"exclude\" match",
							TYPE = "struct",
							STRUCT = {
								["include"] = {
									TYPE = "table",
									TBLSTRUCT = {
										TYPE = { "preset", "string" },
										PRESETS_ENTITYLIST = true,
									},
								},
								["exclude"] = {
									TYPE = "table",
									TBLSTRUCT = {
										TYPE = { "preset", "string" },
										PRESETS_ENTITYLIST = true,
									},
								},
							},
						},
						["weapon_sets"] = {
							DESC = "Include/exclude based on attacker's held weapon, testing every weapon in the given weapon set. Pass if any in \"include\" match, fail if any in \"exclude\" match",
							TYPE = "struct",
							STRUCT = {
								["include"] = {
									TYPE = "table",
									TBLSTRUCT = {
										TYPE = { "preset" },
										PRESETS = { "weapon_set" },
									},
								},
								["exclude"] = {
									TYPE = "table",
									TBLSTRUCT = {
										TYPE = { "preset" },
										PRESETS = { "weapon_set" },
									},
								},
							},
						},
						["onfire"] = {
							TYPE = "boolean",
						},
					},
				},
				["victim"] = {
               NAME = "Victim Conditions",
					-- DESC = "Conditions about the victim",
					TYPE = "struct",
               SORTNAME = "AB",
					STRUCT = {
						["health_greater"] = {
							DESC = "If number, specific number. If fraction, proportional to max health. Health must be greater than this",
							TYPE = { "fraction", "number" },
						},
						["health_lesser"] = {
							DESC = "If number, specific number. If fraction, proportional to max health. Health must be less than or equal to this",
							TYPE = { "fraction", "number" },
						},
                  ["cumulative_damage"] = {
                     DESC = "Count damage taken within a timeframe",
                     TYPE = "struct",
                     STRUCT = {
                        ["damage"] = {
                           TYPE = "number",
                           DEFAULT = 0,
                        },
                        ["compare_cond"] = {
                           DESC = "Comparison condition for passing",
                           TYPE = "enum",
                           ENUM = {
                              ["Less"] = -2,
                              ["Less or equal"] = -1,
                              ["Equal"] = 0,
                              ["Greater or equal"] = 1,
                              ["Greater"] = 2,
                           },
                           REQUIRED = true,
                        },
                        ["timelimit"] = {
                           DESC = "If given, damage must be within this timeframe in seconds",
                           TYPE = "number",
                        },
                        ["reset_on_pass"] = {
                           DESC = "Reset damage count whenever this subcondition passes. Note: This may or may not trigger if another filter passes before it",
                           TYPE = "boolean",
                           DEFAULT = true,
                        },
                     },
                  },
                  -- ["cumulative_kills"] = {
                  --    DESC = "Count kills by this entity within a timeframe",
                  --    TYPE = "struct",
                  --    STRUCT = {
                  --       ["kills"] = {
                  --          TYPE = "number",
                  --          DEFAULT = 0,
                  --       },
                  --       ["compare_cond"] = {
                  --          DESC = "Comparison condition for passing",
                  --          TYPE = "enum",
                  --          ENUM = {
                  --             ["Less"] = -2,
                  --             ["Less or equal"] = -1,
                  --             ["Equal"] = 0,
                  --             ["Greater or equal"] = 1,
                  --             ["Greater"] = 2,
                  --          },
                  --          REQUIRED = true,
                  --       },
                  --       ["timelimit"] = {
                  --          DESC = "If given, must be within this timeframe in seconds",
                  --          TYPE = "number",
                  --       },
                  --       ["reset_on_pass"] = {
                  --          DESC = "Reset kill count whenever this subcondition passes. Note: This may or may not trigger if another filter passes before it",
                  --          TYPE = "boolean",
                  --          DEFAULT = true,
                  --       },
                  --    },
                  -- },
						["grounded"] = {
							TYPE = "boolean",
							DESC = "Only works correctly for NPCs and players. True to pass when grounded, false to fail when grounded",
						},
						["spin_greater"] = {
							DESC = "Angular velocity. Greater than",
							TYPE = "number",
						},
						["velocity_greater"] = {
							DESC = "Positional velocity. Greater than",
							TYPE = "number",
						},
						["spin_lesser"] = {
							DESC = "Angular velocity. Less than or equal to",
							TYPE = "number",
						},
						["velocity_lesser"] = {
							DESC = "Positional velocity. Less than or equal to",
							TYPE = "number",
						},
						["presets"] = {
							DESC = "Include/exclude victim npcd presets",
							TYPE = "struct",
							STRUCT = {
								["include"] = {
									TYPE = "table",
									TBLSTRUCT = {
										TYPE = "preset",
										PRESETS = {
											"npc",
											"entity",
											"nextbot",
											"player",
										},
									},
								},
								["exclude"] = {
									TYPE = "table",
									TBLSTRUCT = {
										TYPE = "preset",
										PRESETS = {
											"npc",
											"entity",
											"nextbot",
											"player",
										},
									},
								},
							},
						},
						["types"] = {
							DESC = "Include/exclude victim types and dispositions. Pass if any in \"include\" match, fail if any in \"exclude\" match. Dispositions are what the victim thinks of the attacker, and are only available for entities that have them (mostly NPCs)",
							TYPE = "struct",
							STRUCT = {
								["exclude"] = {
									TYPE = "table",
									DEFAULT = { "self" },
									TBLSTRUCT = {
										TYPE = "enum",
										ENUM = {
											["character"] = "character",
											["nextbot"] = "nextbot",
											["non-character entity"] = "non-character entity",
											["npc"] = "npc",
											["player"] = "player",
											["self"] = "self",
											["worldspawn"] = "worldspawn",
											["environment"] = "environment",
											["brush"] = "brush",
											["enemy (only if entity can check disposition)"] = "enemy",
											["friendly (only if entity can check disposition)"] = "friendly",
											["fear (only if entity can check disposition)"] = "fear",
											["neutral (only if entity can check disposition)"] = "neutral",
										},
									},
								},
								["include"] = {
									TYPE = "table",
									TBLSTRUCT = {
										TYPE = "enum",
										ENUM = {
											["character"] = "character",
											["nextbot"] = "nextbot",
											["non-character entity"] = "non-character entity",
											["npc"] = "npc",
											["player"] = "player",
											["self"] = "self",
											["worldspawn"] = "worldspawn",
											["environment"] = "environment",
											["brush"] = "brush",
											["enemy (only if entity can check disposition)"] = "enemy",
											["friendly (only if entity can check disposition)"] = "friendly",
											["fear (only if entity can check disposition)"] = "fear",
											["neutral (only if entity can check disposition)"] = "neutral",
										},
									},
								},
							},
						},
						["classnames"] = {
							DESC = "Include/exclude victim entity class names. Pass if any in \"include\" match, fail if any in \"exclude\" match",
							TYPE = "struct",
							STRUCT = {
								["include"] = {
									TYPE = "table",
									TBLSTRUCT = {
										TYPE = { "preset", "string" },
										PRESETS_ENTITYLIST = true,
									},
								},
								["exclude"] = {
									TYPE = "table",
									TBLSTRUCT = {
										TYPE = { "preset", "string" },
										PRESETS_ENTITYLIST = true,
									},
								},
							},
						},
						["weapon_classes"] = {
							DESC = "Include/exclude based on victim's held weapon. Pass if any in \"include\" match, fail if any in \"exclude\" match",
							TYPE = "struct",
							STRUCT = {
								["include"] = {
									TYPE = "table",
									TBLSTRUCT = {
										TYPE = { "preset", "string" },
										PRESETS_ENTITYLIST = true,
									},
								},
								["exclude"] = {
									TYPE = "table",
									TBLSTRUCT = {
										TYPE = { "preset", "string" },
										PRESETS_ENTITYLIST = true,
									},
								},
							},
						},
						["onfire"] = {
							DESC = "True to include, false to exclude",
							TYPE = "boolean",
						},
					},
				},
				["damage"] = {
               NAME = "Damage Conditions",
					DESC = "Conditions about the damage properties",
					TYPE = "struct",
               SORTNAME = "AC",
					STRUCT = {
						["explosion"] = {
							DESC = "Tests if explosion damage. True to include, false to exclude",
							TYPE = "boolean",
						},
						["bullet"] = {
							DESC = "Tests if bullet damage. True to include, false to exclude",
							TYPE = "boolean",
						},
						["dmg_types"] = {
							TYPE = "struct",
							DESC = "Include/exclude damage types",
							STRUCT = {
								["include"] = {
									TYPE = "table",
									TBLSTRUCT = {
										TYPE = { "enum", "int" },
										ENUM = t_enums["dmg_type"],
									},
								},
								["exclude"] = {
									TYPE = "table",
									TBLSTRUCT = {
										TYPE = { "enum", "int" },
										ENUM = t_enums["dmg_type"],
									},
								},
							},
						},
						-- ["entityname"] = { TYPE = "string", },
						["greater"] = {
							DESC = "Damage must be greater than this",
						},
						["lesser"] = {
							DESC = "Damage must be less than or equal to this",
						},
						["greater_than_health"] = {
							TYPE = "boolean",
							DESC = "If true, damage must be greater or equal to the victim's health. If false, damage must be less than",
						},
						["taken"] = {
							DESC = "(Only for post-damage filters) Whether or not the entity actually took the damage. Be sure to enable \"Ignore Took\" if this is to be set to false. True to include, false to exclude",
							TYPE = "boolean",
						},
						["ignore_took"] = {
							NAME = "Ignore Took",
							DESC = "(For post-damage filters only) Allow filter even if the entity did not actually take the original damage",
							TYPE = "boolean",
						},
					},
				},
			},
		},
		["attacker"] = {
			NAME = "Actions: Attacker",
			DESC = "Effects to be done towards the attacker",
			TYPE = "struct",
         SORTNAME = "AA",
			STRUCT = {
				["drop_set"] = t_value_structs["drop_set"],
				["damage_drop_set"] = t_value_structs["damage_drop_set_damagefilter"],
				["explode"] = {
					DESC = "Caution: Without filter conditions this explosion may retrigger itself. For conditions, non-weaponry explosions are considered an \"environment\" type",
					TYPE = "struct",
					STRUCT = t_value_structs["explode"].STRUCT,
				},
				["ignite"] = {
					TYPE = { "boolean", "number" },
					DESC = "If number, ignites for that duration. If boolean, ignite indefinitely",
				},
				["freeze"] = {
					NAME = "Freeze (Player)",
					TYPE = { "number", "boolean" },
					DESC = "If number, freeze for duration in seconds. If boolean, freeze indefinitely",
				},
				["takedamage"] = {
					TYPE = "number",
				},
				["reflect"] = {
					TYPE = "number",
					DESC = "Damage is reflected back to the attacker by this factor",
				},
				["effects"] = t_value_structs["effects"],
				["scale_mult"] = {
					TYPE = "number",
					DESC = "Multiply entity scale by this factor. Entity immediately dies if too small",
				},
				["heal"] = {
					DESC = "If number, flat health healed. If fraction, proportional health healed",
					TYPE = { "fraction", "number" },
				},
				["healarmor"] = {
					DESC = "If number, flat armor healed. If fraction, proportional armor healed",
					TYPE = { "fraction", "number" },
				},
				["resetregen"] = {
					DESC = "If entity has regen, resets delay (delays further)",
					TYPE = "boolean",
				},
				["leech"] = {
					DESC = "Heal based on damage done, adjusted by this factor",
					TYPE = "number",
				},
				["leecharmor"] = {
					DESC = "Restore armor based on damage done, adjusted by this factor",
					TYPE = "number",
				},
				["instakill"] = {
					TYPE = "boolean",
				},
				["remove"] = {
					TYPE = "boolean",
				},
				["jigglify"] = {
					TYPE = "boolean",
				},
				["bones"] = table.Copy( t_value_structs["bones"] ),
				-- ["apply_values"] = nil // included later
				["apply_preset"] = {
					DESC = "Applies values from this preset to the entity. Entity-type presets can apply to all entities, otherwise applies only to that specific type of entity",
					TYPE = "preset",
					PRESETS = { "entity", "npc", "nextbot", "player" },
				},
				["drop_weapon"] = {
					TYPE = "boolean",
				},
				["setenemy"] = {
					TYPE = "boolean",
					DESC = "Set attacker's enemy to the victim",
				},
				["settarget"] = {
					TYPE = "boolean",
					DESC = "Set attacker's target to the victim",
				},
				["setchase"] = {
					TYPE = "boolean",
					DESC = "Attacker will chase the victim",
				},
				["change_squad"] = {
					TYPE = "boolean",
					DESC = "Attacker is removed from their squad, and added to victim's squad if available. They will also inherit the victim's squad values",
				},
				["announce_death"] = {
					TYPE = "boolean",
				},
				["ent_funcs"] = {
					NAME = "Entity Functions",
					DESC = "Runs pre-existing functions from the entity. Arguments are sent as-is and are NOT compiled as Lua",
					TYPE = "struct_table",
					STRUCT = {
						["func"] = {
							NAME = "Function",
							SORTNAME = "a",
							TYPE = "string",
						},
						["args"] = {
							NAME = "Arguments",
							SORTNAME = "b",
							TYPE = "table",
							TBLSTRUCT = {
								TYPE = "any",
							},
						},
						["delay"] = {
							NAME = "Delay",
							SORTNAME = "c",
							TYPE = "number",
						},
					},
				},
			},
		},
		["victim"] = {
			NAME = "Actions: Victim",
			DESC = "Effects to be done towards the victim",
			TYPE = "struct",
         SORTNAME = "AB",
			STRUCT = {
				["drop_set"] = t_value_structs["drop_set"],
				["damage_drop_set"] = t_value_structs["damage_drop_set_damagefilter"],
				["effects"] = t_value_structs["effects"],
				["explode"] = {
					DESC = "Caution: Without filter conditions this explosion may retrigger itself. For conditions, explosion entities are considered an \"environment\" type",
					TYPE = "struct",
					STRUCT = t_value_structs["explode"].STRUCT,
				},
				["ignite"] = {
					TYPE = { "boolean", "number" },
					DESC = "If number, ignites for that duration in seconds. If boolean, ignite indefinitely",
				},
				["freeze"] = {
					NAME = "Freeze (Player)",
					TYPE = { "number", "boolean" },
					DESC = "If number, freeze for duration in seconds. If boolean, freeze indefinitely",
				},
				["takedamage"] = {
					TYPE = "number",
				},
				["scale_mult"] = {
					TYPE = "number",
					DESC = "Multiply entity scale by this factor. Entity immediately dies if too small",
				},
				["leech"] = {
					DESC = "Heal based on damage done, adjusted by this factor. Can also be a convenient way to damage entities that can't normally take damage, if set to negative",
					TYPE = "number",
				},
				["resetregen"] = {
					DESC = "If entity has regen, resets delay (delays further)",
					TYPE = "boolean",
				},
				["heal"] = {
					DESC = "If number, flat health healed. If fraction, proportional health healed",
					TYPE = { "fraction", "number" },
				},
				["healarmor"] = {
					DESC = "If number, flat armor healed. If fraction, proportional armor healed",
					TYPE = { "fraction", "number" },
				},
				["instakill"] = {
					TYPE = "boolean",
				},
				["remove"] = {
					TYPE = "boolean",
				},
				["jigglify"] = {
					TYPE = "boolean",
				},
				["bones"] = table.Copy( t_value_structs["bones"] ),
				-- ["apply_values"] = nil // included later
				["apply_preset"] = {
					DESC = "Applies values from this preset to the entity. Entity-type presets can apply to all entities, otherwise it can only apply to that specific type of entity",
					TYPE = "preset",
					PRESETS = { "entity", "npc", "nextbot", "player" },
				},
				["drop_weapon"] = {
					TYPE = "boolean",
				},
				["setenemy"] = {
					TYPE = "boolean",
					DESC = "Set victim's enemy to the attacker",
				},
				["settarget"] = {
					TYPE = "boolean",
					DESC = "Set victim's target to the attacker",
				},
				["setchase"] = {
					TYPE = "boolean",
					DESC = "Victim will chase the attacker",
				},
				["change_squad"] = {
					TYPE = "boolean",
					DESC = "Victim is removed from their squad, and added to attacker's squad if available. They will also inherit the attacker's squad values",
				},
				["announce_death"] = {
					TYPE = "boolean",
				},
				["ent_funcs"] = {
					NAME = "Entity Functions",
					DESC = "Runs pre-existing functions from the entity. Arguments are sent as-is and are NOT compiled as Lua",
					TYPE = "struct_table",
					STRUCT = {
						["func"] = {
							NAME = "Function",
							SORTNAME = "a",
							TYPE = "string",
						},
						["args"] = {
							NAME = "Arguments",
							SORTNAME = "b",
							TYPE = "table",
							TBLSTRUCT = {
								TYPE = "any",
							},
						},
						["delay"] = {
							NAME = "Delay",
							SORTNAME = "c",
							TYPE = "number",
						},
					},
				},
			},
		},
		["continue"] = {
			NAME = "Continue Testing After This Passes",
			DESC = "Continue going down the filter list even if this filter passes",
			TYPE = "boolean",
			DEFAULT = false,
		},

		-- ["damage"] = { TYPE = "struct", } // maybe later
		["max"] = {
			DESC = "Clamps damage",
			TYPE = "number",
		},
		["min"] = {
			DESC = "Clamps damage",
			TYPE = "number",
		},
		["minmax_zero"] = {
			DESC = "If true, damage will not be min/max clamped if equal to zero",
			TYPE = "boolean",
			DEFAULT = true,
		},
		["damagescale"] = {},
		["damageadd"] = {
			DESC = "Add/subtract damage",
		},
		["new_dmg_type"] = {
			DESC = "Changes the damage type",
			TYPE = { "enum", "int" },
			ENUM = t_enums["dmg_type"],
		},
		
		["damageforce"] = {
			DESC = "Physical force of the damage",
			TYPE = "struct",
			STRUCT = {
				["new"] = {
					NAME = "New Damage Force",
					DESC = "Sets vector. Will be rotated to entity's yaw",
					TYPE = "vector",
				},
				["add"] = {
					NAME = "Add",
					DESC = "Adds vector. Will be rotated to entity's yaw",
					TYPE = "vector",
				},
				["mult"] = {
					NAME = "Mult",
					TYPE = "number",
				},
			}
		},
	},
}

t_value_structs["damagefilter_hitbox"] = {
	NAME = "Damage Filter: Hit Boxes",
	CATEGORY = t_CAT.DAMAGE,
	DESC = "For NPCs and players only. The given damage filters will be tested when the specified hitgroup is attacked. Radial and melee attacks are generally always HITGROUP_GENERIC",
	TYPE = "struct_table",
	STRUCT = {
		["hitgroups"] = {
			REQUIRED = true,
			TYPE = "struct",
			STRUCT = {
				["include"] = {
					TYPE = "table",
					TBLSTRUCT = {
						TYPE = { "enum", "int" },
						ENUM = t_enums["hitgroups"],
					},
				},
				["exclude"] = {
					TYPE = "table",
					TBLSTRUCT = {
						TYPE = { "enum", "int" },
						ENUM = t_enums["hitgroups"],
					},
				},
			},			
		},
		["damagefilter"] = table.Copy( t_value_structs["damagefilter"] ),
	},
}

// values that require being managed by npcd
t_active_values = {
	["accelerate"] = {
		CATEGORY = t_CAT.PHYSICAL,
		DESC = "Only for players and entities that actively move via physics object, e.g. manhacks and rollermines. For players, sprinting is replaced with acceleration. For entities, the entity is accelerated when they are moving towards their target.",
		STRUCT = {
			["enabled"] = {
				TYPE = "boolean",
				DEFAULT = true,
				SORTNAME = "aabled",
			},
			["accel_rate"] = {
				NAME = "Accel Rate",
				-- FUNCTION = {}, -- [[ DoActiveEffects() ]]
				DEFAULT = 45,
			},
			["accel_threshold"] = {
				NAME = "Accel Speed Threshold",
				-- FUNCTION = {}, -- [[ DoActiveEffects() ]]
				DEFAULT = 500,
			},
			["player_lerp"] = {
				NAME = "Player: Turn Smoothing",
				DESC = "For players, smoothens the physical turning speed. The higher, the smoother. 0 to disable",
				DEFAULT = 0.97,
				MIN = 0,
				MAX = 1,
			},
			["player_lerp_relative"] = {
				NAME = "Player: Speed Adjusts Smoothing",
				DESC = "If true, \"Player Turn Smoothing\" is adjusted based on speed relative to the speed threshold. Starting from 0 at 0 speed and approaching the original value",
				TYPE = "boolean",
			},
			["movekeys"] = {
				NAME = "Player: Accelerate On Move Keys",
				DESC = "If true, acceleration also begins when move keys are pressed",
				TYPE = "boolean",
			},
			["jump"] = {
				NAME = "Player: Jump Inherits Speed",
				TYPE = "boolean",
				DEFAULT = true,
			},
		},
		-- FUNCTION = {}, -- [[ DoActiveEffects() ]]
		TYPE = "struct",
	},

	-- ["damagefilter_in"] = table.Copy( t_value_structs["damagefilter"] ),   
	["damagefilter_in"] = {
		NAME = "Damage Filter: Incoming",
		CATEGORY = t_CAT.DAMAGE,
		DESC = "Filters, if passed, conditionally adjust damage and allow other effects to both attacker and victim. The filters are tested from top to bottom, succeeding after any filter passes",
		TYPE = "struct_table",
		STRUCT = t_value_structs["damagefilter"].STRUCT,
	},   

	-- ["damagefilter_out"] = table.Copy( t_value_structs["damagefilter"] ),
	["damagefilter_out"] = {
		NAME = "Damage Filter: Outgoing",
		CATEGORY = t_CAT.DAMAGE,
		DESC = "Filters, if passed, conditionally adjust damage and allow other effects to both attacker and victim. The filters are tested from top to bottom, succeeding after any filter passes",
		TYPE = "struct_table",
		STRUCT = t_value_structs["damagefilter"].STRUCT,
	},

	["damagefilter_post_in"] = {
		CATEGORY = t_CAT.DAMAGE,
		NAME = "Post-Damage Filter: Incoming",
		DESC = "Checks AFTER damage is taken. On default conditions, only damage that the entity actually takes can pass. Allow other effects to both attacker and victim if passed. The filters are tested from top to bottom, succeeding after any filter passes",
		TYPE = "struct_table",
		STRUCT = {
			["condition"] = t_value_structs["damagefilter"].STRUCT["condition"],
			["attacker"] = t_value_structs["damagefilter"].STRUCT["attacker"],
			["victim"] = t_value_structs["damagefilter"].STRUCT["victim"],
			["continue"] = t_value_structs["damagefilter"].STRUCT["continue"],
			["maxpasses"] = t_value_structs["damagefilter"].STRUCT["maxpasses"],
		},
	},

	["damagefilter_post_out"] = {
		CATEGORY = t_CAT.DAMAGE,
		NAME = "Post-Damage Filter: Outgoing",
		DESC = "Checks AFTER damage is taken. On default conditions, only damage that the entity actually takes can pass. Allow other effects to both attacker and victim if passed. The filters are tested from top to bottom, succeeding after any filter passes",
		TYPE = "struct_table",
		STRUCT = {
			["condition"] = t_value_structs["damagefilter"].STRUCT["condition"],
			["attacker"] = t_value_structs["damagefilter"].STRUCT["attacker"],
			["victim"] = t_value_structs["damagefilter"].STRUCT["victim"],
			["continue"] = t_value_structs["damagefilter"].STRUCT["continue"],
			["maxpasses"] = t_value_structs["damagefilter"].STRUCT["maxpasses"],
		},
	},

	["damagescale_in"] = {     
		CATEGORY = t_CAT.DAMAGE,   
		-- FUNCTION = {}, --[[ hook.Call("EntityTakeDamage") ]]
		NAME = "Damage Scale: Incoming",        
		DEFAULT = 1,        
	},

	["damagescale_out"] = {  
		CATEGORY = t_CAT.DAMAGE,
		-- FUNCTION = {}, --[[ hook.Call("EntityTakeDamage") ]]
		NAME = "Damage Scale: Outgoing",        
		DEFAULT = 1,        
	},

	["deatheffect"] = {
		CATEGORY = t_CAT.VISUAL,
		-- FUNCTION = {}, --[[ hook.Call("OnNPCKilled") ]]
		TYPE = "struct_table",
		STRUCT_TBLMAINKEY = "name",
		STRUCT = table.Copy( t_value_structs["effects"].STRUCT ),
	},

	["deathexplode"] = { 
		CATEGORY = t_CAT.COMBAT,
		NAME = "Explode On Death",
		DESC = "Entity explodes on death",
		-- FUNCTION = {}, --[[ hook.Call("OnNPCKilled") ]]
		TYPE = "struct", 
		STRUCT = t_value_structs["explode"].STRUCT,
	},

	["drop_set"] = {
		CATEGORY = t_CAT.COMBAT,
		NAME = "Drop Set: On Death",
		DESC = "On death, drop these sets",
		-- FUNCTION = {}, --[[ hook.Call("OnNPCDeath") ]]
		TYPE = "struct_table",
		STRUCT_TBLMAINKEY = "drop_set",
		STRUCT = {
			["chance"] = table.Copy( t_value_structs["chance"] ),
			["drop_set"] = {
				TYPE = "preset",
				PRESETS = { "drop_set" },
			},
		},
	},

	["damage_drop_set"] = table.Copy( t_value_structs["damage_drop_set"] ),

	["force_sequence"] = {
		CATEGORY = t_CAT.BEHAVIOR,
		NAME = "Force Sequence",
		DESC = "Continuously forces the entity to play this animation sequence",
		-- FUNCTION = {}, --[[ DoActiveEffects() ]]
		TYPE = { "number", "string" },
		LOOKUP_REROLL = true,
	},
	
	["sequencedelay"] = {
		NAME = "Force Sequence Delay",
		CATEGORY = t_CAT.BEHAVIOR,
		DESC = "Continuous delay between Force Sequence calls",
		LOOKUP_REROLL = true,
	},


	["quota_fakeweight"] = {
		-- FUNCTION = {}, --[[ Direct() ]]
		CATEGORY = t_CAT.NPCD,
		DESC = "If given, applies to spawn quota, but NOT to radius/pool limit",
	},

	["quota_weight"] = {
		-- FUNCTION = {}, --[[ Direct() ]]
		CATEGORY = t_CAT.NPCD,
		DESC = "Applies to spawn quota and radius/pool limit",
		DEFAULT = 1,
	},
	["regen"] = {
		CATEGORY = t_CAT.HEALTH,
		DESC = "Regenerate health over time",
		-- FUNCTION = {}, --[[ DoActiveEffects() ]]
	},

	["regendelay"] = {
		CATEGORY = t_CAT.HEALTH,
		DESC = "Delay in seconds between regens",
		LOOKUP_REROLL = true,
		-- FUNCTION = {}, --[[ DoActiveEffects() ]]
		DEFAULT = 1,
	},

	["removebody"] = {
		CATEGORY = t_CAT.PHYSICAL,
		FUNCTION = { "SetShouldServerRagdoll", true }, --[[ hook.Add("OnNPCKilled") ]]
		FUNCTION_REQ = true,
		TYPE = "boolean",
		NAME = "Remove Body On Death",
		DESC = "Removes entity on death. If true, \"Keep Corpse\" will also be enabled",
	},

	["removebody_delay"] = {
		CATEGORY = t_CAT.PHYSICAL,
		TYPE = "number",
		NAME = "Remove Body On Death: Delay",
		DESC = "If \"Remove Body On Death\" is true, delays removing entity by this many seconds",
	},

	["spawn_req_navmesh"] = {
		CATEGORY = t_CAT.SPAWN,
		NAME = "Spawn Requires Map Navmesh",
		DESC = "Map must have navmeshes for this to be allowed to spawn",
		TYPE = "boolean",
	},

	["spawn_req_nodes"] = {
		CATEGORY = t_CAT.SPAWN,
		NAME = "Spawn Requires Map Nodes",
		DESC = "Map must have nodes for this to be allowed to spawn",
		TYPE = "boolean",
	},
	["spawn_low"] = {
		CATEGORY = t_CAT.SPAWN,
		NAME = "Spawn to Lowest Point",
		DESC = "If true, the entity will spawn at the lowest possible point onto the ground. Normally, entities spawn a few units above the ground",
		TYPE = "boolean",
	},
	["spawn_ceiling"] = {
		CATEGORY = t_CAT.SPAWN,
		NAME = "Spawn on Ceiling",
		DESC = "If true, the entity will spawn from the ceiling point, instead of the ground. Auto-Spawner will avoid spawning onto the sky. Any spawn offset will be applied from the ceiling point",
		TYPE = "boolean",
	},
	["spawn_sky"] = {
		CATEGORY = t_CAT.SPAWN,
		NAME = "Spawn on Sky",
		DESC = "If true, the entity will spawn from the sky ceiling point. The Auto-Spawner will try to place it under the skybox ceiling, and the auto-spawn will fail if no spot under the sky is found. Any spawn offset will be applied from the ceiling point",
		TYPE = "boolean",
	},

	["spawn_req_water"] = {
      NAME = "Spawn Requires Water",
		CATEGORY = t_CAT.SPAWN,
      DESC = "Water level required for Auto-Spawner. Note: The entity's water requirement is ignored when spawned in a squad, change the squad's water spawn requirement instead",
		TYPE = "enum",
		ENUM = {
			["Any"] = -1,
			["Disallow water"] = 0,
			["Water only"] = 1,
		},
		DEFAULT = "Disallow water",
	},

	["stress_mult"] = {
		CATEGORY = t_CAT.NPCD,
		DESC = "Adjusts npcd stress factor relating to the player actions involving this entity (taking/receiving damage, killing)",
		-- FUNCTION = {}, --[[ StressOut() ]]
		DEFAULT = 1,
	},

	["volatile"] = {
		CATEGORY = t_CAT.COMBAT,
		-- FUNCTION = {}, --[[ hook.Call("EntityTakeDamage") ]]
		DESC = "Entity ignites when taking damage",
		-- TYPE = "boolean",
		TYPE = "struct",
		STRUCT = {
			["enabled"] = {
				TYPE = "boolean",
				-- ENUM = {
				-- 	["Random"] = { "__TBLRANDOM", true, false },
				-- },
				DEFAULT = true,
				-- REQUIRED = true,
				SORTNAME = "aabled",
			},
			["duration"] = {
				-- ENUM = {
				-- 	["Random"] = { math.random, 1, 30, },
				-- },
				-- ["__RANDOMDEFAULT"] = { 1, 30 },
			},
			["threshold_shot"] = {
				DESC = "Ignites if shot damage is greater than this. Less than 0 to disable",
				-- ENUM = {
				-- 	["Random"] = { math.random, 5, 10, },
				-- },
				DEFAULT = { "__RANDOM", 5, 10, },
			},
			["threshold_total"] = {
				DESC = "Ignites if total damage taken is greater than this. Less than 0 to disable",
				-- ENUM = {
				-- 	["Random"] = { math.random, 10, 35, },
				-- },
				DEFAULT = { "__RANDOM", 10, 35, },
			},
		},
	},

	["killonremove"] = {
		CATEGORY = t_CAT.NPCD,
		NAME = "Death On Removed",
		DESC = "NPCD acts like the entity died when it is removed. Forced true for NextBots",
		TYPE = "boolean",
	},

	["scale_proportion"] = {
		CATEGORY = t_CAT.PHYSICAL,
		NAME = "Scale Proportional To Health",
		DESC = "Scale the entity proportional to its health, approaching the given number",
		TYPE = "number",
	},

	["scale_bone_proportion"] = {
		CATEGORY = t_CAT.PHYSICAL,
		NAME = "Scale Bones Proportional To Health",
		DESC = "(Can cause significant lag) Scale the entity's bones proportional to its health, approaching the given number",
		TYPE = "number",
	},


	["startalpha"] = {
		CATEGORY = t_CAT.VISUAL,
		DESC = "Alpha on spawn, fading into the entity's alpha",
		-- FUNCTION = {}, --[[{ "SetKeyValue", "renderamt", "__VALUE" },]]
		DEFAULT = 0,
		MIN = 0,
		MAX = 255,
		-- ENUM = {
		-- 	["Random"] = { math.Rand, 1, 255 },
		-- },
	},

	["relationships_inward"] = {
		CATEGORY = t_CAT.BEHAVIOR,
		NAME = "Relationships: Inward (Other's Feelings)",
		DESC = "(Only for other NPCs) Changes how others feel about this entity",
		TYPE = "struct",
		STRUCT = {
			["by_class"] = {
				-- CATEGORY = t_CAT.BEHAVIOR,
				-- FUNCTION = {}, --[[ SpawnNPC() ]]
				TYPE = "struct_table",
				STRUCT_TBLMAINKEY = "classname",
				STRUCT = {
					["classname"] = {
						DESC = "(player class is \"player\")",
						TYPE = { "preset", "string" },
						REQUIRED = true,
						PRESETS_ENTITYLIST = true,
					},
					["disposition"] = {
						REQUIRED = true,
						TYPE = "enum",
						ENUM = {
							-- ["Error"] = D_ER,
							["Hostile"] = 1,
							["Friendly"] = 3,
							["Fear"] = 2,
							["Neutral"] = 4,
						},
					},
					["priority"] = {
						TYPE = "number",
						MIN = 0,
						MAX = 99,
						DEFAULT = 50,
					},
				},
			},
			["by_preset"] = {
				-- CATEGORY = t_CAT.BEHAVIOR,
				-- FUNCTION = {}, --[[ SpawnNPC() ]]
				TYPE = "struct_table",
				STRUCT_TBLMAINKEY = "preset",
				STRUCT = {
					["preset"] = {
						TYPE = "preset",
						PRESETS = {
							"npc",
							"entity",
							"nextbot",
							"squad",
							"player"
						},
						REQUIRED = true,
					},
					["disposition"] = {
						REQUIRED = true,
						TYPE = "enum",
						ENUM = {
							-- ["Error"] = D_ER,
							["Hostile"] = 1,
							["Friendly"] = 3,
							["Fear"] = 2,
							["Neutral"] = 4,
						},
					},
					["priority"] = {
						TYPE = "number",
						MIN = 0,
						MAX = 99,
						DEFAULT = 50,
					},
				},
			},
			["everyone"] = {
				DESC = "Excluding entities with the same squad preset",
				-- CATEGORY = t_CAT.BEHAVIOR,
				-- FUNCTION = {}, --[[ SpawnNPC() ]]
				TYPE = "struct",
				STRUCT = {
					["disposition"] = {
						REQUIRED = true,
						TYPE = "enum",
						ENUM = {
							-- ["Error"] = D_ER,
							["Hostile"] = 1,
							["Friendly"] = 3,
							["Fear"] = 2,
							["Neutral"] = 4,
						},
					},
					["priority"] = {
						TYPE = "number",
						MIN = 0,
						MAX = 99,
						DEFAULT = 50,
					},
				},
			},
			["self_squad"] = {
				DESC = "Including entities with the same squad preset",
				-- CATEGORY = t_CAT.BEHAVIOR,
				-- FUNCTION = {}, --[[ SpawnNPC() ]]
				TYPE = "struct",
				STRUCT = {
					["disposition"] = {
						REQUIRED = true,
						TYPE = "enum",
						ENUM = {
							-- ["Error"] = D_ER,
							["Hostile"] = 1,
							["Friendly"] = 3,
							["Fear"] = 2,
							["Neutral"] = 4,
						},
					},
					["priority"] = {
						TYPE = "number",
						MIN = 0,
						MAX = 99,
						DEFAULT = 50,
					},
				},
			},
		},
	},

	["velocity_in"] = {
		CATEGORY = t_CAT.DAMAGE,
		NAME = "Velocity Incoming Damage",
		TYPE = "struct",
		DESC = "Incoming damage is adjusted proportional to the entity's velocity",
		STRUCT = {
			["increase"] = {
				DESC = "If true, incoming damage is increased (multiplied). If false, incoming damage is decreased (divided). The amount is determined by the speed over the min speed and ratio velocity",
				TYPE = "boolean",
				DEFAULT = false,
			},
			["minspeed"] = {
				TYPE = "number",
				NAME = "Min Speed",
				DEFAULT = 400,
			},
			["ratio"] = {
				TYPE = "number",
				NAME = "Ratio Velocity",
				DESC = "The factor is determined by speed over this velocity. For example, with 100 min speed and a ratio velocity of 200: going 300 velocity would multiply/divide the damage by 2; going 500 would be by 3, and so on",
				DEFAULT = 400,
			},
			["exponent"] = {
				TYPE = "number",
				NAME = "Exponent",
				DESC = "If given, the speed used to calculate is first raised by this exponent",
			},
		},
	},

	["velocity_out"] = {
		CATEGORY = t_CAT.DAMAGE,
		NAME = "Velocity Outgoing Damage",
		TYPE = "struct",
		DESC = "Outgoing damage is adjusted proportional to the entity's velocity",
		STRUCT = {
			["increase"] = {
				DESC = "If true, outgoing damage is increased (multiplied). If false, outgoing damage is decreased (divided). The amount is determined by the speed over the min speed and ratio velocity",
				TYPE = "boolean",
				DEFAULT = true,
			},
			["minspeed"] = {
				TYPE = "number",
				NAME = "Min Speed",
				DEFAULT = 400,
			},
			["ratio"] = {
				TYPE = "number",
				NAME = "Ratio Velocity",
				DESC = "The factor is determined by speed over this velocity. For example, with 100 min speed and a ratio velocity of 200: going 300 velocity would multiply/divide the damage by 2; going 500 would be by 3, and so on",
				DEFAULT = 400,
			},
			["exponent"] = {
				TYPE = "number",
				NAME = "Exponent",
				DESC = "If given, the speed used to calculate is first raised by this exponent",
			},
		},
	},

	["allow_chased"] = {
		CATEGORY = t_CAT.CHASE,
		NAME = "Allow Being Chased",
		DESC = "If true, NPCD will allow this entity to be a valid target for NPCs seeking out targets",
		TYPE = "boolean",
		DEFAULT = true,
	},

	["beacon"] = {
		CATEGORY = t_CAT.SPAWN,
		NAME = "Spawn Beacon",
		TYPE = "boolean",
		DESC = "Sets if the radius around this entity will be considered when determining spawnpoints. On player presets, if false, will only ignore the player's radius if \"Only Use Spawn Beacons\" is enabled in the spawnpool preset",
	},
}

t_active_values["damage_drop_set"].CATEGORY = t_CAT.COMBAT

t_active_values["postdamage_drop_set"] = {
	CATEGORY = t_CAT.COMBAT,
	NAME = "Drop Set: On Post-Damage",
	DESC = "AFTER damage is taken, drop these sets",
	TYPE = "struct_table",
	STRUCT_TBLMAINKEY = "drop_set",
	STRUCT = table.Copy( t_value_structs["damage_drop_set"].STRUCT ),
}

t_active_values["postdamage_drop_set"].STRUCT["ignore_took"] = {
	TYPE = "boolean",
	DESC = "Run even if the entity did not take the damage",
}


// values that can apply to any entity created
t_basic_values = {

	["angle"] = {
		CATEGORY = t_CAT.PHYSICAL,
		NAME = "Spawn Angle",
		FUNCTION = { "SetAngles", "__VALUE" },
		TYPE = "angle",
		-- DEFAULT = { "__RANDOMANGLE" },
	},

	["offset"] = {
		CATEGORY = t_CAT.PHYSICAL,
		NAME = "Spawn Offset",
		TYPE = "vector",
	},

	["bloodcolor"] = {
		CATEGORY = t_CAT.VISUAL,
		FUNCTION = { "SetBloodColor", "__VALUE" },
		FUNCTION_GET = { "GetBloodColor" },
		TYPE = { "enum", "int" },
		ENUM = {
			["DONT_BLEED"] = -1,
			["BLOOD_COLOR_RED"] = 0,
			["BLOOD_COLOR_YELLOW"] = 1,
			["BLOOD_COLOR_GREEN"] = 2,
			["BLOOD_COLOR_MECH"] = 3,
			["BLOOD_COLOR_ANTLION"] = 4,
			["BLOOD_COLOR_ZOMBIE"] = 5,
			["BLOOD_COLOR_ANTLION_WORKER"] = 6,
			// WARNING: SOME ENUMS ARE SERVERSIDE ONLY
			-- ["DONT_BLEED"] = DONT_BLEED,
			-- ["BLOOD_COLOR_RED"] = BLOOD_COLOR_RED,
			-- ["BLOOD_COLOR_YELLOW"] = BLOOD_COLOR_YELLOW,
			-- ["BLOOD_COLOR_GREEN"] = BLOOD_COLOR_GREEN,
			-- ["BLOOD_COLOR_MECH"] = BLOOD_COLOR_MECH,
			-- ["BLOOD_COLOR_ANTLION"] = BLOOD_COLOR_ANTLION,
			-- ["BLOOD_COLOR_ZOMBIE"] = BLOOD_COLOR_ZOMBIE,
			-- ["BLOOD_COLOR_ANTLION_WORKER"] = BLOOD_COLOR_ANTLION_WORKER,
		},
	},

	["classname"] = { 
		-- FUNCTION = {}, --[[ SpawnNPC() ]]
		NOFUNC = true,
		REFRESHICON = true,
		REFRESHDESC = true,
		DESC = "The entity's class. Can also be typed as a string. For example, props are \"prop_physics\" or \"prop_physics_multiplayer\"",
		CATEGORY = t_CAT.REQUIRED,
		NAME = "Entity Class Name", 
		TYPE = { "preset", "string" }, 
		PRESETS_ENTITYLIST = true,
		REQUIRED = true,
		CANCLASS = true,
	},
   
	

	["effects"] = t_value_structs["effects"],

	["engineeffects"] = {
		CATEGORY = t_CAT.VISUAL,
		FUNCTION = { "AddEffects", "__VALUE" },
		TYPE = { "table", "int" },
		TBLSTRUCT = {
			TYPE = { "enum", "int" },
			FUNCTION = { "AddEffects", "__VALUE" },
			ENUM = {
				["EF_BRIGHTLIGHT"] = EF_BRIGHTLIGHT,
				["EF_ITEM_BLINK"] = EF_ITEM_BLINK,
				["EF_NODRAW"] = EF_NODRAW,
				["EF_NOINTERP"] = EF_NOINTERP,
				["EF_NORECEIVESHADOW"] = EF_NORECEIVESHADOW,
				["EF_NOSHADOW"] = EF_NOSHADOW,
			},
		},
	},

	["engineflags"] = {
		CATEGORY = t_CAT.MISC,
		-- FUNCTION = { "AddEFlags", "__VALUE" }, // PreEntitySpawn()
		TYPE = "table", --, "int" },
		TBLSTRUCT = {
			TYPE = { "enum", "int" },
			-- FUNCTION = { "AddEFlags", "__VALUE" }, // PreEntitySpawn()
			FUNCTION = {
				function( self, value )
					-- for k in pairs( value ) do
						local v = bit.band( value, bit.bnot( EFL_KILLME ) ) // make sure bad flag isn't set
						self:AddEFlags( v )
					-- end
				end, "__SELF", "__VALUE"
			},
			ENUM = {
				["EFL_NO_DAMAGE_FORCES"] = EFL_NO_DAMAGE_FORCES,
				["EFL_NO_DISSOLVE"] = EFL_NO_DISSOLVE,
				["EFL_NO_GAME_PHYSICS_SIMULATION"] = EFL_NO_GAME_PHYSICS_SIMULATION,
				["EFL_NO_MEGAPHYSCANNON_RAGDOLL"] = EFL_NO_MEGAPHYSCANNON_RAGDOLL,
				["EFL_NO_PHYSCANNON_INTERACTION"] = EFL_NO_PHYSCANNON_INTERACTION,
				["EFL_NO_ROTORWASH_PUSH"] = EFL_NO_ROTORWASH_PUSH,
				["EFL_NO_THINK_FUNCTION"] = EFL_NO_THINK_FUNCTION,
				["EFL_NO_WATER_VELOCITY_CHANGE"] = EFL_NO_WATER_VELOCITY_CHANGE,
			},
		},
	},

	["entityflags"] = {
		CATEGORY = t_CAT.MISC,
		-- FUNCTION = { "AddFlags", "__VALUE" }, // PreEntitySpawn()
		FUNCTION = {
			function( self, value )
				-- for k in pairs( value ) do
					local v = bit.band( value, bit.bnot( FL_KILLME ) ) // make sure bad flag isn't set
					self:AddFlags( v )
				-- end
			end, "__SELF", "__VALUE"
		},
		TYPE = "table", -- "int" },
		TBLSTRUCT = {
			TYPE = { "enum", "int" },
			-- FUNCTION = { "AddFlags", "__VALUE" }, // PreEntitySpawn()
			ENUM = {
				["FL_AIMTARGET"] = FL_AIMTARGET,
				["FL_FROZEN"] = FL_FROZEN,
				["FL_NOTARGET"] = FL_NOTARGET,
				["FL_DONTTOUCH"] = FL_DONTTOUCH,
			},
		},
	},

	

	["friction_mult"] = {
		CATEGORY = t_CAT.PHYSICAL,
		FUNCTION = { "SetFriction", "__VALUE" },
      FUNCTION_GET = { "GetFriction" },
	},

	["gmod_allowphysgun"] = {
		CATEGORY = t_CAT.MISC,
		FUNCTION = { "SetKeyValue", "gmod_allowphysgun", "__VALUETOSTRING" },
		FUNCTION_GET = { "GetKeyValue", "gmod_allowphysgun" },
		TYPE = "boolean",
		ENUM = {
			["Disallow Physics Gun"] = true,
			["Allow Physics Gun"] = false,
		},
	},

	["numhealth"] = {
		CATEGORY = t_CAT.HEALTH,
      NAME = "Initial Health",
		DESC = "Sets initial health. Does not change max health",
		FUNCTION = { "SetHealth", "__VALUE" },        
		FUNCTION_GET = { "Health" },        
		-- DEFAULT = "-1",
	},

	["healthmult"] = {
		CATEGORY = t_CAT.HEALTH,
		DESC = "Multiply health and max health by this factor",
	},

	["ignite"] = {
		CATEGORY = t_CAT.PHYSICAL,
		DESC = "Set entity on fire on spawn for this many seconds",
		FUNCTION = { "Ignite", "__VALUE" },
	},

	["inputs"] = {
      NAME = "Inputs",
		CATEGORY = t_CAT.MISC,
		DESC = "Entity I/O, using Entity:Fire()",
		-- FUNCTION = {}, --[[ SpawnNPC() ]]
		TYPE = "struct_table",
		STRUCT = {
         //string input, string param = nil, number delay = 0, Entity activator = nil, Entity caller = nil
         ["command"] = {
            TYPE = "string",
            REQUIRED = true,
            ENUM = {
					["AddOutput"] = "AddOutput",
               ["Ignite"] =  "Ignite",
               ["IgniteLifetime"] =  "IgniteLifetime",
               ["Break"] =  "Break" ,
               ["BecomeRagdoll"] =  "BecomeRagdoll" ,
               ["StartScripting"] =  "StartScripting" ,
               ["StopScripting"] =  "StopScripting" ,
               ["Wake"] =  "Wake" ,
               ["GagEnable"] =  "GagEnable" ,
               ["GagDisable"] =  "GagDisable" ,
               ["IgnoreDangerSounds"] =  "IgnoreDangerSounds",
               ["HolsterWeapon"] =  "HolsterWeapon" ,
               ["UnholsterWeapon"] =  "UnholsterWeapon" ,
               ["HolsterAndDestroyWeapon"] =  "HolsterAndDestroyWeapon" ,
               ["DisableShadow"] =  "DisableShadow" ,
               ["EnableShadow"] =  "EnableShadow" ,
               ["DisableReceivingFlashlight"] =  "DisableReceivingFlashlight" ,
               ["EnableReceivingFlashlight"] =  "EnableReceivingFlashlight" ,
            },
         },
         ["value"] = {
            DESC = "The value to send with the command",
            TYPE = { "string", "int", "number", "boolean" },
				ENUM = {
					["Self"] = "!self",
					["Nearest Visible Player or First Player"] = "!pvsplayer",
					["First Player"] = "!player",
				},
         },
         ["delay"] = {
            DESC = "In seconds",
            TYPE = "number",
         },
		},
	},

	["jiggle_all"] = {
		CATEGORY = t_CAT.PHYSICAL,
		NAME = "Jiggle",
		DESC = "Jiggle",
		TYPE = "boolean",
	},

	["keyvalues"] = {
		CATEGORY = t_CAT.MISC,
		TYPE = "struct_table",
		STRUCT = {
			["key"] = {
				TYPE = "string",
			},
			["value"] = {
				TYPE = "any",
			},
		},
	},

	["bone_scale"] = {
		CATEGORY = t_CAT.PHYSICAL,
		NAME = "Bone Scale",
		DESC = "(Can cause significant lag) Scales all entity bones by this factor",
	},

	["bones"] = table.Copy( t_value_structs["bones"] ),

	["material"] = {
		CATEGORY = t_CAT.VISUAL,
		DESC = "Material path. Set to a blank string to revert to the model's default material",
		FUNCTION = { "SetMaterial", "__VALUETOSTRING" },
		FUNCTION_GET = { "GetMaterial" },
		TYPE = "string",
		ENUM = {
			["Cool Materials"] = {
				"__TBLRANDOM",
				"models/props_combine/tprings_globe",
				"models/effects/slimebubble_sheet",
				"models/flesh",
				"models/props_combine/com_shield001a",
				"models/props_combine/stasisshield_sheet",
				"models/props_lab/Tank_Glass001",
				"models/props_lab/xencrystal_sheet",
				"models/shadertest/shader5",
				"models/player/shared/gold_player",
				"models/player/shared/ice_player",
			},
		},
		ASSET = "materials",
	},

	["setboundary"] = {
		NAME = "Custom Collision Bounds",
		DESC = "Sets collision boundary box, relative to center of entity. Does not apply to players",
		CATEGORY = t_CAT.PHYSICAL,
		TYPE = "struct",
		STRUCT_RECURSIVE = true,
		STRUCT = {
			["min"] = {
				DESC = "Minimum vector",
				TYPE = "vector",
                DEFAULT = Vector()
			},
			["max"] = {
				DESC = "Maximum vector",
				TYPE = "vector",
                DEFAULT = Vector()
			},
		},
	},

	["submaterial"] = {
		CATEGORY = t_CAT.VISUAL,
		DESC = "Overrides a single material on the model of this entity based on its index",
		-- FUNCTION = { function( ent, val )
		-- 	-- for i=0,31 do
		-- 	-- 	print( i, ent:GetSubMaterial( i ) )
		-- 	-- end
		-- 	if istable( val ) then
		-- 		for k, v in pairs( val ) do
		-- 			-- print( v.id, v.material )
		-- 			ent:SetSubMaterial( v.id, v.material )
		-- 		end
		-- 	end
		-- 	-- for i=0,31 do
		-- 		-- print( i, ent:GetSubMaterial( i ) )
		-- 	-- end
		-- end, "__SELF", "__VALUE" },
		TYPE = "struct_table",
		STRUCT_RECURSIVE = true,
		-- STRUCT_TBLMAINKEY = "id",
		STRUCT = {
			["id"] = {
				DESC = "If nil (clear), then all submaterials will be reset",
				TYPE = "int",
				MIN = 0,
				MAX = 31,
			},
			["material"] = {
				ASSET = "materials",
				TYPE = "string",
				DESC = "If nil (clear), then it will revert to the default material",
			},
		},
	},

	["maxhealth"] = {
		CATEGORY = t_CAT.HEALTH,
      NAME = "Max Health",
		DESC = "Will also adjust the initial health unless specifically set",
		FUNCTION = { "SetMaxHealth", "__VALUE" },        -- DEFAULT = "-1",
		FUNCTION_GET = { "GetMaxHealth" },
	},

	["model"] = {
		-- CATEGORY = t_CAT.VISUAL,
		CATEGORY = t_CAT.REQUIRED,
		DESC = "Model path. Set to a blank string to revert to the class's default model",
		TYPE = "string",
		FUNCTION = { "SetModel", "__VALUE" },
		REVERTVALUE = "",
		ASSET = "models",
	},

	["physicsinit"] = {
		DESC = "Recreates the physics object with the given solid type. For simply recreating the physics object it should be SOLID_VPHYSICS, in most cases",
		CATEGORY = t_CAT.PHYSICAL,
		TYPE = { "enum", "int" },
		-- FUNCTION_REQ = true,
		FUNCTION = { "PhysicsInit", "__VALUE" },
		ENUM = {
			["SOLID_NONE"] = 0,
			["SOLID_BSP"] = 1,
			["SOLID_BBOX"] = 2,
			["SOLID_OBB"] = 3,
			["SOLID_OBB_YAW"] = 4,
			["SOLID_CUSTOM"] = 5,
			["SOLID_VPHYSICS"] = 6,
		},
	},

	["solidflags"] = {
		CATEGORY = t_CAT.PHYSICAL,
		FUNCTION = { "AddSolidFlags", "__VALUE" },
		FUNCTION_GET = { "GetSolidFlags" },
		TYPE = { "table", "int" },
		TBLSTRUCT = {
			TYPE = { "enum", "int" },
			ENUM = {
				["FSOLID_CUSTOMRAYTEST"] = 1,
				["FSOLID_CUSTOMBOXTEST"] = 2,
				["FSOLID_NOT_SOLID"] = 4,
				["FSOLID_TRIGGER"] = 8,
				["FSOLID_NOT_STANDABLE"] = 16,
				["FSOLID_VOLUME_CONTENTS"] = 32,
				["FSOLID_FORCE_WORLD_ALIGNED"] = 64,
				["FSOLID_USE_TRIGGER_BOUNDS"] = 128,
				["FSOLID_ROOT_PARENT_ALIGNED"] = 256,
				["FSOLID_TRIGGER_TOUCH_DEBRIS"] = 512,
				["FSOLID_MAX_BITS"] = 10,
			},
		},
	},

	-- ["nextregen"] = {
	-- 	-- FUNCTION = {}, --[[ DoActiveEffects() ]]
	-- 	TYPE = "data",
	-- 	DEFAULT = 0,
	-- 	NOLOOKUP = true,
	-- },

	["activate"] = {
		CATEGORY = t_CAT.MISC,
		DESC = "(Debug) If false, don't call Entity:Activate() on spawn. Bug fix: Defaulted to \"false\" on npc_manhack presets when deployed by Metropolice, to fix the manhack light staying visible even when the model is changed",
		-- FUNCTION = {}, --[[ SpawnNPC() ]]
		TYPE = "boolean",
	},

	["use"] = {
		CATEGORY = t_CAT.MISC,
		DESC = "+use the entity on spawn. Always originates from first player",
		-- FUNCTION = {}, --[[ SpawnNPC() ]]
		-- TYPE = "struct",
		-- STRUCT = {
		-- 	["activator"] = {
		-- 		DESC = "Orignator of signal. Number based on join order. Player in singleplayer is always \"1\"",
		-- 		TYPE = int,
		-- 		MIN = 1,
		-- 		DEFAULT = 1,
		-- 	},
		-- 	["signal"] = {
		-- 		TYPE = "enum",
		-- 		ENUM = {
		-- 			["OFF"] = 0,
		-- 			["ON"] = 1,
		-- 			["SET"] = 2,
		-- 			["TOGGLE"] = 3,
		-- 		},
		-- 	},
		-- },
		TYPE = "boolean",
	},

	["collisiongroup"] = {
		CATEGORY = t_CAT.PHYSICAL,
		FUNCTION = { "SetCollisionGroup", "__VALUE" },
		FUNCTION_GET = { "GetCollisionGroup" },
		TYPE = { "enum", "int" },
		MIN = 0,
		MAX = LAST_SHARED_COLLISION_GROUP,
		ENUM = {
			["COLLISION_GROUP_NONE"] = COLLISION_GROUP_NONE,
			["COLLISION_GROUP_DEBRIS"] = COLLISION_GROUP_DEBRIS,
			["COLLISION_GROUP_DEBRIS_TRIGGER"] = COLLISION_GROUP_DEBRIS_TRIGGER,
			["COLLISION_GROUP_INTERACTIVE_DEBRIS"] = COLLISION_GROUP_INTERACTIVE_DEBRIS,
			["COLLISION_GROUP_INTERACTIVE"] = COLLISION_GROUP_INTERACTIVE,
			["COLLISION_GROUP_PLAYER"] = COLLISION_GROUP_PLAYER,
			["COLLISION_GROUP_BREAKABLE_GLASS"] = COLLISION_GROUP_BREAKABLE_GLASS,
			["COLLISION_GROUP_VEHICLE"] = COLLISION_GROUP_VEHICLE,
			["COLLISION_GROUP_PLAYER_MOVEMENT"] = COLLISION_GROUP_PLAYER_MOVEMENT,
			["COLLISION_GROUP_NPC"] = COLLISION_GROUP_NPC,
			["COLLISION_GROUP_IN_VEHICLE"] = COLLISION_GROUP_IN_VEHICLE,
			["COLLISION_GROUP_WEAPON"] = COLLISION_GROUP_WEAPON,
			["COLLISION_GROUP_VEHICLE_CLIP"] = COLLISION_GROUP_VEHICLE_CLIP,
			["COLLISION_GROUP_PROJECTILE"] = COLLISION_GROUP_PROJECTILE,
			["COLLISION_GROUP_DOOR_BLOCKER"] = COLLISION_GROUP_DOOR_BLOCKER,
			["COLLISION_GROUP_PASSABLE_DOOR"] = COLLISION_GROUP_PASSABLE_DOOR,
			["COLLISION_GROUP_DISSOLVING"] = COLLISION_GROUP_DISSOLVING,
			["COLLISION_GROUP_PUSHAWAY"] = COLLISION_GROUP_PUSHAWAY,
			["COLLISION_GROUP_NPC_ACTOR"] = COLLISION_GROUP_NPC_ACTOR,
			["COLLISION_GROUP_NPC_SCRIPTED"] = COLLISION_GROUP_NPC_SCRIPTED,
			["COLLISION_GROUP_WORLD"] = COLLISION_GROUP_WORLD,
		},
	},

	-- ["gravitymult"] = {
	-- 	CATEGORY = t_CAT.PHYSICAL,
	-- 	NAME = "Gravity Multiplier",
	-- 	FUNCTION = { "SetGravity", "__VALUE" },
	-- },

	["physobject"] = { // functions will be called on the phys obj
		DESC = "Only for physics-enabled entities",
		CATEGORY = t_CAT.PHYSICAL,	
		TYPE = "struct",
		STRUCT = {
			["contents"] = {
				FUNCTION = { "SetContents", "__VALUE" },
				TYPE = { "enum", "int" },
				ENUM = {
					["CONTENTS_EMPTY"] = CONTENTS_EMPTY,
					["CONTENTS_SOLID"] = CONTENTS_SOLID,
					["CONTENTS_WINDOW"] = CONTENTS_WINDOW,
					["CONTENTS_AUX"] = CONTENTS_AUX,
					["CONTENTS_GRATE"] = CONTENTS_GRATE,
					["CONTENTS_SLIME"] = CONTENTS_SLIME,
					["CONTENTS_WATER"] = CONTENTS_WATER,
					["CONTENTS_BLOCKLOS"] = CONTENTS_BLOCKLOS,
					["CONTENTS_OPAQUE"] = CONTENTS_OPAQUE,
					["CONTENTS_TESTFOGVOLUME"] = CONTENTS_TESTFOGVOLUME,
					["CONTENTS_TEAM4"] = CONTENTS_TEAM4,
					["CONTENTS_TEAM3"] = CONTENTS_TEAM3,
					["CONTENTS_TEAM1"] = CONTENTS_TEAM1,
					["CONTENTS_TEAM2"] = CONTENTS_TEAM2,
					["CONTENTS_IGNORE_NODRAW_OPAQUE"] = CONTENTS_IGNORE_NODRAW_OPAQUE,
					["CONTENTS_MOVEABLE"] = CONTENTS_MOVEABLE,
					["CONTENTS_AREAPORTAL"] = CONTENTS_AREAPORTAL,
					["CONTENTS_PLAYERCLIP"] = CONTENTS_PLAYERCLIP,
					["CONTENTS_MONSTERCLIP"] = CONTENTS_MONSTERCLIP,
					["CONTENTS_CURRENT_0"] = CONTENTS_CURRENT_0,
					["CONTENTS_CURRENT_180"] = CONTENTS_CURRENT_180,
					["CONTENTS_CURRENT_270"] = CONTENTS_CURRENT_270,
					["CONTENTS_CURRENT_90"] = CONTENTS_CURRENT_90,
					["CONTENTS_CURRENT_DOWN"] = CONTENTS_CURRENT_DOWN,
					["CONTENTS_CURRENT_UP"] = CONTENTS_CURRENT_UP,
					["CONTENTS_DEBRIS"] = CONTENTS_DEBRIS,
					["CONTENTS_DETAIL"] = CONTENTS_DETAIL,
					["CONTENTS_HITBOX"] = CONTENTS_HITBOX,
					["CONTENTS_LADDER"] = CONTENTS_LADDER,
					["CONTENTS_MONSTER"] = CONTENTS_MONSTER,
					["CONTENTS_ORIGIN"] = CONTENTS_ORIGIN,
					["CONTENTS_TRANSLUCENT"] = CONTENTS_TRANSLUCENT,
				},
			},
			["angledrag"] = {
				FUNCTION = { "SetAngleDragCoefficient", "__VALUE" },
				TYPE = "number",
			},
			["drag"] = {
				FUNCTION = { "SetDragCoefficient", "__VALUE" },
				TYPE = "number",
			},
			["angle"] = {
				FUNCTION = { "SetAngles", "__VALUE" },
				TYPE = "angle",
			},
			["angularvelocity"] = {
				FUNCTION = { "SetAngleVelocity", "__VALUE" },
				TYPE = "vector",
			},
			["buoyancyratio"] = {
				FUNCTION = { "SetBuoyancyRatio", "__VALUE" },
				TYPE = "number",
			},
			["damping"] = {
				FUNCTION = { "SetDamping", "__VALUE", "__VALUE" },
				TYPE = "vector",
			},
			["inertia"] = {
				FUNCTION = { "SetInertia", "__VALUE" },
				TYPE = "vector",
			},
			["mass"] = {
				FUNCTION = { "SetMass", "__VALUE" },
				TYPE = "number",
			},

			["gravity"] = {
				TYPE = "boolean",
				FUNCTION = { "EnableGravity", "__VALUE" },
			},

			["material"] = {
				FUNCTION = { "SetMaterial", "__VALUE" },
				TYPE = { "enum", "string" },
				ENUM = {
					["alienflesh"] = "alienflesh",
					["antlion"] = "antlion",
					["antlionsand"] = "antlionsand",
					["armorflesh"] = "armorflesh",
					["bloodyflesh"] = "bloodyflesh",
					["boulder "] = "boulder ",
					["brakingrubbertire"] = "brakingrubbertire",
					["brick"] = "brick",
					["canister"] = "canister",
					["cardboard"] = "cardboard",
					["carpet"] = "carpet",
					["ceiling_tile"] = "ceiling_tile",
					["chain"] = "chain",
					["chainlink"] = "chainlink",
					["combine_glass"] = "combine_glass",
					["combine_metal"] = "combine_metal",
					["computer"] = "computer",
					["concrete"] = "concrete",
					["concrete_block"] = "concrete_block",
					["crowbar"] = "crowbar",
					["default"] = "default",
					["default_silent"] = "default_silent",
					["dirt"] = "dirt",
					["flesh"] = "flesh",
					["floating_metal_barrel"] = "floating_metal_barrel",
					["floatingstandable"] = "floatingstandable",
					["foliage"] = "foliage",
					["glass"] = "glass",
					["glassbottle"] = "glassbottle",
					["gmod_bouncy"] = "gmod_bouncy",
					["gmod_ice"] = "gmod_ice",
					["gmod_silent"] = "gmod_silent",
					["grass"] = "grass",
					["gravel"] = "gravel",
					["gravel"] = "gravel",
					["grenade"] = "grenade",
					["gunship"] = "gunship",
					["ice"] = "ice",
					["item"] = "item",
					["jeeptire"] = "jeeptire",
					["ladder"] = "ladder",
					["metal"] = "metal",
					["metal_barrel"] = "metal_barrel",
					["metal_bouncy"] = "metal_bouncy",
					["Metal_Box"] = "Metal_Box",
					["metalgrate"] = "metalgrate",
					["metalpanel"] = "metalpanel",
					["metal_seafloorcar"] = "metal_seafloorcar",
					["metalvehicle"] = "metalvehicle",
					["metalvent"] = "metalvent",
					["mud"] = "mud",
					["no_decal"] = "no_decal",
					["paintcan"] = "paintcan",
					["paper"] = "paper",
					["papercup"] = "papercup",
					["pecial"] = "pecial",
					["plaster"] = "plaster",
					["plastic"] = "plastic",
					["plastic_barrel"] = "plastic_barrel",
					["plastic_barrel_buoyant"] = "plastic_barrel_buoyant",
					["Plastic_Box"] = "Plastic_Box",
					["player"] = "player",
					["player_control_clip"] = "player_control_clip",
					["popcan"] = "popcan",
					["pottery"] = "pottery",
					["puddle"] = "puddle",
					["quicksand"] = "quicksand",
					["rock"] = "rock",
					["roller"] = "roller",
					["rubber"] = "rubber",
					["rubbertire"] = "rubbertire",
					["sand"] = "sand",
					["slidingrubbertire"] = "slidingrubbertire",
					["slidingrubbertire_front"] = "slidingrubbertire_front",
					["slidingrubbertire_rear"] = "slidingrubbertire_rear",
					["slime"] = "slime",
					["slipperymetal"] = "slipperymetal",
					["slipperyslime"] = "slipperyslime",
					["snow"] = "snow",
					["solidmetal"] = "solidmetal",
					["strider"] = "strider",
					["tile"] = "tile",
					["wade"] = "wade",
					["water"] = "water",
					["watermelon"] = "watermelon",
					["weapon"] = "weapon",
					["Wood"] = "Wood",
					["Wood_Box"] = "Wood_Box",
					["Wood_Crate "] = "Wood_Crate ",
					["Wood_Furniture"] = "Wood_Furniture",
					["Wood_LowDensity "] = "Wood_LowDensity ",
					["Wood_Panel"] = "Wood_Panel",
					["Wood_Plank"] = "Wood_Plank",
					["Wood_Solid"] = "Wood_Solid",
					["zombieflesh"] = "zombieflesh",
				},
			},
		}
	},

	["physcollide"] = {
		CATEGORY = t_CAT.PHYSICAL,
		NAME = "Physics Collisions",
		DESC = "Will only work if either entity involved in the collision is a physics-enabled entity. Damage and other actions when this entity collides with other entities",
		-- FUNCTION = {}, --[[{ "AddCallback", "PhysicsCollide", EntRamming },]]
		TYPE = "struct_table",
		STRUCT = {
			-- ["self_damage_scale"] = {
			-- 	DEFAULT = 0,
			-- },
			["no_impact"] = {
				NAME = "Do Not Apply Velocity",
				TYPE = "boolean",
				DESC = "If true, do not apply velocity and damage force",
			},
			["no_zero"] = {
				NAME = "Do Not Apply Zero Damage",
				TYPE = "boolean",
				DESC = "If true, the entity will not TakeDamageInfo if the damage is less than or equal to 0. Fixes a problem where player armor is damaged even if damage is 0 or less, but means damage force will not be applied (though velocity can still be applied)",
			},
			["damage_scale"] =  {
				NAME = "Collision Damage Factor",
				DEFAULT = 0.0025,
			},
			["damage_type"] =  {
				NAME = "Collision Damage Type",
				TYPE = { "enum", "int" },
				DEFAULT = "DMG_VEHICLE",
				ENUM = t_enums["dmg_type"],
			},
			["damagefilter_out"] = {
				NAME = "Damage Filter: Outgoing",
				-- CATEGORY = t_CAT.COMBAT,
				DESC = "(Applied for every entity hit) Filters, if passed, conditionally adjust damage and allow other effects to both attacker and victim. The filters are tested from top to bottom, succeeding after any filter passes",
				TYPE = "struct_table",
				STRUCT = t_value_structs["damagefilter"].STRUCT,
			},
			["speed_min"] = {
				NAME = "Minimum Collision Speed",
				DESC = "Collision must impact greater than or equal to this speed to be valid",
				DEFAULT = 300,
			},
			["speed_exp"] = {
				NAME = "Collision Speed-Damage Ratio Exponent",
				DEFAULT = 1.5,
			},
			["flat_damage"] = {
				NAME = "Flat Damage",
				DESC = "Overrides damage",
			},
			["npc_only"] = {
				NAME = "Characters Only",
				DESC = "True to include, false to exclude. Regards applying damage and damage filters",
				TYPE = "boolean",
			},
			["filter_onlyimpact"] = {
				NAME = "Only Damage Filter On Impacted",
				DESC = "Only run the damage filter on the single entity hit, the rest simply take impact damage if applicable",
				TYPE = "boolean",
			},
			["effects"] = t_value_structs["effects"],
			["newvelocity_mult"] = {
				NAME = "Victim New Velocity Factor",
				DESC = "Victim inherits collision's velocity, multiplied by this factor",
				DEFAULT = 1,
			},
			["impact_radius"] = {
				DESC = "If given, collision is applied to every entity in this radius. This can also include non-physics-enabled entities",
				-- DEFAULT = 180,
			},
			["mindelay"] =  {
				DESC = "Minimum delay between valid collisions, since collisions can activate multiple times rapidly. If function, rerolls every time it is called",
				DEFAULT = 0.24,
				MIN = 0,
			},
		},
	},

	["physdamagescale"] = {
		CATEGORY = t_CAT.DAMAGE,
		FUNCTION = { "SetKeyValue", "physdamagescale", "__VALUETOSTRING" },
		FUNCTION_GET = { "GetKeyValue", "physdamagescale" },
		NAME = "Incoming Physics Damage",
	},

	

	["ragdoll_serverside"] = {
		NAME = "Keep Corpse",
		CATEGORY = t_CAT.PHYSICAL,
		FUNCTION = { "SetShouldServerRagdoll", "__VALUE" },
		FUNCTION_GET = { "GetShouldServerRagdoll" },
		TYPE = "boolean",
	},

	

	["renderamt"] = {
		CATEGORY = t_CAT.VISUAL,
		-- FUNCTION = {}, --[[ FadeIns() ]]
		NAME = "Alpha", 
		DEFAULT = 255,        
		MIN = 0,        
		MAX = 255,
		-- ENUM = {
		-- 	["Random"] = { math.Rand, 1, 255 },
		-- },
	},

	["rendercolor"] = { 
		CATEGORY = t_CAT.VISUAL,
		FUNCTION = { "SetColor", "__VALUE"}, --[[ SetColors() ]]
		FUNCTION_GET = { "GetColor" },
		COLORALPHA = false,
		NAME = "Color",
		TYPE = "color",
		-- ENUM = {
		-- 	["Random"] = { RandomColor },
		-- },
	},

	["renderfx"] = {
		CATEGORY = t_CAT.VISUAL,
		TYPE = { "enum", "int" },
		FUNCTION = { "SetRenderFX" , "__VALUE" },        
		FUNCTION_GET = { "GetRenderFX" },
		MIN = 0,        
		-- MAX = 24,
		ENUM = {
			-- ["Random"] = { math.random, 0, 24 },
			["kRenderFxNone"] = kRenderFxNone,
			["kRenderFxPulseSlow"] = kRenderFxPulseSlow,
			["kRenderFxPulseFast"] = kRenderFxPulseFast,
			["kRenderFxPulseSlowWide"] = kRenderFxPulseSlowWide,
			["kRenderFxPulseFastWide"] = kRenderFxPulseFastWide,
			["kRenderFxFadeSlow"] = kRenderFxFadeSlow,
			["kRenderFxFadeFast"] = kRenderFxFadeFast,
			["kRenderFxSolidSlow"] = kRenderFxSolidSlow,
			["kRenderFxSolidFast"] = kRenderFxSolidFast,
			["kRenderFxStrobeSlow"] = kRenderFxStrobeSlow,
			["kRenderFxStrobeFast"] = kRenderFxStrobeFast,
			["kRenderFxStrobeFaster"] = kRenderFxStrobeFaster,
			["kRenderFxFlickerSlow"] = kRenderFxFlickerSlow,
			["kRenderFxFlickerFast"] = kRenderFxFlickerFast,
			["kRenderFxNoDissipation"] = kRenderFxNoDissipation,
			["kRenderFxDistort"] = kRenderFxDistort,
			["kRenderFxHologram"] = kRenderFxHologram,
			["kRenderFxExplode"] = kRenderFxExplode,
			["kRenderFxGlowShell"] = kRenderFxGlowShell,
			["kRenderFxClampMinScale"] = kRenderFxClampMinScale,
			["kRenderFxEnvRain"] = kRenderFxEnvRain,
			["kRenderFxEnvSnow"] = kRenderFxEnvSnow,
			["kRenderFxSpotlight"] = kRenderFxSpotlight,
			["kRenderFxRagdoll"] = kRenderFxRagdoll,
			["kRenderFxPulseFastWider"] = kRenderFxPulseFastWider,
		},
	},

	["rendermode"] = {
		CATEGORY = t_CAT.VISUAL,
		FUNCTION = { "SetRenderMode" , "__VALUE" }, --[[ also FadeIns() ]]
		FUNCTION_GET = { "GetRenderMode" },
		-- ENUM = {
		-- 	["Random"] = { math.random, 1, 10 },
		-- },
		TYPE = { "enum", "int" },
		DEFAULT = "RENDERMODE_TRANSCOLOR",        
		MIN = 0,        
		-- MAX = 10,
		ENUM = {
			["RENDERMODE_NORMAL"] = 0,
			["RENDERMODE_TRANSCOLOR"] = 1,
			["RENDERMODE_TRANSTEXTURE"] = 2,
			["RENDERMODE_GLOW"] = 3,
			["RENDERMODE_TRANSALPHA"] = 4,
			["RENDERMODE_TRANSADD"] = 5,
			["RENDERMODE_ENVIROMENTAL"] = 6,
			["RENDERMODE_TRANSADDFRAMEBLEND"] = 7,
			["RENDERMODE_TRANSALPHADD"] = 8,
			["RENDERMODE_WORLDGLOW"] = 9,
			["RENDERMODE_NONE"] = 10,
		},
		TYPE = { "enum", "int" },
	},

	["scale"] = {
		CATEGORY = t_CAT.PHYSICAL,
		FUNCTION = { "SetModelScale", "__VALUE", engine.TickInterval() },
		FUNCTION_GET = { "GetModelScale" },
		-- ENUM = {
		-- 	["Random"] = { math.Rand, 0.33, 2 },        
		-- },
		-- DEFAULT = 1,        
		-- MIN = 0,        
		-- MAX = 5,
	},

	["skin"] = {
		CATEGORY = t_CAT.VISUAL,
		FUNCTION = { "SetSkin", "__VALUE" },
		FUNCTION_GET = { "GetSkin" },
		TYPE = "int",
	},

	

	["spawneffect"] = {
		CATEGORY = t_CAT.VISUAL,
		-- FUNCTION = {}, --[[ SpawnNPC() ]]
		TYPE = "struct_table",
		STRUCT_TBLMAINKEY = "name",
		STRUCT = table.Copy( t_value_structs["effects"].STRUCT ),
	},

	["spawnflags"] = {
		CATEGORY = t_CAT.MISC,
		TYPE = { "table", "int" },
		DESC = "Sets exclusive features of an entity. Spawnflags differ depending on entity class",
		FUNCTION = { "AddSpawnFlag", "__VALUE" },
		TBLSTRUCT = {
			TYPE = "int",
		},
		-- FUNCTION = { "AddSpawnFlag", "__VALUE" },
		-- ENUM = {
		-- 	["Do Alternate collision for this NPC (player avoidance)"] = 4096,
		-- 	["Think outside PVS"] = 1024,
		-- 	["Drop Healthkit"] = 8,
		-- 	["Fade Corpse"] = 512,
		-- 	["Fall to ground (unchecked means *teleport* to ground)"] = 4,
		-- 	["Gag (No IDLE sounds until angry)"] = 2,
		-- 	["Long Visibility/Shoot"] = 256,
		-- 	["Ignore player push"] = 16384,
		-- 	["Don't drop weapons"] = 8192,
		-- 	["Efficient - Don't acquire enemies or avoid obstacles"] = 16,
		-- 	["Wait Till Seen"] = 1,
		-- },
	},

	["spritetrail"] = {
		CATEGORY = t_CAT.VISUAL,
		-- FUNCTION = {}, --[[ SpawnNPC() ]]
		TYPE = "struct_table",
		STRUCT_TBLMAINKEY = "texture",
		STRUCT = {
			["attachment"] = {
				DEFAULT = 0,
				TYPE = "int",
			}, --0,
			["color"] = {
				TYPE = "color",
				DEFAULT = Color( 255, 255, 255),
			}, --Color(255,255,255),
			["additive"] = {
				TYPE = "boolean",
				DEFAULT = false,
			}, --false,
			["startwidth"] = {
				DEFAULT = 25,
			},--25,
			["endwidth"] = {
				DEFAULT = 1,
			},--1,
			["lifetime"] = {
				DEFAULT = 5,
			},--5,
			["texture"] = {
				TYPE = "string",
				DEFAULT = "trails/plasma",
				ASSET = "textures",
			},--"trails/plasma",
		},
	},

	["pickupsound"] = {
		CATEGORY = t_CAT.VISUAL,
		TYPE = "boolean",
		FUNCTION = { "SetShouldPlayPickupSound", "__VALUE" },
		FUNCTION_GET = { "GetShouldPlayPickupSound" },
	},

	["bodygroups"] = {
		CATEGORY = t_CAT.VISUAL,
		TYPE = "struct_table",
		STRUCT_RECURSIVE = true,
		STRUCT = {
			["group"] = {
				DESC = "Index as int or name as string",
				TYPE = { "int", "string" },
				MIN = 0,
				DEFAULT = 0,
			},
			["value"] = {
				TYPE = "int",
				MIN = 0,
				DEFAULT = 0,
			},
		},
		-- FUNCTION = { function( ent, val )
		-- 	if !istable( val ) then return end
		-- 	for _, bg in pairs( val ) do
		-- 		-- if bg.value == nil then continue end

		-- 		local id = bg.group
		-- 		-- if isstring( id ) then
		-- 		-- 	id = ent:FindBodygroupByName( id )
		-- 		-- end
		-- 		-- if !id or id == -1 then continue end

		-- 		ent:SetBodygroup( id, bg.value )
		-- 	end
		-- end, "__SELF", "__VALUE" },
	},

	["ent_funcs"] = {
		NAME = "Entity Functions",
		DESC = "Runs pre-existing functions from the entity. Arguments are sent as-is and are NOT compiled as Lua",
		CATEGORY = t_CAT.MISC,
		TYPE = "struct_table",
		STRUCT = {
			["func"] = {
				NAME = "Function",
				SORTNAME = "a",
				TYPE = "string",
			},
			["args"] = {
				NAME = "Arguments",
				SORTNAME = "b",
				TYPE = "table",
				TBLSTRUCT = {
					TYPE = "any",
				},
			},
			["delay"] = {
				NAME = "Delay",
				SORTNAME = "c",
				TYPE = "number",
			},
		},
	},

	["drawshadow"] = {
		NAME = "Draw Shadow",
		CATEGORY = t_CAT.VISUAL,
		FUNCTION = { "DrawShadow", "__VALUE" },
		TYPE = "boolean",
	},
}

local spawnflags_desc = "Sets exclusive features of an entity. Class-specific enums included. Note for all class-specific values: If a value has a class-specific version (e.g. spawnflags), that value will be cleared when the class struct is changed or removed if the class-specific version was ever touched."

t_entity_base_values = {
	["entity_type"] = {
		TYPE = "data",
		DEFAULT = "entity",
		DEFAULT_SAVE = true,
	},
}
t_entity_class_values = {
	["prop_physics"] = {
		["keyvalues"] = {
			CATEGORY = t_CAT.MISC,
			TYPE = "struct_table",
			STRUCT = {
				["key"] = {
					TYPE = "string",
					ENUM = {
						["Damagetype <boolean> (If true, damage type is sharp)"] = "Damagetype",
						["nodamageforces <boolean> (Damaging it doesn't push it)"] = "nodamageforces",
						["inertiascale <float>"] = "inertiascale",
						["massscale <float>"] = "massscale",
						["damagetoenablemotion <int>"] = "damagetoenablemotion",
						["forcetoenablemotion <int>"] = "forcetoenablemotion",
					},
				},
				["value"] = {
					TYPE = "any",
				},
			},
		},
		["spawnflags"] = {
			DESC = spawnflags_desc,
			FUNCTION = { "AddSpawnFlag", "__VALUE" },
			TYPE = { "table", "int" },
			TBLSTRUCT = {
				TYPE = { "enum", "int" },
				ENUM = {
					["Start Asleep"] = 1,
					["Don't take physics damage"] = 2,
					["Debris - Don't collide with the player or other debris"] = 4,
					["Motion Disabled"] = 8,
					["Break on Touch"] = 16,
					["Break on Pressure"] = 32,
					["Enable motion when grabbed by gravity gun"] = 64,
					["Not affected by rotor wash"] = 128,
					["Generate output on +use"] = 256,
					["Prevent pickup"] = 512,
					["Prevent motion enable on player bump"] = 1024,
					["Debris with trigger interaction"] = 4096,
					["Force server-side (Multiplayer only; see sv_pushaway_clientside_size)"] = 8192,
					["Gravity gun can ALWAYS pick up. No matter what"] = 1048576,
				},
			},
		},
	},
}

t_npc_base_values = {

	-- ["classname"] = { 
	-- 	-- FUNCTION = {}, --[[ SpawnNPC() ]]
	-- 	NOFUNC = true,
	-- 	DESC = "The entity's class. Can also be typed as a string. For example, props are \"prop_physics\" or \"prop_physics_multiplayer\"",
	-- 	CATEGORY = t_CAT.REQUIRED,
	-- 	NAME = "Entity Class Name", 
	-- 	TYPE = { "preset", "string" }, 
	-- 	PRESETS_ENTITYLIST = true,
	-- 	-- PRESETS_ENTITYLIST_ONLY = { ["NPC"] = "NPC" },
	-- 	REQUIRED = true,
	-- 	CANCLASS = true,
	-- },

	["animspeed"] = {
		NAME = "Animation Speed",
		CATEGORY = t_CAT.PHYSICAL,
		FUNCTION = { "SetPlaybackRate", "__VALUE" },
	},

	["capabilities_add"] = {
		CATEGORY = t_CAT.MISC,
		FUNCTION = { "CapabilitiesAdd" , "__VALUE" },
		TYPE = { "table", "int" },
		TBLSTRUCT = {
			TYPE = { "enum", "int" },
			ENUM = {
				["CAP_AIM_GUN"] = 536870912,
				["CAP_ANIMATEDFACE"] = 8388608,
				["CAP_AUTO_DOORS"] = 1024,
				["CAP_DUCK"] = 134217728,
				["CAP_FRIENDLY_DMG_IMMUNE"] = 33554432,
				["CAP_INNATE_MELEE_ATTACK1"] = 524288,
				["CAP_INNATE_MELEE_ATTACK2"] = 1048576,
				["CAP_INNATE_RANGE_ATTACK1"] = 131072,
				["CAP_INNATE_RANGE_ATTACK2"] = 262144,
				["CAP_MOVE_CLIMB"] = 8,
				["CAP_MOVE_CRAWL"] = 32,
				["CAP_MOVE_FLY"] = 4,
				["CAP_MOVE_GROUND"] = 1,
				["CAP_MOVE_JUMP"] = 2,
				["CAP_MOVE_SHOOT"] = 64,
				["CAP_MOVE_SWIM"] = 16,
				["CAP_NO_HIT_PLAYER"] = 268435456,
				["CAP_NO_HIT_SQUADMATES"] = 1073741824,
				["CAP_OPEN_DOORS"] = 2048,
				["CAP_SIMPLE_RADIUS_DAMAGE"] = -2147483648,
				["CAP_SKIP_NAV_GROUND_CHECK"] = 128,
				["CAP_SQUAD"] = 67108864,
				["CAP_TURN_HEAD"] = 4096,
				["CAP_USE"] = 256,
				["CAP_USE_SHOT_REGULATOR"] = 16777216,
				["CAP_USE_WEAPONS"] = 2097152,
				["CAP_WEAPON_MELEE_ATTACK1"] = 32768,
				["CAP_WEAPON_MELEE_ATTACK2"] = 65536,
				["CAP_WEAPON_RANGE_ATTACK1"] = 8192,
				["CAP_WEAPON_RANGE_ATTACK2"] = 16384,
			},
		},
	},
	["capabilities_remove"] = {
		CATEGORY = t_CAT.MISC,
		FUNCTION = { "CapabilitiesRemove" , "__VALUE" },
		TYPE = { "table", "int" },
		TBLSTRUCT = {
			TYPE = { "enum", "int" },
			ENUM = {
				["CAP_AIM_GUN"] = 536870912,
				["CAP_ANIMATEDFACE"] = 8388608,
				["CAP_AUTO_DOORS"] = 1024,
				["CAP_DUCK"] = 134217728,
				["CAP_FRIENDLY_DMG_IMMUNE"] = 33554432,
				["CAP_INNATE_MELEE_ATTACK1"] = 524288,
				["CAP_INNATE_MELEE_ATTACK2"] = 1048576,
				["CAP_INNATE_RANGE_ATTACK1"] = 131072,
				["CAP_INNATE_RANGE_ATTACK2"] = 262144,
				["CAP_MOVE_CLIMB"] = 8,
				["CAP_MOVE_CRAWL"] = 32,
				["CAP_MOVE_FLY"] = 4,
				["CAP_MOVE_GROUND"] = 1,
				["CAP_MOVE_JUMP"] = 2,
				["CAP_MOVE_SHOOT"] = 64,
				["CAP_MOVE_SWIM"] = 16,
				["CAP_NO_HIT_PLAYER"] = 268435456,
				["CAP_NO_HIT_SQUADMATES"] = 1073741824,
				["CAP_OPEN_DOORS"] = 2048,
				["CAP_SIMPLE_RADIUS_DAMAGE"] = -2147483648,
				["CAP_SKIP_NAV_GROUND_CHECK"] = 128,
				["CAP_SQUAD"] = 67108864,
				["CAP_TURN_HEAD"] = 4096,
				["CAP_USE"] = 256,
				["CAP_USE_SHOT_REGULATOR"] = 16777216,
				["CAP_USE_WEAPONS"] = 2097152,
				["CAP_WEAPON_MELEE_ATTACK1"] = 32768,
				["CAP_WEAPON_MELEE_ATTACK2"] = 65536,
				["CAP_WEAPON_RANGE_ATTACK1"] = 8192,
				["CAP_WEAPON_RANGE_ATTACK2"] = 16384,
			},
		},
	},

	["chase_players"] = {
		CATEGORY = t_CAT.CHASE,
		NAME = "Chase Players",
		DESC = "Pick a random player to chase until either dies",
		TYPE = "boolean",
		TESTFUNCTION = f_test_chase,
	},

	["chase_setenemy"] = {
		CATEGORY = t_CAT.CHASE,
		NAME = "Set NPC Enemy On Chase",
		DESC = "The entity chosen on chase will be marked as an enemy. Some schedules need this",
		TYPE = "boolean",  
		DEFAULT = true,      
		TESTFUNCTION = f_test_chase,
	},
	["seekout_setenemy"] = {
		CATEGORY = t_CAT.CHASE,
		NAME = "Set NPC Enemy On Seekout",
		DESC = "The entity chosen on seekout will be marked as an enemy. Some schedules need this",
		TYPE = "boolean",         
		TESTFUNCTION = f_test_chase,
	},

	["chase_settarget"] = {
		CATEGORY = t_CAT.CHASE,
		NAME = "Set NPC Target On Chase",
		DESC = "The entity chosen on chase will be marked as a target. Some schedules need this",
		TYPE = "boolean",
		DEFAULT = true,
		TESTFUNCTION = f_test_chase,
	},
	["seekout_settarget"] = {
		CATEGORY = t_CAT.CHASE,
		NAME = "Set NPC Target On Seekout",
		DESC = "The entity chosen on seekout will be marked as a target. Some schedules need this",
		TYPE = "boolean",
		TESTFUNCTION = f_test_chase,
	},

	["seekout_clear"] = {
		CATEGORY = t_CAT.CHASE,
		NAME = "Stop Seekout Schedule On Enemy Found",
		DESC = "Clears the seekout schedule when the NPC has a enemy or target after being sent on seekout. Conflicts with \"Set NPC Enemy/Target On Seekout\"",
		TYPE = "boolean",
		DEFAULT = true,
		TESTFUNCTION = f_test_chase,
	},
	["seekout_clear_dmg"] = {
		CATEGORY = t_CAT.CHASE,
		NAME = "Stop Seekout Schedule On Damage",
		DESC = "Clears the seekout schedule when the NPC takes damage after being sent on seekout",
		TYPE = "boolean",
		DEFAULT = true,
		TESTFUNCTION = f_test_chase,
	},
	["dmg_setenemy"] = {
		CATEGORY = t_CAT.CHASE,
		NAME = "Change Enemy On Damage",
		TYPE = "boolean",
		TESTFUNCTION = "SetEnemy",
	},
	["dmg_settarget"] = {
		CATEGORY = t_CAT.CHASE,
		NAME = "Change Target On Damage",
		TYPE = "boolean",
		TESTFUNCTION = "SetTarget",
	},
	["dmg_setchase"] = {
		CATEGORY = t_CAT.CHASE,
		NAME = "Chase Last Attacker",
		TYPE = "boolean",
		TESTFUNCTION = f_test_chase,
	},

	["chase_anything"] = {
		CATEGORY = t_CAT.CHASE,
		TYPE = "boolean",
		NAME = "Chase Non-Players",
		DESC = "Picks a random non-player target to chase until either dies",
		TESTFUNCTION = f_test_chase,
	},

	["chase_preset"] = {
		CATEGORY = t_CAT.CHASE,
		NAME = "Chase Preset",
		TYPE = "table",
		DESC = "Picks a random target out of any of the given presets to chase until either dies",
		TBLSTRUCT = {
			TYPE = "preset",
			PRESETS = {
				"npc",
				"entity",
				"nextbot",
				"player",
			},
		},
		TESTFUNCTION = f_test_chase,
	},

	["chase_schedule"] = {
		CATEGORY = t_CAT.CHASE,
		NAME = "Preferred NPC Chase Schedule",
		DESC = "The NPC schedule used when chasing. If the preferred schedule fails too many times, then the next schedule down the list will be the new preferred schedule, and so on",
		DEFAULT = { "SCHED_TARGET_CHASE", "SCHED_CHASE_ENEMY", "SCHED_FORCED_GO_RUN" },
		TYPE = "table",
		TBLSTRUCT = {
			ENUM_SORT = true,
			TYPE = { "enum", "int" },
			MIN = 0,
			MAX = LAST_SHARED_SCHEDULE,
			ENUM = t_enums["schedule"],
		},
		TESTFUNCTION = f_test_chase,
	},

	["seekout_schedule"] = {
		CATEGORY = t_CAT.CHASE,
		NAME = "Preferred NPC Seekout Schedule",
		DESC = "The NPC schedule used when sent on seekout. If the preferred schedule fails too many times, then the next schedule down the list will be the new preferred schedule, and so on",
		DEFAULT = {  "SCHED_FORCED_GO", "SCHED_TARGET_CHASE", "SCHED_CHASE_ENEMY", "SCHED_FORCED_GO_RUN" },
		TYPE = "table",
		TBLSTRUCT = {
			ENUM_SORT = true,
			TYPE = { "enum", "int" },
			MIN = 0,
			MAX = LAST_SHARED_SCHEDULE,
			ENUM = t_enums["schedule"],
		},
		TESTFUNCTION = f_test_chase,
	},

	["entity_type"] = {
		TYPE = "data",
		DEFAULT = "npc",
		DEFAULT_SAVE = true,
	},

	["aware_range"] = {
		CATEGORY = t_CAT.COMBAT,
		NAME = "Look Distance",
		DESC = "The maximum distance the NPC can see. The same value affected by \"Long Visibility/Shoot\"",
		FUNCTION = { "Fire", "SetMaxLookDistance", "__VALUE" },
		TYPE = "number",
	},

	["force_approach"] = {
		CATEGORY = t_CAT.CHASE,
		NAME = "Always Seekout",
		DESC = "NPC will be forced to constantly seek out others. Cannot be interrupted",
		-- FUNCTION = {}, -- [[ ManageSchedules() ]]
		TYPE = "boolean",
		TESTFUNCTION = f_test_chase,
	},

	-- ["force_sched_go"] = {
	-- 	CATEGORY = t_CAT.CHASE,
	-- 	NAME = "Use \"Forced Go Run\" for NPC Chasing",
	-- 	DESC = "If true, then when managing NPC chasing, a different NPC schedule is used to force the NPC to move towards the target",
	-- 	-- FUNCTION = {}, -- [[ ManageSchedules() ]]
	-- 	TYPE = "boolean",
	-- },

	["idleout"] = {
		CATEGORY = t_CAT.CHASE,
		NAME = "Idle Timeout",
		DESC = "Overrides \"Idle Timeout\" ConVar (npcd Options > Scheduling). Duration before NPC is considered idle. Set to a negative to disable",
		TYPE = "number",
		TESTFUNCTION = f_test_chase,
	},

	["noidle"] = {
		CATEGORY = t_CAT.CHASE,
		NAME = "Disable Idle Seekout",
		DESC = "If true, disables manipulating the NPC when it idles out",
		TYPE = "boolean",
		TESTFUNCTION = f_test_chase,
	},

	["ignoreunseenenemies"] = {
		CATEGORY = t_CAT.BEHAVIOR,
		NAME = "Ignore unseen enemies",
		FUNCTION = { "SetKeyValue", "ignoreunseenenemies", "__VALUETOSTRING" },
		FUNCTION_GET = { "GetKeyValue", "ignoreunseenenemies" },
		TYPE = "boolean",
		ENUM = {
			["Ignore unseen enemies"] = true,
			["Do not ignore unseen enemies"] = false,
			-- ["Random"] = { table.Random, {true, false},},
		},
	},

	["long_range"] = {
		CATEGORY = t_CAT.COMBAT,
		NAME = "Long Visibility/Shoot",
		DESC = "Overrides \"Long Visibility/Shoot\" spawnflag",
		TYPE = "boolean",
		TESTFUNCTION = f_test_npcspawnflag,
		-- FUNCTION = {}, --[[ SpawnNPC() ]]
	},

	["dropweapon"] = {
		CATEGORY = t_CAT.COMBAT,
		NAME = "Drop Weapon On Death",
		DESC = "Overrides \"Don't drop weapons\" spawnflag",
		TYPE = "boolean",
		TESTFUNCTION = f_test_npcspawnflag,
		-- FUNCTION = {}, --[[ SpawnNPC() ]]
	},

	["moveact"] = {
		NAME = "Force Movement Act",
		CATEGORY = t_CAT.BEHAVIOR,
		-- FUNCTION = {}, --[[ DoActiveEffects() ]]
		ENUM_SORT = true,
		TYPE = { "enum", "int" },
		MIN = 0,
		MAX = LAST_SHARED_ACTIVITY,
		ENUM = t_enums["activity"],
		TESTFUNCTION = { "GetMovementActivity", "SetMovementActivity" },
	},

	["activity"] = {
		NAME = "Force Act",
		CATEGORY = t_CAT.BEHAVIOR,
		-- FUNCTION = {}, --[[ DoActiveEffects() ]]
		DESC = "Continuously forces the NPC to attempt this activity",
		LOOKUP_REROLL = true,
		ENUM_SORT = true,
		MIN = 0,
		MAX = LAST_SHARED_ACTIVITY,
		TYPE = { "enum", "int" },
		ENUM = t_enums["activity"],
		TESTFUNCTION = { "GetActivity", "SetActivity" },
	},

	["actdelay"] = {
		NAME = "Force Act Delay",
		CATEGORY = t_CAT.BEHAVIOR,
		DESC = "Delay between Force Act calls",
		LOOKUP_REROLL = true,
		TESTFUNCTION = { "GetActivity", "SetActivity" },
	},
	

	["damagefilter_hitbox_out"] = table.Copy( t_value_structs["damagefilter_hitbox"] ),
	["damagefilter_hitbox_in"] = table.Copy( t_value_structs["damagefilter_hitbox"] ),

	-- ["nocrouch"] = {
	-- 	-- FUNCTION = {}, --[[ DoActiveEffects() ]]
	-- 	TYPE = "boolean",
	-- },

	["relationships_outward"] = {
		CATEGORY = t_CAT.BEHAVIOR,
		NAME = "Relationships: Outward (Self's Feelings)",
		DESC = "Changes how this entity feels about others",
		TYPE = "struct",
		TESTFUNCTION = "AddEntityRelationship",
		STRUCT = {
			["by_class"] = {
				TYPE = "struct_table",
				STRUCT_TBLMAINKEY = "classname",
				STRUCT = {
					["classname"] = {
						DESC = "(player class is \"player\")",
						TYPE = { "preset", "string" },
						REQUIRED = true,
						PRESETS_ENTITYLIST = true,
					},
					["disposition"] = {
						REQUIRED = true,
						TYPE = "enum",
						ENUM = {
							-- ["Error"] = D_ER,
							["Hostile"] = 1,
							["Friendly"] = 3,
							["Fear"] = 2,
							["Neutral"] = 4,
						},
					},
					["priority"] = {
						TYPE = "number",
						MIN = 0,
						MAX = 99,
						DEFAULT = 50,
					},
				},
			},
			["by_preset"] = {
				TYPE = "struct_table",
				STRUCT_TBLMAINKEY = "preset",
				STRUCT = {
					["preset"] = {
						TYPE = "preset",
						PRESETS = {
							"npc",
							"entity",
							"nextbot",
							"squad",
							"player"
						},
						REQUIRED = true,
					},
					["disposition"] = {
						REQUIRED = true,
						TYPE = "enum",
						ENUM = {
							-- ["Error"] = D_ER,
							["Hostile"] = 1,
							["Friendly"] = 3,
							["Fear"] = 2,
							["Neutral"] = 4,
						},
					},
					["priority"] = {
						TYPE = "number",
						MIN = 0,
						MAX = 99,
						DEFAULT = 50,
					},
				},
			},
			["everyone"] = {
				DESC = "Excluding entities with the same squad preset",
				TYPE = "struct",
				STRUCT = {
					["exclude"] = {
						TYPE = "struct",
						STRUCT = {
							["by_preset"] = {
								TYPE = "table",
								TBLSTRUCT = {
									TYPE = "preset",
									PRESETS = {
										"npc",
										"entity",
										"nextbot",
										"squad",
										"player"
									},
								},
							},
							["by_class"] = {
								DESC = "(player class is \"player\")",
								TYPE = "table",
								TBLSTRUCT = {
									TYPE = { "preset", "string" },
									PRESETS_ENTITYLIST = true,
								},
							},
						},
					},
					["disposition"] = {
						REQUIRED = true,
						TYPE = "enum",
						ENUM = {
							-- ["Error"] = D_ER,
							["Hostile"] = 1,
							["Friendly"] = 3,
							["Fear"] = 2,
							["Neutral"] = 4,
						},
					},
					["priority"] = {
						TYPE = "number",
						MIN = 0,
						MAX = 99,
						DEFAULT = 50,
					},
				},
			},
			["self_squad"] = {
				DESC = "Including entities with the same squad preset",
				TYPE = "struct",
				STRUCT = {
					["exclude"] = nil,
					["disposition"] = {
						REQUIRED = true,
						TYPE = "enum",
						ENUM = {
							-- ["Error"] = D_ER,
							["Hostile"] = 1,
							["Friendly"] = 3,
							["Fear"] = 2,
							["Neutral"] = 4,
						},
					},
					["priority"] = {
						TYPE = "number",
						MIN = 0,
						MAX = 99,
						DEFAULT = 50,
					},
				},
			},
		},
	},

	["start_aware"] = { 
		CATEGORY = t_CAT.BEHAVIOR,
		-- FUNCTION = {}, --[[ SpawnNPC() ]]
		NAME = "Start Aware Of Player",
		DESC = "Send NPC towards nearest player on spawn",
		TYPE = "boolean",         
		-- DEFAULT = false,
		TESTFUNCTION = function(ent)
			local pass = false
			for _,f in ipairs( {"SetEnemy","SetTarget","SetLastPosition","SetSchedule"} ) do
				if isfunction( ent[f] ) then
					pass = true 
				end
			end
			if (pass) then
				return true
			else
				return false, "Missing all functions: SetEnemy, SetTarget, SetLastPosition, SetSchedule"
			end
		end,
	},

	["start_patrol"] = {
		CATEGORY = t_CAT.BEHAVIOR,
		FUNCTION = { "Fire", "StartPatrolling" },
		NAME = "Start Patrolling",
		DESC = "Calls NPC to patrol if possible",
		TYPE = "boolean", 
		FUNCTION_REQ = true,
		DEFAULT = true,
	},

	["spawnflags"] = {
		CATEGORY = t_CAT.MISC,
		TYPE = { "table", "int" },
		FUNCTION = { "AddSpawnFlag", "__VALUE" },
		DESC = "Sets exclusive features of an entity. Spawnflags differ depending on entity class. Enums may be wrong if entity is not an engine NPC",
		TBLSTRUCT = {
			TYPE = { "enum", "int" },
			ENUM = {
            ["Wait Till Seen"] = 1,
            ["Gag (No IDLE sounds until angry)"] = 2,
            ["Fall to ground (unchecked means *teleport* to ground)"] = 4,
            ["Drop Healthkit"] = 8,
            ["Efficient - Don't acquire enemies or avoid obstacles"] = 16,
            ["Long Visibility/Shoot"] = 256,
            ["Fade Corpse"] = 512,
            ["Think outside PVS"] = 1024,
				["Do Alternate collision for this NPC (player avoidance)"] = 4096,
				["Don't drop weapons"] = 8192,
				["Ignore player push"] = 16384,
			},
		},
	},

	["npc_state"] = {
		CATEGORY = t_CAT.BEHAVIOR,
		NAME = "NPC State",
		DESC = "The state the NPC is in, used by the engine to decide on an ideal schedule",
		TYPE = { "enum", "int" },
		FUNCTION = { "SetNPCState" , "__VALUE" },
		FUNCTION_GET = { "GetNPCState"  },
		ENUM = {
			["NPC_STATE_INVALID"] = -1,
			["NPC_STATE_NONE"] = 0,
			["NPC_STATE_IDLE"] = 1,
			["NPC_STATE_ALERT"] = 2,
			["NPC_STATE_COMBAT"] = 3,
			["NPC_STATE_SCRIPT"] = 4,
			["NPC_STATE_PLAYDEAD"] = 5,
			["NPC_STATE_PRONE"] = 6,
			["NPC_STATE_DEAD"] = 7,
		},
		DEFAULT = "NPC_STATE_COMBAT",
		TESTFUNCTION = {"GetNPCState","SetNPCState"},
		-- DEFAULT = 3,
	},

	["weapon_proficiency"] = {
		CATEGORY = t_CAT.COMBAT,
		TYPE = { "enum", "int" },
		FUNCTION = { "SetCurrentWeaponProficiency", "__VALUE" },
		FUNCTION_GET = { "GetCurrentWeaponProficiency" },
		ENUM = {
			["Poor"] = WEAPON_PROFICIENCY_POOR,
			["Average"] = WEAPON_PROFICIENCY_AVERAGE,
			["Good"] = WEAPON_PROFICIENCY_GOOD,
			["Very Good"] = WEAPON_PROFICIENCY_VERY_GOOD,
			["Perfect"] = WEAPON_PROFICIENCY_PERFECT,
		},
		TESTFUNCTION = {"GetCurrentWeaponProficiency","SetCurrentWeaponProficiency"},
	},

	["weapon_set"] = {
		CATEGORY = t_CAT.REQUIRED,
		DESC = "Equips a weapon set preset. Weapon sets allow for random weapon choices and greater customization",
		-- FUNCTION = {}, --[[ SpawnNPC() ]]
		TYPE = "preset",
		PRESETS = { "weapon_set" },
		SORTNAME = "weapona",
	},
	["weapon"] = {
		CATEGORY = t_CAT.REQUIRED,
		DESC = "Equips a weapon, simply",
		TYPE = { "preset", "string" }, 
		PRESETS_ENTITYLIST = true,
		CANCLASS = false,
		SORTNAME = "weaponb",
	},

	["weapon_inherit"] = {
		CATEGORY = t_CAT.VISUAL,
		NAME = "Weapon Inherits Values",
		DESC = "The NPC's weapon will inherit some visual values if not already set on the weapon. Includes: alpha, startalpha, scale, color, rendermode, renderfx, material, and jiggle",
		TYPE = "boolean",
		DEFAULT = true,
	},
}

t_player_values = {
	["entity_type"] = {
		TYPE = "data",
		DEFAULT = "player",
		DEFAULT_SAVE = true,
	},
	["expected"] = table.Copy( t_value_structs["expected"] ),
	["condition_forced"] = {
		CATEGORY = t_CAT.REQUIRED,
		TYPE = "struct",
		DESC = "Includes conditions which will FORCE this preset onto the player on spawn if passed. Will be applied even if normal conditions fail, and will not fail the normal condition if not passed",
		STRUCT = {
			["infected_previous"] = {
					TYPE = "boolean",
					DESC = "If true, FORCE this preset if the player has been this preset previously",
				},
			["infected_cure"] = {
				TYPE = "enum",
				DESC = "Players will be cleared (cured) from being forced into this preset based on the given condition",
				ENUM = {
					["Died"] = 1,
					["Killed"] = 2,
					["Killed By Non-Infected"] = 3,
					["Killed By Non-Infected Player"] = 4,
					["Killed By Infected"] = 5,
				},
			},
			["infected"] = {
				DESC = "If set, FORCE this preset on players killed by any of these presets",
				TYPE = "table",
				TBLSTRUCT = {
					TYPE = "preset",
					PRESETS = {
						"npc",
						"entity",
						"nextbot",
						"player",
					},
				},
			},
		},
	},
	["weapon_sets"] = {
		CATEGORY = t_CAT.REQUIRED,
		-- FUNCTION = {}, --[[ SpawnNPC() ]]
		TYPE = "table",
		TBLSTRUCT = {
			TYPE = "preset",
			PRESETS = { "weapon_set" },
		},
	},
	["condition"] = {
		CATEGORY = t_CAT.REQUIRED,
		DESC = "If included, the player must pass the conditions inside any condition set for this preset to be appliable on spawn",
		TYPE = "struct_table",
		STRUCT = {
			["steamid"] = {
				DESC = "Player must have any of these SteamIDs. Uses the player's 64-bit SteamID aka CommunityID.",
				TYPE = "table",
				TBLSTRUCT = {
					TYPE = "number",
				},
			},
			["admin"] = { --[[ IsAdmin, !IsSuperAdmin ]]
				DESC = "Specifically admins, not superadmins. True to include, false to exclude",
				TYPE = "boolean",
			},
			["superadmin"] = { --[[ IsSuperAdmin ]]
				DESC = "True to include, false to exclude",
				TYPE = "boolean",
			},
			["nonadmin"] = {
				DESC = "Neither admin nor superadmin. True to include, false to exclude",
				TYPE = "boolean",
			},
			["deaths_lessthan"] = { --[[ Deaths() ]]
				TYPE = "int",
			},
			["deaths_greaterthan"] = {
				TYPE = "int",
			},
			["kills_lessthan"] = { --[[ Frags() ]]
				TYPE = "int",
			},
			["kills_greaterthan"] = {
				TYPE = "int",
			},
			["hasgodmode"] = { --[[ HasGodMode() ]]
				DESC = "True to include, false to exclude",
				TYPE = "boolean",
			},
			["preset_max"] = {
				DESC = "Max number of this preset allowed at a time",
				TYPE = "int",
			},
			["isbot"] = { --[[ IsBot ]]
				DESC = "True for bots only, false for real players only",
				TYPE = "boolean",
			},
			["nepotism"] = { --[[ GetFriendStatus() ]]
				DESC = "Player is friends with the server account. True to include, false to exclude",
				TYPE = "boolean",
			},
			["listenhost"] = { --[[ IsListenServerHost() ]]
				DESC = "Player is hosting the server locally. True to include, false to exclude",
				TYPE = "boolean",
			},
			["usergroups"] = { --[[ IsUserGroup, GetUserGroup ]]
				TYPE = "table",
				TBLSTRUCT = {
					TYPE = "string",
				},
			},
			["teams"] = {
				DESC = "Team IDs",
				TYPE = "table",
				TBLSTRUCT = {
					TYPE = "int",
				},
			},
			["killed_by_presets"] = {
				TYPE = "struct",
				DESC = "Include/exclude players killed by any of these presets",
				STRUCT = {
					["include"] = {
						TYPE = "table",
						TBLSTRUCT = {
							TYPE = "preset",
							PRESETS = {
								"npc",
								"entity",
								"nextbot",
								"player",
							},
						},
					},
					["exclude"] = {
						TYPE = "table",
						TBLSTRUCT = {
							TYPE = "preset",
							PRESETS = {
								"npc",
								"entity",
								"nextbot",
								"player",
							},
						},
					},
				},
			},
		},
	},
	["armor"] = {
		CATEGORY = t_CAT.HEALTH,
		FUNCTION = { "SetArmor", "__VALUE" },
		FUNCTION_GET = { "Armor" },
	},
	["maxarmor"] = {
		CATEGORY = t_CAT.HEALTH,
		FUNCTION = { "SetMaxArmor", "__VALUE" },
		FUNCTION_GET = { "GetMaxArmor" },
	},

	["damagefilter_hitbox_out"] = table.Copy( t_value_structs["damagefilter_hitbox"] ),
	["damagefilter_hitbox_in"] = table.Copy( t_value_structs["damagefilter_hitbox"] ),

	["weapons_in_vehicle"] = {
		CATEGORY = t_CAT.COMBAT,
		NAME = "Weapons In Vehicle Allowed",
		TYPE = "boolean",
		FUNCTION = { "SetAllowWeaponsInVehicle", "__VALUE" },
		FUNCTION_GET = { "GetAllowWeaponsInVehicle" },
	},
	["dropweapon"] = {
		CATEGORY = t_CAT.COMBAT,
		NAME = "Drop Weapon On Death",
		TYPE = "boolean",
		FUNCTION = { "ShouldDropWeapon", "__VALUE" },
	},
	["fullrotation"] = {
		CATEGORY = t_CAT.MOVEMENT,
		NAME = "Player Model Rotates On All Axis",
		TYPE = "boolean",
		FUNCTION = { "SetAllowFullRotation", "__VALUE" },
		FUNCTION_GET = { "GetAllowFullRotation" },
	},
	["jumppower"] = {
		CATEGORY = t_CAT.MOVEMENT,
		NAME = "Jump Power",
		FUNCTION = { "SetJumpPower", "__VALUE" },
		TYPE = "number",
		FUNCTION_GET = { "GetJumpPower" },
	},
	["fov"] = {
		CATEGORY = t_CAT.VISUAL,
		NAME = "FOV",
		FUNCTION = { "SetFOV", "__VALUE" },
		FUNCTION_GET = { "GetFOV" },
		REVERT = false,
		TYPE = "number",
	},
	["crouchwalkspeed"] = {
		CATEGORY = t_CAT.MOVEMENT,
		NAME = "Crouch Speed Mult",
		FUNCTION = { "SetCrouchedWalkSpeed", "__VALUE" },
		FUNCTION_GET = { "GetCrouchedWalkSpeed" },
		TYPE = "number",
		MAX = 1,
	},
	["ladderspeed"] = {
		CATEGORY = t_CAT.MOVEMENT,
		NAME = "Ladder Speed",
		FUNCTION = { "SetLadderClimbSpeed", "__VALUE" },
		FUNCTION_GET = { "GetLadderClimbSpeed" },
		TYPE = "number",
	},
	["runspeed"] = {
		CATEGORY = t_CAT.MOVEMENT,
		NAME = "Run Speed",
		FUNCTION = { "SetRunSpeed", "__VALUE" },
		FUNCTION_GET = { "GetRunSpeed" },
		TYPE = "number",
	},
	["walkspeed"] = {
		CATEGORY = t_CAT.MOVEMENT,
		NAME = "Walk Speed",
		FUNCTION = { "SetWalkSpeed", "__VALUE" },
		FUNCTION_GET = { "GetWalkSpeed" },
		TYPE = "number",
	},
	["slowwalkspeed"] = {
		CATEGORY = t_CAT.MOVEMENT,
		NAME = "Slow Walk Speed",
		FUNCTION = { "SetSlowWalkSpeed", "__VALUE" },
		FUNCTION_GET = { "GetSlowWalkSpeed" },
		TYPE = "number",
	},
	["playercolor"] = {
		CATEGORY = t_CAT.VISUAL,
		NAME = "Player Color",
	 	-- FUNCTION = { "SetPlayerColor", "__VALUE" }, // Color to Vector with a 0-1 range
	 	FUNCTION_GET = { "GetPlayerColor" }, // Color to Vector with a 0-1 range
		REVERT = false,
		TYPE = "color",
	},
	["weaponcolor"] = {
		CATEGORY = t_CAT.VISUAL,
		NAME = "Player Weapon Color",
		-- FUNCTION = { "SetWeaponColor", "__VALUE" },
		FUNCTION_GET = { "GetWeaponColor" },
		REVERT = false,
		TYPE = "color",
	},
	["maxspeed"] = {
		CATEGORY = t_CAT.MOVEMENT,
		NAME = "Max Speed",
		FUNCTION = { "SetMaxSpeed", "__VALUE" },
		FUNCTION_GET = { "GetMaxSpeed" },
		TYPE = "number",
	},
	["stepheight"] = {
		CATEGORY = t_CAT.MOVEMENT,
		NAME = "Step Height",
		FUNCTION = { "SetStepSize", "__VALUE" },
		FUNCTION_GET = { "GetStepSize" },
		TYPE = "number",
	},
	["laggedmove"] = {
		CATEGORY = t_CAT.MOVEMENT,
		NAME = "Movement Timescale",
		FUNCTION = { "SetLaggedMovementValue", "__VALUE" },
		FUNCTION_GET = { "GetLaggedMovementValue" },
		TYPE = "number",
	},
	["duckspeed"] = {
		CATEGORY = t_CAT.MOVEMENT,
		NAME = "Duck Speed",
		FUNCTION = { "SetDuckSpeed", "__VALUE" },
		FUNCTION_GET = { "GetDuckSpeed" },
		TYPE = "number",
		MAX = 1,
	},
	["unduckspeed"] = {
		CATEGORY = t_CAT.MOVEMENT,
		NAME = "Unduck Speed",
		FUNCTION = { "SetUnDuckSpeed", "__VALUE" },
		FUNCTION_GET = { "GetUnDuckSpeed" },
		TYPE = "number",
	},
	["canwalk"] = {
		CATEGORY = t_CAT.MOVEMENT,
		NAME = "Can Walk",
		FUNCTION = { "SetCanWalk", "__VALUE" },
		FUNCTION_GET = { "GetCanWalk" },
		TYPE = "boolean",
	},
	["canzoom"] = {
		CATEGORY = t_CAT.BEHAVIOR,
		NAME = "Can Zoom",
		FUNCTION = { "SetCanZoom", "__VALUE" },
		FUNCTION_GET = { "GetCanZoom" },
		TYPE = "boolean",
	},
	["canflashlight"] = {
		CATEGORY = t_CAT.EQUIP,
		NAME = "Can Flashlight",
		FUNCTION = { "AllowFlashlight", "__VALUE" },
		TYPE = "boolean",
	},
	["freeze"] = {
		NAME = "Freeze",
		CATEGORY = t_CAT.MOVEMENT,
		FUNCTION = { "Freeze", "__VALUE" },
		TYPE = "boolean",
	},
	["flashlight"] = {
		CATEGORY = t_CAT.EQUIP,
		NAME = "Flashlight Starts On",
		FUNCTION = { "Flashlight", "__VALUE" },
		TYPE = "boolean",
	},
	["suit"] = {
		CATEGORY = t_CAT.EQUIP,
		NAME = "HEV Suit",
		DESC = "True to give, false to remove",
		FUNCTION = { "EquipSuit" },
		FUNCTION_NOT = { "RemoveSuit" },
		FUNCTION_GET = { "IsSuitEquipped" }, // is false at init spawn
		REVERT = false,
		FUNCTION_REQ = true,
		FUNCTION_REQ_NOT = false,
		TYPE = "boolean",
	},
	["suitpower"] = {
		CATEGORY = t_CAT.EQUIP,
		NAME = "Hev Suit Power",
		DESC = "Default is 100",
		FUNCTION = { "SetSuitPower", "__VALUE" },
		FUNCTION_GET = { "GetSuitPower" },
		REVERT = false,
		TYPE = "number",
	},
	["godmode"] = {
		CATEGORY = t_CAT.HEALTH,
		NAME = "God Mode",
		FUNCTION = { "GodEnable" },
		FUNCTION_NOT = { "GodDisable" },
		FUNCTION_GET = { "HasGodMode" },
		FUNCTION_REQ = true,
		FUNCTION_REQ_NOT = false,
		TYPE = "boolean",
	},
	["crosshair"] = {
		CATEGORY = t_CAT.VISUAL,
		NAME = "Crosshair",
		DESC = "False to disable",
		FUNCTION = { "CrosshairEnable" },
		FUNCTION_NOT = { "CrosshairDisable" },
		FUNCTION_REQ = true,
		FUNCTION_REQ_NOT = false,
		TYPE = "boolean",
	},
}

t_nextbot_base_values = {}
t_nextbot_class_values = {}

t_npc_class_values = {
   ["npc_turret_ceiling"] = {
      ["spawnflags"] = {
			DESC = spawnflags_desc,
			FUNCTION = { "AddSpawnFlag", "__VALUE" },
			TYPE = { "table", "int" },
			TBLSTRUCT = {
				TYPE = { "enum", "int" },
				ENUM = {
               ["Autostart"] = 32,
               ["Start Inactive"] = 64,
               ["Fast Retire"] = 128,
               ["Out of Ammo"] = 256,
				},
			},
		},
      ["turret_ceiling_autostart"] = {
         NAME = "Turret Autostart",
         DESC = "Activates turret on spawn. Sets \"Autostart\" spawnflag",
			FUNCTION = { "AddSpawnFlag", 32 },
			TYPE = "boolean",
         DEFAULT = true,
         FUNCTION_REQ = true,
      },
   },
   ["npc_combine_camera"] = {
      ["spawnflags"] = {
			DESC = spawnflags_desc,
			FUNCTION = { "AddSpawnFlag", "__VALUE" },
			TYPE = { "table", "int" },
			TBLSTRUCT = {
				TYPE = { "enum", "int" },
				ENUM = {
               ["Always Become Angry On New Enemy"] = 32,
               ["Ignore Enemies (Scripted Targets Only)"] = 64,
               ["Start Inactive"] = 128,
				},
			},
		},
   },
	["npc_combine_s"] = {
		["tacticalvariant"] = { 
			FUNCTION = { "SetKeyValue", "tacticalvariant", "__VALUETOSTRING" },
			FUNCTION_GET = { "GetKeyValue", "tacticalvariant" },
			TYPE = { "enum", "int" },
			-- MIN = 0,
			-- MAX = 2,
			ENUM = {
				["Normal Tactics"] = 0,
				["Pressure the enemy (Keep advancing)"] = 1,
				["Pressure until within 30ft, then normal"] = 2,
				-- ["Random"] = { math.random, 0, 2 },
			},
		},
		["spawnflags"] = {
			DESC = spawnflags_desc,
			FUNCTION = { "AddSpawnFlag", "__VALUE" },
			TYPE = { "table", "int" },
			TBLSTRUCT = {
				TYPE = { "enum", "int" },
				ENUM = {
					["Start LookOff"] = 65536,
					["Don't drop grenades"] = 131072,
					["Don't drop AR2 alt fire (Elite only)"] = 262144,
				},
			},
		},
		["numgrenades"] = {
			TYPE = "int",
			FUNCTION = { "SetKeyValue", "numgrenades", "__VALUETOSTRING" },
		},
		["soldiertype"] = {
			TYPE = "enum",
			ENUM = {
				["Normal"] = "Normal",
				["Elite"] = "Elite",
				["Prison"] = "Prison",
			},
			FUNCTION_TABLE = {
				["Normal"] = { "SetModel", "models/combine_soldier.mdl" },
				["Elite"] = { "SetModel", "models/combine_super_soldier.mdl" },
				["Prison"] = { "SetModel", "models/combine_soldier_prisonguard.mdl" },
			},
		},
		["childpreset"] = {
			NAME = "Grenade Preset",
			DESC = "Override Combine Soldier's thrown grenade with a preset (WIP, will override all grenades (including yours) thrown near the entity)",
			TYPE = { "preset" },
			PRESETS = {
				"npc",
				"entity",
			},
			SORTNAME = "zzzza",
		},
		["childpreset_replace"] = {
			NAME = "Replace Grenade Entity",
			DESC = "If true, completely replace the thrown grenade with a new entity instead of overriding it",
			TYPE = "boolean",
			SORTNAME = "zzzzb",
		},
	},
	["npc_metropolice"] = {
		["manhacks"] = {
			TYPE = "int",
			FUNCTION = { "SetKeyValue", "manhacks", "__VALUETOSTRING" },
			FUNCTION_GET = { "GetKeyValue", "manhacks" },
			FUNCTION_NOT = { "AddSpawnFlag", 8388608 }, // Prevent manhack toss spawnflag
			FUNCTION_REQ_NOT = 0,
		},
		["weapondrawn"] = {
			FUNCTION = { "SetKeyValue", "weapondrawn", "__VALUETOSTRING" },
			FUNCTION_GET = { "GetKeyValue", "weapondrawn" },
			TYPE = "boolean",
		},
		["spawnflags"] = {
			DESC = spawnflags_desc,
			FUNCTION = { "AddSpawnFlag", "__VALUE" },
			TYPE = { "table", "int" },
			TBLSTRUCT = {
				TYPE = { "enum", "int" },
				ENUM = {
					["Simple cops"] = 131072,
					["Rappel <Obsolete>"] = 262144,
					["Always stitch"] = 524288,
					["No chatter"] = 1048576,
					["Arrest enemies"] = 2097152,
					["No far stitching"] = 4194304,
					["Prevent manhack toss"] = 8388608,
					["Allowed to respond to thrown objects"] = 16777216,
					["Mid-range attacks (halfway between normal + long-range)"] = 33554432,
				},
			},
		},
		["childpreset"] = {
			NAME = "Manhack Preset",
			DESC = "Override Metropolice's Manhack with a preset",
			TYPE = { "preset" },
			PRESETS = {
				"npc",
				"entity",
			},
		},
		["childpreset_replace"] = {
			NAME = "Replace Manhack Entity",
			DESC = "If true, completely replace the deployed manhack with a new entity instead of overriding it. This is useful for making the manhack start unpacked",
			TYPE = "boolean",
		},
		["inheritscale"] = {
			TYPE = "boolean",
			DESC = "Manhack inherits scale",
		},
	},
	["npc_citizen"] = {
		["citizentype"] = {
			FUNCTION = { "SetKeyValue", "citizentype", "__VALUETOSTRING" },
			FUNCTION_GET = { "GetKeyValue", "citizentype" },
			TYPE = { "enum", "int" },
			ENUM = {
				["Default"] = 0,
				["Downtrodden"] = 1,
				["Refugee"] = 2,
				["Rebel"] = 3,
				["Unique"] = 4,
			},
		},
		["spawnflags"] = {
			DESC = spawnflags_desc,
			FUNCTION = { "AddSpawnFlag", "__VALUE" },
			TYPE = { "table", "int" },
			TBLSTRUCT = {
				TYPE = { "enum", "int" },
				ENUM = {
					["Ammo Resupplier"] = 524288,
					["Don't use speech semaphore"] = 2097152,
					["Follow player on spawn"] = 65536,
					["Medic"] = 131072,
					["Not Commandable"] = 1048576,
					["Random Head"] = 262144,
					["Random female head"] = 8388608,
					["Random male head"] = 4194304,
					["Use RenderBox in ActBusies"] = 16777216,
				},
			},
		},
	},
	["npc_turret_floor"] = {
		["selfdestruct"] = {
			DESC = "Turret self destructs when deactivated",
			TYPE = "boolean",
			FUNCTION = { "Fire", "AddOutput" , "OnTipped !self:SelfDestruct::0:-1" },
			FUNCTION_REQ = true,
		},
	},
	["npc_antlion"] = {
		["spawnflags"] = {
			DESC = spawnflags_desc,
			FUNCTION = { "AddSpawnFlag", "__VALUE" },
			TYPE = { "table", "int" },
			TBLSTRUCT = {
				TYPE = { "enum", "int" },
				ENUM = {	
					["Burrow when eluded"] = 65535,
					["Use Ground Checks"] = 131072,
					["Worker Type"] = 262144
				},	
			},		
		},
	},
	["npc_headcrab"] = {
		["spawnflags"] = {
			DESC = spawnflags_desc,
			FUNCTION = { "AddSpawnFlag", "__VALUE" },
			TYPE = { "table", "int" },
			TBLSTRUCT = {
				TYPE = { "enum", "int" },
				ENUM = {
					["Start hidden"] = 65536,
					["Start hanging from ceiling"] = 131072,
				},
			},
		},
	},
	["npc_headcrab_fast"] = {
		["spawnflags"] = {
			DESC = spawnflags_desc,
			FUNCTION = { "AddSpawnFlag", "__VALUE" },
			TYPE = { "table", "int" },
			TBLSTRUCT = {
				TYPE = { "enum", "int" },
				ENUM = {
					["Start hidden"] = 65536,
					["Start hanging from ceiling"] = 131072,
				},
			},
		},
	},
	["npc_headcrab_black"] = {
		["spawnflags"] = {
			DESC = spawnflags_desc,
			FUNCTION = { "AddSpawnFlag", "__VALUE" },
			TYPE = { "table", "int" },
			TBLSTRUCT = {
				TYPE = { "enum", "int" },
				ENUM = {
					["Start hidden"] = 65536,
					["Start hanging from ceiling"] = 131072,
				},
			},
		},
	},
	["npc_poisonzombie"] = {
		["childpreset"] = {
			NAME = "Thrown Headcrab Preset",
			DESC = "Override any thrown headcrabs with a preset",
			TYPE = { "preset" },
			PRESETS = {
				"npc",
				"entity",
			},
		},
		["childpreset_replace"] = {
			NAME = "Replace Headcrab Entity",
			DESC = "If true, completely replace the thrown headcrab with a new entity instead of overriding it",
			TYPE = "boolean",
		},
		["inheritscale"] = {
			TYPE = "boolean",
			DESC = "Thrown headcrab inherits scale",
		},
		-- ["spawnflags"] = {
		-- 	DESC = spawnflags_desc,
		-- 	FUNCTION = { "AddSpawnFlag", "__VALUE" },
		-- 	TYPE = { "table", "int" },
		-- 	TBLSTRUCT = {
		-- 		TYPE = { "enum", "int" },
		-- 		ENUM = {
		-- 			["Start hidden"] = 65536,
		-- 			["Start hanging from ceiling"] = 131072,
		-- 		},
		-- 	},
		-- },
	},
	["npc_barnacle"] = {
		["spawnflags"] = {
			DESC = spawnflags_desc,
			FUNCTION = { "AddSpawnFlag", "__VALUE" },
			TYPE = { "table", "int" },
			TBLSTRUCT = {
				TYPE = { "enum", "int" },
				ENUM = {
					["Cheap death"] = 65536,
					["Ambush Mode"] = 131072,
				},
			},
		},
      ["fix_prespawn"] = { //PreEntitySpawn()
         NAME = "Entity-Specific Fixes",
         TYPE = "boolean",
         DESC = "npc_barnacle: Adjust position down by 2 units (same fix used in Gmod spawnmenu)",
         DEFAULT = true,
         FUNCTION = { function( self )
            self:SetPos( self:GetPos() + Vector( 0, 0, -2 ) )
         end, "__SELF" },
         FUNCTION_REQ = -1, // Don't actually call the function when resolving value list
      },
	},
	["npc_cscanner"] = {
		["spawnflags"] = {
			DESC = spawnflags_desc,
			FUNCTION = { "AddSpawnFlag", "__VALUE" },
			TYPE = { "table", "int" },
			TBLSTRUCT = {
				TYPE = { "enum", "int" },
				ENUM = {
					["No Dynamic Light"] = 65536,
					["Strider Scout Scanner"] = 131072,
				},
			},
		},
	},
	["npc_vortigaunt"] = {
		["inputs"] = { -- [[ PostEntitySpawn() ]]
         NAME = "Inputs",
         CATEGORY = t_CAT.MISC,
         DESC = "Entity I/O, using Entity:Fire()",
         TYPE = "struct_table",
         STRUCT = {
            ["command"] = {
               TYPE = "string",
               REQUIRED = true,
               ENUM = {
                  ["EnableArmorRecharge"] =  "EnableArmorRecharge" ,
                  ["DisableArmorRecharge"] =  "DisableArmorRecharge" ,
                  ["EnableHealthRegeneration"] =  "EnableHealthRegeneration" ,
                  ["DisableHealthRegeneration"] =  "DisableHealthRegeneration" ,
                  ["TurnBlue"] =  "TurnBlue",
                  ["TurnBlack"] =  "TurnBlack",
               },
			   },
            ["value"] = {
               DESC = "The value to send with the command",
               TYPE = { "string", "int", "number", "boolean" },
            },
            ["delay"] = {
               DESC = "In seconds",
               TYPE = "number",
            },
		   },
	   },
   },
}

t_weapon_values = {
	["entity_type"] = {
		TYPE = "data",
		DEFAULT = "weapon",
		-- DEFAULT_SAVE = true,
	},
    ["expected"] = table.Copy( t_value_structs["expected"] ),
	["chance"] = table.Copy( t_value_structs["chance"] ),
	["giveammo_primary"] = {
		CATEGORY = t_CAT.EQUIP,
		TYPE = "int",
		DESC = "Only applies when being given to players. Gives this much extra primary ammo",
		MIN = 0,
	},
	["giveammo_secondary"] = {
		CATEGORY = t_CAT.EQUIP,
		TYPE = "int",
		DESC = "Only applies when being given to players. Gives this much extra secondary ammo",
		MIN = 0,
	},
	["clip_primary"] = {
		CATEGORY = t_CAT.EQUIP,
		FUNCTION = { "SetClip1", "__VALUE" },
		FUNCTION_GET = { "Clip1" },
		TYPE = "int",
		DESC = "Sets the weapon's initial primary clip",
	},
	["clip_secondary"] = {
		CATEGORY = t_CAT.EQUIP,
		FUNCTION = { "SetClip2", "__VALUE" },
		FUNCTION_GET = { "Clip2" },
		TYPE = "int",
		DESC = "Sets the weapon's initial secondary clip",
	},
}

t_weapon_set_values = {
	["weapons"] = {
		CATEGORY = t_CAT.EQUIP,
        TYPE = "struct_table",
		STRUCT_TBLMAINKEY = "classname",
		STRUCT = t_weapon_values,
		DEFAULT = {},
		NOFUNC = true,
		SORTNAME = "a",
    },
	["override_soft"] = {
		DESC = "Only adds included values if they don't already exist",
		CATEGORY = t_CAT.OVERRIDE,
		TYPE = "struct",
		STRUCT = {
			["weapon"] = {
				TYPE = "struct",
				STRUCT = t_weapon_values,
			},
		},
	},
	["override_hard"] = {
		DESC = "Overwrites included values on all weapons",
		CATEGORY = t_CAT.OVERRIDE,
		TYPE = "struct",
		STRUCT = {
			["weapon"] = {
				TYPE = "struct",
				STRUCT = t_weapon_values,
			},
		},
	},
	["giveall"] = {
		CATEGORY = t_CAT.EQUIP,
		NAME = "Give All",
        TYPE = "boolean",
	},
	["removeall"] = {
		CATEGORY = t_CAT.EQUIP,
		NAME = "Remove Existing Weapons",
		TYPE = "boolean",
	},
	["exclude"] = {
		CATEGORY = t_CAT.NPCD,
		NAME = "Exclude",
		TYPE = "enum",
		DESC = "If set, weapon set cannot be given to this type of entity",
		ENUM = {
			["player"] = "player",
			["npc"] = "npc",
			["all"] = "all",
		},
	},
}

t_squad_values = {
    ["spawnlist"] = {
		CATEGORY = t_CAT.REQUIRED,
        -- -- FUNCTION = {}, --[[ GenerateSquad() ]]
		NAME = "Squad",
        TYPE = "struct_table",
		STRUCT_TBLMAINKEY = "preset",
		REQUIRED = true,
		STRUCT = {
			["preset"] = {
				NAME = "Preset",
				REQUIRED = true,
				TYPE = "preset",
				PRESETS = {
					"npc",
					"entity",
					"nextbot",
				},
			},
			["count"] = {
				NAME = "Count",
				TYPE = "struct",
				STRUCT = {
					["min"] = {
						SORTNAME = "a",
						TYPE = "number",
						-- MIN = 0,
						-- REQUIRED = true,
						DEFAULT = 1,
					},
					["median"] = {
						DESC = "Only used if included",
						SORTNAME = "b",
						TYPE = "number",
					},
					["max"] = {
						SORTNAME = "c",
						TYPE = "number",
						-- REQUIRED = true,
						DEFAULT = 1,
					},
				},
				DEFAULT = {
					["min"] = 1,
					["max"] = 1,
				},
				-- REQUIRED = true,
			},
			["chance"] = {
				NAME = "Chance",
				DESC = "If given, rolls the chance for this spawn",
				TYPE = "fraction",
			},
		},
    },
	["spawnfix"] = {
		CATEGORY = t_CAT.SPAWN,
      NAME = "Hold Position During Spawn",
		DESC = "Force entities spawned to stay affixed to their spawn position until squad is fully spawned.",
		TYPE = "boolean",
		-- DEFAULT = false,
	},
	["spawnforce"] = { 
		CATEGORY = t_CAT.PHYSICAL,
		NAME = "Spawn Velocity",
        -- -- FUNCTION = {}, --[[ GenerateSquad() ]]
		DESC = "Random horizontal spawn velocity",
        TYPE = "struct",
		STRUCT = {
			["forward"] = {
				DEFAULT = { "__RAND", 300, 600 },
				LOOKUP_REROLL = true,
			},
			["up"] = {
				DEFAULT = -5,
				LOOKUP_REROLL = true,
			},
			["rotrandom"] = {
				TYPE = "boolean",
				DESC = "If true, force angle is random",
				DEFAULT = true,
			},
		},
        DEFAULT = {
			["forward"] = { "__RAND", 300, 600 },
			["up"] = -5,
			["rotrandom"] = true,
			["LOOKUP_REROLL"] = {
				["forward"] = true,
			},
		},
    },
	["squadname"] = {
		NAME = "Use Specific Squad Name",
		CATEGORY = t_CAT.MISC,
		TYPE = "string",
	},
	["hivequeen"] = {
		CATEGORY = t_CAT.BEHAVIOR,
		NAME = "Hivequeen",
		DESC = "If enabled, this preset becomes the \"queen\" of the squad, and all squad \"servants\" will die if the queen dies",
		-- -- FUNCTION = {}, --[[ hook.Add("OnNPCKilled") ]]
		TYPE = "preset",
		PRESETS = { "npc", "entity", "nextbot" },
	},
	["hivequeen_mutual"] = {
		CATEGORY = t_CAT.BEHAVIOR,
		NAME = "Hivequeen: Mutual Dependence",
		DESC = "If enabled, the hivequeen will die when all the servants are dead. This is in addition to the normal behavior when the queen dies",
		-- -- FUNCTION = {}, --[[ hook.Add("OnNPCKilled") ]]
		TYPE = "boolean",
	},
	["hivequeen_maxdist"] = {
		CATEGORY = t_CAT.BEHAVIOR,
		NAME = "Hivequeen: Max Distance From Queen Allowed",
		DESC = "Servant will immediately die if greater than this distance away from the queen",
		-- -- FUNCTION = {}, --[[ DoActiveEffects() ]]
		MIN = 0,
	},
	["hiverope"] = {
		CATEGORY = t_CAT.BEHAVIOR,
		NAME = "Hivequeen: Rope Effect",
		-- -- FUNCTION = {}, --[[ Direct() ]]
		TYPE = "struct_table",
		STRUCT_TBLMAINKEY = "material",
		STRUCT = {
			["attachment_queen"] = {
				DESC = "Attachment id. Set to 0 to use the entity's position",
				DEFAULT = 3,
			},
			["attachment_servant"] = {
				DESC = "Attachment id. Set to 0 to use the entity's position",
				DEFAULT = 1,
			},
			["width"] = {
				DEFAULT = 5,
			},
			["material"] = {
				TYPE = "string",
				DEFAULT = "cable/physbeam",
				ASSET = "materials",
			},
			-- ["color"] = {
			-- 	TYPE = "color",
			-- },
		}
	},
	["mapmax"] = {
		NAME = "Map Max",
		CATEGORY = t_CAT.NPCD,
		DESC = "Max amount of this squad allowed on the map at once",
		-- -- FUNCTION = {}, --[[ Direct() ]]
	},
	["mapmin"] = {
		NAME = "Map Min",
		CATEGORY = t_CAT.NPCD,
		DESC = "Prioritize spawning this squad if there are less than this amount on the map",
		-- -- FUNCTION = {}, --[[ Direct() ]]
	},
	["mindelay"] = {
		CATEGORY = t_CAT.NPCD,
		DESC = "Minimum delay between spawns. If function, rerolls every time it is called",
		-- -- FUNCTION = {}, --[[ Direct() ]]
	},
	-- ["maxdelay"] = {
	-- 	-- -- FUNCTION = {}, --[[ Direct() ]]
	-- },
	["nocollide"] = {
		CATEGORY = t_CAT.PHYSICAL,
      NAME = "No Collide",
		DESC = "Entities in this squad will always not collide with each other",
		TYPE = "boolean",
	},
	["spawncollide_time"] = {
		CATEGORY = t_CAT.PHYSICAL,
      NAME = "Spawn Collision Min Duration",
		DESC = "Minimum time in seconds for spawned entities to stay in a no-collision state. After spawning, entities will only return to normal collision when they are not stuck in anything",
		TYPE = "number",
      DEFAULT = 1,
	},
	["spawncollide_fast"] = {
		CATEGORY = t_CAT.PHYSICAL,
      NAME = "Spawn Collision Fast End",
		DESC = "If true, entities in this squad will return to normal collision after spawning without checking if they are still stuck in anyone",
		TYPE = "boolean",
	},
	["spawngrid"] = {
		CATEGORY = t_CAT.SPAWN,
		NAME = "Spawn In Grid",
		DESC = "Spawned are placed in a grid. Defaults to true if a nextbot is in the squad",
		TYPE = "boolean",
	},
	["spawngrid_gap"] = {
		CATEGORY = t_CAT.SPAWN,
		NAME = "Spawn In Grid: Gap",
		DESC = "Offset between entities in the grid. Defaults to \"Spawn Grid Default Gap\" ConVar (see: npcd Options > Spawning)",
		TYPE = "number",
	},
	["fadein"] = {
		NAME = "Fade In",
		DESC = "Enable/disable spawns fading in",
		CATEGORY = t_CAT.SPAWN,
		TYPE = "boolean",
		DEFAULT = true,
	},
	["fadein_nodelay"] = {
		NAME = "Fade In Immediately",
		DESC = "Starts each fade-in immediately after being spawned, not waiting until entity has \"settled\"",
		CATEGORY = t_CAT.SPAWN,
		TYPE = "boolean",
	},

	["spawn_req_water"] = {
		NAME = "Spawn Requires Water",
		CATEGORY = t_CAT.SPAWN,
      DESC = "Water level required for Auto-Spawner to spawn entire squad. Note: Individual entities' water spawn requirements are ignored when spawned in a squad",
		TYPE = "enum",
		ENUM = {
			["Any"] = -1,
			["Disallow water"] = 0,
			["Water only"] = 1,
		},
		DEFAULT = "Disallow water",
	},
	["spawn_req_navmesh"] = {
		CATEGORY = t_CAT.SPAWN,
		NAME = "Spawn Requires Map Navmesh",
		DESC = "Map must have navmeshes for this to be allowed to spawn",
		TYPE = "boolean",
	},

	["spawn_req_nodes"] = {
		CATEGORY = t_CAT.SPAWN,
		NAME = "Spawn Requires Map Nodes",
		DESC = "Map must have nodes for this to be allowed to spawn",
		TYPE = "boolean",
	},

	["announce_all"] = {
		CATEGORY = t_CAT.ANNOUNCE,
		NAME = "Announce All",
		DESC = "Announce in chat when the entity spawns or dies",
		TYPE = "boolean",
		-- DEFAULT = false,
	},
	["announce_color"] = {
		CATEGORY = t_CAT.ANNOUNCE,
		NAME = "Announce Color",
		TYPE = "color",
		DEFAULT = { "__RANDOMCOLOR", nil, nil, nil, nil, 1, 1 },
	},
	["announce_spawn"] = {
		CATEGORY = t_CAT.ANNOUNCE,
		NAME = "Announce Spawn",
		DESC = "Announce in chat when the entity spawns. Has priority over \"Announce All\"",
		TYPE = "boolean",
		-- DEFAULT = false,
	},
	["announce_spawn_message"] = {
		CATEGORY = t_CAT.ANNOUNCE,
		NAME = "Announce Spawn: Message",
		TYPE = "string",
	},
	["announce_death"] = {
		CATEGORY = t_CAT.ANNOUNCE,
		NAME = "Announce Death",
		DESC = "Announce in chat when the entity dies. Has priority over \"Announce All\"",
		TYPE = "boolean",
		-- DEFAULT = false,
	},
	["announce_death_message"] = {
		CATEGORY = t_CAT.ANNOUNCE,
		NAME = "Announce Death: Message",
		TYPE = "string",
	},
	["displayname"] = {
		CATEGORY = t_CAT.ANNOUNCE,
		NAME = "Display Name For Generic",
		DESC = "Used in generic spawn/death announcements",
		TYPE = "string",
	},
	["override_hard"] = {
		DESC = "Overwrites included values for spawned presets",
		CATEGORY = t_CAT.OVERRIDE,
		TYPE = "struct",
		STRUCT = {
			["all"] = {
				TYPE = "struct",
				STRUCT = t_any_values,
			},
			["npc"] = {
				TYPE = "struct",
				STRUCT = t_npc_base_values,
			},
			["entity"] = {
				TYPE = "struct",
				STRUCT = t_entity_base_values,
			},
			["nextbot"] = {
				TYPE = "struct",
				STRUCT = t_nextbot_base_values,
			},
			["weapon"] = {
				TYPE = "struct",
				STRUCT = t_weapon_values,
			},
			["weapon_set"] = {
				TYPE = "struct",
				STRUCT = t_weapon_set_values,
			},
		},
	},
	["override_soft"] = {
		DESC = "Only adds included values if they don't already exist on the spawned presets",
		CATEGORY = t_CAT.OVERRIDE,
		TYPE = "struct",
		STRUCT = {
			["all"] = {
				TYPE = "struct",
				STRUCT = t_any_values,
			},
			["npc"] = {
				TYPE = "struct",
				STRUCT = t_npc_base_values,
			},
			["entity"] = {
				TYPE = "struct",
				STRUCT = t_entity_base_values,
			},
			["nextbot"] = {
				TYPE = "struct",
				STRUCT = t_nextbot_base_values,
			},
			["weapon"] = {
				TYPE = "struct",
				STRUCT = t_weapon_values,
			},
			["weapon_set"] = {
				TYPE = "struct",
				STRUCT = t_weapon_set_values,
			},
		},
	},
}

t_spawnpool_values = {
	["spawns"] = {
		NAME = "Spawns",
		DESC = "All presets that can be spawned by this pool",
		TYPE = "struct_table",
		STRUCT_TBLMAINKEY = "preset",
		CATEGORY = t_CAT.REQUIRED,
		-- -- FUNCTION = {}, --[[ Direct() ]]
		NOFUNC = true,
		-- DESC = "A squad can only be automatically spawned if it has a spawnpool. Can be empty if used elsewhere (e.g. drop sets)",
		-- TYPE = "struct_table",
		STRUCT = {
			["preset"] = {
				SORTNAME = "*<a",
				NAME = "Preset",
				NOFUNC = true,
				TYPE = "preset",
				PRESETS = { "squad", "npc", "entity", "nextbot" },
				REQUIRED = true,
			},
			["expected"] = table.Copy( t_value_structs["expected"] ),
		},
		SORTNAME = "a",
	},
	["radiuslimits"] = {
		REQUIRED = true,
		CATEGORY = t_CAT.NPCD,
		NAME = "Radiuses",
		DESC = "Determines where entities can be spawned by the Auto-Spawner, and how many, based on radial distance from players/beacons. Any spawnpoint that is chosen must be valid for at least one player/beacon in a randomly chosen radius around them. A spawnpoint is invalid if it would cause the radius around anyone to go over their limit",
		TYPE = "struct_table",
		SORTNAME = "b",
		STRUCT = {
			["minradius"] = {
				SORTNAME = "a1",
				NAME = "Spawn Radius: Minimum",
				DESC = "Spawn distance can be between the minimum and maximum distance from any valid player",
				DEFAULT = 0,
				REQUIRED = true,
			},
			["maxradius"] = {
				SORTNAME = "a2",
				NAME = "Spawn Radius: Maximum",
				DESC = "Spawn distance can be between the minimum and maximum distance from any valid player",
				DEFAULT = 32768,
				REQUIRED = true,
			},
			["radius_entity_limit"] = {
				NAME = "Radius Entity Limit",
				DESC = "Limits entities by squadpool within this radius. Measured by quota-weight of spawnpool's entities only within this radius",	
				SORTNAME = "a3",
			},
			["radius_squad_limit"] = {
				NAME = "Radius Squad Limit",
				SORTNAME = "a4",
			},
			["nospawn"] = {
				NAME = "No Spawn",
				DESC = "Don't use this radius for picking spawn points",
				TYPE = "boolean",
			},
			["despawn"] = {
				NAME = "Despawn",
				DESC = "Requires either a radius or pool entity limit. Despawns entities if over entity limit, within each players' radius",
				TYPE = "boolean",
				DEFAULT = false,
			},
			["despawn_tooclose"] = {
				NAME = "Despawn: Player Minimum Distance",
				DESC = "Will not despawn any entity this close to any player",
				TYPE = "number",
			},
			["despawn_addquota"] = {
				NAME = "Despawn: Make Room For Spawn Quota",
				DESC = "If true, then instead of only despawning when over the radius/pool limit, it will despawn enough under the limit to fit the spawn quota. Caution: If there are multiple players and the radius is too small, it might despawn more than the spawn quota",
				TYPE = "boolean",
            DEFAULT = true,
			},
			["outside"] = {
				NAME = "Use Outside Area",
				DESC = "If true, use the area OUTSIDE the radius (WIP, but works)",
				TYPE = "boolean",
            DEFAULT = false,
			},
			["spawn_tooclose"] = {
				NAME = "Spawn Distance Hard Minimum",
				DESC = "Will not attempt to spawn anything this close to any player (only players). Note: Spawn velocity could still push enemies closer",
				TYPE = "number",
				SORTNAME = "a5",
				DEFAULT = 500,
			},
			["radius_autoadjust_max"] = {
				TYPE = "boolean",
				NAME = "Allow Max Radius Adjusting",
				DESC = "Allow the max radius to be adjusted, approaching the min radius (see: npcd Options > Spawn Radius & Limits)",
				DEFAULT = true,
				SORTNAME = "e2",
			},
			["radius_autoadjust_min"] = {
				TYPE = "boolean",
				NAME = "Allow Min Radius Adjusting",
				DESC = "Allow the min radius to be adjusted (see: npcd Options > Spawn Radius & Limits)",
				DEFAULT = true,
				SORTNAME = "e1",
			},
			["radius_spawn_autoadjust"] = {
				TYPE = "boolean",
				NAME = "Allow Radius Spawn Limit Adjusting",
				DESC = "If the radius has spawn/squad limits, allow these limits to be adjusted (this doesn't affect pool limits) (see: npcd Options > Spawn Radius & Limits)",
				DEFAULT = true,
				-- DEFAULT = false,
				SORTNAME = "e3",
			},
		},
		ENUM = {
			["Balanced"] = {
				{
					["minradius"] = 1250,
					["maxradius"] = 2750,
					["radius_entity_limit"] = 15,
					-- ["radius_squad_limit"] = nil,
					["despawn"] = false,
					["radius_autoadjust_min"] = true,
					["radius_autoadjust_max"] = true,
					["radius_spawn_autoadjust"] = false,
				},
				{
					["minradius"] = 2750,
					["maxradius"] = 7500,
					["radius_entity_limit"] = 35,
					-- ["radius_squad_limit"] = nil,
					["despawn"] = false,
					["radius_autoadjust_min"] = true,
					["radius_autoadjust_max"] = true,
					["radius_spawn_autoadjust"] = true,
				},
				{
					["minradius"] = 0,
					["maxradius"] = 32768,
					-- ["radius_entity_limit"] = 60,
					-- ["radius_squad_limit"] = nil,
					["nospawn"] = true,
					["despawn"] = true,
					["despawn_tooclose"] = 3000,
					["radius_autoadjust_max"] = true,
					["radius_autoadjust_min"] = true,
					["radius_spawn_autoadjust"] = true,
				},
			},
		},
		DEFAULT = {
			{
				["minradius"] = 1500,
				["maxradius"] = 7500,
				-- ["radius_squad_limit"] = nil,
				["despawn"] = false,
				["radius_autoadjust_min"] = true,
				["radius_autoadjust_max"] = true,
			},
			{
				["minradius"] = 0,
				["maxradius"] = 32768,
				-- ["radius_squad_limit"] = nil,
				["nospawn"] = true,
				["despawn"] = true,
				["despawn_tooclose"] = 3000,
				["radius_autoadjust_max"] = true,
				["radius_autoadjust_min"] = true,
			},
		},
	},
	["spawn_autoadjust"] = {
		CATEGORY = t_CAT.NPCD,
		NAME = "Allow Spawn Limit Adjusting",
		TYPE = "boolean",
		DESC = "Allow the pool's spawn/squad limits to be adjusted (see: npcd Options > Spawn Radius & Limits)",
		DEFAULT = true,
		-- DEFAULT_SAVE = true,
		NOFUNC = true,
		SORTNAME = "n",
	},
	["pool_spawnlimit"] = {
		CATEGORY = t_CAT.NPCD,
		NAME = "Spawnpool Entity Limit",
		DESC = "Limits entities from spawnpool. Measured by quota-weight of spawnpool's entities",
		SORTNAME = "c",
	},
	["pool_squadlimit"] = {
		CATEGORY = t_CAT.NPCD,
		NAME = "Spawnpool Squad Limit",
		SORTNAME = "d",
	},
	["minpressure"] = {
		CATEGORY = t_CAT.NPCD,
		NAME = "Pressure Requirement: Minimum",
		DESC = "If included, NPCD pressure must be greater than this",
		-- DEFAULT = 0,
		MIN = 0,
		MAX = 1,
	},
	["maxpressure"] = {
		CATEGORY = t_CAT.NPCD,
		NAME = "Pressure Requirement: Maximum",
		DESC = "If included, NPCD pressure must be less than this",
		MIN = 0,
		MAX = 1,
	},
	["mindelay"] = {
		CATEGORY = t_CAT.NPCD,
      NAME = "Minimum Delay",
		DESC = "Minimum delay between spawn automations. If function, rerolls every time it is called",
		DEFAULT = 0,
	},
	["initdelay"] = {
		CATEGORY = t_CAT.NPCD,
      NAME = "Initial Delay",
		DESC = "Minimum intial delay after map loads until spawning for this pool can begin",
		DEFAULT = 0,
	},
	["onlybeacons"] = {
		CATEGORY = t_CAT.SPAWN,
		NAME = "Only Use Spawn Beacons",
		TYPE = "boolean",
		DESC = "Spawner will only choose entities with \"Spawn Beacon\" enabled to determine spawnpoints. \"Spawn Distance Hard Minimum\" in Radiuses will still check all players",	},
	["override_hard"] = {
		DESC = "Overwrites included values on any spawned presets from this spawnpool. Entity override priority (applied last to first): Drop > Drop Set > Spawnpool > Squad > Entity/NPC/Nextbot > All",
		CATEGORY = t_CAT.OVERRIDE,
		TYPE = "struct",
		STRUCT = {
			["all"] = {
				TYPE = "struct",
				STRUCT = t_any_values,
			},
			["npc"] = {
				TYPE = "struct",
				STRUCT = t_npc_base_values,
			},
			["squad"] = {
				TYPE = "struct",
				STRUCT = t_squad_values,
			},
			["entity"] = {
				TYPE = "struct",
				STRUCT = t_entity_base_values,
			},
			["nextbot"] = {
				TYPE = "struct",
				STRUCT = t_nextbot_base_values,
			},
			["weapon"] = {
				TYPE = "struct",
				STRUCT = t_weapon_values,
			},
			["weapon_set"] = {
				TYPE = "struct",
				STRUCT = t_weapon_set_values,
			},
		},
	},
	["override_soft"] = {
		DESC = "Only adds included values if they don't already exist on the spawned preset. Entity override priority (applied last to first): Drop > Drop Set > Spawnpool > Squad > Entity/NPC/Nextbot > All",
		CATEGORY = t_CAT.OVERRIDE,
		TYPE = "struct",
		STRUCT = {
			["all"] = {
				TYPE = "struct",
				STRUCT = t_any_values,
			},
			["npc"] = {
				TYPE = "struct",
				STRUCT = t_npc_base_values,
			},
			["squad"] = {
				TYPE = "struct",
				STRUCT = t_squad_values,
			},
			["entity"] = {
				TYPE = "struct",
				STRUCT = t_entity_base_values,
			},
			["nextbot"] = {
				TYPE = "struct",
				STRUCT = t_nextbot_base_values,
			},
			["weapon"] = {
				TYPE = "struct",
				STRUCT = t_weapon_values,
			},
			["weapon_set"] = {
				TYPE = "struct",
				STRUCT = t_weapon_set_values,
			},
		},
	},
	["quota_entity_mult"] = {
		CATEGORY = t_CAT.NPCD,
		NAME = "Quota: Entity Multiplier",
		TYPE = "number",
		DESC = "Multiply entity quota by this number (see: npcd Options > Auto-Spawner)",
	},
	["quota_squad_mult"] = {
		CATEGORY = t_CAT.NPCD,
		NAME = "Quota: Squad Multiplier",
		TYPE = "number",
		DESC = "Multiply squad quota by this number (see: npcd Options > Auto-Spawner)",
	},
	["quota_entity_min"] = {
		CATEGORY = t_CAT.NPCD,
		NAME = "Quota: Entity Hard Min",
		DESC = "Minimum entity quota. Overrides ConVar \"Quota Hard Min: Entity\" from npcd Options > Auto-Spawner",
		TYPE = "number",
		SORTNAME = "z1",
	},
	["quota_entity_max"] = {
		CATEGORY = t_CAT.NPCD,
		NAME = "Quota: Entity Hard Max",
      DESC = "Maximum entity quota",
		TYPE = "number",
		SORTNAME = "z2",
	},
	["quota_squad_min"] = {
		CATEGORY = t_CAT.NPCD,
		NAME = "Quota: Squad Hard Min",
		DESC = "Minimum squad quota. Overrides ConVar \"Quota Hard Min: Squad\" from npcd Options > Auto-Spawner",
		TYPE = "number",
		SORTNAME = "z3",
	},
	["quota_squad_max"] = {
		NAME = "Quota: Squad Hard Max",
      DESC = "Maximum squad quota",
		CATEGORY = t_CAT.NPCD,
		TYPE = "number",
		SORTNAME = "z4",
	},
}

t_drop_values = {
	["entity_type"] = {
		TYPE = "data",
		DEFAULT = "drop",
		-- DEFAULT_SAVE = true,
	},
	["type"] = {
		CATEGORY = t_CAT.REQUIRED,
		TYPE = "enum",
		ENUM = {
			["entity"] = "entity",
			["preset"] = "preset",
		},
		DEFAULT = "preset",
		REQUIRED = true,
	},
	["entity_values"] = {
		CATEGORY = t_CAT.REQUIRED,
		NAME = "Entity Values",
		TYPE = "struct",
		-- STRUCT = t_entity_base_values,
		STRUCT = t_item_values,
	},
	["preset_values"] = {
		CATEGORY = t_CAT.REQUIRED,
		NAME = "Preset Values",
		TYPE = "struct",
		STRUCT = {
			["preset"] = {
				CATEGORY = t_CAT.REQUIRED,
				NAME = "Preset",
				TYPE = "preset",
				PRESETS = {
					"npc",
					"squad",
					"drop_set",
					"weapon_set",
					"entity",
					"nextbot",
				},
			},
			["inherit"] = {
				NAME = "Inherit Values & Overrides",
				DESC = "Inherits different things depending on preset type. Entities: Inherit squad values and squad overrides and become part of the original squad; Squad: New squad becomes part of inherited squad; Drop Set: Inherit drop set's overrides; Weapon Set: Inherit dropping entity's values and squad override",
				TYPE = "boolean",
				DEFAULT = false,
			},
			["keepangle"] = {
				NAME = "Entity Inherits Angle",
				DESC = "For entity-type presets",
				TYPE = "boolean",
			},
			["override_soft"] = {
				CATEGORY = t_CAT.OVERRIDE,
				DESC = "For this specific drop. Only adds included values if they don't already exist on the drop",
				TYPE = "struct",
				STRUCT = {
					["all"] = {
						TYPE = "struct",
						DESC = "Applies to npc, nextbot, & entity presets, including in squad presets",
						STRUCT = t_any_values,
					},
					["npc"] = {
						TYPE = "struct",
						DESC = "Applies to NPC presets, including in squad presets",
						STRUCT = t_npc_base_values,
					},
					["squad"] = {
						TYPE = "struct",
						STRUCT = t_squad_values,
					},
					["entity"] = {
						DESC = "Applies to entity presets, including in squad presets",
						TYPE = "struct",
						STRUCT = t_entity_base_values,
					},
					["nextbot"] = {
						TYPE = "struct",
						DESC = "Applies to NextBot presets, including in squad presets",
						STRUCT = t_nextbot_base_values,
					},
				},
			},
			["override_hard"] = {
				CATEGORY = t_CAT.OVERRIDE,
				DESC = "For this specific drop. Overwrites included values for this drop",
				TYPE = "struct",
				STRUCT = {
					["all"] = {
						TYPE = "struct",
						DESC = "Applies to npc, nextbot, & entity presets, including in squad presets",
						STRUCT = t_any_values,
					},
					["npc"] = {
						TYPE = "struct",
						DESC = "Applies to NPC presets, including in squad presets",
						STRUCT = t_npc_base_values,
					},
					["squad"] = {
						TYPE = "struct",
						STRUCT = t_squad_values,
					},
					["entity"] = {
						DESC = "Applies to entity presets, including in squad presets",
						TYPE = "struct",
						STRUCT = t_entity_base_values,
					},
					["nextbot"] = {
						TYPE = "struct",
						DESC = "Applies to NextBot presets, including in squad presets",
						STRUCT = t_nextbot_base_values,
					},
				},
			},
		},
	},
	
	["offset"] = {
		CATEGORY = t_CAT.PHYSICAL,
		TYPE = "vector",
	},
	["chance"] = table.Copy( t_value_structs["chance"] ),
	["min"] = {
		CATEGORY = t_CAT.NPCD,
		NAME = "Minimum Drops",
		DESC = "Will always drop on every roll if below this minimum, but not above the drop set's maximum",
		DEFAULT = 0,
    },
	["forcemin"] = {
		CATEGORY = t_CAT.NPCD,
		NAME = "Force Minimum Drops",
		DESC = "Force this drop to drop the minimum amount, ignoring the drop set's maximum.",
		TYPE = "boolean",
		-- DEFAULT = false,
	},
	["max"] = {
		CATEGORY = t_CAT.NPCD,
		NAME = "Maximum Drops",
		DESC = "Max of this specific drop",
		-- DEFAULT = 1,
    },
	
	-- ["count"] = {
	-- 	TYPE = "data",
	-- 	NOLOOKUP = true,
	-- 	DEFAULT = 0,
	-- },
	["destroydelay"] = {
		NAME = "Destroy After Time",
		DESC = "If given, remove the spawned entity after this many seconds. Does not apply to squad or drop set presets",
		-- DEFAULT = -1,
	},
	["spawnforce"] = { 
		CATEGORY = t_CAT.PHYSICAL,
		NAME = "Spawn Velocity",
		DESC = "For single entity spawns, random horizontal spawn velocity. The angle is always random",
        TYPE = "struct",
		STRUCT = {
			["forward"] = {
				DEFAULT = { "__RAND", 300, 600 },
			},
			["up"] = {
				DEFAULT = -5,
			},
		},
    },
	["squad_disposition"] = {
		DESC = "Changes dropped entities' disposition towards the originating squad and vice versa",
		TYPE = "enum",
		ENUM = {
			-- ["Error"] = D_ER,
			["Hostile"] = 1,
			["Friendly"] = 3,
			["Fear"] = 2,
			["Neutral"] = 4,
		},
	},
}

t_drop_set_values = {
	["drops"] = {
		CATEGORY = t_CAT.NPCD,
        TYPE = "struct_table",
		STRUCT_TBLMAINKEY = "type",
		STRUCT = t_drop_values,
		REQUIRED = true,
    },
	["rolls"] = {
		CATEGORY = t_CAT.NPCD,
		DESC = "Number of times to roll through all drops in the drop set",
		DEFAULT = 1,
    },
	["maxdrops"] = {
		CATEGORY = t_CAT.NPCD,
		-- DEFAULT = 1,
    },
	-- ["count"] = {
	-- 	TYPE = "data",
	-- 	NOLOOKUP = true,
	-- 	DEFAULT = 0,
	-- },
	["override_hard"] = {
		CATEGORY = t_CAT.OVERRIDE,
		DESC = "For all drops. Overwrites included values for each drop",
		TYPE = "struct",
		STRUCT = {
			["all"] = {
				TYPE = "struct",
				DESC = "Applies to generic entities and presets (npc, nextbot, & entity), including in squad presets",
				STRUCT = t_any_values,
			},
			["npc"] = {
				TYPE = "struct",
				DESC = "Applies to NPCs presets, including in squad presets",
				STRUCT = t_npc_base_values,
			},
			["squad"] = {
				TYPE = "struct",
				STRUCT = t_squad_values,
			},
			["entity"] = {
				DESC = "Applies to generic entities and entity preset types, including in squad presets",
				TYPE = "struct",
				STRUCT = t_entity_base_values,
			},
			["nextbot"] = {
				TYPE = "struct",
				DESC = "Applies to NextBots presets, including in squad presets",
				STRUCT = t_nextbot_base_values,
			},
		},
	},
	["override_soft"] = {
		CATEGORY = t_CAT.OVERRIDE,
		DESC = "For all drops. Only adds included values if they don't already exist for each drop",
		TYPE = "struct",
		STRUCT = {
			["all"] = {
				TYPE = "struct",
				DESC = "Applies to generic entities and presets (npc, nextbot, & entity), including in squad presets",
				STRUCT = t_any_values,
			},
			["npc"] = {
				TYPE = "struct",
				DESC = "Applies to NPCs presets, including in squad presets",
				STRUCT = t_npc_base_values,
			},
			["squad"] = {
				TYPE = "struct",
				STRUCT = t_squad_values,
			},
			["entity"] = {
				DESC = "Applies to generic entities and entity preset types, including in squad presets",
				TYPE = "struct",
				STRUCT = t_entity_base_values,
			},
			["nextbot"] = {
				TYPE = "struct",
				DESC = "Applies to NextBots presets, including in squad presets",
				STRUCT = t_nextbot_base_values,
			},
		},
	},
	["shuffle"] = {
		CATEGORY = t_CAT.NPCD,
		TYPE = "boolean",
		DESC = "If set to false, drops are rolled in order from top to bottom. Useful when dealing with max drops.",
		DEFAULT = true,
	},
	["count_per_squad_spawn"] = {
		CATEGORY = t_CAT.NPCD,
		TYPE = "boolean",
		DESC = "For squad preset drops, add the number of entities spawned from the squad to the drop count rather than the entire squad counting as a single drop.",		-- DEFAULT = false,
	},
}

t_render = {
    ["effect"] = { --t_effects
		["AirboatGunHeavyTracer"] = "AirboatGunHeavyTracer",
        ["AirboatGunImpact"] = "AirboatGunImpact",
        ["AirboatGunTracer"] = "AirboatGunTracer",
        ["AirboatMuzzleFlash"] = "AirboatMuzzleFlash",
        ["AntlionGib"] = "AntlionGib",
        ["AR2Explosion"] = "AR2Explosion",
        ["AR2Impact"] = "AR2Impact",
        ["AR2Tracer"] = "AR2Tracer",
        ["balloon_pop"] = "balloon_pop",
        ["BloodImpact"] = "BloodImpact",
        ["bloodspray"] = "bloodspray",
        ["BoltImpact"] = "BoltImpact",
        ["cball_bounce"] = "cball_bounce",
        ["cball_explode"] = "cball_explode",
        ["ChopperMuzzleFlash"] = "ChopperMuzzleFlash",
        ["CommandPointer"] = "CommandPointer",
        ["CrossbowLoad"] = "CrossbowLoad",
        ["CS_MuzzleFlash"] = "CS_MuzzleFlash",
        ["CS_MuzzleFlash_X"] = "CS_MuzzleFlash_X",
        ["dof_node"] = "dof_node",
        ["EjectBrass_12Gauge"] = "EjectBrass_12Gauge",
        ["EjectBrass_338Mag"] = "EjectBrass_338Mag",
        ["EjectBrass_556"] = "EjectBrass_556",
        ["EjectBrass_57"] = "EjectBrass_57",
        ["EjectBrass_762Nato"] = "EjectBrass_762Nato",
        ["EjectBrass_9mm"] = "EjectBrass_9mm",
        ["ElectricSpark"] = "ElectricSpark",
        ["entity_remove"] = "entity_remove",
        ["Explosion"] = "Explosion",
        ["GaussTracer"] = "GaussTracer",
        ["GlassImpact"] = "GlassImpact",
        ["GunshipImpact"] = "GunshipImpact",
        ["GunshipMuzzleFlash"] = "GunshipMuzzleFlash",
        ["GunshipTracer"] = "GunshipTracer",
        ["gunshotsplash"] = "gunshotsplash",
        ["HelicopterImpact"] = "HelicopterImpact",
        ["HelicopterMegaBomb"] = "HelicopterMegaBomb",
        ["HelicopterTracer"] = "HelicopterTracer",
        ["HL1GaussBeam"] = "HL1GaussBeam",
        ["HL1GaussBeamReflect"] = "HL1GaussBeamReflect",
        ["HL1GaussReflect"] = "HL1GaussReflect",
        ["HL1GaussWallImpact1"] = "HL1GaussWallImpact1",
        ["HL1GaussWallImpact2"] = "HL1GaussWallImpact2",
        ["HL1GaussWallPunchEnter"] = "HL1GaussWallPunchEnter",
        ["HL1GaussWallPunchExit"] = "HL1GaussWallPunchExit",
        ["HL1Gib"] = "HL1Gib",
        ["HL1ShellEject"] = "HL1ShellEject",
        ["HudBloodSplat"] = "HudBloodSplat",
        ["HunterDamage"] = "HunterDamage",
        ["HunterMuzzleFlash"] = "HunterMuzzleFlash",
        ["HunterTracer"] = "HunterTracer",
        ["Impact"] = "Impact",
        ["ImpactGauss"] = "ImpactGauss",
        ["ImpactGunship"] = "ImpactGunship",
        ["ImpactJeep"] = "ImpactJeep",
        ["inflator_magic"] = "inflator_magic",
        ["LaserTracer"] = "LaserTracer",
        ["ManhackSparks"] = "ManhackSparks",
        ["MetalSpark"] = "MetalSpark",
        ["MuzzleEffect"] = "MuzzleEffect",
        ["MuzzleFlash"] = "MuzzleFlash",
        ["ParticleEffect"] = "ParticleEffect",
        ["ParticleEffectStop"] = "ParticleEffectStop",
        ["ParticleTracer"] = "ParticleTracer",
        ["PhyscannonImpact"] = "PhyscannonImpact",
        ["phys_freeze"] = "phys_freeze",
        ["phys_unfreeze"] = "phys_unfreeze",
        ["propspawn"] = "propspawn",
        ["RagdollImpact"] = "RagdollImpact",
        ["RifleShellEject"] = "RifleShellEject",
        ["RPGShotDown"] = "RPGShotDown",
        ["selection_indicator"] = "selection_indicator",
        ["selection_ring"] = "selection_ring",
        ["ShakeRopes"] = "ShakeRopes",
        ["ShellEject"] = "ShellEject",
        ["ShotgunShellEject"] = "ShotgunShellEject",
        ["Smoke"] = "Smoke",
        ["Sparks"] = "Sparks",
        ["StriderBlood"] = "StriderBlood",
        ["StriderMuzzleFlash"] = "StriderMuzzleFlash",
        ["StriderTracer"] = "StriderTracer",
        ["StunstickImpact"] = "StunstickImpact",
        ["TeslaHitboxes"] = "TeslaHitboxes",
        ["TeslaZap"] = "TeslaZap",
        ["ThumperDust"] = "ThumperDust",
        ["ToolTracer"] = "ToolTracer",
        ["Tracer"] = "Tracer",
        ["TracerSound"] = "TracerSound",
        ["VortDispel"] = "VortDispel",
        ["waterripple"] = "waterripple",
        ["watersplash"] = "watersplash",
        ["WaterSurfaceExplosion"] = "WaterSurfaceExplosion",
        ["WheelDust"] = "WheelDust",
        ["wheel_indicator"] = "wheel_indicator",
    },
}

// pre-inherit adjustments
t_npc_base_values["relationships_outward"].STRUCT["self_squad"].STRUCT["exclude"] = table.Copy( t_npc_base_values["relationships_outward"].STRUCT["everyone"].STRUCT["exclude"] )
t_npc_base_values["relationships_outward"].STRUCT["self_squad"].STRUCT["exclude"].STRUCT["by_preset"].PRESETS = {
	"npc",
	"entity",
	"nextbot",
	"player"
}
t_active_values["relationships_inward"].STRUCT["everyone"].STRUCT["exclude"] = t_npc_base_values["relationships_outward"].STRUCT["everyone"].STRUCT["exclude"]
t_active_values["relationships_inward"].STRUCT["self_squad"].STRUCT["exclude"] = t_npc_base_values["relationships_outward"].STRUCT["self_squad"].STRUCT["exclude"]

// main lookup table

t_lookup = {
	["squad"] = t_squad_values,
	["spawnpool"] = t_spawnpool_values,
	["npc"] = t_npc_base_values,
	["nextbot"] = t_nextbot_base_values,
	["entity"] = t_entity_base_values,
	["weapon_set"] = t_weapon_set_values,
	["weapon"] = t_weapon_values,
	["drop_set"] = t_drop_set_values,
	["drop"] = t_drop_values,
	["player"] = t_player_values,
	["struct"] = t_value_structs,
	["item"] = t_item_values,
	["any"] = t_any_values,
	["basic"] = t_basic_values,
	["active"] = t_active_values,
	["class"] = {
		["npc"] = t_npc_class_values,
		["entity"] = t_entity_class_values,
		["nextbot"] = t_nextbot_class_values,
	},
}

// inherit t_active_values, t_basic_values
for lup in pairs( ACTIVE_TYPES ) do
	for k, v in pairs( t_active_values ) do
		-- print( basetbl[k], k, v )
		if t_lookup[lup][k] == nil then
			-- basetbl[k] = table.Copy( v )
			t_lookup[lup][k] = v
		end
	end
end

for lup in pairs( BASIC_TYPES ) do
	for k, v in pairs( t_basic_values ) do
		if t_lookup[lup][k] == nil then
			t_lookup[lup][k] = v
		end
	end
end

// excluded values, including anything that requires being on the activeNPC table
// todo: a better way of doing this
t_any_values["entity_type"] = nil
t_any_values["classname"] = nil

t_player_values["classname"] = nil
t_player_values["killonremove"] = nil
t_player_values["quota_fakeweight"] = nil
t_player_values["quota_weight"] = nil
t_player_values["spawn_req_navmesh"] = nil
t_player_values["spawn_req_nodes"] = nil
t_player_values["stress_mult"] = nil

// post-inherit adjustments

//spawnpool
t_spawnpool_values["spawns"].STRUCT["expected"].COMPARECHANCE_MAINKEY = { "expected", "f" }
t_spawnpool_values["spawns"].STRUCT["expected"].COMPARECHANCE_TABLE = true
t_spawnpool_values["spawns"].STRUCT["expected"].COMPARECHANCE_TABLE_KEY = "preset"
t_spawnpool_values["spawns"].STRUCT["expected"].DEFAULT_SAVE = true

// value structs
t_value_structs["damagefilter"].STRUCT["attacker"].STRUCT["apply_values"] = {
	DESC = "Overwrite and (re)apply values to the entity. Note: Some values require the entity to be a preset to work",
	TYPE = "struct",
	STRUCT = {
		["all"] = {
			TYPE = "struct",
			STRUCT = t_any_values,
		},
		["npc"] = {
			TYPE = "struct",
			STRUCT = t_npc_base_values,
		},
		["entity"] = {
			TYPE = "struct",
			STRUCT = t_entity_base_values,
		},
		["player"] = {
			TYPE = "struct",
			STRUCT = t_player_values,
		},
		["nextbot"] = {
			TYPE = "struct",
			STRUCT = t_nextbot_base_values,
		},
	}
}
t_value_structs["damagefilter"].STRUCT["victim"].STRUCT["apply_values"] = {
	DESC = "Overwrite and (re)apply values to the entity. Note: Some values require the entity to be a preset to work",
	TYPE = "struct",
	STRUCT = {
		["all"] = {
			TYPE = "struct",
			STRUCT = t_any_values,
		},
		["npc"] = {
			TYPE = "struct",
			STRUCT = t_npc_base_values,
		},
		["entity"] = {
			TYPE = "struct",
			STRUCT = t_entity_base_values,
		},
		["player"] = {
			TYPE = "struct",
			STRUCT = t_player_values,
		},
		["nextbot"] = {
			TYPE = "struct",
			STRUCT = t_nextbot_base_values,
		},
	}
}

//npc
t_npc_base_values["damagefilter_hitbox_out"].NAME = "Damage Filter: Outgoing Hit Boxes"
t_npc_base_values["damagefilter_hitbox_in"].NAME = "Damage Filter: Incoming Hit Boxes"

//entity
t_entity_base_values["stress_mult"] = table.Copy( t_active_values["stress_mult"] )
t_entity_base_values["stress_mult"].DEFAULT = 0
t_entity_base_values["allow_chased"] = table.Copy( t_active_values["allow_chased"] )
t_entity_base_values["allow_chased"].DEFAULT = false

//item
-- t_item_values["entity_type"] = {
-- 	TYPE = "data",
-- 	DEFAULT = "item",
	-- DEFAULT_SAVE = true,
-- }
t_item_values["classname"] = t_value_structs["classname_nonclass"]

//weapon
t_weapon_values["classname"] = t_value_structs["classname_nonclass"]
t_weapon_values["chance"].CATEGORY = t_CAT.REQUIRED
t_weapon_values["chance"].DESC = "(Only for \"Give All\") " .. t_value_structs["chance"].DESC
t_weapon_values["chance"].NAME = "(Give All) Chance"
t_weapon_values["expected"].COMPARECHANCE_MAINKEY = { "expected", "f" }
t_weapon_values["expected"].COMPARECHANCE_TABLE = true
t_weapon_values["expected"].COMPARECHANCE_TABLE_KEY = "classname"
t_weapon_values["expected"].DEFAULT_SAVE = true
t_weapon_values["expected"].DESC = t_value_structs["expected"].DESC .. ". Does not apply if Give All is enabled"
t_weapon_values["startalpha"] = table.Copy( t_active_values["startalpha"] )
t_weapon_values["startalpha"].DEFAULT = nil

//npc
t_npc_base_values["spawneffect"] = table.Copy( t_basic_values["spawneffect"] )
t_npc_base_values["spawneffect"].DEFAULT = {
	{
		["type"] = "effect",
		["name"] = "ThumperDust",
		["effect_data"] = {
			["scale"] = 96,
			["normal"] = Vector(0,0,1),
		},
	}
}

//nextbot
t_nextbot_base_values["spawneffect"] = t_npc_base_values["spawneffect"]
t_nextbot_base_values["entity_type"] = {
	TYPE = "data",
	DEFAULT = "nextbot",
	DEFAULT_SAVE = true,
}

//player
t_player_values["entity_type"] = {
	TYPE = "data",
	DEFAULT = "player",
	DEFAULT_SAVE = true,
}
t_player_values["expected"].DEFAULT_SAVE = true
t_player_values["expected"].DEFAULT = {
	["n"] = 0,
	["d"] = 0,
	["f"] = 0,
}
t_player_values["weapon_set"] = nil
t_player_values["damagefilter_hitbox_out"].NAME = "Damage Filter: Outgoing Hit Boxes"
t_player_values["damagefilter_hitbox_in"].NAME = "Damage Filter: Incoming Hit Boxes"


for i in pairs( PROFILE_SETS ) do
	t_lookup[i]["npcd_enabled"] = {
		TYPE = "data",
		DEFAULT = true,
	}
	t_lookup[i]["description"] = {
		-- TYPE = "string",
		TYPE = "info",
		-- TYPE = "data",
		-- NAME = "Description",
		REFRESHDESC = true,
		NAME = "",
		CATEGORY = t_CAT.DESC,
	}
	t_lookup[i]["icon"] = { // maybe another day
		TYPE = "data",
		NOLOOKUP = true,
		-- TYPE = "string",
		-- NAME = "Icon",
		-- CATEGORY = t_CAT.DESC,
		-- NOFUNC = true,
	}
end

// misc preset panel types
t_presetspanel_misc = {
	["effects"] = t_render["effect"],
}



// inherit defaults for all values in lookup, should exclude typ_class tables
for refname, ltbl in pairs( t_lookup ) do
	if refname == "class" then continue end
	InheritBaseFormat(ltbl, t_basevalue_format[refname] or t_basevalue_format["default"] )
end

// for _class tables since each 1st-level key is the classname instead of the keyvalue
for typ, ltbl in pairs( t_lookup["class"] ) do
	for classname, classtbl in pairs( ltbl ) do
		InheritBaseFormat(classtbl, t_basevalue_format[typ] or t_basevalue_format["default"] )
		InheritExistingValues(classtbl, t_lookup[typ])
	end
end

// merge class/base enums
local t_enum_merge = {
	["npc"] = {
		"spawnflags",
		"inputs",
	},
	["entity"] = {
		"spawnflags",
		"inputs",
	},
	["nextbot"] = {
		"spawnflags",
		"inputs",
	},
}
for cl, clt in pairs( t_enum_merge ) do
	for _, vn in ipairs( clt ) do
		for cname, ctbl in pairs( t_lookup["class"][cl] ) do
			if ctbl[vn] and ctbl[vn].TBLSTRUCT
			and t_lookup[cl][vn] and t_lookup[cl][vn].TBLSTRUCT and  t_lookup[cl][vn].TBLSTRUCT.ENUM then
				ctbl[vn].TBLSTRUCT.ENUM = ctbl[vn].TBLSTRUCT.ENUM or {}
				
				for k, v in pairs( t_lookup[cl][vn].TBLSTRUCT.ENUM ) do
					if ctbl[vn].TBLSTRUCT.ENUM[k] == nil then
						ctbl[vn].TBLSTRUCT.ENUM[k] = v
					end
				end
			end

         if ctbl[vn] and ctbl[vn].STRUCT
			and t_lookup[cl][vn] and t_lookup[cl][vn].STRUCT then
         // and  t_lookup[cl][vn].TBLSTRUCT.ENUM then
            for j, jt in pairs(ctbl[vn].STRUCT) do
               if t_lookup[cl][vn].STRUCT[j].ENUM then
                  ctbl[vn].STRUCT[j].ENUM = ctbl[vn].STRUCT[j].ENUM or {}
                  for k, v in pairs( t_lookup[cl][vn].STRUCT[j].ENUM ) do
                     if ctbl[vn].STRUCT[j].ENUM[k] == nil then
                        ctbl[vn].STRUCT[j].ENUM[k] = v
                     end
                  end
               end
            end
			end
		end
	end
end


for k, ltbl in pairs( t_lookup ) do
	if k != "class" then
		ltbl["LOOKUP_REROLL"] = {
			TYPE = "data",
			NOLOOKUP = true,
		}
		ltbl["VERSION"] = { // version at time of creation
			TYPE = "data",
			NOLOOKUP = true,
			-- CLEAR = true,
		}
	end

	// for structs
	for _, dvtbl in pairs( ltbl ) do
		if dvtbl.STRUCT then
			InheritBaseFormat( dvtbl.STRUCT, t_basevalue_format["default"] )			
		end
	end
end

// for patches
t_old_lookup = {
	[20] = {
		["squad"] = {
			["squadpools"] = {
				CATEGORY = t_CAT.REQUIRED,
				-- -- FUNCTION = {}, --[[ Direct() ]]
				NOFUNC = true,
				DESC = "A squad can only be automatically spawned if it has a squadpool. Can be empty if used elsewhere (e.g. drop sets)",
				TYPE = "struct_table",
				STRUCT = {
					["preset"] = {
						SORTNAME = "*<a",
						NOFUNC = true,
						TYPE = "preset",
						PRESETS = { "squadpool" },
						REQUIRED = true,
					},
					["expected"] = {
						CATEGORY = t_CAT.REQUIRED,
						NOFUNC = true,
						DESC = "[double-click line to switch editor] Chance for this item out of all items within the available set. The chance will be proportional to the sum of all chances within that set",
						REQUIRED = true,
						TYPE = "fraction",
						DEFAULT = {
							["n"] = 1,
							["d"] = 1,
							["f"] = 1,
						},
						DEFAULT_SAVE = true,
						COMPARECHANCE = true,
						COMPARECHANCE_SIDEKEY = { "preset", "name" },
						COMPARECHANCE_MAINKEY = { "expected", "f" },
					}
				},
			},
		}
	},
}