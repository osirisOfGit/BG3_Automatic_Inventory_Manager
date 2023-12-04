-- 0 if equal, 1 if base beats challenger, -1 if base loses to challenger

ProcessorUtils = {}

local function Compare(baseValue, challengerValue, comparator)
	if baseValue == challengerValue then
		return 0
	elseif comparator == HIGHER then
		return baseValue > challengerValue and 1 or -1
	elseif comparator == LOWER then
		return baseValue < challengerValue and 1 or -1
	end
end

--- Calculates the winner based on the result of comparing the baseValue against the challengerValue, using the Comparator
--- to determine the nature of the compare
---@param baseValue number|nil
---@param challengerValue number
---@param comparator COMPARATOR
---@param winnersTable table
---@param targetPartyMember GUIDSTRING
---@return table winners table of winners - will either append the targetPartyMember if the values were equal, or replace the table with just targetPartyMember if the challenger won
---@return number winningVal value that won in the compare, or baseValue if both were equal
function ProcessorUtils.SetWinningVal_ByCompareResult(baseValue,
													  challengerValue,
													  comparator,
													  winnersTable,
													  targetPartyMember)
	--- @type number
	local winningValue
	if not baseValue then
		table.insert(winnersTable, targetPartyMember)
		winningValue = challengerValue
	else
		local result = Compare(baseValue, challengerValue, comparator)
		if result == 0 then
			table.insert(winnersTable, targetPartyMember)
			winningValue = baseValue
		elseif result == -1 then
			for i = 1, #winnersTable do
				winnersTable[i] = nil
			end
			table.insert(winnersTable, targetPartyMember)
			winningValue = challengerValue
		else
			winningValue = baseValue
		end
	end

	return winnersTable, winningValue
end

--- Uses the following on the targetChar
--- + Osi.GetStackAmount (via Osi.GetItemByTemplateInInventory)
--- + the calculated amount won for this item stack thusfar
--- + the calculated amount won for previous items of the same template that haven't been added to the targetChar inventory yet (event hasn't been processed)
---
--- to determine the amount of the item's template that are theoretically in the given characters inventory.
---
--- If the targetChar is the inventoryHolder, will subtract the amount of the item stack being processed that has been "won" by the other party members
---@param partyMembersWithAmountWon table
---@param targetChar GUIDSTRING
---@param inventoryHolder GUIDSTRING
---@param root GUIDSTRING
---@return number totalStackSize
function ProcessorUtils.CalculateTotalItemCount(partyMembersWithAmountWon, targetChar,
												inventoryHolder, root)
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
