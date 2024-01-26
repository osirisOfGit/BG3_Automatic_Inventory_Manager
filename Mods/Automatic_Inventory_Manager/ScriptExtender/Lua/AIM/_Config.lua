Config                      = {}

Config.AIM                  = {
	FILTERS_DIR = 'filters',
	ENABLED = 1,
	LOG_LEVEL = 3,
	RESET_CONFIGS = 0,
	SYNC_CONFIGS = 1,
	SORT_ITEMS_ON_LOAD = 1,
	FILTER_TABLES = {},
	MERGE_DEFAULT_FILTERS = 1
}

local MODIFIED_CONFIG_NAMES = {
	SYNC_FILTERS = "MERGE_DEFAULT_FILTERS"
}

local REMOVED_CONFIG_NAMES  = {
	"SYNC_CONFIGS"
}

PersistentVars              = {
}

function Config:InitializeConfigurations()
	Logger:BasicInfo(
		"Initializing configs - will completely remove any customizations to config.json or known filters/ itemMaps!")
	Config.AIM.RESET_CONFIGS = 0

	for mapName, mapValues in pairs(ItemFilters.itemMaps) do
		table.insert(Config.AIM.FILTER_TABLES, mapName)
		Utils:SaveTableToFile(Config.AIM.FILTERS_DIR .. "/" .. mapName .. ".json", mapValues)
	end

	-- PersistentVars.ItemFilters = {}
	Utils:SaveTableToFile("config.json", Config.AIM)
end

function Config.SyncConfigsAndFilters()
	Logger:ClearLogFile()

	PersistentVars = {}

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

	for oldProp, newProp in pairs(MODIFIED_CONFIG_NAMES) do
		if config[oldProp] then
			config[newProp] = config[oldProp]
			config[oldProp] = nil
		end
	end

	for _, oldProp in pairs(REMOVED_CONFIG_NAMES) do
		config[oldProp] = nil
	end

	-- if config.SYNC_CONFIGS == 1 then
	Config.AIM = config
	if Config.AIM.MERGE_DEFAULT_FILTERS == 1 then
		Logger:BasicInfo("Adding new AIM-provided itemMaps to the FILTER_TABLES config!")
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
				Logger:BasicInfo("Added itemMap " .. mapName)
			end
		end
	else
		for itemMapName, _ in pairs(ItemFilters.itemMaps) do
			if not Config.AIM[itemMapName] then
				ItemFilters:DeleteItemFilterMap(itemMapName)
			end
		end
	end
	Utils:SaveTableToFile("config.json", Config.AIM)

	-- PersistentVars.Config = Config.AIM
	-- elseif PersistentVars.Config then
	-- 	Config.AIM = PersistentVars.Config
	-- end

	-- if not PersistentVars.ItemFilters then
	-- 	PersistentVars.ItemFilters = {}
	-- end

	Logger:BasicInfo("Syncing the filters")
	for _, filterTableName in pairs(Config.AIM.FILTER_TABLES) do
		local filterTableFilePath = Config.AIM.FILTERS_DIR .. "/" .. filterTableName .. ".json"
		local filterTable = Utils:LoadFile(filterTableFilePath)

		if filterTable then
			local success, result = pcall(function()
				if Config.AIM.MERGE_DEFAULT_FILTERS == 1 then
					Logger:BasicWarning(string.format(
						"Merging %s.json in with AIM defaults - customizations may get overwritten, or deleted filters added back",
						filterTableName))

					ItemFilters:AddItemFilterMaps({ [filterTableName] = Ext.Json.Parse(filterTable) },
						false,
						true,
						false)
				else
					Logger:BasicInfo(string.format("Overwriting default ItemFilters for %s with contents of %s.json",
						filterTableName, filterTableName))

					ItemFilters:AddItemFilterMaps({ [filterTableName] = Ext.Json.Parse(filterTable) },
						true,
						false,
						false)
				end

				-- PersistentVars.ItemFilters[filterTableName] = ItemFilters.itemMaps[filterTableName]
			end)

			if not success then
				Logger:BasicError(string.format("Could not parse table %s due to error [%s]", filterTableName,
					result))
			end
		else
			Logger:BasicWarning("Could not find filter table file " .. filterTableFilePath)
		end
		-- else
		-- for itemFilterTableName, itemFilterTable in pairs(PersistentVars.ItemFilters) do
		-- 	ItemFilters:AddItemFilterMaps({ [itemFilterTableName] = itemFilterTable }, true, true, false)
		-- end
		-- end

		ItemFilters:UpdateItemMapsClone()
	end
end
