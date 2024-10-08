local all_defaults = {}
all_defaults.Weapons = {
	[ItemFilters.ItemKeys.WILDCARD] = {
		Filters = {
			[90] = { TargetStat = ItemFilters.FilterFields.TargetStat.WEAPON_ABILITY, CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER },
			[91] = { TargetStat = ItemFilters.FilterFields.TargetStat.WEAPON_SCORE, CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER },
		}
	}
}

all_defaults.Equipment = {
	[ItemFilters.ItemKeys.WILDCARD] = {
		Filters = {
			[50] = { TargetStat = ItemFilters.FilterFields.TargetStat.HAS_TYPE_EQUIPPED },
			[51] = {
				TargetStat = ItemFilters.FilterFields.TargetStat.STACK_AMOUNT,
				CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER,
			},
			[52] = {
				TargetStat = ItemFilters.FilterFields.TargetStat.STACK_AMOUNT,
				CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER,
				CalculateStackUsing = {
					["EQUIPMENT_TYPES"] = { "SELF" },
					["ARMOR_TYPES"] = { "SELF" }
				},
			},
			[53] = { TargetStat = ItemFilters.FilterFields.TargetStat.PROFICIENCY },
		}
	}
}

all_defaults.Roots = {
	-- not a typo :D
	["ALCH_Soultion_Elixir_Barkskin_cc1a8802-675a-426b-a791-ec1d5a5b6328"] = {
		PreFilters = { [ItemFilters.ItemFields.PreFilters.STACK_LIMIT] = 2 },
		Filters = {
			[1] = { TargetStat = ItemFilters.FilterFields.TargetStat.ARMOR_CLASS, CompareStrategy = ItemFilters.FilterFields.CompareStrategy.LOWER }
		}
	},
	["LOOT_Gold_A_1c3c9c74-34a1-4685-989e-410dc080be6f"] = {
		Filters = {
			[1] = {
				TargetStat = ItemFilters.FilterFields.TargetStat.STACK_AMOUNT,
				CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER
			}
		}
	}
}

all_defaults.Tags = {
	["HEALING_POTION"] = {
		PreFilters = { [ItemFilters.ItemFields.PreFilters.STACK_LIMIT] = 2 },
		Filters = {
			[1] = { TargetStat = ItemFilters.FilterFields.TargetStat.HEALTH_PERCENTAGE, CompareStrategy = ItemFilters.FilterFields.CompareStrategy.LOWER, },
			[2] = {
				TargetStat = ItemFilters.FilterFields.TargetStat.STACK_AMOUNT,
				CompareStrategy = ItemFilters.FilterFields.CompareStrategy.LOWER,
				CalculateStackUsing = {
					["TAGS"] = { "HEALING_POTION" }
				},
			}
		},
	},
	["LOCKPICKS"] = {
		Filters = {
			[1] = { TargetStat = ItemFilters.FilterFields.TargetStat.SKILL_TYPE, TargetSubStat = "SleightOfHand", CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER, },
			[2] = {
				TargetStat = ItemFilters.FilterFields.TargetStat.STACK_AMOUNT,
				CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER
			}
		},
	},
	["TOOL"] = {
		Filters = {
			[1] = { TargetStat = ItemFilters.FilterFields.TargetStat.SKILL_TYPE, TargetSubStat = "SleightOfHand", CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER, },
			[2] = {
				TargetStat = ItemFilters.FilterFields.TargetStat.STACK_AMOUNT,
				CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER,
				CalculateStackUsing = {
					["TAGS"] = { "TOOL" }
				}
			}
		},
	},
	["COATING"] = {
		Filters = {
			[1] = {
				TargetStat = ItemFilters.FilterFields.TargetStat.STACK_AMOUNT,
				CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER
			},
			[2] = {
				TargetStat = ItemFilters.FilterFields.TargetStat.STACK_AMOUNT,
				CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER,
				CalculateStackUsing = {
					["TAGS"] = { "COATING" }
				},
			},
			[3] = { TargetStat = ItemFilters.FilterFields.TargetStat.ABILITY_STAT, TargetSubStat = "Dexterity", CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER }
		}
	},
	["ARROW"] = {
		Filters = {
			[1] = {
				TargetStat = ItemFilters.FilterFields.TargetStat.STACK_AMOUNT,
				CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER
			},
			[2] = {
				TargetStat = ItemFilters.FilterFields.TargetStat.STACK_AMOUNT,
				CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER,
				CalculateStackUsing = {
					["TAGS"] = { "ARROW" }
				},
			},
			[3] = { TargetStat = ItemFilters.FilterFields.TargetStat.ABILITY_STAT, TargetSubStat = "Dexterity", CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER }
		}
	},
	["GRENADE"] = {
		Filters = {
			[1] = {
				TargetStat = ItemFilters.FilterFields.TargetStat.STACK_AMOUNT,
				CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER
			},
			[2] = {
				TargetStat = ItemFilters.FilterFields.TargetStat.STACK_AMOUNT,
				CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER,
				CalculateStackUsing = {
					["TAGS"] = { "GRENADE" }
				},
			},
			[3] = { TargetStat = ItemFilters.FilterFields.TargetStat.ABILITY_STAT, TargetSubStat = "Strength", CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER }
		}
	},
	["SCROLL"] = {
		Filters = {
			[1] = {
				TargetStat = ItemFilters.FilterFields.TargetStat.STACK_AMOUNT,
				CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER,
			},
			[2] = {
				TargetStat = ItemFilters.FilterFields.TargetStat.STACK_AMOUNT,
				CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER,
				CalculateStackUsing = {
					["TAGS"] = { "SCROLL" }
				},
			},
			[3] = { Target = "originalTarget" },
		}
	},
	["CONSUMABLE"] = {
		Filters = {
			[99] = {
				TargetStat = ItemFilters.FilterFields.TargetStat.STACK_AMOUNT,
				CompareStrategy = ItemFilters.FilterFields.CompareStrategy.HIGHER
			}
		},
	},
	["CAMPSUPPLIES"] = {
		Filters = {
			[1] = { Target = "camp" }
		}
	}
}

all_defaults.RootPartial = {
	["BOOK"] = {
		Filters = {
			[1] = { Target = "camp" }
		}
	},
	["LOOT_MF_Rune_Tablet"] = {
		Filters = {
			[1] = { Target = "camp" }
		}
	}
}

Preset_AllDefaults = {}
Preset_AllDefaults.Name = "All-Defaults"
Preset_AllDefaults.ItemFilterMaps = TableUtils:MakeImmutableTableCopy(all_defaults)
all_defaults = nil
