local function RemoveItemFromTracker_IfAlreadySorted(root, item, inventoryHolder)
	local originalOwner = Osi.GetOriginalOwner(item)
	if originalOwner and not (originalOwner == Osi.GetUUID(inventoryHolder)) and Osi.IsPlayer(inventoryHolder) == 1 then
		Logger:BasicDebug("|OriginalOwner| = " .. Osi.GetOriginalOwner(item)
			.. "\n\t|DirectInventoryOwner| = " .. Osi.GetDirectInventoryOwner(item)
			.. "\n\t|Owner| = " .. Osi.GetOwner(item))

		if TEMPLATES_BEING_TRANSFERRED[root] and TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder] then
			Logger:BasicDebug(string.format("Found %s of %s being transferred to %s - tagging as processed!"
			, TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder]
			, item
			, inventoryHolder))

			TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder] = TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder] -
				Osi.GetStackAmount(item)

			if TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder] == 0 then
				TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder] = nil
			end

			if #(TEMPLATES_BEING_TRANSFERRED[root]) == 0 then
				TEMPLATES_BEING_TRANSFERRED[root] = nil
			end
		end
	end
end

local function DetermineAndExecuteFiltersForItem(root, item, inventoryHolder, ignoreProcessedTag)
	if PersistentVars.Config.ENABLED == 1 then
		RemoveItemFromTracker_IfAlreadySorted(root, item, inventoryHolder)

		if ignoreProcessedTag == false and Osi.IsTagged(item, TAG_AIM_PROCESSED) == 1 then
			Logger:BasicDebug("Item was already processed, skipping!")
			return
		end

		local applicableItemFilter = ItemFilters:SearchForItemFilters(item, root, inventoryHolder)
		if #applicableItemFilter.Filters > 0 then
			Logger:BasicDebug(
				"\n----------------------------------------------------------\n\t\t\tSTARTED\n----------------------------------------------------------")

			local itemStack, templateStack = Osi.GetStackAmount(item)
			Logger:BasicDebug("|item| = " .. item
				.. "\n\t|root| = " .. root
				.. "\n\t|inventoryHolder| = " .. inventoryHolder
				.. "\n\t|itemStackSize| = " .. itemStack
				.. "\n\t|templateStackSize| = " .. templateStack)

			Logger:BasicDebug(Ext.Json.Stringify(applicableItemFilter))

			Processor:ProcessFiltersForItemAgainstParty(item, root, inventoryHolder, applicableItemFilter)
			Logger:BasicDebug(
				"\n----------------------------------------------------------\n\t\t\tFINISHED\n----------------------------------------------------------")
		else
			Logger:BasicInfo("No command could be found for " ..
				item .. " with root " .. root .. " on " .. inventoryHolder)
		end

		Osi.SetTag(item, TAG_AIM_PROCESSED)
	end
end

Ext.Osiris.RegisterListener("DroppedBy", 2, "after", function(object, _)
	if PersistentVars.Config.ENABLED == 1 then
		Osi.ClearTag(object, TAG_AIM_PROCESSED)
	end
end)

-- Includes moving from container to other inventories etc...
Ext.Osiris.RegisterListener("TemplateAddedTo", 4, "after", function(root, item, inventoryHolder, addType)
	if PersistentVars.Config.ENABLED == 1 then
		-- Will be nil if inventoryHolder isn't a character
		if Osi.IsPlayer(inventoryHolder) ~= 1 then
			Logger:BasicDebug(string.format("inventoryHolder %s is not a player", inventoryHolder))
			return
		elseif Osi.Exists(item) ~= 1 then
			Logger:BasicWarning("Item doesn't exist!")
			return
		end

		DetermineAndExecuteFiltersForItem(root, item, inventoryHolder, false)
	end
end)


Ext.Osiris.RegisterListener("TemplateUseFinished", 4, "after", function(character, itemTemplate, item2, success)
	if PersistentVars.Config.ENABLED == 1 then
		if success == 1 and Osi.TemplateIsInPartyInventory(itemTemplate, character, 0) > 0 and Osi.IsInCombat(character) == 0 then
			Logger:BasicInfo("Resorting all items of template " .. itemTemplate .. " due to finished use of " .. item2)
			for _, player in pairs(Osi.DB_Players:Get(nil)) do
				Osi.IterateInventoryByTemplate(player[1],
					itemTemplate,
					EVENT_RESORT_CONSUMABLE_START .. player[1],
					EVENT_RESORT_CONSUMABLE_END .. player[1])
			end
		end
	end
end)

Ext.Osiris.RegisterListener("EntityEvent", 2, "before", function(guid, event)
	if PersistentVars.Config.ENABLED == 1 then
		if string.find(event, EVENT_ITERATE_ITEMS_TO_RESORT_THEM_START) or string.find(event, EVENT_RESORT_CONSUMABLE_START) then
			if Osi.IsEquipped(guid) == 0 and Ext.Entity.Get(guid).Value.Unique == false and Osi.IsStoryItem(guid) == 0 then
				Logger:BasicDebug("Processing item " .. guid .. " for event " .. event)
				local character = string.sub(event, string.len(EVENT_ITERATE_ITEMS_TO_RESORT_THEM_START) + 1)

				DetermineAndExecuteFiltersForItem(Osi.GetTemplate(guid), guid, character, string.find(event, EVENT_RESORT_CONSUMABLE_START) ~= nil)
			end
		end
	end
end)
