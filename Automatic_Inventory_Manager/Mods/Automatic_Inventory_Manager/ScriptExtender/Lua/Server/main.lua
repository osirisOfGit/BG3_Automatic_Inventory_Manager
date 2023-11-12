-- https://github.com/Norbyte/bg3se/blob/main/Docs/API.md#getting-started
-- Outline:
--  OnPickup, move item to Lae'Zal (S_Player_Laezel_58a69333-40bf-8358-1d17-fff240d7fb12)
--  OnPickup, don't move item if not in table
--  OnPickup, move item to designated party member
--  OnPickup, tag item as junk if designated
--  OnPickup, move item designated as "best fit" to party member round-robin (e.g. distribute potions evenly)
--            Add weighted distribution
--  SkillActivate - trigger distribution for all party members
--					stretch: anti-annoying measure for online play
--  OnPartyMemberSwap, redistribute from party member being left in camp

-- Useful functions: MoveItemTo, GetItemByTagInInventory, GetStackAmount, ItemTagIsInInventory, UserTransferTaggedItems
-- Useful events: TemplateAddedTo, CharacterJoinedParty, CharacterLeftParty
-- Make a symblink: mklink /J "D:\GOG\Baldurs Gate 3\Data\Mods\Automatic_Inventory_Manager" "D:\Mods\BG3 Modder MultiTool\My Mods\Automatic_Inventory_Manager\Mods\Automatic_Inventory_Manager"

-- Includes moving from container to other inventories etc...
-- Chops off the UUID
function GetName(item)
    return string.sub(item, 1, -38)
end

-- Chops off the "Human" part of the id
function GetUUID(item)
	return string.sub(item, -36)
end

Ext.Osiris.RegisterListener("TemplateAddedTo", 4, "before", function(root, item, inventoryHolder, addType)
	_P("Picked up an object!")
	_D(Osi.GetHostCharacter())
	_D(inventoryHolder)
	if (GetUUID(inventoryHolder) == Osi.GetHostCharacter()) then
		_P("inventoryHolder is Character!")
		local exactAmount, totalAmount = Osi.GetStackAmount(item)
		_P("Moving " .. exactAmount .. " of item [" .. item .. "] to Lae'Zal!")
		Osi.MoveItemTo(inventoryHolder, item, "58a69333-40bf-8358-1d17-fff240d7fb12", exactAmount, "")
		_P("Moved item [" .. item .. "] to Lae'Zal!")
	end
end)
