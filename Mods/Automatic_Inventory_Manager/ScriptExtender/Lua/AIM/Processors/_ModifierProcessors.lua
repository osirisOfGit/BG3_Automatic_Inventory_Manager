--- @module "Processors._ModifierProcessors"
ModifierProcessors = {}

--- The table that's passed to each ModifierProcessor
--- @field itemFilter being processed for the stack
--- @field eligiblePartyMembers copy of the list of party members that have been identified as eligible up to this point
--- @field targetsWithAmountWon table<GUIDSTRING, number> copy of the winners table across all filters being run for the given item - will be nil for perStack ModifierProcessors
--- @field item GUIDSTRING being sorted
--- @field currentItemStackSize as identified by the first return of Osi.GetStackAmount
--- @field root GUIDSTRING rootTemplate of the item
--- @field inventoryHolder CHARACTER
--- @table ModifierParamMap
ModifierProcessors.ParamMap = {
	itemFilter = nil,
	eligiblePartyMembers = nil,
	targetsWithAmountWon = nil,
	item = nil,
	currentItemStackSize = nil,
	root = nil,
	inventoryHolder = nil,
}


local perStackModifierProcessors = {}

-- Exclude Party Members
perStackModifierProcessors[ItemFilters.ItemFields.FilterModifiers.EXCLUDE_PARTY_MEMBERS] =
	function(partyMembersToExclude, paramMap)
		local survivors = {}
		for _, player in pairs(paramMap.eligiblePartyMembers) do
			for _, memberToExclude in pairs(partyMembersToExclude) do
				if player == memberToExclude then
					goto continue
				end
			end
			table.insert(survivors, player)
			::continue::
		end

		return survivors
	end

--- Adds a new Modifier Processor that pre-filters eligiblePartyMembers before the stack is processed.
---@param modUUID that ScriptExtender has registered for your mod, for tracking purposes - https://github.com/Norbyte/bg3se/blob/main/Docs/API.md#ismodloadedmodguid
--- will throw an error if the mod identified by that UUID is not loaded
---@param modifierKey the modifier that this processorFunction can process. Can have multiple processors for the same modifierKey
---@param processorFunction to actually process the modifier, accepting the following params:<br/>
--- 1) the value of the modifier identified by modifierKey <br/> 2) _ModifierProcessors.ParamMap
--- <br/> and return the list of party members that are eligible to continue processing. If the list is empty, or nil is returned, the
--- last known populated eligiblePartyMembers list will be used.
---@treturn boolean if the function was added successfully for the modifierKey
function ModifierProcessors:AddPerStackModifierProcessor(modUUID, modifierKey, processorFunction)
	local modName = ModUtils:GetModInfoFromUUID(modUUID)
	if not modName then return false end

	if perStackModifierProcessors[modifierKey] then
		Logger:BasicWarning(string.format("Mod %s tried to add a new modifier processor for existing modifierKey %s",
			modName,
			modifierKey))

		return false
	else
		perStackModifierProcessors[modifierKey] = processorFunction
		Logger:BasicInfo(string.format("Mod %s successfully added new perStack modifierProcesor for modifierKey %s",
			modName,
			modifierKey))
		return true
	end
end

--- Processes all modifiers that pre-filter eligiblePartyMembers before processing the stack of items
--- @param modifiers The entire Modifiers field on the ItemFilter being processed
--- @param itemFilter being processed for the stack
--- @param partyMembers the list of party members that have been identified as eligible up to this point
--- @param targetsWithAmountWon table<GUIDSTRING, number> copy of the winners table across all filters being run for the given item - will be nil for perStack ModifierProcessors
--- @param item GUIDSTRING being sorted
--- @param currentItemStackSize as identified by the first return of Osi.GetStackAmount
--- @param root GUIDSTRING rootTemplate of the item
--- @param inventoryHolder CHARACTER
--- @return the finalized list of eligible party members
function ModifierProcessors:ProcessPerStackModifiers(modifiers,
													 itemFilter,
													 partyMembers,
													 targetsWithAmountWon,
													 item,
													 currentItemStackSize,
													 root,
													 inventoryHolder)
	ModifierProcessors.ParamMap = {
		itemFilter = itemFilter,
		eligiblePartyMembers = TableUtils:MakeImmutableTableCopy(partyMembers),
		targetsWithAmountWon = targetsWithAmountWon,
		item = item,
		currentItemStackSize = currentItemStackSize,
		root = root,
		inventoryHolder = inventoryHolder,
	}

	local survivors = { table.unpack(partyMembers) }
	local modifierResult
	for modifierKey, modifierValue in pairs(modifiers) do
		if perStackModifierProcessors[modifierKey] then
			modifierResult = perStackModifierProcessors[modifierKey](modifierValue, ModifierProcessors.ParamMap)

			if not modifierResult or #modifierResult == 0 then
				if Logger:IsLogLevelEnabled(Logger.PrintTypes.DEBUG) then
					Logger:BasicDebug(string.format(
						"After processing per stack modifier %s, no party members were considered eligible, so resetting back to list state of: %s",
						modifierKey,
						Ext.Json.Stringify(survivors)))
				end
			else
				survivors = modifierResult
				if Logger:IsLogLevelEnabled(Logger.PrintTypes.DEBUG) then
					Logger:BasicDebug(string.format(
						"After processing per stack modifier %s, eligible party members are %s",
						modifierKey,
						Ext.Json.Stringify(survivors)))
				end
			end
		end
	end

	return survivors
end

local perItemModifierProcessors = {}
