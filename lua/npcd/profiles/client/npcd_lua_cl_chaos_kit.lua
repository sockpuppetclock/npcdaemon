// (CLIENT) chaos kit

if !CLIENT then return false end
if !npcd.CheckClientPerm2( LocalPlayer(), "profiles" ) then return false end

// The function will insert the presets as pending changes into the given profile.

// Returns existing profile or creates empty profile
// 1st arg: profile name, or generic name if nil.
// 2nd arg: always create a new profile (true) or return the name without changes if existing (false/nil)
local profile_name = npcd.ClientCreateEmptyProfile( "chaos kit", true ) // set profile_name to nil to insert into the currently active profile

-- npcd.ClientClearProfile( profile_name ) // (optional) empty out existing profile
-- npcd.ClientSwitchProfile( profile_name ) // (optional) set as active profile

-- npcd.QuerySettings()
// runs function once after profiles update is received
// 1st arg: profile that must exist before it can run, or nil for no requirement
npcd.QueuePostQuery( profile_name, 30, function()
	npcd.InsertPending( profile_name, "player", "Kill Bonus", {
		["VERSION"] = 20,
		["damagefilter_post_out"] = {
			[1] = {
				["attacker"] = {
					["effects"] = {
						[1] = {
							["name"] = "items/smallmedkit1.wav",
							["sound"] = {
								["pitch"] = {
									[1] = "__RAND",
									[2] = 95,
									[3] = 105,
								},
							},
							["type"] = "sound",
						},
					},
					["heal"] = 1.65,
				},
				["condition"] = {
					["victim"] = {
						["health_lesser"] = 0,
					},
				},
			},
		},
		["description"] = "Health on kill",
		["entity_type"] = "player",
		["expected"] = {
			["d"] = 1,
			["f"] = 1,
			["n"] = 1,
		},
		["npcd_enabled"] = true,
	} )

	npcd.InsertPending( profile_name, "player", "Hunger", {
		["VERSION"] = 20,
		["damagefilter_out"] = {
			[1] = {
				["attacker"] = {
					["leech"] = 0.12,
				},
			},
		},
		["description"] = "Increased max health & armor, damage dealt restores your health, but you constantly bleed health and armor",
		["entity_type"] = "player",
		["expected"] = {
			["d"] = 1,
			["f"] = 1,
			["n"] = 1,
		},
		["maxarmor"] = 999,
		["maxhealth"] = 999,
		["npcd_enabled"] = true,
		["numhealth"] = 100,
		["regen"] = -1,
	} )

	npcd.InsertPending( profile_name, "player", "Headshots Only", {
		["VERSION"] = 20,
		["damagefilter_hitbox_out"] = {
			[1] = {
				["damagefilter"] = {
					[1] = {
						["condition"] = {
							["victim"] = {
								["types"] = {
									["exclude"] = {
									},
									["include"] = {
										[1] = "character",
									},
								},
							},
						},
						["damagescale"] = 0,
					},
				},
				["hitgroups"] = {
					["exclude"] = {
						[1] = "HITGROUP_HEAD",
					},
				},
			},
			[2] = {
				["damagefilter"] = {
					[1] = {
						["damagescale"] = 1.5,
					},
				},
				["hitgroups"] = {
					["include"] = {
						[1] = "HITGROUP_HEAD",
					},
				},
			},
		},
		["damagefilter_out"] = {
			[1] = {
				["condition"] = {
					["attacker"] = {
						["weapon_sets"] = {
							["include"] = {
								[1] = {
									["name"] = "Melee",
									["type"] = "weapon_set",
								},
							},
						},
					},
				},
				["victim"] = {
					["takedamage"] = 10,
				},
			},
		},
		["entity_type"] = "player",
		["expected"] = {
			["d"] = 1,
			["f"] = 1,
			["n"] = 1,
		},
		["npcd_enabled"] = true,
		["weapon_sets"] = {
			[1] = {
				["name"] = "Full Mangun",
				["type"] = "weapon_set",
			},
		},
	} )

	npcd.InsertPending( profile_name, "player", "Low Gravity", {
		["VERSION"] = 20,
		["entity_type"] = "player",
		["expected"] = {
			["d"] = 1,
			["f"] = 1,
			["n"] = 1,
		},
		["jumppower"] = 400,
		["laggedmove"] = 0.5,
		["relationships_inward"] = {
			["everyone"] = {
				["disposition"] = "Hostile",
			},
		},
		["runspeed"] = 800,
		["slowwalkspeed"] = 200,
		["walkspeed"] = 400,
	} )

	npcd.InsertPending( profile_name, "player", "Go Fast", {
		["VERSION"] = 20,
		["accelerate"] = {
			["accel_rate"] = 150,
			["accel_threshold"] = 1500,
			["movekeys"] = true,
			["player_lerp_relative"] = true,
		},
		["description"] = "Accelerate whenever moving",
		["entity_type"] = "player",
		["expected"] = {
			["d"] = 1,
			["f"] = 1,
			["n"] = 1,
		},
		["npcd_enabled"] = true,
	} )

	npcd.InsertPending( profile_name, "player", "Cool Materials", {
		["VERSION"] = 20,
		["description"] = "Player model materials",
		["entity_type"] = "player",
		["expected"] = {
			["d"] = 1,
			["f"] = 1,
			["n"] = 1,
		},
		["material"] = "Cool Materials",
		["npcd_enabled"] = true,
		["rendercolor"] = {
			[1] = "__RANDOMCOLOR",
		},
	} )

	npcd.InsertPending( profile_name, "player", "High Impact", {
		["VERSION"] = 20,
		["accelerate"] = {
			["accel_rate"] = 80,
			["accel_threshold"] = 1500,
			["player_lerp"] = 0.92959770114943,
		},
		["damagefilter_in"] = {
			[1] = {
				["condition"] = {
					["attacker"] = {
						["classnames"] = {
							["include"] = {
								[1] = "prop_physics",
							},
						},
					},
					["victim"] = {
						["velocity_greater"] = 600,
					},
				},
				["damagescale"] = 0.1,
			},
			[2] = {
				["condition"] = {
					["attacker"] = {
						["classnames"] = {
							["include"] = {
								[1] = "prop_physics",
							},
						},
					},
					["victim"] = {
						["velocity_greater"] = 800,
					},
				},
				["damagescale"] = 0.035,
			},
			[3] = {
				["condition"] = {
					["attacker"] = {
						["classnames"] = {
							["include"] = {
								[1] = "prop_physics",
							},
						},
					},
					["victim"] = {
						["velocity_greater"] = 1000,
					},
				},
				["damagescale"] = 0.01,
			},
		},
		["damagefilter_out"] = {
			[1] = {
				["attacker"] = {
					["effects"] = {
						[1] = {
							["name"] = {
								[1] = "__TBLRANDOM",
								[2] = "weapons/mortar/mortar_explode1.wav",
								[3] = "weapons/mortar/mortar_explode2.wav",
								[4] = "weapons/mortar/mortar_explode3.wav",
							},
							["sound"] = {
								["restart"] = true,
							},
							["type"] = "sound",
						},
					},
				},
				["condition"] = {
					["attacker"] = {
						["velocity_greater"] = 1000,
						["weapon_sets"] = {
							["include"] = {
								[1] = {
									["name"] = "Melee",
									["type"] = "weapon_set",
								},
							},
						},
					},
					["victim"] = {
						["types"] = {
							["exclude"] = {
								[1] = "self",
							},
						},
					},
				},
				["damageforce"] = {
					["mult"] = 10,
					["new"] = Vector( 16384, 0, 0 ),
				},
				["damagescale"] = 12,
				["new_dmg_type"] = "DMG_DISSOLVE",
			},
			[2] = {
				["attacker"] = {
					["effects"] = {
						[1] = {
							["name"] = {
								[1] = "__TBLRANDOM",
								[2] = "weapons/357/357_fire2.wav",
								[3] = "weapons/357/357_fire3.wav",
							},
							["sound"] = {
								["restart"] = true,
							},
							["type"] = "sound",
						},
					},
				},
				["condition"] = {
					["attacker"] = {
						["velocity_greater"] = 550,
						["weapon_sets"] = {
							["include"] = {
								[1] = {
									["name"] = "Melee",
									["type"] = "weapon_set",
								},
							},
						},
					},
					["victim"] = {
						["types"] = {
							["exclude"] = {
								[1] = "self",
							},
						},
					},
				},
				["damageforce"] = {
					["add"] = Vector( 4000, 0, 500 ),
					["mult"] = 3,
				},
				["damagescale"] = 6,
				["new_dmg_type"] = "DMG_VEHICLE",
			},
			[3] = {
				["attacker"] = {
					["effects"] = {
						[1] = {
							["name"] = "phx/eggcrack.wav",
							["sound"] = {
								["restart"] = true,
							},
							["type"] = "sound",
						},
					},
				},
				["condition"] = {
					["attacker"] = {
						["velocity_greater"] = 400,
						["weapon_sets"] = {
							["include"] = {
								[1] = {
									["name"] = "Melee",
									["type"] = "weapon_set",
								},
							},
						},
					},
					["victim"] = {
						["types"] = {
							["exclude"] = {
								[1] = "self",
							},
						},
					},
				},
				["damageforce"] = {
					["add"] = Vector( 0, 0, 5000 ),
				},
				["damagescale"] = 2.4,
			},
			[4] = {
				["attacker"] = {
					["effects"] = {
						[1] = {
							["name"] = "phx/eggcrack.wav",
							["sound"] = {
								["restart"] = true,
							},
							["type"] = "sound",
						},
					},
				},
				["condition"] = {
					["attacker"] = {
						["velocity_greater"] = 250,
						["weapon_sets"] = {
							["include"] = {
								[1] = {
									["name"] = "Melee",
									["type"] = "weapon_set",
								},
							},
						},
					},
					["victim"] = {
						["types"] = {
							["exclude"] = {
								[1] = "self",
							},
						},
					},
				},
				["damageforce"] = {
					["add"] = Vector( 0, 0, 5000 ),
				},
				["damagescale"] = 1.5,
			},
			[5] = {
				["attacker"] = {
					["effects"] = {
						[1] = {
							["name"] = {
								[1] = "__TBLRANDOM",
								[2] = "weapons/crossbow/hitbod1.wav",
								[3] = "weapons/crossbow/hitbod2.wav",
							},
							["type"] = "sound",
						},
					},
				},
				["condition"] = {
					["attacker"] = {
						["velocity_greater"] = 1000,
					},
					["victim"] = {
						["types"] = {
							["exclude"] = {
								[1] = "self",
							},
						},
					},
				},
				["damagescale"] = 1.5,
			},
		},
		["damagescale_out"] = 1,
		["deathexplode"] = {
			["radius"] = 240,
		},
		["description"] = "Melee at high speeds for massive damage. Press +speed to accelerate",
		["entity_type"] = "player",
		["expected"] = {
			["d"] = 1,
			["f"] = 1,
			["n"] = 1,
		},
		["friction_mult"] = 0.2,
		["fullrotation"] = true,
		["maxspeed"] = 32768,
		["npcd_enabled"] = true,
		["physcollide"] = {
			[1] = {
				["damagefilter_out"] = {
					[1] = {
						["condition"] = {
							["attacker"] = {
								["velocity_greater"] = 1050,
							},
						},
						["damagescale"] = 2,
						["victim"] = {
							["explode"] = {
								["damage"] = 0,
							},
						},
					},
				},
				["filter_onlyimpact"] = true,
				["impact_radius"] = 180,
				["mindelay"] = 0.24,
				["speed_min"] = 100,
			},
		},
		["velocity_in"] = {
		},
		["walkspeed"] = 300,
		["weapon_sets"] = {
			[1] = {
				["name"] = "Wowozela",
				["type"] = "weapon_set",
			},
			[2] = {
				["name"] = "Melee",
				["type"] = "weapon_set",
			},
		},
	} )

	npcd.InsertPending( profile_name, "player", "Jello Boy", {
		["VERSION"] = 20,
		["damage_drop_set"] = {
			[1] = {
				["drop_set"] = {
					["name"] = "Yum",
					["type"] = "drop_set",
				},
			},
		},
		["damagefilter_out"] = {
			[1] = {
				["victim"] = {
					["apply_values"] = {
						["npc"] = {
							["weapon_proficiency"] = "Poor",
						},
					},
					["damage_drop_set"] = {
						[1] = {
							["chance"] = {
								["d"] = 2,
								["f"] = 0.5,
								["n"] = 1,
							},
							["drop_set"] = {
								["name"] = "Yum",
								["type"] = "drop_set",
							},
							["multidrop_dmg"] = 10,
						},
					},
					["jigglify"] = true,
					["scale_mult"] = {
						[1] = "__RAND",
						[2] = 0.9,
						[3] = 1.1,
					},
				},
			},
		},
		["description"] = "Works best in third-person",
		["entity_type"] = "player",
		["expected"] = {
			["d"] = 1,
			["f"] = 1,
			["n"] = 1,
		},
		["fullrotation"] = true,
		["jiggle_all"] = true,
		["npcd_enabled"] = true,
		["physobject"] = {
			["gravity"] = false,
		},
	} )

	npcd.InsertPending( profile_name, "player", "Invincible", {
		["VERSION"] = 20,
		["entity_type"] = "player",
		["expected"] = {
			["d"] = 0,
			["f"] = 0,
			["n"] = 0,
		},
		["maxarmor"] = 999,
		["maxhealth"] = 999,
		["regen"] = 1,
		["regendelay"] = 0,
	} )

	npcd.InsertPending( profile_name, "drop_set", "Fear Determination, Least", {
		["VERSION"] = 20,
		["count_per_squad_spawn"] = true,
		["drops"] = {
			[1] = {
				["chance"] = {
					["d"] = 30,
					["f"] = 0.033333333333333,
					["n"] = 1,
				},
				["max"] = 1,
				["preset_values"] = {
					["inherit"] = true,
					["preset"] = {
						["name"] = "Many, Many Fears",
						["type"] = "squad",
					},
				},
				["type"] = "preset",
			},
			[2] = {
				["destroydelay"] = 30,
				["entity_values"] = {
					["classname"] = "prop_physics",
					["material"] = "models/flesh",
					["model"] = "models/props_c17/doll01.mdl",
					["scale"] = 1,
					["spawnflags"] = {
						[1] = 4,
					},
				},
				["min"] = 1,
				["spawnforce"] = {
					["forward"] = {
						[1] = "__RAND",
						[2] = 100,
						[3] = 300,
					},
				},
				["type"] = "entity",
			},
		},
		["maxdrops"] = 2,
		["npcd_enabled"] = true,
		["rolls"] = 1,
		["shuffle"] = false,
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

	npcd.InsertPending( profile_name, "drop_set", "Buckcrab Persistence", {
		["VERSION"] = 20,
		["drops"] = {
			[1] = {
				["chance"] = {
					["d"] = 10,
					["f"] = 0.9,
					["n"] = 9,
				},
				["preset_values"] = {
					["inherit"] = true,
					["preset"] = {
						["name"] = "Persistent Headcrab",
						["type"] = "npc",
					},
				},
				["type"] = "preset",
			},
			[2] = {
				["destroydelay"] = 300,
				["entity_values"] = {
					["classname"] = {
						["name"] = "item_box_buckshot",
						["type"] = "SpawnableEntities",
					},
				},
				["type"] = "entity",
			},
			[3] = {
				["destroydelay"] = 180,
				["forcemin"] = true,
				["min"] = 1,
				["preset_values"] = {
					["preset"] = {
						["name"] = "HL2 Shotgun",
						["type"] = "weapon_set",
					},
				},
				["type"] = "preset",
			},
		},
		["maxdrops"] = 1,
		["npcd_enabled"] = true,
		["rolls"] = 1,
		["shuffle"] = false,
	} )

	npcd.InsertPending( profile_name, "drop_set", "Bomber", {
		["VERSION"] = 20,
		["drops"] = {
			[1] = {
				["preset_values"] = {
					["inherit"] = false,
					["preset"] = {
						["name"] = "Bombing Run",
						["type"] = "squad",
					},
				},
				["squad_disposition"] = "Friendly",
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

	npcd.InsertPending( profile_name, "drop_set", "Bomb", {
		["VERSION"] = 20,
		["drops"] = {
			[1] = {
				["preset_values"] = {
					["inherit"] = false,
					["preset"] = {
						["name"] = "Tumbleweed",
						["type"] = "npc",
					},
				},
				["squad_disposition"] = "Friendly",
				["type"] = "preset",
			},
		},
		["npcd_enabled"] = true,
		["rolls"] = 1,
		["shuffle"] = true,
	} )

	npcd.InsertPending( profile_name, "drop_set", "Clown Car", {
		["VERSION"] = 20,
		["drops"] = {
			[1] = {
				["preset_values"] = {
					["inherit"] = true,
					["preset"] = {
						["name"] = "Lil Silly",
						["type"] = "squad",
					},
				},
				["type"] = "preset",
			},
		},
		["npcd_enabled"] = true,
		["rolls"] = 1,
		["shuffle"] = true,
	} )

	npcd.InsertPending( profile_name, "drop_set", "Miniscule Level Drops", {
		["VERSION"] = 20,
		["description"] = "Intended for enemies that show up in large numbers",
		["drops"] = {
			[1] = {
				["chance"] = {
					["d"] = 14,
					["f"] = 0.071428571428571,
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
					["d"] = 35,
					["f"] = 0.028571428571429,
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
					["d"] = 6,
					["f"] = 0.16666666666667,
					["n"] = 1,
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
				["spawnforce"] = {
					["forward"] = {
						[1] = "__RAND",
						[2] = 1000,
						[3] = 1600,
					},
					["up"] = {
						[1] = "__RAND",
						[2] = 0,
						[3] = 235,
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

	npcd.InsertPending( profile_name, "drop_set", "Fear Determination, One", {
		["VERSION"] = 20,
		["count_per_squad_spawn"] = true,
		["drops"] = {
			[1] = {
				["max"] = 1,
				["min"] = 1,
				["preset_values"] = {
					["inherit"] = true,
					["preset"] = {
						["name"] = "Many Fears",
						["type"] = "squad",
					},
				},
				["type"] = "preset",
			},
			[2] = {
				["destroydelay"] = 30,
				["entity_values"] = {
					["classname"] = "prop_physics",
					["material"] = "models/flesh",
					["model"] = "models/props_c17/doll01.mdl",
					["scale"] = 3.5,
					["spawnflags"] = {
						[1] = 4,
					},
				},
				["max"] = 6,
				["min"] = 6,
				["spawnforce"] = {
					["forward"] = {
						[1] = "__RAND",
						[2] = 100,
						[3] = 300,
					},
				},
				["type"] = "entity",
			},
			[3] = {
				["forcemin"] = true,
				["min"] = 1,
				["preset_values"] = {
					["preset"] = {
						["name"] = "High Level Drops",
						["type"] = "drop_set",
					},
				},
				["type"] = "preset",
			},
		},
		["maxdrops"] = 6,
		["npcd_enabled"] = true,
		["rolls"] = 1,
		["shuffle"] = false,
	} )

	npcd.InsertPending( profile_name, "drop_set", "Headcrab Persistence", {
		["VERSION"] = 20,
		["drops"] = {
			[1] = {
				["chance"] = {
					["d"] = 5,
					["f"] = 0.8,
					["n"] = 4,
				},
				["preset_values"] = {
					["preset"] = {
						["name"] = "Persistent Headcrab",
						["type"] = "npc",
					},
				},
				["type"] = "preset",
			},
			[2] = {
				["destroydelay"] = 30,
				["entity_values"] = {
					["classname"] = "prop_physics",
					["model"] = "models/props_c17/doll01.mdl",
					["spawnflags"] = {
						[1] = 4,
					},
				},
				["type"] = "entity",
			},
		},
		["maxdrops"] = 1,
		["npcd_enabled"] = true,
		["override_hard"] = {
			["npc"] = {
				["healthmult"] = 0.8,
			},
		},
		["rolls"] = 1,
		["shuffle"] = false,
	} )

	npcd.InsertPending( profile_name, "drop_set", "Fear Determination, Lesser", {
		["VERSION"] = 20,
		["count_per_squad_spawn"] = true,
		["drops"] = {
			[1] = {
				["max"] = 1,
				["min"] = 1,
				["preset_values"] = {
					["inherit"] = true,
					["preset"] = {
						["name"] = "Many, Many Fears",
						["type"] = "squad",
					},
				},
				["type"] = "preset",
			},
			[2] = {
				["destroydelay"] = 30,
				["entity_values"] = {
					["classname"] = "prop_physics",
					["material"] = "models/flesh",
					["model"] = "models/props_c17/doll01.mdl",
					["scale"] = 2,
					["spawnflags"] = {
						[1] = 4,
					},
				},
				["max"] = 4,
				["min"] = 4,
				["spawnforce"] = {
					["forward"] = {
						[1] = "__RAND",
						[2] = 100,
						[3] = 300,
					},
				},
				["type"] = "entity",
			},
		},
		["maxdrops"] = 4,
		["npcd_enabled"] = true,
		["rolls"] = 1,
		["shuffle"] = false,
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

	npcd.InsertPending( profile_name, "drop_set", "Large Rocket", {
		["VERSION"] = 20,
		["drops"] = {
			[1] = {
				["destroydelay"] = 180,
				["entity_values"] = {
					["classname"] = {
						["name"] = "item_rpg_round",
						["type"] = "SpawnableEntities",
					},
					["material"] = "models/flesh",
					["scale"] = 3,
				},
				["type"] = "entity",
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

	npcd.InsertPending( profile_name, "drop_set", "Pick Up That Tab", {
		["VERSION"] = 20,
		["description"] = "",
		["drops"] = {
			[1] = {
				["preset_values"] = {
					["preset"] = {
						["name"] = "Pick Me Up",
						["type"] = "entity",
					},
				},
				["spawnforce"] = {
					["forward"] = {
						[1] = "__RAND",
						[2] = 300,
						[3] = 600,
					},
					["up"] = -50,
				},
				["type"] = "preset",
			},
		},
		["npcd_enabled"] = true,
		["rolls"] = {
			[1] = "__RANDOM",
			[2] = 1,
			[3] = 5,
		},
		["shuffle"] = true,
	} )

	npcd.InsertPending( profile_name, "drop_set", "Yum", {
		["VERSION"] = 20,
		["drops"] = {
			[1] = {
				["destroydelay"] = 30,
				["entity_values"] = {
					["classname"] = "prop_physics_multiplayer",
					["model"] = "models/props_junk/watermelon01.mdl",
					["scale"] = {
						[1] = "__RAND",
						[2] = 0.5,
						[3] = 1,
					},
					["spawnflags"] = {
						[1] = 4,
					},
				},
				["spawnforce"] = {
					["forward"] = {
						[1] = "__RAND",
						[2] = 10,
						[3] = 100,
					},
				},
				["type"] = "entity",
			},
			[2] = {
				["destroydelay"] = 30,
				["entity_values"] = {
					["classname"] = "prop_physics_multiplayer",
					["model"] = "models/noesis/donut.mdl",
					["scale"] = {
						[1] = "__RAND",
						[2] = 0.35,
						[3] = 0.45,
					},
					["spawnflags"] = {
						[1] = 4,
					},
				},
				["spawnforce"] = {
					["forward"] = {
						[1] = "__RAND",
						[2] = 10,
						[3] = 100,
					},
				},
				["type"] = "entity",
			},
			[3] = {
				["chance"] = {
					["d"] = 3,
					["f"] = 0.33333333333333,
					["n"] = 1,
				},
				["destroydelay"] = 30,
				["entity_values"] = {
					["bloodcolor"] = "BLOOD_COLOR_RED",
					["classname"] = "prop_physics_multiplayer",
					["model"] = "models/food/hotdog.mdl",
					["scale"] = {
						[1] = "__RAND",
						[2] = 0.75,
						[3] = 1,
					},
					["spawnflags"] = {
						[1] = 4,
					},
				},
				["spawnforce"] = {
					["forward"] = {
						[1] = "__RAND",
						[2] = 10,
						[3] = 100,
					},
				},
				["type"] = "entity",
			},
			[4] = {
				["chance"] = {
					["d"] = 3,
					["f"] = 0.33333333333333,
					["n"] = 1,
				},
				["destroydelay"] = 30,
				["entity_values"] = {
					["bloodcolor"] = "BLOOD_COLOR_RED",
					["classname"] = "prop_physics_multiplayer",
					["model"] = "models/food/burger.mdl",
					["scale"] = {
						[1] = "__RAND",
						[2] = 1,
						[3] = 1.25,
					},
					["spawnflags"] = {
						[1] = 4,
					},
				},
				["spawnforce"] = {
					["forward"] = {
						[1] = "__RAND",
						[2] = 10,
						[3] = 100,
					},
				},
				["type"] = "entity",
			},
		},
		["maxdrops"] = 1,
		["npcd_enabled"] = true,
		["rolls"] = 1,
		["shuffle"] = true,
	} )

	npcd.InsertPending( profile_name, "npc", "Combine Elitist", {
		["VERSION"] = 20,
		["animspeed"] = 0.7,
		["bloodcolor"] = "BLOOD_COLOR_ANTLION_WORKER",
		["chase_schedule"] = {
			[1] = "SCHED_FORCED_GO_RUN",
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

	npcd.InsertPending( profile_name, "npc", "Tiny Party Favors", {
		["VERSION"] = 20,
		["activate"] = false,
		["bloodcolor"] = "DONT_BLEED",
		["classname"] = {
			["name"] = "npc_manhack",
			["type"] = "NPC",
		},
		["deatheffect"] = {
			[1] = {
				["name"] = "balloon_pop",
				["type"] = "effect",
			},
		},
		["drop_set"] = {
			[1] = {
				["drop_set"] = {
					["name"] = "Miniscule Level Drops",
					["type"] = "drop_set",
				},
			},
		},
		["entity_type"] = "npc",
		["maxhealth"] = 2,
		["model"] = {
			[1] = "__TBLRANDOM",
			[2] = "models/balloons/balloon_star.mdl",
			[3] = "models/balloons/balloon_dog.mdl",
			[4] = "models/maxofs2d/balloon_classic.mdl",
			[5] = "models/maxofs2d/balloon_classic.mdl",
			[6] = "models/balloons/balloon_classicheart.mdl",
		},
		["noidle"] = true,
		["npcd_enabled"] = true,
		["quota_weight"] = 0.01,
		["regen"] = -2,
		["regendelay"] = {
			[1] = "__RAND",
			[2] = 120,
			[3] = 300,
		},
		["relationships_outward"] = {
			["everyone"] = {
				["disposition"] = "Friendly",
				["priority"] = 99,
			},
		},
		["removebody"] = true,
		["rendercolor"] = {
			[1] = "__RANDOMCOLOR",
			[4] = 1,
			[6] = 1,
		},
		["scale"] = {
			[1] = "__RAND",
			[2] = 0.2,
			[3] = 0.4,
		},
		["seekout_clear"] = true,
		["spawneffect"] = {
		},
		["spawnflags"] = {
			[1] = 131072,
			[2] = 65536,
		},
		["start_patrol"] = true,
	} )

	npcd.InsertPending( profile_name, "npc", "Insane Beer Lover", {
		["VERSION"] = 20,
		["bones"] = {
			[1] = {
				["bone"] = {
					[1] = "__TBLRANDOM",
					[2] = 5,
					[3] = "",
					[4] = "",
				},
				["offset"] = Vector( 5, 8, 7 ),
				["rotate"] = Angle( -28, 87, -151.9375 ),
				["scale"] = {
					[1] = "__RANDOMVECTOR",
					[2] = -30,
					[3] = 30,
					[4] = -2,
					[5] = 2,
					[6] = -2,
					[7] = 2,
				},
			},
			[2] = {
				["bone"] = "ValveBiped.Bip01_Head1",
				["rotate"] = Angle( 90, 0, 180 ),
				["scale"] = {
					[1] = "__RANDOMVECTOR",
					[2] = 2,
					[3] = 2,
					[4] = 0.5,
					[5] = 2,
					[6] = 0.5,
					[7] = 2,
				},
			},
			[3] = {
				["bone"] = {
					[1] = "__TBLRANDOM",
					[2] = 1,
					[3] = 5,
				},
				["jiggle"] = true,
				["offset"] = Vector( 5, 8, 7 ),
				["rotate"] = Angle( -28, 87, -151.9375 ),
				["scale"] = {
					[1] = "__RANDOMVECTOR",
					[2] = -30,
					[3] = 30,
					[4] = -2,
					[5] = 2,
					[6] = -2,
					[7] = 2,
				},
			},
			[4] = {
				["bone"] = {
					[1] = "__RANDOM",
					[2] = 0,
					[3] = 57,
				},
				["jiggle"] = {
					[1] = "__TBLRANDOM",
					[2] = true,
					[3] = false,
					[4] = false,
					[5] = false,
					[6] = false,
				},
				["offset"] = {
					[1] = "__RANDOMVECTOR",
					[2] = -5,
					[3] = 5,
					[4] = -5,
					[5] = 5,
					[6] = -5,
					[7] = 5,
				},
				["rotate"] = {
					[1] = "__RANDOMANGLE",
					[2] = -180,
					[3] = 180,
					[4] = -180,
					[5] = 180,
					[6] = -180,
					[7] = 180,
				},
				["scale"] = {
					[1] = "__RANDOMVECTOR",
					[2] = -3,
					[3] = 3,
					[4] = -3,
					[5] = 3,
					[6] = -3,
					[7] = 3,
				},
			},
			[5] = {
				["bone"] = {
					[1] = "__RANDOM",
					[2] = 0,
					[3] = 57,
				},
				["jiggle"] = {
					[1] = "__TBLRANDOM",
					[2] = true,
					[3] = false,
					[4] = false,
					[5] = false,
					[6] = false,
				},
				["offset"] = {
					[1] = "__RANDOMVECTOR",
					[2] = -5,
					[3] = 5,
					[4] = -5,
					[5] = 5,
					[6] = -5,
					[7] = 5,
				},
				["rotate"] = {
					[1] = "__RANDOMANGLE",
					[2] = -180,
					[3] = 180,
					[4] = -180,
					[5] = 180,
					[6] = -180,
					[7] = 180,
				},
				["scale"] = {
					[1] = "__RANDOMVECTOR",
					[2] = -3,
					[3] = 3,
					[4] = -3,
					[5] = 3,
					[6] = -3,
					[7] = 3,
				},
			},
			[6] = {
				["bone"] = {
					[1] = "__RANDOM",
					[2] = 0,
					[3] = 57,
				},
				["jiggle"] = {
					[1] = "__TBLRANDOM",
					[2] = true,
					[3] = false,
					[4] = false,
					[5] = false,
					[6] = false,
				},
				["offset"] = {
					[1] = "__RANDOMVECTOR",
					[2] = -5,
					[3] = 5,
					[4] = -5,
					[5] = 5,
					[6] = -5,
					[7] = 5,
				},
				["rotate"] = {
					[1] = "__RANDOMANGLE",
					[2] = -180,
					[3] = 180,
					[4] = -180,
					[5] = 180,
					[6] = -180,
					[7] = 180,
				},
				["scale"] = {
					[1] = "__RANDOMVECTOR",
					[2] = -3,
					[3] = 3,
					[4] = -3,
					[5] = 3,
					[6] = -3,
					[7] = 3,
				},
			},
			[7] = {
				["bone"] = {
					[1] = "__TBLRANDOM",
					[2] = 5,
					[3] = "",
					[4] = "",
					[5] = "",
					[6] = "",
					[7] = "",
					[8] = "",
					[9] = "",
					[10] = "",
				},
				["offset"] = Vector( 5, 8, 7 ),
				["rotate"] = Angle( -28, 87, -151.9375 ),
				["scale"] = Vector( 3491.65625, 2, 2 ),
			},
			[8] = {
				["bone"] = {
					[1] = "__TBLRANDOM",
					[2] = 1,
					[3] = "",
					[4] = "",
					[5] = "",
					[6] = "",
					[7] = "",
					[8] = "",
					[9] = "",
					[10] = "",
				},
				["offset"] = Vector( 5, 8, 7 ),
				["rotate"] = Angle( -28, 87, -151.9375 ),
				["scale"] = Vector( 3491.65625, 2, 2 ),
			},
		},
		["classname"] = {
			["name"] = "npc_barney",
			["type"] = "NPC",
		},
		["damagefilter_in"] = {
			[1] = {
				["victim"] = {
					["effects"] = {
						[1] = {
							["name"] = "vo/npc/barney/ba_ohshit03.wav",
							["sound"] = {
								["dist"] = 125,
								["pitch"] = {
									[1] = "__RAND",
									[2] = 50,
									[3] = 125,
								},
							},
							["type"] = "sound",
						},
					},
				},
			},
		},
		["damagefilter_out"] = {
			[1] = {
				["condition"] = {
					["victim"] = {
						["types"] = {
							["exclude"] = {
								[1] = "player",
							},
							["include"] = {
								[1] = "character",
							},
						},
					},
				},
				["continue"] = true,
				["damagescale"] = 1.5,
				["victim"] = {
					["bones"] = {
						[1] = {
							["bone"] = "ValveBiped.Bip01_Head1",
							["rotate"] = {
								[1] = "__RANDOMANGLE",
								[2] = -180,
								[3] = 180,
								[4] = -180,
								[5] = 180,
								[6] = -180,
								[7] = 180,
							},
							["scale"] = {
								[1] = "__RANDOMVECTOR",
								[2] = 0.5,
								[3] = 1.5,
								[4] = 0.5,
								[5] = 1.5,
								[6] = 0.5,
								[7] = 1.5,
							},
						},
					},
					["effects"] = {
						[1] = {
							["name"] = "vo/trainyard/ba_thatbeer02.wav",
							["sound"] = {
								["pitch"] = {
									[1] = "__RAND",
									[2] = 75,
									[3] = 125,
								},
								["restart"] = false,
							},
							["type"] = "sound",
						},
					},
				},
			},
			[2] = {
				["condition"] = {
					["damage"] = {
						["greater_than_health"] = true,
					},
					["victim"] = {
						["types"] = {
							["exclude"] = {
								[1] = "self",
								[2] = "player",
							},
						},
					},
				},
				["damagescale"] = 0,
				["victim"] = {
					["announce_death"] = true,
					["apply_preset"] = {
						["name"] = "Insane Beer Lover",
						["type"] = "npc",
					},
					["change_squad"] = true,
					["heal"] = {
						["d"] = 1,
						["f"] = 1,
						["n"] = 1,
					},
				},
			},
			[3] = {
				["victim"] = {
					["effects"] = {
						[1] = {
							["name"] = "vo/trainyard/ba_thatbeer02.wav",
							["sound"] = {
								["pitch"] = {
									[1] = "__RAND",
									[2] = 75,
									[3] = 125,
								},
								["restart"] = false,
							},
							["type"] = "sound",
						},
					},
				},
			},
		},
		["damagescale_out"] = 2,
		["description"] = "It\'s me: Barney, from Black Mesa!",
		["drop_set"] = {
			[1] = {
				["drop_set"] = {
					["name"] = "Ammo",
					["type"] = "drop_set",
				},
			},
			[2] = {
				["drop_set"] = {
					["name"] = "Pick Up That Tab",
					["type"] = "drop_set",
				},
			},
		},
		["effects"] = {
			[1] = {
				["delay"] = {
					[1] = "__RAND",
					[2] = 1,
					[3] = 30,
				},
				["name"] = {
					[1] = "__TBLRANDOM",
					[2] = "vo/npc/barney/ba_oldtimes.wav",
					[3] = "vo/npc/barney/ba_soldiers.wav",
				},
				["reps"] = 1,
				["sound"] = {
					["dist"] = 100,
					["pitch"] = {
						[1] = "__RAND",
						[2] = 90,
						[3] = 110,
					},
				},
				["type"] = "sound",
			},
		},
		["entity_type"] = "npc",
		["force_approach"] = true,
		["model"] = "models/Barney.mdl",
		["npcd_enabled"] = true,
		["quota_weight"] = 1,
		["relationships_inward"] = {
			["by_preset"] = {
				[1] = {
					["disposition"] = "Friendly",
					["preset"] = {
						["name"] = "Insane Beer Lover",
						["type"] = "npc",
					},
					["priority"] = 99,
				},
			},
			["everyone"] = {
				["disposition"] = "Hostile",
				["exclude"] = {
					["by_preset"] = {
						[1] = {
							["name"] = "Insane Beer Lover",
							["type"] = "npc",
						},
					},
				},
				["priority"] = 99,
			},
			["self_squad"] = {
				["disposition"] = "Hostile",
				["exclude"] = {
					["by_preset"] = {
						[1] = {
							["name"] = "Insane Beer Lover",
							["type"] = "npc",
						},
					},
				},
				["priority"] = 99,
			},
		},
		["relationships_outward"] = {
			["by_preset"] = {
				[1] = {
					["disposition"] = "Friendly",
					["preset"] = {
						["name"] = "Insane Beer Lover",
						["type"] = "npc",
					},
					["priority"] = 99,
				},
			},
			["everyone"] = {
				["disposition"] = "Hostile",
				["exclude"] = {
					["by_preset"] = {
						[1] = {
							["name"] = "Insane Beer Lover",
							["type"] = "npc",
						},
					},
				},
				["priority"] = 99,
			},
			["self_squad"] = {
				["disposition"] = "Hostile",
				["exclude"] = {
					["by_preset"] = {
						[1] = {
							["name"] = "Insane Beer Lover",
							["type"] = "npc",
						},
					},
				},
				["priority"] = 99,
			},
		},
		["rendercolor"] = {
			[1] = "__RANDOMCOLOR",
			[4] = 0.9031007751938,
			[6] = 0.80232558139535,
			[7] = 1,
		},
		["seekout_clear"] = false,
		["seekout_schedule"] = {
			[1] = "SCHED_FORCED_GO_RUN",
			[2] = "SCHED_TARGET_CHASE",
			[3] = "SCHED_CHASE_ENEMY",
		},
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
				["name"] = "vo/trainyard/ba_rememberme.wav",
				["sound"] = {
					["dist"] = 111,
					["pitch"] = {
						[1] = "__RAND",
						[2] = 90,
						[3] = 110,
					},
				},
				["type"] = "sound",
			},
		},
		["spawnflags"] = {
			[1] = "Don\'t drop weapons",
			[2] = "Ignore player push",
		},
		["spritetrail"] = {
			[1] = {
				["attachment"] = 5,
				["color"] = Color( 177, 54, 54 ),
				["texture"] = "trails/plasma1",
			},
		},
		["start_patrol"] = true,
		["weapon_proficiency"] = "Perfect",
		["weapon_set"] = {
			["name"] = "HL2 AR2/SMG",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "High Burst", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_magnusson",
			["type"] = "NPC",
		},
		["damage_drop_set"] = {
			[1] = {
				["chance"] = {
					["d"] = 50,
					["f"] = 0.02,
					["n"] = 1,
				},
				["drop_set"] = {
					["name"] = "Ammo Special",
					["type"] = "drop_set",
				},
				["max"] = 8,
			},
		},
		["damagefilter_in"] = {
			[1] = {
				["condition"] = {
					["victim"] = {
						["health_greater"] = {
							["d"] = 20,
							["f"] = 0.95,
							["n"] = 19,
						},
					},
				},
				["continue"] = true,
				["victim"] = {
					["resetregen"] = true,
				},
			},
			[2] = {
				["condition"] = {
					["damage"] = {
						["dmg_types"] = {
							["include"] = {
								[1] = "DMG_CRUSH",
							},
						},
						["greater"] = 499,
						["lesser"] = 500,
					},
				},
				["max"] = 250,
			},
		},
		["drop_set"] = {
			[1] = {
				["drop_set"] = {
					["name"] = "High Level Drops",
					["type"] = "drop_set",
				},
			},
			[2] = {
				["drop_set"] = {
					["name"] = "Ammo Special",
					["type"] = "drop_set",
				},
			},
		},
		["entity_type"] = "npc",
		["maxhealth"] = 290,
		["regen"] = 290,
		["regendelay"] = 1.9,
		["relationships_inward"] = {
			["everyone"] = {
				["disposition"] = "Hostile",
			},
		},
		["relationships_outward"] = {
			["everyone"] = {
				["disposition"] = "Hostile",
			},
		},
		["scale_proportion"] = 0.6,
		["weapon_set"] = {
			["name"] = "HL2 Annabelle",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Zexplosive Zombie", {
		["VERSION"] = 20,
		["angle"] = {
			[1] = "__RANDOMANGLE",
		},
		["bloodcolor"] = "BLOOD_COLOR_MECH",
		["classname"] = {
			["name"] = "npc_zombie",
			["type"] = "NPC",
		},
		["damagefilter_in"] = {
			[1] = {
				["condition"] = {
					["damage"] = {
						["dmg_types"] = {
							["include"] = {
								[1] = "DMG_BURN",
								[2] = "DMG_SLOWBURN",
							},
						},
					},
				},
				["damagescale"] = {
					[1] = "__RAND",
					[2] = 2.5,
					[3] = 3,
				},
				["victim"] = {
					["ignite"] = true,
				},
			},
			[2] = {
				["condition"] = {
					["damage"] = {
						["explosion"] = true,
					},
				},
				["victim"] = {
					["ignite"] = true,
				},
			},
		},
		["deathexplode"] = {
			["damage"] = 65,
			["radius"] = 220,
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
		["material"] = "models/props_c17/oil_drum001h",
		["npcd_enabled"] = true,
		["quota_weight"] = 1,
		["rendercolor"] = {
			[1] = "__RANDOMCOLOR",
			[3] = 15,
			[4] = 0,
			[5] = 0.3,
			[6] = 1,
		},
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
		["start_patrol"] = true,
		["volatile"] = {
			["threshold_shot"] = {
				[1] = "__RAND",
				[2] = 5,
				[3] = 10,
			},
			["threshold_total"] = {
				[1] = "__RAND",
				[2] = 10,
				[3] = 35,
			},
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Bugman", {
		["VERSION"] = 20,
		["animspeed"] = {
			[1] = "__RAND",
			[2] = 0.9,
			[3] = 2,
		},
		["bloodcolor"] = "BLOOD_COLOR_GREEN",
		["bone_scale"] = {
			[1] = "__RAND",
			[2] = -0.7,
			[3] = -0.4,
		},
		["classname"] = {
			["name"] = "npc_breen",
			["type"] = "NPC",
		},
		["damage_drop_set"] = {
			[1] = {
				["chance"] = {
					["d"] = 1,
					["f"] = 5,
					["n"] = 5,
				},
			},
			[2] = {
				["health_greater"] = 5,
			},
		},
		["description"] = "A friend",
		["entity_type"] = "npc",
		["force_approach"] = true,
		["force_sequence"] = {
			[1] = "__RANDOM",
			[2] = 0,
			[3] = 497,
		},
		["healthmult"] = 0.5,
		["ignite"] = 0,
		["keyvalues"] = {
			[1] = {
				["key"] = "isdumb",
				["value"] = true,
			},
		},
		["material"] = "models/barnacle/barnacle_sheet",
		["noidle"] = true,
		["npcd_enabled"] = true,
		["quota_weight"] = 0.4,
		["regen"] = -100,
		["regendelay"] = {
			[1] = "__RAND",
			[2] = 240,
			[3] = 360,
		},
		["relationships_inward"] = {
			["everyone"] = {
				["disposition"] = "Hostile",
				["priority"] = 99,
			},
		},
		["relationships_outward"] = {
			["everyone"] = {
				["disposition"] = "Neutral",
				["priority"] = 99,
			},
			["self_squad"] = {
				["disposition"] = "Friendly",
				["priority"] = 99,
			},
		},
		["rendercolor"] = {
			[1] = "__RANDOMCOLOR",
			[2] = 0,
			[3] = 169.57,
			[4] = 0,
			[5] = 0.11,
			[6] = 1,
		},
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
		["start_patrol"] = true,
		["stress_mult"] = 0.5,
		["weapon_proficiency"] = {
			[1] = "__RANDOM",
			[2] = 0,
			[3] = 3,
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Drone Strike", {
		["VERSION"] = 20,
		["accelerate"] = {
			["accel_rate"] = 45,
			["accel_threshold"] = 400,
			["enabled"] = true,
		},
		["animspeed"] = 5,
		["chase_settarget"] = true,
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
				["max"] = 45,
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
		["maxhealth"] = 150,
		["model"] = "models/Combine_Helicopter.mdl",
		["npcd_enabled"] = true,
		["physobject"] = {
			["angledrag"] = 64,
			["mass"] = 128,
		},
		["quota_weight"] = 1,
		["removebody"] = true,
		["scale"] = 0.25,
		["seekout_clear"] = false,
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
		["spritetrail"] = {
			[1] = {
				["attachment"] = 12,
				["color"] = Color( 255, 0, 0, 141 ),
				["lifetime"] = 1,
				["startwidth"] = 30,
			},
		},
		["start_patrol"] = true,
		["weapon_set"] = {
			["name"] = "HL2 RPG",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "One Fear", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_headcrab_fast",
			["type"] = "NPC",
		},
		["damagefilter_out"] = {
			[1] = {
				["damagescale"] = {
					[1] = "__RAND",
					[2] = 2.5,
					[3] = 5,
				},
			},
		},
		["drop_set"] = {
			[1] = {
				["drop_set"] = {
					["name"] = "Fear Determination, One",
					["type"] = "drop_set",
				},
			},
		},
		["effects"] = {
			[1] = {
				["delay"] = {
					[1] = "__RAND",
					[2] = 1.2,
					[3] = 0.1,
				},
				["name"] = "npc/fast_zombie/breathe_loop1.wav",
				["sound"] = {
					["dist"] = 80,
					["pitch"] = {
						[1] = "__RAND",
						[2] = 0,
						[3] = 255,
					},
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
		["force_approach"] = true,
		["material"] = {
			[1] = "__TBLRANDOM",
			[2] = "models/zombie_fast/fast_zombie_sheet",
			[3] = "models/flesh",
			[4] = "models/gibs/hgibs/spine",
		},
		["maxhealth"] = 20,
		["npcd_enabled"] = true,
		["scale"] = 3,
	} )

	npcd.InsertPending( profile_name, "npc", "Firefly", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_antlion",
			["type"] = "NPC",
		},
		["damagefilter_in"] = {
			[1] = {
				["condition"] = {
					["damage"] = {
						["explosion"] = true,
					},
				},
				["victim"] = {
					["ignite"] = true,
				},
			},
		},
		["damagefilter_out"] = {
			[1] = {
				["victim"] = {
					["ignite"] = 1.5,
				},
			},
		},
		["damagescale_out"] = 0.2,
		["deatheffect"] = {
			[1] = {
				["name"] = "HelicopterMegaBomb",
				["type"] = "effect",
			},
		},
		["drop_set"] = {
			[1] = {
				["drop_set"] = {
					["name"] = "Miniscule Level Drops",
					["type"] = "drop_set",
				},
			},
		},
		["entity_type"] = "npc",
		["material"] = "brick/brick_model",
		["maxhealth"] = 8,
		["npcd_enabled"] = true,
		["quota_weight"] = 1,
		["rendercolor"] = {
			[1] = "__RANDOMCOLOR",
			[3] = 15,
		},
		["scale"] = {
			[1] = "__RAND",
			[2] = 0.5,
			[3] = 0.7,
		},
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
		["start_patrol"] = true,
	} )

	npcd.InsertPending( profile_name, "npc", "Vort", {
		["VERSION"] = 20,
		["animspeed"] = 1.5,
		["classname"] = {
			["name"] = "npc_vortigaunt",
			["type"] = "NPC",
		},
		["damagefilter_out"] = {
			[1] = {
				["condition"] = {
					["victim"] = {
						["types"] = {
							["exclude"] = {
								[1] = "self",
								[2] = "player",
							},
							["include"] = {
								[1] = "character",
							},
						},
					},
				},
				["max"] = {
					[1] = "__RAND",
					[2] = 7,
					[3] = 10,
				},
			},
			[2] = {
				["max"] = {
					[1] = "__RAND",
					[2] = 15,
					[3] = 20,
				},
			},
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
		["maxhealth"] = 70,
		["npcd_enabled"] = true,
		["quota_weight"] = 1,
		["relationships_inward"] = {
			["by_class"] = {
			},
			["by_preset"] = {
				[1] = {
					["disposition"] = "Friendly",
					["preset"] = {
						["name"] = "Vort",
						["type"] = "npc",
					},
					["priority"] = 99,
				},
				[2] = {
					["disposition"] = "Friendly",
					["preset"] = {
						["name"] = "Vortest",
						["type"] = "npc",
					},
				},
			},
			["everyone"] = {
				["disposition"] = "Hostile",
			},
		},
		["relationships_outward"] = {
			["by_preset"] = {
				[1] = {
					["disposition"] = "Friendly",
					["preset"] = {
						["name"] = "Vort",
						["type"] = "npc",
					},
				},
				[2] = {
					["disposition"] = "Friendly",
					["preset"] = {
						["name"] = "Vortest",
						["type"] = "npc",
					},
				},
			},
			["everyone"] = {
				["disposition"] = "Hostile",
			},
		},
		["rendercolor"] = {
			[1] = "__RANDOMCOLOR",
			[2] = 260.37735849057,
			[3] = 369.05660377358,
			[4] = 0.35,
			[6] = 1,
		},
		["seekout_clear"] = true,
		["skin"] = 1,
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

	npcd.InsertPending( profile_name, "npc", "Antlioness", {
		["VERSION"] = 20,
		["angle"] = {
			[1] = "__RANDOMANGLE",
		},
		["animspeed"] = 1.5,
		["chase_settarget"] = true,
		["classname"] = {
			["name"] = "npc_antlionguard",
			["type"] = "NPC",
		},
		["damagefilter_in"] = {
			[1] = {
				["condition"] = {
					["damage"] = {
						["explosion"] = true,
					},
				},
				["damagescale"] = 0.2,
			},
		},
		["damagefilter_out"] = {
			[1] = {
				["condition"] = {
					["damage"] = {
						["explosion"] = false,
					},
					["victim"] = {
						["types"] = {
							["include"] = {
								[1] = "non-character entity",
							},
						},
					},
				},
				["victim"] = {
					["explode"] = {
						["damage"] = 1,
						["radius"] = 220,
					},
					["ignite"] = 1,
				},
			},
			[2] = {
				["condition"] = {
					["damage"] = {
						["explosion"] = false,
					},
					["victim"] = {
						["types"] = {
							["exclude"] = {
								[1] = "self",
								[2] = "player",
							},
							["include"] = {
								[1] = "character",
							},
						},
					},
				},
				["victim"] = {
					["explode"] = {
						["damage"] = 30,
						["radius"] = 220,
					},
					["ignite"] = 0.1,
				},
			},
			[3] = {
				["condition"] = {
					["damage"] = {
						["explosion"] = false,
					},
					["victim"] = {
						["types"] = {
							["include"] = {
								[1] = "player",
							},
						},
					},
				},
				["victim"] = {
					["explode"] = {
						["damage"] = 15,
						["radius"] = 220,
					},
					["ignite"] = 0.1,
				},
			},
		},
		["damagescale_in"] = 1.35,
		["deatheffect"] = {
			[1] = {
				["delay"] = 0.1,
				["name"] = "generic_smoke",
				["pcf"] = "particles/gmod_effects.pcf",
				["reps"] = 5,
				["type"] = "particle",
			},
		},
		["drop_set"] = {
			[1] = {
				["drop_set"] = {
					["name"] = "High Level Drops",
					["type"] = "drop_set",
				},
			},
			[2] = {
				["drop_set"] = {
					["name"] = "Large Rocket",
					["type"] = "drop_set",
				},
			},
		},
		["entity_type"] = "npc",
		["long_range"] = true,
		["material"] = {
			[1] = "__TBLRANDOM",
			[2] = "models/charple/charple2_sheet",
			[3] = "models/charple/charple3_sheet",
			[4] = "models/charple/charple4_sheet",
		},
		["npcd_enabled"] = true,
		["quota_weight"] = 1,
		["scale"] = 1.5,
		["seekout_clear"] = false,
		["spawneffect"] = {
			[1] = {
				["effect_data"] = {
					["normal"] = Vector( 0, 0, 1 ),
					["scale"] = 2,
				},
				["name"] = {
					["name"] = "Explosion",
					["type"] = "effects",
				},
				["type"] = "effect",
			},
		},
		["spritetrail"] = {
			[1] = {
				["attachment"] = 1,
				["color"] = Color( 255, 255, 255, 210 ),
				["lifetime"] = 2,
				["startwidth"] = 50,
				["texture"] = "effects/beam001_white",
			},
			[2] = {
				["attachment"] = 1,
				["color"] = Color( 255, 0, 0 ),
				["startwidth"] = 110,
			},
		},
		["start_patrol"] = true,
		["stress_mult"] = 1,
	} )

	npcd.InsertPending( profile_name, "npc", "Tiny Clown", {
		["VERSION"] = 20,
		["bloodcolor"] = {
			[1] = "__TBLRANDOM",
			[2] = "BLOOD_COLOR_RED",
			[3] = "BLOOD_COLOR_YELLOW",
			[4] = "BLOOD_COLOR_GREEN",
			[5] = "BLOOD_COLOR_ANTLION",
			[6] = "BLOOD_COLOR_ZOMBIE",
			[7] = "BLOOD_COLOR_ANTLION_WORKER",
		},
		["childpreset"] = {
			["name"] = "Tiny Party Favors",
			["type"] = "npc",
		},
		["classname"] = {
			["name"] = "npc_metropolice",
			["type"] = "NPC",
		},
		["damagefilter_out"] = {
			[1] = {
				["max"] = 1,
			},
		},
		["deatheffect"] = {
			[1] = {
				["delay"] = 0.05,
				["effect_data"] = {
					["color"] = {
						[1] = "__RANDOM",
						[2] = 0,
						[3] = 7,
					},
				},
				["name"] = {
					["name"] = "BloodImpact",
					["type"] = "effects",
				},
				["reps"] = {
					[1] = "__RANDOM",
					[2] = 6,
					[3] = 10,
				},
				["type"] = "effect",
			},
		},
		["entity_type"] = "npc",
		["manhacks"] = {
			[1] = "__RANDOM",
			[2] = 0,
			[3] = 1,
		},
		["maxhealth"] = 1,
		["npcd_enabled"] = true,
		["quota_weight"] = 0.1,
		["regen"] = -1,
		["regendelay"] = {
			[1] = "__RAND",
			[2] = 300,
			[3] = 600,
		},
		["relationships_inward"] = {
			["by_class"] = {
				[1] = {
					["classname"] = {
						["name"] = "npc_combine_s",
						["type"] = "NPC",
					},
					["disposition"] = "Hostile",
					["priority"] = {
						[1] = "__RAND",
						[2] = 0,
						[3] = 99,
					},
				},
			},
		},
		["relationships_outward"] = {
			["by_class"] = {
				[1] = {
					["classname"] = {
						["name"] = "npc_combine_s",
						["type"] = "NPC",
					},
					["disposition"] = "Hostile",
					["priority"] = {
						[1] = "__RAND",
						[2] = 0,
						[3] = 99,
					},
				},
			},
		},
		["removebody"] = true,
		["rendercolor"] = {
			[1] = "__RANDOMCOLOR",
		},
		["scale"] = {
			[1] = "__RAND",
			[2] = 0.1,
			[3] = 0.3,
		},
		["spawneffect"] = {
			[1] = {
				["name"] = {
					["name"] = "balloon_pop",
					["type"] = "effects",
				},
				["type"] = "effect",
			},
		},
		["spawnflags"] = {
			[1] = "Don\'t drop weapons",
		},
		["startalpha"] = 255,
		["weapon_proficiency"] = "Poor",
		["weapon_set"] = {
			["name"] = "HL2 Stunstick",
			["type"] = "weapon_set",
		},
		["weapondrawn"] = true,
	} )

	npcd.InsertPending( profile_name, "npc", "Party Favors", {
		["VERSION"] = 20,
		["activate"] = false,
		["bloodcolor"] = "DONT_BLEED",
		["classname"] = {
			["name"] = "npc_manhack",
			["type"] = "NPC",
		},
		["deatheffect"] = {
			[1] = {
				["name"] = "balloon_pop",
				["type"] = "effect",
			},
		},
		["entity_type"] = "npc",
		["maxhealth"] = 5,
		["model"] = {
			[1] = "__TBLRANDOM",
			[2] = "models/balloons/balloon_star.mdl",
			[3] = "models/balloons/balloon_dog.mdl",
			[4] = "models/maxofs2d/balloon_classic.mdl",
			[5] = "models/maxofs2d/balloon_classic.mdl",
			[6] = "models/balloons/balloon_classicheart.mdl",
		},
		["noidle"] = true,
		["npcd_enabled"] = true,
		["quota_weight"] = 0.01,
		["regen"] = -5,
		["regendelay"] = {
			[1] = "__RAND",
			[2] = 120,
			[3] = 300,
		},
		["relationships_outward"] = {
			["everyone"] = {
				["disposition"] = "Friendly",
				["priority"] = 99,
			},
		},
		["removebody"] = true,
		["rendercolor"] = {
			[1] = "__RANDOMCOLOR",
			[4] = 1,
			[6] = 1,
		},
		["scale"] = {
			[1] = "__RAND",
			[2] = 1,
			[3] = 2,
		},
		["seekout_clear"] = true,
		["spawneffect"] = {
		},
		["spawnflags"] = {
			[1] = 131072,
			[2] = 65536,
		},
		["start_patrol"] = true,
	} )

	npcd.InsertPending( profile_name, "npc", "Rebel Rat", {
		["VERSION"] = 20,
		["animspeed"] = 1.35,
		["bloodcolor"] = "BLOOD_COLOR_YELLOW",
		["citizentype"] = {
			[1] = "__RANDOM",
			[2] = 1,
			[3] = 3,
		},
		["classname"] = {
			["name"] = "npc_citizen",
			["type"] = "NPC",
		},
		["damagefilter_in"] = {
			[1] = {
				["min"] = 4,
			},
		},
		["damagefilter_out"] = {
			[1] = {
				["max"] = {
					[1] = "__RANDOM",
					[2] = 0,
					[3] = 1,
				},
			},
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
		["material"] = "models/player/shared/ice_player",
		["maxhealth"] = 10,
		["moveact"] = "ACT_RUN_CROUCH",
		["npcd_enabled"] = true,
		["quota_weight"] = 1,
		["relationships_outward"] = {
			["by_class"] = {
				[1] = {
					["classname"] = "player",
					["disposition"] = "Hostile",
					["priority"] = {
						[1] = "__RAND",
						[2] = 0,
						[3] = 99,
					},
				},
			},
		},
		["renderamt"] = 184,
		["rendercolor"] = {
			[1] = "__RANDOMCOLOR",
			[6] = 1,
		},
		["scale"] = {
			[1] = "__RAND",
			[2] = 0.7,
			[3] = 0.9,
		},
		["scale_proportion"] = {
			[1] = "__RAND",
			[2] = 0.3,
			[3] = 0.4,
		},
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
			[1] = "Random Head",
			[2] = "Don\'t drop weapons",
		},
		["start_patrol"] = true,
		["weapon_set"] = {
			["name"] = "HL2 Pistol Wireframe",
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

	npcd.InsertPending( profile_name, "npc", "Machine", {
		["VERSION"] = 20,
		["bloodcolor"] = "BLOOD_COLOR_GREEN",
		["bone_scale"] = 2,
		["classname"] = {
			["name"] = "npc_strider",
			["type"] = "NPC",
		},
		["damagefilter_in"] = {
			[1] = {
				["condition"] = {
					["damage"] = {
						["explosion"] = true,
					},
				},
				["continue"] = true,
				["damagescale"] = 0,
			},
			[2] = {
				["condition"] = {
					["damage"] = {
						["greater"] = 0.1,
					},
				},
				["victim"] = {
					["effects"] = {
						[1] = {
							["attachment"] = 12,
							["effect_data"] = {
								["scale"] = {
									[1] = "__RAND",
									[2] = 0.8,
									[3] = 1,
								},
							},
							["name"] = {
								["name"] = "StriderBlood",
								["type"] = "effects",
							},
							["offset"] = {
								[1] = "__RANDOMVECTOR",
								[2] = 15,
								[3] = 80,
								[4] = -30,
								[5] = 30,
								[6] = -80,
								[7] = -40,
							},
							["type"] = "effect",
						},
					},
					["leech"] = -0.3,
				},
			},
		},
		["damagefilter_out"] = {
			[1] = {
				["condition"] = {
					["victim"] = {
						["types"] = {
							["exclude"] = {
								[1] = "player",
							},
						},
					},
				},
				["damagescale"] = 2,
			},
		},
		["deatheffect"] = {
			[1] = {
				["attachment"] = 3,
				["effect_data"] = {
					["scale"] = 2,
				},
				["name"] = {
					["name"] = "StriderBlood",
					["type"] = "effects",
				},
				["reps"] = 5,
				["type"] = "effect",
			},
		},
		["drop_set"] = {
			[1] = {
				["drop_set"] = {
					["name"] = "Grand Level Drops",
					["type"] = "drop_set",
				},
			},
			[2] = {
				["drop_set"] = {
					["name"] = "Bomb",
					["type"] = "drop_set",
				},
			},
		},
		["entity_type"] = "npc",
		["long_range"] = true,
		["material"] = "models/XQM/LightLinesRed_tool",
		["maxhealth"] = 500,
		["npcd_enabled"] = true,
		["postdamage_drop_set"] = {
			[1] = {
				["chance"] = {
					["d"] = 2,
					["f"] = 0.5,
					["n"] = 1,
				},
				["drop_set"] = {
					["name"] = "Bomber",
					["type"] = "drop_set",
				},
				["health_lesser"] = {
					["d"] = 20,
					["f"] = 0.65,
					["n"] = 13,
				},
				["ignore_took"] = true,
				["max"] = 1,
			},
			[2] = {
				["chance"] = {
					["d"] = 10,
					["f"] = 0.1,
					["n"] = 1,
				},
				["drop_set"] = {
					["name"] = "Bomber",
					["type"] = "drop_set",
				},
				["health_lesser"] = {
					["d"] = 10,
					["f"] = 0.3,
					["n"] = 3,
				},
				["ignore_took"] = true,
				["max"] = 1,
			},
			[3] = {
				["chance"] = {
					["d"] = 125,
					["f"] = 0.008,
					["n"] = 1,
				},
				["drop_set"] = {
					["name"] = "Bomber",
					["type"] = "drop_set",
				},
				["health_lesser"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["ignore_took"] = true,
				["max"] = 2,
			},
		},
		["quota_weight"] = 1,
		["relationships_inward"] = {
			["everyone"] = {
				["disposition"] = "Hostile",
				["exclude"] = {
					["by_preset"] = {
						[1] = {
							["name"] = "Tumbleweed",
							["type"] = "npc",
						},
						[2] = {
							["name"] = "Machine",
							["type"] = "npc",
						},
					},
				},
			},
		},
		["relationships_outward"] = {
			["everyone"] = {
				["disposition"] = "Hostile",
				["exclude"] = {
					["by_preset"] = {
						[1] = {
							["name"] = "Tumbleweed",
							["type"] = "npc",
						},
						[2] = {
							["name"] = "Machine",
							["type"] = "npc",
						},
					},
				},
			},
		},
		["removebody"] = true,
		["removebody_delay"] = 180,
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
		["start_patrol"] = true,
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
		["relationships_inward"] = {
			["everyone"] = {
				["disposition"] = "Hostile",
				["exclude"] = {
					["by_preset"] = {
						[1] = {
							["name"] = "Machine",
							["type"] = "npc",
						},
						[2] = {
							["name"] = "Tumbleweed",
							["type"] = "npc",
						},
					},
				},
				["priority"] = 0,
			},
		},
		["relationships_outward"] = {
			["everyone"] = {
				["disposition"] = "Hostile",
				["exclude"] = {
					["by_preset"] = {
						[1] = {
							["name"] = "Machine",
							["type"] = "npc",
						},
						[2] = {
							["name"] = "Tumbleweed",
							["type"] = "npc",
						},
					},
				},
				["priority"] = 99,
			},
		},
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

	npcd.InsertPending( profile_name, "npc", "New Man", {
		["VERSION"] = 20,
		["animspeed"] = 2,
		["bloodcolor"] = "BLOOD_COLOR_RED",
		["classname"] = {
			["name"] = "npc_dog",
			["type"] = "NPC",
		},
		["damagefilter_in"] = {
			[1] = {
				["condition"] = {
					["victim"] = {
						["types"] = {
							["exclude"] = {
							},
							["include"] = {
								[1] = "self",
							},
						},
					},
				},
				["damagescale"] = 0,
			},
			[2] = {
				["condition"] = {
					["damage"] = {
						["greater_than_health"] = true,
					},
				},
				["damagescale"] = 0,
				["victim"] = {
					["apply_preset"] = {
						["name"] = "Normal Citizen",
						["type"] = "npc",
					},
					["heal"] = {
						["d"] = 1,
						["f"] = 1,
						["n"] = 1,
					},
				},
			},
			[3] = {
				["condition"] = {
					["damage"] = {
						["greater"] = 0,
					},
				},
				["victim"] = {
					["effects"] = {
						[1] = {
							["name"] = {
								[1] = "__TBLRANDOM",
								[2] = "vo/npc/male01/imhurt01.wav",
								[3] = "vo/npc/male01/imhurt02.wav",
								[4] = "vo/npc/male01/myarm01.wav",
								[5] = "vo/npc/male01/myarm02.wav",
								[6] = "vo/npc/male01/mygut02.wav",
								[7] = "vo/npc/male01/myleg01.wav",
								[8] = "vo/npc/male01/myleg02.wav",
								[9] = "vo/npc/male01/no02.wav",
								[10] = "vo/npc/male01/ow01.wav",
								[11] = "vo/npc/male01/ow02.wav",
								[12] = "vo/npc/male01/pain01.wav",
								[13] = "vo/npc/male01/pain02.wav",
								[14] = "vo/npc/male01/pain03.wav",
								[15] = "vo/npc/male01/pain04.wav",
								[16] = "vo/npc/male01/pain05.wav",
								[17] = "vo/npc/male01/pain06.wav",
								[18] = "vo/npc/male01/pain07.wav",
								[19] = "vo/npc/male01/pain08.wav",
								[20] = "vo/npc/male01/pain09.wav",
							},
							["type"] = "sound",
						},
					},
				},
			},
		},
		["damagefilter_out"] = {
			[1] = {
				["max"] = 50,
			},
		},
		["engineflags"] = {
			[1] = "EFL_NO_DISSOLVE",
		},
		["entity_type"] = "npc",
		["material"] = {
			[1] = "__TBLRANDOM",
			[2] = "models/humans/male/group01/art_facemap",
			[3] = "models/humans/male/group01/erdim_cylmap",
			[4] = "models/humans/male/group01/erdim_facemap",
			[5] = "models/humans/male/group01/eric_facemap",
			[6] = "models/humans/male/group01/joe_facemap",
			[7] = "models/humans/male/group01/mike_facemap",
			[8] = "models/humans/male/group01/sandro_facemap",
			[9] = "models/humans/male/group01/ted_facemap",
			[10] = "models/humans/male/group01/van_facemap",
			[11] = "models/humans/male/group01/vance_facemap",
		},
		["maxhealth"] = 225,
		["npcd_enabled"] = true,
		["quota_fakeweight"] = -10,
		["quota_weight"] = 1,
		["relationships_inward"] = {
			["everyone"] = {
				["disposition"] = "Hostile",
				["priority"] = 99,
			},
		},
		["relationships_outward"] = {
			["everyone"] = {
				["disposition"] = "Hostile",
				["priority"] = 99,
			},
		},
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
		["start_patrol"] = true,
		["weapon_proficiency"] = "Perfect",
		["weapon_set"] = {
			["name"] = "RPinGas",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Soldier Boy", {
		["VERSION"] = 20,
		["bones"] = {
			[1] = {
				["bone"] = "L_Foot",
				["offset"] = {
					[1] = "__RANDOMVECTOR",
					[2] = 0,
					[3] = 0,
					[4] = -8,
					[5] = 0,
					[6] = 0,
					[7] = 0,
				},
			},
			[2] = {
				["bone"] = "Spine",
				["offset"] = Vector( 0, 0, -2 ),
				["rotate"] = {
					[1] = "__TBLRANDOM",
					[2] = Angle( 0, -10, 0 ),
					[3] = Angle( 0, 10, 0 ),
				},
			},
			[3] = {
				["bone"] = "Head1",
				["rotate"] = {
					[1] = "__TBLRANDOM",
					[2] = Angle( 0, -10, 0 ),
					[3] = Angle( 0, 10, 0 ),
					[4] = Angle( 0, 0, 0 ),
				},
			},
			[4] = {
				["bone"] = "R_Forearm",
				["jiggle"] = true,
			},
			[5] = {
				["bone"] = "R_Hand",
				["jiggle"] = true,
			},
		},
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
		["material"] = {
			[1] = "__TBLRANDOM",
			[2] = "models/props_combine/tprings_globe",
			[3] = "models/props_combine/stasisshield_sheet",
			[4] = "models/shadertest/shader5",
			[5] = "models/props_lab/Tank_Glass001",
			[6] = "models/props_combine/com_shield001a",
			[7] = "models/flesh",
			[8] = "models/effects/slimebubble_sheet",
			[9] = "models/props_lab/xencrystal_sheet",
			[10] = "models/player/shared/ice_player",
		},
		["npcd_enabled"] = true,
		["numgrenades"] = {
			[1] = "__RANDOM",
			[2] = 0,
			[3] = 2,
		},
		["quota_weight"] = 1,
		["rendercolor"] = {
			[1] = "__RANDOMCOLOR",
		},
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
		["tacticalvariant"] = {
			[1] = "__RANDOM",
			[2] = 0,
			[3] = 2,
		},
		["weapon_set"] = {
			["name"] = "HL2 Two-Handed",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Rebel Giant Rat", {
		["VERSION"] = 20,
		["animspeed"] = 0.75,
		["bloodcolor"] = "BLOOD_COLOR_YELLOW",
		["citizentype"] = {
			[1] = "__RANDOM",
			[2] = 1,
			[3] = 3,
		},
		["classname"] = {
			["name"] = "npc_citizen",
			["type"] = "NPC",
		},
		["damagefilter_in"] = {
			[1] = {
				["min"] = 4,
			},
		},
		["damagefilter_out"] = {
			[1] = {
				["max"] = {
					[1] = "__RAND",
					[2] = 30,
					[3] = 35,
				},
			},
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
		["material"] = "models/player/shared/gold_player",
		["maxhealth"] = 110,
		["moveact"] = "ACT_WALK",
		["npcd_enabled"] = true,
		["quota_weight"] = 1,
		["relationships_outward"] = {
			["by_class"] = {
				[1] = {
					["classname"] = "player",
					["disposition"] = "Hostile",
					["priority"] = {
						[1] = "__RAND",
						[2] = 0,
						[3] = 99,
					},
				},
			},
		},
		["rendercolor"] = {
			[1] = "__RANDOMCOLOR",
			[6] = 1,
		},
		["scale"] = {
			[1] = "__RAND",
			[2] = 1.4,
			[3] = 1.5,
		},
		["scale_proportion"] = {
			[1] = "__RAND",
			[2] = 0.2,
			[3] = 0.3,
		},
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
			[1] = "Random Head",
			[2] = "Don\'t drop weapons",
		},
		["start_patrol"] = true,
		["weapon_set"] = {
			["name"] = "HL2 RPG",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Persistent Headcrab", {
		["VERSION"] = 20,
		["classname"] = {
			["name"] = "npc_headcrab",
			["type"] = "NPC",
		},
		["drop_set"] = {
			[1] = {
				["drop_set"] = {
					["name"] = "Headcrab Persistence",
					["type"] = "drop_set",
				},
			},
			[2] = {
				["drop_set"] = {
					["name"] = "Miniscule Level Drops",
					["type"] = "drop_set",
				},
			},
		},
		["entity_type"] = "npc",
		["material"] = {
			[1] = "__TBLRANDOM",
			[2] = "models/zombie_fast/fast_zombie_sheet",
			[3] = "models/flesh",
			[4] = "models/gibs/hgibs/spine",
		},
		["npcd_enabled"] = true,
		["quota_weight"] = 1,
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
	} )

	npcd.InsertPending( profile_name, "npc", "Nicht Keiner", {
		LOOKUP_REROLL = {
			["actdelay"] = true,
			["activity"] = true,
		},
		["VERSION"] = 20,
		["actdelay"] = {
			[1] = "__RAND",
			[2] = 1,
			[3] = 15,
		},
		["activity"] = {
			[1] = "__TBLRANDOM",
			[2] = "ACT_RUN",
			[3] = "ACT_RANGE_ATTACK1",
		},
		["animspeed"] = 1.22,
		["chase_setenemy"] = true,
		["chase_settarget"] = true,
		["classname"] = {
			["name"] = "npc_fastzombie",
			["type"] = "NPC",
		},
		["effects"] = {
			[1] = {
				["name"] = "npc/fast_zombie/breathe_loop1.wav",
				["sound"] = {
					["channel"] = "CHAN_AUTO",
					["dist"] = 511,
					["pitch"] = 0,
					["restart"] = false,
					["volume"] = 1,
				},
				["type"] = "sound",
			},
		},
		["entity_type"] = "npc",
		["force_approach"] = true,
		["maxhealth"] = 101,
		["model"] = "models/Kleiner.mdl",
		["npcd_enabled"] = true,
		["quota_weight"] = 1,
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
		["weapon_set"] = {
			["name"] = "HL2 Crowbar",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Metro Clown", {
		["VERSION"] = 20,
		["bloodcolor"] = {
			[1] = "__TBLRANDOM",
			[2] = "BLOOD_COLOR_RED",
			[3] = "BLOOD_COLOR_YELLOW",
			[4] = "BLOOD_COLOR_GREEN",
			[5] = "BLOOD_COLOR_ANTLION",
			[6] = "BLOOD_COLOR_ZOMBIE",
			[7] = "BLOOD_COLOR_ANTLION_WORKER",
		},
		["childpreset"] = {
			["name"] = "Party Favors",
			["type"] = "npc",
		},
		["classname"] = {
			["name"] = "npc_metropolice",
			["type"] = "NPC",
		},
		["damagefilter_in"] = {
			[1] = {
				["condition"] = {
					["damage"] = {
						["greater"] = 15,
					},
				},
				["victim"] = {
					["jigglify"] = true,
				},
			},
		},
		["damagefilter_out"] = {
			[1] = {
				["condition"] = {
					["victim"] = {
						["types"] = {
							["exclude"] = {
							},
							["include"] = {
								[1] = "player",
							},
						},
					},
				},
				["max"] = {
					[1] = "__RAND",
					[2] = 8,
					[3] = 10,
				},
			},
		},
		["drop_set"] = {
			[1] = {
				["chance"] = {
					["d"] = 7,
					["f"] = 0.14285714285714,
					["n"] = 1,
				},
				["drop_set"] = {
					["name"] = "Clown Car",
					["type"] = "drop_set",
				},
			},
			[2] = {
				["drop_set"] = {
					["name"] = "Low Level Drops",
					["type"] = "drop_set",
				},
			},
		},
		["entity_type"] = "npc",
		["manhacks"] = {
			[1] = "__RANDOM",
			[2] = 0,
			[3] = 1,
		},
		["npcd_enabled"] = true,
		["quota_weight"] = 1,
		["relationships_inward"] = {
			["by_class"] = {
				[1] = {
					["classname"] = {
						["name"] = "npc_combine_s",
						["type"] = "NPC",
					},
					["disposition"] = "Hostile",
					["priority"] = {
						[1] = "__RAND",
						[2] = 0,
						[3] = 99,
					},
				},
			},
		},
		["relationships_outward"] = {
			["by_class"] = {
				[1] = {
					["classname"] = {
						["name"] = "npc_combine_s",
						["type"] = "NPC",
					},
					["disposition"] = "Hostile",
					["priority"] = {
						[1] = "__RAND",
						[2] = 0,
						[3] = 99,
					},
				},
			},
		},
		["rendercolor"] = {
			[1] = "__RANDOMCOLOR",
		},
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
		["weapon_proficiency"] = "Poor",
		["weapon_set"] = {
			["name"] = "HL2 One-Handed",
			["type"] = "weapon_set",
		},
	} )

	npcd.InsertPending( profile_name, "npc", "Vortest", {
		["VERSION"] = 20,
		["animspeed"] = 0.7,
		["classname"] = {
			["name"] = "npc_vortigaunt",
			["type"] = "NPC",
		},
		["damagefilter_in"] = {
		},
		["damagefilter_out"] = {
			[1] = {
				["condition"] = {
					["victim"] = {
						["types"] = {
							["exclude"] = {
								[1] = "player",
							},
							["include"] = {
								[1] = "character",
							},
						},
					},
				},
				["max"] = {
					[1] = "__RAND",
					[2] = 60,
					[3] = 70,
				},
				["victim"] = {
					["explode"] = {
						["damage"] = 20,
						["enabled"] = true,
						["radius"] = 180,
					},
				},
			},
			[2] = {
				["max"] = {
					[1] = "__RAND",
					[2] = 20,
					[3] = 40,
				},
				["victim"] = {
					["explode"] = {
						["damage"] = 20,
						["radius"] = 180,
					},
				},
			},
		},
		["damagescale_in"] = 0.65,
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
		["maxhealth"] = 230,
		["npcd_enabled"] = true,
		["quota_weight"] = 1,
		["relationships_inward"] = {
			["by_preset"] = {
				[1] = {
					["disposition"] = "Friendly",
					["preset"] = {
						["name"] = "Vort",
						["type"] = "npc",
					},
					["priority"] = 99,
				},
				[2] = {
					["disposition"] = "Friendly",
					["preset"] = {
						["name"] = "Vortest",
						["type"] = "npc",
					},
				},
			},
			["everyone"] = {
				["disposition"] = "Hostile",
			},
		},
		["relationships_outward"] = {
			["by_preset"] = {
				[1] = {
					["disposition"] = "Friendly",
					["preset"] = {
						["name"] = "Vort",
						["type"] = "npc",
					},
				},
				[2] = {
					["disposition"] = "Friendly",
					["preset"] = {
						["name"] = "Vortest",
						["type"] = "npc",
					},
				},
			},
			["everyone"] = {
				["disposition"] = "Hostile",
			},
		},
		["rendercolor"] = {
			[1] = "__RANDOMCOLOR",
			[2] = 260.37735849057,
			[3] = 369.05660377358,
			[4] = 0.35,
			[6] = 1,
		},
		["scale"] = {
			[1] = "__RAND",
			[2] = 1.8,
			[3] = 2.1,
		},
		["seekout_clear"] = true,
		["skin"] = 1,
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
		["spritetrail"] = {
			[1] = {
				["attachment"] = 3,
				["color"] = Color( 255, 0, 0 ),
			},
			[2] = {
				["attachment"] = 4,
				["color"] = Color( 255, 0, 0 ),
			},
		},
		["start_patrol"] = true,
	} )

	npcd.InsertPending( profile_name, "npc", "Normal Citizen", {
		["VERSION"] = 20,
		["bloodcolor"] = "BLOOD_COLOR_RED",
		["citizentype"] = {
			[1] = "__RANDOM",
			[2] = 1,
			[3] = 2,
		},
		["classname"] = {
			["name"] = "npc_citizen",
			["type"] = "NPC",
		},
		["entity_type"] = "npc",
		["material"] = "",
		["maxhealth"] = 15,
		["model"] = {
			[1] = "__TBLRANDOM",
			[2] = "models/Humans/Group01/male_01.mdl",
			[3] = "models/Humans/Group01/male_02.mdl",
			[4] = "models/Humans/Group01/male_03.mdl",
			[5] = "models/Humans/Group01/male_04.mdl",
			[6] = "models/Humans/Group01/male_05.mdl",
			[7] = "models/Humans/Group01/male_06.mdl",
			[8] = "models/Humans/Group01/male_07.mdl",
			[9] = "models/Humans/Group01/male_08.mdl",
			[10] = "models/Humans/Group01/male_09.mdl",
			[11] = "models/Humans/Group02/male_01.mdl",
			[12] = "models/Humans/Group02/male_02.mdl",
			[13] = "models/Humans/Group02/male_03.mdl",
			[14] = "models/Humans/Group02/male_04.mdl",
			[15] = "models/Humans/Group02/male_05.mdl",
			[16] = "models/Humans/Group02/male_06.mdl",
			[17] = "models/Humans/Group02/male_07.mdl",
			[18] = "models/Humans/Group02/male_08.mdl",
			[19] = "models/Humans/Group02/male_09.mdl",
		},
		["npcd_enabled"] = true,
		["quota_weight"] = 1,
		["regen"] = -30,
		["regendelay"] = {
			[1] = "__RAND",
			[2] = 240,
			[3] = 480,
		},
		["relationships_outward"] = {
			["by_class"] = {
				[1] = {
					["classname"] = {
						["name"] = "npc_citizen",
						["type"] = "NPC",
					},
					["disposition"] = "Friendly",
					["priority"] = {
						[1] = "__RAND",
						[2] = 0,
						[3] = 99,
					},
				},
				[2] = {
					["classname"] = "player",
					["disposition"] = "Friendly",
					["priority"] = {
						[1] = "__RAND",
						[2] = 0,
						[3] = 99,
					},
				},
			},
			["everyone"] = {
				["disposition"] = "Friendly",
				["priority"] = 99,
			},
			["self_squad"] = {
				["disposition"] = "Friendly",
				["priority"] = 99,
			},
		},
		["seekout_clear"] = true,
		["spawneffect"] = {
			[1] = {
				["delay"] = {
					[1] = "__RAND",
					[2] = 0.5,
					[3] = 1,
				},
				["name"] = {
					[1] = "__TBLRANDOM",
					[2] = "vo/npc/male01/sorrydoc01.wav",
					[3] = "vo/npc/male01/sorrydoc02.wav",
					[4] = "vo/npc/male01/sorrydoc04.wav",
				},
				["type"] = "sound",
			},
		},
		["start_patrol"] = true,
		["weapon_set"] = {
			["name"] = "No Weapon",
			["type"] = "weapon_set",
		},
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

	npcd.InsertPending( profile_name, "squad", "Dancing Bugmen", {
		["VERSION"] = 20,
		["description"] = "Friends",
		["mapmax"] = 2,
		["npcd_enabled"] = true,
		["spawnforce"] = {
			LOOKUP_REROLL = {
				["forward"] = true,
			},
			["forward"] = {
				[1] = "__RAND",
				[2] = 100,
				[3] = 1200,
			},
			["rotrandom"] = true,
		},
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 8,
					["min"] = 3,
				},
				["preset"] = {
					["name"] = "Bugman",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Lil Silly", {
		["VERSION"] = 20,
		["fadein"] = true,
		["npcd_enabled"] = true,
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 4,
					["min"] = 2,
				},
				["preset"] = {
					["name"] = "Tiny Clown",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "One Fear", {
		["VERSION"] = 20,
		["announce_death"] = true,
		["announce_spawn"] = true,
		["announce_spawn_message"] = {
			[1] = "__TBLRANDOM",
			[2] = "One Fear arrives!",
			[3] = "One Fear has arrived!",
			[4] = "One Fear appears!",
		},
		["mapmax"] = 2,
		["mindelay"] = 120,
		["npcd_enabled"] = true,
		["spawnlist"] = {
			[1] = {
				["preset"] = {
					["name"] = "One Fear",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Rebel Rats", {
		["VERSION"] = 20,
		["fadein"] = true,
		["hivequeen"] = {
			["name"] = "Rebel Giant Rat",
			["type"] = "npc",
		},
		["hivequeen_maxdist"] = 5000,
		["hivequeen_mutual"] = true,
		["npcd_enabled"] = true,
		["override_hard"] = {
			["npc"] = {
				["deatheffect"] = {
					[1] = {
						["attachment"] = 1,
						["name"] = "cball_bounce",
						["type"] = "effect",
					},
				},
			},
		},
		["spawnlist"] = {
			[1] = {
				["preset"] = {
					["name"] = "Rebel Giant Rat",
					["type"] = "npc",
				},
			},
			[2] = {
				["count"] = {
					["max"] = 5,
					["min"] = 4,
				},
				["preset"] = {
					["name"] = "Rebel Rat",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "The Machine", {
		["VERSION"] = 20,
		["announce_color"] = {
			[1] = "__RANDOMCOLOR",
			[2] = 340,
			[3] = 380,
			[6] = 1,
			[7] = 1,
		},
		["announce_death_message"] = "The Machine has shut down.",
		["announce_spawn_message"] = "The Machine has activated.",
		["fadein"] = false,
		["mindelay"] = 300,
		["npcd_enabled"] = true,
		["spawnforce"] = {
			["forward"] = 15,
			["up"] = 0,
		},
		["spawnlist"] = {
			[1] = {
				["count"] = {
				},
				["preset"] = {
					["name"] = "Machine",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Soldier Boys", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 4,
					["median"] = 2.5,
					["min"] = 2,
				},
				["preset"] = {
					["name"] = "Soldier Boy",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Fireflies", {
		["VERSION"] = 20,
		["fadein"] = true,
		["npcd_enabled"] = true,
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 7,
					["median"] = 5,
					["min"] = 4,
				},
				["preset"] = {
					["name"] = "Firefly",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Couch Fountains", {
		["VERSION"] = 20,
		["fadein"] = false,
		["mapmax"] = 5,
		["mindelay"] = 160,
		["npcd_enabled"] = true,
		["spawnforce"] = {
			["forward"] = {
				[1] = "__RAND",
				[2] = 300,
				[3] = 600,
			},
			["up"] = -5,
		},
		["spawnlist"] = {
			[1] = {
				["preset"] = {
					["name"] = "Couch Fountain",
					["type"] = "entity",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "New Men", {
		["VERSION"] = 20,
		["mapmax"] = 2,
		["nocollide"] = true,
		["npcd_enabled"] = true,
		["spawnforce"] = {
			["forward"] = {
				[1] = "__RAND",
				[2] = 300,
				[3] = 600,
			},
			["up"] = -5,
		},
		["spawnlist"] = {
			[1] = {
				["preset"] = {
					["name"] = "New Man",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Now About That Beer I Ow", {
		["VERSION"] = 20,
		["announce_all"] = true,
		["announce_death_message"] = "And if you see Dr. Breen, tell him I said ABOUT THAT BEER I OWE YA!",
		["announce_spawn_message"] = "Now, about that beer I owe ya...",
		["description"] = "Just like old times, ey, Gordon?",
		["mindelay"] = 600,
		["npcd_enabled"] = true,
		["spawnforce"] = {
			["forward"] = {
				[1] = "__RAND",
				[2] = 300,
				[3] = 600,
			},
			["up"] = -5,
		},
		["spawnlist"] = {
			[1] = {
				["preset"] = {
					["name"] = "Insane Beer Lover",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "IT HAS A GUN", {
		["VERSION"] = 20,
		["announce_all"] = true,
		["announce_death_message"] = "IT DEAD!",
		["announce_spawn_message"] = "IT HAS A GUN!",
		["description"] = "Dev Diary: Today I coded giving NPCs weapons",
		["mapmax"] = 1,
		["npcd_enabled"] = true,
		["override_hard"] = {
			["npc"] = {
				["damagefilter_out"] = {
					[1] = {
						["condition"] = {
							["victim"] = {
								["types"] = {
									["exclude"] = {
										[1] = "self",
										[2] = "player",
									},
									["include"] = {
										[1] = "character",
									},
								},
							},
						},
						["damagescale"] = {
							[1] = "__RAND",
							[2] = 4,
							[3] = 10,
						},
					},
				},
				["drop_set"] = {
					[1] = {
						["drop_set"] = {
							["name"] = "Buckcrab Persistence",
							["type"] = "drop_set",
						},
					},
				},
				["force_approach"] = true,
				["material"] = "",
				["weapon_set"] = {
					["name"] = "HL2 Shotgun",
					["type"] = "weapon_set",
				},
			},
		},
		["spawnlist"] = {
			[1] = {
				["count"] = {
				},
				["preset"] = {
					["name"] = "Persistent Headcrab",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Drone Warfare", {
		["VERSION"] = 20,
		["fadein_nodelay"] = true,
		["mapmax"] = 2,
		["npcd_enabled"] = true,
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 3,
					["min"] = 3,
				},
				["preset"] = {
					["name"] = "Drone Strike",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "The Vorts", {
		["VERSION"] = 20,
		["npcd_enabled"] = false,
		["override_hard"] = {
			["npc"] = {
				["maxhealth"] = 60,
			},
		},
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 3,
					["min"] = 2,
				},
				["preset"] = {
					["name"] = "Vort",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Many, Many Fears", {
		["VERSION"] = 20,
		["announce_death"] = true,
		["announce_spawn"] = false,
		["description"] = "Sorry",
		["fadein_nodelay"] = true,
		["npcd_enabled"] = true,
		["override_hard"] = {
			["npc"] = {
				["animspeed"] = 2,
				["damagefilter_out"] = {
					[1] = {
						["damagescale"] = 0.75,
					},
				},
				["drop_set"] = {
					[1] = {
						["drop_set"] = {
							["name"] = "Fear Determination, Least",
							["type"] = "drop_set",
						},
					},
					[2] = {
						["drop_set"] = {
							["name"] = "Miniscule Level Drops",
							["type"] = "drop_set",
						},
					},
				},
				["maxhealth"] = 4,
				["quota_weight"] = 0.0625,
				["regen"] = -100,
				["regendelay"] = {
					[1] = "__RAND",
					[2] = 180,
					[3] = 240,
				},
				["scale"] = 1,
				["spawneffect"] = {
					[1] = {
						["delay"] = 0.15,
						["name"] = "BloodImpact",
						["offset"] = Vector( 0, 0, 7 ),
						["reps"] = 5,
						["type"] = "effect",
					},
				},
			},
		},
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 4,
					["median"] = 4,
					["min"] = 0,
				},
				["preset"] = {
					["name"] = "One Fear",
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

	npcd.InsertPending( profile_name, "squad", "The Vortest", {
		["VERSION"] = 20,
		["announce_all"] = true,
		["mapmax"] = 2,
		["npcd_enabled"] = true,
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 4,
					["median"] = 3,
					["min"] = 3,
				},
				["preset"] = {
					["name"] = "Vort",
					["type"] = "npc",
				},
			},
			[2] = {
				["count"] = {
					["max"] = 2,
					["min"] = 2,
				},
				["preset"] = {
					["name"] = "Vortest",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Many Fears", {
		["VERSION"] = 20,
		["announce_death"] = true,
		["announce_spawn"] = false,
		["description"] = "Editor Tip: Thoughtful use of overrides can make copying entity presets unnecessary",
		["fadein_nodelay"] = true,
		["npcd_enabled"] = true,
		["override_hard"] = {
			["npc"] = {
				["animspeed"] = 1.5,
				["damagefilter_out"] = {
					[1] = {
						["damagescale"] = {
							[1] = "__RAND",
							[2] = 1.5,
							[3] = 2,
						},
					},
				},
				["drop_set"] = {
					[1] = {
						["drop_set"] = {
							["name"] = "Fear Determination, Lesser",
							["type"] = "drop_set",
						},
					},
				},
				["quota_weight"] = 0.25,
				["regen"] = -100,
				["regendelay"] = {
					[1] = "__RAND",
					[2] = 240,
					[3] = 300,
				},
				["scale"] = 2,
				["spawneffect"] = {
					[1] = {
						["delay"] = 0.15,
						["name"] = "BloodImpact",
						["offset"] = Vector( -0.33680000901222, -0.81309998035431, 0 ),
						["reps"] = 5,
						["type"] = "effect",
					},
				},
			},
		},
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 6,
					["median"] = 6,
					["min"] = 0,
				},
				["preset"] = {
					["name"] = "One Fear",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Persistent Headcrab", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["spawnlist"] = {
			[1] = {
				["count"] = {
				},
				["preset"] = {
					["name"] = "Persistent Headcrab",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Metro Clowns", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 4,
					["min"] = 2,
				},
				["preset"] = {
					["name"] = "Metro Clown",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Antlioness", {
		["VERSION"] = 20,
		["fadein_nodelay"] = true,
		["mapmax"] = 2,
		["mindelay"] = 300,
		["npcd_enabled"] = true,
		["spawnlist"] = {
			[1] = {
				["count"] = {
				},
				["preset"] = {
					["name"] = "Antlioness",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "Zexplosive Zombies", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["spawnforce"] = {
			["forward"] = {
				[1] = "__RAND",
				[2] = 1000,
				[3] = 2000,
			},
		},
		["spawnlist"] = {
			[1] = {
				["count"] = {
					["max"] = 5,
					["median"] = 3,
					["min"] = 1,
				},
				["preset"] = {
					["name"] = "Zexplosive Zombie",
					["type"] = "npc",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "squad", "No-Brainer (2)", {
		["VERSION"] = 20,
		["description"] = "Cop with its brain on a leash (Alt)",
		["hivequeen"] = {
			["name"] = "Brainhack",
			["type"] = "npc",
		},
		["hivequeen_maxdist"] = 6000,
		["hivequeen_mutual"] = true,
		["hiverope"] = {
			[1] = {
				["attachment_queen"] = 0,
				["attachment_servant"] = 1,
				["material"] = "cable/red",
				["width"] = 2.5,
			},
		},
		["npcd_enabled"] = true,
		["override_hard"] = {
			["npc"] = {
				["bloodcolor"] = "BLOOD_COLOR_RED",
				["material"] = "",
			},
		},
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

	npcd.InsertPending( profile_name, "spawnpool", "Bosses", {
		["VERSION"] = 20,
		["initdelay"] = {
			[1] = "__RAND",
			[2] = 45,
			[3] = 90,
		},
		["mindelay"] = {
			[1] = "__RAND",
			[2] = 60,
			[3] = 120,
		},
		["minpressure"] = 0.3,
		["npcd_enabled"] = true,
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
		},
		["pool_squadlimit"] = 4,
		["radiuslimits"] = {
			[1] = {
				["maxradius"] = 10000,
				["minradius"] = 2000,
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
					["name"] = "One Fear",
					["type"] = "squad",
				},
			},
			[2] = {
				["expected"] = {
					["d"] = 5,
					["f"] = 0.4,
					["n"] = 2,
				},
				["preset"] = {
					["name"] = "The Machine",
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
					["name"] = "Drone Warfare",
					["type"] = "squad",
				},
			},
			[4] = {
				["expected"] = {
					["d"] = 5,
					["f"] = 0.2,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "Now About That Beer I Ow",
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
					["name"] = "IT HAS A GUN",
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
					["name"] = "Elitists",
					["type"] = "squad",
				},
			},
			[7] = {
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
			[8] = {
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "The Vortest",
					["type"] = "squad",
				},
			},
			[9] = {
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "Antlioness",
					["type"] = "squad",
				},
			},
			[10] = {
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "New Men",
					["type"] = "squad",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "spawnpool", "Default", {
		["VERSION"] = 20,
		["initdelay"] = 0,
		["mindelay"] = 0,
		["npcd_enabled"] = true,
		["pool_spawnlimit"] = 60,
		["radiuslimits"] = {
			[1] = {
				["despawn"] = false,
				["maxradius"] = 2750,
				["minradius"] = 1250,
				["radius_autoadjust_max"] = true,
				["radius_autoadjust_min"] = true,
				["radius_entity_limit"] = 15,
				["radius_spawn_autoadjust"] = true,
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
				["despawn_ignorenear"] = 1250,
				["maxradius"] = 32768,
				["minradius"] = 1250,
				["radius_autoadjust_max"] = true,
			},
		},
		["spawn_autoadjust"] = true,
		["spawns"] = {
			[1] = {
				["expected"] = {
					["d"] = 4,
					["f"] = 0.25,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "Dancing Bugmen",
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
					["name"] = "Rebel Rats",
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
					["name"] = "Soldier Boys",
					["type"] = "squad",
				},
			},
			[4] = {
				["expected"] = {
					["d"] = 2,
					["f"] = 0.5,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "Fireflies",
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
					["name"] = "The Vorts",
					["type"] = "squad",
				},
			},
			[6] = {
				["expected"] = {
					["d"] = 4,
					["f"] = 0.75,
					["n"] = 3,
				},
				["preset"] = {
					["name"] = "Persistent Headcrab",
					["type"] = "squad",
				},
			},
			[7] = {
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "Metro Clowns",
					["type"] = "squad",
				},
			},
			[8] = {
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["preset"] = {
					["name"] = "Zexplosive Zombies",
					["type"] = "squad",
				},
			},
		},
	} )

	npcd.InsertPending( profile_name, "spawnpool", "Props", {
		["VERSION"] = 20,
		["initdelay"] = 0,
		["mindelay"] = {
			[1] = "__RAND",
			[2] = 15,
			[3] = 30,
		},
		["npcd_enabled"] = true,
		["pool_spawnlimit"] = 100,
		["radiuslimits"] = {
			[1] = {
				["despawn"] = true,
				["despawn_tooclose"] = 3000,
				["maxradius"] = 32768,
				["minradius"] = 1500,
				["radius_autoadjust"] = true,
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
					["name"] = "Couch Fountains",
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

	npcd.InsertPending( profile_name, "weapon_set", "Quake 3", {
		["VERSION"] = 20,
		["description"] = "Requires the \"Quake 3 Gmod\" addon",
		["exclude"] = "npc",
		["giveall"] = true,
		["npcd_enabled"] = false,
		["removeall"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "weapon_q3_machinegun",
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
					["name"] = "weapon_q3_gauntlet",
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
					["name"] = "weapon_q3_shotgun",
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
					["name"] = "weapon_q3_rocketlauncher",
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
					["name"] = "weapon_q3_grenadelauncher",
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
					["name"] = "weapon_q3_lightninggun",
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
					["name"] = "weapon_q3_plasmagun",
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
					["name"] = "weapon_q3_chaingun",
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
					["name"] = "weapon_q3_railgun",
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
					["name"] = "weapon_q3_bfg10k",
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

	npcd.InsertPending( profile_name, "weapon_set", "Warning Shotty", {
		["VERSION"] = 20,
		["description"] = "Visual changes can be seen in thirdperson",
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["bones"] = {
					[1] = {
						["scale"] = Vector( 0.5, 2, 1 ),
					},
				},
				["classname"] = {
					["name"] = "weapon_shotgun",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["material"] = "phoenix_storms/stripes",
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

	npcd.InsertPending( profile_name, "weapon_set", "Wowozela", {
		["VERSION"] = 20,
		["npcd_enabled"] = false,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "wowozela",
					["type"] = "Weapon",
				},
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["jiggle_all"] = true,
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

	npcd.InsertPending( profile_name, "weapon_set", "Max Ar2y", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "weapon_ar2",
					["type"] = "Weapon",
				},
				["clip_primary"] = 9999,
				["clip_secondary"] = 9999,
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["giveammo_primary"] = 9999,
				["giveammo_secondary"] = 9999,
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

	npcd.InsertPending( profile_name, "weapon_set", "RPinGas", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["bloodcolor"] = "BLOOD_COLOR_RED",
				["bones"] = {
					[1] = {
						["bone"] = 1,
						["scale"] = {
							[1] = "__RANDOMVECTOR",
							[2] = 2,
							[3] = 2.2,
							[4] = 2,
							[5] = 2.2,
							[6] = 1.4,
							[7] = 1.6,
						},
					},
				},
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

	npcd.InsertPending( profile_name, "weapon_set", "Max Smggy", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "weapon_smg1",
					["type"] = "Weapon",
				},
				["clip_primary"] = 9999,
				["clip_secondary"] = 9999,
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["giveammo_primary"] = 9999,
				["giveammo_secondary"] = 9999,
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

	npcd.InsertPending( profile_name, "weapon_set", "Max Shotty", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "weapon_shotgun",
					["type"] = "Weapon",
				},
				["clip_primary"] = 9999,
				["clip_secondary"] = 9999,
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["giveammo_primary"] = 9999,
				["giveammo_secondary"] = 9999,
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "Full Mangun", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "weapon_357",
					["type"] = "Weapon",
				},
				["clip_primary"] = 9999,
				["expected"] = {
					["d"] = 1,
					["f"] = 1,
					["n"] = 1,
				},
				["giveammo_primary"] = 9999,
			},
		},
	} )

	npcd.InsertPending( profile_name, "weapon_set", "Doom", {
		["VERSION"] = 20,
		["description"] = "Requires the \"gmDoom\" addon",
		["exclude"] = "npc",
		["giveall"] = true,
		["npcd_enabled"] = false,
		["removeall"] = true,
		["weapons"] = {
			[1] = {
				["classname"] = {
					["name"] = "doom_weapon_pistol",
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
					["name"] = "doom_weapon_fist",
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
					["name"] = "doom_weapon_chaingun",
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
					["name"] = "doom_weapon_shotgun",
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
					["name"] = "doom_weapon_supershotgun",
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
					["name"] = "doom_weapon_missile",
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
					["name"] = "doom_weapon_plasma",
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
					["name"] = "doom_weapon_chainsaw",
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
					["name"] = "doom_weapon_bfg",
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

	npcd.InsertPending( profile_name, "weapon_set", "HL2 Pistol Wireframe", {
		["VERSION"] = 20,
		["npcd_enabled"] = true,
		["override_hard"] = {
			["weapon"] = {
				["material"] = "models/wireframe",
				["renderamt"] = 170.34836065574,
				["rendercolor"] = {
					[1] = "__RANDOMCOLOR",
					[6] = 1,
				},
			},
		},
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
				["renderamt"] = 149.93055555556,
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

	npcd.InsertPending( profile_name, "entity", "Pick Me Up", {
		["VERSION"] = 20,
		["allow_chased"] = true,
		["classname"] = "prop_physics",
		["description"] = "Note: Physics collisions override normal touch behavior for some items (e.g. health kits)",
		["entity_type"] = "entity",
		["maxhealth"] = 50,
		["model"] = {
			[1] = "__TBLRANDOM",
			[2] = "models/props_junk/garbage_glassbottle003a.mdl",
         [3] = "models/props_junk/glassbottle01a.mdl",
         [4] = "models/props_junk/garbage_glassbottle001a.mdl"
		},
		["npcd_enabled"] = true,
		["physcollide"] = {
			[1] = {
				["damagefilter_out"] = {
					[1] = {
						["attacker"] = {
							["remove"] = true,
						},
						["condition"] = {
							["victim"] = {
								["presets"] = {
									["include"] = {
										[1] = {
											["name"] = "Insane Beer Lover",
											["type"] = "npc",
										},
									},
								},
							},
						},
						["victim"] = {
							["effects"] = {
								[1] = {
									["name"] = {
										[1] = "__TBLRANDOM",
										[2] = "npc/barnacle/barnacle_gulp2.wav",
										[3] = "npc/barnacle/barnacle_gulp1.wav",
									},
									["sound"] = {
										["pitch"] = {
											[1] = "__RAND",
											[2] = 85,
											[3] = 115,
										},
									},
									["type"] = "sound",
								},
								[2] = {
									["name"] = {
										[1] = "__TBLRANDOM",
										[2] = "vo/npc/barney/ba_laugh01.wav",
										[3] = "vo/npc/barney/ba_laugh02.wav",
										[4] = "vo/npc/barney/ba_laugh03.wav",
										[5] = "vo/npc/barney/ba_laugh04.wav",
									},
									["sound"] = {
										["pitch"] = {
											[1] = "__RAND",
											[2] = 85,
											[3] = 115,
										},
									},
									["type"] = "sound",
								},
							},
							["heal"] = {
								["d"] = 5,
								["f"] = -0.4,
								["n"] = -2,
							},
							["jigglify"] = true,
						},
					},
					[2] = {
						["attacker"] = {
							["remove"] = true,
						},
						["condition"] = {
							["victim"] = {
								["classnames"] = {
									["exclude"] = {
										[1] = "prop_dynamic",
										[2] = "prop_static",
									},
								},
								["presets"] = {
									["exclude"] = {
										[1] = {
											["name"] = "Pick Me Up",
											["type"] = "entity",
										},
									},
								},
								["types"] = {
									["exclude"] = {
										[1] = "self",
										[2] = "worldspawn",
										[3] = "environment",
										[4] = "brush",
									},
								},
							},
						},
						["victim"] = {
							["effects"] = {
								[1] = {
									["name"] = {
										[1] = "__TBLRANDOM",
										[2] = "npc/barnacle/barnacle_gulp2.wav",
										[3] = "npc/barnacle/barnacle_gulp1.wav",
									},
									["sound"] = {
										["pitch"] = {
											[1] = "__RAND",
											[2] = 85,
											[3] = 115,
										},
									},
									["type"] = "sound",
								},
							},
							["heal"] = {
								[1] = "__RANDOM",
								[2] = 2,
								[3] = 4,
							},
						},
					},
				},
				["flat_damage"] = 0,
				["no_impact"] = true,
				["no_zero"] = true,
				["speed_min"] = -1,
			},
		},
		["scale"] = {
			[1] = "__RAND",
			[2] = 1,
			[3] = 1.2,
		},
	} )

	npcd.InsertPending( profile_name, "entity", "Couch Fountain", {
		["VERSION"] = 20,
		["classname"] = "prop_physics",
		["damage_drop_set"] = {
			[1] = {
				["chance"] = {
					["d"] = 5,
					["f"] = 0.4,
					["n"] = 2,
				},
				["drop_set"] = {
					["name"] = "Yum",
					["type"] = "drop_set",
				},
				["multidrop_dmg"] = 4,
			},
			[2] = {
				["chance"] = {
					["d"] = 4,
					["f"] = 0.25,
					["n"] = 1,
				},
				["drop_set"] = {
					["name"] = "Low Level Drops",
					["type"] = "drop_set",
				},
				["multidrop_dmg"] = 4,
			},
		},
		["damagefilter_in"] = {
			[1] = {
				["condition"] = {
					["attacker"] = {
						["types"] = {
							["include"] = {
								[1] = "character",
							},
						},
					},
					["victim"] = {
						["spin_greater"] = 1000,
					},
				},
				["continue"] = true,
				["min"] = 200,
			},
			[2] = {
				["victim"] = {
					["drop_set"] = {
						[1] = {
							["chance"] = {
								["d"] = 16,
								["f"] = 0.0625,
								["n"] = 1,
							},
							["drop_set"] = {
								["name"] = "Low Level Drops",
								["type"] = "drop_set",
							},
						},
						[2] = {
							["chance"] = {
								["d"] = 20,
								["f"] = 0.1,
								["n"] = 2,
							},
							["drop_set"] = {
								["name"] = "Yum",
								["type"] = "drop_set",
							},
						},
					},
					["leech"] = -1,
				},
			},
		},
		["deatheffect"] = {
			[1] = {
				["name"] = {
					["name"] = "balloon_pop",
					["type"] = "effects",
				},
				["type"] = "effect",
			},
		},
		["drop_set"] = {
			[1] = {
				["drop_set"] = {
					["name"] = "Yum",
					["type"] = "drop_set",
				},
			},
		},
		["entity_type"] = "entity",
		["killonremove"] = true,
		["maxhealth"] = 200,
		["model"] = "models/props_c17/FurnitureCouch002a.mdl",
		["npcd_enabled"] = true,
		["physobject"] = {
			["angularvelocity"] = Vector( 0, 0, 16384 ),
		},
		["quota_weight"] = 1,
		["regen"] = -5,
		["regendelay"] = {
			[1] = "__RAND",
			[2] = 60,
			[3] = 90,
		},
		["removebody"] = true,
		["scale_proportion"] = 0.05,
	} )

	npcd.StartSettingsPanel()

end )

return profile_name