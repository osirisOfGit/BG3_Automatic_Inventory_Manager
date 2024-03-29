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
	if Config.AIM.ENABLED == 1 then
		RemoveItemFromTracker_IfAlreadySorted(root, item, inventoryHolder)

		if ignoreProcessedTag == false and Osi.IsTagged(item, TAG_AIM_PROCESSED) == 1 then
			Logger:BasicDebug("Item was already processed, skipping!")
			return
		end

		local startTime = Ext.Utils.MonotonicTime()

		EntityPropertyRecorder:RecordEntityProperties(item)
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
			Logger:BasicDebug(string.format(
				"\n----------------------------------------------------------\n\t\t\tFINISHED in %dms\n----------------------------------------------------------",
				(Ext.Utils.MonotonicTime() - startTime)))
		else
			Logger:BasicInfo("No command could be found for " ..
				item .. " with root " .. root .. " on " .. inventoryHolder)
		end

		Osi.SetTag(item, TAG_AIM_PROCESSED)
	end
end

Ext.Osiris.RegisterListener("DroppedBy", 2, "after", function(object, _)
	if Config.AIM.ENABLED == 1 then
		Osi.ClearTag(object, TAG_AIM_PROCESSED)
	end
end)

-- Includes moving from container to other inventories etc...
Ext.Osiris.RegisterListener("TemplateAddedTo", 4, "before", function(root, item, inventoryHolder, _)
	if Config.AIM.ENABLED == 1 then
		-- Will be nil if inventoryHolder isn't a character
		if Osi.IsPlayer(inventoryHolder) ~= 1 then
			Logger:BasicDebug(string.format("inventoryHolder %s is not a player", inventoryHolder))
			return
		elseif Osi.Exists(item) ~= 1 then
			Logger:BasicWarning("Item doesn't exist!")
			return
		end

		if (Config.AIM.SORT_ITEMS_DURING_COMBAT == 1 or Osi.IsInCombat(inventoryHolder) == 0) and not ItemBlackList:IsItemOrTemplateInBlacklist(item, root) then
			DetermineAndExecuteFiltersForItem(root, item, inventoryHolder, false)
		end
	end
end)

Ext.Osiris.RegisterListener("TemplateUseFinished", 4, "before", function(character, itemTemplate, item2, success)
	if Config.AIM.ENABLED == 1
		-- Has the consumable tag
		and Osi.IsTagged(item2, "4d79b277-97f0-4227-a780-7a14fb9827fc") == 1
		and not ItemBlackList:IsItemOrTemplateInBlacklist(item2, itemTemplate)
	then
		local isTemplateInInventory = Osi.TemplateIsInPartyInventory(itemTemplate, character, 0)
		if success == 1 and (isTemplateInInventory and isTemplateInInventory > 0) and (Config.AIM.SORT_CONSUMABLE_ITEMS_DURING_COMBAT == 1 or Osi.IsInCombat(character) == 0) then
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

local function extractCharAndSortItem(guid, event, aimEvent, ignoreProcessedTag)
	if Osi.IsEquipped(guid) == 0 and Ext.Entity.Get(guid).Value.Unique == false and Osi.IsStoryItem(guid) == 0 and not ItemBlackList:IsItemOrTemplateInBlacklist(guid, Osi.GetTemplate(guid)) then
		Logger:BasicDebug("Processing item " .. guid .. " for event " .. event)
		local character = string.sub(event, string.len(aimEvent) + 1)

		DetermineAndExecuteFiltersForItem(Osi.GetTemplate(guid), guid, character, ignoreProcessedTag)
	end
end

Ext.Osiris.RegisterListener("EntityEvent", 2, "before", function(guid, event)
	if Config.AIM.ENABLED == 1 then
		if string.find(event, EVENT_ITERATE_ITEMS_TO_RESORT_THEM_START) then
			extractCharAndSortItem(guid, event, EVENT_ITERATE_ITEMS_TO_RESORT_THEM_START, false)
		elseif string.find(event, EVENT_RESORT_CONSUMABLE_START) then
			extractCharAndSortItem(guid, event, EVENT_RESORT_CONSUMABLE_START, true)
		end
	end
end)
