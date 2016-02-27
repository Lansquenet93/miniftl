
yui = require ".yui.init"
SDL = require "SDL"

WeaponControl =
	new: (opts) =>
		yui.Widget.new self, opts

		self.width = 130
		self.height = 100

		unless opts.weapon
			error "no opts.weapon!"

		unless opts.player
			error "no opts.player!"

		unless opts.selection
			print "WARNING: no .selection parameter in WeaponControl"

		@weapon = opts.weapon
		@selection = opts.selection
		@player = opts.player

		@clickable = true

		@eventListeners.click = (button) =>
			if button == 1 or button == "finger"
				if @weapon.powered
					@selection.type = "weapon"
					@selection.weapon = @weapon
				else
					powerUsed = 0
					for system in *@player.systems
						powerUsed += system.power

					unless powerUsed + @weapon.power <= @player.reactorLevel
						print "Not enough power!"
						return

					local weaponsControl
					for system in *@player.systems
						if system.name == "Weapons"
							weaponsControl = system
							break

					unless weaponsControl.power + @weapon.power <= weaponsControl.health
						print "Not enough system power!"
						return

					weaponsControl.power += @weapon.power
					@weapon.powered = true
			elseif button == 3 -- right
				if @weapon.powered
					@weapon.powered = false

					for system in *@player.systems
						if system.name == "Weapons"
							system.power -= @weapon.power
							return

		self\addChild yui.Label {
			text: @weapon.name or "ERROR"
		}

	draw: (renderer) =>
		if @hovered
			renderer\setDrawColor 0xFFFFFF
		elseif @selection.type == "weapon" and @selection.weapon == @weapon
			renderer\setDrawColor 0xBBBBBB
		else
			renderer\setDrawColor 0x888888
		renderer\drawRect @rectangle!
		renderer\drawRect (yui.growRectangle @rectangle!, -1)

		renderer\drawRect
			x: @realX + 5,
			y: @realY + 40,
			w: 100 * (@weapon.charge / @weapon.chargeTime),
			h: 10

		yui.Widget.draw self, renderer

yui.Object WeaponControl, yui.Widget

