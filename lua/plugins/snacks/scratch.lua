local colors = require("base46.colors")

local cmd = vim.api.nvim_create_user_command

---Charge les variables d'un fichier .env trouvé dans `dir` ou ses parents.
---@param dir string répertoire de départ pour la recherche
---@return table<string, string>
local function load_dotenv(dir)
	local env_file = vim.fs.find(".env", { path = dir, upward = true })[1]
	if not env_file then
		return {}
	end
	local env = {} ---@type table<string, string>
	local f = io.open(env_file, "r")
	if not f then
		return {}
	end
	for line in f:lines() do
		if not line:match("^%s*#") and line:match("=") then
			local key, val = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
			if key then
				val = val:match('^"(.*)"$') or val:match("^'(.*)'$") or val
				env[key] = val
			end
		end
	end
	f:close()
	return env
end

---@param filename? string
---@return string
local function default_ft(filename)
	if filename then
		local ext = vim.fs.ext(filename)
		if ext ~= "" then
			return ext
		end
	end

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
		local ft = args[3] or default_ft(args[2])
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

-- output buffer par scratch buffer (scratch_buf -> out_buf)
local output_bufs = {} ---@type table<integer, integer>
-- job en cours par scratch buffer (scratch_buf -> job_id)
local running_jobs = {} ---@type table<integer, integer>

---@param win snacks.win
---@param out_buf integer
local function update_mapping(win, out_buf)
	if not win.buf then
		return
	end
	local current = win.buf

	vim.keymap.set("n", "<cr>", function()
		win:set_buf(current)
	end, { buffer = out_buf, desc = "Retour au scratch Python" })
	vim.keymap.set("n", "<c-q>", function()
		win:set_buf(current)
	end, { buffer = out_buf, desc = "Retour au scratch Python" })
	vim.keymap.set("n", "q", function()
		win:set_buf(current)
	end, { buffer = out_buf, desc = "Retour au scratch Python" })

	vim.keymap.set("n", "<c-c>", function()
		local job_id = running_jobs[current]
		if job_id and vim.fn.jobwait({ job_id }, 0)[1] == -1 then
			vim.fn.jobstop(job_id)
		end
		win:set_buf(current)
	end, { buffer = out_buf, desc = "Kill current job" })
end

---@param win snacks.win
---@return integer
local function get_out(win)
	---@cast win.buf -?
	local out_buf = output_bufs[win.buf]
	if not out_buf or not vim.api.nvim_buf_is_valid(out_buf) then
		out_buf = vim.api.nvim_create_buf(false, true)
		vim.bo[out_buf].filetype = "python-output"
		output_bufs[win.buf] = out_buf
	end
	update_mapping(win, out_buf)
	return out_buf
end

---@type snacks.Config
local opts = {
	scratch = {
		ft = default_ft,
		win_by_ft = {
			python = {
				keys = {
					["run"] = {
						"<cr>",
						---@param self snacks.win
						function(self)
							if not self.buf or not self.win then
								return
							end

							local scratch_buf = self.buf

							vim.api.nvim_buf_call(scratch_buf, function()
								vim.cmd("silent write")
							end)
							local file = vim.api.nvim_buf_get_name(scratch_buf)
							local cwd = vim.fn.getcwd()
							local env = load_dotenv(cwd)

							local out_buf = get_out(self)

							-- bascule la fenêtre vers la sortie
							self:set_buf(out_buf)
							vim.wo[self.win].wrap = true

							-- job en cours : bascule seulement
							local job_id = running_jobs[scratch_buf]
							if job_id and vim.fn.jobwait({ job_id }, 0)[1] == -1 then
								return
							end

							vim.api.nvim_buf_set_lines(out_buf, 0, -1, false, {})
							running_jobs[scratch_buf] = vim.fn.jobstart({ "python", "-u", file }, {
								cwd = cwd,
								env = next(env) and env or nil,
								stdout_buffered = false,
								stderr_buffered = false,
								on_stdout = function(_, data)
									vim.schedule(function()
										if vim.api.nvim_buf_is_valid(out_buf) then
											vim.api.nvim_buf_set_lines(out_buf, -1, -1, false, data)
										end
									end)
								end,
								on_stderr = function(_, data)
									vim.schedule(function()
										if vim.api.nvim_buf_is_valid(out_buf) then
											local errs = vim.tbl_map(function(l)
												return l ~= "" and ("ERR: " .. l) or l
											end, data)
											vim.api.nvim_buf_set_lines(out_buf, -1, -1, false, errs)
										end
									end)
								end,
								on_exit = function(_, code)
									running_jobs[scratch_buf] = nil
									vim.schedule(function()
										if vim.api.nvim_buf_is_valid(out_buf) then
											local msg = code == 0 and "── OK ──"
												or ("── ERREUR (code " .. code .. ") ──")
											vim.api.nvim_buf_set_lines(out_buf, -1, -1, false, { "", msg })
										end
									end)
								end,
							})
						end,
						desc = "Run Python buffer",
						mode = { "n", "x" },
					},
					["kill"] = {
						"<C-c>",
						---@param self snacks.win
						function(self)
							local job_id = running_jobs[self.buf]
							if job_id and vim.fn.jobwait({ job_id }, 0)[1] == -1 then
								vim.fn.jobstop(job_id)
							end
						end,
						desc = "Kill Python job",
						mode = "n",
					},
					["out_buf"] = {
						"<c-q>",
						---@param self snacks.win
						function(self)
							if not self.buf then
								return
							end
							local out_buf = get_out(self)
							self:set_buf(out_buf)
						end,
						desc = "Show output buffer",
						mode = "n",
					},
				},
			},
		},
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
