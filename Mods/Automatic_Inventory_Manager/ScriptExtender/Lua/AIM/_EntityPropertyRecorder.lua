--- @module "EntityPropertyRecorder"

EntityPropertyRecorder = {}

local RECORD_FILE = FileUtils:BuildRelativeJsonFileTargetPath("RecordedEntityProperties")

local recordedEntityProperties = {}

function EntityPropertyRecorder:LoadRecordedItems()
	if Config.AIM.RECORD_APPLICABLE_ENTITY_PROPS == 1 then
		local savedItemProperties = FileUtils:LoadTableFile(RECORD_FILE)

		if savedItemProperties then
			recordedEntityProperties = savedItemProperties
		end
	end
end

--- Constant
EntityPropertyRecorder.CanBeAppliedTo = "Can Be Applied To"
--- Constant
EntityPropertyRecorder.ItemFilterMaps = "ItemFilterMaps"
--- Constant
EntityPropertyRecorder.ItemFilterFields = "ItemFilterFields"
--- Constant
EntityPropertyRecorder.FilterFields = "FilterFields"
--- Constant
EntityPropertyRecorder.PreFilterFields = "PreFilterFields"
--- Constants
EntityPropertyRecorder.Filters = "Filters"
--- Constant
EntityPropertyRecorder.PreFilters = "PreFilters"
--- Constant
EntityPropertyRecorder.Value = "Value"
--- Constant
EntityPropertyRecorder.Key = "Key"

--- Constructs the common table structure shared by all recorded entries
---@param initialApplicableItemFilterMaps will default to {} if not provided
---@param initialApplicableItemFilterFields will default to {} if not provided
---@param initialApplicableFilterFields will be removed if nil is provided
---@param initialApplicablePreFilterFields will be removed if nil is provided
---@param initialValue will default to "N/A" if not provided
---@treturn table
function EntityPropertyRecorder:BuildInitialRecordEntry(initialApplicableItemFilterMaps,
														initialApplicableItemFilterFields,
														initialApplicableFilterFields,
														initialApplicablePreFilterFields,
														initialValue)
	return {
		[EntityPropertyRecorder.CanBeAppliedTo] = {
			[EntityPropertyRecorder.ItemFilterMaps] = initialApplicableItemFilterMaps or {},
			[EntityPropertyRecorder.ItemFilterFields] = initialApplicableItemFilterFields or {},
			[EntityPropertyRecorder.FilterFields] = initialApplicableFilterFields,
			[EntityPropertyRecorder.PreFilterFields] = initialApplicablePreFilterFields,
		},
		[EntityPropertyRecorder.Value] = initialValue or "N/A"
	}
end

local registeredPropertyRecorders = {}
registeredPropertyRecorders[ModUtils:GetAIMModInfo().Name] = {
	-- Tags
	function(entity)
		if Osi.IsItem(entity) == 1 then
			local recordedTags = {
				["Tags"] =
					EntityPropertyRecorder:BuildInitialRecordEntry({ "Tags" },
						{ EntityPropertyRecorder.Filters },
						{ EntityPropertyRecorder.Key },
						nil,
						{}
					)
			}

			for _, tagUUID in pairs(Ext.Entity.Get(entity).Tag.Tags) do
				local tagTable = Ext.StaticData.Get(tagUUID, "Tag")
				if tagTable then
					table.insert(recordedTags.Tags[EntityPropertyRecorder.Value], tagTable["Name"])
				end
			end

			return recordedTags
		end
	end,

	-- Equipable
	function(entity)
		if Osi.IsEquipable(entity) == 1 then
			local recordedEquipment = {}

			local entityEntry = Ext.Entity.Get(entity)
			if entityEntry.Equipable then
				recordedEquipment["Equipable.Slot"] = EntityPropertyRecorder:BuildInitialRecordEntry({ "Equipment" },
					{ EntityPropertyRecorder.Filters },
					{ EntityPropertyRecorder.Key }
				)
				local itemSlot = tostring(entityEntry.Equipable.Slot)
				if itemSlot == Ext.Enums.StatsItemSlot[Ext.Enums.StatsItemSlot.MeleeMainHand] then
					itemSlot = "Melee Main Weapon"
				elseif itemSlot == Ext.Enums.StatsItemSlot[Ext.Enums.StatsItemSlot.MeleeOffHand] then
					itemSlot = "Melee Offhand Weapon"
				elseif itemSlot == Ext.Enums.StatsItemSlot[Ext.Enums.StatsItemSlot.RangedMainHand] then
					itemSlot = "Ranged Main Weapon"
				elseif itemSlot == Ext.Enums.StatsItemSlot[Ext.Enums.StatsItemSlot.RangedOffHand] then
					itemSlot = "Ranged Offhand Weapon"
				end

				recordedEquipment["Equipable.Slot"][EntityPropertyRecorder.Value] = itemSlot
			end

			if entityEntry.Armor then
				recordedEquipment["Armor.ArmorType"] = EntityPropertyRecorder:BuildInitialRecordEntry({ "Equipment" },
					{ EntityPropertyRecorder.Filters },
					{ EntityPropertyRecorder.Key }
				)

				recordedEquipment["Armor.ArmorType"][EntityPropertyRecorder.Value] =
					tostring(Ext.Enums.ArmorType[entityEntry.Armor.ArmorType])
			end


			if entityEntry.ServerItem.Template.EquipmentTypeID and entityEntry.ServerItem.Template.EquipmentTypeID ~= "00000000-0000-0000-0000-000000000000" then
				recordedEquipment["EquipmentType"] = EntityPropertyRecorder:BuildInitialRecordEntry(
					{ "Equipment", "Weapons" },
					{ EntityPropertyRecorder.Filters },
					{ EntityPropertyRecorder.Key }
				)

				recordedEquipment["EquipmentType"][EntityPropertyRecorder.Value] =
					Ext.StaticData.Get(entityEntry.ServerItem.Template.EquipmentTypeID, "EquipmentType")["Name"]
			end

			return recordedEquipment
		end
	end,

	-- RootTemplate
	function(entity)
		local recordedUUIDs = {
			["uuid"] = EntityPropertyRecorder:BuildInitialRecordEntry(),
		}

		if Osi.IsPartyMember(entity, 1) == 1 then
			recordedUUIDs["uuid"][EntityPropertyRecorder.Value] = entity

			table.insert(
				recordedUUIDs["uuid"][EntityPropertyRecorder.CanBeAppliedTo][EntityPropertyRecorder.ItemFilterFields],
				EntityPropertyRecorder.Filters)
			recordedUUIDs["uuid"][EntityPropertyRecorder.CanBeAppliedTo][EntityPropertyRecorder.FilterFields] = {
				"Target" }

			table.insert(
				recordedUUIDs["uuid"][EntityPropertyRecorder.CanBeAppliedTo][EntityPropertyRecorder.ItemFilterFields],
				EntityPropertyRecorder.PreFilters)
			recordedUUIDs["uuid"][EntityPropertyRecorder.CanBeAppliedTo][EntityPropertyRecorder.PreFilterFields] = {
				"EXCLUDE_PARTY_MEMBERS" }

			table.insert(
				recordedUUIDs["uuid"][EntityPropertyRecorder.CanBeAppliedTo][EntityPropertyRecorder.ItemFilterMaps],
				"All")
		elseif Osi.IsItem(entity) == 1 then
			recordedUUIDs["uuid"][EntityPropertyRecorder.Value] = Osi.GetTemplate(entity)

			table.insert(
				recordedUUIDs["uuid"][EntityPropertyRecorder.CanBeAppliedTo][EntityPropertyRecorder.ItemFilterFields],
				"Filters")
			recordedUUIDs["uuid"][EntityPropertyRecorder.CanBeAppliedTo][EntityPropertyRecorder.FilterFields] = {
				EntityPropertyRecorder.Key }

			local applicableItemFilterMaps = recordedUUIDs["uuid"][EntityPropertyRecorder.CanBeAppliedTo]
				[EntityPropertyRecorder.ItemFilterMaps]
			table.insert(applicableItemFilterMaps, "Roots")
			table.insert(applicableItemFilterMaps, "RootPartial")

			if Osi.IsEquipable(entity) == 1 then
				table.insert(applicableItemFilterMaps, "Equipment")
			end

			if Osi.IsWeapon(entity) == 1 then
				table.insert(applicableItemFilterMaps, "Weapons")
			end
		end

		return recordedUUIDs
	end
}

--- Registers new Entity Property Recorders for the given mod
--- @param modUUID that ScriptExtender has registered for your mod, for tracking purposes - <a href="https://github.com/Norbyte/bg3se/blob/main/Docs/API.md#ismodloadedmodguid">https://github.com/Norbyte/bg3se/blob/main/Docs/API.md#ismodloadedmodguid</a>
--- will throw an error if the mod identified by that UUID is not loaded
--- @tparam function ... the functions to register. Each function should accept the following params:
--- <br/>GUIDSTRING - of the entity being proceseed. Will be the character string or the item UUID, but not the rootTemplateUUID (unless a mod manually triggers recording on one)
--- <br/>and return the record entry as a table to save to the file, or nil. Can be any structure, but recommended to use the existing one (can use EntityPropertyRecorder:BuildInitialRecordEntry to construct it)
--- @treturn boolean true if the operation succeeds
function EntityPropertyRecorder:RegisterPropertyRecorders(modUUID, ...)
	local modName = ModUtils:GetModInfoFromUUID(modUUID).Name

	registeredPropertyRecorders[modName] = {}
	local recorderCount = 0
	for _, recorderFunc in pairs({ ... }) do
		table.insert(registeredPropertyRecorders[modName], recorderFunc)
		recorderCount = recorderCount + 1
	end

	Logger:BasicInfo(string.format("Mod %s registered %d new Entity Property Recorders!",
		modName,
		recorderCount))

	return true
end

--- Runs all the registered recorders against the entity and saves them to the file, if the RECORD_APPLICABLE_ENTITY_PROPS config is enabled
--- Each recorder is run inside of pcall, so all errors will be logged, but not propagated.
--- Runs an Osi.Exists check first, logging a warning if it returns false
--- Automatically run whenever an item without the AIM_PROCESSED tag is being run through AIM, or after a character joins the party
--- @tparam string entity the character GUIDSTRING or the item GUIDSTRING (not the rootTemplate)
--- @tparam boolean respectAimDisabledConfig true to respect the ENABLED AIM config property, false to only respect the RECORD_APPLICABLE_ENTITY_PROPS config. Defaults to true
--- @treturn table the recorded result for the entity, or nil if processing wasn't enabled or the entity doesn't exist
function EntityPropertyRecorder:RecordEntityProperties(entity, respectAimDisabledConfig)
	if (Config.AIM.ENABLED == 1 or respectAimDisabledConfig == false) and Config.AIM.RECORD_APPLICABLE_ENTITY_PROPS == 1 then
		if Osi.Exists(entity) == 1 then
			local recordedTable = {}
			if Osi.IsItem(entity) == 1 then
				recordedEntityProperties[Osi.GetTemplate(entity)] = {}
				recordedTable = recordedEntityProperties[Osi.GetTemplate(entity)]
			else
				recordedEntityProperties[entity] = {}
				recordedTable = recordedEntityProperties[entity]
			end

			for mod, recorders in pairs(registeredPropertyRecorders) do
				recordedTable[mod] = {}
				for _, recorderFunc in pairs(recorders) do
					local succeeded, response = pcall(function()
						return recorderFunc(entity)
					end)

					if succeeded then
						if response then
							for key, values in pairs(response) do
								recordedTable[mod][key] = values
							end
						end
					else
						Logger:BasicError(string.format(
							"Error occured while attempting to process a propertyRecorder for mod %s on entity %s; error is: \n\t%s",
							mod,
							entity,
							response))
					end
				end
			end
			Logger:BasicDebug(string.format("Finished running all recorders against entity %s, writing to %s!",
				entity,
				RECORD_FILE))

			FileUtils:SaveTableToFile(RECORD_FILE, recordedEntityProperties)

			return recordedTable
		else
			Logger:BasicWarning(string.format(
				"Tried to run the EntityPropertyRecorder on entity %s, which doesn't exist (according to Osi.Exists)!",
				entity))
		end
	end
end

--- Executes EntityPropertyRecorder:RecordEntityProperties against the current party members (as found by Osi.DB_Players:Get(nil))
--- Automatically run after the `Osi.CharacterJoinedParty` and `LevelGamplayStarted` event
--- @tparam boolean respectAimDisabledConfig true to respect the ENABLED AIM config property, false to only respect the RECORD_APPLICABLE_ENTITY_PROPS config. Defaults to true
function EntityPropertyRecorder:RecordPartyMembers(respectAimDisabledConfig)
	if Config.AIM.RECORD_APPLICABLE_ENTITY_PROPS == 1 then
		for _, player in pairs(Osi.DB_Players:Get(nil)) do
			EntityPropertyRecorder:RecordEntityProperties(player[1], respectAimDisabledConfig)
		end
	end
end

Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", function(_)
	EntityPropertyRecorder:RecordPartyMembers(true)
end)
