---@diagnostic disable:missing-fields, assign-type-mismatch, param-type-mismatch

---@type snacks.Config
local opts = {
	notifier = { enabled = true, timeout = 5000, padding = false },
	styles = {
		notification = {
			wo = {
				winblend = 5,
				wrap = true,
				colorcolumn = "",
				conceallevel = 2,
				statuscolumn = "",
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
					-- Register snacks_notif → markdown so get_parser(buf) resolves correctly
					vim.treesitter.language.register("markdown", vim.bo[self.buf].filetype)
					require("markdown_renderer").render_notification(self.buf, self.win)
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
