---@diagnostic disable:missing-fields, assign-type-mismatch, param-type-mismatch
---@type string[]
local markview_fts = { "markdown", "Avante", "codecompanion", "snacks_notif" }

---@type snacks.Config
local opts = {
	notifier = { enabled = true, timeout = 5000 },
	styles = {
		notification = {
			wo = {
				winblend = 5,
				wrap = false,
				colorcolumn = "",
				conceallevel = 2,
			},
			on_win = function(self)
				if not self.buf or not self.win then
					return
				end
				-- Append extra winhighlight entries (notifier overwrites wo.winhighlight before show)
				local whl = vim.wo[self.win].winhighlight
				-- Detect notification type from existing Normal:SnacksNotifier<Type> mapping
				local suffix = whl:match("Normal:(SnacksNotifier%u%l+)") or "SnacksNotifierInfo"
				local extra = {
					"EndOfBuffer:" .. suffix,
					"StatusColumn:" .. suffix,
					"LineNr:" .. suffix,
				}
				vim.wo[self.win].winhighlight = whl .. "," .. table.concat(extra, ",")

				vim.schedule(function()
					if not vim.api.nvim_buf_is_valid(self.buf) or not vim.api.nvim_win_is_valid(self.win) then
						return
					end
					local ft = vim.bo[self.buf].filetype
					if vim.tbl_contains(markview_fts, ft) then
						-- Register snacks_notif → markdown so get_parser(buf) resolves correctly
						vim.treesitter.language.register("markdown", ft)
						require("markview.actions").render(self.buf, nil, {
							markdown = {
								list_items = { indent_size = 1, shift_width = 1 },
								code_blocks = {
									label_direction = "right", --[[min_width = self:size().width - 4 ]]
									style = "simple",
								},
							},
							markdown_inline = {
								inline_codes = { padding_left = "", padding_right = "" },
								hyperlinks = { enable = false },
							},
							preview = { ignore_buftypes = {} },
						})
						-- Supprimer les conceal_lines de treesitter (cache les lignes de fence entières)
						-- tout en gardant les conceal classiques (**, `, etc.) intacts
						local ts_ns = vim.api.nvim_create_namespace("nvim.treesitter.highlighter")
						local marks = vim.api.nvim_buf_get_extmarks(self.buf, ts_ns, 0, -1, { details = true })
						for _, mark in ipairs(marks) do
							if mark[4].conceal_lines then
								vim.api.nvim_buf_del_extmark(self.buf, ts_ns, mark[1])
							end
						end
					end
				end)
			end,
		},
	},
}

---@type LazyKeysSpec[]
local keys = {}

vim.api.nvim_create_user_command("Notifi", function()
	Snacks.picker.notifications()
end, { desc = "list notifications" })

---@type SnacksSubmodule
return { opts = opts, keys = keys }
