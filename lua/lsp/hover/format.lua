---@namespace Ozay.Hover
local M = {}

local function is_markdown_block(line)
	local trimmed = line:match("^%s*(.-)%s*$")

	return trimmed:match("^#") -- headings
		or trimmed:match("^[-*+] ") -- bullet list
		or trimmed:match("^%d+%. ") -- ordered list
		or trimmed:match("^>") -- blockquote
		or trimmed:match("^```") -- fenced code
		or trimmed:match("^~~~") -- fenced code alt
		or trimmed:match("^|") -- tables
		or trimmed:match("^%-%-%-$") -- horizontal rule
		or trimmed:match("^%*%*%*$")
		or trimmed:match("^<.+>$") -- HTML block-ish
end

local function ends_sentence(line)
	return line:match("[%.%!%?%;:`]%s*$") ~= nil
end

local function join_sentence_lines(lines)
	local result = {}
	local current = ""
	local in_code_block = false

	local function flush()
		if current == "" then return end
		table.insert(result, current)
		current = ""
	end

	for _, line in ipairs(lines) do
		if line:match("^```") or line:match("^~~~") then
			flush()
			in_code_block = not in_code_block
			table.insert(result, line)
			goto continue
		end

		if in_code_block then
			table.insert(result, line)
			goto continue
		end

		if line:match("^%s*$") then
			flush()
			table.insert(result, "")
			goto continue
		end

		if is_markdown_block(line) then
			flush()
			table.insert(result, line)
			goto continue
		end

		current = current == "" and line or (current .. " " .. line:gsub("^%s+", ""))
		if ends_sentence(line) then
			flush()
		end

		::continue::
	end

	if current ~= "" then
		table.insert(result, current)
	end

	return result
end

---@param text_list string[]
---@param width integer
---@param opts? { linebreak?: boolean, breakat?: string }
---@return string[]
local function wrap_string(text_list, width, opts)
	opts = opts or {}

	local linebreak = opts.linebreak ~= false
	local breakat = opts.breakat or " \t!@*-+;:,./?"
	local displaywidth = vim.fn.strdisplaywidth

	local lines = {}

	local breakset = {}
	for c in breakat:gmatch(".") do
		breakset[c] = true
	end

	local in_code_block = false

	for _, text in ipairs(text_list) do
		if text:match("^```") or text:match("^~~~") then
			in_code_block = not in_code_block
			table.insert(lines, text)
			goto continue
		end

		if in_code_block then
			table.insert(lines, text)
			goto continue
		end

		local pos = 1
		while pos <= #text do
			local chunk = text:sub(pos, pos + width - 1)

			if displaywidth(chunk) < width then
				table.insert(lines, chunk)
				break
			end

			local break_pos = nil

			if linebreak then
				for i = #chunk, 1, -1 do
					if breakset[chunk:sub(i, i)] then
						break_pos = i
						break
					end
				end
			end

			table.insert(lines, chunk:sub(1, break_pos or width))

			pos = pos + (break_pos or width)
			while text:sub(pos, pos):match("%s") do
				pos = pos + 1
			end
		end

		::continue::
	end

	return lines
end

---@param ss string[]
---@param max_width integer
function M.format_string(ss, max_width)
	local trim = vim.trim
	local wrapped = wrap_string(join_sentence_lines(ss), max_width)

	local formatted = {}
	for i, s in ipairs(wrapped) do
		if trim(s) == "" and (trim(wrapped[i + 1] or "") == "" or (wrapped[i + 1] or ""):find("^---$")) then
			goto continue
		end

		local line = s
			:gsub("&nbsp;", " ") -- HTML entity
			:gsub("\u{00A0}", " ") -- vrai NBSP
			:gsub("\u{202F}", " ") -- narrow NBSP
		if line:find("^---$") then
			line = "___"
		elseif not line:find("^```") then
			line = " " .. line
		end
		table.insert(formatted, line)
		::continue::
	end

	return formatted
end

return M
