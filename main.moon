
yui = require ".yui.init"
SDL = require "SDL"

Ship = require "ship"
Room = require "room"
System = require "system"
CrewMan = require "crewman"
Weapon = require "weapon"
Battle = require "battle"

cli = require "cli"

-- Custom widgets.
ShipView = require "widgets.shipview"
CrewView = require "widgets.crewview"
SystemView = require "widgets.systemview"
ReactorView = require "widgets.reactorview"
WeaponControl = require "widgets.weaponcontrol"

-- Game data.
systems = require "data.systems"
ships = require "data.ships"

-- Model
battle = Battle!

selection = {
	type: "none"
}

player = ships.raider2\clone!\finalize!

battle\addShip player, 1
battle\addShip ships.raider2\clone!\finalize!, 1

battle\addShip ships.raider\clone!\finalize!, 2
battle\addShip ships.raider2\clone!\finalize!, 2

with player
	\addCrew (CrewMan {}, "Luke"), {x: player.rooms[3].position.x, y: player.rooms[3].position.y}

	\addCrew (CrewMan {}, "Leia"), {x: player.rooms[#player.rooms].position.x, y: player.rooms[#player.rooms].position.y}

	.reactorLevel = 18

	\addWeapon Weapon
		name: "Big Laser"
		power: 3
		shots: 3
	\addWeapon Weapon
		name: "Simple Laser"
	\addWeapon Weapon
		name: "Fire Laser" -- wait, what?
		chargeTime: 2000
		fireChance: 100

for room in *player.rooms
	print room

	if room.system
		print "", room.system

for ship in *battle.ships
	for system in *ship.systems
		while ship\power system
			true

ShieldsIndicator = (ship, opts) ->
	yui.Frame
		x: opts.x,
		y: opts.y,
		id: opts.id,
		width: 40 * 4 + 5 + 125,
		height: 45,
		theme:
			drawFrame: (renderer) =>
				maxShields = ship\getMaxShields!

				renderer\setDrawColor 0x0088FF

				renderer\drawRect @rectangle!

				for i = 1, ship.shields
					renderer\drawRect
						x: @realX + (i - 1) * 40 + 5,
						y: @realY + 5,
						w: 35,
						h: 35

				renderer\setDrawColor 0x004488

				for i = ship.shields + 1, maxShields
					renderer\drawRect
						x: @realX + (i - 1) * 40 + 5,
						y: @realY + 5,
						w: 35,
						h: 35

				if ship.shieldsProgress > 0
					renderer\setDrawColor 0x0088FF

					renderer\drawRect
						x: @realX + 4 * 40 + 5,
						y: @realY + 5,
						w: math.floor math.floor (ship.shieldsProgress / Ship.shieldsChargeTime) * 120,
						h: 35

HealthIndicator = (ship, opts) ->
	with yui.Frame
		width: 12 * 30 + 2,
		height: 22,
		x: opts.x,
		y: opts.y,
		id: opts.id,
		theme:
			drawFrame: (renderer) =>
				renderer\setDrawColor 0x44FF88

				renderer\drawRect @rectangle!

				for i = 1, @ship.health
					renderer\drawRect
						x: @realX + (i - 1) * 12 + 2,
						y: @realY + 2,
						w: 10,
						h: 18
		.ship = ship

updateTargetView = (ship) =>
	view = self\getRoot!\getElementById "targetView"

	view\removeChild view.children[#view.children]

	view\addChild ShipView
		width: view.realWidth,
		height: view.realHeight,
		ship: ship,
		selection: selection,
		rotated: true

	e = self\getRoot!\getElementById "targetHealth"
	e.ship = ship

updateTargetSelector = (battle) =>
	selector = @\getElementById "targetShipSelector"

	for i = 1, #battle.ships
		ship = battle.ships[i]

		selector\addChild yui.Button {
			x: 2,
			y: 2 + 50 * (i - 1),
			width: 86,
			height: 48,

			theme:
				drawButton: (renderer) =>
					fleet = battle\fleetOf ship
					if fleet == 1
						renderer\setDrawColor 0x8888FF
					elseif fleet == 2
						renderer\setDrawColor 0xFF8888
					else
						renderer\setDrawColor 0x888888

					renderer\drawRect @rectangle!

			events:
				click: (button) =>
					if button == 1 or button == "finger"
						updateTargetView self, ship

			yui.Label
				text: ship.name
		}

--cli.dump player

yui.init!

yui\loadFont "default", "DejaVuSans.ttf", 18

w = yui.Window {
	width:  1280,
	height: 800,
	--flags: {SDL.window.Resizable},

	events:
		update: (dt) =>
			battle\update dt

	theme:
		drawRow: (r) =>
			if @hovered
				r\setDrawColor 0xFFFFFF
			else
				r\setDrawColor 0x888888

			r\drawRect yui.growRectangle @rectangle!, 2

	ShipView {
		x: 160,
		y: 100,
		width: 600,
		height: 400,
		selection: selection,
		ship: player,
		controlable: true
	},

	yui.Frame {
		x: 760,
		y: 100,
		width: 400,
		height: 600,
		id: "targetView",

		ShipView {
			width: 400,
			height: 600,
			ship: battle.fleets[2][1],
			selection: selection,
			rotated: true,
		},
	},

	yui.Column {
		width: 1280,
		yui.Frame {
			height: 100,
			events:
				update: (dt) =>
					root = self\getRoot!
					self.realWidth = root.width

			HealthIndicator player, {
				id: "playerHealth",
			},

			ShieldsIndicator player, {
				x: 0,
				y: 50
			}

			HealthIndicator battle.fleets[2][1], {
				x: 700,
				y: 1,
				id: "targetHealth",
			},
			ShieldsIndicator battle.fleets[2][1], {
				x: 700,
				y: 24,
				id: "targetShields"
			}
		},
		yui.Row {
			width: 160,
			events:
				update: (dt) =>
					root = self\getRoot!
					self.realHeight = root.height - 376

			yui.Column {
				width: 160,

				events:
					update: (dt) =>
						self.realWidth = self.parent.realWidth

				unpack [(CrewView crew: crew, selection: selection) for crew in *player.crew]
			}
		},
		yui.Row {
			height: 276,
			events:
				update: (dt) =>
					if #@children == 0
						self\addChild ReactorView player

						for system in *player.systems
							self\addChild SystemView system, player, frame
		}
	},
	yui.Row {
		width: 400,
		height: 100,
		x: 1280 - 400 * 2 - 20 * 2,
		y: 800 - 100 - 20,

		events:
			update: (dt) =>
				if #@children == 0
					for weapon in *player.weapons
						self\addChild (WeaponControl
							player: player,
							weapon: weapon,
							selection: selection
						)
	},
	yui.Frame {
		x: 1280 - 2 - 88 - 4,
		y: 2,
		width: 2 + 88,
		height: 2 + 8 * 50,
		id: "targetShipSelector",
		theme:
			drawFrame: (renderer) =>
				renderer\setDrawColor 0x000000
				renderer\fillRect @rectangle!

				renderer\setDrawColor 0x888888
				renderer\drawRect @rectangle!
	},
	yui.Frame {
		width: 400,
		height: 100,
		x: 1280 - 400 - 20,
		y: 800 - 100 - 20
	}
}

updateTargetSelector w, battle
updateTargetView w, battle.fleets[2][1]

--player.crew[1]\pathfinding player.dijkstra, player.rooms[5], player.tiles
--player.crew[2]\pathfinding player.dijkstra, player.rooms[5], player.tiles
player.tiles[player.rooms[5].position.x][player.rooms[5].position.y].fire = 100

c = true
while c do
	c = yui\run {w}

