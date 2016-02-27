
yui = require ".yui.init"
SDL = require "SDL"

return (system, ship) ->
	frame = yui.Frame {
		width: if system.options then 92 else 60,
		height: 276,
		events:
			update: (dt) =>
				--self.y = self.parent.height - self.realHeight
				self.realHeight = self.parent.height

		yui.Label {
			text: system.name
		},
		yui.Button
			width: 48,
			height: 48,
			x: 5,
			y: 276 - 48 - 5,
			events:
				click: (click) =>
					if click == 1 or click == "finger"
						ship\power system
					elseif click == 3
						ship\unpower system
	}

	for i = 1, system.level
		frame\addChild yui.Button {
			width: 40,
			height: 5,
			x: 10,
			y: 276 - 48 - 7 - i * 8,
			theme:
				drawButton: (renderer) =>
					if system.health < i
						renderer\setDrawColor 0xFF0000
					elseif system.power >= i
						renderer\setDrawColor 0x00FF00
					else
						renderer\setDrawColor 0xFF8800

					renderer\fillRect @rectangle!
		}

	if system.options
		for i = 1, #system.options
			option = system.options[i]

			frame\addChild yui.Button {
				width: 24,
				height: 24,
				x: 60,
				y: 276 - 92 - i * 28,

				events:
					click: (button) =>
						if button == 1 or button == "finger"
							option.onClick system, ship
			}

	frame

