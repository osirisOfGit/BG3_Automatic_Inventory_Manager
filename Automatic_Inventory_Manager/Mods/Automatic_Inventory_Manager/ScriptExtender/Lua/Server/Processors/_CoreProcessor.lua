Ext.Require("Server/Processors/_FilterProcessors.lua")

local function AddItemToProcessingTable(root, target, amount)
	if not TEMPLATES_BEING_TRANSFERRED[root] then
		TEMPLATES_BEING_TRANSFERRED[root] = { [target] = amount }
	else
		AddItemToTable_AddingToExistingAmount(TEMPLATES_BEING_TRANSFERRED[root], target, amount)
	end
end

--- Executes the given filter according to weighted stat distribution
--- @param itemFilter ItemFilter
--- @param eligiblePartyMembers CHARACTER[]
--- @param partyMembersWithAmountWon table<CHARACTER, number>
--- @param item GUIDSTRING
--- @param root GUIDSTRING
--- @param inventoryHolder CHARACTER
--- @return integer|nil 1 if a winner was found so that the parent method can stop searching, nil otherwise
local function ProcessWeightByMode(itemFilter,
								   eligiblePartyMembers,
								   partyMembersWithAmountWon,
								   item,
								   root,
								   inventoryHolder)
	local numberOfFiltersToProcess = #itemFilter.Filters

	if itemFilter.Filters then
		for i = 1, numberOfFiltersToProcess do
			local filter = itemFilter.Filters[i]
			--- @cast filter WeightedFilter
			eligiblePartyMembers = FilterProcessors:ExecuteFilterAgainstEligiblePartyMembers(filter,
				eligiblePartyMembers,
				partyMembersWithAmountWon,
				inventoryHolder,
				item,
				root)

			if #eligiblePartyMembers == 1 or i == numberOfFiltersToProcess then
				local target = #eligiblePartyMembers == 1 and eligiblePartyMembers[1] or
					eligiblePartyMembers[Osi.Random(#eligiblePartyMembers) + 1]

				partyMembersWithAmountWon[target] = partyMembersWithAmountWon[target] + 1
				_P("Winning command: " .. Ext.Json.Stringify(filter))
				return 1
			end
		end
	end
end

--- Distributes the item stack according to the winners of the processed filters
--- @param partyMembersWithAmountWon table<CHARACTER, number>
--- @param item GUIDSTRING
--- @param root GUIDSTRING
--- @param inventoryHolder CHARACTER
local function ProcessWinners(partyMembersWithAmountWon, item, root, inventoryHolder)
	_P("Final Results: " .. Ext.Json.Stringify(partyMembersWithAmountWon))

	for target, amount in pairs(partyMembersWithAmountWon) do
		if amount > 0 then
			if target == inventoryHolder then
				_P(string.format("Target was determined to be inventoryHolder for %s on character %s"
				, item
				, inventoryHolder))
			else
				-- This method generates a new uuid for the item upon moving it without forcing us to destroy it and generate a new one from the template
				Osi.ToInventory(item, target, amount, 0, 0)
				AddItemToProcessingTable(root, target, amount)

				_P(string.format("'Moved' %s of %s to %s from %s"
				, amount
				, item
				, target
				, inventoryHolder))
			end
		end
	end
end

-- If there's a stack limit, returns all the party members that are <=, or nil if no members are
--- comment
--- @param itemFilter ItemFilter
--- @param eligiblePartyMembers CHARACTER[]
--- @param partyMembersWithAmountWon table<CHARACTER, number>
--- @param root GUIDSTRING
--- @param inventoryHolder CHARACTER
---@return table|nil # All party members that have fewer than the stack limit, or nil if no members do
local function FilterInitialTargets_ByStackLimit(itemFilter,
												 eligiblePartyMembers,
												 partyMembersWithAmountWon,
												 root,
												 inventoryHolder)
	if itemFilter.Modifiers and itemFilter[ItemFilters.ItemFields.FilterModifiers.STACK_LIMIT] then
		local filteredSurvivors = {}
		for _, partyMember in pairs(eligiblePartyMembers) do
			local totalFutureStackSize = ProcessorUtils:CalculateTotalItemCount(
				partyMembersWithAmountWon, partyMember, inventoryHolder, root)

			if totalFutureStackSize <= itemFilter[ItemFilters.ItemFields.FilterModifiers.STACK_LIMIT] then
				-- _P("Reserved amount of " .. totalFutureStackSize .. " is less than limit of " .. stackLimit .. " on " .. partyMember)
				table.insert(filteredSurvivors, partyMember)
			end
		end

		return #filteredSurvivors > 0 and filteredSurvivors or nil
	end
end

Processor = {}
--- Processes the filters on the given params
---@param item GUIDSTRING
---@param root GUIDSTRING
---@param inventoryHolder CHARACTER
---@param itemFilters ItemFilter[]
function Processor:ProcessFiltersForItemAgainstParty(item, root, inventoryHolder, itemFilters)
	local partyMembersWithAmountWon = {}
	local currentItemStackSize = Osi.GetStackAmount(item)
	local eligiblePartyMembers = {}
	for _, player in pairs(Osi.DB_Players:Get(nil)) do
		partyMembersWithAmountWon[player[1]] = 0
		table.insert(eligiblePartyMembers, player[1])
	end

	local exitCode
	for c = 1, #itemFilters do
		if exitCode == 1 then
			break
		end

		local filter = itemFilters[c]
		if filter.Mode == ItemFilters.ItemFields.SelectionModes.TARGET then
			local target = filter.Filters[1].Target

			if target then
				if string.lower(target) == "camp" then
					Osi.SendToCampChest(item, inventoryHolder)
					AddItemToProcessingTable(root, item, currentItemStackSize)
					_P("Sent item to camp!")
					return
				elseif Osi.IsPlayer(target) == 1 then
					AddItemToTable_AddingToExistingAmount(partyMembersWithAmountWon, target, currentItemStackSize)
					_P("Sent item to " .. target)
					break
				else
					Ext.Utils.PrintError(string.format(
						"The target %s was specified for item %s but they are not a party member!"
						, target
						, item))
				end
			else
				Ext.Utils.PrintError("A Target was not provided despite using TargetFilter for item " .. item)
			end
		else
			for _ = 1, currentItemStackSize do
				eligiblePartyMembers = FilterInitialTargets_ByStackLimit(filter,
						eligiblePartyMembers,
						partyMembersWithAmountWon,
						root,
						inventoryHolder)
					or eligiblePartyMembers

				-- _P("Processing " ..
				-- 	itemCounter ..
				-- 	" out of " ..
				-- 	itemStackAmount ..
				-- 	" with winners: " .. Ext.Json.Stringify(partyMembersWithAmountWon, { Beautify = false }))
				if filter.Mode == ItemFilters.ItemFields.SelectionModes.WEIGHT_BY then
					exitCode = ProcessWeightByMode(filter,
						eligiblePartyMembers,
						partyMembersWithAmountWon,
						item,
						root,
						inventoryHolder)
				end
			end
		end
	end

	ProcessWinners(partyMembersWithAmountWon, item, root, inventoryHolder)
end
