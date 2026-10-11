--------------------------------------------------------------------------------
-- Settings: Sound tab. See LuaUI/widgets/gui_settings.lua for the fields.
--------------------------------------------------------------------------------

return {
	id = "snd", name = "Sound", order = 30,
	options = {
		{ type = "separator", name = "Volume" },
		{ id = "volmaster", name = "Master", type = "slider", min = 0, max = 200, step = 2, config = "snd_volmaster", format = "%d%%" },
		{ id = "volbattle", name = "Battle", type = "slider", min = 0, max = 100, step = 2, config = "snd_volbattle", format = "%d%%" },
		{ id = "volgeneral", name = "General", type = "slider", min = 0, max = 100, step = 2, config = "snd_volgeneral", format = "%d%%" },
		{ id = "volui", name = "Interface", type = "slider", min = 0, max = 100, step = 2, config = "snd_volui", format = "%d%%" },
		{ id = "volunitreply", name = "Unit replies", type = "slider", min = 0, max = 100, step = 2, config = "snd_volunitreply", format = "%d%%" },
		{ id = "volmusic", name = "Music", type = "slider", min = 0, max = 100, step = 2, config = "snd_volmusic", format = "%d%%" },

		{ type = "separator", name = "Music" },
		{ id = "musicplayer", name = "Music player", type = "bool", widget = "THIS Music", requires = "THIS Music",
		  desc = "Plays the .ogg files in the music folder. Its controls are in the game menu." },
	},
}
