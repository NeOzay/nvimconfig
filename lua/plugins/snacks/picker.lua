---@diagnostic disable: missing-fields

---@type string[]
local markview_fts = { "markdown", "Avante", "codecompanion", "snacks_notif" }
---@type snacks.Config
local opts = {
	picker = {
		prompt = "   ",
		actions = {
			trouble_open = function(picker)
				picker:close()
				require("trouble.sources.snacks").open(picker)
			end,
			yank_text = { action = "yank", field = "text" },
		},
		layout = {
			preset = "telescope",
		},
		win = {
			input = {
				keys = {
					["<c-q>"] = { "trouble_open", mode = { "i", "n" } },
					["<c-y>"] = { "yank", mode = { "i", "n" } },
				},
			},
			preview = {
				wo = {
					winhighlight = { EndOfBuffer = "SnacksNormal" },
					-- La fenêtre de preview est un float : statuscol ignore les floats
					-- (conditions.lua → `cfg.relative ~= ""`) et ne nettoie donc pas le
					-- `statuscolumn` global hérité. On le neutralise ici, ce qui couvre
					-- aussi le mode `preview = "main"` (où le `wo` du box n'est jamais
					-- appliqué car la win est en `layout = false`).
					statuscolumn = "",
					number = false,
					relativenumber = false,
					foldcolumn = "0",
					signcolumn = "no",
				},
				on_win = function(self)
					if not self.buf or not self.win then
						return
					end
					-- Timer créé une fois à l'ouverture du picker, réutilisé pour debouncer
					-- les multiples on_lines déclenchés lors du chargement d'un même fichier.
					local timer = assert(vim.uv.new_timer())
					vim.api.nvim_buf_attach(self.buf, false, {
						on_lines = function(_, bufnb)
							if not vim.api.nvim_win_is_valid(self.win) then
								timer:stop()
								return true
							end
							timer:stop()
							timer:start(
								10,
								0,
								vim.schedule_wrap(function()
									if
										not vim.api.nvim_buf_is_valid(bufnb)
										or not vim.api.nvim_win_is_valid(self.win)
									then
										return
									end
									vim.api.nvim_win_call(self.win, function()
										require("ibl").setup_buffer(bufnb)
									end)
									local ft = vim.split(vim.bo[bufnb].filetype, ".", { plain = true })[1]
									if vim.tbl_contains(markview_fts, ft) then
										vim.wo[self.win].conceallevel = 2
										require("markview").render(bufnb)
										require("markview.actions").set_query(bufnb)
									else
										vim.wo[self.win].conceallevel = 0
									end
								end)
							)
						end,
					})
				end,
			},
			list = {
				wo = {
					winhighlight = { --[[LineNr = "CursorLineNr",]]
						EndOfBuffer = "SnacksNormal",
					},
				},
				keys = {
					["<c-j>"] = false,
				},
			},
		},
		layouts = {
			telescope = {
				reverse = false,
				-- Réévalué à l'ouverture du picker et sur VimResized.
				-- Quand le terminal est trop étroit pour la preview en split
				-- (< 120 colonnes), on bascule sur `preview = "main"` : la preview
				-- s'affiche dans la fenêtre d'arrière-plan (le buffer courant). Le
				-- picker devient alors un panneau compact en bas (hauteur 0.4) pour
				-- laisser visible cet arrière-plan qui sert de preview.
				-- NB : la win "preview" DOIT rester listée dans le box même en mode
				-- `preview = "main"`. snacks la marque `layout = false` (relative =
				-- "win") donc elle n'occupe aucune place, mais `get_wins` ne parcourt
				-- que la structure du box : sans cette entrée, la fenêtre de preview
				-- n'est jamais ouverte au premier affichage et la preview reste vide
				-- jusqu'à un cycle de resize. C'est exactement ce que fait le preset
				-- `ivy_split` fourni par snacks.
				config = function(layout)
					if vim.o.columns < 120 then
						layout.preview = "main"
						layout.layout = {
							box = "vertical",
							backdrop = false,
							width = 0,
							height = 0.4,
							position = "bottom",
							border = "none",
							{
								win = "input",
								height = 1,
								border = true,
								title = "{title} {live} {flags}",
								title_pos = "center",
							},
							{
								win = "list",
								border = true,
								title = " Results ",
								title_pos = "center",
							},
							{ win = "preview" },
						}
					end
				end,
				layout = {
					box = "horizontal",
					backdrop = false,
					width = 0.8,
					height = 0.9,
					border = "none",
					{
						box = "vertical",
						border = "none",
						width = 0.40,
						{
							win = "input",
							height = 1,
							border = true,
							title = "{title} {live} {flags}",
							title_pos = "center",
						},
						{
							win = "list",
							border = true,
							title = " Results ",
							title_pos = "center",
						},
					},
					{
						win = "preview",
						title = "{preview:Preview}",
						border = true,
						title_pos = "center",
						wo = { number = false, foldcolumn = "0", signcolumn = "no" },
					},
				},
			},
		},
		icons = { ui = { selected = "+", unselected = " " } },
	},
}

---@type LazyKeysSpec[]
local keys = {
	{
		"<leader>fw",
		function()
			Snacks.picker.grep()
		end,
		desc = "picker live grep",
	},
	{
		"<leader>fb",
		function()
			Snacks.picker.buffers()
		end,
		desc = "picker find buffers",
	},
	{
		"<leader>fh",
		function()
			Snacks.picker.help()
		end,
		desc = "picker help page",
	},
	{
		"<leader>ma",
		function()
			Snacks.picker.marks()
		end,
		desc = "picker find marks",
	},
	{
		"<leader>fo",
		function()
			Snacks.picker.recent()
		end,
		desc = "picker find oldfiles",
	},
	{
		"<leader>fz",
		function()
			Snacks.picker.lines({
				layout = {
					layout = {
						height = 0.2,
						wo = { winhighlight = { FloatTitle = "SnacksPickerInputTitle" } },
					},
				},
				win = { list = { wo = { winhighlight = { LineNr = "CursorLineNr" } } } },
			})
		end,
		desc = "picker find in current buffer",
	},
	{
		"<leader>cm",
		function()
			Snacks.picker.git_log()
		end,
		desc = "picker git commits",
	},
	{
		"<leader>gt",
		function()
			Snacks.picker.git_status()
		end,
		desc = "picker git status",
	},
	{
		"<leader>ff",
		function()
			Snacks.picker.files()
		end,
		desc = "picker find files",
	},
	{
		"<leader>fa",
		function()
			Snacks.picker.files({ hidden = true, ignored = true })
		end,
		desc = "picker find all files",
	},
	{
		"<F3>",
		function()
			Snacks.picker.files()
		end,
		desc = "picker find files",
	},
	{
		"<leader>fj",
		function()
			Snacks.picker.jumps()
		end,
		desc = "picker jumplist",
	},
	{
		"<leader>fr",
		function()
			Snacks.picker.resume()
		end,
		desc = "picker resume",
	},
	{
		"<leader>f<C-j>",
		function()
			Snacks.picker.highlights({
				actions = {
					yank_hi = { action = "yank", field = "hl_group" },
				},
				win = {
					input = {
						keys = {
							["<c-y>"] = { "yank_hi", mode = { "n", "i" } },
						},
					},
				},
			})
		end,
		{
			"<leader>th",
			function()
				Snacks.picker.colorschemes()
			end,
			desc = "themes",
		},
	},
	desc = "picker highlights",
}

vim.api.nvim_create_user_command("Pickers", function()
	Snacks.picker.pickers()
end, { desc = "list pickers" })

---@type SnacksSubmodule
return { opts = opts, keys = keys }
