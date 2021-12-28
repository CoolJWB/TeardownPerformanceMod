#include "umf/umf_meta.lua"
#include "umf/umf_utils.lua"

VEC_MIN = Vec(-math.huge, -math.huge, -math.huge)
VEC_MAX = Vec(math.huge, math.huge, math.huge) 

-- UI functions
	function UiDrawLine(dx, dy, r, g, b, a)
		UiPush()
			UiColor(r, g, b, a)
			UiRotate(math.atan2(-dy, dx) * 180 / math.pi)
			UiRect((dx * dx + dy * dy) ^ .5, 1)
		UiPop()
	end

	function UiEmptyButton(w, h, backColor)
		UiAlign("left")

		local info = {UiIsMouseInRect(w, h), InputPressed("lmb"), InputDown("lmb")}
		local colorOffset = (info[1] and info[3]) and .1 or 0

		-- Button background
		UiPush()
			UiColor(backColor[1] - colorOffset, backColor[2] - colorOffset, backColor[3] - colorOffset, backColor[4] ~= nil and backColor[4] or 1)
			UiRect(w, h)
		UiPop()

		return info
	end

	function UiTextedButton(text, align, w, h, backColor, textColor)
		local info = UiEmptyButton(w, h, backColor)
		local colorOffset = (info[1] and info[3]) and .1 or 0

		-- Button text
		UiPush()
			UiTranslate(w / 2 + ((info[1] and info[3]) and 2 or 0), h / 2 + ((info[1] and info[3]) and 2 or 0))
			UiAlign(align)
			UiColor(textColor[1] + colorOffset, textColor[2] + colorOffset, textColor[3] + colorOffset, textColor[4] ~= nil and textColor[4] or 1)
			UiText(text)
		UiPop()

		return info[1] and info[2], info[1] and info[3]
	end

	function UiColoredSlider(value, rangeMin, rangeMax, w, h, backColor, sliderColor)
		local info = {UiIsMouseInRect(w, h), InputPressed("lmb"), InputDown("lmb")}
		
		UiPush()
			-- Slider background
			UiAlign("left")
			UiColor(backColor[1], backColor[2], backColor[3], backColor[4] ~= nil and backColor[4] or 1)
			UiRect(w, h)
		UiPop()

		-- Slider button
		local valueWidth = w / rangeMax
		local widthValue = rangeMax / w
		local x = (info[1] and info[3]) and UiGetMousePos() or (valueWidth * value)

		UiPush()
			UiWindow(x, h, true)
			UiColor(sliderColor[1], sliderColor[2], sliderColor[3], sliderColor[4])
			UiRect(x - 8, h)

			UiTranslate(x - 8)
			UiColor(sliderColor[1] + .1, sliderColor[2] + .1, sliderColor[3] + .1, sliderColor[4])
			UiRect(16, h)
		UiPop()

		UiPush()
			UiAlign("center middle")
			UiTranslate(w / 2, h / 2)
			UiColor(1, 1, 1, 1)
			UiFont("bold.ttf", 18)
			UiText(value)
		UiPop()

		return widthValue * x
	end

	function UiColorPicker(lastColor, scale)
		local size = (480 * scale)
		local mouseX, mouseY = UiGetMousePos()
		local positions = (UiIsMouseInRect(size, size) and InputDown("lmb")) and {1 / size * math.min(math.max(mouseX, 0), size), 1, 1 / size * math.min(math.max(mouseY, 0), size)} or lastColor
		local color = visual.hslrgb(positions[1], positions[2], positions[3])

		UiPush()
			UiScale(scale)
			UiColor(1, 1, 1, 1)
			UiImage("assets/gfx/palette/palette.png")
			UiPush()
				local invserseColorLightness = visual.hslrgb(0, 0, 1 - positions[3])
				UiAlign("center middle")
				UiTranslate(480 * positions[1], 480 * positions[3])
				UiScale(.1 / scale)
				UiColor(invserseColorLightness[1], invserseColorLightness[2], invserseColorLightness[3])
				UiImage("assets/gfx/palette/palette_pointer.png")
			UiPop()
		UiPop()

		return positions
	end

	function UiInformationCounter(x, y, scale, data, options)
		UiPush()
			local color = visual.hslrgb(options.counter.textColor[1][1], options.counter.textColor[1][2], options.counter.textColor[1][3])
			local xAlignments = {"left", "center", "right"}
			local yAlignments = {"top", "middle", "bottom"}
			local xAlignment = Round(2 * options.counter.position[1] / UiWidth())
			local yAlignment = Round(2 * options.counter.position[2] / UiHeight())

			local enabledCounts = 0
			local counts = {{options.counter.frameCount, CalculateFrameAccuracy(data[4], options), "FPS"}, {options.counter.bodyCount, data[5], "BOD"}, {options.counter.shapeCount, data[6], "SHA"}, {options.counter.fireCount, data[7], "FIR"}}
			for enabledCountsIteration = 1, #counts do
				enabledCounts = enabledCounts + (counts[enabledCountsIteration][1] and 1 or 0)
			end

			-- Draw the counter background
			local backgroundSize = 15 * enabledCounts * scale + (enabledCounts > 0 and 5 or 0) * scale
			local backgroundColor = visual.hslrgb(options.counter.backColor[1][1], options.counter.backColor[1][2], options.counter.backColor[1][3])
			UiAlign(xAlignments[xAlignment + 1] .. yAlignments[yAlignment + 1])
			UiTranslate(options.counter.position[1] + x, options.counter.position[2] + y)
			UiColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], options.counter.backColor[2])
			UiRect(60 * scale, backgroundSize)

			-- Configure counter text sizes and color
			UiAlign("left middle")
			UiTranslate(-30 * xAlignment * scale, -backgroundSize * (yAlignment / 2) + 10 * options.counter.size)
			UiFont("bold.ttf", options.counter.textSize * scale)
			UiColor(color[1], color[2], color[3], options.counter.textColor[2])

			for countIteration = 1, #counts do
				local count = counts[countIteration]

				if count[1] then
					UiPush()
						UiFont("bold.ttf", options.counter.textSize * scale - 4 * math.floor(count[2] / 10000))
						UiText(count[2])

						UiAlign("right")
						UiTranslate(60 * scale, 0)
						UiFont("bold.ttf", 8 * scale)
						UiText(count[3])
					UiPop()
					UiTranslate(0, 15 * scale)
				end
			end
		UiPop()
	end

-- Global functions
	function Clone(object)
		return util.unserialize(util.serialize(object))
	end

	function GetBodies(min, max, require)
		QueryRequire(require and require or "")
		return QueryAabbBodies(min and min or VEC_MIN, max and max or VEC_MAX)
	end
	function GetBodyCount(min, max, require)
		QueryRequire(require and require or "")
		return #QueryAabbBodies(min and min or VEC_MIN, max and max or VEC_MAX)
	end

	function GetShapes(min, max, require)
		return QueryAabbShapes(min and min or VEC_MIN, max and max or VEC_MAX)
	end
	function GetShapeCount(min, max, require)
		return #QueryAabbShapes(min and min or VEC_MIN, max and max or VEC_MAX)
	end

-- Mathematical functions
	function Round(value, decimals, overflow)
		decimals = decimals or 0
		overflow = overflow or .5
		return math.floor((value + overflow) * 10 ^ decimals) / 10 ^ decimals
	end

	function CalculateFrameAccuracy(framesPerSecond, options)
		local accuracy = math.pow(10, framesPerSecond >= 100 and math.max(options.counter.accuracy - 1, 0) or options.counter.accuracy)
		return math.floor(framesPerSecond * accuracy) / accuracy
	end