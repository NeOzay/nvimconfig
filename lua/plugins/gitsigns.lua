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
	event = "User FilePost",
	config = function(_, opts)
		require("gitsigns").setup(opts)
		setup_fold_hl()
		vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_fold_hl })
		vim.api.nvim_create_autocmd("User", {
			pattern = "GitSignsUpdate",
			once = true,
			callback = function() vim.cmd("redraw!") end,
		})
	end,
	opts = {
		signs = {
			add = { text = "│" },
			change = { text = "│" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
			untracked = { text = "┆" },
		},
		signs_staged_enable = false,
		signcolumn = false,
		preview_config = {
			style = "minimal",
			border = "rounded",
			relative = "cursor",
			row = 0,
			col = 1,
		},
	},
}
