
System = require "system"

{
	bridge: System "Bridge", {
		powerless: true
	},
	engines: System "Engines",

	weapons: System "Weapons", {
		powerMethod: (ship, powerUsed) =>
			for weapon in *ship.weapons
				if not weapon.powered
					if powerUsed + weapon.power <= ship.reactorLevel
						weapon.powered = true
						@power += weapon.power
						return true

					return
		unpowerMethod: (ship, powerUsed) =>
			for i = #ship.weapons, 1, -1
				weapon = ship.weapons[i]
				if weapon.powered
					weapon.powered = false
					@power -= weapon.power
					return true
	},

	shields: System "Shields", {
		powerMethod: (ship, powerUsed) =>
			if powerUsed <= ship.reactorLevel - 2 and @power <= @level - 2
				@power += 2
				true
		unpowerMethod: (ship) =>
			if @power > 0
				@power -= 2
				true
		special: "shields"
	},

	lifeSupport: System "Life Support", {
		oxygen: {1, 1.5, 3, 5, 7, 9},
	},

	doorsControl: System "Doors Control", {
		options: {
			{
				label: "Open doors",
				onClick: (ship) =>
					if @power > 0
						for door in *ship.doors
							door.opened = true
			},
			{
				label: "Close doors",
				onClick: (ship) =>
					if @power > 0
						for door in *ship.doors
							door.opened = false
			}
		}
	},
}
