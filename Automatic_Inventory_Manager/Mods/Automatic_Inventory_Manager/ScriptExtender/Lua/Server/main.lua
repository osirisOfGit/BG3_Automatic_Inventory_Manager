-- https://github.com/Norbyte/bg3se/blob/main/Docs/API.md#getting-started
-- Outline:
--  ✅ OnPickup, move item to Lae'Zal (S_Player_Laezel_58a69333-40bf-8358-1d17-fff240d7fb12)
--  ✅ OnPickup, don't move item if not in table
--  OnPickup, move item to designated party member
--  OnPickup, tag item as junk if designated
--  OnPickup, move item designated as "best fit" to party member round-robin (e.g. distribute potions evenly)
--            Add weighted distribution
--  OnContainerOpen, optionally execute distribution according to config
--  SkillActivate - trigger distribution for all party members
--					stretch: anti-annoying measure for online play
--  OnPartyMemberSwap, redistribute from party member being left in camp

-- Useful functions: MoveItemTo, GetItemByTagInInventory, GetStackAmount, ItemTagIsInInventory, UserTransferTaggedItems, SendToCampChest, IterateTagsCategory
-- Useful events: TemplateAddedTo, CharacterJoinedParty, CharacterLeftParty
-- Make a symblink: mklink /J "D:\GOG\Baldurs Gate 3\Data\Mods\Automatic_Inventory_Manager" "D:\Mods\BG3 Modder MultiTool\My Mods\Automatic_Inventory_Manager\Mods\Automatic_Inventory_Manager"

-- Chops off the UUID <br/>
-- @returns <br/>the 36 character UUID,<br/>the Human-Readable part of the id
function SplitUUIDAndName(item)
    return string.sub(item, -36), string.sub(item, 1, -38)
end

function GetItemDisplayName(item)
	        -- Allows fallback
			local success, translatedName = pcall(function()
				---@diagnostic disable-next-line: param-type-mismatch
				return Osi.ResolveTranslatedString(Osi.GetDisplayName(item))
			end)
			if not success then return "NO HANDLE" else return translatedName end
end

-- Includes moving from container to other inventories etc...
Ext.Osiris.RegisterListener("TemplateAddedTo", 4, "before", function(root, item, inventoryHolder, addType)
	local itemTemplateUUID, itemTemplateName= SplitUUIDAndName(root)
	_P("Processing item " .. item .. " with template " .. itemTemplateUUID .. " on inventoryHolder " .. inventoryHolder .. " with addType ".. addType)
	local invHolderUUID, invHolderName = SplitUUIDAndName(inventoryHolder)
	if (invHolderUUID == Osi.GetHostCharacter() and ITEM_MAP[itemTemplateName] ~= nil) then
		Osi.Pickup("S_Player_Laezel_58a69333-40bf-8358-1d17-fff240d7fb12", item, addType, 1)
		_P("Moved " .. Osi.GetStackAmount(item) .. " of item " .. item .. " to Lae'Zel")
	end
end)
