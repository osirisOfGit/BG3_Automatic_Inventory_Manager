ItemFilters = {}

ItemFilters.ItemFields = {}

--- @enum SelectionModes
ItemFilters.ItemFields.SelectionModes = {
	TARGET = 'TARGET',
	WEIGHT_BY = 'WEIGHT_BY'
}

--- @enum FilterModifiers
ItemFilters.ItemFields.FilterModifiers = {
	STACK_LIMIT = "STACK_LIMIT",
}

ItemFilters.FilterFields = {}
--- @enum CompareStrategy Determines which value to pick when comparing against other party member values.
ItemFilters.FilterFields.CompareStategy = {
	LOWER = "LOWER",
	HIGHER = "HIGHER"
}

--- @enum TargetStat
ItemFilters.FilterFields.TargetStat = {
	HEALTH_PERCENTAGE = "HEALTH_PERCENTAGE",
	STACK_AMOUNT = "STACK_AMOUNT",
	PROFICIENCY = "PROFICIENCY",
	WEAPON_SCORE = "WEAPON_SCORE",
	WEAPON_ABILITY = "WEAPON_ABILITY",
	HAS_TYPE_EQUIPPED = "HAS_TYPE_EQUIPPED",
	SKILL_TYPE = "SKILL_TYPE",
	ABILITY_STAT = "ABILITY_STAT",
	ARMOR_CLASS = "ARMOR_CLASS"
}

--- @enum ItemKeys
ItemFilters.ItemKeys = {
	WILDCARD = "ALL"
}

--- @class TargetFilter
--- @field Target string

--- @class WeightedFilter
--- @field CompareStategy CompareStrategy|nil
--- @field TargetStat TargetStat
--- @field TargetSubStat SkillId|AbilityId|nil

--- @alias Filters table<number, WeightedFilter|TargetFilter>

---Compare two Filters tables
---@param first WeightedFilter|TargetFilter
---@param second WeightedFilter|TargetFilter
---@return boolean true if the tables are equal
function ItemFilters:CompareFilter(first, second)
	if first.Target == second.Target
		and first.TargetStat == second.TargetStat
		and first.TargetSubStat == second.TargetSubStat
		and first.CompareStategy == second.CompareStategy then
		return true
	end

	return false
end

--- @class ItemFilter
--- @field Mode SelectionModes
--- @field Filters Filters
--- @field Modifiers table<FilterModifiers, any>|nil

--- @alias ItemFilterMap table<string, ItemFilter>

--- @class ItemMap
--- @field Weapons ItemFilterMap
--- @field Equipment ItemFilterMap
--- @field Tags ItemFilterMap
ItemFilters.ItemMaps = {}

local itemFields = ItemFilters.ItemFields
local filterFields = ItemFilters.FilterFields

ItemFilters.FilterFields.Shortcuts = {}
ItemFilters.FilterFields.Shortcuts.ByLargerStack = {
	TargetStat = filterFields.TargetStat.STACK_AMOUNT,
	CompareStategy = filterFields.CompareStategy.HIGHER
}

ItemFilters.ItemMaps.Weapons = {
	[ItemFilters.ItemKeys.WILDCARD] = {
		Mode = itemFields.SelectionModes.WEIGHT_BY,
		Filters = {
			[1] = { TargetStat = filterFields.TargetStat.HAS_TYPE_EQUIPPED },
			[2] = { TargetStat = filterFields.TargetStat.WEAPON_ABILITY, CompareStategy = filterFields.CompareStategy.HIGHER },
			[3] = { TargetStat = filterFields.TargetStat.WEAPON_SCORE, CompareStategy = filterFields.CompareStategy.HIGHER },
		}
	}
}

ItemFilters.ItemMaps.Equipment = {
	[ItemFilters.ItemKeys.WILDCARD] = {
		Mode = itemFields.SelectionModes.WEIGHT_BY,
		Filters = {
			[1] = { TargetStat = filterFields.TargetStat.PROFICIENCY },
			[2] = filterFields.Shortcuts.ByLargerStack
		}
	}
}

ItemFilters.ItemMaps.Roots = {
	-- not a typo :D
	["ALCH_Soultion_Elixir_Barkskin_cc1a8802-675a-426b-a791-ec1d5a5b6328"] = {
		Mode = itemFields.SelectionModes.WEIGHT_BY,
		Modifiers = { [itemFields.FilterModifiers.STACK_LIMIT] = 1 },
		Filters = {
			[1] = { TargetStat = filterFields.TargetStat.ARMOR_CLASS, CompareStategy = filterFields.CompareStategy.LOWER }
		}
	},
	["LOOT_Gold_A_1c3c9c74-34a1-4685-989e-410dc080be6f"] = {
		Mode = itemFields.SelectionModes.WEIGHT_BY,
		Filters = {
			[1] = filterFields.Shortcuts.ByLargerStack
		}
	}
}

ItemFilters.ItemMaps.Tags = {
	["HEALING_POTION"] = {
		Mode = itemFields.SelectionModes.WEIGHT_BY,
		Modifiers = { [itemFields.FilterModifiers.STACK_LIMIT] = 2 },
		Filters = {
			[1] = { TargetStat = filterFields.TargetStat.HEALTH_PERCENTAGE, CompareStategy = filterFields.CompareStategy.LOWER, },
			[2] = { TargetStat = filterFields.TargetStat.STACK_AMOUNT, CompareStategy = filterFields.CompareStategy.LOWER }
		},
	},
	["LOCKPICKS"] = {
		Mode = itemFields.SelectionModes.WEIGHT_BY,
		Filters = {
			[1] = { TargetStat = filterFields.TargetStat.SKILL_TYPE, TargetSubStat = "SleightOfHand", CompareStategy = filterFields.CompareStategy.HIGHER, },
			[2] = filterFields.Shortcuts.ByLargerStack
		},
	},
	["TOOL"] = {
		Mode = itemFields.SelectionModes.WEIGHT_BY,
		Filters = {
			[1] = { TargetStat = filterFields.TargetStat.SKILL_TYPE, TargetSubStat = "SleightOfHand", CompareStategy = filterFields.CompareStategy.HIGHER, },
			[2] = filterFields.Shortcuts.ByLargerStack
		},
	},
	["COATING"] = {
		Mode = itemFields.SelectionModes.WEIGHT_BY,
		Filters = {
			[1] = filterFields.Shortcuts.ByLargerStack,
			[2] = { TargetStat = filterFields.TargetStat.ABILITY_STAT, TargetSubStat = "Dexterity", CompareStategy = filterFields.CompareStategy.HIGHER }
		}
	},
	["CAMPSUPPLIES"] = {
		Mode = itemFields.SelectionModes.TARGET,
		Filters = {
			[1] = { Target = "camp" }
		}
	}
}

---@param itemMap ItemMap
---@param key string
---@param filtersTable ItemFilter[]
local function GetFiltersFromMap(itemMap, key, filtersTable)
	if itemMap[key] then
		table.insert(filtersTable, itemMap[key])
	end

	if itemMap[ItemFilters.ItemKeys.WILDCARD] then
		table.insert(filtersTable, itemMap[ItemFilters.ItemKeys.WILDCARD])
	end
end

---
---@param root GUIDSTRING root template UUID of the item
---@return ItemFilter[]
function ItemFilters:GetFiltersByRoot(root)
	local filters = {}

	GetFiltersFromMap(ItemFilters.ItemMaps.Roots, root, filters)

	return filters
end

--- Queries all ItemFilters.ItemMaps related to Equipment and returns all found filters, including wildcards.
--- The Equipment Map is queried last
---@param item GUIDSTRING
---@return ItemFilter[]
function ItemFilters:GetFiltersByEquipmentType(item)
	local filters = {}

	if Osi.IsWeapon(item) == 1 then
		GetFiltersFromMap(ItemFilters.ItemMaps.Weapons, item, filters)
	end

	local equipTypeUUID = Ext.Entity.Get(item).ServerItem.Item.OriginalTemplate.EquipmentTypeID
	local equipType = Ext.StaticData.Get(equipTypeUUID, "EquipmentType")
	if equipType then
		GetFiltersFromMap(ItemFilters.ItemMaps.Equipment, equipType["Name"], filters)
	end

	return filters
end

--- @param item GUIDSTRING
--- @return ItemFilter[] List of filters that were identified by the tags
function ItemFilters:GetFilterByTag(item)
	local filters = {}
	for _, tagUUID in pairs(Ext.Entity.Get(item).Tag.Tags) do
		local tagTable = Ext.StaticData.Get(tagUUID, "Tag")
		if tagTable then
			local tagFilter = ItemFilters.ItemMaps.Tags[tagTable["Name"]]
			if tagFilter then
				table.insert(filters, tagFilter)
			end
		end
	end

	return filters
end
