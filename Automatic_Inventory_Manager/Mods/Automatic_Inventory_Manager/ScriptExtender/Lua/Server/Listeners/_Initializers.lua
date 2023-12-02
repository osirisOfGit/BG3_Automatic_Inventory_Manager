ITEMS_TO_DELETE = {}

function ResetItemStacks()
	for _, player in pairs(Osi.DB_Players:Get(nil)) do
		_P("Cleaning up item stacks on " .. player[1])
		Osi.IterateInventory(player[1],
			EVENT_ITERATE_ITEMS_TO_REBUILD_THEM_START .. player[1],
			EVENT_ITERATE_ITEMS_TO_REBUILD_THEM_END .. player[1])
		ITEMS_TO_DELETE[player[1]] = {}
	end
end

Ext.Events.ResetCompleted:Subscribe(function(_)
	ResetItemStacks()
end)

Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function(level, _)
	if level == "SYS_CC_I" then return end
	if Config.resetAllStacks then
		ResetItemStacks()
		Config.resetAllStacks = false
	end
end)

Ext.Osiris.RegisterListener("EntityEvent", 2, "before", function(guid, event)
	if string.find(event, EVENT_ITERATE_ITEMS_TO_REBUILD_THEM_START) then
		local character = string.sub(event, string.len(EVENT_ITERATE_ITEMS_TO_REBUILD_THEM_START) + 1)
		Osi.ClearTag(guid, TAG_AIM_PROCESSED)
		if Osi.IsEquipped(guid) == 0 and (Ext.Entity.Get(guid).Value.Unique == false or Osi.IsStoryItem(guid) == 0 or Osi.GetMaxStackAmount(guid) > 1) then
			local itemTemplate = Osi.GetTemplate(guid)
			local currentStackSize, _ = Osi.GetStackAmount(guid)
			Osi.SetTag(guid, TAG_AIM_MARK_FOR_DELETION)

			local itemsToDelete = ITEMS_TO_DELETE[character]
			AddItemToTable_AddingToExistingAmount(itemsToDelete, itemTemplate, currentStackSize)
		end
	elseif string.find(event, EVENT_ITERATE_ITEMS_TO_REBUILD_THEM_END) then
		local character = string.sub(event, string.len(EVENT_ITERATE_ITEMS_TO_REBUILD_THEM_END) + 1)
		Osi.PartyRemoveTaggedItems(character, TAG_AIM_MARK_FOR_DELETION,
			Osi.TaggedItemsGetCountInMagicPockets(TAG_AIM_MARK_FOR_DELETION, character))

		if ITEMS_TO_DELETE[character] then
			for itemTemplate, amount in pairs(ITEMS_TO_DELETE[character]) do
				Osi.TemplateAddTo(itemTemplate, character, amount)
				_P("Added " .. amount .. " of " .. itemTemplate .. " to " .. character)
			end
			ITEMS_TO_DELETE[character] = nil
		end
	end
end)
