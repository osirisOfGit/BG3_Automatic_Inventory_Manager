function AddItemToTable_AddingToExistingAmount(tarTable, key, amount)
	if not tarTable[key] then
		tarTable[key] = amount
	else
		tarTable[key] = tarTable[key] + amount
	end
end

