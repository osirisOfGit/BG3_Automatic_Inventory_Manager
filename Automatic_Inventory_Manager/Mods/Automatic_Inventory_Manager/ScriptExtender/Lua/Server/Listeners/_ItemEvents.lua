local function RemoveItemFromTracker_IfAlreadySorted(root, item, inventoryHolder)
	local originalOwner = Osi.GetOriginalOwner(item)
	if originalOwner and not (originalOwner == Osi.GetUUID(inventoryHolder)) and Osi.IsPlayer(inventoryHolder) == 1 then
		-- _P("|OriginalOwner| = " .. Osi.GetOriginalOwner(item)
		-- 	.. "\n\t|DirectInventoryOwner| = " .. Osi.GetDirectInventoryOwner(item)
		-- 	.. "\n\t|Owner| = " .. Osi.GetOwner(item))

		if TEMPLATES_BEING_TRANSFERRED[root] and TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder] then
			_P(string.format("Found %s of %s being transferred to %s - tagging as processed!"
			, TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder]
			, item
			, inventoryHolder))

			Osi.SetOriginalOwner(item, Osi.GetUUID(inventoryHolder))
			TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder] = TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder] -
				Osi.GetStackAmount(item)

			if TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder] == 0 then
				TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder] = nil
			end

			if #TEMPLATES_BEING_TRANSFERRED[root] == 0 then
				TEMPLATES_BEING_TRANSFERRED[root] = nil
			end
		end
	end
end

---@param existingFilterTable Filters
---@param desiredPriority number
---@return number
local function DetermineItemFilterPriority(existingFilterTable, desiredPriority)
	if existingFilterTable[desiredPriority] then
		return DetermineItemFilterPriority(existingFilterTable, desiredPriority + 1)
	else
		return desiredPriority
	end
end


---
---@param consolidatedItemFilter ItemFilter the existing ItemFilter to consolidate into
---@param newItemFilters ItemFilter[] the filters to add to the table
local function AddFiltersToTable(consolidatedItemFilter, newItemFilters)
	for _, newItemFilter in pairs(newItemFilters) do
		-- Consolidate filters, ignoring duplicates
		for newItemFilterPriority, newItemFilter in pairs(newItemFilter.Filters) do
			local foundIdenticalFilter = false
			for _, existingFilter in pairs(consolidatedItemFilter.Filters) do
				if ItemFilters:CompareFilter(newItemFilter, existingFilter) then
					foundIdenticalFilter = true
				end
			end
			if not foundIdenticalFilter then
				local determinedPriority = DetermineItemFilterPriority(consolidatedItemFilter.Filters,
					newItemFilterPriority)
				consolidatedItemFilter.Filters[determinedPriority] = newItemFilter
			end
		end

		if newItemFilter.Modifiers then
			for modifier, newModifier in pairs(newItemFilter.Modifiers) do
				if not consolidatedItemFilter.Modifiers[modifier] then
					consolidatedItemFilter.Modifiers[modifier] = newModifier
				end
			end
		end
	end
end

--- Finds all Filters for the given item
---@param item GUIDSTRING
---@param root GUIDSTRING
---@return ItemFilter|nil
local function SearchForItemFilters(item, root)
	--- @type ItemFilter
	local consolidatedItemFilter = { Filters = {}, Modifiers = {} }

	if Osi.IsEquipable(item) == 1 then
		AddFiltersToTable(consolidatedItemFilter, ItemFilters:GetFiltersByEquipmentType(item))
	end

	AddFiltersToTable(consolidatedItemFilter, ItemFilters:GetFilterByTag(item))

	AddFiltersToTable(consolidatedItemFilter, ItemFilters:GetFiltersByRoot(root))

	local normalizedFilters = {}
	local index = 0
	for _,_ in pairs(consolidatedItemFilter.Filters) do
		index = index + 1
	end
	for i = 1, index do
		local nextLowestNumber
		for filterPriority, _ in pairs(consolidatedItemFilter.Filters) do
			if filterPriority == i then
				nextLowestNumber = i
				goto continue
			else
				if not nextLowestNumber then
					nextLowestNumber = filterPriority
				else
					nextLowestNumber = filterPriority < nextLowestNumber and filterPriority or nextLowestNumber
				end
			end
		end
		::continue::
		normalizedFilters[i] = consolidatedItemFilter.Filters[nextLowestNumber]
		consolidatedItemFilter.Filters[nextLowestNumber] = nil
	end

	consolidatedItemFilter.Filters = normalizedFilters
	return consolidatedItemFilter
end

-- Includes moving from container to other inventories etc...
Ext.Osiris.RegisterListener("TemplateAddedTo", 4, "after", function(root, item, inventoryHolder, addType)
	-- Will be null if inventoryHolder isn't a character
	if not (Osi.IsPlayer(inventoryHolder) == 1) then
		_P(string.format("inventoryHolder %s is not a player", inventoryHolder))
		return
	elseif not (Osi.Exists(item) == 1) then
		_P("Item doesn't exist!")
		return
	end

	RemoveItemFromTracker_IfAlreadySorted(root, item, inventoryHolder)

	if Osi.IsTagged(item, TAG_AIM_PROCESSED) == 1 then
		_P("Item was already processed, skipping!\n")
		return
	end

	local applicableItemFilter = SearchForItemFilters(item, root)
	if #applicableItemFilter.Filters > 0 then
		Ext.Utils.PrintWarning(
			"----------------------------------------------------------\n\t\t\tSTARTED\n----------------------------------------------------------")

		local itemStack, templateStack = Osi.GetStackAmount(item)
		_P("|item| = " .. item
			.. "\n\t|root| = " .. root
			.. "\n\t|inventoryHolder| = " .. inventoryHolder
			.. "\n\t|addType| = " .. addType
			.. "\n\t|itemStackSize| = " .. itemStack
			.. "\n\t|templateStackSize| = " .. templateStack)

		_P(Ext.Json.Stringify(applicableItemFilter))

		Processor:ProcessFiltersForItemAgainstParty(item, root, inventoryHolder, applicableItemFilter)

		Ext.Utils.PrintWarning(
			"----------------------------------------------------------\n\t\t\tFINISHED\n----------------------------------------------------------")
	else
		Ext.Utils.Print("No command could be found for " ..
			item .. " with root " .. root .. " on " .. inventoryHolder)
	end

	Osi.SetTag(item, TAG_AIM_PROCESSED)
end)

Ext.Osiris.RegisterListener("DroppedBy", 2, "after", function(object, _)
	Osi.ClearTag(object, TAG_AIM_PROCESSED)
end)
