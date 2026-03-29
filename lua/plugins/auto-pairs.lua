local function rules_brackets()
	local autopairs = require("nvim-autopairs")
	local Rule = require("nvim-autopairs.rule")
	local cond = require("nvim-autopairs.conds")

	local brackets = { { "(", ")" }, { "[", "]" }, { "{", "}" } }
	autopairs.add_rules({
		-- Rule for a pair with left-side ' ' and right side ' '
		Rule
			.new(" ", " ")
			-- Pair will only occur if the conditional function returns true
			:with_pair(function(opts)
				-- We are checking if we are inserting a space in (), [], or {}
				local pair = opts.line:sub(opts.col - 1, opts.col)
				return vim.tbl_contains({
					brackets[1][1] .. brackets[1][2],
					brackets[2][1] .. brackets[2][2],
					brackets[3][1] .. brackets[3][2],
				}, pair)
			end)
			:with_move(cond.none())
			:with_cr(cond.none())
			-- We only want to delete the pair of spaces when the cursor is as such: ( | )
			:with_del(function(opts)
				local col = vim.api.nvim_win_get_cursor(0)[2]
				local context = opts.line:sub(col - 1, col + 2)
				return vim.tbl_contains({
					brackets[1][1] .. "  " .. brackets[1][2],
					brackets[2][1] .. "  " .. brackets[2][2],
					brackets[3][1] .. "  " .. brackets[3][2],
				}, context)
			end),
	})
	-- For each pair of brackets we will add another rule
	for _, bracket in pairs(brackets) do
		autopairs.add_rules({
			-- Each of these rules is for a pair with left-side '( ' and right-side ' )' for each bracket type
			Rule
				.new(bracket[1] .. " ", " " .. bracket[2])
				:with_pair(cond.none())
				:with_move(function(opts)
					return opts.char == bracket[2]
				end)
				:with_del(cond.none())
				:use_key(bracket[2])
				-- Removes the trailing whitespace that can occur without this
				:replace_map_cr(function(_)
					return "<C-c>2xi<CR><C-c>O"
				end),
		})
	end
end

-- Ne complète pas la paire si un ferment sans ouvrant correspondant existe après le curseur.
-- Pour les brackets : compte les ouvrants/fermants après curseur — si fermants > ouvrants, il y a un orphelin.
-- Pour les quotes   : si le nombre de quotes après le curseur est impair, l'une est orpheline.
local function rules_no_unmatched_close()
	local autopairs = require("nvim-autopairs")
	local function bracket_cond(open_char, close_char)
		return function(opts)
			local line = opts.line
			local depth = 0
			for i = 1, #line do
				local c = line:sub(i, i)
				if c == open_char then
					depth = depth + 1
				elseif c == close_char then
					if depth == 0 then
						return false -- fermant orphelin trouvé
					end
					depth = depth - 1
				end
			end
			return true
		end
	end

	local function quote_cond(quote_char)
		return function(opts)
			local line = opts.line
			local count = 0
			for i = 1, #line do
				if line:sub(i, i) == quote_char then
					count = count + 1
				end
			end
			return count % 2 == 0 -- impair = quote orpheline
		end
	end

	for _, pair in ipairs({ { "(", ")" }, { "[", "]" }, { "{", "}" } }) do
		for _, rule in ipairs(autopairs.get_rules(pair[1])) do
			rule:with_pair(bracket_cond(pair[1], pair[2]))
		end
	end

	for _, quote in ipairs({ '"', "'" }) do
		for _, rule in ipairs(autopairs.get_rules(quote)) do
			rule:with_pair(quote_cond(quote))
		end
	end
end

local function config(_, opts)
	local autopairs = require("nvim-autopairs")
	autopairs.setup(opts)
	rules_brackets()
	rules_no_unmatched_close()
end

---@type LazyPluginSpec
return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	opts = {},
	config = config,
}
