-- Chemin allant de la sélection visuelle au texte envoyé au démon. C'est lui qui a laissé passer
-- un `config.opts` hérité de l'upstream : le module de configuration expose ses champs à plat.

local new_set = MiniTest.new_set
local expect = MiniTest.expect

local config = require("tts-nvim.config")
local util = require("tts-nvim.util")

---Pose une sélection visuelle sur un buffer neuf et retourne le texte traité.
---@param lines string[]
---@param from { [1]: integer, [2]: integer }
---@param to { [1]: integer, [2]: integer }
---@param filetype? string
---@return string
local function selected(lines, from, to, filetype)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_set_current_buf(buf)
	if filetype then
		vim.bo[buf].filetype = filetype
	end

	vim.api.nvim_buf_set_mark(buf, "<", from[1], from[2], {})
	vim.api.nvim_buf_set_mark(buf, ">", to[1], to[2], {})

	local text = util.getAndProcessText()
	vim.api.nvim_buf_delete(buf, { force = true })
	return text
end

local T = new_set({
	hooks = {
		pre_case = function()
			config.setup({})
		end,
	},
})

T["sélection sur une ligne"] = function()
	expect.equality(selected({ "Bonjour le monde" }, { 1, 0 }, { 1, 6 }), "Bonjour")
end

T["sélection multi-lignes"] = function()
	local text = selected({ "Bonjour le monde", "deuxième ligne" }, { 1, 0 }, { 2, 8 })
	-- Les lignes sont jointes par une espace : sans elle, les mots de bord se soudent.
	expect.equality(text, "Bonjour le monde deuxième")
end

T["ne lève pas sans sélection"] = function()
	expect.no_error(function()
		selected({ "" }, { 1, 0 }, { 1, 0 })
	end)
end

T["remove_syntax nettoie le markdown"] = function()
	config.setup({ remove_syntax = true, syntax_removal_method = "simple" })
	local text = selected({ "**gras** et `code`" }, { 1, 0 }, { 1, 17 }, "markdown")
	expect.equality(text:find("*", 1, true), nil)
	expect.equality(text:find("`", 1, true), nil)
end

T["sans remove_syntax le texte passe tel quel"] = function()
	config.setup({ remove_syntax = false })
	expect.equality(selected({ "**gras**" }, { 1, 0 }, { 1, 7 }, "markdown"), "**gras**")
end

return T
