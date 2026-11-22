function widget:GetInfo() return { name = "Lights Probe", layer = 99997, enabled = true } end
-- LIGHTSPROBE=1 with VISUALUI=1: every 60 frames reports the deferred lights widget's unit-bound light buffers
-- (entries, and entries whose unit no longer exists: those must stay 0) and the unit tracker's list.
if not (Spring.GetModOptions() or {}).lightsprobe then return false end

local function leaked(vbo)
  if not vbo or not vbo.indextoUnitID then return "-", "-" end
  local bad = 0
  for i = 1, vbo.usedElements do
    local u = vbo.indextoUnitID[i]
    if u and not Spring.ValidUnitID(u) then bad = bad + 1 end
  end
  return vbo.usedElements, bad
end

function widget:GameFrame(f)
  if f % 60 ~= 0 or f == 0 then return end
  local api = WG.lightsgl4
  local pu, pl = leaked(api and api.GetLightVBO and api.GetLightVBO("unitPointLightVBO"))
  local cu, cl = leaked(api and api.GetLightVBO and api.GetLightVBO("unitConeLightVBO"))
  local tracked, stale = 0, 0
  if WG.unittrackerapi and WG.unittrackerapi.visibleUnits then
    for u in pairs(WG.unittrackerapi.visibleUnits) do
      tracked = tracked + 1
      if not Spring.ValidUnitID(u) or Spring.GetUnitIsDead(u) ~= false then stale = stale + 1 end
    end
  end
  Spring.Echo(("[LIGHTSPROBE] f=%d api=%s tracker=%s point used=%s leaked=%s | cone used=%s leaked=%s | tracker units=%d stale=%d | units alive=%d")
    :format(f, tostring(api ~= nil), tostring(WG.unittrackerapi ~= nil), tostring(pu), tostring(pl), tostring(cu), tostring(cl), tracked, stale, #Spring.GetAllUnits()))
end

-- LIGHTSPROBE=2: also one strong red test light in the middle of the map (does the lights widget draw at all?)
local added
function widget:Update()
  if added or (Spring.GetModOptions().lightsprobe ~= "2") or Spring.GetGameFrame() < 100 or not WG.lightsgl4 then return end
  added = true
  local x, z = Game.mapSizeX / 2, Game.mapSizeZ / 2
  local id = WG.lightsgl4.AddPointLight(nil, nil, nil, nil, x, Spring.GetGroundHeight(x, z) + 120, z, 600, 1, 0.15, 0.1, 2,
    1, 0.15, 0.1, 0, 1, 1, 1, 0, nil, 0, 0, 0)
  Spring.Echo("[LIGHTSPROBE] test light " .. tostring(id))
end
