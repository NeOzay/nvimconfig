---Ouverture des documents du chantier en cours (implementation-tracker).
---
---Le chantier en cours est le fichier de suivi `.claude/implementation/<slug>.md`
---dont le champ `branche` égale la branche git courante, dans le dépôt du cwd de
---Neovim. Les chantiers archivés (`done/`) sont ignorés : le glob ne descend pas.
---Pas de correspondance : un message, sauf pour `brief`, qui se rabat sur les briefs
---qu'aucun suivi ne cite — un chantier cadré mais pas encore créé.

local frontmatter = require("frontmatter")

---Suffixes des documents appariés au suivi, à écarter de la recherche.
local SIBLINGS = { ".brief.md", ".audit.md", ".plan.md" }

local M = {}

---@param msg string
---@param level? integer
local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.WARN, { title = "Chantier" })
end

---@param value string?
---@return string?
local function filled(value)
	if not value or value == "" or frontmatter.is_marker(value) then
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

---@class Ozay.Chantier.Suivi
---@field path string
---@field data Ozay.Frontmatter.Data

---@class Ozay.Chantier.Scan
---@field suivis Ozay.Chantier.Suivi[] suivis lus, hors `done/`
---@field errors string[] erreurs de lecture : un suivi illisible interdit de conclure à l'absence
---@field briefs string[] chemins des `*.brief.md`, hors `done/`

---Balaie `.claude/implementation/` sans descendre dans `done/`.
---@param root string
---@return Ozay.Chantier.Scan
---@nodiscard
local function scan(root)
	local dir = vim.fs.joinpath(root, ".claude", "implementation")
	---@type Ozay.Chantier.Scan
	local found = { suivis = {}, errors = {}, briefs = {} }
	for name, kind in vim.fs.dir(dir) do
		if kind == "file" and vim.endswith(name, ".md") then
			local path = vim.fs.joinpath(dir, name)
			if vim.endswith(name, ".brief.md") then
				found.briefs[#found.briefs + 1] = path
			elseif not is_sibling(name) then
				local data, err = frontmatter.read(path)
				if data then
					found.suivis[#found.suivis + 1] = { path = path, data = data }
				else
					found.errors[#found.errors + 1] = err
				end
			end
		end
	end
	return found
end

---Le suivi dont `branche` égale `branch`.
---@param found Ozay.Chantier.Scan
---@param branch string
---@return Ozay.Chantier.Suivi?
---@nodiscard
local function find_suivi(found, branch)
	for _, suivi in ipairs(found.suivis) do
		if filled(suivi.data.fields.branche) == branch then
			return suivi
		end
	end
	return nil
end

---Chemin absolu d'une valeur de champ, relative à la racine du dépôt ou déjà absolue.
---@param root string
---@param value string
---@return string
---@nodiscard
local function resolve(root, value)
	return vim.fs.normalize(vim.startswith(value, "/") and value or vim.fs.joinpath(root, value))
end

---Les briefs qu'aucun suivi ne cite en `brief` : ceux d'un chantier pas encore créé.
---@param root string
---@param found Ozay.Chantier.Scan
---@return string[]
---@nodiscard
local function orphan_briefs(root, found)
	---@type table<string, true>
	local cited = {}
	for _, suivi in ipairs(found.suivis) do
		local value = filled(suivi.data.fields.brief)
		if value then
			cited[resolve(root, value)] = true
		end
	end
	return vim.tbl_filter(function(path)
		return not cited[vim.fs.normalize(path)]
	end, found.briefs)
end

---@param path string
local function edit(path)
	vim.cmd.edit(vim.fn.fnameescape(path))
end

---Ouvre un brief hors chantier : le seul, ou au choix dans un picker s'il y en a plusieurs.
---@param root string
---@param briefs string[]
local function open_brief(root, briefs)
	if #briefs == 1 then
		return edit(briefs[1])
	end
	table.sort(briefs)
	Snacks.picker.pick({
		source = "chantier_briefs",
		title = "Briefs hors chantier",
		items = vim.tbl_map(function(path)
			return { text = vim.fs.relpath(root, path) or path, file = path }
		end, briefs),
		format = "file",
		preview = "file",
	})
end

---Ouvre le document du chantier en cours désigné par `field` du suivi, ou le
---suivi lui-même quand `field` est nil. Hors chantier, `brief` ouvre un brief qu'aucun
---suivi ne cite encore.
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

	local found = scan(root)
	local suivi = find_suivi(found, branch)
	if not suivi then
		local msg = ("aucun chantier en cours sur la branche « %s »"):format(branch)
		if #found.errors > 0 then
			return notify(msg .. " — suivis non lus :\n" .. table.concat(found.errors, "\n"), vim.log.levels.ERROR)
		end
		if field == "brief" then
			local briefs = orphan_briefs(root, found)
			if #briefs > 0 then
				return open_brief(root, briefs)
			end
			return notify(msg .. ", ni de brief hors chantier")
		end
		return notify(msg)
	end

	local path = suivi.path
	if field then
		local value = filled(suivi.data.fields[field])
		if not value then
			return notify(("le suivi ne renseigne pas « %s »"):format(field), vim.log.levels.ERROR)
		end
		path = resolve(root, value)
		if not vim.uv.fs_stat(path) then
			return notify(("%s introuvable : %s"):format(field, value), vim.log.levels.ERROR)
		end
	end

	edit(path)
end

return M
