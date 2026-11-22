-- After jK's LoadTexture addon (engine base content), which this file replaces.
if addon.InGetInfo then
	return {
		name    = "LoadTexture",
		desc    = "A picture from bitmaps/loadpictures/ behind the loading panel, filling the screen",
		author  = "jK; THIS contributors",
		date    = "2012; 2026",
		license = "GPL2",
		layer   = 2,
		depend  = {"LoadProgress"},
		enabled = true,
	}
end

-- One picture at random (jpg/png/dds). It fills the screen and is cropped to
-- the screen's shape rather than letterboxed, so a 16:9 picture covers 16:10
-- and ultrawide screens too.
math.randomseed(os.time())
local pictures = VFS.DirList("bitmaps/loadpictures/", "*.{jpg,jpeg,png,dds}")
local backgroundTexture = #pictures > 0 and pictures[math.random(#pictures)] or nil
local aspectRatio

function addon.DrawLoadScreen()
	if not backgroundTexture then
		return
	end
	if not aspectRatio then
		local texInfo = gl.TextureInfo(backgroundTexture)
		if not texInfo or texInfo.xsize <= 0 then
			return
		end
		aspectRatio = texInfo.xsize / texInfo.ysize
	end
	local vsx, vsy = gl.GetViewSizes()
	local ratio = (vsx / vsy) / aspectRatio
	-- texture coordinates of the part that is shown
	local s0, s1, t0, t1 = 0, 1, 0, 1
	if ratio > 1 then        -- screen wider than the picture: crop top and bottom
		local cut = (1 - 1 / ratio) * 0.5
		t0, t1 = cut, 1 - cut
	else                     -- taller: crop the sides
		local cut = (1 - ratio) * 0.5
		s0, s1 = cut, 1 - cut
	end
	gl.Color(1, 1, 1, 1)
	gl.Texture(backgroundTexture)
	gl.BeginEnd(GL.QUADS, function()
		gl.TexCoord(s0, t1) gl.Vertex(0, 0)
		gl.TexCoord(s1, t1) gl.Vertex(1, 0)
		gl.TexCoord(s1, t0) gl.Vertex(1, 1)
		gl.TexCoord(s0, t0) gl.Vertex(0, 1)
	end)
	gl.Texture(false)
end

function addon.Shutdown()
	if backgroundTexture then
		gl.DeleteTexture(backgroundTexture)
	end
end
