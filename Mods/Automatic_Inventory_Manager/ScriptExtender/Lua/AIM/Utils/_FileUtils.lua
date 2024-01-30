FileUtils = {}

FileUtils.MOD_INFO = function()
	return Ext.Mod.GetMod('23bdda0c-a671-498f-89f5-a69e8d3a4b52').Info
end

--- Builds a file target path relative to AIM's ScriptExtender/ path (to be used in combination with Utils:BuildAbsoluteFileTargetPath)
---@tparam string fileName required
---@tparam string... subDirs optional varargs
---@treturn string Example: subDir="dir", fileName="file", returns dir/file.json
function FileUtils:BuildRelativeJsonFileTargetPath(fileName, ...)
	local subDirs = { ... }
	if subDirs then
		local filePath = ""
		for _, subDir in pairs(subDirs) do
			filePath = filePath .. subDir .. "/"
		end
		return filePath .. fileName .. ".json"
	else
		return fileName .. ".json"
	end
end

--- Builds the aboslute file path to the AIM ScriptExtender directory
---@tparam string filepath required
---@treturn string
function FileUtils:BuildAbsoluteFileTargetPath(filepath)
	return FileUtils.MOD_INFO().Directory .. "/" .. filepath
end

--- Convenience for saving a Lua Table to a file under the AIM mod directory, logging and swallowing any errors encountered
---@param filepath string relative to the mod dir (e.g. filters/weapons.json)
---@param content any will be stringified using Ext.Json.Stringify
---@treturn boolean true if the operation succeeded, false otherwise
function FileUtils:SaveTableToFile(filepath, content)
	local success, error = pcall(function()
		FileUtils:SaveStringContentToFile(filepath, Ext.Json.Stringify(content))
	end)

	if not success then
		Ext.Utils.PrintError(string.format("Failed to convert content %s to JSON due to error [%s] ",
			tostring(content), error))
	end
end

--- Convenience for saving a file under the AIM mod directory, logging and swallowing any errors encountered
---@tparam string filepath relative to the mod dir (e.g. filters/weapons.json)
---@tparam any content will be stringified using Ext.Json.Stringify
---@treturn boolean true if the operation succeeded, false otherwise
function FileUtils:SaveStringContentToFile(filepath, content)
	local success, error = pcall(function()
		return Ext.IO.SaveFile(FileUtils:BuildAbsoluteFileTargetPath(filepath), content)
	end)

	if not success then
		Ext.Utils.PrintError(string.format("Failed to save config file %s due to error [%s] ",
			FileUtils:BuildAbsoluteFileTargetPath(filepath), error))

		return false
	end

	return true
end

--- Convenience for loading a file under the AIM mod directory
---@param filepath string relative to the mod directory
---@return string|nil
function FileUtils:LoadFile(filepath)
	local success, result = pcall(function()
		return Ext.IO.LoadFile(FileUtils:BuildAbsoluteFileTargetPath(filepath))
	end)

	if not success then
		Ext.Utils.PrintError(string.format("Failed to load %s due to error [%s]",
			FileUtils:BuildAbsoluteFileTargetPath(filepath),
			result))
		return nil
	else
		return result
	end
end


