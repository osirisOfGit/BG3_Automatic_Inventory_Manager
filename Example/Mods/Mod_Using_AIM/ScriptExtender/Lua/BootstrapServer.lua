SAMPLE_MOD_UUID = "83f59e8c-7bf4-4e53-92bc-68dc7e8d5d17"
Ext.Utils.Print("AIM's SampleMod is starting to register its stuff")
-- Requires AIM
if Ext.Mod.IsModLoaded("23bdda0c-a671-498f-89f5-a69e8d3a4b52") then
	AIM_SHORTCUT = Mods.Automatic_Inventory_Manager
	Ext.Require("_CustomFilters.lua")
	Ext.Require("_CustomItemFilterMap.lua")
	Ext.Require("_CustomPreFilters.lua")
	Ext.Require("_WithVanillaFunctionality.lua")
	Ext.Require("_ItemBlackList.lua")
	Ext.Utils.Print("AIM's SampleMod is done registering its stuff")
else
	-- The error so nice, we weren't sure where to put it.
	Ext.Utils.PrintError("Automatic_Inventory_Manager was not loaded!!")
	Ext.Utils.ShowError("Automatic_Inventory_Manager was not loaded!!")
end
