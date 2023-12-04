-- Helpers for mapping items to criteria tables 
local EQUIPTYPE_UUID_TO_NAME_MAP = {}
for _, equipTypeUUID in pairs(Ext.StaticData.GetAll("EquipmentType")) do
	EQUIPTYPE_UUID_TO_NAME_MAP[equipTypeUUID] = Ext.StaticData.Get(equipTypeUUID, "EquipmentType")["Name"]
end

function GetEquipmentType(item)
	local equipTypeUUID = Ext.Entity.Get(item).ServerItem.Item.OriginalTemplate.EquipmentTypeID
	return EQUIPTYPE_UUID_TO_NAME_MAP[equipTypeUUID]
end


TAG_UUID_TO_NAME_MAP = {}
for _, tagUUID in pairs(Ext.StaticData.GetAll("Tag")) do
	TAG_UUID_TO_NAME_MAP[tagUUID] = Ext.StaticData.Get(tagUUID, "Tag")["Name"]
end

--- @class Criteria
--- @field Stat string
--- @field Comparator COMPARATOR

MODE = 'MODE'
------------
MODE_DIRECT = 'DIRECT'
TARGET = 'TARGET'
------------
ALL_ITEMS_MATCHING_MAP_CATEGORY = "ALL"
------------
MODE_WEIGHT_BY = 'WEIGHT_BY'
CRITERIA = 'CRITERIA'
STACK_LIMIT = 'STACK_LIMIT'
------------
COMPARATOR = "COMPARATOR"
LOWER = "LOWER"
HIGHER = "HIGHER"
---@alias COMPARATOR string|"LOWER"|"HIGHER"
------------
STAT = "STAT"
STAT_HEALTH_PERCENTAGE = "HEALTH_PERCENTAGE"
STAT_STACK_AMOUNT = "STACK_AMOUNT"
STAT_PROFICIENCY = "PROFICIENCY"
STAT_WEAPON_SCORE = "WEAPON_SCORE"
STAT_WEAPON_ABILITY = "WEAPON_ABILITY"
STAT_HAS_TYPE_EQUIPPED = "HAS_TYPE_EQUIPPED"
STAT_SKILL = "SKILL" -- Use Ext.Enums.SkillId
------------

WEAPON_MAP = {
	[ALL_ITEMS_MATCHING_MAP_CATEGORY] = {
		[MODE] = MODE_WEIGHT_BY,
		[CRITERIA] = {
			[1] = { [STAT] = STAT_HAS_TYPE_EQUIPPED},
			[2] = { [STAT] = STAT_WEAPON_ABILITY, [COMPARATOR] = HIGHER },
			[3] = { [STAT] = STAT_WEAPON_SCORE, [COMPARATOR] = HIGHER },
		}
	}
}

EQUIPMENT_MAP = {
	[ALL_ITEMS_MATCHING_MAP_CATEGORY] = {
		[MODE] = MODE_WEIGHT_BY,
		[CRITERIA] = {
			[1] = { [STAT] = STAT_PROFICIENCY },
		}
	}
}

TAGS_MAP = {
	["HEALING_POTION"] = {
		[MODE] = MODE_WEIGHT_BY,
		[CRITERIA] = {
			[1] = { [STAT] = STAT_HEALTH_PERCENTAGE, [COMPARATOR] = LOWER, },
			[2] = { [STAT] = STAT_STACK_AMOUNT, [COMPARATOR] = LOWER }
		},
		[STACK_LIMIT] = 2
	},
	["LOCKPICKS"] = {
		[MODE] = MODE_WEIGHT_BY,
		[CRITERIA] = {
			[1] = { [STAT] = STAT_SKILL, [STAT_SKILL] = "SleightOfHand", [COMPARATOR] = HIGHER, },
			[2] = { [STAT] = STAT_STACK_AMOUNT, [COMPARATOR] = HIGHER }
		}
	}
}
