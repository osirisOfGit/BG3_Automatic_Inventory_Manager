PersistentVars = {}
--- SETUP
Ext.Require("AIM/Utils/_UpgradeUtils.lua")
Ext.Require("AIM/Utils/_ModUtils.lua")
Ext.Require("AIM/Utils/_TableUtils.lua")
Ext.Require("AIM/Utils/_FileUtils.lua")
Ext.Require("AIM/Utils/_Logger.lua")
Ext.Require("AIM/_Globals.lua")
Ext.Require("AIM/_ItemFilters.lua")
Ext.Require("AIM/_ItemBlackList.lua")
Ext.Require("AIM/_EntityPropertyRecorder.lua")

-- MCM Check
if Ext.Mod.IsModLoaded("755a8a72-407f-4f0d-9a33-274ac0f0b53d") then
	Logger:BasicInfo("MCM is detected - enabling integration")
else
	Logger:BasicWarn("Mod Configuration Menu wasn't loaded in time! If you're not using it, you can safely ignore this warning - if you are using it, ensure your load order places AIM after MCM")
end

Ext.Require("AIM/_Config.lua")


-- CORE LOGIC
Ext.Require("AIM/Processors/_CoreProcessor.lua")
Ext.Require("AIM/Listeners/_ItemEvents.lua")
Ext.Require("AIM/Listeners/_Initializers.lua")

