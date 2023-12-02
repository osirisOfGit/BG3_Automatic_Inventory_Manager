EQUIPTYPE_UUID_TO_NAME_MAP = {}
for _, equipTypeUUID in pairs(Ext.StaticData.GetAll("EquipmentType")) do
	EQUIPTYPE_UUID_TO_NAME_MAP[equipTypeUUID] = Ext.StaticData.Get(equipTypeUUID, "EquipmentType")["Name"]
end

TAG_UUID_TO_NAME_MAP = {}
for _, tagUUID in pairs(Ext.StaticData.GetAll("Tag")) do
	TAG_UUID_TO_NAME_MAP[tagUUID] = Ext.StaticData.Get(tagUUID, "Tag")["Name"]
end

function SetAsProcessed_IfItemWasAddedByAIM(root, item, inventoryHolder)
	if not Osi.GetOriginalOwner(item) == Osi.GetUUID(inventoryHolder) and Osi.DB_Players:Get(Osi.GetOriginalOwner(item)) then
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
		end
	end
end

function AppendCommandToTable(applicableCommands, command)
	if command then
		applicableCommands[#applicableCommands + 1] = command
	end
end

function SearchForManagementCommand(item)
	local applicableCommands = {}
	if Osi.IsEquipable(item) == 1 then
		local equipmentTypeUUID = Ext.Entity.Get(item).ServerItem.Item.OriginalTemplate.EquipmentTypeID
		AppendCommandToTable(applicableCommands, EQUIPMENT_MAP[EQUIPTYPE_UUID_TO_NAME_MAP[equipmentTypeUUID]])

		if EQUIPMENT_MAP[ALL_ITEMS_MATCHING_MAP_CATEGORY] then
			AppendCommandToTable(applicableCommands, EQUIPMENT_MAP[ALL_ITEMS_MATCHING_MAP_CATEGORY])
		end
	end

	for _, tag in pairs(Ext.Entity.Get(item).Tag.Tags) do
		AppendCommandToTable(applicableCommands, TAGS_MAP[TAG_UUID_TO_NAME_MAP[tag]])
	end

	return #applicableCommands > 0 and applicableCommands or nil
end

-- Includes moving from container to other inventories etc...
Ext.Osiris.RegisterListener("TemplateAddedTo", 4, "after", function(root, item, inventoryHolder, addType)
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

		ProcessCommand(item, root, inventoryHolder, applicableCommand)

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
