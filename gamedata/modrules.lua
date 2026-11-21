--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    modrules.lua
--  brief:   modrules definitions
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modrules  = {

  sensors = {
    requireSonarUnderWater = false,
    
    los = {
      losMipLevel = 2,  -- defaults to 1
      losMul      = 1,  -- defaults to 1
      airMipLevel = 2,  -- defaults to 2
      airMul      = 1,  -- defaults to 1
    },
  },

  flankingBonus = {
    -- defaults to 1
    -- 0: no flanking bonus  
    -- 1: global coords, mobile  
    -- 2: unit coords, mobile  
    -- 3: unit coords, locked 
    defaultMode = 0,
  },

  experience = {
    experienceMult = 0.0, -- defaults to 1.0

    -- these are all used in the following form:
    --   value = defValue * (1 + (scale * (exp / (exp + 1))))
    powerScale  = 0.0,  -- defaults to 1.0
    healthScale = 0.0,  -- defaults to 0.7
    reloadScale = 0.0,  -- defaults to 0.4
  },

  transportability = {
    transportGround = 0,   -- defaults to 1
    transportHover  = 0,   -- defaults to 0
    transportShip   = 0,  -- defaults to 0
    transportAir    = 1,  -- defaults to 0
    -- the Imperator's turrets are attached to it (Spring.UnitAttach), which
    -- makes them transported units as far as the engine is concerned
    targetableTransportedUnits = true,  -- defaults to false
  },

  fireAtDead = {
    fireAtKilled   = false,  -- defaults to false
    fireAtCrashing = false,   -- defaults to false
  },
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return modrules

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

