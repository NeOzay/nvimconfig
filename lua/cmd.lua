local cmd = vim.api.nvim_create_user_command

cmd("Format", function()
	vim.lsp.buf.format()
end, {})

cmd("TSInstalled", function()
	print(table.concat(require("nvim-treesitter").get_installed(), ", "))
end, {})

cmd("LspInfo", "checkhealth vim.lsp", {})

cmd("LspLog", function()
	local log_path = vim.lsp.log.get_filename()
	vim.cmd.edit(log_path)
end, {})

cmd("LualineReload", function()
	package.loaded["lualine-conf"] = nil
	require("lualine-conf").setup()
	vim.notify("Lualine rechargé", vim.log.levels.INFO)
end, { desc = "Recharger lualine-conf.lua depuis le disque" })

cmd("StlToggle", function()
	if vim.g.stl_is_lualine ~= false then
		require("lualine").hide()
		vim.g.stl_is_lualine = false
		vim.notify("Statusline : hidden", vim.log.levels.INFO)
	else
		require("lualine").hide({ unhide = true })
		vim.g.stl_is_lualine = true
		vim.notify("Statusline : lualine", vim.log.levels.INFO)
	end
end, { desc = "Basculer la statusline lualine on/off" })
