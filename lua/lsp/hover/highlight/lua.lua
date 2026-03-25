---@namespace Ozay.Hover
--- Tokenizer for Lua/EmmyLua signatures in hover code blocks.
local M = {}

-- stylua: ignore start
local KEYWORD_FN    = "@keyword.function"
local KEYWORD       = "@keyword"
local KEYWORD_OP    = "@keyword.operator"
local TYPE          = "@type"
local TYPE_BUILTIN  = "@type.builtin"
local FUNC          = "@function"
local VAR           = "@variable"
local VAR_MEMBER    = "@variable.member"
local VAR_PARAM     = "@variable.parameter"
local VAR_BUILTIN   = "@variable.builtin"
local STRING        = "@string"
local NUMBER        = "@number"
local BOOLEAN       = "@boolean"
local CONST_BUILTIN = "@constant.builtin"
local PUNCT_BRACKET = "@punctuation.bracket"
local PUNCT_DELIM   = "@punctuation.delimiter"
local PUNCT_SPECIAL = "@punctuation.special"
local OPERATOR      = "@operator"
-- stylua: ignore end

---@alias Token { [1]: integer, [2]: integer, [3]: string }

--- Word-boundary check: true if char at pos is NOT alphanumeric/underscore.
---@param line string
---@param pos integer  byte position (1-based) right after the candidate word
---@return boolean
local function at_word_boundary(line, pos)
	if pos > #line then
		return true
	end
	local c = line:byte(pos)
	-- [A-Za-z0-9_]
	return not ((c >= 65 and c <= 90) or (c >= 97 and c <= 122) or (c >= 48 and c <= 57) or c == 95)
end

---@class LuaTokenizer
---@field line string
---@field cursor integer  1-based position in line
---@field offset integer  column offset (for leading space)
---@field tokens Token[]
---@field context string  current context: "default"|"function"|"type"|"local"|"field"|"global"|"param_or_type"
---@field paren_depth integer
---@field angle_depth integer
local T = {}
T.__index = T

---@param line string
---@param offset integer
---@return LuaTokenizer
function T.new(line, offset)
	return setmetatable({
		line = line,
		cursor = offset + 1, -- skip leading space
		offset = offset,
		tokens = {},
		context = "default",
		paren_depth = 0,
		angle_depth = 0,
		brace_depth = 0,
	}, T)
end

--- Remaining portion of the line from cursor.
---@return string
function T:rest()
	return self.line:sub(self.cursor)
end

--- Column position (0-based) for extmarks.
---@return integer
function T:col()
	return self.cursor - 1
end

--- Try to match a Lua pattern at the start of rest(). Returns match or nil.
---@param pat string
---@return string?
function T:try(pat)
	return self:rest():match("^" .. pat)
end

--- Emit a token and advance cursor.
---@param len integer  length in bytes
---@param hl string    highlight group
function T:emit(len, hl)
	table.insert(self.tokens, { self:col(), self:col() + len, hl })
	self.cursor = self.cursor + len
end

--- Skip n bytes without emitting.
---@param n integer
function T:skip(n)
	self.cursor = self.cursor + n
end

--- Try to match a keyword with word boundary. Returns length or nil.
---@param word string
---@return integer?
function T:try_keyword(word)
	local rest = self:rest()
	if rest:sub(1, #word) == word and at_word_boundary(rest, #word + 1) then
		return #word
	end
end

--- Look ahead from current cursor to check if identifier is followed by `:` or `?:`.
---@param id_len integer  length of identifier
---@return boolean
function T:is_param_lookahead(id_len)
	local after = self.line:sub(self.cursor + id_len)
	return after:match("^%s*%?*:") ~= nil
end

--- Process a parenthesized label like (field), (global), etc.
---@return boolean  true if matched
function T:try_label()
	local label = self:try("%((%a+)%)")
	if not label then
		return false
	end

	local labels = { field = true, global = true, method = true, class = true, alias = true, enum = true }
	if not labels[label] then
		return false
	end

	local full_len = #label + 2 -- including parens
	self:emit(full_len, KEYWORD)

	if label == "field" then
		self.context = "field"
	elseif label == "global" then
		self.context = "global"
	elseif label == "method" then
		self.context = "method"
	else
		self.context = "type"
	end
	return true
end

--- Resolve highlight for the tail segment (or a standalone identifier) based on context.
---@param full_len integer  total length of the full dotted identifier (for look-ahead)
---@return string hl
---@return boolean reset  whether to reset context to "default" after
function T:resolve_tail_hl(full_len)
	local ctx = self.context

	if ctx == "function" then
		return FUNC, true
	elseif ctx == "type" then
		if self:is_param_lookahead(full_len) then
			return self.brace_depth > 0 and VAR_MEMBER or VAR, false
		end
		return TYPE, false
	elseif ctx == "local" then
		return VAR, true
	elseif ctx == "field" then
		return VAR_MEMBER, true
	elseif ctx == "global" then
		return VAR, true
	elseif ctx == "method" then
		return VAR, false
	elseif self.paren_depth > 0 and self:is_param_lookahead(full_len) then
		return VAR_PARAM, false
	elseif self.angle_depth > 0 then
		return TYPE, false
	end
	return VAR, false
end

--- Process an identifier with context-dependent highlighting.
--- Dotted identifiers (a.b.c) are split: a=@variable, b=@variable.member, c=context-dependent.
function T:process_identifier()
	local full = self:try("[%a_][%w_%.]*")
	if not full then
		return false
	end

	local segments = vim.split(full, ".", { plain = true })

	if #segments == 1 then
		local hl, reset = self:resolve_tail_hl(#full)
		self:emit(#full, hl)
		if reset then
			self.context = "default"
		end
	else
		local tail_hl, reset = self:resolve_tail_hl(#full)
		local in_type = self.context == "type" or self.angle_depth > 0
		for i, seg in ipairs(segments) do
			if i > 1 then
				self:emit(1, PUNCT_DELIM) -- dot
			end
			if in_type then
				self:emit(#seg, TYPE)
			elseif i == 1 then
				self:emit(#seg, VAR)
			elseif i < #segments then
				self:emit(#seg, VAR_MEMBER)
			else
				self:emit(#seg, tail_hl)
			end
		end
		if reset then
			self.context = "default"
		end
	end

	return true
end

--- Main tokenize loop.
---@return Token[]
function T:tokenize()
	while self.cursor <= #self.line do
		-- 1. Whitespace
		local ws = self:try("%s+")
		if ws then
			self:skip(#ws)
			goto continue
		end

		-- 2. Strings
		local str = self:try('"[^"]*"') or self:try("'[^']*'")
		if str then
			self:emit(#str, STRING)
			goto continue
		end

		-- 3. Varargs
		if self:try("%.%.%.") then
			self:emit(3, PUNCT_SPECIAL)
			goto continue
		end

		-- 4. Arrow
		if self:try("%->") then
			self:emit(2, KEYWORD_OP)
			self.context = "type"
			goto continue
		end

		-- 5. Keywords
		local kw_len

		kw_len = self:try_keyword("function")
		if kw_len then
			self:emit(kw_len, KEYWORD_FN)
			self.context = "function"
			goto continue
		end

		kw_len = self:try_keyword("fun")
		if kw_len then
			self:emit(kw_len, FUNC)
			self.context = "default"
			goto continue
		end

		kw_len = self:try_keyword("async") or self:try_keyword("sync")
		if kw_len then
			self:emit(kw_len, KEYWORD)
			goto continue
		end

		kw_len = self:try_keyword("local")
		if kw_len then
			self:emit(kw_len, KEYWORD)
			self.context = "local"
			goto continue
		end

		kw_len = self:try_keyword("return")
			or self:try_keyword("end")
			or self:try_keyword("if")
			or self:try_keyword("then")
			or self:try_keyword("else")
			or self:try_keyword("elseif")
			or self:try_keyword("for")
			or self:try_keyword("in")
			or self:try_keyword("do")
			or self:try_keyword("while")
			or self:try_keyword("repeat")
			or self:try_keyword("until")
		if kw_len then
			self:emit(kw_len, KEYWORD)
			goto continue
		end

		-- 6. Booleans
		kw_len = self:try_keyword("true") or self:try_keyword("false")
		if kw_len then
			self:emit(kw_len, BOOLEAN)
			goto continue
		end

		-- 7. nil
		kw_len = self:try_keyword("nil")
		if kw_len then
			self:emit(kw_len, CONST_BUILTIN)
			goto continue
		end

		-- 8. self
		kw_len = self:try_keyword("self")
		if kw_len then
			self:emit(kw_len, VAR_BUILTIN)
			goto continue
		end

		-- 9. Builtin types
		for _, bt in ipairs({ "integer", "string", "boolean", "number", "table", "any", "thread", "userdata" }) do
			kw_len = self:try_keyword(bt)
			if kw_len then
				self:emit(kw_len, TYPE_BUILTIN)
				goto continue
			end
		end

		-- 10. Labels: (field), (global), etc.
		if self:try_label() then
			goto continue
		end

		-- 11. Numbers
		local num = self:try("%d+%.?%d*")
		if num then
			self:emit(#num, NUMBER)
			goto continue
		end

		-- 12. Punctuation
		local ch = self.line:sub(self.cursor, self.cursor)

		if ch == "(" then
			self.paren_depth = self.paren_depth + 1
			self:emit(1, PUNCT_BRACKET)
			if self.context ~= "type" then
				self.context = "default"
			end
			goto continue
		end

		if ch == ")" then
			self.paren_depth = math.max(0, self.paren_depth - 1)
			self:emit(1, PUNCT_BRACKET)
			goto continue
		end

		if ch == "{" then
			self.brace_depth = self.brace_depth + 1
			self:emit(1, PUNCT_BRACKET)
			goto continue
		end

		if ch == "}" then
			self.brace_depth = math.max(0, self.brace_depth - 1)
			self:emit(1, PUNCT_BRACKET)
			goto continue
		end

		if ch == "[" or ch == "]" then
			self:emit(1, PUNCT_BRACKET)
			goto continue
		end

		if ch == "<" then
			self.angle_depth = self.angle_depth + 1
			self:emit(1, PUNCT_BRACKET)
			goto continue
		end

		if ch == ">" then
			self.angle_depth = math.max(0, self.angle_depth - 1)
			self:emit(1, PUNCT_BRACKET)
			goto continue
		end

		if ch == "," or ch == ";" then
			self:emit(1, PUNCT_DELIM)
			if self.paren_depth > 0 then
				self.context = "default"
			elseif self.context ~= "type" and self.angle_depth == 0 then
				self.context = "default"
			end
			goto continue
		end

		if ch == ":" then
			self:emit(1, PUNCT_DELIM)
			self.context = self.context == "method" and "function" or "type"
			goto continue
		end

		if ch == "|" then
			self:emit(1, KEYWORD_OP)
			goto continue
		end

		if ch == "?" then
			self:emit(1, PUNCT_SPECIAL)
			goto continue
		end

		if ch == "=" then
			self:emit(1, OPERATOR)
			self.context = "default"
			goto continue
		end

		-- 13. Identifiers (context-dependent)
		if self:process_identifier() then
			goto continue
		end

		-- Fallback: skip unknown char
		self:skip(1)

		::continue::
	end

	return self.tokens
end

--- Highlight lua code block lines with extmarks.
---@param bufnr integer
---@param ns integer  namespace id
---@param start_line integer  0-indexed, first content line
---@param end_line integer  0-indexed, exclusive
function M.highlight(bufnr, ns, start_line, end_line)
	local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)

	-- Carry state across lines within the same code block
	local carry = { context = "default", paren_depth = 0, angle_depth = 0, brace_depth = 0 }

	for i, line in ipairs(lines) do
		local row = start_line + i - 1
		local tokenizer = T.new(line, 1) -- offset 1 for leading space
		tokenizer.context = carry.context
		tokenizer.paren_depth = carry.paren_depth
		tokenizer.angle_depth = carry.angle_depth
		tokenizer.brace_depth = carry.brace_depth

		local tokens = tokenizer:tokenize()

		carry.context = tokenizer.context
		carry.paren_depth = tokenizer.paren_depth
		carry.angle_depth = tokenizer.angle_depth
		carry.brace_depth = tokenizer.brace_depth

		for _, tok in ipairs(tokens) do
			vim.api.nvim_buf_set_extmark(bufnr, ns, row, tok[1], {
				end_col = tok[2],
				hl_group = tok[3],
				priority = 200,
			})
		end
	end
end

return M
