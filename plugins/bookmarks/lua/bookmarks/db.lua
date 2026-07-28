---@class Ozay.Bookmarks.Record
---@field id? integer
---@field project_root string
---@field file string
---@field lnum integer
---@field annotation? string
---@field code_context? string
---@field tag? string
---@field note? string
---@field created_at integer

---@class Ozay.Bookmarks.Db
local M = {}

---@type table? sqlite.lua db handle (require("sqlite.db"):open(...))
local conn

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS bookmarks (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	project_root TEXT NOT NULL,
	file TEXT NOT NULL,
	lnum INTEGER NOT NULL,
	annotation TEXT,
	code_context TEXT,
	tag TEXT,
	note TEXT,
	created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_bookmarks_project_file ON bookmarks(project_root, file);
]]

--- Ajoute les colonnes manquantes sur une base déjà existante (migration idempotente).
local function migrate()
	local columns = conn:eval("PRAGMA table_info(bookmarks)")
	if type(columns) ~= "table" then
		return
	end
	local has_note = false
	for _, col in ipairs(columns) do
		if col.name == "note" then
			has_note = true
			break
		end
	end
	if not has_note then
		local ok, err = pcall(function()
			conn:eval("ALTER TABLE bookmarks ADD COLUMN note TEXT")
		end)
		if not ok then
			vim.notify(
				"bookmarks.nvim: échec migration colonne note: " .. tostring(err),
				vim.log.levels.ERROR,
				{ title = "bookmarks.nvim" }
			)
		end
	end
end

--- Ouvre (ou crée) la base et la table si absente. Idempotent.
---@param db_path string chemin absolu du fichier .sqlite.db
function M.setup(db_path)
	if conn then
		return
	end
	local ok, sqlite = pcall(require, "sqlite.db")
	if not ok then
		vim.notify("bookmarks.nvim: sqlite.lua introuvable", vim.log.levels.ERROR, { title = "bookmarks.nvim" })
		return
	end
	local parent = vim.fs.dirname(db_path)
	if vim.fn.isdirectory(parent) == 0 then
		vim.fn.mkdir(parent, "p")
	end
	conn = sqlite:open(db_path)
	local eval_ok, eval_err = pcall(function()
		conn:eval(SCHEMA)
	end)
	if not eval_ok then
		vim.notify(
			"bookmarks.nvim: échec de création du schéma: " .. tostring(eval_err),
			vim.log.levels.ERROR,
			{ title = "bookmarks.nvim" }
		)
		return
	end
	migrate()
end

---@return boolean
local function ensure_ready()
	if not conn then
		vim.notify("bookmarks.nvim: db non initialisée", vim.log.levels.ERROR, { title = "bookmarks.nvim" })
		return false
	end
	return true
end

--- Insère un nouveau bookmark, retourne son id (ou nil si échec).
---@param record Ozay.Bookmarks.Record  -- sans `id`
---@return integer? id
function M.insert(record)
	if not ensure_ready() then
		return nil
	end
	local ok, result = pcall(function()
		return conn:eval(
			[[INSERT INTO bookmarks (project_root, file, lnum, annotation, code_context, tag, created_at)
			VALUES (:project_root, :file, :lnum, :annotation, :code_context, :tag, :created_at)]],
			record
		)
	end)
	if not ok then
		vim.notify(
			"bookmarks.nvim: échec insert: " .. tostring(result),
			vim.log.levels.ERROR,
			{ title = "bookmarks.nvim" }
		)
		return nil
	end
	local id_row = conn:eval("SELECT last_insert_rowid() as id")
	return type(id_row) == "table" and id_row[1] and id_row[1].id or nil
end

--- Liste tous les bookmarks d'un projet (tous fichiers confondus), triés par fichier puis ligne.
---@param project_root string
---@return Ozay.Bookmarks.Record[]
function M.list_by_project(project_root)
	if not ensure_ready() then
		return {}
	end
	local rows = conn:eval(
		"SELECT * FROM bookmarks WHERE project_root = :project_root ORDER BY file, lnum",
		{ project_root = project_root }
	)
	return type(rows) == "table" and rows or {}
end

--- Liste les bookmarks d'un fichier précis dans un projet, triés par ligne.
---@param project_root string
---@param file string
---@return Ozay.Bookmarks.Record[]
function M.list_by_file(project_root, file)
	if not ensure_ready() then
		return {}
	end
	local rows = conn:eval(
		"SELECT * FROM bookmarks WHERE project_root = :project_root AND file = :file ORDER BY lnum",
		{ project_root = project_root, file = file }
	)
	return type(rows) == "table" and rows or {}
end

--- Met à jour un bookmark existant (partiel : seuls les champs fournis sont modifiés).
---@param id integer
---@param fields table<string, unknown> -- ex: {lnum=42, annotation="..."}
function M.update(id, fields)
	if not ensure_ready() then
		return
	end
	local sets = {}
	local params = { id = id }
	for k, v in pairs(fields) do
		table.insert(sets, k .. " = :" .. k)
		params[k] = v
	end
	if #sets == 0 then
		return
	end
	local ok, err = pcall(function()
		conn:eval("UPDATE bookmarks SET " .. table.concat(sets, ", ") .. " WHERE id = :id", params)
	end)
	if not ok then
		vim.notify(
			"bookmarks.nvim: échec update: " .. tostring(err),
			vim.log.levels.ERROR,
			{ title = "bookmarks.nvim" }
		)
	end
end

--- Supprime un bookmark par id.
---@param id integer
function M.delete(id)
	if not ensure_ready() then
		return
	end
	conn:eval("DELETE FROM bookmarks WHERE id = :id", { id = id })
end

--- Supprime tous les bookmarks d'un fichier dans un projet.
---@param project_root string
---@param file string
function M.delete_by_file(project_root, file)
	if not ensure_ready() then
		return
	end
	conn:eval(
		"DELETE FROM bookmarks WHERE project_root = :project_root AND file = :file",
		{ project_root = project_root, file = file }
	)
end

--- Ferme la connexion.
function M.close()
	if conn then
		conn:close()
		conn = nil
	end
end

return M
