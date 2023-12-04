Ext.Require("Server/CriteriaProcessor/_CriteriaProcessors.lua")

local function ProcessWeightByMode(command, eligiblePartyMembers, partyMembersWithAmountWon, item, root, inventoryHolder)
	local numberOfCriteriaToProcess = #command[CRITERIA]
	local survivors = eligiblePartyMembers

	if command[CRITERIA] and numberOfCriteriaToProcess > 0 then
		for i = 1, numberOfCriteriaToProcess do
			--- @type Criteria
			local currentWeightedCriteria = command[CRITERIA][i]
			survivors = CriteriaProcessors.ExecuteCriteria(currentWeightedCriteria,
				partyMembersWithAmountWon,
				survivors,
				inventoryHolder,
				item,
				root)

			if #survivors == 1 or i == numberOfCriteriaToProcess then
				local target = #survivors == 1 and survivors[1] or survivors[Osi.Random(#survivors) + 1]
				partyMembersWithAmountWon[target] = partyMembersWithAmountWon[target] + 1

				return 1
			end
		end
	end
end

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
				if not TEMPLATES_BEING_TRANSFERRED[root] then
					TEMPLATES_BEING_TRANSFERRED[root] = { [target] = amount }
				else
					AddItemToTable_AddingToExistingAmount(TEMPLATES_BEING_TRANSFERRED[root], target, amount)
				end

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
local function FilterInitialTargets_ByStackLimit(command, eligiblePartyMembers, partyMembersWithAmountWon, root,
												 inventoryHolder)
	if command[STACK_LIMIT] then
		local filteredSurvivors = {}
		for _, partyMember in pairs(eligiblePartyMembers) do
			local totalFutureStackSize = ProcessorUtils.CalculateTotalItemCount(
				partyMembersWithAmountWon, partyMember, inventoryHolder, root)

			if totalFutureStackSize <= command[STACK_LIMIT] then
				-- _P("Reserved amount of " .. totalFutureStackSize .. " is less than limit of " .. stackLimit .. " on " .. partyMember)
				table.insert(filteredSurvivors, partyMember)
			end
		end

		return #filteredSurvivors > 0 and filteredSurvivors or nil
	end
end

Processor = {}
function Processor.ProcessCommand(item, root, inventoryHolder, commands)
	local partyMembersWithAmountWon = {}
	local currentItemStackSize = Osi.GetStackAmount(item)
	local eligiblePartyMembers = {}
	for _, player in pairs(Osi.DB_Players:Get(nil)) do
		partyMembersWithAmountWon[player[1]] = 0
		table.insert(eligiblePartyMembers, player[1])
	end

	local exitCode
	for c = 1, #commands do
		if exitCode == 1 then
			break
		end

		local commandToProcess = commands[c]
		if commandToProcess[MODE] == MODE_DIRECT then
			local target = commandToProcess[TARGET]
			if target and Osi.DB_IsPlayer:Get(target) then
				AddItemToTable_AddingToExistingAmount(partyMembersWithAmountWon, target, currentItemStackSize)
				break
			else
				Ext.Utils.PrintError(string.format(
					"The target %s for mode %s was specified for item %s but they are not a party member!"
					, target
					, MODE_DIRECT
					, item))
			end
		else
			for _ = 1, currentItemStackSize do
				eligiblePartyMembers = FilterInitialTargets_ByStackLimit(commandToProcess,
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
				if commandToProcess[MODE] == MODE_WEIGHT_BY then
					exitCode = ProcessWeightByMode(commandToProcess,
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
