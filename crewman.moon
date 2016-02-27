
class
	new: (species, name) =>

		@name = name or "unnamed person"
		@team = "ally"
		@boarding = false
		@experience = {}

		@maxHealth = species.health or 100
		@health    = species.health or 100

		@chargeTime = species.chargeTime or 120
		@charge = @chargeTime
		@damage = species.damage or 10

		@quickness = species.quickness or 0.6
		@position =
			x: 0
			y: 0
		@move =
			trajectory: {}
			trajInd: 1
		for ability in *@@abilities
			@experience[ability] = 0

	abilities: {
		"pilot", "shields", "weapons", "repairs", "fights"
	}

	gainExperience: (domain) =>
		@experience[domain] += 1

	move: (destination) =>
		@position = destination

	pathfinding: (dijkstra, room, tiles) =>
		unless room
			error "room is nil"
		
		local destination
		
		positions = {}
		
		positions = room\positionTiles !
		
		stop = false
		i = 1
		
		while positions[i] and not stop
			unless tiles[positions[i].x][positions[i].y].crewMember[@team]
				destination = positions[i]
				stop = true
			i += 1
				
		
		unless destination
			print "room is already full"
			return nil

		x = math.floor (@position.x + 0.5)
		y = math.floor (@position.y + 0.5)

		origInd = tiles[x][y].posInDijkstra
		destInd = tiles[destination.x][destination.y].posInDijkstra

		dijkstra[destInd].weight = 0
		dijkstra[destInd].goTo = "arrived"
		
		i = destInd
		
--		print dijkstra[i].goTo .. " " .. dijkstra[i].position.x .. " " .. dijkstra[i].position.y
		
		while i != origInd
		
			for link in *dijkstra[i].links
			
				if link.tile
				
					if link.tile.weight > dijkstra[i].weight+1 and not link.tile.process
						link.tile.weight = dijkstra[i].weight+1
						
						if dijkstra[i].position.x < link.tile.position.x
							link.tile.goTo = "left"
						elseif dijkstra[i].position.x > link.tile.position.x
							link.tile.goTo = "right"
						elseif dijkstra[i].position.y < link.tile.position.y
							link.tile.goTo = "up"
						elseif dijkstra[i].position.y > link.tile.position.y
							link.tile.goTo = "down"
						
--						print link.tile.goTo .. " " .. link.tile.position.x .. " " .. link.tile.position.y
				
			dijkstra[i].process = true
			i = origInd
			
			for j = 1, #dijkstra
				if dijkstra[j].weight < dijkstra[i].weight and not dijkstra[j].process
					i = j
			
		if dijkstra[origInd].weight == math.huge
			print "destination unreachable"
			return nil

		trajectory = {}
		
		trajectory[1] = dijkstra[origInd]
			
		tile = dijkstra[origInd]
		
		while tile.position.x != destination.x or tile.position.y != destination.y
			stop = false
			i = 1
			
			while tile.links[i] and not stop
				if tile.links[i].direction == tile.goTo
					tile = tile.links[i].tile
					stop = true
					
				i+=1
				
			unless stop
				print "there is no such a direction"
				return nil
				
			trajectory[#trajectory+1] = tile
			
		dijkstra[origInd].crewMember[@team] = nil
		dijkstra[destInd].crewMember[@team] = self
		
		for tile in *dijkstra
			tile.goTo = nil
			tile.weight = math.huge
			tile.process = false
		
		@move.trajectory = trajectory
		@move.trajInd = 1
		@move.trajectory[#@move.trajectory].crewMember.team = self
		@move.trajectory[1].crewMember[@team] = nil

	roundPos: =>
		position = {
			x: math.floor (@position.x + 0.5)
			y: math.floor (@position.y + 0.5)
		}
		return position

	update: (dt, battle, room, fire) =>
		
		--print @name
		
		if fire
			@health -= 5 * dt / 1000
		
		if room.oxygen < 30
			@health -= 5 * dt / 1000
		
		if @health < 0
			@health = 0
		
		if @move.trajectory
			if #@move.trajectory > 1
		
				dest = @move.trajectory[@move.trajInd+1].position
				dirx = dest.x - @move.trajectory[@move.trajInd].position.x
				diry = dest.y - @move.trajectory[@move.trajInd].position.y
	
				if dirx != 0 and diry != 0
					@position.x += (math.sqrt 2) * dirx * @quickness * dt / 1000
					@position.y += (math.sqrt 2) * diry * @quickness * dt / 1000
				else
					@position.x += dirx * @quickness * dt / 1000
					@position.y += diry * @quickness * dt / 1000

				if @position.x*dirx > dest.x*dirx
					@position.x = dest.x

				if @position.y*diry > dest.y*diry
					@position.y = dest.y

				if @position.x == dest.x and @position.y == dest.y
					@move.trajInd +=1
		
				if @move.trajInd == #@move.trajectory
					@move.trajInd = 1
					@move.trajectory = {}

		else
			@charge += dt
			if @charge > @chargeTime
				@charge = @chargeTime

			team = "ally"
			if @team = "ally"
				team = "enemy"
			enemies = {}
			for tile in *room.tiles
				enemies[#enemies+1] = tile.crewMember[team]

			target = enemies[1]
			
			for enemy in *enemies
				if enemy.position.x == @position.x and enemy.position.y == @position.y
					 target = enemy

			if target
				if @charge == @chargeTime
					enemy.health -= @damage
					@charge = 0

			else
				if room.system
					if room.system.health < room.system.level * 10
						room.system.health += dt/1000
					if room.system.health > room.system.level * 10
						room.system.health = room.system.level * 10

