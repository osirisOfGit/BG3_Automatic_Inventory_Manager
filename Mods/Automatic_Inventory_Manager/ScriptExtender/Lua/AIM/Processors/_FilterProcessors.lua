--- @module "Processors._FilterProcessors"

Ext.Require("AIM/Processors/_ProcessorUtils.lua")

local targetStats = ItemFilters.FilterFields.TargetStat
local StatFunctions = {}

StatFunctions[targetStats.HEALTH_PERCENTAGE] = function(partyMember, paramMap)
	paramMap.winners, paramMap.winningVal = ProcessorUtils:SetWinningVal_ByCompareResult(paramMap.winningVal,
		Osi.GetHitpointsPercentage(partyMember),
		paramMap.filter.CompareStategy,
		paramMap.winners,
		partyMember)
end

StatFunctions[targetStats.ARMOR_CLASS] = function(partyMember, paramMap)
	paramMap.winners, paramMap.winningVal = ProcessorUtils:SetWinningVal_ByCompareResult(paramMap.winningVal,
		Ext.Entity.Get(partyMember).Health.AC,
		paramMap.filter.CompareStategy,
		paramMap.winners,
		partyMember)
end

StatFunctions[targetStats.STACK_AMOUNT] = function(partyMember, paramMap)
	local totalFutureStackSize = ProcessorUtils:CalculateTotalItemCount(paramMap.targetsWithAmountWon,
		partyMember,
		paramMap.inventoryHolder,
		paramMap.root,
		paramMap.item)
	Logger:BasicTrace("Found " .. totalFutureStackSize .. " on " .. partyMember)

	paramMap.winners, paramMap.winningVal = ProcessorUtils:SetWinningVal_ByCompareResult(paramMap.winningVal,
		totalFutureStackSize,
		paramMap.filter.CompareStategy,
		paramMap.winners,
		partyMember)
end

StatFunctions[targetStats.SKILL_TYPE] = function(partyMember, paramMap)
	local skillName = tostring(Ext.Enums.SkillId[paramMap.filter.TargetSubStat])
	local skillScore = Osi.CalculatePassiveSkill(partyMember, skillName)

	paramMap.winners, paramMap.winningVal = ProcessorUtils:SetWinningVal_ByCompareResult(paramMap.winningVal,
		skillScore,
		paramMap.filter.CompareStategy,
		paramMap.winners,
		partyMember)
end

StatFunctions[targetStats.ABILITY_STAT] = function(partyMember, paramMap)
	paramMap.winners, paramMap.winningVal = ProcessorUtils:SetWinningVal_ByCompareResult(paramMap.winningVal,
		Osi.GetAbility(partyMember, paramMap.filter.TargetSubStat),
		paramMap.filter.CompareStategy,
		paramMap.winners,
		partyMember)
end

StatFunctions[targetStats.WEAPON_SCORE] = function(partyMember, paramMap)
	if Osi.IsWeapon(paramMap.item) ~= 1 then
		Logger:BasicTrace("Item " .. paramMap.item .. " is not a weapon according to Osi!")
		return
	end

	local weaponScore = Osi.GetWeaponScoreForCharacter(paramMap.item, partyMember)
	paramMap.winners, paramMap.winningVal = ProcessorUtils:SetWinningVal_ByCompareResult(paramMap.winningVal,
		weaponScore,
		paramMap.filter.CompareStategy,
		paramMap.winners,
		partyMember)
end

StatFunctions[targetStats.WEAPON_ABILITY] = function(partyMember, paramMap)
	local weaponAbility = tostring(Ext.Enums.AbilityId[Ext.Entity.Get(paramMap.item).Weapon.Ability])
	local partyMemberAbilityScore = Osi.GetAbility(partyMember, weaponAbility)
	Logger:BasicTrace(string.format("Weapon uses %s, %s has a score of %s", weaponAbility, partyMember,
		partyMemberAbilityScore))
	paramMap.winners, paramMap.winningVal = ProcessorUtils:SetWinningVal_ByCompareResult(paramMap.winningVal,
		partyMemberAbilityScore,
		paramMap.filter.CompareStategy,
		paramMap.winners,
		partyMember)
end

StatFunctions[targetStats.PROFICIENCY] = function(partyMember, paramMap)
	if Osi.IsProficientWith(partyMember, paramMap.item) == 1 then
		table.insert(paramMap.winners, partyMember)
	end
end

StatFunctions[targetStats.HAS_TYPE_EQUIPPED] = function(partyMember, paramMap)
	local itemSlot = tostring(Ext.Entity.Get(paramMap.item).Equipable.Slot)

	-- Getting this aligned with Osi.EQUIPMENTSLOTNAME, because, what the heck Larian (╯°□°）╯︵ ┻━┻
	if itemSlot == Ext.Enums.StatsItemSlot[Ext.Enums.StatsItemSlot.MeleeMainHand] then
		itemSlot = "Melee Main Weapon"
	elseif itemSlot == Ext.Enums.StatsItemSlot[Ext.Enums.StatsItemSlot.MeleeOffHand] then
		itemSlot = "Melee Offhand Weapon"
	elseif itemSlot == Ext.Enums.StatsItemSlot[Ext.Enums.StatsItemSlot.RangedMainHand] then
		itemSlot = "Ranged Main Weapon"
	elseif itemSlot == Ext.Enums.StatsItemSlot[Ext.Enums.StatsItemSlot.RangedOffHand] then
		itemSlot = "Ranged Offhand Weapon"
	end

	local currentEquippedItem = Osi.GetEquippedItem(partyMember, itemSlot)
	if not currentEquippedItem then
		return
	end
	--- @cast currentEquippedItem -number # dont know why the heck it would be?
	local currentEquipTypeUUID = Ext.Entity.Get(currentEquippedItem).ServerItem.OriginalTemplate.EquipmentTypeID
	local paramItemTypeUUID = Ext.Entity.Get(paramMap.item).ServerItem.OriginalTemplate.EquipmentTypeID

	local paramItemType = Ext.StaticData.Get(currentEquipTypeUUID, "EquipmentType")["Name"]
	local equippedItemType = Ext.StaticData.Get(paramItemTypeUUID, "EquipmentType")["Name"]
	if paramItemType == equippedItemType then
		table.insert(paramMap.winners, partyMember)
	end
end


FilterProcessor = {}

--- Adds the provided stat functions to the list of possible functions, using the key as the criteria
---@param statFunctions table<TargetStat|string, function<CHARACTER, FilterParamMap>>
function FilterProcessor:AddStatFunctions(statFunctions)
	for targetStat, statFunction in pairs(statFunctions) do
		StatFunctions[targetStat] = statFunction
	end
end

local filterProcessors = {}

filterProcessors[function(filter)
	return filter["Target"] ~= nil
end] = function(partyMember, paramMap)
	local target = paramMap.filter.Target

	if target then
		if string.lower(target) == "camp" then
			paramMap.winners = { "camp" }
		elseif string.lower(target) == "originaltarget" then
			paramMap.winners = { paramMap.inventoryHolder }
		elseif Osi.IsPlayer(target) == 1 then
			local filterIgnoresEligibility = paramMap.filter["RespectEligibility"] or "false"

			if target == partyMember or string.lower(filterIgnoresEligibility) == "false" then
				paramMap.winners = { target }
			end
		elseif (Osi.Exists(target) == 1 and Osi.IsContainer(target) == 1) then
			paramMap.winners = { target }
		else
			error(string.format(
				"The target %s was specified for item %s but they are not a valid target!"
				, target
				, paramMap.item), 2)
		end
	else
		error("A Target was not provided despite using TargetFilter for item " .. paramMap.item, 2)
	end
end

filterProcessors[function(filter)
	return filter["TargetStat"] ~= nil and filter["CompareStategy"] ~= nil
end] = function(partyMember, paramMap)
	StatFunctions[paramMap.filter["TargetStat"]](partyMember, paramMap)
end

--- Add a new filter processor -
---@param predicateFunction function(Filter, boolean) Should test the filter to see if the filterProcessor can process it, returning true if
---@param filterProcessor function(CHARACTER, ParamMap) proceses the filter against the provided character, setting ParamMap.winners and optionally ParamMap.winningVal
function FilterProcessor:AddNewFilterProcessor(predicateFunction, filterProcessor)
	filterProcessors[predicateFunction] = filterProcessor
end

--- The table that's passed to each FilterProcessor
--- @field winners GUIDSTRING[] List of targets that pass the filter - should be set by the FilterProcessor
--- @field winningVal any value identified by the filter that is currently the victor across all partyMembers
--- @field targetsWithAmountWon table<GUIDSTRING, number> copy of the winners table across all filters being run for the given item
--- @field filter the single filter being evaluated, such as a Compare or TargetFilter
--- @field prefilters associated with the ItemFilter
--- @field customItemFilterFields any fields that aren't FILTERS or PREFILTERS that were found on the ItemFilter
--- @field item GUIDSTRING being sorted
--- @field root GUIDSTRING rootTemplate of the item
--- @field inventoryHolder CHARACTER
--- @table FilterParamMap
FilterProcessor.ParamMap = {
	winners = nil,
	winningVal = nil,
	filter = nil,
	prefilters = nil,
	customItemFilterFields = nil,
	inventoryHolder = nil,
	item = nil,
	root = nil,
	targetsWithAmountWon = nil,
}

--- Executes the provided Filter against the provided params. Any exceptions will be logged, swallowed, and whatever the value of the winners table was at exception time will be returned
--- @param filter the single filter being evaluated, such as a Compare or TargetFilter
--- @param prefilters associated with the ItemFilter
--- @param customItemFilterFields any fields that aren't FILTERS or PREFILTERS that were found on the ItemFilter
--- @param eligiblePartyMembers GUIDSTRING[]
--- @param targetsWithAmountWon table<GUIDSTRING, number>
--- @param inventoryHolder CHARACTER
--- @param item GUIDSTRING
--- @param root GUIDSTRING
--- @return table winners The survivors that were eligible to receive the item, or the original survivors table if none were eligible
function FilterProcessor:ExecuteFilterAgainstEligiblePartyMembers(filter,
																  prefilters,
																  customItemFilterFields,
																  eligiblePartyMembers,
																  targetsWithAmountWon,
																  inventoryHolder,
																  item,
																  root)
	FilterProcessor.ParamMap = {
		winners = {},
		winningVal = nil,
		filter = filter,
		prefilters = prefilters,
		customItemFilterFields = customItemFilterFields,
		inventoryHolder = inventoryHolder,
		item = item,
		root = root,
		targetsWithAmountWon = TableUtils:DeeplyCopyTable(targetsWithAmountWon),
	}

	local success, errorResponse = pcall(function()
		for predicate, filterProcessor in pairs(filterProcessors) do
			if predicate(filter) then
				for _, partyMember in pairs(eligiblePartyMembers) do
					filterProcessor(partyMember, FilterProcessor.ParamMap)
				end
			end
		end
	end)

	if not success then
		Logger:BasicError(string.format("Got error while attempting to process filter with paramMap %s: %s",
			Ext.Json.Stringify(FilterProcessor.ParamMap), errorResponse))
	end
	if Logger:IsLogLevelEnabled(Logger.PrintTypes.TRACE) then
		Logger:BasicTrace(string.format("FilterProcessor finished iteration - param map is %s",
			Ext.Json.Stringify(FilterProcessor.ParamMap)))
	end

	return #FilterProcessor.ParamMap.winners > 0 and FilterProcessor.ParamMap.winners or eligiblePartyMembers
end
