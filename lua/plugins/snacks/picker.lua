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
			preset = function()
				if vim.o.columns < 120 then
					return "ivy_2"
				end
				return "telescope"
			end,
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
				---@type snacks.layout.Box
				layout = {
					box = "horizontal",
					backdrop = false,
					width = 0.95,
					max_width = 150,
					height = 0.95,
					border = "none",
					{
						box = "vertical",
						border = "none",
						width = 0.40,
						max_width = 45,
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
			ivy_2 = {
				reverse = false,
				layout = {
					box = "vertical",
					backdrop = false,
					width = 0,
					max_width = 100,
					height = 0,
					border = true,
					title = "{preview:Preview}",
					wo = { winhighlight = { FloatTitle = "SnacksPickerPreviewTitle" } },
					{ win = "preview", border = false },
					{
						win = "input",
						height = 1,
						border = "top_bottom",
						title = "{title} {live} {flags}",
						title_pos = "center",
					},
					{
						win = "list",
						border = "bottom",
						title_pos = "center",
						height = 0.3,
						max_height = 10,
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
			Snacks.picker.grep({ layout = { preset = "ivy_2" } })
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
		desc = "picker highlights",
	},
	{
		"<leader>th",
		function()
			Snacks.picker.colorschemes()
		end,
		desc = "themes",
	},
}

vim.api.nvim_create_user_command("Pickers", function()
	Snacks.picker.pickers()
end, { desc = "list pickers" })

---@type SnacksSubmodule
return { opts = opts, keys = keys }
