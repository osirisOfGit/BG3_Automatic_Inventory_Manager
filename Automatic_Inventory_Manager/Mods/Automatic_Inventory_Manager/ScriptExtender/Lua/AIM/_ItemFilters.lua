--- @module "ItemFilters"

ItemFilters = {}

ItemFilters.ItemFields = {}

--- Filters that pre-filter eligible party members before a stack of items, or an item in the stack, is processed.
ItemFilters.ItemFields.PreFilters = {
	STACK_LIMIT = "STACK_LIMIT",                  -- Filters out any party members that have > than the specified limit
	EXCLUDE_PARTY_MEMBERS = "EXCLUDE_PARTY_MEMBERS", -- Array of party members to exclude from processing
	EXCLUDE_CLASSES = "EXCLUDE_CLASSES",          -- Array of (sub)classes to exclude from processing
	ENCUMBRANCE = "ENCUMBRANCE",                  -- Internal only
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

--- Convenience table for keys that are common across ItemFilterMaps
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

local itemFilterMaps = {}

--- Registers a new Preset with the provided ItemFilterMaps - files will be created, overwriting any existing contents, and the preset information will be added to the
--- PRESETS.FILTERS_PRESETS configuration property.
--- @tparam UUID modUUID that ScriptExtender has registered for your mod, for tracking purposes - <a href="https://github.com/Norbyte/bg3se/blob/main/Docs/API.md#ismodloadedmodguid">https://github.com/Norbyte/bg3se/blob/main/Docs/API.md#ismodloadedmodguid</a>
--- will throw an error if the mod identified by that UUID is not loaded
--- @tparam string presetName to save the itemFilterMaps under. Your mod name will be automatically prepended to this in {MOD_NAME}-{presetName} format.
--- @tparam table itemFilterMaps table of mapName:ItemFilters[] to add
--- @treturn boolean true if the operation succeeded
function ItemFilters:RegisterItemFilterMapPreset(modUUID, presetName, itemFilterMaps)
	local modName = ModUtils:GetModInfoFromUUID(modUUID).Name

	presetName = modName .. "-" .. presetName

	Config.AIM.PRESETS.FILTERS_PRESETS[presetName] = {}

	local mapCount = 0
	for mapName, itemFilters in pairs(itemFilterMaps) do
		local saveSuccess = FileUtils:SaveTableToFile(
			FileUtils:BuildRelativeJsonFileTargetPath(mapName, Config.AIM.PRESETS.PRESETS_DIR, presetName),
			itemFilters)
		if saveSuccess then
			table.insert(Config.AIM.PRESETS.FILTERS_PRESETS[presetName], mapName)
			mapCount = mapCount + 1
		else
			Logger:BasicError(string.format(
				"Was unable to save itemFilterMap %s while creating preset %s for mod %s - this map will be skipped! Check previous logs for errors",
				mapName,
				presetName,
				modName))
		end
	end

	Logger:BasicInfo(string.format("Mod %s successfully registered %d new itemFilterMaps under preset %s",
		modName,
		mapCount,
		presetName))

	if Config.IsInitialized then
		FileUtils:SaveTableToFile("config.json", Config.AIM)
	end

	return true
end

--- For each itemFilterMap, will just add to the superset if the map is not already known, otherwise will do a recursive merge,
--- adding any Filters that are not already added, incrementing the priority to the next highest number if taken.
---@param newItemFilterMaps table of mapName:ItemFilters[] to add
---@param forceOverride if the itemFilterMap is already known, will just completely overwrite with the provided map instead of merging
---@param prioritizeNewFilters if merging in a filter for an existing ItemFilter, and an existing filter shares the same priority, the provided filter will be given higher priority
---@param updateItemFilterMapClone if we should update ItemFilters.itemFilterMap after merging - performance flag in case there are multiple, independent loads that need to happen
local function AddItemFilterMaps(newItemFilterMaps, forceOverride, prioritizeNewFilters, updateItemFilterMapClone)
	for newMapName, newItemFilterMap in pairs(newItemFilterMaps) do
		if not itemFilterMaps[newMapName] or forceOverride == true then
			itemFilterMaps[newMapName] = newItemFilterMap
		else
			local existingItemFilterMap = itemFilterMaps[newMapName]
			for newItemKey, newItemFilter in pairs(newItemFilterMap) do
				if not existingItemFilterMap[newItemKey] then
					existingItemFilterMap[newItemKey] = newItemFilter
				else
					MergeItemFiltersIntoTarget(existingItemFilterMap[newItemKey], { newItemFilter }, prioritizeNewFilters)
				end
			end
		end
		if Logger:IsLogLevelEnabled(Logger.PrintTypes.TRACE) then
			Logger:BasicTrace(string.format("Finished merging itemFilterMap %s, new map is: %s",
				newMapName,
				Ext.Json.Stringify(itemFilterMaps[newMapName])))
		end
	end

	if updateItemFilterMapClone == true then ItemFilters:UpdateItemFilterMapsClone() end
end

--- Loads the active ItemFilterMap presets as identified by the PRESETS.ACTIVE_PRESETS configuration property
--- Throws an error if no tables were loaded.
--- @treturn boolean true if at least one requested table was succesfully loaded. Error otherwise.
function ItemFilters:LoadItemFilterPresets()
	local loadedTables = 0
	local loadedPresets = 0
	for presetName, presetTablesToLoad in pairs(Config.AIM.PRESETS.ACTIVE_PRESETS) do
		Logger:BasicInfo("Loading filter preset " .. presetName)
		if not Config.AIM.PRESETS.FILTERS_PRESETS[presetName] then
			Logger:BasicError(string.format(
				"Specified preset '%s' was not present in the FILTERS_PRESETS property - please specify a real preset (case sensitive). This will be skipped!",
				presetName))
			goto continue
		end
		loadedPresets = loadedPresets + 1
		for _, filterTableName in pairs(Config.AIM.PRESETS.FILTERS_PRESETS[presetName]) do
			local filterTableIsRequested = false
			for _, presetTableToLoad in pairs(presetTablesToLoad) do
				if string.upper(presetTableToLoad) == "ALL" or string.upper(presetTableToLoad) == string.upper(filterTableName) then
					filterTableIsRequested = true
					break
				end
			end

			if filterTableIsRequested then
				local filterTableFilePath = FileUtils:BuildRelativeJsonFileTargetPath(filterTableName,
					Config.AIM.PRESETS.PRESETS_DIR,
					presetName)
				local filterTable = FileUtils:LoadFile(filterTableFilePath)

				if filterTable then
					local success, result = pcall(function()
						Logger:BasicInfo(string.format(
							"Merging %s/%s.json into active itemFilterMaps",
							presetName,
							filterTableName))

						AddItemFilterMaps({ [filterTableName] = Ext.Json.Parse(filterTable) },
							false,
							false,
							false)
					end)

					if not success then
						Logger:BasicError(string.format("Could not merge table %s from preset %s due to error [%s]",
							filterTableName,
							presetName,
							result))
					else
						loadedTables = loadedTables + 1
					end
				else
					Logger:BasicError("Could not find filter table file " .. filterTableFilePath)
				end
			else
				Logger:BasicInfo(string.format(
					"The table %s in Preset %s was excluded from the ACTIVE_PRESETS list, so skipping it!",
					filterTableName,
					presetName))
			end
		end
		::continue::
	end

	if loadedTables == 0 then
		local errorMessage = "No preset tables were loaded, likely due to errors! Check previous logs."
		Logger:BasicError(errorMessage)
		error(errorMessage)
	end

	Logger:BasicInfo(string.format("Successfully merged %d Item Filter Maps from %d Preset(s) to the itemFilterMaps!",
		loadedTables,
		loadedPresets))

	ItemFilters:UpdateItemFilterMapsClone()
	if Logger:IsLogLevelEnabled(Logger.PrintTypes.DEBUG) then
		Logger:BasicDebug("Finished loading in presets - finalized item maps are:")
		for itemFilterMap, itemFilterMapContent in pairs(ItemFilters.itemFilterMaps) do
			Logger:BasicDebug(string.format("%s: %s", itemFilterMap, Ext.Json.Stringify(itemFilterMapContent)))
		end
	end

	return true
end

--- immutable clone of the itemFilterMaps - can be forceably synced using UpdateItemFilterMapsClone, but we'll do it on each update we know about
ItemFilters.itemFilterMaps = TableUtils:MakeImmutableTableCopy(itemFilterMaps)

--- Updates ItemFilters.itemFilterMaps
function ItemFilters:UpdateItemFilterMapsClone()
	ItemFilters.itemFilterMaps = TableUtils:MakeImmutableTableCopy(itemFilterMaps)

	-- Update the TargetStat enum with new fields for use by FilterProcessors
	for _, itemFilterMap in pairs(ItemFilters.itemFilterMaps) do
		for _, itemFilter in pairs(itemFilterMap) do
			for _, filter in pairs(itemFilter.Filters) do
				if filter.TargetStat and not ItemFilters.FilterFields.TargetStat[filter.TargetStat] then
					ItemFilters.FilterFields.TargetStat[filter.TargetStat] = filter.TargetStat
				end
			end
		end
	end
end

local function GetItemFiltersFromMap(itemFilterMap, key, filtersTable)
	if itemFilterMap then
		if itemFilterMap[key] then
			table.insert(filtersTable, itemFilterMap[key])
		end

		if itemFilterMap[ItemFilters.ItemKeys.WILDCARD] then
			table.insert(filtersTable, itemFilterMap[ItemFilters.ItemKeys.WILDCARD])
		end
	end
end

local function GetItemFiltersByRoot(itemFilterMaps, root, _, _)
	local filters = {}

	GetItemFiltersFromMap(itemFilterMaps.Roots, root, filters)

	if itemFilterMaps["RootPartial"] then
		for key, filter in pairs(itemFilterMaps.RootPartial) do
			if string.find(root, key) then
				table.insert(filters, filter)
			end
		end
	end

	return filters
end
local function GetItemFiltersByEquipmentType(itemFilterMaps, root, item, _)
	local filters = {}
	local entity = Ext.Entity.Get(item)
	if (itemFilterMaps["Equipment"] or itemFilterMaps["Weapons"]) and Osi.IsEquipable(item) == 1 then
		if entity.ServerItem.Template.EquipmentTypeID ~= "00000000-0000-0000-0000-000000000000" then
			local equipmentType = tostring(Ext.StaticData.Get(entity.ServerItem.Template.EquipmentTypeID, "EquipmentType")["Name"])
			GetItemFiltersFromMap(itemFilterMaps.Equipment, equipmentType, filters)
			if Osi.IsWeapon(item) == 1 then
				GetItemFiltersFromMap(itemFilterMaps.Weapons, equipmentType, filters)
			end
		end

		if Osi.IsWeapon(item) == 1 then
			GetItemFiltersFromMap(itemFilterMaps.Weapons, root, filters)
		end

		GetItemFiltersFromMap(itemFilterMaps.Equipment, root, filters)

		if entity.Armor then
			GetItemFiltersFromMap(itemFilterMaps.Equipment,
				Ext.Enums.ArmorType[tonumber(entity.Armor.ArmorType)],
				filters)
		end

		if entity.Equipable then
			local itemSlot = tostring(entity.Equipable.Slot)
			if itemSlot == Ext.Enums.StatsItemSlot[Ext.Enums.StatsItemSlot.MeleeMainHand] then
				itemSlot = "Melee Main Weapon"
			elseif itemSlot == Ext.Enums.StatsItemSlot[Ext.Enums.StatsItemSlot.MeleeOffHand] then
				itemSlot = "Melee Offhand Weapon"
			elseif itemSlot == Ext.Enums.StatsItemSlot[Ext.Enums.StatsItemSlot.RangedMainHand] then
				itemSlot = "Ranged Main Weapon"
			elseif itemSlot == Ext.Enums.StatsItemSlot[Ext.Enums.StatsItemSlot.RangedOffHand] then
				itemSlot = "Ranged Offhand Weapon"
			end

			GetItemFiltersFromMap(itemFilterMaps.Equipment,
				itemSlot,
				filters)
		end
	end

	return filters
end

local function GetItemFilterByTag(itemFilterMaps, _, item, _)
	local filters = {}
	if itemFilterMaps["Tags"] then
		for _, tagUUID in pairs(Ext.Entity.Get(item).Tag.Tags) do
			local tagTable = Ext.StaticData.Get(tagUUID, "Tag")
			if tagTable then
				local tagFilter = itemFilterMaps.Tags[tagTable["Name"]]
				if tagFilter then
					table.insert(filters, tagFilter)
				end
			end
		end
	end

	return filters
end

local itemFilterLookups = {
	GetItemFiltersByRoot,
	GetItemFilterByTag,
	GetItemFiltersByEquipmentType
}

--- Add custom function(s) to use to find ItemFilters for a given item within the available ItemFilterMaps.
---@param modUUID that ScriptExtender has registered for your mod, for tracking purposes - <a href="https://github.com/Norbyte/bg3se/blob/main/Docs/API.md#ismodloadedmodguid">https://github.com/Norbyte/bg3se/blob/main/Docs/API.md#ismodloadedmodguid</a>
--- will throw an error if the mod identified by that UUID is not loaded
---@tparam function ... should accept:
--- <br/>1. table(string, table(string, ItemFilter)) - immutable copy of all the itemFilterMaps to perform lookup against
--- <br/>2. GUIDSTRING - the root template of the item being sorted
--- <br/>3. GUIDSTRING - the item being sorted
--- <br/>4. GUIDSTRING - the inventoryHolder
--- <br/>and return a list of ItemFilters
function ItemFilters:RegisterItemFilterLookupFunction(modUUID, ...)
	local modName = ModUtils:GetModInfoFromUUID(modUUID).Name

	local funcCount = 0
	for _, lookupFunc in pairs({ ... }) do
		table.insert(itemFilterLookups, lookupFunc)
		funcCount = funcCount + 1
	end

	Logger:BasicInfo(string.format("Mod %s successfully added %d new ItemFilterLookupFunction(s)!",
		modName,
		funcCount))

	return true
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
				lookupFunc(ItemFilters.itemFilterMaps, root, item, inventoryHolder),
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
