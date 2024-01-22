ItemFilters = {}

ItemFilters.ItemFields = {}

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

--- @class Filter

--- @class TargetFilter: Filter
--- @field Target string

--- @class WeightedFilter: Filter
--- @field CompareStategy CompareStrategy|nil
--- @field TargetStat TargetStat
--- @field TargetSubStat SkillId|AbilityId|nil

--- @alias Filters table<number, Filter>

---Compare two Filters tables
---@param first Filter
---@param second Filter
---@return boolean true if the tables are equal
function ItemFilters:CompareFilter(first, second)
	local isEqual = false
	for property, value in pairs(first) do
		isEqual = value == second[property]
	end

	for property, value in pairs(second) do
		isEqual = value == first[property]
	end

	return isEqual
end

--- @class ItemFilter
--- @field Filters Filters
--- @field Modifiers table<FilterModifiers, any>|nil

--- @alias ItemFilterMap table<string, ItemFilter>
--- @alias ItemMap table<string, ItemFilterMap>

local itemFields = ItemFilters.ItemFields
local filterFields = ItemFilters.FilterFields

local shortcuts = {}
--- @type WeightedFilter
shortcuts.ByLargerStack = {
	TargetStat = filterFields.TargetStat.STACK_AMOUNT,
	CompareStategy = filterFields.CompareStategy.HIGHER
}

--- @type ItemMap
local itemMaps = {}
itemMaps.Weapons = {
	[ItemFilters.ItemKeys.WILDCARD] = {
		Filters = {
			[99] = { TargetStat = filterFields.TargetStat.HAS_TYPE_EQUIPPED },
			[100] = { TargetStat = filterFields.TargetStat.WEAPON_ABILITY, CompareStategy = filterFields.CompareStategy.HIGHER },
			[101] = { TargetStat = filterFields.TargetStat.WEAPON_SCORE, CompareStategy = filterFields.CompareStategy.HIGHER },
		}
	}
}

itemMaps.Equipment = {
	[ItemFilters.ItemKeys.WILDCARD] = {
		Filters = {
			[99] = { TargetStat = filterFields.TargetStat.PROFICIENCY },
			[100] = shortcuts.ByLargerStack
		}
	}
}

itemMaps.Roots = {
	-- not a typo :D
	["ALCH_Soultion_Elixir_Barkskin_cc1a8802-675a-426b-a791-ec1d5a5b6328"] = {
		Modifiers = { [itemFields.FilterModifiers.STACK_LIMIT] = 1 },
		Filters = {
			[1] = { TargetStat = filterFields.TargetStat.ARMOR_CLASS, CompareStategy = filterFields.CompareStategy.LOWER }
		}
	},
	["LOOT_Gold_A_1c3c9c74-34a1-4685-989e-410dc080be6f"] = {
		Filters = {
			[1] = shortcuts.ByLargerStack
		}
	}
}

itemMaps.Tags = {
	["HEALING_POTION"] = {
		Modifiers = { [itemFields.FilterModifiers.STACK_LIMIT] = 2 },
		Filters = {
			[1] = { TargetStat = filterFields.TargetStat.HEALTH_PERCENTAGE, CompareStategy = filterFields.CompareStategy.LOWER, },
			[2] = { TargetStat = filterFields.TargetStat.STACK_AMOUNT, CompareStategy = filterFields.CompareStategy.LOWER }
		},
	},
	["LOCKPICKS"] = {
		Filters = {
			[1] = { TargetStat = filterFields.TargetStat.SKILL_TYPE, TargetSubStat = "SleightOfHand", CompareStategy = filterFields.CompareStategy.HIGHER, },
			[2] = shortcuts.ByLargerStack
		},
	},
	["TOOL"] = {
		Filters = {
			[1] = { TargetStat = filterFields.TargetStat.SKILL_TYPE, TargetSubStat = "SleightOfHand", CompareStategy = filterFields.CompareStategy.HIGHER, },
			[2] = shortcuts.ByLargerStack
		},
	},
	["COATING"] = {
		Filters = {
			[1] = shortcuts.ByLargerStack,
			[2] = { TargetStat = filterFields.TargetStat.ABILITY_STAT, TargetSubStat = "Dexterity", CompareStategy = filterFields.CompareStategy.HIGHER }
		}
	},
	["ARROW"] = {
		Filters = {
			[1] = shortcuts.ByLargerStack,
			[2] = { TargetStat = filterFields.TargetStat.ABILITY_STAT, TargetSubStat = "Dexterity", CompareStategy = filterFields.CompareStategy.HIGHER }
		}
	},
	["GRENADE"] = {
		Filters = {
			[1] = shortcuts.ByLargerStack,
			[2] = { TargetStat = filterFields.TargetStat.ABILITY_STAT, TargetSubStat = "Strength", CompareStategy = filterFields.CompareStategy.HIGHER }
		}
	},
	["SCROLL"] = {
		Filters = {
			[1] = shortcuts.ByLargerStack,
			[2] = { Target = "originalTarget" },
		}
	},
	["CONSUMABLE"] = {
		Filters = {
			[99] = shortcuts.ByLargerStack
		}
	},
	["CAMPSUPPLIES"] = {
		Filters = {
			[1] = { Target = "camp" }
		}
	}
}

--- @type ItemFilterMap
itemMaps.RootPartial = {
	["BOOK"] = {
		Filters = {
			[1] = { Target = "camp" }
		}
	}
}

---
---@param targetItemFilter ItemFilter the existing ItemFilter to merge into
---@param newItemFilters ItemFilter[] the filters to add to the table
---@param prioritizeNewFilters boolean if merging in a filter for an existing ItemFilter, and an existing filter shares the same priority, the provided filter will be given higher priority
local function MergeItemFiltersIntoTarget(targetItemFilter, newItemFilters, prioritizeNewFilters)
	for _, newItemFilter in pairs(newItemFilters) do
		for itemFilterProperty, propertyValue in pairs(newItemFilter) do
			if string.lower(itemFilterProperty) == "filters" then
				--- @cast propertyValue Filters
				-- Consolidate filters, ignoring duplicates
				for newFilterPriority, newFilter in pairs(propertyValue) do
					newFilterPriority = tonumber(newFilterPriority)
					---@cast newFilterPriority number

					local foundIdenticalFilter = false
					for _, existingFilter in pairs(targetItemFilter.Filters) do
						if ItemFilters:CompareFilter(newFilter, existingFilter) then
							foundIdenticalFilter = true
							break
						end
					end
					if not foundIdenticalFilter then
						if targetItemFilter.Filters[newFilterPriority] then
							-- Find the first empty index after the requested priority -
							-- if we're prioritizing new filters, we'll shift all consecutive filters down one spot
							-- otherwise, we'll insert the new filter into that available index
							local filterIndex = newFilterPriority
							while targetItemFilter.Filters[filterIndex] do
								filterIndex = filterIndex + 1
							end
							if prioritizeNewFilters ~= true then
								targetItemFilter.Filters[filterIndex] = newFilter
							else
								table.move(targetItemFilter.Filters, newFilterPriority, filterIndex - 1,
									newFilterPriority + 1)
								targetItemFilter.Filters[newFilterPriority] = newFilter
							end
						else
							targetItemFilter.Filters[newFilterPriority] = newFilter
						end
					end
				end
			elseif string.lower(itemFilterProperty) == "modifiers" then
				--- @cast propertyValue table<FilterModifiers, any>
				for modifier, newModifier in pairs(propertyValue) do
					if not targetItemFilter.Modifiers[modifier] then
						targetItemFilter.Modifiers[modifier] = newModifier
					end
				end
			else
				targetItemFilter[itemFilterProperty] = propertyValue
			end
		end
	end
end

--- For each itemFilterMap, will just add to the superset if the map is not already known, otherwise will do a recursive merge,
--- adding any Filters that are not already added, incrementing the priority to the next highest number if taken.
---@param itemFilterMaps table<string, ItemFilterMap>
---@param forceOverride boolean if the itemFilterMap is already known, will just completely overwrite with the provided map instead of merging
---@param prioritizeNewFilters boolean if merging in a filter for an existing ItemFilter, and an existing filter shares the same priority, the provided filter will be given higher priority
---@param updateItemMapClone boolean if we should update ItemFilters.itemMap after merging - performance flag in case there are multiple, independent loads that need to happen
function ItemFilters:AddItemFilterMaps(itemFilterMaps, forceOverride, prioritizeNewFilters, updateItemMapClone)
	for mapName, itemFilterMap in pairs(itemFilterMaps) do
		if not itemMaps[mapName] or forceOverride == true then
			itemMaps[mapName] = itemFilterMap
		else
			---@type ItemFilterMap
			local existingItemFilterMap = itemMaps[mapName]
			for itemKey, itemFilter in pairs(itemFilterMap) do
				if not existingItemFilterMap[itemKey] then
					existingItemFilterMap[itemKey] = itemFilter
				else
					MergeItemFiltersIntoTarget(existingItemFilterMap[itemKey], { itemFilter }, prioritizeNewFilters)
				end
			end
		end
	end

	if updateItemMapClone == true then ItemFilters:UpdateItemMapsClone() end
end

--- @type table<string, ItemMap> immutable clone of the itemMaps - can be foreably synced using UpdateItemMapsClone, but we'll do it on each update we know about
ItemFilters.itemMaps = Utils:MakeImmutableTableCopy(itemMaps)
function ItemFilters:UpdateItemMapsClone()
	ItemFilters.itemMaps = Utils:MakeImmutableTableCopy(itemMaps)

	for mapName, itemMap in pairs(ItemFilters.itemMaps) do
		for _, itemFilter in pairs(itemMap) do
			for _, filter in pairs(itemFilter.Filters) do
				if filter.TargetStat and not ItemFilters.FilterFields.TargetStat[filter.TargetStat] then
					ItemFilters.FilterFields.TargetStat[filter.TargetStat] = filter.TargetStat
				end
			end
		end
		Utils:SaveTableToFile(Config.FILTERS_DIR .. mapName .. ".json", itemMaps[mapName])
		PersistentVars.ItemFilters[mapName] = itemMap
	end
end

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
local function GetFiltersByRoot(itemMaps, root, _, _)
	local filters = {}

	GetFiltersFromMap(itemMaps.Roots, root, filters)

	for key, filter in pairs(itemMaps.RootPartial) do
		if string.find(root, key) then
			table.insert(filters, filter)
		end
	end

	return filters
end

--- Queries all itemMaps related to Equipment and returns all found filters, including wildcards.
--- The Equipment Map is queried last
---@param item GUIDSTRING
---@return ItemFilter[]
local function GetFiltersByEquipmentType(itemMaps, _, item, _)
	local filters = {}

	if Osi.IsWeapon(item) == 1 then
		GetFiltersFromMap(itemMaps.Weapons, item, filters)
	end

	if Osi.IsEquipable(item) == 1 then
		local equipTypeUUID = Ext.Entity.Get(item).ServerItem.OriginalTemplate.EquipmentTypeID
		local equipType = Ext.StaticData.Get(equipTypeUUID, "EquipmentType")
		if equipType then
			GetFiltersFromMap(itemMaps.Equipment, equipType["Name"], filters)
		end
	end

	return filters
end

--- @param item GUIDSTRING
--- @return ItemFilter[] List of filters that were identified by the tags
local function GetFilterByTag(itemMaps, _, item, _)
	local filters = {}
	for _, tagUUID in pairs(Ext.Entity.Get(item).Tag.Tags) do
		local tagTable = Ext.StaticData.Get(tagUUID, "Tag")
		if tagTable then
			local tagFilter = itemMaps.Tags[tagTable["Name"]]
			if tagFilter then
				table.insert(filters, tagFilter)
			end
		end
	end

	return filters
end

local itemFilterLookups = {
	GetFiltersByRoot,
	GetFilterByTag,
	GetFiltersByEquipmentType
}

--- Add custom function(s) to use to find ItemFilters for a given item - each function should accept:
--- 1. table<string, table<string, ItemFilter>> - immutable copy of all the itemMaps to perform lookup against
--- 2. GUIDSTRING - the root template of the item being sorted
--- 3. GUIDSTRING - the item being sorted
--- 4. GUIDSTRING - the inventoryHolder
---
--- and return a list of ItemFilters
---@param lookupFuncs function[]
function ItemFilters:AddItemFilterLookupFunction(lookupFuncs)
	for _, lookupFunc in pairs(lookupFuncs) do
		table.insert(itemFilterLookups, lookupFunc)
	end
end

--- Finds all Filters for the given item
---@param item GUIDSTRING
---@param root GUIDSTRING
---@return ItemFilter
function ItemFilters:SearchForItemFilters(item, root, inventoryHolder)
	--- @type ItemFilter
	local consolidatedItemFilter = { Filters = {}, Modifiers = {} }

	for _, lookupFunc in pairs(itemFilterLookups) do
		local success, errorMessage = pcall(function()
			MergeItemFiltersIntoTarget(consolidatedItemFilter,
				lookupFunc(ItemFilters.itemMaps, root, item, inventoryHolder),
				false)
		end
		)
		if not success then
			Logger:BasicError(string.format(
				"ItemFilters:SearchForItemFilters - Received error executing itemFilterLoop for item %s, root %s, inventoryHolder %s: [%s]",
				item,
				root,
				inventoryHolder,
				errorMessage))
		end
	end

	-- Since lua is addicted to sequential indexes, we have to normalize the indexes of itemFilters that were given arbitrarily large numbers
	-- to ensure we can iterate through every filter later
	local normalizedFilters = {}
	local numFilters = 0
	for _, _ in pairs(consolidatedItemFilter.Filters) do
		numFilters = numFilters + 1
	end
	for i = 1, numFilters do
		local nextLowestNumber
		for filterPriority, _ in pairs(consolidatedItemFilter.Filters) do
			if filterPriority == i then
				nextLowestNumber = i
				break
			else
				if not nextLowestNumber then
					nextLowestNumber = filterPriority
				else
					nextLowestNumber = filterPriority < nextLowestNumber and filterPriority or nextLowestNumber
				end
			end
		end
		normalizedFilters[i] = consolidatedItemFilter.Filters[nextLowestNumber]
		consolidatedItemFilter.Filters[nextLowestNumber] = nil
	end

	consolidatedItemFilter.Filters = normalizedFilters
	return consolidatedItemFilter
end
