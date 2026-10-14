-- `:Brief` en Neovim enfant, sur des dépôts git temporaires : hors chantier, un brief qu'aucun suivi
-- ne cite s'ouvre ; plusieurs ouvrent un picker ; aucun laisse un message. Sur une branche de
-- chantier, le brief du suivi.

local new_set = MiniTest.new_set
local expect = MiniTest.expect

local child = MiniTest.new_child_neovim()

---Un dépôt git vide sur `branch`, dont `.claude/implementation/` porte `files` (nom → lignes).
---@param branch string
---@param files table<string, string[]>
---@return string root
local function repo(branch, files)
	local root = vim.fn.tempname()
	local dir = vim.fs.joinpath(root, ".claude", "implementation")
	vim.fn.mkdir(vim.fs.joinpath(dir, "done"), "p")
	local res = vim.system({ "git", "init", "-q", "-b", branch, root }):wait()
	assert(res.code == 0, res.stderr)
	for name, lines in pairs(files) do
		vim.fn.writefile(lines, vim.fs.joinpath(dir, name))
	end
	return root
end

---Front matter d'un suivi.
---@param branch string
---@param brief string
---@return string[]
local function suivi(branch, brief)
	return { "+++", ('branche = "%s"'):format(branch), ('brief = "%s"'):format(brief), "+++", "", "## Étapes" }
end

local BRIEF = { "+++", 'gabarit = "brief"', "+++", "", "## Intention" }

---Lance `:Brief` dans l'enfant, depuis `root`.
---@param root string
local function brief(root)
	child.lua("vim.cmd.cd(...)", { root })
	child.lua('require("chantier").open("brief")')
end

---@return string chemin relatif à la racine du buffer courant de l'enfant
local function current(root)
	local name = child.lua_get("vim.api.nvim_buf_get_name(0)")
	return vim.fs.relpath(vim.uv.fs_realpath(root), vim.uv.fs_realpath(name) or name) or name
end

local T = new_set({
	hooks = {
		pre_case = function()
			child.restart({ "-u", "tests/minimal_init.lua" })
			child.lua([[
				_G.notified = {}
				vim.notify = function(msg) table.insert(_G.notified, msg) end
			]])
		end,
		post_once = child.stop,
	},
})

T["hors chantier"] = new_set()

T["hors chantier"]["un brief → ouvert"] = function()
	local root = repo("master", { ["neuf.brief.md"] = BRIEF })
	brief(root)
	expect.equality(current(root), ".claude/implementation/neuf.brief.md")
end

T["hors chantier"]["un brief cité par un suivi est écarté"] = function()
	local root = repo("master", {
		["neuf.brief.md"] = BRIEF,
		["vieux.brief.md"] = BRIEF,
		["vieux.md"] = suivi("vieux", ".claude/implementation/vieux.brief.md"),
	})
	brief(root)
	expect.equality(current(root), ".claude/implementation/neuf.brief.md")
end

T["hors chantier"]["plusieurs → picker"] = function()
	local root = repo("master", { ["un.brief.md"] = BRIEF, ["deux.brief.md"] = BRIEF })
	brief(root)
	child.lua([[vim.wait(2000, function() return #Snacks.picker.get({ source = "chantier_briefs" }) > 0 end, 10)]])
	local texts = child.lua_get([[vim.tbl_map(function(item) return item.text end,
		Snacks.picker.get({ source = "chantier_briefs" })[1]:items())]])
	expect.equality(texts, { ".claude/implementation/deux.brief.md", ".claude/implementation/un.brief.md" })
end

T["hors chantier"]["aucun → message"] = function()
	local root = repo("master", {
		["vieux.brief.md"] = BRIEF,
		["vieux.md"] = suivi("vieux", ".claude/implementation/vieux.brief.md"),
	})
	brief(root)
	expect.equality(child.lua_get("_G.notified"), {
		"aucun chantier en cours sur la branche « master », ni de brief hors chantier",
	})
end

T["sur une branche de chantier"] = new_set()

T["sur une branche de chantier"]["le brief du suivi"] = function()
	local root = repo("vieux", {
		["neuf.brief.md"] = BRIEF,
		["vieux.brief.md"] = BRIEF,
		["vieux.md"] = suivi("vieux", ".claude/implementation/vieux.brief.md"),
	})
	brief(root)
	expect.equality(current(root), ".claude/implementation/vieux.brief.md")
end

return T
