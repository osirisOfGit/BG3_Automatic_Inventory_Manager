Ext.Require("AIM/FilterPresets/_AllDefaults.lua")
Ext.Require("AIM/FilterPresets/_CampGoldBooks.lua")

Config = {}

Config.AIM = {
	ENABLED = 1,
	RESET_CONFIGS = 0,
	LOG_LEVEL = 3,
	SORT_ITEMS_ON_FIRST_LOAD = 1,
	SORT_ITEMS_DURING_COMBAT = 0,
	SORT_CONSUMABLE_ITEMS_ON_USE_DURING_COMBAT = 0,
	PRESETS = {
		PRESETS_DIR = "presets",
		ACTIVE_PRESETS = {},
		FILTERS_PRESETS = {}
	},
}

local function InitializeConfigurations()
	Logger:BasicInfo(
		"Initializing configs - will completely remove any customizations to config.json, including custom presets (custom preset directories will be unaffected)")
	Config.AIM.RESET_CONFIGS = 0

	FileUtils:SaveTableToFile("config.json", Config.AIM)
end

--- Initializes the presets from AIM/FilterPresets/, overwriting directory contents, and migrates 1.x FILTER_DIR and FILTER_TABLES config properties to new structure,
--- copying existing files over to a custom preset directory and activating it. If no legacy configs are detected, sets Preset_AllDefaults as the active preset
local function InitializeFilterPresetsAndUpgradeLegacyFilters()
	Logger:BasicDebug("Creating and saving default preset - " .. Preset_CampGoldBooks.Name)
	Config.AIM.PRESETS.FILTERS_PRESETS[Preset_CampGoldBooks.Name] = {}
	for mapName, itemFilterMap in pairs(Preset_CampGoldBooks.ItemMaps) do
		table.insert(Config.AIM.PRESETS.FILTERS_PRESETS[Preset_CampGoldBooks.Name], mapName)
		FileUtils:SaveTableToFile(
			FileUtils:BuildRelativeJsonFileTargetPath(mapName, Config.AIM.PRESETS.PRESETS_DIR, Preset_CampGoldBooks.Name),
			itemFilterMap)
	end

	Logger:BasicDebug("Creating and saving default preset - " .. Preset_AllDefaults.Name)
	Config.AIM.PRESETS.FILTERS_PRESETS[Preset_AllDefaults.Name] = {}
	for mapName, itemFilterMap in pairs(Preset_AllDefaults.ItemMaps) do
		table.insert(Config.AIM.PRESETS.FILTERS_PRESETS[Preset_AllDefaults.Name], mapName)
		FileUtils:SaveTableToFile(
			FileUtils:BuildRelativeJsonFileTargetPath(mapName, Config.AIM.PRESETS.PRESETS_DIR, Preset_AllDefaults.Name),
			itemFilterMap)
	end

	Upgrade:LegacyFiltersToPresets()

	if not Config.AIM.PRESETS.ACTIVE_PRESETS or #Config.AIM.PRESETS.ACTIVE_PRESETS == 0 then
		table.insert(Config.AIM.PRESETS.ACTIVE_PRESETS, Preset_AllDefaults.Name)
	end

	FileUtils:SaveTableToFile("config.json", Config.AIM)
end

local function LoadAndMergeItemMapsFromActivePresets()
	for _, presetName in ipairs(Config.AIM.PRESETS.ACTIVE_PRESETS) do
		Logger:BasicInfo("Loading filter preset " .. presetName)
		if not Config.AIM.PRESETS.FILTERS_PRESETS[presetName] then
			Logger:BasicError(string.format(
				"Specified preset '%s' was not present in the FILTERS_PRESETS property - please specify a real preset (case sensitive)",
				presetName))
			goto continue
		end
		for _, filterTableName in pairs(Config.AIM.PRESETS.FILTERS_PRESETS[presetName]) do
			local filterTableFilePath = FileUtils:BuildRelativeJsonFileTargetPath(filterTableName,
				Config.AIM.PRESETS.PRESETS_DIR,
				presetName)
			local filterTable = FileUtils:LoadFile(filterTableFilePath)

			if filterTable then
				local success, result = pcall(function()
					Logger:BasicInfo(string.format(
						"Merging %s/%s.json into active itemMaps",
						presetName,
						filterTableName))

					ItemFilters:AddItemFilterMaps({ [filterTableName] = Ext.Json.Parse(filterTable) },
						false,
						false,
						false)
				end)

				if not success then
					Logger:BasicError(string.format("Could not merge table %s from preset %s due to error [%s]",
						filterTableName,
						presetName,
						result))
				end
			else
				Logger:BasicWarning("Could not find filter table file " .. filterTableFilePath)
			end
		end
		::continue::
	end
	ItemFilters:UpdateItemMapsClone()
	if Logger:IsLogLevelEnabled(Logger.PrintTypes.DEBUG) then
		Logger:BasicDebug("Finished loading in presets - finalized item maps are:")
		for itemMap, itemMapContent in pairs(ItemFilters.itemMaps) do
			Logger:BasicDebug(string.format("%s: %s", itemMap, Ext.Json.Stringify(itemMapContent)))
		end
	end
end

function Config.SyncConfigsAndFilters()
	Logger:ClearLogFile()

	local config = FileUtils:LoadFile("config.json")

	if config then
		config = Ext.Json.Parse(config)
	end

	if not config or config.RESET_CONFIGS == 1 then
		InitializeConfigurations()
		Logger:BasicInfo("Initializing all the configs!")

		config = Config.AIM
	end

	Upgrade:ConfigFile(config)

	Config.AIM = config

	InitializeFilterPresetsAndUpgradeLegacyFilters()

	LoadAndMergeItemMapsFromActivePresets()

	ItemBlackList:InitializeBlackList()
end
