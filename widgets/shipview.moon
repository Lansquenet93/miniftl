
yui = require ".yui.init"
SDL = require "SDL"

RoomButton = (room, parent) ->
	{:x, :y} = room.position
	rect =
		x: x,
		y: y,
		w: room.width,
		h: room.height

	if parent.rotated
		rect.x, rect.y = rect.y, rect.x
		rect.w, rect.h = rect.h, rect.w

	gridWidth = parent.ship.tiles.width
	gridHeight = parent.ship.tiles.height
	if parent.rotated
		gridWidth, gridHeight = gridHeight, gridWidth

	yui.Button {
		x: (parent.width - 48 * gridWidth) / 2 + (rect.x - 1) * 48,
		y: (parent.height - 48 * gridHeight) / 2 + (rect.y - 1) * 48,
		width: 48 * rect.w,
		height: 48 * rect.h,

		events:
			click: (button) =>
				local fireWeapon, moveCrew
				if button == "finger"
					if parent.selection.type == "weapon"
						fireWeaon = true
					elseif parent.selection.type == "crew"
						moveCrew = true
				elseif button == 1
					if parent.selection.type == "weapon"
							fireWeapon = true
				elseif button == 3
					if parent.selection.type == "crew"
						moveCrew = true

				if fireWeapon
					weapon = parent.selection.weapon

					weapon.target = {
						room: room,
						ship: parent.ship
					}

					parent.selection.type = "none"
				elseif moveCrew
					parent.selection.crew\pathfinding parent.ship.dijkstra, room, parent.ship.tiles

					parent.selection.type = "none"

		theme:
			drawButton: (renderer) =>
				renderer\setDrawColor {r: math.floor (127 * (100 - room.oxygen) / 100), g: 0, b: 0}
				renderer\fillRect @rectangle!

				if room.system
					renderer\setDrawColor 0x88FF88
				else
					renderer\setDrawColor 0x888888

				renderer\drawRect @rectangle!

				for x = 1, room.width
					for y = 1, room.height
						tile = parent.ship.tiles[room.position.x + x - 1][room.position.y + y - 1]

						if parent.rotated
							x, y = y, x

						if tile.fire > 0
							renderer\setDrawColor 0xFF0000
							renderer\drawRect
								x: @realX + 5 + 48 * (x - 1),
								y: @realY + 5 + 48 * (y - 1),
								w: 48 - 10,
								h: 48 - 10

						if tile.breach > 0
							renderer\setDrawColor 0x888888
							renderer\drawRect
								x: @realX + 7 + 48 * (x - 1),
								y: @realY + 7 + 48 * (y - 1),
								w: 48 - 16,
								h: 48 - 16
	}

DoorButton = (door, parent) ->
	{:x, :y} = door.position

	local rect
	if door.type == "horizontal"
		rect =
			x: (x - 1) * 48 + 8,
			y: y * 48 - 6,
			w: 48 - 2 * 8,
			h: 12
	else
		rect =
			x: x * 48 - 6,
			y: (y - 1) * 48 + 8,
			w: 12,
			h: 48 - 2 * 8

	gridWidth = parent.ship.tiles.width
	gridHeight = parent.ship.tiles.height

	if parent.rotated
		rect.x, rect.y = rect.y, rect.x
		rect.w, rect.h = rect.h, rect.w

		gridWidth, gridHeight = gridHeight, gridWidth

	rect.x += parent.realX + parent.width / 2 - 48 * gridWidth / 2
	rect.y += parent.realY + parent.height / 2 - 48 * gridHeight / 2

	yui.Button
		x: rect.x,
		y: rect.y,
		width: rect.w,
		height: rect.h,
		events:
			click: (button) =>
				unless parent.controlable
					return false

				if button == 1 or button == "finger"
					door.opened = not door.opened
		theme:
			drawButton: (renderer) =>
				renderer\setDrawColor 0x000000
				renderer\fillRect @rectangle!

				if @hovered and parent.controlable
					if door.opened
						renderer\setDrawColor 0xFF8888
					else
						renderer\setDrawColor 0xBBBBBB
				else
					if door.opened
						renderer\setDrawColor 0xFF0000
					else
						renderer\setDrawColor 0x888888

				renderer\drawRect @rectangle!

CrewButton = (crew, parent) ->
	yui.Button
		width: 32,
		height: 32,

		events:
			update: (dt) =>
				x = crew.position.x
				y = crew.position.y

				gridWidth = parent.ship.tiles.width
				gridHeight = parent.ship.tiles.height

				if parent.rotated
					gridWidth, gridHeight = gridHeight, gridWidth
					x, y = y, x

				@x = (crew.position.x - 1) * 48 + 8 + (parent.width - gridWidth * 48) / 2
				@y = (crew.position.y - 1) * 48 + 8 + (parent.height - gridHeight * 48) / 2

			click: (button) =>
				if button == 1 or button == "finger"
					parent.selection.type = "crew"
					parent.selection.crew = crew

		theme:
			drawButton: (renderer) =>
				renderer\setDrawColor 0x00FF88
				renderer\drawRect @rectangle!

ShipView =
	new: (opts) =>
		yui.Widget.new self, opts

		unless opts.ship
			error "no opts.ship!"

		self.ship = opts.ship
		self.rotated = opts.rotated or false
		self.controlable = opts.controlable or false

		unless opts.selection
			print "WARNING: no .selection in parameters!"

		@selection = opts.selection

		for room in *@ship.rooms
			self\addChild (RoomButton room, self)

		for crew in *@ship.crew
			self\addChild (CrewButton crew, self)

		for door in *@ship.doors
			self\addChild (DoorButton door, self)

	draw: (renderer) =>
		renderer\setDrawColor 0xFF8800
		renderer\drawRect @rectangle!
		renderer\drawRect yui.growRectangle @rectangle!, -1

		yui.Widget.draw self, renderer

		if PRINTING_CENTERED_SHIP_BLOCK
			renderer\setDrawColor 0xFF0088
			if @rotated
				renderer\drawRect
					x: @realX + (@realWidth - @ship.tiles.height * 48) / 2,
					y: @realY + (@realHeight - @ship.tiles.width * 48) / 2,
					w: 48 * @ship.tiles.height,
					h: 48 * @ship.tiles.width
			else
				renderer\drawRect
					x: @realX + (@realWidth - @ship.tiles.width * 48) / 2,
					y: @realY + (@realHeight - @ship.tiles.height * 48) / 2,
					w: 48 * @ship.tiles.width,
					h: 48 * @ship.tiles.height

yui.Object ShipView, yui.Widget

