function ProcessCommand(item, root, inventoryHolder, command)
	local target
	if command[MODE] == MODE_DIRECT then
		target = command[TARGET]
	elseif command[MODE] == MODE_WEIGHT_BY then
		if command[CRITERIA] then
			for i = 1, #command[CRITERIA] do
				local currentWeightedCriteria = command[CRITERIA][i]
				if currentWeightedCriteria[STAT] == STAT_HEALTH_PERCENTAGE then
					local winners = GET_TARGET_BY_WEIGHTED_HEALTH_STAT(currentWeightedCriteria)
					if #winners == 1 then
						target = winners[1]
						_P("Determined target " .. target .. " for item " .. item .. " by " .. STAT_HEALTH_PERCENTAGE)
						break
					end
				elseif currentWeightedCriteria[STAT] == STAT_STACK_AMOUNT then
					-- Osi.GetStackAmount()
				end
			end
		end
	end

	if target then
		Osi.ToInventory(item, target, Osi.GetStackAmount(item), 1, 1)
		Osi.SetTag(item, TAG_AIM_PROCESSED)
		_P("Moved item " .. item .. " to " .. target)
	else 
		_P("Couldn't determine a target for item " .. item .. " on character " .. inventoryHolder .. " for command " .. command)
	end
end

-- 0 if equal, 1 if base beats challenger, -1 if base loses to challenger
function Compare(baseValue, challengerValue, comparator)
	if baseValue == challengerValue then
		return 0
	elseif comparator == COMPARATOR_GT then
		return baseValue > challengerValue and 1 or -1
	elseif comparator == COMPARATOR_LT then
		return baseValue < challengerValue and 1 or -1
	end
end

function GET_TARGET_BY_WEIGHTED_HEALTH_STAT(criteria)
	local winningHealthPercent
	local winners = {}
	for _, player in pairs(Osi.DB_Players:Get(nil)) do
		local health = Ext.Entity.Get(player[1]).Health
		local challengerHealthPercent = (health.Hp / health.MaxHp) * 100
		if winningHealthPercent then
			local result = Compare(winningHealthPercent, challengerHealthPercent,
				criteria[COMPARATOR])
			if result == 0 then
				table.insert(winners, player[1])
			elseif result == -1 then
				winners = { player[1] }
			end
		else
			winningHealthPercent = challengerHealthPercent
			table.insert(winners, player[1])
		end
	end

	return winners
end
