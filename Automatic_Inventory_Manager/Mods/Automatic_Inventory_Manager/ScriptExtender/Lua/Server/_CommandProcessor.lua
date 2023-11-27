function ProcessCommand(item, root, inventoryHolder, command)
	local itemStackAmount, _ = Osi.GetStackAmount(item)
	local targetCharsAndReservedAmount = {}
	for _, player in pairs(Osi.DB_Players:Get(nil)) do
		targetCharsAndReservedAmount[player[1]] = 0
	end

	for itemCounter = 1, itemStackAmount do
		-- _P("Processing " ..
		-- 	itemCounter ..
		-- 	" out of " ..
		-- 	itemStackAmount ..
		-- 	" with winners: " .. Ext.Json.Stringify(targetCharsAndReservedAmount, { Beautify = false }))
		local target
		if command[MODE] == MODE_DIRECT then
			target = command[TARGET]
			targetCharsAndReservedAmount[target] = targetCharsAndReservedAmount[target] + 1
		elseif command[MODE] == MODE_WEIGHT_BY then
			if command[CRITERIA] then
				for i = 1, #command[CRITERIA] do
					local currentWeightedCriteria = command[CRITERIA][i]
					local winners = STAT_TO_FUNCTION_MAP[currentWeightedCriteria[STAT]](targetCharsAndReservedAmount,
						inventoryHolder,
						item, root,
						currentWeightedCriteria)

					if #winners == 1 or i == #command[CRITERIA] then
						if #winners == 1 then
							target = winners[1]
						else
							target = winners[Osi.Random(#winners) + 1]
						end
						targetCharsAndReservedAmount[target] = targetCharsAndReservedAmount[target] + 1
						break
					end
				end
			end
		end
	end
	_P("Final Results: " .. Ext.Json.Stringify(targetCharsAndReservedAmount))
	for target, amount in pairs(targetCharsAndReservedAmount) do
		if amount > 0 then
			-- if not target then
			-- 	_P("Couldn't determine a target for item " ..
			-- 		item .. " on character " .. inventoryHolder .. " for command " .. Ext.Json.Stringify(command))
			-- end
			if target == inventoryHolder then
				_P("Target was determined to be inventoryHolder for " ..
					item .. " on character " .. inventoryHolder)
				-- Generally happens when splitting stacks, this allows us to tag the stack without trying to "move"
				-- which can cause infinite loops due to GetItemByTemplateInUserInventory not refreshing its value in time (TemplateRemoveFromUser kicks off an event maybe?)
			else
				-- Forces the game to generate a new, complete stack of items with all one UUID, since stacking is a very duct-tape-and-glue system
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

-- 0 if equal, 1 if base beats challenger, -1 if base loses to challenger
function Compare(baseValue, challengerValue, comparator)
	if baseValue == challengerValue then
		return 0
	elseif comparator == COMPARATOR_GT then
		return baseValue > challengerValue and 1 or -1
	elseif comparator == COMPARATOR_LT then
		return baseValue < challengerValue and 1 or -1
	end
end

function GetTargetByHealthPercent(targetCharacters, _, _, _, criteria)
	local winningHealthPercent
	local winners = {}
	for targetChar, _ in pairs(targetCharacters) do
		local health = Ext.Entity.Get(targetChar).Health
		local challengerHealthPercent = (health.Hp / health.MaxHp) * 100
		if winningHealthPercent then
			local result = Compare(winningHealthPercent, challengerHealthPercent,
				criteria[COMPARATOR])
			if result == 0 then
				table.insert(winners, targetChar)
			elseif result == -1 then
				winners = { targetChar }
				winningHealthPercent = challengerHealthPercent
			end
		else
			winningHealthPercent = challengerHealthPercent
			table.insert(winners, targetChar)
		end
	end

	return winners
end

function GetTargetByStackAmount(targetCharacters, inventoryHolder, _, root, criteria)
	local winners = {}
	local winningVal

	for targetChar, amountOfItemReserved in pairs(targetCharacters) do
		local item = Osi.GetItemByTemplateInInventory(root, targetChar)
		local _, totalFutureStackSize
		if item then
			_, totalFutureStackSize = Osi.GetStackAmount(item)
		else
			totalFutureStackSize = 0
		end
		totalFutureStackSize = totalFutureStackSize + amountOfItemReserved
		if TEMPLATES_BEING_TRANSFERRED[root] and TEMPLATES_BEING_TRANSFERRED[root][targetChar] then
			totalFutureStackSize = totalFutureStackSize + TEMPLATES_BEING_TRANSFERRED[root][targetChar]
			-- _P("Added " .. TEMPLATES_BEING_TRANSFERRED[root][targetChar] .. " to the stack size")
		end
		if targetChar == inventoryHolder then
			for char, amountReserved in pairs(targetCharacters) do
				if not (char == inventoryHolder) then
					totalFutureStackSize = totalFutureStackSize - amountReserved
					-- _P("Brought down inventoryHolder's amount by  " .. amountReserved)
				end
			end
		end
		-- _P("Found " .. totalFutureStackSize .. " on " .. targetChar)

		if not winningVal then
			winningVal = totalFutureStackSize
			table.insert(winners, targetChar)
		else
			local result = Compare(winningVal, totalFutureStackSize,
				criteria[COMPARATOR])
			if result == 0 then
				table.insert(winners, targetChar)
			elseif result == -1 then
				winners = { targetChar }
				winningVal = totalFutureStackSize
			end
		end
	end
	return winners
end

STAT_TO_FUNCTION_MAP = {
	[STAT_STACK_AMOUNT] = GetTargetByStackAmount,
	[STAT_HEALTH_PERCENTAGE] = GetTargetByHealthPercent
}
