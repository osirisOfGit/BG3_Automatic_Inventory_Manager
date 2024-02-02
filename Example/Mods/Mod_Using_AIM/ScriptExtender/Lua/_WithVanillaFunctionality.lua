local newItemFilterMap = {
	["Tags2"] = {
		-- case sensitive
		["HEALING_POTION"] = {
			-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/ItemFilters.html#ItemFilters.ItemFields.PreFilters
			PreFilters = { [AIM_SHORTCUT.ItemFilters.ItemFields.PreFilters.STACK_LIMIT] = 2 },
			Filters = {
				-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/ItemFilters.html#ItemFilters.FilterFields.TargetStat
				[1] = { TargetStat = AIM_SHORTCUT.ItemFilters.FilterFields.TargetStat.HEALTH_PERCENTAGE, CompareStategy = AIM_SHORTCUT.ItemFilters.FilterFields.CompareStategy.LOWER, },
				[2] = { TargetStat = AIM_SHORTCUT.ItemFilters.FilterFields.TargetStat.STACK_AMOUNT, CompareStategy = AIM_SHORTCUT.ItemFilters.FilterFields.CompareStategy.LOWER }
			},
		},
	},
	-- The Tags itemFilterMap is already known by AIM, so it has a FilterLookupFunction associated to it already
	["Tags"] = {
		-- case sensitive
		["HEALING_POTION"] = {
			-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/ItemFilters.html#ItemFilters.ItemFields.PreFilters
			PreFilters = { [AIM_SHORTCUT.ItemFilters.ItemFields.PreFilters.STACK_LIMIT] = 2 },
			Filters = {
				-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/ItemFilters.html#ItemFilters.FilterFields.TargetStat
				[1] = { TargetStat = AIM_SHORTCUT.ItemFilters.FilterFields.TargetStat.HEALTH_PERCENTAGE, CompareStategy = AIM_SHORTCUT.ItemFilters.FilterFields.CompareStategy.LOWER, },
				[2] = { TargetStat = AIM_SHORTCUT.ItemFilters.FilterFields.TargetStat.STACK_AMOUNT, CompareStategy = AIM_SHORTCUT.ItemFilters.FilterFields.CompareStategy.LOWER }
			},
		},
	}
}

-- Mod name is prepended to the presetName for us
-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/ItemFilters.html#RegisterItemFilterMapPreset
AIM_SHORTCUT.ItemFilters:RegisterItemFilterMapPreset(SAMPLE_MOD_UUID, "VanillaFilters", newItemFilterMap)
