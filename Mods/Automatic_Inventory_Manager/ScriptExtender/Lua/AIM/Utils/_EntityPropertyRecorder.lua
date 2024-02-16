--- @module "Utils.EntityPropertyRecorder"

EntityPropertyRecorder = {}

local RECORD_FILE = FileUtils:BuildRelativeJsonFileTargetPath("RecordedEntityProperties")

local recordedEntityProperties = {}

function EntityPropertyRecorder:LoadRecordedItems()
	if Config.AIM.RECORD_APPLICABLE_ITEM_PROPS == 1 then
		local savedItemProperties = FileUtils:LoadTableFile(RECORD_FILE)

		if savedItemProperties then
			recordedEntityProperties = savedItemProperties
		end
	end
end

EntityPropertyRecorder.ApplicableItemFilterMaps = "ApplicableItemFilterMaps"
EntityPropertyRecorder.ApplicableItemFilterFields = "ApplicableItemFilterFields"
EntityPropertyRecorder.Value = "Value"

local registeredPropertyRecorders = {}
registeredPropertyRecorders[ModUtils:GetAIMModInfo().Name] = {
	-- Tags
	function(entity)
		if Osi.IsItem(entity) == 1 then
			local recordedTags = {
				["Tags"] = {
					[EntityPropertyRecorder.ApplicableItemFilterMaps] = { "Tags" },
					[EntityPropertyRecorder.ApplicableItemFilterFields] = { "Filters" },
					[EntityPropertyRecorder.Value] = {}
				}
			}

			for _, tagUUID in pairs(Ext.Entity.Get(entity).Tag.Tags) do
				local tagTable = Ext.StaticData.Get(tagUUID, "Tag")
				if tagTable then
					table.insert(recordedTags.Tags["Value"], tagTable["Name"])
				end
			end

			return recordedTags
		end
	end,

	-- EquipmentType
	function(entity)
		if Osi.IsEquipable(entity) == 1 then
			local recordedEquipment = {
				["EquipmentType"] = {
					[EntityPropertyRecorder.ApplicableItemFilterMaps] = { "Equipment" },
					[EntityPropertyRecorder.ApplicableItemFilterFields] = { "Filters" },
					[EntityPropertyRecorder.Value] = "N/A"
				}
			}

			local equipTypeUUID = Ext.Entity.Get(entity).ServerItem.OriginalTemplate.EquipmentTypeID
			local equipType = Ext.StaticData.Get(equipTypeUUID, "EquipmentType")
			if equipType then
				recordedEquipment["EquipmentType"]["Value"] = equipType["Name"]
			end

			return recordedEquipment
		end
	end,

	-- RootTemplate
	function(entity)
		local recordedUUIDs = {
			["uuid"] = {
				[EntityPropertyRecorder.ApplicableItemFilterMaps] = {},
				[EntityPropertyRecorder.ApplicableItemFilterFields] = {},
				[EntityPropertyRecorder.Value] = "N/A"
			}
		}

		if Osi.IsPartyMember(entity, 1) == 1 then
			recordedUUIDs["uuid"][EntityPropertyRecorder.Value] = entity
			table.insert(recordedUUIDs["uuid"][EntityPropertyRecorder.ApplicableItemFilterFields], "PreFilters")
		elseif Osi.IsItem(entity) then
			recordedUUIDs["uuid"][EntityPropertyRecorder.Value] = Osi.GetTemplate(entity)
			table.insert(recordedUUIDs["uuid"][EntityPropertyRecorder.ApplicableItemFilterFields], "Filters")

			local applicableItemFilterMaps = recordedUUIDs["uuid"][EntityPropertyRecorder.ApplicableItemFilterMaps]
			table.insert(applicableItemFilterMaps, "Roots")
			table.insert(applicableItemFilterMaps, "RootPartial")

			if Osi.IsEquipable(entity) then
				table.insert(applicableItemFilterMaps, "Equipment")
			end

			if Osi.IsWeapon(entity) then
				table.insert(applicableItemFilterMaps, "Weapons")
			end
		end

		return recordedUUIDs
	end
}


function EntityPropertyRecorder:RecordEntityProperties(entity)

end
