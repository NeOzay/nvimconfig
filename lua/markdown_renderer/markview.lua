---@namespace Ozay.MarkdownRenderer

--- Adaptateur markview : le code qui vivait dans les intégrations (notifier, picker, hover),
--- déplacé tel quel.
---@class Adapter
local M = {}

---@return boolean
local function loaded()
	return package.loaded["markview"] ~= nil
end

---@param buf integer
---@param win integer
function M.render_notification(buf, win)
	if not loaded() then
		return
	end
	require("markview.actions").render(buf, nil, {
		markdown = {
			list_items = { indent_size = 1, shift_width = 1 },
			code_blocks = {
				label_direction = "right",
				style = "simple",
			},
		},
		markdown_inline = {
			inline_codes = { padding_left = "", padding_right = "" },
			hyperlinks = { enable = false },
		},
		preview = { ignore_buftypes = {} },
	})
	-- Retire les conceal_lines des fence lines sans stopper treesitter :
	-- set_query() remplace temporairement la query markdown pour supprimer
	-- les directives conceal_lines, redémarre le highlighter sur ce buffer,
	-- puis restaure la query globale. Les highlights d'injection (code blocks)
	-- sont préservés.
	require("markview.actions").set_query(buf)
end

---@param buf integer
---@param win integer
function M.render_preview(buf, win)
	if not loaded() then
		return
	end
	require("markview").render(buf)
	require("markview.actions").set_query(buf)
end

---@param buf integer
---@param win integer
function M.render_hover(buf, win)
	vim.b[buf].markview = true
	if loaded() and package.loaded["markview"].render then
		require("markview.actions").render(buf, { enable = true, hybrid_mode = false }, {
			markdown = {
				block_quotes = { enable = false },
				list_items = {
					shift_width = 1,
					indent_size = 1,
				},
			},
		})
	end
end

--- Attache markview au buffer courant (codecompanion).
---@param buf integer
function M.attach(buf)
	if loaded() then
		vim.cmd("Markvie attach")
	end
end

return M
