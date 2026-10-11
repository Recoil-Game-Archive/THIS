--------------------------------------------------------------------------------
--  Shared helpers for the RmlUi HUD widgets. Load with include("rml/hud.lua").
--------------------------------------------------------------------------------

local hud = {}

local CONTEXT_NAME = "shared"

-- The HUD is laid out in "dp" for a 1920x1080 screen and scaled from there.
local BASE_WIDTH = 1920
local BASE_HEIGHT = 1080

-- The context every HUD document lives in (created in LuaUI/rml_setup.lua).
function hud.GetContext()
	local context = RmlUi.GetContext(CONTEXT_NAME)
	if not context then
		context = RmlUi.CreateContext(CONTEXT_NAME)
	end
	return context
end

-- Pixels per dp: the resolution relative to 1080p, times the user's ui_scale.
function hud.GetScale()
	local vsx, vsy = Spring.GetViewGeometry()
	local userScale = Spring.GetConfigFloat("ui_scale", 1)
	if not userScale or userScale <= 0 then
		userScale = 1
	end
	local scale = math.min(vsx / BASE_WIDTH, vsy / BASE_HEIGHT) * userScale
	scale = math.floor(scale * 100 + 0.5) / 100
	if scale < 0.5 then
		scale = 0.5
	end
	return scale
end

-- Call when a HUD widget starts and whenever the view is resized.
function hud.UpdateScale()
	local context = hud.GetContext()
	if context then
		local scale = hud.GetScale()
		if context.dp_ratio ~= scale then
			context.dp_ratio = scale
		end
	end
	return context
end

-- The accent colour is the team colour, made brighter when it would be too
-- dark to read on the dark panels: first by scaling it up (which keeps its
-- hue and saturation), then by mixing in white. Returns r, g, b in 0..255.
local MIN_LUMINANCE = 0.45

local function Luminance(r, g, b)
	return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

function hud.GetAccent(teamID)
	local r, g, b = Spring.GetTeamColor(teamID)
	if not r then
		r, g, b = 0.4, 0.8, 1
	end
	if Luminance(r, g, b) < MIN_LUMINANCE then
		local peak = math.max(r, g, b)
		if peak > 0.001 then
			r, g, b = r / peak, g / peak, b / peak
		else
			r, g, b = 0.5, 0.5, 0.5 -- black team colour: fall back to grey
		end
		local luminance = Luminance(r, g, b)
		if luminance < MIN_LUMINANCE then
			local t = (MIN_LUMINANCE - luminance) / (1 - luminance)
			r = r + (1 - r) * t
			g = g + (1 - g) * t
			b = b + (1 - b) * t
		end
	end
	return math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)
end

function hud.GetAccentRCSS(teamID)
	local r, g, b = hud.GetAccent(teamID)
	return string.format("rgb(%d,%d,%d)", r, g, b)
end

-- Sets the accent colour on elements of a document, looked up by id.
-- textIds get it as text colour, backgroundIds as background colour.
function hud.ApplyAccent(document, teamID, textIds, backgroundIds)
	local colour = hud.GetAccentRCSS(teamID)
	for _, id in ipairs(textIds or {}) do
		local element = document:GetElementById(id)
		if element then
			element.style["color"] = colour
		end
	end
	for _, id in ipairs(backgroundIds or {}) do
		local element = document:GetElementById(id)
		if element then
			element.style["background-color"] = colour
		end
	end
	return colour
end

-- Shows a document without giving it keyboard focus, so a passive HUD panel
-- never swallows key presses.
function hud.ShowPassive(document)
	if RmlUi.RmlModalFlag and RmlUi.RmlFocusFlag then
		document:Show(RmlUi.RmlModalFlag.None, RmlUi.RmlFocusFlag.None)
	else
		document:Show()
	end
end

-- Text coming from the game (messages, names) must be escaped before it is
-- assigned to inner_rml.
function hud.Escape(text)
	text = tostring(text or "")
	text = text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
	return text
end

return hud
