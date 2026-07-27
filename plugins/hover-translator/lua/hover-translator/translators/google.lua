---@namespace hover-translator

---@class Translator.google: Translator
local M = {}

M.name = "google"

---Translate text using Google Translate API
---@param text string
---@param target_lang string
---@param callback fun(result: Translator.Result)
function M.translate(text, target_lang, callback)
	local ok, curl = pcall(require, "plenary.curl")
	if not ok then
		callback({
			success = false,
			translated_text = nil,
			error = "plenary.nvim is required for HTTP requests",
		})
		return
	end

	-- Google Translate API endpoint
	local url = "https://translate.googleapis.com/translate_a/single"

	-- Build query parameters
	local params = {
		client = "gtx",
		sl = "auto", -- source language (auto-detect)
		tl = target_lang,
		dt = "t", -- return translation
		q = text,
	}

	-- URL encode the text
	local query_parts = {}
	for k, v in pairs(params) do
		local encoded_value = vim.uri_encode(tostring(v))
		table.insert(query_parts, k .. "=" .. encoded_value)
	end
	local full_url = url .. "?" .. table.concat(query_parts, "&")

	curl.get(full_url, {
		callback = vim.schedule_wrap(function(response)
			if response.status ~= 200 then
				callback({
					success = false,
					translated_text = nil,
					error = "HTTP error: " .. tostring(response.status),
				})
				return
			end

			-- Parse the JSON response
			local ok_decode, decoded = pcall(vim.json.decode, response.body)
			if not ok_decode then
				callback({
					success = false,
					translated_text = nil,
					error = "Failed to parse response JSON",
				})
				return
			end

			-- Extract translated text from response
			-- Response format: [[["translated text","original text",null,null,10],...],...]
			local translated_parts = {}
			if type(decoded) == "table" and type(decoded[1]) == "table" then
				for _, part in ipairs(decoded[1]) do
					if type(part) == "table" and type(part[1]) == "string" then
						table.insert(translated_parts, part[1])
					end
				end
			end

			if #translated_parts == 0 then
				callback({
					success = false,
					translated_text = nil,
					error = "No translation found in response",
				})
				return
			end

			callback({
				success = true,
				translated_text = table.concat(translated_parts, ""),
				error = nil,
			})
		end),
	})
end

return M
