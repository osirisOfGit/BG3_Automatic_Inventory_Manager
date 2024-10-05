Upgrade = {}

function Upgrade:StategySpellingFix(filterTable, filterTableFilePath)
	for _, itemFilter in pairs(filterTable) do
		for _, filter in pairs(itemFilter.Filters) do
			for key, value in pairs(filter) do
				if string.upper(key) == string.upper("CompareStategy") then
					filter["CompareStrategy"] = value
					filter[key] = nil
				end
			end
		end
	end

	FileUtils:SaveTableToFile(filterTableFilePath, filterTable)
end
