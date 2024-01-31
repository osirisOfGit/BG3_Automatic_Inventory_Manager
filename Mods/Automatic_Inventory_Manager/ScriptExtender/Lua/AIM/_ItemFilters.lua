--- @module "ItemFilters"

ItemFilters = {}

ItemFilters.ItemFields = {}

--- Filters that pre-filter eligible party members before a stack of items, or an item in the stack, is processed.
ItemFilters.ItemFields.PreFilters = {
	STACK_LIMIT = "STACK_LIMIT", -- Filters out any party members that have > than the specified limit
	EXCLUDE_PARTY_MEMBERS = "EXCLUDE_PARTY_MEMBERS", -- Array of party members to exclude from processing
	ENCUMBRANCE = "ENCUMBRANCE", -- Internal only
}

ItemFilters.FilterFields = {}

--- Used by Compare Filters to determine whether a higher or lower value is considered the "winner"
ItemFilters.FilterFields.CompareStategy = {
	LOWER = "LOWER",
	HIGHER = "HIGHER"
}

--- Used by Compare Filters to identify the criteria that party members are filtered on
ItemFilters.FilterFields.TargetStat = {
	HEALTH_PERCENTAGE = "HEALTH_PERCENTAGE",
	STACK_AMOUNT = "STACK_AMOUNT",  -- the amount of that item's template in the party's inventory
	PROFICIENCY = "PROFICIENCY",    -- as dictated by the item, i.e. SleightOfHand for lockpicks
	WEAPON_SCORE = "WEAPON_SCORE",  --  using Osi.WeaponScore, does some math, i have no idea.
	WEAPON_ABILITY = "WEAPON_ABILITY", -- as dictated by the item, i.e. Greatswords use Strength
	HAS_TYPE_EQUIPPED = "HAS_TYPE_EQUIPPED",
	SKILL_TYPE = "SKILL_TYPE",      -- requires TargetSubStat to be specified
	ABILITY_STAT = "ABILITY_STAT",  -- requires TargetSubStat to be specified
	ARMOR_CLASS = "ARMOR_CLASS"
}

--- Convenience table for keys that are common across ItemMaps
ItemFilters.ItemKeys = {
	WILDCARD = "ALL"
}

---
---@param targetItemFilter the existing ItemFilter to merge into
---@param newItemFilters the ItemFilters to add to the table
---@tparam boolean prioritizeNewFilters if merging in a filter for an existing ItemFilter, and an existing filter shares the same priority, the provided filter will be given higher priority
local function MergeItemFiltersIntoTarget(targetItemFilter, newItemFilters, prioritizeNewFilters)
	for _, newItemFilter in pairs(newItemFilters) do
		for itemFilterProperty, propertyValue in pairs(newItemFilter) do
			if string.lower(itemFilterProperty) == "filters" then
				-- Consolidate filters, ignoring duplicates
				for newFilterPriority, newFilter in pairs(propertyValue) do
					local foundIdenticalFilter = false
					for _, existingFilter in pairs(targetItemFilter.Filters) do
						if TableUtils:CompareLists(newFilter, existingFilter) then
							foundIdenticalFilter = true
							break
						end
					end
					if not foundIdenticalFilter then
						newFilterPriority = tonumber(newFilterPriority)
						if targetItemFilter.Filters[newFilterPriority] or targetItemFilter.Filters[tostring(newFilterPriority)] then
							-- Find the first empty index after the requested priority -
							-- if we're prioritizing new filters, we'll shift all consecutive filters down one spot
							-- otherwise, we'll insert the new filter into that available index
							local filterIndex = newFilterPriority
							while targetItemFilter.Filters[filterIndex] or targetItemFilter.Filters[tostring(filterIndex)] do
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
			elseif string.lower(itemFilterProperty) == "prefilters" then
				for modifier, newModifier in pairs(propertyValue) do
					if not targetItemFilter.PreFilters[modifier] then
						targetItemFilter.PreFilters[modifier] = newModifier
					end
				end
			else
				targetItemFilter[itemFilterProperty] = propertyValue
			end
		end
	end
end

local itemMaps = {}

--- For each itemFilterMap, will just add to the superset if the map is not already known, otherwise will do a recursive merge,
--- adding any Filters that are not already added, incrementing the priority to the next highest number if taken.
---@param itemFilterMaps table of mapName:ItemFilters[] to add
---@param forceOverride if the itemFilterMap is already known, will just completely overwrite with the provided map instead of merging
---@param prioritizeNewFilters if merging in a filter for an existing ItemFilter, and an existing filter shares the same priority, the provided filter will be given higher priority
---@param updateItemMapClone if we should update ItemFilters.itemMap after merging - performance flag in case there are multiple, independent loads that need to happen
function ItemFilters:AddItemFilterMaps(itemFilterMaps, forceOverride, prioritizeNewFilters, updateItemMapClone)
	for mapName, itemFilterMap in pairs(itemFilterMaps) do
		if not itemMaps[mapName] or forceOverride == true then
			itemMaps[mapName] = itemFilterMap
		else
			local existingItemFilterMap = itemMaps[mapName]
			for itemKey, itemFilter in pairs(itemFilterMap) do
				if not existingItemFilterMap[itemKey] then
					existingItemFilterMap[itemKey] = itemFilter
				else
					MergeItemFiltersIntoTarget(existingItemFilterMap[itemKey], { itemFilter }, prioritizeNewFilters)
				end
			end
		end
		if Logger:IsLogLevelEnabled(Logger.PrintTypes.TRACE) then
			Logger:BasicTrace(string.format("Finished merging itemMap %s, new map is: %s", mapName,
				Ext.Json.Stringify(itemMaps[mapName])))
		end
	end

	if updateItemMapClone == true then ItemFilters:UpdateItemMapsClone() end
end

--- immutable clone of the itemMaps - can be forceably synced using UpdateItemMapsClone, but we'll do it on each update we know about
ItemFilters.itemMaps = TableUtils:MakeImmutableTableCopy(itemMaps)

--- Updates ItemFilters.itemMaps
function ItemFilters:UpdateItemMapsClone()
	ItemFilters.itemMaps = TableUtils:MakeImmutableTableCopy(itemMaps)

	-- Update the TargetStat enum with new fields for use by FilterProcessors
	for _, itemMap in pairs(ItemFilters.itemMaps) do
		for _, itemFilter in pairs(itemMap) do
			for _, filter in pairs(itemFilter.Filters) do
				if filter.TargetStat and not ItemFilters.FilterFields.TargetStat[filter.TargetStat] then
					ItemFilters.FilterFields.TargetStat[filter.TargetStat] = filter.TargetStat
				end
			end
		end
	end
end

local function GetFiltersFromMap(itemMap, key, filtersTable)
	if itemMap then
		if itemMap[key] then
			table.insert(filtersTable, itemMap[key])
		end

		if itemMap[ItemFilters.ItemKeys.WILDCARD] then
			table.insert(filtersTable, itemMap[ItemFilters.ItemKeys.WILDCARD])
		end
	end
end

local function GetFiltersByRoot(itemMaps, root, _, _)
	local filters = {}

	GetFiltersFromMap(itemMaps.Roots, root, filters)

	if itemMaps["RootPartial"] then
		for key, filter in pairs(itemMaps.RootPartial) do
			if string.find(root, key) then
				table.insert(filters, filter)
			end
		end
	end

	return filters
end

local function GetFiltersByEquipmentType(itemMaps, _, item, _)
	local filters = {}

	if Osi.IsWeapon(item) == 1 then
		GetFiltersFromMap(itemMaps.Weapons, item, filters)
	end

	if itemMaps["Equipment"] and Osi.IsEquipable(item) == 1 then
		local equipTypeUUID = Ext.Entity.Get(item).ServerItem.OriginalTemplate.EquipmentTypeID
		local equipType = Ext.StaticData.Get(equipTypeUUID, "EquipmentType")
		if equipType then
			GetFiltersFromMap(itemMaps.Equipment, equipType["Name"], filters)
		end
	end

	return filters
end

local function GetFilterByTag(itemMaps, _, item, _)
	local filters = {}
	if itemMaps["Tags"] then
		for _, tagUUID in pairs(Ext.Entity.Get(item).Tag.Tags) do
			local tagTable = Ext.StaticData.Get(tagUUID, "Tag")
			if tagTable then
				local tagFilter = itemMaps.Tags[tagTable["Name"]]
				if tagFilter then
					table.insert(filters, tagFilter)
				end
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
---
--- <br/>1. table(string, table(string, ItemFilter)) - immutable copy of all the itemMaps to perform lookup against
--- <br/>2. GUIDSTRING - the root template of the item being sorted
--- <br/>3. GUIDSTRING - the item being sorted
--- <br/>4. GUIDSTRING - the inventoryHolder
---
--- and return a list of ItemFilters
---@tparam function[] lookupFuncs
function ItemFilters:AddItemFilterLookupFunction(lookupFuncs)
	for _, lookupFunc in pairs(lookupFuncs) do
		table.insert(itemFilterLookups, lookupFunc)
	end
end

--- Finds all ItemFilters for the given item
---@tparam string item
---@tparam string root
---@tparam string inventoryHolder
---@return A consolidated ItemFilter containing all the filters, prefilters, and custom fields found for the given item, with normalized priorities
function ItemFilters:SearchForItemFilters(item, root, inventoryHolder)
	local consolidatedItemFilter = { Filters = {}, PreFilters = {} }

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
