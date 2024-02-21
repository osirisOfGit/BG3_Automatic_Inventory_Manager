--- @module "Processors._ProcessorUtils"

ProcessorUtils = {}

--- @param baseValue number
--- @param challengerValue number
--- @param comparator CompareStrategy
--- @return integer 0 if equal, 1 if base beats challenger, -1 if base loses to challenger
local function Compare(baseValue, challengerValue, comparator)
	if baseValue == challengerValue then
		return 0
	end

	local compareResult
	if comparator == ItemFilters.FilterFields.CompareStategy.HIGHER then
		compareResult = baseValue > challengerValue
	else
		compareResult = baseValue < challengerValue
	end

	return compareResult and 1 or -1
end

--- Calculates the winner based on the result of comparing the baseValue against the challengerValue, using the Comparator
--- to determine the nature of the compare
---@param baseValue number|nil
---@param challengerValue number
---@param comparator CompareStrategy
---@param winnersTable table
---@param targetPartyMember GUIDSTRING
---@return table of winners - will either append the targetPartyMember if the values were equal, or replace the table with just targetPartyMember if the challenger won
---@return number that won in the compare, or baseValue if both were equal
function ProcessorUtils:SetWinningVal_ByCompareResult(baseValue,
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
			for _, winner in pairs(winnersTable) do
				if winner == targetPartyMember then goto continue end
			end
		end
	end

	::continue::
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
--- @param targetsWithAmountWon table<GUIDSTRING, number>
--- @param targetChar CHARACTER
--- @param inventoryHolder CHARACTER
--- @param root GUIDSTRING
--- @param item GUIDSTRING
--- @return number the calculated stack size
function ProcessorUtils:CalculateTotalItemCount(targetsWithAmountWon,
												targetChar,
												inventoryHolder,
												root,
												item)
	Logger:BasicTrace(string.format("Calculating total count of %s in inventory of %s", root, targetChar))
	local totalFutureStackSize = targetsWithAmountWon[targetChar]

	local itemByTemplate = Osi.GetItemByTemplateInInventory(root, targetChar)
	if itemByTemplate then
		local _, templateStackSize = Osi.GetStackAmount(itemByTemplate)
		totalFutureStackSize = totalFutureStackSize + templateStackSize

		Logger:BasicDebug(string.format("Found %d of %s already in %s's inventory", templateStackSize, root,
			targetChar))
	end

	if TEMPLATES_BEING_TRANSFERRED[root] and TEMPLATES_BEING_TRANSFERRED[root][targetChar] then
		totalFutureStackSize = totalFutureStackSize + TEMPLATES_BEING_TRANSFERRED[root][targetChar]
		Logger:BasicDebug(string.format(
			"Found %d of the item currently being transferreed to %s, adding to the stack size",
			TEMPLATES_BEING_TRANSFERRED[root][targetChar],
			targetChar))
	end

	if targetChar == inventoryHolder then
		local amountToRemove = Osi.GetStackAmount(item)
		Logger:BasicDebug(string.format(
			"Brought down %s's, the inventoryHolder of the item, total item count of %d by %d", inventoryHolder,
			totalFutureStackSize, amountToRemove))
		totalFutureStackSize = totalFutureStackSize - amountToRemove
	end

	Logger:BasicDebug(string.format("Total item count for %s is %d", targetChar, totalFutureStackSize))
	return totalFutureStackSize
end
