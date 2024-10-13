AIM_MCM_API = {}

-- https://wiki.bg3.community/Tutorials/Mod-Frameworks/mod-configuration-menu

if Ext.Mod.IsModLoaded("755a8a72-407f-4f0d-9a33-274ac0f0b53d") then
	local configMap = {
		["mod_enabled"] = "ENABLED",
		["log_level"] = "LOG_LEVEL",
		["enable_epr"] = "RECORD_APPLICABLE_ENTITY_PROPS",
		["respect_container_blacklist_in_stack_calcs"] = "RESPECT_CONTAINER_BLACKLIST_FOR_CUSTOM_STACK_CALCULATIONS",
		["redistribute_consumables_in_combat"] = "SORT_CONSUMABLE_ITEMS_ON_USE_DURING_COMBAT",
		["distribute_items_in_combat"] = "SORT_ITEMS_DURING_COMBAT",
		["distribute_items_on_first_load"] = "SORT_ITEMS_ON_FIRST_LOAD",
	}

	function AIM_MCM_API:InitializeConfigsFromMCM()
		for mcm_key, config_key in pairs(configMap) do
			local mcm_val = MCM.Get(mcm_key)
			if mcm_val ~= nil then
				Logger:BasicInfo("Copying Configuration property %s from MCM", config_key)
				mcm_val = type(mcm_val) == "boolean" and (mcm_val == false and 0 or 1) or mcm_val
				Config.AIM[config_key] = mcm_val
			end
		end
	end

	function AIM_MCM_API:SyncAllConfigsOnLoad()
		Logger:BasicInfo("MCM is detected - enabling integration")

		for mcm_key, config_key in pairs(configMap) do
			local config_val = Config.AIM[config_key]
			if config_val then
				if config_key ~= "LOG_LEVEL" then
					-- config_val == 0 and false or true
					-- ... i can't find the words to explain why the above does what it does, but it doesn't do the below
					if config_val == 0 then
						config_val = false
					else
						config_val = true
					end
				end

				MCM.Set(mcm_key, config_val)
			end
		end

		-- In your MCM-integrated mod's code
		Ext.ModEvents.BG3MCM["MCM_Setting_Saved"]:Subscribe(function(payload)
			if not payload or payload.modUUID ~= ModuleUUID or not payload.settingId then
				return
			end

			if configMap[payload.settingId] then
				Config.AIM[configMap[payload.settingId]] = type(payload.value) == "boolean" and (payload.value == false and 0 or 1) or payload.value

				FileUtils:SaveTableToFile("config.json", Config.AIM)

				if payload.settingId == "enable_epr" and payload.value == true then
					EntityPropertyRecorder:RecordPartyMembers(false)
				end
			end
		end)
	end
else
	function AIM_MCM_API:SyncAllConfigsOnLoad()
		Logger:BasicWarning(
			"Mod Configuration Menu wasn't loaded in time! If you're not using it, you can safely ignore this warning - if you are using it, ensure your load order places AIM after MCM")
	end

	function AIM_MCM_API:InitializeConfigsFromMCM()

	end
end
