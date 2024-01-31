ITEMS_TO_DELETE = {}

local function ResetItemStacks()
	for _, player in pairs(Osi.DB_Players:Get(nil)) do
		Logger:BasicInfo("Sorting item stacks on " .. player[1])
		Osi.IterateInventory(player[1],
			EVENT_ITERATE_ITEMS_TO_RESORT_THEM_START .. player[1],
			EVENT_ITERATE_ITEMS_TO_RESORT_THEM_END .. player[1])
	end
end

Ext.Events.ResetCompleted:Subscribe(function(_)
	if Config.AIM.ENABLED == 1 then
		Config.SyncConfigsAndFilters()
		ResetItemStacks()
	end
end)

Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function(level, _)
	if Config.AIM.ENABLED == 1 then
		if level == "SYS_CC_I" then return end
		if Config.AIM.SORT_ITEMS_ON_LOAD == 1 and PersistentVars.SORT_ITEMS_ON_LOAD ~= 0 then
			Logger:BasicInfo("Sorting all items in party inventory on save load!")
			ResetItemStacks()
			PersistentVars.SORT_ITEMS_ON_LOAD = 0
		end

	end
end)

Ext.Events.SessionLoaded:Subscribe(Config.SyncConfigsAndFilters)
