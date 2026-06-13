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
		name = "dap_signs",
		order = 20,
		condition = {
			-- Masquée si window/terminal étroit : le sign segment a une largeur
			-- dynamique, vider son texte suffit à replier la colonne. Mesure par
			-- window (gère les splits) + garde-fou terminal.
			min_win_width = cond.NARROW_WIN_WIDTH,
			min_columns = cond.NARROW_WIDTH,
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
					auto = true,
				},
				click = "v:lua.DapClickHandler",
			}
		end,
	},
	{
		name = "number",
		order = 30,
		condition = {
			-- Pas de `enabled` ici : en terminal étroit c'est l'option `number` qui
			-- est éteinte (cf. conditions.apply_win_options), ce qui masque le
			-- segment ET récupère la largeur de `numberwidth`. `args.nu` devient
			-- alors faux et le segment ne rend rien.
			ft_blacklist = { snacks_picker_preview = true, ["markdown.snacks_picker_preview"] = true },
			predicate = function(args)
				return args.nu
			end,
		},
		segment = function(builtin)
			-- click ScLa = handler lnum natif -> dispatch "Lnum" (cf. init.lua).
			-- Double-clic gauche = pose/retrait d'un breakpoint dap.
			return { text = { builtin.lnumfunc }, click = "v:lua.ScLa" }
		end,
	},
	{
		name = "git_signs",
		order = 40,
		condition = {
			ft_blacklist = cond.ft_ignore,
			ignore_float_win = true,
			require_file = true,
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

	{
		name = "padding",
		order = 60,
		condition = {
			-- ft_whitelist = cond.ft_padding,
			-- require_number = false,
			after = function(ctx)
				return vim.tbl_isempty(ctx.rendered)
			end,
		},
		segment = function(builtin)
			return { text = { " " }, hl = "Normal" }
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
			seg.condition = cond.make_condition(def.condition, def.name)
		end
		table.insert(segments, seg)
	end

	return {
		relculright = true,
		segments = segments,
	}
end

return M
