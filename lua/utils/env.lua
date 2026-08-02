---Lecteur minimaliste de fichier `.env` (non suivi par git) placé à la racine
---de la config Neovim. Utilisé pour les clés d'API (DeepSeek, etc.).
---
---Format supporté : `KEY=VALUE` par ligne, commentaires `#`, `export` optionnel,
---valeur éventuellement entourée de guillemets simples ou doubles.
---@class Ozay.Env
local M = {}

---@type table<string, string>?
local cache

---@return string
local function env_path()
	return vim.fs.joinpath(vim.fn.stdpath("config") --[[@as string]], ".env")
end

---@return table<string, string>
local function load()
	if cache then
		return cache
	end

	---@type table<string, string>
	local vars = {}
	local path = env_path()

	if vim.uv.fs_stat(path) then
		for _, line in ipairs(vim.fn.readfile(path)) do
			local key, value = line:match("^%s*export%s+([%w_]+)%s*=%s*(.*)$")
			if not key then
				key, value = line:match("^%s*([%w_]+)%s*=%s*(.*)$")
			end
			if key and value then
				value = vim.trim(value)
				local quoted = value:match('^"(.-)"') or value:match("^'(.-)'")
				if quoted then
					value = quoted
				else
					-- commentaire de fin de ligne
					value = vim.trim((value:gsub("%s+#.*$", "")))
				end
				vars[key] = value
			end
		end
	end

	cache = vars
	return vars
end

---Retourne la valeur d'une variable : `.env` d'abord, puis l'environnement du
---processus en repli.
---@param name string
---@return string?
---@nodiscard
function M.get(name)
	local value = load()[name]
	if value and value ~= "" then
		return value
	end
	value = vim.uv.os_getenv(name)
	if value and value ~= "" then
		return value
	end
	return nil
end

---Vide le cache (utile après édition du `.env` sans redémarrer Neovim).
function M.reload()
	cache = nil
end

return M
