---@namespace hover-translator

---@class Parser.Result
---@field preserved string[] Lines to preserve (signatures, code)
---@field translatable string Text to translate
---@field reconstruct fun(translated: string): string Reconstruct the final hover

---@class Parser
---@field name string
---@field parse fun(content: string): Parser.Result

---@class ParserRegistry
local M = {}

---@type table<string, Parser>
M._registry = {}

---Register a parser
---@param name string
---@param parser Parser
function M.register(name, parser)
	M._registry[name] = parser
end

---Get a parser by name
---@param name string
---@return Parser|nil
function M.get(name)
	return M._registry[name]
end

---Get the appropriate parser for a filetype
---@param filetype? string
---@return Parser
function M.get_for_filetype(filetype)
	-- Try filetype-specific parser first
	if filetype and M._registry[filetype] then
		return M._registry[filetype]
	end
	-- Fallback to generic parser
	return M._registry["generic"]
end

---List all registered parsers
---@return string[]
function M.list()
	local names = {}
	for name, _ in pairs(M._registry) do
		table.insert(names, name)
	end
	return names
end

-- Auto-register built-in parsers
local function setup_builtin()
	local generic = require("hover-translator.parsers.generic")
	M.register("generic", generic)

	local lua_parser = require("hover-translator.parsers.lua")
	M.register("lua", lua_parser)
end

setup_builtin()

return M
