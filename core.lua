#include "assets/scripts/util.lua"

local data
local options
local totalTicks = 0
local frames = {}
local defaultValues = {}

local lastTickStatus = {}


function InitCore(dataReference, optionsReference)
	data = dataReference
	options = optionsReference[2]

	local fogStart, fogEnd, fogAmount, fogExponent = GetEnvironmentProperty("fogParams")
	defaultValues = {GetInt("game.fire.maxcount"), GetFloat("game.fire.spread"), GetEnvironmentProperty("sunBrightness"), GetEnvironmentProperty("sunLength"), fogAmount}
end

function TickCore(dt)
	-- Average the FPS values every time the total amount of ticks match with the delay
	if totalTicks % options.counter.delay == 0 then
		data[4] = 0
		for iteration = 1, #frames do
			data[4] = data[4] + frames[iteration]
		end
		data[4] = data[4] / 60
	end

	-- Iterate over all bodies in the scene every 20 ticks (1 / 3 of a in-game second at 60 FPS)
	if totalTicks % 20 == 0 then
		local bodies = GetBodies()

		for bodyIteration = 1, #bodies do
			local body = bodies[bodyIteration]
			local shapes = GetBodyShapes(body)
			local bodyMass = GetBodyMass(body)
			local min, max = GetBodyBounds(body)
			local transform = GetBodyTransform(body)

			for shapeIteration = 1, #shapes do
				local shape = shapes[shapeIteration]

				-- The controller for all lights in the level
				if options.light.enabled then
					local lights = GetShapeLights(shape)
					
					for lightIteration = 1, #lights do
						local light = lights[lightIteration]
						local lightColor = visual.hslrgb(options.light.color[1], options.light.color[2], options.light.color[3])
						
						if options.light.colorControl then SetLightColor(light, lightColor[1], lightColor[2], lightColor[3]) end
						if options.light.intensityControl and options.light.intensity > .1 then SetLightIntensity(light, options.light.intensity) else SetLightEnabled(light, false) end
					end
				end

				-- Object stabilizer
				if options.stabilizer.enabled and VecLength(VecSub(max, min)) < 10 and (not HasTag(body, "escapevehicle")) then
					local distanceToPlayer = VecLength(VecSub(transform.pos, GetPlayerPos()))

					if distanceToPlayer > 25 and IsBodyDynamic(body) then
						if options.stabilizer.stabilizeActiveObjects == IsBodyActive(body) and options.stabilizer.stabilizeVisibleObjects == IsBodyVisible(body, 50) then
							SetBodyDynamic(body, false)
						end
					end

					if distanceToPlayer <= 25 and not IsBodyDynamic(body) then
						SetBodyDynamic(body, true)
						SetBodyVelocity(body, Vec(0, 0, 0))
					end
				end
			end

			-- Debris cleaner
			if options.cleaner.enabled then
				if IsBodyBroken(body) and VecLength(VecSub(max, min)) < data[3][options.cleaner.curve][2](math.floor(data[4])) * options.cleaner.multiplier and (bodyMass > 0 and bodyMass < 200) then
					if (options.cleaner.removeActiveDebris or not IsBodyActive(body)) and (options.cleaner.removeVisibleDebris or not IsBodyVisible(body, 50)) and not (HasTag(body, "target") or HasTag(GetBodyShapes(body)[1], "alarmbox")) then
						Delete(body)
					end
				end
			end
		end

		if HasVersion("0.8.0") then
			if options.fire.enabled then
				SetInt("game.fire.maxcount", options.fire.amount)
				SetFloat("game.fire.spread", options.fire.spread)
			else
				if lastTickStatus[1] then
					SetInt("game.fire.maxcount", defaultValues[1])
					SetFloat("game.fire.spread", defaultValues[2])
				end
			end

			if options.fog.enabled then
				local fogStart, fogEnd, fogAmount, fogExponent = GetEnvironmentProperty("fogParams")
				SetEnvironmentProperty("fogParams", fogStart, fogEnd, options.fog.amount, fogExponent)
			else
				if lastTickStatus[3] then
					SetEnvironmentProperty("fogParams", fogStart, fogEnd, defaultValues[5], fogExponent)
				end
			end

			if options.sun.enabled then
				SetEnvironmentProperty("sunBrightness", options.sun.enabled and options.sun.brightness or defaultValues[3])
				SetEnvironmentProperty("sunLength", options.sun.enabled and options.sun.length or defaultValues[4])
			else
				if lastTickStatus[2] then
					SetEnvironmentProperty("sunBrightness", defaultValues[3])
					SetEnvironmentProperty("sunLength", defaultValues[4])
				end
			end
		end

		lastTickStatus = {options.fire.enabled, options.sun.enabled, options.fog.enabled}
	end

	-- Modify the variables to fit the current data
	frames[totalTicks % 60 + 1] = 1 / dt
	totalTicks = totalTicks + 1
end