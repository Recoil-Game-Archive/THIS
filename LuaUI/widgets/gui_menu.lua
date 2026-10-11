--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Game menu of the RmlUi HUD.
--
--  Esc (or the MENU handle beside the top bar) opens a small menu: resume,
--  pause or unpause, the widget list, and quit with a confirmation. Esc or a
--  click outside the menu closes it. The menu does not pause the game by
--  itself.
--
--  Other HUD widgets get Esc first (to cancel deploy mode or close the chat
--  history), and Esc is left alone while a chat message is being typed.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "THIS Game Menu",
		desc = "Esc menu: resume, pause, widget list, quit",
		author = "THIS contributors",
		date = "2026-10-11",
		license = "GNU GPL, v2 or later",
		layer = 100, -- after the other HUD widgets, so they see Esc first
		enabled = true
	}
end

local DOCUMENT_PATH = "LuaUI/rml/menu.rml"
local UPDATE_INTERVAL = 0.25
local KEY_ESCAPE = 27

local hud
local document
local view
local lastUpdate
local open = false
local confirming = false
local accentTeam, accentColour

local function Refresh()
	local team = Spring.GetLocalTeamID()
	local colour = hud.GetAccentRCSS(team)
	if team ~= accentTeam or colour ~= accentColour then
		accentTeam, accentColour = team, colour
		hud.ApplyAccent(document, team, {}, {"menu-accent", "m-resume"})
	end

	view.SetClass("menu", "hidden", not open)
	view.SetClass("backdrop", "hidden", not open)
	view.SetClass("main-items", "hidden", confirming)
	view.SetClass("confirm-items", "hidden", not confirming)
	local _, _, paused = Spring.GetGameSpeed()
	view.SetText("m-pause", paused and "Unpause game" or "Pause game")
end

local function SetOpen(state)
	open = state
	confirming = false
	if open then
		pcall(function() document:PullToFront() end) -- above the other HUD panels
	end
	Refresh()
end

local function OnClick(id, handler)
	local element = view.Element(id)
	if element then
		element:AddEventListener("mousedown", function(event)
			if event.parameters and event.parameters.button == 0 then
				handler()
			end
		end)
	end
end

--------------------------------------------------------------------------------

function widget:Initialize()
	if not RmlUi then
		widgetHandler:RemoveWidget()
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
		Spring.Echo("[THIS Game Menu] could not load " .. DOCUMENT_PATH .. ", Esc keeps the engine's quit prompt", ok and "" or result)
		widgetHandler:RemoveWidget()
		return
	end
	hud = helpers
	document = result
	hud.PrepareDocument(document)

	view = hud.NewView(document)
	view.Assume("menu", "hidden", true)
	view.Assume("backdrop", "hidden", true)
	view.Assume("confirm-items", "hidden", true)
	view.Assume("main-items", "hidden", false)

	OnClick("menu-button", function() SetOpen(not open) end)
	OnClick("backdrop", function() SetOpen(false) end)
	OnClick("m-resume", function() SetOpen(false) end)
	OnClick("m-pause", function()
		Spring.SendCommands("pause")
		SetOpen(false)
	end)
	OnClick("m-widgets", function()
		SetOpen(false)
		Spring.SendCommands("luaui selector")
	end)
	OnClick("m-quit", function()
		confirming = true
		Refresh()
	end)
	OnClick("m-quit-no", function()
		confirming = false
		Refresh()
	end)
	OnClick("m-quit-yes", function()
		Spring.SendCommands("quitforce")
	end)

	Refresh()
	hud.ShowPassive(document)
	lastUpdate = Spring.GetTimer()
end

function widget:Shutdown()
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

function widget:KeyPress(key, mods, isRepeat)
	if not document or key ~= KEY_ESCAPE or isRepeat then
		return false
	end
	if Spring.IsUserWriting and Spring.IsUserWriting() then
		return false -- Esc cancels the chat message being typed
	end
	if confirming then
		confirming = false
		Refresh()
	else
		SetOpen(not open)
	end
	return true
end

function widget:Update()
	if not document or not open then
		return
	end
	local now = Spring.GetTimer()
	if Spring.DiffTimers(now, lastUpdate) >= UPDATE_INTERVAL then
		lastUpdate = now
		Refresh()
	end
end
