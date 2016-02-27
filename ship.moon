
Room = require "room"
Tile = require "tile"

class
	new: (name = "") =>
		@name = name

		@scrap    = 0
		@missiles = 0
		@fuel     = 0
		@parts    = 0

		@rooms   = {}
		@doors   = {}
		@systems = {}
		@crew    = {}
		@weapons = {}

		-- Sane default value.
		@reactorLevel = 8

		@maxHealth = 30
		@health    = 30

		@shieldsProgress = 0
		@shields = 0

	clone: =>
		n = @@ @name

		n.scrap    = @scrap
		n.missiles = @missiles
		n.fuel     = @fuel
		n.parts    = @parts

		for room in *@rooms
			n\addRoom room\clone!, {x: room.position.x, y: room.position.y}

		for door in *@doors
			n\addDoor {x: door.position.x, y: door.position.y}, door.type

		for system in *@systems
			n\addSystem system\clone!,
				(n.getRoomByCoordinates n,
					system.room.position.x,
					system.room.position.y
				), system.level

		for crew in *@crew
			n\addCrew crew\clone!

		n.reactorLevel = @reactorLevel

		n.maxHealth = @maxHealth
		n.health    = @health

		n.shields = 0

		n

	addRoom: (room, to) =>
		@rooms[#@rooms+1] = room

		room.position = to

	addDoor: (position, type) =>
		@doors[#@doors+1] = {
			position: position,
			type: type
		}

	addSystem: (system, room, level) =>
		system = system\clone!
		
		unless room
			error "room is nil"
		
		unless level
			error "level is nil"

		@systems[#@systems+1] = system

		system.room = room
		room.system = system

		system.level = level
		system.health = level

	addCrew: (crew, position) =>
		@crew[#@crew+1] = crew
		crew.position = position

		tile = @tiles[position.x][position.y]

		tile.crewMember["ally"] = crew

		if tile.posInDijkstra
			@dijkstra[@tiles[position.x][position.y].posInDijkstra].crewMember["ally"] = crew

	addWeapon: (weapon) =>
		@weapons[#@weapons+1] = weapon

	power: (system) =>
		powerUsed = 0
		for sys in *@systems
			powerUsed += sys.power

		local powered

		if system.powerMethod
			powered = system\powerMethod self, powerUsed
		else
			if system.power < system.level and powerUsed < @reactorLevel
				system.power += 1

				powered = true

		while system.power > system.health and system.power > 0
			powered = powered and not self\unpower system

		powered

	unpower: (system) =>
		if system.unpowerMethod
			system\unpowerMethod self
		else
			if system.power > 0
				system.power -= 1

				true

	getMaxShields: =>
		for system in *@systems
			if system.special == "shields"
				return (system.power - system.power % 2) / 2

		return 0

	getRoomByCoordinates: (x, y) =>
		print ">", x, ":", y
		for room in *@rooms
			print room.position.x, ":", room.position.y
			if room.position.x == x and room.position.y == y
				return room

	finalize: () =>

		width = 1
		height = 1
		@tiles = {}
		@dijkstra = {}

		for room in *@rooms
			room.tiles = {}
			for j = 0, room.height-1
				for i = 0, room.width-1

					x = room.position.x + i
					y = room.position.y + j

					tile = Tile x, y
					tile.posInDijkstra = #@dijkstra+1
					room.tiles[#room.tiles+1] = tile

					unless @tiles[x]
						@tiles[x] = {}

					@tiles[x][y] = tile
					@dijkstra[#@dijkstra+1] = tile
					@dijkstra[#@dijkstra].weight = math.huge
					@dijkstra[#@dijkstra].goTo
					@dijkstra[#@dijkstra].process = false

					if x > width
						width = x

					if y > height
						height = y
					
					unless x == room.position.x
						tile\addLink @tiles[x-1][y], nil, "left"
						@dijkstra[tile.posInDijkstra]\addLink @dijkstra[@tiles[x-1][y].posInDijkstra], nil, "left"
					
					unless y == room.position.y
						tile\addLink @tiles[x][y-1], nil, "up"
						@dijkstra[tile.posInDijkstra]\addLink @dijkstra[@tiles[x][y-1].posInDijkstra], nil, "up"

		@tiles.width = width
		@tiles.height = height
		
		for i = 1, width
			unless @tiles[i]
				@tiles[i] = {}

		for door in *@doors
			tile = @tiles[door.position.x][door.position.y]

			if door.type == "vertical"
				if tile
					tile\addLink @tiles[door.position.x+1][door.position.y], door, "right"
				else
					tile = @tiles[door.position.x+1][door.position.y]
					tile\addLink @tiles[door.position.x][door.position.y], door, "left"


			if door.type == "horizontal"
				if tile
					tile\addLink @tiles[door.position.x][door.position.y+1], door, "down"
				else
					tile = @tiles[door.position.x][door.position.y+1]
					tile\addLink @tiles[door.position.x][door.position.y], door, "up"
			
		self


	update: (dt, battle) =>
		maxShields = self\getMaxShields!

		oxygen = 0

		for system in *@systems
			if system.oxygen
				oxygen += system.oxygen[system.power] or 0

		if oxygen == 0 -- no oxygen generation.
			for room in *@rooms
				room.oxygen -= 1.5 * dt /1000

				if room.oxygen < 0
					room.oxygen = 0
		else
			for room in *@rooms
				room.oxygen += oxygen * dt / 1000

				if room.oxygen > 100
					room.oxygen = 100

		do
			for room in *@rooms
				room.oldOxygen = room.oxygen

			for room in *@rooms
				links = @\doorsOfRoom room

				doors = 0
				oxygen = 0
				for link in *links
					if link.door.opened
						if link.tile
							-- Adjacent room.
							roomt = @\roomByPos link.tile.position

							doors += 1
							oxygen += roomt.oldOxygen

				room.oxygen = (room.oldOxygen * 60 + oxygen) / (60 + doors)

			for room in *@rooms
				links = @\doorsOfRoom room

				for link in *links
					if link.door.opened
						if not link.tile
							room.oxygen = 0

			for room in *@rooms
				room.oxygen = math.max room.oxygen, 0
				room.oldOxygen = nil
		
		local crewPos
		local room
		
		for crewman in *@crew
			oxygen = true
			crewPos = crewman\roundPos!
			room = @\roomByPos crewPos
			
			positions = room\positionTiles!
			fire = false
			
			for position in *positions
				if @tiles[position.x][position.y].fire > 0
					fire = true

			if room.oxygen < 30
				oxygen = false
			crewman\update dt, battle, fire, oxygen
		
		for weapon in *@weapons
			weapon\update dt, battle

		if @shields == maxShields
			return

		if @shields > maxShields
			@shields = maxShields
			return

		@shieldsProgress += dt

		if @shieldsProgress >= @@shieldsChargeTime
			@shields += 1

			if @shields < maxShields
				@shieldsProgress -= @@shieldsChargeTime
			else
				@shieldsProgress = 0

	__tostring: =>
		"<Ship: #{@name}>"

	shieldsChargeTime: 2000

	damage: (projectile) =>
		local damage

		if projectile.weapon.type == "missile"
			damage = projectile.weapon.damage
		elseif projectile.weapon.type == "beam"
			damage = projectile.weapon.damage - @shields
		else
			damage = projectile.weapon.damage

			if @shields > 0
				@shields = @shields - 1
				return
		
		@health = @health - damage

		room = projectile.targetRoom
		if room.system
			room.system.health = room.system.health - damage
			unpower = room.system.power - room.system.health

			if unpower > 0
				for i = 1, unpower
					self\unpower(room.system)

		tiles = {}

		for i = 0, room.width-1
			for j = 0, room.height-1
				tiles[#tiles+1] = @tiles[room.position.x+i][room.position.y+j]

		for tile in *tiles
			if tile.crewMember[1]
				crewMember[1].health -= projectile.weapon.crewDamage
			if tile.crewMember[2]
				crewMember[2].health -= projectile.weapon.crewDamage

			if (math.random 0, 100) < projectile.weapon.fireChance
				tile.fire = 100
			
			if (math.random 0, 100) < projectile.weapon.breachChance
				tile.breach = 100


	roomByPos: (position) =>
		
		for room in *@rooms
			if room.position.x <= position.x and room.position.x + room.width > position.x
				if room.position.y <= position.y and room.position.y + room.height > position.y
					return room
		print "there is no room at these coordinates"

	doorsOfRoom: (room) =>
		positions = @\roomByPos(room.position)\positionTiles !
		
		links = {}
		
		for position in *positions
			for link in *@tiles[position.x][position.y].links
				if link.door
					links[#links+1] = link
		
		return links
