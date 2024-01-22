-- Make symlink for debugging purposes
-- mklink /J "D:\GOG\Baldurs Gate 3\Data\Mods\Mod_Using_AIM" "D:\Mods\BG3 Modder MultiTool\My Mods\Automatic_Inventory_Manager\Example\Mods\Mod_Using_AIM"

-- Requires AIM
if Ext.Mod.IsModLoaded("23bdda0c-a671-498f-89f5-a69e8d3a4b52") then
	--- @type ItemMap
	local newItemMap = {
		-- Adding a new itemMap key
		["ARMOR"] = {
			["ALL"] = {
				Filters = {
					[99] = {
						-- We can add arbitrary stats without a separate call - AIM will take care of adding new ones to the relevant table
						TargetStat = "COOLNESS",
						CompareStategy = "HIGHER"
					},
					-- will be converted to number
					["200"] = {
						CustomField = "Rando"
					}
				}
			}
		},
		-- Modifying an existing itemMap
		["Tags"] = {
			-- case sensitive
			["ARROW"] = {
				-- not case sensitive
				Filters = {
					[1] = {
						CustomField = "Rando"
					}
				},
				CustomItemFilterField = {
					Cuz = true
				}
			}
		}
	}

	Mods.Automatic_Inventory_Manager.ItemFilters:AddItemFilterLookupFunction({function (itemMaps, root, item, inventoryHolder)
		local filters = {}

		Mods.Automatic_Inventory_Manager.Logger:BasicInfo("Look Ma, ItemFilterLookup is working!")

		if Osi.IsEquipable(item) then
			local armorItemMap = itemMaps["ARMOR"]
			if armorItemMap[item] then
				table.insert(filters, armorItemMap[item])
			end
		
			if armorItemMap["ALL"] then
				table.insert(filters, armorItemMap["ALL"])
			end
		end

		return filters
	end})

	-- Adding my new maps, prioritizing my filters over existing ones
	Mods.Automatic_Inventory_Manager.ItemFilters:AddItemFilterMaps(newItemMap, false, true, true)

	Mods.Automatic_Inventory_Manager.FilterProcessor:AddNewFilterProcessor(function(filter) return filter["CustomField"] ~= nil end,
		function(partyMember, paramMap)
			if paramMap.filter.CustomField == "Rando" then
				Mods.Automatic_Inventory_Manager.Logger:BasicInfo("Look Ma, Mods working!")
				table.insert(paramMap.winners, partyMember)
			end
		end
	)

	local myTargetStatProcessors = {
		["COOLNESS"] = function(partyMember, paramMap)
			paramMap.winners, paramMap.winningVal = Mods.Automatic_Inventory_Manager.ProcessorUtils:SetWinningVal_ByCompareResult(paramMap.winningVal,
				Osi.Random(19) + 1,
				paramMap.filter.CompareStategy,
				paramMap.winners,
				partyMember)
		end
	}
	Mods.Automatic_Inventory_Manager.FilterProcessor:AddStatFunctions(myTargetStatProcessors)
else
	Ext.Utils.ShowError("Automatic_Inventory_Manager was not loaded!!")
end
