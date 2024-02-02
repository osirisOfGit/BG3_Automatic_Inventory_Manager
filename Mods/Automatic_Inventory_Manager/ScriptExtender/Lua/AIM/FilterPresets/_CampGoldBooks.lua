local campgoldbooks = {}

campgoldbooks.Roots = {
	["LOOT_Gold_A_1c3c9c74-34a1-4685-989e-410dc080be6f"] = {
		Filters = {
			[1] = {
				TargetStat = ItemFilters.FilterFields.TargetStat.STACK_AMOUNT,
				CompareStategy = ItemFilters.FilterFields.CompareStategy.HIGHER
			}
		}
	}
}

campgoldbooks.Tags = {
	["CAMPSUPPLIES"] = {
		Filters = {
			[1] = { Target = "camp" }
		}
	}
}

campgoldbooks.RootPartial = {
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

Preset_CampGoldBooks = {}
Preset_CampGoldBooks.Name = "Camp-Gold-Books"
Preset_CampGoldBooks.ItemFilterMaps = TableUtils:MakeImmutableTableCopy(campgoldbooks)
campgoldbooks = nil
