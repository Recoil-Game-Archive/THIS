--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Chat of the RmlUi HUD, in place of the engine console.
--
--  Three toggles split what is shown:
--    CHAT     what people say, plus pauses, speed changes and map markers
--    CONSOLE  everything else the game and engine print
--    ALL      both
--  Recent lines of the selected toggle appear above the row of toggles and
--  drop off after a while. HISTORY opens the scrollback for the selected
--  toggle; the recent history also shows while you are typing.
--
--  Lines are colour coded: player names in their team colour, and the message
--  by channel (everyone, allies, spectators, whispers, events, console).
--
--  The message parsing follows SplinterFaction's ChatterboxChat widget.
--  Typing is still the engine's: Enter opens its input line as before. The
--  engine console is switched off while this widget runs and back on when it
--  stops.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "THIS Chat",
		desc = "Colour-coded chat with Chat / Console / All toggles (replaces the engine console)",
		author = "THIS contributors",
		date = "2026-10-11",
		license = "GNU GPL, v2 or later",
		layer = -10,
		enabled = true
	}
end

local DOCUMENT_PATH = "LuaUI/rml/chat.rml"
local UPDATE_INTERVAL = 0.25
local LINE_SECONDS = 15        -- how long a line stays up outside the history
local VISIBLE_LINES = 8        -- lines shown normally
local TYPING_LINES = 14        -- lines shown while typing
local HISTORY_LINES = 150      -- lines kept in the opened history
local MAX_STORED = 600
local MAX_LENGTH = 500         -- characters kept of one message
local SPEED_MERGE_SECONDS = 0.6 -- a burst of speed changes becomes one line
local PLAYER_REFRESH_SECONDS = 3

local TAB_CHAT, TAB_CONSOLE, TAB_ALL = 1, 2, 3

-- message colours by channel
local CHANNEL_COLOUR = {
	public    = "#e6edf7",
	ally      = "#6fdc8c",
	spectator = "#f2d24b",
	whisper   = "#ff8a80",
	marker    = "#6fdc8c",
	event     = "#8cc8ff",
}
local SPECTATOR_NAME_COLOUR = "#c9d4e5"

local hud
local document
local view
local lastUpdate
local dirty = true

local entries = {}     -- {channel=, player=, body=, time=} oldest first
local clock = 0        -- seconds since the widget started, for line ages
local tab = TAB_CHAT
local expanded = false
local shownRml
local scrollPending = 0
local players = {}     -- lowercase name -> {name=, colour=}
local playersAge = math.huge

--------------------------------------------------------------------------------
-- players

local function RefreshPlayers()
	players = {}
	local list = Spring.GetPlayerList() or {}
	for i = 1, #list do
		local name, _, spectator, teamID = Spring.GetPlayerInfo(list[i], false)
		if name then
			local colour = SPECTATOR_NAME_COLOUR
			if not spectator and teamID then
				colour = hud.GetAccentRCSS(teamID)
			end
			players[name:lower()] = {name = name, colour = colour}
		end
	end
	playersAge = 0
end

local function NameColour(name)
	local player = players[(name or ""):lower()]
	return player and player.colour or "#e6edf7"
end

--------------------------------------------------------------------------------
-- parsing

local function Trim(text)
	return (text and text:match("^%s*(.-)%s*$")) or ""
end

-- engine colour codes: \255 r g b switches colour, \008 resets it
local function StripColours(text)
	text = text:gsub("\255...", "")
	text = text:gsub("\008", "")
	return text
end

local function Parse(text)
	local player, body

	player, body = text:match("^<([^>]+)>%s*Spectators:%s*(.*)$")
	if player then
		return {channel = "spectator", player = player, body = body}
	end

	player, body = text:match("^<([^>]+)>%s*Allies:%s*(.*)$")
	if player then
		return {channel = "ally", player = player, body = body}
	end

	player, body = text:match("^<([^>]+)>%s*Whispers:%s*(.*)$")
	if not player then
		player, body = text:match("^Whisper from ([^:]+):%s*(.*)$")
	end
	if not player then
		player, body = text:match("^To ([^:]+):%s*(.*)$")
	end
	if player then
		return {channel = "whisper", player = Trim(player), body = body}
	end

	player, body = text:match("^<([^>]+)>%s*(.*)$")
	if player then
		return {channel = "public", player = player, body = body}
	end

	-- "name added point: label"
	player, body = text:match("^(.+) added point:%s*(.*)$")
	if player then
		return {channel = "marker", player = player, body = (body ~= "") and ("added point: " .. body) or "added a point"}
	end

	-- "Speed set to N [player]", the player part is optional
	local speed, who = text:match("^Speed set to%s+([%d%.]+)%s+%[([^%]]+)%]%s*$")
	if not speed then
		speed = text:match("^Speed set to%s+([%d%.]+)%s*$")
	end
	if speed then
		if who and who ~= "" then
			return {channel = "event", kind = "speed", player = Trim(who), body = "set the speed to " .. speed .. "x", plain = true}
		end
		return {channel = "event", kind = "speed", body = "Speed set to " .. speed .. "x"}
	end

	-- "player unpaused the game" must be tested before "paused"
	player = text:match("^(.-)%s+unpaused the game%s*$")
	if player and player ~= "" then
		return {channel = "event", player = Trim(player), body = "unpaused the game", plain = true}
	end
	player = text:match("^(.-)%s+paused the game%s*$")
	if player and player ~= "" then
		return {channel = "event", player = Trim(player), body = "paused the game", plain = true}
	end

	-- spectators are printed as "[Name] text"; the engine also prints
	-- bracketed tags such as "[Game::Load]", so the name has to be a player
	player, body = text:match("^%[([^%]]+)%]%s*(.*)$")
	if player and players[Trim(player):lower()] then
		return {channel = "spectator", player = Trim(player), body = body}
	end

	return {channel = "system", body = text}
end

--------------------------------------------------------------------------------
-- display

local function InTab(entry)
	if tab == TAB_ALL then
		return true
	end
	local chat = entry.channel ~= "system"
	if tab == TAB_CHAT then
		return chat
	end
	return not chat
end

local function EntryRML(entry)
	if entry.channel == "system" then
		return '<div class="line system">' .. hud.Escape(entry.body) .. '</div>'
	end
	local colour = CHANNEL_COLOUR[entry.channel] or CHANNEL_COLOUR.public
	local body = '<span style="color: ' .. colour .. ';">' .. hud.Escape(entry.body) .. '</span>'
	if not entry.player then
		return '<div class="line">' .. body .. '</div>'
	end
	-- "Name: text" for speech, "Name did something" for events
	-- (a plain space between two elements would be dropped by the layout)
	local separator = entry.plain and "&nbsp;" or ": "
	return '<div class="line"><span class="who" style="color: ' .. NameColour(entry.player) .. ';">' ..
		hud.Escape(entry.player) .. '</span>' .. separator .. body .. '</div>'
end

local function Refresh()
	local typing = Spring.IsUserWriting and Spring.IsUserWriting() or false
	local limit = expanded and HISTORY_LINES or (typing and TYPING_LINES or VISIBLE_LINES)
	local keepOld = expanded or typing

	local shown = {}
	for i = #entries, 1, -1 do
		if #shown >= limit then
			break
		end
		local entry = entries[i]
		if not keepOld and (clock - entry.time) >= LINE_SECONDS then
			break -- everything older has expired as well
		end
		if InTab(entry) then
			table.insert(shown, 1, EntryRML(entry))
		end
	end

	local rml = table.concat(shown)
	if expanded and rml == "" then
		rml = '<div class="line system">Nothing here yet.</div>'
	end
	view.SetClass("log", "hidden", rml == "")
	view.SetClass("chat", "expanded", expanded)
	view.SetText("expand", expanded and "CLOSE" or "HISTORY")
	for i = TAB_CHAT, TAB_ALL do
		view.SetClass("tab-" .. i, "active", tab == i)
	end
	if rml ~= shownRml then
		shownRml = rml
		view.SetText("lines", rml)
		scrollPending = 2
	end
	-- keep the newest line in view; the new height is only known after the
	-- document has been laid out again, so repeat it on the next refresh
	if expanded and scrollPending > 0 then
		scrollPending = scrollPending - 1
		local log = view.Element("log")
		if log then
			pcall(function() log.scroll_top = log.scroll_height end)
		end
	end
end

--------------------------------------------------------------------------------
-- input

local function LeftButton(event)
	return event.parameters and event.parameters.button == 0
end

local function OnTabMouseDown(event)
	if not LeftButton(event) then
		return
	end
	local index = hud.EventAttribute(event, "data-tab")
	if index and index >= TAB_CHAT and index <= TAB_ALL then
		tab = index
		shownRml = nil
		Refresh()
	end
end

local function OnExpandMouseDown(event)
	if LeftButton(event) then
		expanded = not expanded
		shownRml = nil
		Refresh()
	end
end

--------------------------------------------------------------------------------
-- call-ins

function widget:AddConsoleLine(message, priority)
	if type(message) ~= "string" or message == "" or not hud then
		return
	end
	local text = Trim(StripColours(message))
	if text == "" then
		return
	end
	if #text > MAX_LENGTH then
		text = text:sub(1, MAX_LENGTH) .. "..."
	end
	local entry = Parse(text)
	entry.time = clock

	-- dragging the speed slider prints many lines: keep only the last
	local previous = entries[#entries]
	if entry.kind == "speed" and previous and previous.kind == "speed" and (clock - previous.time) < SPEED_MERGE_SECONDS then
		entries[#entries] = entry
	else
		entries[#entries + 1] = entry
		if #entries > MAX_STORED then
			table.remove(entries, 1)
		end
	end
	dirty = true
end

function widget:KeyPress(key)
	if expanded and key == 27 then -- Esc closes the history
		expanded = false
		shownRml = nil
		dirty = true
		return true
	end
	return false
end

function widget:Initialize()
	if not RmlUi then
		Spring.Echo("[THIS Chat] RmlUi is not available, keeping the engine console")
		widgetHandler:RemoveWidget()
		return
	end

	local helpers = include("rml/hud.lua")

	local context = helpers.UpdateScale()
	if not context then
		Spring.Echo("[THIS Chat] no RmlUi context, keeping the engine console")
		widgetHandler:RemoveWidget()
		return
	end

	helpers.LoadFonts()
	local ok, result = pcall(context.LoadDocument, context, DOCUMENT_PATH, widget)
	if not ok or not result then
		Spring.Echo("[THIS Chat] could not load " .. DOCUMENT_PATH .. ", keeping the engine console", ok and "" or result)
		widgetHandler:RemoveWidget()
		return
	end
	hud = helpers
	document = result
	hud.PrepareDocument(document)

	view = hud.NewView(document)
	view.Assume("log", "hidden", true)
	view.Assume("tab-1", "active", true)
	view.Assume("tab-2", "active", false)
	view.Assume("tab-3", "active", false)
	view.Assume("chat", "expanded", false)

	view.Element("tabs"):AddEventListener("mousedown", OnTabMouseDown)
	view.Element("expand"):AddEventListener("mousedown", OnExpandMouseDown)

	RefreshPlayers()
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
		playersAge = playersAge + elapsed
		lastUpdate = now
		dirty = false
		if playersAge >= PLAYER_REFRESH_SECONDS then
			RefreshPlayers()
		end
		Refresh()
	end
end
