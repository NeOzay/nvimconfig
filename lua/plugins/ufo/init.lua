local api = vim.api
local actions = require("plugins.ufo.actions")
local handler = require("plugins.ufo.handler")

---@type LazyPluginSpec
return {
	"kevinhwang91/nvim-ufo",
	dependencies = { "kevinhwang91/promise-async" },
	event = "User FilePost",
	keys = {
		{
			"zR",
			function()
				vim.b.ufo_fold_level = 99
				require("ufo").openAllFolds()
			end,
			desc = "Open all folds",
		},
		{
			"zM",
			function()
				vim.b.ufo_fold_level = 0
				require("ufo").closeAllFolds()
			end,
			desc = "Close all folds",
		},
		{
			"zr",
			function()
				local bufnr = api.nvim_get_current_buf()
				local level = (vim.b[bufnr].ufo_fold_level or 0) + 1
				vim.b[bufnr].ufo_fold_level = level
				require("ufo").closeFoldsWith(level)
			end,
			desc = "Open one fold level",
		},
		{
			"zm",
			function()
				local bufnr = api.nvim_get_current_buf()
				local level = math.max(0, (vim.b[bufnr].ufo_fold_level or 0) - 1)
				vim.b[bufnr].ufo_fold_level = level
				require("ufo").closeFoldsWith(level)
			end,
			desc = "Close one fold level",
		},
		{ "zC", actions.close_recursive, desc = "Close fold recursively" },
		{ "zO", actions.open_recursive, desc = "Open fold recursively" },
		{ "zA", actions.toggle_recursive, desc = "Toggle fold recursively" },
		{
			"zK",
			function()
				if not require("ufo").peekFoldedLinesUnderCursor() then
					vim.lsp.buf.hover()
				end
			end,
			desc = "Peek fold",
		},
	},
	config = function(_, opts)
		require("ufo").setup(opts)
		api.nvim_create_user_command("UfoFoldDocstrings", function()
			require("plugins.ufo.langs.python").fold_docstrings()
		end, { desc = "Fold Python docstrings" })
	end,
	opts = {
		provider_selector = function(_, _, buftype)
			return buftype == "nofile" and "" or { "treesitter", "indent" }
		end,
		preview = {
			win_config = {
				border = "rounded",
				winhighlight = "Normal:Folded",
				winblend = 0,
			},
		},
		fold_virt_text_handler = handler.fold_handler,
	},
}
