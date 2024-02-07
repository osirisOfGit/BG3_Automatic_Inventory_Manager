# "Automatic" Inventory Manager (AIM)
If you process the world in if statements, then oh boy, is this the mod for you!

Mod also uploaded to Nexus Mods - https://www.nexusmods.com/baldursgate3/mods/6163

### Disclaimer
This mod isn't actually particular useful from a functionality standpoint thanks to Larian's Magic Pockets, multi-select, and Filter implementations - if you're looking at this mod because you think you need to move items and gear to a character before you can use them, or because you don't know about the built-in filters and have trouble finding items, or because you don't know you can select multiple items in your inventory by shift-clicking, then you'll be happy to know that Larian has largely solved these problems already. Play around! 

This mod is more targeted at people like me who hate the giant, messy inventories for aesthetic but also hate swapping between characters to pick up items/constantly right-click "send to"ing, or who find the interface way too busy to manage (especially when playing on small monitors or Steam Deck). 

Additionally, I have no idea what'll happen in a true multiplayer game - never tested it. According to Norbyte, praise be his name, [single player sessions are really just multiplayer sessions, Milhouse-style](https://github.com/Norbyte/bg3se/blob/main/Docs/API.md#client-server), so it should maybe work fine? File an issue with **_EXACT DETAILS, LOGS, AND A ZIP OF YOUR `filters\` DIRECTORY_** if you have, well, issues. Otherwise, disable this mod using the config.json.

## Usage Guides
For in-progress 2.0.0 documentation, see https://github.com/osirisOfGit/BG3_Automatic_Inventory_Manager/wiki

## Future Enhancements (in no particular order)
- [x] (2.0.0, with presets) - Fix Filter merge logic to allow users to redefine existing filter priorities 
- [x] (2.0.0, with presets) - Make AIM smart enough to know when a filter or itemMap was removed by the user or added in a new release
- [ ] Make logging less performance intensive
- [ ] Flesh out existing filters more
- [ ] Set up a way to control PersistentVar syncing in-game, instead of through the cross-save config.json
  - This stems from issues with syncing and merging filters after modification 
- [ ] Automatically loot corpses after a battle, directing characters to loot the items they "win"
- [ ] Automatically loot nearby containers (will contain a bunch of conservative safeguards to make sure Lae'zel doesn't channel FO4's Dogmeat in a minefield) 
