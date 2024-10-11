AIM_MCM_API = {}

-- MCM Check
if Ext.Mod.IsModLoaded("755a8a72-407f-4f0d-9a33-274ac0f0b53d") then
	Logger:BasicInfo("MCM is detected - enabling integration")
else
	Logger:BasicWarn("Mod Configuration Menu wasn't loaded in time! If you're not using it, you can safely ignore this warning - if you are using it, ensure your load order places AIM after MCM")
end


