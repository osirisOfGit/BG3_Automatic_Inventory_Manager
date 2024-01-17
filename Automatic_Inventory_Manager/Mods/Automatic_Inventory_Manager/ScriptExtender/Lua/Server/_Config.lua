Config = {}

Config.Mod = {
	ENABLED = 1,
	RESET_CONFIGS = 0,
	SYNC_CONFIGS = 1,
	SORT_ITEMS_ON_LOAD = 1,
	FILTERS_DIR = 'filters/',
	FILTER_TABLES = {},
	SYNC_FILTERS = 1
}

PersistentVars = {
	---@type ItemFilterMap
	ItemFilters = {}
}

function Config:InitializeConfigurations()
	Config.Mod.RESET_CONFIGS = 0
	
	for mapName, mapValues in pairs(ItemFilters.ItemMaps) do
		table.insert(Config.Mod.FILTER_TABLES, mapName)
		Utils:SaveTableToFile(Config.Mod.FILTERS_DIR .. mapName .. ".json", mapValues)
	end
	
	Utils:SaveTableToFile("config.json", Config.Mod)
	PersistentVars.Config = Config.Mod
end

function Config.SyncConfigsAndFilters()
	local config = Utils:LoadFile("config.json")

	if config then
		config = Ext.Json.Parse(config)
	end

	if not config or config.RESET_CONFIGS == 1 then
		_P("Initalizing all the configs!")
		Config:InitializeConfigurations()

		config = Config.Mod
	end

	if config.SYNC_CONFIGS == 1 then
		Config.Mod = config
		for mapName, mapValues in pairs(ItemFilters.ItemMaps) do
			local hasTableRecorded = false
			for _, filterTable in pairs(Config.Mod.FILTER_TABLES) do
				if filterTable == mapName then
					hasTableRecorded = true
					break
				end
			end

			if not hasTableRecorded then
				table.insert(Config.Mod.FILTER_TABLES, mapName)
			end
		end
		
		PersistentVars.Config = Config.Mod
	end

	if PersistentVars.Config.SYNC_FILTERS == 1 then
		for _, filterTableName in pairs(PersistentVars.Config.FILTER_TABLES) do
			local filterTableFilePath = PersistentVars.Config.FILTERS_DIR .. "/" .. filterTableName .. ".json"
			local filterTable = Utils:LoadFile(filterTableFilePath)

			if filterTable then
				local success, result = pcall(function()
					---@type ItemFilterMap
					local loadedFilterTable = Ext.Json.Parse(filterTable)
					
					if not ItemFilters.ItemMaps[filterTableName] then
						ItemFilters.ItemMaps[filterTableName] = loadedFilterTable
					else 
						for key, itemFilter in pairs(loadedFilterTable) do
							if not ItemFilters.ItemMaps[filterTableName][key] then
								ItemFilters.ItemMaps[filterTableName][key] = itemFilter
							end
						end
					end

					PersistentVars.ItemFilters[filterTableName] = ItemFilters.ItemMaps[filterTableName]
				end)

				if not success then
					Ext.Utils.PrintError(string.format("Could not parse table %s due to error [%s]", filterTableName,
						result))
				else
					Utils:SaveTableToFile(Config.Mod.FILTERS_DIR .. filterTableName .. ".json", PersistentVars.ItemFilters[filterTableName])
				end
			else
				Ext.Utils.PrintWarning("Could not find filter table file " .. filterTableFilePath)
			end
		end
	end

	for itemFilterTableName, itemFilterTable in pairs(PersistentVars.ItemFilters) do
		ItemFilters.ItemMaps[itemFilterTableName] = itemFilterTable
	end
end
