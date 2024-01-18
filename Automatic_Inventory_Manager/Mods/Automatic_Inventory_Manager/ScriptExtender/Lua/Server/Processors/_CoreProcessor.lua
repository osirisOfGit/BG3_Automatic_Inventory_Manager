Ext.Require("Server/Processors/_FilterProcessors.lua")

--- Distributes the item stack according to the winners of the processed filters
--- @param partyMembersWithAmountWon table<CHARACTER, number>
--- @param item GUIDSTRING
--- @param root GUIDSTRING
--- @param inventoryHolder CHARACTER
local function ProcessWinners(partyMembersWithAmountWon, item, root, inventoryHolder)
	Logger:BasicInfo(string.format("Final Results for item %s with root %s on inventoryHolder %s: %s", item, root, inventoryHolder, Ext.Json.Stringify(partyMembersWithAmountWon)))
	Osi.SetTag(item, TAG_AIM_PROCESSED)

	for target, amount in pairs(partyMembersWithAmountWon) do
		if amount > 0 then
			if target == inventoryHolder then
				Logger:BasicDebug(string.format("Target was determined to be inventoryHolder for %s on character %s"
				, item
				, inventoryHolder))
			elseif target == "camp" then
				Osi.SendToCampChest(item, inventoryHolder)
			else
				Osi.SetOriginalOwner(item, inventoryHolder)

				-- This method generates a new uuid for the item upon moving it without forcing us to destroy it and generate a new one from the template
				-- Need to make sure we don't clear the original owner here so our tracker logic in itemEvents knows
				Osi.ToInventory(item, target, amount, 0, 0)

				if not TEMPLATES_BEING_TRANSFERRED[root] then
					TEMPLATES_BEING_TRANSFERRED[root] = { [target] = amount }
				else
					Utils:AddItemToTable_AddingToExistingAmount(TEMPLATES_BEING_TRANSFERRED[root], target, amount)
				end

				Logger:BasicInfo(string.format("Moved %s of %s to %s from %s"
				, amount
				, item
				, target
				, inventoryHolder))
			end
		end
	end
end

-- If there's a stack limit, returns all the party members that are <, or nil if no members are
---
--- @param itemFilter ItemFilter
--- @param eligiblePartyMembers GUIDSTRING[]
--- @param targetsWithAmountWon table<GUIDSTRING, number>
--- @param root GUIDSTRING
--- @param inventoryHolder CHARACTER
---@return table|nil # All party members that have fewer than the stack limit, or nil if no members do
local function FilterInitialTargets_ByStackLimit(itemFilter,
												 eligiblePartyMembers,
												 targetsWithAmountWon,
												 root,
												 inventoryHolder)
	if itemFilter.Modifiers and itemFilter.Modifiers[ItemFilters.ItemFields.FilterModifiers.STACK_LIMIT] then
		local filteredSurvivors = {}
		for _, partyMember in pairs(eligiblePartyMembers) do
			local totalFutureStackSize = ProcessorUtils:CalculateTotalItemCount(
				targetsWithAmountWon, partyMember, inventoryHolder, root)

			if totalFutureStackSize < itemFilter.Modifiers[ItemFilters.ItemFields.FilterModifiers.STACK_LIMIT] then
				table.insert(filteredSurvivors, partyMember)
			end
		end

		return #filteredSurvivors > 0 and filteredSurvivors or nil
	end

	return {table.unpack(eligiblePartyMembers)}
end

---
---@param item GUIDSTRING
---@param eligiblePartyMembers CHARACTER[]
---@return table|nil # All party members that won't be encumbered by the item, or nil if all members will
local function FilterInitialTargets_ByEncumbranceRisk(item, eligiblePartyMembers)
	local filteredSurvivors = {}
	local itemWeight = tonumber(Ext.Entity.Get(item).Data.Weight)

	for _, partyMember in pairs(eligiblePartyMembers) do
		local partyMemberEntity = Ext.Entity.Get(partyMember)
		-- If not encumbered
		if tonumber(partyMemberEntity.EncumbranceState.State) == 0 then
			local unencumberedLimit = tonumber(partyMemberEntity.EncumbranceStats["field_0"])
			local inventoryWeight = tonumber(partyMemberEntity.InventoryWeight["Weight"])
			if (inventoryWeight + itemWeight) <= unencumberedLimit then
				-- Logger:BasicDebug(string.format("Item weight %d will not encumber %s, with %d more room!",
				-- 	itemWeight,
				-- 	partyMember,
				-- 	unencumberedLimit - (inventoryWeight + itemWeight)))
				table.insert(filteredSurvivors, partyMember)
			end
		end
	end

	return #filteredSurvivors > 0 and filteredSurvivors or nil
end

Processor = {}

--- Processes the filters on the given params
---@param item GUIDSTRING
---@param root GUIDSTRING
---@param inventoryHolder CHARACTER
---@param itemFilter ItemFilter
function Processor:ProcessFiltersForItemAgainstParty(item, root, inventoryHolder, itemFilter)
	local targetsWithAmountWon = {}
	local currentItemStackSize = Osi.GetStackAmount(item)
	local partyMembers = {}
	for _, player in pairs(Osi.DB_Players:Get(nil)) do
		targetsWithAmountWon[player[1]] = 0
		table.insert(partyMembers, player[1])
	end

	-- if itemFilter.Filters then
	local numberOfFiltersToProcess = #itemFilter.Filters
	for _ = 1, currentItemStackSize do
		local eligiblePartyMembers = FilterInitialTargets_ByStackLimit(itemFilter,
				partyMembers,
				targetsWithAmountWon,
				root,
				inventoryHolder)
			or partyMembers

		eligiblePartyMembers = FilterInitialTargets_ByEncumbranceRisk(item, eligiblePartyMembers)
			or eligiblePartyMembers

		for i = 1, numberOfFiltersToProcess do
			local filter = itemFilter.Filters[i]

			if filter.Target then
				---@cast filter TargetFilter
				eligiblePartyMembers = FilterProcessors:ExecuteTargetFilter(filter, inventoryHolder, item)
			elseif filter.CompareStategy then
				--- @cast filter WeightedFilter
				eligiblePartyMembers = FilterProcessors:ExecuteFilterAgainstEligiblePartyMembers(filter,
					eligiblePartyMembers,
					targetsWithAmountWon,
					inventoryHolder,
					item,
					root)
			end

			if #eligiblePartyMembers == 1 or i == numberOfFiltersToProcess then
				local target
				if #eligiblePartyMembers > 0 then
					target = #eligiblePartyMembers == 1 and eligiblePartyMembers[1] or
						eligiblePartyMembers[Osi.Random(#eligiblePartyMembers) + 1]
				else
					target = targetsWithAmountWon[Osi.Random(#targetsWithAmountWon) + 1]
				end

				Utils:AddItemToTable_AddingToExistingAmount(targetsWithAmountWon, target, 1)
				Logger:BasicDebug("Winning command: " .. Ext.Json.Stringify(filter))
				goto continue
			end
		end
		::continue::
	end

	ProcessWinners(targetsWithAmountWon, item, root, inventoryHolder)
end
