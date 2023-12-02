Ext.Require("Server/CriteriaProcessor/_ProcessorUtils.lua")

function ByHealthPercent(_, survivors, _, _, _, criteria)
	local winningVal
	local winners = {}
	for _, survivor in pairs(survivors) do
		local health = Ext.Entity.Get(survivor).Health
		local challengerHealthPercent = (health.Hp / health.MaxHp) * 100
		winningVal = SetWinningVal_ByCompareResult(winningVal, challengerHealthPercent, criteria[COMPARATOR], winners, survivor)
	end

	return winners
end

function ByStackAmount(partyMembersWithAmountWon, survivors, inventoryHolder, _, root, criteria)
	local winners = {}
	local winningVal

	for _, survivor in pairs(survivors) do
		local totalFutureStackSize = CalculateTemplateCurrentAndReservedStackSize(partyMembersWithAmountWon, survivor,
			inventoryHolder, root)
		-- _P("Found " .. totalFutureStackSize .. " on " .. partyMember)

		winningVal = SetWinningVal_ByCompareResult(winningVal, totalFutureStackSize, criteria[COMPARATOR], winners, survivor)
	end
	return winners
end

function BySkillAmount(_, survivors, _, _, _, criteria)
	local winners = {}
	local winningVal

	for _, survivor in pairs(survivors) do
		local skillScore = Osi.CalculatePassiveSkill(survivor, tostring(Ext.Enums.SkillId[criteria[STAT_SKILL]]))
		winningVal = SetWinningVal_ByCompareResult(winningVal, skillScore, criteria[COMPARATOR], winners, survivor)
	end

	return winners
end

function ByWeaponScore(_, survivors, _, item, _, criteria)
	if Osi.IsWeapon(item) == 0 then
		return survivors
	end

	local winners = {}
	local winningVal

	for _, survivor in pairs(survivors) do
		local weaponScore = Osi.GetWeaponScoreForCharacter(item, survivor)
		winningVal = SetWinningVal_ByCompareResult(winningVal, weaponScore, criteria[COMPARATOR], winners, survivor)
	end

	return winners
end

function ByWeaponAbility(_, survivors, _, item, _, criteria)
	local winners = {}
	local winningVal

	for _, survivor in pairs(survivors) do
		local weaponAbility = tostring(Ext.Enums.AbilityId[Ext.Entity.Get(item).Weapon.Ability])
		local survivorAbility = Osi.GetAbility(survivor, weaponAbility)
		-- _P(string.format("Weapon uses %s, %s has a score of %s", weaponAbility, survivor, survivorAbility))
		winningVal = SetWinningVal_ByCompareResult(winningVal, survivorAbility, criteria[COMPARATOR], winners, survivor)
	end

	return winners
end

function ByProficiency(_, survivors, _, item, _, _)
	local winners = {}

	for _, partyMember in pairs(survivors) do
		if Osi.IsProficientWith(partyMember, item) == 1 then
			table.insert(winners, partyMember)
		end
	end

	return winners
end

STAT_TO_FUNCTION_MAP = {
	[STAT_STACK_AMOUNT] = ByStackAmount,
	[STAT_HEALTH_PERCENTAGE] = ByHealthPercent,
	[STAT_PROFICIENCY] = ByProficiency,
	[STAT_SKILL] = BySkillAmount,
	[STAT_WEAPON_SCORE] = ByWeaponScore,
	[STAT_WEAPON_ABILITY] = ByWeaponAbility,
}
