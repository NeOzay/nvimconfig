---@namespace Ozay.Hover
--- Scrollbar flottant pour la hover window.
--- Architecture inspirée de blink.cmp :
---   - gutter : float 1-col pleine hauteur (fond)
---   - thumb  : float 1-col hauteur proportionnelle (indicateur)
--- Les deux sont positionnés avec `relative = "win"` et zindex supérieur
--- au parent, ce qui les superpose au border droit sans coordonnées absolues.

local M = {}

--- Highlight groups par défaut (surchargeables via le système de highlights).
local function setup_hl()
	local ok, b46 = pcall(require, "base46")
	if not ok then
		return
	end
	local c = b46.get_theme_tb("base_30")
	local mix = require("base46.colors").mix
	vim.api.nvim_set_hl(0, "HoverScrollbarThumb", { bg = mix(c.grey_fg, c.one_bg3, 55), default = true })
end

---@class Scrollbar
---@field thumb_win integer?
---@field buf integer?
---@field autocmd_scroll integer?
---@field autocmd_hide integer?
local scrollbar = {}
scrollbar.__index = scrollbar

---@return Scrollbar
function M.new()
	setup_hl()
	return setmetatable({}, scrollbar)
end

-- ── Géométrie ────────────────────────────────────────────────────────────────

---@param target_win integer
---@return { should_hide: boolean, win_h: integer, thumb_row: integer, thumb_h: integer }
local function get_geometry(target_win)
	local win_h = vim.api.nvim_win_get_height(target_win)
	-- text_height compte les lignes visuelles réelles (conceal_lines exclus, wrap inclus)
	local buf_h = vim.api.nvim_win_text_height(target_win, {}).all

	if win_h >= buf_h then
		return { should_hide = true, win_h = win_h, thumb_row = 0, thumb_h = win_h }
	end

	local thumb_h = math.max(1, math.floor(win_h * win_h / buf_h + 0.5) - 1)
	local first_line = vim.fn.line("w0", target_win)
	local pct = (first_line - 1) / math.max(1, buf_h - win_h)
	local thumb_row = math.min(math.floor(pct * (win_h - thumb_h) + 0.5), win_h - 1)
	thumb_h = math.min(thumb_h, win_h - thumb_row)

	return { should_hide = false, win_h = win_h, thumb_row = thumb_row, thumb_h = math.max(1, thumb_h) }
end

-- ── Fenêtres ──────────────────────────────────────────────────────────────────

---@param self Scrollbar
---@return integer buf
local function get_buf(self)
	if not self.buf or not vim.api.nvim_buf_is_valid(self.buf) then
		self.buf = vim.api.nvim_create_buf(false, true)
	end
	return self.buf
end

---@param self Scrollbar
---@param cfg table
---@param hl string
---@return integer win
local function open_win(self, cfg, hl)
	local win = vim.api.nvim_open_win(
		get_buf(self),
		false,
		vim.tbl_extend("force", cfg, {
			style = "minimal",
			focusable = false,
			noautocmd = true,
			border = "none",
		})
	)
	vim.api.nvim_set_option_value("winhighlight", ("Normal:%s,EndOfBuffer:%s"):format(hl, hl), { win = win })
	return win
end

---@param target_win integer
---@param row integer
---@param height integer
---@param zindex integer
---@return table
local function win_cfg(target_win, row, height, zindex)
	local cfg = vim.api.nvim_win_get_config(target_win)
	return {
		relative = "win",
		win = target_win,
		row = row,
		col = cfg.width, -- superpose le border droit
		width = 1,
		height = height,
		zindex = zindex,
	}
end

-- ── API publique ──────────────────────────────────────────────────────────────

---@param target_win integer
function scrollbar:update(target_win)
	if not vim.api.nvim_win_is_valid(target_win) then
		return self:hide()
	end

	local geo = get_geometry(target_win)
	if geo.should_hide then
		return self:hide()
	end

	-- Le border droit sert de gutter ; seul le thumb est un float séparé.
	local base_z = vim.api.nvim_win_get_config(target_win).zindex or 100
	local tcfg = win_cfg(target_win, geo.thumb_row, geo.thumb_h, base_z + 1)
	if self.thumb_win and vim.api.nvim_win_is_valid(self.thumb_win) then
		vim.api.nvim_win_set_config(self.thumb_win, tcfg)
	else
		self.thumb_win = open_win(self, tcfg, "HoverScrollbarThumb")
	end
end

function scrollbar:hide()
	if self.thumb_win and vim.api.nvim_win_is_valid(self.thumb_win) then
		vim.api.nvim_win_close(self.thumb_win, true)
	end
	self.thumb_win = nil

	if self.autocmd_scroll then
		pcall(vim.api.nvim_del_autocmd, self.autocmd_scroll)
		self.autocmd_scroll = nil
	end
	if self.autocmd_hide then
		pcall(vim.api.nvim_del_autocmd, self.autocmd_hide)
		self.autocmd_hide = nil
	end
end

--- Attache le scrollbar à une window hover et le maintient à jour.
---@param target_win integer
function scrollbar:attach(target_win)
	-- Supprime les anciens autocmds avant de recréer
	if self.autocmd_scroll then
		pcall(vim.api.nvim_del_autocmd, self.autocmd_scroll)
	end
	if self.autocmd_hide then
		pcall(vim.api.nvim_del_autocmd, self.autocmd_hide)
	end

	self:update(target_win)

	self.autocmd_scroll = vim.api.nvim_create_autocmd("WinScrolled", {
		callback = function(ev)
			if tonumber(ev.match) == target_win then
				self:update(target_win)
			end
		end,
	})

	self.autocmd_hide = vim.api.nvim_create_autocmd("WinClosed", {
		pattern = tostring(target_win),
		once = true,
		callback = function()
			self:hide()
		end,
	})
end

return M
