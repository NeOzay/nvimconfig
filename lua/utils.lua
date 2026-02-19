local M = {}
local api = vim.api

---@param s string
---@return boolean
function M.is_blanc_line(s)
	return vim.trim(s) == ""
end

function M.current_line_is_blanc()
	return M.is_blanc_line(api.nvim_get_current_line())
end

M.keys_nb_map = {
	[1] = "&",
	[2] = "é",
	[3] = '"',
	[4] = "'",
	[5] = "(",
	[6] = "-",
	[7] = "è",
	[8] = "_",
	[9] = "ç",
	[0] = "à",
}

-- For AZERTY keyboards, return the corresponding key for a given number. For example, 1 returns "&", 2 returns "é", etc.
---@param nb integer
function M.key_nb_mapping(nb)
	return M.keys_nb_map[nb] or error("No mapping for number " .. nb)
end

M.statuscolumn = "%#normal# "

local hi_cache = {}

---@param fg string
---@param bg string
function M.hi_pathwork(fg, bg)
	local hi_key = fg .. "&" .. bg
	local new_hi = fg .. bg
	if hi_cache[hi_key] then
		return hi_cache[hi_key]
	end
	local main_hi = api.nvim_get_hl(0, { name = fg, link = false }) ---@as vim.api.keyset.highlight
	main_hi.bg = api.nvim_get_hl(0, { name = bg, link = false }).bg
	api.nvim_set_hl(0, new_hi, main_hi)
	hi_cache[hi_key] = new_hi
	return new_hi
end

Userautocmd("ColorScheme", {
	callback = function()
		for k in pairs(hi_cache) do
			local fg, bg = k:match("^(.*)&(.*)$")
			M.hi_pathwork(fg, bg)
		end
	end,
})

--- Get an icon from `mini.icons` or `nvim-web-devicons`.
---@param name string
---@param cat? "file"|"filetype"|"extension"|"directory"
---@param opts? { fallback?: {dir?:string, file?:string} }
---@return string, string?
function M.icon(name, cat, opts)
	opts = opts or {}
	opts.fallback = opts.fallback or {}
	---@type (fun():string, string?)[]
	local try = {
		function()
			---@diagnostic disable-next-line
			return MiniIcons.get(cat or "file", name)
		end,
		function()
			if cat == "directory" then
				return opts.fallback.dir or "󰉋 ", "Directory"
			end
			local Icons = require("nvim-web-devicons")
			if cat == "filetype" then
				return Icons.get_icon_by_filetype(name, { default = false })
			elseif cat == "file" then
				local ext = name:match("%.(%w+)$")
				return Icons.get_icon(name, ext, { default = false })
			elseif cat == "extension" then
				return Icons.get_icon(nil, name, { default = false })
			end
		end,
	}
	for _, fn in ipairs(try) do
		local ret = { pcall(fn) }
		if ret[1] and ret[2] then
			return ret[2], ret[3]
		end
	end
	return opts.fallback.file or "󰈔 "
end

return M
