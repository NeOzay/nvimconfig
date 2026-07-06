---@diagnostic disable:missing-fields, assign-type-mismatch, param-type-mismatch

---@type snacks.Config
local opts = {
	notifier = { enabled = true, timeout = 5000 },
	picker = {
		sources = {
			notifications = {
				win = {
					preview = {
						wo = { wrap = true },
						---@param self snacks.win
						on_win = function(self)
							if not self.buf or not self.win then
								return
							end
							vim.api.nvim_buf_attach(self.buf, false, {
								on_lines = function()
									if not vim.api.nvim_win_is_valid(self.win) then
										return true
									end
									vim.schedule(function()
										if not vim.api.nvim_buf_is_valid(self.buf) then
											return
										end
										vim.wo[self.win].conceallevel = 2
										require("markview.actions").render(self.buf, nil, {
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
										require("markview.actions").set_query(self.buf)
									end)
								end,
							})
						end,
					},
				},
			},
		},
	},
	styles = {
		notification = {
			wo = {
				winblend = 5,
				wrap = true,
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
				vim.wo[self.win].concealcursor = "n"

				vim.schedule(function()
					if not vim.api.nvim_buf_is_valid(self.buf) or not vim.api.nvim_win_is_valid(self.win) then
						return
					end
					local ft = vim.bo[self.buf].filetype
					if package.loaded["markview"] then
						-- Register snacks_notif → markdown so get_parser(buf) resolves correctly
						vim.treesitter.language.register("markdown", ft)
						require("markview.actions").render(self.buf, nil, {
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
						require("markview.actions").set_query(self.buf)
					end
				end)
			end,
		},
	},
}

---@type LazyKeysSpec[]
local keys = {}

vim.api.nvim_create_user_command("Notifi", function()
	Snacks.picker.notifications({ layout = { preset = "ivy_2" } })
end, { desc = "list notifications" })

---@type SnacksSubmodule
return { opts = opts, keys = keys }
