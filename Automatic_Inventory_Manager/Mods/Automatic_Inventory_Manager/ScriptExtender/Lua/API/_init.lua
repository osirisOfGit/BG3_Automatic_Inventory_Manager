Ext.Require("AIM/_ItemFilters.lua")
Ext.Require("AIM/_Logger.lua")
Api = {}
Api.ItemFilters = {}

--- For each itemFilterMap, will just add to the superset if the map is not already known, otherwise will do a recursive merge,
--- adding any Filters that are not already added, incrementing the priority to the next highest number if taken.
---@param itemFilterMaps table<string, ItemFilterMap>
---@param forceOverride boolean if the itemFilterMap is already known, will just completely overwrite with the provided map instead of merging
---@param prioritizeNewFilters boolean if merging in a filter for an existing ItemFilter, and an existing filter shares the same priority, the provided filter will be given higher priority
function Api.ItemFilters:AddItemFilterMap(itemFilterMaps, forceOverride, prioritizeNewFilters)
	for mapName, itemFilterMap in pairs(itemFilterMaps) do
		if not ItemFilters.ItemMaps[mapName] or forceOverride == true then
			ItemFilters.ItemMaps[mapName] = itemFilterMap
		else
			---@type ItemFilterMap
			local existingItemFilterMap = ItemFilters.ItemMaps[mapName]
			for itemKey, itemFilter in pairs(itemFilterMap) do
				if not existingItemFilterMap[itemKey] then
					existingItemFilterMap[itemKey] = itemFilter
				else
					local existingItemFilter = existingItemFilterMap[itemKey]
					ItemFilters:MergeItemFiltersIntoTarget(existingItemFilter, itemFilter, prioritizeNewFilters)
				end
			end
		end
	end

	ItemFilters:CopyItemMaps()
end

--- Add the provided lookup functions to be used when processing an item. Each function should have the following arguments:
--- 1. ItemMaps - this will be a copy of table<string, ItemFilterMap> to prevent modification 
--- 2. root - the GUIDSTRING of the root template
--- 3. item - the GUIDSTRING of the item being processed
--- 4. inventoryHolder - the CHARACTER that currently has the item (picked up off the ground, etc)
---
--- Any errors that occur during execution of these lookups will be logged and ignored.
---@param filterLookups function[]
function Api.ItemFilters:AddItemFilterLookups(filterLookups)
	for _, func in pairs(filterLookups) do
		table.insert(ItemFilters.ItemFilterLookups, func)
	end
	Logger:BasicInfo(string.format("ItemFilterLookup list now contains %d lookups", #ItemFilters.ItemFilterLookups))
end
