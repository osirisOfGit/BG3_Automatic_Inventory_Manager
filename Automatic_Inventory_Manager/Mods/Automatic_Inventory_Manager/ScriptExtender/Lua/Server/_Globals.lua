EQUIPTYPE_UUID_TO_NAME_MAP = {}
for _, equipTypeUUID in pairs(Ext.StaticData.GetAll("EquipmentType")) do
	EQUIPTYPE_UUID_TO_NAME_MAP[equipTypeUUID] = Ext.StaticData.Get(equipTypeUUID, "EquipmentType")["Name"]
end
_P("Finished initializing EQUIP_TYPE_TO_NAME_MAP")

EQUIPMENT_TYPE_MAP = {
    ['Dagger'] = 'S_Player_Gale_ad9af97d-75da-406a-ae13-7071c563f604'
}

-- Most of this was stolen from Auto_Sell_Loot. Cheers m8 ヾ(⌐■_■)ノ♪
Config = { 
    initDone = false,
    config_tbl = { MOD_ENABLED = 1 },
    config_json_file_path = "config.json",
    logPath = "log.txt",
    -- CurrentVersion = Ext.Mod.GetMod(MOD_UUID).Info.ModVersion[1].."."..Ext.Mod.GetMod(MOD_UUID).Info.ModVersion[2].."."..Ext.Mod.GetMod(MOD_UUID).Info.ModVersion[3].."."..Ext.Mod.GetMod(MOD_UUID).Info.ModVersion[4],
}
