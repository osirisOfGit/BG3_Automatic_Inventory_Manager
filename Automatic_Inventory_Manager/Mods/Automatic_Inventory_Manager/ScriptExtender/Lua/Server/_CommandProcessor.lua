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

	if not target then
		_P("Couldn't determine a target for item " ..
			item .. " on character " .. inventoryHolder .. " for command " .. Ext.Json.Stringify(command))
		return
	elseif target == inventoryHolder then
		_P("Target was determined to be inventoryHolder for " ..
			item .. " on character " .. inventoryHolder .. " for command " .. Ext.Json.Stringify(command))
	else
		if Osi.GetMaxStackAmount(item) > 1 then
			local current, _ = Osi.GetStackAmount(item)
			-- Forces the game to generate new UUIDs for the items, since stacking is a very duct-tape-and-glue system
			Osi.TemplateAddTo(root, target, current, 1)
			Osi.TemplateRemoveFromUser(root, inventoryHolder, current)
			_P("'Moved' " .. current .. " " .. root .. " to " .. target .. " from " .. inventoryHolder)
		else
			-- To avoid any potential weirdness with unique item UUIDs
			Osi.MagicPocketsMoveTo(inventoryHolder, item, target, 1, 0)
			_P("'Moved' single " .. item .. " to " .. target)
		end
	end
	_D(Osi.GetItemByTemplateInUserInventory(root, target))
	Osi.SetTag(Osi.GetItemByTemplateInUserInventory(root, target), TAG_AIM_PROCESSED)
	_P("Set Tag to Processed")
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
				winningHealthPercent = challengerHealthPercent
			end
		else
			winningHealthPercent = challengerHealthPercent
			table.insert(winners, player[1])
		end
		_P("Current winners for health % are " .. Ext.Json.Stringify(winners))
	end

	return winners
end
