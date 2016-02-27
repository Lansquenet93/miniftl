
yui = require ".yui.init"
SDL = require "SDL"

CrewView =
	new: (opts) =>
		unless opts.height
			opts.height = 52

		yui.Widget.new self, opts

		unless opts.crew
			error "no opts.crew!"

		unless opts.selection
			print "WARNING: no .selection parameter in CrewView"

		@crew = opts.crew

		@selection = opts.selection

		yui.Widget.addChild self, yui.Label {
			text: tostring @crew.name,
			x: 50
		}

		@eventListeners.click = (button) =>
			if button == 1 or button == "finger"
				print "Crewmember selected."
				@selection.type = "crew"
				@selection.crew = opts.crew

		@clickable = true

	draw: (renderer) =>
		yui.Widget.draw self, renderer

		if @selection.type == "crew" and @selection.crew == @crew
			renderer\setDrawColor 0xFFFFFF
		else
			renderer\setDrawColor 0x888888
		renderer\drawRect @rectangle!

		renderer\setDrawColor 0x44FF88
		renderer\fillRect
			x: @realX + 50,
			y: @realY + 25,
			w: @crew.health / @crew.maxHealth * (@realWidth - 50 - 10),
			h: 10
			
yui.Object CrewView, yui.Widget

