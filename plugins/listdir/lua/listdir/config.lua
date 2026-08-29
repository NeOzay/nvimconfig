---Options du plugin et leurs valeurs par défaut.
---
---`cli` est une option et non une constante : rien ne garantit que la skill `list-dir`
---soit installée sous `~/.claude`, et coder ce chemin en dur est une dette déjà
---constatée ailleurs.

---@class Ozay.ListDir.Options
---@field paths (string|fun():string)[] chemins fouillés ; une fonction est résolue à l'usage
---@field depth integer profondeur maximale de descente sous chaque chemin
---@field ignore string[] répertoires dans lesquels ne pas descendre
---@field cli string chemin du script `list-dir.py`
---@field python string interpréteur utilisé pour l'appeler
---@field timeout integer délai maximal d'un appel, en millisecondes
---@field pickers Ozay.ListDir.Pickers réglages Snacks ajoutés à chaque picker

---Réglages passés tels quels à `Snacks.picker.pick`, par picker. Ils sont appliqués
---**après** les nôtres : layout, keymaps, previewer, tout est surchargeable.
---@class Ozay.ListDir.Pickers
---@field lists snacks.picker.Config|{} picker des répertoires-listes
---@field items snacks.picker.Config|{} picker des éléments d'une liste

---@class Ozay.ListDir.Config
---@field defaults Ozay.ListDir.Options
---@field options Ozay.ListDir.Options
local M = {}

---@type Ozay.ListDir.Options
M.defaults = {
	paths = { vim.fn.getcwd },
	depth = 4,
	-- Un scan à `depth` élevé passe l'essentiel de son temps dans ces répertoires,
	-- qui ne contiennent jamais de `.list`.
	ignore = { ".git", "node_modules", ".venv", "__pycache__", "dist", "build", "target" },
	cli = vim.fs.joinpath(vim.env.HOME, ".claude/skills/list-dir/scripts/list-dir.py"),
	python = "python3",
	timeout = 5000,
	pickers = { lists = {}, items = {} },
}

M.options = vim.deepcopy(M.defaults)

---@param opts? Ozay.ListDir.Options
function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

---Les options d'un picker : les nôtres d'abord, celles de l'utilisateur par-dessus.
---@param name "lists"|"items"
---@param opts snacks.picker.Config|{} réglages du plugin pour ce picker
---@return snacks.picker.Config
---@nodiscard
function M.picker(name, opts)
	return vim.tbl_deep_extend("force", opts, M.options.pickers[name] or {})
end

---Les chemins de recherche, fonctions résolues et doublons écartés.
---@return string[]
---@nodiscard
function M.paths()
	---@type string[]
	local out = {}
	---@type table<string, true>
	local seen = {}
	for _, entry in ipairs(M.options.paths) do
		local path = type(entry) == "function" and entry() or entry --[[@as string]]
		if type(path) == "string" and path ~= "" then
			path = vim.fs.abspath(vim.fs.normalize(path))
			if not seen[path] then
				seen[path] = true
				out[#out + 1] = path
			end
		end
	end
	return out
end

return M
