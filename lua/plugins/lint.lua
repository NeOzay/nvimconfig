local function create_autocmd(lint)
	local timer = assert(vim.uv.new_timer())
	local debounce = assert(vim.uv.new_timer())

	vim.api.nvim_create_autocmd({ "BufEnter", "BufLeave" }, {
		group = vim.api.nvim_create_augroup("NvimLintTimer", { clear = true }),
		callback = function(ev)
			timer:stop()
			if ev.event == "BufEnter" and lint.linters_by_ft[vim.bo[ev.buf].filetype] then
				timer:start(
					500,
					3000,
					vim.schedule_wrap(function()
						lint.try_lint()
					end)
				)
			end
		end,
	})

	vim.api.nvim_create_autocmd("TextChanged", {
		group = vim.api.nvim_create_augroup("NvimLintDebounce", { clear = true }),
		callback = function()
			debounce:stop()
			debounce:start(
				300,
				0,
				vim.schedule_wrap(function()
					lint.try_lint()
				end)
			)
		end,
	})
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
		group = vim.api.nvim_create_augroup("NvimLint", { clear = true }),
		callback = function()
			debounce:stop()
			lint.try_lint()
		end,
	})
end

---@type LazySpec
return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPost", "BufWritePost" },
	config = function()
		local lint = require("lint")

		-- Force stdin pour linter le contenu du buffer (pas le fichier disque)
		lint.linters.shellcheck = vim.tbl_deep_extend("force", lint.linters.shellcheck, {
			args = { "--format", "json1", "-" },
		})

		lint.linters_by_ft = {
			json = { "jsonlint" },
			sh = { "shellcheck" },
			bash = { "shellcheck" },
			zsh = { "shellcheck" },
		}
		create_autocmd(lint)
	end,
}
