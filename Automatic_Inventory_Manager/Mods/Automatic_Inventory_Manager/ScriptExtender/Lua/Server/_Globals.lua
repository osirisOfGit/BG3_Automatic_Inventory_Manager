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
STACK_LIMIT = 'STACK_LIMIT'
------------
COMPARATOR = "COMPARATOR"
HAS_LESS = "HAS_LESS"
HAS_MORE = "HAS_MORE"
------------
STAT = "STAT"
STAT_HEALTH_PERCENTAGE = "HEALTH %"
STAT_STACK_AMOUNT = "STACK AMOUNT"
STAT_PROFICIENCY = "PROFICIENCY"
------------


ITEMS_TO_PROCESS_MAP = {
    ['Dagger'] = {
        [MODE] = MODE_WEIGHT_BY,
        [CRITERIA] = {
            [1] = { [STAT] = STAT_PROFICIENCY }
        }
    },
    ["HEALING_POTION"] = {
        [MODE] = MODE_WEIGHT_BY,
        [CRITERIA] = {
            [1] = { [STAT] = STAT_HEALTH_PERCENTAGE, [COMPARATOR] = HAS_LESS, },
            [2] = { [STAT] = STAT_STACK_AMOUNT, [COMPARATOR] = HAS_LESS }
        },
        [STACK_LIMIT] = 2
    }
}

-- Since moving/creating items in a way that ensures a new item UUID is created is an event, not just a DB update, you can't just move an item and immediately tag it as processed <br/>
-- You need to move it, then wait for the *AddedTo event to fire. So, this global map serves as a tracker for what templates
-- were added to which characters, so that when that event fires, _hopefully_ we can match it and not process it again
TEMPLATES_BEING_TRANSFERRED = {}


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
    for _, tag in pairs(tags) do
        table.insert(TAGS_TO_CLEAR, tag)
    end
end

ITEMS_TO_DELETE = {}

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
