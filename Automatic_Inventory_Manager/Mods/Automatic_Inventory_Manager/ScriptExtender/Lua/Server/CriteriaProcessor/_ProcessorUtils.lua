-- 0 if equal, 1 if base beats challenger, -1 if base loses to challenger
function Compare(baseValue, challengerValue, comparator)
	if baseValue == challengerValue then
		return 0
	elseif comparator == GREATER_THAN then
		return baseValue > challengerValue and 1 or -1
	elseif comparator == LESS_THAN then
		return baseValue < challengerValue and 1 or -1
	end
end

function SetWinningVal_ByCompareResult(baseValue, challengerValue, comparator, winnersTable, targetPartyMember)
	if not baseValue then
		table.insert(winnersTable, targetPartyMember)
		return challengerValue
	else
		local result = Compare(baseValue, challengerValue, comparator)
		if result == 0 then
			table.insert(winnersTable, targetPartyMember)
			return baseValue
		elseif result == -1 then
			for i = 1, #winnersTable do
				winnersTable[i] = nil
			end
			table.insert(winnersTable, targetPartyMember)
			return challengerValue
		end
	end

	return baseValue
end

-- Uses the following on the targetChar
-- + Osi.GetStackAmount (via Osi.GetItemByTemplateInInventory)
-- + the calculated amount won for this item stack thusfar
-- + the calculated amount won for previous items of the same template that haven't been added to the targetChar inventory yet (event hasn't been processed)
--
-- to determine the amount of the item's template that are theoretically in the given characters inventory.
--
-- If the targetChar is the inventoryHolder, will subtract the amount of the item stack being processed that has been "won" by the other party members
function CalculateTemplateCurrentAndReservedStackSize(partyMembersWithAmountWon, targetChar, inventoryHolder, root)
	local itemByTemplate = Osi.GetItemByTemplateInInventory(root, targetChar)
	local totalFutureStackSize = itemByTemplate and Osi.GetStackAmount(itemByTemplate) or 0
	totalFutureStackSize = totalFutureStackSize + partyMembersWithAmountWon[targetChar]

	if TEMPLATES_BEING_TRANSFERRED[root] and TEMPLATES_BEING_TRANSFERRED[root][targetChar] then
		totalFutureStackSize = totalFutureStackSize + TEMPLATES_BEING_TRANSFERRED[root][targetChar]
		-- _P("Added " .. TEMPLATES_BEING_TRANSFERRED[root][targetChar] .. " to the stack size")
	end

	if targetChar == inventoryHolder then
		local amountToRemove = Osi.GetStackAmount(itemByTemplate)
		for char, amountReserved in pairs(partyMembersWithAmountWon) do
			if not (char == inventoryHolder) then
				amountToRemove = amountToRemove + amountReserved
			end
		end
		if amountToRemove > totalFutureStackSize then
			amountToRemove = totalFutureStackSize
		end
		-- _P("Brought down inventoryHolder's amount by  " .. amountToRemove)
		totalFutureStackSize = totalFutureStackSize - amountToRemove
	end

	return totalFutureStackSize
end
