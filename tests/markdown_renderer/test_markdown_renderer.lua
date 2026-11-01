-- État du moteur de rendu markdown et routage de l'abstraction vers l'adaptateur actif.
-- Chaque cas redirige le fichier d'état vers un fichier temporaire : le fichier réel n'est jamais
-- lu ni écrit.

local new_set = MiniTest.new_set
local expect = MiniTest.expect

local ADAPTERS = {
	markview = "markdown_renderer.markview",
	["render-markdown"] = "markdown_renderer.render_markdown",
}
local KINDS = { "render_notification", "render_preview", "render_hover", "attach" }

---@type string
local path
---@type table<string, table>
local saved

---@param engine string?
local function write_state(engine)
	if engine then
		vim.fn.writefile({ engine }, path)
	end
end

---@return string[]
local function read_lines()
	return vim.fn.readfile(path)
end

local T = new_set({
	hooks = {
		pre_case = function()
			path = vim.fn.tempname()
			saved = {}
			for _, mod in pairs(ADAPTERS) do
				saved[mod] = package.loaded[mod]
			end
			package.loaded["markdown_renderer"] = nil
			package.loaded["markdown_renderer.state"] = nil
			require("markdown_renderer")._reset(path)
		end,
		post_case = function()
			vim.fn.delete(path)
			for mod, value in pairs(saved) do
				package.loaded[mod] = value
			end
		end,
	},
})

T["état"] = new_set()

T["état"]["fichier absent → markview"] = function()
	expect.equality(require("markdown_renderer.state").read(path), "markview")
end

T["état"]["valeur inconnue → markview"] = function()
	write_state("xyz")
	expect.equality(require("markdown_renderer.state").read(path), "markview")
end

T["état"]["fichier vide → markview"] = function()
	vim.fn.writefile({}, path)
	expect.equality(require("markdown_renderer.state").read(path), "markview")
end

T["état"]["écriture puis relecture"] = function()
	local state = require("markdown_renderer.state")
	state.write("render-markdown", path)
	expect.equality(state.read(path), "render-markdown")
	state.write("markview", path)
	expect.equality(state.read(path), "markview")
end

T["état"]["écriture crée le répertoire parent"] = function()
	local state = require("markdown_renderer.state")
	local nested = vim.fs.joinpath(path .. "-dir", "sous", "markdown-renderer")
	state.write("render-markdown", nested)
	expect.equality(state.read(nested), "render-markdown")
	vim.fn.delete(path .. "-dir", "rf")
end

T["état"]["écriture d'un moteur inconnu lève et laisse le fichier"] = function()
	local state = require("markdown_renderer.state")
	state.write("render-markdown", path)
	expect.error(function()
		state.write("xyz", path)
	end)
	expect.equality(read_lines(), { "render-markdown" })
end

T["abstraction"] = new_set()

T["abstraction"]["sans fichier : markview actif"] = function()
	local mr = require("markdown_renderer")
	expect.equality(mr.active(), "markview")
	expect.equality(mr.is_active("markview"), true)
	expect.equality(mr.is_active("render-markdown"), false)
end

T["abstraction"]["ENGINES et FILETYPES exposés"] = function()
	local mr = require("markdown_renderer")
	expect.equality(mr.ENGINES, { "markview", "render-markdown" })
	expect.equality(vim.list_contains(mr.FILETYPES, "markdown"), true)
	expect.equality(vim.list_contains(mr.FILETYPES, "snacks_notif"), true)
end

T["abstraction"]["set_next écrit sans bouger l'actif"] = function()
	local mr = require("markdown_renderer")
	expect.equality(mr.active(), "markview")
	mr.set_next("render-markdown")
	expect.equality(mr.next(), "render-markdown")
	expect.equality(mr.active(), "markview")
	expect.equality(read_lines(), { "render-markdown" })
end

T["abstraction"]["actif lu une fois au premier appel"] = function()
	write_state("render-markdown")
	local mr = require("markdown_renderer")
	expect.equality(mr.active(), "render-markdown")
	write_state("markview")
	expect.equality(mr.active(), "render-markdown")
	expect.equality(mr.next(), "markview")
end

T["abstraction"]["_reset vide le cache"] = function()
	local mr = require("markdown_renderer")
	write_state("render-markdown")
	expect.equality(mr.active(), "render-markdown")
	write_state("markview")
	mr._reset(path)
	expect.equality(mr.active(), "markview")
end

T["abstraction"]["set_next inconnu lève, fichier inchangé"] = function()
	local mr = require("markdown_renderer")
	mr.set_next("markview")
	expect.error(function()
		mr.set_next("xyz")
	end)
	expect.equality(read_lines(), { "markview" })
	expect.equality(mr.next(), "markview")
end

T["abstraction"]["set_next inconnu sans fichier ne le crée pas"] = function()
	local mr = require("markdown_renderer")
	expect.error(function()
		mr.set_next("xyz")
	end)
	expect.equality(vim.uv.fs_stat(path), nil)
end

T["routage"] = new_set()

for engine in pairs(ADAPTERS) do
	for _, kind in ipairs(KINDS) do
		T["routage"][("%s : %s atteint son adaptateur seul"):format(engine, kind)] = function()
			local calls = {}
			for other, other_mod in pairs(ADAPTERS) do
				package.loaded[other_mod] = setmetatable({}, {
					__index = function(_, name)
						return function(...)
							table.insert(calls, { other, name, { ... } })
						end
					end,
				})
			end
			write_state(engine)
			require("markdown_renderer")[kind](3, 7)
			-- `attach` ne prend que le buffer
			local args = kind == "attach" and { 3 } or { 3, 7 }
			expect.equality(calls, { { engine, kind, args } })
		end
	end
end

-- `:MarkdownRenderer` en Neovim enfant, sous un `XDG_STATE_HOME` temporaire : le fichier d'état
-- réel n'est jamais touché.
local child = MiniTest.new_child_neovim()
---@type string
local state_home
---@type string?
local saved_state_home

---@return string
local function state_file()
	return vim.fs.joinpath(state_home, "nvim", "markdown-renderer")
end

---@return string[]
local function notified()
	return child.lua_get("_G.notified")
end

local hooks = {
	pre_case = function()
		state_home = vim.fn.tempname()
		saved_state_home = vim.uv.os_getenv("XDG_STATE_HOME")
		vim.uv.os_setenv("XDG_STATE_HOME", state_home)
		child.restart({ "-u", "tests/minimal_init.lua" })
		child.lua('dofile("lua/cmd.lua")')
		child.lua([[
			_G.notified = {}
			vim.notify = function(msg) table.insert(_G.notified, msg) end
		]])
	end,
	post_case = function()
		child.stop()
		if saved_state_home then
			vim.uv.os_setenv("XDG_STATE_HOME", saved_state_home)
		else
			vim.uv.os_unsetenv("XDG_STATE_HOME")
		end
		vim.fn.delete(state_home, "rf")
	end,
}
T["commande"] = new_set({ hooks = hooks })

T["commande"]["avec un moteur : écrit le fichier d'état et le dit"] = function()
	child.cmd("MarkdownRenderer render-markdown")
	expect.equality(vim.fn.readfile(state_file()), { "render-markdown" })
	expect.equality(notified(), { "prochain démarrage : render-markdown" })
end

T["commande"]["l'actif ne bouge pas, le prochain si"] = function()
	-- au démarrage, le `cond` des specs fige l'actif
	child.lua('require("markdown_renderer").active()')
	child.cmd("MarkdownRenderer render-markdown")
	child.cmd("MarkdownRenderer")
	expect.equality(notified()[2], "actif : markview · prochain démarrage : render-markdown")
end

T["commande"]["sans argument ni fichier : markview des deux côtés"] = function()
	child.cmd("MarkdownRenderer")
	expect.equality(notified(), { "actif : markview · prochain démarrage : markview" })
	expect.equality(vim.uv.fs_stat(state_file()), nil)
end

T["commande"]["un moteur inconnu lève et laisse le fichier"] = function()
	child.cmd("MarkdownRenderer render-markdown")
	expect.error(function()
		child.cmd("MarkdownRenderer xyz")
	end)
	expect.equality(vim.fn.readfile(state_file()), { "render-markdown" })
end

T["commande"]["un moteur inconnu sans fichier ne le crée pas"] = function()
	expect.error(function()
		child.cmd("MarkdownRenderer xyz")
	end)
	expect.equality(vim.uv.fs_stat(state_file()), nil)
end

T["commande"]["complétion sur les moteurs"] = function()
	expect.equality(child.fn.getcompletion("MarkdownRenderer ", "cmdline"), { "markview", "render-markdown" })
	expect.equality(child.fn.getcompletion("MarkdownRenderer re", "cmdline"), { "render-markdown" })
	expect.equality(child.fn.getcompletion("MarkdownRenderer x", "cmdline"), {})
end

-- Défilement d'une fenêtre sans focus (preview du picker) : Neovim n'y déclenche pas le
-- `WinScrolled` local au buffer sur lequel render-markdown compte ; l'adaptateur le surveille.
-- Neovim enfant avec interface : sans elle, `WinScrolled` ne se déclenche pas.
T["défilement"] = new_set({
	hooks = {
		pre_case = function()
			local plugin = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "render-markdown.nvim")
			if not vim.uv.fs_stat(plugin) then
				MiniTest.skip("render-markdown.nvim n'est pas installé")
			end
			child.restart({ "-u", "tests/minimal_init.lua" })
			child.lua(([[
				vim.opt.rtp:prepend(%q)
				require("render-markdown").setup({ file_types = require("markdown_renderer").FILETYPES })
				local lines = {}
				for i = 1, 80 do lines[#lines + 1] = "## Titre " .. i; lines[#lines + 1] = "" end
				_G.buf = vim.api.nvim_create_buf(false, true)
				vim.api.nvim_buf_set_lines(_G.buf, 0, -1, false, lines)
				vim.bo[_G.buf].filetype = "markdown"
				_G.win = vim.api.nvim_open_win(_G.buf, false,
					{ relative = "editor", width = 40, height = 10, row = 1, col = 1 })
				_G.marks = function()
					local top = vim.api.nvim_win_call(_G.win, function() return vim.fn.line("w0") end)
					local n = 0
					for _, id in pairs(vim.api.nvim_get_namespaces()) do
						n = n + #vim.api.nvim_buf_get_extmarks(_G.buf, id, { top - 1, 0 }, { top + 8, -1 }, {})
					end
					return n
				end
			]]):format(plugin))
		end,
		post_case = function()
			child.stop()
		end,
	},
})

T["défilement"]["les lignes qui entrent à l'écran sont rendues"] = function()
	-- l'adaptateur de render-markdown, sans passer par le fichier d'état
	child.lua('require("markdown_renderer.render_markdown").render_preview(_G.buf, _G.win)')
	child.lua("vim.wait(400)")
	expect.equality(child.lua_get("_G.marks()") > 0, true)
	child.lua("vim.api.nvim_win_call(_G.win, function() vim.fn.winrestview({ topline = 100, lnum = 100 }) end)")
	child.lua("vim.wait(800)")
	expect.equality(child.lua_get("_G.marks()") > 0, true)
end

return T
