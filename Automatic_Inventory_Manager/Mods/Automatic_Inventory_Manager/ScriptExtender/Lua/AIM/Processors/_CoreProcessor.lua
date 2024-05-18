--- @module "Processors._CoreProcessor"

Ext.Require("AIM/Processors/_FilterProcessors.lua")
Ext.Require("AIM/Processors/_PreFilterProcessors.lua")

--- Distributes the item stack according to the winners of the processed filters
--- @param partyMembersWithAmountWon table<CHARACTER, number>
--- @param item GUIDSTRING
--- @param root GUIDSTRING
--- @param inventoryHolder CHARACTER
local function ProcessWinners(partyMembersWithAmountWon, item, root, inventoryHolder)
	Osi.SetTag(item, TAG_AIM_PROCESSED)
	if Logger:IsLogLevelEnabled(Logger.PrintTypes.DEBUG) then
		Logger:BasicDebug("Final results are: " .. Ext.Json.Stringify(partyMembersWithAmountWon))
	end
	for target, amount in pairs(partyMembersWithAmountWon) do
		if amount > 0 then
			if target == inventoryHolder then
				Logger:BasicInfo("Target %s was determined to be inventoryHolder for %d of %s"
				, inventoryHolder
				, amount
				, item)
			elseif target == "camp" then
				Osi.SendToCampChest(item, inventoryHolder)
				Logger:BasicInfo("Moved %s of %s to CAMP from %s"
				, amount
				, item
				, inventoryHolder)
			else
				Osi.SetOriginalOwner(item, inventoryHolder)

				-- This method generates a new uuid for the item upon moving it without forcing us to destroy it and generate a new one from the template
				-- Need to make sure we don't clear the original owner here so our tracker logic in itemEvents knows
				Osi.ToInventory(item, target, amount, 0, 0)

				if not TEMPLATES_BEING_TRANSFERRED[root] then
					TEMPLATES_BEING_TRANSFERRED[root] = { [target] = amount }
				else
					TableUtils:AddItemToTable_AddingToExistingAmount(TEMPLATES_BEING_TRANSFERRED[root], target, amount)
				end

				Logger:BasicInfo("Moved %s of %s to %s from %s"
				, amount
				, item
				, target
				, inventoryHolder)
			end
		end
	end
end

Processor = {}

--- Processes the filters on the given params, moving the item(s) to the identified targets after all items in the stack have been processed
---@param item GUIDSTRING
---@param root GUIDSTRING
---@param inventoryHolder CHARACTER
---@param itemFilter ItemFilter
function Processor:ProcessFiltersForItemAgainstParty(item, root, inventoryHolder, itemFilter)
	local targetsWithAmountWon = {}
	local currentItemStackSize = Osi.GetStackAmount(item)
	local partyMembers = {}

	if (#Osi.DB_Players:Get(nil) <= 1) then
		Logger:BasicDebug("The party has one or fewer members - skipping processing")
		return
	end

	for _, player in pairs(Osi.DB_Players:Get(nil)) do
		table.insert(partyMembers, player[1])
	end

	partyMembers = PreFilterProcessors:ProcessPerStackPreFilters(itemFilter.PreFilters,
		itemFilter,
		partyMembers,
		item,
		currentItemStackSize,
		root,
		inventoryHolder)

	for _, partyMember in pairs(partyMembers) do
		targetsWithAmountWon[partyMember] = 0
	end

	local customItemFilterFields = {}
	for key, val in pairs(itemFilter) do
		local loweredKey = string.lower(key)
		if loweredKey ~= "filters" and loweredKey ~= "prefilters" then
			customItemFilterFields[key] = val
		end
	end

	itemFilter.PreFilters[ItemFilters.ItemFields.PreFilters.ENCUMBRANCE] = ""

	local numberOfFiltersToProcess = #itemFilter.Filters
	for _ = 1, currentItemStackSize do
		local eligiblePartyMembers = PreFilterProcessors:ProcessPerItemPreFilters(itemFilter.PreFilters,
			itemFilter,
			partyMembers,
			targetsWithAmountWon,
			item,
			currentItemStackSize,
			root,
			inventoryHolder)

		for i, filter in ipairs(itemFilter.Filters) do
			eligiblePartyMembers = FilterProcessor:ExecuteFilterAgainstEligiblePartyMembers(filter,
				itemFilter.PreFilters,
				customItemFilterFields,
				eligiblePartyMembers,
				targetsWithAmountWon,
				inventoryHolder,
				item,
				root)

			if #eligiblePartyMembers == 1 or i == numberOfFiltersToProcess then
				local target
				if #eligiblePartyMembers > 0 then
					target = #eligiblePartyMembers == 1 and eligiblePartyMembers[1] or
						eligiblePartyMembers[Osi.Random(#eligiblePartyMembers) + 1]
				else
					target = targetsWithAmountWon[Osi.Random(#targetsWithAmountWon) + 1]
				end

				TableUtils:AddItemToTable_AddingToExistingAmount(targetsWithAmountWon, target, 1)
				if Logger:IsLogLevelEnabled(Logger.PrintTypes.DEBUG) then
					Logger:BasicDebug("Chose winner %s, new winners table is:\n%s",
						target,
						Ext.Json.Stringify(targetsWithAmountWon))
				end

				if Logger:IsLogLevelEnabled(Logger.PrintTypes.TRACE) then
					Logger:BasicTrace("Winning command: %s", Ext.Json.Stringify(filter))
				end
				break
			end
		end
	end

	ProcessWinners(targetsWithAmountWon, item, root, inventoryHolder)
end
