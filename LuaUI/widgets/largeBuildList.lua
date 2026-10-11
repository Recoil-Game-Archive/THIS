function widget:GetInfo()
	return {
		name = "Large ship build list",
		desc = "Displays the build list for large ships",
		author = "KDR_11k (David Becker)",
		date = "2008-03-04",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

local _, orderLarge = include("Configs/build_order.lua") 

local large={}
local builder={}

local buttonToUnit = {}

local jumpDist=600

local vsx, vsy =600

local top = 200
local height = 0
local right = 0
local width = 0

local CMD_BUILD = 31000

local buttonHeight=60
local buttonWidth=80

local myTeam = Spring.GetMyTeamID()

local vsize

local column = false

local function tobool(val)
  local t = type(val)
  if (t == 'nil') then
    return false
  elseif (t == 'boolean') then
    return val
  elseif (t == 'number') then
    return (val ~= 0)
  elseif (t == 'string') then
    return ((val ~= '0') and (val ~= 'false'))
  end
  return false
end



function widget:Initialize()
	local n = 0
	local sorted = {}
	for id,d in pairs(UnitDefs) do
		local c = d.customParams
		if c.type=="large" and (not c.nobuild) then
			large[id] = {
				cost = tonumber(c.cost),
				buildtime = tonumber(c.buildtime),
				perk = tonumber(c.needperk)
			}
			n = n + 1
			sorted[n] = id
		end
		if c.builds then
			builder[id] = tonumber(c.builds)
		end
	end
	-- table.sort only sorts indices 1..#t, so sort a 1-based list first and
	-- then copy it into the 0-based button table the rest of the widget uses.
	-- Units missing from build_order.lua go last instead of raising an error.
	local function order(id)
		return orderLarge[UnitDefs[id].name] or math.huge
	end
	table.sort(sorted, function(a,b)
		local oa, ob = order(a), order(b)
		if oa ~= ob then return oa < ob end
		return a < b
	end)
	for i = 1, n do
		buttonToUnit[i - 1] = sorted[i]
	end
	vsx, vsy = widgetHandler:GetViewSizes()
	vsize =n
	height = vsize * buttonHeight
	width = buttonWidth
end

function widget:ViewResize(x, y)
	vsx, vsy = widgetHandler:GetViewSizes()
	height = vsize * buttonHeight
	width = buttonWidth
end

function widget:DrawScreen()
	local isGrey = false
	gl.Rect(vsx - right, vsy - top, vsx - right- width, vsy - top - height)
	--Spring.Echo(top.." "..right.." "..height.." "..width)
	for n,id in pairs(buttonToUnit) do
		local perk = large[id].perk
		if perk and not (Spring.GetTeamRulesParam(Spring.GetLocalTeamID(), "hasperk_"..perk) == 1) then
			gl.Color(0.2,0.2,0.2,1)
			isGrey = true
		elseif isGrey then
			isGrey = false
			gl.Color(1,1,1,1)
		end
		gl.Texture("#"..id)
		gl.TexRect(vsx - right - buttonWidth, vsy - top - n * buttonHeight, vsx - right, vsy - top - n * buttonHeight - buttonHeight, false, true)
		gl.Texture(false)
	end
	gl.Color(1,1,1,1)
end

function widget:IsAbove(x,y)
	if y < vsy - top and y > vsy - top - height and x > vsx - right - width and x < vsx - right then
		return true
	end
end

function widget:GetTooltip(x,y)
	local pos = math.floor((-y - top + vsy) / buttonHeight)
	local d = large[buttonToUnit[pos]]
	local udef = UnitDefs[buttonToUnit[pos]]
	return "Build "..udef.humanName.."\n"..
		udef.tooltip.."\n"..
		"Cost: "..d.cost.."\n"..
		"Build time: "..d.buildtime.." seconds"
end

function widget:MousePress(x,y,button)
	if y < vsy - top and y > vsy - top - height and x > vsx - right - width and x < vsx - right then
		local team = Spring.GetLocalTeamID()
		local pos = math.floor((-y - top + vsy) / buttonHeight)
		local d = buttonToUnit[pos]
		local opts = {}
		if button == 3 then
			opts[#opts+1] = "right"
		end
		if Spring.GetModKeyState() then
			opts[#opts+1] = "alt"
		end
		for _,u in ipairs(Spring.GetTeamUnits(team)) do
			Spring.GiveOrderToUnit(u, CMD_BUILD + d, {}, opts)
			break
		end
		return true
	end
end

