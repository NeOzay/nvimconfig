local function config()
	local persistence = require("persistence")
	persistence.setup({
		dir = vim.fn.stdpath("state") .. "/sessions/",
		need = 1,
		branch = true,
	})

	vim.keymap.set("n", "<leader>qs", function()
		require("persistence").load()
	end, { desc = "Restore session for cwd" })

	vim.keymap.set("n", "<leader>qS", function()
		require("persistence").select()
	end, { desc = "Select session to load" })

	vim.keymap.set("n", "<leader>ql", function()
		require("persistence").load({ last = true })
	end, { desc = "Restore last session" })

	vim.keymap.set("n", "<leader>qd", function()
		require("persistence").stop()
	end, { desc = "Stop persistence (no save on exit)" })
end

---@type LazySpec
return {
	"folke/persistence.nvim",
	event = "BufReadPre",
	config = config,
}
