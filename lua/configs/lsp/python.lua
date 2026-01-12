---@type vim.lsp.Config
local M = {}

M.name = "basedpyright"
M.filetypes = { "python" }

-- Détection automatique de l'environnement virtuel (Poetry, venv, etc.)
local function get_python_path()
	local cwd = vim.fn.getcwd()

	-- 1. Essayer Poetry
	local poetry_env = vim.fn.system("cd " .. cwd .. " && poetry env info --path 2>/dev/null")
	if vim.v.shell_error == 0 and poetry_env ~= "" then
		poetry_env = vim.trim(poetry_env)
		local poetry_python = poetry_env .. "/bin/python"
		if vim.fn.executable(poetry_python) == 1 then
			return poetry_python
		end
	end

	-- 2. Essayer .venv local
	local venv_python = cwd .. "/.venv/bin/python"
	if vim.fn.executable(venv_python) == 1 then
		return venv_python
	end

	-- 3. Essayer venv local
	local venv_alt = cwd .. "/venv/bin/python"
	if vim.fn.executable(venv_alt) == 1 then
		return venv_alt
	end

	-- 4. Utiliser python système
	return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
end

M.settings = {
	basedpyright = {
		analysis = {
			typeCheckingMode = "strict", -- "off", "basic", "standard", "strict"
			autoSearchPaths = true,
			useLibraryCodeForTypes = true,
			diagnosticMode = "openFilesOnly", -- "workspace" ou "openFilesOnly"
			autoImportCompletions = true,
			extraPaths = {},
		},
	},
	python = {
		pythonPath = get_python_path(),
	},
}

-- Commandes personnalisées pour Python
M.on_init = function()
	-- Commande pour afficher le chemin Python détecté
	vim.api.nvim_create_user_command("PyPath", function()
		local python_path = get_python_path()
		vim.notify("Python path: " .. python_path, vim.log.levels.INFO)
	end, { desc = "Afficher le chemin Python utilisé par basedpyright" })

	-- Commande pour recharger le LSP Python (utile si vous changez d'environnement)
	vim.api.nvim_create_user_command("PyReload", function()
		vim.cmd("LspRestart basedpyright")
		vim.notify("Basedpyright redémarré avec: " .. get_python_path(), vim.log.levels.INFO)
	end, { desc = "Redémarrer basedpyright avec le bon environnement" })
end

return M
