Config = {}

Config.AIM = {
	FILTERS_DIR = 'filters',
	ENABLED = 1,
	LOG_LEVEL = 3,
	RESET_CONFIGS = 0,
	SYNC_CONFIGS = 1,
	SORT_ITEMS_ON_LOAD = 1,
	FILTER_TABLES = {},
	SYNC_FILTERS = 1
}

PersistentVars = {
	ItemFilters = {}
}

function Config:InitializeConfigurations()
	Config.AIM.RESET_CONFIGS = 0

	for mapName, mapValues in pairs(ItemFilters.itemMaps) do
		table.insert(Config.AIM.FILTER_TABLES, mapName)
		Utils:SaveTableToFile(Config.AIM.FILTERS_DIR .. "/" .. mapName .. ".json", mapValues)
	end

	Config.AIM = Config.AIM
	PersistentVars.ItemFilters = {}
	Utils:SaveTableToFile("config.json", Config.AIM)
end

function Config.SyncConfigsAndFilters()
	Logger:ClearLogFile()

	local config = Utils:LoadFile("config.json")

	if config then
		config = Ext.Json.Parse(config)
	end

	if not config or config.RESET_CONFIGS == 1 then
		Config:InitializeConfigurations()
		Logger:BasicInfo("Initalizing all the configs!")

		config = Config.AIM
	end

	for prop, val in pairs(Config.AIM) do
		if not config[prop] then
			config[prop] = val
		end
	end

	if config.SYNC_CONFIGS == 1 then
		Config.AIM = config
		Logger:BasicInfo("Syncing the config file!")
		for mapName, _ in pairs(ItemFilters.itemMaps) do
			local hasTableRecorded = false
			for _, filterTable in pairs(Config.AIM.FILTER_TABLES) do
				if filterTable == mapName then
					hasTableRecorded = true
					break
				end
			end

			if not hasTableRecorded then
				table.insert(Config.AIM.FILTER_TABLES, mapName)
			end
		end

		PersistentVars.Config = Config.AIM
	elseif PersistentVars.Config then
		Config.AIM = PersistentVars.Config
	end

	if not PersistentVars.ItemFilters then
		PersistentVars.ItemFilters = {}
	end

	if Config.AIM.SYNC_FILTERS == 1 then
		Logger:BasicInfo("Syncing the filters")
		for _, filterTableName in pairs(Config.AIM.FILTER_TABLES) do
			local filterTableFilePath = Config.AIM.FILTERS_DIR .. "/" .. filterTableName .. ".json"
			local filterTable = Utils:LoadFile(filterTableFilePath)

			if filterTable then
				local success, result = pcall(function()
					ItemFilters:AddItemFilterMaps({ [filterTableName] = Ext.Json.Parse(filterTable) }, false, false,
						false)

					PersistentVars.ItemFilters[filterTableName] = ItemFilters.itemMaps[filterTableName]
				end)

				if not success then
					Logger:BasicError(string.format("Could not parse table %s due to error [%s]", filterTableName,
						result))
				else
					Utils:SaveTableToFile(filterTableFilePath,
						PersistentVars.ItemFilters[filterTableName])
				end
			else
				Logger:BasicWarning("Could not find filter table file " .. filterTableFilePath)
			end
		end
	else
		for itemFilterTableName, itemFilterTable in pairs(PersistentVars.ItemFilters) do
			ItemFilters:AddItemFilterMaps({ [itemFilterTableName] = itemFilterTable }, true, true, false)
		end
	end

	ItemFilters:UpdateItemMapsClone()
end
