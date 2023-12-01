Ext.Require("Server/CriteriaProcessor/_ProcessorUtils.lua")

function GetTargetByHealthPercent(_, survivors, _, _, _, criteria)
	local winningHealthPercent
	local winners = {}
	for _, targetChar in pairs(survivors) do
		local health = Ext.Entity.Get(targetChar).Health
		local challengerHealthPercent = (health.Hp / health.MaxHp) * 100
		if winningHealthPercent then
			local result = Compare(winningHealthPercent, challengerHealthPercent,
				criteria[COMPARATOR])
			if result == 0 then
				table.insert(winners, targetChar)
			elseif result == -1 then
				winners = { targetChar }
				winningHealthPercent = challengerHealthPercent
			end
		else
			winningHealthPercent = challengerHealthPercent
			table.insert(winners, targetChar)
		end
	end

	return winners
end

function GetTargetByStackAmount(partyMembersWithAmountWon, survivors, inventoryHolder, _, root, criteria)
	local winners = {}
	local winningVal

	for _, targetChar in pairs(survivors) do
		local totalFutureStackSize = CalculateTemplateCurrentAndReservedStackSize(partyMembersWithAmountWon, targetChar,
			inventoryHolder, root)
		-- _P("Found " .. totalFutureStackSize .. " on " .. targetChar)

		if not winningVal then
			winningVal = totalFutureStackSize
			table.insert(winners, targetChar)
		else
			local result = Compare(winningVal, totalFutureStackSize,
				criteria[COMPARATOR])
			if result == 0 then
				table.insert(winners, targetChar)
			elseif result == -1 then
				winners = { targetChar }
				winningVal = totalFutureStackSize
			end
		end
	end
	return winners
end

STAT_TO_FUNCTION_MAP = {
	[STAT_STACK_AMOUNT] = GetTargetByStackAmount,
	[STAT_HEALTH_PERCENTAGE] = GetTargetByHealthPercent
}
