---@type LazySpec
return {
	"folke/persistence.nvim",
	event = "BufReadPre",
	init = function()
		vim.api.nvim_create_autocmd("VimEnter", {
			nested = true,
			once = true,
			callback = function()
				if vim.fn.argc(-1) ~= 0 then
					return
				end
				local persistence = require("persistence")
				local session = persistence.current()
				if vim.uv.fs_stat(session) then
					persistence.load()
				else
					persistence.stop()
				end
			end,
		})
	end,
	opts = {
		dir = vim.fn.stdpath("state") .. "/sessions/",
		need = 1,
		branch = true,
	},
	config = function(_, opts)
		local persistence = require("persistence")
		persistence.setup(opts)
		if vim.fn.argc(-1) > 0 then
			persistence.stop()
		end

		Userautocmd("User", {
			pattern = "PersistenceSavePre",
			callback = function()
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					local buf = vim.api.nvim_win_get_buf(win)
					local bt = vim.api.nvim_get_option_value("buftype", { buf = buf })
					if bt ~= "" and bt ~= "help" then
						vim.api.nvim_win_close(win, false)
					end
				end
			end,
		})

		vim.api.nvim_create_user_command("PersistenceStart", function()
			persistence.start()
		end, { desc = "Start persistence (resume saving)" })

		vim.api.nvim_create_user_command("PersistenceDelete", function()
			local session = persistence.current()
			if session and vim.uv.fs_stat(session) then
				vim.uv.fs_unlink(session, function() end)
			end
			persistence.stop()
		end, { desc = "Delete session and stop persistence" })
	end,
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
