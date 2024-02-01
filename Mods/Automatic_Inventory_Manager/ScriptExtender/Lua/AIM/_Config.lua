Ext.Require("AIM/FilterPresets/_AllDefaults.lua")
Ext.Require("AIM/FilterPresets/_CampGoldBooks.lua")

Config = {}

Config.IsInitialized = false

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

	if not Config.AIM.PRESETS.ACTIVE_PRESETS or next(Config.AIM.PRESETS.ACTIVE_PRESETS) == nil then
		Config.AIM.PRESETS.ACTIVE_PRESETS = { [Preset_AllDefaults.Name] = { "ALL" } }
	end

	FileUtils:SaveTableToFile("config.json", Config.AIM)
end

function Config.SyncConfigsAndFilters()
	Logger:ClearLogFile()
	Logger:BasicInfo("AIM has begun initialization!")

	local config = FileUtils:LoadTableFile("config.json")

	if not config or config.RESET_CONFIGS == 1 then
		InitializeConfigurations()
		Logger:BasicInfo("Initializing all the configs!")

		config = Config.AIM
	end

	for prop, val in pairs(Config.AIM) do
		if not config[prop] then
			config[prop] = val
		end
	end

	for presetName, preset in pairs(Config.AIM.PRESETS.FILTERS_PRESETS) do
		config.PRESETS.FILTERS_PRESETS[presetName] = preset
	end

	Upgrade:ConfigFile(config)

	Config.AIM = config

	InitializeFilterPresetsAndUpgradeLegacyFilters()

	ItemFilters:LoadItemFilterPresets()

	ItemBlackList:InitializeBlackList()

	Logger:BasicInfo("AIM has finished initialization!")
	Config.IsInitialized = true
end
