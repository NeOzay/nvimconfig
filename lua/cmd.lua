local cmd = vim.api.nvim_create_user_command

cmd("Format", function()
	vim.lsp.buf.format()
end, {})

cmd("TSInstalled", function()
	print(table.concat(require("utils").get_installed_parsers(), ", "))
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

cmd("Lexique", function(opts)
	if opts.args == "" then
		return require("lexique").open(opts.bang)
	end
	if opts.bang then
		return vim.notify(
			"`!` ouvre le lexique global et ne prend pas de terme",
			vim.log.levels.ERROR,
			{ title = "Lexique" }
		)
	end
	require("lexique").define(opts.args)
end, {
	nargs = "?",
	bang = true,
	complete = function(arglead, cmdline)
		return require("lexique").complete(arglead, cmdline)
	end,
	desc = "Ouvrir le lexique local (! : global), ou afficher la définition d'un terme",
})

cmd("LexiquePicker", function()
	require("plugins.snacks.picker.sources.lexique")()
end, { desc = "Picker des termes du lexique et de leur définition" })

cmd("MarkdownRenderer", function(opts)
	local renderer = require("markdown_renderer")
	if opts.args == "" then
		return vim.notify(
			("actif : %s · prochain démarrage : %s"):format(renderer.active(), renderer.next()),
			vim.log.levels.INFO,
			{ title = "MarkdownRenderer" }
		)
	end
	renderer.set_next(opts.args)
	vim.notify(("prochain démarrage : %s"):format(opts.args), vim.log.levels.INFO, { title = "MarkdownRenderer" })
end, {
	nargs = "?",
	complete = function(arglead)
		return vim.tbl_filter(function(engine)
			return vim.startswith(engine, arglead)
		end, require("markdown_renderer").ENGINES)
	end,
	desc = "Choisir le moteur de rendu markdown du prochain démarrage (sans argument : l'état)",
})

cmd("Dettes", function()
	require("registres").dettes()
end, { desc = "Picker de la dette technique du dépôt, pins en tête" })

cmd("Roadmap", function()
	require("registres").roadmap()
end, { desc = "Picker des entrées de la road-map du dépôt" })

for name, field in pairs({ Suivi = false, Brief = "brief", Plan = "plan", Audit = "audit" }) do
	cmd(name, function()
		require("chantier").open(field or nil)
	end, { desc = ("Ouvrir le document « %s » du chantier en cours"):format(name:lower()) })
end
