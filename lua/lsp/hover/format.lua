---@namespace Ozay.Hover
local M = {}

local HTML_ENTITIES = {
	["&nbsp;"] = " ",
	["&gt;"] = ">",
	["&lt;"] = "<",
	["&amp;"] = "&",
	["&quot;"] = '"',
	["&apos;"] = "'",
	["&mdash;"] = "—",
	["&ndash;"] = "–",
	["&hellip;"] = "…",
	["&laquo;"] = "«",
	["&raquo;"] = "»",
	["\u{00A0}"] = " ", -- NBSP unicode
	["\u{202F}"] = " ", -- narrow NBSP unicode
}

---@param line string
---@return string
local function decode_html_entities(line)
	-- Entités nommées
	line = line:gsub("&%a+;", HTML_ENTITIES)
	-- Entités numériques décimales (ex: &#160;)
	line = line:gsub("&#(%d+);", function(n)
		local _n = tonumber(n)
		if not _n then
			return "&#" .. n .. ";"
		end
		return vim.fn.nr2char(math.floor(_n))
	end)
	-- Entités numériques hexadécimales (ex: &#x00A0;)
	line = line:gsub("&#x(%x+);", function(h)
		local _h = tonumber(h, 16)
		if not _h then
			return "&#x" .. h .. ";"
		end
		return vim.fn.nr2char(math.floor(_h))
	end)
	-- Espaces insécables unicode résiduels
	for entity, replacement in pairs(HTML_ENTITIES) do
		if entity:sub(1, 1) ~= "&" then
			line = line:gsub(entity, replacement)
		end
	end

	local _, _, broken_fence = line:find("^%s*``(%w*)$")
	if broken_fence ~= nil then
		line = "```" .. (broken_fence or "")
	end

	return line
end

---@param line string
---@return boolean
local function is_fence(line)
	return line:match("^```") ~= nil or line:match("^~~~") ~= nil
end

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
		if current == "" then
			return
		end
		result[#result + 1] = current
		current = ""
	end

	for _, line in ipairs(lines) do
		if is_fence(line) then
			flush()
			in_code_block = not in_code_block
			result[#result + 1] = line
		elseif in_code_block then
			result[#result + 1] = line:gsub("\\([^\\])", "%1") -- déséchapper les backslashes dans les blocs de code
		elseif line:match("^%s*$") then
			flush()
			result[#result + 1] = ""
		elseif line:match("^%s*[%w\\_]+:") or is_markdown_block(line) then
			flush()
			result[#result + 1] = line
		else
			current = current == "" and line or (current .. " " .. line:gsub("^%s+", ""))
			if ends_sentence(line) then
				flush()
			end
		end
	end

	if current ~= "" then
		result[#result + 1] = current
	end

	return result
end

---@param lines string[]
---@return string[]
local function decode_lines(lines)
	local result = {}
	for _, line in ipairs(lines) do
		result[#result + 1] = decode_html_entities(line)
	end
	return result
end

--- Convertit `|word|` en inline code, en ignorant les blocs fencés.
---@param lines string[]
---@return string[]
local function convert_vimhelp_links(lines)
	local result = {}
	local in_code_block = false
	for _, line in ipairs(lines) do
		if is_fence(line) then
			in_code_block = not in_code_block
			result[#result + 1] = line
		elseif in_code_block then
			result[#result + 1] = line
		else
			result[#result + 1] = line:gsub("|([^|%s]+)|", "`%1`")
		end
	end
	return result
end

---@param result string[]
---@param before string
---@param lang string
---@return true
local function vimhelp_open(result, before, lang)
	if before:match("%S") then
		result[#result + 1] = before
	end
	result[#result + 1] = "```" .. lang
	return true
end

--- Détecte un marqueur d'ouverture Vim help sur `line`.
--- Valide uniquement `>lang` en début de ligne ou après `:`.
---@param line string
---@return string? before
---@return string? lang
local function vimhelp_block_start(line)
	local lang = line:match("^%s*>(%w*)%s*$")
	if lang ~= nil then
		return "", lang
	end
	return line:match("^(.+:%s*)>(%w*)%s*$")
end

--- Détecte un marqueur de fermeture Vim help.
--- `<` seul, `< contenu`, ou `<texte: >lang` (close+reopen).
---@param line string
---@return boolean
local function is_vimhelp_close(line)
	if line:match("^<$") or line:match("^<%s") then
		return true
	end
	local rest = line:match("^<(.+)$")
	return rest ~= nil and rest:match("^.+:%s*>%w*%s*$") ~= nil
end

--- Convertit les blocs Vim help (`>lang ... <`) en blocs fencés markdown.
---@param lines string[]
---@return string[]
local function convert_vimhelp_blocks(lines)
	local result = {}
	local in_block = false
	for _, line in ipairs(lines) do
		if not in_block then
			local before, lang = vimhelp_block_start(line)
			if before ~= nil then
				in_block = vimhelp_open(result, before, lang)
			else
				result[#result + 1] = line
			end
		elseif not is_vimhelp_close(line) then
			result[#result + 1] = line
		else
			result[#result + 1] = "```"
			in_block = false
			local rest = line:match("^<(.+)$")
			if rest and rest:match("%S") then
				local before, lang = rest:match("^(.-)%s*>(%w*)%s*$")
				lang = lang or ""
				if before ~= nil then
					in_block = vimhelp_open(result, before, lang)
				else
					result[#result + 1] = rest
				end
			end
		end
	end
	if in_block then
		result[#result + 1] = "```"
	end
	return result
end

--- Avance dans `text` depuis `start` en consommant jusqu'à `width` colonnes visuelles.
--- Gère les échappements Markdown \X (1 colonne), les caractères UTF-8 multi-octets,
--- et les caractères à ignorer (largeur nulle, ex: backtick Markdown).
---@param text string
---@param start integer          position en octets (1-indexed)
---@param width integer          nombre de colonnes cibles
---@param skip_chars? table<string, true>  ensemble de caractères à ignorer (largeur 0)
---@return integer end_pos   premier octet non consommé
---@return integer consumed  colonnes visuelles effectivement consommées
local function advance_cols(text, start, width, skip_chars)
	local pos = start
	local cols = 0
	local n = #text
	while pos <= n do
		local ch = text:sub(pos, pos)
		if skip_chars and skip_chars[ch] then
			-- Caractère ignoré : aucune colonne consommée
			pos = pos + 1
		elseif ch == "\\" and pos + 1 <= n and text:sub(pos + 1, pos + 1):match("[%p]") then
			-- Échappement Markdown \X : seul X est affiché
			local w = vim.fn.strdisplaywidth(text:sub(pos + 1, pos + 1))
			if cols + w > width then
				break
			end
			cols = cols + w
			pos = pos + 2
		else
			-- Caractère UTF-8 (longueur selon le premier octet)
			local b = text:byte(pos)
			local clen = b >= 0xF0 and 4 or b >= 0xE0 and 3 or b >= 0xC0 and 2 or 1
			local w = vim.fn.strdisplaywidth(text:sub(pos, pos + clen - 1))
			if cols + w > width then
				break
			end
			cols = cols + w
			pos = pos + clen
		end
	end
	return pos, cols
end

---@param chunk string
---@param breakset table<string, true>
---@return integer?
local function find_break_pos(chunk, breakset)
	for i = #chunk, 1, -1 do
		if breakset[chunk:sub(i, i)] then
			return i
		end
	end
end

---@param text_list string[]
---@param width integer
---@param opts? { linebreak?: boolean, breakat?: string, skip_chars?: table<string, true> }
---@return string[]
local function wrap_string(text_list, width, opts)
	opts = opts or {}

	local linebreak = opts.linebreak ~= false
	local breakat = opts.breakat or " \t!@*-+;:,./? "
	local skip_chars = opts.skip_chars or { ["`"] = true }

	local lines = {}

	local breakset = {}
	for c in breakat:gmatch(".") do
		breakset[c] = true
	end

	for _, text in ipairs(text_list) do
		if text:match("^%s*$") then
			lines[#lines + 1] = ""
		else
			local pos = 1
			local n = #text
			while pos <= n do
				local end_byte, consumed = advance_cols(text, pos, width, skip_chars)
				local chunk = text:sub(pos, end_byte - 1)

				if consumed < width then
					-- Fin du texte : le reste tient dans la largeur
					lines[#lines + 1] = chunk
					break
				end

				local break_pos = linebreak and find_break_pos(chunk, breakset)
				if break_pos then
					lines[#lines + 1] = chunk:sub(1, break_pos)
					pos = pos + break_pos
				else
					lines[#lines + 1] = chunk
					pos = end_byte
				end

				-- Saute les espaces en début du prochain chunk
				while pos <= n and text:sub(pos, pos):match("%s") do
					pos = pos + 1
				end
			end
		end
	end

	for i, line in ipairs(lines) do
		local s = vim.trim(line)
		if not vim.startswith(s, "-") and not vim.startswith(s, "*") then
			lines[i] = " " .. line
		end
	end

	return lines
end

--- Largeur visuelle d'une ligne Markdown après rendu :
--- - escapes \X → X
--- - liens [texte](url) → texte
--- - gras **texte** → texte
--- - italique *texte* → texte
--- - backticks inline supprimés
---@param line string
---@return integer
function M.visual_width(line)
	line = line:gsub("\\([%p])", "%1")
	line = line:gsub("%[(.-)%]%b()", "%1") -- liens Markdown
	line = line:gsub("%*%*(.-)%*%*", "%1") -- gras
	line = line:gsub("%*(.-)%*", "%1") -- italique
	line = line:gsub("`", "")
	return vim.fn.strdisplaywidth(line)
end

---@param ss string[]
---@param max_width integer
function M.format_string(ss, max_width)
	local formatted = {}
	local wrapped =
		wrap_string(join_sentence_lines(convert_vimhelp_links(convert_vimhelp_blocks(decode_lines(ss)))), max_width)

	for i, s in ipairs(wrapped) do
		local next = wrapped[i + 1] or ""
		local is_double_blank = vim.trim(s) == "" and (vim.trim(next) == "" or next:find("^---$"))
		if not is_double_blank then
			formatted[#formatted + 1] = s:find("^%s*---$") and " ___" or s
		end
	end

	return formatted
end

return M
