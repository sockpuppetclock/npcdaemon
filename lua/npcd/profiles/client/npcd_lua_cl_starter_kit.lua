// (CLIENT) starter kit

if !CLIENT then return false end
if !npcd.CheckClientPerm2( LocalPlayer(), "profiles" ) then return false end

// The function will insert the presets as pending changes into the given profile.

// Returns existing profile or creates empty profile
// 1st arg: profile name, or generic name if nil.
// 2nd arg: always create a new profile (true) or return the name without changes if existing (false/nil)
local profile_name = npcd.ClientCreateEmptyProfile( "starter kit", true ) // set profile_name to nil to insert into the currently active profile

-- npcd.ClientClearProfile( profile_name ) // (optional) empty out existing profile
-- npcd.ClientSwitchProfile( profile_name ) // (optional) set as active profile

-- npcd.QuerySettings()
// runs function once after profiles update is received
// 1st arg: profile that must exist before it can run, or nil for no requirement
npcd.QueuePostQuery( profile_name, 30, function()
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

	npcd.InsertPending( profile_name, "drop_set", "Simple Drop", {
		["VERSION"] = 20,
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
					["d"] = 9,
					["f"] = 0.11111111111111,
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
					["d"] = 8,
					["f"] = 0.125,
					["n"] = 1,
				},
				["destroydelay"] = 180,
				["entity_values"] = {
					["classname"] = {
						["name"] = "item_healthkit",
						["type"] = "SpawnableEntities",
					},
				},
				["type"] = "entity",
			},
			[4] = {
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

	npcd.InsertPending( profile_name, "npc", "Dr. Arne Magnusson", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_magnusson",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Zombie", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_zombie",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Refugee", {
		["VERSION"] = 20,
		["citizentype"] = "Refugee",
		["classname"] = {
			["name"] = "npc_citizen",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["weapon_set"] = {
			["name"] = "HL2 Pistol/SMG",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Uriah", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_vortigaunt",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["model"] = "models/vortigaunt_doctor.mdl",
	} )

	npcd.InsertPending( profile_name, "npc", "Strider", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_strider",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["offset"] = Vector( 0, 0, 100 ),
	} )

	npcd.InsertPending( profile_name, "npc", "Dog", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_dog",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Poison Zombie", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_poisonzombie",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Ceiling Turret", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_turret_ceiling",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["spawn_ceiling"] = true,
		["spawnflags"] = 32,
	} )

	npcd.InsertPending( profile_name, "npc", "Headcrab", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_headcrab",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Father Grigori", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_monk",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["weapon_set"] = {
			["name"] = "HL2 Annabelle",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Citizen", {
		["VERSION"] = 20,
		["citizentype"] = "Downtrodden",
		["classname"] = {
			["name"] = "npc_citizen",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Seagull", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_seagull",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Stalker", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_stalker",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["keyvalues"] = {
			[1] = {
				["key"] = "squadname",
				["value"] = "npc_stalker_squad",
			},
		},
		["offset"] = Vector( 0, 0, 10 ),
	} )

	npcd.InsertPending( profile_name, "npc", "Crow", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_crow",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Barney Calhoun", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_barney",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["weapon_set"] = {
			["name"] = "HL2 Two-Handed",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Alyx Vance", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_alyx",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["weapon_set"] = {
			["name"] = "HL2 Alyx Vance Weapons",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Zombine", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_zombine",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Wallace Breen", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_breen",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Rollermine", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_rollermine",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["offset"] = Vector( 0, 0, 20 ),
	} )

	npcd.InsertPending( profile_name, "npc", "Fast Zombie", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_fastzombie",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Antlion Worker", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_antlion_worker",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Hunter", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_hunter",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Antlion Guardian", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_antlionguard",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["keyvalues"] = {
			[1] = {
				["key"] = "cavernbreed",
				["value"] = 1,
			},
			[2] = {
				["key"] = "incavern",
				["value"] = 1,
			},
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Dr. Isaac Kleiner", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_kleiner",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Shield Scanner", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_clawscanner",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["offset"] = Vector( 0, 0, 20 ),
	} )

	npcd.InsertPending( profile_name, "npc", "Manhack", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_manhack",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Pigeon", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_pigeon",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Antlion Guard", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_antlionguard",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Poison Headcrab", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_headcrab_black",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Fast Headcrab", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_headcrab_fast",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Vortigaunt", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_vortigaunt",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Rebel", {
		["VERSION"] = 20,
		["citizentype"] = "Rebel",
		["classname"] = {
			["name"] = "npc_citizen",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["spawnflags"] = 262144,
		["weapon_set"] = {
			["name"] = "HL2 Rebel Weapons",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Combine Soldier", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_combine_s",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["keyvalues"] = {
			[1] = {
				["key"] = "Numgrenades",
				["value"] = 5,
			},
		},
		["model"] = "models/combine_soldier.mdl",
		["weapon_set"] = {
			["name"] = "HL2 AR2/SMG",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Antlion", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_antlion",
			["type"] = "NPC",
		},
		["drop_set"] = {
			[1] = {
				["drop_set"] = {
					["name"] = "Simple Drop",
					["type"] = "drop_set",
				},
			},
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "City Scanner", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_cscanner",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["offset"] = Vector( 0, 0, 20 ),
	} )

	npcd.InsertPending( profile_name, "npc", "Medic", {
		["VERSION"] = 20,
		["citizentype"] = "Rebel",
		["classname"] = {
			["name"] = "npc_citizen",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["spawnflags"] = 131080,
		["weapon_set"] = {
			["name"] = "HL2 Rebel Weapons",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Combine Gunship", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_combinegunship",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["offset"] = Vector( 0, 0, 300 ),
	} )

	npcd.InsertPending( profile_name, "npc", "Prison Shotgun Guard", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_combine_s",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["keyvalues"] = {
			[1] = {
				["key"] = "Numgrenades",
				["value"] = 5,
			},
		},
		["model"] = "models/combine_soldier_prisonguard.mdl",
		["skin"] = 1,
		["weapon_set"] = {
			["name"] = "HL2 Shotgun",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Shotgun Soldier", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_combine_s",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["keyvalues"] = {
			[1] = {
				["key"] = "Numgrenades",
				["value"] = 5,
			},
		},
		["model"] = "models/combine_soldier.mdl",
		["skin"] = 1,
		["weapon_set"] = {
			["name"] = "HL2 Shotgun",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Vortigaunt Slave", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_vortigaunt",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["model"] = "models/vortigaunt_slave.mdl",
	} )

	npcd.InsertPending( profile_name, "npc", "Antlion Grub", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_antlion_grub",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["offset"] = Vector( 0, 0, 1 ),
	} )

	npcd.InsertPending( profile_name, "npc", "Metro Police", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_metropolice",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["manhacks"] = {
			[1] = "__RANDOM",
			[2] = 0,
			[3] = 0,
		},
		["weapon_set"] = {
			["name"] = "HL2 Metro Police Weapons",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Turret", {
		["VERSION"] = 20,
		["angle"] = Angle( 0, 180, 0 ),
		["classname"] = {
			["name"] = "npc_turret_floor",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["offset"] = Vector( 0, 0, 2 ),
	} )

	npcd.InsertPending( profile_name, "npc", "Hunter-Chopper", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_helicopter",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["maxhealth"] = 600,
		["offset"] = Vector( 0, 0, 300 ),
	} )

	npcd.InsertPending( profile_name, "npc", "Eli Vance", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_eli",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Dr. Judith Mossman", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_mossman",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Combine Dropship", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_combinedropship",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["offset"] = Vector( 0, 0, 300 ),
	} )

	npcd.InsertPending( profile_name, "npc", "Camera", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_combine_camera",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
      ["spawn_ceiling"] = true,
	} )

	npcd.InsertPending( profile_name, "npc", "G-Man", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_gman",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Fast Zombie Torso", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_fastzombie_torso",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Zombie Torso", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_zombie_torso",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
	} )

	npcd.InsertPending( profile_name, "npc", "Combine Elite", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_combine_s",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["keyvalues"] = {
			[1] = {
				["key"] = "Numgrenades",
				["value"] = 10,
			},
		},
		["model"] = "models/combine_super_soldier.mdl",
		["spawnflags"] = 16384,
		["weapon_set"] = {
			["name"] = "HL2 AR2",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Prison Guard", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_combine_s",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["keyvalues"] = {
			[1] = {
				["key"] = "Numgrenades",
				["value"] = 5,
			},
		},
		["model"] = "models/combine_soldier_prisonguard.mdl",
		["weapon_set"] = {
			["name"] = "HL2 AR2/SMG",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Barnacle", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_barnacle",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
      ["spawn_ceiling"] = true,
	} )

	npcd.InsertPending( profile_name, "npc", "Odessa Cubbage", {
		["VERSION"] = 20,
		["citizentype"] = "Unique",
		["classname"] = {
			["name"] = "npc_citizen",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["model"] = "models/odessa.mdl",
	} )

	npcd.InsertPending( profile_name, "squad", "Rebel Squad", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["spawnforce"] = {
		},
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 2,
					["median"] = 1,
					["min"] = 1,
				},
				["preset"] = {
					["name"] = "Rebel",
					["type"] = "npc",
				},
			},
			[2] = {
				["chance"] = {
					["d"] = 2,
					["f"] = 0.5,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "Medic",
					["type"] = "npc",
				},
			},
			[3] = {
				["chance"] = {
					["d"] = 10,
					["f"] = 0.1,
					["n"] = 1,
				},
				["count"] = {
					["min"] = 1,
				},
				["preset"] = {
					["name"] = "Refugee",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Fast Zombies", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["spawnforce"] = {
			LOOKUP_REROLL = {
				["forward"] = true,
			},
			["forward"] = {
				[1] = "__RAND",
				[2] = 400,
				[3] = 800,
			},
			["rotrandom"] = true,
		},
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 2,
					["min"] = 1,
				},
				["preset"] = {
					["name"] = "Fast Zombie",
					["type"] = "npc",
				},
			},
			[2] = {
				["chance"] = {
					["d"] = 10,
					["f"] = 0.1,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "Fast Zombie Torso",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Metro Police Squad", {
		["VERSION"] = 20,
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 3,
					["min"] = 1,
				},
				["preset"] = {
					["name"] = "Metro Police",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Antlions", {
		["VERSION"] = 20,
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 3,
					["min"] = 2,
				},
				["preset"] = {
					["name"] = "Antlion",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Zombies", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["spawnforce"] = {
			LOOKUP_REROLL = {
				["forward"] = true,
			},
			["forward"] = {
				[1] = "__RAND",
				[2] = 400,
				[3] = 800,
			},
			["rotrandom"] = true,
		},
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 4,
					["min"] = 2,
				},
				["preset"] = {
					["name"] = "Zombie",
					["type"] = "npc",
				},
			},
			[2] = {
				["chance"] = {
					["d"] = 10,
					["f"] = 0.1,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "Zombie Torso",
					["type"] = "npc",
				},
			},
			[3] = {
				["chance"] = {
					["d"] = 6,
					["f"] = 0.16666666666667,
					["n"] = 1,
				},
				["count"] = {
					["max"] = 2,
					["min"] = 1,
				},
				["preset"] = {
					["name"] = "Zombine",
					["type"] = "npc",
				},
			},
			[4] = {
				["chance"] = {
					["d"] = 12,
					["f"] = 0.083333333333333,
					["n"] = 1,
				},
				["count"] = {
					["max"] = 1,
					["min"] = 1,
				},
				["preset"] = {
					["name"] = "Poison Zombie",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Combine Squad", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["spawnforce"] = {
		},
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 3,
					["min"] = 1,
				},
				["preset"] = {
					["name"] = "Combine Soldier",
					["type"] = "npc",
				},
			},
			[2] = {
				["chance"] = {
					["d"] = 7,
					["f"] = 0.14285714285714,
					["n"] = 1,
				},
				["count"] = {
					["max"] = 1,
					["min"] = 1,
				},
				["preset"] = {
					["name"] = "Combine Elite",
					["type"] = "npc",
				},
			},
			[3] = {
				["chance"] = {
					["d"] = 5,
					["f"] = 0.2,
					["n"] = 1,
				},
				["count"] = {
					["max"] = 2,
					["min"] = 1,
				},
				["preset"] = {
					["name"] = "Shotgun Soldier",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "spawnpool", "Normal", {
		["VERSION"] = 20,
		["description"] = "This pool\'s radius limits are designed to control the entity population near the player while still allowing larger counts across the entire map. Drop sets and max squad limits are applied to all squads through pool overrides.",
		["npcd_enabled"] = true,
		["override_soft"] = {
			["npc"] = {
				["drop_set"] = {
					[1] = {
						["drop_set"] = {
							["name"] = "Simple Drop",
							["type"] = "drop_set",
						},
					},
				},
			},
			["squad"] = {
				["mapmax"] = 10,
			},
		},
		["pool_spawnlimit"] = 90,
		["radiuslimits"] = {
			[1] = {
				["despawn"] = false,
				["maxradius"] = 2750,
				["minradius"] = 1250,
				["radius_autoadjust_max"] = true,
				["radius_autoadjust_min"] = true,
				["radius_entity_limit"] = 15,
				["radius_spawn_autoadjust"] = false,
			},
			[2] = {
				["despawn"] = false,
				["maxradius"] = 7500,
				["minradius"] = 2750,
				["radius_autoadjust_max"] = true,
				["radius_autoadjust_min"] = true,
				["radius_entity_limit"] = 35,
				["radius_spawn_autoadjust"] = true,
			},
			[3] = {
				["despawn"] = true,
				["despawn_tooclose"] = 3000,
				["maxradius"] = 32768,
				["minradius"] = 0,
				["nospawn"] = true,
				["radius_autoadjust_max"] = true,
				["radius_autoadjust_min"] = true,
				["radius_spawn_autoadjust"] = true,
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
					["name"] = "Rebel Squad",
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
					["name"] = "Fast Zombies",
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
					["name"] = "Metro Police Squad",
					["type"] = "squad",
				},
			},
			[4] = {
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "Antlions",
					["type"] = "squad",
				},
			},
			[5] = {
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "Zombies",
					["type"] = "squad",
				},
			},
			[6] = {
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "Combine Squad",
					["type"] = "squad",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "HL2 Stunstick", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "weapon_stunstick",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "Ammo Special Drop", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "weapon_frag",
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
					["name"] = "item_ammo_smg1_grenade",
					["type"] = "SpawnableEntities",
				},
				["expected"] = {
					["d"] = 20,
					["f"] = 0.65,
					["n"] = 13,
				},
			},
			[3] = {
				["classname"] = {
					["name"] = "item_rpg_round",
					["type"] = "SpawnableEntities",
				},
				["expected"] = {
					["d"] = 2,
					["f"] = 0.5,
					["n"] = 1,
				},
			},
			[4] = {
				["classname"] = {
					["name"] = "item_ammo_ar2_altfire",
					["type"] = "SpawnableEntities",
				},
				["expected"] = {
					["d"] = 2,
					["f"] = 0.5,
					["n"] = 1,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "#GMOD_Camera", {
		["VERSION"] = 20,
		["weapons"] = {
			[1] = {
				["classname"] = "gmod_camera",
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "HL2 Pistol", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "weapon_pistol",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
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

	npcd.InsertPending( profile_name, "weapon_set", "HL2 Crowbar", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "weapon_crowbar",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "HL2 Shotgun", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "weapon_shotgun",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "HL2 AR2", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "weapon_ar2",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "HL2 One-Handed", {
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
					["name"] = "weapon_357",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 5,
					["f"] = 0.2,
					["n"] = 1,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "HL2 RPG", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "weapon_rpg",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "#GMOD_Fists", {
		["VERSION"] = 20,
		["weapons"] = {
			[1] = {
				["classname"] = "weapon_fists",
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "HL2 Rebel Weapons", {
		["VERSION"] = 20,
		["weapons"] = {
			[1] = {
				["classname"] = "weapon_pistol",
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[2] = {
				["classname"] = "weapon_ar2",
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[3] = {
				["classname"] = "weapon_smg1",
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "#GMOD_ManhackGun", {
		["VERSION"] = 20,
		["weapons"] = {
			[1] = {
				["classname"] = "manhack_welder",
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "No Weapon", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["removeall"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "none",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "HL2 Metro Police Weapons", {
		["VERSION"] = 20,
		["weapons"] = {
			[1] = {
				["classname"] = "weapon_stunstick",
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[2] = {
				["classname"] = "weapon_pistol",
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[3] = {
				["classname"] = "weapon_smg1",
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "#GMOD_ToolGun", {
		["VERSION"] = 20,
		["weapons"] = {
			[1] = {
				["classname"] = "gmod_tool",
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
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

	npcd.InsertPending( profile_name, "weapon_set", "HL2 Weapons", {
		["VERSION"] = 20,
		["giveall"] = true,
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "weapon_357",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[2] = {
				["classname"] = {
					["name"] = "weapon_ar2",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[3] = {
				["classname"] = {
					["name"] = "weapon_bugbait",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[4] = {
				["classname"] = {
					["name"] = "weapon_crossbow",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[5] = {
				["classname"] = {
					["name"] = "weapon_crowbar",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[6] = {
				["classname"] = {
					["name"] = "weapon_frag",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[7] = {
				["classname"] = {
					["name"] = "weapon_physcannon",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[8] = {
				["classname"] = {
					["name"] = "weapon_pistol",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[9] = {
				["classname"] = {
					["name"] = "weapon_rpg",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[10] = {
				["classname"] = {
					["name"] = "weapon_shotgun",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[11] = {
				["classname"] = {
					["name"] = "weapon_slam",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[12] = {
				["classname"] = {
					["name"] = "weapon_smg1",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[13] = {
				["classname"] = {
					["name"] = "weapon_stunstick",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
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

	npcd.InsertPending( profile_name, "weapon_set", "HL2 AR2/SMG", {
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
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "#GMOD_FlechetteGun", {
		["VERSION"] = 20,
		["weapons"] = {
			[1] = {
				["classname"] = "weapon_flechettegun",
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "Melee", {
		["VERSION"] = 20,
		["description"] = "All melee weapons. Could be used to test for melee weapons in damage filters.",
		["giveall"] = true,
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "weapon_crowbar",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[2] = {
				["classname"] = {
					["name"] = "weapon_stunstick",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[3] = {
				["classname"] = {
					["name"] = "weapon_fists",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "HL2 SMG", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "weapon_smg1",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "#GMOD_MedKit", {
		["VERSION"] = 20,
		["weapons"] = {
			[1] = {
				["classname"] = "weapon_medkit",
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "HL2 Annabelle", {
		["VERSION"] = 20,
		["weapons"] = {
			[1] = {
				["classname"] = "weapon_annabelle",
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "HL2 Alyx Vance Weapons", {
		["VERSION"] = 20,
		["weapons"] = {
			[1] = {
				["classname"] = "weapon_alyxgun",
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[2] = {
				["classname"] = "weapon_smg1",
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
			},
			[3] = {
				["classname"] = "weapon_shotgun",
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
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

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: Helicopter Grenade", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "grenade_helicopter",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Editors: Sun Editor", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "edit_sun",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: Magnusson", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "weapon_striderbuster",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Fun + Games: Bouncy Ball", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "sent_ball",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: SMG Grenade", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "item_ammo_smg1_grenade",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: AR2 Ammo", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "item_ammo_ar2",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: Zombine Grenade", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_grenade_frag",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: RPG Rocket", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "item_rpg_round",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: Combine Mine", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "combine_mine",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: AR2 Ammo (Large)", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "item_ammo_ar2_large",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: Thumper", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "prop_thumper",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Editors: Sky Editor", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "edit_sky",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: Suit Charger", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "item_suitcharger",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Editors: Fog Editor", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "edit_fog",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: Health Kit", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "item_healthkit",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: Pistol Ammo", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "item_ammo_pistol",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: Crossbow Bolts", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "item_ammo_crossbow",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: Health Charger", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "item_healthcharger",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: Shotgun Ammo", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "item_box_buckshot",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: Health Vial", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "item_healthvial",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: 357 Ammo (Large)", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "item_ammo_357_large",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: HEV Suit", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "item_suit",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: AR2 Orb", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "item_ammo_ar2_altfire",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: Suit Battery", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "item_battery",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: 357 Ammo", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "item_ammo_357",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: Pistol Ammo (Large)", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "item_ammo_pistol_large",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: SMG Ammo (Large)", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "item_ammo_smg1_large",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.InsertPending( profile_name, "entity", "Half-Life 2: SMG Ammo", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "item_ammo_smg1",
			["type"] = "SpawnableEntities",
		},
		["entity_type"] = "entity",
		["offset"] = Vector( 0, 0, 32 ),
	} )

	npcd.StartSettingsPanel()

end )

return profile_name