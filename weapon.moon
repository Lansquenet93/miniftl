
class
	new: (arg) =>
		@name = arg.name or "Test Weapon"
		@type = arg.type or "laser"

		@damage = arg.damage or 1
		@shots  = arg.shots  or 1

		@power = arg.power or 1
		@chargeTime = arg.chargeTime or 6000
		@charge = 0

		@powered = false

	update: (dt) =>
		if @powered
			@charge += dt
		else
			@charge -= dt * 2

		if @charge < 0
			@charge = 0
		elseif @charge >= @chargeTime
			@charge = @chargeTime

	__tostring: =>
		"<Weapon: #{@type}, #{@damage}dmg, #{@shots}shots>"

