--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Settings window of the RmlUi HUD. Opened from the game menu.
--
--  HOW OPTIONS ARE DEFINED
--
--  Every file in LuaUI/Configs/options/ is one tab. A file returns:
--
--      return {
--          id = "gfx", name = "Graphics", order = 10,
--          options = { ... },
--      }
--
--  Each entry in `options` is ONE table that fully describes an option: what
--  it is called, what control it uses, and how its value is read and written.
--  Nothing in this widget needs to change when an option is added. (The
--  format is the one SplinterFaction's options panel uses, minus a few
--  fields, so options can be copied between the two games.)
--
--    Control types
--      "bool"       on/off switch
--      "slider"     a number; give min/max/step, or steps={...} for a fixed list
--      "select"     one of a list; give options={"a","b",...} and optionally
--                   values={...} for the underlying value of each choice
--                   (defaults to the 1-based index)
--      "action"     a button; give set=function() end, and button="Label"
--      "separator"  a heading line; no value. Give name="..."
--
--    Where the value lives (use whichever fit; several may be combined)
--      config="Key"         engine config value. configType="int"|"float"|
--                           "string" is worked out when left out
--      cmd="vsync %d"       engine command sent after a change, formatted with
--                           the underlying value. May be a table of strings.
--      widget="Name"        (bool) switches that widget on and off
--      store=true           the value is kept in this widget's own config
--      get=function() end   custom read (returns the option's value)
--      set=function(v) end  custom write (replaces every writer above)
--      default=...          value used when nothing else supplies one
--
--    Other fields
--      desc="..."           one line of explanation under the name
--      restart=true         shows "some changes need a restart" once changed
--      applyOnRelease=true  (slider) only written when the mouse is released
--      applyOnLoad=true     onSet is also run with the saved value at startup
--      onUnload=function()  run when this widget shuts down
--      requires="Name"      hidden unless that widget exists
--      showIf=function()    hidden while it returns false
--      children={...}       options shown under this one; for a bool only
--                           while it is on
--      format="%d%%"        (slider) how the value is displayed
--      onSet=function(v)    run after the value has been written
--
--  Definition files get an `OPT` table:
--      OPT.get(id), OPT.set(id, v), OPT.widgetActive(name), OPT.close(),
--      OPT.hud (the helpers of LuaUI/rml/hud.lua)
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "THIS Settings",
		desc = "Settings window; options are listed in LuaUI/Configs/options",
		author = "THIS contributors",
		date = "2026-10-11",
		license = "GNU GPL, v2 or later",
		layer = 90,      -- sees Esc before the game menu (layer 100)
		handler = true,  -- the real widgetHandler, to switch widgets on and off
		enabled = true
	}
end

local DOCUMENT_PATH = "LuaUI/rml/settings.rml"
local OPTIONS_DIR = "LuaUI/Configs/options/"
local UPDATE_INTERVAL = 0.5
local KEY_ESCAPE = 27

local hud
local document
local view
local lastUpdate

local tabs = {}          -- sorted list of tab definitions
local byId = {}          -- option id -> option table
local store = {}         -- values of store=true options, saved with the widget config
local rows = {}          -- options shown on the current tab, by row number
local currentTab = 1
local open = false
local restartNeeded = false
local expanded            -- row number of the select whose choices are shown
local drag                -- {row = n, value = v} while a slider is being dragged
local accentTeam, accentColour

local OFF_COLOUR = "rgba(255, 255, 255, 40)"

--------------------------------------------------------------------------------
-- reading and writing values

local function HasFraction(n)
	return n and n ~= math.floor(n)
end

local function ConfigType(opt)
	if opt.configType then
		return opt.configType
	end
	if opt.type == "slider" then
		if HasFraction(opt.min) or HasFraction(opt.max) or HasFraction(opt.step) then
			return "float"
		end
		for _, step in ipairs(opt.steps or {}) do
			if HasFraction(step) then
				return "float"
			end
		end
		return "int"
	end
	if opt.type == "select" and opt.values and type(opt.values[1]) == "string" then
		return "string"
	end
	return "int"
end

local function ReadConfig(opt)
	local kind = ConfigType(opt)
	if kind == "float" then
		return Spring.GetConfigFloat(opt.config, tonumber(opt.default) or 0)
	elseif kind == "string" then
		return Spring.GetConfigString(opt.config, opt.default or "")
	end
	local default = opt.default
	if type(default) == "boolean" then
		default = default and 1 or 0
	end
	return Spring.GetConfigInt(opt.config, tonumber(default) or 0)
end

local function WriteConfig(opt, raw)
	local kind = ConfigType(opt)
	if kind == "float" then
		Spring.SetConfigFloat(opt.config, raw)
	elseif kind == "string" then
		Spring.SetConfigString(opt.config, tostring(raw))
	else
		Spring.SetConfigInt(opt.config, math.floor((tonumber(raw) or 0) + 0.5))
	end
end

-- stored value -> the option's own value (bool, number, or choice index)
local function FromRaw(opt, raw)
	if raw == nil then
		return nil
	end
	if opt.type == "bool" then
		if type(raw) == "number" then
			return raw ~= 0
		elseif type(raw) == "string" then
			return raw == "1" or raw == "true"
		end
		return raw and true or false
	elseif opt.type == "select" then
		if opt.values then
			for i = 1, #opt.values do
				if opt.values[i] == raw or tostring(opt.values[i]) == tostring(raw) then
					return i
				end
			end
			return nil
		end
		local n = tonumber(raw)
		if n and opt.options[n] then
			return n
		end
		return nil
	elseif opt.type == "slider" then
		return tonumber(raw)
	end
	return raw
end

local function ToRaw(opt, value)
	if opt.type == "bool" then
		if opt.config or opt.cmd then
			return value and 1 or 0
		end
		return value and true or false
	elseif opt.type == "select" and opt.values then
		return opt.values[value]
	end
	return value
end

-- true: running; "half": switched on but not running; false: off; nil: unknown widget
local function WidgetState(name)
	local known = widgetHandler.knownWidgets and widgetHandler.knownWidgets[name]
	if not known then
		return nil
	end
	if known.active then
		return true
	end
	local order = widgetHandler.orderList and widgetHandler.orderList[name]
	if order and order > 0 then
		return "half"
	end
	return false
end

local function Get(opt)
	if opt.type == "separator" or opt.type == "action" then
		return nil
	end
	local value
	if opt.get then
		value = FromRaw(opt, opt.get())
		if value ~= nil then
			return value
		end
	end
	if opt.widget and opt.type == "bool" then
		local state = WidgetState(opt.widget)
		return state ~= false and state ~= nil, state
	end
	if opt.config then
		value = FromRaw(opt, ReadConfig(opt))
		if value ~= nil then
			return value
		end
	end
	if opt.store then
		value = FromRaw(opt, store[opt.id])
		if value ~= nil then
			return value
		end
	end
	value = FromRaw(opt, opt.default)
	if value ~= nil then
		return value
	end
	if opt.type == "bool" then
		return false
	elseif opt.type == "slider" then
		return opt.min or (opt.steps and opt.steps[1]) or 0
	end
	return 1
end

local function SendCommand(command, raw)
	if type(command) == "table" then
		for _, one in ipairs(command) do
			SendCommand(one, raw)
		end
		return
	end
	local ok, text = pcall(string.format, command, raw)
	Spring.SendCommands(ok and text or command)
end

-- the value a slider may actually take that is nearest to v
local function SnapSlider(opt, v)
	if opt.steps then
		local best, bestDistance = opt.steps[1], math.huge
		for _, step in ipairs(opt.steps) do
			local distance = math.abs(step - v)
			if distance < bestDistance then
				best, bestDistance = step, distance
			end
		end
		return best
	end
	local min, max, step = opt.min or 0, opt.max or 1, opt.step or 1
	v = math.max(min, math.min(max, v))
	v = min + math.floor((v - min) / step + 0.5) * step
	v = math.max(min, math.min(max, v))
	if not HasFraction(step) and not HasFraction(min) then
		v = math.floor(v + 0.5)
	end
	return v
end

local function Set(opt, value)
	if opt.type == "separator" then
		return
	end
	if opt.type == "action" then
		if opt.set then
			opt.set()
		end
		if opt.onSet then
			opt.onSet()
		end
		return
	end
	if opt.type == "slider" then
		value = SnapSlider(opt, value)
	end
	local raw = ToRaw(opt, value)

	if opt.set then
		opt.set(value, raw)
	else
		if opt.widget and opt.type == "bool" then
			if value then
				widgetHandler:EnableWidget(opt.widget)
			else
				widgetHandler:DisableWidget(opt.widget)
			end
		end
		if opt.config then
			WriteConfig(opt, raw)
		end
		if opt.store or not (opt.widget or opt.config) then
			-- nothing else owns this value: keep it here
			opt.store = true
			store[opt.id] = raw
		end
	end
	if opt.cmd then
		SendCommand(opt.cmd, raw)
	end
	if opt.onSet then
		opt.onSet(value, raw)
	end
	if opt.restart then
		restartNeeded = true
	end
end

local function Safely(what, opt, fn, ...)
	local ok, a, b = pcall(fn, ...)
	if not ok then
		Spring.Echo("[THIS Settings] " .. what .. " '" .. tostring(opt.id or opt.name) .. "' failed: " .. tostring(a))
		return nil
	end
	return a, b
end

--------------------------------------------------------------------------------
-- loading the definitions

local OPT = {}

local function Register(list)
	for _, opt in ipairs(list or {}) do
		if opt.id then
			byId[opt.id] = opt
		end
		Register(opt.children)
	end
end

local function LoadTabs()
	tabs, byId = {}, {}
	local environment = setmetatable({OPT = OPT}, {__index = widget})
	local files = VFS.DirList(OPTIONS_DIR, "*.lua", VFS.ZIP) or {}
	table.sort(files)
	for _, path in ipairs(files) do
		local ok, tab = pcall(VFS.Include, path, environment, VFS.ZIP)
		if ok and type(tab) == "table" and type(tab.options) == "table" then
			tabs[#tabs + 1] = tab
			Register(tab.options)
		else
			Spring.Echo("[THIS Settings] could not load " .. path .. ": " .. tostring(tab))
		end
	end
	table.sort(tabs, function(a, b)
		return (a.order or 1000) < (b.order or 1000)
	end)
end

--------------------------------------------------------------------------------
-- drawing

local function Shown(opt)
	if opt.requires and WidgetState(opt.requires) == nil then
		return false
	end
	if opt.showIf and not Safely("showIf of", opt, opt.showIf) then
		return false
	end
	return true
end

local function SliderFraction(opt, value)
	if opt.steps then
		for i, step in ipairs(opt.steps) do
			if step == value then
				return (#opt.steps > 1) and (i - 1) / (#opt.steps - 1) or 0
			end
		end
		return 0
	end
	local min, max = opt.min or 0, opt.max or 1
	if max <= min then
		return 0
	end
	return math.max(0, math.min(1, (value - min) / (max - min)))
end

local function SliderText(opt, value)
	local format = opt.format or (ConfigType(opt) == "float" and "%.2f" or "%d")
	if not format:find("%%[%d%.]*f") then
		value = math.floor(value + 0.5) -- %d needs a whole number
	end
	local ok, text = pcall(string.format, format, value)
	return ok and hud.Escape(text) or tostring(value)
end

local function FillWidth(opt, value)
	return string.format("%.1f%%", SliderFraction(opt, value) * 100)
end

local function ControlRML(n, opt, value, state)
	if opt.type == "bool" then
		local class = "toggle" .. (value and " on" or "") .. (state == "half" and " half" or "")
		return string.format('<div id="tog-%d" class="%s" data-act="toggle" data-opt="%d"><div class="knob"/></div>', n, class, n)
	elseif opt.type == "slider" then
		return string.format(
			'<div class="step" data-act="dec" data-opt="%d">-</div>' ..
			'<div id="trk-%d" class="track" data-act="track" data-opt="%d"><div class="track-line">' ..
			'<div id="fill-%d" class="track-fill" style="width: %s;"/></div></div>' ..
			'<div class="step" data-act="inc" data-opt="%d">+</div>' ..
			'<div id="val-%d" class="slider-value">%s</div>',
			n, n, n, n, FillWidth(opt, value), n, n, SliderText(opt, value))
	elseif opt.type == "select" then
		return string.format('<div id="sel-%d" class="select" data-act="open" data-opt="%d">%s</div>',
			n, n, hud.Escape(opt.options[value] or "?"))
	elseif opt.type == "action" then
		return string.format('<div class="button quiet" data-act="action" data-opt="%d">%s</div>',
			n, hud.Escape(opt.button or "Run"))
	end
	return ""
end

local function AppendRows(rml, list)
	for _, opt in ipairs(list) do
		if opt.type == "separator" then
			rml[#rml + 1] = '<div class="sep label">' .. hud.Escape((opt.name or ""):upper()) .. '</div>'
		elseif Shown(opt) then
			local n = #rows + 1
			rows[n] = opt
			local value, state = Safely("reading", opt, Get, opt)
			if value == nil and opt.type ~= "action" then
				value = (opt.type == "bool") and false or (opt.type == "select" and 1 or (opt.min or 0))
			end
			local desc = opt.desc and ('<div class="row-desc">' .. hud.Escape(opt.desc) .. '</div>') or ""
			rml[#rml + 1] = string.format(
				'<div class="row"><div class="row-text"><div class="row-name">%s</div>%s</div>' ..
				'<div class="row-control">%s</div></div>',
				hud.Escape(opt.name or opt.id or ""), desc, ControlRML(n, opt, value, state))
			if opt.type == "select" then
				local choices = {}
				for i, label in ipairs(opt.options) do
					choices[#choices + 1] = string.format(
						'<div id="ch-%d-%d" class="choice%s" data-act="choice" data-opt="%d" data-choice="%d">%s</div>',
						n, i, (i == value) and " current" or "", n, i, hud.Escape(label))
				end
				rml[#rml + 1] = string.format('<div id="choices-%d" class="choices hidden">%s</div>', n, table.concat(choices))
			end
			if opt.children then
				local hidden = (opt.type == "bool" and not value) and " hidden" or ""
				rml[#rml + 1] = string.format('<div id="kids-%d" class="kids%s">', n, hidden)
				AppendRows(rml, opt.children)
				rml[#rml + 1] = '</div>'
			end
		end
	end
end

local function ApplyRowColours()
	for n, opt in ipairs(rows) do
		if opt.type == "bool" then
			local value, state = Safely("reading", opt, Get, opt)
			view.SetStyle("tog-" .. n, "background-color", (value and state ~= "half") and accentColour or (state == "half" and "#f2b84b" or OFF_COLOUR))
		elseif opt.type == "slider" then
			view.SetStyle("fill-" .. n, "background-color", accentColour)
		end
	end
end

local function BuildTabs()
	local rml = {}
	for i, tab in ipairs(tabs) do
		rml[#rml + 1] = string.format('<div id="tab-%d" class="tab" data-tab="%d">%s</div>', i, i, hud.Escape((tab.name or tab.id or "?"):upper()))
	end
	view.Element("tabs").inner_rml = table.concat(rml)
end

local function BuildList()
	rows = {}
	expanded = nil
	drag = nil
	local rml = {}
	local tab = tabs[currentTab]
	if tab then
		AppendRows(rml, tab.options)
	end
	view.Forget()
	local list = view.Element("list")
	list.inner_rml = table.concat(rml)
	list.scroll_top = 0
	for i = 1, #tabs do
		view.SetClass("tab-" .. i, "active", i == currentTab)
		view.SetStyle("tab-" .. i, "border-bottom-color", (i == currentTab) and accentColour or "rgba(0, 0, 0, 0)")
	end
	ApplyRowColours()
end

-- Bring one row up to date after its value changed.
local function RefreshRow(n)
	local opt = rows[n]
	if not opt then
		return
	end
	local value, state = Safely("reading", opt, Get, opt)
	if value == nil then
		return
	end
	if opt.type == "bool" then
		view.SetClass("tog-" .. n, "on", value)
		view.SetClass("tog-" .. n, "half", state == "half")
		view.SetStyle("tog-" .. n, "background-color", (value and state ~= "half") and accentColour or (state == "half" and "#f2b84b" or OFF_COLOUR))
		if opt.children then
			view.SetClass("kids-" .. n, "hidden", not value)
		end
	elseif opt.type == "slider" then
		view.SetStyle("fill-" .. n, "width", FillWidth(opt, value))
		view.SetText("val-" .. n, SliderText(opt, value))
	elseif opt.type == "select" then
		view.SetText("sel-" .. n, hud.Escape(opt.options[value] or "?"))
		for i = 1, #opt.options do
			view.SetClass("ch-" .. n .. "-" .. i, "current", i == value)
		end
	end
end

local function RefreshRows()
	for n = 1, #rows do
		if not (drag and drag.row == n) then
			RefreshRow(n)
		end
	end
end

local function Refresh()
	local team = Spring.GetLocalTeamID()
	local colour = hud.GetAccentRCSS(team)
	if team ~= accentTeam or colour ~= accentColour then
		accentTeam, accentColour = team, colour
		hud.ApplyAccent(document, team, {}, {"settings-accent", "close"})
		view.ForgetStyles()
		if open then
			BuildList()
		end
	end
	view.SetClass("settings", "hidden", not open)
	view.SetClass("backdrop", "hidden", not open)
	view.SetText("note", restartNeeded and "Some changes take effect after a restart." or "")
	if open then
		RefreshRows()
	end
end

local function SetOpen(state)
	open = state and #tabs > 0
	drag = nil
	if open then
		BuildList()
		pcall(function() document:PullToFront() end)
	end
	Refresh()
end

--------------------------------------------------------------------------------
-- input

-- the element with a data-act attribute that the event happened on or in
local function ActionElement(event)
	local element = event.target_element
	for _ = 1, 6 do
		if not element then
			return nil
		end
		if element:HasAttribute("data-act") then
			return element
		end
		element = element.parent_node
	end
	return nil
end

local function Change(n, value)
	local opt = rows[n]
	Safely("changing", opt, Set, opt, value)
	RefreshRows() -- one option may change another (fullscreen and borderless)
	Refresh()
end

-- the slider value under the mouse
local function DragValue(n)
	local opt = rows[n]
	local track = view.Element("trk-" .. n)
	if not opt or not track then
		return nil
	end
	local mouseX = Spring.GetMouseState()
	local width = track.offset_width
	if not width or width <= 0 then
		return nil
	end
	local fraction = math.max(0, math.min(1, (mouseX - track.absolute_left) / width))
	if opt.steps then
		return opt.steps[math.floor(fraction * (#opt.steps - 1) + 0.5) + 1]
	end
	local min, max = opt.min or 0, opt.max or 1
	return SnapSlider(opt, min + fraction * (max - min))
end

local function ShowDragValue()
	local opt = rows[drag.row]
	view.SetStyle("fill-" .. drag.row, "width", FillWidth(opt, drag.value))
	view.SetText("val-" .. drag.row, SliderText(opt, drag.value))
end

local function StepSlider(n, direction)
	local opt = rows[n]
	local value = Safely("reading", opt, Get, opt)
	if value == nil then
		return
	end
	if opt.steps then
		local index = 1
		for i, step in ipairs(opt.steps) do
			if step == SnapSlider(opt, value) then
				index = i
			end
		end
		value = opt.steps[math.max(1, math.min(#opt.steps, index + direction))]
	else
		value = value + direction * (opt.step or 1)
	end
	Change(n, value)
end

local function OnListMouseDown(event)
	if not (event.parameters and event.parameters.button == 0) then
		return
	end
	local element = ActionElement(event)
	if not element then
		return
	end
	local action = element:GetAttribute("data-act")
	local n = tonumber(element:GetAttribute("data-opt"))
	local opt = n and rows[n]
	if not opt then
		return
	end
	if action == "toggle" then
		Change(n, not Safely("reading", opt, Get, opt))
	elseif action == "dec" then
		StepSlider(n, -1)
	elseif action == "inc" then
		StepSlider(n, 1)
	elseif action == "track" then
		local value = DragValue(n)
		if value ~= nil then
			drag = {row = n, value = value}
			ShowDragValue()
			if not opt.applyOnRelease then
				Safely("changing", opt, Set, opt, value)
			end
		end
	elseif action == "open" then
		if expanded and expanded ~= n then
			view.SetClass("choices-" .. expanded, "hidden", true)
		end
		expanded = (expanded ~= n) and n or nil
		view.SetClass("choices-" .. n, "hidden", expanded ~= n)
	elseif action == "choice" then
		local choice = tonumber(element:GetAttribute("data-choice"))
		view.SetClass("choices-" .. n, "hidden", true)
		expanded = nil
		if choice and opt.options[choice] then
			Change(n, choice)
		end
	elseif action == "action" then
		Change(n)
	end
end

local function OnTabsMouseDown(event)
	if not (event.parameters and event.parameters.button == 0) then
		return
	end
	local index = hud.EventAttribute(event, "data-tab")
	if index and tabs[index] and index ~= currentTab then
		currentTab = index
		BuildList()
	end
end

local function OnClick(id, handler)
	view.Element(id):AddEventListener("mousedown", function(event)
		if event.parameters and event.parameters.button == 0 then
			handler()
		end
	end)
end

--------------------------------------------------------------------------------
-- call-ins

function widget:Initialize()
	if not RmlUi then
		widgetHandler:RemoveWidget(widget)
		return
	end

	hud = include("rml/hud.lua")
	local context = hud.UpdateScale()
	if not context then
		widgetHandler:RemoveWidget(widget)
		return
	end

	OPT.hud = hud
	OPT.get = function(id)
		local opt = byId[id]
		return opt and Get(opt)
	end
	OPT.set = function(id, value)
		local opt = byId[id]
		if opt then
			Set(opt, value)
		end
	end
	OPT.widgetActive = function(name)
		return WidgetState(name) == true
	end
	OPT.close = function()
		SetOpen(false)
	end
	LoadTabs()

	hud.LoadFonts()
	local ok, result = pcall(context.LoadDocument, context, DOCUMENT_PATH, widget)
	if not ok or not result then
		Spring.Echo("[THIS Settings] could not load " .. DOCUMENT_PATH .. "", ok and "" or result)
		widgetHandler:RemoveWidget(widget)
		return
	end
	document = result
	hud.PrepareDocument(document)

	view = hud.NewView(document)
	accentTeam = Spring.GetLocalTeamID()
	accentColour = hud.ApplyAccent(document, accentTeam, {}, {"settings-accent", "close"})
	BuildTabs()
	view.Element("list"):AddEventListener("mousedown", OnListMouseDown)
	view.Element("tabs"):AddEventListener("mousedown", OnTabsMouseDown)
	OnClick("close", function() SetOpen(false) end)
	OnClick("backdrop", function() SetOpen(false) end)

	-- options that have to be put into effect at every start
	for _, opt in pairs(byId) do
		if opt.applyOnLoad and opt.onSet then
			local value = Safely("reading", opt, Get, opt)
			if value ~= nil then
				Safely("applying", opt, opt.onSet, value, ToRaw(opt, value))
			end
		end
	end

	WG.thisSettings = {
		Open = function() SetOpen(true) end,
		Close = function() SetOpen(false) end,
		IsOpen = function() return open end,
	}

	Refresh()
	hud.ShowPassive(document)
	lastUpdate = Spring.GetTimer()
end

function widget:Shutdown()
	WG.thisSettings = nil
	for _, opt in pairs(byId) do
		if opt.onUnload then
			Safely("unloading", opt, opt.onUnload)
		end
	end
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
	if document and open and key == KEY_ESCAPE and not isRepeat then
		SetOpen(false)
		return true
	end
	return false
end

function widget:Update()
	if not document then
		return
	end
	if hud.FollowGuiHidden(document) or not open then
		return
	end

	if drag then
		local opt = rows[drag.row]
		local _, _, leftDown = Spring.GetMouseState()
		local value = DragValue(drag.row)
		if value ~= nil and value ~= drag.value then
			drag.value = value
			ShowDragValue()
			if not opt.applyOnRelease then
				Safely("changing", opt, Set, opt, value)
			end
		end
		if not leftDown then
			local row, final = drag.row, drag.value
			drag = nil
			if opt.applyOnRelease then
				Change(row, final)
			else
				RefreshRows()
				Refresh()
			end
		end
		return
	end

	local now = Spring.GetTimer()
	if Spring.DiffTimers(now, lastUpdate) >= UPDATE_INTERVAL then
		lastUpdate = now
		Refresh()
	end
end

function widget:GetConfigData()
	return {store = store}
end

function widget:SetConfigData(data)
	if type(data) == "table" and type(data.store) == "table" then
		store = data.store
	end
end
