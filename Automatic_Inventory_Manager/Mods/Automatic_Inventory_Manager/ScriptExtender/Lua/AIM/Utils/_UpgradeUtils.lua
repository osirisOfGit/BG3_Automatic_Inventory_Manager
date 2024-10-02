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

