local function SetAsProcessed_IfItemWasAddedByAIM(root, item, inventoryHolder)
	local originalOwner = Osi.GetOriginalOwner(item)
	if originalOwner and not (originalOwner == Osi.GetUUID(inventoryHolder)) and Osi.IsPlayer(inventoryHolder) == 1 then
		_P("|OriginalOwner| = " .. Osi.GetOriginalOwner(item)
			.. "\n\t|DirectInventoryOwner| = " .. Osi.GetDirectInventoryOwner(item)
			.. "\n\t|Owner| = " .. Osi.GetOwner(item))

		if TEMPLATES_BEING_TRANSFERRED[root] and TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder] then
			_P(string.format("Found %s of %s being transferred to %s - tagging as processed!"
			, TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder]
			, item
			, inventoryHolder))

			Osi.SetTag(item, TAG_AIM_PROCESSED)

			Osi.SetOriginalOwner(item, Osi.GetUUID(inventoryHolder))
			TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder] = TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder] -
				Osi.GetStackAmount(item)

			if TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder] == 0 then
				TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder] = nil
			end

			if #TEMPLATES_BEING_TRANSFERRED[root] == 0 then
				TEMPLATES_BEING_TRANSFERRED[root] = nil
			end
		end
	end
end

---
---@param applicableCommands ItemFilter[] the table of existing commands to append to
---@param newCommands ItemFilter[] the filters to add to the table
local function AddFiltersToTable(applicableCommands, newCommands)
	for i = 1, #newCommands do
		local command = newCommands[i]

		for _, existingCommand in pairs(applicableCommands) do
			if existingCommand.Mode == command.Mode then
				-- Consolidate filters by Mode, moving the new filters over as long as we don't already have identical ones
				for _, newFilter in pairs(command.Filters) do
					local foundIdenticalFilter = false
					for _, existingFilter in pairs(existingCommand.Filters) do
						if ItemFilters:CompareFilter(newFilter, existingFilter) then
							foundIdenticalFilter = true
						end
					end
					if not foundIdenticalFilter then
						table.insert(existingCommand.Filters, newFilter)
					end
				end

				if command.Modifiers then
					for modifier, newModifier in pairs(command.Modifiers) do
						local existingModifier = existingCommand.Modifiers[modifier]
						if existingModifier then
							if modifier == ItemFilters.ItemFields.FilterModifiers.STACK_LIMIT then
								if existingModifier > newModifier then
									existingCommand.Modifiers[modifier] = newModifier
								end
							end
						else
							existingCommand.Modifiers[modifier] = newModifier
						end
					end
				end
				goto continue
			end
		end

		-- If we don't have a Command with the same Mode already, add to this table
		applicableCommands[#applicableCommands + 1] = command
		::continue::
	end
end

--- Finds all Filters for the given item
---@param item any
---@return ItemFilter[]|nil
local function SearchForItemFilters(item)
	--- @type ItemFilter[]
	local applicableCommands = {}

	if Osi.IsEquipable(item) == 1 then
		AddFiltersToTable(applicableCommands, ItemFilters:GetFiltersByEquipmentType(item))
	end

	AddFiltersToTable(applicableCommands, ItemFilters:GetFilterByTag(item))

	return applicableCommands
end

-- Includes moving from container to other inventories etc...
Ext.Osiris.RegisterListener("TemplateAddedTo", 4, "after", function(root, item, inventoryHolder, addType)
	-- Will be null if inventoryHolder isn't a character
	if not (Osi.IsPlayer(inventoryHolder) == 1) then
		_P(string.format("inventoryHolder %s is not a player", inventoryHolder))
		return
	elseif not (Osi.Exists(item) == 1) then
		_P("Item doesn't exist!")
		return
	end
	
	SetAsProcessed_IfItemWasAddedByAIM(root, item, inventoryHolder)

	if Osi.IsTagged(item, TAG_AIM_PROCESSED) == 1 then
		_P("Item was already processed, skipping!\n")
		return
	end

	local applicableCommands = SearchForItemFilters(item)
	if #applicableCommands > 0 then
		Ext.Utils.PrintWarning(
			"----------------------------------------------------------\n\t\t\tSTARTED\n----------------------------------------------------------")

		local itemStack, templateStack = Osi.GetStackAmount(item)
		_P("|item| = " .. item
			.. "\n\t|root| = " .. root
			.. "\n\t|inventoryHolder| = " .. inventoryHolder
			.. "\n\t|addType| = " .. addType
			.. "\n\t|itemStackSize| = " .. itemStack
			.. "\n\t|templateStackSize| = " .. templateStack)

		_P(Ext.Json.Stringify(applicableCommands))

		Processor:ProcessFiltersForItemAgainstParty(item, root, inventoryHolder, applicableCommands)

		Ext.Utils.PrintWarning(
			"----------------------------------------------------------\n\t\t\tFINISHED\n----------------------------------------------------------")
	else
		Ext.Utils.Print("No command could be found for " ..
			item .. " with root " .. root .. " on " .. inventoryHolder)
	end

	Osi.SetTag(item, TAG_AIM_PROCESSED)
end)

Ext.Osiris.RegisterListener("DroppedBy", 2, "after", function(object, _)
	Osi.ClearTag(object, TAG_AIM_PROCESSED)
end)
