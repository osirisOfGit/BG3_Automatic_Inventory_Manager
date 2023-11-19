-- https://github.com/Norbyte/bg3se/blob/main/Docs/API.md#getting-started
-- https://github.com/LaughingLeader/BG3ModdingTools/wiki
-- https://github.com/ShinyHobo/BG3-Modders-Multitool/wiki/

-- Outline:
--  ✅ OnPickup, move item to Lae'Zal (S_Player_Laezel_58a69333-40bf-8358-1d17-fff240d7fb12)
--  ✅ OnPickup, don't move item if not in table
--  ✅ OnPickup, move item to party member designated in table (S_Player_Gale_ad9af97d-75da-406a-ae13-7071c563f604)
--  ✅ Create Custom Tag to identify sorted items
--  ✅ Remove Custom Tag on drop
--  ❎ Reason: There's no reliable way to have BG3 tag an item as junk - no idea have Osi.IsJunk works. Gonna just point people to AUTO_SELL_LOOT
--			|-- Original item: OnPickup, tag item as junk if designated
-- 			|-- New Item: Implement adding optional tags. No use-cases yet, re-evaluate if needed later
--  ✅ Clear my item tags on Script Extender reset
--  OnPickup, move item designated as "best fit" to party member round-robin (e.g. distribute potions evenly)
--            Add weighted distribution
--  OnContainerOpen, optionally execute distribution according to config
--  Add option to have party members move to the item for "realism" - intercept on RequestCanPickup
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

function ApplyOptionalTags(item)
	if Osi.IsTagged(item, TAG_AIM_OPTIONALLY_TAGGED) == 0 then
		_P("Adding optional tags")
		Osi.SetTag(item, TAG_AIM_OPTIONALLY_TAGGED)

		local opt_tags = OPTIONAL_TAGS[item]
		if not opt_tags then opt_tags = OPTIONAL_TAGS[root] end
		if opt_tags then
			_P("Have tags to add ")
			for _, tag in pairs(opt_tags) do
				if Osi.IsTagged(item, tag) == 0 then
					Osi.SetTag(item, tag)
					_P("Set tag " .. tag .. " on " .. item)
				end
			end
		end
	end
end

-- Includes moving from container to other inventories etc...
Ext.Osiris.RegisterListener("TemplateAddedTo", 4, "before", function(root, item, inventoryHolder, addType)
	_P("Processing item " ..
		item .. " with root " .. root .. " on character " .. inventoryHolder .. " with addType " .. addType)

	ApplyOptionalTags(item)

	if Osi.IsTagged(item, TAG_AIM_SORTED) == 1 then
		_P("Item was already sorted, skipping!")
		return
	end

	local targetCharacter
	if Osi.IsEquipable(item) then
		targetCharacter = EQUIPMENT_TYPE_MAP[EQUIPTYPE_UUID_TO_NAME_MAP[Ext.Entity.Get(item).ServerItem.Item.OriginalTemplate.EquipmentTypeID]]
		if targetCharacter then _P("targetCharacter determined by EquipmentType, result: " .. targetCharacter) end
	end

	if targetCharacter then
		Osi.MagicPocketsMoveTo(inventoryHolder, item, targetCharacter, 1, 0)
		Osi.SetTag(item, TAG_AIM_SORTED)
		_P("Moved " .. Osi.GetStackAmount(item) .. " of item " .. item .. " to " .. targetCharacter)
	end
end)

Ext.Osiris.RegisterListener("DroppedBy", 2, "after", function(object, inventoryHolder)
	Osi.ClearTag(object, TAG_AIM_SORTED)
end)

-- There's definitely a way to combine this and the iterator listener, but types were being difficult
Ext.Events.ResetCompleted:Subscribe(function(_)
	for _, player in pairs(Osi.DB_Players:Get(nil)) do
		_D(player[1])
		for _, optionalTag in pairs(TAGS_TO_CLEAR) do
			Osi.IterateInventoryByTag(player[1], optionalTag, EVENT_CLEAR_CUSTOM_TAGS_START .. optionalTag, EVENT_CLEAR_CUSTOM_TAGS_END .. optionalTag)
		end
	end
end)

Ext.Osiris.RegisterListener("EntityEvent", 2, "after", function(guid, event)
	if string.find(event, EVENT_CLEAR_CUSTOM_TAGS_START) then
		_D(event)
		_P("Cleared tag " .. string.sub(event, string.len(EVENT_CLEAR_CUSTOM_TAGS_START) + 1) .. " off item " .. guid)
		Osi.ClearTag(guid, string.sub(event, string.len(EVENT_CLEAR_CUSTOM_TAGS_START) + 1))
	end
end)
