---@namespace Ozay
---@class Statuscol.FoldData
---@field width integer         -- current width of the fold column
---@field close string         -- foldclose char
---@field open string          -- foldopen char
---@field sep string           -- foldsep char

---@class Statuscol.text.arg
---@field lnum integer         -- v:lnum
---@field relnum integer       -- v:relnum
---@field virtnum integer      -- v:virtnum
---@field buf integer          -- buffer handle of drawn window
---@field win integer          -- window handle of drawn window
---@field actual_curbuf integer -- buffer handle of |g:actual_curwin|
---@field actual_curwin integer -- window handle of |g:actual_curbuf|
---@field nu boolean           -- 'number' option value
---@field rnu boolean          -- 'relativenumber' option value
---@field empty boolean        -- statuscolumn is currently empty
---@field fold Statuscol.FoldData        -- fold column data
---@field tick integer         -- display_tick value
---@field wp any               -- win_T pointer handle (FFI cdata)

---@type LazyPluginSpec
return {
	"luukvbaal/statuscol.nvim",
	event = "User FilePost",
	-- enabled = false,
	config = function()
		local dap_handler = require("plugins.statuscol.dap_handler")
		local folds = require("plugins.statuscol.folds")
		local cond = require("plugins.statuscol.conditions")
		local segments = require("plugins.statuscol.segments")
		dap_handler.setup()
		folds.setup_hl()
		cond.setup_win_autocmd()
		vim.api.nvim_create_autocmd("ColorScheme", { callback = folds.setup_hl })
		local builtin = require("statuscol.builtin")
		local opts = segments.build()
		opts.clickhandlers = {
			FoldOpen = folds.with_scroll_to_click(builtin.foldopen_click),
			FoldOther = folds.with_scroll_to_click(builtin.foldother_click),
		}
		require("statuscol").setup(opts)
	end,
}
