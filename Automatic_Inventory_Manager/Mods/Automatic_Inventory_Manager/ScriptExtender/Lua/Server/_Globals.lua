-- Larians Tags(Public/shared/Tags/)

-- Custom Tags (/Public/Automatic_Inventory_Manager/Tags)
TAG_AIM_PROCESSED = "add41a41-a1a8-4405-ae7f-ce12a0788a1a"
TAG_AIM_MARK_FOR_DELETION = "4b640e87-509b-4c90-a4e7-144c224314b0"

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
