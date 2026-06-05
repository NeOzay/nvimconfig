local new_set = MiniTest.new_set
local expect = MiniTest.expect

local format = require("lsp.hover.format")

--- Raccourci : format_string avec largeur optionnelle (défaut 200).
---@param lines string[]
---@param width? integer
---@return string[]
local function fmt(lines, width)
	return format.format_string(lines, width or 200)
end

--- Concatène le résultat pour faciliter les recherches.
---@param lines string[]
---@return string
local function joined(lines)
	return table.concat(lines, "\n")
end

local T = new_set()

-- ============================================================
-- visual_width
-- ============================================================
T["visual_width"] = new_set()

T["visual_width"]["texte brut"] = function()
	expect.equality(format.visual_width("hello"), 5)
end

T["visual_width"]["gras **...**"] = function()
	expect.equality(format.visual_width("**hello**"), 5)
end

T["visual_width"]["italique *...*"] = function()
	expect.equality(format.visual_width("*hi*"), 2)
end

T["visual_width"]["lien markdown"] = function()
	expect.equality(format.visual_width("[txt](url)"), 3)
end

T["visual_width"]["backticks supprimés"] = function()
	expect.equality(format.visual_width("`abc`"), 3)
end

T["visual_width"]["escape \\X → 1 colonne"] = function()
	expect.equality(format.visual_width("\\*"), 1)
end

-- ============================================================
-- Entités HTML
-- ============================================================
T["html_entities"] = new_set()

T["html_entities"]["&nbsp; → espace"] = function()
	local r = joined(fmt({ "a&nbsp;b" }))
	expect.equality(r:find("&nbsp;"), nil)
	expect.no_equality(r:find("a b"), nil)
end

T["html_entities"]["&lt; &gt; → < >"] = function()
	local r = joined(fmt({ "&lt;tag&gt;" }))
	expect.no_equality(r:find("<tag>"), nil)
end

T["html_entities"]["entité décimale &#65; → A"] = function()
	local r = joined(fmt({ "&#65;" }))
	expect.no_equality(r:find("A"), nil)
end

T["html_entities"]["entité hexadécimale &#x41; → A"] = function()
	local r = joined(fmt({ "&#x41;" }))
	expect.no_equality(r:find("A"), nil)
end

-- ============================================================
-- Blocs Vim help
-- ============================================================
T["vimhelp_blocks"] = new_set()

T["vimhelp_blocks"][">vim seul → bloc fencé"] = function()
	local r = joined(fmt({ ">vim", "  echo hello", "<" }))
	expect.no_equality(r:find("```vim"), nil)
	expect.no_equality(r:find("echo hello"), nil)
end

T["vimhelp_blocks"][">lua seul → bloc fencé lua"] = function()
	local r = joined(fmt({ ">lua", "  local x = 1", "<" }))
	expect.no_equality(r:find("```lua"), nil)
end

T["vimhelp_blocks"]["> sans lang → bloc fencé vide"] = function()
	local r = joined(fmt({ ">", "  code", "<" }))
	-- ``` suivi d'un newline (pas de lang)
	expect.no_equality(r:find("```\n"), nil)
end

T["vimhelp_blocks"]["text: >vim → texte gardé + bloc ouvert"] = function()
	local r = joined(fmt({ "Examples: >vim", "  echo nr2char(64)", "<" }))
	expect.no_equality(r:find("Examples:"), nil)
	expect.no_equality(r:find("```vim"), nil)
	expect.no_equality(r:find("echo nr2char%(64%)"), nil)
end

T["vimhelp_blocks"]["<text: >vim → close + reopen"] = function()
	-- Cas réel de builtin.txt : fermeture puis réouverture sur la même ligne
	local lines = {
		"Examples: >vim",
		'  echo nr2char(64)    " returns A',
		'<Example for "utf-8": >vim',
		'  echo nr2char(300)    " returns I with bow',
		"<",
	}
	local r = joined(fmt(lines))
	local count = 0
	for _ in r:gmatch("```vim") do
		count = count + 1
	end
	expect.equality(count, 2)
	expect.no_equality(r:find('Example for "utf%-8":'), nil)
end

T["vimhelp_blocks"]["< output > → close + reopen (builtin.txt)"] = function()
	local lines = {
		"Examples: >",
		"  :echo asin(0.8)",
		"<\t\t\t0.927295 >",
		"  :echo asin(-0.5)",
		"<\t\t\t-0.523599",
	}
	local r = joined(fmt(lines))
	-- 4 fences : open1 close1 open2 close2
	local count = 0
	for _ in r:gmatch("```") do
		count = count + 1
	end
	expect.equality(count, 4)
end

T["vimhelp_blocks"]["bloc non fermé → auto-clôturé"] = function()
	local ok, r = pcall(fmt, { ">vim", "  echo hello" })
	expect.equality(ok, true)
	-- Nombre pair de fences
	local count = 0
	for _ in joined(r):gmatch("```") do
		count = count + 1
	end
	expect.equality(count % 2, 0)
end

-- Faux positifs évités
T["vimhelp_blocks"]["Promise<void> en fin de ligne → pas de bloc"] = function()
	local r = joined(fmt({ "Returns Promise<void>" }))
	expect.equality(r:find("```"), nil)
end

T["vimhelp_blocks"]["-> string en fin → pas de bloc"] = function()
	local r = joined(fmt({ "function foo() -> string" }))
	expect.equality(r:find("```"), nil)
end

T["vimhelp_blocks"]["valeur > 0 sans deux-points → pas de bloc"] = function()
	local r = joined(fmt({ "The value must be > 0" }))
	expect.equality(r:find("```"), nil)
end

T["vimhelp_blocks"]["<type>expr9 à l'intérieur d'un bloc → pas de fermeture"] = function()
	local lines = {
		">vim",
		"  let x = <int>value",
		"  echo x",
		"<",
	}
	local r = joined(fmt(lines))
	-- Les deux lignes de code doivent être présentes
	expect.no_equality(r:find("let x"), nil)
	expect.no_equality(r:find("echo x"), nil)
	-- Exactement 2 fences (open + close)
	local count = 0
	for _ in r:gmatch("```") do
		count = count + 1
	end
	expect.equality(count, 2)
end

-- ============================================================
-- Liens Vim help
-- ============================================================
T["vimhelp_links"] = new_set()

T["vimhelp_links"]["|word| → `word`"] = function()
	local r = joined(fmt({ "Prefer |string.char()|: only works with ASCII." }))
	expect.no_equality(r:find("`string.char()`", 1, true), nil)
end

T["vimhelp_links"]["|word| à l'intérieur d'un bloc fencé → inchangé"] = function()
	local r = joined(fmt({ "```vim", "  echo |word|", "```" }))
	expect.no_equality(r:find("|word|"), nil)
end

T["vimhelp_links"]["|word| à l'intérieur d'un bloc vimhelp → inchangé"] = function()
	local r = joined(fmt({ ">vim", "  echo |word|", "<" }))
	expect.no_equality(r:find("|word|"), nil)
end

T["vimhelp_links"]["|foo bar| avec espace → inchangé"] = function()
	local r = joined(fmt({ "see |foo bar| here" }))
	expect.no_equality(r:find("|foo bar|"), nil)
end

-- ============================================================
-- Jointure de phrases
-- ============================================================
T["sentence_joining"] = new_set()

T["sentence_joining"]["lignes courtes jointes"] = function()
	local r = joined(fmt({ "This is the first", "part of a sentence." }, 200))
	expect.no_equality(r:find("first part"), nil)
end

T["sentence_joining"]["lignes dans un bloc fencé non jointes"] = function()
	local r = joined(fmt({ "```lua", "local a = 1", "local b = 2", "```" }, 200))
	expect.no_equality(r:find("local a = 1"), nil)
	expect.no_equality(r:find("local b = 2"), nil)
	-- Elles ne doivent pas être concaténées ensemble
	expect.equality(r:find("local a = 1 local b"), nil)
end

T["sentence_joining"]["ligne vide préservée comme séparateur"] = function()
	local result = fmt({ "Paragraph one.", "", "Paragraph two." }, 200)
	local has_blank = false
	for _, l in ipairs(result) do
		if vim.trim(l) == "" then
			has_blank = true
		end
	end
	expect.equality(has_blank, true)
end

-- ============================================================
-- Formatage final
-- ============================================================
T["formatting"] = new_set()

T["formatting"]["--- → ___"] = function()
	local r = joined(fmt({ "---" }))
	expect.no_equality(r:find("___"), nil)
	expect.equality(r:find("^---$"), nil)
end

T["formatting"]["double ligne vide supprimée"] = function()
	local result = fmt({ "text.", "", "", "more." }, 200)
	local consecutive_blanks = 0
	local prev_blank = false
	for _, l in ipairs(result) do
		if vim.trim(l) == "" then
			if prev_blank then
				consecutive_blanks = consecutive_blanks + 1
			end
			prev_blank = true
		else
			prev_blank = false
		end
	end
	expect.equality(consecutive_blanks, 0)
end

T["formatting"]["wrap : longue ligne coupée à max_width"] = function()
	local long = ("word "):rep(30) -- ~150 chars
	local result = fmt({ long }, 60)
	for _, l in ipairs(result) do
		expect.equality(format.visual_width(l) <= 61, true) -- +1 pour l'espace de padding
	end
end

return T
