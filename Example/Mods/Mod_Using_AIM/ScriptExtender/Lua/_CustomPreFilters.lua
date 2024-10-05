local newItemFilterMap = {
	["Tags"] = {
		["HEALING_POTION"] = {
			PreFilters = {
				-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/ItemFilters.html#ItemFilters.ItemFields.PreFilters
				[AIM_SHORTCUT.ItemFilters.ItemFields.PreFilters.STACK_LIMIT] = 2,
				-- Custom PreFilters that we need to register processors for
				["CustomPreFilter-PerStack"] = { isEnabled = true },
				["CustomPreFilter-PerItem"] = { amICool = false },
			},
			Filters = {
				[1] = { TargetStat = AIM_SHORTCUT.ItemFilters.FilterFields.TargetStat.HEALTH_PERCENTAGE, CompareStrategy = AIM_SHORTCUT.ItemFilters.FilterFields.CompareStrategy.LOWER, },
				[2] = { TargetStat = AIM_SHORTCUT.ItemFilters.FilterFields.TargetStat.STACK_AMOUNT, CompareStrategy = AIM_SHORTCUT.ItemFilters.FilterFields.CompareStrategy.LOWER }
			},
		},
	}
}

-- Mod name is prepended to the presetName for us
-- don't bother registering the pre-filter processors if the preset that uses them didn't get saved
-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/ItemFilters.html#RegisterItemFilterMapPreset
if AIM_SHORTCUT.ItemFilters:RegisterItemFilterMapPreset(SAMPLE_MOD_UUID, "CustomPreFilters", newItemFilterMap) then

	-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/Processors._PreFilterProcessors.html#PreFilterProcessors:RegisterPerStackPreFilterProcessor
	AIM_SHORTCUT.PreFilterProcessors:RegisterPerStackPreFilterProcessor(SAMPLE_MOD_UUID, "CustomPreFilter-PerStack",
		-- ParamMap - https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/Processors._PreFilterProcessors.html#PreFilterParamMap
		function(preFilterContent, paramMap)
			if preFilterContent.isEnabled then
				Ext.Utils.Print("PerStack Pre-Filter is working!")
				return paramMap.eligiblePartyMembers
			end
		end)


	-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/Processors._PreFilterProcessors.html#PreFilterProcessors:RegisterPerItemPreFilterProcessor
	AIM_SHORTCUT.PreFilterProcessors:RegisterPerItemPreFilterProcessor(SAMPLE_MOD_UUID, "CustomPreFilter-PerItem",
		function(content, paramMap)
			if not content.amICool then
				Ext.Utils.Print("PerItem Pre-Filter is working!")
				return paramMap.eligiblePartyMembers
			end
		end)
end
