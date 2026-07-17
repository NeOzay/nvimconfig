local function get_cmd()
	local dev_path = os.getenv("HOME") .. "/projects/basedpyright/packages/pyright/langserver.index.js"
	if vim.uv.fs_stat(dev_path) then
		return { "node", dev_path, "--stdio" }
	end
	return { "basedpyright-langserver", "--stdio" }
end

local function get_python_path()
	local cwd = vim.fn.getcwd()

	local poetry_env = vim.fn.system("cd " .. cwd .. " && poetry env info --path 2>/dev/null")
	if vim.v.shell_error == 0 and poetry_env ~= "" then
		poetry_env = vim.trim(poetry_env)
		local poetry_python = poetry_env .. "/bin/python"
		if vim.fn.executable(poetry_python) == 1 then
			return poetry_python
		end
	end

	local venv_python = cwd .. "/.venv/bin/python"
	if vim.fn.executable(venv_python) == 1 then
		return venv_python
	end

	local venv_alt = cwd .. "/venv/bin/python"
	if vim.fn.executable(venv_alt) == 1 then
		return venv_alt
	end

	return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
end

---@type vim.lsp.Config
return {
	filetypes = { "python" },
	cmd = get_cmd(),
	init_options = { disablePullDiagnostics = true },

	settings = {
		basedpyright = {
			analysis = {
				typeCheckingMode = "strict",
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
				diagnosticMode = "workspace",
				autoImportCompletions = true,
				extraPaths = {},
			},
		},
		python = {
			pythonPath = get_python_path(),
		},
	},

	on_attach = function(client, bufnr)
		-- Set up buffer-local key mappings and options here
	end,

	on_init = function()
		vim.api.nvim_create_user_command("PyPath", function()
			vim.notify("Python path: " .. get_python_path(), vim.log.levels.INFO)
		end, { desc = "Afficher le chemin Python utilisé par basedpyright" })

		vim.api.nvim_create_user_command("PyVer", function()
			local python_path = get_python_path()
			vim.notify("Python version: " .. vim.fn.system(python_path .. " --version"), vim.log.levels.INFO)
		end, { desc = "Afficher la version de Python utilisée par basedpyright" })

		vim.api.nvim_create_user_command("PyReload", function()
			vim.cmd("LspRestart basedpyright")
			vim.notify("Basedpyright redémarré avec: " .. get_python_path(), vim.log.levels.INFO)
		end, { desc = "Redémarrer basedpyright avec le bon environnement" })
	end,
}
