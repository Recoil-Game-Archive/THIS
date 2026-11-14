--------------------------------------------------------------------------------
--  Shared helpers for the RmlUi HUD widgets. Load with include("rml/hud.lua").
--------------------------------------------------------------------------------

local hud = {}

local CONTEXT_NAME = "shared"

-- The HUD is laid out in "dp" for a 1920x1080 screen and scaled from there.
local BASE_WIDTH = 1920
local BASE_HEIGHT = 1080

-- Exo 2 is the HUD typeface (SIL Open Font License, LuaUI/Fonts/Exo2-OFL.txt).
local FONT_FILES = {
	"LuaUI/Fonts/Exo2-Regular.ttf",
	"LuaUI/Fonts/Exo2-Bold.ttf",
}
-- Used when Exo 2 cannot be loaded; the engine loads this face itself.
local FALLBACK_FAMILY = "FreeSans"

-- Loads the HUD fonts once per LuaUI session (WG is shared by all widgets).
-- Returns true when Exo 2 is available.
function hud.LoadFonts()
	if WG.thisHudFonts ~= nil then
		return WG.thisHudFonts
	end
	local allLoaded = true
	for _, path in ipairs(FONT_FILES) do
		local ok, loaded = pcall(RmlUi.LoadFontFace, path, false)
		if not ok or loaded == false then
			allLoaded = false
			Spring.Echo("[THIS HUD] could not load font " .. path .. (ok and "" or (": " .. tostring(loaded))))
		end
	end
	WG.thisHudFonts = allLoaded
	return allLoaded
end

--------------------------------------------------------------------------------
-- Interface sounds. To change a sound, change the file name here; the file
-- can be any format the engine plays (wav, ogg). Volume is 0..1, on top of
-- the Interface volume slider in Settings.
hud.SOUNDS = {
	hover = "sounds/ui/Mechanical_button_light_switch_02.wav",       -- the mouse moves onto something clickable
	click = "sounds/ui/Interface_thin_open_tone_10.wav",       -- left click on it
	altclick = "sounds/ui/Interface_thin_close_tone_10.wav", -- right click on it (cancel, remove from queue)
	volume = 0.6,
}

-- What counts as clickable: an element with one of these classes or
-- attributes, or inside one. Everything else is silent. An element with the
-- attribute data-sfx="none" is silent too, and so is a disabled or locked one.
local SOUND_CLASSES = {"button", "card", "bcard", "cmd", "qpic", "tab", "perk", "toggle", "step", "track", "select", "choice", "pill"}
local SOUND_ATTRIBUTES = {"data-def", "data-cmd", "data-act", "data-tab", "data-perk", "data-choice", "data-sfx"}
local SOUND_IDS = {["menu-button"] = true, specs = true, expand = true}
local SILENT_CLASSES = {"disabled", "locked", "full", "owned"}

local lastHovered = false

local function SoundTarget(element)
	for _ = 1, 8 do
		if not element then
			return nil
		end
		local clickable = SOUND_IDS[element:GetAttribute("id") or ""]
		if not clickable then
			for _, class in ipairs(SOUND_CLASSES) do
				if element:IsClassSet(class) then
					clickable = true
					break
				end
			end
		end
		if not clickable then
			for _, attribute in ipairs(SOUND_ATTRIBUTES) do
				if element:HasAttribute(attribute) then
					clickable = true
					break
				end
			end
		end
		if clickable then
			if element:HasAttribute("data-sfx") and element:GetAttribute("data-sfx") == "none" then
				return nil
			end
			for _, class in ipairs(SILENT_CLASSES) do
				if element:IsClassSet(class) then
					return nil
				end
			end
			return element
		end
		element = element.parent_node
	end
	return nil
end

function hud.PlaySound(name)
	if WG.thisUiSoundsOff then
		return
	end
	local file = hud.SOUNDS[name]
	if file and file ~= "" then
		Spring.PlaySoundFile(file, hud.SOUNDS.volume or 1, "ui")
	end
end

-- Gives a document the interface sounds: hover, click and right click on
-- anything clickable in it.
function hud.AttachSounds(document)
	local ok = pcall(function()
		-- Capture phase: the sound is decided before the panel's own handler
		-- runs, which may disable the button that was just pressed.
		document:AddEventListener("mouseover", function(event)
			local target = SoundTarget(event.target_element)
			if target ~= lastHovered then
				lastHovered = target
				if target then
					hud.PlaySound("hover")
				end
			end
		end, true)
		document:AddEventListener("mousedown", function(event)
			if not SoundTarget(event.target_element) then
				return
			end
			local button = event.parameters and event.parameters.button
			if button == 0 then
				hud.PlaySound("click")
			elseif button == 1 then
				hud.PlaySound("altclick")
			end
		end, true)
	end)
	if not ok then
		Spring.Echo("[THIS HUD] could not attach the interface sounds to a document")
	end
end

-- Call after loading a HUD document: makes sure its font exists, and switches
-- the document to the engine's own font if Exo 2 could not be loaded, so the
-- text is never simply missing. Also gives the document the interface sounds.
function hud.PrepareDocument(document)
	if not hud.LoadFonts() then
		pcall(function()
			document.style["font-family"] = FALLBACK_FAMILY
		end)
	end
	hud.AttachSounds(document)
end

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

-- RML for a unit's picture. The picture is loaded as a plain image file from
-- unitpics/, the same file the engine uses as the build picture. A unit with
-- no picture gets an empty box of the same size.
local PICTURE_EXTENSIONS = {"png", "dds", "tga", "jpg", "bmp", "pcx"}
local picturePaths = {}

function hud.GetUnitPicturePath(unitDefID)
	local path = picturePaths[unitDefID]
	if path == nil then
		path = false
		local def = UnitDefs[unitDefID]
		if def then
			local candidates = {}
			local named = def.buildPic or def.buildpicname
			if type(named) == "string" and named ~= "" then
				candidates[#candidates + 1] = "unitpics/" .. named
			end
			for _, extension in ipairs(PICTURE_EXTENSIONS) do
				candidates[#candidates + 1] = "unitpics/" .. def.name .. "." .. extension
			end
			for _, candidate in ipairs(candidates) do
				if VFS.FileExists(candidate) then
					path = candidate
					break
				end
			end
		end
		picturePaths[unitDefID] = path
	end
	return path or nil
end

-- class: the RCSS class that sizes the picture; attributes: extra RML
-- attributes for the element, e.g. 'data-def="12"'
function hud.UnitPictureRML(unitDefID, class, attributes)
	local path = hud.GetUnitPicturePath(unitDefID)
	attributes = attributes and (" " .. attributes) or ""
	if path then
		-- the leading slash makes the path absolute instead of relative to the document
		return string.format('<img class="%s" src="/%s"%s/>', class, path, attributes)
	end
	return string.format('<div class="%s"%s/>', class, attributes)
end

-- A view wraps a document and only touches it when a value actually changes,
-- so a widget can simply restate everything on every refresh.
function hud.NewView(document)
	local view = {document = document}
	local elements = {}
	local shownText, shownClass, shownStyle = {}, {}, {}

	function view.Element(id)
		local element = elements[id]
		if element == nil then
			element = document:GetElementById(id) or false
			elements[id] = element
		end
		return element
	end

	function view.SetText(id, text)
		if shownText[id] ~= text then
			local element = view.Element(id)
			if element then
				element.inner_rml = text
			end
			shownText[id] = text
		end
	end

	function view.SetClass(id, class, state)
		local key = id .. "." .. class
		if shownClass[key] ~= state then
			local element = view.Element(id)
			if element then
				element:SetClass(class, state)
			end
			shownClass[key] = state
		end
	end

	function view.SetStyle(id, property, value)
		local key = id .. "." .. property
		if shownStyle[key] ~= value then
			local element = view.Element(id)
			if element then
				element.style[property] = value
			end
			shownStyle[key] = value
		end
	end

	-- Tell the view what the markup already says, so the first refresh does
	-- not rewrite it (e.g. an element that starts with class "hidden").
	function view.Assume(id, class, state)
		shownClass[id .. "." .. class] = state
	end

	-- Forget everything that was cached. Call right after replacing a
	-- container's content with inner_rml: the new elements may reuse the ids
	-- of the old ones but start from what the new markup says.
	function view.Forget()
		elements = {}
		shownText, shownClass, shownStyle = {}, {}, {}
	end

	-- Styles set from outside the view (hud.ApplyAccent) are not tracked.
	function view.ForgetStyles()
		shownStyle = {}
	end

	return view
end

-- For event handlers on a container: the numeric value of the given attribute
-- on the element the event happened on, or on one of its ancestors.
function hud.EventAttribute(event, attribute)
	local element = event.target_element
	for _ = 1, 8 do
		if not element then
			return nil
		end
		if element:HasAttribute(attribute) then
			return tonumber(element:GetAttribute(attribute))
		end
		element = element.parent_node
	end
	return nil
end

-- Hide-GUI (F5) support: call at the start of a widget's Update. Hides the
-- document while the engine's GUI is hidden and shows it again afterwards.
-- Returns true while hidden, so the widget can skip its refresh.
local guiHidden = false

function hud.FollowGuiHidden(document)
	local hidden = Spring.IsGUIHidden() and true or false
	if hidden ~= guiHidden then
		guiHidden = hidden
		if hidden then
			document:Hide()
		else
			hud.ShowPassive(document)
		end
	end
	return hidden
end

-- Text coming from the game (messages, names) must be escaped before it is
-- assigned to inner_rml.
function hud.Escape(text)
	text = tostring(text or "")
	text = text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
	return text
end

return hud
