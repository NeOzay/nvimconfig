---@namespace hover-translator
local M = {}

local config = require("hover-translator.config")
local cache = require("hover-translator.cache")
local translators = require("hover-translator.translators")
local parsers = require("hover-translator.parsers")

---Extract text content from LSP hover result
---@param result table LSP hover result
---@return string|nil
local function extract_hover_content(result)
	if not result or not result.contents then
		return nil
	end

	local contents = result.contents

	-- Handle different content formats
	if type(contents) == "string" then
		return contents
	elseif type(contents) == "table" then
		-- MarkupContent: { kind = "markdown"|"plaintext", value = "..." }
		if contents.value then
			return contents.value
		end

		-- MarkedString[]: array of strings or { language, value } objects
		if vim.islist(contents) then
			local parts = {}
			for _, item in ipairs(contents) do
				if type(item) == "string" then
					table.insert(parts, item)
				elseif type(item) == "table" and item.value then
					if item.language then
						table.insert(parts, "```" .. item.language)
						table.insert(parts, item.value)
						table.insert(parts, "```")
					else
						table.insert(parts, item.value)
					end
				end
			end
			return table.concat(parts, "\n")
		end
	end

	return nil
end

---Display hover content in a floating window
---@param content string
---@param opts? {border?: string}
local function display_hover(content, opts)
	opts = opts or {}
	---@cast opts -?
	local lines = vim.split(content, "\n")
	-- Use Neovim's built-in hover display
	vim.lsp.util.open_floating_preview(lines, "markdown", {
		border = opts.border or config.border,
		focus_id = "hover-translator",
	})
end

---Perform hover translation
---@param opts? {target_lang?: string, border?: string, translator?:string}
function M.hover_translate(opts)
	opts = opts or {}
	---@cast opts -?
	local target_lang = opts.target_lang or config.target_lang

	-- Get current buffer and position
	local bufnr = vim.api.nvim_get_current_buf()
	local first_client = vim.lsp.get_clients({ bufnr = 0 })[1]
	local offset_encoding = first_client and first_client.offset_encoding or "utf-16"
	local params = vim.lsp.util.make_position_params(nil, offset_encoding)

	-- Request hover from LSP
	vim.lsp.buf_request(bufnr, "textDocument/hover", params, function(err, result, ctx, _)
		if err then
			vim.notify("LSP hover error: " .. vim.inspect(err), vim.log.levels.ERROR)
			return
		end

		if not result then
			vim.notify("No information available", vim.log.levels.INFO)
			return
		end

		-- Extract content from hover result
		local content = extract_hover_content(result)
		if not content or content == "" then
			vim.notify("No hover content to translate", vim.log.levels.INFO)
			return
		end

		local translator = translators.get_configured()
		-- Get the configured translator
		if not translator then
			vim.notify("No translator configured: " .. config.translator, vim.log.levels.ERROR)
			display_hover(content, opts)
			return
		end

		-- Check cache first (if enabled)
		if config.cache.enabled then
			local cached = cache.get(content, target_lang, translator.name)
			if cached then
				display_hover(cached, opts)
				return
			end
		end

		-- Get the appropriate parser for the current filetype
		local filetype = vim.bo[bufnr].filetype
		local parser = parsers.get_for_filetype(filetype)

		-- Parse the content
		local parse_result = parser.parse(content)

		-- If nothing to translate, display as-is
		if not parse_result.translatable or parse_result.translatable:match("^%s*$") then
			display_hover(content, opts)
			return
		end

		-- Perform translation
		translator.translate(parse_result.translatable, target_lang, function(translation_result)
			if not translation_result.success then
				vim.notify("Translation failed: " .. (translation_result.error or "unknown error"), vim.log.levels.WARN)
				display_hover(content, opts)
				return
			end

			-- Reconstruct the hover with translated content
			local translated_content = parse_result.reconstruct(translation_result.translated_text)

			-- Cache the result (if enabled)
			if config.cache.enabled then
				cache.set(content, target_lang, translator.name)
			end

			-- Display the translated hover
			display_hover(translated_content, opts)
		end)
	end)
end

return M
