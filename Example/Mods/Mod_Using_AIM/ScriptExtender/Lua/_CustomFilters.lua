local newItemFilterMap = {
	["Tags"] = {
		["HEALING_POTION"] = {
			Filters = {
				-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/ItemFilters.html
				[1] = {
					TargetStat = "STACK_AMOUNT",
					CompareStategy = "HIGHER",
					CalculateStackUsing = {
						["CUSTOM_KEY"] = "I'M CUSTOM!"
					},
				},
				[2] = {
					-- CustomTargetStat that we need to register a TargetStatProcessor for
					TargetStat = "MyCustomStat",
					-- Need TargetStat and CompareStrategy for this to be recognized as a CompareFilter
					-- If you don't want to include this, then you need to register a new FilterProcessor
					CompareStrategy = "HIGHER"
				},
				[3] = {
					-- Custom field we need to register a new FilterProcessor for
					CustomField = "Rando"
				},
			},
			-- As of 2.0.0, there's no mechanism available to register a new processor for new ItemFilterFields
			-- However, custom ItemFilterFields will be passed to stat functions and filter processors via
			-- their respective ParamMaps
			MyCustomItemFilterField = {
				Cuz = true
			}
		}
	}

}

-- Mod name is prepended to the presetName for us
-- don't bother registering the filter processors if the preset that uses them didn't get saved
-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/ItemFilters.html#RegisterItemFilterMapPreset
if AIM_SHORTCUT.ItemFilters:RegisterItemFilterMapPreset(SAMPLE_MOD_UUID, "CustomFilters", newItemFilterMap) then
	-- Registering Property Recorders for our new fields so consumers know when they're applicable
	-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/EntityPropertyRecorder.html
	AIM_SHORTCUT.EntityPropertyRecorder:RegisterPropertyRecorders(SAMPLE_MOD_UUID,
		-- CustomField
		function(entity)
			if Osi.IsPlayer(entity) == 1 then
				local recordEntry = AIM_SHORTCUT.EntityPropertyRecorder:BuildInitialRecordEntry(
					nil,                              -- initialApplicableItemFilterMaps
					{ AIM_SHORTCUT.EntityPropertyRecorder.Filters }, -- initialApplicableItemFilterFields
					{ "CustomField" },                -- initialApplicableFilterFields
					nil,                              -- initialApplicablePreFilterFields
					"N/A"                             -- initialValue
				)
				--[[
					recordEntry looks like:
					{
						"Can Be Applied To" :
						{
							"FilterFields" :
							[
								"CustomField"
							],
							"ItemFilterFields" :
							[
								"Filters"
							],
							"ItemFilterMaps" :
							[
								
							]
						},
						"Value" : "N/A"
					}
				]]

				if Osi.IsPartyMember(entity, 1) == 1 then
					table.insert(
						recordEntry[AIM_SHORTCUT.EntityPropertyRecorder.CanBeAppliedTo]
						[AIM_SHORTCUT.EntityPropertyRecorder.ItemFilterMaps],
						"Tags")

					recordEntry[AIM_SHORTCUT.EntityPropertyRecorder.Value] = "Rando"
				end

				-- The property that our entry represents - each mod has their own isolated entries, so we can set this to existing values
				-- if applicable without fear of merge behavior
				return { ["MyCustomField"] = recordEntry }
			end
			-- Returning nil if the condition isn't met
		end,
		-- MyCustomItemFilterField
		function(entity)
			local recordEntry = AIM_SHORTCUT.EntityPropertyRecorder:BuildInitialRecordEntry(
				{ "ALL" },        -- initialApplicableItemFilterMaps
				{ "MyCustomItemFilterField" } -- initialApplicableItemFilterFields
			-- The rest will be set their defaults
			)

			-- Can add custom fields without issue.
			recordEntry[AIM_SHORTCUT.EntityPropertyRecorder.CanBeAppliedTo]["MyCustomItemFilterFields"] = { "Cuz" }
			recordEntry[AIM_SHORTCUT.EntityPropertyRecorder.Value] = true

			return { ["JustCuz"] = recordEntry }
		end
	)

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
				table.insert(paramMap.winners, partyMemberFilterIsBeingRunAgainst)
				Ext.Utils.Print("HECK YEAH")
			end
		end)

	AIM_SHORTCUT.ProcessorUtils:RegisterCustomStackCalculator(SAMPLE_MOD_UUID,
		{
			["CUSTOM_KEY"] = function(itemInInventory, valuesToCompareAgainst, originalItem)
				-- valuesToCompareAgainst will always be a list
				for _, valueToCompare in pairs(valuesToCompareAgainst) do
					Ext.Utils.Print("CustomStackCalculator: I'm working, bruh! Value: " .. valueToCompare .. "| Item: " .. itemInInventory .. " | original item: ".. originalItem)
				end
				return false
			end
		})
end
