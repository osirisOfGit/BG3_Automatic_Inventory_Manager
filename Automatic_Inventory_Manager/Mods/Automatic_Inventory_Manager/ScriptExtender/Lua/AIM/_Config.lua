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
	RECORD_APPLICABLE_ENTITY_PROPS = 0,
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

--- Initializes the presets from AIM/FilterPresets/, overwriting directory contents
local function InitializeFilterPresets()
	ItemFilters:RegisterItemFilterMapPreset(ModUtils:GetAIMModInfo().ModuleUUID, Preset_AllDefaults.Name, Preset_AllDefaults.ItemFilterMaps)
	ItemFilters:RegisterItemFilterMapPreset(ModUtils:GetAIMModInfo().ModuleUUID, Preset_CampGoldBooks.Name, Preset_CampGoldBooks.ItemFilterMaps)

	if not Config.AIM.PRESETS.ACTIVE_PRESETS or next(Config.AIM.PRESETS.ACTIVE_PRESETS) == nil then
		Config.AIM.PRESETS.ACTIVE_PRESETS = { [ModUtils:GetAIMModInfo().Name .. "-" .. Preset_AllDefaults.Name] = { "ALL" } }
	end

	FileUtils:SaveTableToFile("config.json", Config.AIM)
end

function Config.SyncConfigsAndFilters()
	local startTime = Ext.Utils.MonotonicTime()
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

	Config.AIM = config

	AIM_MCM_API:SyncAllConfigsOnLoad()

	InitializeFilterPresets()

	ItemFilters:LoadItemFilterPresets()

	ItemBlackList:InitializeBlackList()

	EntityPropertyRecorder:LoadRecordedItems()

	Config.IsInitialized = true
	Logger:BasicInfo("AIM has finished initialization in %dms!", Ext.Utils.MonotonicTime() - startTime)
end
