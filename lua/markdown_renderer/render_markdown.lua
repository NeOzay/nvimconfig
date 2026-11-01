---@namespace Ozay.MarkdownRenderer

--- Adaptateur render-markdown : rendu selon la config de l'utilisateur (`opts` de la spec), que l'adaptateur ne règle pas.
--- Pas d'équivalent de `set_query` : render-markdown désactive déjà les directives `conceal_lines`
--- du markdown.
---@class Adapter
local M = {}

--- Délai de la seconde passe : au-delà du `debounce` par défaut de render-markdown (100 ms).
local RETRY_MS = 150

---@param buf integer
---@param win integer
local function call_render(buf, win)
	require("render-markdown").render({ buf = buf, win = win })
end

---@type table<integer, uv.uv_timer_t> un minuteur de rendu final par fenêtre surveillée
local timers = {}

--- render-markdown se met à jour sur `WinScrolled` par un autocmd local au buffer, que Neovim ne
--- déclenche que si la fenêtre défilée est la courante : une fenêtre qui n'a pas le focus (preview
--- du picker, float) ne rend jamais les lignes qui entrent à l'écran. On défile donc nous-mêmes,
--- avec un rendu final une fois le défilement fini (le `debounce` ignore les derniers appels).
---@param win integer
local function watch_scroll(win)
	if timers[win] then
		return
	end
	local group = vim.api.nvim_create_augroup("MarkdownRendererScroll" .. win, { clear = true })
	local timer = assert(vim.uv.new_timer())
	timers[win] = timer
	vim.api.nvim_create_autocmd("WinScrolled", {
		group = group,
		pattern = tostring(win),
		callback = function()
			if not vim.api.nvim_win_is_valid(win) then
				return
			end
			local buf = vim.api.nvim_win_get_buf(win)
			local ft = vim.split(vim.bo[buf].filetype, ".", { plain = true })[1]
			if not vim.tbl_contains(require("markdown_renderer").FILETYPES, ft) then
				return
			end
			call_render(buf, win)
			timer:stop()
			timer:start(
				RETRY_MS,
				0,
				vim.schedule_wrap(function()
					if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
						call_render(buf, win)
					end
				end)
			)
		end,
	})
	vim.api.nvim_create_autocmd("WinClosed", {
		group = group,
		pattern = tostring(win),
		once = true,
		callback = function()
			timer:stop()
			timer:close()
			timers[win] = nil
			vim.api.nvim_del_augroup_by_id(group)
		end,
	})
end

---@param buf integer
---@param win integer
local function render(buf, win)
	if not package.loaded["render-markdown"] then
		return
	end
	call_render(buf, win)
	watch_scroll(win)
	-- Un rendu demandé dans le `debounce` d'une mise à jour déjà lancée (ouverture du float) est
	-- ignoré par render-markdown : une seconde passe, hors de cette fenêtre, le rattrape.
	vim.defer_fn(function()
		if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_win_is_valid(win) then
			call_render(buf, win)
		end
	end, RETRY_MS)
end

---@param buf integer
---@param win integer
function M.render_notification(buf, win)
	render(buf, win)
end

---@param buf integer
---@param win integer
function M.render_preview(buf, win)
	render(buf, win)
end

---@param buf integer
---@param win integer
function M.render_hover(buf, win)
	render(buf, win)
end

--- render-markdown s'attache de lui-même aux `file_types` (codecompanion en fait partie).
---@param buf integer
function M.attach(buf) end

return M
