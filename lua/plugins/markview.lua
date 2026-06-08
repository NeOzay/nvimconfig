---@diagnostic disable: missing-fields, assign-type-mismatch

-- Highlight escaped symbols in insert mode, otherwise do not highlight them.
local previous_hi = nil
Userautocmd("InsertEnter", {
	callback = function(args)
		if previous_hi then
			vim.api.nvim_set_hl(0, "@string.escape.markdown_inline", previous_hi)
		end
	end,
})

Userautocmd({ "InsertLeave", "BufEnter" }, {
	callback = function(args)
		previous_hi = previous_hi or vim.api.nvim_get_hl(0, { name = "@string.escape.markdown_inline", link = false })
		vim.api.nvim_set_hl(0, "@string.escape.markdown_inline", { fg = "None", bg = "None" })
	end,
})

local function hook_render(opts)
	local buffer_configs = {}
	local filetype_map = { markdown = true }
	if opts.preview and opts.preview.filetypes then
		for _, ft in ipairs(opts.preview.filetypes) do
			filetype_map[ft] = true
		end
	end
	local render = require("markview.actions").render
	require("markview.actions").render = function(_buffer, _state, _config)
		-- Persist per-buffer config in Lua-only state: store when provided, retrieve when absent
		local buffer = _buffer or vim.api.nvim_get_current_buf()
		if _config ~= nil then
			_config = vim.tbl_deep_extend("force", opts, _config)
			buffer_configs[buffer] = _config
		else
			_config = buffer_configs[buffer]
			local filetype = vim.bo[buffer].filetype
			if not filetype_map[filetype] and not _config then
				return
			end
			-- Auto-triggered by markview: skip floating windows (signature help)
			-- if not _config then
			-- 	for _, w in ipairs(vim.api.nvim_list_wins()) do
			-- 		if vim.api.nvim_win_get_buf(w) == buffer and vim.api.nvim_win_get_config(w).relative ~= "" then
			-- 			return
			-- 		end
			-- 	end
			-- end
		end
		render(buffer, _state, _config)
	end
end

---@type LazyPluginSpec
return {
	"NeOzay/markview.nvim",
	lazy = false,
	dev = true,
	ft = { "markdown", "codecompanion", "snacks_notif" },
	---@type markview.config
	opts = {
		preview = {
			filetypes = { "markdown", "Avante", "codecompanion", "snacks_notif" },
			ignore_buftypes = {},
		},
		experimental = { fancy_comments = true },
		markdown = {
			block_quotes = { enable = true },
			code_blocks = { style = "simple" },
			list_items = {
				marker_minus = {
					text = "●",
				},
			},
		},
		markdown_inline = { inline_codes = { padding_left = "", padding_right = "" } },
	},
	config = function(_, opts)
		hook_render(opts)
		require("markview").setup(opts)
	end,
}
