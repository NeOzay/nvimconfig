local schemastore, has_schemastore = pRequire("schemastore")

local extra = {
	{
		description = "Emmylua ls configuration schema",
		fileMatch = { ".emmyrc.json" },
		name = ".emmyrc.json",
		url = "https://raw.githubusercontent.com/EmmyLuaLs/emmylua-analyzer-rust/refs/heads/main/crates/emmylua_code_analysis/resources/schema.json",
	},
}

---@type vim.lsp.Config
return {
	filetypes = { "json", "jsonc" },

	settings = {
		json = {
			schemas = has_schemastore and schemastore.json and schemastore.json.schemas({ extra = extra }) or {},
			validate = { enable = true },
			format = { enable = true },
		},
	},
}
