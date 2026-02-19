-- Restaurer automatiquement la session au démarrag
Userautocmd("VimEnter", {
	nested = true,
	callback = function()
		-- Ne pas restaurer si des arguments ont été passés (fichiers ouverts)
		if vim.fn.argc() == 0 and not vim.g.started_with_stdin then
			local persistence, ok = pRequire("persistence")
			if ok then
				persistence.load()
			end
		end
	end,
})

---@type LazySpec
return {
	"folke/persistence.nvim",
	event = "BufReadPre",
	opts = {
		dir = vim.fn.stdpath("state") .. "/sessions/",
		need = 1,
		branch = true,
	},
	keys = {
		{
			"<leader>qs",
			function()
				require("persistence").load()
			end,
			desc = "Restore session for cwd",
		},
		{
			"<leader>qS",
			function()
				require("persistence").select()
			end,
			desc = "Select session to load",
		},
		{
			"<leader>ql",
			function()
				require("persistence").load({ last = true })
			end,
			desc = "Restore last session",
		},
		{
			"<leader>qd",
			function()
				require("persistence").stop()
			end,
			desc = "Stop persistence (no save on exit)",
		},
	},
}
