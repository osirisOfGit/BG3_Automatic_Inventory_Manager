--- SETUP
Ext.Require("Server/_Utils.lua")
Ext.Require("Server/_Globals.lua")
Ext.Require("Server/_ItemFilters.lua")
Ext.Require("Server/_Config.lua")
Ext.Require("Server/Listeners/_Initializers.lua")

-- CORE LOGIC
Ext.Require("Server/Processors/_CoreProcessor.lua")
Ext.Require("Server/Listeners/_ItemEvents.lua")
Ext.Require("Server/main.lua")
