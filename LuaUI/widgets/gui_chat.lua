--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Chat log of the RmlUi HUD.
--
--  Shows recent chat and game messages at the bottom-left, in place of the
--  engine console, which printed across the top of the screen underneath the
--  top bar. A line disappears after a while; while you are typing a message
--  the recent history is shown.
--
--  Typing itself is still the engine's: Enter opens its input line as before.
--  The engine console is switched off while this widget runs and back on when
--  it stops.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "THIS Chat",
		desc = "Recent chat and game messages (replaces the engine console)",
		author = "THIS contributors",
		date = "2026-10-11",
		license = "GNU GPL, v2 or later",
		layer = -10,
		enabled = true
	}
end

local DOCUMENT_PATH = "LuaUI/rml/chat.rml"
local UPDATE_INTERVAL = 0.25
local LINE_SECONDS = 15    -- how long a line stays up
local VISIBLE_LINES = 8    -- lines shown normally
local HISTORY_LINES = 14   -- lines shown while typing
local MAX_STORED = 100
local MAX_LENGTH = 400     -- characters kept of one message

local hud
local document
local view
local lastUpdate
local dirty = true

local lines = {}  -- {text=, system=, time=} oldest first
local clock = 0   -- seconds since the widget started, for line ages

--------------------------------------------------------------------------------

-- engine colour codes: \255 r g b switches colour, \008 resets it
local function StripColours(text)
	text = text:gsub("\255...", "")
	text = text:gsub("\008", "")
	return text
end

-- "<Name> text" and "[Name] text" are people talking; everything else is the
-- game or the engine. Engine tags look like "[Game::Load]" or "[f=0001234]".
local function Classify(text)
	local who, rest = text:match("^(<[^>]+>)%s*(.*)$")
	if not who then
		who, rest = text:match("^(%[[^%]]+%])%s*(.*)$")
		if who and (who:find("::", 1, true) or who:find("=", 1, true)) then
			who = nil
		end
	end
	if who then
		return false, who, rest
	end
	return true, nil, text
end

local function LineRML(line)
	if line.system then
		return '<div class="line system">' .. hud.Escape(line.text) .. '</div>'
	end
	return '<div class="line"><span class="who">' .. hud.Escape(line.who) .. '</span> ' .. hud.Escape(line.text) .. '</div>'
end

local function Refresh()
	local typing = Spring.IsUserWriting and Spring.IsUserWriting() or false
	local limit = typing and HISTORY_LINES or VISIBLE_LINES
	local shown = {}
	for i = #lines, 1, -1 do
		local line = lines[i]
		if #shown >= limit then
			break
		end
		if typing or (clock - line.time) < LINE_SECONDS then
			table.insert(shown, 1, LineRML(line))
		else
			break -- older lines have expired as well
		end
	end
	view.SetClass("chat", "hidden", #shown == 0)
	view.SetText("lines", table.concat(shown))
end

--------------------------------------------------------------------------------

function widget:AddConsoleLine(message, priority)
	if type(message) ~= "string" or message == "" then
		return
	end
	local text = StripColours(message)
	if #text > MAX_LENGTH then
		text = text:sub(1, MAX_LENGTH) .. "..."
	end
	local system, who, rest = Classify(text)
	lines[#lines + 1] = {text = rest, who = who, system = system, time = clock}
	if #lines > MAX_STORED then
		table.remove(lines, 1)
	end
	dirty = true
end

function widget:Initialize()
	if not RmlUi then
		Spring.Echo("[THIS Chat] RmlUi is not available, keeping the engine console")
		widgetHandler:RemoveWidget()
		return
	end

	hud = include("rml/hud.lua")

	local context = hud.UpdateScale()
	if not context then
		Spring.Echo("[THIS Chat] no RmlUi context, keeping the engine console")
		widgetHandler:RemoveWidget()
		return
	end

	hud.LoadFonts()
	local ok, result = pcall(context.LoadDocument, context, DOCUMENT_PATH, widget)
	if not ok or not result then
		Spring.Echo("[THIS Chat] could not load " .. DOCUMENT_PATH .. ", keeping the engine console", ok and "" or result)
		widgetHandler:RemoveWidget()
		return
	end
	document = result
	hud.PrepareDocument(document)

	view = hud.NewView(document)
	view.Assume("chat", "hidden", true)

	Refresh()
	hud.ShowPassive(document)
	lastUpdate = Spring.GetTimer()

	Spring.SendCommands("console 0")
	WG.thisChat = true
end

function widget:Shutdown()
	if WG.thisChat then
		Spring.SendCommands("console 1")
	end
	WG.thisChat = nil
	if document then
		document:Close()
		document = nil
	end
end

function widget:ViewResize()
	if hud then
		hud.UpdateScale()
	end
end

function widget:Update()
	if not document then
		return
	end
	local now = Spring.GetTimer()
	local elapsed = Spring.DiffTimers(now, lastUpdate)
	if dirty or elapsed >= UPDATE_INTERVAL then
		clock = clock + elapsed
		lastUpdate = now
		dirty = false
		Refresh()
	end
end
