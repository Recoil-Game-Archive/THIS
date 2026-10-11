--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Defenders of the Galaxy status panel (the co-op mode against invaders).
--
--  Only does anything when that mode is running. Shows the difficulty, the
--  time until the enemy flagship warps in, how many enemy starbases and ships
--  are alive and how many have been destroyed, and announces waves, command
--  cruisers and the flagship.
--
--  The numbers are the game rules params set by the unit_spawner gadget
--  (queenTime, <unit>Count, <unit>Kills, lagging, difficulty); the
--  announcements arrive through its ChickenEvent call.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "THIS Defenders Panel",
		desc = "Status of the Defenders of the Galaxy mode",
		author = "THIS contributors",
		date = "2026-10-11",
		license = "GNU GPL, v2 or later",
		layer = -10,
		enabled = true
	}
end

local DOCUMENT_PATH = "LuaUI/rml/defenders.rml"
local UPDATE_INTERVAL = 0.5
local EVENT_SECONDS = 10
local BASE_NAME = "starbase" -- spawn_defs.lua: burrowName

local hud
local document
local view
local lastUpdate
local unitNames = {}   -- unit def names the spawner counts, without the starbase
local eventText
local eventAge = 0
local waveCount = 0

local floor = math.floor

local function FormatTime(seconds)
	seconds = math.max(0, floor(seconds))
	return string.format("%d:%02d", floor(seconds / 60), seconds % 60)
end

local function Count(name, suffix)
	return Spring.GetGameRulesParam(name .. suffix) or 0
end

local function Refresh()
	local flagshipTime = Spring.GetGameRulesParam("queenTime") or 0
	local now = Spring.GetGameSeconds()

	local mode = tostring(Spring.GetGameRulesParam("difficulty") or "")
	mode = mode:gsub("^Defenders of the Galaxy:%s*", "")
	if Spring.GetGameRulesParam("lagging") == 1 then
		mode = mode .. " \194\183 anti-lag active"
	end
	view.SetText("def-mode", hud.Escape(mode))

	if now < flagshipTime then
		view.SetText("def-timer", FormatTime(flagshipTime - now))
		view.SetText("def-timer-label", "until the flagship")
	else
		view.SetText("def-timer", "Flagship")
		view.SetText("def-timer-label", "has warped in")
	end
	local fraction = (flagshipTime > 0) and math.min(1, now / flagshipTime) or 1
	view.SetStyle("def-fill", "width", floor(fraction * 100) .. "%")
	view.SetClass("def-timer", "bad", now >= flagshipTime)

	local ships, kills = 0, 0
	for i = 1, #unitNames do
		ships = ships + Count(unitNames[i], "Count")
		kills = kills + Count(unitNames[i], "Kills")
	end
	view.SetText("def-bases", tostring(Count(BASE_NAME, "Count")))
	view.SetText("def-ships", tostring(ships))
	view.SetText("def-kills", kills .. " ships \194\183 " .. Count(BASE_NAME, "Kills") .. " starbases")

	view.SetClass("def-event", "hidden", eventText == nil)
	if eventText then
		view.SetText("def-event", hud.Escape(eventText))
	end
end

local function ShipLine(name, number)
	local def = name and UnitDefNames[name]
	if not def or not number or number <= 0 then
		return nil
	end
	return number .. " " .. def.humanName
end

-- called by the unit_spawner gadget
local function ChickenEvent(args)
	if type(args) ~= "table" or not document then
		return
	end
	if args.type == "wave" then
		local bases = Count(BASE_NAME, "Count")
		if bases < 1 then
			return
		end
		waveCount = waveCount + 1
		local name1, name2, number1, number2 = args[1], args[2], args[3], args[4]
		local parts = {}
		if name1 and name1 == name2 then
			parts[1] = ShipLine(name1, ((number1 or 0) + (number2 or 0)) * bases)
		else
			parts[#parts + 1] = ShipLine(name1, (number1 or 0) * bases)
			parts[#parts + 1] = ShipLine(name2, (number2 or 0) * bases)
		end
		eventText = "Wave " .. waveCount .. (#parts > 0 and (": " .. table.concat(parts, ", ")) or "")
	elseif args.type == "miniQueen" then
		eventText = "Command cruisers attacking!"
	elseif args.type == "queen" then
		eventText = "The Imperator has warped in!"
	else
		return
	end
	eventAge = 0
	Refresh()
end

--------------------------------------------------------------------------------

function widget:Initialize()
	if Spring.GetGameRulesParam("difficulty") == nil or not RmlUi then
		widgetHandler:RemoveWidget() -- not a Defenders game
		return
	end

	local helpers = include("rml/hud.lua")
	local context = helpers.UpdateScale()
	if not context then
		widgetHandler:RemoveWidget()
		return
	end

	helpers.LoadFonts()
	local ok, result = pcall(context.LoadDocument, context, DOCUMENT_PATH, widget)
	if not ok or not result then
		Spring.Echo("[THIS Defenders Panel] could not load " .. DOCUMENT_PATH, ok and "" or result)
		widgetHandler:RemoveWidget()
		return
	end
	hud = helpers
	document = result
	hud.PrepareDocument(document)

	for _, def in pairs(UnitDefs) do
		if def.name ~= BASE_NAME and Spring.GetGameRulesParam(def.name .. "Count") ~= nil then
			unitNames[#unitNames + 1] = def.name
		end
	end

	view = hud.NewView(document)
	view.Assume("defenders", "hidden", true)
	view.Assume("def-event", "hidden", true)
	view.SetClass("defenders", "hidden", false)

	Refresh()
	hud.ShowPassive(document)
	lastUpdate = Spring.GetTimer()
	widgetHandler:RegisterGlobal("ChickenEvent", ChickenEvent)
end

function widget:Shutdown()
	if document then
		widgetHandler:DeregisterGlobal("ChickenEvent")
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
	if elapsed >= UPDATE_INTERVAL then
		lastUpdate = now
		if eventText then
			eventAge = eventAge + elapsed
			if eventAge >= EVENT_SECONDS then
				eventText = nil
			end
		end
		Refresh()
	end
end
