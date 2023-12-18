-- https://github.com/Norbyte/bg3se/blob/main/Docs/API.md#getting-started
-- https://github.com/LaughingLeader/BG3ModdingTools/wiki
-- https://github.com/ShinyHobo/BG3-Modders-Multitool/wiki/

--[[
Development Outline:
 ✅ OnPickup, move item to Lae'Zal (S_Player_Laezel_58a69333-40bf-8358-1d17-fff240d7fb12)
 ✅ OnPickup, don't move item if not in table
 ✅ OnPickup, move item to party member designated in table (S_Player_Gale_ad9af97d-75da-406a-ae13-7071c563f604)
 ✅ Create Custom Tag to identify sorted items
 ✅ Remove Custom Tag on drop
 ❎ Reason: There's no reliable way to have BG3 tag an item as junk - no idea have Osi.IsJunk works. Gonna just point people to AUTO_SELL_LOOT
			|-- Original item: OnPickup, tag item as junk if designated
			|-- New Item: Implement adding optional tags. No use-cases yet, re-evaluate if needed later
 ✅ Clear my item tags on Script Extender reset
 ✅ OnPickup, move item designated as "best fit" to party member round-robin (e.g. distribute potions evenly)
           ✅  Add weighted distribution by health
	✅ OnPickup, move item to designated class, with backup
 ✅ Execute sort on game start
 Add whole bunch of criteria for different use-cases that i can think of
   ✅ UsableItem Proficiency, 
   ✅ EquipableItem by Character Stat (e.g. Dex for knife), 
   ✅ Supply to camp,
   ✅ Gold by stack
   ✅ Poisons to chars by stack, then dex
   ✅ Barkskin elixirs to lowest total A/C, 
   scrolls to characters with high int/wis/charisma,
   potion of animal speaking to host character 
 Fallback distribution if exceeds weight limit
 Use PersistantVars to store onReset check
 OnContainerOpen, optionally execute distribution according to config
 Add option to have party members move to the item for "realism" - intercept on RequestCanPickup
 SkillActivate - trigger distribution for all party members
					stretch: anti-annoying measure for online play
 OnPartyMemberSwap, redistribute from party member being left in camp
 Add confirmation box to choose second-best fit if best fit will be encumbered (and so on)
 
Useful functions: MoveItemTo, GetItemByTagInInventory, GetStackAmount, ItemTagIsInInventory, UserTransferTaggedItems, SendToCampChest, IterateTagsCategory
Useful events: TemplateAddedTo, CharacterJoinedParty, CharacterLeftParty
Make a symblink: mklink /J "D:\GOG\Baldurs Gate 3\Data\Mods\Automatic_Inventory_Manager" "D:\Mods\BG3 Modder MultiTool\My Mods\Automatic_Inventory_Manager\Mods\Automatic_Inventory_Manager"
_D(Ext.Entity.Get("S_GLO_Orin_Bhaalist_Dagger_51c312d5-ce5e-4f8c-a5ad-edc2beced3e6"):GetAllComponents())
569b0f3d-abcd-4b01-aaf0-979091288163 RootTemplateId
IsEquipable -> _D(Ext.StaticData.GetAll("EquipmentType")) -> _D(Ext.Entity.Get("51c312d5-ce5e-4f8c-a5ad-edc2beced3e6").ServerItem.Item.OriginalTemplate.EquipmentTypeID)
_D(Ext.Types.Serialize(Ext.StaticData.Get("7490e5d0-d346-4b0e-80c6-04e977160863", "Tag")).Name)
]]
