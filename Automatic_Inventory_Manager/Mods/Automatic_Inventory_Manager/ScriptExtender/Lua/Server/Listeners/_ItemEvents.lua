local function SetAsProcessed_IfItemWasAddedByAIM(root, item, inventoryHolder)
	local originalOwner = Osi.GetOriginalOwner(item)
	if not originalOwner == Osi.GetUUID(inventoryHolder) and Osi.DB_Players:Get(originalOwner) then
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
---@param ... ItemFilter the filters to add to the table
local function AddFiltersToTable(applicableCommands, ...)
	local filters = { ... }
	for i = 1, #filters do
		local command = filters[i]
		for _, existingCommand in pairs(applicableCommands) do
			if existingCommand.Mode == command.Mode then
				table.move(command.Filters, 1, #command.Filters, #existingCommand.Filters + 1, existingCommand.Filters)

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

	return #applicableCommands > 0 and applicableCommands or nil
end

-- Includes moving from container to other inventories etc...
Ext.Osiris.RegisterListener("TemplateAddedTo", 4, "after", function(root, item, inventoryHolder, addType)
	if Osi.Exists(item) == 0 then
		_P("Item doesn't exist!")
		return
	end

	SetAsProcessed_IfItemWasAddedByAIM(root, item, inventoryHolder)

	if Osi.IsTagged(item, TAG_AIM_PROCESSED) == 1 then
		_P("Item was already processed, skipping!\n")
		return
	end

	local applicableCommand = SearchForItemFilters(item)
	if applicableCommand then
		Ext.Utils.PrintWarning(
			"----------------------------------------------------------\n\t\t\tSTARTED\n----------------------------------------------------------")

		local itemStack, templateStack = Osi.GetStackAmount(item)
		_P("|item| = " .. item
			.. "\n\t|root| = " .. root
			.. "\n\t|inventoryHolder| = " .. inventoryHolder
			.. "\n\t|addType| = " .. addType
			.. "\n\t|itemStackSize| = " .. itemStack
			.. "\n\t|templateStackSize| = " .. templateStack)

		_P(Ext.Json.Stringify(applicableCommand))

		Processor:ProcessFiltersForItemAgainstParty(item, root, inventoryHolder, applicableCommand)

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
