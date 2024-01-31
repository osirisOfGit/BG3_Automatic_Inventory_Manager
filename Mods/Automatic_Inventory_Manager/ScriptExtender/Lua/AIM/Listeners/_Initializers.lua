local function ResetItemStacks()
	if Config.AIM.SORT_ITEMS_ON_LOAD == 1 and PersistentVars.SORT_ITEMS_ON_LOAD ~= 0 then
		Logger:BasicInfo("Sorting all items in party inventory on level load/reset!")
		PersistentVars.SORT_ITEMS_ON_LOAD = 0

		for _, player in pairs(Osi.DB_Players:Get(nil)) do
			Logger:BasicInfo("Sorting item stacks on " .. player[1])
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

				local equippedItem = Osi.GetEquippedItem(player[1], itemSlot)
				if equippedItem then
					Osi.SetTag(equippedItem, TAG_AIM_PROCESSED)
				end
			end

			Osi.IterateInventory(player[1],
				EVENT_ITERATE_ITEMS_TO_RESORT_THEM_START .. player[1],
				EVENT_ITERATE_ITEMS_TO_RESORT_THEM_END .. player[1])
		end
	end
end

Ext.Events.ResetCompleted:Subscribe(function(_)
	if Config.AIM.ENABLED == 1 then
		ResetItemStacks()
	end
end)

Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function(level, _)
	if Config.AIM.ENABLED == 1 then
		if level == "SYS_CC_I" then return end
		ResetItemStacks()
	end
end)

Ext.Events.SessionLoaded:Subscribe(Config.SyncConfigsAndFilters)
