local colors = require("base46").get_theme_tb("base_30") ---@type Base30Table
---@diagnostic disable
-- Cache pour lastused (mis à jour à chaque changement de buffer)
local buffer_lastused = {}

vim.api.nvim_create_autocmd("BufEnter", {
	callback = function(args)
		buffer_lastused[args.buf] = vim.uv.now()
	end,
})

---@param buffer {path: string}
---@return integer|nil
local function get_harpoon_index(buffer)
	local harpoon = require("harpoon")
	local list = harpoon:list()
	for i, item in pairs(list.items) do
		local buf_path = buffer.path
		local item_path = vim.fn.fnamemodify(item.value, ":p")
		if buf_path == item_path then
			return i
		end
	end
	return nil
end

--- Fonction de tri: harponnés par index, puis récents par lastused
local function buffer_sorter(a, b)
	local a_harpoon = get_harpoon_index(a)
	local b_harpoon = get_harpoon_index(b)

	-- Les deux sont harponnés: trier par index harpoon
	if a_harpoon and b_harpoon then
		return a_harpoon < b_harpoon
	end

	-- Seulement a est harponné: a vient avant
	if a_harpoon then
		return true
	end

	-- Seulement b est harponné: b vient avant
	if b_harpoon then
		return false
	end

	-- Aucun n'est harponné: trier par lastused (plus récent d'abord)
	local a_lastused = buffer_lastused[a.number] or 0
	local b_lastused = buffer_lastused[b.number] or 0
	return a_lastused > b_lastused
end

-- Charger tous les buffers harponnés au démarrage
local function load_harpoon_buffers()
	local harpoon = require("harpoon")
	local list = harpoon:list()
	for _, item in pairs(list.items) do
		local path = vim.fn.fnamemodify(item.value, ":p")
		if vim.fn.filereadable(path) == 1 then
			vim.fn.bufadd(path)
		end
	end
end

local states = {
	pass_harpoon = false,
	has_separtor = false,
}

local function reset_states()
	states.pass_harpoon = false
	states.has_separtor = false
end

---@type table<string, Cokeline.Component>
local components = {}

components.reset_states = {
	text = function(buffer)
		if buffer.is_first then
			reset_states()
		end
		return ""
	end,
}
-- Indicateur gauche (harpon ou barre)
components.separator = {
	text = function(buffer)
		local idx = get_harpoon_index(buffer)
		if idx then
			return " " .. idx .. " "
		end
		if not states.pass_harpoon then
			states.pass_harpoon = true
			return "▎"
		end
		return " "
	end,
	fg = function(buffer)
		local idx = get_harpoon_index(buffer)
		if idx then
			return buffer.is_focused and colors.cyan or colors.blue
		end
		if buffer.diagnostics and buffer.diagnostics.errors > 0 then
			return colors.red
		end
		return buffer.is_modified and colors.yellow or colors.grey_fg
	end,
	bold = function(buffer)
		return get_harpoon_index(buffer) ~= nil
	end,
}

-- Icône fichier
components.icon = {
	text = function(buffer)
		return buffer.devicon.icon
	end,
	fg = function(buffer)
		return buffer.devicon.color
	end,
}

local mixed_red = require("base46.colors").mix(colors.red, colors.grey, 40)
-- Nom du fichier
components.filename = {
	text = function(buffer)
		return vim.fn.fnamemodify(buffer.filename, ":r") .. " "
	end,
	bold = function(buffer)
		return buffer.is_focused
	end,
	fg = function(buffer)
		if buffer.diagnostics and buffer.diagnostics.errors > 0 then
			return buffer.is_focused and colors.red or mixed_red
		end
		return buffer.is_focused and colors.white or colors.light_grey
	end,
}

-- Préfixe unique
components.prefix = {
	text = function(buffer)
		return buffer.unique_prefix
	end,
	fg = colors.grey,
	italic = true,
}
-- Bouton fermer/unharpoon (affiche ● si modifié)
components.close = {
	text = function(buffer)
		return buffer.is_modified and "●" or "󰅖"
	end,
	fg = function(buffer)
		if buffer.is_modified then
			return colors.yellow
		end
		return buffer.is_focused and colors.red or colors.grey_fg2
	end,
	on_click = function(_, _, _, _, buffer)
		local idx = get_harpoon_index(buffer)
		if idx then
			require("harpoon"):list():remove_at(idx)
		else
			vim.schedule(function()
				vim.api.nvim_buf_delete(buffer.number, { force = false })
			end)
		end
	end,
}

components.space = {
	text = " ",
}

local function config()
	local harpoon = require("harpoon")

	load_harpoon_buffers()

	-- Rafraîchir cokeline quand harpoon change
	harpoon:extend({
		ADD = function()
			vim.schedule(function()
				vim.cmd("redrawtabline")
			end)
		end,
		REMOVE = function()
			vim.schedule(function()
				vim.cmd("redrawtabline")
			end)
		end,
	})

	require("cokeline").setup({
		show_if_buffers_are_at_least = 1,

		buffers = {
			filter_valid = function(buffer)
				return buffer.type == ""
			end,
			new_buffers_position = "last",
		},

		fill_hl = "TabLineFill",

		---@type Cokeline.Component
		default_hl = {
			fg = function(buffer)
				return buffer.is_focused and colors.white or colors.light_grey
			end,
			bg = colors.black2,
			sp = colors.blue,
			underline = function(buffer)
				return buffer.is_focused
			end,
		},

		---@type Cokeline.Component[]
		components = {
			components.reset_states,
			components.separator,
			components.icon,
			components.prefix,
			components.filename,
			components.close,
			components.space,
		},

		sidebar = {
			filetype = { "neo-tree", "NvimTree" },
			components = {
				{
					text = function(buf)
						return "  " .. buf.filetype
					end,
					bold = true,
					fg = colors.cyan,
					bg = colors.darker_black,
				},
				{
					text = " ",
					bg = colors.darker_black,
				},
			},
		},
	})

	-- Retrier les buffers après chaque changement
	local cokeline_buffers = require("cokeline.buffers")
	local original_get_valid = cokeline_buffers.get_valid_buffers

	cokeline_buffers.get_valid_buffers = function(...)
		local buffers = original_get_valid(...)
		table.sort(buffers, buffer_sorter)
		return buffers
	end
end

---@type LazySpec
return {
	"NeOzay/nvim-cokeline",
	dev = true,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"ThePrimeagen/harpoon",
	},
	event = "User FilePost",
	config = config,
}
