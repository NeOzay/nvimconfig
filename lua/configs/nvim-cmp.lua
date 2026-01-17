local M = {}

M.opts = function(_, opts)
	opts.sources = opts.sources or {}
	table.insert(opts.sources, {
		name = "lazydev",
		group_index = 0, -- set group index to 0 to skip loading LuaLS completions
	})
	table.insert(opts.sources, {
		name = "copilot",
		group_index = 2,
	})

	local cmp = require("cmp")
	opts.mapping = opts.mapping or {}
	opts.mapping["<Down>"] = cmp.mapping(function(fallback)
		if cmp.visible() then
			cmp.select_next_item()
		elseif require("luasnip").expand_or_jumpable() then
			require("luasnip").expand_or_jump()
		else
			fallback()
		end
	end, { "i", "s" })

	opts.mapping["<Up>"] = cmp.mapping(function(fallback)
		if cmp.visible() then
			cmp.select_prev_item()
		elseif require("luasnip").jumpable(-1) then
			require("luasnip").jump(-1)
		else
			fallback()
		end
	end, { "i", "s" })
end

return M
