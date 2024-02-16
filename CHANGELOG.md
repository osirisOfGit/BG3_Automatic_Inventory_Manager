# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0]
### Mod Users
### Added
- Equipment.json itemFilterMap now accepts the Root Template UUID as a valid key
### Fixed
- Weapons.json now uses rootTemplateUUID, not itemUUID
### Changed
- Target filters now accept any party members as a target, including ones at camp

## [2.0.1]
### Mod Users
#### Fixed
- ItemStack size logic for STACK_LIMIT prefilter and STACK_AMOUNT filter

### Internal only
#### Changed
- TemplateAddedTo event firing on `before`, not `after`
- More/betterer logs                                                                                      

## [2.0.0]
### Mod Users
#### Added
- Presets functionality
- PreFilters
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
- Rename Modifiers to PreFilters
- Configurations
	- SORT_ITEMS_ON_LOAD -> SORT_ITEMS_ON_FIRST_LOAD - will only apply to the first load in a campaign (assuming a save happens) - implemented a PersistentVar to prevent processing after that, since all items in inventory should be tagged
#### Removed
- Configurations
	- MERGE_DEFAULT_FILTERS
	- FILTERS_DIR
	- FILTER_TABLES

### API
#### Added
- Processors/_PreFilterProcessors
#### Fixed
- Documentation
	- Corrected _CoreProcessor spelling
#### Changed
- Existing methods that added new processors or functions now require modUUID to be passed in
- Existing Add* methods have been renamed to Register*
- Rename RegisterStatFunctions to RegisterTargetStatProcessors
- Broke out SampleMod's samples and fleshed them out more
#### Removed
- Documentation
	- Logger
	- File utilities

### Internal Only
#### Added
- Changelog
- Logger:IsLogLevelActive
- Utils/_ModUtils
- Utils/_UpgradeUtils
#### Changed
- Moved _Logger into Utils/
- Wrapped logs using Ext.Json.Stringify in Logger:IsLogLevelActive checks
- Exploded _Utils into Utils/FileUtils and Utils/TableUtils
#### Fixed
- _ItemFilters:MergeItemFiltersIntoTarget not accounting for stringified number indexes (thanks JSON)
