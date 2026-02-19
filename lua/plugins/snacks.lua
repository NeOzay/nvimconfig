local utils = require("utils")
---@type snacks.Config
local opts = {}
opts.terminal = {
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
}

local cmd = vim.api.nvim_create_user_command

cmd("Scratch", function()
	Snacks.scratch()
end, { desc = "Create Scratch Buffer" })
cmd("ScratchList", function()
	Snacks.scratch.select()
end, { desc = "Select Scratch Buffer" })

opts.scratch = {
	ft = function()
		if vim.bo.buftype == "" and vim.bo.filetype ~= "" then
			return vim.bo.filetype
		end
		return "markdown"
	end,
	icon = {},
	---@diagnostic disable-next-line
	win = {
		b = { scratch = true },
		on_win = function(self)
			local title = self.opts.title
			if type(title) ~= "table" or not self.win then
				return
			end
			for _, part in ipairs(title) do
				if part[2] and part[2] ~= "SnacksScratchTitle" then
					part[2] = utils.hi_pathwork(part[2], "SnacksScratchTitle")
				end
			end
			vim.api.nvim_win_set_config(self.win, { title = title })
		end,
	},
}

---@type LazyPluginSpec
return {
	"folke/snacks.nvim",
	lazy = false,
	priority = 1000,
	dev = true,
	opts = opts,
	config = true,
	keys = {
		{
			"<C-ù>",
			function()
				Snacks.terminal(nil, { env = { PROMPT_EOL_MARK = "" } })
			end,
			desc = "Toggle Terminal",
		},
	},
}
