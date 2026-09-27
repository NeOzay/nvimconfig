---Commande `:Lexique` : ouvrir un lexique, afficher la définition d'un terme.
---
---  :Lexique          ouvre le lexique local du projet
---  :Lexique!         ouvre le lexique global
---  :Lexique <terme>  affiche la définition du terme, à la casse et aux espaces près
---  <leader>L         la définition du terme sous le curseur, ou de la sélection
---  :LexiquePicker    tous les termes et leur définition (`<leader>fL`)
---
---Neovim ne sait rien des lexiques : chemins, termes et définitions viennent de la
---commande `lexique` (skill lexique de `~/.claude` : `chemin`, `termes`, `definition`, `definitions`),
---lancée dans le cwd de Neovim. Aucun fichier n'est lu ici, aucun chemin construit.

local WARN = vim.log.levels.WARN
local ERROR = vim.log.levels.ERROR

-- `default` : un thème qui définit ces groupes garde la main.
for group, link in pairs({
	LexiqueTerme = "Title",
	LexiqueNiveau = "Comment",
	LexiqueDefinition = "Normal",
}) do
	vim.api.nvim_set_hl(0, group, { link = link, default = true })
end

---@class Ozay.Lexique.Entry
---@field niveau string
---@field terme string
---@field definition string

---@class Ozay.Lexique
local M = {}

---@param msg string
---@param level? integer
local function notify(msg, level)
	vim.notify(msg, level or WARN, { title = "Lexique" })
end

---Lance `lexique <args>` dans le cwd de Neovim, ou nil si la commande est introuvable.
---`quiet` tait l'erreur : la complétion, rappelée à chaque `<Tab>`, rend alors une liste vide.
---@param args string[]
---@param quiet? boolean
---@return vim.SystemCompleted?
local function run(args, quiet)
	local ok, res = pcall(function()
		return vim.system(vim.list_extend({ "lexique" }, args), { text = true, cwd = vim.uv.cwd() }):wait()
	end)
	if not ok then
		if not quiet then
			notify("commande `lexique` introuvable : " .. tostring(res), ERROR)
		end
		return nil
	end
	return res
end

---Une ligne `niveau\tterme\tdéfinition` de la CLI, ou nil.
---@param line string
---@return Ozay.Lexique.Entry?
local function parse(line)
	local niveau, terme, definition = line:match("^([^\t]*)\t([^\t]*)\t(.*)$")
	if niveau then
		return { niveau = niveau, terme = terme, definition = definition }
	end
end

---@param bang boolean
function M.open(bang)
	local res = run(bang and { "chemin", "--global" } or { "chemin" })
	if not res then
		return
	end
	if res.code ~= 0 then
		return notify(vim.trim(res.stderr or ""))
	end
	vim.cmd.edit(vim.fn.fnameescape(vim.trim(res.stdout or "")))
end

---Affiche les entrées, une par ligne, terme, niveau et définition colorés à part.
---@param entries Ozay.Lexique.Entry[]
function M.echo(entries)
	---@type [string, string][]
	local chunks = {}
	for i, e in ipairs(entries) do
		if i > 1 then
			chunks[#chunks + 1] = { "\n", "Normal" }
		end
		vim.list_extend(chunks, {
			{ e.terme, "LexiqueTerme" },
			{ (" (%s) : "):format(e.niveau), "LexiqueNiveau" },
			{ e.definition, "LexiqueDefinition" },
		})
	end
	if #chunks > 0 then
		vim.api.nvim_echo(chunks, true, {})
	end
end

---Remonte le stderr de la CLI : avertissement sur un code 0, erreur sinon.
---@param res vim.SystemCompleted
local function report(res)
	local err = vim.trim(res.stderr or "")
	if err ~= "" then
		notify(err, res.code == 0 and WARN or ERROR)
	end
end

---@param terme string
function M.define(terme)
	-- `--` : un terme saisi qui commence par `-` n'est pas une option de `lexique`.
	local res = run({ "definition", "--", terme })
	if not res then
		return
	end
	---@type Ozay.Lexique.Entry[]
	local entries = {}
	for line in vim.gsplit(res.stdout or "", "\n", { trimempty = true }) do
		entries[#entries + 1] = parse(line)
	end
	M.echo(entries)
	report(res)
end

---Tous les termes et leur définition, global puis local, en un appel ; nil si la commande est
---introuvable.
---@return Ozay.Lexique.Entry[]?
function M.entries()
	local res = run({ "definitions" })
	if not res then
		return nil
	end
	---@type Ozay.Lexique.Entry[]
	local entries = {}
	for line in vim.gsplit(res.stdout or "", "\n", { trimempty = true }) do
		entries[#entries + 1] = parse(line)
	end
	report(res)
	return entries
end

---@param s string
---@return string[]
local function words(s)
	return vim.split(vim.trim(s), "%s+", { trimempty = true })
end

---@param s string
---@return string
local function normalize(s)
	return table.concat(words(vim.fn.tolower(s)), " ")
end

---Vrai si l'octet `i` de `s` prolonge un mot. Un octet non ASCII compte pour une lettre :
---`%w` ne connaît pas « é », et « dérive » doit rester un seul mot.
---@param s string
---@param i integer
---@return boolean
local function is_word_byte(s, i)
	local b = s:byte(i)
	return b ~= nil and (b >= 0x80 or string.char(b):match("[%w_]") ~= nil)
end

---Le terme le plus long dont une occurrence, dans `line`, couvre l'octet `col` (0-indexé),
---à la casse et aux espaces près ; nil si aucun.
---@param line string
---@param col integer
---@param termes string[]
---@return string?
local function covering(line, col, termes)
	local lower = vim.fn.tolower(line)
	---@type string?
	local best
	for _, terme in ipairs(termes) do
		local pieces = vim.tbl_map(vim.pesc, words(vim.fn.tolower(terme)))
		local pattern = table.concat(pieces, "%s+")
		local init = 1
		while pattern ~= "" do
			local s, e = lower:find(pattern, init)
			if not s then
				break
			end
			if s - 1 <= col and col < e and not is_word_byte(lower, s - 1) and not is_word_byte(lower, e + 1) then
				if not best or #terme > #best then
					best = terme
				end
			end
			init = s + 1
		end
	end
	return best
end

---Affiche la définition du terme qui couvre le curseur, composé compris.
function M.at_cursor()
	local res = run({ "termes" })
	if not res then
		return
	end
	local termes = vim.split(res.stdout or "", "\n", { trimempty = true })
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local terme = covering(vim.api.nvim_get_current_line(), col, termes)
	if not terme then
		-- Un lexique illisible se dit ici : sans terme, `define` ne le dirait pas. Avec un terme,
		-- c'est lui qui le dit — le dire aussi le ferait apparaître deux fois.
		report(res)
		return notify("aucun terme du lexique sous le curseur")
	end
	M.define(terme)
end

---Affiche la définition du texte sélectionné, lignes jointes par une espace.
function M.selection()
	local region = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
	vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
	local texte = vim.trim(table.concat(region, " "))
	if texte == "" then
		return notify("sélection vide")
	end
	M.define(texte)
end

---Complète un terme, même composé. Neovim ne remplace que le dernier mot (`arglead`) :
---chaque candidat est rendu à partir du rang de ce mot.
---@param arglead string
---@param cmdline string
---@return string[]
function M.complete(arglead, cmdline)
	-- Ancré sur le NOM de la commande, pas sur le début de la ligne : un modificateur
	-- (`:silent Lexique …`) ou un chiffre (`:5Lexique …`) peut le précéder.
	local bang, typed = cmdline:match("%f[%a]Lexique(!?)%s+(.*)$")
	-- `!` ouvre le lexique global et ne prend pas de terme : rien à proposer.
	if not typed or bang == "!" then
		return {}
	end
	local res = run({ "termes" }, true)
	if not res then
		return {}
	end
	-- Un espace final est un mot fini : « signal de » ne doit pas proposer « Signal debug ».
	local prefix = normalize(typed)
	if prefix ~= "" and typed:match("%s$") then
		prefix = prefix .. " "
	end
	local before = #words(typed) - (arglead ~= "" and 1 or 0)

	---@type string[]
	local matches = {}
	for terme in vim.gsplit(res.stdout or "", "\n", { trimempty = true }) do
		local rest = table.concat(words(terme), " ", before + 1)
		if rest ~= "" and vim.startswith(normalize(terme) .. " ", prefix) then
			matches[#matches + 1] = rest
		end
	end
	return matches
end

return M
