# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

**Mod Users** - to review any changes more in-depth, check the relevant sections of [the wiki](https://github.com/osirisOfGit/BG3_Automatic_Inventory_Manager/wiki)

## [2.2.1]
### Mod Users
#### Changed
- Processing on item pickup no longer happens when there's only one character in the party, but items are still tagged
- ALL_DEFAULTS preset
	- Changed priority of Proficiency filter for all Equipment up to 51 from 99
- Improved some log info

### Internal Only
#### Changed
- Stopped being the dumb kind of lazy and consolidated string.format into the Logger:Basic* funcs
#### Fixed
- Non-nil safe logs

## [2.2.0]
### Mod Users
#### Added
- Per-Stack Prefilter EXCLUDE_CLASSES_OR_SUBCLASSES, which accepts a single value or an array
- Filter IS_ONE_OF_CLASS_OR_SUBCLASS, which accepts a single value or an array under TargetSubStat

#### Changed
- Automatic_Inventory_Manager-All-Defaults /Weapons.json and /Equipment.json so stack amount is the highest priority filter 
for all applicable items, and Weapon filters are prioritized over Equipment filters when applicable

#### Fixed
- HAS_TYPE_EQUIPPED and PROFICIENCY filter never running
- The Consumable Tag check that's run on item use, so only consumables should be run again

### Internal
#### Added 
- Performance timing to some methods

## [2.1.2]
### Mod Users
#### Fixed
- Changed mod name back to Automatic_Inventory_Manager (with underscores) to fix preset functionality

## [2.1.1]
### Mod Users
- Fixed the pak'ing process, so it shouldn't reset the modsettings.lsx when managing load order with Vortex

## [2.1.0]
### Mod Users
#### Added
- Config RECORD_APPLICABLE_ENTITY_PROPS and the associated functionality (see wiki)
- [Transmog Enhanced](https://www.nexusmods.com/baldursgate3/mods/2922) and [Lodestones](https://www.nexusmods.com/baldursgate3/mods/6244) items to ItemBlackList by default
#### Fixed
- Weapons itemFilterMap now uses rootTemplateUUID, not itemUUID, as a key
- Equipment itemFilterMap now uses the Larian values for main/offhand equipment slot values
#### Changed
- Equipment itemFilterMap now accepts the Root Template UUID and the Entity fields Equipable.Slot and Armor.ArmorType as a valid key
- Equipment and Weapon itemFilterMaps now accept `ServerItem.Template.EquipmentTypeID` (translated to human) as a valid key
- TargetStat HAS_TYPE_EQUIPPED now checks armorType as well as equipmentType
- Target filters now accept any party members as a target, including ones at camp
- ItemBlackList now accepts partial item or root UUIDs

### API
#### Added
- EntityPropertyRecorder module, with corresponding sample in `Example\Mods\Mod_Using_AIM\ScriptExtender\Lua\_CustomFilters.lua`

### Internal Only
- Skip any EquipmentTypeId logic if the value is `"00000000-0000-0000-0000-000000000000"`


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
