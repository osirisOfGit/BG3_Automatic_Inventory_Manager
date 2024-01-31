# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0]
### TODO:
- Implement ModifierProcessors for per-item modifiers
- Update ItemFilters API methods to create presets instead of updating the itemMap
- Retest vanilla ItemBlackList
- Update documentation
- Update Sample Mod to use new functionality


### Mod Users
#### Added
- Presets functionality
- Modifiers
	- EXCLUDE_PARTY_MEMBERS
- ItemBlackList.json
- Configurations
	- SORT_ITEMS_DURING_COMBAT
	- SORT_CONSUMABLE_ITEMS_ON_USE_DURING_COMBAT
	- PRESETS
		- PRESETS_DIR
		- ACTIVE_PRESETS
		- FILTERS_PRESETS
#### Changed
- Configurations
	- SORT_ITEMS_ON_LOAD -> SORT_ITEMS_ON_FIRST_LOAD - will only apply to the first load in a campaign (assuming a save happens) - implemented a PersistentVar to prevent processing after that, since all items in inventory should be tagged
#### Removed
- Configurations
	- MERGE_DEFAULT_FILTERS
	- FILTERS_DIR
	- FILTER_TABLES

### API
#### Added
- Processors/_ModifierProcessors
#### Fixed
- Documentation
	- Corrected _CoreProcessor spelling
#### Removed
- Documentation
	- Logger
	- File utilities

### Internal Only
#### Added
- Changelog
- Logger:IsLogLevelActive
- Utils/_ModUtils
#### Changed
- Moved _Logger into Utils/
- Wrapped logs using Ext.Json.Stringify in Logger:IsLogLevelActive checks
- Exploded _Utils into Utils/FileUtils and Utils/TableUtils
#### Fixed
- _ItemFilters:MergeItemFiltersIntoTarget not accounting for stringified number indexes (thanks JSON)
