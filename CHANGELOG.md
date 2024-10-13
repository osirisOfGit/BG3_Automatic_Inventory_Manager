# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

**Mod Users** - to review any changes more in-depth, check the relevant sections of [the wiki](https://github.com/osirisOfGit/BG3_Automatic_Inventory_Manager/wiki)

## [2.4.1]
### Mod Users
#### Changed
- ItemsBlackList
  - Added to container roots:
	- `"TCP_OBJ_TUTORIALCHEST"` -- Another tutorial chest, possibly specific to Tutorial Chest Summoning <https://www.nexusmods.com/baldursgate3/mods/457>
	- `"SYR_OBJ_"` -- Immersive Tutorial Chest Spawning and more - <https://www.nexusmods.com/baldursgate3/mods/4687>
  - Added to RootTemplates:
	- `"U_AUTOLOOTTOGGLE"` -- Customizable Auto Loot Aura - <https://www.nexusmods.com/baldursgate3/mods/2342>

#### Fixed
- AIM not copying `false` values from pre-defined MCM configs

## [2.4.0]
### Mod Users
#### Added
- Optional MCM Integration
	- Important Info: This release only supports the non-preset options, as those are natively supported by MCM; presets are dynamic, hierarchal, and unpredictable, and thus require more than just pre-defined flat values, so i'll look into that at a later date. Due to this, MCM integration is optional, as the config.json is still actively supported and synced with MCM - any changes you make to either will be copied over to the other.
		- HOWEVER, since AIM's config.json requires a re-load/SE reset to take effect, this means that the config.json is copied over into MCM on session load - if you make any changes to the relevant settings.json under MCM directly, without using the MCM UI, they will be overwritten by AIM on load.
		- If the config.json doesn't exist on save load, but the MCM configs do, the MCM values will be copied into the config.json, and any missing configs will be generated and set to their defaults
- `RESPECT_CONTAINER_BLACKLIST_FOR_CUSTOM_STACK_CALCULATIONS` config option
  - See [Wiki Section](https://github.com/osirisOfGit/BG3_Automatic_Inventory_Manager/wiki/Customizing-AIM's-Behavior#customizing-how-stack_amount-is-calculated) 

#### Fixed
- `FallenStar_Cons_Wifi` Root Blacklist

### Internal Only
#### Fixed
- Actual fix for items processed by TransmogEnhanced

#### Changed
- Tweaked debug logs again, mainly around STACK_AMOUNT calculation

## [2.3.1]
### Mod Users
### Added
- All containers from [Trade with Withers Addon - Containers](https://www.nexusmods.com/baldursgate3/mods/9397) to the ContainerBlacklist

### Changed
- Tags.json
	- TOOL now uses [CalculateStackingUsing](https://github.com/osirisOfGit/BG3_Automatic_Inventory_Manager/wiki/Customizing-AIM's-Behavior#customizing-how-stack_amount-is-calculated) for the Tool tag

### Internal Only
#### Changed
- Tweaking Logs - Debug logs are more generally helpful and generally less noisy now
#### Fixed
- ItemTracker not clearing an already-distributed item
- Tags ItemFilterLookups not being case-insensitive

## [2.3.0]
### Mod Users
#### Added
- New optional `CalculateStackUsing` option for `STACK_AMOUNT` filters, accepting any combination of `ROOTS`, `TAGS`, `ARMOR_TYPES`, and `EQUIPMENT_TYPES` - values are array of strings or single string (Use [EntityPropertyRecorder](https://github.com/osirisOfGit/BG3_Automatic_Inventory_Manager/wiki/Configurations#entity-property-recorder))
	- See [Wiki Entry](https://github.com/osirisOfGit/BG3_Automatic_Inventory_Manager/wiki/Customizing-AIM's-Behavior#customizing-how-stack_amount-is-calculated)
- Ability to blacklist items by TAG
- ContainerRoots to ItemBlackList, which controls whether items present in that container should be sorted. Runs recursively.
	- See [Wiki Entry](https://github.com/osirisOfGit/BG3_Automatic_Inventory_Manager/wiki/Configurations#blacklisting-items) 
- Following entries to ItemBlackList by default:
	- Roots
		- "FallenStar_Wifi_" -- Wifi Potions - https://www.nexusmods.com/baldursgate3/mods/5080
	- ContainerRoots
		- "CONT_ISF_Container" -- ItemShipmentFramework - https://www.nexusmods.com/baldursgate3/mods/8295
		- "TUT_Chest_Potions" -- Pretty sure this is the tutorial chest

#### Changed
- ALL_DEFAULTS preset
	- Tags.json
		- ARROWS, COATINGS, GRENADES, HEALING_POTIONS, and SCROLLS use the new `CalculateStackUsing` option to find the character with the most
		amount of items with the respective tag, if a winner could not be chosen based on template alone
 	- Equipment.json
		- Moved the `HAS_TYPE_EQUIPPED` filter from Weapons.json to Equipment.json, making it the highest priority filter (all weapons are equipment, not all equipment are weapons)
		- All equipable items use the new `CalculateStackUsing` option `EQUIPMENT_TYPES` and `ARMOR_TYPES` to go to the char with the most amount of identical equipment/armor types (Javelins now go to the character with different kinds of javelins, and scaleMail goes to character with scaleMail in their inventory!)
	- Roots.json
		- Increased stack_limit size for Barkskin potions to 2 (why do i even have this?)
- Tweaked some debug logs
- Case-insensitive ItemFilter lookups - e.g. `Tool` tag will now match `TOOL` and `tool` and `tOOl` in the Tags.json
- Case-insensitive Blacklist lookups

#### Fixed
- `CompareStategy` to `CompareStrategy` - AIM will automatically fix this for you, no manual changes needed

#### Removed
- Upgrade Utilities designed for the 1.x to 2.x migration - if you're still somehow using a 1.x version of this mod, nuke your AIM config folder and just reinstall it

### API
#### Added
- `ProcessorUtils:RegisterCustomStackCalculator` method to allow adding new ways of calculating stack size
- `ItemBlackList:IsContainerInBlacklist`

### Internal Only
#### Added
- Run sorting automatically on characters when they join the party (tagging their equipped items as already processed)
- Check for AIM_PROCESSED tag on TemplateAddedTo event
- Check if the item is in a blacklisted container when processing a newly added or existing item in character inventory

#### Fixed
- Sorting triggering if a template is added to the char's inventory, but is also equipped - fixes transmog behavior and manifested weapons

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
