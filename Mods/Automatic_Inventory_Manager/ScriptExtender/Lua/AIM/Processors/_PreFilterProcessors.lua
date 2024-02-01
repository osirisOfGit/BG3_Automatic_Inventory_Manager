--- @module "Processors._PreFilterProcessors"
PreFilterProcessors = {}

--- The table that's passed to each PreFilterProcessor
--- @field itemFilter being processed for the stack
--- @field eligiblePartyMembers copy of the list of party members that have been identified as eligible up to this point
--- @field targetsWithAmountWon table<GUIDSTRING, number> copy of the winners table across all filters being run for the given item - will be nil for perStack PreFilterProcessors
--- @field item GUIDSTRING being sorted
--- @field currentItemStackSize as identified by the first return of Osi.GetStackAmount
--- @field root GUIDSTRING rootTemplate of the item
--- @field inventoryHolder CHARACTER
--- @table PreFilterParamMap
PreFilterProcessors.ParamMap = {
	itemFilter = nil,
	eligiblePartyMembers = nil,
	targetsWithAmountWon = nil,
	item = nil,
	currentItemStackSize = nil,
	root = nil,
	inventoryHolder = nil,
}

local perStackPreFilterProcessors = {}

-- Exclude Party Members
perStackPreFilterProcessors[ItemFilters.ItemFields.PreFilters.EXCLUDE_PARTY_MEMBERS] =
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

--- Adds a new PreFilter Processor that pre-filters eligiblePartyMembers before the stack is processed.
---@param modUUID that ScriptExtender has registered for your mod, for tracking purposes - <a href="https://github.com/Norbyte/bg3se/blob/main/Docs/API.md#ismodloadedmodguid">Norbyte/bg3se/blob/main/Docs/API.md#ismodloadedmodguid</a>
--- will throw an error if the mod identified by that UUID is not loaded
---@param preFilterKey the prefilter that this processorFunction can process.
---@param processorFunction to actually process the prefilter, accepting the following params:<br/>
--- 1) the value of the prefilter identified by prefilterKey <br/> 2) _PreFilterProcessors.ParamMap
--- <br/> and return the list of party members that are eligible to continue processing. If the list is empty, or nil is returned, the
--- last known populated eligiblePartyMembers list will be used.
---@treturn boolean if the function was added successfully for the prefilterKey
function PreFilterProcessors:AddPerStackPreFilterProcessor(modUUID, preFilterKey, processorFunction)
	local modName = ModUtils:GetModInfoFromUUID(modUUID).Name

	if perStackPreFilterProcessors[preFilterKey] then
		Logger:BasicWarning(string.format("Mod %s tried to add a new prefilter processor for existing prefilterKey %s",
			modName,
			preFilterKey))

		return false
	else
		perStackPreFilterProcessors[preFilterKey] = processorFunction
		Logger:BasicInfo(string.format("Mod %s successfully added new perStack prefilterProcesor for prefilterKey %s",
			modName,
			preFilterKey))
		return true
	end
end

--- Processes all prefilters that pre-filter eligiblePartyMembers before processing the stack of items
--- @param prefilters The entire PreFilters field on the ItemFilter being processed
--- @param itemFilter being processed for the stack
--- @param partyMembers the list of party members that have been identified as eligible up to this point
--- @param item GUIDSTRING being sorted
--- @param currentItemStackSize as identified by the first return of Osi.GetStackAmount
--- @param root GUIDSTRING rootTemplate of the item
--- @param inventoryHolder CHARACTER
--- @return the finalized list of eligible party members
function PreFilterProcessors:ProcessPerStackPreFilters(prefilters,
													   itemFilter,
													   partyMembers,
													   item,
													   currentItemStackSize,
													   root,
													   inventoryHolder)
	PreFilterProcessors.ParamMap = {
		itemFilter = itemFilter,
		eligiblePartyMembers = TableUtils:MakeImmutableTableCopy(partyMembers),
		targetsWithAmountWon = nil,
		item = item,
		currentItemStackSize = currentItemStackSize,
		root = root,
		inventoryHolder = inventoryHolder,
	}

	local survivors = { table.unpack(partyMembers) }
	local prefilterResult
	for prefilterKey, prefilterValue in pairs(prefilters) do
		if perStackPreFilterProcessors[prefilterKey] then
			prefilterResult = perStackPreFilterProcessors[prefilterKey](prefilterValue, PreFilterProcessors.ParamMap)

			if not prefilterResult or #prefilterResult == 0 then
				if Logger:IsLogLevelEnabled(Logger.PrintTypes.DEBUG) then
					Logger:BasicDebug(string.format(
						"After processing per-stack PreFilter %s, no party members were considered eligible, so resetting back to list state of: %s",
						prefilterKey,
						Ext.Json.Stringify(survivors)))
				end
			else
				survivors = prefilterResult
				if Logger:IsLogLevelEnabled(Logger.PrintTypes.DEBUG) then
					Logger:BasicDebug(string.format(
						"After processing per-stack PreFilter %s, eligible party members are %s",
						prefilterKey,
						Ext.Json.Stringify(survivors)))
				end
			end
		end
	end

	return survivors
end

local perItemPreFilterProcessors = {}
-- STACK_LIMIT
perItemPreFilterProcessors[ItemFilters.ItemFields.PreFilters.STACK_LIMIT] = function(stackLimit, paramMap)
	local filteredSurvivors = {}
	for _, partyMember in pairs(paramMap.eligiblePartyMembers) do
		local totalFutureStackSize = ProcessorUtils:CalculateTotalItemCount(
			paramMap.targetsWithAmountWon, partyMember, paramMap.inventoryHolder, paramMap.root, paramMap.item)

		Logger:BasicTrace(string.format("Found %d on %s, against stack limit %d",
			totalFutureStackSize,
			partyMember,
			stackLimit))

		if totalFutureStackSize < stackLimit then
			table.insert(filteredSurvivors, partyMember)
		end
	end

	return #filteredSurvivors > 0 and filteredSurvivors or nil
end

perItemPreFilterProcessors[ItemFilters.ItemFields.PreFilters.ENCUMBRANCE] = function(_, paramMap)
	local filteredSurvivors = {}
	local itemWeight = tonumber(Ext.Entity.Get(paramMap.item).Data.Weight)

	for _, partyMember in pairs(paramMap.eligiblePartyMembers) do
		local partyMemberEntity = Ext.Entity.Get(partyMember)
		-- If not encumbered
		if tonumber(partyMemberEntity.EncumbranceState.State) == 0 then
			local unencumberedLimit = tonumber(partyMemberEntity.EncumbranceStats.UnencumberedWeight)
			local inventoryWeight = tonumber(partyMemberEntity.InventoryWeight["Weight"])
			if (inventoryWeight + itemWeight) <= unencumberedLimit then
				Logger:BasicTrace(string.format("Item weight %d will not encumber %s, with %d more room!",
					itemWeight,
					partyMember,
					unencumberedLimit - (inventoryWeight + itemWeight)))
				table.insert(filteredSurvivors, partyMember)
			end
		end
	end

	return #filteredSurvivors > 0 and filteredSurvivors or nil
end

--- Adds a new PreFilter Processor that pre-filters eligiblePartyMembers before each item in the stack is processed by the filters
---@param modUUID that ScriptExtender has registered for your mod, for tracking purposes - https://github.com/Norbyte/bg3se/blob/main/Docs/API.md#ismodloadedmodguid
--- will throw an error if the mod identified by that UUID is not loaded
---@param preFilterKey the prefilter that this processorFunction can process.
---@param processorFunction to actually process the prefilter, accepting the following params:<br/>
--- 1) the value of the prefilter identified by prefilterKey <br/> 2) _PreFilterProcessors.ParamMap
--- <br/> and return the list of party members that are eligible to continue processing. If the list is empty, or nil is returned, the
--- last known populated eligiblePartyMembers list will be used.
---@treturn boolean if the function was added successfully for the prefilterKey
function PreFilterProcessors:AddPerItemPreFilterProcessor(modUUID, preFilterKey, processorFunction)
	local modName = ModUtils:GetModInfoFromUUID(modUUID).Name

	if perItemPreFilterProcessors[preFilterKey] then
		Logger:BasicWarning(string.format("Mod %s tried to add a new prefilter processor for existing prefilterKey %s",
			modName,
			preFilterKey))

		return false
	else
		perItemPreFilterProcessors[preFilterKey] = processorFunction
		Logger:BasicInfo(string.format("Mod %s successfully added new perStack prefilterProcesor for prefilterKey %s",
			modName,
			preFilterKey))
		return true
	end
end

--- Processes all prefilters that pre-filter eligiblePartyMembers before processing each item in a stack
--- @param prefilters The entire PreFilters field on the ItemFilter being processed
--- @param itemFilter being processed for the stack
--- @param partyMembers the list of party members that have been identified as eligible up to this point for this item in the stack
--- @param targetsWithAmountWon table<GUIDSTRING, number> copy of the winners table across all filters being run for the given item
--- @param item GUIDSTRING being sorted
--- @param currentItemStackSize as identified by the first return of Osi.GetStackAmount
--- @param root GUIDSTRING rootTemplate of the item
--- @param inventoryHolder CHARACTER
--- @return the finalized list of eligible party members
function PreFilterProcessors:ProcessPerItemPreFilters(prefilters,
													  itemFilter,
													  partyMembers,
													  targetsWithAmountWon,
													  item,
													  currentItemStackSize,
													  root,
													  inventoryHolder)
	PreFilterProcessors.ParamMap = {
		itemFilter = itemFilter,
		eligiblePartyMembers = TableUtils:MakeImmutableTableCopy(partyMembers),
		targetsWithAmountWon = targetsWithAmountWon,
		item = item,
		currentItemStackSize = currentItemStackSize,
		root = root,
		inventoryHolder = inventoryHolder,
	}

	local survivors = { table.unpack(partyMembers) }
	local prefilterResult
	for prefilterKey, prefilterValue in pairs(prefilters) do
		if perItemPreFilterProcessors[prefilterKey] then
			prefilterResult = perItemPreFilterProcessors[prefilterKey](prefilterValue, PreFilterProcessors.ParamMap)

			if not prefilterResult or #prefilterResult == 0 then
				if Logger:IsLogLevelEnabled(Logger.PrintTypes.DEBUG) then
					Logger:BasicDebug(string.format(
						"After processing per-item PreFilter %s, no party members were considered eligible, so resetting back to list state of: %s",
						prefilterKey,
						Ext.Json.Stringify(survivors)))
				end
			else
				survivors = prefilterResult
				if Logger:IsLogLevelEnabled(Logger.PrintTypes.DEBUG) then
					Logger:BasicDebug(string.format(
						"After processing per-item PreFilter %s, eligible party members are %s",
						prefilterKey,
						Ext.Json.Stringify(survivors)))
				end
			end
		end
	end

	return survivors
end
