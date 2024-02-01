Upgrade = {}

--- Existing FILTERS_DIR and FILTER_TABLES config porting handled in InitializeFilterPresetsAndMigrateLegacy
function Upgrade:ConfigFile(config)
	local MODIFIED_CONFIG_NAMES = {
		SYNC_FILTERS = "MERGE_DEFAULT_FILTERS",    -- 1.1.0
		SORT_ITEMS_ON_LOAD = "SORT_ITEMS_ON_FIRST_LOAD", -- 2.0.0
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

--- If the Config file contains the FILTERS_DIR and FILTER_TABLES properties, copy the identified tables to the new AIM-Migrated-Custom-Filter-Preset
function Upgrade:LegacyFiltersToPresets()
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
			filterTableContents = FileUtils:LoadTableFile(FileUtils:BuildRelativeJsonFileTargetPath(filterTableName,
				Config.AIM["FILTERS_DIR"]))

			if filterTableContents then
				for _, itemFilter in pairs(filterTableContents) do
					if itemFilter["Modifiers"] then
						itemFilter["PreFilters"] = itemFilter["Modifiers"]
						itemFilter["Modifiers"] = nil
					end
				end

				local success = FileUtils:SaveTableToFile(
					FileUtils:BuildRelativeJsonFileTargetPath(filterTableName, Config.AIM.PRESETS.PRESETS_DIR,
						customPresetName),
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

		Config.AIM.PRESETS.ACTIVE_PRESETS = { [customPresetName] = { "ALL" } }
		Config.AIM["FILTERS_DIR"] = nil
		Config.AIM["FILTER_TABLES"] = nil
	end
end
