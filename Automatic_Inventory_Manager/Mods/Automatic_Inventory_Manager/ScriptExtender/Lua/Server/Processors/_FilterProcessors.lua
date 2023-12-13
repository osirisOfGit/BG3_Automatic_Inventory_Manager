Ext.Require("Server/Processors/_ProcessorUtils.lua")

local targetStats = ItemFilters.FilterFields.TargetStat
local StatFunctions = {}

local paramMap = {}
StatFunctions[targetStats.HEALTH_PERCENTAGE] = function(partyMember)
	return ProcessorUtils:SetWinningVal_ByCompareResult(paramMap.winningVal,
		Osi.GetHitpointsPercentage(partyMember),
		paramMap.weightedFilter.CompareStategy,
		paramMap.winners,
		partyMember)
end

StatFunctions[targetStats.ARMOR_CLASS] = function(partyMember)
	return ProcessorUtils:SetWinningVal_ByCompareResult(paramMap.winningVal,
		Ext.Entity.Get(partyMember).Health.AC,
		paramMap.weightedFilter.CompareStategy,
		paramMap.winners,
		partyMember)
end

StatFunctions[targetStats.STACK_AMOUNT] = function(partyMember)
	local totalFutureStackSize = ProcessorUtils:CalculateTotalItemCount(paramMap.partyMembersWithAmountWon,
		partyMember,
		paramMap.inventoryHolder,
		paramMap.root)
	-- _P("Found " .. totalFutureStackSize .. " on " .. partyMember)

	return ProcessorUtils:SetWinningVal_ByCompareResult(paramMap.winningVal,
		totalFutureStackSize,
		paramMap.weightedFilter.CompareStategy,
		paramMap.winners,
		partyMember)
end

StatFunctions[targetStats.SKILL_TYPE] = function(partyMember)
	local skillName = tostring(Ext.Enums.SkillId[paramMap.weightedFilter.TargetSubStat])
	local skillScore = Osi.CalculatePassiveSkill(partyMember, skillName)

	return ProcessorUtils:SetWinningVal_ByCompareResult(paramMap.winningVal,
		skillScore,
		paramMap.weightedFilter.CompareStategy,
		paramMap.winners,
		partyMember)
end

StatFunctions[targetStats.ABILITY_STAT] = function(partyMember)
	return ProcessorUtils:SetWinningVal_ByCompareResult(paramMap.winningVal,
		Osi.GetAbility(partyMember, paramMap.weightedFilter.TargetSubStat),
		paramMap.weightedFilter.CompareStategy,
		paramMap.winners,
		partyMember)
end

StatFunctions[targetStats.WEAPON_SCORE] = function(partyMember)
	if Osi.IsWeapon(paramMap.item) == 0 then
		return paramMap.winners
	end

	local weaponScore = Osi.GetWeaponScoreForCharacter(paramMap.item, partyMember)
	return ProcessorUtils:SetWinningVal_ByCompareResult(paramMap.winningVal,
		weaponScore,
		paramMap.weightedFilter.CompareStategy,
		paramMap.winners,
		partyMember)
end

StatFunctions[targetStats.WEAPON_ABILITY] = function(partyMember)
	local weaponAbility = tostring(Ext.Enums.AbilityId[Ext.Entity.Get(paramMap.item).Weapon.Ability])
	local survivorAbility = Osi.GetAbility(partyMember, weaponAbility)
	-- _P(string.format("Weapon uses %s, %s has a score of %s", weaponAbility, survivor, survivorAbility))
	return ProcessorUtils:SetWinningVal_ByCompareResult(paramMap.winningVal,
		survivorAbility,
		paramMap.weightedFilter.CompareStategy,
		paramMap.winners,
		partyMember)
end

StatFunctions[targetStats.PROFICIENCY] = function(partyMember)
	if Osi.IsProficientWith(partyMember, paramMap.item) == 1 then
		table.insert(paramMap.winners, partyMember)
	end

	return paramMap.winners
end

StatFunctions[targetStats.HAS_TYPE_EQUIPPED] = function(partyMember)
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
		return paramMap.winners
	end
	--- @cast currentEquippedItem -number # dont know why the heck it would be?
	local currentEquipTypeUUID = Ext.Entity.Get(currentEquippedItem).ServerItem.Item.OriginalTemplate.EquipmentTypeID
	local paramItemTypeUUID = Ext.Entity.Get(paramMap.item).ServerItem.Item.OriginalTemplate.EquipmentTypeID

	local paramItemType = Ext.StaticData.Get(currentEquipTypeUUID, "EquipmentType")["Name"]
	local equippedItemType = Ext.StaticData.Get(paramItemTypeUUID, "EquipmentType")["Name"]
	if paramItemType == equippedItemType then
		table.insert(paramMap.winners, partyMember)
	end

	return paramMap.winners
end

FilterProcessors = {}

---Executes the provided WeightedFilter against the provided params.
--- @param weightedFilter WeightedFilter
--- @param eligiblePartyMembers CHARACTER[]
--- @param partyMembersWithAmountWon table<CHARACTER, number>
--- @param item GUIDSTRING
--- @param root GUIDSTRING
--- @param inventoryHolder CHARACTER
--- @return table winners The survivors that were eligible to receive the item, or the original survivors table if none were eligible
function FilterProcessors:ExecuteFilterAgainstEligiblePartyMembers(weightedFilter,
																   eligiblePartyMembers,
																   partyMembersWithAmountWon,
																   inventoryHolder,
																   item,
																   root)
	paramMap.winners = {}
	paramMap.winningVal = nil
	paramMap.weightedFilter = weightedFilter
	paramMap.partyMembersWithAmountWon = partyMembersWithAmountWon
	paramMap.inventoryHolder = inventoryHolder
	paramMap.item = item
	paramMap.root = root

	for _, partyMember in pairs(eligiblePartyMembers) do
		paramMap.winners, paramMap.winningVal = StatFunctions[weightedFilter.TargetStat](partyMember)
	end

	return #paramMap.winners > 0 and paramMap.winners or eligiblePartyMembers
end
