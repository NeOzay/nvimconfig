vim.keymap.set("v", "@", function()
	vim.api.nvim_get_current_line()
end, { buffer = true })
