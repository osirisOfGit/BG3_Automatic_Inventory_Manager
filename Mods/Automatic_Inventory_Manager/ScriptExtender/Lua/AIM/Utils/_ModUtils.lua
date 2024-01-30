ModUtils = {}

function ModUtils:GetAIMModInfo()
	return Ext.Mod.GetMod('23bdda0c-a671-498f-89f5-a69e8d3a4b52').Info
end

function ModUtils:GetModInfoFromUUID(modUUID)
	if not Ext.Mod.IsModLoaded(modUUID) then
		Logger:BasicError(string.format("Provided modUUID %s is not loaded - make sure you're passing in the right key!"
			.. " The attempted function will not be completed.",
			modUUID))

		return nil
	end
	return Ext.Mod.GetMod(modUUID).Info
end
