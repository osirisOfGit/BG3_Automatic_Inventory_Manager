EQUIPTYPE_UUID_TO_NAME_MAP = {}
for _, equipTypeUUID in pairs(Ext.StaticData.GetAll("EquipmentType")) do
    EQUIPTYPE_UUID_TO_NAME_MAP[equipTypeUUID] = Ext.StaticData.Get(equipTypeUUID, "EquipmentType")["Name"]
end

TAG_UUID_TO_NAME_MAP = {}
for _, tagUUID in pairs(Ext.StaticData.GetAll("Tag")) do
    TAG_UUID_TO_NAME_MAP[tagUUID] = Ext.StaticData.Get(tagUUID, "Tag")["Name"]
end

MODE = 'MODE'

------------
MODE_DIRECT = 'DIRECT'
TARGET = 'TARGET'
------------
MODE_WEIGHT_BY = 'WEIGHT_BY'
CRITERIA = 'CRITERIA'

COMPARATOR = "COMPARATOR"
COMPARATOR_LT = "LT"
COMPARATOR_GT = "GT"

STAT = "STAT"
STAT_HEALTH_PERCENTAGE = "HEALTH %"
STAT_STACK_AMOUNT = "STACK AMOUNT"
------------

ITEMS_TO_PROCESS_MAP = {
    ['Dagger'] = {
        [MODE] = MODE_DIRECT,
        [TARGET] = 'S_Player_Gale_ad9af97d-75da-406a-ae13-7071c563f604'
    },
    ["HEALING_POTION"] = {
        [MODE] = MODE_WEIGHT_BY,
        [CRITERIA] = {
            [1] = { [STAT] = STAT_HEALTH_PERCENTAGE, [COMPARATOR] = COMPARATOR_LT, },
            [2] = { [STAT] = STAT_STACK_AMOUNT, [COMPARATOR] = COMPARATOR_LT }
        }
    }
}


-- Larians Tags(Public/shared/Tags/)

-- Custom Tags (/Public/Automatic_Inventory_Manager/Tags)
TAG_AIM_PROCESSED = "add41a41-a1a8-4405-ae7f-ce12a0788a1a"
TAG_AIM_MARK_FOR_DELETION = "4b640e87-509b-4c90-a4e7-144c224314b0"

-- Supports Item GUID (Name + MapKey) and Root GUID (parentTemplate name + MapKey). <br/>
-- Returns an array of 1-many tags to add
OPTIONAL_TAGS = {
}

TAGS_TO_CLEAR = { TAG_AIM_PROCESSED }
for _, tags in pairs(OPTIONAL_TAGS) do
    for _, tag in pairs(tags) do table.insert(TAGS_TO_CLEAR, tag) end
end

ITEMS_TO_DELETE = {}

-- Most of this was stolen from Auto_Sell_Loot. Cheers m8 ヾ(⌐■_■)ノ♪
Config = {
    initDone = false,
    config_tbl = { MOD_ENABLED = 1 },
    config_json_file_path = "config.json",
    logPath = "log.txt",
    resetAllStacks = true
    -- CurrentVersion = Ext.Mod.GetMod(MOD_UUID).Info.ModVersion[1].."."..Ext.Mod.GetMod(MOD_UUID).Info.ModVersion[2].."."..Ext.Mod.GetMod(MOD_UUID).Info.ModVersion[3].."."..Ext.Mod.GetMod(MOD_UUID).Info.ModVersion[4],
}

-- CUSTOM EVENTS

EVENT_CLEAR_CUSTOM_TAGS_START = "AIM_CLEAR_CUSTOM_TAGS_START"
EVENT_CLEAR_CUSTOM_TAGS_END = "AIM_CLEAR_CUSTOM_TAGS_END"

EVENT_ITERATE_ITEMS_TO_REBUILD_THEM_START = "AIM_REBUILD_ITEMS_START"
EVENT_ITERATE_ITEMS_TO_REBUILD_THEM_END = "AIM_REBUILD_ITEMS_END"
