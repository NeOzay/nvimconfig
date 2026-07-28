local git_types = { "Add", "Change", "Delete", "Topdelete", "Changedelete", "Untracked" }

local function setup_fold_hl()
	local fold = vim.api.nvim_get_hl(0, { name = "FoldColumn", link = false })
	for _, t in ipairs(git_types) do
		local gs = vim.api.nvim_get_hl(0, { name = "GitSigns" .. t, link = false })
		if gs.fg then
			local hl = { fg = fold.bg, bg = gs.fg }
			vim.api.nvim_set_hl(0, "FoldGit" .. t, hl)
			vim.api.nvim_set_hl(0, "CursorLineFoldGit" .. t, hl)
		end
	end
end

---@type LazySpec
return {
	"lewis6991/gitsigns.nvim",
	event = "VeryLazy",
	config = function(_, opts)
		require("gitsigns").setup(opts)
		setup_fold_hl()
		vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_fold_hl })
		vim.api.nvim_create_autocmd("User", {
			pattern = "GitSignsUpdate",
			once = true,
			callback = function()
				vim.cmd("redraw!")
			end,
		})
	end,
	opts = {
		signs = {
			add = { text = "▐" },
			change = { text = "▐" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
			untracked = { text = "┆" },
		},
		signs_staged_enable = true,
		signcolumn = true,
		word_diff = false,
		preview_config = {
			style = "minimal",
			border = "rounded",
			relative = "cursor",
			row = 0,
			col = 1,
		},
		on_attach = function(bufnr)
			local gitsigns = require("gitsigns")

			local function map(mode, l, r, opts)
				opts = opts or {}
				opts.buffer = bufnr
				vim.keymap.set(mode, l, r, opts)
			end

			-- Navigation
			map("n", "]c", function()
				if vim.wo.diff then
					vim.cmd.normal({ "]c", bang = true })
				else
					gitsigns.nav_hunk("next")
				end
			end)

			map("n", "[c", function()
				if vim.wo.diff then
					vim.cmd.normal({ "[c", bang = true })
				else
					gitsigns.nav_hunk("prev")
				end
			end)

			-- Actions
			map("n", "<leader>hs", gitsigns.stage_hunk)
			map("n", "<leader>hr", gitsigns.reset_hunk)

			map("v", "<leader>hs", function()
				gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end)

			map("v", "<leader>hr", function()
				gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end)

			map("n", "<leader>hS", gitsigns.stage_buffer)
			map("n", "<leader>hR", gitsigns.reset_buffer)
			map("n", "<leader>hp", gitsigns.preview_hunk)
			map("n", "<leader>hi", gitsigns.preview_hunk_inline)

			map("n", "<leader>hb", function()
				gitsigns.blame_line({ full = true })
			end)

			map("n", "<leader>hd", gitsigns.diffthis)

			map("n", "<leader>hD", function()
				gitsigns.diffthis("~")
			end)

			map("n", "<leader>hQ", function()
				gitsigns.setqflist("all")
			end)
			map("n", "<leader>hq", gitsigns.setqflist)

			-- Toggles
			map("n", "<leader>tb", gitsigns.toggle_current_line_blame)
			map("n", "<leader>tw", gitsigns.toggle_word_diff)

			-- Text object
			map({ "o", "x" }, "ih", gitsigns.select_hunk)
		end,
	},
}
