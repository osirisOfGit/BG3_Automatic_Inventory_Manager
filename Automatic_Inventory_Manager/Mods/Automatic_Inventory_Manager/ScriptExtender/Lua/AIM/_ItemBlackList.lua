--- @module 'ItemBlackList'

ItemBlackList = {}

local blackListTable = {
	Items = {},
	RootTemplates = {
		"FOCUSLODESTONES", -- Lodestones - https://www.nexusmods.com/baldursgate3/mods/7417
		"TMOG",      -- Transmog enhanced - https://www.nexusmods.com/baldursgate3/mods/2922
		"FALLENSTAR_CONS_WIFI", -- Wifi Potions - https://www.nexusmods.com/baldursgate3/mods/5080
		"U_AUTOLOOTTOGGLE", -- Customizable Auto Loot Aura - https://www.nexusmods.com/baldursgate3/mods/2342
	},
	Tags = {},
	ContainerRoots = {
		"CONT_ISF_CONTAINER", -- ItemShipmentFramework - https://www.nexusmods.com/baldursgate3/mods/8295
		"TUT_CHEST_POTIONS", -- Pretty sure this is the tutorial chest,
		"TCP_OBJ_TUTORIALCHEST", -- Another tutorial chest, possibly specific to Tutorial Chest Summoning https://www.nexusmods.com/baldursgate3/mods/457
		"SYR_OBJ_", -- Immersive Tutorial Chest Spawning and more - https://www.nexusmods.com/baldursgate3/mods/4687
		-- Stuff below is from Trade with Withers Addon - Containers - https://www.nexusmods.com/baldursgate3/mods/9397
		"DIQ_OBJ_IMPORTANT_CONTAINER",
		"DIQ_OBJ_CLOTHING_CONTAINER",
		"DIQ_OBJ_DYE_CONTAINER",
		"DIQ_OBJ_WEAPON_CONTAINER",
	}
}

local fileName = "ItemBlackList"

local initialized = false

local function AddNonDuplicateEntries(currentTable, newTable)
	for _, newEntry in pairs(newTable) do
		newEntry = string.upper(newEntry)
		for _, currentEntry in pairs(currentTable) do
			if newEntry == string.upper(currentEntry) then
				goto continue
			end
		end

		table.insert(currentTable, newEntry)
		::continue::
	end
end

local function AddBlacklistTables(blackList)
	if blackList.Items and #blackList.Items > 0 then
		if #blackListTable.Items > 0 then
			AddNonDuplicateEntries(blackListTable.Items, blackList.Items)
		else
			for index, item in pairs(blackList.Items) do
				blackList.Items[index] = string.upper(item)
			end
			blackListTable.Items = blackList.Items
		end
	end

	if blackList.RootTemplates and #blackList.RootTemplates > 0 then
		if #blackListTable.RootTemplates > 0 then
			AddNonDuplicateEntries(blackListTable.RootTemplates, blackList.RootTemplates)
		else
			for index, root in pairs(blackList.RootTemplates) do
				blackList.RootTemplates[index] = string.upper(root)
			end
			blackListTable.RootTemplates = blackList.RootTemplates
		end
	end

	if blackList.ContainerRoots and #blackList.ContainerRoots > 0 then
		if #blackListTable.ContainerRoots > 0 then
			AddNonDuplicateEntries(blackListTable.ContainerRoots, blackList.ContainerRoots)
		else
			for index, root in pairs(blackList.ContainerRoots) do
				blackList.ContainerRoots[index] = string.upper(root)
			end
			blackListTable.ContainerRoots = blackList.ContainerRoots
		end
	end

	if blackList.Tags and #blackList.Tags > 0 then
		if #blackListTable.Tags > 0 then
			AddNonDuplicateEntries(blackListTable.Tags, blackList.Tags)
		else
			for index, tag in pairs(blackList.Tags) do
				blackList.Tags[index] = string.upper(tag)
			end
			blackListTable.Tags = blackList.Tags
		end
	end
end

function ItemBlackList:InitializeBlackList()
	local filePath = FileUtils:BuildRelativeJsonFileTargetPath(fileName)
	local blackList = FileUtils:LoadTableFile(filePath)

	if blackList then AddBlacklistTables(blackList) end
	FileUtils:SaveTableToFile(filePath, blackListTable)

	initialized = true

	Logger:BasicInfo("ItemBlackList set to: " .. Ext.Json.Stringify(blackListTable))
end

--- Add new items or rootTemplates to the blacklist - duplicate entries will be ignored
---@param modUUID any
---@param blacklistedItems nil or list
---@param blacklistedRoots nil or list
---@param blacklistedTags nil or list
---@treturn boolean if there weren't any problems with adding the entries
--- (will be true even if no tables were provided or all entries provided already existed)
function ItemBlackList:AddEntriesToBlackList(modUUID, blacklistedItems, blacklistedRoots, blacklistedTags, blacklistedContainers)
	local modInfo = ModUtils:GetModInfoFromUUID(modUUID).Name
	local blackListEntries = {
		["Items"] = blacklistedItems,
		["RootTemplates"] = blacklistedRoots,
		["Tags"] = blacklistedTags,
		["ContainerRoots"] = blacklistedContainers
	}
	AddBlacklistTables(blackListEntries)

	Logger:BasicInfo("Mod %s successfully added blackList entries: %s",
		modInfo,
		Ext.Json.Stringify(blackListEntries))

	-- not sure if mods would be able to add their values before we load from the file - so just a sanity check to make sure we only update the file
	-- if it's been loaded in already. Initialization takes this into account as well
	if initialized then
		FileUtils:SaveTableToFile(FileUtils:BuildRelativeJsonFileTargetPath(fileName), blackListTable)
	end

	return true
end

--- Checks to see if the item or rootTemplate is in the user-provided blacklist.
---@param item GUIDSTRING optional. If provided, will also check against the blacklisted Tags
---@param rootTemplate GUIDSTRING optional
---@treturn boolean true if the item or rootTemplate is in the blacklist
function ItemBlackList:IsItemOrTemplateInBlacklist(item, rootTemplate)
	if item then
		local itemUpper = string.upper(type(item) == "string" and item or tostring(item))
		for _, itemUUID in pairs(blackListTable.Items) do
			if itemUpper == itemUUID or string.find(itemUpper, itemUUID) then
				Logger:BasicTrace("Item %s was found in the blacklist!", item)
				return true
			end
		end

		if #blackListTable.Tags > 0 then
			for _, tagUUID in pairs(Ext.Entity.Get(item).Tag.Tags) do
				local tagTable = Ext.StaticData.Get(tagUUID, "Tag")
				if tagTable then
					for _, tagToCompare in pairs(blackListTable.Tags) do
						if tagToCompare == string.upper(tagTable["Name"]) then
							Logger:BasicTrace("Item %s was found in the blacklist via Tag %s", item, tagToCompare)
							return true
						end
					end
				end
			end
		end
	end

	if rootTemplate then
		local rootTemplateUpper = string.upper(rootTemplate)
		for _, rootUUID in pairs(blackListTable.RootTemplates) do
			if rootTemplateUpper == rootUUID or string.find(rootTemplateUpper, rootUUID) then
				Logger:BasicTrace("RootTemplate %s was found in the blacklist!", rootTemplate)
				return true
			end
		end
	end

	Logger:BasicTrace("Item %s and root %s were not found in the blacklist", item, rootTemplate)

	return false
end

--- Checks the given item to see if it's a container and in the dedicated blacklist - if it isn't, will recursively check its DirectInventoryOwner
---@param item GUIDSTRING
---@treturn rootTemplate GUIDSTRING that was found in the blacklist, or nil if it wasn't
function ItemBlackList:IsContainerInBlacklist(item)
	if Osi.IsContainer(item) == 1 then
		local rootTemplate = Osi.GetTemplate(item)
		local upperTemplate = string.upper(rootTemplate)

		for _, rootUUID in pairs(blackListTable.ContainerRoots) do
			if upperTemplate == rootUUID or string.find(upperTemplate, rootUUID) then
				Logger:BasicTrace("Container %s with root %s was found in the container blacklist!", string.sub(rootTemplate, 0, -36) .. item, rootTemplate)
				return rootTemplate
			end
		end

		Logger:BasicTrace("Container %s with root %s was not found in the container blacklist - checking parent %s", string.sub(rootTemplate, 0, -36) .. item, rootTemplate,
			Osi.GetDirectInventoryOwner(item))
		return ItemBlackList:IsContainerInBlacklist(Osi.GetDirectInventoryOwner(item))
	end
	return nil
end
