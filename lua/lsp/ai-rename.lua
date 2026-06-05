---@namespace Ozay
---@diagnostic disable:missing-fields

---@class AIRename
local M = {}

---@param bufnr integer
---@return string
local function get_scope_context(bufnr)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local shared = pRequire("nvim-treesitter-textobjects.shared")

	if shared then
		local range = shared.textobject_at_point("@function.outer", "textobjects", bufnr, cursor)
		if not range then
			range = shared.textobject_at_point("@class.outer", "textobjects", bufnr, cursor)
		end
		if range then
			local lines = vim.api.nvim_buf_get_lines(bufnr, range[1], range[4] + 1, false)
			return table.concat(lines, "\n")
		end
	end

	local row = cursor[1] - 1
	local start_row = math.max(0, row - 10)
	local end_row = math.min(vim.api.nvim_buf_line_count(bufnr) - 1, row + 10)
	local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
	return table.concat(lines, "\n")
end

---@param word string
---@param context string
---@param filetype string
---@return string
local function build_prompt(word, context, filetype)
	return string.format(
		'Variable name: "%s"\nLanguage: %s\nContext:\n%s\n\nSuggest 5 alternative names. Reply with one name per line only, no explanation.',
		word,
		filetype,
		context
	)
end

function M.rename()
	local bufnr = vim.api.nvim_get_current_buf()
	local word = vim.fn.expand("<cword>")

	if word == "" then
		vim.notify("AI Rename: no word under cursor", vim.log.levels.WARN)
		return
	end

	local cursor = vim.api.nvim_win_get_cursor(0)
	local params = {
		textDocument = vim.lsp.util.make_text_document_params(bufnr),
		position = { line = cursor[1] - 1, character = cursor[2] },
	}

	vim.lsp.buf_request(bufnr, "textDocument/prepareRename", params, function(err, result)
		if err then
			vim.notify("AI Rename: " .. (err.message or "cannot rename"), vim.log.levels.WARN)
			return
		end
		if not result then
			vim.notify("AI Rename: symbol is not renamable", vim.log.levels.WARN)
			return
		end
		M._do_rename(bufnr, word)
	end)
end

---@param bufnr integer
---@param word string
function M._do_rename(bufnr, word)
	local filetype = vim.bo[bufnr].filetype
	local context = get_scope_context(bufnr)
	local prompt = build_prompt(word, context, filetype)

	---@type { text: string }[]
	local suggestions = { { text = "⏳ Generating…" } }
	---@type snacks.Picker?
	local picker_ref = nil

	local cc_config = require("codecompanion.config")
	local llm_role = cc_config.constants.LLM_ROLE

	vim.schedule(function()
		picker_ref = Snacks.picker.pick({
			title = "󰁨 AI Rename: " .. word,
			preview = false,
			finder = function(opts, ctx)
				return ctx.filter:filter(suggestions)
			end,
			format = function(item, _)
				return { { item.text, "Normal" } }
			end,
			confirm = function(picker, item)
				picker:close()
				if item then
					vim.lsp.buf.rename(item.text)
				end
			end,
			layout = {
				preset = "select",
				layout = {
					backdrop = false,
					width = 40,
					min_width = 30,
					height = 10,
					min_height = 5,
					box = "vertical",
					border = "rounded",
					title = "{title}",
					title_pos = "center",
					row = 2,
					wo = { winhighlight = "FloatTitle:SnacksPickerInputTitle,FloatBorder:SnacksPickerInputBorder" },
					{ win = "input", height = 1, border = "bottom" },
					{ win = "list", border = "none", height = 5 },
				},
			},
			win = {
				input = {
					keys = {
						["<C-y>"] = {
							function(p)
								local typed = p:filter().pattern
								if typed and typed ~= "" then
									p:close()
									vim.lsp.buf.rename(typed)
								end
							end,
							mode = { "i", "n" },
							desc = "Rename with typed name",
						},
					},
				},
			},
		})
	end)

	require("codecompanion").chat({
		hidden = true,
		auto_submit = true,
		messages = { { role = "user", content = prompt } },
		callbacks = {
			on_checkpoint = function(_, data)
				local msgs = data.messages
				local last = msgs[#msgs]
				if not last or last.role ~= llm_role then
					return
				end

				local text = type(last.content) == "table"
					and table.concat(last.content, "")
					or (last.content or "")

				local items = {}
				for line in text:gmatch("[^\n]+") do
					line = vim.trim(line)
					if line ~= "" then
						table.insert(items, { text = line })
					end
				end

				if #items == 0 then
					return
				end

				-- Affichage progressif : un nom toutes les 80ms
				suggestions = {}
				for i, item in ipairs(items) do
					vim.defer_fn(function()
						table.insert(suggestions, item)
						if picker_ref then
							picker_ref:refresh()
						end
					end, (i - 1) * 80)
				end
			end,
		},
	})
end

return M
