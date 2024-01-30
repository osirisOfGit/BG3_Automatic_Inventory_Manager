Ext.Require("AIM/FilterPresets/_AllDefaults.lua")
Ext.Require("AIM/FilterPresets/_CampGoldBooks.lua")

Config = {}

Config.AIM = {
	ENABLED = 1,
	RESET_CONFIGS = 0,
	LOG_LEVEL = 3,
	SORT_ITEMS_ON_LOAD = 1,
	PRESETS = {
		PRESETS_DIR = "presets",
		ACTIVE_PRESETS = {},
		FILTERS_PRESETS = {}
	}
}

local function InitializeConfigurations()
	Logger:BasicInfo(
		"Initializing configs - will completely remove any customizations to config.json, including custom presets (custom preset directories will be unaffected)")
	Config.AIM.RESET_CONFIGS = 0

	Utils:SaveTableToFile("config.json", Config.AIM)
end

--- Existing FILTERS_DIR and FILTER_TABLES config porting handled in InitializeFilterPresetsAndMigrateLegacy
local function UpdateConfigFile(config)
	for prop, val in pairs(Config.AIM) do
		if not config[prop] then
			config[prop] = val
		end
	end

	local MODIFIED_CONFIG_NAMES = {
		SYNC_FILTERS = "MERGE_DEFAULT_FILTERS" -- 1.1.0
	}

	for oldProp, newProp in pairs(MODIFIED_CONFIG_NAMES) do
		if config[oldProp] then
			config[newProp] = config[oldProp]
			config[oldProp] = nil
		end
	end

	local REMOVED_CONFIG_NAMES = {
		"SYNC_CONFIGS",   -- 1.1.0
		"MERGE_DEFAULT_FILTERS" -- 2.0.0
	}
	for _, oldProp in pairs(REMOVED_CONFIG_NAMES) do
		config[oldProp] = nil
	end
end

--- Initializes the presets from AIM/FilterPresets/, overwriting directory contents, and migrates 1.x FILTER_DIR and FILTER_TABLES config properties to new structure,
--- copying existing files over to a custom preset directory and activating it. If no legacy configs are detected, sets Preset_AllDefaults as the active preset
local function InitializeFilterPresetsAndMigrateLegacy()
	Logger:BasicDebug("Creating and saving default preset - " .. Preset_CampGoldBooks.Name)
	Config.AIM.PRESETS.FILTERS_PRESETS[Preset_CampGoldBooks.Name] = {}
	for mapName, itemFilterMap in pairs(Preset_CampGoldBooks.ItemMaps) do
		table.insert(Config.AIM.PRESETS.FILTERS_PRESETS[Preset_CampGoldBooks.Name], mapName)
		Utils:SaveTableToFile(
			Utils:BuildRelativeJsonFileTargetPath(mapName, Config.AIM.PRESETS.PRESETS_DIR, Preset_CampGoldBooks.Name),
			itemFilterMap)
	end

	Logger:BasicDebug("Creating and saving default preset - " .. Preset_AllDefaults.Name)
	Config.AIM.PRESETS.FILTERS_PRESETS[Preset_AllDefaults.Name] = {}
	for mapName, itemFilterMap in pairs(Preset_AllDefaults.ItemMaps) do
		table.insert(Config.AIM.PRESETS.FILTERS_PRESETS[Preset_AllDefaults.Name], mapName)
		Utils:SaveTableToFile(
			Utils:BuildRelativeJsonFileTargetPath(mapName, Config.AIM.PRESETS.PRESETS_DIR, Preset_AllDefaults.Name),
			itemFilterMap)
	end

	if Config.AIM["FILTERS_DIR"] and (not Config.AIM["FILTER_TABLES"] or #Config.AIM["FILTER_TABLES"] == 0) then
		Logger:BasicError(
			"The legacy config 'FILTERS_DIR' is present, but the 'FILTER_TABLES' property is either missing or empty,"
			..
			" so AIM is unable to copy existing files into a new preset. Please either delete the 'FILTERS_DIR' and 'FILTER_TABLES' property if you don't want your current itemMaps copied,"
			.. " or specify which itemMaps to copy in the 'FILTER_TABLES' property.")
	elseif not Config.AIM["FILTERS_DIR"] and (Config.AIM["FILTER_TABLES"] and #Config.AIM["FILTER_TABLES"] > 0) then
		Logger:BasicError(
			"The legacy config 'FILTER_TABLES' is present, but the 'FILTERS_DIR' property is either missing or empty,"
			..
			" so AIM is unable to copy existing files into a new preset. Please either delete the 'FILTERS_DIR' and 'FILTERS_TABLES' property if you don't want your current itemMaps copied,"
			.. " or specify which directory your custom files to copy are in via the 'FILTERS_DIR' property.")
	elseif Config.AIM["FILTERS_DIR"] and (Config.AIM["FILTER_TABLES"] and #Config.AIM["FILTER_TABLES"] > 0) then
		local customPresetName = "AIM-Migrated-Custom-Filter-Preset"
		Logger:BasicInfo("Migrating legacy configs FILTER_TABLES and FILTERS_DIR into the custom preset " ..
			customPresetName)
		Config.AIM.PRESETS.FILTERS_PRESETS[customPresetName] = {}

		local filterTableContents
		for _, filterTableName in pairs(Config.AIM["FILTER_TABLES"]) do
			filterTableContents = Utils:LoadFile(Utils:BuildRelativeJsonFileTargetPath(filterTableName,
				Config.AIM["FILTERS_DIR"]))

			if filterTableContents then
				local success = Utils:SaveStringContentToFile(
					Utils:BuildRelativeJsonFileTargetPath(filterTableName, Config.AIM.PRESETS.PRESETS_DIR, customPresetName),
					filterTableContents)

				if success then
					table.insert(Config.AIM.PRESETS.FILTERS_PRESETS[customPresetName], filterTableName)
					Logger:BasicInfo(string.format("Successfully added itemMap %s to preset %s", filterTableName,
						customPresetName))
				else
					Logger:BasicWarning(string.format(
						"Operation to save custom table %s failed - will not be including in custom preset %s. See previous logs for error details.",
						filterTableName, customPresetName))
				end
			else
				Logger:BasicWarning(string.format("Custom FilterTable %s was empty! Will not copy over into Preset %s",
					filterTableName, customPresetName))
			end
		end

		Config.AIM.PRESETS.ACTIVE_PRESETS = { customPresetName }
		Config.AIM["FILTERS_DIR"] = nil
		Config.AIM["FILTER_TABLES"] = nil
	end

	if not Config.AIM.PRESETS.ACTIVE_PRESETS or #Config.AIM.PRESETS.ACTIVE_PRESETS == 0 then
		table.insert(Config.AIM.PRESETS.ACTIVE_PRESETS, Preset_AllDefaults.Name)
	end

	Utils:SaveTableToFile("config.json", Config.AIM)
end


local function LoadAndMergeItemMapsFromActivePresets()
	if not Config.AIM.PRESETS.ACTIVE_PRESETS or #Config.AIM.PRESETS.ACTIVE_PRESETS == 0 then
		Logger:BasicError("Config property ACTIVE_PRESETS isn't populated - can't determine which preset(s) to load, so AIM functionality will not work."
		.. " If this is intentional, activating one of the default presets and setting ENABLED to 0 is the preferred approach."
		.. " Setting ENABLED to 0 in-memory to avoid exceptions during execution.")
		Config.AIM.ENABLED = 0
		return
	elseif not Config.AIM.PRESETS.FILTERS_PRESETS then
		Logger:BasicError("Config property FILTERS_PRESETS isn't populated - this means there are no filter maps to load, so AIM functionality will not work."
		..
		" If this is intentional, listing at least one of the presets (defaults should be loaded for you) and setting ENABLED to 0 is the preferred approach."
		.. " Setting ENABLED to 0 in-memory to avoid exceptions during execution.")
		Config.AIM.ENABLED = 0
		return
	end

	for _, presetName in pairs(Config.AIM.PRESETS.ACTIVE_PRESETS) do
		Logger:BasicInfo("Loading filter preset " .. presetName)
		if not Config.AIM.PRESETS.FILTERS_PRESETS[presetName] then
			Logger:BasicError(string.format("Specified preset %s was not present in the FILTERS_PRESETS property - please specify a real map (case sensitive)"))
			goto continue
		end
		for _, filterTableName in pairs(Config.AIM.PRESETS.FILTERS_PRESETS[presetName]) do
			local filterTableFilePath = Utils:BuildRelativeJsonFileTargetPath(filterTableName, Config.AIM.PRESETS.PRESETS_DIR,
				presetName)
			local filterTable = Utils:LoadFile(filterTableFilePath)

			if filterTable then
				local success, result = pcall(function()
					Logger:BasicInfo(string.format(
						"Merging %s.json from preset %s into active itemMaps",
						filterTableName,
						presetName))

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
 end

function Config.SyncConfigsAndFilters()
	Logger:ClearLogFile()
	
	PersistentVars = nil

	local config = Utils:LoadFile("config.json")

	if config then
		config = Ext.Json.Parse(config)
	end

	if not config or config.RESET_CONFIGS == 1 then
		InitializeConfigurations()
		Logger:BasicInfo("Initializing all the configs!")

		config = Config.AIM
	end

	UpdateConfigFile(config)

	Config.AIM = config

	InitializeFilterPresetsAndMigrateLegacy()

	LoadAndMergeItemMapsFromActivePresets()
end
