local newItemMap = {
	["Tags"] = {
		["HEALING_POTION"] = {
			Filters = {
				-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/ItemFilters.html
				[1] = {
					-- CustomTargetStat that we need to register a TargetStatProcessor for
					TargetStat = "MyCustomStat",
					-- Need TargetStat and CompareStrategy for this to be recognized as a CompareFilter
					-- If you don't want to include this, then you need to register a new FilterProcessor
					CompareStrategy = "HIGHER"
				},
				[2] = {
					-- Custom field we need to register a new FilterProcessor for
					CustomField = "Rando"
				}
			},
			-- As of 2.0.0, there's no mechanism available to register a new processor for new ItemFilterFields
			-- However, custom ItemFilterFields will be passed to stat functions and filter processors via
			-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/Processors._FilterProcessors.html#FilterParamMap
			MyCustomItemFilterField = {
				Cuz = true
			}
		}
	}

}

-- Mod name is prepended to the presetName for us
-- don't bother registering the filter processors if the preset that uses them didn't get saved
-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/ItemFilters.html#RegisterItemFilterMapPreset
if AIM_SHORTCUT.ItemFilters:RegisterItemFilterMapPreset(SAMPLE_MOD_UUID, "CustomFilters", newItemMap) then
	-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/Processors._FilterProcessors.html
	AIM_SHORTCUT.FilterProcessor:RegisterTargetStatProcessors(SAMPLE_MOD_UUID,
		{
			["MyCustomStat"] = function(partyMemberBeingProcesed, paramMap)
				if partyMemberBeingProcesed ~= paramMap.inventoryHolder then
					Ext.Utils.Print("TargetStatProcesor: The Target Stat, is Processed")
				end
			end
		}
	)

	AIM_SHORTCUT.FilterProcessor:RegisterNewFilterProcessor(SAMPLE_MOD_UUID,
		-- Predicate filter to see if we can process the filter being run
		function(filterBeingProcessed)
			return filterBeingProcessed["TargetStat"] == "MyCustomStat" or filterBeingProcessed["CustomField"]
		end,
		-- Processor function that modifies ParamMap.winners to identify the winners. AIM runs these in a protected function and logs any errors,
		-- but doesn't cancel processing
		function(partyMemberFilterIsBeingRunAgainst, paramMap)
			-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/Processors._FilterProcessors.html#FilterParamMap
			if paramMap.targetsWithAmountWon[partyMemberFilterIsBeingRunAgainst]
				and (paramMap.customItemFilterFields["MyCustomItemFilterField"] and paramMap.customItemFilterFields["MyCustomItemFilterField"].Cuz) then
				Ext.Utils.Print("HECK YEAH")
			end
		end)
end
