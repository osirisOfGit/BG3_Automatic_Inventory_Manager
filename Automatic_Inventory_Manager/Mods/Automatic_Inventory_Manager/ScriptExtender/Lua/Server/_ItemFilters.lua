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
	BY_SKILL_TYPE = "BY_SKILL_TYPE",
}

--- @enum ItemKeys
ItemFilters.ItemKeys = {
	WILDCARD = "ALL"
}

--- @class TargetFilter
--- @field Target CHARACTER

--- @class WeightedFilter
--- @field CompareStategy CompareStrategy|nil
--- @field TargetStat TargetStat
--- @field TargetSubStat SkillId|nil

--- @alias Filters table<number, WeightedFilter|TargetFilter>

--- @class ItemFilter
--- @field Mode SelectionModes
--- @field Filters Filters
--- @field Modifiers table<FilterModifiers, any>|nil

local filterFields = ItemFilters.FilterFields
local itemFields = ItemFilters.ItemFields

--- @alias ItemFilterMap table<string, ItemFilter>

--- @class ItemMap
--- @field Weapons ItemFilterMap
--- @field Equipment ItemFilterMap
--- @field Tags ItemFilterMap
ItemFilters.ItemMaps = {}

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
		}
	}
}

ItemFilters.ItemMaps.Tags = {
	["HEALING_POTION"] = {
		Mode = itemFields.SelectionModes.WEIGHT_BY,
		Modifier = { [itemFields.FilterModifiers.STACK_LIMIT] = 2 },
		Filters = {
			[1] = { TargetStat = filterFields.TargetStat.HEALTH_PERCENTAGE, CompareStategy = filterFields.CompareStategy.LOWER, },
			[2] = { TargetStat = filterFields.TargetStat.STACK_AMOUNT, CompareStategy = filterFields.CompareStategy.LOWER }
		},
	},
	["LOCKPICKS"] = {
		Mode = itemFields.SelectionModes.WEIGHT_BY,
		Filters = {
			[1] = { TargetStat = filterFields.TargetStat.BY_SKILL_TYPE, TargetSubStat = "SleightOfHand", CompareStategy = filterFields.CompareStategy.HIGHER, },
			[2] = { TargetStat = filterFields.TargetStat.STACK_AMOUNT, CompareStategy = filterFields.CompareStategy.HIGHER }
		},
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

--- Queries all ItemFilters.ItemMaps related to Equipment and returns all found filters, including wildcards.
--- The Equipment Map is queried last
---@param item GUIDSTRING
---@return ItemFilter ...
function ItemFilters:GetFiltersByEquipmentType(item)
	local filters = {}

	if Osi.IsWeapon(item) == 1 then
		GetFiltersFromMap(ItemFilters.ItemMaps.Weapons, item, filters)
	end

	local equipTypeUUID = Ext.Entity.Get(item).ServerItem.Item.OriginalTemplate.EquipmentTypeID
	GetFiltersFromMap(ItemFilters.ItemMaps.Equipment, Ext.StaticData.Get(equipTypeUUID, "EquipmentType")["Name"], filters)

	return table.unpack(filters)
end

--- @param item GUIDSTRING
--- @return ItemFilter ... List of filters that were identified by the tags
function ItemFilters:GetFilterByTag(item)
	local filters = {}
	for _, tagUUID in pairs(Ext.Entity.Get(item).Tag.Tags) do
		local tagFilter = ItemFilters.ItemMaps.Tags[Ext.StaticData.Get(tagUUID, "Tag")["Name"]]
		if tagFilter then
			table.insert(filters, tagFilter)
		end
	end

	return table.unpack(filters)
end
