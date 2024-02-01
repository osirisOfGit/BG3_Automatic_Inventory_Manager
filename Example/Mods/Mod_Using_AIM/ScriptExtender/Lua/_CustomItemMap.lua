local newItemMap = {
	-- This is not a known itemMap, so going to have to register a custom FilterLookupFunction for it
	["ARMOR"] = {
		-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/ItemFilters.html#ItemKeys
		[AIM_SHORTCUT.ItemFilters.ItemKeys.WILDCARD] = {
			Filters = {
				[1] = { Target = "originalTarget", },
			},
		},
	}
}

-- Don't add the new ItemFilterLookup if the itemMap that created it wasn't successfully saved.
-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/ItemFilters.html#RegisterItemFilterMapPreset
if AIM_SHORTCUT.ItemFilters:RegisterItemFilterMapPreset(SAMPLE_MOD_UUID, "CustomItemMap", newItemMap) then

	-- https://osirisofgit.github.io/BG3_Automatic_Inventory_Manager/modules/ItemFilters.html#RegisterItemFilterLookupFunction
	AIM_SHORTCUT.ItemFilters:RegisterItemFilterLookupFunction(SAMPLE_MOD_UUID, function(itemMaps,
																						root,
																						item,
																						inventoryHolder)
		local filters = {}

		if itemMaps.ARMOR and Osi.IsEquipable(item) then
			local armorItemMap = itemMaps.ARMOR
			if armorItemMap[item] then
				table.insert(filters, armorItemMap[item])
			end
			
			if armorItemMap[AIM_SHORTCUT.ItemFilters.ItemKeys.WILDCARD] then
				table.insert(filters, armorItemMap[AIM_SHORTCUT.ItemFilters.ItemKeys.WILDCARD])
			end
			Ext.Utils.Print("Looky loo, CustomItemMap is working! " .. Ext.Json.Stringify(filters))
		end

		return filters
	end)
end
