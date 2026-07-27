---@namespace hover-translator
---@class Parser.lua: Parser
local M = {}

M.name = "lua"

---Check if a line is a separator (horizontal rule)
---@param line string
---@return boolean
local function is_separator(line)
	return line:match("^[─━%-_=]+$") ~= nil or line:match("^%s*[─━%-_=]+%s*$") ~= nil
end

---Check if a line is a Lua/Neovim function signature
---@param line string
---@return boolean
local function is_lua_signature(line)
	local patterns = {
		"^%s*function%s+", -- function keyword
		"^%s*local%s+function", -- local function
		"^%s*[%w_%.]+%s*%(.*%)%s*$", -- name(...) on its own
		"^%s*[%w_%.]+%s*%(.*%)%s*%->", -- name(...) -> return
		"^%s*[%w_%.]+%s*:%s*function", -- method: function
		"^%s*%->%s*[%w_<>%[%]|,%(%)%s]+$", -- just return type
		"^```", -- code block
	}

	for _, pattern in ipairs(patterns) do
		if line:match(pattern) then
			return true
		end
	end

	return false
end

---Check if a line is a Lua type annotation or parameter doc
---@param line string
---@return boolean
local function is_annotation_line(line)
	-- Lines starting with @ are annotations but should be translated
	-- unless they're type-only annotations
	if line:match("^%s*@%w+%s+[%w_]+%s*$") then
		-- @param name (no description) - preserve
		return true
	end
	return false
end

---Parse Lua hover content
---@param content string
---@return Parser.Result
function M.parse(content)
	local lines = vim.split(content, "\n")
	local preserved_indices = {}
	local preserved = {}
	local translatable_lines = {}
	local in_code_block = false
	local header_section = true -- We're in the signature/header section

	for i, line in ipairs(lines) do
		-- Track code blocks
		if line:match("^```") then
			in_code_block = not in_code_block
			preserved_indices[i] = true
			table.insert(preserved, line)
		elseif in_code_block then
			-- Everything in code blocks is preserved
			preserved_indices[i] = true
			table.insert(preserved, line)
		elseif is_separator(line) then
			-- Separator marks end of header section
			header_section = false
			preserved_indices[i] = true
			table.insert(preserved, line)
		elseif header_section and is_lua_signature(line) then
			-- Signatures in header are preserved
			preserved_indices[i] = true
			table.insert(preserved, line)
		elseif line:match("^%s*$") then
			-- Empty lines preserved for structure
			preserved_indices[i] = true
			table.insert(preserved, line)
		elseif is_annotation_line(line) then
			-- Type-only annotations preserved
			preserved_indices[i] = true
			table.insert(preserved, line)
		else
			-- Everything else is translatable
			table.insert(translatable_lines, line)
		end
	end

	local translatable = table.concat(translatable_lines, "\n")

	---Reconstruct with translated content
	---@param translated string
	---@return string
	local function reconstruct(translated)
		local translated_lines = vim.split(translated, "\n")
		local translated_idx = 1
		local result = {}

		for i, line in ipairs(lines) do
			if preserved_indices[i] then
				table.insert(result, line)
			else
				if translated_idx <= #translated_lines then
					table.insert(result, translated_lines[translated_idx])
					translated_idx = translated_idx + 1
				end
			end
		end

		return table.concat(result, "\n")
	end

	return {
		preserved = preserved,
		translatable = translatable,
		reconstruct = reconstruct,
	}
end

return M
