Ext.Require("Server/CriteriaProcessor/_ProcessorUtils.lua")

local StatFunctions = {}

local paramMap = {}
StatFunctions[STAT_HEALTH_PERCENTAGE] = function(partyMember)
	local health = Ext.Entity.Get(partyMember).Health
	local challengerHealthPercent = (health.Hp / health.MaxHp) * 100
	return ProcessorUtils.SetWinningVal_ByCompareResult(paramMap.winningVal,
		challengerHealthPercent,
		paramMap.currentWeightedCriteria[COMPARATOR],
		paramMap.winners,
		partyMember)
end

StatFunctions[STAT_STACK_AMOUNT] = function(partyMember)
	local totalFutureStackSize = ProcessorUtils.CalculateTotalItemCount(paramMap.partyMembersWithAmountWon,
		partyMember,
		paramMap.inventoryHolder,
		paramMap.root)
	-- _P("Found " .. totalFutureStackSize .. " on " .. partyMember)

	return ProcessorUtils.SetWinningVal_ByCompareResult(paramMap.winningVal,
		totalFutureStackSize,
		paramMap.currentWeightedCriteria[COMPARATOR],
		paramMap.winners,
		partyMember)
end

StatFunctions[STAT_SKILL] = function(partyMember)
	local skillScore = Osi.CalculatePassiveSkill(partyMember,
		tostring(Ext.Enums.SkillId[paramMap.currentWeightedCriteria[STAT_SKILL]]))

	return ProcessorUtils.SetWinningVal_ByCompareResult(paramMap.winningVal,
		skillScore,
		paramMap.currentWeightedCriteria[COMPARATOR],
		paramMap.winners,
		partyMember)
end

StatFunctions[STAT_WEAPON_SCORE] = function(partyMember)
	if Osi.IsWeapon(paramMap.item) == 0 then
		return paramMap.winners
	end

	local weaponScore = Osi.GetWeaponScoreForCharacter(paramMap.item, partyMember)
	return ProcessorUtils.SetWinningVal_ByCompareResult(paramMap.winningVal,
		weaponScore,
		paramMap.currentWeightedCriteria[COMPARATOR],
		paramMap.winners,
		partyMember)
end

StatFunctions[STAT_WEAPON_ABILITY] = function(partyMember)
	local weaponAbility = tostring(Ext.Enums.AbilityId[Ext.Entity.Get(paramMap.item).Weapon.Ability])
	local survivorAbility = Osi.GetAbility(partyMember, weaponAbility)
	-- _P(string.format("Weapon uses %s, %s has a score of %s", weaponAbility, survivor, survivorAbility))
	return ProcessorUtils.SetWinningVal_ByCompareResult(paramMap.winningVal,
		survivorAbility,
		paramMap.currentWeightedCriteria[COMPARATOR],
		paramMap.winners,
		partyMember)
end

StatFunctions[STAT_PROFICIENCY] = function(partyMember)
	if Osi.IsProficientWith(partyMember, paramMap.item) == 1 then
		table.insert(paramMap.winners, partyMember)
	end

	return paramMap.winners
end

StatFunctions[STAT_HAS_TYPE_EQUIPPED] = function(partyMember)
	local targetItemType = GetEquipmentType(paramMap.item)
	local itemSlot = tostring(Ext.Entity.Get(paramMap.item).Equipable.Slot)

	-- Getting this aligned with Osi.EQUIPMENTSLOTNAME, because, what the fuck Larian
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
	local equippedItemType = GetEquipmentType(currentEquippedItem)

	if targetItemType == equippedItemType then
		table.insert(paramMap.winners, partyMember)
	end

	return paramMap.winners
end

CriteriaProcessors = {}

---Executes the current Criteria against the provided params.
---@param currentWeightedCriteria Criteria
---@param partyMembersWithAmountWon any
---@param survivors any
---@param inventoryHolder any
---@param item any
---@param root any
---@return table winners The survivors that were eligible to receive the item, or the original survivors table if none were eligible
function CriteriaProcessors.ExecuteCriteria(currentWeightedCriteria,
											partyMembersWithAmountWon,
											survivors,
											inventoryHolder,
											item,
											root)
	paramMap.winners = {}
	paramMap.currentWeightedCriteria = currentWeightedCriteria
	paramMap.partyMembersWithAmountWon = partyMembersWithAmountWon
	paramMap.inventoryHolder = inventoryHolder
	paramMap.item = item
	paramMap.root = root

	for _, partyMember in pairs(survivors) do
		paramMap.winners, paramMap.winningVal = StatFunctions[currentWeightedCriteria[STAT]](partyMember)
	end

	return #paramMap.winners > 0 and paramMap.winners or survivors
end
