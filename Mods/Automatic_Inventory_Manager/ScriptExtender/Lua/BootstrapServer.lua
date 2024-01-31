PersistentVars = {}
--- SETUP
Ext.Require("AIM/Utils/_ModUtils.lua")
Ext.Require("AIM/Utils/_TableUtils.lua")
Ext.Require("AIM/Utils/_FileUtils.lua")
Ext.Require("AIM/Utils/_Logger.lua")
Ext.Require("AIM/_Globals.lua")
Ext.Require("AIM/_ItemFilters.lua")
Ext.Require("AIM/_Config.lua")

-- CORE LOGIC
Ext.Require("AIM/Processors/_CoreProcessor.lua")
Ext.Require("AIM/Listeners/_ItemEvents.lua")
Ext.Require("AIM/Listeners/_Initializers.lua")
