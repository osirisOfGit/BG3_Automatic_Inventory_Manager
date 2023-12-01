Ext.Require("Server/CriteriaProcessor/_CriteriaProcessors.lua")

function ProcessWeightByMode(command, eligiblePartyMembers, partyMembersWithAmountWon, item, root, inventoryHolder)
	local numberOfCriteriaToProcess = #command[CRITERIA]
	local survivors = eligiblePartyMembers
	if command[CRITERIA] and numberOfCriteriaToProcess > 0 then
		for i = 1, numberOfCriteriaToProcess do
			-- Begin actual processing of the command
			local currentWeightedCriteria = command[CRITERIA][i]
			survivors = STAT_TO_FUNCTION_MAP[currentWeightedCriteria[STAT]](partyMembersWithAmountWon,
				survivors,
				inventoryHolder,
				item,
				root,
				currentWeightedCriteria)

			if #survivors == 1 or i == numberOfCriteriaToProcess then
				local target = #survivors == 1 and survivors[1] or survivors[Osi.Random(#survivors) + 1]
				partyMembersWithAmountWon[target] = partyMembersWithAmountWon[target] + 1
				break
			end
		end
	end
end

function ProcessWinners(partyMembersWithAmountWon, item, root, inventoryHolder)
	_P("Final Results: " .. Ext.Json.Stringify(partyMembersWithAmountWon))
	for target, amount in pairs(partyMembersWithAmountWon) do
		if amount > 0 then
			-- if not target then
			-- 	_P("Couldn't determine a target for item " ..
			-- 		item .. " on character " .. inventoryHolder .. " for command " .. Ext.Json.Stringify(command))
			-- end
			if target == inventoryHolder then
				_P("Target was determined to be inventoryHolder for " ..
					item .. " on character " .. inventoryHolder)
			else
				-- This method generates a new uuid for the item upon moving it without forcing us to destroy it and generate a new one from the template
				Osi.ToInventory(item, target, amount, 0, 0)
				if not TEMPLATES_BEING_TRANSFERRED[root] then
					TEMPLATES_BEING_TRANSFERRED[root] = { [target] = amount }
				elseif not TEMPLATES_BEING_TRANSFERRED[root][target] then
					TEMPLATES_BEING_TRANSFERRED[root][target] = amount
				else
					TEMPLATES_BEING_TRANSFERRED[root][target] = TEMPLATES_BEING_TRANSFERRED[root][target] + amount
				end

				_P("'Moved' " ..
					amount ..
					" of " .. root .. " to " .. target .. " from " .. inventoryHolder)
			end
		end
	end
end

function FilterInitialTargets_ByStackLimit(command, partyMembersWithAmountWon, root, inventoryHolder)
	-- If there's a stack limit, remove any members that exceed it, unless all of them do
	local stackLimit = command[STACK_LIMIT]
	if stackLimit then
		local filteredSurvivors = {}
		for partyMember, _ in pairs(partyMembersWithAmountWon) do
			local totalFutureStackSize = CalculateTemplateCurrentAndReservedStackSize(
				partyMembersWithAmountWon, partyMember, inventoryHolder, root)

			if totalFutureStackSize <= stackLimit then
				-- _P("Reserved amount of " .. totalFutureStackSize .. " is less than limit of " .. stackLimit .. " on " .. partyMember)
				table.insert(filteredSurvivors, partyMember)
			end
		end

		if #filteredSurvivors > 0 then
			return filteredSurvivors
		end
	end
end

function ProcessCommand(item, root, inventoryHolder, command)
	local partyMembersWithAmountWon = {}
	local currentItemStackSize = Osi.GetStackAmount(item)

	if command[MODE] == MODE_DIRECT then
		local target = command[TARGET]
		partyMembersWithAmountWon[target] = currentItemStackSize
	else
		local partyList = {}
		for _, player in pairs(Osi.DB_Players:Get(nil)) do
			partyMembersWithAmountWon[player[1]] = 0
			table.insert(partyList, player[1])
		end
		for _ = 1, currentItemStackSize do
			partyList = FilterInitialTargets_ByStackLimit(command, partyMembersWithAmountWon, root, inventoryHolder)
				or partyList
			-- _P("Processing " ..
			-- 	itemCounter ..
			-- 	" out of " ..
			-- 	itemStackAmount ..
			-- 	" with winners: " .. Ext.Json.Stringify(partyMembersWithAmountWon, { Beautify = false }))
			if command[MODE] == MODE_WEIGHT_BY then
				ProcessWeightByMode(command, partyList, partyMembersWithAmountWon, item, root, inventoryHolder)
			end
		end
	end

	ProcessWinners(partyMembersWithAmountWon, item, root, inventoryHolder)
end
