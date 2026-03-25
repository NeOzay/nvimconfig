local colors = require("colors_bank")

local cmd = vim.api.nvim_create_user_command

local function default_ft()
	if vim.bo.buftype == "" and vim.bo.filetype ~= "" then
		return vim.bo.filetype
	end
	return "markdown"
end

local subcommands = { "list", "last", "new" }

cmd("Scratch", function(o)
	local args = vim.split(o.args, "%s+", { trimempty = true })
	local sub = args[1]

	if not sub then
		Snacks.scratch()
	elseif sub == "list" then
		Snacks.scratch.select()
	elseif sub == "last" then
		local list = Snacks.scratch.list()
		if #list == 0 then
			vim.notify("No scratch buffers found", vim.log.levels.WARN)
			return
		end
		Snacks.scratch.open({ file = list[1].file, name = list[1].name, ft = list[1].ft })
	elseif sub == "new" then
		local name = args[2]
		if not name then
			vim.notify("Usage: Scratch new <name> \\[filetype\\]", vim.log.levels.ERROR)
			return
		end
		local ft = args[3] or default_ft()
		Snacks.scratch.open({ name = name, ft = ft })
	else
		vim.notify("Unknown subcommand: " .. sub, vim.log.levels.ERROR)
	end
end, {
	nargs = "*",
	desc = "Scratch buffer: list | last | new <name> [ft]",
	complete = function(arg_lead, cmd_line)
		local args = vim.split(cmd_line, "%s+", { trimempty = true })
		-- args[1] is "Scratch", args[2] is subcommand, etc.
		local nargs = #args
		-- Still typing current arg: don't count it as complete
		if cmd_line:sub(-1) ~= " " then
			nargs = nargs - 1
		end

		if nargs <= 1 then
			return vim.tbl_filter(function(s)
				return s:find(arg_lead, 1, true) == 1
			end, subcommands)
		end

		if args[2] == "new" and nargs == 3 then
			return vim.tbl_filter(function(ft)
				return ft:find(arg_lead, 1, true) == 1
			end, vim.fn.getcompletion("", "filetype"))
		end

		return {}
	end,
})

---@type snacks.Config
local opts = {
	scratch = {
		ft = default_ft,
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
						part[2] = colors.hi_pathwork(part[2], "SnacksScratchTitle")
					end
				end
				vim.api.nvim_win_set_config(self.win, { title = title })
				require("ufo").enableFold(self.buf)
			end,
		},
	},
}

---@type LazyKeysSpec[]
local keys = {
	{
		"<leader>sl",
		function()
			local list = Snacks.scratch.list()
			if #list == 0 then
				vim.notify("No scratch buffers found", vim.log.levels.WARN)
				return
			end
			Snacks.scratch.open({ file = list[1].file, name = list[1].name, ft = list[1].ft })
		end,
		desc = "Open last Scratch",
	},
	{
		"<leader>fs",
		function()
			Snacks.picker.scratch({ filekey = { cwd = true } })
		end,
		desc = "Select Scratch (workspace)",
	},
}

---@type SnacksSubmodule
return { opts = opts, keys = keys }
