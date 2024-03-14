// (CLIENT) vip defense

if !CLIENT then return false end
if !npcd.CheckClientPerm( LocalPlayer(), npcd.cvar.perm_prof.v:GetInt() ) then return false end

// The function will insert the presets as pending changes into the given profile.

// Returns existing profile or creates empty profile
// 1st arg: profile name, or generic name if nil.
// 2nd arg: always create a new profile (true) or return the name without changes if existing (false/nil)
local profile_name = npcd.ClientCreateEmptyProfile( "vip defense", true ) // set profile_name to nil to insert into the currently active profile

-- npcd.ClientClearProfile( profile_name ) // (optional) empty out existing profile
-- npcd.ClientSwitchProfile( profile_name ) // (optional) set as active profile

-- npcd.QuerySettings()
// runs function once after profiles update is received
// 1st arg: profile that must exist before it can run, or nil for no requirement
npcd.QueuePostQuery( profile_name, 30, function()
	npcd.InsertPending( profile_name, "drop_set", "High Level Drops", {
		["VERSION"] = 20,
		["description"] = "Intended for bosses",
		["drops"] = {
			[1] = {
				["destroydelay"] = 180,
				["entity_values"] = {
					["classname"] = {
						["name"] = "item_healthkit",
						["type"] = "SpawnableEntities",
					},
				},
				["type"] = "entity",
			},
			[2] = {
				["chance"] = {
					["d"] = 5,
					["f"] = 0.6,
					["n"] = 3,
				},
				["destroydelay"] = 180,
				["entity_values"] = {
					["classname"] = {
						["name"] = "item_battery",
						["type"] = "SpawnableEntities",
					},
				},
				["type"] = "entity",
			},
			[3] = {
				["chance"] = {
					["d"] = 5,
					["f"] = 0.6,
					["n"] = 3,
				},
				["destroydelay"] = 180,
				["entity_values"] = {
					["classname"] = {
						["name"] = "item_battery",
						["type"] = "SpawnableEntities",
					},
				},
				["type"] = "entity",
			},
			[4] = {
				["destroydelay"] = 180,
				["forcemin"] = true,
				["min"] = {
					[1] = "__RANDOM",
					[2] = 2,
					[3] = 3,
				},
				["offset"] = {
					[1] = "__RANDOMVECTOR",
					[2] = -5,
					[3] = 5,
					[4] = -5,
					[5] = 5,
					[6] = 0,
					[7] = 15,
				},
				["preset_values"] = {
					["preset"] = {
						["name"] = "Ammo Drop",
						["type"] = "weapon_set",
					},
				},
				["type"] = "preset",
			},
		},
		["npcd_enabled"] = true,
		["rolls"] = 1,
		["shuffle"] = true,
	} )

	npcd.InsertPending( profile_name, "drop_set", "Ammo", {
		["VERSION"] = 20,
		["description"] = "",
		["drops"] = {
			[1] = {
				["destroydelay"] = 180,
				["offset"] = {
					[1] = "__RANDOMVECTOR",
					[2] = -5,
					[3] = 5,
					[4] = -5,
					[5] = 5,
					[6] = 0,
					[7] = 15,
				},
				["preset_values"] = {
					["preset"] = {
						["name"] = "Ammo Drop",
						["type"] = "weapon_set",
					},
				},
				["type"] = "preset",
			},
		},
		["npcd_enabled"] = true,
		["rolls"] = 1,
		["shuffle"] = true,
	} )

	npcd.InsertPending( profile_name, "drop_set", "Medium Level Drops", {
		["VERSION"] = 20,
		["description"] = "Intended for slightly less common enemies",
		["drops"] = {
			[1] = {
				["destroydelay"] = 180,
				["entity_values"] = {
					["classname"] = {
						["name"] = "item_healthvial",
						["type"] = "SpawnableEntities",
					},
				},
				["type"] = "entity",
			},
			[2] = {
				["chance"] = {
					["d"] = 5,
					["f"] = 0.2,
					["n"] = 1,
				},
				["destroydelay"] = 180,
				["entity_values"] = {
					["classname"] = {
						["name"] = "item_battery",
						["type"] = "SpawnableEntities",
					},
				},
				["type"] = "entity",
			},
			[3] = {
				["destroydelay"] = 180,
				["offset"] = {
					[1] = "__RANDOMVECTOR",
					[2] = -5,
					[3] = 5,
					[4] = -5,
					[5] = 5,
					[6] = 0,
					[7] = 15,
				},
				["preset_values"] = {
					["preset"] = {
						["name"] = "Ammo Drop",
						["type"] = "weapon_set",
					},
				},
				["type"] = "preset",
			},
		},
		["npcd_enabled"] = true,
		["rolls"] = 1,
		["shuffle"] = true,
	} )

	npcd.InsertPending( profile_name, "drop_set", "Grand Level Drops", {
		["VERSION"] = 20,
		["description"] = "Intended for higher-end bosses",
		["drops"] = {
			[1] = {
				["destroydelay"] = 180,
				["entity_values"] = {
					["classname"] = {
						["name"] = "item_healthkit",
						["type"] = "SpawnableEntities",
					},
				},
				["type"] = "entity",
			},
			[2] = {
				["destroydelay"] = 180,
				["entity_values"] = {
					["classname"] = {
						["name"] = "item_battery",
						["type"] = "SpawnableEntities",
					},
				},
				["max"] = 3,
				["type"] = "entity",
			},
			[3] = {
				["chance"] = {
					["d"] = 4,
					["f"] = 0.75,
					["n"] = 3,
				},
				["destroydelay"] = 180,
				["entity_values"] = {
					["classname"] = {
						["name"] = "item_battery",
						["type"] = "SpawnableEntities",
					},
				},
				["type"] = "entity",
			},
			[4] = {
				["destroydelay"] = 180,
				["forcemin"] = true,
				["min"] = 9,
				["offset"] = {
					[1] = "__RANDOMVECTOR",
					[2] = -5,
					[3] = 5,
					[4] = -5,
					[5] = 5,
					[6] = 0,
					[7] = 15,
				},
				["preset_values"] = {
					["preset"] = {
						["name"] = "Ammo Drop",
						["type"] = "weapon_set",
					},
				},
				["type"] = "preset",
			},
			[5] = {
				["destroydelay"] = 180,
				["entity_values"] = {
					["classname"] = {
						["name"] = "item_healthvial",
						["type"] = "SpawnableEntities",
					},
				},
				["type"] = "entity",
			},
		},
		["npcd_enabled"] = true,
		["rolls"] = {
			[1] = "__RAND",
			[2] = 3,
			[3] = 4,
		},
		["shuffle"] = true,
	} )

	npcd.InsertPending( profile_name, "drop_set", "Low Level Drops", {
		["VERSION"] = 20,
		["description"] = "Intended for common enemies",
		["drops"] = {
			[1] = {
				["chance"] = {
					["d"] = 4,
					["f"] = 0.25,
					["n"] = 1,
				},
				["destroydelay"] = 180,
				["entity_values"] = {
					["classname"] = {
						["name"] = "item_healthvial",
						["type"] = "SpawnableEntities",
					},
				},
				["type"] = "entity",
			},
			[2] = {
				["chance"] = {
					["d"] = 10,
					["f"] = 0.1,
					["n"] = 1,
				},
				["destroydelay"] = 180,
				["entity_values"] = {
					["classname"] = {
						["name"] = "item_battery",
						["type"] = "SpawnableEntities",
					},
				},
				["type"] = "entity",
			},
			[3] = {
				["chance"] = {
					["d"] = 10,
					["f"] = 0.3,
					["n"] = 3,
				},
				["destroydelay"] = 180,
				["offset"] = {
					[1] = "__RANDOMVECTOR",
					[2] = -5,
					[3] = 5,
					[4] = -5,
					[5] = 5,
					[6] = 0,
					[7] = 15,
				},
				["preset_values"] = {
					["preset"] = {
						["name"] = "Ammo Drop",
						["type"] = "weapon_set",
					},
				},
				["type"] = "preset",
			},
		},
		["npcd_enabled"] = true,
		["rolls"] = 1,
		["shuffle"] = true,
	} )

	npcd.InsertPending( profile_name, "drop_set", "Ammo Special", {
		["VERSION"] = 20,
		["description"] = "",
		["drops"] = {
			[1] = {
				["destroydelay"] = 180,
				["offset"] = {
					[1] = "__RANDOMVECTOR",
					[2] = -5,
					[3] = 5,
					[4] = -5,
					[5] = 5,
					[6] = 0,
					[7] = 15,
				},
				["preset_values"] = {
					["preset"] = {
						["name"] = "Ammo Special Drop",
						["type"] = "weapon_set",
					},
				},
				["spawnforce"] = {
					["forward"] = {
						[1] = "__RAND",
						[2] = 100,
						[3] = 200,
					},
				},
				["type"] = "preset",
			},
		},
		["npcd_enabled"] = true,
		["rolls"] = 1,
	} )

	npcd.InsertPending( profile_name, "drop_set", "AR2 Egg", {
		["VERSION"] = 20,
		["drops"] = {
			[1] = {
				["destroydelay"] = 180,
				["entity_values"] = {
					["classname"] = {
						["name"] = "item_ammo_ar2_altfire",
						["type"] = "SpawnableEntities",
					},
				},
				["type"] = "entity",
			},
		},
		["npcd_enabled"] = true,
		["rolls"] = 1,
		["shuffle"] = true,
	} )

	npcd.InsertPending( profile_name, "npc", "Combine Elitist", {
		["VERSION"] = 20,
		["animspeed"] = 0.7,
		["bloodcolor"] = "BLOOD_COLOR_ANTLION_WORKER",
		["chase_preset"] = {
			[1] = {
				["name"] = "VIP",
				["type"] = "npc",
			},
		},
		["chase_schedule"] = {
			[1] = "SCHED_FORCED_GO",
			[2] = "SCHED_CHASE_ENEMY",
			[3] = "SCHED_TARGET_CHASE",
		},
		["classname"] = {
			["name"] = "npc_combine_s",
			["type"] = "NPC",
		},
		["damagefilter_in"] = {
			[1] = {
				["condition"] = {
					["damage"] = {
						["dmg_types"] = {
							["include"] = {
								[1] = "DMG_DISSOLVE",
								[2] = "DMG_CRUSH",
							},
						},
					},
				},
				["max"] = 32,
			},
			[2] = {
				["attacker"] = {
					["reflect"] = 1,
				},
				["condition"] = {
					["attacker"] = {
						["types"] = {
							["exclude"] = {
								[1] = "worldspawn",
								[2] = "environment",
								[3] = "player",
							},
							["include"] = {
								[1] = "character",
							},
						},
					},
					["victim"] = {
						["onfire"] = true,
					},
				},
			},
		},
		["damagescale_in"] = 0.65,
		["damagescale_out"] = 1.45,
		["dmg_setenemy"] = true,
		["drop_set"] = {
			[1] = {
				["drop_set"] = {
					["name"] = "High Level Drops",
					["type"] = "drop_set",
				},
			},
			[2] = {
				["chance"] = {
					["d"] = 20,
					["f"] = 0.65,
					["n"] = 13,
				},
				["drop_set"] = {
					["name"] = "AR2 Egg",
					["type"] = "drop_set",
				},
			},
		},
		["effects"] = {
			[1] = {
				["attachment"] = 3,
				["centered"] = false,
				["delay"] = 0.0167,
				["effect_data"] = {
					["normal"] = Vector( 0, 0, 1 ),
				},
				["name"] = "AR2Impact",
				["offset"] = Vector( -5, -5, 15 ),
				["offset2"] = Vector( -5, 0, 0 ),
				["offset_angadd"] = Angle( 0, 3, 0 ),
				["type"] = "effect",
			},
			[2] = {
				["attachment"] = 3,
				["centered"] = false,
				["delay"] = 0.0167,
				["effect_data"] = {
					["normal"] = Vector( 0, 0, 1 ),
				},
				["name"] = "AR2Impact",
				["offset"] = Vector( 5, 0, 15 ),
				["offset2"] = Vector( -5, 0, 0 ),
				["offset_angadd"] = Angle( 0, 3, 0 ),
				["type"] = "effect",
			},
			[3] = {
				["attachment"] = 3,
				["centered"] = false,
				["delay"] = 0.0167,
				["effect_data"] = {
					["normal"] = Vector( 0, 0, 1 ),
				},
				["name"] = "AR2Impact",
				["offset"] = Vector( -5, 5, 15 ),
				["offset2"] = Vector( -5, 0, 0 ),
				["offset_angadd"] = Angle( 0, 3, 0 ),
				["type"] = "effect",
			},
		},
		["engineflags"] = {
			[1] = "EFL_NO_DISSOLVE",
		},
		["entity_type"] = "npc",
		["force_approach"] = true,
		["long_range"] = true,
		["material"] = "models/shadertest/vertexlittextureplusmaskedenvmappedbumpmap",
		["maxhealth"] = 180,
		["moveact"] = "ACT_WALK_AIM",
		["npc_state"] = "NPC_STATE_COMBAT",
		["npcd_enabled"] = true,
		["numgrenades"] = 10,
		["regen"] = 1,
		["regendelay"] = 0.75,
		["rendercolor"] = {
			[1] = "__RANDOMCOLOR",
		},
		["scale"] = 1.25,
		["seekout_clear"] = false,
		["seekout_clear_dmg"] = false,
		["soldiertype"] = "Elite",
		["spawneffect"] = {
			[1] = {
				["effect_data"] = {
					["normal"] = Vector( 0, 0, 1 ),
					["scale"] = 96,
				},
				["name"] = "ThumperDust",
				["type"] = "effect",
			},
		},
		["spawnflags"] = {
			[1] = "Think outside PVS",
			[2] = "Ignore player push",
			[3] = "Don\'t drop grenades",
			[4] = "Don\'t drop AR2 alt fire (Elite only)",
			[5] = "Don\'t drop weapons",
		},
		["tacticalvariant"] = "Pressure the enemy (Keep advancing)",
		["weapon_proficiency"] = "Perfect",
		["weapon_set"] = {
			["name"] = "HL2 AR2/Shotgun",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Brainhack", {
		["VERSION"] = 20,
		["accelerate"] = {
			["accel_rate"] = 37,
			["accel_threshold"] = 410,
			["enabled"] = true,
		},
		["animspeed"] = 2,
		["bloodcolor"] = "BLOOD_COLOR_RED",
		["bones"] = {
			[1] = {
				["bone"] = 0,
				["rotate"] = Angle( 0, 90, -90 ),
			},
		},
		["classname"] = {
			["name"] = "npc_manhack",
			["type"] = "NPC",
		},
		["damagefilter_out"] = {
			[1] = {
				["damagescale"] = {
					[1] = "__RAND",
					[2] = 2,
					[3] = 4,
				},
			},
		},
		["drop_set"] = {
			[1] = {
				["drop_set"] = {
					["name"] = "High Level Drops",
					["type"] = "drop_set",
				},
			},
		},
		["engineflags"] = {
			[1] = "EFL_NO_DISSOLVE",
		},
		["entity_type"] = "npc",
		["force_approach"] = true,
		["gmod_allowphysgun"] = false,
		["inputs"] = {
			[1] = {
				["command"] = "Unpack",
			},
			[2] = {
				["command"] = "Wake",
			},
		},
		["material"] = {
			[1] = "__TBLRANDOM",
			[2] = "models/props_combine/combine_interface_disp",
			[3] = "models/props_combine/combine_intmonitor001_disp",
			[4] = "models/props_combine/combine_monitorbay_disp",
		},
		["maxhealth"] = 250,
		["model"] = "models/nova/w_headgear.mdl",
		["npcd_enabled"] = true,
		["physobject"] = {
			["angledrag"] = 64,
			["mass"] = 128,
		},
		["quota_weight"] = 1,
		["removebody"] = true,
		["scale"] = 2.56,
		["seekout_clear"] = false,
		["seekout_setenemy"] = true,
		["seekout_settarget"] = true,
		["spawneffect"] = {
			[1] = {
				["effect_data"] = {
					["normal"] = Vector( 0, 0, 1 ),
					["scale"] = 96,
				},
				["name"] = "ThumperDust",
				["type"] = "effect",
			},
		},
		["start_patrol"] = true,
	} )

	npcd.InsertPending( profile_name, "npc", "VIP", {
		["VERSION"] = 20,
		["beacon"] = true,
		["chase_preset"] = {
			[1] = {
				["name"] = "Destination",
				["type"] = "entity",
			},
		},
		["chase_schedule"] = {
			[1] = "SCHED_FORCED_GO",
		},
		["chase_setenemy"] = true,
		["chase_settarget"] = true,
		["citizentype"] = {
			[1] = "__RANDOM",
			[2] = 1,
			[3] = 2,
		},
		["classname"] = {
			["name"] = "npc_citizen",
			["type"] = "NPC",
		},
		["damagefilter_in"] = {
			[1] = {
				["continue"] = true,
				["victim"] = {
					["effects"] = {
						[1] = {
							["chance"] = {
								["d"] = 10,
								["f"] = 0.1,
								["n"] = 1,
							},
							["name"] = {
								[1] = "__TBLRANDOM",
								[2] = "vo/npc/male01/overhere01.wav",
								[3] = "vo/npc/male01/help01.wav",
								[4] = "vo/npc/male01/hacks01.wav",
								[5] = "vo/npc/male01/no02.wav",
								[6] = "vo/npc/male01/ohno.wav",
								[7] = "vo/npc/male01/thehacks01.wav",
							},
							["type"] = "sound",
						},
					},
				},
			},
			[2] = {
				["condition"] = {
					["attacker"] = {
						["types"] = {
							["exclude"] = {
							},
							["include"] = {
								[1] = "player",
							},
						},
					},
				},
				["damagescale"] = 0,
			},
			[3] = {
				["condition"] = {
					["damage"] = {
						["greater_than_health"] = true,
					},
				},
				["victim"] = {
					["explode"] = {
						["altmethod"] = true,
						["altmethod_characteronly"] = true,
						["damage"] = 32768,
						["generic"] = true,
						["radius"] = 32768,
					},
				},
			},
		},
		["deathexplode"] = {
			["altmethod"] = true,
			["altmethod_characteronly"] = true,
			["altmethod_dmgtype"] = "DMG_GENERIC",
			["damage"] = 999,
			["radius"] = 32768,
		},
		["description"] = "Protect them!",
		["effects"] = {
			[1] = {
				["delay"] = {
					[1] = "__RAND",
					[2] = 15,
					[3] = 35,
				},
				["name"] = {
					[1] = "__TBLRANDOM",
					[2] = "vo/npc/male01/answer30.wav",
					[3] = "vo/npc/male01/answer35.wav",
					[4] = "vo/npc/male01/gordead_ans01.wav",
					[5] = "vo/npc/male01/gordead_ans02.wav",
					[6] = "vo/npc/male01/holddownspot01.wav",
					[7] = "vo/npc/male01/holddownspot02.wav",
					[8] = "vo/npc/male01/illstayhere01.wav",
					[9] = "vo/npc/male01/imstickinghere01.wav",
				},
				["sound"] = {
					["dist"] = 100,
					["restart"] = false,
					["volume"] = 1,
				},
				["type"] = "sound",
			},
		},
		["engineflags"] = {
			[1] = "EFL_NO_DISSOLVE",
		},
		["entity_type"] = "npc",
		["inputs"] = {
			[1] = {
				["command"] = "DisableWeaponPickup",
			},
		},
		["material"] = "models/player/shared/gold_player",
		["maxhealth"] = 500,
		["moveact"] = "ACT_WALK",
		["noidle"] = true,
		["npc_state"] = "NPC_STATE_COMBAT",
		["npcd_enabled"] = true,
		["quota_weight"] = 1,
		["regen"] = 1.5,
		["regendelay"] = 1,
		["rendermode"] = "RENDERMODE_TRANSCOLOR",
		["seekout_clear"] = true,
		["spawneffect"] = {
			[1] = {
				["effect_data"] = {
					["normal"] = Vector( 0, 0, 1 ),
					["scale"] = 96,
				},
				["name"] = "ThumperDust",
				["type"] = "effect",
			},
			[2] = {
				["name"] = {
					[1] = "__TBLRANDOM",
					[2] = "vo/npc/male01/hellodrfm01.wav",
					[3] = "vo/npc/male01/hellodrfm02.wav",
					[4] = "vo/npc/male01/heretheycome01.wav",
					[5] = "vo/npc/male01/help01.wav",
					[6] = "vo/npc/male01/overhere01.wav",
					[7] = "vo/npc/female01/hellodrfm01.wav",
					[8] = "vo/npc/female01/hellodrfm02.wav",
					[9] = "vo/npc/female01/heretheycome01.wav",
					[10] = "vo/npc/female01/help01.wav",
					[11] = "vo/npc/female01/overhere01.wav",
				},
				["sound"] = {
					["dist"] = 125,
				},
				["type"] = "sound",
			},
		},
		["spawnflags"] = {
			[1] = "Random Head",
		},
		["spritetrail"] = {
			[1] = {
				["color"] = Color( 214, 184, 87, 142 ),
				["endwidth"] = 1,
				["lifetime"] = 60,
				["startwidth"] = 5,
			},
		},
	} )

	npcd.InsertPending( profile_name, "npc", "VIP (Mission Critical)", {
		["VERSION"] = 20,
		["beacon"] = true,
		["chase_preset"] = {
			[1] = {
				["name"] = "Destination",
				["type"] = "entity",
			},
		},
		["chase_schedule"] = {
			[1] = "SCHED_FORCED_GO",
		},
		["chase_setenemy"] = true,
		["chase_settarget"] = true,
		["citizentype"] = {
			[1] = "__RANDOM",
			[2] = 1,
			[3] = 2,
		},
		["classname"] = {
			["name"] = "npc_citizen",
			["type"] = "NPC",
		},
		["damagefilter_in"] = {
			[1] = {
				["continue"] = true,
				["victim"] = {
					["effects"] = {
						[1] = {
							["chance"] = {
								["d"] = 10,
								["f"] = 0.1,
								["n"] = 1,
							},
							["name"] = {
								[1] = "__TBLRANDOM",
								[2] = "vo/npc/male01/overhere01.wav",
								[3] = "vo/npc/male01/help01.wav",
								[4] = "vo/npc/male01/hacks01.wav",
								[5] = "vo/npc/male01/no02.wav",
								[6] = "vo/npc/male01/ohno.wav",
								[7] = "vo/npc/male01/thehacks01.wav",
							},
							["type"] = "sound",
						},
					},
				},
			},
			[2] = {
				["condition"] = {
					["attacker"] = {
						["types"] = {
							["exclude"] = {
							},
							["include"] = {
								[1] = "player",
							},
						},
					},
				},
				["damagescale"] = 0,
			},
			[3] = {
				["condition"] = {
					["damage"] = {
						["greater_than_health"] = true,
					},
				},
				["victim"] = {
					["explode"] = {
						["altmethod"] = true,
						["altmethod_characteronly"] = true,
						["damage"] = 32768,
						["generic"] = true,
						["radius"] = 32768,
					},
				},
			},
		},
		["deathexplode"] = {
		},
		["description"] = "VIP but the game ends when they die",
		["effects"] = {
			[1] = {
				["delay"] = {
					[1] = "__RAND",
					[2] = 15,
					[3] = 35,
				},
				["name"] = {
					[1] = "__TBLRANDOM",
					[2] = "vo/npc/male01/answer30.wav",
					[3] = "vo/npc/male01/answer35.wav",
					[4] = "vo/npc/male01/gordead_ans01.wav",
					[5] = "vo/npc/male01/gordead_ans02.wav",
					[6] = "vo/npc/male01/holddownspot01.wav",
					[7] = "vo/npc/male01/holddownspot02.wav",
					[8] = "vo/npc/male01/illstayhere01.wav",
					[9] = "vo/npc/male01/imstickinghere01.wav",
				},
				["sound"] = {
					["dist"] = 100,
					["restart"] = false,
					["volume"] = 1,
				},
				["type"] = "sound",
			},
		},
		["engineflags"] = {
			[1] = "EFL_NO_DISSOLVE",
		},
		["entity_type"] = "npc",
		["inputs"] = {
			[1] = {
				["command"] = "DisableWeaponPickup",
			},
			[2] = {
				["command"] = "MakeGameEndAlly",
			},
		},
		["material"] = "models/player/shared/gold_player",
		["maxhealth"] = 500,
		["moveact"] = "ACT_WALK",
		["noidle"] = true,
		["npc_state"] = "NPC_STATE_COMBAT",
		["npcd_enabled"] = false,
		["quota_weight"] = 1,
		["regen"] = 1.5,
		["regendelay"] = 1,
		["rendermode"] = "RENDERMODE_TRANSCOLOR",
		["seekout_clear"] = true,
		["spawneffect"] = {
			[1] = {
				["effect_data"] = {
					["normal"] = Vector( 0, 0, 1 ),
					["scale"] = 96,
				},
				["name"] = "ThumperDust",
				["type"] = "effect",
			},
			[2] = {
				["name"] = {
					[1] = "__TBLRANDOM",
					[2] = "vo/npc/male01/hellodrfm01.wav",
					[3] = "vo/npc/male01/hellodrfm02.wav",
					[4] = "vo/npc/male01/heretheycome01.wav",
					[5] = "vo/npc/male01/help01.wav",
					[6] = "vo/npc/male01/overhere01.wav",
					[7] = "vo/npc/female01/hellodrfm01.wav",
					[8] = "vo/npc/female01/hellodrfm02.wav",
					[9] = "vo/npc/female01/heretheycome01.wav",
					[10] = "vo/npc/female01/help01.wav",
					[11] = "vo/npc/female01/overhere01.wav",
				},
				["sound"] = {
					["dist"] = 125,
				},
				["type"] = "sound",
			},
		},
		["spawnflags"] = {
			[1] = "Random Head",
		},
		["spritetrail"] = {
			[1] = {
				["color"] = Color( 214, 184, 87, 142 ),
				["endwidth"] = 1,
				["lifetime"] = 60,
				["startwidth"] = 5,
			},
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Combine Soldier", {
		["VERSION"] = 20,
		["chase_preset"] = {
			[1] = {
				["name"] = "VIP",
				["type"] = "npc",
			},
		},
		["chase_setenemy"] = true,
		["chase_settarget"] = true,
		["classname"] = {
			["name"] = "npc_combine_s",
			["type"] = "NPC",
		},
		["drop_set"] = {
			[1] = {
				["drop_set"] = {
					["name"] = "Low Level Drops",
					["type"] = "drop_set",
				},
			},
		},
		["entity_type"] = "npc",
		["npcd_enabled"] = true,
		["rendermode"] = "RENDERMODE_TRANSCOLOR",
		["spawneffect"] = {
			[1] = {
				["effect_data"] = {
					["normal"] = Vector( 0, 0, 1 ),
					["scale"] = 96,
				},
				["name"] = "ThumperDust",
				["type"] = "effect",
			},
		},
		["spawnflags"] = {
			[1] = "Don\'t drop weapons",
		},
		["tacticalvariant"] = "Pressure the enemy (Keep advancing)",
		["weapon_set"] = {
			["name"] = "HL2 Two-Handed",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Combine Elite", {
		["VERSION"] = 20,
		["chase_preset"] = {
			[1] = {
				["name"] = "VIP",
				["type"] = "npc",
			},
		},
		["chase_setenemy"] = true,
		["chase_settarget"] = true,
		["classname"] = {
			["name"] = "npc_combine_s",
			["type"] = "NPC",
		},
		["drop_set"] = {
			[1] = {
				["drop_set"] = {
					["name"] = "Medium Level Drops",
					["type"] = "drop_set",
				},
			},
		},
		["entity_type"] = "npc",
		["model"] = "models/Combine_Super_Soldier.mdl",
		["npcd_enabled"] = true,
		["rendermode"] = "RENDERMODE_TRANSCOLOR",
		["seekout_clear"] = true,
		["spawneffect"] = {
			[1] = {
				["effect_data"] = {
					["normal"] = Vector( 0, 0, 1 ),
					["scale"] = 96,
				},
				["name"] = "ThumperDust",
				["type"] = "effect",
			},
		},
		["spawnflags"] = {
			[1] = "Don\'t drop weapons",
			[2] = "Don\'t drop AR2 alt fire (Elite only)",
		},
		["tacticalvariant"] = "Pressure the enemy (Keep advancing)",
		["weapon_inherit"] = true,
		["weapon_proficiency"] = "Very Good",
		["weapon_set"] = {
			["name"] = "HL2 AR2/Shotgun",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Metropolice", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_metropolice",
			["type"] = "NPC",
		},
		["drop_set"] = {
			[1] = {
				["drop_set"] = {
					["name"] = "Low Level Drops",
					["type"] = "drop_set",
				},
			},
		},
		["entity_type"] = "npc",
		["manhacks"] = {
			[1] = "__RANDOM",
			[2] = -1,
			[3] = 1,
		},
		["spawnflags"] = {
			[1] = "Don\'t drop weapons",
			[2] = "Arrest enemies",
		},
		["weapon_set"] = {
			["name"] = "HL2 Pistol/SMG",
			["type"] = "weapon_set",
		},
		["weapondrawn"] = true,
	} )

	npcd.InsertPending( profile_name, "npc", "Tumbleweed", {
		["VERSION"] = 20,
		["accelerate"] = {
		},
		["classname"] = {
			["name"] = "npc_rollermine",
			["type"] = "NPC",
		},
		["damagefilter_in"] = {
			[1] = {
				["condition"] = {
					["attacker"] = {
						["types"] = {
							["exclude"] = {
								[1] = "friendly (only if entity can check disposition)",
							},
						},
					},
				},
				["victim"] = {
					["remove"] = true,
				},
			},
		},
		["damagefilter_out"] = {
			[1] = {
				["attacker"] = {
					["remove"] = true,
				},
				["max"] = 0,
			},
		},
		["deathexplode"] = {
			["damage"] = 35,
			["enabled"] = true,
			["radius"] = 180,
		},
		["entity_type"] = "npc",
		["killonremove"] = true,
		["material"] = "models/combine_helicopter/helicopter_bomb01",
		["model"] = "models/combine_helicopter/helicopter_bomb01.mdl",
		["npcd_enabled"] = true,
		["quota_weight"] = 1,
		["seekout_clear"] = true,
		["spawneffect"] = {
		},
		["spritetrail"] = {
			[1] = {
				["color"] = Color( 255, 0, 0 ),
			},
		},
		["start_patrol"] = true,
	} )

	npcd.InsertPending( profile_name, "npc", "Proxy Cop", {
		["VERSION"] = 20,
		["animspeed"] = 2,
		["bloodcolor"] = "DONT_BLEED",
		["bones"] = {
			[1] = {
				["bone"] = "ValveBiped.Bip01_Head1",
				["scale"] = Vector( 0, 0, 0 ),
			},
		},
		["childpreset"] = {
			["name"] = "Brainhack",
			["type"] = "npc",
		},
		["childpreset_replace"] = true,
		["classname"] = {
			["name"] = "npc_metropolice",
			["type"] = "NPC",
		},
		["damagefilter_in"] = {
			[1] = {
				["condition"] = {
					["damage"] = {
						["dmg_types"] = {
							["include"] = {
								[1] = "DMG_CRUSH",
							},
						},
					},
				},
				["max"] = 100,
			},
		},
		["damagescale_in"] = 0.1,
		["damagescale_out"] = 2.5,
		["deatheffect"] = {
			[1] = {
				["name"] = "cball_bounce",
				["type"] = "effect",
			},
		},
		["description"] = "Intended to be used in a squad with \"Hivequeen\" enabled",
		["drop_set"] = {
			[1] = {
				["drop_set"] = {
					["name"] = "Medium Level Drops",
					["type"] = "drop_set",
				},
			},
		},
		["engineflags"] = {
			[1] = "EFL_NO_DISSOLVE",
		},
		["entity_type"] = "npc",
		["manhacks"] = 1,
		["material"] = {
			[1] = "__TBLRANDOM",
			[2] = "models/props_combine/combine_interface_disp",
			[3] = "models/props_combine/combine_intmonitor001_disp",
			[4] = "models/props_combine/combine_monitorbay_disp",
			[5] = "models/props_lab/eyescanner_disp",
		},
		["maxhealth"] = 50,
		["moveact"] = "ACT_RUN",
		["npcd_enabled"] = true,
		["scale"] = 1.25,
		["seekout_clear"] = true,
		["spawneffect"] = {
			[1] = {
				["effect_data"] = {
					["normal"] = Vector( 0, 0, 1 ),
					["scale"] = 96,
				},
				["name"] = "ThumperDust",
				["type"] = "effect",
			},
		},
		["spawnflags"] = {
			[1] = "Don\'t drop weapons",
		},
		["start_patrol"] = true,
		["weapon_proficiency"] = "Very Good",
		["weapon_set"] = {
			["name"] = "HL2 Stunstick",
			["type"] = "weapon_set",
		},
		["weapondrawn"] = true,
	} )

	npcd.InsertPending( profile_name, "squad", "Elitists", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 3,
					["min"] = 3,
				},
				["preset"] = {
					["name"] = "Combine Elitist",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Soldiers", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 3,
					["min"] = 2,
				},
				["preset"] = {
					["name"] = "Combine Soldier",
					["type"] = "npc",
				},
			},
			[2] = {
				["count"] = {
					["max"] = 1,
					["median"] = 0,
					["min"] = 0,
				},
				["preset"] = {
					["name"] = "Combine Elite",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Metropolices", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 3,
					["min"] = 1,
				},
				["preset"] = {
					["name"] = "Metropolice",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Elite Soldiers", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 3,
					["min"] = 2,
				},
				["preset"] = {
					["name"] = "Combine Elite",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Marker", {
		["VERSION"] = 20,
		["description"] = "VIP will attempt to reach the destination marker",
		["mapmin"] = 1,
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 1,
					["min"] = 1,
				},
				["preset"] = {
					["name"] = "Destination",
					["type"] = "entity",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "VIP", {
		["VERSION"] = 20,
		["announce_all"] = true,
		["announce_death_message"] = "The VIP has died!",
		["announce_spawn_message"] = "The VIP has arrived, protect them!",
		["description"] = "Protect the VIP.. or else!",
		["hivequeen_maxdist"] = 2,
		["mapmin"] = 1,
		["npcd_enabled"] = true,
		["spawnforce"] = {
			["forward"] = {
				[1] = "__RAND",
				[2] = 0,
				[3] = 0,
			},
			["up"] = 0,
		},
		["spawnlist"] = {
			[1] = {
				["preset"] = {
					["name"] = "VIP",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "No-Brainer", {
		["VERSION"] = 20,
		["description"] = "Cop with its brain on a leash",
		["hivequeen"] = {
			["name"] = "Brainhack",
			["type"] = "npc",
		},
		["hivequeen_maxdist"] = 6000,
		["hivequeen_mutual"] = true,
		["hiverope"] = {
			[1] = {
				["attachment_queen"] = 0,
			},
		},
		["npcd_enabled"] = true,
		["spawnforce"] = {
			["forward"] = 0,
		},
		["spawnlist"] = {
			[1] = {
				["preset"] = {
					["name"] = "Proxy Cop",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Bombing Run", {
		["VERSION"] = 20,
		["announce_color"] = {
			[1] = "__RANDOMCOLOR",
			[3] = 0,
			[4] = 0,
			[5] = 0,
			[6] = 0.2,
			[7] = 0.5,
		},
		["announce_death"] = false,
		["announce_spawn"] = true,
		["announce_spawn_message"] = "Initiating bombing run...",
		["fadein"] = false,
		["nocollide"] = true,
		["npcd_enabled"] = true,
		["spawnforce"] = {
			["forward"] = 0,
			["up"] = 0,
		},
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 5,
					["median"] = 8,
					["min"] = 10,
				},
				["preset"] = {
					["name"] = "Tumbleweed",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squadpool", "Enemies", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["onlybeacons"] = true,
		["override_soft"] = {
			["npc"] = {
				["chase_preset"] = {
					[1] = {
						["name"] = "VIP",
						["type"] = "npc",
					},
				},
			},
		},
		["pool_spawnlimit"] = 30,
		["radiuslimits"] = {
			[1] = {
				["despawn"] = false,
				["maxradius"] = 7500,
				["minradius"] = 3000,
				["radius_autoadjust_max"] = true,
				["radius_autoadjust_min"] = false,
				["radius_entity_limit"] = 25,
				["radius_spawn_autoadjust"] = true,
			},
			[2] = {
				["despawn"] = true,
				["despawn_ignorenear"] = 1250,
				["maxradius"] = 32768,
				["minradius"] = 3000,
				["radius_autoadjust_max"] = true,
			},
		},
		["spawn_autoadjust"] = true,
		["spawns"] = {
			[1] = {
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "Soldiers",
					["type"] = "squad",
				},
			},
			[2] = {
				["expected"] = {
					["d"] = 2,
					["f"] = 0.5,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "Metropolices",
					["type"] = "squad",
				},
			},
			[3] = {
				["expected"] = {
					["d"] = 20,
					["f"] = 0.15,
					["n"] = 3,
				},
				["preset"] = {
					["name"] = "Elite Soldiers",
					["type"] = "squad",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squadpool", "Bosses", {
		["VERSION"] = 20,
		["initdelay"] = {
			[1] = "__RAND",
			[2] = 45,
			[3] = 75,
		},
		["mindelay"] = {
			[1] = "__RAND",
			[2] = 45,
			[3] = 90,
		},
		["minpressure"] = 0.3,
		["npcd_enabled"] = true,
		["onlybeacons"] = true,
		["override_hard"] = {
			["squad"] = {
				["announce_all"] = true,
				["mapmax"] = 1,
			},
		},
		["override_soft"] = {
			["all"] = {
				["stress_mult"] = 2,
			},
			["npc"] = {
				["chase_preset"] = {
					[1] = {
						["name"] = "VIP",
						["type"] = "npc",
					},
				},
			},
		},
		["pool_squadlimit"] = 4,
		["radiuslimits"] = {
			[1] = {
				["maxradius"] = 7500,
				["minradius"] = 2000,
				["radius_autoadjust_min"] = false,
			},
		},
		["spawn_autoadjust"] = false,
		["spawns"] = {
			[1] = {
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "Elitists",
					["type"] = "squad",
				},
			},
			[2] = {
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "No-Brainer",
					["type"] = "squad",
				},
			},
			[3] = {
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "Bombing Run",
					["type"] = "squad",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squadpool", "VIPs", {
		["VERSION"] = 20,
		["pool_squadlimit"] = 1,
		["quota_squad_min"] = 128,
		["radiuslimits"] = {
			[1] = {
				["despawn"] = false,
				["maxradius"] = 2000,
				["minradius"] = 500,
				["radius_autoadjust_max"] = false,
				["radius_autoadjust_min"] = false,
				["radius_spawn_autoadjust"] = false,
				["spawn_tooclose"] = 150,
			},
		},
		["spawn_autoadjust"] = false,
		["spawns"] = {
			[1] = {
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "VIP",
					["type"] = "squad",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squadpool", "Markers", {
		["VERSION"] = 20,
		["pool_squadlimit"] = 1,
		["quota_squad_min"] = 1,
		["radiuslimits"] = {
			[1] = {
				["despawn"] = false,
				["maxradius"] = 600,
				["minradius"] = 0,
				["radius_autoadjust_max"] = false,
				["radius_autoadjust_min"] = false,
				["radius_spawn_autoadjust"] = false,
				["spawn_tooclose"] = 150,
			},
		},
		["spawn_autoadjust"] = false,
		["spawns"] = {
			[1] = {
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "Marker",
					["type"] = "squad",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "Ammo Drop", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "item_ammo_357",
					["type"] = "SpawnableEntities",
				},
				["expected"] = {
					["d"] = 5,
					["f"] = 0.4,
					["n"] = 2,
				},
			},
			[2] = {
				["classname"] = {
					["name"] = "item_ammo_ar2",
					["type"] = "SpawnableEntities",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[3] = {
				["classname"] = {
					["name"] = "item_ammo_ar2_altfire",
					["type"] = "SpawnableEntities",
				},
				["expected"] = {
					["d"] = 4,
					["f"] = 0.25,
					["n"] = 1,
				},
			},
			[4] = {
				["classname"] = {
					["name"] = "item_ammo_crossbow",
					["type"] = "SpawnableEntities",
				},
				["expected"] = {
					["d"] = 25,
					["f"] = 0.32,
					["n"] = 8,
				},
			},
			[5] = {
				["classname"] = {
					["name"] = "item_ammo_pistol",
					["type"] = "SpawnableEntities",
				},
				["expected"] = {
					["d"] = 10,
					["f"] = 0.7,
					["n"] = 7,
				},
			},
			[6] = {
				["classname"] = {
					["name"] = "item_ammo_smg1",
					["type"] = "SpawnableEntities",
				},
				["expected"] = {
					["d"] = 5,
					["f"] = 1.2,
					["n"] = 6,
				},
			},
			[7] = {
				["classname"] = {
					["name"] = "item_ammo_smg1_grenade",
					["type"] = "SpawnableEntities",
				},
				["expected"] = {
					["d"] = 4,
					["f"] = 0.25,
					["n"] = 1,
				},
			},
			[8] = {
				["classname"] = {
					["name"] = "item_box_buckshot",
					["type"] = "SpawnableEntities",
				},
				["expected"] = {
					["d"] = 10,
					["f"] = 0.7,
					["n"] = 7,
				},
			},
			[9] = {
				["classname"] = {
					["name"] = "item_rpg_round",
					["type"] = "SpawnableEntities",
				},
				["expected"] = {
					["d"] = 4,
					["f"] = 0.25,
					["n"] = 1,
				},
			},
			[10] = {
				["classname"] = {
					["name"] = "weapon_frag",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 20,
					["f"] = 0.35,
					["n"] = 7,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "HL2 Pistol/SMG", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "weapon_pistol",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 5,
					["f"] = 0.8,
					["n"] = 4,
				},
			},
			[2] = {
				["classname"] = {
					["name"] = "weapon_smg1",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 10,
					["f"] = 0.3,
					["n"] = 3,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "HL2 AR2/Shotgun", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "weapon_ar2",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 10,
					["f"] = 0.7,
					["n"] = 7,
				},
			},
			[2] = {
				["classname"] = {
					["name"] = "weapon_shotgun",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 10,
					["f"] = 0.3,
					["n"] = 3,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "HL2 Two-Handed", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "weapon_smg1",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 25,
					["f"] = 0.72,
					["n"] = 18,
				},
			},
			[2] = {
				["classname"] = {
					["name"] = "weapon_ar2",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 10,
					["f"] = 0.3,
					["n"] = 3,
				},
			},
			[3] = {
				["classname"] = {
					["name"] = "weapon_shotgun",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 25,
					["f"] = 0.08,
					["n"] = 2,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "entity", "Destination", {
		["VERSION"] = 20,
		["angle"] = Angle( 0, 0, 90 ),
		["classname"] = "prop_physics",
		["description"] = "Note: Physics collisions override normal touch behavior for some items (e.g. health kits)",
		["entity_type"] = "entity",
		["model"] = "models/props_c17/streetsign004e.mdl",
		["npcd_enabled"] = true,
		["offset"] = Vector( 0, 0, -25 ),
		["regendelay"] = 1,
		["spawnflags"] = {
			[1] = "Debris - Don\'t collide with the player or other debris",
		},
	} )

	npcd.StartSettingsPanel()

end )

return profile_name