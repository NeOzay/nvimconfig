---@namespace hover-translator

---@class Parser.generic:Parser
local M = {}

M.name = "generic"

---Check if a line is a separator (horizontal rule)
---@param line string
---@return boolean
local function is_separator(line)
	-- Match lines that are mostly dashes, underscores, or box-drawing chars
	return line:match("^[─━%-_=]+$") ~= nil or line:match("^%s*[─━%-_=]+%s*$") ~= nil
end

---Check if a line looks like a function signature
---@param line string
---@return boolean
local function is_signature(line)
	-- Function signatures typically contain:
	-- - function keyword
	-- - arrow return types (->)
	-- - parentheses with parameters
	-- - type annotations with colons
	local patterns = {
		"^%s*function%s+", -- function keyword
		"^%s*[%w_%.]+%s*%(", -- name followed by (
		"->%s*[%w_<>%[%]|]+%s*$", -- arrow return type at end
		"^%s*[%w_%.]+%s*:%s*[%w_<>%[%]|%(%)]+", -- type annotation
		"^```", -- code block start
	}

	for _, pattern in ipairs(patterns) do
		if line:match(pattern) then
			return true
		end
	end

	return false
end

---Check if we're inside a code block
---@param line string
---@param in_code_block boolean
---@return boolean
local function toggle_code_block(line, in_code_block)
	if line:match("^```") then
		return not in_code_block
	end
	return in_code_block
end

---Parse hover content to separate preserved and translatable parts
---@param content string
---@return Parser.Result
function M.parse(content)
	local lines = vim.split(content, "\n")
	local preserved_indices = {} -- Track which lines are preserved
	local preserved = {}
	local translatable_lines = {}
	local in_code_block = false
	local found_separator = false

	for i, line in ipairs(lines) do
		-- Track code blocks
		local was_in_code_block = in_code_block
		in_code_block = toggle_code_block(line, in_code_block)

		-- Determine if this line should be preserved
		local should_preserve = false

		if line:match("^```") then
			-- Code block markers are preserved
			should_preserve = true
		elseif in_code_block or was_in_code_block then
			-- Content inside code blocks is preserved
			should_preserve = true
		elseif is_separator(line) then
			-- Separators are preserved
			should_preserve = true
			found_separator = true
		elseif not found_separator and is_signature(line) then
			-- First block (before separator) that looks like a signature
			should_preserve = true
		elseif line:match("^%s*$") then
			-- Empty lines are preserved as structure
			should_preserve = true
		end

		if should_preserve then
			preserved_indices[i] = true
			table.insert(preserved, line)
		else
			table.insert(translatable_lines, line)
		end
	end

	local translatable = table.concat(translatable_lines, "\n")

	---Reconstruct the hover with translated text
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
