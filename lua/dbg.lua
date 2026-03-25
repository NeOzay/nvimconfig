local M = {}

function M.trace_autocmd()
	-- Tracing des autocommandes
	vim.g.autocmd_trace = true
	local log_path = "/tmp/nvim_autocmd_trace.log"

	-- Capturer debug.getinfo avant tout shadowing potentiel
	local getinfo = debug.getinfo
	local orig_create_autocmd = vim.api.nvim_create_autocmd

	vim.api.nvim_create_autocmd = function(event, opts)
		if opts and opts.callback ~= nil then
			local info = getinfo(2, "Sl")
			local source = info.short_src .. ":" .. info.currentline
			local original_cb = opts.callback
			opts.callback = function(ev)
				if vim.g.autocmd_trace then
					local time = os.date("%H:%M:%S")
					local event_name = ev.event or tostring(event)
					local log_entry = string.format("[%s] %-24s @ %s\n", time, event_name, source)
					local f = io.open(log_path, "a")
					if f then
						f:write(log_entry)
						f:close()
					end
				end
				if type(original_cb) == "string" then
					return vim.fn[original_cb](ev)
				else
					return original_cb(ev)
				end
			end
		end
		return orig_create_autocmd(event, opts)
	end

	local cmd = vim.api.nvim_create_user_command

	cmd("AutocmdTrace", function(args)
		if args.args == "on" then
			vim.g.autocmd_trace = true
			io.open(log_path, "w"):close()
			vim.notify("Autocmd tracing ON → " .. log_path, vim.log.levels.INFO)
		elseif args.args == "off" then
			vim.g.autocmd_trace = false
			vim.notify("Autocmd tracing OFF", vim.log.levels.INFO)
		else
			vim.g.autocmd_trace = not vim.g.autocmd_trace
			if vim.g.autocmd_trace then
				io.open(log_path, "w"):close()
			end
			vim.notify(
				"Autocmd tracing " .. (vim.g.autocmd_trace and "ON → " .. log_path or "OFF"),
				vim.log.levels.INFO
			)
		end
	end, {
		nargs = "?",
		desc = "Activer/désactiver le tracing des autocommandes",
		complete = function()
			return { "on", "off" }
		end,
	})

	cmd("AutocmdTraceLog", function()
		vim.cmd("botright split " .. log_path)
		vim.cmd("setlocal autoread nomodifiable")
		vim.cmd("$")
	end, { desc = "Ouvrir le log de tracing des autocommandes" })
end

function M.schedule_print()
	vim.print = vim.schedule_wrap(vim.print)
end

return M
