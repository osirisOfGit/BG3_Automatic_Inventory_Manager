Utils = {}

function Utils:AddItemToTable_AddingToExistingAmount(tarTable, key, amount)
	if not tarTable then
		tarTable = {}
	end
	if not tarTable[key] then
		tarTable[key] = amount
	else
		tarTable[key] = tarTable[key] + amount
	end
end

local function BuildTargetFilePath(filepath)
	return Ext.Mod.GetMod('23bdda0c-a671-498f-89f5-a69e8d3a4b52').Info.Directory .. "/" .. filepath
end

--- Convenience for saving a file under the mod directory
---@param filepath string relative to the mod dir (e.g. filters/weapons.json)
---@param content any will be stringified using Ext.Json.Stringify
function Utils:SaveTableToFile(filepath, content)
	local success, error = pcall(function()
		local json = Ext.Json.Stringify(content)
		Ext.IO.SaveFile(BuildTargetFilePath(filepath), json)
	end)

	if not success then
		Ext.Utils.PrintError(string.format("Failed to save config file %s due to error [%s] ",
			BuildTargetFilePath(filepath), error))
	end
end

--- Convenience for loading a file under the mod directory
---@param filepath string relative to the mod directory
---@return string|nil
function Utils:LoadFile(filepath)
	local success, result = pcall(function()
		return Ext.IO.LoadFile(BuildTargetFilePath(filepath))
	end)

	if not success then
		Ext.Utils.PrintError(string.format("Failed to load %s due to error [%s]", BuildTargetFilePath(filepath), result))
		return nil
	else
		return result
	end
end
