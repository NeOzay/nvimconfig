---@diagnostic disable: missing-fields, assign-type-mismatch
---@type markview.config
local opts = {
	preview = {
		filetypes = { "markdown", "Avante", "codecompanion", "snacks_notif" },
		-- ignore_buftypes = {},
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
}

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

local function hook_render()
	local buffer_configs = {}
	local render = require("markview.actions").render
	require("markview.actions").render = function(_buffer, _state, _config)
		-- Persist per-buffer config in Lua-only state: store when provided, retrieve when absent
		local buffer = _buffer or vim.api.nvim_get_current_buf()
		if _config ~= nil then
			_config = vim.tbl_deep_extend("force", opts, _config)
			buffer_configs[buffer] = _config
		else
			_config = buffer_configs[buffer]
			-- Auto-triggered by markview: skip floating windows (signature help)
			if not _config and vim.bo[buffer].filetype == "markdown" then
				for _, w in ipairs(vim.api.nvim_list_wins()) do
					if vim.api.nvim_win_get_buf(w) == buffer and vim.api.nvim_win_get_config(w).relative ~= "" then
						return
					end
				end
			end
		end
		render(buffer, _state, _config)
	end
end

local function config()
	hook_render()
	require("markview").setup(opts)
end

---@type LazyPluginSpec
return {
	"OXY2DEV/markview.nvim",
	lazy = false,
	-- enabled = false,
	dev = true,
	ft = { "markdown", "Avante", "codecompanion", "snacks_notif" },
	config = config,
}
