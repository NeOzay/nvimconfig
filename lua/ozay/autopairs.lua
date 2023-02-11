local remap = vim.api.nvim_set_keymap
local npairs = require('nvim-autopairs')
local Rule = require('nvim-autopairs.rule')
local cond = require('nvim-autopairs.conds')
npairs.setup({ map_cr = false })

-- skip it, if you use another global object
_G.MUtils = {}

-- old version
-- MUtils.completion_confirm=function()
-- if vim.fn["coc#pum#visible"]() ~= 0 then
-- return vim.fn["coc#_select_confirm"]()
-- else
-- return npairs.autopairs_cr()
-- end
-- end

local none = cond.none


for _, punct in pairs { ",", ";" } do
	npairs.add_rules {
		Rule("", punct)
			:with_move(function(opts) return opts.char == punct end)
			:with_pair(none())
			:with_del(none())
			:with_cr(none())
			:use_key(punct)
	}
end


--npairs.add_rules {
--	Rule("%-?%-%-$", "", "lua")
--		:use_regex(true)
--		:with_pair(none())
--		:with_cr(none())
--		:with_move(none())
--}

npairs.add_rules {
	Rule("", "", "lua")
		:replace_endpair(function()
			return "-"
		end)
		:with_pair(function(opts)
			local prev_char = opts.line:sub(1,opts.col-1)
			return not prev_char:find("[%w%p]")
		end)
		:with_del(none())
		:with_cr(none())
		:with_move(none())
		:use_key("-")
		:set_end_pair_length(-1)
}


npairs.add_rules {
	Rule("", "", "lua")
		:replace_endpair(function()
			return "<BS>---@"
		end)
		:with_pair(function(opts)
			return not opts.line:find("[%w%p]")
		end)
		:with_del(none())
		:with_cr(none())
		:with_move(none())
		:use_key("@")
		:set_end_pair_length(-3)
}

npairs.add_rules {
	Rule("^---@", "", "lua")
		:replace_map_cr(function()
			return "<cr>---@"
		end)
		:with_del(none())
		:with_pair(none())
		:with_move(none())
		:use_regex(true)
	--:set_end_pair_length(3)
}

-- new version for custom pum
MUtils.completion_confirm = function()
	if vim.fn["coc#pum#visible"]() ~= 0 then
		return vim.fn["coc#pum#confirm"]()
	else
		return npairs.autopairs_cr()
	end
end
local cmp = require"cmp"
--remap('i', '<CR>', 'v:lua.MUtils.completion_confirm()', { expr = true, noremap = true })

vim.keymap.set("i", "<CR>", function ()
  if cmp.visible() then
    cmp.confirm()
  else
    return npairs.autopairs_cr()
  end
end, {expr = true})



