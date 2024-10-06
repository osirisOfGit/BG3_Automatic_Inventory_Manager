local function RemoveItemFromTracker_IfAlreadySorted(root, item, inventoryHolder)
	local originalOwner = Osi.GetOriginalOwner(item)
	if originalOwner and not (originalOwner == Osi.GetUUID(inventoryHolder)) and Osi.IsPlayer(inventoryHolder) == 1 then
		Logger:BasicDebug("|Item| = %s\n\t|OriginalOwner| = %s\n\t|DirectInventoryOwner| = %s\n\t|Owner| = %s",
			item,
			Osi.GetDirectInventoryOwner(item),
			Osi.GetOwner(item),
			Osi.GetOriginalOwner(item)
		)

		if TEMPLATES_BEING_TRANSFERRED[root] and TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder] then
			Logger:BasicDebug("Found %s of %s being transferred to %s - tagging as processed!"
			, TEMPLATES_BEING_TRANSFERRED[root][inventoryHolder]
			, item
			, inventoryHolder)

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
		if #Osi.DB_Players:Get(nil) == 1 then
			Osi.SetTag(item, TAG_AIM_PROCESSED)
			Logger:BasicTrace("Item %s was picked up, but there's only one person in the party, so tagging as processed and skipping!", item)
			return
		end

		RemoveItemFromTracker_IfAlreadySorted(root, item, inventoryHolder)

		if ignoreProcessedTag == false and Osi.IsTagged(item, TAG_AIM_PROCESSED) == 1 then
			Logger:BasicDebug("Item %s was already processed, skipping!", item)
			return
		end

		local startTime = Ext.Utils.MonotonicTime()

		EntityPropertyRecorder:RecordEntityProperties(item)
		local applicableItemFilter = ItemFilters:SearchForItemFilters(item, root, inventoryHolder)
		if #applicableItemFilter.Filters > 0 then
			Logger:BasicDebug(
				"\n----------------------------------------------------------\n\t\t\tSTARTED\n----------------------------------------------------------")

			local itemStack, templateStack = Osi.GetStackAmount(item)

			if Logger:IsLogLevelEnabled(Logger.PrintTypes.DEBUG) then
				Logger:BasicDebug(
					"\n\t|item| = %s\n\t|root| = %s\n\t|inventoryHolder| = %s\n\t|owner| = %s\n\t|originalOwner| = %s\n\t|directInventoryOwner| = %s\n\t|itemStackSize| = %s\n\t|templateStackSize| = %s\n\t|computedItemFilter| = \n%s",
					item,
					root,
					inventoryHolder,
					Osi.GetOwner(item),
					Osi.GetOriginalOwner(item),
					Osi.GetDirectInventoryOwner(item),
					itemStack,
					templateStack,
					Ext.Json.Stringify(applicableItemFilter))
			end

			Processor:ProcessFiltersForItemAgainstParty(item, root, inventoryHolder, applicableItemFilter)
			Logger:BasicDebug(
				"\n----------------------------------------------------------\n\t\t\tFINISHED in %dms\n----------------------------------------------------------",
				(Ext.Utils.MonotonicTime() - startTime))
		else
			Logger:BasicInfo("No command could be found for %s with root %s on %s", item, root, inventoryHolder)
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
			Logger:BasicDebug("inventoryHolder %s is not a player (for item %s)", inventoryHolder, item)
			return
		elseif Osi.Exists(item) ~= 1 then
			Logger:BasicWarning("Item %s, supposedly held by %s, doesn't exist!", item, inventoryHolder)
			return
		elseif Osi.IsEquipped(item) ~= 0 then
			Logger:BasicInfo("Item %s is currently equipped. Marking as processed and moving on", item)
			Osi.SetTag(item, TAG_AIM_PROCESSED)
			return
		end

		local blacklistedContainer = ItemBlackList:IsContainerInBlacklist(Osi.GetDirectInventoryOwner(item))
		if blacklistedContainer then
			Logger:BasicInfo("Item %s is contained in %s, which is in the container blacklist - marking as processed and moving on", item, blacklistedContainer)
			Osi.SetTag(item, TAG_AIM_PROCESSED)
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
			Logger:BasicInfo("Resorting all items of template %s due to finished use of %s", itemTemplate, item2)
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
		Logger:BasicDebug("Processing item %s for event %s", guid, event)
		local character = string.sub(event, string.len(aimEvent) + 1)

		DetermineAndExecuteFiltersForItem(Osi.GetTemplate(guid), guid, character, ignoreProcessedTag)
	end
end

Ext.Osiris.RegisterListener("EntityEvent", 2, "before", function(guid, event)
	if Config.AIM.ENABLED == 1 then
		if string.find(event, EVENT_ITERATE_ITEMS_TO_RESORT_THEM_START) then
			extractCharAndSortItem(guid, event, EVENT_ITERATE_ITEMS_TO_RESORT_THEM_START, false)

			if Osi.IsContainer(guid) and not ItemBlackList:IsContainerInBlacklist(guid) then
				Osi.IterateInventory(guid,
					EVENT_ITERATE_ITEMS_TO_RESORT_THEM_START .. guid,
					EVENT_ITERATE_ITEMS_TO_RESORT_THEM_END .. guid)
			end
		elseif string.find(event, EVENT_RESORT_CONSUMABLE_START) then
			extractCharAndSortItem(guid, event, EVENT_RESORT_CONSUMABLE_START, true)
		end
	end
end)

Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", function(character)
	Logger:BasicInfo("Marking equipped items as sorted, then sorting items on %s", character)
	for _, itemSlot in ipairs(Ext.Enums.ItemSlot) do
		itemSlot = tostring(itemSlot)
		-- Getting this aligned with Osi.EQUIPMENTSLOTNAME, because, what the heck Larian (╯°□°）╯︵ ┻━┻
		if itemSlot == Ext.Enums.StatsItemSlot[Ext.Enums.StatsItemSlot.MeleeMainHand] then
			itemSlot = "Melee Main Weapon"
		elseif itemSlot == Ext.Enums.StatsItemSlot[Ext.Enums.StatsItemSlot.MeleeOffHand] then
			itemSlot = "Melee Offhand Weapon"
		elseif itemSlot == Ext.Enums.StatsItemSlot[Ext.Enums.StatsItemSlot.RangedMainHand] then
			itemSlot = "Ranged Main Weapon"
		elseif itemSlot == Ext.Enums.StatsItemSlot[Ext.Enums.StatsItemSlot.RangedOffHand] then
			itemSlot = "Ranged Offhand Weapon"
		end

		local equippedItem = Osi.GetEquippedItem(character, itemSlot)
		if equippedItem then
			Osi.SetTag(equippedItem, TAG_AIM_PROCESSED)
		end
	end

	Osi.IterateInventory(character,
		EVENT_ITERATE_ITEMS_TO_RESORT_THEM_START .. character,
		EVENT_ITERATE_ITEMS_TO_RESORT_THEM_END .. character)
end)
