---Ouverture des documents du chantier en cours (implementation-tracker).
---
---Le chantier en cours est le fichier de suivi `.claude/implementation/<slug>.md`
---dont le champ `branche` égale la branche git courante, dans le dépôt du cwd de
---Neovim. Les chantiers archivés (`done/`) sont ignorés : le glob ne descend pas.
---Aucun sélecteur : pas de correspondance, un message et rien d'autre.

local frontmatter = require("frontmatter")

---Suffixes des documents appariés au suivi, à écarter de la recherche.
local SIBLINGS = { ".brief.md", ".audit.md", ".plan.md" }

---Marqueurs laissés par les semences gabarit sur un champ non rempli.
local PLACEHOLDERS = { ["<À REMPLIR>"] = true, ["<OPTIONNEL>"] = true }

local M = {}

---@param msg string
---@param level? integer
local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.WARN, { title = "Chantier" })
end

---@param value string?
---@return string?
local function filled(value)
	if not value or value == "" or PLACEHOLDERS[value] then
		return nil
	end
	return value
end

---@param root string
---@return string? branch
local function current_branch(root)
	local res = vim.system({ "git", "-C", root, "branch", "--show-current" }, { text = true }):wait()
	if res.code ~= 0 then
		return nil
	end
	return filled(vim.trim(res.stdout or ""))
end

---@param path string
---@return boolean
local function is_sibling(path)
	for _, suffix in ipairs(SIBLINGS) do
		if vim.endswith(path, suffix) then
			return true
		end
	end
	return false
end

---Le suivi dont `branche` égale `branch`, ou nil et les erreurs de lecture
---rencontrées, pour ne pas conclure à l'absence sur un suivi illisible.
---@param root string
---@param branch string
---@return string? path
---@return Ozay.Frontmatter.Data|string[] data_or_errors
local function find_suivi(root, branch)
	local dir = vim.fs.joinpath(root, ".claude", "implementation")
	local errors = {}
	for name, kind in vim.fs.dir(dir) do
		if kind == "file" and vim.endswith(name, ".md") and not is_sibling(name) then
			local path = vim.fs.joinpath(dir, name)
			local data, err = frontmatter.read(path)
			if not data then
				errors[#errors + 1] = err
			elseif filled(data.fields.branche) == branch then
				return path, data
			end
		end
	end
	return nil, errors
end

---Ouvre le document du chantier en cours désigné par `field` du suivi, ou le
---suivi lui-même quand `field` est nil.
---@param field? "brief"|"plan"|"audit"
function M.open(field)
	local root = vim.fs.root(assert(vim.uv.cwd()), ".git")
	if not root then
		return notify("pas de dépôt git dans le cwd")
	end

	local branch = current_branch(root)
	if not branch then
		return notify("pas de branche courante (HEAD détachée ?)")
	end

	local suivi, data = find_suivi(root, branch)
	if not suivi then
		---@cast data string[]
		local msg = ("aucun chantier en cours sur la branche « %s »"):format(branch)
		if #data > 0 then
			return notify(msg .. " — suivis non lus :\n" .. table.concat(data, "\n"), vim.log.levels.ERROR)
		end
		return notify(msg)
	end
	---@cast data Ozay.Frontmatter.Data

	local path = suivi
	if field then
		local value = filled(data.fields[field])
		if not value then
			return notify(("le suivi ne renseigne pas « %s »"):format(field), vim.log.levels.ERROR)
		end
		path = vim.fs.normalize(vim.startswith(value, "/") and value or vim.fs.joinpath(root, value))
		if not vim.uv.fs_stat(path) then
			return notify(("%s introuvable : %s"):format(field, value), vim.log.levels.ERROR)
		end
	end

	vim.cmd.edit(vim.fn.fnameescape(path))
end

return M
