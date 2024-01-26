--- Third party mods are encouraged to handle their own logging, for better traceability, but exposing this for my own convenience. 
--- It's HIGHLY recommended to keep the logging to a minimum, especially logs that are created per FilterProcessor iteration, as writing logs to the log file 
--- is extremely performance intensive. May look into refactoring in the future, but for now, users can just set their log levels appropriately.
--- @module "Logger"

Logger = {}

-- Largely stolen from Auto_Sell_Loot - https://www.nexusmods.com/baldursgate3/mods/2435 Thx m8 (｡･∀･)ﾉﾞ

Logger.PrintTypes = {
    TRACE = 5,
    DEBUG = 4,
    INFO = 3,
    WARNING = 2,
    ERROR = 1,
	OFF = 0,
}

local TEXT_COLORS = {
    black = 30,
    red = 31,
    green = 32,
    yellow = 33,
    cyan = 34,
    magenta = 35,
    blue = 36,
    white = 37,
}

local function ConcatPrefix(prefix, message)
    local paddedPrefix = prefix .. string.rep(" ", 25 - #prefix) .. " : "

    if type(message) == "table" then
        local serializedMessage = Ext.Json.Stringify(message)
        return paddedPrefix .. serializedMessage
    else
        return paddedPrefix .. tostring(message)
    end
end

--Blatantly stolen from KvCampEvents, mine now
local function ConcatOutput(...)
    local varArgs = { ... }
    local outStr = ""
    local firstDone = false
    for _, v in pairs(varArgs) do
        if not firstDone then
            firstDone = true
            outStr = tostring(v)
        else
            outStr = outStr .. " " .. tostring(v)
        end
    end
    return outStr
end
local function GetRainbowText(text)
    local colors = { "31", "33", "32", "36", "35", "34" } -- Red, Yellow, Green, Cyan, Magenta, Blue
    local coloredText = ""
    for i = 1, #text do
        local char = text:sub(i, i)
        local color = colors[i % #colors + 1]
        coloredText = coloredText .. string.format("\x1b[%sm%s\x1b[0m", color, char)
    end
    return coloredText
end

--- Function to print text with custom colors, message type, custom prefix, rainbowText ,and prefix length
function Logger:BasicPrint(content, messageType, textColor, customPrefix, rainbowText, prefixLength)
    if Config.AIM and Config.AIM.LOG_LEVEL and tonumber(Config.AIM.LOG_LEVEL) >= messageType then
		prefixLength=prefixLength or 15
		messageType = messageType or Logger.PrintTypes.INFO
		local textColorCode = textColor or TEXT_COLORS.cyan -- Default to cyan

		customPrefix = customPrefix or Utils.MOD_INFO().Name
        local padding = string.rep(" ", prefixLength - #customPrefix)
        local message = ConcatOutput(ConcatPrefix(customPrefix .. padding .. "  [" .. messageType .. "]", content))

        Logger:LogMessage(ConcatOutput(ConcatPrefix(customPrefix .. "  [" .. messageType .. "]", content)))
		if messageType <= Logger.PrintTypes.INFO then
			local coloredMessage = rainbowText and GetRainbowText(message) or string.format("\x1b[%dm%s\x1b[0m", textColorCode, message)
			if messageType == Logger.PrintTypes.ERROR then
				Ext.Utils.PrintError(coloredMessage)
			elseif messageType == Logger.PrintTypes.WARNING then
				Ext.Utils.PrintWarning(coloredMessage)
			else
				Ext.Utils.Print(coloredMessage)
			end
		end
    end
end

--- Convenience function for Error Logs
function Logger:BasicError(content)
    Logger:BasicPrint(content, Logger.PrintTypes.ERROR, TEXT_COLORS.red)
end

--- Convenience function for Warning Logs
function Logger:BasicWarning(content)
    Logger:BasicPrint(content, Logger.PrintTypes.WARNING, TEXT_COLORS.yellow)
end

--- Convenience function for Debug Logs
function Logger:BasicDebug(content)
    Logger:BasicPrint(content, Logger.PrintTypes.DEBUG)
end

--- Convenience function for Trace Logs
function Logger:BasicTrace(content)
    Logger:BasicPrint(content, Logger.PrintTypes.TRACE)
end

--- Convenience function for Info Logs
function Logger:BasicInfo(content)
    Logger:BasicPrint(content, Logger.PrintTypes.INFO)
end

local logPath = 'log.txt'
--- Saves the log to the log.txt
function Logger:LogMessage(message)
    local fileContent = Utils:LoadFile(logPath) or ""
    local logMessage = Ext.Utils.MonotonicTime() .. " " .. message
    Ext.IO.SaveFile(Utils:BuildTargetFilePath(logPath), fileContent .. logMessage .. "\n")
end

--- Wipes the log file
function Logger:ClearLogFile()
    if Utils:LoadFile(logPath) then
        Ext.IO.SaveFile(Utils:BuildTargetFilePath(logPath), "")
    end
end
