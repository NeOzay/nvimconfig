-- `:Lexique` en Neovim enfant, contre la CLI `lexique` réelle et le lexique global réel : c'est la
-- CLI qui localise et lit les lexiques, et c'est son contrat que ces tests exercent.

local new_set = MiniTest.new_set
local expect = MiniTest.expect

local child = MiniTest.new_child_neovim()

---Un projet hors dépôt git, à lexique local d'un terme ; un projet sans lexique local ; un projet
---dont le lexique local est illisible (pas en UTF-8).
local projet, sans_local, illisible

---@param args string[]
---@return string
local function lexique(args)
	local res = vim.system(vim.list_extend({ "lexique" }, args), { text = true }):wait()
	assert(res.code == 0, res.stderr)
	return vim.trim(res.stdout)
end

local T = new_set({
	hooks = {
		pre_once = function()
			projet = vim.fn.tempname()
			sans_local = vim.fn.tempname()
			vim.fn.mkdir(sans_local, "p")
			local chemin = lexique({ "init", "--projet", projet })
			vim.fn.writefile({ "| Zorglubage | Un terme local. | [x](x) |" }, chemin, "a")
			illisible = vim.fn.tempname()
			vim.fn.writefile({ "\xff\xfe" }, lexique({ "init", "--projet", illisible }), "b")
		end,
		pre_case = function()
			child.restart({ "-u", "tests/minimal_init.lua" })
			child.lua('dofile("lua/cmd.lua")')
			-- Seuls les morceaux passés à `nvim_echo` disent les groupes de surbrillance.
			child.lua([[
				_G.echoed, _G.notified = {}, {}
				local echo = vim.api.nvim_echo
				vim.api.nvim_echo = function(chunks, ...)
					table.insert(_G.echoed, chunks)
					return echo(chunks, ...)
				end
				vim.notify = function(msg) table.insert(_G.notified, msg) end
			]])
			child.cmd("cd " .. vim.fn.fnameescape(projet))
		end,
		post_once = function()
			child.stop()
			vim.fn.delete(projet, "rf")
			vim.fn.delete(sans_local, "rf")
			vim.fn.delete(illisible, "rf")
		end,
	},
})

---@return string
local function bufname()
	return child.api.nvim_buf_get_name(0)
end

T["ouvrir"] = new_set()

T["ouvrir"]["sans argument, le lexique local du projet"] = function()
	child.cmd("Lexique")
	expect.equality(bufname(), vim.fs.joinpath(projet, ".claude", "LEXIQUE.md"))
end

T["ouvrir"]["avec !, le lexique global"] = function()
	child.cmd("Lexique!")
	expect.equality(bufname(), lexique({ "chemin", "--global" }))
end

T["ouvrir"]["sans lexique local, le dit et n'ouvre rien"] = function()
	child.cmd("cd " .. vim.fn.fnameescape(sans_local))
	child.cmd("Lexique")
	expect.equality(bufname(), "")
	local notified = child.lua_get("_G.notified")
	expect.equality(#notified, 1)
	expect.equality(notified[1]:find("n'existe pas", 1, true) ~= nil, true)
end

T["définir"] = new_set()

T["définir"]["un terme composé, à la casse et aux espaces près, en trois couleurs"] = function()
	child.cmd("Lexique signal  de dérive")
	local echoed = child.lua_get("_G.echoed")
	expect.equality(#echoed, 1)
	local chunks = echoed[1]
	expect.equality(chunks[1], { "Signal de dérive", "LexiqueTerme" })
	expect.equality(chunks[2], { " (global) : ", "LexiqueNiveau" })
	expect.equality(chunks[3][2], "LexiqueDefinition")
	expect.equality(chunks[3][1] ~= "", true)
end

T["définir"]["un terme local"] = function()
	child.cmd("Lexique zorglubage")
	expect.equality(child.lua_get("_G.echoed")[1], {
		{ "Zorglubage", "LexiqueTerme" },
		{ " (local) : ", "LexiqueNiveau" },
		{ "Un terme local.", "LexiqueDefinition" },
	})
end

T["définir"]["un terme inconnu : rien d'affiché, une erreur"] = function()
	child.cmd("Lexique Inexistant")
	expect.equality(child.lua_get("_G.echoed"), {})
	expect.equality(child.lua_get("_G.notified")[1]:find("aucun terme correspondant", 1, true) ~= nil, true)
end

T["sous le curseur"] = new_set()

---@param line string
---@param mot string le mot où poser le curseur
local function cursor_on(line, mot)
	child.api.nvim_buf_set_lines(0, 0, -1, false, { line })
	child.api.nvim_win_set_cursor(0, { 1, assert(line:find(mot, 1, true)) - 1 })
end

T["sous le curseur"]["le terme composé qui couvre le curseur"] = function()
	cursor_on("un Signal de dérive ici", "dérive")
	child.lua('require("lexique").at_cursor()')
	expect.equality(child.lua_get("_G.echoed")[1][1], { "Signal de dérive", "LexiqueTerme" })
end

T["sous le curseur"]["hors terme : rien d'affiché, un message"] = function()
	cursor_on("un Signal de dérive ici", "ici")
	child.lua('require("lexique").at_cursor()')
	expect.equality(child.lua_get("_G.echoed"), {})
	expect.equality(#child.lua_get("_G.notified"), 1)
end

T["sous le curseur"]["pas un terme pris dans un mot plus long"] = function()
	cursor_on("une Database", "base")
	child.lua('require("lexique").at_cursor()')
	expect.equality(child.lua_get("_G.echoed"), {})
end

T["sous le curseur"]["hors terme, un lexique illisible se dit quand même"] = function()
	child.cmd("cd " .. vim.fn.fnameescape(illisible))
	cursor_on("un Signal de dérive ici", "ici")
	child.lua('require("lexique").at_cursor()')
	local notified = table.concat(child.lua_get("_G.notified"), "\n")
	expect.equality(notified:find("illisible", 1, true) ~= nil, true)
	expect.equality(notified:find("aucun terme du lexique sous le curseur", 1, true) ~= nil, true)
end

T["sous le curseur"]["sur un terme, un lexique illisible ne se dit qu'une fois"] = function()
	child.cmd("cd " .. vim.fn.fnameescape(illisible))
	cursor_on("un Signal de dérive ici", "dérive")
	child.lua('require("lexique").at_cursor()')
	expect.equality(child.lua_get("_G.echoed")[1][1], { "Signal de dérive", "LexiqueTerme" })
	local notified = child.lua_get("_G.notified")
	expect.equality(#notified, 1)
	expect.equality(notified[1]:find("illisible", 1, true) ~= nil, true)
end

T["sous le curseur"]["la sélection visuelle"] = function()
	child.api.nvim_buf_set_lines(0, 0, -1, false, { "le signal", "de dérive" })
	child.type_keys("gg", "w", "v", "G", "$")
	child.lua('require("lexique").selection()')
	expect.equality(child.fn.mode(), "n")
	expect.equality(child.lua_get("_G.echoed")[1][1], { "Signal de dérive", "LexiqueTerme" })
end

T["entrées"] = new_set()

T["entrées"]["tous les termes, global puis local, avec leur définition"] = function()
	local entries = child.lua_get('require("lexique").entries()')
	expect.equality(entries[#entries], { niveau = "local", terme = "Zorglubage", definition = "Un terme local." })
	for i = 1, #entries - 1 do
		expect.equality(entries[i].niveau, "global")
	end
	expect.equality(#entries > 1, true)
end

T["compléter"] = new_set()

---@param line string
---@return string[]
local function complete(line)
	return child.fn.getcompletion(line, "cmdline")
end

T["compléter"]["un terme composé, mot à mot"] = function()
	expect.equality(vim.tbl_contains(complete("Lexique Signal de "), "dérive"), true)
end

T["compléter"]["derrière un modificateur"] = function()
	expect.equality(complete("silent Lexique Sig"), { "Signal de dérive" })
end

T["compléter"]["derrière une portée collée au nom"] = function()
	expect.equality(complete("5Lexique Sig"), { "Signal de dérive" })
end

T["compléter"]["rien après `!`, qui ne prend pas de terme"] = function()
	expect.equality(complete("Lexique! Sig"), {})
end

T["compléter"]["un terme local"] = function()
	expect.equality(complete("Lexique Zorg"), { "Zorglubage" })
end

return T
