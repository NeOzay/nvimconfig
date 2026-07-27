---@mod hover-translator Neovim plugin to translate LSP hover responses
---@brief [[
---hover-translator is a Neovim plugin that translates LSP hover documentation
---to your preferred language using various translation services.
---
---Features:
---- Translates hover documentation while preserving function signatures
---- Configurable translation service (Google Translate by default)
---- Caching system to avoid redundant API calls
---- Support for custom parsers per filetype
---@brief ]]

---@namespace hover-translator

local M = {}

local config = require("hover-translator.config")
local hover = require("hover-translator.hover")
local cache = require("hover-translator.cache")

---Setup hover-translator with user configuration
---@param opts? Partial<config>
function M.setup(opts)
	config.setup(opts)

	-- Register user commands
	vim.api.nvim_create_user_command("HoverTranslate", function(cmd_opts)
		local call_opts = {}
		-- Parse optional language argument
		if cmd_opts.args and cmd_opts.args ~= "" then
			call_opts.target_lang = cmd_opts.args
		end
		M.hover_translate(call_opts)
	end, {
		nargs = "?",
		desc = "Translate hover documentation",
	})

	vim.api.nvim_create_user_command("HoverTranslateClearCache", function()
		cache.clear()
		vim.notify("Hover translator cache cleared", vim.log.levels.INFO)
	end, {
		desc = "Clear hover translation cache",
	})
end

---Translate hover at current cursor position
---@param opts? {target_lang?: string, border?: string}
function M.hover_translate(opts)
	hover.hover_translate(opts)
end

---Clear the translation cache
function M.clear_cache()
	cache.clear()
end

---Get cache statistics
---@return {entries: number, expired: number}
function M.cache_stats()
	return cache.stats()
end

return M
