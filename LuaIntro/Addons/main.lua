if addon.InGetInfo then
	return {
		name    = "Main",
		desc    = "The loading panel: a tip, the load message and a progress bar, in the style of the in-game HUD",
		author  = "jK; THIS contributors",
		date    = "2012,2013; 2026",
		license = "GPL2",
		layer   = 0,
		depend  = {"LoadProgress"},
		enabled = true,
	}
end

--------------------------------------------------------------------------------
-- Replaces the engine base content's Main addon.
--
-- RmlUi is not available on the loading screen, so the panel is drawn by hand
-- to the rules of LuaUI/rml/theme.rcss: a .panel (dark blue glass, 1dp border,
-- 4dp corners) with an .accent-line along its top, .label small capitals,
-- .value bold numbers, .sub notes, in Exo 2. When the theme changes, change
-- the THEME table below to match.
--
-- The tips are in LuaIntro/Configs/loadscreen.lua.
--------------------------------------------------------------------------------

local THEME = {
	panel  = {9 / 255, 14 / 255, 24 / 255, 235 / 255},    -- .panel (217 in game; a little denser over a bright picture)
	border = {0x33 / 255, 0x41 / 255, 0x5a / 255, 1},     -- .panel border
	accent = {0x66 / 255, 0xcc / 255, 0xff / 255, 1},     -- .accent-line default (in game: the team colour)
	track  = {0x1a / 255, 0x24 / 255, 0x36 / 255, 1},     -- .pic background, used for the bar's track
	rule   = {0x33 / 255, 0x41 / 255, 0x5a / 255, 1},     -- .divider
}

local function TextColor(r, g, b)
	return "\255" .. string.char(math.max(1, r), math.max(1, g), math.max(1, b))
end
local TEXT = {
	text   = TextColor(0xe6, 0xed, 0xf7),   -- body, .value
	muted  = TextColor(0x8c, 0x9b, 0xb3),   -- .label, .sub
	accent = TextColor(0x66, 0xcc, 0xff),
}

-- Sizes are in dp: pixels on a 1080-pixel-high screen, scaled from there.
local PANEL_WIDTH_FRAC  = 0.50  -- share of the screen's width...
local PANEL_MIN_WIDTH   = 720   -- ...but not narrower than this
local PANEL_BOTTOM_FRAC = 0.07  -- gap under the panel, as a share of the screen's height
local PAD         = 18
local RADIUS      = 4
local ACCENT_LINE = 2
local BAR_HEIGHT  = 4
local TIP_SIZE    = 16
local MAX_TIP_LINES = 3

--------------------------------------------------------------------------------
-- the tip: the next one each launch (math.random repeats itself here, so a
-- counter in a file moves on by one every time the game loads)
--------------------------------------------------------------------------------

local tip
do
	local ok, cards = pcall(VFS.Include, "LuaIntro/Configs/loadscreen.lua")
	local tips = ok and type(cards) == "table" and cards.tips or {}
	if not ok then
		Spring.Echo("[LuaIntro] could not read LuaIntro/Configs/loadscreen.lua: " .. tostring(cards))
	end
	if #tips > 0 then
		local filename = "LuaUI/Config/THIS_loadscreen.data"
		local k = os.time() % 1000
		if VFS.FileExists(filename) then
			k = tonumber(VFS.LoadFile(filename)) or k
		end
		k = k + 1
		local file = io.open(filename, "w")
		if file then
			file:write(k)
			file:close()
		end
		tip = tips[(k % #tips) + 1]
	end
end

--------------------------------------------------------------------------------
-- progress
--------------------------------------------------------------------------------

local lastLoadMessage = ""
local lastProgress = {0, 0}

-- The engine reports stages, not a percentage. Each stage is given a range,
-- and the time the last load of this map took (the LoadProgress addon) moves
-- the bar inside it.
local progressByLastLine = {
	["Parsing Map Information"] = {0, 0.20},
	["Loading Weapon Definitions"] = {0.10, 0.50},
	["Loading LuaRules"] = {0.40, 0.80},
	["Loading LuaUI"] = {0.70, 0.95},
	["Finalizing"] = {1, 1},
}

function addon.LoadProgress(message, replaceLastLine)
	lastLoadMessage = message
	if message:find("Path") then -- pathing has no fixed messages
		lastProgress = {0.8, 1.0}
	end
	lastProgress = progressByLastLine[message] or lastProgress
end

--------------------------------------------------------------------------------
-- drawing, in screen pixels (y up)
--------------------------------------------------------------------------------

local LOADED_FONT_SIZE = 48
local function LoadFont(file)
	return VFS.FileExists(file) and gl.LoadFont(file, LOADED_FONT_SIZE, 2, 1) or nil
end
local font     = LoadFont("LuaUI/Fonts/Exo2-Regular.ttf") or gl.LoadFont("FreeSansBold.otf", LOADED_FONT_SIZE, 2, 1)
local boldFont = LoadFont("LuaUI/Fonts/Exo2-Bold.ttf") or font

local floor = math.floor
local canRound = gl.BeginEnd and GL and GL.TRIANGLE_FAN and GL.TRIANGLE_STRIP

local function SetColor(color, alpha)
	gl.Color(color[1], color[2], color[3], alpha or color[4] or 1)
end

-- the outline of a rounded rectangle, counter-clockwise
local CORNER_STEPS = 6
local function Contour(x1, y1, x2, y2, r)
	local pts = {}
	local corners = {
		{x1 + r, y1 + r, math.pi, 1.5 * math.pi},
		{x2 - r, y1 + r, 1.5 * math.pi, 2 * math.pi},
		{x2 - r, y2 - r, 0, 0.5 * math.pi},
		{x1 + r, y2 - r, 0.5 * math.pi, math.pi},
	}
	for _, c in ipairs(corners) do
		for i = 0, CORNER_STEPS do
			local a = c[3] + (c[4] - c[3]) * i / CORNER_STEPS
			pts[#pts + 1] = {c[1] + math.cos(a) * r, c[2] + math.sin(a) * r}
		end
	end
	return pts
end

local function RoundRect(x1, y1, x2, y2, r, color)
	SetColor(color)
	r = math.min(r, (x2 - x1) * 0.5, (y2 - y1) * 0.5)
	if not canRound or r < 1 then
		gl.Rect(x1, y1, x2, y2)
		return
	end
	local pts = Contour(x1, y1, x2, y2, r)
	gl.BeginEnd(GL.TRIANGLE_FAN, function()
		gl.Vertex((x1 + x2) * 0.5, (y1 + y2) * 0.5)
		for i = 1, #pts do
			gl.Vertex(pts[i][1], pts[i][2])
		end
		gl.Vertex(pts[1][1], pts[1][2])
	end)
end

-- a rounded border of width w, inside the rectangle
local function RoundBorder(x1, y1, x2, y2, r, w, color)
	SetColor(color)
	if not canRound or r < 1 then
		gl.Rect(x1, y1, x2, y1 + w)
		gl.Rect(x1, y2 - w, x2, y2)
		gl.Rect(x1, y1 + w, x1 + w, y2 - w)
		gl.Rect(x2 - w, y1 + w, x2, y2 - w)
		return
	end
	local outer = Contour(x1, y1, x2, y2, r)
	local inner = Contour(x1 + w, y1 + w, x2 - w, y2 - w, math.max(0, r - w))
	gl.BeginEnd(GL.TRIANGLE_STRIP, function()
		for i = 1, #outer do
			gl.Vertex(outer[i][1], outer[i][2])
			gl.Vertex(inner[i][1], inner[i][2])
		end
		gl.Vertex(outer[1][1], outer[1][2])
		gl.Vertex(inner[1][1], inner[1][2])
	end)
end

-- a .label: capitals, spaced out (RmlUi letter-spacing). align "l" or "r"; y is the top of the text
local function PrintLabel(useFont, color, text, x, y, size, spacing, align)
	text = string.upper(text)
	if align == "r" then
		local w = 0
		for i = 1, #text do
			w = w + useFont:GetTextWidth(text:sub(i, i)) * size
		end
		x = x - w - spacing * math.max(0, #text - 1)
	end
	for i = 1, #text do
		local ch = text:sub(i, i)
		useFont:Print(color .. ch, x, y, size, "a")
		x = x + useFont:GetTextWidth(ch) * size + spacing
	end
end

local function Wrap(useFont, text, width, size, maxLines)
	local wrapped = useFont:WrapText(text, width * (LOADED_FONT_SIZE / size))
	local lines = {}
	for line in (wrapped .. "\n"):gmatch("(.-)\r?\n") do
		lines[#lines + 1] = line
		if #lines == maxLines then
			break
		end
	end
	return lines
end

local tipLines -- wrapped once: neither the text nor the screen changes while loading

function addon.DrawLoadScreen()
	local loadProgress = SG.GetLoadProgress()
	if loadProgress <= 0 then
		loadProgress = lastProgress[1]
	else
		loadProgress = math.min(math.max(loadProgress, lastProgress[1]), lastProgress[2])
	end

	local vsx, vsy = gl.GetViewSizes()
	local s = vsy / 1080
	local pad = PAD * s
	local line = math.max(1, floor(s + 0.5))

	local width = floor(math.min(vsx - 2 * pad, math.max(vsx * PANEL_WIDTH_FRAC, PANEL_MIN_WIDTH * s)))
	local x1 = floor((vsx - width) * 0.5)
	local x2 = x1 + width

	local tipSize = TIP_SIZE * s
	local tipLineHeight = tipSize * 1.4
	if tip and not tipLines then
		tipLines = Wrap(font, tip, width - 2 * pad, tipSize, MAX_TIP_LINES)
	end
	-- heights, bottom to top: the bar block, then (with a tip) a rule and the tip block
	local barBlock = floor(66 * s)
	local tipBlock = tipLines and floor(pad + 20 * s + #tipLines * tipLineHeight + 12 * s) or 0
	local y1 = floor(vsy * PANEL_BOTTOM_FRAC)
	local y2 = y1 + barBlock + tipBlock + floor(ACCENT_LINE * s)

	-- the load screen is drawn in 0..1 coordinates; work in pixels instead
	gl.PushMatrix()
	gl.Scale(1 / vsx, 1 / vsy, 1)
	gl.Texture(false)

	RoundRect(x1, y1, x2, y2, RADIUS * s, THEME.panel)
	RoundBorder(x1, y1, x2, y2, RADIUS * s, line, THEME.border)
	-- .accent-line along the top, inside the border
	SetColor(THEME.accent)
	gl.Rect(x1 + line, y2 - line - math.max(2, floor(ACCENT_LINE * s)), x2 - line, y2 - line)

	if tipLines then
		local top = y2 - floor(ACCENT_LINE * s) - pad + 4 * s
		PrintLabel(font, TEXT.muted, "Tip", x1 + pad, top, 11 * s, 1 * s, "l")
		if Game and Game.mapName then
			PrintLabel(font, TEXT.muted, Game.mapName, x2 - pad, top, 11 * s, 1 * s, "r")
		end
		top = top - 20 * s
		for i, text in ipairs(tipLines) do
			font:Print(TEXT.text .. text, x1 + pad, top - (i - 1) * tipLineHeight, tipSize, "a")
		end
		SetColor(THEME.rule)
		gl.Rect(x1 + pad, y1 + barBlock, x2 - pad, y1 + barBlock + line)
	end

	-- "LOADING" over the engine's message, the percentage on the right, the bar underneath
	local top = y1 + barBlock - 12 * s
	PrintLabel(font, TEXT.muted, "Loading", x1 + pad, top, 11 * s, 1 * s, "l")
	if lastLoadMessage ~= "" then
		font:Print(TEXT.muted .. lastLoadMessage, x1 + pad, top - 16 * s, 12 * s, "a")
	end
	boldFont:Print(TEXT.text .. ("%.0f%%"):format(math.max(0, math.min(1, loadProgress)) * 100), x2 - pad, top + 1 * s, 20 * s, "ar")

	local barH = math.max(3, floor(BAR_HEIGHT * s))
	local barY = floor(y1 + 12 * s)
	local barX1, barX2 = floor(x1 + pad), floor(x2 - pad)
	SetColor(THEME.track)
	gl.Rect(barX1, barY, barX2, barY + barH)
	local fill = math.max(0, math.min(1, loadProgress))
	if fill > 0 then
		SetColor(THEME.accent)
		gl.Rect(barX1, barY, barX1 + floor((barX2 - barX1) * fill), barY + barH)
	end

	gl.Color(1, 1, 1, 1)
	gl.PopMatrix()
end

function addon.Shutdown()
	if boldFont and boldFont ~= font then
		gl.DeleteFont(boldFont)
	end
	if font then
		gl.DeleteFont(font)
	end
end
