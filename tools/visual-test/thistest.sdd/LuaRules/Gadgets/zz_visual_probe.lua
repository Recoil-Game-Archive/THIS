function gadget:GetInfo()
  return { name = "Visual Probe", layer = 1006, enabled = true }
end

-- Screenshots of units in the graphical engine (tools/visual-test/run.sh). Lines the units up in the middle of the
-- map, points the camera at them, optionally has them fire or puts enemies in front of them, takes screenshots
-- (write dir /screenshots) and quits. Options arrive as modoptions, see run.sh.
local opt = Spring.GetModOptions() or {}
if not opt.visualunits then return end

local SPACING = tonumber(opt.visualspacing) or 150
local SHOTFRAME = tonumber(opt.visualshotframe) or 190
local NSHOTS = tonumber(opt.visualshots) or 6
local STEP = tonumber(opt.visualstep) or 10
local function on(v) return v and v ~= "" and v ~= "0" end

local function lineup()
  local list = {}
  for name in tostring(opt.visualunits):gmatch("[^,]+") do
    local ud = UnitDefNames[name:lower()]
    if ud then list[#list + 1] = ud end
  end
  return list
end

if gadgetHandler:IsSyncedCode() then

local units = {}

function gadget:GameFrame(n)
  if n == 2 then
    Spring.SendCommands("cheat 1", "globallos")
    local list = lineup()
    local x0 = Game.mapSizeX / 2 - (#list - 1) * SPACING / 2
    local z = Game.mapSizeZ / 2
    for i, ud in ipairs(list) do
      local x = x0 + (i - 1) * SPACING
      local id = Spring.CreateUnit(ud.name, x, Spring.GetGroundHeight(x, z), z, "north", 0)
      if id then
        units[#units + 1] = { id = id, x = x, z = z }
        if on(opt.visualenemy) then  -- VISUALENEMY=<unit>: an enemy in front of each unit
          Spring.CreateUnit(opt.visualenemy, x, Spring.GetGroundHeight(x, z - 450), z - 450, "south", 1)
        end
      else
        Spring.Echo("[VISUAL] spawn failed " .. ud.name)
      end
    end
  end
  if on(opt.visualnodraw) and n == 100 then  -- VISUALNODRAW=<unit>: Spring.SetUnitNoDraw on that unit of the line-up (must vanish)
    for _, u in ipairs(units) do
      if UnitDefs[Spring.GetUnitDefID(u.id)].name == opt.visualnodraw:lower() then Spring.SetUnitNoDraw(u.id, true) end
    end
  end
  if on(opt.visualmove) and n == 60 then  -- VISUALMOVE=1: a two-leg move order for every unit (order lines)
    for _, u in ipairs(units) do
      Spring.GiveOrderToUnit(u.id, CMD.MOVE, { u.x + 500, 0, u.z - 400 }, {})
      Spring.GiveOrderToUnit(u.id, CMD.MOVE, { u.x - 200, 0, u.z - 800 }, { "shift" })
    end
  end
  if on(opt.visualhurt) and n == 60 then
    for _, u in ipairs(units) do
      local h, mh = Spring.GetUnitHealth(u.id)
      if h then Spring.SetUnitHealth(u.id, mh * 0.4) end
    end
  end
  if on(opt.visualkill) and n == SHOTFRAME + 8 then
    for _, u in ipairs(units) do Spring.DestroyUnit(u.id, false) end
    units = {}
  end
  if n % 60 == 0 and n > 0 then
    local t = {}
    for _, u in ipairs(units) do
      local x, y, z = Spring.GetUnitPosition(u.id)
      if x then t[#t + 1] = ("%s %.0f/%.0f/%.0f"):format(UnitDefs[Spring.GetUnitDefID(u.id)].name, x, y, z) end
    end
    Spring.Echo("[VISUAL] frame " .. n .. " " .. table.concat(t, " "))
  end
end

else  -- unsynced: camera and screenshots

local draws, taken, quitting, lastShot = 0, 0, false, -100
local MINFRAME = tonumber(opt.visualframes) or 0
local cx, cz = Game.mapSizeX / 2, Game.mapSizeZ / 2
local far = tonumber(opt.visualzoom) or 700
local alt = tonumber(opt.visualalt) or 130
local rx = tonumber(opt.visualrx) or 2.35
local shotAt
if on(opt.visualshotat) then
  shotAt, NSHOTS = {}, 0
  for frame in opt.visualshotat:gmatch("%d+") do shotAt[tonumber(frame)] = true; NSHOTS = NSHOTS + 1 end
end
local wanted = {}
for _, ud in ipairs(lineup()) do wanted[ud.id] = true end

function gadget:DrawScreenPost()
  draws = draws + 1
  local n = Spring.GetGameFrame()
  if shotAt then  -- VISUALSHOTAT="560,700": screenshots at exactly these frames instead
    if shotAt[n] and lastShot ~= n then
      Spring.SendCommands("screenshot png")
      taken = taken + 1
      lastShot = n
    end
  elseif n >= SHOTFRAME and taken < NSHOTS and n - lastShot >= STEP then
    Spring.SendCommands("screenshot png")
    taken = taken + 1
    lastShot = n
  end
end

function gadget:GameFrame(n)
  if n == 20 then
    Spring.SendCommands("console 0")
    if not on(opt.visualshowui) then Spring.SendCommands("hideinterface 1") end   -- VISUALSHOWUI=1: screenshots with the HUD
    if not on(opt.visualui) then Spring.SendCommands("luaui disable") end   -- VISUALUI=1 keeps LuaUI (lights) running
  end
  if on(opt.visualat) then  -- VISUALAT="300:say hello|520:chatall": console commands at given frames
    for frame, c in opt.visualat:gmatch("(%d+):([^|]+)") do
      if tonumber(frame) == n then Spring.SendCommands(c) end
    end
  end
  if on(opt.visualmove) and n == 70 then  -- and they are selected, so their order lines show
    local mine = {}
    for _, id in ipairs(Spring.GetTeamUnits(0)) do
      if wanted[Spring.GetUnitDefID(id)] then mine[#mine + 1] = id end
    end
    Spring.SelectUnitArray(mine)
  end
  if n == 40 and on(opt.visualcmd) then
    for c in opt.visualcmd:gmatch("[^|]+") do Spring.SendCommands(c) end
  end
  if n >= 20 and taken < NSHOTS then
    -- aim at the middle of the line-up (ships drift after they are created)
    local sx, sy, sz, count = 0, 0, 0, 0
    for _, id in ipairs(Spring.GetTeamUnits(0)) do
      if wanted[Spring.GetUnitDefID(id)] then
        local x, y, z = Spring.GetUnitPosition(id)
        if math.abs(x - Game.mapSizeX / 2) < 2500 and math.abs(z - Game.mapSizeZ / 2) < 2500 then  -- not the start unit
          sx, sy, sz, count = sx + x, sy + y, sz + z, count + 1
        end
      end
    end
    local py = Spring.GetGroundHeight(cx, cz) + alt
    if count > 0 then
      -- the spring camera looks at a point on the ground: pick the one behind the ships along the view direction
      local cs = Spring.GetCameraState()
      local h = sy / count - Spring.GetGroundHeight(sx / count, sz / count)
      local k = (cs.dy and cs.dy < -0.05) and (h / -cs.dy) or 0
      cx, cz = sx / count + (cs.dx or 0) * k, sz / count + (cs.dz or 0) * k
      py = Spring.GetGroundHeight(cx, cz)
    end
    Spring.SetCameraState({ name = "spring", mode = 2, px = cx, py = py, pz = cz,
      dist = far, rx = rx, ry = math.pi, rz = 0, fov = 45 }, 0)
  end
  if taken >= NSHOTS and n >= MINFRAME and n > lastShot + 5 and not quitting then
    quitting = true
    Spring.Echo("[VISUAL] draw frames " .. draws .. ", shots taken " .. taken)
    local t = {}
    for k, v in pairs(Spring.GetCameraState()) do t[#t + 1] = k .. "=" .. tostring(v) end
    Spring.Echo("[VISUAL] camera " .. table.concat(t, " "))
    Spring.SendCommands("quitforce")
  end
end

end
