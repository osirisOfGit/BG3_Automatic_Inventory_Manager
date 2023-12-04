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
			Osi.SetOriginalOwner(Osi.GetUUID(inventoryHolder))
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

local function AppendCommandToTable(applicableCommands, command)
	if command then
		for _, existingCommand in pairs(applicableCommands) do
			if existingCommand[MODE] == command[MODE] then
				table.insert(existingCommand[CRITERIA], table.unpack(command[CRITERIA]))
				return
			end
		end

		applicableCommands[#applicableCommands + 1] = command
	end
end

local function SearchForManagementCommand(item)
	local applicableCommands = {}

	if Osi.IsEquipable(item) == 1 then
		if Osi.IsWeapon(item) == 1 then
			AppendCommandToTable(applicableCommands, WEAPON_MAP[GetEquipmentType(item)])

			AppendCommandToTable(applicableCommands, WEAPON_MAP[ALL_ITEMS_MATCHING_MAP_CATEGORY])
		end

		AppendCommandToTable(applicableCommands, EQUIPMENT_MAP[GetEquipmentType(item)])

		AppendCommandToTable(applicableCommands, EQUIPMENT_MAP[ALL_ITEMS_MATCHING_MAP_CATEGORY])
	end

	for _, tag in pairs(Ext.Entity.Get(item).Tag.Tags) do
		AppendCommandToTable(applicableCommands, TAGS_MAP[TAG_UUID_TO_NAME_MAP[tag]])
	end

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
		-- _P("Item was already processed, skipping!\n")
		return
	end

	local applicableCommand = SearchForManagementCommand(item)
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

		Processor.ProcessCommand(item, root, inventoryHolder, applicableCommand)

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
