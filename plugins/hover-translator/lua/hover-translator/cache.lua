---@namespace hover-translator

---@class Cache
local M = {}

---@type table<string, {text: string, expires: number}>
M._store = {}

---Generate a cache key (hash of content + language + traductor)
---@param content string
---@param target_lang string
---@param traductor string
---@return string
local function gen_key(content, target_lang, traductor)
	-- Simple hash using Neovim's built-in
	local combined = content .. "|" .. target_lang .. "|" .. traductor
	return vim.fn.sha256(combined)
end

---Retrieve a translation from cache (nil if absent or expired)
---@param content string
---@param target_lang string
---@param traductor string
---@return string|nil
function M.get(content, target_lang, traductor)
	local key = gen_key(content, target_lang, traductor)
	local entry = M._store[key]
	if not entry then
		return nil
	end

	-- Check if expired
	if os.time() > entry.expires then
		M._store[key] = nil
		return nil
	end

	return entry.text
end

---Store a translation in cache
---@param content string
---@param target_lang string
---@param traductor string
---@param ttl? number TTL in seconds (default from config)
function M.set(content, target_lang, traductor, ttl)
	local config = require("hover-translator.config")
	local key = gen_key(content, target_lang, traductor)
	ttl = ttl or config.cache.ttl

	M._store[key] = {
		text = content,
		expires = os.time() + ttl,
	}
end

---Clear the cache
function M.clear()
	M._store = {}
end

---Get cache statistics
---@return {entries: number, expired: number}
function M.stats()
	local entries = 0
	local expired = 0
	local now = os.time()

	for _, entry in pairs(M._store) do
		entries = entries + 1
		if now > entry.expires then
			expired = expired + 1
		end
	end

	return { entries = entries, expired = expired }
end

return M
