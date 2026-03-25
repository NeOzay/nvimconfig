---@type snacks.Config
local opts = {
	terminal = {
		shell = { "zsh" },
		win = {
			wo = {
				winbar = "",
				statuscolumn = "%#normal# ",
			},
			bo = {},
			height = 0.2,
			keys = {
				q = "hide",
				gf = function(self)
					local f = vim.fn.findfile(vim.fn.expand("<cfile>"), "**")
					if f == "" then
						Snacks.notify.warn("No file under cursor")
					else
						self:hide()
						vim.schedule(function()
							vim.cmd("e " .. f)
						end)
					end
				end,
				normal = {
					"<C-x>",
					function()
						vim.cmd("stopinsert")
					end,
					mode = "t",
				},
				-- ["<C-x>"] = function(self)
				-- 	self:close()
				-- 	print("Terminal fermé via Snacks")
				-- end,
				close = {
					"<C-ù>",
					function(self)
						self:hide()
					end,
					mode = "t",
				},
			},
		},
	},
}

---@type LazyKeysSpec[]
local keys = {
	{
		"<C-ù>",
		function()
			Snacks.terminal(nil, { env = { PROMPT_EOL_MARK = "" } })
		end,
		desc = "Toggle Terminal",
	},
}

---@type SnacksSubmodule
return { opts = opts, keys = keys }
