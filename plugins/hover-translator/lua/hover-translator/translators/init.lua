---@namespace hover-translator

---@class Translator.Result
---@field success boolean
---@field translated_text string|nil
---@field error string|nil

---@class Translator
---@field name string -- unique name of the translator
---@field translate fun(text: string, target_lang: string, callback: fun(result: Translator.Result))

local M = {}

---@type table<string, Translator>
M._registry = {}

---Register a translator
---@param translator Translator
function M.register(translator)
	M._registry[translator.name] = translator
end

---Get a translator by name
---@param name string
---@return Translator|nil
function M.get(name)
	return M._registry[name]
end

---Get the configured translator
---@return Translator|nil
function M.get_configured()
	local config = require("hover-translator.config")
	return M.get(config.translator)
end

---List all registered translators
---@return string[]
function M.list()
	local names = {}
	for name, _ in pairs(M._registry) do
		table.insert(names, name)
	end
	return names
end

-- Auto-register built-in translators
local function setup_builtin()
	local google = require("hover-translator.translators.google")
	M.register(google)
end

setup_builtin()

return M
