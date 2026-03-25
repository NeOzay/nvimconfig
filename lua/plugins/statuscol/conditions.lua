local M = {}

---@class Ozay.Statuscol.ConditionSpec
---@field ft_blacklist? table<string, true>
---@field ft_whitelist? table<string, true>
---@field require_number? boolean
---@field require_file? boolean
---@field suppress_inactive? boolean
---@field ignore_float_win? boolean
---@field buf_predicate? fun(bufnr: integer): boolean
---@field win_predicate? fun(winid: integer): boolean
---@field predicate? fun(args: Ozay.Statuscol.text.arg): boolean
---@field enabled? boolean|fun(): boolean

M.ft_ignore = {
	Avante = true,
	AvanteInput = true,
	help = true,
	["neo-tree"] = true,
	codecompanion = true,
	snacks_terminal = true,
}

M.ft_padding = { help = true, checkhealth = true, snacks_terminal = true }
M.ft_scrolloff = { help = true, checkhealth = true }

--- Evalue un ConditionSpec contre les arguments statuscol.
---@param spec Ozay.Statuscol.ConditionSpec
---@param args Ozay.Statuscol.text.arg
---@return boolean
function M.evaluate(spec, args)
	if spec.enabled ~= nil then
		local enabled = type(spec.enabled) == "function" and spec.enabled() or spec.enabled
		if not enabled then
			return false
		end
	end

	local ft = vim.bo[args.buf].filetype

	if spec.ignore_float_win then
		local opts = vim.api.nvim_win_get_config(args.win)
		if opts.relative ~= "" then
			return false
		end
	end

	if spec.ft_blacklist and spec.ft_blacklist[ft] then
		return false
	end

	if spec.ft_whitelist and not spec.ft_whitelist[ft] then
		return false
	end

	if spec.require_number ~= false and not vim.wo.number then
		return false
	end

	if spec.require_file and vim.bo[args.buf].buftype == "nofile" then
		return false
	end

	if spec.buf_predicate and not spec.buf_predicate(args.buf) then
		return false
	end

	if spec.win_predicate and not spec.win_predicate(args.win) then
		return false
	end

	if spec.predicate and not spec.predicate(args) then
		return false
	end

	return true
end

--- Retourne une table condition compatible avec statuscol.
---@param spec Ozay.Statuscol.ConditionSpec
---@return table
function M.make_condition(spec)
	return {
		function(args)
			return M.evaluate(spec, args)
		end,
	}
end

--- Configure l'autocmd pour les options de fenetre selon le filetype.
function M.setup_win_autocmd()
	Userautocmd({ "FileType", "WinEnter", "BufWinEnter" }, {
		callback = function(args)
			local w = vim.api.nvim_get_current_win()
			local wo = vim.wo[w]
			local bo = vim.bo[args.buf]
			vim.defer_fn(function()
				if not vim.api.nvim_buf_is_loaded(args.buf) or not vim.api.nvim_win_is_valid(w) then
					return
				end
				local cfg = vim.api.nvim_win_get_config(w)
				if cfg.relative ~= "" then
					return
				end
				if M.ft_ignore[bo.filetype] or bo.buftype == "nofile" or not wo.number then
					wo.number = false
					wo.signcolumn = "no"
					wo.foldcolumn = "0"
					if M.ft_scrolloff[bo.filetype] then
						wo.sidescrolloff = -1
						wo.scrolloff = -1
					else
						wo.sidescrolloff = 0
						wo.scrolloff = 0
					end
				else
					wo.number = true
					wo.signcolumn = "yes"
					wo.foldcolumn = "1"
					wo.sidescrolloff = -1
					wo.scrolloff = -1
				end
			end, 75)
		end,
	})
end

return M
