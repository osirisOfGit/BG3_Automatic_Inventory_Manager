--- @module 'ItemBlackList'

ItemBlackList = {}

local blackListTable = {
	Items = {},
	RootTemplates = {
		"FOCUSLODESTONES",
		"TMOG"
	},
	Tags = {}
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
			blackListTable.Items = blackList.Items
		end
	end

	if blackList.RootTemplates and #blackList.RootTemplates > 0 then
		if #blackListTable.RootTemplates > 0 then
			AddNonDuplicateEntries(blackListTable.RootTemplates, blackList.RootTemplates)
		else
			blackListTable.RootTemplates = blackList.RootTemplates
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
function ItemBlackList:AddEntriesToBlackList(modUUID, blacklistedItems, blacklistedRoots, blacklistedTags)
	local modInfo = ModUtils:GetModInfoFromUUID(modUUID).Name
	local blackListEntries = {
		["Items"] = blacklistedItems,
		["RootTemplates"] = blacklistedRoots,
		["Tags"] = blacklistedTags
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
		for _, itemUUID in pairs(blackListTable.Items) do
			if item == itemUUID or string.find(item, itemUUID) then
				Logger:BasicInfo("Item %s was found in the blacklist!", item)
				return true
			end
		end

		if #blackListTable.Tags > 0 then
			for _, tagUUID in pairs(Ext.Entity.Get(item).Tag.Tags) do
				local tagTable = Ext.StaticData.Get(tagUUID, "Tag")
				if tagTable then
					for _, tagToCompare in pairs(blackListTable.Tags) do
						if tagToCompare == string.upper(tagTable["Name"]) then
							return true
						end
					end
				end
			end
		end
	end

	if rootTemplate then
		for _, rootUUID in pairs(blackListTable.RootTemplates) do
			if rootTemplate == rootUUID or string.find(rootTemplate, rootUUID) then
				Logger:BasicInfo("RootTemplate %s was found in the blacklist!", rootTemplate)
				return true
			end
		end
	end

	return false
end
