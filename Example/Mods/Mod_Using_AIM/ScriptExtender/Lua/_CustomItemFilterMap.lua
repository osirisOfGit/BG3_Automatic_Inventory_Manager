local newItemFilterMap = {
	-- This is not a known itemFilterMap, so going to have to register a custom FilterLookupFunction for it
	["ARMOR"] = {
		-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/ItemFilters.html#ItemKeys
		[AIM_SHORTCUT.ItemFilters.ItemKeys.WILDCARD] = {
			Filters = {
				[1] = { Target = "originalTarget", },
			},
		},
	}
}

-- Don't add the new ItemFilterLookup if the itemFilterMap that created it wasn't successfully saved.
-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/ItemFilters.html#RegisterItemFilterMapPreset
if AIM_SHORTCUT.ItemFilters:RegisterItemFilterMapPreset(SAMPLE_MOD_UUID, "CustomItemFilterMap", newItemFilterMap) then

	-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/ItemFilters.html#RegisterItemFilterLookupFunction
	AIM_SHORTCUT.ItemFilters:RegisterItemFilterLookupFunction(SAMPLE_MOD_UUID, function(itemFilterMaps,
                                                                                        root,
                                                                                        item,
                                                                                        inventoryHolder)
		local filters = {}

		if itemFilterMaps.ARMOR and Osi.IsEquipable(item) then
			local armorItemFilterMap = itemFilterMaps.ARMOR
			if armorItemFilterMap[item] then
				table.insert(filters, armorItemFilterMap[item])
			end

			if armorItemFilterMap[AIM_SHORTCUT.ItemFilters.ItemKeys.WILDCARD] then
				table.insert(filters, armorItemFilterMap[AIM_SHORTCUT.ItemFilters.ItemKeys.WILDCARD])
			end
			Ext.Utils.Print("Looky loo, CustomItemFilterMap is working! " .. Ext.Json.Stringify(filters))
		end

		return filters
	end)
end
