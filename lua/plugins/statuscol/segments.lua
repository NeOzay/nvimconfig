local cond = require("plugins.statuscol.conditions")
local folds = require("plugins.statuscol.folds")

local M = {}

---@class Ozay.Statuscol.SegmentDef
---@field name string
---@field enabled? boolean
---@field order number
---@field condition? Ozay.Statuscol.ConditionSpec
---@field segment fun(builtin: table ): table

---@type Ozay.Statuscol.SegmentDef[]
local registry = {
	{
		name = "padding",
		order = 10,
		condition = {
			ft_whitelist = cond.ft_padding,
			require_number = false,
		},
		segment = function(builtin)
			return { text = { " " }, hl = "Normal" }
		end,
	},
	{
		name = "dap_signs",
		order = 20,
		condition = {
			ft_blacklist = cond.ft_ignore,
			require_file = true,
			buf_predicate = function(bufnr)
				return vim.b[bufnr].scratch ~= true
			end,
			win_predicate = function(winid)
				return vim.wo[winid].signcolumn ~= "no"
			end,
		},
		segment = function(builtin)
			return {
				sign = {
					name = { "Dap.*" },
					namespace = { "dap_disabled" },
					maxwidth = 1,
					colwidth = 2,
					auto = false,
				},
				click = "v:lua.DapClickHandler",
			}
		end,
	},
	{
		name = "number",
		order = 30,
		condition = {
			ft_blacklist = { snacks_picker_preview = true, ["markdown.snacks_picker_preview"] = true },
			predicate = function(args)
				return args.nu
			end,
		},
		segment = function(builtin)
			return { text = { builtin.lnumfunc } }
		end,
	},
	{
		name = "git_signs",
		order = 40,
		condition = {
			ft_blacklist = cond.ft_ignore,
			ignore_float_win = true,
		},
		segment = function(builtin)
			return {
				sign = {
					namespace = { "gitsigns.*" },
					maxwidth = 1,
					colwidth = 1,
					auto = false,
				},
			}
		end,
	},
	{
		name = "fold",
		order = 50,
		condition = {
			ft_blacklist = cond.ft_ignore,
		},
		segment = function(builtin)
			return { text = { folds.fold_by_indent }, click = "v:lua.ScFa" }
		end,
	},
}

--- Desactive un segment par nom.
---@param name string
function M.disable(name)
	for _, def in ipairs(registry) do
		if def.name == name then
			def.enabled = false
			return
		end
	end
end

--- Active un segment par nom.
---@param name string
function M.enable(name)
	for _, def in ipairs(registry) do
		if def.name == name then
			def.enabled = true
			return
		end
	end
end

--- Construit les options pour statuscol.setup().
---@return table
function M.build()
	local builtin = require("statuscol.builtin")
	local segments = {}

	-- Trier par ordre
	local sorted = {}
	for _, def in ipairs(registry) do
		if def.enabled ~= false then
			table.insert(sorted, def)
		end
	end
	table.sort(sorted, function(a, b)
		return a.order < b.order
	end)

	for _, def in ipairs(sorted) do
		local seg = def.segment(builtin)
		if def.condition then
			seg.condition = cond.make_condition(def.condition)
		end
		table.insert(segments, seg)
	end

	return {
		relculright = true,
		segments = segments,
	}
end

return M
