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
	if comparator == ItemFilters.FilterFields.CompareStrategy.HIGHER then
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

local validStackCriteriaKeys = {
	["TAGS"] = function(itemInInventory, tagsToCompare, _)
		for _, tagUUID in pairs(Ext.Entity.Get(itemInInventory).Tag.Tags) do
			for _, tagToCompare in pairs(tagsToCompare) do
				local tagTable = Ext.StaticData.Get(tagUUID, "Tag")
				if tagTable and string.upper(tagToCompare) == string.upper(tagTable["Name"]) then
					return true
				end
			end
		end
		return false
	end,
	["ROOTS"] = function(item, rootsToCompare, originalItem)
		for _, rootToCompare in pairs(rootsToCompare) do
			local itemRoot = Osi.GetTemplate(item)
			if itemRoot == Osi.GetTemplate(originalItem) then
				return true
			elseif string.find(itemRoot, rootToCompare) then
				return true
			end
		end
		return false
	end,
	["EQUIPMENT_TYPES"] = function(item, equipmentToCompareList, originalItem)
		if Osi.IsEquipable(item) == 1 then
			local equipTypeId = Ext.Entity.Get(item).ServerItem.Template.EquipmentTypeID
			if equipTypeId ~= "00000000-0000-0000-0000-000000000000" then
				local equipType = Ext.StaticData.Get(equipTypeId, "EquipmentType")
				for _, equipmentToCompare in pairs(equipmentToCompareList) do
					equipmentToCompare = string.upper(equipmentToCompare)
					if equipType then
						equipType = string.upper(equipType["Name"])
						if equipmentToCompare == "SELF" then
							local originalItemEquipTypeId = Ext.Entity.Get(originalItem).ServerItem.Template.EquipmentTypeID
							if Osi.IsEquipable(originalItem) and originalItemEquipTypeId ~= "00000000-0000-0000-0000-000000000000" then
								local originalItemEquipType = Ext.StaticData.Get(originalItemEquipTypeId, "EquipmentType")["Name"]
								if originalItemEquipType and string.upper(originalItemEquipType) == equipType then
									return true
								end
							end
						elseif equipmentToCompare == equipType then
							return true
						end
					end
				end
			end
		end
	end,

	["ARMOR_TYPES"] = function(item, armorToCompareList, originalItem)
		local itemArmor = Ext.Entity.Get(item).Armor
		if itemArmor then
			for _, armorToCompare in pairs(armorToCompareList) do
				armorToCompare = string.upper(armorToCompare)
				local armorType = tostring(Ext.Enums.ArmorType[itemArmor.ArmorType])
				if armorType then
					armorType = string.upper(tostring(armorType))
					if armorToCompare == "SELF" then
						local originalItemArmor = Ext.Entity.Get(originalItem).Armor
						if originalItemArmor then
							local originalArmorType = tostring(Ext.Enums.ArmorType[originalItemArmor.ArmorType])
							if originalArmorType and string.upper(originalArmorType) == armorType then
								return true
							end
						end
					elseif armorToCompare == armorType then
						return true
					end
				end
			end
		end
	end
};

--- Adds the provided customStackAmountCalculator functions to the list of possible functions, using the key as the criteria
--- If the target key(s) identified already has a processor associated, ignore the provided one and continue
---@param modUUID that ScriptExtender has registered for your mod, for tracking purposes - <a href="https://github.com/Norbyte/bg3se/blob/main/Docs/API.md#ismodloadedmodguid">https://github.com/Norbyte/bg3se/blob/main/Docs/API.md#ismodloadedmodguid</a>
---@param customStackCalculatorPairs table of [string] = function(itemInInventory, valuesForKeyToCompare[], originalItem)
function ProcessorUtils:RegisterCustomStackCalculator(modUUID, customStackCalculatorPairs)
	local modName = ModUtils:GetModInfoFromUUID(modUUID).Name
	for key, calculatorFunction in pairs(customStackCalculatorPairs) do
		if not validStackCriteriaKeys[key] then
			validStackCriteriaKeys[key] = calculatorFunction

			Logger:BasicInfo("Mod %s successfully added new customStackAmountCalculator function for %s",
				modName,
				key)
		else
			Logger:BasicWarning("Mod %s tried to add a new customStackAmountCalculator for existing targetStat %s",
				modName,
				key)
		end
	end
end

-- Function to deep iterate through the inventory and store items in a table, with depth limit
-- Credit to SwissFred57 in Larian Discord for the initial code
local function DeepIterateInventory(container, calculateStackUsing, originalItem, itemAmount, depth)
	itemAmount = itemAmount or 0
	depth = depth or 0

	if depth > 4 then
		Logger:BasicTrace("DeepIterateInventory: Reached max depth")
		return itemAmount
	end

	local entity = Ext.Entity.Get(container)
	if not entity or not entity.InventoryOwner then
		Logger:BasicTrace("DeepIterateInventory: Entity %s does not have an inventory", container)
		return itemAmount
	end

	local primaryInventory = entity.InventoryOwner.PrimaryInventory
	if not primaryInventory or not primaryInventory.InventoryContainer then
		Logger:BasicTrace("DeepIterateInventory: Entity %s does not have an inventory", container)
		return itemAmount
	end

	for _, item in pairs(primaryInventory.InventoryContainer.Items) do
		local uuid = item.Item.Uuid.EntityUuid
		local rootTemplate = Osi.GetTemplate(uuid)
		local isContainer = Osi.IsContainer(uuid)

		if ItemBlackList:IsItemOrTemplateInBlacklist(item, rootTemplate) then
			Logger:BasicTrace("Item %s is in the blacklist - excluding from Stack calculation", string.sub(rootTemplate, 0, -36) .. uuid)
			goto continueItemLoop
		end

		local _, totalAmount = Osi.GetStackAmount(uuid)

		for key, value in pairs(calculateStackUsing) do
			if not validStackCriteriaKeys[string.upper(key)] then
				Logger:BasicWarning("calculateStackUsing key %s is not valid - ignoring it!", key)
				goto continue
			end
			if type(value) ~= "table" then
				value = { value }
			end
			if validStackCriteriaKeys[string.upper(key)](uuid, value, originalItem) then
				itemAmount = itemAmount + totalAmount
				Logger:BasicDebug("Item %s had its stack amount of %d added due to %s predicate passing", string.sub(rootTemplate, 0, -36) .. uuid, totalAmount, key, value)
				break
			end
			::continue::
		end

		if isContainer == 1 then
			if Config.AIM.RESPECT_CONTAINER_BLACKLIST_FOR_CUSTOM_STACK_CALCULATIONS == 1 and ItemBlackList:IsContainerInBlacklist(uuid) then
				Logger:BasicTrace("Container %s is in the blacklist - will exclude all of its items from stack amount calculation", uuid)
			else
				itemAmount = DeepIterateInventory(uuid, calculateStackUsing, originalItem, itemAmount, depth + 1)
			end
		end

		::continueItemLoop::
	end

	-- Return the total count
	return itemAmount
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
--- @param calculateStackUsing table
--- @return number the calculated stack size
function ProcessorUtils:CalculateTotalItemCount(targetsWithAmountWon,
												targetChar,
												inventoryHolder,
												root,
												item,
												calculateStackUsing)
	Logger:BasicTrace("Calculating total count in inventory of %s", targetChar)
	local totalFutureStackSize = targetsWithAmountWon[targetChar]

	if not calculateStackUsing or not next(calculateStackUsing) then
		local itemByTemplate = Osi.GetItemByTemplateInInventory(root, targetChar)
		if itemByTemplate then
			local _, templateStackSize = Osi.GetStackAmount(itemByTemplate)
			totalFutureStackSize = totalFutureStackSize + templateStackSize

			Logger:BasicTrace("Found %d already in %s's inventory", templateStackSize, targetChar)
		end
	else
		local calculatedStackSize = DeepIterateInventory(targetChar, calculateStackUsing, item)
		Logger:BasicTrace("Found %d relevant items already in %s's inventory, based on the custom CalculateStackUsing criteria", calculatedStackSize, targetChar)
		totalFutureStackSize = totalFutureStackSize + calculatedStackSize
	end

	if TEMPLATES_BEING_TRANSFERRED[root] and TEMPLATES_BEING_TRANSFERRED[root][targetChar] then
		totalFutureStackSize = totalFutureStackSize + TEMPLATES_BEING_TRANSFERRED[root][targetChar]
		Logger:BasicDebug(
			"Found %d of the item currently being transferred to %s, adding to the stack size",
			TEMPLATES_BEING_TRANSFERRED[root][targetChar],
			targetChar)
	end

	if targetChar == inventoryHolder then
		local amountToRemove = Osi.GetStackAmount(item)
		Logger:BasicDebug(
			"Brought down %s's, the inventoryHolder of the item, total item count of %d by %d", inventoryHolder,
			totalFutureStackSize, amountToRemove)
		totalFutureStackSize = totalFutureStackSize - amountToRemove
	end

	Logger:BasicDebug("Total item count for %s is %d", targetChar, totalFutureStackSize)
	return totalFutureStackSize
end
