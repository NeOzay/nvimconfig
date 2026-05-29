---@type snacks.Config
local opts = {
	dashboard = {
		enabled = true,
		preset = {
			header = [[
   ███╗   ██╗██╗   ██╗██╗███╗   ███╗
   ████╗  ██║██║   ██║██║████╗ ████║
   ██╔██╗ ██║██║   ██║██║██╔████╔██║
   ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
   ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
   ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
          ]],
			keys = {
				{
					icon = " ",
					key = "f",
					desc = "Trouver un fichier",
					action = ":lua Snacks.dashboard.pick('files')",
				},
				{ icon = " ", key = "n", desc = "Nouveau fichier", action = ":ene | startinsert" },
				{
					icon = " ",
					key = "g",
					desc = "Rechercher (grep)",
					action = ":lua Snacks.dashboard.pick('live_grep')",
				},
				{
					icon = " ",
					key = "r",
					desc = "Fichiers récents",
					action = ":lua Snacks.dashboard.pick('oldfiles')",
				},
				{
					icon = " ",
					key = "s",
					desc = "Restaurer la session",
					action = ':lua require("persistence").load()',
				},
				{
					icon = " ",
					key = "S",
					desc = "Choisir une session",
					action = ':lua require("persistence").select()',
				},
				{ icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
				{ icon = " ", key = "q", desc = "Quitter", action = ":qa" },
			},
		},
		sections = {
			{ section = "header" },
			{ section = "keys", gap = 1, padding = 1 },
			{
				{
					icon = " ",
					title = "Sessions récentes",
					section = "projects",
					indent = 2,
					padding = 1,
					limit = 10,
				},
				{
					pane = 2,
					icon = " ",
					title = "Fichiers récents",
					section = "recent_files",
					indent = 2,
					padding = 1,
					limit = 10,
				},
			},
			{ section = "startup" },
		},
	},
}

return { opts = opts, keys = {} }
