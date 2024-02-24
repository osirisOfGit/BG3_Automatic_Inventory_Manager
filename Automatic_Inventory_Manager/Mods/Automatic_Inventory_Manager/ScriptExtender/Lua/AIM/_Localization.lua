Localization = {
	english = {
		itemIdentifier = "When a party member receives one or more of",
		rules = "I want to",
		prefilters = {
			key = "Exclude any party member that",
			hasStackAmountOver = "is carrying more than",
			isOneOfClassOrSubclass = "is one of the following classes or subclasses",
			isOneOfCharacter = "is one of the following characters"
		},
		filters = {
			key = "Find the party member that, in priority order,",
			comparisonFilters = {
				compareStrategy = {
					key = "has the",
					higher = {
						"highest",
						"most"
					},
					lower = {
						"lowest",
						"least"
					},
				},
				propertyToCompare = {
					key = {
						"amount of",
						"level of"
					},
					amountOfItemInInventory = "the same item in their inventory",
					healthPercentage = "health",
					proficiency = "proficiency",
					ac = "armor class",
					weaponAbility = "stat used by weapon",
					weaponScore = "weapon score as determined by Larian math",
					skill = {
						key = "skill",
						values = {
							key = "for",
							allowedValues = {}
						}
					},
					ability = {
						key = "ability",
						values = {
							key = "for",
							allowedValues = {}
						}
					}
				}
			},
			booleanFilters = {
				key = "does have",
				sameEquipmentType = "the same type of equipment or weapon equipped",
				isOneOfClassOrSubclass = {
					key = "at least one level",
					values = {
						key = "in one of the following classes or subclasses",
						allowedValues = {}
					}
				}
			}
		}
	}
}
