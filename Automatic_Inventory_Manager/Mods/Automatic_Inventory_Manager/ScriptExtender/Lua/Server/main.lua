-- https://github.com/Norbyte/bg3se/blob/main/Docs/API.md#getting-started
-- Outline:
--  ✅ OnPickup, move item to Lae'Zal (S_Player_Laezel_58a69333-40bf-8358-1d17-fff240d7fb12)
--  ✅ OnPickup, don't move item if not in table
--  ✅ OnPickup, move item to designated party member (S_Player_Gale_ad9af97d-75da-406a-ae13-7071c563f604)
--  Create Custom Tag to identify sorted items
--  Remove Custom Tag on drop
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
-- _D(Ext.Entity.Get("S_GLO_Orin_Bhaalist_Dagger_51c312d5-ce5e-4f8c-a5ad-edc2beced3e6"):GetAllComponents())

-- 569b0f3d-abcd-4b01-aaf0-979091288163 RootTemplateId
-- IsEquipable -> _D(Ext.StaticData.GetAll("EquipmentType")) -> _D(Ext.Entity.Get("51c312d5-ce5e-4f8c-a5ad-edc2beced3e6").ServerItem.Item.OriginalTemplate.EquipmentTypeID)
-- _D(Ext.Types.Serialize(Ext.StaticData.Get("7490e5d0-d346-4b0e-80c6-04e977160863", "Tag")).Name)


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
	_P("Processing item " .. item .. " on character ".. inventoryHolder)
	
	if Osi.IsTagged(item, "add41a41-a1a8-4405-ae7f-ce12a0788a1a") == 1 then
		_P("Item was already sorted, skipping!")
		return
	end

	local targetCharacter
	if Osi.IsEquipable(item) then
		targetCharacter = EQUIPMENT_TYPE_MAP[EQUIPTYPE_UUID_TO_NAME_MAP[Ext.Entity.Get(item).ServerItem.Item.OriginalTemplate.EquipmentTypeID]]
		_P("targetCharacter determined by EquipmentType, result: ".. targetCharacter)
	end
	if targetCharacter then
		Osi.MagicPocketsMoveTo(inventoryHolder, item, targetCharacter, 1, 0)
		Osi.SetTag(item, "add41a41-a1a8-4405-ae7f-ce12a0788a1a")
		_P("Moved " .. Osi.GetStackAmount(item) .. " of item " .. item .. " to " .. targetCharacter)
	end
end)
