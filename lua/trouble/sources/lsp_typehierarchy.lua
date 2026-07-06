---@namespace Ozay
local LspSource = require("trouble.sources.lsp")
local Promise = require("trouble.promise")
local Item = require("trouble.item")

---@class trouble.Source.lsp_typehierarchy: trouble.Source
---@diagnostic disable-next-line: missing-fields
local M = {}

M.config = {
	modes = {
		lsp_supertypes = {
			mode = "lsp_base",
			title = "{hl:Title}Supertypes{hl} {count}",
			desc = "supertypes",
			source = "lsp_typehierarchy.supertypes",
			format = "{kind_icon} {text:ts} {pos} {hl:Title}{item.client:Title}{hl}",
		},
		lsp_subtypes = {
			mode = "lsp_base",
			title = "{hl:Title}Subtypes{hl} {count}",
			desc = "subtypes",
			source = "lsp_typehierarchy.subtypes",
			format = "{kind_icon} {text:ts} {pos} {hl:Title}{item.client:Title}{hl}",
		},
		lsp_type_hierarchy = {
			desc = "LSP Type Hierarchy (supertypes + subtypes)",
			sections = { "lsp_supertypes", "lsp_subtypes" },
		},
	},
}

---@param cb trouble.Source.Callback
---@param direction "supertypes"|"subtypes"
local function type_hierarchy(cb, direction)
	local win = vim.api.nvim_get_current_win()
	LspSource.request("textDocument/prepareTypeHierarchy", function(client)
		return vim.lsp.util.make_position_params(win, client.offset_encoding)
	end)
		:next(function(results)
			---@type trouble.Promise[]
			local requests = {}
			for _, res in ipairs(results or {}) do
				for _, thi in ipairs(res.result or {}) do
					requests[#requests + 1] = LspSource.request(
						"typeHierarchy/" .. direction,
						{ item = thi },
						{ client = res.client }
					)
				end
			end
			return Promise.all(requests)
		end)
		:next(function(responses)
			---@type trouble.Item[]
			local items = {}
			for _, results in ipairs(responses) do
				for _, res in ipairs(results) do
					vim.list_extend(items, LspSource.results_to_items(res.client, res.result or {}))
				end
			end
			Item.add_text(items, { mode = "after" })
			cb(items)
		end)
end

M.get = {}

---@param cb trouble.Source.Callback
function M.get.supertypes(cb)
	type_hierarchy(cb, "supertypes")
end

---@param cb trouble.Source.Callback
function M.get.subtypes(cb)
	type_hierarchy(cb, "subtypes")
end

return M
