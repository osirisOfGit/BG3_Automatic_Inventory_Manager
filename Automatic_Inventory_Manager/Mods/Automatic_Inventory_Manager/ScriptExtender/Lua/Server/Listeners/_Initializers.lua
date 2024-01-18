ITEMS_TO_DELETE = {}

local function ResetItemStacks()
	for _, player in pairs(Osi.DB_Players:Get(nil)) do
		Logger:BasicDebug("Cleaning up item stacks on " .. player[1])
		Osi.IterateInventory(player[1],
			EVENT_ITERATE_ITEMS_TO_RESORT_THEM_START .. player[1],
			EVENT_ITERATE_ITEMS_TO_RESORT_THEM_END .. player[1])
	end
end

Ext.Events.ResetCompleted:Subscribe(function(_)
	Config:SyncConfigsAndFilters()
	ResetItemStacks()
end)

Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function(level, _)
	if level == "SYS_CC_I" then return end
	if PersistentVars.Config.SORT_ITEMS_ON_LOAD == 1 then
		Logger:BasicDebug("Resorting items on level load!")
		ResetItemStacks()
	end
end)


